# This is a reproducer of bug 1125 from uvcdat
import ESMF
import numpy

def create_grid_corners(lons, lats, coordtk=ESMF.TypeKind.R8):
    grid = ESMF.Grid(numpy.array([lons.size-1, lats.size-1], 'int32'),
                     staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER],
                     coord_typekind=coordtk)

    gridXCorner = grid.get_coords(lon, staggerloc=ESMF.StaggerLoc.CORNER)
    lon_par = lons[grid.lower_bounds[ESMF.StaggerLoc.CORNER][lon]:grid.upper_bounds[ESMF.StaggerLoc.CORNER][lon]]
    gridXCorner[...] = lon_par.reshape((lon_par.size, 1))

    gridYCorner = grid.get_coords(lat, staggerloc=ESMF.StaggerLoc.CORNER)
    lat_par = lats[grid.lower_bounds[ESMF.StaggerLoc.CORNER][lat]:grid.upper_bounds[ESMF.StaggerLoc.CORNER][lat]]
    gridYCorner[...] = lat_par.reshape((1, lat_par.size))

    offset_lon = (lons[1]-lons[0])/2.
    lons -= offset_lon
    gridXCenter = grid.get_coords(lon)
    lon_par = lons[grid.lower_bounds[ESMF.StaggerLoc.CENTER][lon]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][lon]]
    gridXCenter[...] = lon_par.reshape((lon_par.size, 1))

    offset_lat = (lons[1]-lons[0])/2.
    lats -= offset_lat
    gridYCenter = grid.get_coords(lat)
    lat_par = lats[grid.lower_bounds[ESMF.StaggerLoc.CENTER][lat]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][lat]]
    gridYCenter[...] = lat_par.reshape((1, lat_par.size))

    return grid

def initialize_field(field):
    realdata = False
    try:
        import netCDF4 as nc

        f = nc.Dataset('charles.nc')
        swcre = f.variables['swcre']
        swcre = swcre[:]
        realdata = True
    except:
        raise ImportError('netCDF4 not available on this machine')

    if realdata:
        field.data[...] = swcre[0:-1, 0:-1].T
    else:
        field.data[...] = 2.0

    return field

def plot(srclons, srclats, srcfield, dstlons, dstlats, interpfield):

    try:
        import matplotlib
        import matplotlib.pyplot as plt
    except:
        raise ImportError("matplotlib is not available on this machine")

    exact = srcfield.data.T

    interp = dstfield.data.T

    fig = plt.figure(1, (15,4))

    ax = fig.add_subplot(1,2,1)
    im = ax.imshow(exact, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto')

    ax = fig.add_subplot(1,2,2)
    im = ax.imshow(interp, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto')

    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.85, 0.15, 0.05, 0.7])
    fig.colorbar(im, cax=cbar_ax)

    plt.show()

# Start up ESMF, this call is only necessary to enable debug logging
esmpy = ESMF.Manager(logkind=ESMF.LogKind.MULTI, debug=True)

[lon, lat] = [0, 1]

# Create a destination grid from a SCRIP formatted file.
srcgrid = ESMF.Grid(filename="charles.nc",
                    filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True)

srclons = numpy.array([135.5, 136.5, 137.5, 138.5, 139.5, 140.5, 141.5, 142.5, 143.5, 144.5,
    145.5, 146.5, 147.5, 148.5, 149.5, 150.5, 151.5, 152.5, 153.5, 154.5,
    155.5, 156.5, 157.5, 158.5, 159.5, 160.5, 161.5, 162.5, 163.5, 164.5,
    165.5, 166.5, 167.5, 168.5, 169.5, 170.5, 171.5, 172.5, 173.5, 174.5,
    175.5, 176.5, 177.5, 178.5, 179.5, 180.5, 181.5, 182.5, 183.5, 184.5,
    185.5, 186.5, 187.5, 188.5, 189.5, 190.5, 191.5, 192.5, 193.5, 194.5,
    195.5, 196.5, 197.5, 198.5, 199.5, 200.5, 201.5, 202.5, 203.5, 204.5,
    205.5, 206.5, 207.5, 208.5, 209.5, 210.5, 211.5, 212.5, 213.5, 214.5,
    215.5, 216.5, 217.5, 218.5, 219.5, 220.5, 221.5, 222.5, 223.5, 224.5,
    225.5, 226.5, 227.5, 228.5, 229.5, 230.5, 231.5, 232.5, 233.5, 234.5])
srclats = numpy.array([-29.5, -28.5, -27.5, -26.5, -25.5, -24.5, -23.5, -22.5, -21.5, -20.5,
    -19.5, -18.5, -17.5, -16.5, -15.5, -14.5, -13.5, -12.5, -11.5, -10.5,
    -9.5, -8.5, -7.5, -6.5, -5.5, -4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5,
    2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5,
    15.5, 16.5, 17.5, 18.5, 19.5, 20.5, 21.5, 22.5, 23.5, 24.5, 25.5, 26.5,
    27.5, 28.5, 29.5])
srcgrid = create_grid_corners(srclons, srclats)

dstlons = numpy.array([135., 137., 139., 141., 143., 145., 147., 149., 151.,
                    153., 155., 157., 159., 161., 163., 165., 167., 169.,
                    171., 173., 175., 177., 179., 181., 183., 185., 187.,
                    189., 191., 193., 195., 197., 199., 201., 203., 205.,
                    207., 209., 211., 213., 215., 217., 219., 221., 223.,
                    225., 227., 229., 231., 233., 235.])
dstlats = numpy.array([-29., -27., -25., -23., -21., -19., -17., -15., -13., -11., -9.,
    -7., -5., -3., -1., 1., 3., 5., 7., 9., 11., 13.,
    15., 17., 19., 21., 23., 25., 27., 29.])

dstgrid = create_grid_corners(dstlons, dstlats)


srcfield = ESMF.Field(srcgrid, "srcfield", staggerloc=ESMF.StaggerLoc.CENTER)
dstfield = ESMF.Field(dstgrid, "dstfield", staggerloc=ESMF.StaggerLoc.CENTER)

srcfield = initialize_field(srcfield)

# Regrid from source grid to destination grid.
regridSrc2Dst = ESMF.Regrid(srcfield, dstfield,
                            regrid_method=ESMF.RegridMethod.CONSERVE,
                            unmapped_action=ESMF.UnmappedAction.ERROR)

dstfield = regridSrc2Dst(srcfield, dstfield, zero_region=ESMF.Region.SELECT)

plot(srclons, srclats, srcfield, dstlons, dstlats, dstfield)



print '\nUVCDAT example completed successfully.\n'