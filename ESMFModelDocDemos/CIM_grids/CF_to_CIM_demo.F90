! $Id$
!
! Earth System Modeling Framework
! Copyright 2002-2014, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!
!==============================================================================

program CIM_grids_demo

! !USES:
  use ESMF         ! the ESMF Framework
  implicit none

!-------------------------------------------------------------------------
!=========================================================================

  ! local variables
  integer                 :: rc, localPet, petCount

  type(ESMF_AttPack)      :: attpack   
  type(ESMF_Grid)         :: grid
  type(ESMF_GridComp)     :: gridcomp
  type(ESMF_Field)        :: field
  type(ESMF_FieldBundle)  :: fieldBundle
  type(ESMF_State)        :: importState
  type(ESMF_VM)           :: vm
  character(ESMF_MAXSTR)  :: conv, purp
   
  character(ESMF_MAXSTR),dimension(11)   :: attrList         


  ! Initialize ESMF
  call ESMF_Initialize (defaultCalKind=ESMF_CALKIND_GREGORIAN, &
  defaultlogfilename="CF_to_CIM_demo.Log", &
  logkindflag=ESMF_LOGKIND_MULTI, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
  
  ! get pet info
  call ESMF_VMGetGlobal(vm, rc=rc)
  call ESMF_VMGet(vm, petCount=petCount, localPet=localpet, rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)
  
  ! set log to flush after every message
  call ESMF_LogSet(flush=.true., rc=rc)
  if (rc /= ESMF_SUCCESS) call ESMF_Finalize(endflag=ESMF_END_ABORT)

  grid = ESMF_GridCreate("data/GRIDSPEC_ACCESS1.nc", &
              ESMF_FILEFORMAT_GRIDSPEC, &
              (/1,petCount/), &
              addCornerStagger=.true., &
              addMask=.true., varname="so", rc=rc)
  !-------------------------------------------------------------------------
  !   <CFDocument> attribute representation and output test for
  !   <modelComponent>, <simulationRun>, including <input>s (fields) and
  !   <platform>. Uses built-in, standard CF packages.
  !-------------------------------------------------------------------------

    ! Construct a gridded component ESMF object that will be decorated with
    ! Attributes to output <CFDocument>s
    gridcomp = ESMF_GridCompCreate(name="gridcomp_cfgridspec_to_cim151grids", petList=(/0/), &
                 rc=rc)

    !-------------------------------------------------------------------------
    ! <input>
    !-------------------------------------------------------------------------
    ! Construct a field ESMF object that will be decorated with
    ! Attributes to output within <input>s in a <simulationRun>
    field = ESMF_FieldEmptyCreate(name="DMS_emi", rc=rc)

    !-------------------------------------------------------------------------
    ! Construct a fieldbundle ESMF object that will contain fields
    fieldBundle = ESMF_FieldBundleCreate(name="Field Bundle", rc=rc)

    !-------------------------------------------------------------------------
    ! Add the field to the field bundle (links attributes also)
    call ESMF_FieldBundleAdd(fieldBundle, (/ field /), rc=rc)

    !-------------------------------------------------------------------------
    ! Construct an import state ESMF object that will contain a fieldbundle
    importState = ESMF_StateCreate(name="importState",  &
                                   stateintent=ESMF_STATEINTENT_IMPORT, rc=rc)

    !-------------------------------------------------------------------------
    ! Add a fieldbundle to the import state (links attributes also)
    call ESMF_StateAdd(importState, fieldbundleList=(/fieldBundle/), rc=rc)

    !-------------------------------------------------------------------------
    ! Link import state attributes to the gridded component
    call ESMF_AttributeLink(gridcomp, importState, rc=rc)

    !-------------------------------------------------------------------------
    ! Create standard CF attribute package on the grid
    call ESMF_AttributeAdd(grid, &
                           convention='CIM 1.5.1', &
                           purpose='grids', &
                           rc=rc)

#if 0
    !-------------------------------------------------------------------------
    ! Create package nested inside the CF attribute package on the grid
    attrList(1) = 'nestPack1'
    attrList(2) = 'nestPack2'
    attrList(3) = 'nestPack3'
    call ESMF_AttributeAdd(grid, &
                           convention='CF-nested', &
                           purpose='grids-nested', &
                           attrList=attrList(1:3), &
                           count = 3, &
                           nestConvention='CF', &
                           nestPurpose='grids', &
                           rc=rc)

    !-------------------------------------------------------------------------
    ! Set an attribute value within the CF Grid package
    call ESMF_AttributeSet(grid, 'nestPack1', &
                           'nestPack1', &
                           convention='CF-nested', &
                           purpose='grids-nested', &
                           rc=rc)

    !-------------------------------------------------------------------------
    ! Set an attribute value within the CF Grid package
    call ESMF_AttributeSet(grid, 'nestPack2', &
                           'nestPack2', &
                           convention='CF-nested', &
                           purpose='grids-nested', &
                           rc=rc)

    !-------------------------------------------------------------------------
    ! Set an attribute value within the CF Grid package
    call ESMF_AttributeSet(grid, 'nestPack3', &
                           'nestPack3', &
                           convention='CF-nested', &
                           purpose='grids-nested', &
                           rc=rc)
#endif

    !-------------------------------------------------------------------------
    ! Add a Grid to the Field, this should link the Attribute hierarchies
    call ESMF_FieldEmptySet(field, grid, rc=rc)

    !-------------------------------------------------------------------------
    ! Write out the attribute tree as a CF-formatted XML file
    call ESMF_AttributeWrite(gridcomp, 'CIM 1.5.1', 'grids', &
                             attwriteflag=ESMF_ATTWRITE_XML,rc=rc)

  !------------------------------------------------------------------------
  ! clean up
  call ESMF_GridDestroy(grid, rc=rc)
  call ESMF_FieldDestroy(field, rc=rc)
  call ESMF_FieldBundleDestroy(fieldbundle, rc=rc)
  call ESMF_StateDestroy(importState, rc=rc)
  call ESMF_GridCompDestroy(gridcomp, rc=rc)
  call ESMF_Finalize()
  
end program CIM_grids_demo
