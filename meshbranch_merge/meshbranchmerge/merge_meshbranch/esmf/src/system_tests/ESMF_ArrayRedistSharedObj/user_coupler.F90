! $Id: user_coupler.F90,v 1.2 2009/01/16 05:28:24 theurich Exp $
!
! Example/test code which shows User Component calls.

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

!
! !DESCRIPTION:
!  User-supplied Coupler
!
!
!\begin{verbatim}

module user_coupler

  ! ESMF Framework module
  use ESMF_Mod
    
  implicit none
   
  public usercpl__setvm, usercpl_register
        
  ! global data
  type(ESMF_RouteHandle), save :: routehandle

  contains

!-------------------------------------------------------------------------
!   !  The Register routine sets the subroutines to be called
!   !   as the init, run, and finalize routines.  Note that these are
!   !   private to the module.
 
  subroutine usercpl__setvm(comp, rc)
    type(ESMF_CplComp) :: comp
    integer, intent(out) :: rc
#ifdef ESMF_TESTWITHTHREADS
    type(ESMF_VM) :: vm
    logical :: supportPthreads
#endif

    ! Initialize return code
    rc = ESMF_SUCCESS

#ifdef ESMF_TESTWITHTHREADS
    ! The following call will turn on ESMF-threading (single threaded)
    ! for this component. If you are using this file as a template for
    ! your own code development you probably don't want to include the
    ! following call unless you are interested in exploring ESMF's
    ! threading features.

    ! First test whether ESMF-threading is supported on this machine
    call ESMF_VMGetGlobal(vm, rc=rc)
    call ESMF_VMGet(vm, supportPthreadsFlag=supportPthreads, rc=rc)
    if (supportPthreads) then
      call ESMF_CplCompSetVMMinThreads(comp, rc=rc)
    endif
#endif

  end subroutine

  subroutine usercpl_register(comp, rc)
    type(ESMF_CplComp) :: comp
    integer, intent(out) :: rc

    ! Initialize return code
    rc = ESMF_SUCCESS

    print *, "User Coupler Register starting"
    
    ! Register the callback routines.
    call ESMF_CplCompSetEntryPoint(comp, ESMF_SETINIT, user_init, &
      ESMF_SINGLEPHASE, rc)
    if (rc/=ESMF_SUCCESS) return ! bail out
    call ESMF_CplCompSetEntryPoint(comp, ESMF_SETRUN, user_run, &
      ESMF_SINGLEPHASE, rc)
    if (rc/=ESMF_SUCCESS) return ! bail out
    call ESMF_CplCompSetEntryPoint(comp, ESMF_SETFINAL, user_final, &
      ESMF_SINGLEPHASE, rc)
    if (rc/=ESMF_SUCCESS) return ! bail out

    print *, "Registered Initialize, Run, and Finalize routines"
    print *, "User Coupler Register returning"

  end subroutine

!-------------------------------------------------------------------------
!   !User Comp Component created by higher level calls, here is the
!   ! Initialization routine.
    
  subroutine user_init(comp, importState, exportState, clock, rc)
    type(ESMF_CplComp) :: comp
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    integer, intent(out) :: rc

    ! Local variables
    integer :: itemcount
    type(ESMF_Array) :: srcArray, dstArray
    type(ESMF_VM) :: vm

    ! Initialize return code
    rc = ESMF_SUCCESS

    print *, "User Coupler Init starting"

    call ESMF_StateGet(importState, itemcount=itemcount, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out
    print *, "Import State contains ", itemcount, " items."

    ! Need to reconcile import and export states
    call ESMF_CplCompGet(comp, vm=vm, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out
    call ESMF_StateReconcile(importState, vm, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out
    call ESMF_StateReconcile(exportState, vm, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out

    ! Get source Array out of import state
    call ESMF_StateGet(importState, "array data", srcArray, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out

    ! Get destination Array out of export state
    call ESMF_StateGet(exportState, "array data", dstArray, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out

    ! Precompute and store an ArrayRedist operation
    call ESMF_ArrayRedistStore(srcArray=srcArray, dstArray=dstArray, &
      routehandle=routehandle, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out
    
    print *, "User Coupler Init returning"
   
  end subroutine user_init


!-------------------------------------------------------------------------
!   !  The Run routine where data is coupled.
!   !
 
  subroutine user_run(comp, importState, exportState, clock, rc)
    type(ESMF_CplComp) :: comp
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    integer, intent(out) :: rc

    ! Local variables
    type(ESMF_Array) :: srcArray, dstArray

    ! Initialize return code
    rc = ESMF_SUCCESS

    print *, "User Coupler Run starting"

    ! Get source Array out of import state
    call ESMF_StateGet(importState, "array data", srcArray, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out

    ! Get destination Array out of export state
    call ESMF_StateGet(exportState, "array data", dstArray, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out

    ! Use ArrayRedist() to take data from srcArray to dstArray
    call ESMF_ArrayRedist(srcArray=srcArray, dstArray=dstArray, &
      routehandle=routehandle, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out
  
    print *, "User Coupler Run returning"

  end subroutine user_run


!-------------------------------------------------------------------------
!   !  The Finalization routine where things are deleted and cleaned up.
!   !
 
  subroutine user_final(comp, importState, exportState, clock, rc)
    type(ESMF_CplComp) :: comp
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    integer, intent(out) :: rc

    ! Initialize return code
    rc = ESMF_SUCCESS

    print *, "User Coupler Final starting"
  
    ! Release resources stored for the ArrayRedist.
    call ESMF_ArrayRedistRelease(routehandle=routehandle, rc=rc)
    if (rc/=ESMF_SUCCESS) return ! bail out

    print *, "User Coupler Final returning"
  
  end subroutine user_final


end module user_coupler
    
!\end{verbatim}

subroutine usercpl_setvm(comp, rc)
  use ESMF_Mod
  use user_coupler
  type(ESMF_CplComp) :: comp
  integer, intent(out) :: rc
  call usercpl__setvm(comp, rc)
end subroutine

subroutine usercpl_reg(comp, rc)
  use ESMF_Mod
  use user_coupler
  type(ESMF_CplComp) :: comp
  integer, intent(out) :: rc
  call usercpl_register(comp, rc)
end subroutine
