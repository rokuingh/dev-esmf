# This example demonstrates how to regrid from hycom to roms

import os
import ESMF

# This call enables debug logging
ESMF.Manager(debug=True)

# set up file paths
DATADIR = os.path.join(os.getcwd(), "/Users/ryan.okuinghttons/sandbox/esmf_dev/user_codes/3613852")
grid1file = "hycom_salinity_19960101_t012.nc"
grid2file = "meb_1_30.nc"

# Create the hycom grid
grid1 = ESMF.Grid(filename=os.path.join(DATADIR, grid1file),
                 filetype=ESMF.FileFormat.GRIDSPEC)

# Create a field on the centers of the grid
field1 = ESMF.Field(grid1, staggerloc=ESMF.StaggerLoc.CENTER)

# Read a field from the file
field1.read(filename=os.path.join(DATADIR, grid1file), variable="salinity")

# Create the roms grid
grid2 = ESMF.Grid(filename=os.path.join(DATADIR, grid2file),
                  filetype=ESMF.FileFormat.GRIDSPEC,
                  coord_names=["lon_u", "lat_u"])

# Create a field on the centers of the grid
field2 = ESMF.Field(grid2, staggerloc=ESMF.StaggerLoc.CENTER)

field2.data[:] = 0

# Set up a regridding object between source and destination
regridS2D = ESMF.Regrid(field1, field2, 
                        regrid_method=ESMF.RegridMethod.BILINEAR)

field2 = ESMF.Regrid(field1, field2)

if ESMF.local_pet() == 0:
    print "\nhycom to roms regridding success :)"
