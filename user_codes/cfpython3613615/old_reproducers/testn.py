import ESMF
import numpy

manager = ESMF.Manager(logkind = ESMF.LogKind.MULTI, debug = True)  

# http://www.earthsystemmodeling.org/python_releases/last_esmp/python_doc/html/index.html

lon5  = numpy.arange(  0, 360, 360/20.)
lon6  = numpy.arange(  0, 360, 360/21.)
lat11 = numpy.arange(89.999999999,  -90.1, -180/50.)
#lat11 = numpy.arange(89,  -89.1, -178/11.)

def create_grid(lon, lat):
    '''
Create a Grid with 1 periodic dimension
'''
   #staggerLocs = [ESMF.StaggerLoc.CORNER, ESMF.StaggerLoc.CENTER]
    staggerLocs = [ESMF.StaggerLoc.CENTER]

    grid = ESMF.Grid(numpy.array([lon.size, lat.size], 'int32'),
                     num_peri_dims=1, staggerloc=staggerLocs)

    gridXCenter = grid.get_coords(0)
    gridXCenter[...] = lon.reshape((lon.size, 1))

    gridYCenter = grid.get_coords(1)
    gridYCenter[...] = lat.reshape((1, lat.size))

    print gridXCenter
    print gridYCenter

    return grid
#--- End: def

def create_field(grid, name):
    '''
'''
    field = ESMF.Field(grid, name)
    return field
#--- End: def

def run_regridding(srcfield, dstfield):
    '''
'''
    # call the regridding functions
    regridSrc2Dst = ESMF.Regrid(srcfield, dstfield, 
                                    src_mask_values=numpy.array([1], dtype='int32'), 
                                    dst_mask_values=numpy.array([1], dtype='int32'), 
                                    regrid_method=ESMF.RegridMethod.BILINEAR, 
                                    unmapped_action=ESMF.UnmappedAction.IGNORE, )
#                                    src_frac_field=srcfracfield, 
#                                    dst_frac_field=dstfracfield)
    dstfield = regridSrc2Dst(srcfield, dstfield)
    
    return dstfield #, srcfracfield, dstfracfield
#--- End: def

print '\nSource grid:'
srcgrid = create_grid(lon5 , lat11)
print '\nDestintation grid:'
dstgrid = create_grid(lon6, lat11)

srcfield = create_field(srcgrid, 'srcfield')
dstfield = create_field(dstgrid, 'dstfield')

for i in xrange(lat11.size):
    srcfield.data[:,i] = i+1

print srcfield.data

dstfield = run_regridding(srcfield, dstfield)

print dstfield.data
