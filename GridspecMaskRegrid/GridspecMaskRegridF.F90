program GridspecMaskRegrid

use ESMF

use netcdf

implicit none

integer :: rc
logical :: correct
integer :: localPet, petCount
type(ESMF_VM) :: vm
type(ESMF_Grid) :: srcGrid, dstGrid
type(ESMF_Field) :: srcField, dstField, exactField, errorField, &
	                srcareaField, srcfracField, dstareaField, dstfracField
type(ESMF_RouteHandle) :: routeHandle
real(ESMF_KIND_R8), pointer :: PtrXC(:,:), PtrYC(:,:), &
							   srcPtr(:,:), exactPtr(:,:), &
                               dstPtr(:,:), errorPtr(:,:), &
                               srcareaPtr(:,:), srcfracPtr(:,:), &
                               dstareaPtr(:,:), dstfracPtr(:,:)
integer :: clbnd(2), cubnd(2), flbnd(2), fubnd(2)
integer :: i1,i2
integer :: lDE, localDECount
real(ESMF_KIND_R8) :: lon, lat, theta, phi, DEG2RAD
real(ESMF_KIND_R8) :: srcmass, dstmass, globalMass(2)
integer(ESMF_KIND_I4) :: maskvals(1)
character(ESMF_MaxPathLen) :: srcGridFile, dstGridFile

! init success flag
correct=.true.

rc=ESMF_SUCCESS

! Initialize ESMF
call ESMF_Initialize (defaultCalKind=ESMF_CALKIND_GREGORIAN, &
defaultlogfilename="FieldPlot.Log", &
logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! get pet info
call ESMF_VMGetGlobal(vm, rc=rc)
call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! degree to rad conversion
DEG2RAD = 3.141592653589793_ESMF_KIND_R8/180.0_ESMF_KIND_R8

srcGridFile = "data/GRIDSPEC_ACCESS1.nc"
dstGridFile = "data/SCRIP_1x1.nc"

! Grid create from file
srcGrid = ESMF_GridCreate(trim(srcGridFile), &
						  ESMF_FILEFORMAT_GRIDSPEC, &
						  (/1,petCount/), &
						  addCornerStagger=.true., &
						  addUserArea=.true., &
						  addMask=.true., varname="so", rc=rc)
dstGrid = ESMF_GridCreate(trim(dstGridFile), &
						  ESMF_FILEFORMAT_SCRIP, &
						  (/1,petCount/), &
						  addCornerStagger=.true., rc=rc)

if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! Create source/destination fields
srcField = ESMF_FieldCreate(srcGrid, ESMF_TYPEKIND_R8, &
	staggerloc=ESMF_STAGGERLOC_CENTER, name="source", rc=rc)
srcareaField = ESMF_FieldCreate(srcGrid, ESMF_TYPEKIND_R8, &
	staggerloc=ESMF_STAGGERLOC_CENTER, name="source areas", rc=rc)
srcfracField = ESMF_FieldCreate(srcGrid, ESMF_TYPEKIND_R8, &
	staggerloc=ESMF_STAGGERLOC_CENTER, name="source fracs", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

dstField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
	staggerloc=ESMF_STAGGERLOC_CENTER, name="dest", rc=rc)
dstareaField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
	staggerloc=ESMF_STAGGERLOC_CENTER, name="dest areas", rc=rc)
dstfracField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
	staggerloc=ESMF_STAGGERLOC_CENTER, name="dest fracs", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

exactField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
staggerloc=ESMF_STAGGERLOC_CENTER, name="exact", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

errorField = ESMF_FieldCreate(dstGrid, ESMF_TYPEKIND_R8, &
staggerloc=ESMF_STAGGERLOC_CENTER, name="error", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! Get number of local DEs
call ESMF_GridGet(srcGrid, localDECount=localDECount, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! Construct source Field analytic values
do lDE=0,localDECount-1

	call ESMF_GridGetCoord(srcGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=1, &
		computationalLBound=clbnd, computationalUBound=cubnd, FarrayPtr=PtrXC, rc=rc)
	call ESMF_GridGetCoord(srcGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=2, &
		computationalLBound=clbnd, computationalUBound=cubnd, FarrayPtr=PtrYC, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
		
	! get src pointer
	call ESMF_FieldGet(srcField, lDE, srcPtr, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	! set field
	do i1=clbnd(1),cubnd(1)
		do i2=clbnd(2),cubnd(2)
			lon = PtrXC(i1,i2)
			lat = PtrYC(i1,i2)
			theta = DEG2RAD*(lon)
			phi = DEG2RAD*(90.-lat)
			
			srcPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)
		enddo
	enddo

enddo    ! lDE

! Construct source Field analytic values
do lDE=0,localDECount-1

	call ESMF_GridGetCoord(dstGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=1, &
	computationalLBound=clbnd, computationalUBound=cubnd, FarrayPtr=PtrXC, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	call ESMF_GridGetCoord(dstGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=2, &
	computationalLBound=clbnd, computationalUBound=cubnd, FarrayPtr=PtrYC, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	! get dst pointer
	call ESMF_FieldGet(exactField, lDE, dstPtr, rc=rc)
	call ESMF_FieldGet(exactField, lDE, exactPtr, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	! set field
	do i1=clbnd(1),cubnd(1)
		do i2=clbnd(2),cubnd(2)
			lon = PtrXC(i1,i2)
			lat = PtrYC(i1,i2)
			theta = DEG2RAD*(lon)
			phi = DEG2RAD*(90.-lat)
			
			exactPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)
			dstPtr(i1,i2) = 0
		enddo
	enddo

enddo    ! lDE

! Regridding
maskvals(1) = 0
call ESMF_FieldRegridStore(srcField, dstField=dstField, &
                           srcMaskValues=maskvals, &
                           dstMaskValues=maskvals, &
                           regridmethod=ESMF_REGRIDMETHOD_CONSERVE, &
                           unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, &
                           routeHandle=routeHandle, &
                           srcFracField=srcfracField, &
                           dstFracField=dstfracField, &
                           rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_FieldRegrid(srcField, dstField, routeHandle, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_FieldRegridRelease(routeHandle, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


!get area
call ESMF_FieldRegridGetArea(srcareaField, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
call ESMF_FieldRegridGetArea(dstareaField, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! check results

srcmass = 0
dstmass = 0
do lDE=0,localDECount-1

	! get src pointers
	call ESMF_FieldGet(srcField, lDE, srcPtr, &
		computationalLBound=flbnd, computationalUBound=fubnd, rc=rc)
	call ESMF_FieldGet(srcfracField, lDE, srcfracPtr, rc=rc)
	call ESMF_FieldGet(srcareaField, lDE, srcareaPtr, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	do i1=flbnd(1),fubnd(1)
		do i2=flbnd(2),fubnd(2)
			srcmass = srcmass + srcPtr(i1,i2)*srcfracPtr(i1,i2)*srcareaPtr(i1,i2)
		enddo
	enddo

	! get dst pointers
	call ESMF_FieldGet(dstField, lDE, dstPtr, &
		computationalLBound=flbnd, computationalUBound=fubnd, rc=rc)
	call ESMF_FieldGet(exactField, lDE, exactPtr, rc=rc)
	call ESMF_FieldGet(errorField, lDE, errorPtr, rc=rc)
	call ESMF_FieldGet(dstfracField, lDE, dstfracPtr, rc=rc)
	call ESMF_FieldGet(dstareaField, lDE, dstareaPtr, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

	do i1=flbnd(1),fubnd(1)
		do i2=flbnd(2),fubnd(2)
			dstmass = dstmass + dstPtr(i1,i2)*dstfracPtr(i1,i2)*dstareaPtr(i1,i2)
			errorPtr(i1,i2) = dstPtr(i1,i2) - exactPtr(i1,i2)
		enddo
	enddo

enddo    ! lDE


call ESMF_VMReduce(vm, (/srcmass, dstmass/), globalMass, &
				   count=2, reduceflag=ESMF_REDUCE_SUM, rootPet=0, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

if (localPet == 0) then
	print *, "srcmass = ", globalMass(1)
	print *, "dstmass = ", globalMass(2)
endif

! Clean up
call ESMF_FieldDestroy(srcField, rc=rc)
call ESMF_FieldDestroy(srcareaField, rc=rc)
call ESMF_FieldDestroy(srcfracField, rc=rc)
call ESMF_FieldDestroy(dstField, rc=rc)
call ESMF_FieldDestroy(dstareaField, rc=rc)
call ESMF_FieldDestroy(dstfracField, rc=rc)
call ESMF_FieldDestroy(exactField, rc=rc)
call ESMF_FieldDestroy(errorField, rc=rc)
call ESMF_GridDestroy(srcGrid, rc=rc)
call ESMF_GridDestroy(dstGrid, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! return answer based on correct flag
if (correct) then
	rc=ESMF_SUCCESS
else
	rc=ESMF_FAILURE
endif

call ESMF_Finalize()

end program GridspecMaskRegrid
