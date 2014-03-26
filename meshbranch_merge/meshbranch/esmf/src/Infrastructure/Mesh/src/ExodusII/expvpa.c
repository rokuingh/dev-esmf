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
* expvp - ex_put_all_var_param
*
* entry conditions - 
*   input parameters:
*       int     exoid   	exodus file id
*       int     num_g   	global variable count
*       int     num_n   	nodal variable count
*       int     num_e 		element variable count
*       int*    elem_var_tab	element variable truth table array
*       int     num_m 		nodeset variable count
*       int*    nset_var_tab	nodeset variable truth table array
*       int     num_s 		sideset variable count
*       int*    sset_var_tab	sideset variable truth table array
*
* exit conditions - 
*
*  $Id: expvpa.c,v 1.1.2.1 2009/02/03 22:30:57 amikstcyr Exp $
*****************************************************************************/

#include <stdlib.h>
#include "exodusII.h"
#include "exodusII_int.h"

#include <ctype.h>
static void *safe_free(void *array);
static int define_dimension(int exoid, const char *DIMENSION, int count, const char *label);
static int define_variable_name_variable(int exoid, const char *VARIABLE, long dimension,
					 const char *label);
static nclong *get_status_array(int exoid, long count, const char *VARIABLE, const char *label);
static int put_truth_table(int exoid, int num_blk, int num_var, int varid, int *table, const char *label);
static int define_truth_table(char type, int exoid, int num_ent, int num_var,
			      int *var_tab, int *status, int *ids, const char *label);

/*!
 * writes the number of global, nodal, element, nodeset, and sideset variables 
 * that will be written to the database
 */

int ex_put_all_var_param (int   exoid,
			  int   num_g,
			  int   num_n,
			  int   num_e,
			  int  *elem_var_tab,
			  int   num_m,
			  int  *nset_var_tab,
			  int   num_s,
			  int  *sset_var_tab)
{
  int in_define = 0;
  int time_dim, num_nod_dim, dimid, iresult;
  long num_elem_blk, num_nset, num_sset;
  int numelblkdim, numelvardim, numnsetdim, nsetvardim, numssetdim, ssetvardim;
  int i;

  int eblk_varid, nset_varid, sset_varid;
  
  int *eblk_ids = 0;
  int *nset_ids = 0;
  int *sset_ids = 0;

  nclong *eblk_stat = 0;
  nclong *nset_stat = 0;
  nclong *sset_stat = 0;
  
  int dims[3];
  char errmsg[MAX_ERR_LENGTH];
  const char* routine = "ex_put_all_var_param";

  exerrval = 0; /* clear error code */

  /* inquire previously defined dimensions  */

  if ((time_dim = ncdimid (exoid, DIM_TIME)) == -1) {
    exerrval = ncerr;
    sprintf(errmsg,
	    "Error: failed to locate time dimension in file id %d", exoid);
    ex_err("ex_put_all_var_param",errmsg,exerrval);
    goto error_ret;
  }

  if ((num_nod_dim = ncdimid (exoid, DIM_NUM_NODES)) == -1) {
    if (num_n > 0) {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to locate number of nodes in file id %d",
	      exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;
    }
  }

  /* Check this now so we can use it later without checking for errors */
  if (ncdimid (exoid, DIM_STR) < 0) {
    exerrval = ncerr;
    sprintf(errmsg,
	    "Error: failed to get string length in file id %d",exoid);
    ex_err("ex_put_all_var_param",errmsg,exerrval);
    goto error_ret;
  }

  if (num_e > 0) {
    numelblkdim = ex_get_dimension(exoid, DIM_NUM_EL_BLK, "element blocks", &num_elem_blk, routine);
    if (numelblkdim == -1)
      goto error_ret;
    
    /* get element block IDs */
    if (!(eblk_ids = static_cast<int*>(malloc(num_elem_blk*sizeof(int))))) {
      exerrval = EX_MEMFAIL;
      sprintf(errmsg,
	      "Error: failed to allocate memory for element block id array for file id %d",
	      exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;
    }
    ex_get_elem_blk_ids (exoid, eblk_ids);

    /* Get element block status array for later use (allocates memory) */
    eblk_stat = get_status_array(exoid, num_elem_blk, VAR_STAT_EL_BLK, "element block");
    if (eblk_stat == NULL) {
      goto error_ret;
    }
  }

  if (num_m > 0) {
    numnsetdim = ex_get_dimension(exoid, DIM_NUM_NS, "nodesets", &num_nset, routine);
    if (numnsetdim == -1)
      goto error_ret;
    
    /* get nodeset IDs */
    if (!(nset_ids = static_cast<int*>(malloc(num_nset*sizeof(int))))) {
      exerrval = EX_MEMFAIL;
      sprintf(errmsg,
	      "Error: failed to allocate memory for nodeset id array for file id %d",
	      exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;
    }
    ex_get_node_set_ids (exoid, nset_ids);

    /* Get nodeset status array for later use (allocates memory) */
    nset_stat = get_status_array(exoid, num_nset, VAR_NS_STAT, "nodeset");
    if (nset_stat == NULL) {
      goto error_ret;
    }
  }

  if (num_s > 0) {
    numssetdim = ex_get_dimension(exoid, DIM_NUM_SS, "sidesets", &num_sset, routine);
    if (numssetdim == -1)
      goto error_ret;
    
    /* get sideset IDs */
    if (!(sset_ids = static_cast<int*>(malloc(num_sset*sizeof(int))))) {
      exerrval = EX_MEMFAIL;
      sprintf(errmsg,
	      "Error: failed to allocate memory for sideset id array for file id %d",
	      exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;
    }
    ex_get_side_set_ids (exoid, sset_ids);

    /* Get sideset status array for later use (allocates memory) */
    sset_stat = get_status_array(exoid, num_sset, VAR_SS_STAT, "sideset");
    if (sset_stat == NULL) {
      goto error_ret;
    }
  }

  /* put file into define mode  */
  if (ncredef (exoid) == -1)
    {
      exerrval = ncerr;
      sprintf(errmsg,
              "Error: failed to put file id %d into define mode", exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;
    }
  in_define = 1;

  /* define dimensions and variables */

  if (num_g > 0) 
    {
      dimid = define_dimension(exoid, DIM_NUM_GLO_VAR, num_g, "global");
      if (dimid == -1) goto error_ret;

      
      dims[0] = time_dim;
      dims[1] = dimid;
      if ((ncvardef (exoid, VAR_GLO_VAR, 
                     nc_flt_code(exoid), 2, dims)) == -1)
        {
          exerrval = ncerr;
          sprintf(errmsg,
                  "Error: failed to define global variables in file id %d",
                  exoid);
          ex_err("ex_put_all_var_param",errmsg,exerrval);
          goto error_ret;          /* exit define mode and return */
        }

      /* Now define global variable name variable */
      if (define_variable_name_variable(exoid, VAR_NAME_GLO_VAR, dimid, "global") == -1)
	goto error_ret;
    }

  if (num_n > 0) 
    {
      /*
       * There are two ways to store the nodal variables. The old way *
       * was a blob (#times,#vars,#nodes), but that was exceeding the
       * netcdf maximum dataset size for large models. The new way is
       * to store #vars separate datasets each of size (#times,#nodes)
       *
       * We want this routine to be capable of storing both formats
       * based on some external flag.  Since the storage format of the
       * coordinates have also been changed, we key off of their
       * storage type to decide which method to use for nodal
       * variables. If the variable 'coord' is defined, then store old
       * way; otherwise store new.
       */
      dimid = define_dimension(exoid, DIM_NUM_NOD_VAR, num_n, "nodal");
      if (dimid == -1) goto error_ret;

      if (ex_large_model(exoid) == 0) { /* Old way */
        dims[0] = time_dim;
        dims[1] = dimid;
        dims[2] = num_nod_dim;
        if ((ncvardef (exoid, VAR_NOD_VAR,
                       nc_flt_code(exoid), 3, dims)) == -1)
          {
            exerrval = ncerr;
            sprintf(errmsg,
                    "Error: failed to define nodal variables in file id %d",
                    exoid);
            ex_err("ex_put_all_var_param",errmsg,exerrval);
            goto error_ret;          /* exit define mode and return */
          }
      } else { /* Store new way */
        for (i = 1; i <= num_n; i++) {
          dims[0] = time_dim;
          dims[1] = num_nod_dim;
          if ((ncvardef (exoid, VAR_NOD_VAR_NEW(i),
                         nc_flt_code(exoid), 2, dims)) == -1)
            {
              exerrval = ncerr;
              sprintf(errmsg,
                      "Error: failed to define nodal variable %d in file id %d",
                      i, exoid);
              ex_err("ex_put_var_param",errmsg,exerrval);
              goto error_ret;          /* exit define mode and return */
            }
        }
      }

      /* Now define nodal variable name variable */
      if (define_variable_name_variable(exoid, VAR_NAME_NOD_VAR, dimid, "nodal") == -1)
	goto error_ret;
    }

  if (num_e > 0) {
    numelvardim = define_dimension(exoid, DIM_NUM_ELE_VAR, num_e, "element");
    if (numelvardim == -1) goto error_ret;

    /* Now define element variable name variable */
    if (define_variable_name_variable(exoid, VAR_NAME_ELE_VAR, numelvardim, "element") == -1)
      goto error_ret;

    if (define_truth_table('e', exoid, num_elem_blk, num_e, elem_var_tab, eblk_stat, eblk_ids, "element block") == -1)
      goto error_ret;

    eblk_stat = static_cast<nclong*>(safe_free (eblk_stat));
    eblk_ids  = static_cast<int*>(   safe_free (eblk_ids));

    /* create a variable array in which to store the element variable truth
     * table
     */

    dims[0] = numelblkdim;
    dims[1] = numelvardim;

    if ((eblk_varid = ncvardef (exoid, VAR_ELEM_TAB, NC_LONG, 2, dims)) == -1) {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to define element variable truth table in file id %d",
	      exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;          /* exit define mode and return */
    }

  }

  if (num_m > 0) {
    nsetvardim = define_dimension(exoid, DIM_NUM_NSET_VAR, num_m, "nodeset");
    if (nsetvardim == -1) goto error_ret;

    /* Now define nodeset variable name variable */
    if (define_variable_name_variable(exoid, VAR_NAME_NSET_VAR, nsetvardim, "nodeset") == -1)
      goto error_ret;

    if (define_truth_table('m', exoid, num_nset, num_m, nset_var_tab, nset_stat, nset_ids, "nodeset") == -1)
      goto error_ret;

    nset_stat = static_cast<nclong*>(safe_free (nset_stat));
    nset_ids  = static_cast<int*>(safe_free (nset_ids));

    /* create a variable array in which to store the truth table
     */

    dims[0] = numnsetdim;
    dims[1] = nsetvardim;

    if ((nset_varid = ncvardef (exoid, VAR_NSET_TAB, NC_LONG, 2, dims)) == -1) {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to define nodeset variable truth table in file id %d",
	      exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;          /* exit define mode and return */
    }
  }

  if (num_s > 0) {
    ssetvardim = define_dimension(exoid, DIM_NUM_SSET_VAR, num_s, "sideset");
    if (ssetvardim == -1) goto error_ret;

    /* Now define sideset variable name variable */
    if (define_variable_name_variable(exoid, VAR_NAME_SSET_VAR, ssetvardim, "sideset") == -1)
      goto error_ret;

    if (define_truth_table('s', exoid, num_sset, num_s, sset_var_tab, sset_stat, sset_ids, "sideset") == -1)
      goto error_ret;
      
    sset_stat = static_cast<nclong*>(safe_free (sset_stat));
    sset_ids  = static_cast<int*>(safe_free (sset_ids));

    /* create a variable array in which to store the truth table
     */

    dims[0] = numssetdim;
    dims[1] = ssetvardim;

    if ((sset_varid = ncvardef (exoid, VAR_SSET_TAB, NC_LONG, 2, dims)) == -1) {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to define sideset variable truth table in file id %d",
	      exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;          /* exit define mode and return */
    }
  }

  /* leave define mode  */

  in_define = 0;
  if (ncendef (exoid) == -1)
    {
      exerrval = ncerr;
      sprintf(errmsg,
              "Error: failed to complete definition in file id %d",
              exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      goto error_ret;
    }

  /* write out the variable truth tables */
  if (num_e > 0) {
    iresult = put_truth_table(exoid, num_elem_blk, num_e, eblk_varid, elem_var_tab, "element");
    if (iresult == -1) goto error_ret;
  }

  if (num_m > 0) {
    iresult = put_truth_table(exoid, num_nset, num_m, nset_varid, nset_var_tab, "nodeset");
    if (iresult == -1) goto error_ret;
  }

  if (num_s > 0) {
    iresult = put_truth_table(exoid, num_sset, num_s, sset_varid, sset_var_tab, "sideset");
    if (iresult == -1) goto error_ret;
  }

  return(EX_NOERR);
  
  /* Fatal error: exit definition mode and return */
 error_ret:
  if (in_define == 1) {
    if (ncendef (exoid) == -1)     /* exit define mode */
      {
	sprintf(errmsg,
		"Error: failed to complete definition for file id %d",
		exoid);
	ex_err("ex_put_all_var_param",errmsg,exerrval);
      }
  }
  safe_free(eblk_ids);
  safe_free(nset_ids);
  safe_free(sset_ids);

  safe_free(eblk_stat);
  safe_free(nset_stat);
  safe_free(sset_stat);
  return(EX_FATAL);
}

int define_dimension(int exoid, const char *DIMENSION, int count, const char *label)
{
  char errmsg[MAX_ERR_LENGTH];
  int dimid = 0;
  if ((dimid = ncdimdef (exoid, DIMENSION, (long)count)) == -1) {
    if (ncerr == NC_ENAMEINUSE) {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: %s variable name parameters are already defined in file id %d",
	      label, exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
    } else {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to define number of %s variables in file id %d",
	      label, exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
    }
  }
  return dimid;
}

int define_variable_name_variable(int exoid, const char *VARIABLE, long dimension, const char *label)
{
  char errmsg[MAX_ERR_LENGTH];
  int dims[2];
  int variable;
  
  dims[0] = dimension;
  dims[1] = ncdimid(exoid, DIM_STR); /* Checked earlier, so known to exist */

  if ((variable = ncvardef (exoid, VARIABLE, NC_CHAR, 2, dims)) == -1) {
    if (ncerr == NC_ENAMEINUSE) {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: %s variable names are already defined in file id %d",
	      label, exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);

    } else {
      exerrval = ncerr;
      sprintf(errmsg,
	      "Error: failed to define %s variable names in file id %d",
	      label, exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
    }
  }
  return variable;
}

nclong *get_status_array(int exoid, long var_count, const char *VARIABLE, const char *label)
{
  char errmsg[MAX_ERR_LENGTH];
  int varid;
  long start[2], count[2]; 
  nclong *stat_vals = NULL;
  
  if (!(stat_vals = static_cast<nclong*>(malloc(var_count*sizeof(nclong))))) {
    exerrval = EX_MEMFAIL;
    sprintf(errmsg,
	    "Error: failed to allocate memory for %s status array for file id %d",
	    label, exoid);
    ex_err("ex_put_all_var_param",errmsg,exerrval);
    return (NULL);
  }

  /* get variable id of status array */
  if ((varid = ncvarid (exoid, VARIABLE)) != -1) {
    /* if status array exists (V 2.01+), use it, otherwise assume
       object exists to be backward compatible */
     
    start[0] = 0;
    start[1] = 0;
    count[0] = var_count;
    count[1] = 0;
     
    if (ncvarget (exoid, varid, start, count, (void *)stat_vals) == -1) {
      exerrval = ncerr;
      stat_vals = static_cast<nclong*>(safe_free(stat_vals));
      sprintf(errmsg,
	      "Error: failed to get %s status array from file id %d",
	      label, exoid);
      ex_err("ex_put_all_var_param",errmsg,exerrval);
      return (NULL);
    }
  } else {
    /* status array doesn't exist (V2.00), dummy one up for later checking */
    int i;
    for(i=0; i<var_count; i++)
      stat_vals[i] = 1;
  }
 return stat_vals;
}

void *safe_free(void *array)
{
  if (array != 0) free(array);
  return 0;
}

int put_truth_table(int exoid, int num_blk, int num_var, int varid, int *table, const char *label)
{
  long start[2], count[2]; 
  int  iresult = 0;
  nclong *lptr;
  char errmsg[MAX_ERR_LENGTH];
  
  /* this contortion is necessary because netCDF is expecting nclongs; fortunately
     it's necessary only when ints and nclongs aren't the same size */

  start[0] = 0;
  start[1] = 0;
  
  count[0] = num_blk;
  count[1] = num_var;
    
  if (sizeof(int) == sizeof(nclong)) {
    iresult = ncvarput (exoid, varid, start, count, table);
  } else {
    lptr = itol (table, (int)(num_blk*num_var));
    iresult = ncvarput (exoid, varid, start, count, lptr);
    lptr = static_cast<nclong*>(safe_free(lptr));
  }
    
  if (iresult == -1) {
    exerrval = ncerr;
    sprintf(errmsg,
	    "Error: failed to store %s variable truth table in file id %d",
	    label, exoid);
    ex_err("ex_put_all_var_param",errmsg,exerrval);
   }
  return iresult;
}

int define_truth_table(char type, int exoid, int num_ent, int num_var,
		       int *var_tab, int *status, int *ids, const char *label)
{
  char errmsg[MAX_ERR_LENGTH];
  int k = 0;
  int i, j;
  int time_dim;
  int dims[2];
  int varid;

  time_dim = ncdimid (exoid, DIM_TIME);

  if (var_tab == NULL) {
    exerrval = EX_NULLENTITY;
    sprintf(errmsg,
	    "Error: %s variable truth table is NULL in file id %d", label, exoid);
    ex_err("ex_put_all_var_param",errmsg, exerrval);
    return -1;
  }
  
  for (i=0; i<num_ent; i++) {
    for (j=1; j<=num_var; j++) {
      
      /* check if variables are to be put out for this block */
      if (var_tab[k] != 0) {
	if (status[i] == 0) {/* check for NULL entity */
	  var_tab[k] = 0;
#if 0
	  exerrval = EX_NULLENTITY;
	  sprintf(errmsg,
		  "Warning: %s variable truth table specifies invalid entry for NULL %s %d, variable %d in file id %d",
		  label, label, ids[i], j, exoid);
	  ex_err("ex_put_all_var_param",errmsg,exerrval);
#endif	  
	} else {
	  dims[0] = time_dim;
		
	  /* Determine number of entities in entity */
	  /* Need way to make this more generic... */
	  if (type == 'e')
	    dims[1] = ncdimid (exoid, DIM_NUM_EL_IN_BLK(i+1));
	  else if (type == 'm')
	    dims[1] = ncdimid (exoid, DIM_NUM_NOD_NS(i+1));
	  else if (type == 's')
	    dims[1] = ncdimid (exoid, DIM_NUM_SIDE_SS(i+1));
	  
	  if (dims[1] == -1) {
	    exerrval = ncerr;
	    sprintf(errmsg,
		    "Error: failed to locate number of entities in %s %d in file id %d",
		    label, ids[i], exoid);
	    ex_err("ex_put_all_var_param",errmsg,exerrval);
	    return -1;
	  }
	  
	  /* define netCDF variable to store variable values;
	   * the j index cycles from 1 through the number of variables so 
	   * that the index of the EXODUS II variable (which is part of 
	   * the name of the netCDF variable) will begin at 1 instead of 0
	   */
		
	  if (type == 'e')
	    varid = ncvardef(exoid, VAR_ELEM_VAR(j,i+1), nc_flt_code(exoid), 2, dims);
	  else if (type == 'm')
	    varid = ncvardef(exoid, VAR_NS_VAR(j,i+1),   nc_flt_code(exoid), 2, dims);
	  else if (type == 's')
	    varid = ncvardef(exoid, VAR_SS_VAR(j,i+1),   nc_flt_code(exoid), 2, dims);
	    
	  if (varid == -1) {
	    if (ncerr != NC_ENAMEINUSE) {
	      exerrval = ncerr;
	      sprintf(errmsg,
		      "Error: failed to define %s variable for %s %d in file id %d",
		      label, label, ids[i], exoid);
	      ex_err("ex_put_all_var_param",errmsg,exerrval);
	      return -1;
	    }
	  }
	}
      }  /* if */
      k++; /* increment truth table pointer */
    }  /* for j */
  }  /* for i */
  return 0;
}
