import ocgis
import numpy as np


CSV_IN = '/home/ryan/sandbox/esmf_dev/user_codes/Gara/vulcangrid.10.2012.csv'
NC_OUT = '/home/ryan/sandbox/esmf_dev/user_codes/Gara/vulcangrid.10.2012.nc'

gridres = 10./2.;

rd = ocgis.RequestDataset(CSV_IN)
field = rd.get()

i_size = np.array([int(ii) for ii in field['i'].get_value()]).max()
j_size = np.array([int(ii) for ii in field['j'].get_value()]).max()

xc = np.zeros((j_size, i_size), dtype=np.float32)
yc = np.zeros((j_size, i_size), dtype=np.float32)

for idx, ijkey in enumerate(field['ijkey'].get_value()):
    keys = ijkey.split('.')
    i_key, j_key = [int(ii) - 1 for ii in keys]
    xc[j_key, i_key] = float(field['ddx'].get_value()[idx])-gridres
    yc[j_key, i_key] = float(field['ddy'].get_value()[idx])-gridres

xc = ocgis.Variable(name='longitude', value=xc, dimensions=['lat', 'lon'])
yc = ocgis.Variable(name='latitude', value=yc, dimensions=['lat', 'lon'])
grid = ocgis.Grid(xc, yc, crs=ocgis.crs.Spherical())
ocgis.Field(grid=grid).write(NC_OUT)

ocgis.RequestDataset(NC_OUT).inspect()
