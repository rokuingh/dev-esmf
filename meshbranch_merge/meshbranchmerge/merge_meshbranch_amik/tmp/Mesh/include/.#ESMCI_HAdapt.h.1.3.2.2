#ifndef ESMCI_HAdapt_h
#define ESMCI_HAdapt_h

#include <vector>
#include <map>

#include <Mesh/include/ESMCI_Exception.h>
#include <Mesh/include/ESMCI_MeshTypes.h>
#include <Mesh/include/ESMCI_MEField.h>
#include <Mesh/include/ESMCI_WMat.h>


namespace ESMCI {

class Mesh;
class _field;

template<class> class MEField;

class MeshObj;

/** 
 * This class manages HAdaptivity for the mesh class.  It handles
 * enforcement of the 2-1 rule, ease for marking elements to refine/
 * unrefine, etc...
 *
 * Refinement proceeds as follows:
 *   -) Mark the elements
 *   -) Call MarkerResolution
 *   -) Call Unrefine Mesh
 *   -) Call Refine Mesh
*/
class HAdapt {
public:

enum {ELEM_REQUEST_UNREFINE = 3, ELEM_UNREFINE = 2, ELEM_REFINE = 1};

/**
 * Refine the mesh uniformly.  If keep_parents is false, make the refined
 * mesh the active mesh and delete parents.
 */
void RefineUniformly(bool keep_parents=true);

/**
 * Create an HAdapt, attach to a mesh
*/
HAdapt(Mesh &mesh);

/** 
 * Zero the element refinement marker field
 */
void ZeroMarker() const;


/** 
 * Mark an element to refine or unrefine
 */
void MarkElement(const MeshObj &elem, int val) const;

/**
 * Resolve the refine/unrefine markers.  Elements start with
 * -1 = unrefine, 0 = nothing, 1 = refine.  At the end of the
 * function, some new elements will be marked with 1 (to satisfy
 * the 2-1 rule), and only a handful of the elements will still
 * have -1 (those that CAN refine).
 */
void MarkerResolution();

/**
 *  Refine the mesh according to markers (which should be consistent).
 */
void UnrefineMesh();

/**
 * Unrefine the mesh elements (markers should be consistent).
*/
void RefineMesh();

/**
 * Return the refinement level of an element (0 = genesis, 1=1 parent, ....)
 */
static UInt RefineLevel(MeshObj &elem);


Mesh &GetMesh() { return mesh; }

const Mesh &GetMesh() const { return mesh; }

void ProlongField(MEField<> &field) {
  ProlongField(refine_list, field);
}

void ProlongField(std::vector<MeshObj*> &elems, MEField<> &field);

/**
 * Apply the hanging node constraints to a field.
 */
void EnforceConstraints(MEField<> &field) const;

typedef std::vector<std::pair<MeshObj*,int> > CElemVec;

/**
 * Return a vector of the constrained (elem,side) pairs.
 */
void ConstrainedElems(CElemVec &celems) const;

/*
 * See if the object is on the refined part of a non-conforming side.
 */
bool IsNonConformingRefinedSide(const MeshObj &side) const;

/*
 * Answers:
 * Is this side object on the coarse side of a non-conforming edge??
 * Non static, since we assert the object is truly a side object.
 */
bool IsNonConformingCoarseSide(const MeshObj &side) const;

/*
 * Given a side, return whether is is conforming or nonconforming.
 *   SIDE_NORMAL: side across from this one is at the same refinement level.
 *   SIDE_COARSE: The side across is refined one level, compared to me.
 *   SIDE_REFINED: The side across is one level coarser than me.
 */
typedef enum {NCONF_SIDE_NORMAL=0, NCONF_SIDE_COARSE, NCONF_SIDE_REFINED} SideRefinementState;

SideRefinementState IsNonConformingSide(const MeshObj &side) const;

typedef std::vector<MeshObj*> ElemList;

ElemList::const_iterator refine_list_begin() { return refine_list.begin(); }
ElemList::const_iterator refine_list_end() { return refine_list.end(); }

ElemList::const_iterator unrefine_list_begin() { return unrefine_list.begin(); }
ElemList::const_iterator unrefine_list_end() { return unrefine_list.end(); }

private:
HAdapt(const HAdapt &);
HAdapt &operator=(const HAdapt &);

Mesh &mesh;

/**
 * Update the constraints, attributes, etc as needed.
*/
void refinement_resolution() const;
void resolve_refinement_markers(std::vector<MeshObj*>&);
void resolve_unrefinement_markers(std::vector<MeshObj*>&,std::vector<MeshObj*>&);



/** Field for resolving 2-1 (helps across processors) */
MEField<_field> *node_marker; 

/** Field used to mark elements for refine/unrefine */
MEField<_field> *elem_marker; 

/** Elements to refine are kept on a list since adaptivity
 *  changes the mesh linkage
*/
ElemList refine_list;
ElemList unrefine_list;

};

class RefineTopo;
class MasterElementBase;

/** 
 * Manage prolongation and constraint operators for refinement.
 * This class matrixes (MasterElement, RefinementTopo) so that
 * we may consider different refinement strategies for our elements.
 * For instance, if we implement anisotropic refinement or Rivara, we
 * we not have the homogenous prolongation and constraint matrices hard-coded
 * into our me.
 */
class RefDual {
public:

 /**
  * Create an instance.
  * TODO: what if the refinement creates new topologies with new me?
  */
 static const RefDual *instance(const RefineTopo*, const MasterElementBase*me);

 /** 
  * Matrix that takes parent coefficients array pcoef[] and manufactures the
  * child coefficients, ccoef[];  Dimensions are (me.nfunc,me.nfuc)
  */
 const double *prolongation_matrix(UInt child_num) const  {
   ThrowRequire(child_num < prolong_matrices.size());
   return &(prolong_matrices[child_num][0]);
 }

 void apply_prolongation(UInt fdim, UInt child_num, const double parent_mcoef[], double child_mcoef[]) const;

/*
 struct cmatrix {
   std::vector<int> rows, cols;
   std::vector<double> mat;
 };
*/
 /**
  * Return the constraint matrix for a given side. mat(i,j) describes how the dof row(i) is constrained
  * in terms of parent dof col(j).
  */ 
 //const cmatrix &constraint_matrix(UInt side_num);

 //std::pair<const int*,const double*> constraint_matrix(UInt child_num, UInt side_num);
 typedef std::map<std::pair<const RefineTopo*,const MasterElementBase*>,RefDual*> ref_map;
private:

 RefDual(const RefineTopo *, const MasterElementBase *me);
 void build_matrices(const RefineTopo *, const MasterElementBase *me);
 RefDual(const RefDual&);
 RefDual &operator=(const RefDual&);


 UInt nfunc;
 std::vector<std::vector<double> > prolong_matrices;

 //std::vector<cmatrix> cmatrices;

};


} // namespace

#endif
