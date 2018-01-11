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
  ESMC_Grid srcgrid, dstgrid;
  int *maxIndex;
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

#if 0
  grid = ESMC_GridCreateFromFile("data/ll2.5deg_grid.nc",
                                 ESMC_FILEFORMAT_SCRIP, NULL, NULL,
                                 NULL, NULL, NULL, NULL, NULL, NULL, NULL, &rc);
  if (rc != ESMF_SUCCESS) return 0;

  mesh = ESMC_MeshCreateFromFile("data/mpas_uniform_10242_dual_counterclockwise.nc",
                                 ESMC_FILEFORMAT_ESMFMESH, NULL, NULL,
                                 NULL, NULL, NULL, &rc);
  if (rc != ESMF_SUCCESS) return 0;
#endif

  int m = 8;
  int n = 9;

  int dimcount = 2;
  maxIndex = (int *)malloc(dimcount*sizeof(int));
  maxIndex[0] = m;
  maxIndex[1] = m;
  rc = ESMC_InterArrayIntSet(&i_maxIndex, maxIndex, dimcount);

  ESMC_IndexFlag indexflag = ESMC_INDEX_GLOBAL;
  srcgrid = ESMC_GridCreateNoPeriDim(&i_maxIndex, NULL, NULL, &indexflag, &rc);
  if (rc != ESMF_SUCCESS) return 0;

  maxIndex[0] = m;
  maxIndex[1] = m;

  dstgrid = ESMC_GridCreateNoPeriDim(&i_maxIndex, NULL, NULL, &indexflag, &rc);
  if (rc != ESMF_SUCCESS) return 0;

    int *exLBound = NULL;
    int *exUBound = NULL;
    int p = 0;

    ESMC_GridAddCoord(srcgrid, ESMC_STAGGERLOC_CENTER);

    exLBound = (int *)malloc(dimcount*sizeof(int));
    exUBound = (int *)malloc(dimcount*sizeof(int));

    double *gridXCoord = (double *)ESMC_GridGetCoord(srcgrid, 1,
                                                     ESMC_STAGGERLOC_CENTER, NULL,
                                                     exLBound, exUBound, &rc);

    double *gridYCoord = (double *)ESMC_GridGetCoord(srcgrid, 2,
                                                     ESMC_STAGGERLOC_CENTER, NULL,
                                                     NULL, NULL, &rc);

    // printf("PET%d: lbnd, ubnd    %d    %d    %d    %d\n", localPet, exLBound[0], exLBound[1], exUBound[0], exUBound[1]);

    p = 0;
    for (int i1=exLBound[1]; i1<=exUBound[1]; ++i1) {
      for (int i0=exLBound[0]; i0<=exUBound[0]; ++i0) {
        gridXCoord[p]=i0;
        gridYCoord[p]=i1;
        ++p;
      }
    }

    ESMC_GridAddCoord(dstgrid, ESMC_STAGGERLOC_CENTER);

    exLBound = (int *)malloc(dimcount*sizeof(int));
    exUBound = (int *)malloc(dimcount*sizeof(int));

    gridXCoord = (double *)ESMC_GridGetCoord(dstgrid, 1,
                                                     ESMC_STAGGERLOC_CENTER, NULL,
                                                     exLBound, exUBound, &rc);

    gridYCoord = (double *)ESMC_GridGetCoord(dstgrid, 2,
                                                     ESMC_STAGGERLOC_CENTER, NULL,
                                                     NULL, NULL, &rc);

    // printf("exLBounds = [%d,%d]\n", exLBound[0], exLBound[1]);
    // printf("exUBounds = [%d,%d]\n", exUBound[0], exUBound[1]);

    p = 0;
    for (int i1=exLBound[1]; i1<=exUBound[1]; ++i1) {
      for (int i0=exLBound[0]; i0<=exUBound[0]; ++i0) {
        gridXCoord[p]=i0;
        gridYCoord[p]=i1;
        ++p;
      }
    }

  //----------------------------------------------------------------------------
  //---------------------- FIELD CREATION --------------------------------------
  //----------------------------------------------------------------------------

  srcfield = ESMC_FieldCreateGridTypeKind(srcgrid, ESMC_TYPEKIND_R8,
    ESMC_STAGGERLOC_CENTER, NULL, NULL, NULL, "srcfield", &rc);
  if (rc != ESMF_SUCCESS) return 0;

  dstfield = ESMC_FieldCreateGridTypeKind(dstgrid, ESMC_TYPEKIND_R8,
    ESMC_STAGGERLOC_CENTER, NULL, NULL, NULL, "dstfield", &rc);
  if (rc != ESMF_SUCCESS) return 0;


  // get and fill first coord array and computational bounds
  exLBound = (int *)malloc(dimcount*sizeof(int));
  exUBound = (int *)malloc(dimcount*sizeof(int));

  rc = ESMC_FieldGetBounds(srcfield, 0, exLBound, exUBound, dimcount);
  if (rc != ESMF_SUCCESS) return 0;

  double * srcfieldptr = (double *)ESMC_FieldGetPtr(srcfield, 0, &rc);
  if (rc != ESMF_SUCCESS) return 0;

  p = 0;
  for (int i1=exLBound[1]; i1<=exUBound[1]; ++i1) {
    for (int i0=exLBound[0]; i0<=exUBound[0]; ++i0) {
      srcfieldptr[p] = 42.0;
      p++;
    }
  }

  // get and fill first coord array and computational bounds
  int *exLBound2 = (int *)malloc(dimcount*sizeof(int));
  int *exUBound2 = (int *)malloc(dimcount*sizeof(int));

  rc = ESMC_FieldGetBounds(dstfield, 0, exLBound2, exUBound2, dimcount);
  if (rc != ESMF_SUCCESS) return 0;

  double * dstfieldptr = (double *)ESMC_FieldGetPtr(dstfield, 0, &rc);
  if (rc != ESMF_SUCCESS) return 0;

  // initialize destination field
  p = 0;
  for (int i1=exLBound2[1]; i1<=exUBound2[1]; ++i1) {
    for (int i0=exLBound2[0]; i0<=exUBound2[0]; ++i0) {
      dstfieldptr[p] = 0.0;
      p++;
    }
  }

  //----------------------------------------------------------------------------
  //-------------------------- REGRIDDING --------------------------------------
  //----------------------------------------------------------------------------

  rc = ESMC_FieldRegridStore(srcfield, dstfield, NULL, NULL, &routehandle,
                             NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
  if (rc != ESMF_SUCCESS) return 0;

#if 0
  rc = ESMC_FieldRegridStoreFile(srcfield, dstfield, "data/weights.nc", NULL, NULL,
                                 &routehandle, NULL, NULL, NULL, NULL, NULL,
                                 NULL, NULL, NULL, NULL);
  if (rc != ESMF_SUCCESS) return 0;

  printf("srcfield before smmstore = [\n");
  p = 0;
  for (int i1=exLBound[1]; i1<=exUBound[1]; ++i1) {
    for (int i0=exLBound[0]; i0<=exUBound[0]; ++i0) {
      printf("%f, ", srcfieldptr[p]);
      p++;
    }
  }
  printf("]\n");

  rc = ESMC_FieldSMMStore(srcfield, dstfield, "data/weights_generic.nc", &routehandle,
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

  //rc = ESMC_FieldRegrid(srcfield, dstfield, routehandle, NULL);
  if (rc != ESMF_SUCCESS) return 0;
#endif

  rc = ESMC_FieldRegridRelease(&routehandle);
  if (rc != ESMF_SUCCESS) return 0;

  free(exLBound);
  free(exUBound);
  free(exLBound2);
  free(exUBound2);

  rc = ESMC_FieldDestroy(&srcfield);
  rc = ESMC_FieldDestroy(&dstfield);
  rc = ESMC_GridDestroy(&srcgrid);
  rc = ESMC_GridDestroy(&dstgrid);

  ESMC_Finalize();
  
  return 0;
  
}
