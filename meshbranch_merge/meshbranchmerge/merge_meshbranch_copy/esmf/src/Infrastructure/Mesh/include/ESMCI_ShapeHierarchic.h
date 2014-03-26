#ifndef ESMCI_Hierarchic_h
#define ESMCI_Hierarchic_h

#include <Mesh/include/ESMCI_MeshTypes.h>
#include <Mesh/include/ESMCI_ShapeFunc.h>
#include <Mesh/include/ESMCI_Polynomial.h>
#include <Mesh/include/ESMCI_Exception.h>
#include <map>

/**
 * @defgroup shapehier
 * 
 * Hierarchical shape functions.
 * 
 * @ingroup shapefunc
 * 
 */ 

namespace ESMCI {

/**
 * Basic functionality (such as interpolation) for all hierarchic
 * shape functions.
 * 
 * @ingroup shapehier
 */
class ShapeHier : public ShapeFunc {
protected:
  ShapeHier(UInt q);
  ~ShapeHier() {}
  
   template <typename Real>
   void do_Interpolate(UInt pdim, const double ipoints[],
                       const Real fvals[], Real mcoef[]) const;

public:

   const double *InterpPoints() const { return &iPoints[0]; }

   // description for each dof (Obj type, Obj ordinal, index).
   const int *DofDescriptionTable() const { return &dtable[0]; }

   UInt NumFunctions() const { return nfunc;}

   UInt IntgOrder() const { return q+1; }

   const std::string &name() const { return m_name;}

   // Return true if values only occur at nodes and interpolation is from node values.
   bool is_nodal() const { return false; }

   UInt orientation() const { return ShapeFunc::ME_SIGN_ORIENTED; }

   UInt NumInterp() const { return nfunc; }

   virtual const int *edge_perm(bool p) const {
     return &m_edge_perm[p ? 0 : NumEFunc(0)];
   }

   virtual const int *face_perm(UInt rot,bool p) const {
     return &m_face_perm[(2*rot + (p ? 0:1))*NumFFunc(0)];
   }

private:
  // Return shape values at node
  virtual void shape_node(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const =0;
  // Return shape values at edge points
  virtual void shape_edge(UInt edge, // which edge
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const =0;
  // Return shape values at face points
  virtual void shape_face(UInt face, // which face
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const =0;
  // Return shape values at face points
  virtual void shape_elem(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const =0;

  // Some info needed for interpolation
  virtual UInt NumNodes() const = 0;
  virtual UInt NumEdges() const = 0;
  virtual UInt NumEFunc(UInt e) const = 0; // Functions on edge
  virtual UInt NumFFunc(UInt e) const = 0; // Functions on face
  virtual UInt NumBubble() const = 0;

protected:

  void Interpolate(const double fvals[], double mcoef[]) const;
  void Interpolate(const fad_type fvals[], fad_type mcoef[]) const;

   // ******** Data *********
   UInt q;
   std::vector<int> dtable; // dof description.
   UInt nfunc;
   std::string m_name;
   std::vector<double> iPoints; // interpolation points.

   mutable std::vector<double> interpMatrix;

   std::vector<int> m_edge_perm;
   std::vector<int> m_face_perm;
};

/**
 * 1D hierarchic shape function of arbitrary order.
 * @ingroup shapehier
 */
class BarHier : public ShapeHier {
BarHier(UInt q);
~BarHier() {}
static std::map<UInt,BarHier*> bhMap;
public:
static BarHier *instance(UInt q);
UInt ParametricDim() const { return 1;}
// Return array of the shape function values at the given pcoords(npts,pdim)
// in results(npts,ndofs)
void shape(UInt npts, const double pcoord[], double results[]) const;
void shape(UInt npts, const fad_type pcoord[], fad_type results[]) const;

// Return gradients at the given points pcoord(npts,pdim) in results(npts,ndofs,pdim) 
void shape_grads(UInt npts, const double pcoord[], double results[]) const;
void shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const;

ShapeFunc *side_shape(UInt side_num) const {
  Throw() << "No side shape for BarHier";
}

const int *edge_perm(bool) const {
  Throw() << "BarHier has no edge_perm";
}

const int *face_perm(UInt,bool) const {
  Throw() << "BarHier has no face_perm";
}

private:


// ********* Provide the following to ShapeHier base class for
// purposes of interpolation **************

// Return shape values at node
void shape_node(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at edge points
void shape_edge(UInt edge, // which edge
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_face(UInt face, // which face
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_elem(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
UInt NumNodes() const { return 2; }
UInt NumEdges() const { return 0; }
UInt NumEFunc(UInt) const { return 0; }
UInt NumFFunc(UInt) const { return 0; }
UInt NumBubble() const { return (q-1); }
// Need integrated legendre up to order q
std::vector<ILegendre<double> > ild;
std::vector<ILegendre<fad_type> > ilf;

};

/**
 * Quadrilater hierarchic shape function of arbitrary order.
 * @ingroup shapehier
 */
class QuadHier : public ShapeHier {
QuadHier(UInt q);
~QuadHier() {}
static std::map<UInt,QuadHier*> qhMap;
public:
static QuadHier *instance(UInt q);
UInt ParametricDim() const { return 2;}
// Return array of the shape function values at the given pcoords(npts,pdim)
// in results(npts,ndofs)
void shape(UInt npts, const double pcoord[], double results[]) const;
void shape(UInt npts, const fad_type pcoord[], fad_type results[]) const;

// Return gradients at the given points pcoord(npts,pdim) in results(npts,ndofs,pdim) 
void shape_grads(UInt npts, const double pcoord[], double results[]) const;
void shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const;

ShapeFunc *side_shape(UInt side_num) const {
  return BarHier::instance(q);
}

const int *face_perm(UInt,bool) const {
  Throw() << "QuadHier has no face_perm";
}

private:


// ********* Provide the following to ShapeHier base class for
// purposes of interpolation **************

// Return shape values at node
void shape_node(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at edge points
void shape_edge(UInt edge, // which edge
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_face(UInt face, // which face
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_elem(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
UInt NumNodes() const { return 4; }
UInt NumEdges() const { return 4; }
UInt NumEFunc(UInt) const { return (q-1); }
UInt NumFFunc(UInt) const { return 0; }
UInt NumBubble() const { return (q-1)*(q-1); }
// Need integrated legendre up to order q
std::vector<ILegendre<double> > ild;
std::vector<ILegendre<fad_type> > ilf;

};


/**
 * Triangular hierarchic shape function of
 * abribtary order.
 * @ingroup shapehier
 */
class TriHier : public ShapeHier {
TriHier(UInt q);
~TriHier() {}
static std::map<UInt,TriHier*> qhMap;
public:
static TriHier *instance(UInt q);
UInt ParametricDim() const { return 2;}
// Return array of the shape function values at the given pcoords(npts,pdim)
// in results(npts,ndofs)
void shape(UInt npts, const double pcoord[], double results[]) const;
void shape(UInt npts, const fad_type pcoord[], fad_type results[]) const;

// Return gradients at the given points pcoord(npts,pdim) in results(npts,ndofs,pdim) 
void shape_grads(UInt npts, const double pcoord[], double results[]) const;
void shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const;

ShapeFunc *side_shape(UInt side_num) const {
  return BarHier::instance(q);
}

const int *face_perm(UInt,bool) const {
  Throw() << "QuadHier has no face_perm";
}

private:

// ********* Provide the following to ShapeHier base class for
// purposes of interpolation **************

// Return shape values at node
void shape_node(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at edge points
void shape_edge(UInt edge, // which edge
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_face(UInt face, // which face
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_elem(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
UInt NumNodes() const { return 3; }
UInt NumEdges() const { return 3; }
UInt NumEFunc(UInt) const { return (q-1); }
UInt NumFFunc(UInt) const { return 0; }
UInt NumBubble() const { return (q-1)*(q-2)/2; }
// Need integrated legendre up to order q
std::vector<ILKernel<double> > ild;
std::vector<ILKernel<fad_type> > ilf;

};

// *************** Hex *****************
class HexHier : public ShapeHier {
HexHier(UInt q);
~HexHier() {}
static std::map<UInt,HexHier*> qhMap;
public:
static HexHier *instance(UInt q);
UInt ParametricDim() const { return 3;}
// Return array of the shape function values at the given pcoords(npts,pdim)
// in results(npts,ndofs)
void shape(UInt npts, const double pcoord[], double results[]) const;
void shape(UInt npts, const fad_type pcoord[], fad_type results[]) const;

// Return gradients at the given points pcoord(npts,pdim) in results(npts,ndofs,pdim) 
void shape_grads(UInt npts, const double pcoord[], double results[]) const;
void shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const;

ShapeFunc *side_shape(UInt side_num) const {
  return QuadHier::instance(q);
}



private:

// ********* Provide the following to ShapeHier base class for
// purposes of interpolation **************

// Return shape values at node
void shape_node(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at edge points
void shape_edge(UInt edge, // which edge
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_face(UInt face, // which face
                          UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
// Return shape values at face points
void shape_elem(UInt stride, // how to stride when storing results
                          UInt npts, // how many points to evaluate at
                          const double *pcoord, // parametric coords of point
                          double res[] 
                         ) const;
UInt NumNodes() const { return 8; }
UInt NumEdges() const { return 12; }
UInt NumEFunc(UInt) const { return (q-1); }
UInt NumFFunc(UInt) const { return (q-1)*(q-1); }
UInt NumBubble() const { return (q-1)*(q-1)*(q-1); }
// Need integrated legendre up to order q
std::vector<ILegendre<double> > ild;
std::vector<ILegendre<fad_type> > ilf;


};

} // namespace


#endif
