// $Id$
//
// Earth System Modeling Framework
// Copyright 2002-2014, University Corporation for Atmospheric Research, 
// Massachusetts Institute of Technology, Geophysical Fluid Dynamics 
// Laboratory, University of Michigan, National Centers for Environmental 
// Prediction, Los Alamos National Laboratory, Argonne National Laboratory, 
// NASA Goddard Space Flight Center.
// Licensed under the University of Illinois-NCSA License.
//
//==============================================================================

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

// ESMF header
#include "ESMC.h"


//==============================================================================
//BOP
// !PROGRAM: ESMC_FieldRegridParUTest - Check ESMC_FieldRegrid functionality
//
// !DESCRIPTION:
//
//EOP
//-----------------------------------------------------------------------------

int main(void){

  // Test variables
  char name[80];
  char failMsg[80];
  int result = 0;
  int rc;

  int localPet, petCount;
  ESMC_VM vm;
  
  // Field variables
  ESMC_ArraySpec arrayspec;
  ESMC_RouteHandle routehandle;
  ESMC_Field srcfield, dstfield, exactfield;

  // Grid variables
  ESMC_Grid srcgrid;
  int dimcount = 2;
  int *maxIndex;
  ESMC_InterfaceInt i_maxIndex;
  int exLB_center[2], exUB_center[2];

  // Mesh variables
  int pdim=2;
  int sdim=2;
  ESMC_Mesh dstmesh;
  int num_elem, num_node;


  // computation variables
  int p;
  double x, y, exact, tol;

  //----------------------------------------------------------------------------
  rc = ESMC_Initialize(NULL, ESMC_ArgLast);
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  // Get parallel information
  vm = ESMC_VMGetGlobal(&rc);
  rc = ESMC_VMGet(vm, &localPet, &petCount, (int *)NULL, (MPI_Comm *)NULL,
                (int *)NULL, (int *)NULL);
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  rc = ESMC_LogSet(true);
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  //----------------------------------------------------------------------------
  //----------------------- Grid CREATION --------------------------------------
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  int addCornerStagger = 1;
  srcgrid = ESMC_GridCreateFromFile(const_cast<char *>("data/T42_grid.nc"), 
                                    ESMC_FILEFORMAT_SCRIP, NULL, 
                                    &addCornerStagger, NULL, NULL, 
                                    const_cast<char *>(""), NULL, &rc);
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  dstmesh = ESMC_MeshCreateFromFile(const_cast<char *>("data/ne15np4_scrip.nc"), 
                                    ESMC_FILEFORMAT_SCRIP, NULL, NULL, 
                                    const_cast<char *>(""), NULL, 
                                    const_cast<char *>(""), &rc);
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  //----------------------------------------------------------------------------
  //---------------------- FIELD CREATION --------------------------------------
  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  srcfield = ESMC_FieldCreateGridTypeKind(srcgrid, ESMC_TYPEKIND_R8, 
    ESMC_STAGGERLOC_CENTER, NULL, NULL, NULL, "srcfield", &rc);
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  //----------------------------------------------------------------------------
  dstfield = ESMC_FieldCreateMeshTypeKind(dstmesh, 
    ESMC_TYPEKIND_R8, ESMC_MESHLOC_ELEMENT, NULL, NULL, NULL, "dstfield", &rc);
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  //----------------------------------------------------------------------------
  exactfield = ESMC_FieldCreateMeshTypeKind(dstmesh, 
    ESMC_TYPEKIND_R8, ESMC_MESHLOC_ELEMENT, NULL, NULL, NULL, "dstfield", &rc);
  //----------------------------------------------------------------------------
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  //----------------------------------------------------------------------------
  //-------------------------- REGRIDDING --------------------------------------
  //----------------------------------------------------------------------------

/*
  //----------------------------------------------------------------------------
  double * srcfieldptr = (double *)ESMC_FieldGetPtr(srcfield, 0, &rc);
  //----------------------------------------------------------------------------

  rc = ESMC_GridGetCoordBounds(srcgrid, ESMC_STAGGERLOC_CENTER, exLB_center,
                               exUB_center, &rc);

  // define analytic field on source field
  p = 0;
  for (int i1=exLB_center[1]; i1<=exUB_center[1]; ++i1) {
    for (int i0=exLB_center[0]; i0<=exUB_center[0]; ++i0) {
      srcfieldptr[p] = 20.0;
      //x = gridXCenter[p];
      //y = gridYCenter[p];
      //srcfieldptr[p] = 20.0+x+y;
      ++p;
    }
  }
  

  //----------------------------------------------------------------------------
  double * dstfieldptr = (double *)ESMC_FieldGetPtr(dstfield, 0, &rc);

  //----------------------------------------------------------------------------
  double * exactptr = (double *)ESMC_FieldGetPtr(exactfield, 0, &rc);

  //----------------------------------------------------------------------------
  int num_onode;
  rc = ESMC_MeshGetOwnedNodeCount(dstmesh, &num_onode);

  int num_oelem;
  rc = ESMC_MeshGetOwnedElementCount(dstmesh, &num_oelem);

  //----------------------------------------------------------------------------


  // initialize destination field
  for(int i=0; i<num_oelem; ++i)
    dstfieldptr[i] = 0.0;

  // initialize destination field
  p = 0;
  for(int i=0; i<num_oelem; ++i) {
    //if (nodeOwner[i] == localPet) {
      //x = nodeCoord[2*i];
      //y = nodeCoord[2*i+1];
      //exactptr[p] = 20.0 + x + y;
      //p++;
    //}
    exactptr[i] = 20.0;
  }
*/

  //----------------------------------------------------------------------------
  ESMC_RegridMethod_Flag regridmethod = ESMC_REGRIDMETHOD_CONSERVE;
  ESMC_UnmappedAction_Flag unmappedaction = ESMC_UNMAPPEDACTION_ERROR;
  rc = ESMC_FieldRegridStore(srcfield, dstfield, NULL, NULL, &routehandle, 
                             &regridmethod, NULL, NULL, &unmappedaction,
                             NULL, NULL);
  /*rc = ESMC_FieldRegrid(srcfield, dstfield, routehandle, NULL);
  rc = ESMC_FieldRegridRelease(&routehandle);*/
  if (rc != ESMF_SUCCESS) ESMC_Finalize();

  //----------------------------------------------------------------------------
  //printf("PET:%d, num_node = %d, num_elem = %d\n", localPet, num_onode, num_oelem);

  //----------------------------------------------------------------------------
  //-------------------------- REGRID VALIDATION -------------------------------
  //----------------------------------------------------------------------------
  /*
  bool correct = true;
  // check destination field against analytic field
  for(int i=0; i<num_oelem; ++i) {
    tol = .0001;
    if (abs(dstfieldptr[i]-exactptr[i]) > tol) {
      printf("PET%d: dstfieldptr[%d]:%f /= %f\n", 
             localPet, i, dstfieldptr[i], exactptr[i]);
      correct=false;
    }
  }
  */

  //----------------------------------------------------------------------------
  printf("FINISHED SUCCESSFULLY\n");

  rc = ESMC_FieldDestroy(&srcfield);
  rc = ESMC_FieldDestroy(&dstfield);
  rc = ESMC_MeshDestroy(&dstmesh);
  rc = ESMC_GridDestroy(&srcgrid);

  //----------------------------------------------------------------------------

  //----------------------------------------------------------------------------
  ESMC_Finalize();
  //----------------------------------------------------------------------------
  
  return 0;
}
