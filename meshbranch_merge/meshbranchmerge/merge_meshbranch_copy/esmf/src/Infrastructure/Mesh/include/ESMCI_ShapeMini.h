#ifndef ESMCI_ShapeMini_h
#define ESMCI_ShapeMini_h

#include <Mesh/include/ESMCI_ShapeFunc.h>
#include <Mesh/include/ESMCI_Exception.h>
#include <Mesh/include/ESMCI_SFuncAdaptor.h>


#include <vector>

namespace ESMCI {
  
/**
 * @defgroup shapemini
 * 
 * Linear lagrange + a bubble function
 * 
 * @ingroup shapefunc
 */

/** 
 * Handles basic things.
 * @ingroup shapemini
 */
class ShapeMiniBase : public ShapeFunc {
public:
  virtual UInt NumFunctions() const = 0;
  
  UInt IntgOrder() const { return 4; }
  
  const std::string &name() const { return ename; }
  
  bool is_nodal() const { return false; }

  // Default; should no ask for edge/face perms
  UInt orientation() const { return ShapeFunc::ME_ORIENTED; }
  
  UInt NumInterp() const { return NumFunctions(); }
  
  const double *InterpPoints() const { return &ipoints[0]; }

  void Interpolate(const double fvals[], double mcoef[]) const; 
  void Interpolate(const fad_type fvals[], fad_type mcoef[]) const; 
  
  const int *DofDescriptionTable() const { return &dofs[0];}

  const int *edge_perm(bool p) const {
    Throw() << "No edge perm for mini";
  }

  const int *face_perm(UInt rot, bool p) const {
    Throw() << "No face perm for mini";
  }

protected:

  ShapeMiniBase();
  virtual ~ShapeMiniBase() {}
 
  // ***** Data *****
  std::string ename;
  std::vector<int> dofs;
  std::vector<double> ipoints;

};

/**
 * 
 * @ingroup shapemini
 */
class ShapeMiniTri : public ShapeMiniBase {
public:
  ShapeMiniTri();
  ~ShapeMiniTri();
  
  static ShapeMiniTri *instance();

  UInt NumFunctions() const { return 4; }
  
  UInt ParametricDim() const { return 2; }
  
  void shape(UInt npts, const double pcoord[], double results[]) const;
  void shape(UInt npts, const fad_type pcoord[], fad_type results[]) const;
  
  void shape_grads(UInt npts, const double pcoord[], double results[]) const;
  void shape_grads(UInt npts, const fad_type pcoord[], fad_type results[]) const;

  ShapeFunc *side_shape(UInt side_num) const {
    return SFuncAdaptor<bar_shape_func>::instance();
  }

  void build_itable(std::vector<double> &ip);

private:

  static ShapeMiniTri *classInstance;

  template <typename Real>
  void shape_eval(UInt npts, const Real pcoord[], Real results[]) const;

  template <typename Real>
  void shape_grad_eval(UInt npts, const Real pcoord[], Real results[]) const;

  
};

} // namespace

#endif /*ESMCI_SHAPELAGRANGE_H_*/
