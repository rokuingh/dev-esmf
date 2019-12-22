
import ESMF
import numpy as np

# This call enables debug logging
esmpy = ESMF.Manager(debug=True)

src = 3
name = 0
coords = 1
dims = 2
offset = 3
grid_name = {1:["ufs.s2s.C384_t025.20120701.cmeps_v0.5.1.cice.h2_06h.2012-07-06-00000.nc", ['ULON', 'ULAT'], 2, 300], # degenerate
        2:["cf-compliant.cice.nc", ['ULON', 'ULAT'], 2, 300], # degenerate
        3:["ufs.s2s.C384_t025.20120101.cmeps_v0.5.1.mom6.sfc._2012_01_07_75600.nc", ['xq', 'yq'], 1, 300], # 
        4:["ufs.s2s.C384_t025.20120101.cmeps_v0.5.1.mom6.static.nc", ['xq', 'yq'], 1, 300]} # large error


# Create a grid from file
grid_src = ESMF.Grid(filename=grid_name[src][name], filetype=ESMF.FileFormat.GRIDSPEC,
                 is_sphere=True, coord_names=grid_name[src][coords])

# write the grid to vtk for vis
# grid._write_(grid_name[src][name].rstrip(".nc"))

# set up general grid coordinate info
[lon,lat] = [0, 1]

lbx = grid_src.lower_bounds[ESMF.StaggerLoc.CENTER][lon]
ubx = grid_src.upper_bounds[ESMF.StaggerLoc.CENTER][lon]
lby = grid_src.lower_bounds[ESMF.StaggerLoc.CENTER][lat]
uby = grid_src.upper_bounds[ESMF.StaggerLoc.CENTER][lat]

srcLonCenter = np.zeros([ubx-lbx, uby-lby])
srcLatCenter = np.zeros([ubx-lbx, uby-lby])


# pull full coordinate arrays from file
try:
    import netCDF4 as nc
except:
    raise ImportError('netCDF4 not available on this machine')

f = nc.Dataset(grid_name[src][name])
srclons = np.array(f.variables[grid_name[src][coords][lon]])
# source data on some grids is from -300:60 degrees longitude??
srclons = srclons + grid_name[src][offset]
srclats = np.array(f.variables[grid_name[src][coords][lat]])

# parallelize the coordinates before setting
if grid_name[src][dims] == 1:
    srclonpar = srclons[lbx:ubx]
    srclatpar = srclats[lby:uby]
elif grid_name[src][dims] == 2:
    srclonpar = srclons[lbx:ubx, lby:uby]
    srclatpar = srclats[lbx:ubx, lby:uby]
else:
    raise("dims not available")

# set coordinates on the grid
if grid_name[src][dims] == 1:
    srcLonCenter[:,:] = srclonpar.reshape((srclonpar.size, 1))
    srcLatCenter[:,:] = srclatpar.reshape((1, srclatpar.size))
elif grid_name[src][dims] == 2:
    srcLonCenter[:,:] = srclonpar.T
    srcLatCenter[:,:] = srclatpar.T
else:
    raise("dims not available")

# create a field on the center stagger locations of the source grid
srcfield = ESMF.Field(grid_src, name='srcfield')

# set up analytic field data for testing
# srcfield.data[...] = 2.0 + np.cos(np.radians(srcLatCenter[...]))**2 * \
#                            np.cos(2.0*np.radians(srcLonCenter[...]))
srcfield.data[...] = np.cos(np.radians(srcLatCenter[...]))*np.cos(np.radians(srcLonCenter[...]))
# srcfield.data[...] = 2.0


# create a regular grid in memory with artificial poles
dst_nlon = 144
dst_nlat = 72
max_index = np.array([dst_nlon,dst_nlat])
grid_dst = ESMF.Grid(max_index, staggerloc=[ESMF.StaggerLoc.CENTER], pole_kind=np.array([ESMF.PoleKind.BIPOLE, ESMF.PoleKind.MONOPOLE], dtype=np.int32))

# set up general grid coordinate info
lbx = grid_dst.lower_bounds[ESMF.StaggerLoc.CENTER][lon]
ubx = grid_dst.upper_bounds[ESMF.StaggerLoc.CENTER][lon]
lby = grid_dst.lower_bounds[ESMF.StaggerLoc.CENTER][lat]
uby = grid_dst.upper_bounds[ESMF.StaggerLoc.CENTER][lat]

dstLonCenter = grid_dst.get_coords(lon)
dstLatCenter = grid_dst.get_coords(lat)

dstlons = np.linspace(0,360,dst_nlon)
dstlats = np.linspace(-89,89,dst_nlat)

# parallelize the coordinates before setting
dstlonpar = dstlons[lbx:ubx]
dstlatpar = dstlats[lby:uby]

# set coordinates on the grid
dstLonCenter[...] = dstlonpar.reshape((dstlonpar.size, 1))
dstLatCenter[...] = dstlatpar.reshape((1, dstlatpar.size))

# grid_dst._write_(grid_name[dst][name].rstrip(".nc"))

# create destination Fields
dstfield = ESMF.Field(grid_dst, name='dstfield')
xctfield = ESMF.Field(grid_dst, name='xctfield')

# xctfield.data[...] = 2.0 + np.cos(np.radians(dstLatCenter[...]))**2 * \
#                            np.cos(2.0*np.radians(dstLonCenter[...]))
xctfield.data[...] = np.cos(np.radians(dstLatCenter[...]))*np.cos(np.radians(dstLonCenter[...]))
# xctfield.data[...] = 2.0

dstfield.data[...] = 1e20

# create an object to regrid data from the source to the destination field
regrid = ESMF.Regrid(srcfield, dstfield,
                     regrid_method=ESMF.RegridMethod.BILINEAR,
                     unmapped_action=ESMF.UnmappedAction.ERROR)

# do the regridding from source to destination field
dstfield = regrid(srcfield, dstfield)

# compute the mean relative error

num_nodes = np.prod(xctfield.data.shape)
relerr = 0
meanrelerr = 0
if num_nodes is not 0:
    ind = np.where((dstfield.data != 1e20) & (xctfield.data > 1e-6))[0]
    relerr = np.sum(np.abs(dstfield.data[ind] - xctfield.data[ind]) / np.abs(xctfield.data[ind]))

# handle the parallel case
if ESMF.pet_count() > 1:
    try:
        from mpi4py import MPI
    except:
        raise ImportError
    comm = MPI.COMM_WORLD
    relerr = comm.reduce(relerr, op=MPI.SUM)
    num_nodes = comm.reduce(num_nodes, op=MPI.SUM)

    # print ("rank #{0} - field bounds = [{1}, {2}]".format(ESMF.local_pet(),
    #     dstfield.lower_bounds, dstfield.upper_bounds))

# output the results from one processor only
if ESMF.local_pet() == 0:
    meanrelerr = relerr / num_nodes
    print ("ESMPy Regridding Example")
    print ("  interpolation mean relative error = {0}".format(meanrelerr))
    

if ESMF.pet_count() == 1:
    try:
        import matplotlib
        import matplotlib.pyplot as plt
    except:
        raise ImportError("matplotlib is not available on this machine")
    
    fig = plt.figure(1, (15, 6))
    fig.suptitle('ESMPy Regridding using     ufs.s2s.C384_t025.20120101.cmeps_v0.5.1.mom6.static.nc', fontsize=14,     fontweight='bold')
    
    ax = fig.add_subplot(1, 2, 1)
    im = ax.imshow(dstfield.data.T, cmap='gist_ncar', aspect='auto',
                   extent=[min(dstlons), max(dstlons), min(dstlats), max(dstlats)])
    ax.set_xbound(lower=min(dstlons), upper=max(dstlons))
    ax.set_ybound(lower=min(dstlats), upper=max(dstlats))
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Solution Data")
    
    ax = fig.add_subplot(1, 2, 2)
    im = ax.imshow((dstfield.data.T - xctfield.data.T)/ xctfield.data.T, cmap='gist_ncar', aspect='auto',
                   extent=[min(dstlons), max(dstlons), min(dstlats), max(dstlats)])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Relative Error in Solution Values")
    
    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.9, 0.1, 0.01, 0.8])
    fig.colorbar(im, cax=cbar_ax)
    
    plt.show()
