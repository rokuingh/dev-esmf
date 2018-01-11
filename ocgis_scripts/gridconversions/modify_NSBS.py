import ocgis

PATH_IN = "/home/ryan/sandbox/esmf_dev/ocgis_scripts/gridconversions/data/NSBS6nm.v01.nc"
PATH_OUT = "/home/ryan/sandbox/esmf_dev/ocgis_scripts/gridconversions/data/NSBS6nm.v02.nc"

rd = ocgis.RequestDataset(PATH_IN)
field = rd.create_field()

# now create a grid and write bounds
grid = field.grid
grid.set_extrapolated_bounds('bounds_lon', 'bounds_lat', 'corners')
grid.x.bounds.attrs.pop('units')
grid.y.bounds.attrs.pop('units')

# write from Field to get the variables
field.write(PATH_OUT)