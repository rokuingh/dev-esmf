program AttributeDuplicateNames

use ESMF

use netcdf

implicit none

integer :: rc
logical :: correct
integer :: localPet, petCount
type(ESMF_VM) :: vm
type(ESMF_Grid) :: grid

! ATtribute test
character(len=ESMF_MAXSTR) :: outValue, outValChar
integer :: outValueInt
character(len=ESMF_MAXSTR) :: specList(2), attrList(2)
integer :: num_packs, outval

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
grid = ESMF_GridCreateNoPeriDim(maxIndex=(/10,10/), rc=rc)

! Attributes
call ESMF_AttributeSet(grid, name="srcFieldAttribute", value=4, rc=rc)
outValue = ""
outValueInt = 0
if (localPet == 2) then
	call ESMF_AttributeSet(grid, name="srcFieldAttribute", value="changeToChar", rc=rc)
	call ESMF_AttributeGet(grid, name="srcFieldAttribute", value=outValue, rc=rc)
endif
call ESMF_AttributeGet(grid, name="srcFieldAttribute", value=outValueInt, rc=rc)	
print *, "PET: ", localpet, "Attribute doubly set returns : ", outValueInt, outValue

specList = (/"Spec1", "Spec2"/)
attrList = (/"Attr1", "Attr2"/)

call ESMF_AttributeAdd(grid, specList, attrList, rc=rc)
call ESMF_AttributeAdd(grid, specList, attrList, rc=rc)


call ESMF_AttributeGet(grid, num_packs, attcountflag=ESMF_ATTGETCOUNT_ATTPACK, rc=rc)
if (num_packs /= 2) then
	print *, "Num packs should be 2: ", num_packs
endif
	print *, "Num packs should be 2: ", num_packs


! set the Attpack Attribute
call ESMF_AttributeSet(grid, "Attr1", 42, &
	                   convention="Spec1", purpose="Spec2", rc=rc)

outval = 0
call ESMF_AttributeGet(grid, "Attr1", outval, &
	                   convention="Spec1", purpose="Spec2", rc=rc)
print *, outval


! reset the Attpack Attribute
call ESMF_AttributeSet(grid, "Attr1", "DING", &
	                   convention="Spec1", purpose="Spec2", rc=rc)

outval = 0
call ESMF_AttributeGet(grid, "Attr1", outvalChar, &
	                   convention="Spec1", purpose="Spec2", rc=rc)
print *, outvalChar

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
