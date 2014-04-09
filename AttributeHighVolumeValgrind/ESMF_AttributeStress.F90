!-------------------------------------------------------------------------
program AttributeStress

#include <ESMF_Macros.inc>

    ! ESMF Framework module
    use ESMF_Mod

    implicit none
    
    ! Local variables
    integer :: rc, i
    type(ESMF_Field) :: field
    type(ESMF_Grid) :: grid
    real(ESMF_KIND_R8), dimension(:,:), allocatable     :: farray
    integer, dimension(ESMF_MAXDIM)                     :: gcc, gec

    ! create a grid
    grid = ESMF_GridCreateShapeTile(minIndex=(/1,1/), maxIndex=(/10,20/), &
          regDecomp=(/2,2/), name="grid", rc=rc)
    if (rc .ne. ESMF_SUCCESS) goto 10
    
    ! get info to build a field
    call ESMF_GridGet(grid, localDE=0, staggerloc=ESMF_STAGGERLOC_CENTER, &
        computationalCount=gcc, exclusiveCount=gec, rc=rc)
    if (rc .ne. ESMF_SUCCESS) goto 10  
    allocate(farray(max(gec(1), gcc(1)), max(gec(2), gcc(2))) )
    
    ! loop to create field, add attribute and destroy field
    do i=1,1000
        field = ESMF_FieldCreate(grid, farray, ESMF_INDEX_DELOCAL, rc=rc)
        if (rc .ne. ESMF_SUCCESS) goto 10
    
        call ESMF_AttributeSet(field, "AttributeStress", &
                               "youStressedBrah?", rc=rc)
        if (rc .ne. ESMF_SUCCESS) goto 10

        call ESMF_FieldDestroy(field, rc=rc)
        if (rc .ne. ESMF_SUCCESS) goto 10
    enddo

    ! Remove memory
    deallocate(farray)
    call ESMF_GridDestroy(grid, rc=rc)
    if (rc .ne. ESMF_SUCCESS) goto 10

10  continue
    call ESMF_Finalize(rc=rc) 

end program AttributeStress    
