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

  call test_holegrid(rc)

  call ESMF_Finalize()


contains

 subroutine test_holegrid(rc)
#undef ESMF_METHOD
#define ESMF_METHOD "test_holegrid"
  integer, intent(out)  :: rc
  logical :: correct
  integer :: localrc
  type(ESMF_Mesh) :: srcGrid
  type(ESMF_Mesh) :: dstGrid
  type(ESMF_Field) :: srcField, dstField, xdstField
  type(ESMF_Array) :: srcA, dstA, errA
  type(ESMF_RouteHandle) :: routeHandle
  type(ESMF_VM) :: vm
  type(ESMF_DistGrid) :: distgrid
  real(ESMF_KIND_R8), pointer :: src(:), dst(:), xct(:), errP(:)
  real(ESMF_KIND_R8), allocatable, target :: err(:)
  integer :: localPet, petCount

  ! init success flag
  correct=.true.
  rc=ESMF_SUCCESS

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Create Src Grid
  srcGrid=ESMF_MeshCreate("data/split_src_14.nc", ESMF_FILEFORMAT_UGRID, &
                                  rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Create Dst Grid
  ! dstGrid=ESMF_GridCreate("data/split_dst_14.nc", ESMF_FILEFORMAT_SCRIP, &
  !                         isSphere=.false., addCornerStagger=.true., rc=localrc)
  dstGrid=ESMF_MeshCreate("data/split_dst_14.nc", ESMF_FILEFORMAT_SCRIP, &
                          rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

! print *, "PET", localPet, ": lbnd, ubnd", lbnd, ubnd
! print *, "PET", localPet, ": d_x", d_x

  ! Create source/destination fields
   srcField = ESMF_FieldCreate(srcGrid, typekind=ESMF_TYPEKIND_R8, &
                               meshloc=ESMF_MESHLOC_ELEMENT, &
                               name="source", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   dstField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
                               meshloc=ESMF_MESHLOC_ELEMENT, &
                               name="dest", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  xdstField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
                               meshloc=ESMF_MESHLOC_ELEMENT, &
                               name="xdest", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  ! Get arrays
  ! dstArray
  call ESMF_FieldGet(dstField, farrayPtr=dst, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  dst = 0.

  call ESMF_FieldGet(xdstField, farrayPtr=xct, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  xct = 42.

  ! srcArray
  call ESMF_FieldGet(srcField, farrayPtr=src, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  src = 42.

  ! Do regrid
  call ESMF_FieldRegridStore(srcField, dstField, routehandle=routeHandle, &
                             fileName="data/weights_holegrid.nc", &
                             regridMethod=ESMF_REGRIDMETHOD_CONSERVE, &
                             unmappedAction=ESMF_UNMAPPEDACTION_IGNORE, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_FieldRegrid(srcField, dstField, routehandle=routeHandle, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_FieldRegridRelease(routeHandle, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

#if 0
  call ESMF_FieldGet(srcField, array=srcA, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_GridWriteVTK(srcGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
       filename="srcGrid", array1=srcA, &
       rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_FieldGet(dstField, array=dstA, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_GridGet(dstGrid, distgrid=distgrid, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  allocate(err(m,m))
  err = xct - dst / xct
  errP => err
  errA = ESMF_ArrayCreate(distgrid, farrayPtr=errP, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_GridWriteVTK(dstGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
       filename="dstGrid", array1=dstA, array2=errA, &
       rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  deallocate(err)
#endif

  ! Destroy the Fields
   call ESMF_FieldDestroy(srcField, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   call ESMF_FieldDestroy(dstField, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   call ESMF_FieldDestroy(xdstField, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Free the grids
  call ESMF_MeshDestroy(srcGrid, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_MeshDestroy(dstGrid, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! return answer based on correct flag
  if (correct) then
    rc=ESMF_SUCCESS
  else
    rc=ESMF_FAILURE
  endif

 end subroutine test_holegrid

end program
