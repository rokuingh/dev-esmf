import ESMF
import numpy

manager = ESMF.Manager(logkind = ESMF.LogKind.MULTI, debug = True)  

lon5  = numpy.arange(  0, 360, 360/5.)
lon6  = numpy.arange(  0, 360, 360/6.)
#lat11 = numpy.arange(-89.9999999999999,  90.1, 180/10.)
lat11 = numpy.arange(-90.,  90.1, 180/10.)

def create_grid(lon, lat):
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

print '\nSource grid:'
srcgrid = create_grid(lon5 , lat11)
print '\nDestination grid:'
dstgrid = create_grid(lon6, lat11)

srcfield = ESMF.Field(srcgrid, 'srcgrid')
dstfield = ESMF.Field(dstgrid, 'dstfield')
xctfield = ESMF.Field(dstgrid, 'xctfield')

for i in xrange(lat11.size):
    srcfield.data[:,i] = i+1
    xctfield.data[:,i] = i+1

regridSrc2Dst = ESMF.Regrid(srcfield, dstfield,
                            regrid_method=ESMF.RegridMethod.BILINEAR,
                            unmapped_action=ESMF.UnmappedAction.IGNORE)
dstfield = regridSrc2Dst(srcfield, dstfield)

print '\nExact field:'
print xctfield.data

print '\nDestination field:'
print dstfield.data