/*
 * Copyright (c) 2005 Sandia Corporation. Under the terms of Contract
 * DE-AC04-94AL85000 with Sandia Corporation, the U.S. Governement
 * retains certain rights in this software.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 * 
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.  
 * 
 *     * Neither the name of Sandia Corporation nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 */
/*****************************************************************************
*
* expeat - ex_put_elem_attr_names
*
* entry conditions - 
*   input parameters:
*       int     exoid                   exodus file id
*       int     elem_blk_id             element block id
*       char*   names                   ptr array of attribute names

*
* exit conditions - 
*
* revision history - 
*
*  $Id: expean.c,v 1.1.2.1 2009/02/03 22:30:57 amikstcyr Exp $
*
*****************************************************************************/

#include "exodusII.h"
#include "exodusII_int.h"
#include <string.h>

/*!
 * writes the attribute names for an element block
 */
int ex_put_elem_attr_names(int   exoid,
			   int   elem_blk_id,
			   char *names[])
{
   int varid, numattrdim, elem_blk_id_ndx;
   long num_attr, start[2], count[2];
   char errmsg[MAX_ERR_LENGTH];
   int i;
   
   exerrval = 0; /* clear error code */

  /* Determine index of elem_blk_id in VAR_ID_EL_BLK array */
  elem_blk_id_ndx = ex_id_lkup(exoid,VAR_ID_EL_BLK,elem_blk_id);
  if (exerrval != 0) 
  {
    if (exerrval == EX_NULLENTITY)
    {
      sprintf(errmsg,
              "Warning: no attributes allowed for NULL block %d in file id %d",
              elem_blk_id,exoid);
      ex_err("ex_put_elem_attr_names",errmsg,EX_MSG);
      return (EX_WARN);              /* no attributes for this element block */
    }
    else
    {
      sprintf(errmsg,
             "Error: no element block id %d in %s array in file id %d",
              elem_blk_id, VAR_ID_EL_BLK, exoid);
      ex_err("ex_put_elem_attr_names",errmsg,exerrval);
      return (EX_FATAL);
    }
  }

  /* inquire id's of previously defined dimensions  */
  if ((numattrdim = ncdimid(exoid, DIM_NUM_ATT_IN_BLK(elem_blk_id_ndx))) == -1)
  {
    exerrval = ncerr;
    sprintf(errmsg,
           "Error: number of attributes not defined for block %d in file id %d",
            elem_blk_id,exoid);
    ex_err("ex_put_elem_attr_names",errmsg,EX_MSG);
    return (EX_FATAL);              /* number of attributes not defined */
  }

  if (ncdiminq (exoid, numattrdim, (char *) 0, &num_attr) == -1)
  {
    exerrval = ncerr;
    sprintf(errmsg,
         "Error: failed to get number of attributes for block %d in file id %d",
            elem_blk_id,exoid);
    ex_err("ex_put_elem_attr_names",errmsg,exerrval);
    return (EX_FATAL);
  }

  if ((varid = ncvarid (exoid, VAR_NAME_ATTRIB(elem_blk_id_ndx))) == -1) {
    exerrval = ncerr;
    sprintf(errmsg,
	    "Error: failed to locate element attribute names for block %d in file id %d",
	    elem_blk_id, exoid);
    ex_err("ex_put_elem_attr_names",errmsg,exerrval);
    return (EX_FATAL);
     }

  /* write out the attributes  */
  for (i = 0; i < num_attr; i++) {
    start[0] = i;
    start[1] = 0;

    count[0] = 1;
    count[1] = strlen(names[i])+1;

    if (ncvarput (exoid, varid, start, count, (void*) names[i]) == -1) {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to put attribute namess for block %d in file id %d",
	      elem_blk_id,exoid);
      ex_err("ex_put_elem_attr_names",errmsg,exerrval);
      return (EX_FATAL);
    }
  }
  return(EX_NOERR);
}
