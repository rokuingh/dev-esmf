import ESMF
import numpy

manager = ESMF.Manager(debug = True)  

# http://www.earthsystemmodeling.org/python_releases/last_esmp/python_doc/html/index.html

# Dimensions of source grid
nlon1 = 768
nlat1 = 768

# Dimensions of destination grid
nlon2 = 21600
nlat2 = 43200

# Create long/lat coordinates
lon1 = numpy.linspace(180.0/nlon1, 360.0, nlon1)
lat1 = numpy.linspace(90.0, -90.0, nlat1)
lon2 = numpy.linspace(180.0/nlon2, 360.0, nlon2)
lat2 = numpy.linspace(90.0, -90.0, nlat2)

def create_grid(lon, lat):
    '''
    Create a Grid with 1 periodic dimension with no bounds
    '''
    staggerLocs = [ESMF.StaggerLoc.CENTER]

    grid = ESMF.Grid(numpy.array([lon.size, lat.size], 'int32'),
                     num_peri_dims=0, staggerloc=staggerLocs)
    
    x, y = 0, 1
    gridXCenter = grid.get_coords(x, staggerloc=ESMF.StaggerLoc.CENTER)
    gridXCenter[...] = lon.reshape((lon.size, 1))

    gridYCenter = grid.get_coords(y, staggerloc=ESMF.StaggerLoc.CENTER)
    gridYCenter[...] = lat.reshape((1, lat.size))
    
    return grid
#--- End: def

def create_field(grid, name):
    '''
    Create a named Field from grid
    '''
    return ESMF.Field(grid, name)
#--- End: def

def run_regridding(srcfield, dstfield):
    '''
    Do bilinear regridding of srcfield to the grid of dstfield
    '''
    # call the regridding functions
    regridSrc2Dst = ESMF.Regrid(srcfield, dstfield,
                                src_mask_values=numpy.array([1], dtype='int32'),
                                dst_mask_values=numpy.array([1], dtype='int32'),
                                regrid_method=ESMF.RegridMethod.BILINEAR,
                                unmapped_action=ESMF.UnmappedAction.IGNORE)
    return regridSrc2Dst(srcfield, dstfield)
#--- End: def

# Create grids of specified dimensions
srcgrid = create_grid(lon1, lat1)
dstgrid = create_grid(lon2, lat2)

# Create fields
srcfield = create_field(srcgrid, 'srcfield')
dstfield = create_field(dstgrid, 'dstfield')

# Fill source field with data
srcfield.data[:] = numpy.ones((lon1.size, lat1.size))

# Do regridding
dstfield = run_regridding(srcfield, dstfield)
