! March 28, 2019
! Ryan O'Kuinghttons
! compare ESMF to BUMP regridding performance


#define CHECK_ACCURACY
! #define OUTPUT_ERROR

! define one of the following regrid methods
! #define BILINEAR_CENTERS
#define BILINEAR_CORNERS

! Macros to pass the correct information to the error handling
#define ESMF_CONTEXT line=__LINE__,file="esmfbumpeval.F90",method="  "
#define ESMF_ERR_PASSTHRU msg="ESMF library returned Error"



program ESMF_BUMP_eval

  use ESMF
  implicit none
  logical :: correct
  integer :: localrc
  integer :: localPet, petCount
  type(ESMF_VM) :: vm
  integer :: numargs

   ! Init ESMF
  call ESMF_Initialize(rc=localrc, logappendflag=.false.)
  if (localrc /=ESMF_SUCCESS) then
     stop
  endif
! get pet info
   call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /=ESMF_SUCCESS) then
    stop
  endif

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /=ESMF_SUCCESS) then
    stop
  endif

  ! Write out number of PETS
  if (localPet .eq. 0) then
     write(*,*)
     write(*,*) "NUMBER OF PROCS = ",petCount
     write(*,*)
  endif


  ! !!!!!!!!!!!!!!! Time ESMF Regridding !!!!!!!!!!!!
  ! if (localPet .eq. 0) then
  !    write(*,*) "======= ESMF Regridding ======="
  ! endif
  ! 
  ! ! Regridding using ESMF 
  ! call run_regrid(bump=.false., rc=localrc)
  !  if (localrc /=ESMF_SUCCESS) then
  !    write(*,*) "Error in ESMF regridding"
  !    stop
  ! endif

  !!!!!!!!!!!!!!! Time BUMP interpolation !!!!!!!!!!!!
  if (localPet .eq. 0) then
     write(*,*)
     write(*,*)
     write(*,*) "======= BUMP interpolation ======="
  endif
  
  ! Regridding using BUMP
  call run_regrid(bump=.true., rc=localrc)
   if (localrc /=ESMF_SUCCESS) then
     write(*,*) "Error in BUMP interpolation"
          stop
    endif
  
  ! Finalize ESMF
  call ESMF_Finalize(rc=localrc)
  if (localrc /=ESMF_SUCCESS) then
     stop
  endif

contains  


subroutine run_regrid(bump, rc)
  logical, intent(in) :: bump
  integer, intent(out)  :: rc

  integer :: localrc
  character(12) :: NM
  type(ESMF_DistGrid) :: distgrid
  type(ESMF_Grid) :: srcGrid
  type(ESMF_LocStream) :: dstLocStream
  type(ESMF_Field) :: srcField
  type(ESMF_Field) :: dstField
  type(ESMF_Field) :: xdstField
  type(ESMF_RouteHandle) :: routeHandle
  type(ESMF_ArraySpec) :: arrayspec
  type(ESMF_VM) :: vm
  real(ESMF_KIND_R8), pointer :: dstFarrayPtr(:), xdstFarrayPtr(:)

  real(ESMF_KIND_R8), pointer :: latLS(:), lonLS(:)
  real(ESMF_KIND_R8), pointer :: farrayPtrXC(:,:), farrayPtrYC(:,:)
  integer :: clbnd(2),cubnd(2)

  integer :: localPet, petCount
  ! integer :: lDE, localDECount
  integer :: i1, i2
   
  real(ESMF_KIND_R8) :: srcmass(1), dstmass(1), srcmassg(1), dstmassg(1)
  real(ESMF_KIND_R8) :: maxerror(1), minerror(1), error
  real(ESMF_KIND_R8) :: maxerrorg(1), minerrorg(1), errorg

  real(ESMF_KIND_R8) :: errorTot, errorTotG

  real(ESMF_KIND_R8), parameter :: UNINITVAL = 1E-20
  integer(ESMF_KIND_I4) :: unmapped_count(1), unmapped_countg(1)
  real(ESMF_KIND_R8),parameter :: DEG2RAD = 3.141592653589793_ESMF_KIND_R8/180.0_ESMF_KIND_R8
  real(ESMF_KIND_R8) :: theta, phi
  real(ESMF_KIND_R8) :: lat, lon

  integer :: csTileSize
  integer :: decompX, decompY

  integer :: i,j,k,ierr,mpic,esmf_comm,lDE,localDECount
  integer, dimension(2) :: totalLBnd, totalUBnd
  real, dimension(2,10) :: watch
  real(ESMF_KIND_R8), dimension(:,:), pointer :: sfield_ptr
  real(ESMF_KIND_R8), dimension(:,:), pointer :: srcLat,srcLon

!  integer, parameter :: NUM_FIELD     = 275
!  integer, parameter :: TOTAL_NUM_LOC = 75000000

  integer, parameter :: NUM_FIELD     = 30
  integer, parameter :: TOTAL_NUM_LOC = 2400

  integer, dimension(NUM_FIELD) :: wrong

    ! Init to success
  rc=ESMF_SUCCESS

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
      ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  NM = "ESMF"
  if (bump) then
    NM = "BUMP"
  endif

  !!! Src Grid Info !!!
  ! Size
  csTileSize=64  ! Cube Faces are 64 x 64 in size
!  csTileSize=1024

  ! Decompsition
!  decompX=4      ! Decompose Face into 4x4 patches
!  decompY=4
  decompX=32
  decompY=32  

  !!! Dst LocStream Info !!!

#if 0
  ! Write out number of Number of Pets and Grid info
  if (localPet .eq. 0) then
     write(*,*) 
     write(*,*) "Number of PETs:    ",petCount
     write(*,*) 
     write(*,"(a)")         " Src: Cubed Sphere Grid"
     write(*,"(a,i0,a,i0)") "      Size:   6 x ",csTileSize," x ",csTileSize
     write(*,"(a,i0,a,i0)") "      Decomp: ",decompX," x ",decompY
     write(*,*) 
  endif
#endif
  !!! Create Source Grid Objects & Assign Solution !!!
  !---------------------------------------------------
 
  ! Create source Grid
  call create_csphere_grid(csTileSize, decompX, decompY, petCount, &
       srcGrid, localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
 
  ! Create Field
  srcField = ESMF_FieldCreate(srcGrid, typekind=ESMF_TYPEKIND_R8, &          
          staggerloc=ESMF_STAGGERLOC_CENTER, name="source", &
          ! ungriddedLBound=(/1/), ungriddedUBound=(/NUM_FIELD/), & ! Add extra dimension 
          ! gridToFieldMap=(/2,3/), & ! Put the grid dimensions last (i.e. the extra dim first)
          rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call assign_solution_to_field(srcField, localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  
  !!! Create Destination Objects !!!
  !---------------------------------------------------
  call create_my_locstream(localPet, TOTAL_NUM_LOC, dstLocStream, localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! Create Dst Field
  dstField = ESMF_FieldCreate(dstLocStream, &
                              typekind = ESMF_TYPEKIND_R8, &
                              name="dest", &
                              ! ungriddedLBound=(/1/), ungriddedUBound=(/NUM_FIELD/), & ! Add extra dimension 
                              ! gridToFieldMap=(/2/), & ! Put the grid dimensions last (i.e. the extra dim first)
                              rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call zero_locstream_field(dstField,localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! Create Dst Field
  xdstField = ESMF_FieldCreate(dstLocStream, &
                              typekind = ESMF_TYPEKIND_R8, &
                              name="exact", &
                              ! ungriddedLBound=(/1/), ungriddedUBound=(/NUM_FIELD/), & ! Add extra dimension 
                              ! gridToFieldMap=(/2/), & ! Put the grid dimensions last (i.e. the extra dim first)
                              rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
      ESMF_CONTEXT, rcToReturn=rc)) return

  call set_locstream_field(xdstField,localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
      ESMF_CONTEXT, rcToReturn=rc)) return


  !!! Call into the regridding routine !!!
  !---------------------------------------------------

  ! call into ESMF or BUMP regridding
  if (bump) then
    call interp_bump(srcField, srcGrid, dstLocStream, rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
        ESMF_CONTEXT, rcToReturn=rc)) return
  else
    call ESMF_regrid(srcField, dstField, rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
        ESMF_CONTEXT, rcToReturn=rc)) return
  endif
  


#ifdef CHECK_ACCURACY

  ! Check if the values are close
  minerror(1) = 100000.
  maxerror(1) = 0.
  error = 0.
  errorTot=0.0

  ! get dst Field
  call ESMF_FieldGet(dstField, 0, dstFarrayPtr, computationalLBound=clbnd(1:1), &
                     computationalUBound=cubnd(1:1), rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! get exact destination Field
  call ESMF_FieldGet(xdstField, 0, xdstFarrayPtr, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
  
  ! destination grid
  !! check relative error
  unmapped_count(1) = 0;
  unmapped_countg(1) = 0;
  do i1=clbnd(1),cubnd(1)
        
    ! if value .eq. UNINITVAL
    if (abs (dstFarrayPtr(i1) - UNINITVAL) < 1.0D-12) then
        unmapped_count(1) = unmapped_count(1) + 1
        ! write (*,*) "unmapped point at ", i1
        error = 0
    else
      ! if value .ne. 0 
      if (abs(xdstFarrayPtr(i1)) > 1.0D-12) then
        error=ABS(dstFarrayPtr(i1) - xdstFarrayPtr(i1))/ABS(xdstFarrayPtr(i1))
      else
        error=ABS(dstFarrayPtr(i1) - xdstFarrayPtr(i1))
      endif
    endif

    errorTot=errorTot+error
    if (error > maxerror(1)) then
      maxerror(1) = error
    endif
    if (error < minerror(1)) then
      minerror(1) = error
    endif


#ifdef OUTPUT_ERROR
    ! Get coords
    lon=lonLS(i1)
    lat=latLS(i1)

    ! Set the source to be a function of the coordinates
    theta = DEG2RAD*(lon)
    phi = DEG2RAD*(90.-lat)

    if (error > 1E-1) then
      ! print *, i1, ", ", lon, ", ", lat
      !print *, " Error = ", error, "Dst = ", dstFarrayPtr(i1), "Xct = ", xdstFarrayPtr(i1)
      errnum = errnum + 1
    endif

    if (dstFarrayPtr(i1) .eq. UNINITVAL) then
       write (*,*) localPet, ", ", theta, ", ", phi
    endif

#endif
  enddo

  call ESMF_VMAllReduce(vm, maxerror, maxerrorg, 1, ESMF_REDUCE_MAX, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMAllReduce(vm, minerror, minerrorg, 1, ESMF_REDUCE_MIN, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMAllReduce(vm, unmapped_count, unmapped_countg, 1, ESMF_REDUCE_SUM, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

#ifdef OUTPUT_ERROR
  call ESMF_VMAllReduce(vm, errnum, gerrnum, 1, ESMF_REDUCE_SUM, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
#endif

#endif

  ! Destroy the Fields
  call ESMF_FieldDestroy(srcField, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_FieldDestroy(dstField, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_FieldDestroy(xdstField, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! Free the grid
  call ESMF_GridDestroy(srcGrid, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_LocStreamDestroy(dstLocStream, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

#ifdef CHECK_ACCURACY
  ! Output Accuracy results
  if (localPet == 0) then
    write(*,*)
    write(*,*) unmapped_countg(1), " unmapped points"
    write(*,*) "interp. max. rel. error = ", maxerrorg(1)
    write(*,*)
  endif
#endif

end subroutine run_regrid

subroutine ESMF_regrid(srcField, dstField, rc)
  type(ESMF_Field), intent(inout) :: srcField
  type(ESMF_Field), intent(inout) :: dstField
  integer, intent(out), optional :: rc

  type(ESMF_RouteHandle) :: routeHandle
  integer :: localrc
  
  rc = ESMF_SUCCESS
  
  call ESMF_TraceRegionEnter("before ESMF regrid store")
  call ESMF_VMLogMemInfo("before ESMF regrid store")

  call ESMF_FieldRegridStore(srcField, dstField=dstField, &
                             routeHandle=routeHandle, &
                             regridmethod=ESMF_REGRIDMETHOD_BILINEAR, &
                             unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, &
                             rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMLogMemInfo("after ESMF regrid store")
  call ESMF_TraceRegionExit("after ESMF regrid store")

  call ESMF_TraceRegionEnter("before ESMF regrid")
  call ESMF_VMLogMemInfo("before ESMF regrid")

  ! Do regrid
  call ESMF_FieldRegrid(srcField, dstField, routeHandle, &
                        zeroregion=ESMF_REGION_SELECT, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMLogMemInfo("after ESMF regrid")
  call ESMF_TraceRegionExit("after ESMF regrid")

  call ESMF_TraceRegionEnter("before ESMF regrid release")
  call ESMF_VMLogMemInfo("before ESMF regrid release")

  call ESMF_FieldRegridRelease(routeHandle, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMLogMemInfo("after ESMF regrid release")
  call ESMF_TraceRegionExit("after ESMF regrid release")

end subroutine

subroutine interp_bump(field, grid, locstream, rc)

  use type_bump, only: bump_type
  
  implicit none
  type(ESMF_Field), intent(in) :: field
  type(ESMF_Grid), intent(in) :: grid
  type(ESMF_LocStream), intent(in) :: locstream
  integer, intent(inout), optional :: rc
  
  real(ESMF_KIND_R8), pointer :: grid_lon(:,:), grid_lat(:,:)
  integer(ESMF_KIND_I4) :: totalLBnd(2), totalUBnd(2)

  real(ESMF_KIND_R8), pointer :: ls_lon(:), ls_lat(:)
  integer :: cl, cu

  integer :: localrc, lDE, localDECount

  type(bump_type) :: bump
  
  integer :: mod_nx,mod_ny,mod_nz,mod_num,obs_num
  real(ESMF_KIND_R8), allocatable :: mod_lon(:), mod_lat(:)
  
  real(ESMF_KIND_R8), allocatable :: area(:),vunit(:,:)
  logical, allocatable :: lmask(:,:)
  
  
  rc = ESMF_SUCCESS
  
  ! get Grid coordinates
  call ESMF_GridGet(grid, localDECount=localDECount, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  do lDE=0,localDECount-1
    call ESMF_GridGetCoord(grid, staggerLoc=ESMF_STAGGERLOC_CENTER,   &
          localDE=lDE, coordDim=1, farrayPtr=grid_lon, &
          totalLBound=totalLBnd, totalUBound=totalUBnd, rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
    call ESMF_GridGetCoord(grid, staggerLoc=ESMF_STAGGERLOC_CENTER,   &
          localDE=lDE, coordDim=2, farrayPtr=grid_lat, rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    !Get the Solution dimensions
    !---------------------------
    mod_nx  = totalUBnd(1) - totalLBnd(1) + 1  
    mod_ny  = totalUBnd(2) - totalLBnd(2) + 1
    mod_num = mod_nx * mod_ny
    ! mod_nz  = grid%npz
    
    !Calculate interpolation weight using BUMP
    !-----------------------------------------
    ! RLO comment out allocate as it was triggering a Fortran ABORT saying it was already allocated..
    ! allocate( mod_lon(mod_num), mod_lat(mod_num) )
    mod_lon = reshape(grid_lon(totalLBnd(1):totalUBnd(1), &
                               totalLBnd(2):totalUBnd(2)), &
                      [mod_num])  
    mod_lat = reshape(grid_lat(totalLBnd(1):totalUBnd(1), &
                               totalLBnd(2):totalUBnd(2)), &
                      [mod_num])

  enddo
  
  ! get locstream coordinates
  call  ESMF_LocStreamGet(locStream, &
                          localDECount=localDECount, &
                          rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
  
  ! Loop over each local DE pulling out memory and setting coordinates
  do lDE=0,localDECount-1

    ! Get bounds of this DE
    call  ESMF_LocStreamGetBounds(locStream, &
                                  localDE=lDE, &
                                  computationalLBound=cl, &
                                  computationalUBound=cu, &
                                  rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    ! Get memory for latitudes
    call ESMF_LocStreamGetKey(locStream, &
                              localDE=lDE, &
                              keyName="ESMF:Lat", &
                              farray=ls_lat, &
                              rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return


    ! Get memory for longitudes
    call ESMF_LocStreamGetKey(locStream, &
                              localDE=lDE, &
                              keyName="ESMF:Lon", &
                              farray=ls_lon, &
                              rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    obs_num = cu - cl + 1
  enddo

  !Important namelist options
  bump%nam%prefix = 'oops_data'   ! Prefix for files output
  bump%nam%nobs = obs_num         ! Number of observations
  bump%nam%obsop_interp = 'bilin' ! Interpolation type (bilinear)
  bump%nam%obsdis = 'local'       ! Observation distribution parameter ('random','local' or 'adjusted')
  bump%nam%diag_interp = 'bilin'

  ! RLO: options added to make it work
  bump%nam%model = ''
  bump%nam%verbosity = 'all'

  !Less important namelist options (should not be changed)
  bump%nam%default_seed = .true.
  bump%nam%new_hdiag = .false.
  bump%nam%check_adjoints = .false.
  bump%nam%check_pos_def = .false.
  bump%nam%check_dirac = .false.
  bump%nam%check_randomization = .false.
  bump%nam%check_consistency = .false.
  bump%nam%check_optimality = .false.
  bump%nam%new_lct = .false.
  bump%nam%new_obsop = .true.

  !Initialize geometry
  allocate(area(mod_num))
  allocate(vunit(mod_num,1))
  allocate(lmask(mod_num,1))
  area = 1.0           ! Dummy area
  vunit = 1.0          ! Dummy vertical unit
  lmask = .true.       ! Mask

  !Initialize BUMP
  call bump%setup_online( mod_num,1,1,1,mod_lon,mod_lat,area,vunit,lmask, &
                           nobs=obs_num,lonobs=ls_lon(:),latobs=ls_lat(:) )

  !Release memory
  deallocate(area)
  deallocate(vunit)
  deallocate(lmask)
  deallocate(mod_lon, mod_lat)

end subroutine interp_bump

subroutine compute_max_avg_time(in, max, avg, rc)
  real(ESMF_KIND_R8) :: in,max,avg
  type(ESMF_VM) :: vm
  real(ESMF_KIND_R8) :: in_array(1)
  real(ESMF_KIND_R8) :: in_max_array(1)
  real(ESMF_KIND_R8) :: in_sum_array(1)
  integer :: localrc, rc, petCount, localPet

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  in_array(1)=in

  call ESMF_VMAllReduce(vm, in_array, in_sum_array, 1, &
       ESMF_REDUCE_SUM, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  call ESMF_VMAllReduce(vm, in_array, in_max_array, 1, &
       ESMF_REDUCE_MAX, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! do output
  avg=in_sum_array(1)/REAL(petCount,ESMF_KIND_R8)
  max=in_max_array(1)

end subroutine compute_max_avg_time

!
!---------------------- create_csphere_grid -----------------------
!
! Create a cubed sphere grid.
! Each of the 6 tiles will be divided into 
! decompX pieces along the x dimension and 
! decompY pieces along the y dimension. 
! The pieces will be dealt in turn to the processors
subroutine create_csphere_grid(csTileSize, decompX, decompY, petCount,  grid, rc)
  integer :: csTileSize
  integer :: decompX, decompY
  integer :: petCount
  type(ESMF_Grid), intent(out) :: grid
  integer, intent(out)  :: rc
  integer :: regDecompPTile(2,6)
  type(ESMF_DELayout) :: delayout
  integer, pointer :: petMap(:)
  integer :: numDEs, de, pet
 
 
  ! Number of DEs
  numDEs=6*decompX*decompY
 
  ! Setup decomposition per tile
  regDecompPTile(:,1)=(/decompX,decompY/)
  regDecompPTile(:,2)=(/decompX,decompY/)
  regDecompPTile(:,3)=(/decompX,decompY/)
  regDecompPTile(:,4)=(/decompX,decompY/)
  regDecompPTile(:,5)=(/decompX,decompY/)
  regDecompPTile(:,6)=(/decompX,decompY/)
 
 
  ! Create array which tells which PET/processor each DE goes on
  ! (As an example, deal out processors in order to DEs)
  allocate(petMap(numDEs))
  pet=0
  do de=1,numDEs
     ! Set DE to pet mapping
     petMap(de)=pet
        
     ! Advance to next pet
     pet=pet+1
     if (pet > petCount-1) pet=0
  enddo
 
  ! Create delayout to specify which PET/processor each DE goes on
  delayout=ESMF_DELayoutCreate(petMap=petMap, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
 
  ! Free petMap array 
  deallocate(petMap)
 
  ! Create cubesphere Grid
  ! (this call sets the grid coordinates internally) 
  grid=ESMF_GridCreateCubedSphere(tileSize=csTileSize, &
       regDecompPTile=regDecompPTile, &
       staggerLocList = (/ESMF_STAGGERLOC_CORNER, ESMF_STAGGERLOC_CENTER/), &
       delayout=delayout, &
       rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

end subroutine create_csphere_grid

!
!------------------- create_my_locstream --------------------
!
! Create a location stream and fill it with coordinates
! LocStream will be set of points around equator.
! Points will be equally divided between processors
subroutine create_my_locstream(ran_seed,num_loc, locstream, rc)
  integer, intent(in) :: ran_seed,num_loc
  type(ESMF_LocStream), intent(out) :: locStream
  integer, intent(out)  :: rc
  integer :: lDE, localDECount
  real(ESMF_KIND_R8), pointer :: latArray(:),lonArray(:)
  integer :: i,cl,cu
  integer, allocatable, dimension(:) :: seed
  real(ESMF_KIND_R8) :: rand
  
  ! Configure Random Number Generator
  call random_seed(size=i)
  allocate( seed(i) )
  seed(:) = ran_seed
  call random_seed(put=seed)

  ! Create locstream structure
  ! Use default option to just divide it evenly across pets
  locstream=ESMF_LocStreamCreate(maxIndex=num_loc, &
                                 indexflag=ESMF_INDEX_GLOBAL, &
                                 coordSys=ESMF_COORDSYS_SPH_DEG, &
                                 rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
  
  
  ! Get number of DEs on this pet
  ! Should be 1, but could be 0 if divided across enough processors
  call  ESMF_LocStreamGet(locStream, &
                          localDECount=localDECount, &
                          rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
  
  ! Internally allocate memory to hold latitude coordinates
  call ESMF_LocStreamAddKey(locStream, &
                            keyName="ESMF:Lat", &
                            KeyTypeKind=ESMF_TYPEKIND_R8, &
                            rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
  
  ! Internally allocate memory to hold longitude coordinates
  call ESMF_LocStreamAddKey(locStream, &
                            keyName="ESMF:Lon", &
                            KeyTypeKind=ESMF_TYPEKIND_R8, &
                            rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return


  ! Loop over each local DE pulling out memory and setting coordinates
  do lDE=0,localDECount-1

    ! Get bounds of this DE
    call  ESMF_LocStreamGetBounds(locStream, &
                               localDE=lDE, &
                               computationalLBound=cl, &
                               computationalUBound=cu, &
                               rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    ! Get memory for latitudes
    call ESMF_LocStreamGetKey(locStream, &
                             localDE=lDE, &
                             keyName="ESMF:Lat", &
                             farray=latArray, &
                             rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return


    ! Get memory for longitudes
    call ESMF_LocStreamGetKey(locStream, &
                             localDE=lDE, &
                             keyName="ESMF:Lon", &
                             farray=lonArray, &
                             rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    ! Loop over DE setting random coordinates
    do i=cl,cu
      call random_number(rand)
      latArray(i) =  -89.9999 + (rand * 179.9999)
      call random_number(rand)
      lonArray(i) =    0.0 + (rand * 359.9999)  
    enddo
  enddo

  deallocate(seed)

end subroutine create_my_locstream


!                                                                                                                         
!---------------------- zero_field -----------------------                                                  
!                                                                                                                         
subroutine zero_locstream_field(field, rc)
  type(ESMF_Field), intent(in) :: field
  integer, intent(out), optional  :: rc

  integer :: i,j,lDE, localDECount, localrc
  integer, dimension(1) :: totalLBnd, totalUBnd
  real(ESMF_KIND_R8), dimension(:), pointer :: sfield_ptr

  rc = ESMF_SUCCESS

  ! Get the grid & # of local DE from the Field                                                                          
  call ESMF_FieldGet(field=field, localDeCount=localDECount, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! Set the source Field values at each location
  do lDE=0,localDECount-1

    ! Retrieve the data pointer and bounds from the field
    call ESMF_FieldGet(field=field, localDe=lDE, farrayPtr=sfield_ptr, &
          totalLBound=totalLBnd, totalUBound=totalUBnd, &
          rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    ! Now set bogus value using:
    ! sfield_ptr(:,:) = Pointer to Field Data                                                               
    ! do j = totalLBnd(2), totalUBnd(2)
    do i = totalLBnd(1), totalUBnd(1)
      sfield_ptr(i) = REAL(-999.99, ESMF_KIND_R8)
    enddo

  enddo
end subroutine zero_locstream_field

!!                                                                                                                         
!---------------------- set_field -----------------------                                                  
!                                                                                                                         
subroutine set_locstream_field(field, rc)
  type(ESMF_Field), intent(in) :: field
  integer, intent(out), optional  :: rc

  integer :: i,j,lDE, localDECount, localrc
  integer, dimension(1) :: totalLBnd, totalUBnd
  real(ESMF_KIND_R8), dimension(:), pointer :: sfield_ptr

  rc = ESMF_SUCCESS

  ! Get the grid & # of local DE from the Field                                                                          
  call ESMF_FieldGet(field=field, localDeCount=localDECount, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! Set the source Field values at each location
  do lDE=0,localDECount-1

    ! Retrieve the data pointer and bounds from the field
    call ESMF_FieldGet(field=field, localDe=lDE, farrayPtr=sfield_ptr, &
          totalLBound=totalLBnd, totalUBound=totalUBnd, &
          rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    ! Now set bogus value using:
    ! sfield_ptr(:,:) = Pointer to Field Data                                                               
    ! do j = totalLBnd(2), totalUBnd(2)
    do i = totalLBnd(1), totalUBnd(1)
      ! sfield_ptr(i) = REAL(-999.99, ESMF_KIND_R8)
      sfield_ptr(i) = 42
    enddo

  enddo
end subroutine set_locstream_field

!
!---------------------- assign_solution_to_field -----------------------
!
subroutine assign_solution_to_field(field, rc)
  type(ESMF_Field), intent(in) :: field
  integer, intent(out), optional  :: rc
  
  type(ESMF_Grid) :: fgrid
  integer :: i,j,k,lDE, localDECount, localrc
  integer, dimension(2) :: totalLBnd, totalUBnd
  real(ESMF_KIND_R8), dimension(:,:), pointer :: sfield_ptr
  real(ESMF_KIND_R8), dimension(:,:), pointer :: grid_lat,grid_lon

  rc = ESMF_SUCCESS

  ! Get the grid & # of local DE from the Field
  call ESMF_FieldGet(field=field, grid=fgrid, localDeCount=localDECount, rc=localrc)
  if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

  ! Set the source Field values at each location 
  do lDE=0,localDECount-1
     
    ! Retrieve the data pointer and bounds from the field
    call ESMF_FieldGet(field=field, localDe=lDE, farrayPtr=sfield_ptr, &
          totalLBound=totalLBnd, totalUBound=totalUBnd, &
          rc=localrc) 
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return

    call ESMF_GridGetCoord(fgrid, staggerLoc=ESMF_STAGGERLOC_CENTER,   &
          localDE=lDE, coordDim=1, farrayPtr=grid_lon, rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
    call ESMF_GridGetCoord(fgrid, staggerLoc=ESMF_STAGGERLOC_CENTER,   &
          localDE=lDE, coordDim=2, farrayPtr=grid_lat, rc=localrc)
    if (ESMF_LogFoundError(localrc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) return
     
    ! Now set known function using:
    ! sfield_ptr(:,:) = Pointer to Field Data
    ! grid_lat(:,:)   = Grid Lat Coordniates
    ! grid_lon(:,:)   = Grid Lon Coordniates
    ! do k = totalLBnd(3), totalUBnd(3)
    do j = totalLBnd(2), totalUBnd(2)
      do i = totalLBnd(1), totalUBnd(1)
        call latlon_solution(grid_lat(i,j),grid_lon(i,j),REAL(i,ESMF_KIND_R8),sfield_ptr(i,j))
      enddo
    enddo
  
  enddo

end subroutine assign_solution_to_field

!
!---------------------- latlon_solution -----------------------
!
subroutine latlon_solution(lat,lon,inc,ans)
  real(ESMF_KIND_R8), intent(in) :: lat,lon,inc
  real(ESMF_KIND_R8), intent(out) :: ans
   
  ! ans = inc + (90.0 - abs(lat))/90.0 + min(lon,360.0-lon)/180.0
  !constant
  ans = 42

end subroutine latlon_solution


!
!---------------------- handle_error -----------------------
!

! Output error message and stop
subroutine handle_error(localPet)
  integer :: localPet

  ! Report an error and stop
  if (localPet .eq. 0) then
    write(*,*) 
    write(*,*) "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    write(*,*) "!  ERROR: PLEASE CHECK LOG FILE     !"
    write(*,*) "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    write(*,*) 
  endif

  call ESMF_Finalize()
  stop

end subroutine handle_error

end program ESMF_BUMP_eval