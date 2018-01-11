import ocgis

PATH_IN = "/software/co2flux/SurfaceFluxData/CASA/GEE.3hrly.1x1.25.2015.nc"
PATH_OUT = "/software/co2flux/SurfaceFluxData/CASA/modified_GEE.3hrly.1x1.25.2015.nc"
# PATH_IN = 'data/GEE.3hrly.1x1.25.2015.nc'
# PATH_OUT = 'data/modified_GEE.3hrly.1x1.25.2015-2.nc'

rd = ocgis.RequestDataset(PATH_IN)
vc = rd.get_variable_collection()

GEE = vc['GEE']
GEE.set_value(GEE.get_value()*83333333.33)

vc.attrs['CO2_flux_unit'] = 'umol CO2/m2/sec'

# now create a grid and write bounds
grid = ocgis.Grid(vc["lon"].extract(), vc['lat'].extract(), crs=ocgis.crs.Spherical())
grid.set_extrapolated_bounds('bounds_lon', 'bounds_lat', 'corners')
grid.x.bounds.attrs.pop('units')
grid.y.bounds.attrs.pop('units')

# write from Field to get the variables
ocgis.Field(grid=grid, variables=vc["GEE"].extract()).write(PATH_OUT)
vc.write(PATH_OUT)
