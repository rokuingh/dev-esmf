import ocgis


PATH_IN = "/home/benkoziol/l/project/bekozi-work/ocgis/ryan-grid-bounds/NSBS6nm.v01.nc"
PATH_OUT = "/home/benkoziol/l/project/bekozi-work/ocgis/ryan-grid-bounds/NSBS6nm.v02.nc"


rd = ocgis.RequestDataset(PATH_IN)
field = rd.create_field()


# now create a grid and write bounds
# grid = ocgis.Grid(vc["lon"].extract(), vc['lat'].extract(), crs=ocgis.crs.Spherical())
grid = field.grid
grid.set_extrapolated_bounds('bounds_lon', 'bounds_lat', 'corners')
grid.x.bounds.attrs.pop('units')
grid.y.bounds.attrs.pop('units')

# write from Field to get the variables
field.write(PATH_OUT)
# grid.parent.write(PATH_OUT)
# vc.write(PATH_OUT)
