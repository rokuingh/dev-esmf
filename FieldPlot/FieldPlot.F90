
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
type(ESMF_Grid) :: srcGrid
type(ESMF_Grid) :: dstGrid
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
integer(ESMF_KIND_I4), pointer :: maskB(:,:), maskA(:,:)
real(ESMF_KIND_R8), pointer :: farrayPtrXC(:,:)
real(ESMF_KIND_R8), pointer :: farrayPtrYC(:,:)
real(ESMF_KIND_R8), pointer :: farrayPtr(:,:), farrayPtr2(:,:)
real(ESMF_KIND_R8), pointer :: xfarrayPtr(:,:)
real(ESMF_KIND_R8), pointer :: errorPtr(:,:)
integer :: clbnd(2),cubnd(2)
integer :: fclbnd(2),fcubnd(2)
integer :: i1,i2,i3, index(2)
integer :: lDE, localDECount
real(ESMF_KIND_R8) :: coord(2)
character(len=ESMF_MAXSTR) :: string
integer src_nx, src_ny, dst_nx, dst_ny
integer num_arrays
real(ESMF_KIND_R8) :: dx,dy

real(ESMF_KIND_R8) :: src_dx, src_dy
real(ESMF_KIND_R8) :: dst_dx, dst_dy

real(ESMF_KIND_R8) :: lon, lat, theta, phi, DEG2RAD

integer :: spherical_grid

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
srcGrid = ESMF_GridCreate("fv1.9x2.5_050503.nc", ESMF_FILEFORMAT_SCRIP, [1,1], &
                          addCornerStagger=.true., rc=localrc)
dstGrid = ESMF_GridCreate("wr50a_090614.nc", ESMF_FILEFORMAT_SCRIP, [1,1], &
                          addCornerStagger=.true., rc=localrc)

! Create source/destination fields
call ESMF_ArraySpecSet(arrayspec, 2, ESMF_TYPEKIND_R8, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


srcField = ESMF_FieldCreate(srcGrid, arrayspec, &
staggerloc=ESMF_STAGGERLOC_CENTER, name="source", rc=localrc)
if (localrc /= ESMF_SUCCESS) return


dstField = ESMF_FieldCreate(dstGrid, arrayspec, &
staggerloc=ESMF_STAGGERLOC_CENTER, name="dest", rc=localrc)
if (localrc /= ESMF_SUCCESS) return

xdstField = ESMF_FieldCreate(dstGrid, arrayspec, &
staggerloc=ESMF_STAGGERLOC_CENTER, name="xdest", rc=localrc)
if (localrc /= ESMF_SUCCESS) return

errorField = ESMF_FieldCreate(dstGrid, arrayspec, &
staggerloc=ESMF_STAGGERLOC_CENTER, name="error", rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! Get number of local DEs
call ESMF_GridGet(srcGrid, localDECount=localDECount, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! Construct Src Grid
! (Get memory and set coords for src)
do lDE=0,localDECount-1

!! get coord 1
call ESMF_GridGetCoord(srcGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=1, &
computationalLBound=clbnd, computationalUBound=cubnd, farrayPtr=farrayPtrXC, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_GridGetCoord(srcGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=2, &
computationalLBound=clbnd, computationalUBound=cubnd, farrayPtr=farrayPtrYC, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! get src pointer
call ESMF_FieldGet(srcField, lDE, farrayPtr, computationalLBound=fclbnd, &
computationalUBound=fcubnd,  rc=localrc)
if (localrc /=ESMF_SUCCESS) return

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
farrayPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)
!farrayPtr(i1,i2) = 20.0
enddo
enddo

enddo    ! lDE


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Destination grid
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

! Get number of local DEs
call ESMF_GridGet(dstGrid, localDECount=localDECount, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


! Get memory and set coords for dst
do lDE=0,localDECount-1

!! get coords
call ESMF_GridGetCoord(dstGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=1, &
computationalLBound=clbnd, computationalUBound=cubnd, farrayPtr=farrayPtrXC, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_GridGetCoord(dstGrid, localDE=lDE, staggerLoc=ESMF_STAGGERLOC_CENTER, coordDim=2, &
computationalLBound=clbnd, computationalUBound=cubnd, farrayPtr=farrayPtrYC, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldGet(dstField, lDE, farrayPtr, computationalLBound=fclbnd, &
computationalUBound=fcubnd,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldGet(xdstField, lDE, xfarrayPtr,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return

!! set coords
do i1=clbnd(1),cubnd(1)
do i2=clbnd(2),cubnd(2)

! init exact answer
lon = farrayPtrXC(i1,i2)
lat = farrayPtrYC(i1,i2)

! Set the source to be a function of the x,y,z coordinate
theta = DEG2RAD*(lon)
phi = DEG2RAD*(90.-lat)

! set exact dst data
xfarrayPtr(i1,i2) = 2. + cos(theta)**2.*cos(2.*phi)
!xfarrayPtr(i1,i2) = 20.0

! initialize destination field
farrayPtr(i1,i2)=0.0

enddo
enddo

enddo    ! lDE

#if 0
! Get arrays
! dstArray
call ESMF_FieldGet(srcField, array=srcArray, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_GridWriteVTK(srcGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
filename="srcGrid1", rc=localrc)
if (localrc /= ESMF_SUCCESS) return
#endif

!!! Regrid forward from the A grid to the B grid
! Regrid store
call ESMF_FieldRegridStore( &
srcField, &
dstField=dstField, &
unmappedaction=ESMF_UNMAPPEDACTION_IGNORE, &
routeHandle=routeHandle, &
regridmethod=ESMF_REGRIDMETHOD_BILINEAR, &
rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! Do regrid
call ESMF_FieldRegrid(srcField, dstField, routeHandle, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldRegridRelease(routeHandle, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


! Check results
do lDE=0,localDECount-1

call ESMF_FieldGet(dstField, lDE, farrayPtr, computationalLBound=clbnd, &
computationalUBound=cubnd,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldGet(errorField, lDE, errorPtr,  rc=localrc)
if (localrc /= ESMF_SUCCESS) return


!! make sure we're not using any bad points
do i1=clbnd(1),cubnd(1)
do i2=clbnd(2),cubnd(2)
! if working everything should be really close to 20.0
if (xfarrayPtr(i1,i2) /= 0) then
    errorPtr(i1,i2) = abs(farrayPtr(i1,i2)-xfarrayPtr(i1,i2))/xfarrayPtr(i1,i2)
endif
if (abs(farrayPtr(i1,i2)-xfarrayPtr(i1,i2)) .gt. 0.001) then
    correct=.false.
endif
enddo
enddo

enddo    ! lDE


! Get arrays
! dstArray
call ESMF_FieldGet(dstField, array=dstArray, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


! srcArray
call ESMF_FieldGet(srcField, array=srcArray, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

#if 0
spherical_grid = 1
call ESMF_MeshIO(vm, srcGrid, ESMF_STAGGERLOC_CENTER, &
"srcgrid", srcArray, rc=localrc, &
spherical=spherical_grid)
call ESMF_MeshIO(vm, dstGrid, ESMF_STAGGERLOC_CENTER, &
"dstgrid", dstArray, rc=localrc, &
spherical=spherical_grid)
#endif


#if 1
call ESMF_GridWriteVTK(srcGrid, filename="srcGrid", array1=srcArray, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_GridWriteVTK(dstGrid,staggerloc=ESMF_STAGGERLOC_CENTER, &
filename="dstGrid", array1=dstArray, &
rc=localrc)
if (localrc /= ESMF_SUCCESS) return
#endif

! Destroy the Fields
call ESMF_FieldDestroy(srcField, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_FieldDestroy(dstField, rc=localrc)
if (localrc /= ESMF_SUCCESS) return


! Free the grids
call ESMF_GridDestroy(srcGrid, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

call ESMF_GridDestroy(dstGrid, rc=localrc)
if (localrc /=ESMF_SUCCESS) return

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

end subroutine test_regridDGSph

end program Fieldplot
