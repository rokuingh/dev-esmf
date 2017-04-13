program MoabMesh

use ESMF

use netcdf

implicit none

integer :: rc
integer :: localPet, petCount
type(ESMF_VM) :: vm
type(ESMF_Mesh) :: mesh

rc=ESMF_SUCCESS

! Initialize ESMF
call ESMF_Initialize (rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! get pet info
call ESMF_VMGetGlobal(vm, rc=rc)
call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_VMLogMemInfo('Before MeshCreate',rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

mesh = ESMF_MeshCreate("data/ne15np4_scrip.nc", ESMF_FILEFORMAT_SCRIP, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_VMLogMemInfo('After MeshCreate',rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! measure VmRSS and VmPeak
! procs from 1 up to 2^5
! ne15, a couple of the larger grids (esmf format ones)

call ESMF_Finalize()

end program MoabMesh
