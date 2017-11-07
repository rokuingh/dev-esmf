# This example demonstrates how to regrid between a LocStream and a Grid.

import ESMF
import numpy

def create_locstream_spherical_16(coord_sys=ESMF.CoordSys.SPH_DEG, domask=False):
    """
    :param coord_sys: the coordinate system of the LocStream
    :param domask: a boolean to tell whether or not to add a mask
    :return: LocStream
    """
    if ESMF.pet_count() is not 1:
        raise ValueError("processor count must be 1 to use this function")

    locstream = ESMF.LocStream(16, coord_sys=coord_sys)

    deg_rad = 3.14159
    if coord_sys == ESMF.CoordSys.SPH_DEG:
        deg_rad = 180

    locstream["ESMF:Lon"] = [0.0, 0.5*deg_rad, 1.5*deg_rad, 2*deg_rad, 0.0, 0.5*deg_rad, 1.5*deg_rad, 2*deg_rad, 0.0, 0.5*deg_rad, 1.5*deg_rad, 2*deg_rad, 0.0, 0.5*deg_rad, 1.5*deg_rad, 2*deg_rad]
    locstream["ESMF:Lat"] = [deg_rad/-2.0, deg_rad/-2.0, deg_rad/-2.0, deg_rad/-2.0, -0.25*deg_rad, -0.25*deg_rad, -0.25*deg_rad, -0.25*deg_rad, 0.25*deg_rad, 0.25*deg_rad, 0.25*deg_rad, 0.25*deg_rad, deg_rad/2.0, deg_rad/2.0, deg_rad/2.0, deg_rad/2.0]
    if domask:
        locstream["ESMF:Mask"] = np.array([1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], dtype=np.int32)

    return locstream


grid = ESMF.Grid(filename="ll1deg_grid.nc", filetype=ESMF.FileFormat.SCRIP)

locstream = create_locstream_spherical_16()

# create fields
srcfield = ESMF.Field(locstream, name='srcfield')
dstfield = ESMF.Field(grid, name='dstfield')

# initialize the fields
[x, y] = [0, 1]
deg2rad = 3.14159/180

gridXCoord = locstream["ESMF:Lon"]
gridYCoord = locstream["ESMF:Lat"]
srcfield.data[...] = 10.0 + numpy.cos(gridXCoord * deg2rad) ** 2 + numpy.cos(2 * gridYCoord * deg2rad)

dstfield.data[...] = 1e20

# create an object to regrid data from the source to the destination field
regrid = ESMF.Regrid(srcfield, dstfield,
                     regrid_method=ESMF.RegridMethod.NEAREST_DTOS)

# do the regridding from source to destination field
dstfield = regrid(srcfield, dstfield)

