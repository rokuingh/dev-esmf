program AttributeDuplicateNames

use ESMF

use netcdf

implicit none

integer :: rc
logical :: correct
integer :: localPet, petCount
type(ESMF_VM) :: vm
type(ESMF_ArraySpec) :: arrayspec
type(ESMF_Grid) :: grid
type(ESMF_Field) :: field
type(ESMF_AttPack) :: attpack, attpack_parent

! ATtribute test
character(len=ESMF_MAXSTR) :: outValue, outValChar
integer :: outValueInt
character(len=ESMF_MAXSTR) :: specList(2), attrList(2), convESMF, purpGen
integer :: num_packs, outval
logical :: isPresent1, isPresent2

! init success flag
correct=.true.

rc=ESMF_SUCCESS

! Initialize ESMF
call ESMF_Initialize (defaultCalKind=ESMF_CALKIND_GREGORIAN, &
defaultlogfilename="AttributeDuplicate.Log", &
logkindflag=ESMF_LOGKIND_SINGLE, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


! get pet info
call ESMF_VMGetGlobal(vm, rc=rc)
if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=rc)
if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)


! Grid create from file
call ESMF_ArraySpecSet(arrayspec, typekind=ESMF_TYPEKIND_R8, rank=2, rc=rc)
if (rc/=ESMF_SUCCESS) return
grid = ESMF_GridCreateNoPeriDim(minIndex=(/1,1/), maxIndex=(/100,150/), &
  regDecomp=(/1,petCount/), &
  gridEdgeLWidth=(/0,0/), gridEdgeUWidth=(/0,0/), &
  indexflag=ESMF_INDEX_GLOBAL, rc=rc)
if (rc/=ESMF_SUCCESS) return

field = ESMF_FieldCreate(grid, arrayspec=arrayspec, &
          staggerloc=ESMF_STAGGERLOC_CENTER, name="field", rc=rc)

convESMF = 'ESMF'
purpGen = 'General'


call ESMF_AttributeAdd(field, convention=convESMF, purpose=purpGen, &
  attpack=attpack_parent, rc=rc)
if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_AttributeAdd(field, "newConvention", "newPurpose", &
                       attrList=(/"att1","att2"/), &
                       nestConvention=convESMF, nestPurpose=purpGen, &
                       attpack=attpack, rc=rc)
if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_AttributeSet(field, "att1", "val1", attpack=attpack, rc=rc)
if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_AttributeRemove(field, attpack=attpack_parent, rc=rc)
if (ESMF_LogFoundError(rcToCheck=rc, msg=ESMF_LOGERR_PASSTHRU, &
line=__LINE__, file=__FILE__, rcToReturn=rc)) &
call ESMF_Finalize(endflag=ESMF_END_ABORT)


isPresent1 = .true.
isPresent2 = .false.
call ESMF_AttributeGetAttPack(field, "newConvention", "newPurpose", &
                              attpack=attpack, isPresent=isPresent1, rc=rc)
call ESMF_AttributeGetAttPack(field, convESMF, purpGen, &
                              attpack=attpack, isPresent=isPresent2, rc=rc)

print *, "PET", localPet, "isPresent1 = ", isPresent1, " and isPresent2 = ", isPresent2

! Free the grids
call ESMF_GridDestroy(grid, rc=rc)
if (rc /= ESMF_SUCCESS) return

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

call ESMF_Finalize()

end program AttributeDuplicateNames
