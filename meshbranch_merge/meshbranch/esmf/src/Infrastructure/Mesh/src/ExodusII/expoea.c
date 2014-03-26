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
* expoea - ex_put_one_elem_attr
*
* entry conditions - 
*   input parameters:
*       int     exoid                   exodus file id
*       int     elem_blk_id             element block id
*       int     attrib_index            index of attribute to write
*       float*  attrib                  array of attributes
*
* exit conditions - 
*
* revision history - 
*
*  $Id: expoea.c,v 1.1.2.1 2009/02/03 22:30:57 amikstcyr Exp $
*
*****************************************************************************/

#include "exodusII.h"
#include "exodusII_int.h"

/*!
 * writes the specified attribute for an element block
 */

int ex_put_one_elem_attr (int   exoid,
			  int   elem_blk_id,
			  int   attrib_index,
			  const void *attrib)
{
  int numelbdim, numattrdim, attrid, elem_blk_id_ndx;
  long num_elem_this_blk, num_attr;
  size_t start[2], count[2];
  ptrdiff_t stride[2];
  int error;
  char errmsg[MAX_ERR_LENGTH];

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
	  ex_err("ex_put_one_elem_attr",errmsg,EX_MSG);
	  return (EX_WARN);              /* no attributes for this element block */
	}
      else
	{
	  sprintf(errmsg,
		  "Error: no element block id %d in %s array in file id %d",
		  elem_blk_id, VAR_ID_EL_BLK, exoid);
	  ex_err("ex_put_one_elem_attr",errmsg,exerrval);
	  return (EX_FATAL);
	}
    }

  /* inquire id's of previously defined dimensions  */
  if ((numelbdim = ncdimid (exoid, DIM_NUM_EL_IN_BLK(elem_blk_id_ndx))) == -1)
    {
      if (ncerr == NC_EBADDIM)
	{
	  exerrval = ncerr;
	  sprintf(errmsg,
		  "Error: no element block with id %d in file id %d",
		  elem_blk_id, exoid);
	  ex_err("ex_put_one_elem_attr",errmsg,exerrval);
	  return (EX_FATAL);
	}
      else
	{
	  exerrval = ncerr;
	  sprintf(errmsg,
		  "Error: failed to locate number of elements for block %d in file id %d",
		  elem_blk_id, exoid);
	  ex_err("ex_put_one_elem_attr",errmsg,exerrval);
	  return (EX_FATAL);
	}
    }


  if (ncdiminq (exoid, numelbdim, (char *) 0, &num_elem_this_blk) == -1)
    {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to get number of elements for block %d in file id %d",
	      elem_blk_id,exoid);
      ex_err("ex_put_one_elem_attr",errmsg,exerrval);
      return (EX_FATAL);
    }


  if ((numattrdim = ncdimid(exoid, DIM_NUM_ATT_IN_BLK(elem_blk_id_ndx))) == -1)
    {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: number of attributes not defined for block %d in file id %d",
	      elem_blk_id,exoid);
      ex_err("ex_put_one_elem_attr",errmsg,EX_MSG);
      return (EX_FATAL);              /* number of attributes not defined */
    }

  if (ncdiminq (exoid, numattrdim, (char *) 0, &num_attr) == -1)
    {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to get number of attributes for block %d in file id %d",
	      elem_blk_id,exoid);
      ex_err("ex_put_one_elem_attr",errmsg,exerrval);
      return (EX_FATAL);
    }

  if (attrib_index < 1 || attrib_index > num_attr) {
    exerrval = EX_FATAL;
    sprintf(errmsg,
	    "Error: Invalid attribute index specified: %d.  Valid range is 1 to %ld for block %d in file id %d",
            attrib_index, num_attr, elem_blk_id,exoid);
    ex_err("ex_put_one_elem_attr",errmsg,exerrval);
    return (EX_FATAL);
  }

  if ((attrid = ncvarid (exoid, VAR_ATTRIB(elem_blk_id_ndx))) == -1)
    {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to locate attribute variable for block %d in file id %d",
	      elem_blk_id,exoid);
      ex_err("ex_put_one_elem_attr",errmsg,exerrval);
      return (EX_FATAL);
    }


  /* write out the attributes  */

  start[0] = 0;
  start[1] = attrib_index-1;

  count[0] = num_elem_this_blk;
  count[1] = 1;

  stride[0] = 1;
  stride[1] = num_attr;
  
  if (nc_flt_code(exoid) == NC_FLOAT) {
    error = nc_put_vars_float(exoid, attrid, start, count, stride,
			      static_cast<float*>(ex_conv_array(exoid,WRITE_CONVERT,attrib,
								(int)num_attr*num_elem_this_blk)));
  } else {
    error = nc_put_vars_double(exoid, attrid, start, count, stride,
			       static_cast<double*>(ex_conv_array(exoid,WRITE_CONVERT,attrib,
								  (int)num_attr*num_elem_this_blk)));
  }
  if (error == -1) {
    exerrval = ncerr;
    sprintf(errmsg,
            "Error: failed to put attribute %d for block %d in file id %d",
            attrib_index, elem_blk_id,exoid);
    ex_err("ex_put_one_elem_attr",errmsg,exerrval);
    return (EX_FATAL);
  }


  return(EX_NOERR);

}
