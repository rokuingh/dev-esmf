// $Id: ESMCI_SpaceDir.C,v 1.2 2010/03/04 18:57:45 svasquez Exp $
//
// Earth System Modeling Framework
// Copyright 2002-2010, University Corporation for Atmospheric Research, 
// Massachusetts Institute of Technology, Geophysical Fluid Dynamics 
// Laboratory, University of Michigan, National Centers for Environmental 
// Prediction, Los Alamos National Laboratory, Argonne National Laboratory, 
// NASA Goddard Space Flight Center.
// Licensed under the University of Illinois-NCSA License.
//
//==============================================================================
#define ESMC_FILENAME "ESMCI_SpaceDir.C"
//==============================================================================
//
// ESMC SpaceDir method implementation (body) file
//
//-----------------------------------------------------------------------------
//
// !DESCRIPTION:
//
// The code in this file implements the C++ spatial search methods declared
// in ESMCI_SpaceDir.h. This code/algorithm developed by Bob Oehmke. Note to self,
// put ref here when article is done making its way through publication process. 
//
//-----------------------------------------------------------------------------

// include associated header file
#include <Mesh/include/ESMCI_OTree.h>
#include <Mesh/include/ESMCI_SpaceDir.h>
#include "stdlib.h"
#include <Mesh/include/ESMCI_ParEnv.h>

#include <algorithm>

//-----------------------------------------------------------------------------
// leave the following line as-is; it will insert the cvs ident string
// into the object file for tracking purposes.
static const char *const version = "$Id: ESMCI_SpaceDir.C,v 1.2 2010/03/04 18:57:45 svasquez Exp $";
//-----------------------------------------------------------------------------


//-----------------------------------------------------------------------------


// Set up ESMCI name space for these methods
namespace ESMCI{  


//-----------------------------------------------------------------------------
//
// Public Interfaces
//
//-----------------------------------------------------------------------------



//-----------------------------------------------------------------------------
#undef  ESMC_METHOD
#define ESMC_METHOD "ESMCI::SpaceDir()"
//BOPI
// !IROUTINE:  SpaceDir
//
// !INTERFACE:
SpaceDir::SpaceDir(
//
// !RETURN VALUE:
//    Pointer to a new SpaceDir
//
// !ARGUMENTS:
		   double _proc_min[3], // min of objects in otree for this proc 
		   double _proc_max[3], // max of objects in otree for this proc
		   OTree *_otree        // Otree of objects on this proc 
                                        // NOTE: _otree should be commited before being passed in
                                        // NOTE: SpaceDir won't destruct this otree
  ){
//
// !DESCRIPTION:
//   Construct SpaceDir
//EOPI
//-----------------------------------------------------------------------------
   Trace __trace("SpaceDir::SpaceDir()");

   // Set variables
   otree=_otree;
   
   proc_min[0]=_proc_min[0];
   proc_min[1]=_proc_min[1];
   proc_min[2]=_proc_min[2];
   
   proc_max[0]=_proc_max[0];
   proc_max[1]=_proc_max[1];
   proc_max[2]=_proc_max[2];



   // EVENTUALLY NEED TO MAKE THIS MORE SCALABLE, BUT FOR
   // AN INITIAL TEST DO SOMETHING EASY

   // Distribute min-max box of each proc 
   // Pack up local minmax
   std::vector<double> local_minmax(6,0.0);
   local_minmax[0]=proc_min[0]; 
   local_minmax[1]=proc_min[1]; 
   local_minmax[2]=proc_min[2]; 
   local_minmax[3]=proc_max[0]; 
   local_minmax[4]=proc_max[1]; 
   local_minmax[5]=proc_max[2]; 

   // Number of procs
   int num_procs = Par::Size();
   if (num_procs <1)     Throw() << "Error: number of procs is less than 1";

   // Allocate buffer for global minmax list
   std::vector<double> global_minmax(6*num_procs, 0.0);

   // Do all gather to get info from all procs
   MPI_Allgather(&local_minmax[0], 6, MPI_DOUBLE, &global_minmax[0], 6, MPI_DOUBLE, Par::Comm());

   // Setup a list of numbers to store in proc tree
   proc_nums=new int[num_procs];
   for (int i=0; i<num_procs; i++) {
     proc_nums[i]=i;
   }
      
   // Construct tree
   proc_otree = new OTree(num_procs);

   // Add proc min max boxes
   for (int i=0; i<num_procs; i++) {

     // Get min and max from global list
     double *min=&global_minmax[6*i];
     double *max=&global_minmax[6*i+3];

     // Add proc to tree
     proc_otree->add(min, max, (void *)(proc_nums+i));
   }

   // Commit tree to make it usable
   proc_otree->commit();
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
#undef  ESMC_METHOD
#define ESMC_METHOD "ESMCI::~SpaceDir()"
//BOPI
// !IROUTINE:  ~SpaceDir
//
// !INTERFACE:
 SpaceDir::~SpaceDir(void){
//
// !RETURN VALUE:
//    none
//
// !ARGUMENTS:
// none
//
// !DESCRIPTION:
//  Destructor for SpaceDir, deallocates all internal memory, etc. 
//
//EOPI
//-----------------------------------------------------------------------------
   Trace __trace("SpaceDir::~SpaceDir()");

   // Get rid of list of proc numbers
   delete [] proc_nums;

   // Get rid of proc otree
   delete proc_otree;
}

//-----------------------------------------------------------------------------
struct GP_Data {

  set<int> set_of_procs;

};

static int GP_func(void *c, void *y) {
  int proc = *static_cast<int *>(c);
  GP_Data *gpd = static_cast<GP_Data *>(y);

  // Use Set here to maintain a unique list of procs
  /// TODO: Consider just using the output vector and keeping it sorted???
  gpd->set_of_procs.insert(proc);

  return 0;
}


//-----------------------------------------------------------------------------
#undef  ESMC_METHOD
#define ESMC_METHOD "ESMCI::SpaceDir::get_procs()"
//BOP
// !IROUTINE:  get_procs
//
// !INTERFACE:
void SpaceDir::get_procs(

//
// !RETURN VALUE:
//  none
// 
// !ARGUMENTS:
//  
	       double min[3],
	       double max[3],
	       vector<int> *procs
  ) {
//
// !DESCRIPTION:
// Get the list of processors that may contain objects in the space delimited by
// min and max. Note that procs is constructed to be a unique list of processors 
// (i.e. no repeats).
//EOP
//-----------------------------------------------------------------------------
   Trace __trace("SpaceDir::get_procs()");
   GP_Data gpd;

   // Search for procs
   proc_otree->runon(min, max, GP_func, (void*)&gpd);    

   // If there are any procs, copy them into the output vector
   if (!gpd.set_of_procs.empty()) {
     procs->reserve(gpd.set_of_procs.size());
     set<int>::iterator set_beg=gpd.set_of_procs.begin();
     set<int>::iterator set_end=gpd.set_of_procs.end();
     copy(set_beg,set_end, back_inserter(*procs));
   }  
}
//-----------------------------------------------------------------------------



} // END ESMCI name space
//-----------------------------------------------------------------------------










