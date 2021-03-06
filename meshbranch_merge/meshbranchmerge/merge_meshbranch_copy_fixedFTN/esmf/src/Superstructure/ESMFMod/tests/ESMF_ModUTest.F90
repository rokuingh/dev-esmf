! $Id$
!
! Earth System Modeling Framework
! Copyright 2002-2010, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!
!==============================================================================
!
program ESMF_ModUTest

!==============================================================================
!
#include "ESMF.h"
!
!BOP
! !PROGRAM: ESMF_ModUTest - Test using specific features of ESMF_Mod.
!
! !DESCRIPTION:
!
! Some coding styles encourage the use of the 'use...only' variant of
! the Fortran USE statement.  This makes the location of various
! names clear to the reader, and keeps the namespace of the routine
! from becoming cluttered.  This test ensures early detection of
! compilers that have problems with it.  (See ticket #2893461.)
!
! !USES:
  use ESMF_TestMod     ! test methods
  implicit none
!------------------------------------------------------------------------------
! The following line turns the CVS identifier string into a printable variable.
      character(*), parameter :: version = &
      '$Id$'
!------------------------------------------------------------------------------

!     ! Local variables

  integer :: rc

  ! cumulative result: count failures; no failures equals "all pass"
  integer :: result = 0

  ! individual test failure messages
  character(ESMF_MAXSTR) :: failMsg
  character(ESMF_MAXSTR) :: name

!-------------------------------------------------------------------------------

  call ESMF_TestStart(ESMF_SRCLINE, rc=rc)

!-------------------------------------------------------------------------------
! Test each of the major ESMF data types, when individually
! specified in a 'use...only' statement.
!-------------------------------------------------------------------------------

  call all_types ()
  call alarm_type ()
  call array_type ()
  call arraybundle_type ()
  call arrayspec_type ()
  call clock_type ()
  call config_type ()
  call context_type ()
  call cplcomp_type ()
  call delayout_type ()
  call distgrid_type ()
  call field_type ()
  call fieldbundle_type ()
  call geom_type ()
  call grid_type ()
  call gridcomp_type ()
  call gridconn_type ()
  call iofileformat_type ()
  call iospec_type ()
  call localarray_type ()
  call locstream_type ()
  call log_type ()
  call mesh_type ()
  call method_type ()
  call regrid_type ()
  call routehandle_type ()
  call stagger_type ()
  call state_type ()
  call term_type ()
  call time_type ()
  call timeint_type ()
  call vm_type ()

      
  call ESMF_TestEnd(result, ESMF_SRCLINE)

contains

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine all_types ()
    use ESMF_Mod
    type(ESMF_Alarm) :: alarm
    type(ESMF_Array) :: array
    type(ESMF_ArrayBundle) :: arraybundle
    type(ESMF_ArraySpec) :: arrayspec
    type(ESMF_Calendar) :: calendar
    type(ESMF_Clock) :: clock
    type(ESMF_Config) :: config
    type(ESMF_ContextFlag) :: contextflag
    type(ESMF_CplComp) :: cplcomp
    type(ESMF_DELayout) :: delayout
    type(ESMF_DistGrid) :: distgrid
    type(ESMF_Field) :: field
    type(ESMF_FieldBundle) :: fieldbundle
    type(ESMF_GeomType) :: geomtype
    type(ESMF_Grid) :: grid
    type(ESMF_GridComp) :: gridcomp
    type(ESMF_GridConn) :: gridconn
    type(ESMF_IOFileFormat) :: iofileformat
    type(ESMF_IOSpec) :: iospec
    type(ESMF_LocalArray) :: localarray
    type(ESMF_LocStream) :: locstream
    type(ESMF_Log) :: log
    type(ESMF_Mesh) :: mesh
    type(ESMF_Method) :: method
    type(ESMF_RegridMethod) :: regridmethod
    type(ESMF_RouteHandle) :: routehandle
    type(ESMF_StaggerLoc) :: staggerloc
    type(ESMF_State) :: state
    type(ESMF_TerminationFlag) :: terminationflag
    type(ESMF_Time) :: time
    type(ESMF_TimeInterval) :: timeinterval
    type(ESMF_VM) :: vm

    failMsg = "All types fail"
    name = "All types"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine alarm_type (dummy)
    use ESMF_Mod, only: ESMF_Alarm
    type(ESMF_Alarm), intent(in), optional :: dummy
    failMsg = "Alarm type fail"
    name = "Alarm type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine array_type (dummy)
    use ESMF_Mod, only: ESMF_Array
    type(ESMF_Array), intent(in), optional :: dummy
    failMsg = "Array type fail"
    name = "Array type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine arraybundle_type (dummy)
    use ESMF_Mod, only: ESMF_ArrayBundle
    type(ESMF_ArrayBundle), intent(in), optional :: dummy
    failMsg = "ArrayBundle type fail"
    name = "ArrayBundle type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine arrayspec_type (dummy)
    use ESMF_Mod, only: ESMF_ArraySpec
    type(ESMF_ArraySpec), intent(in), optional :: dummy
    failMsg = "ArraySpec type fail"
    name = "ArraySpec type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine calendar_type (dummy)
    use ESMF_Mod, only: ESMF_Calendar
    type(ESMF_Calendar), intent(in), optional :: dummy
    failMsg = "Calendar type fail"
    name = "Calendar type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine clock_type (dummy)
    use ESMF_Mod, only: ESMF_Clock
    type(ESMF_Clock), intent(in), optional :: dummy
    failMsg = "Clock type fail"
    name = "Clock type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine config_type (dummy)
    use ESMF_Mod, only: ESMF_Config
    type(ESMF_Config), intent(in), optional :: dummy
    failMsg = "Config type fail"
    name = "Config type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine context_type (dummy)
    use ESMF_Mod, only: ESMF_ContextFlag
    type(ESMF_ContextFlag), intent(in), optional :: dummy
    failMsg = "ContextFlag type fail"
    name = "ContextFlag type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine cplcomp_type (dummy)
    use ESMF_Mod, only: ESMF_CplComp
    type(ESMF_CplComp), intent(in), optional :: dummy
    failMsg = "CplComp type fail"
    name = "CplComp type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine delayout_type (dummy)
    use ESMF_Mod, only: ESMF_DELayout
    type(ESMF_DELayout), intent(in), optional :: dummy
    failMsg = "DELayout type fail"
    name = "DELayout type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine distgrid_type (dummy)
    use ESMF_Mod, only: ESMF_DistGrid
    type(ESMF_DistGrid), intent(in), optional :: dummy
    failMsg = "DistGrid type fail"
    name = "DistGrid type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine field_type (dummy)
    use ESMF_Mod, only: ESMF_Field
    type(ESMF_Field), intent(in), optional :: dummy
    failMsg = "Field type fail"
    name = "Field type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine fieldbundle_type (dummy)
    use ESMF_Mod, only: ESMF_FieldBundle
    type(ESMF_FieldBundle), intent(in), optional :: dummy
    failMsg = "FieldBundle type fail"
    name = "FieldBundle type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine geom_type (dummy)
    use ESMF_Mod, only: ESMF_GeomType
    type(ESMF_GeomType), intent(in), optional :: dummy
    failMsg = "Geom type fail"
    name = "Geom type"
    call ESMF_Test (.true.,  & name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine grid_type (dummy)
    use ESMF_Mod, only: ESMF_Grid
    type(ESMF_Grid), intent(in), optional :: dummy
    failMsg = "Grid type fail"
    name = "Grid type"
    call ESMF_Test (.true.,  &
      name, failMsg, result, ESMF_SRCLINE)
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine gridcomp_type (dummy)
    use ESMF_Mod, only: ESMF_GridComp
    type(ESMF_GridComp), intent(in), optional :: dummy
    failMsg = "GridComp type fail"  
    name = "GridComp type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine gridconn_type (dummy)
    use ESMF_Mod, only: ESMF_GridConn
    type(ESMF_GridConn), intent(in), optional :: dummy
    failMsg = "GridConn type fail"  
    name = "GridConn type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine iofileformat_type (dummy)
    use ESMF_Mod, only: ESMF_IOFileFormat
    type(ESMF_IOFileFormat), intent(in), optional :: dummy
    failMsg = "IOFileFormat type fail"  
    name = "IOFileFormat type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine iospec_type (dummy)
    use ESMF_Mod, only: ESMF_IOSpec
    type(ESMF_IOSpec), intent(in), optional :: dummy
    failMsg = "IOSpec type fail"  
    name = "IOSpec type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine localarray_type (dummy)
    use ESMF_Mod, only: ESMF_LocalArray
    type(ESMF_LocalArray), intent(in), optional :: dummy
    failMsg = "LocalArray type fail"  
    name = "LocalArray type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine locstream_type (dummy)
    use ESMF_Mod, only: ESMF_LocStream
    type(ESMF_LocStream), intent(in), optional :: dummy
    failMsg = "LocStream type fail"  
    name = "LocStream type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine log_type (dummy)
    use ESMF_Mod, only: ESMF_Log
    type(ESMF_Log), intent(in), optional :: dummy
    failMsg = "Log type fail"  
    name = "Log type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine mesh_type (dummy)
    use ESMF_Mod, only: ESMF_Mesh
    type(ESMF_Mesh), intent(in), optional :: dummy
    failMsg = "Mesh type fail"  
    name = "Mesh type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine method_type (dummy)
    use ESMF_Mod, only: ESMF_Method
    type(ESMF_Method), intent(in), optional :: dummy
    failMsg = "Method type fail"  
    name = "Method type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine regrid_type (dummy)
    use ESMF_Mod, only: ESMF_RegridMethod
    type(ESMF_RegridMethod), intent(in), optional :: dummy
    failMsg = "RegridMethod type fail"  
    name = "RegridMethod type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine routehandle_type (dummy)
    use ESMF_Mod, only: ESMF_RouteHandle
    type(ESMF_RouteHandle), intent(in), optional :: dummy
    failMsg = "RouteHandle type fail"  
    name = "RouteHandle type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine stagger_type (dummy)
    use ESMF_Mod, only: ESMF_StaggerLoc
    type(ESMF_StaggerLoc), intent(in), optional :: dummy
    failMsg = "StaggerLoc type fail"  
    name = "StaggerLoc type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine state_type (dummy)
    use ESMF_Mod, only: ESMF_State
    type(ESMF_State), intent(in), optional :: dummy
    failMsg = "State type fail"  
    name = "State type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine term_type (dummy)
    use ESMF_Mod, only: ESMF_TerminationFlag
    type(ESMF_TerminationFlag), intent(in), optional :: dummy
    failMsg = "TerminationFlag type fail"  
    name = "TerminationFlag type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine time_type (dummy)
    use ESMF_Mod, only: ESMF_Time
    type(ESMF_Time), intent(in), optional :: dummy
    failMsg = "Time type fail"  
    name = "Time type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine timeint_type (dummy)
    use ESMF_Mod, only: ESMF_TimeInterval
    type(ESMF_TimeInterval), intent(in), optional :: dummy
    failMsg = "TimeInterval type fail"  
    name = "TimeInterval type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

!-------------------------------------------------------------------------------
! NEX_noUTest

  subroutine vm_type (dummy)
    use ESMF_Mod, only: ESMF_VM
    type(ESMF_VM), intent(in), optional :: dummy
    failMsg = "VM type fail"  
    name = "VM type"  
    call ESMF_Test (.true.,  &  
      name, failMsg, result, ESMF_SRCLINE)  
  end subroutine

end program
