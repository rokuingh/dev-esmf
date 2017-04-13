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

  call test_smm(rc)

  call ESMF_Finalize()


contains

 subroutine test_smm(rc)
#undef ESMF_METHOD
#define ESMF_METHOD "test_smm"
  integer, intent(out)  :: rc
  logical :: correct
  integer :: localrc
  type(ESMF_Grid) :: srcGrid
  type(ESMF_Grid) :: dstGrid
  type(ESMF_Field) :: srcField
  type(ESMF_Field) :: dstField
  type(ESMF_Field) :: xdstField
  type(ESMF_RouteHandle) :: routeHandle
  type(ESMF_VM) :: vm
  real(ESMF_KIND_R8), pointer :: src(:,:), dst(:,:), xct(:,:)
  real(ESMF_KIND_R8) :: lon, lat, theta, phi
  integer :: localPet, petCount
  real(ESMF_KIND_R8), parameter ::  DEG2RAD = &
                3.141592653589793_ESMF_KIND_R8/180.0_ESMF_KIND_R8

  ! init success flag
  correct=.true.
  rc=ESMF_SUCCESS

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

#if 0
  ! Create Src Grid
  srcGrid=ESMF_GridCreate("data/ll2.5deg_grid.nc", ESMF_FILEFORMAT_SCRIP, &
                                  rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Create Dst Grid
  dstGrid=ESMF_MeshCreate("data/mpas_uniform_10242_dual_counterclockwise.nc", &
                          ESMF_FILEFORMAT_ESMFMESH, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
#endif

  srcGrid = ESMF_GridCreateNoPeriDim(maxIndex=(/4,4/), rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  dstGrid = ESMF_GridCreateNoPeriDim(maxIndex=(/4,4/), rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

  ! Create source/destination fields
   srcField = ESMF_FieldCreate(srcGrid, typekind=ESMF_TYPEKIND_R8, &
                               staggerloc=ESMF_STAGGERLOC_CENTER, &
                               name="source", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

   dstField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
                               staggerloc=ESMF_STAGGERLOC_CENTER, &
                               name="dest", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  xdstField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
                               staggerloc=ESMF_STAGGERLOC_CENTER, &
                               name="xdest", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  ! Get arrays
  ! dstArray
  call ESMF_FieldGet(dstField, farrayPtr=dst, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  dst(:,:) = 0.

  call ESMF_FieldGet(xdstField, farrayPtr=xct, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  xct(:,:) = 42.

  ! srcArray
  call ESMF_FieldGet(srcField, farrayPtr=src, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
  src(:,:) = 42.


#if 0
  call ESMF_GridWriteVTK(srcGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
       filename="srcGrid", rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE
#endif

  ! SMM store
  call ESMF_FieldSMMStore(srcField, dstField, "data/weights_generic.nc", routeHandle, &
                          rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

print *, src

#if 0
  ! Do regrid
  call ESMF_FieldRegrid(srcField, dstField, routeHandle, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE


  call ESMF_FieldRegridRelease(routeHandle, rc=localrc)
  if (localrc /= ESMF_SUCCESS) return ESMF_FAILURE

#endif

#if 0
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

 end subroutine test_smm

end program
