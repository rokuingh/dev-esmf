# This is an ESMPy reproducer of uvcdat bug 1125, esmf support request 3613723
import ESMF
import numpy as np

def create_grid_corners(lons, lats, lonbnds, latbnds):
    [lon, lat] = [0, 1]
    max_index = np.array([len(lons), len(lats)])
    grid = ESMF.Grid(max_index,
                     staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER])

    gridXCenter = grid.get_coords(lon)
    lon_par = lons[grid.lower_bounds[ESMF.StaggerLoc.CENTER][lon]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][lon]]
    gridXCenter[...] = lon_par.reshape((lon_par.size, 1))

    gridYCenter = grid.get_coords(lat)
    lat_par = lats[grid.lower_bounds[ESMF.StaggerLoc.CENTER][lat]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][lat]]
    gridYCenter[...] = lat_par.reshape((1, lat_par.size))

    lbx = grid.lower_bounds[ESMF.StaggerLoc.CORNER][lon]
    ubx = grid.upper_bounds[ESMF.StaggerLoc.CORNER][lon]
    lby = grid.lower_bounds[ESMF.StaggerLoc.CORNER][lat]
    uby = grid.upper_bounds[ESMF.StaggerLoc.CORNER][lat]

    gridXCorner = grid.get_coords(lon, staggerloc=ESMF.StaggerLoc.CORNER)
    for i0 in range(ubx - lbx - 1):
        gridXCorner[i0, :] = lonbnds[i0, 0]
    gridXCorner[i0 + 1, :] = lonbnds[i0, 1]

    gridYCorner = grid.get_coords(lat, staggerloc=ESMF.StaggerLoc.CORNER)
    for i1 in range(uby - lby - 1):
        gridYCorner[:, i1] = latbnds[i1, 0]
    gridYCorner[:, i1 + 1] = latbnds[i1, 1]

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
        # transpose because uvcdat data is represented as lat/lon
        field.data[...] = swcre.T
    else:
        field.data[...] = 2.0

    return field

def compute_mass(valuefield, areafield, fracfield, dofrac):
    mass = 0.0
    areafield.get_area()
    if dofrac:
        mass = np.sum(areafield*valuefield*fracfield)
    else:
        mass = np.sum(areafield * valuefield)

    return mass

def plot(srclons, srclats, srcfield, dstlons, dstlats, interpfield):

    try:
        import matplotlib
        import matplotlib.pyplot as plt
    except:
        raise ImportError("matplotlib is not available on this machine")

    fig = plt.figure(1, (15, 6))
    fig.suptitle('ESMPy Conservative Regridding', fontsize=14, fontweight='bold')

    ax = fig.add_subplot(1, 2, 1)
    im = ax.imshow(srcfield.T, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto',
                   extent=[min(srclons), max(srclons), min(srclats), max(srclats)])
    ax.set_xbound(lower=min(srclons), upper=max(srclons))
    ax.set_ybound(lower=min(srclats), upper=max(srclats))
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Source Data")

    ax = fig.add_subplot(1, 2, 2)
    im = ax.imshow(interpfield.T, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto',
                   extent=[min(dstlons), max(dstlons), min(dstlats), max(dstlats)])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Conservative Regrid Solution")

    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.9, 0.1, 0.01, 0.8])
    fig.colorbar(im, cax=cbar_ax)

    plt.show()

##########################################################################################


# Start up ESMF, this call is only necessary to enable debug logging
esmpy = ESMF.Manager(logkind=ESMF.LogKind.MULTI, debug=True)

# Create a destination grid from a GRIDSPEC formatted file.
srcgrid = ESMF.Grid(filename="charles.nc",
                    filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True, is_sphere=False)
try:
    import netCDF4 as nc
except:
    raise ImportError('netCDF4 not available on this machine')

# read longitudes and latitudes from file
f = nc.Dataset('charles.nc')
srclons = f.variables['lon'][:]
srclats = f.variables['lat'][:]
srclonbounds = f.variables['bounds_lon'][:]
srclatbounds = f.variables['bounds_lat'][:]

# original destination centers from charles
# dstlons = numpy.array([135., 137., 139., 141., 143., 145., 147., 149., 151.,
#                     153., 155., 157., 159., 161., 163., 165., 167., 169.,
#                     171., 173., 175., 177., 179., 181., 183., 185., 187.,
#                     189., 191., 193., 195., 197., 199., 201., 203., 205.,
#                     207., 209., 211., 213., 215., 217., 219., 221., 223.,
#                     225., 227., 229., 231., 233., 235.])
# dstlats = numpy.array([-29., -27., -25., -23., -21., -19., -17., -15., -13., -11., -9.,
#     -7., -5., -3., -1., 1., 3., 5., 7., 9., 11., 13.,
# #     15., 17., 19., 21., 23., 25., 27., 29.])
#
# # create data slightly offset for a destination grid
# dstlats = srclats - 0.5
# dstlons = srclons - 0.5
# dstlatbounds = srclatbounds - 0.5
# dstlonbounds = srclonbounds - 0.5
#
# dstgrid = create_grid_corners(dstlons, dstlats, dstlonbounds, dstlatbounds)

# use same grid to avoid boundary errors associated with domain mismatch
dstlats = srclats
dstlons = srclons
dstlatbounds = srclatbounds
dstlonbounds = srclonbounds
dstgrid = ESMF.Grid(filename="charles.nc",
                    filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True, is_sphere=False)

srcfield = ESMF.Field(srcgrid, "srcfield", staggerloc=ESMF.StaggerLoc.CENTER)
dstfield = ESMF.Field(dstgrid, "dstfield", staggerloc=ESMF.StaggerLoc.CENTER)
srcareafield = ESMF.Field(srcgrid, "srcfield", staggerloc=ESMF.StaggerLoc.CENTER)
dstareafield = ESMF.Field(dstgrid, "dstfield", staggerloc=ESMF.StaggerLoc.CENTER)
srcfracfield = ESMF.Field(srcgrid, "srcfield", staggerloc=ESMF.StaggerLoc.CENTER)
dstfracfield = ESMF.Field(dstgrid, "dstfield", staggerloc=ESMF.StaggerLoc.CENTER)

srcfield = initialize_field(srcfield)

# Regrid from source grid to destination grid.
regridSrc2Dst = ESMF.Regrid(srcfield, dstfield,
                            regrid_method=ESMF.RegridMethod.CONSERVE,
                            unmapped_action=ESMF.UnmappedAction.ERROR,
                            src_frac_field=srcfracfield,
                            dst_frac_field=dstfracfield)

dstfield = regridSrc2Dst(srcfield, dstfield)

srcmass = compute_mass(srcfield, srcareafield, srcfracfield, True)
dstmass = compute_mass(dstfield, dstareafield, 0, False)

print "Conservative error = {}".format(abs(srcmass-dstmass)/abs(srcmass))

plot(srclons, srclats, srcfield, dstlons, dstlats, dstfield)

print '\nUVCDAT example completed successfully.\n'