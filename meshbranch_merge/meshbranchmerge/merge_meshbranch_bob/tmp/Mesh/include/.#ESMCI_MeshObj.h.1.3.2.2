#ifndef ESMCI_MeshObj_h
#define ESMCI_MeshObj_h


#include <Mesh/include/ESMCI_MeshTypes.h>
#include <Mesh/include/ESMCI_List.h>
#include <Mesh/include/ESMCI_Tree.h>
#include <Mesh/include/ESMCI_SmallAlloc.h>

#include <stdlib.h>
#include <stdio.h>
#include <utility>

#include <string>


//#include <list>
#include <vector>
#include <map>
#include <exception>
#include <iostream>
#include <limits>



// A basic container for all mesh objects (used to connect different types)
//  Some container types
namespace ESMCI {

class MeshObj;
typedef List<MeshObj> MeshObjList;


class Kernel;  // Only so the object can provide an
                    // accesor.  Do not include details here,
                    // becuase this would create a circular
                    // dependency.

class _fieldStore; // similar story here.  We only hold a pointer to this
                   // class. We should never include its header, since this
                   // would cause a circular dependency.

typedef long MeshObj_id_type;


/**
 * A class to represent a basic object in a mesh such as a node, face, edge,
 * element, etc..  This class provides a container for the various relations
 * between mesh objects such as USES, CHILD, etc...
 * A main goal of this class is to be as small as possible, since there
 * very well may be millions of these present.
 *
 * Relations for a given object have the following properties:
 * They are sorted first by object type, so all nodes will appear first,
 * edges, faces, elements, etc...  Within each of these classes, relations
 * are sorted by relation type; USES, USED_BY, PARENT, CHILD, INTPER, FOSTERS
 *
 * <ul>
 * <li> USES e.g. element uses its nodes.  Not, USES are not turned on
 *      for edge to node, face to node, face to edge.  All these relations
 *      may be derived from the hosting element using the topological tables.
 *      We do not put them in the mesh to save memory and to save the complexity
 *      of keeping such relations up to date.
 * <li> USED_BY e.g nodes point back to the element with this.  For any
 *      USES there is a converse USED_BY.
 * <li> PARENT e.g. child element has PARENT parent element.
 * <li> CHILD parent element has CHILD child element
 * <li> FOSTERS since interior edges of a face (3d) do not have parents, but
 *      since we need to connect them to a mesh (possibly on a constrained face),
 *      the hosting (parent) face will FOSTERS these edges.
 * </ul>
 *
 * Elements will have all of the USES relations for their topology in place
 * (unless sides, edges are off).  For instance, a triangle will always have
 * its three USES nodes.  This allows for very quick access to such objects:
 * @code
 *   MeshObj &node3 = *elem.Relations[3].obj;
 *   MeshObj &edge0 = *elem.Relations[topo->num_nodes+0].obj;
 * @endcode
 *
 * Children, on the other hand, will appear only as
 * they are created, so their ordering is not predictiable.  For instance,
 * a hanging node might appear, but other nodes may not exist.
 * Within the obj type, relation type hierarchy, next sort is by ordinal.
 *
 * Also, the meshobj class inherits from tree and list nodes.  We must
 * store the mesh objects in a list and a map for access.  Rather than
 * use standard C++ lists and maps, we use an embedded map and list so
 * that we do not have to store an extra set of pointers per mesh object.
 * The pointer is the object itself!  Also, this allows for instant delete
 * from either the list of tree, whereas we would otherwise have to take
 * our collection of MeshObj*'s, look them up in their lists, and then delete,
 * which would be very expensive.
 *
 * TODO: rewrite a minimal vector class to replace the Relations vector.
 * I suspect vector takes more memory than an optimal implementation, and
 * since this size is accumulated for every object, a rewrite could significantly
 * decrease the memory used by a mesh.
 *
 * TODO: This class is a bit of a messs and could use a facelift.
 *
 * @ingroup meshdatabase
*/
class MeshObj :  public ListNode<MeshObj>, public TreeNode<MeshObj_id_type> {
public:
#ifdef ESMCI_MESHOBJ_MMANAGE
  static void *operator new(std::size_t);
  static void operator delete(void *p, std::size_t);
#endif
  /**
   * The list of objects that have relation to this meshobject.
   * The relation has several attributes:
   * <ol>
   * <li> obj: a pointer to the object
   * <li> ordinal: topological number of object (e.g. node 2)
   * <li> type: type of relation (USES,USED_BY,PARENT,CHILD)
   * <li> polarity,rotation:defines edge/face orienation wrt this object.
   * </ol>
   * @ingroup meshdatabase
   */
class Relation {
public:
  Relation() : obj(NULL), ordinal(0), type(0), polarity(0), rotation(0) {}
  MeshObj *obj;
  typedef UShort ordinal_type;
  typedef UChar type_type;
  typedef bool polarity_type;
  typedef UChar rotation_type;
  ordinal_type ordinal;
  type_type type; // ha ha
  polarity_type polarity; // true = normal, false = reversed
  rotation_type rotation;
  bool operator<(const Relation &r) const {
    if (obj->get_type() != r.obj->get_type()) return obj->get_type() < r.obj->get_type();
    if (type != r.type) return type < r.type;
    if (ordinal != r.ordinal) return ordinal < r.ordinal;
  // objects can change id, so this is
  // not a reliable sort criterion  if (obj->get_id() != r.obj->get_id()) return obj->get_id() < r.obj->get_id();
    return false;
  }
  bool operator==(const Relation &r) const {
    return obj == r.obj &&
           ordinal == r.ordinal &&
           polarity == r.polarity &&
           type == r.type &&
           rotation == r.rotation;
  }
};

 typedef MeshObj_id_type id_type;
 friend class Mesh;
 friend class MeshDB;
 friend class Kernel;
 typedef enum {NONE = 0x0, NODE = 0x01, EDGE=0x02,
               FACE=0x04, ELEMENT=0x08,
               INTERP= 0x10,                       // Use for interpolation
               ANY=0xFF } MeshObjType;
 typedef enum {USES=0x01, USED_BY=0x02,
               PARENT=0x04, CHILD=0x08,
               FOSTERS=0x10, FOSTERED_BY=0x20} RelationType;

 MeshObj(UChar _type, int _id, long _data_index=-1, int _owner=std::numeric_limits<int>::max());
 ~MeshObj();
 typedef std::vector<Relation> RelationList;
 RelationList Relations;
 // find the given object (if exists)
 bool operator <(const MeshObj &rhs) {return KeyOfValue() < rhs.KeyOfValue();}
 MeshObj::id_type get_id() const {return KeyOfValue();}
 const Kernel *GetKernel() const { return meshset;}
 Kernel *GetKernel() { return meshset;}
 void printdata() const;
 void printrelations(std::ostream &) const;
 //const MeshObjTopo * get_topo() const {return topo;}
 // Find the element opposite to this one's side 'side_ordinal'.  Return the oridnal
 // in the other elements numbering, rotation and polarity.  Return NULL if nothing there.
 UInt get_type() const;
 UInt get_owner() const { return owner;}

 typedef UInt OwnerType;
 OwnerType *get_owner_ptr() { return &owner; }
 void set_owner(OwnerType _owner) { owner = _owner;}

 typedef long DataIndexType;

 DataIndexType get_data_index() const { return data_index;}
 DataIndexType *get_data_index_ptr() { return &data_index;}
 bool operator==(const MeshObj &r) const { return &r == this;}
 bool operator!=(const MeshObj &r) const { return &r != this;}
 void AssignStore(_fieldStore *s, UInt idx);
 const std::pair<_fieldStore *,UInt> &GetStore() const { return fstore;}
private:
 MeshObj(const MeshObj &rhs);
 MeshObj &operator=(const MeshObj &rhs);
 DataIndexType data_index;
 UChar type;
 Kernel *meshset; // point back to mesh set
 OwnerType owner;  // owning proc
 std::pair<_fieldStore*,UInt> fstore;
 friend std::ostream &operator<<(std::ostream &os, const MeshObj &dc);

};

typedef MeshObj::RelationList MeshObjRelationList;

// Add a relation properly sorted
MeshObjRelationList::iterator AddMeshObjRelation(MeshObj &obj, const MeshObj::Relation &r);

std::string MeshObjTypeString(UInt);
std::string RelationTypeString(UInt);

const UInt NumMeshObjTypes = 4;
const UInt MeshObjTypes[] = {
  MeshObj::NODE,
  MeshObj::EDGE,
  MeshObj::FACE,
  MeshObj::ELEMENT
};

// Return converse of obj relation type
UInt MeshObjRelationConverse(UInt rel_type);

} //namespace


#endif
