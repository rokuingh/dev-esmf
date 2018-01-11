import ocgis
import numpy as np


# CSV_IN = '/software/co2flux/SurfaceFluxData/VULCAN/vulcangrid.10.2012.csv'
# NC_OUT = '/software/co2flux/SurfaceFluxData/VULCAN/vulcangrid.10.2012.nc'
CSV_IN = 'data/vulcangrid.10.2012.csv'
NC_OUT = 'data/vulcangrid.10.2012-2.nc'

# grid resolution acquired from ocgis.Grid (print grid.resolution)
gridres = 0.0988216/2.;

rd = ocgis.RequestDataset(CSV_IN)
field = rd.get()

i_size = np.array([int(ii) for ii in field['i'].get_value()]).max()
j_size = np.array([int(ii) for ii in field['j'].get_value()]).max()

xc = np.zeros((j_size, i_size), dtype=np.float32)
yc = np.zeros((j_size, i_size), dtype=np.float32)

i_value = field['i'].get_value().astype(np.int) - 1
j_value = field['j'].get_value().astype(np.int) - 1
for idx, ijkey in enumerate(field['ijkey'].get_value()):
    i_key, j_key = i_value[idx], j_value[idx]
    xc[j_key, i_key] = float(field['ddx'].get_value()[idx])+gridres
    yc[j_key, i_key] = float(field['ddy'].get_value()[idx])-gridres

xc = ocgis.Variable(name='longitude', value=xc, dimensions=['lat', 'lon'])
yc = ocgis.Variable(name='latitude', value=yc, dimensions=['lat', 'lon'])
grid = ocgis.Grid(xc, yc, crs=ocgis.crs.Spherical())

grid.set_extrapolated_bounds('x_bounds', 'y_bounds', 'corners')

ocgis.Field(grid=grid).write(NC_OUT)
vc.write(NC_OUT)

ocgis.RequestDataset(NC_OUT).inspect()
