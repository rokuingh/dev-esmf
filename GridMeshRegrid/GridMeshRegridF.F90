program GridMeshRegrid

use ESMF

use netcdf

implicit none

integer :: rc
logical :: correct
integer :: localPet, petCount
type(ESMF_VM) :: vm
type(ESMF_Grid) :: srcGrid
type(ESMF_Mesh) :: dstMesh
type(ESMF_Field) :: srcField
type(ESMF_Field) :: dstField
type(ESMF_Field) :: xdstField
type(ESMF_Field) :: errorField
type(ESMF_Array) :: dstArray
type(ESMF_Array) :: srcArray
type(ESMF_RouteHandle) :: routeHandle
type(ESMF_ArraySpec) :: arrayspec
real(ESMF_KIND_R8), pointer :: farrayPtrXC(:,:), farrayPtrYC(:,:), srcFarrayPtr(:,:)
real(ESMF_KIND_R8), pointer :: farrayPtr(:), xfarrayPtr(:), errorPtr(:)
integer :: clbnd(2),cubnd(2)
integer :: i1,i2
integer :: lDE, localDECount
real(ESMF_KIND_R8) :: lon, lat, theta, phi, DEG2RAD

real(ESMF_KIND_R8), allocatable :: dstCoords(:)
integer :: i, num_nodes, sd

integer(ESMF_KIND_I4), pointer :: factorIndexList(:,:)
real(ESMF_KIND_R8), pointer :: factorList(:)

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

! Grid create from file
srcGrid = ESMF_GridCreate("data/T42_grid.nc", ESMF_FILEFORMAT_SCRIP, &
						  (/1,petCount/), addCornerStagger=.true., rc=rc)
dstMesh = ESMF_MeshCreate("data/ne15np4_scrip.nc", ESMF_FILEFORMAT_SCRIP, rc=rc)

if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! Create source/destination fields
srcField = ESMF_FieldCreate(srcGrid, ESMF_TYPEKIND_R8, &
staggerloc=ESMF_STAGGERLOC_CENTER, name="source", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

dstField = ESMF_FieldCreate(dstMesh, ESMF_TYPEKIND_R8, &
meshloc=ESMF_MESHLOC_ELEMENT, name="dest", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

#if 0
xdstField = ESMF_FieldCreate(dstMesh, ESMF_TYPEKIND_R8, &
meshloc=ESMF_MESHLOC_ELEMENT, name="dest", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

errorField = ESMF_FieldCreate(dstMesh, ESMF_TYPEKIND_R8, &
meshloc=ESMF_MESHLOC_ELEMENT, name="dest", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
#endif

! Get number of local DEs
call ESMF_GridGet(srcGrid, localDECount=localDECount, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! Construct Src Grid
! (Get memory and set coords for src)
do lDE=0,localDECount-1

	!! get coord 1
	call ESMF_GridGetCoord(srcGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=1, &
	computationalLBound=clbnd, computationalUBound=cubnd, farrayPtr=farrayPtrXC, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	call ESMF_GridGetCoord(srcGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=2, &
	computationalLBound=clbnd, computationalUBound=cubnd, farrayPtr=farrayPtrYC, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	! get src pointer
	call ESMF_FieldGet(srcField, lDE, srcFarrayPtr, rc=rc)
    if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
	
	!! set coords, interpolated function
	do i1=clbnd(1),cubnd(1)
		do i2=clbnd(2),cubnd(2)
			! init exact answer
			lon = farrayPtrXC(i1,i2)
			lat = farrayPtrYC(i1,i2)
			
			! Set the source to be a function of the x,y,z coordinate
			theta = DEG2RAD*(lon)
			phi = DEG2RAD*(90.-lat)
			
			! set exact src data
			srcFarrayPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)
		enddo
	enddo

enddo    ! lDE

#if 0
! *********************  THIS IS NODE, SHOULD BE ELEMENT *******************
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! Destination grid
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!! get coords
call ESMF_MeshGet(dstMesh, spatialDim=sd, numOwnedNodes=num_nodes, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

allocate (dstCoords(sd*num_nodes))
call ESMF_MeshGet(dstMesh, ownedNodeCoords=dstCoords, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_FieldGet(dstField, 0, farrayPtr, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_FieldGet(xdstField, 0, xfarrayPtr,  rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

!! set coords, interpolated function
do i=1,sd*num_nodes

	! init exact answer
	lon = dstCoords(i)
	lat = dstCoords(i+1)
	
	! Set the source to be a function of the x,y,z coordinate
	theta = DEG2RAD*(lon)
	phi = DEG2RAD*(90.-lat)
	
	! set exact dst data
	xfarrayPtr(i) = 2. + cos(theta)**2.*cos(2.*phi)
	
	! initialize destination field
	farrayPtr(i)=0.0

enddo
#endif

call ESMF_FieldPrint(dstField)

!!! Regrid forward from the A grid to the B grid
! Regrid store
call ESMF_FieldRegridStore( &
srcField, &
dstField=dstField, &
unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, &
routeHandle=routeHandle, &
!factorList=factorList, &
!factorIndexList=factorIndexList, &
regridmethod=ESMF_REGRIDMETHOD_CONSERVE, &
rc=rc)

call ESMF_FieldPrint(dstField)

!call ESMF_FieldRegrid(srcField, dstField, routeHandle, rc=rc)


call ESMF_FieldRegridRelease(routeHandle, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

#if 0
! *********************  THIS IS NODE, SHOULD BE ELEMENT *******************
! check results
call ESMF_FieldGet(dstField, lDE, farrayPtr, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_FieldGet(errorField, lDE, errorPtr, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

!! make sure we're not using any bad points
do i=1,sd*num_nodes
	! if working everything should be really close to 20.0
	if (xfarrayPtr(i) /= 0) then
	    errorPtr(i) = abs(farrayPtr(i)-xfarrayPtr(i))/xfarrayPtr(i)
	endif
	if (abs(farrayPtr(i)-xfarrayPtr(i)) .gt. 0.001) then
	    correct=.false.
	endif
enddo

! Get arrays
! srcArray
call ESMF_FieldGet(srcField, array=srcArray, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! dstArray
call ESMF_FieldGet(dstField, array=dstArray, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

deallocate(dstCoords)
#endif


! Clean up
call ESMF_FieldDestroy(srcField, rc=rc)
call ESMF_FieldDestroy(dstField, rc=rc)
call ESMF_GridDestroy(srcGrid, rc=rc)
call ESMF_MeshDestroy(dstMesh, rc=rc)

! return answer based on correct flag
if (correct) then
	rc=ESMF_SUCCESS
else
	rc=ESMF_FAILURE
endif

call ESMF_Finalize()

end program GridMeshRegrid
