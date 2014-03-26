#ifndef ESMCI_LinSys_h
#define ESMCI_LinSys_h

#include <Mesh/include/ESMCI_MeshObj.h>
#include <Mesh/include/ESMCI_MEField.h>
#include <Mesh/include/ESMCI_ParamHandler.h>

#ifdef ESMCI_TRILINOS
#include <Epetra_Map.h>
#include <Epetra_FECrsMatrix.h>
#include <Epetra_FEVector.h>
#endif

#include <map>

namespace ESMCI {

class Mesh;
class Kernel;
class HAdapt;

struct LinSysParam {
 LinSysParam() :
  output(QUIET),
  method(GMRES),
  preconditioner(ML),
  residual(1e-10),
  max_iters(200),
  ml_levels(10)
 {
    
  }
  void declare_parameters(ParameterHandler &);
  void load_parameters(ParameterHandler &);

  enum {QUIET= 0, VERBOSE=1};
  enum {GMRES = 0, DIRECT=1};
  enum {ML=0, ILUT=1};
  int output;
  int method;
  int preconditioner;
  double residual;
  int max_iters;
  double ILUT_FILL;
  double ILUT_ATOL;
  double ILUT_RTOL;
  double ILUT_DROP;
  int ml_levels;
};

// A linear system abstraction class.  Builds a matrix that couples
// the given fields.
class LinSys {
public:

  typedef int DField_type; // type of dof field: use int, since Epetra does.

  LinSys(Mesh &mesh, UInt nfields, MEField<> **fields, const LinSysParam &lsp);

  /**
   * Reset the lin sys (same fields, though)
   */
  void clear();

  /**
   * Loop the mesh, find dofs, obtain global numbers
   */
  void BuildDofs();

  /**
   * Build the sparsity pattern into the global matrix.  If matrix was created
   * previously, it is cleared and then rebuilt.
   */
  void BuildMatrix();

  /**
   * Zero the matrix, create the rhs vector (and zero)
   */
  void BeginAssembly(); 

  /** 
   * Norm of the rhs vector (l2)
   */
  void RhsNorm(double &res_norm);

  /**
   * Bring the matrix and rhs to one processor.  This is necessary before
   * applying any type of constraints, otherwise ExtractRowView will not
   * get the shared contributions
   */
  void GlobalAssemble();

  /**
   * Form and apply the hnode constraints to the matrix
   */
  void ApplyHNodeConstraints(HAdapt &hadapt);

  /**
   * End matrix assembly.  Convert matrix to local indicies for use with Aztec
   */
  void EndAssembly(); 

 /**
  * Solve the linear system.  Return the number of iterations and
  * the linear residual.
  */
  void Solve(UInt &lin_iter, double &lin_res);

  /**
   * Set an entry that constraints the dof to be dirichlet.  Sets I in
   * matrix, and sets val in rhs vector.
   * Should set owned=true on owner, and false if not owned.  Still must call
   * on the non-owner; this proc just zeros everything.
   */
  void Dirichlet(DField_type id, double val, bool owned);
  
  /**
   * Return the number of degrees of freedom on the given kernel.
   * Sets up the map for (field,dim) -> local dof map
   */
  UInt Setup(Kernel &ker);

  /**
   * Call for each element.  Sets up the dofindices mapping.
   */
  void ReInit(MeshObj &elem);

  /**
   * Set up the values of fad coefficients.  Negate if needed.
   */
  void SetFadCoef(UInt offset, std::vector<double> &mcoef, std::vector<fad_type> &fad_coef);

  void PrintMatrix(std::ostream &);

  typedef std::vector<MEField<>*> FieldVec;

  /**
   * Sum a row into the global matrix.  The row should be ordered as
   * field(0,dim=0), field(0,1), ..., field(1,0), field(1,1), etc...
   */
  void SumToGlobal(UInt row, const double mat_row[], double rhs_val);

  // Various iterators
  FieldVec::iterator field_begin() { return Fields.begin(); }
  FieldVec::iterator field_end() { return Fields.end(); }

  FieldVec::const_iterator field_begin() const { return Fields.begin(); }
  FieldVec::const_iterator field_end() const { return Fields.end(); }

private:

  void delete_epetra_objs();
  
  /**
   * Scatter x to the field(s).
   */
  void scatter_sol();

  FieldVec Fields;
  FieldVec DFields;

  std::vector<DField_type> elem_dofs; // Gather expect
  std::vector<int> elem_dof_signs;  // for sign oriented elements
  std::vector<char> field_on;
  UInt nelem_dofs;
  
  template<typename dof_action>
  void loop_dofs(dof_action&);
  
  Mesh &mesh;
#ifdef ESMCI_TRILINOS
  Epetra_Map *map, *umap;
  Epetra_FECrsMatrix *matrix;
  Epetra_FEVector *x, *b; 
  std::vector<int> my_global,my_owned,my_column;
  std::map<int,int> global2local;
  std::map<int,int> global2local_col;
#endif
  bool has_neg_dofs;
  const LinSysParam &lsp;
};



} // namespace ESMCI

#endif

