! $Id: user_coupler.F90,v 1.7 2009/01/16 05:28:25 theurich Exp $
!
! Example/test code which shows User Component calls.

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

!BOP
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
   
  public usercpl_setvm, usercpl_register
        
  contains

!-------------------------------------------------------------------------
!   !  The Register routine sets the subroutines to be called
!   !   as the init, run, and finalize routines.  Note that these are
!   !   private to the module.
 
  subroutine usercpl_setvm(comp, rc)
    type(ESMF_CplComp) :: comp
    integer, intent(out) :: rc

#ifdef ESMF_TESTWITHTHREADS
    type(ESMF_VM) :: vm
    logical :: supportPthreads
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

    rc = ESMF_SUCCESS
  end subroutine

  subroutine usercpl_register(comp, rc)
    type(ESMF_CplComp) :: comp
    integer, intent(out) :: rc

    print *, "in user setservices routine"

    ! Register the callback routines.
    call ESMF_CplCompSetEntryPoint(comp, ESMF_SETINIT, user_init, &
      ESMF_SINGLEPHASE, rc)
    call ESMF_CplCompSetEntryPoint(comp, ESMF_SETRUN, user_run, &
      ESMF_SINGLEPHASE, rc)
    call ESMF_CplCompSetEntryPoint(comp, ESMF_SETFINAL, user_final, &
      ESMF_SINGLEPHASE, rc)

    print *, "Registered Initialize, Run, and Finalize routines"

    rc = ESMF_SUCCESS
  end subroutine

!-------------------------------------------------------------------------
!   !User Comp Component created by higher level calls, here is the
!   ! Initialization routine.
    
  subroutine user_init(comp, importState, exportState, clock, rc)
    type(ESMF_CplComp) :: comp
    type(ESMF_State) :: importState, exportState
    type(ESMF_Clock) :: clock
    integer, intent(out) :: rc

    print *, "User Coupler Init starting"

    print *, "User Coupler Init returning"
   
    rc = ESMF_SUCCESS
    return
    
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
    integer :: condition
    character (len=ESMF_MAXSTR) :: state_name, name

    print *, "User Coupler Run starting"

    ! Get name of export state to determine which 
    ! condition to read.
    call ESMF_StateGet(state=exportState, name=state_name, rc=rc)
    
    if (trim(state_name).eq."compA export") then
	name = "CondA"
    else if (trim(state_name).eq."compB export") then
	name = "CondB"
    else if (trim(state_name).eq."compC export") then
	name = "CondC"
    else
	print *, "Undefined state_name: ", trim(state_name)
        rc = ESMF_FAILURE
        return
    end if

    ! Get the Condition for this model
    call ESMF_AttributeGet(exportState, name=name, value=condition, rc=rc)

    ! square the condition just read
    condition=condition * condition
 
    ! Store the condition for this component in the modelD import State
    
    call ESMF_AttributeSet(importState, name=name, value=condition, rc=rc)

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

    ! Local variables

    print *, "User Coupler Final starting"
  

    print *, "User Coupler Final returning"
  
    rc = ESMF_SUCCESS

  end subroutine user_final


end module user_coupler
    
!\end{verbatim}
    
