// Earth System Modeling Framework
// Copyright 2002-2017, University Corporation for Atmospheric Research,
// Massachusetts Institute of Technology, Geophysical Fluid Dynamics
// Laboratory, University of Michigan, National Centers for Environmental
// Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
// NASA Goddard Space Flight Center.
// Licensed under the University of Illinois-NCSA License.


#include <stdio.h>
#include "ESMC.h"

#include </home/ryan/sandbox/esmf/src/Infrastructure/Mesh/include/ESMCI_MBMesh.h>
#include </home/ryan/sandbox/esmf/src/Infrastructure/Mesh/include/ESMCI_MBMesh_Glue.h>


using namespace ESMCI;

MBMesh* create_mesh_simple_triangles(int &rc) {
  //

  //  1.0   3 -------- 4
  //  0.75  |  \    12 |
  //        |    \     |
  //  0.25  |  11   \  |
  //  0.0   1 -------- 2
  //
  //       0.0 .25 .75 1.0
  //
  //      Node Ids at corners
  //      Element Ids in centers
  //
  //
  //      ( Everything owned by PET 0)
  //

  rc = ESMF_RC_NOT_IMPL;

  int pdim = 2;
  int sdim = 2;

  // set Mesh parameters
  int num_elem = 2;
  int num_node = 4;

  int nodeId_s [] ={1,2,3,4};
  double nodeCoord_s [] ={0.0,0.0, 1.0,0.0,
                          0.0,1.0, 1.0,1.0};
  int nodeOwner_s [] ={0,0,0,0};
  int nodeMask_s [] ={1,1,1,1};
  int elemId_s [] ={11,12};
  // ESMF_MESHELEMTYPE_QUAD
  int elemType_s [] ={ESMC_MESHELEMTYPE_TRI,
                      ESMC_MESHELEMTYPE_TRI};
  int elemConn_s [] ={1,2,3,
                      //2,3,1 works!!
                      2,4,3};
  int elemMask_s [] ={1,1};

  ESMC_CoordSys_Flag local_coordSys=ESMC_COORDSYS_CART;

  int orig_sdim = sdim;

  MBMesh *mesh = new MBMesh();
  void *meshp = static_cast<void *> (mesh);

  MBMesh_create(&meshp, &pdim, &sdim, &local_coordSys, &rc);
  if (rc != ESMF_SUCCESS) return NULL;

  InterArray<int> *ii_node = new InterArray<int>(nodeMask_s,4);

  MBMesh_addnodes(&meshp, &num_node, nodeId_s, nodeCoord_s, nodeOwner_s,
                  ii_node, &local_coordSys, &orig_sdim, &rc);
  if (rc != ESMF_SUCCESS) return NULL;

  InterArray<int> *ii_elem = new InterArray<int>(elemMask_s,2);

  int areapresent = 0;
  int coordspresent = 0;
  int numelemconn = 6;
  int regridconserve = 0;
  MBMesh_addelements(&meshp, &num_elem, elemId_s, elemType_s, ii_elem,
                     &areapresent, NULL,
                     &coordspresent, NULL,
                     &numelemconn, elemConn_s,
                     &regridconserve,
                     &local_coordSys, &orig_sdim, &rc);
  if (rc != ESMF_SUCCESS) return NULL;

  delete ii_node;
  delete ii_elem;

  rc = ESMF_SUCCESS;
  return static_cast<MBMesh *>(meshp);
}

int main(void){

  ESMC_Initialize(NULL, ESMC_ArgLast);
  
  int rc;
  int localPet, petCount;
  ESMC_VM vm;

  //----------------------------------------------------------------------------
  rc=ESMC_LogSet(true);

  //----------------------------------------------------------------------------
  //ESMC_MoabSet(true);

  // Get parallel information
  vm=ESMC_VMGetGlobal(&rc);
  if (rc != ESMF_SUCCESS) return 0;

  rc=ESMC_VMGet(vm, &localPet, &petCount, (int *)NULL, (MPI_Comm *)NULL,
                (int *)NULL, (int *)NULL);
  if (rc != ESMF_SUCCESS) return 0;

  MBMesh *mesh_tri_simple;
  mesh_tri_simple = create_mesh_simple_triangles(rc);

  Interface *mesh = mesh_tri_simple->mesh;

  WriteHDF5(mesh);

  ESMC_Finalize();
  
  return 0;
  
}
