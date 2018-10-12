##################Function to create grid based on ESMPy
import numpy as np
import ESMF

def gridcreate(latres = 2.5, lonres = 2.5):
    '''
    parameter
    --------
    latres / lonres : the resolution along latitude and longitude
    
    Return
    --------
    grid : grid used for regridding
    '''
    
    #resolution should be able to well divided by lat/lon
    if((360%latres != 0) | (180%lonres !=0)):
        print('Error, the number of grids will not be an integer')
        return
    
    #create the x/y coordinates
    lat = np.linspace(-90, 90, int(180/latres+1))
    lon = np.arange(0, 360, lonres)
    
    #create void grid based on dimension of x/y coordinates
    grid = ESMF.Grid(np.array([len(lon), len(lat)]), 
                     staggerloc = [ESMF.StaggerLoc.CENTER])
    
    #read in lon grid
    gridXCenter = grid.get_coords(0)
    x_par = lon[grid.lower_bounds[ESMF.StaggerLoc.CENTER][0] : \
                grid.upper_bounds[ESMF.StaggerLoc.CENTER][0]]
    gridXCenter[...] = x_par.reshape((x_par.size, 1))
    
    #read in lat grid
    gridYCenter = grid.get_coords(1)
    y_par = lat[grid.lower_bounds[ESMF.StaggerLoc.CENTER][1] : \
                grid.upper_bounds[ESMF.StaggerLoc.CENTER][1]]
    gridYCenter[...] = y_par.reshape((1, y_par.size))
    
    return grid




##################Function to downscale the resolution of one file to another
    
from netCDF4 import Dataset

def gregrid(srcfile, dstfile, variable, latres = 2.5, lonres = 2.5):
    '''
    parameter
    --------
    srcfile : the source nc file name to be regridded
    
    dstfile : the destination nc file name to be created, in dstfile, the varible 
                dimension is ['time', 'lat', 'lon']
    
    variable : the variable in the sourcefile to be regridded
    
    latres, lonres : the resolution of destination dataset
    
    Return
    --------
    field2.data.T : 3d.matrix, containing the original data    
    dstfield.data.T : 3d.matrix, containing the regridded data
    '''
    dataset = Dataset(srcfile,'r')
    
    #create the destination grid and field to be overwritten
    grid1 = gridcreate(latres = latres, lonres = lonres)
    field1 = ESMF.Field(grid1, staggerloc=ESMF.StaggerLoc.CENTER, 
                        ndbounds=[dataset.variables[variable].shape[0]])
    
    #read in the source grid and field to be regridded
    grid2 = ESMF.Grid(filename=srcfile, filetype=ESMF.FileFormat.GRIDSPEC)
    field2 = ESMF.Field(grid2, staggerloc=ESMF.StaggerLoc.CENTER, 
                        ndbounds=[dataset.variables[variable].shape[0]])
    field2.read(filename=srcfile, variable=variable, timeslice=1)
    
    #regridding using the bilinear method
    regridres = ESMF.Regrid(srcfield = field2, dstfield = field1, regrid_method = ESMF.RegridMethod.BILINEAR)
    dstfield = regridres(field2, field1)
    
    destination = Dataset(dstfile, 'w')
    
    # Copy global attributes 
    destination.setncatts({a:dataset.getncattr(a) for a in dataset.ncattrs()}) 

    #create dimensions
    destination.createDimension('time', None)
    destination.createDimension('lat', len(dstfield.grid.coords[0][1][0,:][::-1]))
    destination.createDimension('lon', len(dstfield.grid.coords[0][0][:,0]))

    # create variables
    destination.createVariable('time', np.float64, ('time',))
    destination.createVariable('lat', np.float64, ('lat',))
    destination.createVariable('lon', np.float64, ('lon',))
    destination.createVariable(variable, np.float32, ('time', 'lat', 'lon'))
    
    # Copy variables attributes
    for name, var in destination.variables.items():
        destination.variables[name].setncatts({a:dataset.variables[name].getncattr(a) 
                                        for a in dataset.variables[name].ncattrs()})
    
    destination.variables['time'][:] = dataset.variables['time'][:]
    destination.variables['lat'][:] = dstfield.grid.coords[0][1][0,:]
    destination.variables['lon'][:] = dstfield.grid.coords[0][0][:,0]
    destination.variables[variable][:] = dstfield.data.T
    
    destination.close() 
    dataset.close() 
    
    return field2.data.T, dstfield.data.T
    







