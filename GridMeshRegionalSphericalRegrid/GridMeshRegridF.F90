program GridMeshRegrid

use ESMF

use netcdf

implicit none

integer :: rc
integer :: localPet, petCount
type(ESMF_VM) :: vm
type(ESMF_Grid) :: grid
type(ESMF_Mesh) :: mesh
type(ESMF_Field) :: srcField
type(ESMF_Field) :: dstField
type(ESMF_RouteHandle) :: routeHandle
real(ESMF_KIND_R8), pointer :: farrayPtrXC(:,:), farrayPtrYC(:,:), &
                               farrayPtrXO(:,:), farrayPtrYO(:,:), &
                               srcFarrayPtr(:,:)
real(ESMF_KIND_R8), pointer :: dstFarrayPtr(:)
integer :: clbnd(2),cubnd(2)
integer :: i1,i2
real(ESMF_KIND_R8) :: dx, dy, pi

integer, pointer :: nodeIds(:),nodeOwners(:)
real(ESMF_KIND_R8), pointer :: nodeCoords(:)
integer, pointer :: elemIds(:),elemTypes(:),elemConn(:)

rc=ESMF_SUCCESS

! Initialize ESMF
call ESMF_Initialize (defaultCalKind=ESMF_CALKIND_GREGORIAN, &
defaultlogfilename="GridMeshRegionalSpherical.Log", &
logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! get pet info
call ESMF_VMGetGlobal(vm, rc=rc)
call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

pi = 3.14159

! Grid create from file
grid = ESMF_GridCreateNoPeriDim(maxIndex = (/2, 2/), &
    coordSys=ESMF_COORDSYS_SPH_DEG, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_GridAddCoord(grid, staggerloc=ESMF_STAGGERLOC_CENTER, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_GridGetCoord(grid, staggerLoc=ESMF_STAGGERLOC_CENTER, &
    coordDim=1, computationalLBound=clbnd, computationalUBound=cubnd, &
    farrayPtr=farrayPtrXC, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_GridGetCoord(grid, staggerLoc=ESMF_STAGGERLOC_CENTER, &
    coordDim=2, computationalLBound=clbnd, computationalUBound=cubnd, &
    farrayPtr=farrayPtrYC, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

dx = pi/4
dy = pi/4
do i1=clbnd(1),cubnd(1)
do i2=clbnd(2),cubnd(2)
   farrayPtrXC(i1,i2) = pi/8 + dx*(i2-1)
   farrayPtrYC(i1,i2) = pi/8 + dy*(i1-1)
enddo
enddo

call ESMF_GridAddCoord(grid, staggerloc=ESMF_STAGGERLOC_CORNER, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_GridGetCoord(grid, staggerLoc=ESMF_STAGGERLOC_CORNER, &
    coordDim=1, computationalLBound=clbnd, computationalUBound=cubnd, &
    farrayPtr=farrayPtrXO, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_GridGetCoord(grid, staggerLoc=ESMF_STAGGERLOC_CORNER, &
    coordDim=2, computationalLBound=clbnd, computationalUBound=cubnd, &
    farrayPtr=farrayPtrYO, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

dx = pi/4
dy = pi/4
do i1=clbnd(1),cubnd(1)
do i2=clbnd(2),cubnd(2)
   farrayPtrXO(i1,i2) = dx*(i2-1)
   farrayPtrYO(i1,i2) = dy*(i1-1)
enddo
enddo

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

allocate(nodeIds(4))
nodeIds=(/1,2,3,4/) 

allocate(nodeCoords(8))
nodeCoords=[ real(8) :: 0.0,0.0, pi/2.0,0.0, 0.0,pi/2.0, pi/2.0,pi/2.0 ]

allocate(nodeOwners(4))
nodeOwners=(/0,0,0,0/)

allocate(elemIds(1))
elemIds=(/1/)  

allocate(elemTypes(1))
elemTypes=(/ESMF_MESHELEMTYPE_QUAD/)

allocate(elemConn(4))
elemConn=(/1,2,4,3/)

mesh=ESMF_MeshCreate(parametricDim=2,spatialDim=2, &
     coordSys=ESMF_COORDSYS_SPH_DEG, &
     nodeIds=nodeIds, nodeCoords=nodeCoords, &
     nodeOwners=nodeOwners, elementIds=elemIds,&
     elementTypes=elemTypes, elementConn=elemConn, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


! Create source/destination fields
srcField = ESMF_FieldCreate(grid, ESMF_TYPEKIND_R8, &
    staggerloc=ESMF_STAGGERLOC_CENTER, name="source", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

dstField = ESMF_FieldCreate(mesh, ESMF_TYPEKIND_R8, &
    meshloc=ESMF_MESHLOC_ELEMENT, name="dest", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! get src pointer
call ESMF_FieldGet(srcField, 0, srcFarrayPtr, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
srcFarrayPtr(:,:) = 42.

call ESMF_FieldGet(dstField, 0, dstFarrayPtr, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
dstFarrayPtr(:) = 0.


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



!!! Regrid forward from the A grid to the B grid
! Regrid store
call ESMF_FieldRegridStore(srcField, dstField=dstField, &
    routeHandle=routeHandle, &
    regridmethod=ESMF_REGRIDMETHOD_CONSERVE, &
    unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, &
    rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

!call ESMF_FieldRegrid(srcField, dstField, routeHandle, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! Clean up
call ESMF_FieldDestroy(srcField, rc=rc)
call ESMF_FieldDestroy(dstField, rc=rc)
call ESMF_GridDestroy(grid, rc=rc)
call ESMF_MeshDestroy(mesh, rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)


call ESMF_Finalize()

end program GridMeshRegrid
