! Ryan O'Kuinghttons
! May 5, 2019
! F90 reproducer for SMM double free segfault demonstrated in ticket 3614712

! #define ANALYTIC_DATA

program regrid

  use ESMF
  implicit none
  integer :: localrc
  integer :: localPet, petCount
  type(ESMF_VM) :: vm

  character(*), parameter :: srcfile = "t_2016123100.nc"
  character(*), parameter :: dstfile = "temporal_coords.nc"

  type(ESMF_Grid) :: srcGrid, dstGrid
  type(ESMF_Field) :: srcField, dstField, xctField
  type(ESMF_Array) :: srcFieldArray, dstFieldArray, xctFieldArray
  type(ESMF_RouteHandle) :: routeHandle
  real(ESMF_KIND_R8), pointer :: srcFarrayPtr(:,:,:,:), dstFarrayPtr(:,:,:,:), &
                                 xctFarrayPtr(:,:,:,:)

  integer :: i1, i2, i3, i4
  integer(ESMF_KIND_I4) :: clbnd(4), cubnd(4)
  real(ESMF_KIND_R8), parameter :: UNINITVAL = 1E-20
  
  integer(ESMF_KIND_I4) :: unmapped_count(1), unmapped_countg(1)
  real(ESMF_KIND_R8) :: maxerror(1), minerror(1), error
  real(ESMF_KIND_R8) :: maxerrorg(1), minerrorg(1), errorg
  real(ESMF_KIND_R8) :: errorTot, errorTotG

  ! file specific parameters
  integer :: timesteps = 25

  ! in serial, value higher than 9 segfaults in SMM with double free
  ! in parallel we can access all 48 levels in the file
  integer :: levels = 10

   ! Init ESMF
  call ESMF_Initialize(rc=localrc, logappendflag=.false.)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Write out number of PETS
  if (localPet .eq. 0) then
     write(*,*)
     write(*,*) "REGRIDDING FROM ",trim(srcfile)," TO ",trim(dstfile)
     write(*,*) "NUMBER OF PROCS = ",petCount
     write(*,*)
  endif


  !!!!!!!!!!!!!!!!!!!!!! SOURCE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  srcGrid=ESMF_GridCreate(filename=srcfile, fileformat=ESMF_FILEFORMAT_CFGRID, &
                          rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  srcField = ESMF_FieldCreate(srcGrid, ESMF_TYPEKIND_R8, &
                              staggerloc=ESMF_STAGGERLOC_CENTER, &
                              gridToFieldMap=(/1,2/), &
                              ungriddedLBound=(/1,1/), &
                              ungriddedUBound=(/levels,timesteps/), &
                              name="src", rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


#ifdef ANALYTIC_DATA

  call ESMF_FieldGet(srcField, 0, srcFarrayPtr, computationalLBound=clbnd, &
                     computationalUBound=cubnd,  rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Set field values
  do i1=clbnd(1),cubnd(1)
    do i2=clbnd(2),cubnd(2)
      do i3=clbnd(3),cubnd(3)
        do i4=clbnd(4),cubnd(4)
          srcFarrayPtr(i1,i2,i3,i4) = i3
        enddo
      enddo
    enddo
  enddo

#else

  call ESMF_FieldRead(srcField, srcfile, variableName="t",&
                      timeslice=timesteps, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

#endif
  
  !!!!!!!!!!!!!!!!!!!!!! DESTINATION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  
  
  dstGrid=ESMF_GridCreate(filename=dstfile, fileformat=ESMF_FILEFORMAT_CFGRID, &
                          rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  dstField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
                              staggerloc=ESMF_STAGGERLOC_CENTER, &
                              gridToFieldMap=(/1,2/), &
                              ungriddedLBound=(/1,1/), &
                              ungriddedUBound=(/levels,timesteps/), &
                              name="dst", rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  xctField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
                              staggerloc=ESMF_STAGGERLOC_CENTER, &
                              gridToFieldMap=(/1,2/), &
                              ungriddedLBound=(/1,1/), &
                              ungriddedUBound=(/levels,timesteps/), &
                              name="xct", rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_FieldGet(dstField, 0, dstFarrayPtr, computationalLBound=clbnd, &
                     computationalUBound=cubnd,  rc=localrc)
  call ESMF_FieldGet(xctField, 0, xctFarrayPtr, computationalLBound=clbnd, &
                     computationalUBound=cubnd,  rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Set field values
  do i1=clbnd(1),cubnd(1)
    do i2=clbnd(2),cubnd(2)
      do i3=clbnd(3),cubnd(3)
        do i4=clbnd(4),cubnd(4)
          xctFarrayPtr(i1,i2,i3,i4) = i3
          dstFarrayPtr(i1,i2,i3,i4) = UNINITVAL
        enddo
      enddo
    enddo
  enddo

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  REGRID  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  call ESMF_FieldRegridStore(srcField, dstField=dstField, &
                             routeHandle=routeHandle, &
                             regridmethod=ESMF_REGRIDMETHOD_BILINEAR, &
                             unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, &
                             rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_FieldRegrid(srcField, dstField, routeHandle, &
                        zeroregion=ESMF_REGION_SELECT, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_FieldRegridRelease(routeHandle, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)



  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  VERIFY !!!!!!!!!!!!!!!!!!!!!!!!!!
  
#ifdef ANALYTIC_DATA

  minerror(1) = 100000.
  maxerror(1) = 0.
  error = 0.
  errorTot = 0.0

  call ESMF_FieldGet(dstField, 0, dstFarrayPtr, computationalLBound=clbnd, &
                     computationalUBound=cubnd, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_FieldGet(xctField, 0, xctFarrayPtr, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  !! check relative error
  unmapped_count(1) = 0;
  unmapped_countg(1) = 0;
  do i1=clbnd(1),cubnd(1)
    do i2=clbnd(2),cubnd(2)
      do i3=clbnd(3),cubnd(3)
        do i4=clbnd(4),cubnd(4)
    
          ! if value .eq. UNINITVAL
          if (abs (dstFarrayPtr(i1,i2,i3,i4) - UNINITVAL) < 1.0D-12) then
              unmapped_count(1) = unmapped_count(1) + 1
              ! write (*,*) "unmapped point at ", i1
              error = 0
          else
            ! if value .ne. 0 
            if (abs(xctFarrayPtr(i1,i2,i3,i4)) > 1.0D-12) then
              error=ABS(dstFarrayPtr(i1,i2,i3,i4) - xctFarrayPtr(i1,i2,i3,i4)) &
                    /ABS(xctFarrayPtr(i1,i2,i3,i4))
            else
              error=ABS(dstFarrayPtr(i1,i2,i3,i4) - xctFarrayPtr(i1,i2,i3,i4))
            endif
          endif
      
          errorTot=errorTot+error
          if (error > maxerror(1)) then
            maxerror(1) = error
          endif
          if (error < minerror(1)) then
            minerror(1) = error
          endif

        enddo
      enddo
    enddo
  enddo



  !!!!!!!!!!!!!!!!!!!!!!!!!!! COMMUNICATION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  call ESMF_VMAllReduce(vm, maxerror, maxerrorg, 1, ESMF_REDUCE_MAX, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_VMAllReduce(vm, minerror, minerrorg, 1, ESMF_REDUCE_MIN, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_VMAllReduce(vm, unmapped_count, unmapped_countg, 1, ESMF_REDUCE_SUM, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

#endif

  !!!!!!!!!!!!!!!!!!!!!!!!!!!!  FILE OUTPUT !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#if 0
  call ESMF_FieldGet(srcField, array=srcFieldArray, rc=localrc)
  call ESMF_FieldGet(dstField, array=dstFieldArray, rc=localrc)
  call ESMF_FieldGet(xctField, array=xctFieldArray, rc=localrc)

  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_GridWrite(srcGrid,"src", srcFieldArray)
  call ESMF_GridWrite(dstGrid,"dst", dstFieldArray, xctFieldArray)
#endif



  !!!!!!!!!!!!!!!!!!!!!!!!!!!! CLEANUP !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  ! Destroy the Fields
  call ESMF_FieldDestroy(srcField, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_FieldDestroy(dstField, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_FieldDestroy(xctField, rc=localrc)
  if (localrc /=ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! OUTPUT RESULTS !!!!!!!!!!!!!!!!!!!!!!!!!
  
  ! Output Accuracy results
  if (localPet == 0) then
    write(*,*)
#ifdef ANALYTIC_DATA
    write(*,*) unmapped_countg(1), " unmapped points"
    write(*,*) "interp. max. rel. error = ", maxerrorg(1)
#else
    write(*,*) "SUCCESS"
#endif
    write(*,*)
  endif
  
  ! Finalize ESMF
  call ESMF_Finalize()

end program