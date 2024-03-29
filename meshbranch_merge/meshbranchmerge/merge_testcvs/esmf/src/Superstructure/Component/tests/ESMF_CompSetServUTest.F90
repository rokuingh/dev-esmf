! $Id$
!
! Earth System Modeling Framework
! Copyright 2002-2010, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!
!==============================================================================
!
      program ESMF_CompSetServUTest

!------------------------------------------------------------------------------

#include "ESMF_Macros.inc"

!==============================================================================
!BOP
! !PROGRAM: ESMF_CompSetServUTest - Unit test for Components.
!
! !DESCRIPTION:
!   Test replacing an already registered service routine with another
!   and actually having it take effect.
!
!-------------------------------------------------------------------------
!
! !USES:
    use ESMF_TestMod     ! test methods
    use ESMF_Mod
    use SetServCode   ! "user" code
    implicit none
    
!   ! Local variables
    integer :: rc, userRc
    character(ESMF_MAXSTR) :: cname
    type(ESMF_GridComp) :: comp1
    type(ESMF_VM) :: vm
    integer:: localPet, petCount, i
    integer, allocatable:: petList(:)

    ! individual test failure message
    character(ESMF_MAXSTR) :: failMsg
    character(ESMF_MAXSTR) :: name
    integer :: result = 0

    ! Internal State Variables
    type testData
    sequence
        integer :: testNumber
    end type

    type dataWrapper
    sequence
        type(testData), pointer :: p
    end type

#ifdef ESMF_TESTEXHAUSTIVE
    type (dataWrapper) :: wrap1, wrap2
    type(testData), target :: data1, data2
#endif

!-------------------------------------------------------------------------------
!   The unit tests are divided into Sanity and Exhaustive. The Sanity tests are
!   always run. When the environment variable, EXHAUSTIVE, is set to ON then
!   the EXHAUSTIVE and sanity tests both run. If the EXHAUSTIVE variable is set
!   to OFF, then only the sanity unit tests.
!   Special strings (Non-exhaustive and exhaustive) have been
!   added to allow a script to count the number and types of unit tests.
!-------------------------------------------------------------------------------
        
    call ESMF_TestStart(ESMF_SRCLINE, rc=rc)

! - construct petList according to petCount
    call ESMF_VMGetGlobal(vm, rc=rc)
    if (rc/=ESMF_SUCCESS) call ESMF_Finalize(terminationflag=ESMF_ABORT)
    
    call ESMF_VMGet(vm, petCount=petCount, localPet=localPet, rc=rc)
    if (rc/=ESMF_SUCCESS) call ESMF_Finalize(terminationflag=ESMF_ABORT)
    
    allocate(petList((petCount+1)/2))
    petList=(/(2*i, i=0,(petCount+1)/2-1)/)
    
!-------------------------------------------------------------------------
!   !
    !NEX_UTest
!   !  Create a Component
    cname = "Atmosphere"
    comp1 = ESMF_GridCompCreate(name=cname, gridcompType=ESMF_ATM, &
      petList=petList, configFile="grid.rc", rc=rc)  

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Creating a Component Test"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


!-------------------------------------------------------------------------
!   !
    !NEX_UTest
!   !  Set VM

    call ESMF_GridCompSetVM(comp1, SetVM, rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Setting Component VM"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


!-------------------------------------------------------------------------
!   !
    !NEX_UTest
!   !  Set Services

    call ESMF_GridCompSetServices(comp1, userRoutine=SetServ1, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Setting Component Services"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


!-------------------------------------------------------------------------
!   !
    !NEX_UTest
!   !  Call init

    call ESMF_GridCompInitialize(comp1, userRc=userRc, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Calling Component Init"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)

    !NEX_UTest
    write(failMsg, *) "userRc not ESMF_SUCCESS"
    write(name, *) "Calling Component Init"
    if ((localPet/2)*2 == localPet) then
      call ESMF_Test((userRc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)
    else      
      call ESMF_Test(.true., name, failMsg, result, ESMF_SRCLINE)
    endif


#ifdef ESMF_TESTEXHAUSTIVE
!-------------------------------------------------------------------------
!   !
    !EX_UTest
!   !  Re-Set Services

    call ESMF_GridCompSetServices(comp1, userRoutine=SetServ2, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Setting Component Services for 2nd time"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


!-------------------------------------------------------------------------
!   !
    !EX_UTest
!   !  Call new init

    call ESMF_GridCompInitialize(comp1, userRc=userRc, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Calling Component Init"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)

    !EX_UTest
    write(failMsg, *) "userRc does not contain expected code"
    write(name, *) "Calling Component Init"
    if ((localPet/2)*2 == localPet) then
      call ESMF_Test((userRc.eq.123456), name, failMsg, result, ESMF_SRCLINE)
    else
      call ESMF_Test(.true., name, failMsg, result, ESMF_SRCLINE)
    endif

!-------------------------------------------------------------------------
!   !  Set Internal State
    !EX_UTest
    data1%testnumber=4567
    wrap1%p=>data1

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Set Internal State Test"
    call ESMF_GridCompSetInternalState(comp1, wrap1, rc)
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)

!-------------------------------------------------------------------------
!   !
!   !  Get Internal State
    !EX_UTest
    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Get Internal State Test"
    call ESMF_GridCompGetInternalState(comp1, wrap2, rc)
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)

!-------------------------------------------------------------------------
!   !
!   !  Verify Internal State
    !EX_UTest
    data2 = wrap2%p 
    write(failMsg, *) "Did not return correct data"
    write(name, *) "Verify Internal State Test"
    call ESMF_Test((data2%testnumber.eq.4567), name, failMsg, result, ESMF_SRCLINE)
    print *, "data2%testnumber = ", data2%testnumber


!-------------------------------------------------------------------------
!   !
    !EX_UTest
!   !  Destroying a component

    call ESMF_GridCompDestroy(comp1, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Destroying a Component Test"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)

!-------------------------------------------------------------------------
!   !
    !EX_UTest
!   !  Create a Component
    cname = "Atmosphere - child in parent VM context"
    comp1 = ESMF_GridCompCreate(name=cname, gridcompType=ESMF_ATM, &
      configFile="grid.rc", contextflag=ESMF_CHILD_IN_PARENT_VM, rc=rc)  

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Creating a Component Test"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


!-------------------------------------------------------------------------
!   !
    !EX_UTest
!   !  Set Services

    call ESMF_GridCompSetServices(comp1, userRoutine=SetServ1, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Setting Component Services"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


!-------------------------------------------------------------------------
!   !
    !EX_UTest
!   !  Call init

    call ESMF_GridCompInitialize(comp1, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Calling Component Init"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


#endif

!-------------------------------------------------------------------------
!   !
    !NEX_UTest
!   !  Destroying a component

    call ESMF_GridCompDestroy(comp1, rc=rc)

    write(failMsg, *) "Did not return ESMF_SUCCESS"
    write(name, *) "Destroying a Component Test"
    call ESMF_Test((rc.eq.ESMF_SUCCESS), name, failMsg, result, ESMF_SRCLINE)


    call ESMF_TestEnd(result, ESMF_SRCLINE)

    end program ESMF_CompSetServUTest
    
