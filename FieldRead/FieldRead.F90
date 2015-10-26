
program FieldRead

use ESMF

use netcdf

implicit none

integer :: rc

rc = ESMF_SUCCESS


! Initialize ESMF
call ESMF_Initialize (defaultCalKind=ESMF_CALKIND_GREGORIAN, &
defaultlogfilename="FieldRead.Log", &
logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call test_fieldread(rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_Finalize()

contains

subroutine test_fieldread(rc)
integer, intent(out)  :: rc

logical :: correct
integer :: localrc
type(ESMF_Grid) :: grid
type(ESMF_Field) :: field
type(ESMF_ArraySpec) :: arrayspec
type(ESMF_VM) :: vm


integer :: localPet, petCount

! result code
integer :: finalrc

! init success flag
correct=.true.

rc=ESMF_SUCCESS

! get pet info
call ESMF_VMGetGlobal(vm, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)


! Grid create from file
grid = ESMF_GridCreate("source.nc", ESMF_FILEFORMAT_GRIDSPEC, &
                          regDecomp=[1,1], addCornerStagger=.true., rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! Create source/destination fields
call ESMF_ArraySpecSet(arrayspec, 3, ESMF_TYPEKIND_R8, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


field = ESMF_FieldCreate(grid, arrayspec, staggerloc=ESMF_STAGGERLOC_CENTER, &
ungriddedLBound=(/1/), ungriddedUBound=(/10/), gridToFieldMap=(/2, 3/), &
name="field", rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldRead(field, "source.nc", variableName="pr", timeslice=10, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldPrint(field)

#if 0
call ESMF_GridWriteVTK(grid, filename="so_Omon_GISS-E2.nc", rc=localrc)
if (localrc /= ESMF_SUCCESS) return
#endif

! Destroy the Fields
call ESMF_FieldDestroy(field, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! Free the grids
call ESMF_GridDestroy(grid, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

end subroutine test_fieldread

end program FieldRead
