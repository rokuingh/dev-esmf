
import ocgis

# wrfout file may need to be renamed to have a .nc ending for ocgis to recognize the format
PATH_IN = "/software/co2flux/Saved_WRF_runs/wrfout_d01_2015-03-05_00:00:00"
PATH_OUT = '/software/co2flux/Saved_WRF_runs/subset_wrfout.nc'
# PATH_IN = 'data/wrfout_link.nc'
# PATH_OUT = 'data/subset_wrfout.nc'

VARS_TO_KEEP = ['XLONG', 'XLAT']


rd = ocgis.RequestDataset(PATH_IN)
vc = rd.get_variable_collection()

diff = set(vc.keys()).difference(VARS_TO_KEEP)
for to_remove in diff:
    vc.pop(to_remove)

sub = vc[{'Time': 0}]

new_dimensions = sub.first().dimensions[1:]
for var in sub.values():
    var.reshape(new_dimensions)

# now create a grid and write bounds
grid = ocgis.Grid(sub['XLONG'].extract(), sub['XLAT'].extract())
grid.set_extrapolated_bounds('XLONG_BNDS', 'XLAT_BNDS', 'corners')
grid.x.bounds.attrs.pop('units')
grid.y.bounds.attrs.pop('units')

grid.parent.write(PATH_OUT)
vc.write(PATH_OUT)
