# This example demonstrates regridding with ungridded dims

import ESMF

# This call enables debug logging
esmpy = ESMF.Manager(debug=True)

datafile = "so_Omon_ACCESS1-0_historical_r1i1p1_185001-185412_2timesteps.nc"
gridfile = "clt.nc"

# the number of elements in the extra field dimensions
levels = 50
time = 2

# Create a  grid from a GRIDSPEC formatted file
srcgrid = ESMF.Grid(filename=datafile, filetype=ESMF.FileFormat.GRIDSPEC)


# create a tripole grid
dstgrid = ESMF.Grid(filename=gridfile, filetype=ESMF.FileFormat.GRIDSPEC,
                    coord_names=["latitude","longitude"])


# create a field on the center stagger locations of the source grid
srcfield = ESMF.Field(srcgrid, name='srcfield',
                      staggerloc=ESMF.StaggerLoc.CENTER,
                      ndbounds=[time])

srcfield.read(filename=datafile, variable="so", ndbounds=2)

# create a field on the center stagger locations of the destination grid
dstfield = ESMF.Field(dstgrid, name='dstfield',
                      staggerloc=ESMF.StaggerLoc.CENTER,
                      ndbounds=[time, levels])

# create a field on the center stagger locations of the destination grid
xctfield = ESMF.Field(dstgrid, name='xctfield',
                      staggerloc=ESMF.StaggerLoc.CENTER,
                      ndbounds=[time, levels])

dstfield.data[:] = 1e20
xctfield.data[:] = 0

# create an object to regrid data from the source to the destination field
regrid = ESMF.Regrid(srcfield, dstfield,
                     regrid_method=ESMF.RegridMethod.BILINEAR,
                     unmapped_action=ESMF.UnmappedAction.ERROR)

# do the regridding from source to destination field
dstfield = regrid(srcfield, dstfield)

# output the results from one processor only
if ESMF.local_pet() is 0: print ("ESMPy Field Data Regridding Example Finished Successfully")