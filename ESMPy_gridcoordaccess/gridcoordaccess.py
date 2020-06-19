# At some point I was seeing segv with grid coordinates access based on how they were set, but I can't reproduce it

import ESMF
import numpy as np

# This call enables debug logging
esmpy = ESMF.Manager(debug=True)

src = 3
name = 0
coords = 1
dims = 2
offset = 3
grid_name = "charles.nc"

# Create a grid from file
grid_src = ESMF.Grid(filename=grid_name, filetype=ESMF.FileFormat.GRIDSPEC,
                 is_sphere=True, coord_names=["lon","lat"])

# write the grid to vtk for vis
# grid._write_(grid_name[src][name].rstrip(".nc"))

# set up general grid coordinate info
[lon,lat] = [0, 1]

lbx = grid_src.lower_bounds[ESMF.StaggerLoc.CENTER][lon]
ubx = grid_src.upper_bounds[ESMF.StaggerLoc.CENTER][lon]
lby = grid_src.lower_bounds[ESMF.StaggerLoc.CENTER][lat]
uby = grid_src.upper_bounds[ESMF.StaggerLoc.CENTER][lat]

srcLonCenter = grid_src.get_coords(lon)
srcLatCenter = grid_src.get_coords(lat)
# srcLonCenter = np.zeros([ubx-lbx, uby-lby])
# srcLatCenter = np.zeros([ubx-lbx, uby-lby])

# pull full coordinate arrays from file
try:
    import netCDF4 as nc
except:
    raise ImportError('netCDF4 not available on this machine')

f = nc.Dataset(grid_name)
srclons = np.array(f.variables["lon"])
srclats = np.array(f.variables["lat"])

# set coordinates on the grid
srcLonCenter[:,:] = srclons.reshape((srclons.size, 1))
srcLatCenter[:,:] = srclats.reshape((1, srclats.size))

# access grid coordinates
srcLonCenter2 = grid_src.get_coords(lon)
srcLatCenter2 = grid_src.get_coords(lat)

print (srcLonCenter2, srcLatCenter2)

# create a field on the center stagger locations of the source grid
srcfield = ESMF.Field(grid_src, name='srcfield')

# set up analytic field data for testing
# srcfield.data[...] = 2.0 + np.cos(np.radians(srcLatCenter[...]))**2 * \
#                            np.cos(2.0*np.radians(srcLonCenter[...]))
srcfield.data[...] = np.cos(np.radians(srcLatCenter[...]))*np.cos(np.radians(srcLonCenter[...]))
# srcfield.data[...] = 2.0

print ("success")