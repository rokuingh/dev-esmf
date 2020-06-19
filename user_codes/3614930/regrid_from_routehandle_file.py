# Reproducer for 3614930
# April 4, 2020
# Ryan O'Kuinghttons

import ESMF
import numpy as np

# This call enables debug logging
# ESMF.Manager(debug=True)

UNINITVAL = 1e-20

# Create a global grid from a SCRIP formatted file
srcgrid = ESMF.Grid(filename="ll1deg_grid.nc", filetype=ESMF.FileFormat.SCRIP)

# Create a field on the centers of the grid
srcfield = ESMF.Field(srcgrid)

# Set the srcfield data
srcfield.data[:,:] = 42

# Create a global grid from a SCRIP formatted file
dstgrid = ESMF.Grid(filename="ll1deg_grid.nc", filetype=ESMF.FileFormat.SCRIP)

# Create a field on the centers of the grid
dstfield = ESMF.Field(dstgrid)

# Initialize the dstfield
dstfield.data[:,:] = UNINITVAL

# Create a routehandle file
rh_filename = "routehandle_esmpy.dat"
rh = ESMF.Regrid(srcfield, dstfield, rh_filename=rh_filename)

# Reinitialize the dstfield (it is modified in Regrid as part of RouteHandle generation)
dstfield.data[:,:] = UNINITVAL

# Create the RouteHandle from file
rff = ESMF.RegridFromFile(srcfield, dstfield, rh_filename=rh_filename)

assert(np.all(dstfield.data[:,:] == UNINITVAL))

# Apply the weights using the RouteHandle created from file
dstfield = rff(srcfield, dstfield)

assert(np.all(dstfield.data[:,:] == 42))

if ESMF.local_pet() == 0:
    print ("ESMPy regridding from RouteHandle file completed successfully :)")
