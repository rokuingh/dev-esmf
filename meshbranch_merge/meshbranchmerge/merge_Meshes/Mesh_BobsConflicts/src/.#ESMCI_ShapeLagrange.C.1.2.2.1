#include <Mesh/include/ESMCI_ShapeLagrange.h>
#include <Mesh/include/ESMCI_Exception.h>
#include <Mesh/include/ESMCI_ParEnv.h>
#include <Mesh/include/ESMCI_Quadrature.h>
#include <iterator>
#include <iostream>

#include <vector>

namespace ESMCI {

/*-----------------------------------------------------------------------*/
// Basic lagrangian chores such as interpolation
/*-----------------------------------------------------------------------*/
ShapeLagrangeBase::ShapeLagrangeBase(UInt _q) :
 q(_q),
 q_1sq((q-1)*(q-1)),
 q_1cb((q-1)*(q-1)*(q-1))
{

  // Edge perm
  m_edge_perm.resize(2*(q-1));
  for (UInt i = 0; i < (q-1); ++i) {

    m_edge_perm[i] = i;
    m_edge_perm[(q-1)+i] = q-2-i;

  }

  // Face permutation (for now assuming hex--4 rotations).  Must move out of
  // base if we do tri
  
  // We have a tensor of points on the face which must be rotated e.g. q=4
  //
  //         6   7   8                            8  5  2
  //         3   4   5   ---> (under a rotation)  7  4  1
  //         0   1   2                            6  3  0
  //
  // To rotate, we just sweep the colums into the new rows, i.e.
  // new row i = old col i
  const UInt nrot = 4;
  m_face_perm.resize(2*nrot*q_1sq);
Par::Out() << "Lag face perm:" << std::endl;
  UInt n = 0;
  for (UInt i = 0; i < (q-1); ++i) {
    for (UInt j = 0; j < (q-1); ++j) {
      m_face_perm[i*(q-1)+j] = n;

      // Permutation flips the rows
      m_face_perm[q_1sq+(q-2-i)*(q-1)+j] = n;

      ++n;
    }
  }
  
  // Now apply the rule above to the last matrix entry
  for (int r = 1; r < nrot; ++r) {
    UInt two_rxq_1 = 2*r*q_1sq;
    int *pbase = &m_face_perm[two_rxq_1];
    int *opbase = &m_face_perm[2*(r-1)*q_1sq];
    for (UInt i = 0; i < (q-1); ++i) {
      for (UInt j = 0; j < (q-1); ++j) {

        pbase[i*(q-1)+j] = opbase[(q-2-j)*(q-1)+i];
        pbase[q_1sq+i*(q-1)+j] = opbase[q_1sq+(q-2-j)*(q-1)+i];

      }
    }
  } // r

  for (int r = 0; r < nrot; ++r) {
Par::Out() << std::endl << "r=" << r << " ";
    UInt two_rxq_1 = 2*r*q_1sq;
    const int *pbase = &m_face_perm[two_rxq_1];
    const int *opbase = &m_face_perm[2*(r-1)*q_1sq];
Par::Out() << "pol true" << std::endl << "\t";
    for (UInt i = 0; i < (q-1); ++i) {
      for (UInt j = 0; j < (q-1); ++j) {
Par::Out() << pbase[(q-2-i)*(q-1)+j] << " ";
      }
Par::Out() << std::endl << "\t";
    }
Par::Out() << std::endl << "pol=false" << std::endl << "\t";
    for (UInt i = 0; i < (q-1); ++i) {
      for (UInt j = 0; j < (q-1); ++j) {
Par::Out() << pbase[q_1sq+(q-2-i)*(q-1)+j] << " ";
      }
Par::Out() << std::endl << "\t";
    }
  }
Par::Out() << std::endl;



}

void ShapeLagrangeBase::Interpolate(const double fvals[], double mcoef[]) const {

  UInt nfunc = NumFunctions();

  std::copy(&fvals[0], &fvals[nfunc], mcoef);

}

void ShapeLagrangeBase::Interpolate(const fad_type fvals[], fad_type mcoef[]) const {

  UInt nfunc = NumFunctions();

  std::copy(&fvals[0], &fvals[nfunc], mcoef);

}


/*-----------------------------------------------------------------------*/
// Basic lagrangian shape function evaluation
/*-----------------------------------------------------------------------*/
template <typename Real>
Real lagrange(int i, const double *x, const Real &xbar, int n)
{
   int j;

  Real l = 1.0;
  
   for (j=0; j<n; j++) {
     if(j != i) 
       l *= (xbar-x[j])/(x[i]-x[j]);
   }
   
   return l;
}

/*-----------------------------------------------------------------------*/
// 1D continuous lagrange
/*-----------------------------------------------------------------------*/
static void build_bar_dofs(UInt q, std::vector<int> &table) {
    
  // Int dofs first
  for (UInt i = 0; i < 2; i++) {
    table.push_back(DOF_NODE); 
    table.push_back(i); // ordinal
    table.push_back(0); // index
    table.push_back(1); // polarity
  } 
  
  // And now edge dofs
  for (UInt i = 0; i < 1; i++) {
    // q -1 on each edge
    for (UInt j = 1; j < q; j++) {
      table.push_back(DOF_ELEM);
      table.push_back(i); // ordinal
      table.push_back(j-1);
      table.push_back(1); // orientation
    }
  }
}

void ShapeLagrangeBar::build_itable(UInt nfunc, UInt q, std::vector<double> &ip) {
  
  // First the nodes:
  ip.clear(); ip.resize(nfunc*1, 0);
  ip[0] = -1;
  ip[1] = 1;

  // Now q-1 integration points along the edges.
  UInt ofs = 2;

  // edge 0
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = lobatto_points[i];
  }

  ThrowRequire(ofs == nfunc*1);
}

static std::map<UInt,ShapeLagrangeBar*> &get_bar_lgmap() {
  static std::map<UInt,ShapeLagrangeBar*> lgmap;
  
  return lgmap;
}


ShapeLagrangeBar *ShapeLagrangeBar::instance(UInt _q) {
  
  std::map<UInt,ShapeLagrangeBar*> &lgMap = get_bar_lgmap();
  
  std::map<UInt,ShapeLagrangeBar*>::iterator qi =
    lgMap.find(_q);
  ShapeLagrangeBar *qp;
  if (qi == lgMap.end()) {
    qp = new ShapeLagrangeBar(_q);
    lgMap[_q] = qp;
  } else qp = qi->second;
  return qp;
}

ShapeLagrangeBar::ShapeLagrangeBar(UInt _q) :
 ShapeLagrangeBase(_q)
{
  lobatto_points.resize(_q+1);
  
  std::vector<double> temp_w(q+1, 0);
  
  lobatto_legendre_set(q+1, &lobatto_points[0], &temp_w[0]);

  char buf[512];
  
  std::sprintf(buf, "LagrangeBar_%02d", q);
  
  ename = std::string(buf);
  
  build_bar_dofs(q, dofs);
  
  build_itable(NumFunctions(), q, ipoints);
  
}

ShapeLagrangeBar::~ShapeLagrangeBar() {
}

UInt ShapeLagrangeBar::NumFunctions() const {
  return 2 // nodes 
  + 1*(q-1); // edges
}


template <typename Real>
void ShapeLagrangeBar::shape_eval(UInt npts, const Real pcoord[], Real results[]) const {
  
  UInt nfunc = NumFunctions();
  UInt pdim = ParametricDim();
 
  std::vector<Real> x_shape((q+1)*npts, 0);
  
  // evaluate 
  for (UInt i = 0; i < q+1; i++) {
    
    for (UInt j = 0; j < npts; j++) {
      
      x_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j], q+1);
      
    }
    
  }

  // And now contract to get results
  
  // Nodes
  for (UInt n = 0; n < npts; n++) {
    
    UInt nnfunc = n*nfunc;
    
    UInt qn = (q+1)*n;
    results[nnfunc] = x_shape[qn];
    results[nnfunc+1] = x_shape[qn+q];
    
  }
  
  // Element
  for (UInt n = 0; n < npts; n++) {
    UInt qn = (q+1)*n;
    UInt nnfunc = n*nfunc;
    
    Real *r = &x_shape[qn];

    UInt ebase = nnfunc + 2;
      
    for (UInt i = 1; i < q; i++)
        results[ebase+(i-1)] = r[i];

  }  // n
  
}

template <typename Real>
void bar_shape_grad_eval(UInt npts, const Real pcoord[], Real results[]) {
}

void ShapeLagrangeBar::shape(UInt npts, const double pcoord[], double results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeBar::shape(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeBar::shape_grads(UInt npts, const double pcoord[], double results[]) const {

  UInt nfunc = NumFunctions();

  std::vector<fad_type> shape_fad(nfunc);

  UInt pdim = ParametricDim();

  ThrowAssert(pdim == 1);

  std::vector<fad_type> pcoord_fad(pdim);

  for (UInt i = 0; i < npts; i++) {
    pcoord_fad[0] = pcoord[i*pdim];
    pcoord_fad[0].diff(0, 1);
    
    shape_eval(1, &pcoord_fad[0], &shape_fad[0]);

    for (UInt j = 0; j < nfunc; j++) {
      const double *diff = &(shape_fad[j].fastAccessDx(0));

      results[(i*nfunc+j)] = diff[0];
    }
  }


/*
Par::Out() << "Lag shape grads: nqpoints:" << npts << ", nfunc=" << nfunc << std::endl;
std::copy(&results[0], &results[npts*nfunc*pdim], std::ostream_iterator<double>(Par::Out(), " "));
Par::Out() << std::endl;
*/

}

void ShapeLagrangeBar::shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  Throw() << "do you even need this for the fad_type??";
}


/*-----------------------------------------------------------------------*/
// Quadratic continuous lagrange
/*-----------------------------------------------------------------------*/
static void build_dofs(UInt q, std::vector<int> &table) {
    
  // Int dofs first
  for (UInt i = 0; i < 4; i++) {
    table.push_back(DOF_NODE); 
    table.push_back(i); // ordinal
    table.push_back(0); // index
    table.push_back(1); // polarity
  } 
  
  // And now edge dofs
  for (UInt i = 0; i < 4; i++) {
    // q -1 on each edge
    for (UInt j = 1; j < q; j++) {
      table.push_back(DOF_EDGE);
      table.push_back(i); // ordinal
      table.push_back(j-1);
      table.push_back(1); // orientation
    }
  }
  

  // And, finally, the interior dofs
  UInt idx = 0;
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      table.push_back(DOF_ELEM);
      table.push_back(0); // no ordinal for element
      table.push_back(idx++);
      table.push_back(1); // index
    }
  }

}

void ShapeLagrangeQuad::build_itable(UInt nfunc, UInt q, std::vector<double> &ip) {
  
  // First the nodes:
  ip.clear(); ip.resize(nfunc*2, 0);
  ip[0] = -1; ip[1] = -1;
  ip[2] = 1; ip[3] = -1;
  ip[4] = 1; ip[5] = 1;
  ip[6] = -1; ip[7] = 1;

  // Now q-1 integration points along the edges.
  UInt ofs = 8;

  // edge 0
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = lobatto_points[i];
    ip[ofs++] = -1;
  }
  // edge 1
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = 1;
    ip[ofs++] = lobatto_points[i];
  }
  
  // edge 2
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = lobatto_points[q-i];
    ip[ofs++] = 1;
  }
  
  // edge 3
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = -1;
    ip[ofs++] = lobatto_points[q-i];
  }

  // And now, the beloved interior (tensor product
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      ip[ofs++] = lobatto_points[j];
      ip[ofs++] = lobatto_points[i];
    }
  }
  ThrowRequire(ofs == nfunc*2);
}

static std::map<UInt,ShapeLagrangeQuad*> &get_lgmap() {
  static std::map<UInt,ShapeLagrangeQuad*> lgmap;
  
  return lgmap;
}


ShapeLagrangeQuad *ShapeLagrangeQuad::instance(UInt _q) {
  
  std::map<UInt,ShapeLagrangeQuad*> &lgMap = get_lgmap();
  
  std::map<UInt,ShapeLagrangeQuad*>::iterator qi =
    lgMap.find(_q);
  ShapeLagrangeQuad *qp;
  if (qi == lgMap.end()) {
    qp = new ShapeLagrangeQuad(_q);
    lgMap[_q] = qp;
  } else qp = qi->second;
  return qp;
}

ShapeLagrangeQuad::ShapeLagrangeQuad(UInt _q) :
 ShapeLagrangeBase(_q)
{
  lobatto_points.resize(_q+1);
  
  std::vector<double> temp_w(q+1, 0);
  
  lobatto_legendre_set(q+1, &lobatto_points[0], &temp_w[0]);

  char buf[512];
  
  std::sprintf(buf, "LagrangeQuad_%02d", q);
  
  ename = std::string(buf);
  
  build_dofs(q, dofs);
  
  build_itable(NumFunctions(), q, ipoints);
  
}

ShapeLagrangeQuad::~ShapeLagrangeQuad() {
}

UInt ShapeLagrangeQuad::NumFunctions() const {
  return 4 // nodes 
  + 4*(q-1) // edges
  + q_1sq; // element
}



template <typename Real>
void ShapeLagrangeQuad::shape_eval(UInt npts, const Real pcoord[], Real results[]) const {
  
  UInt nfunc = NumFunctions();
  UInt pdim = ParametricDim();
 
  std::vector<Real> x_shape((q+1)*npts, 0);
  std::vector<Real> y_shape((q+1)*npts,0);
  
  // evaluate 
  for (UInt i = 0; i < q+1; i++) {
    
    for (UInt j = 0; j < npts; j++) {
      
      x_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j*pdim], q+1);
      y_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j*pdim+1], q+1);
      
    }
    
  }

  // And now contract to get results
  
  // Nodes
  for (UInt n = 0; n < npts; n++) {
    
    UInt nnfunc = n*nfunc;
    
    UInt qn = (q+1)*n;
    results[nnfunc] = x_shape[qn]*y_shape[qn];
    results[nnfunc+1] = x_shape[qn+q]*y_shape[qn];
    results[nnfunc+2] = x_shape[qn+q]*y_shape[qn+q];
    results[nnfunc+3] = x_shape[qn]*y_shape[qn+q];
    
  }
  
  // Edges
  for (UInt n = 0; n < npts; n++) {
    UInt qn = (q+1)*n;
    UInt nnfunc = n*nfunc;
    
    // The stationary shape function
    Real spt[] = { y_shape[qn],
                  x_shape[qn+q],
                  y_shape[qn+q],
                  x_shape[qn] };
    
    Real *row[] = {
        &x_shape[qn],
        &y_shape[qn],
        &x_shape[qn],
        &y_shape[qn] };
                          
    for (UInt e = 0; e < 4; e++) {
      
      UInt ebase = nnfunc + 4 + e*(q-1);
      
      Real s = spt[e];
      Real *r = row[e];
      
      if (e < 2) {
        for (UInt i = 1; i < q; i++)
        results[ebase+(i-1)] = s*r[i];
      } else {
        for (UInt i = 1; i < q; i++)
         results[ebase+(i-1)] = s*r[q-i];
      }
      
    }

  }  // n
  
  // Bubbles
  for (UInt n = 0; n < npts; n++) {
    
    UInt nnfunc = n*nfunc;
    UInt qn = (q+1)*n;
    UInt base = nnfunc + 4 + 4*(q-1);
    
    UInt of = 0;
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        
        results[base+of] = x_shape[qn + j]*y_shape[qn + i];
        
        ++of;
      }
    }
    
  } // n
  
}

template <typename Real>
void shape_grad_eval(UInt npts, const Real pcoord[], Real results[]) {
}

void ShapeLagrangeQuad::shape(UInt npts, const double pcoord[], double results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeQuad::shape(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeQuad::shape_grads(UInt npts, const double pcoord[], double results[]) const {

  UInt nfunc = NumFunctions();

  std::vector<fad_type> shape_fad(nfunc);

  UInt pdim = ParametricDim();

  ThrowAssert(pdim == 2);

  std::vector<fad_type> pcoord_fad(pdim);

  for (UInt i = 0; i < npts; i++) {
    pcoord_fad[0] = pcoord[i*pdim];
    pcoord_fad[0].diff(0, 2);
    
    pcoord_fad[1] = pcoord[i*pdim+1];
    pcoord_fad[1].diff(1, 2);

    shape_eval(1, &pcoord_fad[0], &shape_fad[0]);

    for (UInt j = 0; j < nfunc; j++) {
      const double *diff = &(shape_fad[j].fastAccessDx(0));

      results[(i*nfunc+j)*pdim] = diff[0];
      results[(i*nfunc+j)*pdim+1] = diff[1];
    }
  }


/*
Par::Out() << "Lag shape grads: nqpoints:" << npts << ", nfunc=" << nfunc << std::endl;
std::copy(&results[0], &results[npts*nfunc*pdim], std::ostream_iterator<double>(Par::Out(), " "));
Par::Out() << std::endl;
*/

}

void ShapeLagrangeQuad::shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  Throw() << "do you even need this for the fad_type??";
}

/*-----------------------------------------------------------------------*/
// Quadratic dis-continuous lagrange
/*-----------------------------------------------------------------------*/

static void build_dofs_dg(UInt q, std::vector<int> &table) {
    
  // And, finally, the interior dofs
  UInt idx = 0;
  for (UInt i = 0; i < q+1; i++) {
    for (UInt j = 0; j < q+1; j++) {
      table.push_back(DOF_ELEM);
      table.push_back(0); // no ordinal for element
      table.push_back(idx++);
      table.push_back(1); // index
    }
  }

}

void ShapeLagrangeQuadDG::build_itable(UInt nfunc, UInt q, std::vector<double> &ip) {
  
  // First the nodes:
  ip.clear(); ip.resize(nfunc*2, 0);

  // And now, the beloved interior (tensor product
  UInt ofs = 0;
  for (UInt i = 0; i < q+1; i++) {
    for (UInt j = 0; j < q+1; j++) {
      ip[ofs++] = lobatto_points[j];
      ip[ofs++] = lobatto_points[i];
    }
  }

  ThrowRequire(ofs == nfunc*2);
}

static std::map<UInt,ShapeLagrangeQuadDG*> &get_lgdgmap() {
  static std::map<UInt,ShapeLagrangeQuadDG*> lgdgmap;
  
  return lgdgmap;
}


ShapeLagrangeQuadDG *ShapeLagrangeQuadDG::instance(UInt _q) {
  
  std::map<UInt,ShapeLagrangeQuadDG*> &lgdgMap = get_lgdgmap();
  
  std::map<UInt,ShapeLagrangeQuadDG*>::iterator qi =
    lgdgMap.find(_q);
  ShapeLagrangeQuadDG *qp;
  if (qi == lgdgMap.end()) {
    qp = new ShapeLagrangeQuadDG(_q);
    lgdgMap[_q] = qp;
  } else qp = qi->second;
  return qp;
}

ShapeLagrangeQuadDG::ShapeLagrangeQuadDG(UInt _q) :
 ShapeLagrangeBase(_q)
{
  lobatto_points.resize(_q+1);
  
  std::vector<double> temp_w(q+1, 0);
  
  lobatto_legendre_set(q+1, &lobatto_points[0], &temp_w[0]);

  char buf[512];
  
  std::sprintf(buf, "LagrangeQuad_%02d", q);
  
  ename = std::string(buf);
  
  build_dofs_dg(q, dofs);
  
  build_itable(NumFunctions(), q, ipoints);
  
}

ShapeLagrangeQuadDG::~ShapeLagrangeQuadDG() {
}

UInt ShapeLagrangeQuadDG::NumFunctions() const {
  return (q+1)*(q+1); // element
}


template <typename Real>
void ShapeLagrangeQuadDG::shape_eval(UInt npts, const Real pcoord[], Real results[]) const {
  
  UInt nfunc = NumFunctions();
  UInt pdim = ParametricDim();
 
  std::vector<Real> x_shape((q+1)*npts, 0);
  std::vector<Real> y_shape((q+1)*npts,0);
  
  // evaluate 
  for (UInt i = 0; i < q+1; i++) {
    
    for (UInt j = 0; j < npts; j++) {
      
      x_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j*pdim], q+1);
      y_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j*pdim+1], q+1);
      
    }
    
  }

  // And now contract to get results
  
  // Bubbles
  for (UInt n = 0; n < npts; n++) {
    
    UInt nnfunc = n*nfunc;
    UInt qn = (q+1)*n;
    UInt base = nnfunc;
    
    UInt of = 0;
    for (UInt i = 0; i < q+1; i++) {
      for (UInt j = 0; j < q+1; j++) {
        
        results[base+of] = x_shape[qn + j]*y_shape[qn + i];
        
        ++of;
      }
    }
    
  } // n
  
}

void ShapeLagrangeQuadDG::shape(UInt npts, const double pcoord[], double results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeQuadDG::shape(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeQuadDG::shape_grads(UInt npts, const double pcoord[], double results[]) const {
Throw() << "DG shape grad not yet implemented";
}

void ShapeLagrangeQuadDG::shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const {
Throw() << "DG shape grad not yet implemented";
}

/*-----------------------------------------------------------------------*/
// Hexahedron continuous lagrange
/*-----------------------------------------------------------------------*/
static void hex_build_dofs(UInt q, std::vector<int> &table) {
    
  // Int dofs first
  for (UInt i = 0; i < 8; i++) {
    table.push_back(DOF_NODE); 
    table.push_back(i); // ordinal
    table.push_back(0); // index
    table.push_back(1); // polarity
  } 
  
  // And now edge dofs
  for (UInt i = 0; i < 12; i++) {
    // q -1 on each edge
    for (UInt j = 1; j < q; j++) {
      table.push_back(DOF_EDGE);
      table.push_back(i); // ordinal
      table.push_back(j-1);
      table.push_back(1); // orientation
    }
  }

  // And now face dofs
  for (UInt i = 0; i < 6; i++) {

    UInt idx = 0;

    for (UInt j = 1; j < q; j++) {
      for (UInt k = 1; k < q; k++) {
        table.push_back(DOF_FACE);
        table.push_back(i); // ordinal
        table.push_back(idx++);
        table.push_back(1); // orientation
      }
    }
  }
  

  // And, finally, the interior dofs
  UInt idx = 0;
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      for (UInt k = 1; k < q; k++) {
        table.push_back(DOF_ELEM);
        table.push_back(0); // no ordinal for element
        table.push_back(idx++);
        table.push_back(1); // index
      }
    }
  }

}

void ShapeLagrangeHex::build_itable(UInt nfunc, UInt q, std::vector<double> &ip) {

static double hex_node_coord[] = {
-1,  -1,  -1,
 1,  -1,  -1,
 1, 1, -1,
 -1, 1, -1,
-1,-1,1,
1, -1, 1,
1, 1,  1,
-1, 1, 1};

  
  // First the nodes:
  ip.clear(); ip.resize(nfunc*3, 0);

  std::copy(&hex_node_coord[0], &hex_node_coord[3*8], ip.begin());

  // Now q-1 integration points along the edges.
  UInt ofs = 3*8;

  // Circle around bottom
  
  // edge 0
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = lobatto_points[i];
    ip[ofs++] = -1;
    ip[ofs++] = -1;
  }
  // edge 1
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = 1;
    ip[ofs++] = lobatto_points[i];
    ip[ofs++] = -1;
  }
  
  // edge 2
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = lobatto_points[q-i];
    ip[ofs++] = 1;
    ip[ofs++] = -1;
  }
  
  // edge 3
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = -1;
    ip[ofs++] = lobatto_points[q-i];
    ip[ofs++] = -1;
  }

  // Same, but at z=1

  // edge 4
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = lobatto_points[i];
    ip[ofs++] = -1;
    ip[ofs++] = 1;
  }
  // edge 5
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = 1;
    ip[ofs++] = lobatto_points[i];
    ip[ofs++] = 1;
  }
  
  // edge 6
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = lobatto_points[q-i];
    ip[ofs++] = 1;
    ip[ofs++] = 1;
  }
  
  // edge 7
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = -1;
    ip[ofs++] = lobatto_points[q-i];
    ip[ofs++] = 1;
  }

  // Now sides  all increate in z

  // edge 8
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = -1;
    ip[ofs++] = -1;
    ip[ofs++] = lobatto_points[i];
  }
  // edge 9
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = 1;
    ip[ofs++] = -1;
    ip[ofs++] = lobatto_points[i];
  }
  
  // edge 10
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = 1;
    ip[ofs++] = 1;
    ip[ofs++] = lobatto_points[i];
  }
  
  // edge 11
  for (UInt i = 1; i < q; i++) {
    ip[ofs++] = -1;
    ip[ofs++] = 1;
    ip[ofs++] = lobatto_points[i];
  }

  // The six face bubbles

  // Face 0
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      ip[ofs++] = lobatto_points[j];
      ip[ofs++] = -1;
      ip[ofs++] = lobatto_points[i];
    }
  }

  // Face 1
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      ip[ofs++] = 1;
      ip[ofs++] = lobatto_points[j];
      ip[ofs++] = lobatto_points[i];
    }
  }

  // Face 2
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      ip[ofs++] = lobatto_points[q-j];
      ip[ofs++] = 1;
      ip[ofs++] = lobatto_points[i];
    }
  }

  // Face 3
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      ip[ofs++] = -1;
      ip[ofs++] = lobatto_points[i];
      ip[ofs++] = lobatto_points[j];
    }
  }

  // Face 4
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      ip[ofs++] = lobatto_points[i];
      ip[ofs++] = lobatto_points[j];
      ip[ofs++] = -1;
    }
  }

  // Face 5
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      ip[ofs++] = lobatto_points[j];
      ip[ofs++] = lobatto_points[i];
      ip[ofs++] = 1;
    }
  }
  

  // And now, the beloved interior (tensor product
  for (UInt i = 1; i < q; i++) {
    for (UInt j = 1; j < q; j++) {
      for (UInt k = 1; k < q; k++) {
        ip[ofs++] = lobatto_points[k];
        ip[ofs++] = lobatto_points[j];
        ip[ofs++] = lobatto_points[i];
      }
    }
  }
  ThrowRequire(ofs == nfunc*3);
}

static std::map<UInt,ShapeLagrangeHex*> &get_hex_lgmap() {
  static std::map<UInt,ShapeLagrangeHex*> lgmap;
  
  return lgmap;
}


ShapeLagrangeHex *ShapeLagrangeHex::instance(UInt _q) {
  
  std::map<UInt,ShapeLagrangeHex*> &lgMap = get_hex_lgmap();
  
  std::map<UInt,ShapeLagrangeHex*>::iterator qi =
    lgMap.find(_q);
  ShapeLagrangeHex *qp;
  if (qi == lgMap.end()) {
    qp = new ShapeLagrangeHex(_q);
    lgMap[_q] = qp;
  } else qp = qi->second;
  return qp;
}

ShapeLagrangeHex::ShapeLagrangeHex(UInt _q) :
 ShapeLagrangeBase(_q)
{
  lobatto_points.resize(_q+1);
  
  std::vector<double> temp_w(q+1, 0);
  
  lobatto_legendre_set(q+1, &lobatto_points[0], &temp_w[0]);

  char buf[512];
  
  std::sprintf(buf, "LagrangeHex_%02d", q);
  
  ename = std::string(buf);
  
  hex_build_dofs(q, dofs);
  
  build_itable(NumFunctions(), q, ipoints);
  
}

ShapeLagrangeHex::~ShapeLagrangeHex() {
}

UInt ShapeLagrangeHex::NumFunctions() const {
  return 8 // nodes 
  + 12*(q-1) // edges
  + 6*q_1sq // edges
  + q_1cb; // element
}



template <typename Real>
void ShapeLagrangeHex::shape_eval(UInt npts, const Real pcoord[], Real results[]) const {
  
  UInt nfunc = NumFunctions();
  UInt pdim = ParametricDim();
 
  std::vector<Real> x_shape((q+1)*npts, 0);
  std::vector<Real> y_shape((q+1)*npts,0);
  std::vector<Real> z_shape((q+1)*npts,0);
  
  // evaluate 
  for (UInt i = 0; i < q+1; i++) {
    
    for (UInt j = 0; j < npts; j++) {
      
      x_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j*pdim], q+1);
      y_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j*pdim+1], q+1);
      z_shape[j*(q+1)+i] = lagrange(i, &lobatto_points[0], pcoord[j*pdim+2], q+1);
      
    }
    
  }

  // And now contract to get results
  
  // Nodes
  for (UInt n = 0; n < npts; n++) {
    
    UInt nnfunc = n*nfunc;
    
    UInt qn = (q+1)*n;
    results[nnfunc] = x_shape[qn]*y_shape[qn]*z_shape[qn];
    results[nnfunc+1] = x_shape[qn+q]*y_shape[qn]*z_shape[qn];
    results[nnfunc+2] = x_shape[qn+q]*y_shape[qn+q]*z_shape[qn];
    results[nnfunc+3] = x_shape[qn]*y_shape[qn+q]*z_shape[qn];
    results[nnfunc+4] = x_shape[qn]*y_shape[qn]*z_shape[qn+q];
    results[nnfunc+5] = x_shape[qn+q]*y_shape[qn]*z_shape[qn+q];
    results[nnfunc+6] = x_shape[qn+q]*y_shape[qn+q]*z_shape[qn+q];
    results[nnfunc+7] = x_shape[qn]*y_shape[qn+q]*z_shape[qn+q];
    
  }
  
  // Edges
  for (UInt n = 0; n < npts; n++) {
    UInt qn = (q+1)*n;
    UInt nnfunc = n*nfunc;
    
    // The stationary shape function(s)
    Real spt[] = { // bottom
                  y_shape[qn],z_shape[qn],
                  x_shape[qn+q], z_shape[qn],
                  y_shape[qn+q],z_shape[qn],
                  x_shape[qn], z_shape[qn],
                  // top
                  y_shape[qn],z_shape[qn+q],
                  x_shape[qn+q], z_shape[qn+q],
                  y_shape[qn+q],z_shape[qn+q],
                  x_shape[qn], z_shape[qn+q],
                  // side
                  x_shape[qn],y_shape[qn],
                  x_shape[qn+q],y_shape[qn],
                  x_shape[qn+q],y_shape[qn+q],
                  x_shape[qn],y_shape[qn+q]
    };

    // 1 if lobatto points are inc, 0 if dec
    int inc[] = {
      1, 1, 0, 0,
      1, 1, 0, 0,
      1, 1, 1, 1
    };
    
    // Varying function
    Real *row[] = {
        &x_shape[qn],
        &y_shape[qn],
        &x_shape[qn],
        &y_shape[qn],
        &x_shape[qn],
        &y_shape[qn],
        &x_shape[qn],
        &y_shape[qn],
        &z_shape[qn],
        &z_shape[qn],
        &z_shape[qn],
        &z_shape[qn]
    };
                          
    for (UInt e = 0; e < 12; e++) {
      
      UInt ebase = nnfunc + 8 + e*(q-1);
      
      Real *s = &spt[2*e];
      Real *r = row[e];
      
      if (inc[e] > 0) {
        for (UInt i = 1; i < q; i++)
        results[ebase+(i-1)] = s[0]*s[1]*r[i];
      } else {
        for (UInt i = 1; i < q; i++)
         results[ebase+(i-1)] = s[0]*s[1]*r[q-i];
      }
      
    }

  }  // n

  // Faces
  for (UInt n = 0; n < npts; n++) {
    UInt qn = (q+1)*n;
    UInt nnfunc = n*nfunc;

    UInt ebase = nnfunc + 8 + 12*(q-1);

    // Face 0
    UInt ofs = 0;
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        results[ebase + ofs++] =
          y_shape[qn]*x_shape[qn+j]*z_shape[qn+i];
      }
    }

    // Face 1
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        results[ebase + ofs++] =
          x_shape[qn+q]*y_shape[qn+j]*z_shape[qn+i];
      }
    }

    // Face 2
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        results[ebase + ofs++] =
          y_shape[qn+q]*x_shape[qn+(q-j)]*z_shape[qn+i];
      }
    }

    // Face 3
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        results[ebase + ofs++] =
          x_shape[qn]*z_shape[qn+j]*y_shape[qn+i];
      }
    }

    // Face 4
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        results[ebase + ofs++] =
          z_shape[qn]*y_shape[qn+j]*x_shape[qn+i];
      }
    }

    // Face 5
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        results[ebase + ofs++] =
          z_shape[qn+q]*x_shape[qn+j]*y_shape[qn+i];
      }
    }

  }  // n
  
  // Bubbles
  for (UInt n = 0; n < npts; n++) {
    
    UInt nnfunc = n*nfunc;
    UInt qn = (q+1)*n;
    UInt base = nnfunc + 8 + 12*(q-1) + 6*(q-1)*(q-1);
    
    UInt of = 0;
    for (UInt i = 1; i < q; i++) {
      for (UInt j = 1; j < q; j++) {
        for (UInt k = 1; k < q; k++) {
        
          results[base+of] = x_shape[qn + k]*y_shape[qn + j]*z_shape[qn+i];
        
          ++of;
        }
      }
    }
    
  } // n
  
}

void ShapeLagrangeHex::shape(UInt npts, const double pcoord[], double results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeHex::shape(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeLagrangeHex::shape_grads(UInt npts, const double pcoord[], double results[]) const {

  UInt nfunc = NumFunctions();

  std::vector<fad_type> shape_fad(nfunc);

  UInt pdim = ParametricDim();

  ThrowAssert(pdim == 3);

  std::vector<fad_type> pcoord_fad(pdim);

  for (UInt i = 0; i < npts; i++) {
    pcoord_fad[0] = pcoord[i*pdim];
    pcoord_fad[0].diff(0, 3);
    pcoord_fad[1] = pcoord[i*pdim+1];
    pcoord_fad[1].diff(1, 3);
    pcoord_fad[2] = pcoord[i*pdim+2];
    pcoord_fad[2].diff(2, 3);
    
    shape_eval(1, &pcoord_fad[0], &shape_fad[0]);

    for (UInt j = 0; j < nfunc; j++) {
      const double *diff = &(shape_fad[j].fastAccessDx(0));

      results[(i*nfunc+j)*pdim] = diff[0];
      results[(i*nfunc+j)*pdim+1] = diff[1];
      results[(i*nfunc+j)*pdim+2] = diff[2];
    }
  }


/*
Par::Out() << "Lag shape grads: nqpoints:" << npts << ", nfunc=" << nfunc << std::endl;
std::copy(&results[0], &results[npts*nfunc*pdim], std::ostream_iterator<double>(Par::Out(), " "));
Par::Out() << std::endl;
*/

}

void ShapeLagrangeHex::shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  Throw() << "do you even need this for the fad_type??";
}

template void ShapeLagrangeQuad::shape_eval(UInt npts, const double pcoord[], double results[]) const; 
template void ShapeLagrangeQuad::shape_eval(UInt npts, const fad_type pcoord[], fad_type results[]) const; 

template void ShapeLagrangeHex::shape_eval(UInt npts, const double pcoord[], double results[]) const; 
template void ShapeLagrangeHex::shape_eval(UInt npts, const fad_type pcoord[], fad_type results[]) const; 

template void ShapeLagrangeQuadDG::shape_eval(UInt npts, const double pcoord[], double results[]) const; 
template void ShapeLagrangeQuadDG::shape_eval(UInt npts, const fad_type pcoord[], fad_type results[]) const; 

} // namespace
