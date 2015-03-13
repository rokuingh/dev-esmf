import ESMF
import numpy as np

def createNormarGrid(normarLons, normarLats, domask):
    '''
    PRECONDITIONS: 'bounds' contains the number of indices required for the
                   two dimensions of a 2D Grid.  'coords' contains the
                   upper and lower coordinate bounds of the Grid.  'domask'
                   is a boolean value that gives the option to put a mask
                   on this Grid.  'doarea' is an option to create user
                   defined areas on this Grid. \n
    POSTCONDITIONS: A 2D Grid has been created.
    RETURN VALUES: \n Grid :: grid \n
    '''
    bounds=[0, 0, len(normarLons),len(normarLats)]
    coords=[min(normarLons), min(normarLats), max(normarLons), max(normarLats)]
    
    lb_x = float(bounds[0])
    lb_y = float(bounds[1])
    ub_x = float(bounds[2])
    ub_y = float(bounds[3])
    
    min_x = float(coords[0])
    min_y = float(coords[1])
    max_x = float(coords[2])
    max_y = float(coords[3])
    
    cellwidth_x = (max_x-min_x)/(ub_x-lb_x)
    cellwidth_y = (max_y-min_y)/(ub_y-lb_y)
    
    cellcenter_x = cellwidth_x/2
    cellcenter_y = cellwidth_y/2
    
    max_index = np.array([ub_x,ub_y])
    print max_index
    
    grid = ESMF.Grid(max_index, coord_sys=ESMF.CoordSys.SPH_DEG)
    
    ##     CORNERS
    grid.add_coords(staggerloc=[ESMF.StaggerLoc.CORNER])
    
    # get the coordinate pointers and set the coordinates
    [x,y] = [0,1]
    gridCorner = grid.coords[ESMF.StaggerLoc.CORNER]
    
    for i in xrange(gridCorner[x].shape[x]):
        gridCorner[x][i, :] = float(i)*cellwidth_x + \
            min_x + grid.lower_bounds[ESMF.StaggerLoc.CORNER][x] * cellwidth_x
            # last line is the pet specific starting point for this stagger and dim
    
    for j in xrange(gridCorner[y].shape[y]):
        gridCorner[y][:, j] = float(j)*cellwidth_y + \
            min_y + grid.lower_bounds[ESMF.StaggerLoc.CORNER][y] * cellwidth_y
            # last line is the pet specific starting point for this stagger and dim
    
    ##     CENTERS
    grid.add_coords(staggerloc=[ESMF.StaggerLoc.CENTER])
    
    # get the coordinate pointers and set the coordinates
    [x,y] = [0,1]
    gridXCenter = grid.get_coords(x, staggerloc=ESMF.StaggerLoc.CENTER)
    gridYCenter = grid.get_coords(y, staggerloc=ESMF.StaggerLoc.CENTER)
    
    for i in xrange(gridXCenter.shape[x]):
        gridXCenter[i, :] = float(i)*cellwidth_x + cellwidth_x/2.0 + \
            min_x + grid.lower_bounds[ESMF.StaggerLoc.CENTER][x] * cellwidth_x
            # last line is the pet specific starting point for this stagger and dim
    
    for j in xrange(gridYCenter.shape[y]):
        gridYCenter[:, j] = float(j)*cellwidth_y + cellwidth_y/2.0 + \
            min_y + grid.lower_bounds[ESMF.StaggerLoc.CENTER][y] * cellwidth_y
            # last line is the pet specific starting point for this stagger and dim
    
    if domask:
        mask = grid.add_item(ESMF.GridItem.MASK)
        mask[:] = 1
        mask[np.where((1.75 <= gridXCenter.data < 2.25) &
                      (1.75 <= gridYCenter.data < 2.25))] = 0
    
    return grid


esmp = ESMF.Manager(logkind=ESMF.LogKind.MULTI, debug=True)


lons=np.arange(-44,75,1)
lats=np.arange(34,86,1)

normargrid = createNormarGrid(lats, lons, domask=False)

esmfgrid = ESMF.Grid(filename="/Users/ryan.okuinghttons/netCDFfiles/grids/T42_grid.nc", 
	filetype=ESMF.FileFormat.SCRIP)

fieldSrc = ESMF.Field(esmfgrid, "fieldSrc", staggerloc=ESMF.StaggerLoc.CENTER)
fieldDst = ESMF.Field(normargrid, "fieldDst", staggerloc=ESMF.StaggerLoc.CENTER)

regridSrc2Dst = ESMF.Regrid(fieldSrc, fieldDst, regrid_method=ESMF.RegridMethod.BILINEAR,
    unmapped_action=ESMF.UnmappedAction.IGNORE)

field = regridSrc2Dst(fieldSrc, fieldDst)

#field = np.fliplr(np.rot90(field,3))
field = np.fliplr(np.rot90(field.data,3))