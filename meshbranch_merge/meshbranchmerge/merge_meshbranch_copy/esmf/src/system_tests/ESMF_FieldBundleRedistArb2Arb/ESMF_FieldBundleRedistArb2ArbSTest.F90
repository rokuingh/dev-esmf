! $Id: ESMF_FieldBundleRedistArb2ArbSTest.F90,v 1.2 2008/11/14 04:39:16 theurich Exp $
!
! System test FieldBundleRedistArb2Arb
!  Description on Sourceforge under System Test #XXXXX

!-------------------------------------------------------------------------
!ESMF_SYSTEM_removeTEST        String used by test script to count system tests.
!=========================================================================

!BOP
!
! !DESCRIPTION:
! System test FieldBundleRedistArb2Arb.
!
! This system test checks the functionality of the igrid distribution
! routines by redistributing data from one FieldBundle arbitrarily distributed
! structure to another FieldBundle that has been distributed arbitrarily
! and then back again.  The original data should exactly match the final
! data, which serves as the test for SUCCESS.  This program creates two
! identical IGrids with different distributions, both with the semi-random
! arbitrary distribution.  The first IGrid has two FieldBundle created from it,
! the first as the source for the test and the second for the final results.
! The second IGrid has a single FieldBundle that serves as an intermediate
! result between the two redistributions.
!
!\begin{verbatim}

     program Arb2ArbBunReDist

#include "ESMF_Macros.inc"

     ! ESMF Framework module
     use ESMF_Mod
     use ESMF_TestMod
    
     implicit none

     ! Local variables
     integer :: status
     integer :: i, j, j1, i1, add
     integer :: counts(2), localCounts(2), miscount
     integer :: npets, myDE, myPet
     integer, dimension(:,:), allocatable :: myIndices1, myIndices2
     logical :: match
     real(ESMF_KIND_R8) :: min(2), max(2), compval
     real(ESMF_KIND_R8) :: pi = 3.1416d0
     real(ESMF_KIND_R8), dimension(:), pointer :: coordX, coordY
     real(ESMF_KIND_R8), dimension(:), pointer :: srcdata, resdata
     type(ESMF_ArraySpec) :: arrayspec1, arrayspec2
     type(ESMF_DELayout) :: delayout1, delayout2
     type(ESMF_Field) :: humidity1, humidity2, humidity3
     type(ESMF_FieldBundle) :: bundle1, bundle2, bundle3
     type(ESMF_IGrid) :: igrid1, igrid2
     type(ESMF_IGridHorzStagger) :: horz_stagger
     type(ESMF_RouteHandle) :: rh12, rh23
     type(ESMF_VM) :: vm

     ! cumulative result: count failures; no failures equals "all pass"
     integer :: testresult = 0

     ! individual test name
     character(ESMF_MAXSTR) :: testname

     ! individual test failure message and final rc msg
     character(ESMF_MAXSTR) :: failMsg, finalMsg

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------

     print *, "System Test FieldBundleRedistArb2Arb."
!
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!  Create section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!
     ! Initialize the framework and get back the default global VM
     call ESMF_Initialize(vm=vm, rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! Get the PET count and our PET number
     call ESMF_VMGet(vm, localPet=myPet, petCount=npets, rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     miscount = 0

     if (npets .eq. 1) then
       print *, "This test must run with > 1 processor"
       goto 20
     endif

     print *, "Create section finished"
!
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!  Init section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!
     ! create two layouts, both are 1D layout
     ! for arbitrary distribution
     delayout1 = ESMF_DELayoutCreate(vm, (/ 1, npets /), rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20
     delayout2 = ESMF_DELayoutCreate(vm, (/ npets, 1 /), rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! and get our local DE number on the first layout
     call ESMF_DELayoutGetDeprecated(delayout1, localDE=myDE, rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! Create the igrids and corresponding Fields
     counts(1) = 60
     counts(2) = 40
     min(1) = 0.0
     max(1) = 60.0
     min(2) = 0.0
     max(2) = 50.0
     horz_stagger = ESMF_IGRID_HORZ_STAGGER_A

     ! make two identical igrids, both are distributed in arbitrary style
     ! with slightly different delayout.
     igrid1 = ESMF_IGridCreateHorzXYUni(counts=counts, &
                             minGlobalCoordPerDim=min, &
                             maxGlobalCoordPerDim=max, &
                             horzStagger=horz_stagger, &
                             name="source igrid", rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20
     !
     ! Arbitrary case
     ! allocate myIndices to maximum number of points on any DE in the first
     ! dimension and 2 in the second dimension.
     j = int((counts(1)*counts(2) + npets -1)/npets)
     allocate (myIndices1(j,2))
     ! calculate myIndices based on DE number
     ! for now, start at point (1,1+myDE) and go up in the j-direction first
     ! to create a semi-regular distribution of points
     i1  = 1 + myDE
     add = 0
     do j = 1,counts(2)
       do i = i1,counts(1),npets
         add = add + 1
         myIndices1(add,1) = i
         myIndices1(add,2) = j
       enddo
       i1 = i - counts(1)
     enddo

     ! the distribute call is similar to the block distribute but with
     ! a couple of different arguments
     call ESMF_IGridDistribute(igrid1, delayout=delayout1, myCount=add, &
                              myIndices=myIndices1, rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     igrid2 = ESMF_IGridCreateHorzXYUni(counts=counts, &
                             minGlobalCoordPerDim=min, &
                             maxGlobalCoordPerDim=max, &
                             horzStagger=horz_stagger, &
                             name="source igrid", rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! allocate myIndices to maximum number of points on any DE in the first
     ! dimension and 2 in the second dimension.
     i = int((counts(1)*counts(2) + npets -1)/npets)
     allocate (myIndices2(i,2))

     ! calculate myIndices based on DE number
     ! for now, start at point (1,1+myDE) and go up in the j-direction first
     ! to create a semi-regular distribution of points
     j1  = 1 + myDE
     add = 0
     do i = 1,counts(1)
       do j = j1,counts(2),npets
         add = add + 1
         myIndices2(add,1) = i
         myIndices2(add,2) = j
       enddo
       j1 = j - counts(2)
     enddo

     ! the distribute call is similar to the block distribute but with
     ! a couple of different arguments
     call ESMF_IGridDistribute(igrid2, delayout=delayout2, myCount=add, &
                              myIndices=myIndices2, rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! Set up a 1D (for the arbitrarily distributed FieldBundle) and a 1D real array
     call ESMF_ArraySpecSet(arrayspec1, rank=1, &
                            typekind=ESMF_TYPEKIND_R8)
     if (status .ne. ESMF_SUCCESS) goto 20
     call ESMF_ArraySpecSet(arrayspec2, rank=1, &
                            typekind=ESMF_TYPEKIND_R8)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! Create bundles
     bundle1 = ESMF_FieldBundleCreate(igrid1, 'FieldBundle1', rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     bundle2 = ESMF_FieldBundleCreate(igrid2, 'FieldBundle2', rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     bundle3 = ESMF_FieldBundleCreate(igrid1, 'FieldBundle3', rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! Create the field and have it create the array internally for each igrid
     ! and add the Fields to the FieldBundle corresponding to the IGrid.
     humidity1 = ESMF_FieldCreate(igrid1, arrayspec1, &
                                  horzRelloc=ESMF_CELL_CENTER, &
                                  haloWidth=0, name="humidity1", rc=status)
     call ESMF_FieldBundleAddField(bundle1, humidity1, rc=status)

     if (status .ne. ESMF_SUCCESS) goto 20
     humidity2 = ESMF_FieldCreate(igrid2, arrayspec2, &
                                  horzRelloc=ESMF_CELL_CENTER, &
                                  haloWidth=0, name="humidity2", rc=status)
     call ESMF_FieldBundleAddField(bundle2, humidity2, rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     humidity3 = ESMF_FieldCreate(igrid1, arrayspec1, &
                                  horzRelloc=ESMF_CELL_CENTER, &
                                  haloWidth=0, name="humidity3", rc=status)
     call ESMF_FieldBundleAddField(bundle3, humidity3, rc=status)
     if (status .ne. ESMF_SUCCESS) goto 20

     ! precompute communication patterns, the first from the 1st arbitrarily
     ! distributed FieldBundle to the 2nd arbitrarily distributed FieldBundle; and
     ! the second from the 2nd arbitrarily distributed FieldBundle back to
     ! the 1st distributed FieldBundle
     call ESMF_FieldBundleRedistStore(bundle1, bundle2, vm, rh12, rc=status)
     call ESMF_FieldBundleRedistStore(bundle2, bundle3, vm, rh23, rc=status)

    ! get coordinate arrays available for setting the source data array
    call ESMF_IGridGetCoord(igrid1, dim=1, horzRelloc=ESMF_CELL_CENTER, &
      centerCoord=coordX, localCounts=localCounts, rc=status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_IGridGetCoord(igrid1, dim=2, horzRelloc=ESMF_CELL_CENTER, &
      centerCoord=coordY, rc=status)
    if (status .ne. ESMF_SUCCESS) goto 20

    ! Get pointers to the data and set it up
    call ESMF_FieldGetDataPointer(humidity1, srcdata, ESMF_DATA_REF, rc=status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_FieldGetDataPointer(humidity3, resdata, ESMF_DATA_REF, rc=status)
    if (status .ne. ESMF_SUCCESS) goto 20

    ! initialize data arrays
    srcdata = 0.0
    resdata = 0.0

    ! set data array to a function of coordinates (in the computational part
    ! of the array only, not the halo region)
    do i = 1,localCounts(1)
      srcdata(i) = 10.0 + 5.0*sin(coordX(i)/60.0*pi) &
                        + 2.0*sin(coordY(i)/50.0*pi)
    enddo

    print *, "Initial data, before Redistribution:"

    ! No deallocate() is needed for array data, it will be freed when the
    ! Array is destroyed. 

    print *, "Init section finished"
!
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!  Run section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!

    ! Call redistribution method here, output ends up in humidity2
    call ESMF_FieldBundleRedist(bundle1, bundle2, rh12, rc=status)
    print *, "Run ESMF_FieldBundleRedist :",status,ESMF_SUCCESS
    call ESMF_FieldBundleGetField(bundle2, "humidity2", humidity2, rc=status)
    print *, "Run ESMF_FieldBundleGetField :",status,ESMF_SUCCESS
    if (status .ne. ESMF_SUCCESS) goto 20

    print *, "Array contents after Transpose:"

    ! Redistribute back so we can compare contents
    ! output ends up in humidity3
    call ESMF_FieldBundleRedist(bundle2, bundle3, rh23, rc=status)
    call ESMF_FieldBundleGetField(bundle3, "humidity3", humidity3, rc=status)
    if (status .ne. ESMF_SUCCESS) goto 20

    print *, "Array contents after second Redistribution, should match original:"

    print *, "Run section finished"

!
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!   Finalize section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!   Print result

    call ESMF_DELayoutGetDeprecated(delayout1, localDE=myDE, rc=status)

    print *, "-----------------------------------------------------------------"
    print *, "-----------------------------------------------------------------"
    print *, "Result from DE number ", myDE
    print *, "-----------------------------------------------------------------"
    print *, "-----------------------------------------------------------------"

    ! check and make sure the original data and the data that has been 
    ! distributed to the 1D Field and back again are the same
    match    = .true.
    miscount = 0
    do i = 1,localCounts(1)
        compval = 10.0 + 5.0*sin(coordX(i)/60.0*pi) &
                       + 2.0*sin(coordY(i)/50.0*pi)
        if ((srcdata(i) .ne. resdata(i)) .OR. &
            (abs(resdata(i)-compval).ge.1.0d-12)) then
          print *, "array contents do not match at: (", i , ") on DE ", &
                   myDE, ".  src=", srcdata(i), "dst=", &
                   resdata(i), "realval=", compval
          match = .false.
          miscount = miscount + 1
          if (miscount .gt. 40) then
            print *, "more than 40 mismatches, skipping rest of loop"
            goto 10
          endif
        endif
    enddo
    if (match) print *, "Array contents matched correctly!! DE = ", myDE
10  continue

    print *, "Finalize section finished"

!
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!   Destroy section
!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
!   Clean up

    deallocate(myIndices1, myIndices2)

    call ESMF_FieldBundleRedistRelease(rh12, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_FieldBundleRedistRelease(rh23, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_FieldDestroy(humidity1, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_FieldDestroy(humidity2, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_FieldDestroy(humidity3, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_IGridDestroy(igrid1, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_IGridDestroy(igrid2, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_DELayoutDestroy(delayout1, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    call ESMF_DELayoutDestroy(delayout2, status)
    if (status .ne. ESMF_SUCCESS) goto 20
    print *, "All Destroy routines done"

!-------------------------------------------------------------------------
!-------------------------------------------------------------------------
20  print *, "System Test FieldBundleRedistArb2Arb complete."

    write(failMsg, *)  "Redistribution back not same as original"
    write(testname, *) "System Test FieldBundleRedistArb2Arb: FieldBundle Redistribute"

    call ESMF_TestGlobal(((miscount.eq.0).and.(status.eq.ESMF_SUCCESS)), &
      testname, failMsg, testresult, ESMF_SRCLINE)

    if ((myPet .eq. 0) .or. (status .ne. ESMF_SUCCESS)) then
      ! Separate message to console, for quick confirmation of success/failure
      if ((miscount.eq.0) .and. (status .eq. ESMF_SUCCESS)) then
        write(finalMsg, *) "SUCCESS: Data redistributed twice same as original."
      else
        write(finalMsg, *) "System Test did not succeed. ", &
        "Data redistribution does not match expected values, or error code", &
        " set ",status 
      endif
      write(0, *) ""
      write(0, *) trim(testname)
      write(0, *) trim(finalMsg)
      write(0, *) ""

    endif
    
    call ESMF_Finalize(rc=status)

    end program Arb2ArbBunReDist
    
!\end{verbatim}
