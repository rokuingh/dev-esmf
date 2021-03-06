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
#define ESMF_FILENAME "ESMF_FieldRegrid.F90"
!==============================================================================
!
!     ESMF FieldRegrid module
module ESMF_FieldRegridMod
!
!==============================================================================
!
! This file contains the FieldRegrid methods.
!
!------------------------------------------------------------------------------
! INCLUDES
#include "ESMF.h"

!------------------------------------------------------------------------------
! !USES:
  use ESMF_UtilTypesMod
  use ESMF_VMMod
  use ESMF_LogErrMod
  use ESMF_ArrayMod
  use ESMF_GridMod
  use ESMF_GridUtilMod
  use ESMF_StaggerLocMod
  use ESMF_MeshMod
  use ESMF_RHandleMod
  use ESMF_GeomBaseMod
  use ESMF_RegridMod
  use ESMF_FieldMod
  use ESMF_FieldGetMod

  
  implicit none
  private

!------------------------------------------------------------------------------
!
! !PUBLIC MEMBER FUNCTIONS:
!
! - ESMF-public methods:
   public ESMF_FieldRegridStore        ! Store a regrid matrix
   public ESMF_FieldRegridRun          ! apply a regrid operator
   public ESMF_FieldRegrid             ! apply a regrid operator
   public ESMF_FieldRegridRelease      ! apply a regrid operator
   public ESMF_FieldRegridGetIwts      ! get integration weights
   private checkGrid                   ! small subroutine to check the grid

! -------------------------- ESMF-public method -------------------------------
!BOPI
! !IROUTINE: ESMF_FieldRegrid -- Generic interface

! !INTERFACE:
  interface ESMF_FieldRegrid

! !PRIVATE MEMBER FUNCTIONS:
!
    module procedure ESMF_FieldRegridRun
!EOPI

  end interface


! -------------------------- ESMF-public method -------------------------------


!------------------------------------------------------------------------------
! The following line turns the CVS identifier string into a printable variable.
  character(*), parameter, private :: version = &
    '$Id$'

!==============================================================================
!
! INTERFACE BLOCKS
!
!==============================================================================


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

contains

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!------------------------------------------------------------------------------
#undef  ESMF_METHOD
#define ESMF_METHOD "ESMF_FieldRegridRun"

!BOP
! !IROUTINE: ESMF_FieldRegrid - Apply the regrid operator
!
! !INTERFACE:
  !   Private name; call using ESMF_FieldRegrid()
      subroutine ESMF_FieldRegridRun(srcField, dstField, &
                   routehandle, zeroflag, checkflag, rc)
!
! !ARGUMENTS:
      type(ESMF_Field), intent(inout)                 :: srcField
      type(ESMF_Field), intent(inout)                 :: dstField
      type(ESMF_RouteHandle), intent(inout)           :: routeHandle
      type(ESMF_RegionFlag),  intent(in),    optional :: zeroflag
      logical,                intent(in),    optional :: checkflag
      integer, intent(out), optional :: rc 
!
! !DESCRIPTION:
!   Execute the precomputed regrid operation stored in {\tt routeHandle} to 
!   interpolate from {\tt srcField} to {\tt dstField}.  See {\tt ESMF\_FieldRegridStore()} on how to 
!   precompute the {\tt routehandle}. 
!  
!   Both {\tt srcField} and {\tt dstField} must be
!   congruent with the respective Fields used during 
!   {\tt ESMF\_FieldRegridStore()}. In the case of the Regrid operation congruent 
!   Fields are built upon the same stagger location and on the same Grid. The routeHandle represents
!   the interpolation between the Grids as they were during the {\tt ESMF\_FieldRegridStore()} call.  
!   So if the coordinates at the stagger location in the Grids change, a new call to {\tt ESMF\_FieldRegridStore()} 
!   is necessary to compute the interpolation between that new set of coordinates.
!
!   It is erroneous to specify the identical Field object for {\tt srcField} and
!   {\tt dstField} arguments.
!
!   This call is {\em collective} across the current VM.
!
!   \begin{description}
!   \item [{[srcField]}]
!     {\tt ESMF\_Field} with source data.
!   \item [{[dstField]}]
!     {\tt ESMF\_Field} with destination data.
!   \item [routehandle]
!     Handle to the precomputed Route.
!   \item [{[zeroflag]}]
!     If set to {\tt ESMF\_REGION\_TOTAL} {\em (default)} the total regions of
!     all DEs in {\tt dstField} will be initialized to zero before updating the 
!     elements with the results of the sparse matrix multiplication. If set to
!     {\tt ESMF\_REGION\_EMPTY} the elements in {\tt dstField} will not be
!     modified prior to the sparse matrix multiplication and results will be
!     added to the incoming element values. Setting {\tt zeroflag} to 
!     {\tt ESMF\_REGION\_SELECT} will only zero out those elements in the 
!     destination Array that will be updated by the sparse matrix
!     multiplication. See section \ref{opt:regionflag} for a complete list of
!     valid settings.
!   \item [{[checkflag]}]
!     If set to {\tt .TRUE.} the input Array pair will be checked for
!     consistency with the precomputed operation provided by {\tt routehandle}.
!     If set to {\tt .FALSE.} {\em (default)} only a very basic input check
!     will be performed, leaving many inconsistencies undetected. Set
!     {\tt checkflag} to {\tt .FALSE.} to achieve highest performance.
!   \item [{[rc]}]
!     Return code; equals {\tt ESMF\_SUCCESS} if there are no errors.
!   \end{description}
!EOP
        integer :: localrc
        type(ESMF_Array)     :: srcArray
        type(ESMF_Array)     :: dstArray

        ! Initialize return code; assume failure until success is certain
        localrc = ESMF_SUCCESS
        if (present(rc)) rc = ESMF_RC_NOT_IMPL

        ! Now we go through the painful process of extracting the data members
        ! that we need.
        call ESMF_FieldGet(srcField, array=srcArray, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

        call ESMF_FieldGet(dstField, array=dstArray, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

        call ESMF_ArraySMM(srcArray=srcArray, dstArray=dstArray, &
                   routehandle=routeHandle, zeroflag=zeroflag, &
                   checkflag=checkflag, rc=localrc)

        if (ESMF_LogMsgFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rc)) return

        if(present(rc)) rc = ESMF_SUCCESS

    end subroutine ESMF_FieldRegridRun
!------------------------------------------------------------------------------
#undef  ESMF_METHOD
#define ESMF_METHOD "ESMF_FieldRegridRelease"

!BOP
! !IROUTINE: ESMF_FieldRegridRelease - Free resources used by regrid object
!
! !INTERFACE:
      subroutine ESMF_FieldRegridRelease(routeHandle, rc)
!
! !ARGUMENTS:
      type(ESMF_RouteHandle), intent(inout)  :: routeHandle
      integer, intent(out), optional :: rc 
!
! !DESCRIPTION:
!     Free resources used by regrid objec
!
!     The arguments are:
!     \begin{description}
!     \item [routeHandle]
!           Handle carrying the sparse matrix
!     \item [{[rc]}]
!           Return code; equals {\tt ESMF\_SUCCESS} if there are no errors.
!     \end{description}
!
!EOP
        integer :: localrc

        call ESMF_RouteHandleRelease(routehandle=routeHandle, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

        if(present(rc)) rc = ESMF_SUCCESS

    end subroutine ESMF_FieldRegridRelease
!------------------------------------------------------------------------------
#undef  ESMF_METHOD
#define ESMF_METHOD "ESMF_FieldRegridStore"

!BOP
! !IROUTINE: ESMF_FieldRegridStore - Store regrid and return RouteHandle and weights
!
! !INTERFACE:
  !   Private name; call using ESMF_FieldRegridStore()
      subroutine ESMF_FieldRegridStore(srcField, srcMaskValues,        &
                                       dstField, dstMaskValues,        &
                                       unmappedDstAction,              &
                                       routeHandle, indicies, weights, & 
                                       regridMethod, regridConserve,   &
                                       regridScheme, rc)
!
! !RETURN VALUE:
!      
! !ARGUMENTS:
      type(ESMF_Field), intent(inout)                 :: srcField
      integer(ESMF_KIND_I4), intent(in), optional     :: srcMaskValues(:)
      type(ESMF_Field), intent(inout)                 :: dstField
      integer(ESMF_KIND_I4), intent(in), optional     :: dstMaskValues(:)
      type(ESMF_UnmappedAction), intent(in), optional :: unmappedDstAction
      type(ESMF_RouteHandle), intent(inout), optional :: routeHandle
      integer(ESMF_KIND_I4), pointer, optional        :: indicies(:,:)
      real(ESMF_KIND_R8), pointer, optional           :: weights(:)
      type(ESMF_RegridMethod), intent(in), optional   :: regridMethod
      type(ESMF_RegridConserve), intent(in), optional :: regridConserve
      integer, intent(in), optional                   :: regridScheme
      integer, intent(out), optional                  :: rc 
!
! !DESCRIPTION:
!       Creates a sparse matrix operation (stored in {\tt routeHandle}) that contains the calculations and 
!       communications necessary to interpolate from {\tt srcField} to {\tt dstField}. The routeHandle can then be used in the call
!       {\tt ESMF\_FieldRegrid()} to interpolate between the Fields. The user may also get the
!       interpolation matrix in sparse matrix form via the optional arguments {\tt indices} and {\tt weights}. 
!       
!       The routeHandle generated by this call is based just on the coordinates at the 
!       Fields' stagger locations in the Grids contained in the Fields.  
!       If those coordinates don't change the routehandle can be used repeatedly to interpolate from the source Field to the destination Field. 
!       This is true even if the data in the Fields changes. The routeHandle may also be used to interpolate between any source and 
!       destination Field which are created on the same stagger location and Grid as the original Fields.        
!
!       When it's no longer needed the routeHandle should be destroyed by using {\tt ESMF\_FieldRegridRelease()} to free the memory it's using. 
!
!     The arguments are:
!     \begin{description}
!     \item [srcField]
!           Source Field.
!     \item [{[srcMaskValues]}]
!           List of values that indicate a source point should be masked out. 
!           If not specified, no masking will occur. 
!     \item [dstField]
!           Destination Field.
!     \item [{[dstMaskValues]}]
!           List of values that indicate a destination point should be masked out. 
!           If not specified, no masking will occur.
!     \item [{[unmappedDstAction]}]
!           Specifies what should happen if there are destination points that
!           can't be mapped to a source cell. Options are 
!           {\tt ESMF\_UNMAPPEDACTION\_ERROR} or 
!           {\tt ESMF\_UNMAPPEDACTION\_IGNORE}. If not specified, defaults 
!           to {\tt ESMF\_UNMAPPEDACTION\_ERROR}. 
!     \item [{[routeHandle]}]
!           The handle that implements the regrid and that can be used in later 
!           {\tt ESMF\_FieldRegrid}.
!     \item [{[indices]}] 
!           The indices for the sparse matrix.
!     \item [{[weights]}] 
!           The weights for the sparse matrix.
!     \item [{[regridMethod]}]
!           The type of regrid. Options are 
!           {\tt ESMF\_REGRID\_METHOD\_BILINEAR} or 
!           {\tt ESMF\_REGRID\_METHOD\_PATCH}. If not specified, defaults 
!           to {\tt ESMF\_REGRID\_METHOD\_BILINEAR}.
!     \item [{[regridConserve]}]
!           The mass conservation correction, options are 
!           {\tt ESMF\_REGRID\_CONSERVE\_OFF} or 
!           {\tt ESMF\_REGRID\_CONSERVE\_ON}. If not specified, defaults 
!           to {\tt ESMF\_REGRID\_CONSERVE\_OFF}. 
!     \item [{[regridScheme]}]
!           Whether to convert to spherical coordinates 
!           ({\tt ESMF\_REGRID\_SCHEME\_FULL3D}), 
!           or to leave in native coordinates 
!           ({\tt ESMF\_REGRID\_SCHEME\_NATIVE}). 
!     \item [{[rc]}]
!           Return code; equals {\tt ESMF\_SUCCESS} if there are no errors.
!     \end{description}
!
!EOP
        integer :: localrc
        integer              :: lregridScheme
        type(ESMF_RegridMethod) :: lregridMethod
        type(ESMF_RegridConserve) :: lregridConserve
        integer              :: isSphere
        type(ESMF_GeomType)  :: srcgeomtype
        type(ESMF_GeomType)  :: dstgeomtype

        type(ESMF_Grid)      :: srcGrid
        type(ESMF_Grid)      :: dstGrid
        type(ESMF_Array)     :: srcArray
        type(ESMF_Array)     :: dstArray
        type(ESMF_VM)        :: vm
        type(ESMF_Mesh)      :: srcMesh
        type(ESMF_Mesh)      :: dstMesh
        type(ESMF_StaggerLoc) :: srcStaggerLoc,dstStaggerLoc

        ! Initialize return code; assume failure until success is certain
        localrc = ESMF_SUCCESS
        if (present(rc)) rc = ESMF_RC_NOT_IMPL


        ! global vm for now
        call ESMF_VMGetGlobal(vm, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

        ! Now we go through the painful process of extracting the data members
        ! that we need.
        call ESMF_FieldGet(srcField, geomtype=srcgeomtype, array=srcArray, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

        call ESMF_FieldGet(dstField, geomtype=dstgeomtype, array=dstArray, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

        ! Handle optional method argument
        if (present(regridMethod)) then
           lregridMethod=regridMethod
        else     
           lregridMethod=ESMF_REGRID_METHOD_BILINEAR
        endif

        ! Handle optional conserve argument
        if (present(regridConserve)) then
           lregridConserve=regridConserve
        else     
           lregridConserve=ESMF_REGRID_CONSERVE_OFF
        endif

        ! Will eventually determine scheme either as a parameter or from properties
        ! of the source grid
        if (present(regridScheme)) then
          lregridScheme = regridScheme
        else
          lregridScheme = ESMF_REGRID_SCHEME_NATIVE
        endif


        ! If grids, then convert to a mesh to do the regridding
        if (srcgeomtype .eq. ESMF_GEOMTYPE_GRID) then
          call ESMF_FieldGet(srcField, grid=srcGrid, &
                 staggerloc=srcStaggerloc, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return

          isSphere = 0
          if (lregridScheme .eq. ESMF_REGRID_SCHEME_FULL3D) isSphere = 1

          ! check grid
          call checkGrid(srcGrid,srcStaggerloc,rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

          ! Convert Grid to Mesh
          srcMesh = ESMF_GridToMesh(srcGrid, srcStaggerLoc, isSphere, &
                      srcMaskValues, lregridConserve, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return

        else
          call ESMF_FieldGet(srcField, mesh=srcMesh, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
        endif

        if (dstgeomtype .eq. ESMF_GEOMTYPE_GRID) then
          call ESMF_FieldGet(dstField, grid=dstGrid, &
                 staggerloc=dstStaggerloc, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return

          isSphere = 0
          if (lregridScheme .eq. ESMF_REGRID_SCHEME_FULL3D) isSphere = 1

          ! check grid
          call checkGrid(dstGrid,dstStaggerloc,rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

          ! Convert Grid to Mesh
          dstMesh = ESMF_GridToMesh(dstGrid, dstStaggerLoc, isSphere, &
                      dstMaskValues, lregridConserve, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
        else
          call ESMF_FieldGet(dstField, mesh=dstMesh, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
        endif

        ! At this point, we have the meshes, so we are ready to call
        ! the 'mesh only' interface of the regrid.

        ! call into the Regrid mesh interface
        call ESMF_RegridStore(srcMesh, srcArray, dstMesh, dstArray, &
              lregridMethod, lregridConserve, lregridScheme, &
              unmappedDstAction, routeHandle, &
              indicies, weights, localrc)
        if (ESMF_LogMsgFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rc)) return

        ! destroy Meshes, if they were created here
        if (srcgeomtype .ne. ESMF_GEOMTYPE_MESH) then
        call ESMF_MeshDestroy(srcMesh,rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rc)) return
        endif

        if (dstgeomtype .ne. ESMF_GEOMTYPE_MESH) then
        call ESMF_MeshDestroy(dstMesh,rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rc)) return
        endif

        if(present(rc)) rc = ESMF_SUCCESS

    end subroutine ESMF_FieldRegridStore

!------------------------------------------------------------------------------

#undef  ESMF_METHOD
#define ESMF_METHOD "ESMF_FieldRegridGetIwts"

!BOPI
! !IROUTINE: ESMF_FieldRegridGetIwts - Get the integration weights
!
! !INTERFACE:
  !   Private name; call using ESMF_FieldRegridGetIwts()
      subroutine ESMF_FieldRegridGetIwts(Field, Iwts, MaskValues, regridScheme, rc)
!
! !RETURN VALUE:
!      
! !ARGUMENTS:
      type(ESMF_Field), intent(inout)                    :: Field
      type(ESMF_Field), intent(inout)                 :: Iwts
      integer(ESMF_KIND_I4), intent(in), optional     :: MaskValues(:)
      integer, intent(in), optional                   :: regridScheme
      integer, intent(out), optional                  :: rc 
!
! !DESCRIPTION:
!
!     The arguments are:
!     \begin{description}
!     \item [Field]
!           The Field.
!     \item [{[regridScheme]}]
!           Whether to convert to spherical coordinates 
!           ({\tt ESMF\_REGRID\_SCHEME\_FULL3D}), 
!           or to leave in native coordinates 
!           ({\tt ESMF\_REGRID\_SCHEME\_NATIVE}). 
!     \item [{[rc]}]
!           Return code; equals {\tt ESMF\_SUCCESS} if there are no errors.
!     \end{description}
!
!EOPI
        integer :: localrc
        integer              :: isSphere
        integer              :: lregridScheme
        type(ESMF_GeomType)  :: geomtype

        type(ESMF_Grid)      :: Grid
        type(ESMF_Array)     :: Array
        type(ESMF_VM)        :: vm
        type(ESMF_Mesh)      :: Mesh
        type(ESMF_StaggerLoc) :: staggerLoc

        ! Initialize return code; assume failure until success is certain
        localrc = ESMF_SUCCESS
        if (present(rc)) rc = ESMF_RC_NOT_IMPL

        ! global vm for now
        call ESMF_VMGetGlobal(vm, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

  !  check Field and Iwts to make sure they are from the same grid

        ! Now we go through the painful process of extracting the data members
        ! that we need.
        call ESMF_FieldGet(Iwts, geomtype=geomtype, array=Array, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

        ! Will eventually determine scheme either as a parameter or from properties
        ! of the source grid
        if (present(regridScheme)) then
          lregridScheme = regridScheme
        else
          lregridScheme = ESMF_REGRID_SCHEME_NATIVE
        endif

        ! If grids, then convert to a mesh to do the regridding
        if (geomtype .eq. ESMF_GEOMTYPE_GRID) then
          call ESMF_FieldGet(Iwts, grid=Grid, &
                 staggerloc=staggerLoc, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return

          isSphere = 0
          if (lregridScheme .eq. ESMF_REGRID_SCHEME_FULL3D) isSphere = 1

          ! check grid
          call checkGrid(Grid,staggerloc,rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
          ESMF_CONTEXT, rcToReturn=rc)) return

          ! Convert Grid to Mesh
          Mesh = ESMF_GridToMesh(Grid, staggerLoc, isSphere, &
                      MaskValues, ESMF_REGRID_CONSERVE_ON, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return

        else
          call ESMF_FieldGet(Iwts, mesh=Mesh, rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
        endif

        ! call into the Regrid GetIwts interface
        call ESMF_RegridGetIwts(Grid, Mesh, Array, staggerLoc, lregridScheme, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rc)) return

        ! destroy Mesh, if they were created here
        if (geomtype .ne. ESMF_GEOMTYPE_MESH) then
        call ESMF_MeshDestroy(Mesh,rc=localrc)
          if (ESMF_LogMsgFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rc)) return
        endif

        if(present(rc)) rc = ESMF_SUCCESS

    end subroutine ESMF_FieldRegridGetIwts

!------------------------------------------------------------------------------

    ! Small subroutine to make sure that Grid doesn't
    ! contain some of the properties that aren't currently
    ! allowed in regridding
    subroutine checkGrid(grid,staggerloc,rc)
        type (ESMF_Grid) :: grid
        type(ESMF_StaggerLoc) :: staggerloc
        integer, intent(out), optional :: rc
        type(ESMF_GridDecompType) :: decompType
        integer :: localDECount, lDE, ec(ESMF_MAXDIM)
        integer :: localrc, i, dimCount

        if (present(rc)) rc = ESMF_RC_NOT_IMPL

        ! Make sure Grid isn't arbitrarily distributed
        call ESMF_GridGetDecompType(grid, decompType, rc=localrc)
        if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return

       ! Error if decompType is ARBITRARY
       if (decompType .eq. ESMF_GRID_ARBITRARY) then
             call ESMF_LogMsgSetError(ESMF_RC_ARG_BAD, & 
                 "- can't currently regrid an arbitrarily distributed Grid", & 
                 ESMF_CONTEXT, rc) 
              return
       endif        

       ! Make sure Grid doesn't contain width 1 DEs
       call ESMF_GridGet(grid,localDECount=localDECount, dimCount=dimCount, &
              rc=localrc)
       if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
       
       ! loop through checking DEs
       do lDE=0,localDECount-1
           
           ! Get bounds of DE
           call ESMF_GridGet(grid,staggerloc=staggerloc, localDE=lDE, &
                  exclusivecount=ec,rc=localrc)
           if (ESMF_LogMsgFoundError(localrc, ESMF_ERR_PASSTHRU, &
               ESMF_CONTEXT, rcToReturn=rc)) return

           ! loop and make sure they aren't too small in any dimension
           do i=1,dimCount
              if (ec(i) .lt. 2) then
                 call ESMF_LogMsgSetError(ESMF_RC_ARG_BAD, & 
              "- can't currently regrid a grid that contains a DE of width less than 2", & 
                 ESMF_CONTEXT, rc) 
              return
              endif
           enddo
       enddo

       if(present(rc)) rc = ESMF_SUCCESS
   end subroutine checkGrid

!------------------------------------------------------------------------------

end module ESMF_FieldRegridMod
