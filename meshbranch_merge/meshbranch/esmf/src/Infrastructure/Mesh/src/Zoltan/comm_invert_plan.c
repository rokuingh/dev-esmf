/*****************************************************************************
 * Zoltan Library for Parallel Applications                                  *
 * Copyright (c) 2000,2001,2002, Sandia National Laboratories.               *
 * This software is distributed under the GNU Lesser General Public License. *
 * For more info, see the README file in the top-level Zoltan directory.     *
 *****************************************************************************/
/*****************************************************************************
 * CVS File Information :
 *    $RCSfile: comm_invert_plan.c,v $
 *    $Author: amikstcyr $
 *    $Date: 2010/02/12 00:19:56 $
 *    Revision: 1.4 $
 ****************************************************************************/

#include <stdio.h>
#include "comm.h"
#include "zoltan_mem.h"

#ifdef __cplusplus
/* if C++, define the rest of this header file as extern C */
extern "C" {
#endif


/* 
 * Given a communication plan, invert the plan for the reverse communication.
 * The sizes in the inverted plan are assumed to be uniform.
 * The input plan is overwritten with the inverted plan.
 * If an error occurs, the old plan is returned unchanged.
 * Note:  receives in new plan are blocked, even if sends in old 
 * plan were not.   This blocking allows variable sized sends to be
 * done with the new plan (Zoltan_Comm_Resize).  However, it also means
 * the new plan can not do exactly what Zoltan_Comm_Do_Reverse can do.
 * If the application cares about the order of received data, it should
 * not use this routine.
 */

int Zoltan_Comm_Invert_Plan(
ZOLTAN_COMM_OBJ **plan 		/* communicator object to be inverted */
)
{
static char *yo = "Zoltan_Comm_Invert_Plan";
ZOLTAN_COMM_OBJ *old = *plan, *nnew = NULL;
int i, ierr = ZOLTAN_OK;
int total_send_length;
int max_recv_length;

  if (old == NULL){
    ZOLTAN_COMM_ERROR("NULL input plan.", yo, -1);
    ierr = ZOLTAN_FATAL;
    goto End;
  }

  total_send_length = 0;
  for (i = 0; i < old->nsends + old->self_msg; i++) {
    total_send_length += old->lengths_to[i];
  }

  max_recv_length = 0;
  for (i = 0; i < old->nrecvs; i++) {
    if (old->lengths_from[i] > max_recv_length)
      max_recv_length = old->lengths_from[i];
  }

  nnew = (ZOLTAN_COMM_OBJ *) ZOLTAN_MALLOC(sizeof(ZOLTAN_COMM_OBJ));
  if (!nnew) {
    ierr = ZOLTAN_MEMERR;
    goto End;
  }
  nnew->lengths_to = old->lengths_from;
  nnew->starts_to = old->starts_from;
  nnew->procs_to = old->procs_from;
  nnew->indices_to = old->indices_from;
  nnew->lengths_from = old->lengths_to;
  nnew->starts_from = old->starts_to;
  nnew->procs_from = old->procs_to;
  nnew->indices_from = NULL;    /* In new plan, receives are blocked. */

  /* Assumption:  uniform object sizes in output plans.   */
  /* Can be changed by later calls to Zoltan_Comm_Resize. */
  nnew->sizes = NULL;
  nnew->sizes_to = NULL;
  nnew->sizes_from = NULL;
  nnew->starts_to_ptr = NULL;
  nnew->starts_from_ptr = NULL;
  nnew->indices_to_ptr = NULL;
  nnew->indices_from_ptr = NULL;

  nnew->nvals = old->nvals_recv;
  nnew->nvals_recv = old->nvals;
  nnew->nrecvs = old->nsends;
  nnew->nsends = old->nrecvs;
  nnew->self_msg = old->self_msg;
  nnew->max_send_size = max_recv_length;
  nnew->total_recv_size = total_send_length;
  nnew->comm = old->comm;
  nnew->maxed_recvs = 0;

  if (MPI_RECV_LIMIT > 0){
    /* If we have a limit to the number of posted receives we are allowed,
    ** and our plan has exceeded that, then switch to an MPI_Alltoallv so
    ** that we will have fewer receives posted when we do the communication.
    */
    MPI_Allreduce(&nnew->nrecvs, &i, 1, MPI_INT, MPI_MAX, nnew->comm);
    if (i > MPI_RECV_LIMIT){
      nnew->maxed_recvs = 1;
    }
  }

  if (nnew->maxed_recvs){
    nnew->request = NULL;
    nnew->status = NULL;
  }
  else{
    nnew->request = (MPI_Request *) ZOLTAN_MALLOC(nnew->nrecvs*sizeof(MPI_Request));
    nnew->status = (MPI_Status *) ZOLTAN_MALLOC(nnew->nrecvs*sizeof(MPI_Status));
    if (nnew->nrecvs && ((nnew->request == NULL) || (nnew->status == NULL))) {
      ierr = ZOLTAN_MEMERR;
      goto End;
    }
  }

End:
  if (ierr == ZOLTAN_OK) {
    if (old->indices_to)       ZOLTAN_FREE(&(old->indices_to));
    if (old->sizes)            ZOLTAN_FREE(&(old->sizes));
    if (old->sizes_to)         ZOLTAN_FREE(&(old->sizes_to));
    if (old->sizes_from)       ZOLTAN_FREE(&(old->sizes_from));
    if (old->starts_to_ptr)    ZOLTAN_FREE(&(old->starts_to_ptr));
    if (old->starts_from_ptr)  ZOLTAN_FREE(&(old->starts_from_ptr));
    if (old->indices_to_ptr)   ZOLTAN_FREE(&(old->indices_to_ptr));
    if (old->indices_from_ptr) ZOLTAN_FREE(&(old->indices_from_ptr));
    if (old->request)          ZOLTAN_FREE(&(old->request));
    if (old->status)           ZOLTAN_FREE(&(old->status));
    ZOLTAN_FREE(&old);
    *plan = nnew;
  }
  else {
    if (nnew) {
      ZOLTAN_FREE(&(nnew->request));
      ZOLTAN_FREE(&(nnew->status));
      ZOLTAN_FREE(&nnew);
    }
  }
  return (ierr);
}

#ifdef __cplusplus
} /* closing bracket for extern "C" */
#endif
