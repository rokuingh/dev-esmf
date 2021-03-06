/*****************************************************************************
 * Zoltan Dynamic Load-Balancing Library for Parallel Applications           *
 * Copyright (c) 2000, Sandia National Laboratories.                         *
 * For more info, see the README file in the top-level Zoltan directory.     *
 *****************************************************************************/
/*****************************************************************************
 * CVS File Information :
 *    $RCSfile$
 *    $Author$
 *    $Date$
 *    Revision: 1.10 $
 ****************************************************************************/

#ifndef __GRAPH_H
#define __GRAPH_H

#ifdef __cplusplus
/* if C++, define the rest of this header file as extern C */
extern "C" {
#endif

#include "matrix.h"

typedef struct ZG_ {
  Zoltan_matrix_2d mtx;
  int         *fixed_vertices;
  int          bipartite;
  int          fixObj;
} ZG;

int
Zoltan_ZG_Build (ZZ* zz, ZG* graph, int local);

int
Zoltan_ZG_Export (ZZ* zz, const ZG* const graph, int *gvtx, int *nvtx, int *obj_wgt_dim, int *edge_wgt_dim,
	   int **vtxdist, int **xadj, int **adjncy, int **adjproc,
	   float **xwgt, float **ewgt, int **partialD2);

int
Zoltan_ZG_Vertex_Info(ZZ* zz, const ZG *const graph,
		      ZOLTAN_ID_PTR *gid, int **input_part);

int
Zoltan_ZG_Register(ZZ* zz, ZG* graph, int* properties);

int
Zoltan_ZG_Query (ZZ* zz, const ZG *graph, const ZOLTAN_ID_PTR GID,
	  int GID_length, int* properties);

void
Zoltan_ZG_Free(ZG *m);


#ifdef __cplusplus
}
#endif

#endif
