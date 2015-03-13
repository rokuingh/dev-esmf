def regrid():
    import ESMF
    import numpy

    lon5  = numpy.arange(  0, 360, 360/249.)
    lon6  = numpy.arange(  0, 360, 360/250.)
    lat11 = numpy.arange(90,  -90.1, -180/249.)
    
    def create_grid(lon, lat):
        '''
        Create a Grid with 1 periodic dimension
        '''
        staggerLocs = [ESMF.StaggerLoc.CENTER]
        
        grid = ESMF.Grid(numpy.array([lon.size, lat.size], 'int32'),
                         num_peri_dims=1, staggerloc=staggerLocs)
        
        gridXCenter = grid.get_coords(0)
        gridXCenter[...] = lon.reshape((lon.size, 1))
        
        gridYCenter = grid.get_coords(1)
        gridYCenter[...] = lat.reshape((1, lat.size))
        
        return grid
    #--- End: def
    
    def create_field(grid, name):
        '''
        Create a field
        '''
        field = ESMF.Field(grid, name)
        return field
    #--- End: def
    
    def run_regridding(srcfield, dstfield):
        '''
        Run regridding
        '''
        regridSrc2Dst = ESMF.Regrid(srcfield, dstfield)
        dstfield = regridSrc2Dst(srcfield, dstfield)
        regridSrc2Dst.release()
        return dstfield#, srcfracfield, dstfracfield
    #--- End: def
    
    srcgrid = create_grid(lon5, lat11)
    dstgrid = create_grid(lon6, lat11)
    
    srcfield = create_field(srcgrid, 'srcfield')
    dstfield = create_field(dstgrid, 'dstfield')
    
    srcfield.data[...] = 1
    
    dstfield = run_regridding(srcfield, dstfield)
    
    dstfield.release()
    srcfield.release()
    dstgrid.release()
    srcgrid.release()


for i in xrange(5000):
    print '\nIteration: ' + str(i + 1) + '...'
    regrid()
