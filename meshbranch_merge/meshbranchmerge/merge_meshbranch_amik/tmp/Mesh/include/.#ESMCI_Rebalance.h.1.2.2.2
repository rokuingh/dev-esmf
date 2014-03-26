#ifndef ESMCI_Rebalance_h
#define ESMCI_Rebalance_h

#include <Mesh/include/ESMCI_MEField.h>
#include <Mesh/include/ESMCI_CommRel.h>

#include <Mesh/src/Zoltan/zoltan.h>

namespace ESMCI {

  class Mesh;
  class CommReg;

  // Re load balance the mesh.
  // We only provide rebalance at the granularity of the Genesis mesh.
  // Returns false if no rebalancing is needed.
  //
  // Mesh must be in a consistent state before this is called
  // If bfield is present, will use the weights in this field.
  // Field should be a single entry element field.

  bool Rebalance(Mesh &mesh, MEField<> *bfield=0);

  bool Rebalance(Mesh &mesh, CommReg &comm);

  // Gives lower level control to the user.

  class LoadBalance {
   
  public:

    LoadBalance(Mesh&);
 
    void AddUserWeightField( MEField<> *);
    void AddCommReg(CommReg &);
    void AddZoltanOption(std::string,std::string);

    bool Rebalance();

  private:

    Mesh *pMesh;   
    static struct Zoltan_Struct *zz;
    std::vector<std::string> ZoltanOptLHS, ZoltanOptRHS;
    MEField<> *pMEField;
    CommReg *pCommReg;
    bool is_user_options;

    // Zoltan interface.
    typedef std::vector<MeshObj*> MeshObjVect;
    
    struct zoltan_user_data {
      Mesh *mesh;
      MeshObjVect gen_elem;
      MEField<> *bfield;
    };
    
    static bool   form_rebalance_comm(struct Zoltan_Struct*,Mesh &mesh, CommReg &migration, MEField<> *bfield);
    static void   set_new_obj_owners(Mesh &mesh, CommReg &migration, UInt obj_type);
    static void   set_new_elem_owners(Mesh &mesh, CommReg &migration);  
    static void   build_obj_migration(Mesh &mesh, CommReg &migration, UInt obj_type);

    static void   resolve_rebalance_ownership(Mesh &mesh);
    static void   add_obj_children(MeshObj &obj, std::vector<CommRel::CommNode> &cnodes, UInt P);
    static void   build_obj_migration_recursive(MeshObj &obj, std::vector<CommRel::CommNode> &cnodes, UInt P, UInt obj_type);
    static void   recursive_elem_owner(MeshObj &elem, UInt owner);
    static void   build_lists(Mesh &mesh, MeshObjVect &gen_elem);
    static int    num_children(MeshObj &obj);
    static double children_weight(MeshObj &obj, MEField<> *bfield);
    static int    GetNumAssignedObj(void *user, int *err);

    static void   GetObjList(void *user, int numGlobalIds, int numLids, ZOLTAN_ID_PTR gids, ZOLTAN_ID_PTR lids,
			     int wgt_dim, float *obj_wghts, int *err);

    static int    GetNumGeom(void *user, int *err);

    static void   GetObject(void *user, int numGlobalIds, int numLids, int numObjs,
			    ZOLTAN_ID_PTR gids, ZOLTAN_ID_PTR lids, int numDim, double *pts, int *err); 

    static void   GetEdgeList(void *user, int numGlobalIds, int numLids, int numObjs,
			      ZOLTAN_ID_PTR gids, ZOLTAN_ID_PTR lids, int *numEdges, 
			      ZOLTAN_ID_PTR nborGlobalIds,int* nborProcs, int wgtDim, 
			      float *edgeWgts, int *err);
    
    static void   GetNumEdges(void *user, int num_gid_entries, int num_lid_entries, 
			      int num_obj, ZOLTAN_ID_PTR global_ids, ZOLTAN_ID_PTR local_ids, 
			      int *num_edges, int *err);
    
    static bool   form_rebalance_comm(Mesh &mesh, CommReg &migration, MEField<> *bfield);

    bool Rebalance(Mesh &mesh, MEField<> *bfield=0);
    bool Rebalance(Mesh &mesh, CommReg &comm);
    
  };



} // namespace

#endif
