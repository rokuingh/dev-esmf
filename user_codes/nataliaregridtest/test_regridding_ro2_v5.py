# coding=utf-8

import numpy
import ESMF
from netCDF4 import Dataset


esmpy = ESMF.Manager(logkind=ESMF.LogKind.MULTI, debug=True)

"""
f1 = '/data/tatarinova/tasmax_day_EC-EARTH_rcp26_r8i1p1_2077.nc' # (160 * 320)

f2 = '/data/tatarinova/CMIP5/tasmax_day/tasmax_day_CNRM-CM5_historical_r1i1p1_18500101-18541231.nc' # (128 * 256)
"""

grid_src = ESMF.Grid(filename="tasmax_day_EC-EARTH_rcp26_r8i1p1_20770401-20770410.nc",
                    filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True)

grid_dst = ESMF.Grid(filename="tasmax_day_CNRM-CM5_historical_r1i1p1_18500101-1850010.nc",
                    filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True)

#------------------------------------------------
#Ã‚Â creating srcfield and dstfield
#------------------------------------------------
field_src = ESMF.Field(grid_src, 'gridFrom')
field_dst = ESMF.Field(grid_dst, 'gridTo')
field_exact = ESMF.Field(grid_dst, 'gridTo')
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

# let's pretend that we have source data at 500 time levels, let's also
# create a similar 500 level destination field.  Also, we need to
#  create an array to hold all of the validation results
# for the interpolation and conservation.  The source and exact fields
# are set to a constant field value of 25 for this small experiment, and
# the desination field is set to an abnormally large value to ensure
# that it will affect the validation if an interpolation point is missed.

print field_src.shape
print field_dst.shape

time_steps = 365

nc = Dataset("tasmax_day_EC-EARTH_rcp26_r8i1p1_20770401-20770410.nc", 'r')
src_data = nc.variables['tasmax'][:,:,:]


print src_data.shape # (365, 160, 320)


for time_step in range(time_steps):
    field_src.data[:,:] = src_data[time_step,:,:].transpose
    dst_data[time_step,:,:] = regridSrc2Dst(field_src, field_dst)



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
