# This example demonstrates how to use ESMPy with MetOffice tripole grids.

# NOTES:

# nemo grid has several issues:
# - units attributes for nav_lon and nav_lat should be degrees_east and
#   degrees_north, respectively, to comply with GRIDSPEC conventions
# - there is one row of coordinates set to a really large number (9.96e36)
#   right at the equator
# - with conservative regridding there some infinite weights, due to malformed
#   cell boundaries
#
# orca grid also has some issues:
# - appear to be some malformed cells near one pole, this affects both
#   conservative and bilinear regridding which suggests that these cells have
#   have issues with the cell centers as well as the boundaries


import ESMF
import numpy
import os

regrid_method = ESMF.RegridMethod.BILINEAR

g1 = "nemo2"
g2 = "nemo2"

DATADIR = "/home/ryan/data/grids/tripole"

grids = {}
# filename, filetype, addcornerstagger, coordnames, addmask, varname, srclons, srclats, srclonbnds, srclatbnds
grids["nemo"] = (os.path.join(DATADIR, "nemo_025_sample_grid.nc"),
                 ESMF.FileFormat.GRIDSPEC, True, False, "",
                 "nav_lon", "nav_lat", "nav_lon_bnds", "nav_lat_bnds")
grids["nemo2"] = (os.path.join(DATADIR, "nemo_ay490o_1d_19701216-19710101_grid-T.nc"),
                 ESMF.FileFormat.GRIDSPEC, False, False, "",
                 "nav_lon", "nav_lat", "", "")
grids["orca"] = (os.path.join(DATADIR, "ORCA2_1d_00010101_00010101_grid_T_0000.nc"),
                 ESMF.FileFormat.GRIDSPEC, True, False, "",
                 "nav_lon", "nav_lat", "nav_lon_bnds", "nav_lat_bnds")
grids["pop"] = (os.path.join(DATADIR, "tx0.1v2_070911.nc"),
                ESMF.FileFormat.SCRIP, True, True, "grid_imask",
                "grid_center_lon", "grid_center_lat", "grid_corner_lon", "grid_corner_lat")
grids["ll1deg"] = (os.path.join(DATADIR, "ll1deg_grid.nc"),
                   ESMF.FileFormat.SCRIP, True, False, "",
                   "grid_center_lon", "grid_center_lat", "grid_corner_lon", "grid_corner_lat")
grids["ll2.5deg"] = (os.path.join(DATADIR, "ll2.5deg_grid.nc"),
                   ESMF.FileFormat.SCRIP, True, False, "",
                   "grid_center_lon", "grid_center_lat", "grid_corner_lon", "grid_corner_lat")


def create_grid(g):

    grid = ESMF.Grid(filename=grids[g][0], filetype=grids[g][1], add_corner_stagger=grids[g][2],
              add_mask=grids[g][3], varname=grids[g][4], coord_names=[grids[g][5], grids[g][6]])

    return grid

def initialize_field(field, analytic=False):

    # use a 2nd order spherical harmonic like function
    if analytic:
        # get the coordinate pointers and set the coordinates
        [lon, lat] = [0, 1]
        gridXCoord = field.grid.get_coords(lon, ESMF.StaggerLoc.CENTER)
        gridYCoord = field.grid.get_coords(lat, ESMF.StaggerLoc.CENTER)

        deg2rad = 3.14159 / 180

        field.data[...] = 2.0 + numpy.cos(gridXCoord * deg2rad) ** 2 *\
                                numpy.cos(2.0 * gridYCoord * deg2rad)
    # use data from input file
    else:
        import netCDF4 as nc
        # realistic source data
        f = nc.Dataset(grids[g1][0])
        sohefldo = f.variables['sohefldo']
        sohefldo = sohefldo[:]
        # transpose because this data is represented as lat/lon
        field.data[...] = sohefldo[0, :, :].T

def validate(srcfield, dstfield, xctfield, srcfracfield=None, dstfracfield=None):

    # handle the destination fractions field default value
    csrverr = None
    if dstfracfield is None:
        dstfracfield = ESMF.Field(dstfield.grid)
        dstfracfield.data[:] = numpy.ones(dstfield.data.shape)

    # check the mass conservation in the case of conservative regridding
    csrv = False
    if ((srcfracfield is not None) and (dstfracfield is not None)):
        csrv = True
        # get the area fields
        srcareafield = ESMF.Field(srcfield.grid, name='srcareafield')
        dstareafield = ESMF.Field(dstfield.grid, name='dstareafield')

        srcareafield.get_area()
        dstareafield.get_area()

        csrverr = 0
        srcmass = numpy.sum(numpy.abs(srcareafield.data * srcfracfield.data *
                                      srcfield.data))
        # NOTE: this is a workaround for infinite values resulting from
        #       infinite weights calculated for conservative regridding
        #       with wonky cells in the nemo grid
        ind = numpy.where((dstfield.data != float('inf')))
        dstmass = numpy.sum(numpy.abs(dstareafield.data[ind] *
                                      dstfield.data[ind]))
        if dstmass is not 0:
            csrverr = numpy.abs(srcmass - dstmass) / dstmass

    # compute the mean relative interpolation error
    from operator import mul

    # NOTE: first condition is a workaround for infinite values resulting from
    #       infinite weights calculated for conservative regridding
    #       with wonky cells in the nemo grid

    ind = numpy.where((dstfield.data != float('inf')) &
                      (dstfield.data != 1e20) &
                      (xctfield.data != 0) &
                      (dstfracfield.data > .999))
    num_nodes = reduce(mul, xctfield.data[ind].shape)
    relerr = numpy.sum(numpy.abs(dstfield.data[ind] / dstfracfield.data[ind] -
                                 xctfield.data[ind]) /
                       numpy.abs(dstfield.data[ind]))
    meanrelerr = relerr / num_nodes

    # handle the parallel case
    if ESMF.pet_count() > 1:
        try:
            from mpi4py import MPI
        except:
            raise ImportError
        comm = MPI.COMM_WORLD
        meanrelerr = comm.reduce(meanrelerr, op=MPI.SUM)
        csrverr = comm.reduce(csrverr, op=MPI.SUM)

    # output the results from one processor only
    if ESMF.local_pet() is 0:
        print "ESMPy Tripole Regridding Example"
        print "  interpolation mean relative error = {0}".format(meanrelerr)
        if csrv:
            print "  mass conservation relative error  = {0}".format(csrverr)

def plot(srcfield, interpfield, regrid_method="Conservative"):
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
    im = ax.imshow(srcfield.data.T, cmap='gist_ncar', aspect='auto',
                   extent=[numpy.min(srclons), numpy.max(srclons), numpy.min(srclats), numpy.max(srclats)])
    ax.set_xbound(lower=numpy.min(srclons), upper=numpy.max(srclons))
    ax.set_ybound(lower=numpy.min(srclats), upper=numpy.max(srclats))
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Source Data")

    ax = fig.add_subplot(1, 2, 2)
    im = ax.imshow(interpfield.data.T, cmap='gist_ncar', aspect='auto',
                   extent=[numpy.min(dstlons), numpy.max(dstlons), numpy.min(dstlats), numpy.max(dstlats)])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Regrid Solution")

    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.9, 0.1, 0.01, 0.8])
    fig.colorbar(im, cax=cbar_ax)

    plt.show()

###################################################################################

# this will enable ESMF logging
ESMF.Manager(debug=True)

print ("Create grid 1...")

# Create a grid1
grid1 = create_grid(g1)
# fix the wonky coords in the nemo grid
if g1 == "nemo":
    grid1.coords[0][1][:, 498] = 0

print ("Create grid 2...")

# Create a grid2
grid2 = create_grid(g2)
# fix the wonky coords in the nemo agrid
if g2 == "nemo":
    grid2.coords[0][1][:, 498] = 0

print ("Create field 1...")

# create a field on the center stagger locations of the source grid
srcfield = ESMF.Field(grid1, name='srcfield', staggerloc=ESMF.StaggerLoc.CENTER)

print ("Create field 2...")

# create fields on the center stagger locations of the other grid
dstfield = ESMF.Field(grid2, name='dstfield', staggerloc=ESMF.StaggerLoc.CENTER)
xctfield = ESMF.Field(grid2, name='xctfield', staggerloc=ESMF.StaggerLoc.CENTER)

print ("Initialize fields...")

# initialize the field to either an analytic or source value
initialize_field(srcfield, analytic=True)
initialize_field(xctfield, analytic=True)
dstfield.data[...] = 1e20

print ("Regrid weight generation...")

# create fields needed to analyze accuracy of conservative regridding
srcfracfield = None
dstfracfield = None
if regrid_method is ESMF.RegridMethod.CONSERVE:
    srcfracfield = ESMF.Field(grid1, name='srcfracfield')
    dstfracfield = ESMF.Field(grid2, name='dstfracfield')

# create an object to regrid data from the source to the destination field
regrid = ESMF.Regrid(srcfield, dstfield,
                     regrid_method=regrid_method,
                     unmapped_action=ESMF.UnmappedAction.IGNORE,
                     ignore_degenerate=False,
                     src_frac_field=srcfracfield,
                     dst_frac_field=dstfracfield)

print ("SMM..")

# do the regridding from source to destination field
dstfield = regrid(srcfield, dstfield, zero_region=ESMF.Region.SELECT)

print ("Validating...")


validate(srcfield, dstfield, xctfield, srcfracfield, dstfracfield)

# NOTE: this is a workaround for infinite values resulting from
#       infinite weights calculated for conservative regridding
#       with wonky cells in the nemo grid
if regrid_method == ESMF.RegridMethod.CONSERVE:
    dstfield.data[numpy.where(dstfield.data > 1e1)] = 0

rm2string = {ESMF.RegridMethod.BILINEAR:"Bilinear", ESMF.RegridMethod.CONSERVE:"Conservative"}
plot(srcfield, dstfield, regrid_method=rm2string[regrid_method])
