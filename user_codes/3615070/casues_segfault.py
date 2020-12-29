import ESMF
import numpy as np
import matplotlib.pyplot as plt


def grid_create_from_coordinates(xcoords, ycoords, xcorners=False, ycorners=False, corners=False, domask=False, doarea=False, ctk=ESMF.TypeKind.R8):
    """
    Create a 2 dimensional Grid using the bounds of the x and y coordiantes.
    :param xcoords: The 1st dimension or 'x' coordinates at cell centers, as a Python list or numpy Array
    :param ycoords: The 2nd dimension or 'y' coordinates at cell centers, as a Python list or numpy Array
    :param xcorners: The 1st dimension or 'x' coordinates at cell corners, as a Python list or numpy Array
    :param ycorners: The 2nd dimension or 'y' coordinates at cell corners, as a Python list or numpy Array
    :param domask: boolean to determine whether to set an arbitrary mask or not
    :param doarea: boolean to determine whether to set an arbitrary area values or not
    :param ctk: the coordinate typekind
    :return: grid
    """
    [x, y] = [0, 1]

    # create a grid given the number of grid cells in each dimension, the center stagger location is allocated, the
    # Cartesian coordinate system and type of the coordinates are specified
    max_index = np.array([len(xcoords), len(ycoords)])
    grid = ESMF.Grid(max_index, staggerloc=[ESMF.StaggerLoc.CENTER], coord_sys=ESMF.CoordSys.CART) #, coord_typekind=ctk)

    # set the grid coordinates using numpy arrays, parallel case is handled using grid bounds
    gridXCenter = grid.get_coords(x)
    x_par = xcoords[grid.lower_bounds[ESMF.StaggerLoc.CENTER][x]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][x]]
    gridXCenter[...] = x_par.reshape((x_par.size, 1))

    gridYCenter = grid.get_coords(y)
    y_par = ycoords[grid.lower_bounds[ESMF.StaggerLoc.CENTER][y]:grid.upper_bounds[ESMF.StaggerLoc.CENTER][y]]
    gridYCenter[...] = y_par.reshape((1, y_par.size))


    return grid


mg = ESMF.Manager(debug=True)
print ("Running ESMF version {} with {} processing core(s).".format(ESMF.__version__, mg.pet_count))

mesh = ESMF.Mesh(parametric_dim=2, spatial_dim=2, coord_sys=ESMF.CoordSys.CART)

num_node = 3
num_elem = 1
nodeId = np.array([0,1,2])
nodeCoord = np.array([ 0,0,
                      1,1,
                      2,0])

nodeOwner = np.zeros(num_node)

elemId = np.array([0])
elemType=np.array([ESMF.MeshElemType.TRI])
elemConn=np.array([0,2,1]) 
elemCoord = np.array([0.5,0.5])

mesh.add_nodes(num_node,nodeId,nodeCoord,nodeOwner)

mesh.add_elements(num_elem,elemId,elemType,elemConn, element_coords=elemCoord)
srcfield = ESMF.Field(mesh,'ID',meshloc=ESMF.MeshLoc.ELEMENT) 
srcfield.data[:] = elemId

nodes, elements = (0, 1)
lon, lat = (0, 1)
u, v = (0, 1)

num = int((mesh.coords[0][0].max() - mesh.coords[0][0].min())/0.5)

x = np.linspace(start = mesh.coords[nodes][u].min(), stop = mesh.coords[nodes][u].max(), num=num)
y = np.linspace(start = mesh.coords[nodes][v].min(), stop = mesh.coords[nodes][v].max(),num=num)

grid = grid_create_from_coordinates(x,y)
dstfield = ESMF.Field(grid,'ID2')

# import ipdb; ipdb.set_trace()

regrid = ESMF.Regrid(srcfield, dstfield, regrid_method=ESMF.RegridMethod.NEAREST_DTOS, unmapped_action=ESMF.UnmappedAction.ERROR)
out = regrid(srcfield, dstfield)
plt.pcolormesh(grid.get_coords(0),grid.get_coords(1),out.data)
plt.show()

