
program ArrayWrite

use ESMF

use netcdf

implicit none

integer :: rc

rc = ESMF_SUCCESS


! Initialize ESMF
call ESMF_Initialize (defaultlogfilename="ArrayWrite.Log", rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call test_arraywrite(rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

! set log to flush after every message
call ESMF_LogSet(flush=.true., rc=rc)
if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

call ESMF_Finalize()

contains

subroutine test_arraywrite(rc)
integer, intent(out)  :: rc

type(ESMF_DistGrid) :: distgrid
type(ESMF_Array) :: array_undist
real(ESMF_KIND_R8), pointer :: arrayPtrR8D3(:,:,:)
logical :: correct
integer :: localrc
type(ESMF_VM) :: vm

  type(ESMF_DistGrid)                     :: distgrid_tmp
  type(ESMF_Array)                        :: array_tmp
  integer                                 :: rank, tileCount, dimCount, jj
  integer, allocatable                    :: arrayToDistGridMap(:), regDecomp(:)
  integer, allocatable                    :: minIndexPTile(:,:), maxIndexPTile(:,:)
  integer, allocatable                    :: minIndexNew(:), maxIndexNew(:)
  integer, allocatable                    :: undistLBound(:), undistUBound(:)


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

distgrid = ESMF_DistGridCreate(minIndex=(/1,1/), &
              maxIndex=(/5,10/), regDecomp=(/petCount,1/),  rc=rc)
if (localrc /= ESMF_SUCCESS) return

array_undist = ESMF_ArrayCreate(distgrid=distgrid, typekind=ESMF_TYPEKIND_R8, &
          indexflag=ESMF_INDEX_GLOBAL, distgridToArrayMap=(/2,3/), &
          undistLBound=(/1/), undistUBound=(/8/), &
          name="myData", rc=rc)
if (localrc /= ESMF_SUCCESS) return

  ! access the pointer to the allocated memory on each DE
call ESMF_ArrayGet(array_undist, farrayPtr=arrayPtrR8D3, rc=rc)
if (localrc /= ESMF_SUCCESS) return


! initialize data
arrayPtrR8D3 = 12345._ESMF_KIND_R8*localPet

! ! Given an ESMF array, write the netCDF file.
call ESMF_ArrayWrite(array_undist, fileName="Array_undist_first.nc", &
      status=ESMF_FILESTATUS_REPLACE, iofmt=ESMF_IOFMT_NETCDF, rc=rc)
if (localrc /= ESMF_SUCCESS) return
#endif

!#define TEST_WORKAROUND
#if defined(TEST_WORKAROUND)
!!!! Calling ArrayWrite on array directly does not work because it has
!!!! undistributed dimensions!!

!!!! The way to solve this is to create a new Array on a new DistGrid, that
!!!! has all distributed dims, and still results in exactly the same memory
!!!! allocation. This new Array can then use the original arrayPtr to access
!!!! the original memory.

  ! get some basic information out of the Array
  call ESMF_ArrayGet(array_undist, rank=rank, tileCount=tileCount, dimCount=dimCount, &
    rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  if (tileCount /= 1) then
    ! code below, and I/O only supports single tile case for now.
    call ESMF_Finalize(endflag=ESMF_END_ABORT)
  endif

  ! get more info out of the Array
  allocate(minIndexPTile(dimCount,1), maxIndexPTile(dimCount,1))
  allocate(arrayToDistGridMap(rank))
  allocate(undistLBound(rank), undistUBound(rank))
  call ESMF_ArrayGet(array_undist, arrayToDistGridMap=arrayToDistGridMap, &
    undistLBound=undistLBound, undistUBound=undistUBound, &
    minIndexPTile=minIndexPTile, maxIndexPTile=maxIndexPTile, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! construct the new minIndex and maxIndex
  allocate(minIndexNew(rank), maxIndexNew(rank))
  jj=0  ! reset
  do i=1, rank
    j = arrayToDistGridMap(i)
    if (j>0) then
      ! valid DistGrid dimension
      minIndexNew(i) = minIndexPTile(j,1)
      maxIndexNew(i) = maxIndexPTile(j,1)
    else
      ! undistributed dimension
      jj=jj+1
      minIndexNew(i) = undistLBound(jj)
      maxIndexNew(i) = undistUBound(jj)
    endif
  enddo

  ! general dimensionality of regDecomp
  allocate(regDecomp(rank))
  regDecomp = 1 ! default all dims to 1
  regDecomp(1) = petCount ! first element petCount for default distribution

  ! now create the fixed up DistGrid
  distgrid_tmp = ESMF_DistGridCreate(minIndex=minIndexNew, &
    maxIndex=maxIndexNew, regDecomp=regDecomp, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! finally create the fixed up Array, passing in same memory allocation ptr
  array_tmp = ESMF_ArrayCreate(distgrid=distgrid_tmp, &
    farrayPtr=arrayPtrR8D4, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

!!!! Now array_tmp is an Array that references the exact same data allocation
!!!! as the oritional array object did, however, array_tmp only has distributed
!!!! dimensions, and therefore will work in the ArrayWrite() call below...

  call ESMF_ArrayWrite(array_tmp, fileName="Array_myData.nc",         &
      status=ESMF_FILESTATUS_REPLACE, iofmt=ESMF_IOFMT_NETCDF, rc=rc)
#endif


! Free the grids
call ESMF_ArrayDestroy(array_undist, rc=localrc)
if (localrc /= ESMF_SUCCESS) return

! return answer based on correct flag
if (correct) then
rc=ESMF_SUCCESS
else
rc=ESMF_FAILURE
endif

end subroutine test_arraywrite

end program ArrayWrite
