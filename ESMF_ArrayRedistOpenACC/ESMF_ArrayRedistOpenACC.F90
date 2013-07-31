program arrayredistopenacc

  ! modules
  use ESMF
  
  implicit none
  
  ! local variables
  integer :: localPet, petCount, rc=ESMF_SUCCESS
  type(ESMF_VM):: vm

  real(ESMF_KIND_R8)    :: pi
  real(ESMF_KIND_R8), pointer :: farrayPtr(:,:)   ! matching F90 array pointer
  integer               :: i, j, il, iu, jl, ju

  real(ESMF_KIND_R8)    :: starttime, stoptime

  type(ESMF_DELayout)   :: delayout
  type(ESMF_ArraySpec)  :: arrayspec
  type(ESMF_DistGrid)   :: distgrid
  type(ESMF_Array)      :: array
  
  ! Initialize framework and get back default global VM
  call ESMF_Initialize(vm=vm, &
    defaultlogfilename="ArrayRedistOpenACC.Log", &
    logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  print *, "------------------------------------------------------------------"
  print *, "-------------- START of ESMF_ArrayRedistOpenACC Test -------------"
  print *, "------------------------------------------------------------------" 

  ! Get number of PETs we are running with
  call ESMF_VMGet(vm, petCount=petCount, localPet=localPet, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Check for correct number of PETs
  if ( petCount > 1 ) then
    call ESMF_LogWrite(msg="This system test does not run on more than 1 PET.",&
      logmsgFlag=ESMF_LOGMSG_ERROR, rc=rc)
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)
  endif

  ! create a source array with a DELayout which specifies that 8 DE's will
  ! run on a single PET, allowing OpenACC to utilize a GPU (8) unit
  call ESMF_ArraySpecSet(arrayspec, typekind=ESMF_TYPEKIND_R8, rank=2, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  delayout = ESMF_DELayoutCreate(petMap=(/0,0,0,0,0,0,0,0,0/), rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  distgrid = ESMF_DistGridCreate(minIndex=(/1,1/), maxIndex=(/10000,15000/), &
    delayout=delayout, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  array = ESMF_ArrayCreate(arrayspec=arrayspec, distgrid=distgrid, &
    indexflag=ESMF_INDEX_GLOBAL, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Gain access to actual data via F90 array pointer
  call ESMF_ArrayGet(array, localDe=0, farrayPtr=farrayPtr, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
    
  ! Fill source Array with data
  ! For OpenACC to work correctly the loop bounds need to be obtained
  ! outside of the OpenACC region!
  jl = lbound(farrayPtr, 2)
  ju = ubound(farrayPtr, 2)
  il = lbound(farrayPtr, 1)
  iu = ubound(farrayPtr, 1)

  ! start timeer
  call ESMF_VMWtime(starttime, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

!$acc kernels
  do j = jl, ju
    do i = il, iu
      farrayPtr(i,j) = 10.0d0 &
        + 5.0d0 * sin(real(i,ESMF_KIND_R8)/100.d0*pi) &
        + 2.0d0 * sin(real(j,ESMF_KIND_R8)/1500.d0*pi)
    enddo
  enddo
!$acc end kernels

  ! stop timeer
  call ESMF_VMWtime(stoptime, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
  
  ! Test Array against exact solution
  do j = lbound(farrayPtr, 2), ubound(farrayPtr, 2)
    do i = lbound(farrayPtr, 1), ubound(farrayPtr, 1)
      if (abs(farrayPtr(i,j) - (10.0d0 &
        + 5.0d0 * sin(real(i,ESMF_KIND_R8)/100.d0*pi) &
        + 2.0d0 * sin(real(j,ESMF_KIND_R8)/1500.d0*pi))) > 1.d-8) then
        rc=ESMF_FAILURE
      endif
    enddo
  enddo

  ! test for failure
  if (rc /= ESMF_SUCCESS) then
    print *, "FAIL"
  else 
    print *, "SUCCESS"
    print *, "elapsed time = ", stoptime-starttime
  endif

  print *, "------------------------------------------------------------------"
  print *, "-------------- END of ESMF_ArrayRedistOpenACC Test ---------------"
  print *, "------------------------------------------------------------------"

  call ESMF_Finalize()
  
end program
