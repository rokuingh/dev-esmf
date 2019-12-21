
import ESMF
import numpy

# This call enables debug logging
esmpy = ESMF.Manager(debug=True)

selection = 2
grid_name = {1:["ufs.s2s.C384_t025.20120701.cmeps_v0.5.1.cice.h2_06h.2012-07-06-00000.nc", ['ULAT', 'ULON']], # degenerate
        2:["ufs.s2s.C384_t025.20120101.cmeps_v0.5.1.mom6.sfc._2012_01_07_75600.nc", ['xq', 'yq']], # large error
        3:["ufs.s2s.C384_t025.20120101.cmeps_v0.5.1.mom6.static.nc", ['xq', 'yq']], # large error
        4:["cf-compliant.cice.nc", ['ULAT', 'ULON']], # degenerate
        99:"ll2.5deg_grid.nc"} # destination regular grid

# Create a uniform global latlon grid from a SCRIP formatted file
grid = ESMF.Grid(filename=grid_name[selection][0], filetype=ESMF.FileFormat.GRIDSPEC,
                 is_sphere=True, coord_names=grid_name[selection][1])

# grid._write_(grid_name[selection][0].rstrip(".nc"))

# create a field on the center stagger locations of the source grid
srcfield = ESMF.Field(grid, name='srcfield')
srcfracfield = ESMF.Field(grid, name='srcfracfield')

# create an ESMF formatted unstructured mesh with clockwise cells removed
grid_reg = ESMF.Grid(filename=grid_name[99], filetype=ESMF.FileFormat.SCRIP, 
                     pole_kind=numpy.array([ESMF.PoleKind.BIPOLE, ESMF.PoleKind.MONOPOLE], dtype=numpy.int32),
                     is_sphere=True)

# grid_reg._write_(grid_name[99][0].rstrip(".nc"))

# create a field on the nodes of the destination mesh
dstfield = ESMF.Field(grid_reg, name='dstfield')
xctfield = ESMF.Field(grid_reg, name='xctfield')
dstfracfield = ESMF.Field(grid_reg, name='dstfracfield')

# initialize the fields
[lon,lat] = [0, 1]

gridLon = srcfield.grid.get_coords(lon)
gridLat = srcfield.grid.get_coords(lat)
srcfield.data[...] = 2.0 + numpy.cos(numpy.radians(gridLat[...]))**2 * \
                           numpy.cos(2.0*numpy.radians(gridLon[...]))

gridLon = xctfield.grid.get_coords(lon)
gridLat = xctfield.grid.get_coords(lat)
xctfield.data[...] = 2.0 + numpy.cos(numpy.radians(gridLat[...]))**2 * \
                           numpy.cos(2.0*numpy.radians(gridLon[...]))

dstfield.data[...] = 1e20

# create an object to regrid data from the source to the destination field
regrid = ESMF.Regrid(srcfield, dstfield,
                     regrid_method=ESMF.RegridMethod.BILINEAR,
                     unmapped_action=ESMF.UnmappedAction.ERROR)
                     # src_frac_field=srcfracfield,
                     # dst_frac_field=dstfracfield)

# do the regridding from source to destination field
dstfield = regrid(srcfield, dstfield)

# compute the mean relative error

num_nodes = numpy.prod(xctfield.data.shape)
relerr = 0
meanrelerr = 0
if num_nodes is not 0:
    ind = numpy.where((dstfield.data != 1e20) & (xctfield.data != 0))[0]
    relerr = numpy.sum(numpy.abs(dstfield.data[ind] - xctfield.data[ind]) / numpy.abs(xctfield.data[ind]))
    meanrelerr = relerr / num_nodes

# handle the parallel case
if ESMF.pet_count() > 1:
    try:
        from mpi4py import MPI
    except:
        raise ImportError
    comm = MPI.COMM_WORLD
    relerr = comm.reduce(relerr, op=MPI.SUM)
    num_nodes = comm.reduce(num_nodes, op=MPI.SUM)

    print ("rank #{0} - field bounds = [{1}, {2}]".format(ESMF.local_pet(),
        dstfield.lower_bounds, dstfield.upper_bounds))

# output the results from one processor only
if ESMF.local_pet() is 0:
    meanrelerr = relerr / num_nodes
    print ("ESMPy Regridding Example")
    print ("  interpolation mean relative error = {0}".format(meanrelerr))

    assert (meanrelerr < 3e-3)
