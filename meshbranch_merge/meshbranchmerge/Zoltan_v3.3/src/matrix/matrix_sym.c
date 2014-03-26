/*****************************************************************************
 * Zoltan Library for Parallel Applications                                  *
 * Copyright (c) 2009 Sandia National Laboratories.                          *
 * For more info, see the README file in the top-level Zoltan directory.     *
 *****************************************************************************/
/*****************************************************************************
 * CVS File Information :
 *    $RCSfile$
 *    $Author$
 *    $Date$
 *    Revision$
 ****************************************************************************/

#ifdef __cplusplus
/* if C++, define the rest of this header file as extern C */
extern "C" {
#endif

#include <math.h>
#include "zz_const.h"
#include "zz_util_const.h"
#include "zoltan_dd.h"
#include "phg.h"
#include "matrix.h"

int
Zoltan_Matrix_Sym(ZZ* zz, Zoltan_matrix *matrix, int bipartite)
{
  static char *yo = "Zoltan_Matrix_Sym";
  int ierr = ZOLTAN_OK;
  Zoltan_Arc *tr_tab = NULL;
  int i, j, cnt;
  ZOLTAN_ID_PTR yGID = NULL;
  int *ypid=NULL;
  float *pinwgt=NULL;
  int * ybipart = NULL;

  ZOLTAN_TRACE_ENTER(zz, yo);
  if (bipartite || !matrix->opts.enforceSquare) {
    matrix->bipartite = 1;
    matrix->redist = 1;
  }

  if (matrix->ywgtdim != zz->Obj_Weight_Dim)
      FATAL_ERROR("Cannot form bipartite graph: vertex and edge weights are not consistant");

  matrix->opts.symmetrize = 1;

  /* Update the data directories */
  tr_tab = (Zoltan_Arc*) ZOLTAN_MALLOC(sizeof(Zoltan_Arc)*(matrix->nPins*2+matrix->nY));
  if (matrix->nPins && tr_tab == NULL) MEMORY_ERROR;

  pinwgt = (float*)ZOLTAN_MALLOC((matrix->nPins*2+matrix->nY)*matrix->pinwgtdim*sizeof(float));
  for (i = 0 ; i < 2 ; ++i) /* Copy pin weights */
    memcpy(pinwgt + i*matrix->nPins*matrix->pinwgtdim*sizeof(float),
	   matrix->pinwgt, matrix->nPins*matrix->pinwgtdim*sizeof(float));

  for (i=0, cnt = 0 ; i < matrix->nY ; ++i) {
    for (j = matrix->ystart[i] ; j < matrix->yend[i] ; ++j) {
      tr_tab[cnt].GNO[0] = matrix->yGNO[i] + bipartite*matrix->globalX;   /* Normal arc */
      tr_tab[cnt].GNO[1] = matrix->pinGNO[j];
      memcpy(pinwgt + cnt*matrix->pinwgtdim, matrix->pinwgt+j*matrix->pinwgtdim,
	     matrix->pinwgtdim*sizeof(float));
      cnt ++;

      tr_tab[cnt].GNO[0] = matrix->pinGNO[j];                        /* Symmetric arc */
      tr_tab[cnt].GNO[1] = matrix->yGNO[i] + bipartite*matrix->globalX; /* new ordering */
      memcpy(pinwgt + cnt*matrix->pinwgtdim, matrix->pinwgt+j*matrix->pinwgtdim,
	     matrix->pinwgtdim*sizeof(float));
      cnt ++;
    }
    if (matrix->ystart[i] == matrix->yend[i]) { /* Singleton */
      tr_tab[cnt].GNO[0] = matrix->yGNO[i] + bipartite*matrix->globalX;   /* Normal arc */
      tr_tab[cnt].GNO[1] = -1;
      cnt ++;
    }
  }
  ZOLTAN_FREE(&matrix->pinwgt);

  Zoltan_Matrix_Remove_DupArcs(zz, cnt, tr_tab, pinwgt, matrix);
  ZOLTAN_FREE(&tr_tab);
  ZOLTAN_FREE(&pinwgt);

  if (bipartite) {
    int endX;
    int * yGNO = NULL;

    /* Update data directories */
    yGID = ZOLTAN_MALLOC_GID_ARRAY(zz, matrix->nY);
    ypid = (int*) ZOLTAN_MALLOC(matrix->nY*sizeof(int));

    ybipart = (int*) ZOLTAN_MALLOC(matrix->nY*sizeof(int));

    for (endX = 0 ; endX < matrix->nY ; ++endX) {
      if (matrix->yGNO[endX] >= matrix->globalX)
	break;
      ybipart[endX] = 0;
    }
    /* Get Informations about X */
    Zoltan_DD_Find (matrix->ddX, (ZOLTAN_ID_PTR)matrix->yGNO, yGID, (ZOLTAN_ID_PTR)ypid, NULL,
		    endX, NULL);

    yGNO = (int*)ZOLTAN_MALLOC(endX*sizeof(int));
    for (i = endX ; i < matrix->nY ; ++i) {
      yGNO[i-endX] = matrix->yGNO[i] - matrix->globalX;
      /* TODO: add a something to have the correct ypid */
      ybipart[endX] = 1;
    }
    /* Get Informations about Y */
    Zoltan_DD_Find (matrix->ddY, (ZOLTAN_ID_PTR)yGNO,
		    yGID + endX*zz->Num_GID,
		    NULL, NULL,
		    matrix->nY-endX, NULL);

    if (matrix->ddY != matrix->ddX)
      Zoltan_DD_Destroy (&matrix->ddY);
    Zoltan_DD_Destroy (&matrix->ddX);

    matrix->globalX += matrix->globalY;
    matrix->globalY = matrix->globalX;

    /* I store : xGNO, xGID, xpid, bipart */
    ierr = Zoltan_DD_Create (&matrix->ddX, zz->Communicator, 1, zz->Num_GID,
			     1, matrix->globalX/zz->Num_Proc, 0);
    matrix->ddY = matrix->ddX;
    /* Hope a linear assignment will help a little */
    Zoltan_DD_Set_Neighbor_Hash_Fn1(matrix->ddX, matrix->globalX/zz->Num_Proc);
    /* Associate all the data with our xyGNO */
    Zoltan_DD_Update (matrix->ddX, (ZOLTAN_ID_PTR)matrix->yGNO, yGID, (ZOLTAN_ID_PTR)ypid, ybipart,
		      matrix->nY);
  }

 End:
  ZOLTAN_FREE(&ybipart);
  ZOLTAN_FREE(&ypid);
  ZOLTAN_FREE(&pinwgt);
  ZOLTAN_FREE(&yGID);
  ZOLTAN_FREE(&tr_tab);

  ZOLTAN_TRACE_EXIT(zz, yo);
  return (ierr);
}


#ifdef __cplusplus
}
#endif
