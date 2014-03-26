#ifndef ESMCI_Interp_h
#define ESMCI_Interp_h

#include <Mesh/include/ESMCI_MEField.h>
#include <Mesh/include/ESMCI_Search.h>
#include <Mesh/include/ESMCI_GeomRendezvous.h>
#include <Mesh/include/ESMCI_Migrator.h>
#include <Mesh/include/ESMCI_SparseMsg.h>
#include <Mesh/include/ESMCI_WMat.h>

#include <vector>
#include <ostream>
#include <map>

namespace ESMCI {
  
class CommRel;
class MeshObj;

/*
 * Provides interpolation for serial and parallel meshes.  For 
 * serial the interpolatin is a simple search/application.  For parallel
 * we use the Rendezvous algorithm of Stewart et al.  The interface
 * is the same for both cases.
 */

class Mesh;
class Geom;

// Store/Migrate interp weights
class IWeights : public WMat {

public:

  IWeights();
  
  IWeights(const IWeights &);
  
  IWeights &operator=(const IWeights &);
    
  /*
   * Gather the tangent vectors for the mesh.  Template class TVECT supports
   * tv()(const MeshObj &node, const MEField<> &coords, double U[], double V[]) 
   * to return the
   * tangent vectors.  The vectors are returned as (U V), a 3x2 matrix, unless
   * transpose=true, where they we be a 2x3 matrix, (U V)^T.
   */ 
  template <typename TVECT>
  void GatherTangentVectors(const Mesh &mesh, TVECT tv, bool transpose = false); 
  
  /*
   * Change a 3d->3d vector matrix into a matrix mapping u,v -> u,v
   * coordinates.
   */
  void ChangeCoords(const IWeights &src_uv, const IWeights &dst_uc);
  
  /*
   * Remove any rows that have a mask value < 1.  Also remove any rows assigned to
   * a node that is not locally owned.
   */
  void Prune(const Mesh &mesh, const MEField<> &mask);
  void Prune(const Mesh &mesh, const MEField<> *mask=0);

};

// Tangent vector support
template <typename TVECT>
void IWeights::GatherTangentVectors(const Mesh &mesh, TVECT tv, bool transpose) {
  
  clear();
  
  Mesh::const_iterator ni = mesh.node_begin(), ne = mesh.node_end();
  
  const MEField<> &coords = *mesh.GetCoordField();
  
  for (; ni != ne; ++ni) {
    
    const MeshObj &node = *ni;
    
    double U[3], V[3];
    
    tv(node, coords, U, V);

    if (!transpose) {
      
      for (UInt r = 0; r < 3; r++) {
        Entry row(node.get_id(), r);
        std::vector<Entry> col(2);
        col[0] = Entry(node.get_id(), 0, U[r]);
        col[1] = Entry(node.get_id(), 1, V[r]);
        InsertRow(row, col);
      } // r
      
    } else {
      for (UInt r = 0; r < 2; r++) {
            Entry row(node.get_id(), r);
            std::vector<Entry> col(3);
            double *val = r == 0 ? U : V;
            col[0] = Entry(node.get_id(), 0, val[0]);
            col[1] = Entry(node.get_id(), 1, val[1]);
            col[2] = Entry(node.get_id(), 2, val[2]);
            InsertRow(row, col);
          } // r
    }
  } // ni
  
}

/*
 * Hold the necessary state to perform an interpolation (either parallel
 * or serial).  The interpolated fields must have a certain uniform nature.
 * In particular, they must all be defined on the same part of the meshes,
 * and the destination fields must all be either nodal or interpolatory,
 * but not mixed.
 * Note: if INTERP_PATCH is used, it is up to the caller to make sure they
 * have ghosting enabled on the mesh.  It will also be their responsibility
 * to make sure the data is halo'ed to the ghosts before the Interp() operation.
 */ 

class Interp {
public:

  // STD means use nodal interpolation, patch patchrecovery, forward_only doesn't interpolate, just makes
  enum {INTERP_STD = 0, INTERP_PATCH, FORWARD_ONLY};
  
  struct FieldPair {
  FieldPair(MEField<> *_sF, MEField<> *_dF, UChar _idata=INTERP_STD, UChar _patch_order=2) :
    first(_sF), second(_dF), idata(_idata), patch_order(_patch_order) {
  }
  MEField<> *first, *second;
  UChar idata; // interpolation specification.
  UChar patch_order;
  };

  // For user defined interpolation derive from this.  This function should
  // interpolate at the parametric points into the results buffer.  The field dimensions
  // of the dest field are the same as for the source field, and the results buffer
  // should have the field dimensions interleaves, i.e. results(npoints, fdim) C order
  class UserFunc {
   public:
   virtual void evaluate(Mesh &srcmesh,
                         const MeshObj &elem,            // source element
                         MEField<> &sfield,        // source field
                         UInt npoints,             // nparametric points
                         const double pcoord[],    // parametric coords of dest points
                         double results[])=0;
  };
  
  /* 
   * Build the interpolation object.  The MEFields must be compatible in the
   * sense that they are all element based, or node based, etc...
   */
  Interp(Mesh &src, Mesh &dest, const std::vector<FieldPair> &Fields, bool is_dg = false);
  
  ~Interp();
  
  // Actually process the interpolation
  void operator()();

  // Interpolate with a user interpolation
  void operator()(UserFunc *uf);
  
  // Form a matrix of the interpolant for the fpair_num field
  void operator()(int fpair_num, IWeights &iw);
  
  private:
  
  void transfer_serial();
  
  void transfer_parallel();
  
  void mat_transfer_serial(int fpair_num, IWeights &);
  
  void mat_transfer_parallel(int fpair_num, IWeights &);
  
  SearchResult sres;
  GeomRend grend;
  std::vector<FieldPair> fpairs;
  bool is_parallel;
  std::vector<MEField<>*> srcF;
  std::vector<MEField<>*> dstF;
  std::vector<_field*> dstf; // interp fields
  std::vector<int> iflag;
  bool has_std; // true if a standard interpolation exists
  bool has_patch; // true if a patch interp exists
  Mesh &srcmesh;
  Mesh &dstmesh;
  UserFunc *ufunc;
  bool is_dg;   // is the dest a dg refinement?
};


  
} // namespace

#endif /*ESMCI_INTERP_H_*/
