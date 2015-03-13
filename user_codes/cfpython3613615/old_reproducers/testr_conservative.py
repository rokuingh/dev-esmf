import ESMF
import numpy

manager = ESMF.Manager(logkind = ESMF.LogKind.MULTI, debug = True)

lon4  = numpy.arange(0., 360., 360/4)
lon5  = numpy.arange(0., 360., 360/5)
lon6  = numpy.arange(0., 360., 360/6)
lon7  = numpy.arange(0., 360., 360/7)
lon50  = numpy.arange(0., 360., 360/50)
lon60  = numpy.arange(0., 360., 360/60)
lon70  = numpy.arange(0., 360., 360/70)

lat11 = numpy.linspace(90.,  -90., 11)
lat12 = numpy.linspace(90.,  -90., 12)
lat110 = numpy.linspace(90.,  -90., 110)
lat120 = numpy.linspace(90.,  -90., 120)
lat130 = numpy.linspace(90.,  -90., 130)

def create_grid(lon, lat):
    staggerLocs = [ESMF.StaggerLoc.CORNER, ESMF.StaggerLoc.CENTER]

    grid = ESMF.Grid(numpy.array([lon.size, lat.size], 'int32'),
                     num_peri_dims=1, staggerloc=staggerLocs)

    offset_lon = 360./lon.size/2.
    lon -= offset_lon
    gridXCenter = grid.get_coords(0)
    gridXCenter[...] = lon.reshape((lon.size, 1))

    offset_lat = 180./(lat.size)/2.
    lat = numpy.linspace(90-offset_lat, -90+offset_lat, lat.size)
    gridYCenter = grid.get_coords(1)
    gridYCenter[...] = lat.reshape((1, lat.size))

    gridXCorner = grid.get_coords(0, staggerloc=ESMF.StaggerLoc.CORNER)
    gridXCorner[...] = lon.reshape((lon.size, 1))

    gridYCorner = grid.get_coords(1, staggerloc=ESMF.StaggerLoc.CORNER)
    lat_corner = numpy.linspace(90, -90, lat.size+1)
    gridYCorner[...] = lat_corner.reshape((1, lat_corner.size))

    '''
    print numpy.shape(gridXCenter)
    print numpy.shape(gridYCenter)
    print numpy.shape(gridXCorner)
    print numpy.shape(gridYCorner)

    print gridXCenter
    print gridYCenter
    print gridXCorner
    print gridYCorner
    '''
    return grid

#print '\nSource grid:'
srcgrid = create_grid(lon7, lat11)
#print '\nDestination grid:'
dstgrid = create_grid(lon7, lat11)

srcfield = ESMF.Field(srcgrid, 'srcfield')
dstfield = ESMF.Field(dstgrid, 'dstfield')
xctfield = ESMF.Field(dstgrid, 'xctfield')

for i in xrange(lat11.size):
    srcfield.data[:,i] = i+1
    xctfield.data[:,i] = i+1

regridSrc2Dst = ESMF.Regrid(srcfield, dstfield,
                            regrid_method=ESMF.RegridMethod.CONSERVE,
                            unmapped_action=ESMF.UnmappedAction.IGNORE)
dstfield = regridSrc2Dst(srcfield, dstfield)

print"\nExact Field"
print xctfield.data

print "\nDestination Field"
print dstfield.data

print "\n Exact error - sum(interp - exact) = {0}\n".format(
    numpy.sum(numpy.abs(dstfield.data-xctfield.data)))