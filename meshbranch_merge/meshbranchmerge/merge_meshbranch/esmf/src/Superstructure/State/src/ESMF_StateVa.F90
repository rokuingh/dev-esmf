! $Id$
!
! Earth System Modeling Framework
! Copyright 2002-2010, University Corporation for Atmospheric Research, 
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics 
! Laboratory, University of Michigan, National Centers for Environmental 
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory, 
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!==============================================================================
!
#define ESMF_FILENAME "ESMF_StateVa.F90"
!
!     ESMF StateVa module
      module ESMF_StateVaMod
!
!==============================================================================
!
! This file contains the State Validate method
!
!------------------------------------------------------------------------------
! INCLUDES
!------------------------------------------------------------------------------
#include "ESMF.h"
!------------------------------------------------------------------------------
!BOPI
! !MODULE: ESMF_StateVaMod - State Va Module
!
! !DESCRIPTION:
!
! The code in this file implements the State Validate method.
!
!
! !USES:
      use ESMF_ArrayMod,       only: ESMF_ArrayValidate
      use ESMF_ArrayBundleMod, only: ESMF_ArrayBundleValidate
      use ESMF_FieldMod,       only: ESMF_FieldValidate
      use ESMF_FieldBundleMod, only: ESMF_FieldBundleValidate
      use ESMF_LogErrMod
      use ESMF_RHandleMod,     only: ESMF_RouteHandleValidate
      use ESMF_StateTypesMod
      use ESMF_InitMacrosMod
      use ESMF_IOUtilMod,      only: ESMF_IOstderr
      use ESMF_UtilTypesMod
      use ESMF_UtilMod,        only: ESMF_StringLowerCase
      
      implicit none
      
!------------------------------------------------------------------------------
! !PRIVATE TYPES:
      private
      
!------------------------------------------------------------------------------
! !PUBLIC TYPES:

!------------------------------------------------------------------------------

! !PUBLIC MEMBER FUNCTIONS:

      public ESMF_StateValidate

!EOPI

!------------------------------------------------------------------------------
! The following line turns the CVS identifier string into a printable variable.
      character(*), parameter, private :: version = &
      '$Id$'

!==============================================================================
! 
! INTERFACE BLOCKS
!
!==============================================================================


!==============================================================================

      contains

!==============================================================================

!------------------------------------------------------------------------------
#undef  ESMF_METHOD
#define ESMF_METHOD "ESMF_StateValidate"
!BOP
! !IROUTINE: ESMF_StateValidate - Check validity of a State
!
! !INTERFACE:
      subroutine ESMF_StateValidate(state, options, nestedFlag, rc)
!
! !ARGUMENTS:
      type(ESMF_State) :: state
      character (len = *),   intent(in), optional :: options
      type(ESMF_NestedFlag), intent(in), optional :: nestedFlag
      integer, intent(out), optional :: rc 
!
! !DESCRIPTION:
!     Validates that the {\tt state} is internally consistent.
!      Currently this method determines if the {\tt state} is uninitialized 
!      or already destroyed.  The method returns an error code if problems 
!      are found.  
!
!     The arguments are:
!     \begin{description}
!     \item[state]
!       The {\tt ESMF\_State} to validate.
!     \item[{[nestedFlag]}]
!       {\tt ESMF\_NESTED\_OFF} - validates at the current State level only
!       {\tt ESMF\_NESTED\_ON} - recursively validates any nested States
!     \item[{[options]}]
!       Validation options are not yet supported.
!     \item[{[rc]}]
!       Return code; equals {\tt ESMF\_SUCCESS} if there are no errors.
!     \end{description}
!
!
!EOP

!
! TODO: code goes here
!
      character (len=16) :: localopts
      integer :: localrc
      logical :: localnestedflag
      type(ESMF_StateClass), pointer :: stypep

      ! Initialize return code; assume failure until success is certain
      if (present(rc)) rc = ESMF_RC_NOT_IMPL
      localrc = ESMF_SUCCESS

      ! check input variables
      ESMF_INIT_CHECK_DEEP(ESMF_StateGetInit,state,rc)

      localnestedflag = .false.
      if (present (nestedFlag)) then
        localnestedflag = nestedFlag == ESMF_NESTED_ON
      end if

      localopts = "brief"
      if (present (options)) then
        if (options /= " ")  &
          localopts = options
      end if

      call ESMF_StringLowerCase (localopts)
      select case (localopts)
      case ("brief")
      case ("collective")
        write (ESMF_IOstderr,*)  &
            "ESMF_StateValidate: warning: collective option is deferred"
      case default
        write (ESMF_IOstderr,*) "ESMF_StateValidate: unknown options arg: ", &
            trim (localopts)
        return 
      end select

      ! Validate the State

      if (.not. associated (state%statep)) then
          if (ESMF_LogMsgFoundError(ESMF_RC_OBJ_BAD, &
                                 "State uninitialized or already destroyed", &
                                  ESMF_CONTEXT, rc)) return
      endif


      if (localnestedflag) then
        stypep => state%statep
        call validateWorker (stypep, rc=localrc)
      end if

      if (present(rc)) rc = localrc

      contains

        recursive subroutine validateWorker (sp, rc)
          type(ESMF_StateClass), pointer :: sp
          integer, intent (out) :: rc

          integer :: i1
          integer :: local1rc
          type(ESMF_StateItem) , pointer :: dp


          rc = ESMF_SUCCESS

          if (sp%st == ESMF_STATE_INVALID) then
            if (ESMF_LogMsgFoundError(ESMF_RC_OBJ_BAD, &
                                 "State uninitialized or already destroyed", &
                                  ESMF_CONTEXT, rc)) return
          end if

          do, i1 = 1, sp%datacount
            dp => sp%datalist(i1)
            local1rc = ESMF_SUCCESS

            select case (dp%otype%ot)
            case (ESMF_STATEITEM_ARRAY%ot)
              call ESMF_ArrayValidate (dp%datap%ap, rc=local1rc)

            case (ESMF_STATEITEM_ARRAYBUNDLE%ot)
              call ESMF_ArrayBundleValidate (dp%datap%abp, rc=local1rc)

            case (ESMF_STATEITEM_FIELD%ot)
              call ESMF_FieldValidate (dp%datap%fp, rc=local1rc)

            case (ESMF_STATEITEM_FIELDBUNDLE%ot)
              call ESMF_FieldBundleValidate (dp%datap%fbp, rc=local1rc)

            case (ESMF_STATEITEM_ROUTEHANDLE%ot)
              call ESMF_RouteHandleValidate (dp%datap%rp, rc=local1rc)

            case (ESMF_STATEITEM_STATE%ot)
              if (localnestedflag)  &
                call validateWorker (dp%datap%spp, rc=local1rc)

            case (ESMF_STATEITEM_NAME%ot, ESMF_STATEITEM_INDIRECT%ot)
              continue

            case (ESMF_STATEITEM_UNKNOWN%ot, ESMF_STATEITEM_NOTFOUND%ot)
              local1rc = ESMF_RC_OBJ_BAD

            case default
              local1rc = ESMF_RC_OBJ_BAD

            end select

            if (local1rc /= ESMF_SUCCESS) then
              rc = ESMF_RC_OBJ_BAD
              print *, 'ESMF_StateValidate: Invalid object: ', trim (dp%namep)
            end if

          end do

        end subroutine validateWorker

      end subroutine ESMF_StateValidate

!------------------------------------------------------------------------------



      end module ESMF_StateVaMod





