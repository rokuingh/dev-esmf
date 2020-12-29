import ESMF
import numpy as np
import matplotlib.pyplot as plt

mg = ESMF.Manager(debug=True)
print ("Running ESMF version {} with {} processing core(s).".format(ESMF.__version__, mg.pet_count))

 # Two parametric dimensions, and two spatial dimensions
mesh = ESMF.Mesh(parametric_dim=2, spatial_dim=2, coord_sys=ESMF.CoordSys.CART)

num_node = 9
num_elem = 5
nodeId = np.array([11,12,13,21,22,23,31,32,33])
# RLO: these are the "corner" coordinates of a Mesh
nodeCoord = np.array([0.0,0.0,  # node 11
                      2.0,0.0,  # node 12
                      4.0,0.0,  # node 13
                      0.0,2.0,  # node 21
                      2.0,2.0,  # node 22
                      4.0,2.0,  # node 23
                      0.0,4.0,  # node 31
                      2.0,4.0,  # node 32
                      4.0,4.0]) # node 33
nodeOwner = np.zeros(num_node)

elemId = np.array([11,12,21,22,23])
elemType=np.array([ESMF.MeshElemType.QUAD,
                   ESMF.MeshElemType.QUAD,
                   ESMF.MeshElemType.QUAD,
                   ESMF.MeshElemType.TRI,
                   ESMF.MeshElemType.TRI])
elemConn=np.array([0,1,4,3, # element 11
                   1,2,5,4, # element 12
                   3,4,7,6, # element 21
                   4,8,7,   # element 22
                   4,5,8])  # element 23
# RLO: these are the "center" coordinates of a Mesh
elemCoord = np.array([1.0, 1.0,
                      3.0, 1.0,
                      1.0, 3.0,
                      2.5, 3.5,
                      3.5, 2.5])

mesh.add_nodes(num_node,nodeId,nodeCoord,nodeOwner)

mesh.add_elements(num_elem,elemId,elemType,elemConn, element_coords=elemCoord)

# RLO: define the source Field on the centers of the Mesh elements
srcfield = ESMF.Field(mesh,'ID',meshloc=ESMF.MeshLoc.ELEMENT) 
srcfield.data[:] = elemId

x_center = np.linspace(0.5, 3.5, 4)
y_center = np.linspace(0.5, 3.5, 4)
x_corner = np.linspace(0, 4, 5)
y_corner = np.linspace(0, 4, 5)

# RLO: create a Grid allocated with space for both center and corner coordinates
max_index = np.array([len(x_center), len(y_center)])
grid = ESMF.Grid(max_index, staggerloc=[ESMF.StaggerLoc.CENTER, ESMF.StaggerLoc.CORNER], coord_sys=ESMF.CoordSys.CART)

# RLO: access Grid center coordinates
gridXCenter = grid.get_coords(0)
gridYCenter = grid.get_coords(1)

# RLO: set Grid center coordinates as a 2D array (this can also be done 1d)
gridXCenter[...] = x_center.reshape((x_center.size, 1))
gridYCenter[...] = y_center.reshape((1, y_center.size))

# RLO: access Grid corner coordinates
gridXCorner = grid.get_coords(0, staggerloc=ESMF.StaggerLoc.CORNER)
gridYCorner = grid.get_coords(1, staggerloc=ESMF.StaggerLoc.CORNER)

# RLO: set Grid corner coordinats as a 2D array
gridXCorner[...] = x_corner.reshape((x_corner.size, 1))
gridYCorner[...] = y_corner.reshape((1, y_corner.size))

# print (grid)
# import ipdb; ipdb.set_trace()

# RLO: create the destination Field on the centers of the Grid cells
dstfield = ESMF.Field(grid,'ID', staggerloc=ESMF.StaggerLoc.CENTER)

# RLO: create a Regrid object from source Mesh to destination Grid using 1st order conservative method
regrid = ESMF.Regrid(srcfield, dstfield, regrid_method=ESMF.RegridMethod.CONSERVE)

# RLO: apply regrid object to move data from srcfield to dstfield
out = regrid(srcfield, dstfield)

plt.pcolormesh(grid.get_coords(0),grid.get_coords(1),out.data)
plt.show()

