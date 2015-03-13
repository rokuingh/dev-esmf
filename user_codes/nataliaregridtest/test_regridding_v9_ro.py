# coding=utf-8

import numpy
import ESMF
from netCDF4 import Dataset
from time import time

esmpy = ESMF.Manager(logkind=ESMF.LogKind.MULTI, debug=True)


f1 = '/home/globc/tatarinova/Downloads/tasmax_day_EC-EARTH_rcp26_r8i1p1_20770401_20770410.nc' # (160 * 320)

#f2 = '/home/globc/tatarinova/Downloads/tasmax_day_CNRM-CM5_historical_r1i1p1_18500101-1850010.nc' # (128 * 256)


start = time()

#------------------------------------------------
# Creating srcgrid and dstgrid
#------------------------------------------------
grid_src = ESMF.Grid(filename=f1, 
                    filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True)

#grid_dst = ESMF.Grid(filename=f2, 
#                    filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True)


######################
######################

nc = Dataset(f1, 'r')
lat_bounds_dst = nc.variables['lat_bounds'][:,:]
lon_bounds_dst = nc.variables['lon_bounds'][:,:]

lb_x_dst = 0
lb_y_dst = 0
ub_x_dst = 320/2 - 1
ub_y_dst = 160/2 - 1

#print ub_x_dst
#print ub_y_dst

min_x_dst = numpy.amin(lon_bounds_dst)
min_y_dst = numpy.amin(lat_bounds_dst)
max_x_dst = numpy.amax(lon_bounds_dst)
max_y_dst = numpy.amax(lat_bounds_dst)


cellwidth_x_dst = (max_x_dst - min_x_dst) / (ub_x_dst - lb_x_dst)
cellwidth_y_dst = (max_y_dst - min_y_dst) / (ub_y_dst - lb_y_dst)

cellcenter_x_dst = cellwidth_x_dst/2
cellcenter_y_dst = cellwidth_y_dst/2

max_index_dst = numpy.array([ub_x_dst, ub_y_dst])

# You cannot regrid between grids of differing numbers of coordinate
# dimensions.  The grid created from file is represented in spherical
# coordinates, which means it has 2 parametric dimensions and 3 spatial
# dimensions.  There the grid created in memory should also have 3
# spatial dimensions.
#grid_dst = ESMF.Grid(max_index_dst, coord_sys=ESMF.CoordSys.CART)
# Spherical coordinates are required, you can choose to use radians or degrees,
# I am guess you are using degrees..
grid_dst = ESMF.Grid(max_index_dst, coord_sys=ESMF.CoordSys.SPH_DEG)
# Spherical degrees are also the default option, so the following call will also work
#grid_dst = ESMF.Grid(max_index_dst)


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


######################
######################

#------------------------------------------------
# Creating srcfield and dstfield
#------------------------------------------------
field_src = ESMF.Field(grid_src, 'gridFrom')
field_dst = ESMF.Field(grid_dst, 'gridTo')

srcfracfield = ESMF.Field(grid_src, 'srcfracfield')
dstfracfield = ESMF.Field(grid_dst, 'dstfracfield')

srcareafield = ESMF.Field(grid_src, 'srcareaield')
dstareafield = ESMF.Field(grid_dst, 'dstareafield')

#------------------------------------------------
# Create the regrid object ONLY ONCE
#------------------------------------------------
regridSrc2Dst = ESMF.Regrid(field_src, field_dst, 
                                regrid_method=ESMF.RegridMethod.CONSERVE, 
                                unmapped_action=ESMF.UnmappedAction.ERROR, 
                                src_frac_field=srcfracfield, 
                                dst_frac_field=dstfracfield)

srcareafield.get_area()
dstareafield.get_area()

#------------------------------------------------------------
# call the Regrid object on the Field pairs at each time step
#------------------------------------------------------------


src_data = nc.variables['tasmax'][:,:,:]
#print src_data.shape # (365, 160, 320)

#WARNING: our variable 'tasmax' has dimensions in order (time, lat, lon), while ESMF inverts the lat and lon: (lon, lat)
#    ---> We need to transpose the lat and lon
src_data_t = numpy.transpose(src_data, axes=[0,2,1])
#print src_data_t.shape # (365, 320, 160)

time_steps_src = src_data_t.shape[0]

dst_data = numpy.zeros((time_steps, field_dst.shape[0], field_dst.shape[1]))
dst_data[...] = 1e20


for time_step in range(time_steps_src):
    field_src.data[:,:] = src_data_t[time_step,:,:]
    dst_data[time_step,:,:] = regridSrc2Dst(field_src, field_dst)

#print dst_data.shape

#dst_data is the result data that will be written to an output netcdf file, but first we need again to transpose lat and lon
dst_data_t = numpy.transpose(dst_data, axes=[0,2,1])

#print dst_data_t.shape

stop = time()
time1 = stop - start
print "time: ", time1


print dst_data_t.shape



#num_levels = 500
#src_data = numpy.zeros([num_levels] + list(field_src.shape))
#src_data[...] = 25
#field_exact[...] = 25
#dst_data = numpy.zeros([num_levels] + list(field_dst.shape))
#dst_data[...] = 1e20
#
#results = numpy.zeros([2, num_levels])
#
#for level in range(num_levels):
#    field_src.data[:,:] = src_data[level,:,:]
#    dst_data[level,:,:] = regridSrc2Dst(field_src, field_dst)
#
#    # check results
#    srcmass = numpy.sum(srcareafield.data*srcfracfield.data*field_src.data)
#    dstmass = numpy.sum(dstareafield.data*field_dst.data)
#    results[0,level] = numpy.sum(numpy.abs(field_dst.data/dstfracfield.data-field_exact.data)/numpy.abs(field_exact.data))
#    results[1,level] = numpy.abs(srcmass - dstmass)/numpy.abs(dstmass)
#
#
#print "interpolation mean relative error - max over all levels"
#print numpy.max(results[0,:])
#
#print "mass conservation relative error - max over all levels"
#print numpy.max(results[1,:])
