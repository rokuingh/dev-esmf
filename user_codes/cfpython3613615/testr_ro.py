import ESMF
import numpy

manager = ESMF.Manager(logkind = ESMF.LogKind.MULTI, debug = True)

# http://www.earthsystemmodeling.org/python_releases/last_esmp/python_doc/html/index.html

lon5  = numpy.arange(  0, 360, 360/99.)
lon6  = numpy.arange(  0, 360, 360/100.)
#lat11 = numpy.arange(90,  -90.1, -180/9.)
lat11 = numpy.arange(89,  -89.1, -178/9.)

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

    #print gridXCenter
    #print gridYCenter

    return grid
#--- End: def

srcgrid = create_grid(lon5 , lat11)
dstgrid = create_grid(lon6, lat11)

srcfield = ESMF.Field(srcgrid, 'srcfield')
dstfield = ESMF.Field(dstgrid, 'dstfield')
xctfield = ESMF.Field(dstgrid, 'xctfield')

#for i in xrange(lat11.size):
#    srcfield.data[:,i] = i+1

# first create a regrid object with one pair of fields
regridSrc2Dst = ESMF.Regrid(srcfield, dstfield,
                            src_mask_values=numpy.array([1]),
                            dst_mask_values=numpy.array([1]),
                            regrid_method=ESMF.RegridMethod.BILINEAR,
                            unmapped_action=ESMF.UnmappedAction.IGNORE)

# create a numpy array to hold the source and destination data at each vertical level
levels = 500
srcdata = numpy.zeros([levels] + list(srcfield.shape))
dstdata = numpy.zeros([levels] + list(dstfield.shape))
results = numpy.zeros([levels])

# initialize fields to constant values to allow simple result checking
srcdata[...] = 25
dstfield[...] = 1e20
xctfield[...] = 25

# now execute the regridding on each individual vertical level
for level in range(levels):
    srcfield.data[:,:] = srcdata[level,:,:]
    dstdata[level,:,:] = regridSrc2Dst(srcfield, dstfield)

    # check results
    results[level] = numpy.sum(numpy.abs(dstfield.data-xctfield.data)/numpy.abs(xctfield.data))

print "interpolation mean relative error - max over all levels"
print numpy.max(results[:])
