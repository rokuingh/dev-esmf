! Earth System Modeling Framework
! Copyright 2002-2016, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.

program esmf_application

  ! modules
  use ESMF
  
  implicit none
  
  ! local variables
  integer:: rc
  
  call ESMF_Initialize(rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  !call test_bilinear_regrid_csgrid(rc)
  call test_csgrid_print(rc)

  call ESMF_Finalize()


contains

 subroutine test_csgrid_print(rc)
#undef ESMF_METHOD
#define ESMF_METHOD "test_csgrid_print"
  integer, intent(out)  :: rc
  type(ESMF_Grid) :: grid
  type(ESMF_VM) :: vm
  integer :: localpet, petCount, localrc

  real(ESMF_KIND_R8), pointer :: coords1(:,:), coords2(:,:)

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Establish the resolution of the grids

  ! Create grid
  grid=ESMF_GridCreateCubedSphere(tileSize=6, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! get

  call ESMF_GridGetCoord(grid, 1, localDE=0, farrayPtr=coords1, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  call ESMF_GridGetCoord(grid, 2, localDE=0, farrayPtr=coords2, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  print *, localpet, 1, coords1
  print *, localpet, 2, coords2

  ! return answer based on correct flag
  rc=ESMF_SUCCESS

 end subroutine test_csgrid_print


 subroutine test_bilinear_regrid_csgrid(rc)
#undef ESMF_METHOD
#define ESMF_METHOD "test_bilinear_regrid_csgrid"
  integer, intent(out)  :: rc
  logical :: correct
  integer :: localrc
  type(ESMF_Grid) :: srcGrid
  type(ESMF_Grid) :: dstGrid
  type(ESMF_Field) :: srcField
  type(ESMF_Field) :: dstField
  type(ESMF_Field) :: xdstField
  type(ESMF_Field) :: errField
  type(ESMF_Array) :: dstArray
  type(ESMF_Array) :: errArray
  type(ESMF_Array) :: srcArray
  type(ESMF_RouteHandle) :: routeHandle
  type(ESMF_VM) :: vm
  real(ESMF_KIND_R8), pointer :: farrayPtrXC(:,:)
  real(ESMF_KIND_R8), pointer :: farrayPtrYC(:,:)
  real(ESMF_KIND_R8), pointer :: farrayPtr(:,:), farrayPtr2(:,:)
  real(ESMF_KIND_R8), pointer :: xfarrayPtr(:,:)
  real(ESMF_KIND_R8), pointer :: errfarrayPtr(:,:)
  integer :: clbnd(2),cubnd(2)
  integer :: fclbnd(2),fcubnd(2)
  integer :: i1,i2,i3, index(2)
  integer :: lDE, srclocalDECount, dstlocalDECount
  real(ESMF_KIND_R8) :: coord(2),x,y,z
  character(len=ESMF_MAXSTR) :: string
  integer src_tile_size, dst_nx, dst_ny
  real(ESMF_KIND_R8) :: lon, lat, theta, phi, relErr
  real(ESMF_KIND_R8) :: coords(2), maxRelErr
  integer :: localPet, petCount
  real(ESMF_KIND_R8), parameter ::  DEG2RAD = &
                3.141592653589793_ESMF_KIND_R8/180.0_ESMF_KIND_R8
  integer :: decomptile(2,6)

  ! init success flag
  correct=.true.
  rc=ESMF_SUCCESS

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Establish the resolution of the grids

  ! Create Src Grid
  srcGrid=ESMF_GridCreateCubedSphere(tileSize=20, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Create Dst Grid
  dstGrid=ESMF_GridCreate("ll1deg_grid.nc", ESMF_FILEFORMAT_SCRIP, &
                                  rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Create source/destination fields
   srcField = ESMF_FieldCreate(srcGrid, typekind=ESMF_TYPEKIND_R8, &
                         staggerloc=ESMF_STAGGERLOC_CENTER, name="source", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   dstField = ESMF_FieldCreate(dstGrid, typekind=ESMF_TYPEKIND_R8, &
                         staggerloc=ESMF_STAGGERLOC_CENTER, name="dest", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  xdstField = ESMF_FieldCreate(dstGrid, typekind=ESMF_TYPEKIND_R8, &
                         staggerloc=ESMF_STAGGERLOC_CENTER, name="xdest", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  errField = ESMF_FieldCreate(dstGrid, typekind=ESMF_TYPEKIND_R8, &
                         staggerloc=ESMF_STAGGERLOC_CENTER, name="xdest", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Get arrays
  ! dstArray
  call ESMF_FieldGet(dstField, array=dstArray, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_FieldGet(errField, array=errArray, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! srcArray
  call ESMF_FieldGet(srcField, array=srcArray, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Get number of local DEs
  call ESMF_GridGet(srcGrid, localDECount=srclocalDECount, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Get number of local DEs
  call ESMF_GridGet(dstGrid, localDECount=dstlocalDECount, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Construct Src Grid
  ! (Get memory and set coords for src)
  do lDE=0,srclocalDECount-1

     ! get src pointer
     call ESMF_FieldGet(srcField, lDE, farrayPtr, &
          computationalLBound=clbnd, computationalUBound=cubnd, rc=localrc)
     if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE



     !! set coords, interpolated function
     do i1=clbnd(1),cubnd(1)
     do i2=clbnd(2),cubnd(2)

        ! Get coords
        call ESMF_GridGetCoord(srcGrid, staggerloc=ESMF_STAGGERLOC_CENTER, &
             localDE=lDE, index=(/i1,i2/), coord=coords, rc=localrc)
        if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


        ! init exact answer
        lon = coords(1)
        lat = coords(2)

       ! Set the source to be a function of the x,y,z coordinate
        theta = DEG2RAD*(lon)
        phi = DEG2RAD*(90.-lat)

        x = cos(theta)*sin(phi)
        y = sin(theta)*sin(phi)
        z = cos(phi)

        ! set src data
        farrayPtr(i1,i2) = x+y+z+15.0
        !farrayPtr(i1,i2) = 15.0+theta+phi

        ! This one seems to do a weird thing around the pole with a cubed sphere
        ! farrayPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)
     enddo
     enddo

  enddo    ! lDE


  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  ! Destination grid
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  ! Get memory and set coords for dst
  do lDE=0,dstlocalDECount-1

     ! get dst pointer
     call ESMF_FieldGet(dstField, lDE, farrayPtr, &
          computationalLBound=clbnd, computationalUBound=cubnd, rc=localrc)
    if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


     ! Get exact dst pointer
     call ESMF_FieldGet(xdstField, lDE, xfarrayPtr,  rc=localrc)
    if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


     !! dst data
     do i1=clbnd(1),cubnd(1)
     do i2=clbnd(2),cubnd(2)

        ! Get coords
        call ESMF_GridGetCoord(dstGrid, staggerloc=ESMF_STAGGERLOC_CENTER, &
             localDE=lDE, index=(/i1,i2/), coord=coords, rc=localrc)
        if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


        ! init exact answer
        lon = coords(1)
        lat = coords(2)

       ! Set the source to be a function of the x,y,z coordinate
        theta = DEG2RAD*(lon)
        phi = DEG2RAD*(90.-lat)
        x = cos(theta)*sin(phi)
        y = sin(theta)*sin(phi)
        z = cos(phi)

        ! farrayPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)
        ! set exact dst data
        xfarrayPtr(i1,i2) = x+y+z+15.0
        !xfarrayPtr(i1,i2) = 15.0+theta+phi

        ! This one seems to do a weird thing around the pole with a cubed sphere
        !xfarrayPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)

        ! initialize destination field
        farrayPtr(i1,i2)=0.0
     enddo
     enddo

  enddo    ! lDE

#if 0
  call ESMF_GridWriteVTK(srcGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
       filename="srcGrid", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


#endif

  !!! Regrid forward from the A grid to the B grid
  ! Regrid store
  call ESMF_FieldRegridStore( &
          srcField, &
          dstField=dstField, &
          routeHandle=routeHandle, &
          unmappedAction=ESMF_UNMAPPEDACTION_ERROR, &
          regridmethod=ESMF_REGRIDMETHOD_BILINEAR, &
          rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Do regrid
  call ESMF_FieldRegrid(srcField, dstField, routeHandle, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  call ESMF_FieldRegridRelease(routeHandle, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE



  ! Check results
  maxRelErr=0.0
  do lDE=0,dstlocalDECount-1

    call ESMF_FieldGet(dstField, lDE, farrayPtr, computationalLBound=clbnd, &
          computationalUBound=cubnd,  rc=localrc)
    if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


    call ESMF_FieldGet(xdstField, lDE, xfarrayPtr,  rc=localrc)
    if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


    call ESMF_FieldGet(errField, lDE, errfarrayPtr,  rc=localrc)
    if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


     !! make sure we're not using any bad points
     do i1=clbnd(1),cubnd(1)
     do i2=clbnd(2),cubnd(2)

        ! Compute relative error
        if (xfarrayPtr(i1,i2) .ne. 0.0) then
           relErr=abs((farrayPtr(i1,i2)-xfarrayPtr(i1,i2))/xfarrayPtr(i1,i2))
        else
           relErr=abs(farrayPtr(i1,i2)-xfarrayPtr(i1,i2))
        endif

        ! if working everything should be close to exact answer
        if (relErr .gt. 0.001) then
            correct=.false.
            !write(*,*) "relErr=",relErr,farrayPtr(i1,i2),xfarrayPtr(i1,i2)
        endif

        ! Calc max
        if (relErr > maxRelErr) then
           maxRelErr=relErr
        endif

        ! put in error field
        errfarrayPtr(i1,i2)=relErr

     enddo
     enddo
  enddo    ! lDE

  ! output maxRelErr
  write(*,*) "maxRelErr=",maxRelErr

#if 1
  call ESMF_GridWriteVTK(srcGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
       filename="srcGrid", array1=srcArray, &
       rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_GridWriteVTK(dstGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
       filename="dstGrid", array1=dstArray, array2=errArray, &
       rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

#endif

  ! Destroy the Fields
   call ESMF_FieldDestroy(srcField, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   call ESMF_FieldDestroy(dstField, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   call ESMF_FieldDestroy(xdstField, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   call ESMF_FieldDestroy(errField, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Free the grids
  call ESMF_GridDestroy(srcGrid, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_GridDestroy(dstGrid, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  ! return answer based on correct flag
  if (correct) then
    rc=ESMF_SUCCESS
  else
    rc=ESMF_FAILURE
  endif

 end subroutine test_bilinear_regrid_csgrid

end program
