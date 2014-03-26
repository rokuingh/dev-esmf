#ifndef ESMCI_MeshObjTopo_h
#define ESMCI_MeshObjTopo_h

#include <Mesh/include/ESMCI_MeshTypes.h>
#include <Mesh/include/ESMCI_Exception.h>


#include <string>
#include <vector>

namespace ESMCI {

// Get the topo instance
class MeshObjTopo;
MeshObjTopo *GetTopo(const std::string &type);

// Get a topo from a marshalled int.
MeshObjTopo *GetTopo(UInt);
MeshObjTopo *ManufactureTopo(const std::string &type);

// Return a lower order topology; linear from quadratic
MeshObjTopo *LowerTopo(const MeshObjTopo &topo);

/**
 * Switch a shell topo for its pdim=sdim version
 */
const MeshObjTopo *FlattenTopo(const MeshObjTopo &topo);

/**
 * The basic connection pattern within a mesh database.  Describes
 * how a high level topological object (face, cell) relates to other
 * objects in the mesh.
 * 
 * <ul>
 * 
 * <li> Hexahedron topology:
 * @verbatim
 *                       18
 *            7 o--------*--------o 6
 *             /|                /|
 *          19* |            17 * |                       ^  Z
 *           /  |              /  |                       |
 *         4/   |  16         /   |                       |  7  Y
 *         o--------*--------o 5  * 14                    | /
 *         |    *15          |    |                       |/
 *         |    |            |    |                       o----------> X
 *         |    |            |    |                      
 *         |    | 3     10   |13  |                     
 *      12 *    o--------*---*----o 2                  
 *         |   /             |   / 
 *         |11*              |  *9  
 *         | /               | /
 *         |/                |/    
 *         o-------*---------o
 *         0       8         1
 * 
 * Nodes 20-26 are in the center and center of faces:
 * 
 * 
 *                 o22
 *                 |  o26
 *                 | /
 *        23       |/
 *         o-------o-------o24
 *                /| 20
 *               / |
 *              o  |
 *             25  o21
 *            
 *       Face 0               Face 1
 *       4     e4    5        5     e5    6
 *       o----->-----o        o----->-----o
 *       |           |        |           |    
 *       |           |        |           |       
 *    e8 ^           ^ e9  e9 ^           ^ e10
 *       |           |        |           |        
 *       |           |        |           |    
 *       o----->-----o        o----->-----o
 *       0    e0     1        1    e1     2
 *
 *       Face 2               Face 3
 *       6     e6    7        3     e11   7
 *       o----->-----o        o----->-----o
 *       |           |        |           |    
 *       |           |        |           |       
 *    e10^           ^ e11 e3 v           v e7
 *       |           |        |           |        
 *       |           |        |           |    
 *       o----->-----o        o----->-----o
 *       2    e2     3        0    e8     4
 *
 *       Face 4               Face 5
 *       1     e1    2        7     e6    6
 *       o----->-----o        o-----<-----o
 *       |           |        |           |    
 *       |           |        |           |       
 *    e0 v           v e2  e7 v           ^ e5
 *       |           |        |           |        
 *       |           |        |           |    
 *       o-----<-----o        o----->-----o
 *       0    e3     3        4    e4     5
 *
 * @endverbatim
 * 
 * <li> Quadratic topology:
 * @verbatim
 * 
 * Nodes (*= child node)
 *                       
 *       3    6     2
 *       o-----*-----o
 *       |           |    
 *       |           |       
 *     7 *    8*     * 5      
 *       |           |        
 *       |           |    
 *       o-----*-----o
 *       0     4     1
 *                     
 * @endverbatim
 *   
 * <li> Triangle topology:
 * @verbatim
 * Nodes:(*=child node)
 *              2
 *              o
 *             / \
 *            /   \
 *           /     \
 *        5 *       * 4      
 *         /         \
 *        /           \
 *       /             \
 *      o-------*-------o
 *      0       3       1 
 * @endverbatim
 * 
 * <li> Tetrahedron topology:
 * @verbatim
 *         
 *            o 3
 *           /|\
 *        7 * | * 9
 *         /  |6 \
 *      o o- -*- -o 2
 *         \  |8 /
 *        4 * | * 5
 *           \|/
 *            o
 *            1
 *@endverbatim
 *
 * <li> Bar topology:
 * @verbatim
 * 
 *   o-----*-----o 
 *   0     2     1
 * 
 * @endverbatim
 * </ul>           
 *
 * Permutations:
 * Various faces have permutation tables.  The idea is that if a face
 * has rot=r, pol=p wrt to me, I can acces the true node i by
 * topo->perm_table(r,p)[i].
 *
 * Quadrilateral:
 * @verbatim
 *
 *       Rot=0, pol=true     Rot=0, pol=false
 *       3     6     2        0     4     1
 *       o-----*-----o        o-----*-----o
 *       |           |        |           |    
 *       |           |        |           |       
 *     7 *           * 5    7 *           * 5   
 *       |           |        |           |        
 *       |           |        |           |    
 *       o-----*-----o        o-----*-----o
 *       0     4     1        3     6     2
 *
 *       Rot=1, pol=true     Rot=1, pol=false
 *       2     5     1        1     5     2
 *       o-----*-----o        o-----*-----o
 *       |           |        |           |    
 *       |           |        |           |       
 *     6 *           * 4    4 *           * 6   
 *       |           |        |           |        
 *       |           |        |           |    
 *       o-----*-----o        o-----*-----o
 *       3     7     0        0     7     3
 *
 *       Rot=2, pol=true     Rot=2, pol=false
 *       1     4     0        2     6     3
 *       o-----*-----o        o-----*-----o
 *       |           |        |           |    
 *       |           |        |           |       
 *     5 *           * 7    5 *           * 7   
 *       |           |        |           |        
 *       |           |        |           |    
 *       o-----*-----o        o-----*-----o
 *       2     6     3        1     4     0
 *
 *       Rot=3, pol=true     Rot=3, pol=false
 *       0     7     3        3     7     0
 *       o-----*-----o        o-----*-----o
 *       |           |        |           |    
 *       |           |        |           |       
 *     4 *           * 6    6 *           * 4   
 *       |           |        |           |        
 *       |           |        |           |    
 *       o-----*-----o        o-----*-----o
 *       1     5     2        2     5     1
 *
 * @endverbatim
 *
 * Triangular permutations:
 * @verbatim
 *
 *       Rot=0, pol=true         Rot=0, pol =false
 *              2                         0
 *              o                         o
 *             / \                       / \
 *            /   \                     /   \
 *           /     \                   /     \
 *        5 *       * 4             5 *       * 3      
 *         /         \               /         \
 *        /           \             /           \
 *       /             \           /             \
 *      o-------*-------o         o-------*-------o
 *      0       3       1         2       4       1 
 *
 *       Rot=1, pol=true         Rot=1, pol =false
 *              1                         1
 *              o                         o
 *             / \                       / \
 *            /   \                     /   \
 *           /     \                   /     \
 *        4 *       * 3             3 *       * 4      
 *         /         \               /         \
 *        /           \             /           \
 *       /             \           /             \
 *      o-------*-------o         o-------*-------o
 *      2       5       0         0       5       2 
 *
 *       Rot=2, pol=true         Rot=2, pol =false
 *              0                         2
 *              o                         o
 *             / \                       / \
 *            /   \                     /   \
 *           /     \                   /     \
 *        3 *       * 5             5 *       * 4      
 *         /         \               /         \
 *        /           \             /           \
 *       /             \           /             \
 *      o-------*-------o         o-------*-------o
 *      1       4       2         1       3       0 
 *
 * @endverbatim
 * 
 * Parametric coordinates and parametric coordinate mappings are
 * also included in this object.
 *
 * This object can be modified to incorporate no homogenous topologies,
 * but this will require modifying some assumptions, namely that sides
 * have the same number of nodes, edges, etc...
 *
 *
 * There is a peculiar problem concerning interior edges in 3d.  Such edges have
 * no parents.  This can be a problem when a face is constrained (one side refined
 * the other not) and split across a processor boundary.  These edges on the 
 * constrained processor have no elements that USES them, and since they do not have
 * parents, they are isolated from the mesh and cannot be found via the standard
 * relations.  We cure this by letting the parent face FOSTERS these edges.
 * 
 *
 *  Quadrilateral fostered edges
 *       3       6       2  
 *       o-------*-------o 
 *       |       |fe2    |  
 *       |       v       |  
 *       | fe3   |  fe1  | 
 *     7 *-->--- *---<---* 5  
 *       |       |8      |   
 *       |       ^fe0    |  
 *       |       |       |  
 *       o-------*-------o 
 *       0     4     1 
 * 
 *   Trianglular fostered edges
 *
 *              2
 *              o
 *             / \
 *            /   \
 *           / fe2 \
 *        5 *---<---* 4      
 *         / \    /  \
 *        /   V  ^    \
 *       / fe0 \/ fe1  \
 *      o-------*-------o
 *      0       3       1 
 * @ingroup meshdatabase
 * 
 */
class MeshObjTopo {
public:
 typedef UInt global_identifier;

 friend MeshObjTopo *GetTopo(const std::string&);
 friend MeshObjTopo *ManufactureTopo(const std::string&);
 friend void AddHomoSide(MeshObjTopo *topo, std::string side_name);
 friend void AddHomoEdge(MeshObjTopo *topo, std::string edge_name);

 MeshObjTopo(const std::string &a_name,
             global_identifier a_number,
             int a_num_vertices,
             int a_num_nodes,
             int a_num_sides,
             int a_spatial_dim,
             int a_parametric_dim) :
 name(a_name), number(a_number), num_vertices(a_num_vertices), num_nodes(a_num_nodes), num_sides(a_num_sides),
   spatial_dim(a_spatial_dim), parametric_dim(a_parametric_dim),
   num_fostered_edges(0), face_edge_map(0), face_edge_pol(0), fostered_edge_nodes(0) {}

 /**
  * Return the map for how the side topology's nodes map to the element
  * nodes.
  */
 const int *get_side_nodes(int side) const {return &side_node_map[num_side_child_nodes*side];}

 /**
  * Return a map relating how edge nodes map to the element node numbering.
  */
 const int *get_edge_nodes(int edge) const {return &edge_node_map[num_edge_child_nodes*edge];}

 /**
  * A map from face edge to element edges.
  */
 const int *get_face_edge(int face_num) const {
  ThrowAssert(face_edge_map);
   return &face_edge_map[side_topo_list[0]->num_edges*face_num]; 
 }

 const int *get_fostered_edge_nodes(UInt fedge) const {
   return &fostered_edge_nodes[fedge*2];
 }

 /**
  * A face's edges may not have the same orientation as the element.
  * If the polarity is the same, a 1, else 0.
  */
 const int *get_face_edge_pol(int face_num) const {
  ThrowAssert(face_edge_pol);
   return &face_edge_pol[side_topo_list[0]->num_edges*face_num]; 
 }

 const std::string name;

 /** Unique topology index for marshalling the topology */
 const global_identifier number; 

 /** Number of vertex nodes */
 const UInt num_vertices;

 /** Number of nodes >= vertex nodes, for instance, with quadratic topologies. */
 const UInt num_nodes;

 const UInt num_sides;
 const UInt spatial_dim;
 const UInt parametric_dim;

 UInt get_num_side_nodes() const {return num_side_nodes;}
 UInt get_num_edge_nodes() const {return num_edge_nodes;}
 const MeshObjTopo *side_topo(UInt ordinal) const {
   return side_topo_list[ordinal];
 }
 const MeshObjTopo *edge_topo(UInt ordinal) const {
   return edge_topo_list[ordinal];
 }

 /**
  * Return parametric coordinates of the object's nodes.
  */
 const double *node_coord() const {
   return node_coords;
 }

 int num_edges;
 int num_side_nodes;
 int num_side_child_nodes; 
 int num_edge_nodes;
 int num_edge_child_nodes;
 int num_child_nodes;
 int num_fostered_edges;
 const int *perm_table(UInt rotation, UInt p) const { return &ptable[(2*rotation + (1-p))*num_child_nodes];}

 private:

 /** Side and edge topology lists */
 std::vector<MeshObjTopo*> side_topo_list;
 std::vector<MeshObjTopo*> edge_topo_list;
 
 /** How do side nodes (in their ordering) match element nodes? */
 int *side_node_map;

 /** How do edge nodes (in their ordering) match element nodes? */
 int *edge_node_map;

 /** How do a face's edges match element's edges? */
 int *face_edge_map;

 /** Does the face polarity match the element polarity? */
 int *face_edge_pol;

 /** Foster edge node table */
 int *fostered_edge_nodes;

 /** Permutation tables for side topology */
 int *ptable;

 /** Array of nodal parametric coordinates */
 double *node_coords;
};


} // namespace


#endif
