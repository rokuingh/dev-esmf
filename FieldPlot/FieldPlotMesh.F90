
program Fieldplot

use ESMF

use netcdf

implicit none

integer :: rc

rc = ESMF_SUCCESS


! Initialize ESMF
call ESMF_Initialize (defaultCalKind=ESMF_CALKIND_GREGORIAN, &
defaultlogfilename="FieldPlot.Log", &
logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call test_regridDGSph(rc)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_Finalize()

contains

subroutine test_regridDGSph(rc)
integer, intent(out)  :: rc
logical :: correct
integer :: localrc
type(ESMF_Mesh) :: srcMesh
type(ESMF_Mesh) :: dstMesh
type(ESMF_Field) :: srcField
type(ESMF_Field) :: dstField
type(ESMF_Field) :: xdstField
type(ESMF_Field) :: errorField
type(ESMF_Array) :: dstArray
type(ESMF_Array) :: srcArray
type(ESMF_RouteHandle) :: routeHandle
type(ESMF_ArraySpec) :: arrayspec
type(ESMF_VM) :: vm
type(ESMF_DistGrid) :: srcDistgrid
real(ESMF_KIND_R8), allocatable :: srcCoords(:)
real(ESMF_KIND_R8), allocatable :: dstCoords(:)
real(ESMF_KIND_R8), pointer :: farrayPtr(:)
real(ESMF_KIND_R8), pointer :: xfarrayPtr(:)
real(ESMF_KIND_R8), pointer :: errorPtr(:)
integer :: fclbnd(1),fcubnd(1)
integer :: i, num_nodes, sd
character(len=ESMF_MAXSTR) :: string

real(ESMF_KIND_R8) :: lon, lat, theta, phi, DEG2RAD

integer :: localPet, petCount

type(ESMF_DistGridConnection) :: connectionList(3) ! 3 connections


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


! degree to rad conversion
DEG2RAD = 3.141592653589793_ESMF_KIND_R8/180.0_ESMF_KIND_R8

! Grid create from file
srcMesh = ESMF_MeshCreate("ne30np4-t2.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (localrc /= ESMF_SUCCESS) return
dstMesh = ESMF_MeshCreate("ar9v4_100920.nc", ESMF_FILEFORMAT_SCRIP, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! Create source/destination fields
call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


srcField = ESMF_FieldCreate(srcMesh, arrayspec, &
meshloc=ESMF_MESHLOC_ELEMENT, name="source", rc=localrc)
if (localrc /= ESMF_SUCCESS) return


dstField = ESMF_FieldCreate(dstMesh, arrayspec, &
meshloc=ESMF_MESHLOC_ELEMENT, name="dest", rc=localrc)
if (localrc /= ESMF_SUCCESS) return

xdstField = ESMF_FieldCreate(dstMesh, arrayspec, &
meshloc=ESMF_MESHLOC_ELEMENT, name="xdest", rc=localrc)
if (localrc /= ESMF_SUCCESS) return

errorField = ESMF_FieldCreate(dstMesh, arrayspec, &
meshloc=ESMF_MESHLOC_ELEMENT, name="error", rc=localrc)
if (localrc /= ESMF_SUCCESS) return

!! get coords
call ESMF_MeshGet(srcMesh, spatialDim=sd, numOwnedNodes=num_nodes, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

allocate (srcCoords(sd*num_nodes))
call ESMF_MeshGet(srcMesh, ownedNodeCoords=srcCoords, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! get src pointer
call ESMF_FieldGet(srcField, 0, farrayPtr, computationalLBound=fclbnd, &
computationalUBound=fcubnd,  rc=localrc)
if (localrc /=ESMF_SUCCESS) return

if (fcubnd(1)-fclbnd(1) /= sd*num_nodes) then
    print *, "ERROR",fcubnd(1)-fclbnd(1),sd*num_nodes
    rc = ESMF_FAILURE
    return
endif

!! set coords, interpolated function
do i=1,sd*num_nodes

! init exact answer
lon = srcCoords(i)
lat = srcCoords(i+1)

! Set the source to be a function of the x,y,z coordinate
theta = DEG2RAD*(lon)
phi = DEG2RAD*(90.-lat)

! set exact src data
farrayPtr(i) = 2. + cos(theta)**2.*cos(2.*phi)
enddo

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Destination grid
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!! get coords
call ESMF_MeshGet(dstMesh, spatialDim=sd, numOwnedNodes=num_nodes, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

allocate (dstCoords(sd*num_nodes))
call ESMF_MeshGet(dstMesh, ownedNodeCoords=dstCoords, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldGet(dstField, 0, farrayPtr, computationalLBound=fclbnd, &
computationalUBound=fcubnd,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldGet(xdstField, 0, xfarrayPtr,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return

if (fcubnd(1)-fclbnd(1) /= sd*num_nodes) then
print *, "ERROR",fcubnd(1)-fclbnd(1),sd*num_nodes
rc = ESMF_FAILURE
return
endif

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

!!! Regrid forward from the A grid to the B grid
! Regrid store
call ESMF_FieldRegridStore( &
srcField, &
dstField=dstField, &
unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, &
routeHandle=routeHandle, &
regridmethod=ESMF_REGRIDMETHOD_CONSERVE, &
rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! Do regrid
call ESMF_FieldRegrid(srcField, dstField, routeHandle, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldRegridRelease(routeHandle, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


! validate
call ESMF_FieldGet(dstField, 0, farrayPtr, computationalLBound=fclbnd, &
computationalUBound=fcubnd,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldGet(errorField, 0, errorPtr,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return


!! make sure we're not using any bad points
do i=fclbnd(1),fcubnd(1)
! if working everything should be really close to 20.0
if (xfarrayPtr(i) /= 0) then
    errorPtr(i) = abs(farrayPtr(i)-xfarrayPtr(i))/xfarrayPtr(i)
endif
if (abs(farrayPtr(i)-xfarrayPtr(i)) .gt. 0.001) then
    correct=.false.
endif
enddo

! Get arrays
! dstArray
call ESMF_FieldGet(errorField, array=dstArray, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


! srcArray
call ESMF_FieldGet(srcField, array=srcArray, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

#if 1
call ESMF_MeshIO(vm, srcMesh, ESMF_STAGGERLOC_CENTER, &
"srcMesh", srcArray, rc=localrc, &
spherical=1)
call ESMF_MeshIO(vm, dstMesh, ESMF_STAGGERLOC_CENTER, &
"dstMesh", dstArray, rc=localrc, &
spherical=0)
#endif


! Destroy the Fields
call ESMF_FieldDestroy(srcField, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldDestroy(dstField, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

deallocate(srcCoords)
deallocate(dstCoords)

! Free the grids
call ESMF_MeshDestroy(srcMesh, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_MeshDestroy(dstMesh, rc=localrc)
if (localrc /=ESMF_SUCCESS) return

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

end subroutine test_regridDGSph

end program Fieldplot
