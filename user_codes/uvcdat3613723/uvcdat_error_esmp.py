# This is a reproducer of bug 1125 from uvcdat
import ESMP
import numpy as np

# def create_grid(lons, lats, coordtk=ESMF.TypeKind.R8):
#     max_index = numpy.array([lons.size, lats.size])
#     grid = ESMF.Grid(max_index, coord_sys=ESMF.CoordSys.SPH_DEG, coord_typekind=coordtk)
#     # Add coordinates to the source grid.
#     grid.add_coords(staggerloc=[ESMF.StaggerLoc.CENTER])
# 
#     # Get and set the source grid coordinates.
#     gridCoordLat = grid.get_coords(lat)
#     gridCoordLon = grid.get_coords(lon)
# 
#     lons_par = lons[grid.lower_bounds[ESMF.StaggerLoc.CENTER][0]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][0]]
#     lats_par = lats[grid.lower_bounds[ESMF.StaggerLoc.CENTER][1]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][1]]
# 
#     gridCoordLat[...] = lats_par.reshape(1, lats_par.size)
#     gridCoordLon[...] = lons_par.reshape(lons_par.size, 1)
# 
#     return grid
# 
# 
# def create_grid_corners(lons, lats, coordtk=ESMF.TypeKind.R8):
#     grid = ESMF.Grid(numpy.array([lons.size-1, lats.size-1], 'int32'),
#                      staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER],
#                      coord_typekind=coordtk)
# 
#     gridXCorner = grid.get_coords(lon, staggerloc=ESMF.StaggerLoc.CORNER)
#     lon_par = lons[grid.lower_bounds[ESMF.StaggerLoc.CORNER][lon]:grid.upper_bounds[ESMF.StaggerLoc.CORNER][lon]]
#     gridXCorner[...] = lon_par.reshape((lon_par.size, 1))
# 
#     gridYCorner = grid.get_coords(lat, staggerloc=ESMF.StaggerLoc.CORNER)
#     lat_par = lats[grid.lower_bounds[ESMF.StaggerLoc.CORNER][lat]:grid.upper_bounds[ESMF.StaggerLoc.CORNER][lat]]
#     gridYCorner[...] = lat_par.reshape((1, lat_par.size))
# 
#     offset_lon = (lons[1]-lons[0])/2.
#     lons -= offset_lon
#     gridXCenter = grid.get_coords(lon)
#     lon_par = lons[grid.lower_bounds[ESMF.StaggerLoc.CENTER][lon]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][lon]]
#     gridXCenter[...] = lon_par.reshape((lon_par.size, 1))
# 
#     offset_lat = (lons[1]-lons[0])/2.
#     lats -= offset_lat
#     gridYCenter = grid.get_coords(lat)
#     lat_par = lats[grid.lower_bounds[ESMF.StaggerLoc.CENTER][lat]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][lat]]
#     gridYCenter[...] = lat_par.reshape((1, lat_par.size))
# 
#     return grid

def make_index( nx, ny ):
    return np.arange( nx*ny ).reshape( ny, nx )

def create_grid(lons, lats):
    nx = len(lons.flatten())
    ny = len(lats.flatten())-1

    maxIndex = np.array([nx,ny], dtype=np.int32)

    grid = ESMP.ESMP_GridCreate1PeriDim(maxIndex)

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

    assert((exUB_corner[x]-exLB_corner[x]) == nx)
    for i0 in range(len(bnd2indX)):
        gridXCorner[pts[:, i0]] = lons[i0]

    assert((exUB_corner[y]-exLB_corner[y]) == ny+1)
    for i1 in range(len(bnd2indY)):
        gridYCorner[pts[i1, :]] = lats[i1]

    ##   CENTERS
    offset_lon = (lons[1] - lons[0]) / 2.
    lons -= offset_lon
    offset_lat = (lons[1] - lons[0]) / 2.
    lats -= offset_lat

    ESMP.ESMP_GridAddCoord(grid, staggerloc=ESMP.ESMP_STAGGERLOC_CENTER)

    exLB_center, exUB_center = ESMP.ESMP_GridGetCoord(grid,
                                         ESMP.ESMP_STAGGERLOC_CENTER)

    # get the coordinate pointers and set the coordinates
    [x,y] = [0, 1]
    gridXCenter = ESMP.ESMP_GridGetCoordPtr(grid, x, ESMP.ESMP_STAGGERLOC_CENTER)
    gridYCenter = ESMP.ESMP_GridGetCoordPtr(grid, y, ESMP.ESMP_STAGGERLOC_CENTER)

    # make an array that holds indices from lower_bounds to upper_bounds
    bnd2indX = np.arange(exLB_center[x], exUB_center[x], 1)
    bnd2indY = np.arange(exLB_center[y], exUB_center[y], 1)

    pts = make_index( exUB_center[x] - exLB_center[x],
                      exUB_center[y] - exLB_center[y] )

    for i0 in range(len(bnd2indX)):
        gridXCenter[ pts[:,i0] ] = lons[i0]

    for i1 in range(len(bnd2indY)):
        gridYCenter[ pts[i1,:] ] = lats[i1]

    return grid

def create_field(grid, name):
    # defaults to center staggerloc
    field = ESMP.ESMP_FieldCreateGrid(grid, name)

    return field

def build_analyticfield(field, grid):
    import math

    # get the field pointer
    fieldPtr = ESMP.ESMP_FieldGetPtr(field)

    # get the grid bounds and coordinate pointers
    exLB, exUB = ESMP.ESMP_GridGetCoord(grid, ESMP.ESMP_STAGGERLOC_CENTER)

    # make an array that holds indices from lower_bounds to upper_bounds
    [x,y] = [0, 1]
    bnd2indX = np.arange(exLB[x], exUB[x], 1)
    bnd2indY = np.arange(exLB[y], exUB[y], 1)

    # get the coordinate pointers and set the coordinates
    [x,y] = [0, 1]
    gridXCoord = ESMP.ESMP_GridGetCoordPtr(grid, x, ESMP.ESMP_STAGGERLOC_CENTER)
    gridYCoord = ESMP.ESMP_GridGetCoordPtr(grid, y, ESMP.ESMP_STAGGERLOC_CENTER)

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
            theta = gridXCoord[p]
            phi = gridYCoord[p]
            if realdata:
                fieldPtr[p] = swcre.flatten()[p]
            else:
                #fieldPtr[p] = 2.0 + math.cos(theta)**2 * math.cos(2.0*phi)
                fieldPtr[p] = 2.0
            p = p + 1

    return field

def run_regridding(srcfield, dstfield, srcfracfield, dstfracfield):
    routehandle = ESMP.ESMP_FieldRegridStore(srcfield, dstfield,
                                 regridmethod=ESMP.ESMP_REGRIDMETHOD_CONSERVE,
                                 unmappedaction=ESMP.ESMP_UNMAPPEDACTION_ERROR,
                                 srcFracField=srcfracfield,
                                 dstFracField=dstfracfield)
    ESMP.ESMP_FieldRegrid(srcfield, dstfield, routehandle)
    ESMP.ESMP_FieldRegridRelease(routehandle)

    return dstfield, srcfracfield, dstfracfield

def compare_fields(interp_field, exact_field, dstfracfield, srcmass, dstmass, parallel):
    vm = ESMP.ESMP_VMGetGlobal()
    localPet, _ = ESMP.ESMP_VMGet(vm)

    # get the data pointers for the fields
    interp = ESMP.ESMP_FieldGetPtr(interp_field)
    exact = ESMP.ESMP_FieldGetPtr(exact_field)
    dstfrac = ESMP.ESMP_FieldGetPtr(dstfracfield)

    if (interp_field.size != exact_field.size):
      raise TypeError('compare_fields: Fields must be the same size!')

    # initialize to True, and check for False point values
    total_error = 0.0
    max_error = 0.0
    min_error = 1000000.0
    for i in range(interp_field.size):
        if (exact[i] != 0.0):
            err = abs(interp[i]/dstfrac[i] - exact[i])/abs(exact[i])
        else:
            err = abs(interp[i]/dstfrac[i] - exact[i])
        total_error = total_error + err
        if (err > max_error):
            max_error = err
        if (err < min_error):
            min_error = err
    
    if parallel:
        # use mpi4py to collect values
        from mpi4py import MPI

        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()

        max_error_global = comm.reduce(max_error, op=MPI.MAX)
        min_error_global = comm.reduce(min_error, op=MPI.MIN)
        total_error_global = comm.reduce(total_error, op=MPI.SUM)
        srcmass_global = comm.reduce(srcmass, op=MPI.SUM)
        dstmass_global = comm.reduce(dstmass, op=MPI.SUM)

        if rank == 0:
            # check the mass
            csrv = False
            csrv_error = abs(dstmass_global - srcmass_global)/srcmass_global
            if (csrv_error < 10e-12):
                csrv = True
            itrp = False
            if (max_error_global < 10E-2):
                itrp = True

            if (itrp and csrv):
                print "PASS"
            else:
                print "FAIL"
            print "       Total error = "+str(total_error_global)
            print "       Max error   = "+str(max_error_global)
            print "       Min error   = "+str(min_error_global)
            print "       Csrv error  = "+str(csrv_error)
            print "       srcmass     = "+str(srcmass_global)
            print "       dstmass     = "+str(dstmass_global)
    else:
        # check the mass
        csrv = False
        csrv_error = abs(dstmass - srcmass)/srcmass
        if (csrv_error < 10e-12):
            csrv = True
        itrp = False
        if (max_error < 10E-2):
            itrp = True

        if (itrp and csrv):
            print "PASS"
        else:
            print "FAIL"
        print "       Total error = "+str(total_error)
        print "       Max error   = "+str(max_error)
        print "       Min error   = "+str(min_error)
        print "       Csrv error  = "+str(csrv_error)
        print "       srcmass     = "+str(srcmass)
        print "       dstmass     = "+str(dstmass)

    return

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
    exact = exact.reshape(len(srclats.flatten()) - 1, len(srclons.flatten()))

    interp = ESMP.ESMP_FieldGetPtr(interpfield)
    interp = interp.reshape(len(dstlats.flatten()) - 1, len(dstlons.flatten()))

    fig = plt.figure(1, (15,4))

    ax = fig.add_subplot(1,2,1)
    im = ax.imshow(exact, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto')

    ax = fig.add_subplot(1,2,2)
    im = ax.imshow(interp, vmin=-140, vmax=0, cmap='gist_ncar', aspect='auto')

    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.85, 0.15, 0.05, 0.7])
    fig.colorbar(im, cax=cbar_ax)

    plt.show()



##########################################################################################


# start up ESMF
ESMP.ESMP_Initialize()
ESMP.ESMP_LogSet(True)

vm = ESMP.ESMP_VMGetGlobal()
localPet, petCount = ESMP.ESMP_VMGet(vm)

parallel = False
if petCount > 1:
    if petCount != 4:
        raise NameError('PET count must be 4 in parallel mode!')
    parallel = True

# we are testing with real data
analytic=False

srclons = np.array([135.5, 136.5, 137.5, 138.5, 139.5, 140.5, 141.5, 142.5, 143.5, 144.5,
    145.5, 146.5, 147.5, 148.5, 149.5, 150.5, 151.5, 152.5, 153.5, 154.5,
    155.5, 156.5, 157.5, 158.5, 159.5, 160.5, 161.5, 162.5, 163.5, 164.5,
    165.5, 166.5, 167.5, 168.5, 169.5, 170.5, 171.5, 172.5, 173.5, 174.5,
    175.5, 176.5, 177.5, 178.5, 179.5, 180.5, 181.5, 182.5, 183.5, 184.5,
    185.5, 186.5, 187.5, 188.5, 189.5, 190.5, 191.5, 192.5, 193.5, 194.5,
    195.5, 196.5, 197.5, 198.5, 199.5, 200.5, 201.5, 202.5, 203.5, 204.5,
    205.5, 206.5, 207.5, 208.5, 209.5, 210.5, 211.5, 212.5, 213.5, 214.5,
    215.5, 216.5, 217.5, 218.5, 219.5, 220.5, 221.5, 222.5, 223.5, 224.5,
    225.5, 226.5, 227.5, 228.5, 229.5, 230.5, 231.5, 232.5, 233.5, 234.5])
srclats = np.array([-29.5, -28.5, -27.5, -26.5, -25.5, -24.5, -23.5, -22.5, -21.5, -20.5,
    -19.5, -18.5, -17.5, -16.5, -15.5, -14.5, -13.5, -12.5, -11.5, -10.5,
    -9.5, -8.5, -7.5, -6.5, -5.5, -4.5, -3.5, -2.5, -1.5, -0.5, 0.5, 1.5,
    2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5, 13.5, 14.5,
    15.5, 16.5, 17.5, 18.5, 19.5, 20.5, 21.5, 22.5, 23.5, 24.5, 25.5, 26.5,
    27.5, 28.5, 29.5])

srcgrid = create_grid(srclons, srclats)

dstlons = np.array([135., 137., 139., 141., 143., 145., 147., 149., 151.,
                    153., 155., 157., 159., 161., 163., 165., 167., 169.,
                    171., 173., 175., 177., 179., 181., 183., 185., 187.,
                    189., 191., 193., 195., 197., 199., 201., 203., 205.,
                    207., 209., 211., 213., 215., 217., 219., 221., 223.,
                    225., 227., 229., 231., 233., 235.])
dstlats = np.array([-29., -27., -25., -23., -21., -19., -17., -15., -13., -11., -9.,
    -7., -5., -3., -1., 1., 3., 5., 7., 9., 11., 13.,
    15., 17., 19., 21., 23., 25., 27., 29.])

dstgrid = create_grid(dstlons, dstlats)

# create the Fields
srcfield = create_field(srcgrid, 'srcfield')
dstfield = create_field(dstgrid, 'dstfield')
if analytic:
    exact_field = create_field(dstgrid, 'dstfield_exact')

# create the area fields
srcareafield = create_field(srcgrid, 'srcfracfield')
dstareafield = create_field(dstgrid, 'dstfracfield')

# create the fraction fields
srcfracfield = create_field(srcgrid, 'srcfracfield')
dstfracfield = create_field(dstgrid, 'dstfracfield')

# initialize the Fields to an analytic function
srcfield = build_analyticfield(srcfield, srcgrid)
if analytic:
    exact_field = build_analyticfield(exact_field, dstgrid)

# run the ESMF regridding
dstfield, srcfracfield, dstfracfield = run_regridding(srcfield, dstfield,
                                                      srcfracfield, dstfracfield)

# compute the mass
srcmass = compute_mass(srcfield, srcareafield, srcfracfield, True)
dstmass = compute_mass(dstfield, dstareafield, 0, False)

# compare results and output PASS or FAIL
if analytic:
    compare_fields(dstfield, exact_field, dstfracfield, srcmass, dstmass, parallel)

plot(srclons, srclats, srcfield, dstlons, dstlats, dstfield)

# clean up
ESMP.ESMP_FieldDestroy(srcfield)
ESMP.ESMP_FieldDestroy(dstfield)
if analytic:
    ESMP.ESMP_FieldDestroy(exact_field)
ESMP.ESMP_FieldDestroy(srcfracfield)
ESMP.ESMP_FieldDestroy(dstfracfield)
ESMP.ESMP_GridDestroy(srcgrid)
ESMP.ESMP_GridDestroy(dstgrid)

# stop ESMF
ESMP.ESMP_Finalize()

print '\nUVCDAT example completed successfully.\n'