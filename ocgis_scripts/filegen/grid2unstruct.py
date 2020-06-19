import ocgis
from ocgis.test.base import create_gridxy_global


RESOLUTION = 0.25
OUTFILE = "ll"+str(RESOLUTION)+'deg.esmf.nc'

grid = create_gridxy_global(resolution=RESOLUTION, wrapped=False,
                            crs=ocgis.crs.Spherical())
geom = grid.get_abstraction_geometry()
geom.reshape([ocgis.Dimension(name='element_count', size=geom.size)])
polygc = geom.convert_to()
polygc.parent.write(OUTFILE, driver='netcdf-esmf-unstruct')
