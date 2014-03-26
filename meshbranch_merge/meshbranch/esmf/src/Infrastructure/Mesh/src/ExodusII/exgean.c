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
* exgeat - ex_get_elem_attr_names
*
* entry conditions - 
*   input parameters:
*       int     exoid                   exodus file id
*       int     elem_blk_id             element block id
*
* exit conditions - 
*       char*   names[]                 ptr array of attribute names
*
* revision history - 
*
*  $Id: exgean.c,v 1.1.2.1 2009/02/03 22:30:54 amikstcyr Exp $
*
*****************************************************************************/

#include "exodusII.h"
#include "exodusII_int.h"

/*
 * reads the attribute names for an element block
 */
int ex_get_elem_attr_names (int   exoid,
			    int   elem_blk_id,
			    char **names)
{
  int varid, numattrdim, elem_blk_id_ndx;
  long num_attr, start[2], count[2];
  char *ptr;
  char errmsg[MAX_ERR_LENGTH];
  int i, j;
  
  exerrval = 0; /* clear error code */

  /* Determine index of elem_blk_id in VAR_ID_EL_BLK array */
  elem_blk_id_ndx = ex_id_lkup(exoid,VAR_ID_EL_BLK,elem_blk_id);
  if (exerrval != 0) 
  {
    if (exerrval == EX_NULLENTITY)
    {
      sprintf(errmsg,
              "Warning: no attributes found for NULL block %d in file id %d",
              elem_blk_id,exoid);
      ex_err("ex_get_elem_attr_names",errmsg,EX_MSG);
      return (EX_WARN);              /* no attributes for this element block */
    }
    else
    {
      sprintf(errmsg,
      "Warning: failed to locate element block id %d in %s array in file id %d",
              elem_blk_id,VAR_ID_EL_BLK, exoid);
      ex_err("ex_get_elem_attr_names",errmsg,exerrval);
      return (EX_WARN);
    }
  }


/* inquire id's of previously defined dimensions  */

  if ((numattrdim = ncdimid(exoid, DIM_NUM_ATT_IN_BLK(elem_blk_id_ndx))) == -1)
  {
    exerrval = ncerr;
    sprintf(errmsg,
            "Warning: no attributes found for block %d in file id %d",
            elem_blk_id,exoid);
    ex_err("ex_get_elem_attr_names",errmsg,EX_MSG);
    return (EX_WARN);              /* no attributes for this element block */
  }

  if (ncdiminq (exoid, numattrdim, (char *) 0, &num_attr) == -1)
  {
    exerrval = ncerr;
    sprintf(errmsg,
         "Error: failed to get number of attributes for block %d in file id %d",
            elem_blk_id,exoid);
    ex_err("ex_get_elem_attr_names",errmsg,exerrval);
    return (EX_FATAL);
  }

  /* It is OK if we don't find the attribute names since they were
     added at version 4.26; earlier databases won't have the names.
  */
  varid = ncvarid (exoid, VAR_NAME_ATTRIB(elem_blk_id_ndx));

/* read in the attributes */

  if (varid != -1) {
    /* read the names */
    for (i=0; i < num_attr; i++) {
      start[0] = i;
      start[1] = 0;
      
      j = 0;
      ptr = names[i];
      
      if (ncvarget1 (exoid, varid, start, ptr) == -1) {
	exerrval = ncerr;
	sprintf(errmsg,
		"Error: failed to get names for block %d in file id %d",
		elem_blk_id, exoid);
	ex_err("ex_get_elem_attr_names",errmsg,exerrval);
	return (EX_FATAL);
      }
      
      while ((*ptr++ != '\0') && (j < MAX_STR_LENGTH)) {
	start[1] = ++j;
	if (ncvarget1 (exoid, varid, start, ptr) == -1) {
	  exerrval = ncerr;
	  sprintf(errmsg,
		  "Error: failed to get names for block %d in file id %d",
		  elem_blk_id, exoid);
	  ex_err("ex_get_elem_attr_names",errmsg,exerrval);
	  return (EX_FATAL);
	}
       }
       --ptr;
       if (ptr > names[i]) {
	 /*    get rid of trailing blanks */
	 while (*(--ptr) == ' ');
       }
       *(++ptr) = '\0';
     }
   } else {
     /* Names variable does not exist on the database; probably since this is an
      * older version of the database.  Return an empty array...
      */
     for (i=0; i<num_attr; i++) {
       names[i] = '\0';
     }
   }
  return(EX_NOERR);
}
