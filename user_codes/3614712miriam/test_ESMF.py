#!/usr/bin/env python

import os
import ESMF
import numpy

print (ESMF.__version__)

ANALYTIC_DATA = True
UNINITVAL = 1e-20

DATADIR="./"

g1 = "src"
g2 = "dst"

grids = {}
# filename, filetype, addcornerstagger, coordnames, addmask, varname, srclons, srclats, srclonbnds, srclatbnds
grids["src"] = (os.path.join(DATADIR, "t_2016123100.nc"),
                 ESMF.FileFormat.GRIDSPEC, False, False, "",
                 "lon", "lat", "", "")
grids["dst"] = (os.path.join(DATADIR, "temporal_coords.nc"),
                 ESMF.FileFormat.GRIDSPEC, False, False, "",
                 "lon", "lat", "lon_bnds", "lat_bnds")

def initialize(field, grid="src"):
    # import netCDF4 as nc
    # 
    # # read grid coordinates
    # f2 = nc.Dataset(grids[grid][0])
    # lons = f2.variables[grids[grid][5]][:]
    # lats = f2.variables[grids[grid][6]][:]

    for i in range(field.data.shape[0]):
        for j in range(field.data.shape[1]):
            for k in range(field.data.shape[2]):
                for l in range(field.data.shape[3]):
                    field.data[i,j,k,l] = k

def validate(dstfield, xctfield):
    unmapped_count = 0
    error = 0
    errorTot = 0
    maxerror = 0
    for i in range(dstfield.data.shape[0]):
        for j in range(dstfield.data.shape[1]):
            for k in range(dstfield.data.shape[2]):
                for l in range(dstfield.data.shape[3]):
                    if (abs(dstfield.data[i,j,k,l] - UNINITVAL < 1E-12)):
                        unmapped_count = unmapped_count + 1
                        error = 0
                    else:
                        if (abs(xctfield.data[i,j,k,l] > 1E-12)):
                            error = abs(dstfield.data[i,j,k,l] - xctfield.data[i,j,k,l])/abs(xctfield.data[i,j,k,l])
                        else:
                            error = abs(dstfield.data[i,j,k,l] - xctfield.data[i,j,k,l])
                    errorTot = errorTot + error
                    if (error > maxerror):
                        maxerror = error
    
    # comms
    from mpi4py import MPI
    
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()

    comm.reduce(maxerror, maxerrorg, op=MPI.MAX)
    comm.reduce(unmapped_count, unmapped_countg, op=MPI.SUM)
    
    # output
    if rank == 0:
        print ("%d unmapped points".format(unmapped_countg))
        print ("Interpolation maximum relative error = %f".format(maxerrorg))

def plot(srcfield, interpfield, regrid_method="Bilinear"):
    import netCDF4 as nc

    # source data
    f = nc.Dataset(grids[g1][0])
    srclons = f.variables[grids[g1][5]][:]
    srclats = f.variables[grids[g1][6]][:]

    # read grid coordinates
    f2 = nc.Dataset(grids[g2][0])
    dstlons = f2.variables[grids[g2][5]][:]
    dstlats = f2.variables[grids[g2][6]][:]

    try:
        import matplotlib
        import matplotlib.pyplot as plt
    except:
        raise ImportError("matplotlib is not available on this machine")

    fig = plt.figure(1, (15, 6))
    fig.suptitle('ESMPy {} Regridding'.format(regrid_method), fontsize=14, fontweight='bold')

    ax = fig.add_subplot(1, 2, 1)
    im = ax.imshow(srcfield.data[:,:,0,0].T, cmap='gist_ncar', aspect='auto',
                   extent=[numpy.min(srclons), numpy.max(srclons), numpy.min(srclats), numpy.max(srclats)])
    ax.set_xbound(lower=numpy.min(srclons), upper=numpy.max(srclons))
    ax.set_ybound(lower=numpy.min(srclats), upper=numpy.max(srclats))
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Source Data")

    ax = fig.add_subplot(1, 2, 2)
    im = ax.imshow(interpfield.data[:,:,0,0].T, cmap='gist_ncar', aspect='auto',
                   extent=[numpy.min(dstlons), numpy.max(dstlons), numpy.min(dstlats), numpy.max(dstlats)])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Regrid Solution")

    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.9, 0.1, 0.01, 0.8])
    fig.colorbar(im, cax=cbar_ax)

    plt.show()


filename = os.path.join(DATADIR, "t_2016123100.nc")

level = 9
# Create a uniform global latlon grid from a SCRIP formatted file
src_grid = ESMF.Grid(filename=filename, filetype=ESMF.FileFormat.GRIDSPEC)

# Create a field on the centers of the grid
src_field = ESMF.Field(src_grid, name='t',
    staggerloc=ESMF.StaggerLoc.CENTER, ndbounds=[level, 25])

# field.read does not work if ESMF is built with MPIUNI

if ANALYTIC_DATA:
    initialize(src_field)
else:
    if ESMF.api.constants._ESMF_COMM is not ESMF.api.constants._ESMF_COMM_MPIUNI:
        src_field.read(filename=filename, variable='t', timeslice=25)

filename = os.path.join(DATADIR, "temporal_coords.nc")
dst_grid = ESMF.Grid(filename=filename, filetype=ESMF.FileFormat.GRIDSPEC)

dst_field = ESMF.Field(dst_grid, name='t', ndbounds=[level,25])
dst_field.data[...] = UNINITVAL

xct_field = None
if ANALYTIC_DATA:
    xct_field = ESMF.Field(dst_grid, name='t', ndbounds=[level,25])
    xct_field.data[...] = UNINITVAL

regrid = ESMF.Regrid(src_field, dst_field,
regrid_method=ESMF.RegridMethod.BILINEAR,
    unmapped_action=ESMF.UnmappedAction.IGNORE)

dst_field = regrid(src_field, dst_field)
print (dst_field.data.shape)

if ANALYTIC_DATA:
    validate(dst_field, xct_field)

# plot(src_field, dst_field)