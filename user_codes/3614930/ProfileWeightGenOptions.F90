
! This program is intended to compare time required to perform regridding using
! various methods.
!
! 1. weight generation in memory - ESMF_FieldRegridStore()
! 2. read weights from file - ESMF_SMMStore()
! 3. read routehandle from file - ESMF_RouteHandleCreate()


program profile_weightgenoptions

use ESMF

use netcdf

implicit none

integer :: rc

rc = ESMF_SUCCESS


! Initialize ESMF
call ESMF_Initialize (defaultlogfilename="ProfileWeightGenOptions.Log", &
                      logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! call profile_regridstore(rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! call profile_smmstore(rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call profile_routehandlecreate(rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_Finalize()

contains

subroutine profile_regridstore(rc)
integer, intent(out)  :: rc

logical :: correct
integer :: localrc
type(ESMF_Grid) :: srcgrid, dstgrid
type(ESMF_Field) :: srcfield, dstfield
type(ESMF_ArraySpec) :: arrayspec
type(ESMF_VM) :: vm
type(ESMF_RouteHandle) :: routehandle


integer :: localPet, petCount

! result code
integer :: finalrc

! init success flag
correct=.true.

rc=ESMF_SUCCESS

! get pet info
call ESMF_VMGetGlobal(vm, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Grid create from file
srcgrid = ESMF_GridCreate("ll1deg_grid.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Create source/destination fields
call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

srcfield = ESMF_FieldCreate(srcgrid, arrayspec, staggerloc=ESMF_STAGGERLOC_CENTER, &
    name="field", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return


dstgrid = ESMF_GridCreate("ll1deg_grid.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

dstfield = ESMF_FieldCreate(dstgrid, arrayspec, staggerloc=ESMF_STAGGERLOC_CENTER, &
    name="dstfield", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_TraceRegionEnter("ESMF_FieldRegridStore", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_FieldRegridStore(srcfield, dstfield, routehandle=routehandle, &
                           unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_TraceRegionExit("ESMF_FieldRegridStore", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Destroy the Fields
call ESMF_FieldDestroy(srcfield, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_FieldDestroy(dstfield, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Free the grids
call ESMF_GridDestroy(srcgrid, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_GridDestroy(dstgrid, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

print *, "finished profiling ESMF_RegridStore()"

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

end subroutine profile_regridstore

subroutine profile_smmstore(rc)
integer, intent(out)  :: rc

logical :: correct
integer :: localrc
type(ESMF_Grid) :: srcgrid, dstgrid
type(ESMF_Field) :: srcfield, dstfield
type(ESMF_ArraySpec) :: arrayspec
type(ESMF_VM) :: vm
type(ESMF_RouteHandle) :: routehandle


integer :: localPet, petCount

! result code
integer :: finalrc

! init success flag
correct=.true.

rc=ESMF_SUCCESS

! get pet info
call ESMF_VMGetGlobal(vm, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Grid create from file
srcgrid = ESMF_GridCreate("ll1deg_grid.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Create source/destination fields
call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

srcfield = ESMF_FieldCreate(srcgrid, arrayspec, staggerloc=ESMF_STAGGERLOC_CENTER, &
    name="field", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return


dstgrid = ESMF_GridCreate("ll1deg_grid.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

dstfield = ESMF_FieldCreate(dstgrid, arrayspec, staggerloc=ESMF_STAGGERLOC_CENTER, &
    name="dstfield", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_TraceRegionEnter("ESMF_FieldSMMStore", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_FieldSMMStore(srcfield, dstfield, filename="weightfile.nc", &
                           routehandle=routehandle, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_TraceRegionExit("ESMF_FieldSMMStore", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Destroy the Fields
call ESMF_FieldDestroy(srcfield, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_FieldDestroy(dstfield, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Free the grids
call ESMF_GridDestroy(srcgrid, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_GridDestroy(dstgrid, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

print *, "finished profiling ESMF_SMMStore()"

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

end subroutine profile_smmstore

subroutine profile_routehandlecreate(rc)
integer, intent(out)  :: rc

logical :: correct
integer :: localrc
type(ESMF_Grid) :: srcgrid, dstgrid
type(ESMF_Field) :: srcfield, dstfield
type(ESMF_ArraySpec) :: arrayspec
type(ESMF_VM) :: vm
type(ESMF_RouteHandle) :: routehandle, rh
integer :: i1, i2
integer :: clbnd(2),cubnd(2)
real(ESMF_KIND_R8), pointer :: farrayPtr(:,:)
real, parameter :: tol = 1e-6

integer :: localPet, petCount

! result code
integer :: finalrc

! init success flag
correct=.true.

rc=ESMF_SUCCESS

! get pet info
call ESMF_VMGetGlobal(vm, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Grid create from file
srcgrid = ESMF_GridCreate("ll1deg_grid.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Create source/destination fields
call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

srcfield = ESMF_FieldCreate(srcgrid, arrayspec, staggerloc=ESMF_STAGGERLOC_CENTER, &
    name="field", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return


dstgrid = ESMF_GridCreate("ll1deg_grid.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

dstfield = ESMF_FieldCreate(dstgrid, arrayspec, staggerloc=ESMF_STAGGERLOC_CENTER, &
    name="dstfield", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! call ESMF_FieldRegridStore(srcfield, dstfield, routehandle=routehandle, &
!                            unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, rc=localrc)
! if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
! line=__LINE__, file=__FILE__, rcToReturn=rc)) return
! 
! call ESMF_RouteHandleWrite(routehandle, filename="routehandle.dat", rc=localrc)
! if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
! line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_TraceRegionEnter("ESMF_RouteHandleCreate", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

rh = ESMF_RouteHandleCreate("routehandle_rwg.dat", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_TraceRegionExit("ESMF_RouteHandleCreate", rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! get src pointer
call ESMF_FieldGet(dstfield, 0, farrayPtr,  &
                   computationalLBound=clbnd, computationalUBound=cubnd, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

farrayPtr(:,:) = 42.0

call ESMF_FieldRegrid(srcfield, dstfield, rh, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! validate the data

!! set coords, interpolated function
do i1=clbnd(1),cubnd(1)
do i2=clbnd(2),cubnd(2)
    ! Init source value
    if (farrayPtr(i1,i2) - 42.0 > tol) localrc = ESMF_RC_VAL_WRONG
enddo
enddo

if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return


! Destroy the Fields
call ESMF_FieldDestroy(srcfield, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_FieldDestroy(dstfield, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

! Free the grids
call ESMF_GridDestroy(srcgrid, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

call ESMF_GridDestroy(dstgrid, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) return

print *, "finished profiling ESMF_RouteHandleCreate()"

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

end subroutine profile_routehandlecreate

end program profile_weightgenoptions
