# coding=utf-8

import ESMF
import numpy
from netCDF4 import Dataset


esmpy = ESMF.Manager(logkind=ESMF.LogKind.MULTI, debug=True)

f1 = '/data/tatarinova/tasmax_day_EC-EARTH_rcp26_r8i1p1_2077.nc' # (160 * 320)
f2 = '/data/tatarinova/CMIP5/tasmax_day/tasmax_day_CNRM-CM5_historical_r1i1p1_18500101-18541231.nc' # (128 * 256)


# SOURCE 
#------------------------------------------------
# creating a source grid 
#------------------------------------------------
nc1 = Dataset(f1, 'r')
lat_bounds_src = nc1.variables['lat_bounds'][:,:]
lon_bounds_src = nc1.variables['lon_bounds'][:,:]


lb_x_src = 0
lb_y_src = 0
ub_x_src = lon_bounds_src.shape[0]
ub_y_src = lat_bounds_src.shape[0]

min_x_src = numpy.amin(lon_bounds_src)
min_y_src = numpy.amin(lat_bounds_src)
max_x_src = numpy.amax(lon_bounds_src)
max_y_src = numpy.amax(lat_bounds_src)


cellwidth_x_src = (max_x_src - min_x_src) / (ub_x_src - lb_x_src)
cellwidth_y_src = (max_y_src - min_y_src) / (ub_y_src - lb_y_src)

cellcenter_x_src = cellwidth_x_src/2
cellcenter_y_src = cellwidth_y_src/2

max_index_src = numpy.array([ub_x_src, ub_y_src])

grid_src = ESMF.Grid(max_index_src, coord_sys=ESMF.CoordSys.CART)


##     CORNERS
grid_src.add_coords(staggerloc=[ESMF.StaggerLoc.CORNER])

# get the coordinate pointers and set the coordinates
[x,y] = [0,1]
grid_srcCorner = grid_src.coords[ESMF.StaggerLoc.CORNER]

for i in xrange(grid_srcCorner[x].shape[x]):
    grid_srcCorner[x][i, :] = float(i)*cellwidth_x_src + \
        min_x_src + grid_src.lower_bounds[ESMF.StaggerLoc.CORNER][x] * cellwidth_x_src
        # last line is the pet specific starting point for this stagger and dim

for j in xrange(grid_srcCorner[y].shape[y]):
    grid_srcCorner[y][:, j] = float(j)*cellwidth_y_src + \
        min_y_src + grid_src.lower_bounds[ESMF.StaggerLoc.CORNER][y] * cellwidth_y_src
        # last line is the pet specific starting point for this stagger and dim

##     CENTERS
grid_src.add_coords(staggerloc=[ESMF.StaggerLoc.CENTER])

# get the coordinate pointers and set the coordinates
[x,y] = [0,1]
grid_srcXCenter = grid_src.get_coords(x, staggerloc=ESMF.StaggerLoc.CENTER)
grid_srcYCenter = grid_src.get_coords(y, staggerloc=ESMF.StaggerLoc.CENTER)

for i in xrange(grid_srcXCenter.shape[x]):
    grid_srcXCenter[i, :] = float(i)*cellwidth_x_src + cellwidth_x_src/2.0 + \
        min_x_src + grid_src.lower_bounds[ESMF.StaggerLoc.CENTER][x] * cellwidth_x_src
        # last line is the pet specific starting point for this stagger and dim

for j in xrange(grid_srcYCenter.shape[y]):
    grid_srcYCenter[:, j] = float(j)*cellwidth_y_src + cellwidth_y_src/2.0 + \
        min_y_src + grid_src.lower_bounds[ESMF.StaggerLoc.CENTER][y] * cellwidth_y_src
        # last line is the pet specific starting point for this stagger and dim


# DESTINATION
#------------------------------------------------
# creating a destination grid 
#------------------------------------------------
nc2 = Dataset(f2, 'r')
lat_bounds_dst = nc2.variables['lat_bnds'][:,:]
lon_bounds_dst = nc2.variables['lon_bnds'][:,:]

lb_x_dst = 0
lb_y_dst = 0
ub_x_dst = lon_bounds_dst.shape[0]
ub_y_dst = lat_bounds_dst.shape[0]

min_x_dst = numpy.amin(lon_bounds_dst)
min_y_dst = numpy.amin(lat_bounds_dst)
max_x_dst = numpy.amax(lon_bounds_dst)
max_y_dst = numpy.amax(lat_bounds_dst)


cellwidth_x_dst = (max_x_dst - min_x_dst) / (ub_x_dst - lb_x_dst)
cellwidth_y_dst = (max_y_dst - min_y_dst) / (ub_y_dst - lb_y_dst)

cellcenter_x_dst = cellwidth_x_dst/2
cellcenter_y_dst = cellwidth_y_dst/2

max_index_dst = numpy.array([ub_x_dst, ub_y_dst])

grid_dst = ESMF.Grid(max_index_dst, coord_sys=ESMF.CoordSys.CART)


##     CORNERS
grid_dst.add_coords(staggerloc=[ESMF.StaggerLoc.CORNER])

# get the coordinate pointers and set the coordinates
[x,y] = [0,1]
grid_dstCorner = grid_dst.coords[ESMF.StaggerLoc.CORNER]

for i in xrange(grid_dstCorner[x].shape[x]):
    grid_dstCorner[x][i, :] = float(i)*cellwidth_x_dst + \
        min_x_dst + grid_dst.lower_bounds[ESMF.StaggerLoc.CORNER][x] * cellwidth_x_dst
        # last line is the pet specific starting point for this stagger and dim

for j in xrange(grid_dstCorner[y].shape[y]):
    grid_dstCorner[y][:, j] = float(j)*cellwidth_y_dst + \
        min_y_dst + grid_dst.lower_bounds[ESMF.StaggerLoc.CORNER][y] * cellwidth_y_dst
        # last line is the pet specific starting point for this stagger and dim

##     CENTERS
grid_dst.add_coords(staggerloc=[ESMF.StaggerLoc.CENTER])

# get the coordinate pointers and set the coordinates
[x,y] = [0,1]
grid_dstXCenter = grid_dst.get_coords(x, staggerloc=ESMF.StaggerLoc.CENTER)
grid_dstYCenter = grid_dst.get_coords(y, staggerloc=ESMF.StaggerLoc.CENTER)

for i in xrange(grid_dstXCenter.shape[x]):
    grid_dstXCenter[i, :] = float(i)*cellwidth_x_dst + cellwidth_x_dst/2.0 + \
        min_x_dst + grid_dst.lower_bounds[ESMF.StaggerLoc.CENTER][x] * cellwidth_x_dst
        # last line is the pet specific starting point for this stagger and dim

for j in xrange(grid_dstYCenter.shape[y]):
    grid_dstYCenter[:, j] = float(j)*cellwidth_y_dst + cellwidth_y_dst/2.0 + \
        min_y_dst + grid_dst.lower_bounds[ESMF.StaggerLoc.CENTER][y] * cellwidth_y_dst
        # last line is the pet specific starting point for this stagger and dim







#------------------------------------------------
#Â creating srcfield and dstfield
#------------------------------------------------
field_src = ESMF.Field(grid_src, 'gridFrom')
field_dst = ESMF.Field(grid_dst, 'gridTo')


#------------------------------------------------
# regridding
#------------------------------------------------
regridSrc2Dst = ESMF.Regrid(field_src, field_dst, 
                                regrid_method=ESMF.RegridMethod.CONSERVE, 
                                unmapped_action=ESMF.UnmappedAction.ERROR, 
                                src_frac_field=srcfracfield, 
                                dst_frac_field=dstfracfield)

field_dst = regridSrc2Dst(field_src, field_dst)






