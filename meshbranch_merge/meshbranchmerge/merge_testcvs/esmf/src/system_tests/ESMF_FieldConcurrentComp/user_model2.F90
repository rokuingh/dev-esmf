! $Id$
!
! System test for Concurrent Components, user-written component 2.

!--------------------------------------------------------------------------------
!--------------------------------------------------------------------------------

!BOP
!
! !DESCRIPTION:
!  User-supplied Component 2.
!
!
!\begin{verbatim}
#include "ESMF.h"

    module user_model2

    ! ESMF Framework module
    use ESMF_TestMod
    use ESMF_Mod

    implicit none
    
  public userm2_setvm, userm2_register
        
    contains

!--------------------------------------------------------------------------------
!   !  The Register routine sets the subroutines to be called
!   !   as the init, run, and finalize routines.  Note that these are
!   !   private to the module.
 
#undef ESMF_METHOD
#define ESMF_METHOD "userm2_setvm"
  subroutine userm2_setvm(comp, rc)
    type(ESMF_GridComp) :: comp
    integer, intent(out) :: rc
#ifdef ESMF_TESTWITHTHREADS
    type(ESMF_VM) :: vm
    logical :: pthreadsEnabled
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
    call ESMF_VMGet(vm, pthreadsEnabledFlag=pthreadsEnabled, rc=rc)
    if (pthreadsEnabled) then
      call ESMF_GridCompSetVMMinThreads(comp, rc=rc)
    endif
#endif

  end subroutine

#undef ESMF_METHOD
#define ESMF_METHOD "userm2_register"
    subroutine userm2_register(comp, rc)
        type(ESMF_GridComp)         :: comp
        integer, intent(out)        :: rc

        integer                     :: status = ESMF_SUCCESS

        print *, "In user 2 register routine"

        ! Register the callback routines.

        call ESMF_GridCompSetEntryPoint(comp, ESMF_SETINIT, &
          userRoutine=user_init, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        call ESMF_GridCompSetEntryPoint(comp, ESMF_SETRUN, &
          userRoutine=user_run, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        call ESMF_GridCompSetEntryPoint(comp, ESMF_SETFINAL, &
          userRoutine=user_final, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        !print *, "Registered Initialize, Run, and Finalize routines"

        rc = status

    end subroutine

!--------------------------------------------------------------------------------
!   !  User Comp Component created by higher level calls, here is the
!   !   Initialization routine.
 
#undef ESMF_METHOD
#define ESMF_METHOD "userm2_init"
    subroutine user_init(comp, importState, exportState, clock, rc)
        type(ESMF_GridComp)  :: comp
        type(ESMF_State)     :: importState, exportState
        type(ESMF_Clock)     :: clock
        integer, intent(out) :: rc
  
  !   ! Local variables
        integer                             :: status = ESMF_SUCCESS

        type(ESMF_VM)                       :: vm
        type(ESMF_Field)                    :: sorted_data
        type(ESMF_DistGrid)                 :: distgrid
        type(ESMF_Grid)                     :: grid
        type(ESMF_ArraySpec)                :: arrayspec
        integer                             :: petCount
  
        print *, "In user 2 init routine"
        ! Determine petCount
        call ESMF_GridCompGet(comp, vm=vm, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        call ESMF_VMGet(vm, petCount=petCount, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        distgrid = ESMF_DistGridCreate(minIndex=(/1/), maxIndex=(/9/), &
            regDecomp=(/petCount/), rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        grid = ESMF_GridCreate(distgrid=distgrid, &
            gridEdgeLWidth=(/0/), gridEdgeUWidth=(/0/), &
            name="grid", indexflag=ESMF_INDEX_GLOBAL, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        call ESMF_ArraySpecSet(arrayspec, 1, ESMF_TYPEKIND_I4, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
  
        sorted_data = ESMF_FieldCreate(arrayspec=arrayspec, &
            grid=grid, name="sorted_data2", rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        call ESMF_StateAdd(importState, sorted_data, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        rc = status
  
    end subroutine user_init


!--------------------------------------------------------------------------------
!   !  The Run routine where data is computed.
!   !
 
#undef ESMF_METHOD
#define ESMF_METHOD "userm2_run"
    subroutine user_run(comp, importState, exportState, clock, rc)
        type(ESMF_GridComp)  :: comp
        type(ESMF_State)     :: importState, exportState
        type(ESMF_Clock)     :: clock
        integer, intent(out) :: rc
  
  !   ! Local variables
        integer                             :: status = ESMF_SUCCESS
        type(ESMF_Field)                    :: sorted_data
        integer, dimension(9), target       :: d = (/3,7,8,5,2,1,9,5,4/)
        integer, dimension(:), pointer      :: rdptr     ! raw data ptr
        integer, dimension(:), pointer      :: sdptr     ! sorted data ptr
        integer                             :: i

        print *, "In user 2 run routine"
        call ESMF_StateGet(importState, "sorted_data2", sorted_data, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        call ESMF_FieldGet(sorted_data, localDe=0, farrayPtr=sdptr, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        
        ! sort local data
        rdptr => d
        call quicksortI4(rdptr, 1, 9)

        ! compare local sorted data with data sorted on component 1
        ! any mismatch indicates failure
        ! write(*, '(A16, 9I3)') 'local rdptr', rdptr
        do i = lbound(sdptr, 1), ubound(sdptr, 1)
            if(rdptr(i) .ne. sdptr(i)) status = ESMF_FAILURE
        enddo
        rc = status

    end subroutine user_run


!--------------------------------------------------------------------------------
!   !  The Finalization routine where things are deleted and cleaned up.
!   !
 
#undef ESMF_METHOD
#define ESMF_METHOD "userm2_final"
    subroutine user_final(comp, importState, exportState, clock, rc)
        type(ESMF_GridComp)  :: comp
        type(ESMF_State)     :: importState, exportState
        type(ESMF_Clock)     :: clock
        integer, intent(out) :: rc
  
        ! Local variables
        integer                             :: status = ESMF_SUCCESS
        type(ESMF_Field)                    :: sorted_data
        type(ESMF_DistGrid)                 :: distgrid
        type(ESMF_Grid)                     :: grid

        print *, "In user 2 final routine"
  
        call ESMF_StateGet(importState, "sorted_data2", sorted_data, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        call ESMF_FieldGet(sorted_data, grid=grid, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        call ESMF_GridGet(grid, distgrid=distgrid, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return

        ! destroy the objects
        call ESMF_FieldDestroy(sorted_data, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        call ESMF_GridDestroy(grid, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        call ESMF_DistGridDestroy(distgrid, rc=status)
        if (ESMF_LogMsgFoundError(status, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rc)) return
        
        rc = status
   
    end subroutine user_final

    function partition(array, left, right, pindex)
        integer, pointer :: array(:)
        integer, intent(in)    :: left, right, pindex

        integer :: partition

        integer :: pvalue, tmp, sindex, i

        pvalue = array(pindex)
        tmp = array(right)
        array(right) = pvalue
        array(pindex) = tmp

        sindex = left

        do i = left, right-1
            if(array(i) .le. pvalue) then
                tmp = array(i)
                array(i) = array(sindex)
                array(sindex) = tmp
                sindex = sindex + 1
            endif
        end do

        tmp = array(sindex)
        array(sindex) = array(right)
        array(right) = tmp
        partition = sindex
    end function partition

    recursive subroutine quicksortI4(array, left, right)

        integer, pointer :: array(:)
        integer, intent(in)    :: left, right

        integer :: pindex, npindex
        if(right .gt. left) then
            pindex = left + (right - left)/2
            npindex = partition(array, left, right, pindex)
            call quicksortI4(array, left, npindex-1)
            call quicksortI4(array, npindex+1, right)
        endif
    end subroutine quicksortI4

    end module user_model2
    
!\end{verbatim}
