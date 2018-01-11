import ocgis

PATH_IN = "/home/ryan/sandbox/esmf_dev/ocgis_scripts/gridconversions/data/topo.nc"
PATH_OUT = "/home/ryan/sandbox/esmf_dev/ocgis_scripts/gridconversions/data/topo.v02.nc"

rd = ocgis.RequestDataset(PATH_IN)
vc = rd.get_variable_collection()
field = rd.create_field()

# now create a grid and write bounds
grid = field.grid
grid = ocgis.Grid(vc["lonx"].extract(), vc['latx'].extract(), crs=ocgis.crs.Spherical())

grid.set_extrapolated_bounds('bounds_lon', 'bounds_lat', 'corners')
grid.x.bounds.attrs.pop('units')
grid.y.bounds.attrs.pop('units')

# write from Field to get the variables
field.write(PATH_OUT)