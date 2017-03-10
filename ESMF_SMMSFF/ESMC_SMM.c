// Earth System Modeling Framework
// Copyright 2002-2016, University Corporation for Atmospheric Research,
// Massachusetts Institute of Technology, Geophysical Fluid Dynamics
// Laboratory, University of Michigan, National Centers for Environmental
// Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
// NASA Goddard Space Flight Center.
// Licensed under the University of Illinois-NCSA License.

#include <stdlib.h>
#include <stdio.h>
#include "ESMC.h"

int main(void){

  // VM variables
  int localPet, petCount, rc;
  ESMC_VM vm;

  ESMC_RouteHandle routehandle;
  ESMC_Field srcfield, dstfield;
  ESMC_Grid grid;
  ESMC_Mesh mesh;
  ESMC_InterArrayInt i_maxIndex;

  ESMC_Initialize(NULL, ESMC_ArgLast);

  // Get parallel information
  vm=ESMC_VMGetGlobal(&rc);
  if (rc != ESMF_SUCCESS) return 0;

  rc=ESMC_VMGet(vm, &localPet, &petCount, (int *)NULL, (MPI_Comm *)NULL,
                (int *)NULL, (int *)NULL);
  if (rc != ESMF_SUCCESS) return 0;

  rc=ESMC_LogSet(true);

  //----------------------------------------------------------------------------
  //----------------------- GRID CREATION --------------------------------------
  //----------------------------------------------------------------------------

  grid = ESMC_GridCreateFromFile("data/ll2.5deg_grid.nc",
                                 ESMC_FILEFORMAT_SCRIP, NULL, NULL,
                                 NULL, NULL, NULL, NULL, NULL, NULL, NULL, &rc);
  if (rc != ESMF_SUCCESS) return 0;

  mesh = ESMC_MeshCreateFromFile("data/mpas_uniform_10242_dual_counterclockwise.nc",
                                 ESMC_FILEFORMAT_ESMFMESH, NULL, NULL,
                                 NULL, NULL, NULL, &rc);
  if (rc != ESMF_SUCCESS) return 0;


  //----------------------------------------------------------------------------
  //---------------------- FIELD CREATION --------------------------------------
  //----------------------------------------------------------------------------

  dstfield = ESMC_FieldCreateGridTypeKind(grid, ESMC_TYPEKIND_R8,
    ESMC_STAGGERLOC_CENTER, NULL, NULL, NULL, "srcfield", &rc);
  if (rc != ESMF_SUCCESS) return 0;

  srcfield = ESMC_FieldCreateMeshTypeKind(mesh,
    ESMC_TYPEKIND_R8, ESMC_MESHLOC_ELEMENT, NULL, NULL, NULL, "dstfield", &rc);
  if (rc != ESMF_SUCCESS) return 0;

  //----------------------------------------------------------------------------
  //-------------------------- REGRIDDING --------------------------------------
  //----------------------------------------------------------------------------

  // get and fill first coord array and computational bounds
  int *exLBound = (int *)malloc(2*sizeof(int));
  int *exUBound = (int *)malloc(2*sizeof(int));

  rc = ESMC_FieldGetBounds(srcfield, 0, exLBound, exUBound, 2);
  if (rc != ESMF_SUCCESS) return 0;

  double * srcfieldptr = (double *)ESMC_FieldGetPtr(srcfield, 0, &rc);
  if (rc != ESMF_SUCCESS) return 0;

  int p = 0;
  for (int i1=exLBound[1]; i1<=exUBound[1]; ++i1) {
    for (int i0=exLBound[0]; i0<=exUBound[0]; ++i0) {
      srcfieldptr[p] = 42.0;
      p++;
    }
  }

  // get and fill first coord array and computational bounds
  int *exLBound2 = (int *)malloc(1*sizeof(int));
  int *exUBound2 = (int *)malloc(1*sizeof(int));

  rc = ESMC_FieldGetBounds(dstfield, 0, exLBound2, exUBound2, 1);
  if (rc != ESMF_SUCCESS) return 0;

  double * dstfieldptr = (double *)ESMC_FieldGetPtr(dstfield, 0, &rc);
  if (rc != ESMF_SUCCESS) return 0;

  // initialize destination field
  p = 0;
  for (int i0=exLBound2[0]; i0<=exUBound2[0]; ++i0) {
    dstfieldptr[p] = 0.0;
    p++;
  }

  rc = ESMC_FieldRegridStoreFile(srcfield, dstfield, "data/weights.nc", NULL, NULL,
                                 &routehandle, NULL, NULL, NULL, NULL, NULL,
                                 NULL, NULL, NULL, NULL);
  if (rc != ESMF_SUCCESS) return 0;

  rc = ESMC_FieldSMMStore(srcfield, dstfield, "data/weights.nc", &routehandle,
                          NULL, NULL, NULL, NULL);
  if (rc != ESMF_SUCCESS) return 0;

  printf("srcfield = [\n");
  p = 0;
  for (int i1=exLBound[1]; i1<=exUBound[1]; ++i1) {
    for (int i0=exLBound[0]; i0<=exUBound[0]; ++i0) {
      printf("%f, ", srcfieldptr[p]);
      p++;
    }
  }
  printf("]\n");


  rc = ESMC_FieldRegrid(srcfield, dstfield, routehandle, NULL);
  if (rc != ESMF_SUCCESS) return 0;

  rc = ESMC_FieldRegridRelease(&routehandle);
  if (rc != ESMF_SUCCESS) return 0;

  free(exLBound);
  free(exUBound);
  free(exLBound2);
  free(exUBound2);

  rc = ESMC_FieldDestroy(&srcfield);
  rc = ESMC_FieldDestroy(&dstfield);
  rc = ESMC_GridDestroy(&grid);
  rc = ESMC_MeshDestroy(&mesh);

  ESMC_Finalize();
  
  return 0;
  
}
