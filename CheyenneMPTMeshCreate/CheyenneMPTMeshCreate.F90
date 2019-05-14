! $Id:  Exp $
!
! Earth System Modeling Framework
! Copyright 2002-2015, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!


program CheyenneMPTMeshCreate

  use ESMF
  implicit none
  logical :: correct
  integer :: localrc
  integer :: localPet, petCount
  type(ESMF_VM) :: vm
  character(ESMF_MAXPATHLEN) :: srcfile, dstfile
  integer :: numargs

  type(ESMF_Mesh) :: srcMesh
  type(ESMF_Mesh) :: dstMesh

   ! Init ESMF
  call ESMF_Initialize(rc=localrc, logappendflag=.false.)
  if (localrc /=ESMF_SUCCESS) stop

  ! Error check number of command line args
  call ESMF_UtilGetArgC(count=numargs, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)

  if (numargs .ne. 2) then
    write(*,*) "ERROR: CheyenneMPTMeshCreate should be run with 2 arguments"
    call ESMF_Finalize(rc=localrc)
  endif

  ! Get filenames
  call ESMF_UtilGetArg(1, argvalue=srcfile, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)

  ! Get filenames
  call ESMF_UtilGetArg(2, argvalue=dstfile, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)

  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)


  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)


  ! Write out number of PETS
  if (localPet .eq. 0) then
     write(*,*)
     write(*,*) "source file ",trim(srcfile)," destination file ",trim(dstfile)
     write(*,*) "NUMBER OF PROCS = ",petCount
     write(*,*)
  endif

  ! Turn on MOAB
  call ESMF_MeshSetMOAB(.true., rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)

  
  !!!! Setup source mesh !!!!
  srcMesh=ESMF_MeshCreate(filename=srcfile, &
           fileformat=ESMF_FILEFORMAT_ESMFMESH, rc=localrc)
  if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)

  
  ! dstMesh=ESMF_MeshCreate(filename=dstfile, &
  !         fileformat=ESMF_FILEFORMAT_ESMFMESH, rc=localrc)
  ! if (localrc /= ESMF_SUCCESS) call ESMF_Finalize(rc=localrc)

  ! Finalize ESMF
  call ESMF_Finalize(rc=localrc)

end program CheyenneMPTMeshCreate

