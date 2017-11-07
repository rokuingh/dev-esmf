!-------------------------------------------------------------------------
program AttributeBasePointer

#define ESMF_ERR_PASSTHRU msg="Internal subroutine call returned Error"
#define ESMF_CONTEXT  line=__LINE__

! ESMF Framework module
use ESMF


implicit none
    
! Local variables
integer :: rc


type(ESMF_Array) :: array
type(ESMF_ArraySpec) :: arrayspec
type(ESMF_DistGrid) :: distgrid
  

 type(ESMF_AttPack) :: attpack
 character(ESMF_MAXSTR) :: conv, purp, val
 
 integer :: count
 
 character(ESMF_MAXSTR), dimension(1) :: attpackList

 logical :: isPresent 
 
call ESMF_Initialize(rc=rc) 

  call ESMF_ArraySpecSet(arrayspec, typekind=ESMF_TYPEKIND_R8, rank=2, rc=rc)
  distgrid = ESMF_DistGridCreate(minIndex=(/1,1/), maxIndex=(/5,5/), &
    regDecomp=(/2,3/), rc=rc)
  array = ESMF_ArrayCreate(arrayspec=arrayspec, distgrid=distgrid, rc=rc)


  call ESMF_AttributeSet(array, name="att", value="val", rc=rc)
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)

print *, "rc = ", rc


  call ESMF_AttributeGet(array, name="att", value=val, rc=rc)
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)
 
print *, "rc = ", rc


 conv = "customconvention" 
 purp = "custompurpose   " 
 attpackList(1) = "ESMF_I4" 
 

  call ESMF_AttributeAdd(array, conv, purp, attrList=attpackList, attpack=attpack, rc=rc)
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)
    
print *, "rc = ", rc

 ! if i set with attpack it doesn't fail here, but if i set by conv and purp it does..

  call ESMF_AttributeGetAttPack(array, convention=conv, purpose=purp, attpack=attpack, rc=rc)
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT) 

print *, "rc = ", rc
 
  call ESMF_AttributeSet(array, name=attpackList(1), attpack=attpack, value="val", rc=rc)
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)
   
print *, "rc = ", rc

  call ESMF_AttributeSet(array, name=attpackList(1), convention=conv, purpose=purp, value="val", rc=rc)
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)

print *, "rc = ", rc

  call ESMF_AttributeGetAttPack(array, convention=conv, purpose=purp, attpack=attpack, rc=rc)
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)

print *, "rc = ", rc


  count = -5 
  call ESMF_AttributeGet(array, convention=conv, purpose=purp, attnestflag=ESMF_ATTNEST_ON, count=count, rc=rc) 
  if (ESMF_LogFoundError(rc, ESMF_ERR_PASSTHRU, &
    ESMF_CONTEXT, rcToReturn=rc)) &
    call ESMF_Finalize(rc=rc, endflag=ESMF_END_ABORT)

print *, "rc = ", rc


 

  call ESMF_Finalize(rc=rc) 

end program AttributeBasePointer
