import ESMF
from netCDF4 import Dataset, num2date
import numpy as np
import os
import sys
import math

[x, y, z] = [0, 1, 2]
MASK_MAPPED = 99
MASK_UNMAPPED = 98
MISSING_VAL = 1.0e20

# parameters
mm = 1
file1 = "data/BSclimate/%02i.nc" % mm
file2 = "grids/mesh_mask_BSEA.nc"
debug = True

flist = [[ 'temp', 'INIT_TEMP', 'BILINEAR', 1.0 , 273.15 ], \
         [ 'salt', 'INIT_SALT', 'BILINEAR', 1.0 , 0.0    ] ]

# create source grid
nc = Dataset(file1, 'r', format='NETCDF3_CLASSIC')
msk3d = nc.variables['mask'][:]
dims = msk3d.shape
nx = dims[2]
ny = dims[1]
nz = dims[0]

max_index = np.array([nx, ny, nz])
grid_src = ESMF.Grid(max_index, staggerloc=[ESMF.StaggerLoc.CENTER_VCENTER], coord_sys=ESMF.CoordSys.CART)

grid_src_xc = grid_src.get_coords(x)
xs = nc.variables['lon'][:]
grid_src_xc[...] = xs.reshape(xs.size, 1, 1)

grid_src_yc = grid_src.get_coords(y)
ys = nc.variables['lat'][:]
grid_src_yc[...] = ys.reshape(1, ys.size, 1)

grid_src_zc = grid_src.get_coords(z)
zs = nc.variables['lev'][:]
grid_src_zc[...] = zs.reshape(1, 1, zs.size)

mask = grid_src.add_item(ESMF.GridItem.MASK)
mask[:] = 1
mask[np.where(np.transpose(nc.variables['mask'][:]) > 1)] = 0

nc.close()

# is used to check variables such as grid_src_zc, mask
#if (debug):
#    f = Dataset("output.nc", 'w', format='NETCDF3_CLASSIC')
#    dimsn = ['lon', 'lat', 'lev']
#    for i in xrange(len(dims)):
#        dumm = f.createDimension(dimsn[i], dims[2-i])
#    var1 = f.createVariable("data1", 'f4', dimsn[::-1])
#    dumm = np.swapaxes(mask[:], 0, 2)
#    var1[:] = dumm.copy()
#    f.close()
#sys.exit()

# destination grid
nc = Dataset(file2, 'r', format='NETCDF3_CLASSIC')
msk3d = nc.variables['tmask'][0]
dims = msk3d.shape
nx = dims[2]
ny = dims[1]
nz = dims[0]

max_index = np.array([nx, ny, nz])
grid_dst = ESMF.Grid(max_index, staggerloc=[ESMF.StaggerLoc.CENTER_VCENTER], coord_sys=ESMF.CoordSys.CART)

grid_dst_xc = grid_dst.get_coords(x)
xs = nc.variables['nav_lon'][:]
grid_dst_xc[...] = xs.reshape(nx, ny, 1)

grid_dst_yc = grid_dst.get_coords(y)
ys = nc.variables['nav_lat'][:]
grid_dst_yc[...] = ys.reshape(nx, ny, 1)

grid_dst_zc = grid_dst.get_coords(z)
zs = nc.variables['gdept_0'][:]
grid_dst_zc[...] = zs.reshape(1, 1, zs.size)

mask = grid_dst.add_item(ESMF.GridItem.MASK)
mask[:] = 1
mask[np.where(np.transpose(nc.variables['tmask'][0]) == 0)] = 0

nc.close()

# is used to check variables such as grid_dst_zc, mask
#if (debug):
#    f = Dataset("output.nc", 'w', format='NETCDF3_CLASSIC')
#    dimsn = ['lon', 'lat', 'lev']
#    for i in xrange(len(dims)):
#        dumm = f.createDimension(dimsn[i], dims[2-i])
#    var1 = f.createVariable("data1", 'f4', dimsn[::-1])
#    dumm = np.swapaxes(grid_dst_zc[:], 0, 2)
#    var1[:] = dumm.copy()
#    f.close()
#sys.exit()

# create source field
field_src = ESMF.Field(grid_src, name='field_src', typekind=ESMF.TypeKind.R4, staggerloc=ESMF.StaggerLoc.CENTER_VCENTER)

# create desitination field
field_dst = ESMF.Field(grid_dst, name='field_dst', typekind=ESMF.TypeKind.R4, staggerloc=ESMF.StaggerLoc.CENTER_VCENTER)
field_dst.data[...] = MISSING_VAL

# create regrid object
regrid_method = ESMF.RegridMethod.BILINEAR
src_mask_values = np.array([0])
dst_mask_values = np.array([0])
regrid = ESMF.Regrid(field_src, field_dst, regrid_method=regrid_method,
                     src_mask_values=src_mask_values, dst_mask_values=dst_mask_values,
                     unmapped_action=ESMF.UnmappedAction.IGNORE)

# open input file
nc = Dataset(file1, 'r', format='NETCDF3_CLASSIC')

# loop over variables
for name in xrange(len(flist)):
    var_name = flist[name][0]
    sf = float(flist[name][3])
    ao = float(flist[name][4])

    # get variable
    var_src = np.squeeze(nc.variables[var_name][:])
    dumm = np.swapaxes(var_src, 0, 2)
    var_src = dumm.copy()
    field_src.data[...] = var_src[:]

    # interpolate data
    field_dst2 = regrid(field_src, field_dst, zero_region=ESMF.Region.SELECT)

    # create output file
    if (debug):
        f = Dataset("output.nc", 'w', format='NETCDF3_CLASSIC')
        dims = ['lon', 'lat', 'lev']
        for i in xrange(len(dims)):
            dumm = f.createDimension(dims[i], field_dst.upper_bounds[i])
            print dims[i], field_dst.upper_bounds[i]
        var1 = f.createVariable("data1", 'f4', dims[::-1], fill_value=MISSING_VAL)
        dumm = np.swapaxes(field_dst2.data[:], 0, 2)
        var1[:] = dumm.copy()
        f.close()

    sys.exit()