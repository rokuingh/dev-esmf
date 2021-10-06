
import os
import ESMF

# This call enables debug logging
# ESMF.Manager(debug=True)

# Create a  global grid from a GRIDSPEC formatted file
grid = ESMF.Grid(filename="Gridinfo_CAMSv5.1_c20210407.nc"),
                 filetype=ESMF.FileFormat.GRIDSPEC)

# Create a field on the centers of the grid, with extra dimensions
srcfield = ESMF.Field(grid, staggerloc=ESMF.StaggerLoc.CENTER)

srcfield.data = 42.

# Create an ESMF formatted unstructured mesh with clockwise cells removed
grid2 = ESMF.Grid(filename="mpas_scrip.2621442.nc"),
                  filetype=ESMF.FileFormat.SCRIP)

# Create a field on the nodes of the mesh
dstfield = ESMF.Field(grid2, staggerloc=ESMF.StaggerLoc.CENTER)

dstfield.data[:] = 1e20

filename = "test.nc"

# compute the weight matrix for regridding
regrid = ESMF.RegridFromFile(srcfield, dstfield, filename)

assert(np.all(dstfield.data[:] == 42.))

if ESMF.local_pet() == 0:
    print ("Regrid file read and applied successfully :)")
