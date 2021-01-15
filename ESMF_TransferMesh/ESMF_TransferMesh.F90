! $Id$
!
!-------------------------------------------------------------------------
!ESMF_MULTI_PROC_SYSTEM_TEST   String used by test script to count system tests.
!=========================================================================

!-------------------------------------------------------------------------
!
! !DESCRIPTION:
! System test TransferMesh.
!
!   Two Gridded Components and one Coupler Component.
!
!   The first Gridded Component runs on 4 PETs and defines a source Mesh with
!   a 16 element index. This Mesh is used to build a source Field, and added
!   to the component's exportState. The second Gridded Component only runs on 2
!   PETs and defines an empty Field that is added to its importState.
!
!   The Coupler Component runs on all 6 PETs and transfers the Mesh from
!   Component 1 with Component 2.
!
!   Redist and Regrid operations are performed between the two Gridded
!   Components to test correct behavior of the transferred Mesh.
!
!-------------------------------------------------------------------------
!\begin{verbatim}

program ESMF_TransferMeshSTest

  ! ESMF Framework module
  use ESMF

  use user_model1, only : userm1_setvm, userm1_register
  use user_model2, only : userm2_setvm, userm2_register
  use user_coupler, only : usercpl_setvm, usercpl_register

  implicit none

  ! Local variables
  integer :: localPet, petCount, userrc, rc
  character(len=ESMF_MAXSTR) :: cname1, cname2, cplname
  type(ESMF_VM):: vm
  type(ESMF_State) :: c1exp, c2imp
  type(ESMF_GridComp) :: comp1, comp2
  type(ESMF_CplComp) :: cpl

  integer :: i
  ! cheyenne
  integer :: n_ocn = 864
  integer :: n_ice = 72
  ! ! local test
  ! integer, parameter :: n_ocn = 4
  ! integer, parameter :: n_ice = 2
  integer, dimension(n_ocn) :: pet_ocn
  integer, dimension(n_ice) :: pet_ice

  ! cumulative result: count failures; no failures equals "all pass"
  integer :: result = 0

  ! individual test name
  character(ESMF_MAXSTR) :: testname

  ! individual test failure message, and final status msg
  character(ESMF_MAXSTR) :: failMsg, finalMsg

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  write(testname, *) "ESMF_TransferMesh CESM OCN-ICE redist error reproducer"
  write(failMsg, *) "Failure"

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
! Create section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!
  ! Initialize framework and get back default global VM
  call ESMF_Initialize(vm=vm, &
    defaultlogfilename="TransferMesh.Log", &
    logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_LogSet (flush=.true.)

  ! Get number of PETs we are running with
  call ESMF_VMGet(vm, petCount=petCount, localPet=localPet, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  if (localPet == 0) then 
    print *, "--------------------------------------- "
    print *, "Start of ", trim(testname)
    print *, "--------------------------------------- "
  endif


   ! Check for correct number of PETs
  if ( petCount < (n_ocn + n_ice) ) then
     call ESMF_LogSetError(ESMF_RC_ARG_BAD,&
         msg="This test requires more PETs.",&
         line=__LINE__, file=__FILE__)
     call ESMF_Finalize(endflag=ESMF_END_ABORT)
   endif


  ! Create the 2 model components and coupler
  cname1 = "OCN proxy"
  
  do i = 1, n_ocn
    pet_ocn(i) = i - 1
  end do
  do i = 1, n_ice
    pet_ice(i) = n_ocn - 1 + i
  end do
  
  comp1 = ESMF_GridCompCreate(name=cname1, petList=pet_ocn, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  cname2 = "ICE proxy"
  ! use petList to define comp2 on PET 4,5
  comp2 = ESMF_GridCompCreate(name=cname2, petList=pet_ice, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  cplname = "OCN-ICE-MED proxy"
  ! no petList means that coupler component runs on all PETs
  cpl = ESMF_CplCompCreate(name=cplname, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
! Register section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  call ESMF_GridCompSetVM(comp1, userRoutine=userm1_setvm, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_GridCompSetServices(comp1, userRoutine=userm1_register, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_GridCompSetVM(comp2, userRoutine=userm2_setvm, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_GridCompSetServices(comp2, userRoutine=userm2_register, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_CplCompSetVM(cpl, userRoutine=usercpl_setvm, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_CplCompSetServices(cpl, userRoutine=usercpl_register, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
! State create section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  c1exp = ESMF_StateCreate(name="comp1 export",  &
    stateintent=ESMF_STATEINTENT_EXPORT, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  c2imp = ESMF_StateCreate(name="comp2 import",  &
    stateintent=ESMF_STATEINTENT_IMPORT, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
! Init section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  ! Comp1 Initialize phase=1
  call ESMF_GridCompInitialize(comp1, exportState=c1exp, phase=1, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Comp2 Initialize phase=1
  call ESMF_GridCompInitialize(comp2, importState=c2imp, phase=1, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! CPL Initialize phase=1
  ! note that the coupler's import is comp1's export state
  ! and coupler's export is comp2's import state
  call ESMF_CplCompInitialize(cpl, importState=c1exp, exportState=c2imp, &
    phase=1, userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Comp1 Initialize phase=2
  call ESMF_GridCompInitialize(comp1, exportState=c1exp, phase=2, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Comp2 Initialize phase=2
  call ESMF_GridCompInitialize(comp2, importState=c2imp, phase=2, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! CPL Initialize phase=2
  call ESMF_CplCompInitialize(cpl, importState=c1exp, exportState=c2imp, &
    phase=2, userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Comp1 Initialize phase=3
  call ESMF_GridCompInitialize(comp1, exportState=c1exp, phase=3, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Comp2 Initialize phase=3
  call ESMF_GridCompInitialize(comp2, importState=c2imp, phase=3, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! CPL Initialize phase=3
  call ESMF_CplCompInitialize(cpl, importState=c1exp, exportState=c2imp, &
    phase=3, userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
! Run section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  call ESMF_GridCompRun(comp1, exportState=c1exp, userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_CplCompRun(cpl, importState=c1exp, exportState=c2imp, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_GridCompRun(comp2, importState=c2imp, &
    userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
! Finalize section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  call ESMF_CplCompFinalize(cpl, importState=c1exp, &
    exportState=c2imp, userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_GridCompFinalize(comp1, exportState=c1exp, &
      userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_GridCompFinalize(comp2, importState=c2imp, &
      userRc=userrc, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  if (ESMF_LogFoundError(rcToCheck=userrc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
! Destroy section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  call ESMF_GridCompDestroy(comp1, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  call ESMF_GridCompDestroy(comp2, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  call ESMF_CplCompDestroy(cpl, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_StateDestroy(c1exp, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  call ESMF_StateDestroy(c2imp, rc=rc)
  if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
    line=__LINE__, file=__FILE__)) &
    call ESMF_Finalize(endflag=ESMF_END_ABORT)

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

  if (rc .eq. ESMF_SUCCESS) then
    if (localPet == 0) then
      write(finalMsg, *) "SUCCESS: ",trim(testname)," finished correctly."
      write(0, *) trim(finalMsg)
    endif
  else
    write(finalMsg, *) localPet, "# ", trim(failMsg), " - ", trim(testname)
    write(0, *) trim(finalMsg)
  endif
  
  
  
  call ESMF_Finalize()

end program ESMF_TransferMeshSTest

!\end{verbatim}
