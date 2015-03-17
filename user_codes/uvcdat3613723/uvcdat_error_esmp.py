# This is an ESMP reproducer of uvcdat bug 1125, esmf support request 3613723
import ESMP
import numpy as np

def make_index( nx, ny ):
    return np.arange( nx*ny ).reshape( ny, nx )

def create_grid(lons, lats, lonbnds, latbnds):

    maxIndex = np.array([len(lons), len(lats)], dtype=np.int32)

    grid = ESMP.ESMP_GridCreateNoPeriDim(maxIndex)

    ##   CENTERS
    ESMP.ESMP_GridAddCoord(grid, staggerloc=ESMP.ESMP_STAGGERLOC_CENTER)

    exLB_center, exUB_center = ESMP.ESMP_GridGetCoord(grid,
                                                      ESMP.ESMP_STAGGERLOC_CENTER)

    # get the coordinate pointers and set the coordinates
    [x, y] = [0, 1]
    gridXCenter = ESMP.ESMP_GridGetCoordPtr(grid, x, ESMP.ESMP_STAGGERLOC_CENTER)
    gridYCenter = ESMP.ESMP_GridGetCoordPtr(grid, y, ESMP.ESMP_STAGGERLOC_CENTER)

    # make an array that holds indices from lower_bounds to upper_bounds
    bnd2indX = np.arange(exLB_center[x], exUB_center[x], 1)
    bnd2indY = np.arange(exLB_center[y], exUB_center[y], 1)

    pts = make_index(exUB_center[x] - exLB_center[x],
                     exUB_center[y] - exLB_center[y])

    for i0 in range(len(bnd2indX)):
        gridXCenter[pts[:, i0]] = lons[i0]

    for i1 in range(len(bnd2indY)):
        gridYCenter[pts[i1, :]] = lats[i1]

    ##   CORNERS
    ESMP.ESMP_GridAddCoord(grid, staggerloc=ESMP.ESMP_STAGGERLOC_CORNER)

    exLB_corner, exUB_corner = ESMP.ESMP_GridGetCoord(grid, ESMP.ESMP_STAGGERLOC_CORNER)

    # get the coordinate pointers and set the coordinates
    [x,y] = [0, 1]
    gridXCorner = ESMP.ESMP_GridGetCoordPtr(grid, x, ESMP.ESMP_STAGGERLOC_CORNER)
    gridYCorner = ESMP.ESMP_GridGetCoordPtr(grid, y, ESMP.ESMP_STAGGERLOC_CORNER)

    # make an array that holds indices from lower_bounds to upper_bounds
    bnd2indX = np.arange(exLB_corner[x], exUB_corner[x], 1)
    bnd2indY = np.arange(exLB_corner[y], exUB_corner[y], 1)

    pts = make_index(exUB_corner[x] - exLB_corner[x],
                     exUB_corner[y] - exLB_corner[y])

    for i0 in range(len(bnd2indX)-1):
        gridXCorner[pts[:, i0]] = lonbnds[i0, 0]
    gridXCorner[pts[:, i0+1]] = lonbnds[i0, 1]

    for i1 in range(len(bnd2indY)-1):
        gridYCorner[pts[i1, :]] = latbnds[i1, 0]
    gridYCorner[pts[i1+1, :]] = latbnds[i1, 1]

    return grid

def build_analyticfield(field, grid):
    # get the field pointer
    fieldPtr = ESMP.ESMP_FieldGetPtr(field)

    # get the grid bounds and coordinate pointers
    exLB, exUB = ESMP.ESMP_GridGetCoord(grid, ESMP.ESMP_STAGGERLOC_CENTER)

    # make an array that holds indices from lower_bounds to upper_bounds
    [x,y] = [0, 1]
    bnd2indX = np.arange(exLB[x], exUB[x], 1)
    bnd2indY = np.arange(exLB[y], exUB[y], 1)

    realdata = False
    try:
        import netCDF4 as nc
        f = nc.Dataset('charles.nc')
        swcre = f.variables['swcre']
        swcre = swcre[:]
        realdata = True
    except:
        raise ImportError('netCDF4 not available on this machine')

    p = 0
    for i1 in range(len(bnd2indX)):
        for i0 in range(len(bnd2indY)):
            if realdata:
                fieldPtr[p] = swcre.flatten()[p]
            else:
                fieldPtr[p] = 2.0
            p = p + 1

    return field

def compute_mass(valuefield, areafield, fracfield, dofrac):
    mass = 0.0
    ESMP.ESMP_FieldRegridGetArea(areafield)
    area = ESMP.ESMP_FieldGetPtr(areafield)
    value = ESMP.ESMP_FieldGetPtr(valuefield)
    frac = 0
    if dofrac:
        frac = ESMP.ESMP_FieldGetPtr(fracfield)
    for i in range(valuefield.size):
        if dofrac:
            mass += area[i]*value[i]*frac[i]
        else:
            mass += area[i]*value[i]

    return mass


def plot(srclons, srclats, srcfield, dstlons, dstlats, interpfield):

    try:
        import matplotlib
        import matplotlib.pyplot as plt
    except:
        raise ImportError("matplotlib is not available on this machine")

    exact = ESMP.ESMP_FieldGetPtr(srcfield)
    exact = exact.reshape(len(srclats.flatten()), len(srclons.flatten()))

    interp = ESMP.ESMP_FieldGetPtr(interpfield)
    interp = interp.reshape(len(dstlats.flatten()), len(dstlons.flatten()))

    fig = plt.figure(1, (15, 6))
    fig.suptitle('ESMP Conservative Regridding', fontsize=14, fontweight='bold')

    ax = fig.add_subplot(1, 2, 1)
    im = ax.imshow(exact, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto',
                   extent=[min(srclons), max(srclons), min(srclats), max(srclats)])
    ax.set_xbound(lower=min(srclons), upper=max(srclons))
    ax.set_ybound(lower=min(srclats), upper=max(srclats))
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Source Data")

    ax = fig.add_subplot(1, 2, 2)
    im = ax.imshow(interp, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto',
                   extent=[min(dstlons), max(dstlons), min(dstlats), max(dstlats)])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Conservative Regrid Solution")

    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.9, 0.1, 0.01, 0.8])
    fig.colorbar(im, cax=cbar_ax)

    plt.show()

##########################################################################################


# start up ESMF
ESMP.ESMP_Initialize()
ESMP.ESMP_LogSet(True)

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

srcgrid = create_grid(srclons, srclats, srclonbounds, srclatbounds)

# original destination centers from charles
# dstlons = np.array([135., 137., 139., 141., 143., 145., 147., 149., 151.,
#                     153., 155., 157., 159., 161., 163., 165., 167., 169.,
#                     171., 173., 175., 177., 179., 181., 183., 185., 187.,
#                     189., 191., 193., 195., 197., 199., 201., 203., 205.,
#                     207., 209., 211., 213., 215., 217., 219., 221., 223.,
#                     225., 227., 229., 231., 233., 235.])
# dstlats = np.array([-29., -27., -25., -23., -21., -19., -17., -15., -13., -11., -9.,
#     -7., -5., -3., -1., 1., 3., 5., 7., 9., 11., 13.,
#     15., 17., 19., 21., 23., 25., 27., 29.])
#
# # create data slightly offset for a destination grid
# dstlats = srclats - 0.5
# dstlons = srclons - 0.5
# dstlatbounds = srclatbounds - 0.5
# dstlonbounds = srclonbounds - 0.5

# use same grid to avoid boundary errors associated with domain mismatch
dstlats = srclats
dstlons = srclons
dstlatbounds = srclatbounds
dstlonbounds = srclonbounds
dstgrid = create_grid(dstlons, dstlats, dstlonbounds, dstlatbounds)

# create the Fields
srcfield = ESMP.ESMP_FieldCreateGrid(srcgrid, 'srcfield')
dstfield = ESMP.ESMP_FieldCreateGrid(dstgrid, 'dstfield')

# create the area fields
srcareafield = ESMP.ESMP_FieldCreateGrid(srcgrid, 'srcfracfield')
dstareafield = ESMP.ESMP_FieldCreateGrid(dstgrid, 'dstfracfield')

# create the fraction fields
srcfracfield = ESMP.ESMP_FieldCreateGrid(srcgrid, 'srcfracfield')
dstfracfield = ESMP.ESMP_FieldCreateGrid(dstgrid, 'dstfracfield')

# initialize the Fields to an analytic function
srcfield = build_analyticfield(srcfield, srcgrid)

# run the ESMF regridding
routehandle = ESMP.ESMP_FieldRegridStore(srcfield, dstfield,
                   regridmethod=ESMP.ESMP_REGRIDMETHOD_CONSERVE,
                   unmappedaction=ESMP.ESMP_UNMAPPEDACTION_ERROR,
                   srcFracField=srcfracfield,
                   dstFracField=dstfracfield)
ESMP.ESMP_FieldRegrid(srcfield, dstfield, routehandle)
ESMP.ESMP_FieldRegridRelease(routehandle)

# compute the mass
srcmass = compute_mass(srcfield, srcareafield, srcfracfield, True)
dstmass = compute_mass(dstfield, dstareafield, 0, False)

print "Conservative error = {}".format(abs(srcmass-dstmass)/abs(srcmass))

plot(srclons, srclats, srcfield, dstlons, dstlats, dstfield)

# clean up
ESMP.ESMP_FieldDestroy(srcfield)
ESMP.ESMP_FieldDestroy(dstfield)
ESMP.ESMP_FieldDestroy(srcfracfield)
ESMP.ESMP_FieldDestroy(dstfracfield)
ESMP.ESMP_GridDestroy(srcgrid)
ESMP.ESMP_GridDestroy(dstgrid)

# stop ESMF
ESMP.ESMP_Finalize()

print '\nUVCDAT example completed successfully.\n'