program NetCDFIOAttribute

use ESMF

use netcdf

implicit none

integer :: rc
logical :: correct
integer :: localPet, petCount
type(ESMF_VM) :: vm
type(ESMF_Grid) :: grid
type(ESMF_Field) :: field
type(ESMF_FieldBundle) :: fieldbundle
character(len=ESMF_MAXSTR) :: attrList(6)

! init success flag
correct=.true.

rc=ESMF_SUCCESS

! Initialize ESMF
call ESMF_Initialize (defaultlogfilename="NetCDFIOAtrribute.Log", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


! get pet info
call ESMF_VMGetGlobal(vm, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_VMGet(vm, petCount=petCount, localPet=localPet, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


! ESMF object creation
grid = ESMF_GridCreateNoPeriDim(maxIndex=(/10,10/), rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

field = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

fieldbundle = ESMF_FieldBundleCreate(fieldlist=(/field/), rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


! ESMF Attributes for NetCDF file structure
attrList = (/"grid_xt", "grid_yt", "pfull  ", "time   ","       ","       "/)
call ESMF_AttributeAdd(grid, 'GFDL_IO', 'dimension', attrList(1:4), rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

attrList = (/"long_name    ", "units        ", "valid_range  ", "missing_value", "_FillValue   ", "cell_methods "/)
call ESMF_AttributeAdd(field, 'GFDL_IO', 'variable', attrList(1:6), rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_AttributeAdd(fieldbundle, 'GFDL_IO', 'global', (/"filename"/), rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


! Free memory
call ESMF_GridDestroy(grid, rc=rc)
if (rc /= ESMF_SUCCESS) return

call ESMF_FieldDestroy(field, rc=rc)
if (rc /= ESMF_SUCCESS) return

call ESMF_FieldBundleDestroy(fieldbundle, rc=rc)
if (rc /= ESMF_SUCCESS) return

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

call ESMF_Finalize()

end program NetCDFIOAttribute
