#include <Mesh/include/ESMCI_ShapeMini.h>
#include <Mesh/include/ESMCI_Exception.h>
#include <Mesh/include/ESMCI_ParEnv.h>
#include <iterator>
#include <iostream>

#include <vector>

namespace ESMCI {
/*-----------------------------------------------------------------------*/
// Basic Mini items
/*-----------------------------------------------------------------------*/
ShapeMiniBase::ShapeMiniBase()
{
}

void ShapeMiniBase::Interpolate(const double fvals[], double mcoef[]) const {

  UInt nfunc = NumFunctions();
 
  ThrowRequire(nfunc == 4);

  std::copy(&fvals[0], &fvals[nfunc-1], mcoef);
  mcoef[nfunc-1] = 0.0;

  // Evaluate function values at centroid, subtract
  double svals[4];
  shape(1, &ipoints[2*(nfunc-1)], &svals[0]);

  double flin = svals[0]*mcoef[0] + svals[1]*mcoef[1] + svals[2]*mcoef[2];

  mcoef[nfunc-1] = fvals[nfunc-1] - flin;  // value of function minus its linear interpolant.

}

void ShapeMiniBase::Interpolate(const fad_type fvals[], fad_type mcoef[]) const {

  UInt nfunc = NumFunctions();
 
  ThrowRequire(nfunc == 4);

  std::copy(&fvals[0], &fvals[nfunc-1], mcoef);
  mcoef[nfunc-1] = 0.0;

  // Evaluate function values at centroid, subtract
  double svals[4];
  shape(1, &ipoints[2*(nfunc-1)], &svals[0]);

  fad_type flin = svals[0]*mcoef[0] + svals[1]*mcoef[1] + svals[2]*mcoef[2];

  mcoef[nfunc-1] = fvals[nfunc-1] - flin;  // value of function minus its linear interpolant.

}

/*-----------------------------------------------------------------------*/
// Trianglular mini
/*-----------------------------------------------------------------------*/
static void build_minitri_dofs(std::vector<int> &table) {
    
  // Int dofs first
  for (UInt i = 0; i < 3; i++) {
    table.push_back(DOF_NODE); 
    table.push_back(i); // ordinal
    table.push_back(0); // index
    table.push_back(1); // polarity
  } 

  table.push_back(DOF_ELEM);
  table.push_back(0); // ordinal
  table.push_back(0); // idx
  table.push_back(1); // idx
  
}

void ShapeMiniTri::build_itable(std::vector<double> &ip) {

  // First the nodes:
  double one_third = 1.0/3.0;
  ip.clear(); ip.resize(4*2, 0);
  ip[0] = 0; ip[1] = 0;
  ip[2] = 1; ip[3] = 0;
  ip[4] = 0; ip[5] = 1;
  ip[6] = one_third; ip[7] = one_third;

}

ShapeMiniTri *ShapeMiniTri::classInstance = NULL;


ShapeMiniTri *ShapeMiniTri::instance() {
  
  ShapeMiniTri *qp;
  if (classInstance == NULL) {
    qp = new ShapeMiniTri();
    classInstance = qp;
  } else qp = classInstance;
  return qp;
}

ShapeMiniTri::ShapeMiniTri() :
 ShapeMiniBase()
{
  char buf[512];
  
  std::sprintf(buf, "MiniTri");
  
  ename = std::string(buf);
  
  build_minitri_dofs(dofs);
  
  build_itable(ipoints);
  
}

ShapeMiniTri::~ShapeMiniTri() {
}

template <typename Real>
void ShapeMiniTri::shape_eval(UInt npts, const Real pcoord[], Real results[]) const {
  
  UInt nfunc = NumFunctions();
  UInt pdim = ParametricDim();

  for (UInt p = 0; p < npts; ++p) {

    int twop = 2*p;
    int fourp = 4*p;
    Real s = pcoord[twop]; Real t = pcoord[twop+1];
    results[fourp] = 1 - s - t;
    results[fourp+1] = s;
    results[fourp+2] = t;
    results[fourp+3] = results[fourp]*results[fourp+1]*results[fourp+2]*27.0;

  } // 
 
}

template <typename Real>
void ShapeMiniTri::shape_grad_eval(UInt npts, const Real pcoord[], Real results[]) const {


 for (UInt p = 0; p < npts; p++) {
    int eightp = 8*p;
    int twop = 2*p;

    Real s = pcoord[twop]; Real t = pcoord[twop+1];

    results[eightp] = -1;
    results[eightp + 1] = -1;

    results[eightp + 2] = 1;
    results[eightp + 3] = 0;

    results[eightp + 4] = 0;
    results[eightp + 5] = 1;

    results[eightp + 6] = 27.0*(-2.0*s*t+t*(1-t));
    results[eightp + 7] = 27*(-2.0*s*t+s*(1-s));
  }

}

void ShapeMiniTri::shape(UInt npts, const double pcoord[], double results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeMiniTri::shape(UInt npts, const fad_type pcoord[], fad_type results[]) const {
  shape_eval(npts, pcoord, results);
}

void ShapeMiniTri::shape_grads(UInt npts, const double pcoord[], double results[]) const {

  shape_grad_eval(npts, pcoord, results);

}

void ShapeMiniTri::shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const {

  shape_grad_eval(npts, pcoord, results);

}

template void ShapeMiniTri::shape_eval(UInt npts, const double pcoord[], double results[]) const; 
template void ShapeMiniTri::shape_eval(UInt npts, const fad_type pcoord[], fad_type results[]) const; 

} // namespace
