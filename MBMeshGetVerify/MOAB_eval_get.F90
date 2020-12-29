! Earth System Modeling Framework
! Copyright 2002-2020, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.

! #define profile_meshget

program MOAB_eval_get

  use ESMF
  implicit none
  logical :: correct
  integer :: localrc
  integer :: localPet, petCount
  type(ESMF_VM) :: vm
  character(ESMF_MAXPATHLEN) :: file
  integer :: numargs

   ! Init ESMF
  call ESMF_Initialize(rc=localrc, logappendflag=.false.)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Error check number of command line args
  call ESMF_UtilGetArgC(count=numargs, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  if (numargs .ne. 1) then
     write(*,*) "ERROR: MOAB_eval Should be run with 1 argument"
     call ESMF_Finalize(endflag=ESMF_END_ABORT)
  endif

  ! Get filenames
  call ESMF_UtilGetArg(1, argvalue=file, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  ! Write out number of PETS
  if (localPet .eq. 0) then
     write(*,*)
     write(*,*) "NUMBER OF PROCS = ",petCount
     write(*,*) "GRID FILE = ",trim(file)
  endif

  ! Validate MeshGet info between Moab and Native
  call validate_mesh(file, 1E-15, rc=localrc)
   if (localrc /=ESMF_SUCCESS) then
     write(*,*) "Error Validating the Mesh!"
     call ESMF_Finalize(endflag=ESMF_END_ABORT)
  endif

  ! Finalize ESMF
  call ESMF_Finalize(rc=localrc)
  if (localrc /=ESMF_SUCCESS) stop

  contains


  subroutine validate_mesh(file, tol, rc)
    character(*), intent(in) :: file
    real, intent(in) :: tol
    integer, intent(out), optional :: rc

    type(ESMF_VM) :: vm
    type(ESMF_Mesh) :: nativeMesh, moabMesh
    type(ESMF_DistGrid) :: nodeDistgrid, elemDistgrid
    type(ESMF_Field) :: nodeField, elemField
    integer :: i,j,k
    integer :: petCount, localPet
    logical :: correct, print_elem, fail_print
    ! debug verbosity
    ! 0 - no output
    ! 1 - dimensions and counts
    ! 2 - isPresent
    ! 3 - data
    integer :: verbosity = 3
    integer :: outfile

    integer, pointer :: nodeIds(:),nodeOwners(:),nodeMask(:)
    real(ESMF_KIND_R8), pointer :: nodeCoords(:)
    real(ESMF_KIND_R8), pointer :: ownedNodeCoords(:)
    integer :: numNodes, numOwnedNodes, numOwnedNodesNative
    integer :: numElems,numOwnedElemsNative
    integer :: numElemConns, numTriElems, numQuadElems
    real(ESMF_KIND_R8), pointer :: elemCoords(:)
    integer, pointer :: elemIds(:),elemTypes(:),elemConn(:)
    integer, allocatable :: elemMask(:)
    real(ESMF_KIND_R8),allocatable :: elemArea(:)

    integer :: pdimMoab, sdimMoab
    integer :: numNodesMoab, numElemsMoab,numElemConnsMoab
    logical :: nodeMaskIsPresentMoab
    logical :: elemMaskIsPresentMoab
    logical :: elemAreaIsPresentMoab
    logical :: elemCoordsIsPresentMoab
    integer,allocatable :: nodeIdsMoab(:)
    real(ESMF_KIND_R8),allocatable :: nodeCoordsMoab(:)
    integer,allocatable :: nodeOwnersMoab(:)
    integer,allocatable :: nodeMaskMoab(:)
    integer,allocatable :: elemIdsMoab(:)
    integer,allocatable :: elemTypesMoab(:)
    integer,allocatable :: elemConnMoab(:)
    integer,allocatable :: elemMaskMoab(:)
    real(ESMF_KIND_R8),allocatable :: elemAreaMoab(:)
    real(ESMF_KIND_R8), allocatable :: elemCoordsMoab(:)
    type(ESMF_Array) :: elemMaskArrayMoab
    type(ESMF_Field) :: maskFieldMoab
    integer(ESMF_KIND_I4), pointer :: elemMaskArrayFPtrMoab(:)

    integer :: pdimNative, sdimNative
    integer :: numNodesNative, numElemsNative,numElemConnsNative
    logical :: nodeMaskIsPresentNative
    logical :: elemMaskIsPresentNative
    logical :: elemAreaIsPresentNative
    logical :: elemCoordsIsPresentNative
    integer,allocatable :: nodeIdsNative(:)
    real(ESMF_KIND_R8),allocatable :: nodeCoordsNative(:)
    integer,allocatable :: nodeOwnersNative(:)
    integer,allocatable :: nodeMaskNative(:)
    integer,allocatable :: elemIdsNative(:)
    integer,allocatable :: elemTypesNative(:)
    integer,allocatable :: elemConnNative(:)
    integer,allocatable :: elemMaskNative(:)
    real(ESMF_KIND_R8),allocatable :: elemAreaNative(:)
    real(ESMF_KIND_R8), allocatable :: elemCoordsNative(:)
    type(ESMF_Array) :: elemMaskArrayNative
    type(ESMF_Field) :: maskFieldNative
    integer(ESMF_KIND_I4), pointer :: elemMaskArrayFPtrNative(:)

    ! Init to success
    rc=ESMF_SUCCESS
    correct = .true.

    ! Don't do the test is MOAB isn't available
#ifdef ESMF_MOAB

    ! set up file if verbosity >=3
    if (verbosity >= 3) then
      call ESMF_UtilIOUnitGet(outfile, rc=rc)
      if (rc /= ESMF_SUCCESS) return
      OPEN(outfile, FILE=trim(file)//"-createinfo.out")
      write (*,*) "Verbosity >= 3, opening ", trim(file)//"-createinfo.out", " with unit ", outfile
    endif

    ! get pet info
    call ESMF_VMGetGlobal(vm, rc=rc)
    if (rc /= ESMF_SUCCESS) return

    call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=rc)
    if (rc /= ESMF_SUCCESS) return


    call ESMF_MeshSetMOAB(moabOn=.true.)

    moabMesh=ESMF_MeshCreate(filename=file, fileformat=ESMF_FILEFORMAT_ESMFMESH, rc=rc)
    if (rc /= ESMF_SUCCESS) return


    call ESMF_MeshSetMOAB(moabOn=.false.)

    nativeMesh=ESMF_MeshCreate(filename=file, fileformat=ESMF_FILEFORMAT_ESMFMESH, rc=rc)
    if (rc /= ESMF_SUCCESS) return


    ! Get counts 
    call ESMF_MeshGet(moabMesh, &
                      parametricDim=pdimMoab, &
                      spatialDim=sdimMoab, &
                      nodeCount=numNodesMoab, &
                      elementCount=numElemsMoab, &
                      elementConnCount=numElemConnsMoab, &
                      rc=rc)
    if (rc /= ESMF_SUCCESS) return
    call ESMF_MeshGet(nativeMesh, &
                      parametricDim=pdimNative, &
                      spatialDim=sdimNative, &
                      nodeCount=numNodesNative, &
                      elementCount=numElemsNative, &
                      elementConnCount=numElemConnsNative, &
                      rc=rc)
    if (rc /= ESMF_SUCCESS) return

    ! Check Counts
    if (pdimMoab .ne. pdimNative) then
      correct=.false.
      write(*,*) "parametricDimMoab = ",pdimMoab," parametricDimNative = ", pdimNative
    endif
    if (sdimMoab .ne. sdimNative) then
      correct=.false.
      write(*,*) "spatialDimMoab = ",sdimMoab," spatialDimNative = ", sdimNative
    endif

    ! Check Counts
    if (numNodesMoab .ne. numNodesNative) then
      correct=.false.
      write(*,*) "numNodesMoab = ",numNodesMoab," numNodesNative = ", numNodesNative
    endif
    if (numElemsMoab .ne. numElemsNative) then
      correct=.false.
      write(*,*) "numElemsMoab = ",numElemsMoab," numElemsNative = ", numElemsNative
    endif
    if (numElemConnsMoab .ne. numElemConnsNative) then
      correct=.false.
      write(*,*) "numElemConnsMoab = ",numElemConnsMoab," numElemConnsNative = ", numElemConnsNative
    endif

    if (verbosity >= 1) then
      write(*,*) "parametricDim = ",pdimMoab
      write(*,*) "spatialDim = ",sdimMoab
      write(*,*) "numNodes = ",numNodesMoab
      write(*,*) "numElems = ",numElemsMoab
    endif

    if (verbosity >= 3) then
      write(outfile,*) "parametricDim = ",pdimMoab
      write(outfile,*) "spatialDim = ",sdimMoab
      write(outfile,*) "numNodes = ",numNodesMoab
      write(outfile,*) "numElems = ",numElemsMoab
    endif

    ! Get is present information
    call ESMF_MeshGet(moabMesh, &
                      nodeMaskIsPresent=nodeMaskIsPresentMoab, &
                      elementMaskIsPresent=elemMaskIsPresentMoab, &
                      elementAreaIsPresent=elemAreaIsPresentMoab, &
                      elementCoordsIsPresent=elemCoordsIsPresentMoab, &
                      rc=rc)
    if (rc /= ESMF_SUCCESS) return

    call ESMF_MeshGet(nativeMesh, &
                      nodeMaskIsPresent=nodeMaskIsPresentNative, &
                      elementMaskIsPresent=elemMaskIsPresentNative, &
                      elementAreaIsPresent=elemAreaIsPresentNative, &
                      elementCoordsIsPresent=elemCoordsIsPresentNative, &
                      rc=rc)
    if (rc /= ESMF_SUCCESS) return

    ! Check is present info
    if (nodeMaskIsPresentMoab   .neqv. nodeMaskIsPresentNative) correct=.false.
    if (elemMaskIsPresentMoab   .neqv. elemMaskIsPresentNative) correct=.false.
    if (elemAreaIsPresentMoab   .neqv. elemAreaIsPresentNative) correct=.false.
    if (elemCoordsIsPresentMoab .neqv. elemCoordsIsPresentNative) correct=.false.
    if (verbosity >=2) then
      write(*,*) "nodeMaskIsPresent = ",nodeMaskIsPresentMoab
      write(*,*) "elemMaskIsPresent = ",elemMaskIsPresentMoab
      write(*,*) "elemAreaIsPresent = ",elemAreaIsPresentMoab
      write(*,*) "elemCoordsIsPresent = ",elemCoordsIsPresentMoab
    endif

    if (verbosity >= 3) then
      write(outfile,*) "nodeMaskIsPresent = ",nodeMaskIsPresentMoab
      write(outfile,*) "elemMaskIsPresent = ",elemMaskIsPresentMoab
      write(outfile,*) "elemAreaIsPresent = ",elemAreaIsPresentMoab
      write(outfile,*) "elemCoordsIsPresent = ",elemCoordsIsPresentMoab
    endif


    ! Allocate space for Moab arrays
    allocate(nodeIdsMoab(numNodesMoab))
    allocate(nodeCoordsMoab(sdimMoab*numNodesMoab))
    allocate(nodeOwnersMoab(numNodesMoab))
    if (nodeMaskIsPresentMoab) allocate(nodeMaskMoab(numNodesMoab))
    allocate(elemIdsMoab(numElemsMoab))
    allocate(elemTypesMoab(numElemsMoab))
    allocate(elemConnMoab(numElemConnsMoab))
    if (elemMaskIsPresentMoab) allocate(elemMaskMoab(numElemsMoab))
    if (elemAreaIsPresentMoab) allocate(elemAreaMoab(numElemsMoab))
    if (elemCoordsIsPresentMoab) allocate(elemCoordsMoab(sdimMoab*numElemsMoab))
    
    allocate(nodeIdsNative(numNodesNative))
    allocate(nodeCoordsNative(sdimNative*numNodesNative))
    allocate(nodeOwnersNative(numNodesNative))
    if (nodeMaskIsPresentNative) allocate(nodeMaskNative(numNodesNative))
    allocate(elemIdsNative(numElemsNative))
    allocate(elemTypesNative(numElemsNative))
    allocate(elemConnNative(numElemConnsNative))
    if (elemMaskIsPresentNative) allocate(elemMaskNative(numElemsNative))
    if (elemAreaIsPresentNative) allocate(elemAreaNative(numElemsNative))
    if (elemCoordsIsPresentNative) allocate(elemCoordsNative(sdimMoab*numElemsNative))
    
    ! Get Information
    call ESMF_MeshGet(moabMesh, &
                      nodeIds=nodeIdsMoab, &
                      nodeCoords=nodeCoordsMoab, &
                      nodeOwners=nodeOwnersMoab, &
                      nodeMask=nodeMaskMoab, &
                      elementIds=elemIdsMoab, &
                      elementTypes=elemTypesMoab, &
                      elementConn=elemConnMoab, &
                      elementMask=elemMaskMoab, & 
                      elementArea=elemAreaMoab, & 
                      elementCoords=elemCoordsMoab, &
                      rc=rc)
    if (rc /= ESMF_SUCCESS) return
    
    call ESMF_MeshGet(nativeMesh, &
                      nodeIds=nodeIdsNative, &
                      nodeCoords=nodeCoordsNative, &
                      nodeOwners=nodeOwnersNative, &
                      nodeMask=nodeMaskNative, &
                      elementIds=elemIdsNative, &
                      elementTypes=elemTypesNative, &
                      elementConn=elemConnNative, &
                      elementMask=elemMaskNative, & 
                      elementArea=elemAreaNative, & 
                      elementCoords=elemCoordsNative, &
                      rc=rc)
    if (rc /= ESMF_SUCCESS) return
    
    
    fail_print = .false.
    do i=1,numNodesMoab
      print_elem = .false.
      if (nodeIdsMoab(i) .ne. nodeIdsNative(i)) then
        correct=.false.
        print_elem = .true.
        fail_print = .true.
      endif
       if(print_elem .and. verbosity>=3) then
        write(outfile,*) "nodeIdsMoab(", i, ") = ", nodeIdsMoab(i), " nodeIdsNative(", i, ")  = ", nodeIdsNative(i)
      endif
    enddo
    if (verbosity >= 1) then
      if (.not. fail_print) then
        write(*,*) "Pass - nodeIds"
      else
        write(*,*) "Fail - nodeIds"
      endif
    endif
    
    fail_print = .false.
    do i=1,numNodesMoab
      print_elem = .false.
      if (nodeOwnersMoab(i) .ne. nodeOwnersNative(i)) then
        correct=.false.
        print_elem = .true.
        fail_print = .true.
      endif
       if(print_elem .and. verbosity>=3) then
        write(outfile,*) "nodeOwnersMoab(", i, ") = ", nodeOwnersMoab(i), " nodeOwnersNative(", i, ")  = ", nodeOwnersNative(i)
      endif
    enddo
    if (verbosity >= 1) then
      if (.not. fail_print) then
        write(*,*) "Pass - nodeOwners"
      else
        write(*,*) "Fail - nodeOwners"
      endif
    endif
    
    if (nodeMaskIsPresentMoab) then
      fail_print = .false.
      do i=1,numNodesMoab
        print_elem = .false.
        if (nodeMaskMoab(i) .ne. nodeMaskNative(i)) then
          correct=.false.
          print_elem = .true.
          fail_print = .true.
        endif
         if(print_elem .and. verbosity>=3) then
          write(outfile,*) "nodeMaskMoab(", i, ") = ", nodeMaskMoab(i), " nodeMaskNative(", i,  ")  = ", nodeMaskNative(i)
        endif
      enddo
      if (verbosity >= 1) then
        if (.not. fail_print) then
          write(*,*) "Pass - nodeMask"
        else
          write(*,*) "Fail - nodeMask"
        endif
      endif
    endif
    
    
    fail_print = .false.
    do i=1,numElemsMoab
      print_elem = .false.
      if (elemIdsMoab(i) .ne. elemIdsNative(i)) then
        correct=.false.
        print_elem = .true.
        fail_print = .true.
      endif
       if(print_elem .and. verbosity>=3) then
        write(outfile,*) "elemIdsMoab(", i, ") = ", elemIdsMoab(i), " elemIdsNative(", i, ")  = ", elemIdsNative(i)
      endif
    enddo
    if (verbosity >= 1) then
      if (.not. fail_print) then
        write(*,*) "Pass - elemIds"
      else
        write(*,*) "Fail - elemIds"
      endif
    endif
    
    fail_print = .false.
    do i=1,numElemsMoab
      print_elem = .false.
      if (elemTypesMoab(i) .ne. elemTypesNative(i)) then
        correct=.false.
        print_elem = .true.
        fail_print = .true.
      endif
       if(print_elem .and. verbosity>=3) then
        write(outfile,*) "elemTypesMoab(", i, ") = ", elemTypesMoab(i), " elemTypesNative(", i, ")  = ", elemTypesNative(i)
      endif
    enddo
    if (verbosity >= 1) then
      if (.not. fail_print) then
        write(*,*) "Pass - elemTypes"
      else
        write(*,*) "Fail - elemTypes"
      endif
    endif
    
    fail_print = .false.
    do i=1,numElemConnsMoab
      print_elem = .false.
      if (elemConnMoab(i) .ne. elemConnNative(i)) then
        correct=.false.
        print_elem = .true.
        fail_print = .true.
      endif
       if(print_elem .and. verbosity>=3) then
        write(outfile,*) "elemConnMoab(", i, ") = ", elemConnMoab(i), " elemConnNative(", i, ")  = ", elemConnNative(i)
      endif
    enddo
    if (verbosity >= 1) then
      if (.not. fail_print) then
        write(*,*) "Pass - elemConn"
      else
        write(*,*) "Fail - elemConn"
      endif
    endif
    
    if (elemMaskIsPresentMoab) then
      fail_print = .false.
      do i=1,numElemsMoab
        print_elem = .false.
        if (elemMaskMoab(i) .ne. elemMaskNative(i)) then
          correct=.false.
          print_elem = .true.
          fail_print = .true.
          fail_print = .true.
        endif
         if(print_elem .and. verbosity>=3) then
          write(outfile,*) "elemMaskMoab(", i, ") = ", elemMaskMoab(i), " elemMaskNative(", i,  ")  = ", elemMaskNative(i)
        endif
      enddo
      if (verbosity >= 1) then
        if (.not. fail_print) then
          write(*,*) "Pass - elemMask"
        else
          write(*,*) "Fail - elemMask"
        endif
      endif
    endif
    
    if (elemAreaIsPresentMoab) then
      fail_print = .false.
      do i=1,numElemsMoab
        print_elem = .false.
        if (abs(elemAreaMoab(i) - elemAreaNative(i)) > tol) then
          correct=.false.
          print_elem = .true.
          fail_print = .true.
        endif
         if(print_elem .and. verbosity>=3) then
          write(outfile,*) "elemAreaMoab(", i, ") = ", elemAreaMoab(i), " elemAreaNative(", i,  ")  = ", elemAreaNative(i)
        endif
      enddo
      if (verbosity >= 1) then
        if (.not. fail_print) then
          write(*,*) "Pass - elemArea"
        else
          write(*,*) "Fail - elemArea"
        endif
      endif
    endif
    
    
    k=1
    fail_print = .false.
    do i=1,numNodesMoab ! Loop over nodes
      do j=1,2 ! Loop over coord spatial dim
        print_elem = .false.
        if (abs(nodeCoordsMoab(k) - nodeCoordsNative(k)) > tol) then
          correct=.false.
          print_elem = .true.
          fail_print = .true.
        endif
        if (print_elem .and. verbosity>=3) then
          write(outfile,*) "nodeCoordsMoab(", k, ") = ", nodeCoordsMoab(k), " nodeCoordsNative(", k, ")  = ", nodeCoordsNative(k)
        endif
        k=k+1
      enddo
    enddo
    if (verbosity >= 1) then
      if (.not. fail_print) then
        write(*,*) "Pass - nodeCoords"
      else
        write(*,*) "Fail - nodeCoords"
      endif
    endif
    
    if (elemCoordsIsPresentMoab) then
      k=1
      fail_print = .false.
      do i=1,numElemsMoab ! Loop over nodes
        do j=1,2 ! Loop over coord spatial dim
          print_elem = .false.
          if (abs(elemCoordsMoab(k) - elemCoordsNative(k)) > tol) then
            correct=.false.
            print_elem = .true.
            fail_print = .true.
          endif
          if(print_elem .and. verbosity>=3) then
            write(outfile,*) "elemCoordsMoab(", k, ") = ", elemCoordsMoab(k), "   elemCoordsNative(", k, ")  = ", elemCoordsNative(k)
          endif
          k=k+1
        enddo
      enddo
      if (verbosity >= 1) then
        if (.not. fail_print) then
          write(*,*) "Pass - elemCoords"
        else
          write(*,*) "Fail - elemCoords"
        endif
      endif
    endif

    if (elemMaskIsPresentMoab) then
      ! Create Mask Field/Array Moab
      maskFieldMoab = ESMF_FieldCreate(moabMesh, ESMF_TYPEKIND_I4, &
                                      meshloc=ESMF_MESHLOC_ELEMENT, rc=rc)
      if (rc /= ESMF_SUCCESS) return
  
      call ESMF_FieldGet(maskFieldMoab, array=elemMaskArrayMoab, rc=localrc)
      if (rc /= ESMF_SUCCESS) return
  
      call ESMF_MeshGet(moabMesh, elemMaskArray=elemMaskArrayMoab, rc=rc)
      if (rc /= ESMF_SUCCESS) return
  
      maskFieldNative = ESMF_FieldCreate(nativeMesh, ESMF_TYPEKIND_I4, &
                                      meshloc=ESMF_MESHLOC_ELEMENT, rc=rc)
      if (rc /= ESMF_SUCCESS) return
  
      call ESMF_FieldGet(maskFieldNative, array=elemMaskArrayNative, rc=localrc)
      if (rc /= ESMF_SUCCESS) return
  
      call ESMF_MeshGet(nativeMesh, elemMaskArray=elemMaskArrayNative, rc=rc)
      if (rc /= ESMF_SUCCESS) return

      call ESMF_ArrayGet(elemMaskArrayMoab, localDe=0, farrayPtr=elemMaskArrayFPtrMoab, rc=rc)
      if (rc /= ESMF_SUCCESS) return
      call ESMF_ArrayGet(elemMaskArrayNative, localDe=0, farrayPtr=elemMaskArrayFPtrNative, rc=rc)
      if (rc /= ESMF_SUCCESS) return

      fail_print = .false.
      do i=1,numElemsMoab
        print_elem = .false.
        if (elemMaskArrayFPtrMoab(i) .ne. elemMaskArrayFPtrNative(i)) then
          correct=.false.
          print_elem = .true.
          fail_print = .true.
        endif
         if(print_elem .and. verbosity>=3) then        
          write(outfile,*) "elemMaskArrayFPtrMoab(", i, ") = ", elemMaskArrayFPtrMoab(i), " elemMaskArrayFPtrNative(", i,  ")  = ", elemMaskArrayFPtrNative(i)
        endif
      enddo
      if (verbosity >= 1) then
        if (.not. fail_print) then
          write(*,*) "Pass - elemMask from ESMF_Array"
        else
          write(*,*) "Fail - elemMask from ESMF_Array"
        endif
      endif


    endif


    ! close outfile
    if (verbosity >= 3) CLOSE(outfile)

    ! Deallocate
    deallocate(nodeIdsMoab)
    deallocate(nodeCoordsMoab)
    deallocate(nodeOwnersMoab)
    if (nodeMaskIsPresentMoab) deallocate(nodeMaskMoab)
    deallocate(elemIdsMoab)
    deallocate(elemTypesMoab)
    deallocate(elemConnMoab)
    if (elemMaskIsPresentMoab) deallocate(elemMaskMoab)
    if (elemAreaIsPresentMoab) deallocate(elemAreaMoab)
    if (elemCoordsIsPresentMoab) deallocate(elemCoordsMoab)
    
    deallocate(nodeIdsNative)
    deallocate(nodeCoordsNative)
    deallocate(nodeOwnersNative)
    if (nodeMaskIsPresentNative) deallocate(nodeMaskNative)
    deallocate(elemIdsNative)
    deallocate(elemTypesNative)
    deallocate(elemConnNative)
    if (elemMaskIsPresentNative) deallocate(elemMaskNative)
    if (elemAreaIsPresentNative) deallocate(elemAreaNative)
    if (elemCoordsIsPresentNative) deallocate(elemCoordsNative)

    ! Destroy
    if (elemMaskIsPresentMoab) then
      call ESMF_ArrayDestroy(elemMaskArrayMoab, rc=rc)
      call ESMF_ArrayDestroy(elemMaskArrayNative, rc=rc)
      call ESMF_FieldDestroy(maskFieldMoab, rc=rc)
      call ESMF_FieldDestroy(maskFieldNative, rc=rc)
    endif

    call ESMF_MeshDestroy(moabMesh, rc=rc)
    if (rc /= ESMF_SUCCESS) return
    call ESMF_MeshDestroy(nativeMesh, rc=rc)
    if (rc /= ESMF_SUCCESS) return

#endif
! ESMF_MOAB

  end subroutine validate_mesh

end program MOAB_eval_get

