import ocgis
from ocgis.test.base import create_exact_field, create_gridxy_global


PATH = '/tmp/exact.nc'


grid = create_gridxy_global(resolution=1.0, with_bounds=True, wrapped=True, crs=ocgis.crs.Spherical(), dtype=None)
field = create_exact_field(grid, 'exact', ntime=3, fill_data_var=True)

field.write(PATH)



