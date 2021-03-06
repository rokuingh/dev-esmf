// $Id$
//
// Earth System Modeling Framework
// Copyright 2002-2010, University Corporation for Atmospheric Research, 
// Massachusetts Institute of Technology, Geophysical Fluid Dynamics 
// Laboratory, University of Michigan, National Centers for Environmental 
// Prediction, Los Alamos National Laboratory, Argonne National Laboratory, 
// NASA Goddard Space Flight Center.
// Licensed under the University of Illinois-NCSA License.

// ESMC interface routines

//-----------------------------------------------------------------------------
//
// !DESCRIPTION:
//
// The code in this file implements the C++ {\tt ESMC\_State} methods declared
// in the companion file ESMC_State.h
//
// 
//
//-----------------------------------------------------------------------------
//

#include <string.h>

 // insert any higher level, 3rd party or system includes here
#include "ESMCI_Macros.h"

 // associated class definition file
#include "ESMCI_State.h"

//-----------------------------------------------------------------------------
 // leave the following line as-is; it will insert the cvs ident string
 // into the object file for tracking purposes.
 static const char *const version = 
             "$Id$";
//-----------------------------------------------------------------------------

namespace ESMCI {

extern "C" {
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
//
// This section includes all the State routines
//
//

// non-method functions
void FTN(c_esmc_stateserialize)(
                           int *st, 
                           int *needed_default, 
                           int *ready_default,
                           int *stvalid_default, 
                           int *reqrestart_default, 
                           int *alloccount, 
                           int *datacount, 
                           char *buffer, int *length, int *offset,
                           ESMC_InquireFlag *inquireflag, int *localrc,
                           ESMCI_FortranStrLenArg buffer_l){

#undef  ESMC_METHOD
#define ESMC_METHOD "c_esmc_stateserialize()"

    int *ip;

    if (localrc) *localrc = ESMC_RC_NOT_IMPL;

    // TODO: verify length > needed, else realloc longer
    int fixedpart = 10 * sizeof (int *);
    if ((*inquireflag != ESMF_INQUIREONLY) && (*length - *offset) < fixedpart) {
         
         ESMC_LogDefault.MsgFoundError(ESMC_RC_ARG_BAD,
                             "Buffer too short to add a State object", localrc);
         return;
 
        //buffer = (char *)realloc((void *)buffer,
        //                         *length + 2*fixedpart + byte_count);
        //*length += 2 * fixedpart;
    }


    ip = (int *)(buffer + *offset);
    if (*inquireflag != ESMF_INQUIREONLY) {
      *ip++ = *st; 
      *ip++ = *needed_default; 
      *ip++ = *ready_default; 
      *ip++ = *stvalid_default; 
      *ip++ = *reqrestart_default; 
      *ip++ = *alloccount; 
      *ip++ = *datacount; 
    } else
      ip += 7;

    *offset = (char *)ip - buffer;

    if (localrc) *localrc = ESMF_SUCCESS;

    return;
} 


void FTN(c_esmc_statedeserialize)(
                             int *st, 
                             int *needed_default, 
                             int *ready_default,
                             int *stvalid_default, 
                             int *reqrestart_default, 
                             int *alloccount, 
                             int *datacount, 
                             char *buffer, int *offset, int *localrc,
                             ESMCI_FortranStrLenArg buffer_l){

    int *ip;

    if (localrc) *localrc = ESMC_RC_NOT_IMPL;

    ip = (int *)(buffer + *offset);
    *st = *ip++; 
    *needed_default = *ip++; 
    *ready_default = *ip++; 
    *stvalid_default = *ip++; 
    *reqrestart_default = *ip++; 
    *alloccount = *ip++; 
    *datacount = *ip++; 

    *offset = (char *)ip - buffer;

    if (localrc) *localrc = ESMF_SUCCESS;

    return;
} 

#if 0
      type ESMF_DataHolder
          type(ESMF_FieldBundle) :: bp
          type(ESMF_Field)  :: fp
          type(ESMF_Array)  :: ap
          type(ESMF_StateClass), pointer  :: spp

      type ESMF_StateItem
        type(ESMF_StateItemType) :: otype
        character(len=ESMF_MAXSTR) :: namep
        type(ESMF_DataHolder), pointer :: datap
        integer :: indirect_index
        type(ESMF_NeededFlag) :: needed
        type(ESMF_ReadyFlag) :: ready
        type(ESMF_ValidFlag) :: valid
        type(ESMF_ReqForRestartFlag) :: reqrestart

#endif

void FTN(c_esmc_stateitemserialize)(int *otype, 
                               char *namep, 
                               int *indirect_index, 
                               int *needed,
                               int *ready, 
                               int *valid, 
                               int *reqrestart, 
                               char *buffer, int *length, int *offset,
                               ESMC_InquireFlag *inquireflag, int *localrc,
                               ESMCI_FortranStrLenArg clen,
                               ESMCI_FortranStrLenArg buffer_l) {

    int *ip;
    char *cp;

    if (localrc) *localrc = ESMC_RC_NOT_IMPL;

    // TODO: verify length > needed, else realloc longer

    ip = (int *)(buffer + *offset);
    if (*inquireflag != ESMF_INQUIREONLY)
      *ip++ = *otype;
    else
      ip++;

    cp = (char *)ip;
    if (*inquireflag != ESMF_INQUIREONLY)
      memcpy(cp, namep, clen);
    cp += clen;

    ip = (int *)cp;
    if (*inquireflag != ESMF_INQUIREONLY) {
      *ip++ = *indirect_index; 
      *ip++ = *needed; 
      *ip++ = *ready; 
      *ip++ = *valid; 
      *ip++ = *reqrestart; 
    } else
      ip += 5;

    *offset = (char *)ip - buffer;

    if (localrc) *localrc = ESMF_SUCCESS;

    return;
} 


void FTN(c_esmc_stateitemdeserialize)(int *otype, 
                               char *namep, 
                               int *indirect_index, 
                               int *needed,
                               int *ready, 
                               int *valid, 
                               int *reqrestart, 
                               char *buffer, int *offset, int *localrc,
                               ESMCI_FortranStrLenArg clen,
                               ESMCI_FortranStrLenArg buffer_l) {

    int *ip;
    char *cp;

    if (localrc) *localrc = ESMC_RC_NOT_IMPL;

    ip = (int *)(buffer + *offset);
    *otype = *ip++;
    cp = (char *)ip;
    memcpy(namep, cp, clen);
    cp += clen;
    ip = (int *)cp;
    *indirect_index = *ip++; 
    *needed = *ip++; 
    *ready = *ip++; 
    *valid = *ip++; 
    *reqrestart = *ip++; 

    *offset = (char *)ip - buffer;

    if (localrc) *localrc = ESMF_SUCCESS;

    return;
} 

//-----------------------------------------------------------------------------

void FTN(c_esmc_stateread)(State *ptr,
                           ESMC_Base **base,
                           int *fileNameLen,
                           const char *fileName,
                           ESMC_IOFileFormat *fileFormat,
                           int *status,
                           ESMCI_FortranStrLenArg fileName_l) {
#undef  ESMC_METHOD
#define ESMC_METHOD "c_esmc_stateread()"

         ESMF_CHECK_POINTER(ptr, status)

         // Read the items and attributes into the state object.
         int rc = (ptr)->State::read(*base, // always present
                          *fileNameLen, // always present internal argument.
                          fileName,     // always present
                          ESMC_NOT_PRESENT_FILTER(fileFormat));

         if (ESMC_PRESENT(status)) *status = rc;
}

//-----------------------------------------------------------------------------

void FTN(c_esmc_statewrite)(State *ptr,
                           ESMC_Base **base,
                           int *fileNameLen,
                           const char *fileName,
                           ESMC_IOFileFormat *fileFormat,
                           int *status,
                           ESMCI_FortranStrLenArg fileName_l) {
#undef  ESMC_METHOD
#define ESMC_METHOD "c_esmc_statewrite()"

         ESMF_CHECK_POINTER(ptr, status)

         // Read the items and attributes into the state object.
         int rc = (ptr)->State::write(*base, // always present
                          *fileNameLen, // always present internal argument.
                          fileName,     // always present
                          ESMC_NOT_PRESENT_FILTER(fileFormat));

         if (ESMC_PRESENT(status)) *status = rc;
}

//-----------------------------------------------------------------------------

} // extern "C"

} // namespace ESMCI
