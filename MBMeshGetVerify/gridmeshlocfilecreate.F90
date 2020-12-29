!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! $Id$
!
! Earth System Modeling Framework
! Copyright 2002-2020, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!!-------------------------------------------------------------------------------------

!==============================================================================
#define ESMF_FILENAME "ESMF_RegridWeightGen.F90"
!==============================================================================
!
!     ESMF RegridWeightGen module
module ESMF_RegridWeightGenMod
!
!==============================================================================
!
! This file contains the API wrapper for the ESMF_RegridWeightGen application
!
!------------------------------------------------------------------------------
! INCLUDES
#include "ESMF.h"

!------------------------------------------------------------------------------
! !USES:
  use ESMF_UtilTypesMod
  use ESMF_VMMod
  use ESMF_LogErrMod
  use ESMF_ArraySpecMod
  use ESMF_ArrayMod
  use ESMF_DistGridMod
  use ESMF_GridMod
  use ESMF_GridUtilMod
  use ESMF_StaggerLocMod
  use ESMF_MeshMod
  use ESMF_FieldMod
  use ESMF_FieldCreateMod
  use ESMF_FieldGetMod
  use ESMF_FieldGatherMod
  use ESMF_FieldSMMMod
  use ESMF_FieldRegridMod
  use ESMF_IOScripMod
  use ESMF_IOGridspecMod
  use ESMF_IOUGridMod
  use ESMF_IOGridmosaicMod
  use ESMF_IOFileTypeCheckMod
  use ESMF_RHandleMod
  use ESMF_LocStreamMod

  implicit none

!
! !PUBLIC MEMBER FUNCTIONS:
!
! - ESMF-public methods:

  public ESMF_RegridWeightGen

! -------------------------- ESMF-public method -------------------------------
!BOPI
! !IROUTINE: ESMF_RegridWeightGen -- Generic interface

! !INTERFACE:
interface ESMF_RegridWeightGen

! !PRIVATE MEMBER FUNCTIONS:
!
      module procedure ESMF_RegridWeightGenFile
      module procedure ESMF_RegridWeightGenDG
! !DESCRIPTION:
! This interface provides a single entry point for the various
!  types of {\tt ESMF\_RegridWeightGen} subroutines
!EOPI
end interface

!------------------------------------------------------------------------------
contains

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!#define DOBENCHMARK

! -------------------------- ESMF-public method -------------------------------
#undef  ESMF_METHOD
#define ESMF_METHOD "ESMF_RegridWeightGenFile"

!BOP
! !IROUTINE: ESMF_RegridWeightGen - Generate regrid weight file from grid files
! \label{api:esmf_regridweightgenfile}
! !INTERFACE:
  ! Private name; call using ESMF_RegridWeightGen()
  subroutine ESMF_RegridWeightGenFile(srcFile, dstFile, keywordEnforcer, &
    weightFile, rhFile, regridmethod, polemethod, regridPoleNPnts, lineType, normType, &
    extrapMethod, extrapNumSrcPnts, extrapDistExponent, extrapNumLevels, &
    unmappedaction, ignoreDegenerate, srcFileType, dstFileType, &
    srcRegionalFlag, dstRegionalFlag, srcMeshname, dstMeshname,  &
    srcMissingvalueFlag, srcMissingvalueVar, &
    dstMissingvalueFlag, dstMissingvalueVar, &
    useSrcCoordFlag, srcCoordinateVars, &
    useDstCoordFlag, dstCoordinateVars, &
    useSrcCornerFlag, useDstCornerFlag, &
    useUserAreaFlag, largefileFlag, &
    netcdf4fileFlag, weightOnlyFlag, &
    tileFilePath, &
    verboseFlag, rc)

! !ARGUMENTS:

  character(len=*),             intent(in)            :: srcFile
  character(len=*),             intent(in)            :: dstFile
type(ESMF_KeywordEnforcer), optional:: keywordEnforcer ! must use keywords below
  character(len=*),             intent(in),  optional :: weightFile
  character(len=*),             intent(in),  optional :: rhFile
  type(ESMF_RegridMethod_Flag), intent(in),  optional :: regridmethod
  type(ESMF_PoleMethod_Flag),   intent(in),  optional :: polemethod
  integer,                      intent(in),  optional :: regridPoleNPnts
  type(ESMF_LineType_Flag),     intent(in),  optional :: lineType
  type(ESMF_NormType_Flag),     intent(in),  optional :: normType
  type(ESMF_ExtrapMethod_Flag),   intent(in),    optional :: extrapMethod
  integer,                        intent(in),    optional :: extrapNumSrcPnts
  real,                           intent(in),    optional :: extrapDistExponent
  integer,                      intent(in), optional :: extrapNumLevels
  type(ESMF_UnmappedAction_Flag),intent(in), optional :: unmappedaction
  logical,                      intent(in),  optional :: ignoreDegenerate
  type(ESMF_FileFormat_Flag),   intent(in),  optional :: srcFileType
  type(ESMF_FileFormat_Flag),   intent(in),  optional :: dstFileType
  logical,                      intent(in),  optional :: srcRegionalFlag
  logical,                      intent(in),  optional :: dstRegionalFlag
  character(len=*),             intent(in),  optional :: srcMeshname
  character(len=*),             intent(in),  optional :: dstMeshname
  logical,                      intent(in),  optional :: srcMissingValueFlag
  character(len=*),             intent(in),  optional :: srcMissingValueVar
  logical,                      intent(in),  optional :: dstMissingValueFlag
  character(len=*),             intent(in),  optional :: dstMissingValueVar
  logical,                      intent(in),  optional :: useSrcCoordFlag
  character(len=*),             intent(in),  optional :: srcCoordinateVars(:)
  logical,                      intent(in),  optional :: useDstCoordFlag
  character(len=*),             intent(in),  optional :: dstCoordinateVars(:)
  logical,                      intent(in),  optional :: useSrcCornerFlag
  logical,                      intent(in),  optional :: useDstCornerFlag
  logical,                      intent(in),  optional :: useUserAreaFlag
  logical,                      intent(in),  optional :: largefileFlag
  logical,                      intent(in),  optional :: netcdf4fileFlag
  logical,                      intent(in),  optional :: weightOnlyFlag
  logical,                      intent(in),  optional :: verboseFlag
  character(len=*),             intent(in),  optional :: tileFilePath
  integer,                      intent(out), optional :: rc

! !DESCRIPTION:
! This subroutine provides the same function as the {\tt ESMF\_RegridWeightGen} application
! described in Section~\ref{sec:ESMF_RegridWeightGen}.  It takes two grid files in NetCDF format and writes out an
! interpolation weight file also in NetCDF format.  The interpolation weights can be generated with the
! bilinear~(\ref{sec:interpolation:bilinear}), higher-order patch~(\ref{sec:interpolation:patch}),
! or first order conservative~(\ref{sec:interpolation:conserve}) methods.  The grid files can be in
! one of the following four formats:
! \begin{itemize}
! \item The SCRIP format~(\ref{sec:fileformat:scrip})
! \item The native ESMF format for an unstructured grid~(\ref{sec:fileformat:esmf})
! \item The CF Convention Single Tile File format~(\ref{sec:fileformat:gridspec})
! \item The proposed CF Unstructured grid (UGRID) format~(\ref{sec:fileformat:ugrid})
! \item The GRIDSPEC Mosaic File format~(\ref{sec:fileformat:mosaic})
! \end{itemize}
! \smallskip
! The weight file is created in SCRIP format~(\ref{sec:weightfileformat}).
! The optional arguments allow users to specify various options to control the regrid operation,
! such as which pole option to use,
! whether to use user-specified area in the conservative regridding, or whether ESMF should generate masks using a given
! variable's missing value.  There are also optional arguments specific to a certain type of the grid file.
! All the optional arguments are similar to the command line arguments for the {\tt ESMF\_RegridWeightGen}
! application~(\ref{sec:regridusage}). The acceptable values and the default value for the optional arguments
! are listed below.
!
! The arguments are:
!   \begin{description}
!   \item [srcFile]
!     The source grid file name.
!   \item [dstFile]
!     The destination grid file name.
!   \item [weightFile]
!     The interpolation weight file name.
!   \item [{[rhFile]}]
!     The RouteHandle file name.
!   \item [{[regridmethod]}]
!     The type of interpolation. Please see Section~\ref{opt:regridmethod}
!     for a list of valid options. If not specified, defaults to
!     {\tt ESMF\_REGRIDMETHOD\_BILINEAR}.
!   \item [{[polemethod]}]
!     A flag to indicate which type of artificial pole
!     to construct on the source Grid for regridding. Please see
!     Section~\ref{const:polemethod} for a list of valid options.
!     The default value varies depending on the regridding method and the grid type and format.
!   \item [{[regridPoleNPnts]}]
!     If {\tt polemethod} is set to {\tt ESMF\_POLEMETHOD\_NPNTAVG}, this argument is required to
!     specify how many points should be averaged over at the pole.
!   \item [{[lineType]}]
!           This argument controls the path of the line which connects two points on a sphere surface. This in
!           turn controls the path along which distances are calculated and the shape of the edges that make
!           up a cell. Both of these quantities can influence how interpolation weights are calculated.
!           As would be expected, this argument is only applicable when {\tt srcField} and {\tt dstField} are
!           built on grids which lie on the surface of a sphere. Section~\ref{opt:lineType} shows a
!           list of valid options for this argument. If not specified, the default depends on the
!           regrid method. Section~\ref{opt:lineType} has the defaults by line type. Figure~\ref{line_type_support} shows
!           which line types are supported for each regrid method as well as showing the default line type by regrid method.
!     \item [{[normType]}]
!           This argument controls the type of normalization used when generating conservative weights. This option
!           only applies to weights generated with {\tt regridmethod=ESMF\_REGRIDMETHOD\_CONSERVE}. Please see
!           Section~\ref{opt:normType} for a
!           list of valid options. If not specified {\tt normType} defaults to {\tt ESMF\_NORMTYPE\_DSTAREA}.
!     \item [{[extrapMethod]}]
!           The type of extrapolation. Please see Section~\ref{opt:extrapmethod}
!           for a list of valid options. If not specified, defaults to
!           {\tt ESMF\_EXTRAPMETHOD\_NONE}.
!     \item [{[extrapNumSrcPnts]}]
!           The number of source points to use for the extrapolation methods that use more than one source point
!           (e.g. {\tt ESMF\_EXTRAPMETHOD\_NEAREST\_IDAVG}). If not specified, defaults to 8.
!     \item [{[extrapDistExponent]}]
!           The exponent to raise the distance to when calculating weights for
!           the {\tt ESMF\_EXTRAPMETHOD\_NEAREST\_IDAVG} extrapolation method. A higher value reduces the influence
!           of more distant points. If not specified, defaults to 2.0.
!     \item [{[unmappedaction]}]
!           Specifies what should happen if there are destination points that
!           can't be mapped to a source cell. Please see Section~\ref{const:unmappedaction} for a
!           list of valid options. If not specified, {\tt unmappedaction} defaults to {\tt ESMF\_UNMAPPEDACTION\_ERROR}.
!     \item [{[ignoreDegenerate]}]
!           Ignore degenerate cells when checking the input Grids or Meshes for errors. If this is set to true, then the
!           regridding proceeds, but degenerate cells will be skipped. If set to false, a degenerate cell produces an error.
!           If not specified, {\tt ignoreDegenerate} defaults to false.
!   \item [{[srcFileType]}]
!     The file format of the source grid. Please see
!     Section~\ref{const:fileformatflag} for a list of valid options. 
!      If not specifed, the program will determine the file format automatically.
!   \item [{[dstFileType]}]
!     The file format of the destination grid.  Please see Section~\ref{const:fileformatflag} for a list of valid options.
!      If not specifed, the program will determine the file format automatically.
!   \item [{[srcRegionalFlag]}]
!     If .TRUE., the source grid is a regional grid, otherwise,
!     it is a global grid.  The default value is .FALSE.
!   \item [{[dstRegionalFlag]}]
!     If .TRUE., the destination grid is a regional grid, otherwise,
!     it is a global grid.  The default value is .FALSE.
!   \item [{[srcMeshname]}]
!     If the source file is in UGRID format, this argument is required
!     to define the dummy variable name in the grid file that contains the
!     mesh topology info.
!   \item [{[dstMeshname]}]
!     If the destination file is in UGRID format, this argument is required
!     to define the dummy variable name in the grid file that contains the
!     mesh topology info.
!   \item [{[srcMissingValueFlag]}]
!     If .TRUE., the source grid mask will be constructed using the missing
!     values of the variable defined in {\tt srcMissingValueVar}. This flag is
!     only used for the grid defined in  the GRIDSPEC or the UGRID file formats.
!     The default value is .FALSE..
!   \item [{[srcMissingValueVar]}]
!     If {\tt srcMissingValueFlag} is .TRUE., the argument is required to define
!     the variable name whose missing values will be used to construct the grid
!     mask.  It is only used for the grid defined in  the GRIDSPEC or the UGRID
!     file formats.
!   \item [{[dstMissingValueFlag]}]
!     If .TRUE., the destination grid mask will be constructed using the missing
!     values of the variable defined in {\tt dstMissingValueVar}. This flag is
!     only used for the grid defined in  the GRIDSPEC or the UGRID file formats.
!     The default value is .FALSE..
!   \item [{[dstMissingValueVar]}]
!     If {\tt dstMissingValueFlag} is .TRUE., the argument is required to define
!     the variable name whose missing values will be used to construct the grid
!     mask.  It is only used for the grid defined in  the GRIDSPEC or the UGRID
!     file formats.
!   \item [{[useSrcCoordFlag]}]
!     If .TRUE., the coordinate variables defined in {\tt srcCoordinateVars} will
!     be used as the longitude and latitude variables for the source grid.
!     This flag is only used for the GRIDSPEC file format.  The default is .FALSE.
!   \item [{[srcCoordinateVars]}]
!     If {\tt useSrcCoordFlag} is .TRUE., this argument defines the longitude and
 !     latitude variables in the source grid file to be used for the regrid.
!     This argument is only used when the grid file is in GRIDSPEC format.
!     {\tt srcCoordinateVars} should be a array of 2 elements.
!   \item [{[useDstCoordFlag]}]
!     If .TRUE., the coordinate variables defined in {\tt dstCoordinateVars} will
!     be used as the longitude and latitude variables for the destination grid.
!     This flag is only used for the GRIDSPEC file format.  The default is .FALSE.
!   \item [{[dstCoordinateVars]}]
!     If {\tt useDstCoordFlag} is .TRUE., this argument defines the longitude and
!     latitude variables in the destination grid file to be used for the regrid.
!     This argument is only used when the grid file is in GRIDSPEC format.
!     {\tt dstCoordinateVars} should be a array of 2 elements.
!   \item [{[useSrcCornerFlag]}]
!     If {\tt useSrcCornerFlag} is .TRUE., the corner coordinates of the source file
!     will be used for regridding. Otherwise, the center coordinates will be us ed.
!     The default is .FALSE. The corner stagger is not supported for the SCRIP formatted input
!     grid or multi-tile GRIDSPEC MOSAIC input grid.
!   \item [{[useDstCornerFlag]}]
!     If {\tt useDstCornerFlag} is .TRUE., the corner coordinates of the destination file
!     will be used for regridding. Otherwise, the center coordinates will be used.
!     The default is .FALSE. The corner stagger is not supported for the SCRIP formatted input
!     grid or multi-tile GRIDSPEC MOSAIC input grid.
!   \item [{[useUserAreaFlag]}]
!     If .TRUE., the element area values defined in the grid files are used.
!     Only the SCRIP and ESMF format grid files have user specified areas. This flag
!     is only used for conservative regridding. The default is .FALSE..
!   \item [{[largefileFlag]}]
!     If .TRUE., the output weight file is in NetCDF 64bit offset format.
!     The default is .FALSE..
!   \item [{[netcdf4fileFlag]}]
!     If .TRUE., the output weight file is in NetCDF4 file format.
!     The default is .FALSE..
!   \item [{[weightOnlyFlag]}]
!     If .TRUE., the output weight file only contains factorList and factorIndexList.
!     The default is .FALSE..
!   \item [{[verboseFlag]}]
!     If .TRUE., it will print summary information about the regrid parameters,
!     default to .FALSE..
!   \item[{[tileFilePath]}]
!     Optional argument to define the path where the tile files reside. If it
!     is given, it overwrites the path defined in {\tt gridlocation} variable
!     in the mosaic file.
!   \item [{[rc]}]
!     Return code; equals {\tt ESMF\_SUCCESS} if there are no errors.
!   \end{description}
!EOP

    type(ESMF_RegridMethod_Flag) :: localRegridMethod
    type(ESMF_PoleMethod_Flag)   :: localPoleMethod
    type(ESMF_FileFormat_Flag)   :: localSrcFileType
    type(ESMF_FileFormat_Flag)   :: localDstFileType
    integer            :: localPoleNPnts
    logical            :: localUserAreaFlag
    logical            :: localLargefileFlag
    logical            :: localNetcdf4fileFlag
    logical            :: localWeightOnlyFlag
    logical            :: localVerboseFlag
    integer            :: localrc
    type(ESMF_VM)      :: vm
     integer            :: PetNo, PetCnt
    type(ESMF_Mesh)    :: srcMesh, dstMesh
    type(ESMF_Grid)    :: srcGrid, dstGrid
    type(ESMF_Field)   :: srcField, dstField
    type(ESMF_Field)   :: srcFracField, dstFracField
    integer(ESMF_KIND_I4), pointer:: factorIndexList(:,:)
    real(ESMF_KIND_R8), pointer :: factorList(:)
    integer(ESMF_KIND_I4) :: maskvals(1)
    integer            :: ind
    integer            :: srcdims(2), dstdims(2)
    integer            :: srcrank, dstrank
    logical            :: isConserve, srcIsSphere, dstIsSphere
    logical            :: addCorners
    logical            :: convertSrcToDual,convertDstToDual
    type(ESMF_MeshLoc) :: meshloc
    logical            :: srcIsReg, dstIsReg
    logical            :: srcIsMosaic, dstIsMosaic
    logical            :: srcIsRegional, dstIsRegional, typeSetFlag
    character(len=256) :: methodStr
    real(ESMF_KIND_R8), pointer :: srcArea(:)
    real(ESMF_KIND_R8), pointer :: dstArea(:)
    real(ESMF_KIND_R8), pointer :: dstFrac(:), srcFrac(:)
    integer            :: regridScheme
    integer            :: i, bigFac, xpets, ypets, xpart, ypart, xdim, ydim
    logical            :: wasCompacted
    integer(ESMF_KIND_I4), pointer:: compactedFactorIndexList(:,:)
    real(ESMF_KIND_R8), pointer :: compactedFactorList(:)
    type(ESMF_UnmappedAction_Flag) :: localUnmappedaction
    logical            :: srcMissingValue, dstMissingValue
    character(len=256) :: argStr
    logical            :: useSrcCoordVar, useDstCoordVar
    logical            :: useSrcMask, useDstMask
    logical            :: useSrcCorner, useDstCorner
    integer            :: commandbuf(6)
    type(ESMF_RouteHandle) :: rhandle
#ifdef DOBENCHMARK
    real(ESMF_KIND_R8) :: starttime, endtime, totaltime
    real(ESMF_KIND_R8), pointer :: sendbuf(:), recvbuf(:)
    real(ESMF_KIND_R8), pointer :: fptr1D(:), fptr2D(:,:)
#endif
    type(ESMF_LineType_Flag) :: localLineType
    type(ESMF_NormType_Flag):: localNormType
    logical            :: localIgnoreDegenerate
    logical            :: srcUseLocStream, dstUseLocStream
    type(ESMF_LocStream) :: srcLocStream, dstLocStream
    logical            :: usingCreepExtrap

#ifdef ESMF_NETCDF
    !------------------------------------------------------------------------
    ! get global vm information
    !
    call ESMF_VMGetCurrent(vm, rc=localrc)
    if (ESMF_LogFoundError(localrc, &
                           ESMF_ERR_PASSTHRU, &
                           ESMF_CONTEXT, rcToReturn=rc)) return

    ! set up local pet info
    call ESMF_VMGet(vm, localPet=PetNo, petCount=PetCnt, rc=localrc)
    if (ESMF_LogFoundError(localrc, &
                           ESMF_ERR_PASSTHRU, &
                           ESMF_CONTEXT, rcToReturn=rc)) return

    ! Default values
    useSrcMask = .TRUE.
    useDstMask = .TRUE.
    localRegridMethod = ESMF_REGRIDMETHOD_BILINEAR
    localSrcFileType = ESMF_FILEFORMAT_UNKNOWN
    localDstFileType = ESMF_FILEFORMAT_UNKNOWN
    localVerboseFlag = .false.
    srcIsRegional = .false.
    dstIsRegional = .false.
    srcMissingValue = .false.
    dstMissingValue = .false.
    localLargeFileFlag = .false.
    localNetcdf4FileFlag = .false.
    localWeightOnlyFlag = .false.
    localUserAreaflag = .false.
    useSrcCoordVar = .false.
    useDstCoordVar = .false.
    useSrcCorner = .false.
    useDstCorner = .false.
    localPoleNPnts = 0
    localIgnoreDegenerate = .false.
    srcUseLocStream = .false.
    dstUseLocStream = .false.
    srcIsMosaic = .false.
    dstIsMosaic = .false.
    srcIsReg = .false.
    dstIsReg = .false.

    if (.not. present(weightFile) .and. .not. present(rhFile)) then
      call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
        msg ="either a weightFile or a rhFile must be specified", &
        ESMF_CONTEXT, rcToReturn=rc)
      return
    endif

    if (present(regridMethod)) then
      localRegridMethod = regridMethod
    endif

    if (present(poleMethod)) then
         localPoleMethod = poleMethod
    else if ((localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE) .or. &
             (localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE_2ND)) then
       localPoleMethod = ESMF_POLEMETHOD_NONE
    else
       localPoleMethod = ESMF_POLEMETHOD_ALLAVG
    endif

    if (localPoleMethod == ESMF_POLEMETHOD_NPNTAVG) then
      if (present(regridPoleNPnts)) then
        localPoleNPnts = regridPoleNPnts
      else
        call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
          msg ="regridPoleNPnts argument is missing for ESMF_POLEMETHOD_NPNTAVG", &
          ESMF_CONTEXT, rcToReturn=rc)
        return
      endif
    endif

    if ((localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE) .and. &
             (localPoleMethod /= ESMF_POLEMETHOD_NONE)) then
        call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
          msg ="Conserve method only works with no pole", &
          ESMF_CONTEXT, rcToReturn=rc)
        return
    endif

    if ((localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE_2ND) .and. &
             (localPoleMethod /= ESMF_POLEMETHOD_NONE)) then
        call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
          msg ="Conserve method only works with no pole", &
          ESMF_CONTEXT, rcToReturn=rc)
        return
    endif

    if (present(srcFileType)) then
       localSrcFileType = srcFileType
    else
       call ESMF_FileTypeCheck(srcfile, localSrcFileType, rc=localrc)
       if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
    endif

    if (present(dstFileType)) then
       localDstFileType = dstFileType
    else
       call ESMF_FileTypeCheck(dstfile, localDstFileType, rc=localrc)
       if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
    endif


    ! Handle optional normType argument
    if (present(normType)) then
       localNormType=normType
    else
       localNormType=ESMF_NORMTYPE_DSTAREA
    endif


    ! Handle optional lineType argument
    if (present(lineType)) then
       localLineType=lineType
    else
       if (localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE) then
          localLineType=ESMF_LINETYPE_GREAT_CIRCLE
       else if (localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE_2ND) then
          localLineType=ESMF_LINETYPE_GREAT_CIRCLE
       else
          localLineType=ESMF_LINETYPE_CART
       endif
    endif

#if 0
    ! If the src grid type is UGRID, get the dummy variable name in the file
    if (localSrcFileType == ESMF_FILEFORMAT_UGRID) then
      if (.not. present(srcMeshname)) then
        call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
          msg ="srcMeshname is not given", &
          ESMF_CONTEXT, rcToReturn=rc)
        return
      endif
    endif

    ! If the dst grid type is UGRID, get the dummy variable name in the file
    if (localDstFileType == ESMF_FILEFORMAT_UGRID) then
      if (.not. present(dstMeshname)) then
        call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
          msg ="dstMeshname is not given", &
          ESMF_CONTEXT, rcToReturn=rc)
        return
      endif
    endif
#endif

    ! If the src grid type is UGRID or GRIDSPEC, check if the srcMissingvalueFlag is given
    if (localSrcFileType == ESMF_FILEFORMAT_UGRID .or. &
        localSrcFileType == ESMF_FILEFORMAT_GRIDSPEC) then
      if (present(srcMissingvalueFlag)) then
              srcMissingValue = srcMissingvalueFlag
            else
              srcMissingValue = .false.
      endif
      if (srcMissingValue) then
          if (.not. present(srcMissingvalueVar)) then
            call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
                  msg ="srcMissingvalueVar argument is not given", &
                  ESMF_CONTEXT, rcToReturn=rc)
            return
          endif
      endif
    endif

    ! If the dst grid type is UGRID or GRIDSPEC, check if the dstMissingvalueVar is given
    if (localDstFileType == ESMF_FILEFORMAT_UGRID .or. &
        localDstFileType == ESMF_FILEFORMAT_GRIDSPEC) then
      if (present(dstMissingvalueFlag)) then
          dstMissingValue = dstMissingvalueFlag
      else
          dstMissingValue = .false.
      endif
      if (dstMissingValue) then
          if (.not. present(dstMissingvalueVar)) then
            call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
                msg ="dstMissingvalueVar argument is not given", &
                ESMF_CONTEXT, rcToReturn=rc)
            return
          endif
      endif
    endif

    if (srcMissingValue .and. (localSrcFileType == ESMF_FILEFORMAT_SCRIP .or. &
        localSrcFileType == ESMF_FILEFORMAT_ESMFMESH)) then
      call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
              msg =" missingvalue is only supported for UGRID and GRIDSPEC", &
        ESMF_CONTEXT, rcToReturn=rc)
      return
    endif

!      if (srcMissingValue .and. localSrcFileType == ESMF_FILEFORMAT_UGRID .and. &
!          localRegridMethod /= ESMF_REGRIDMETHOD_CONSERVE) then
!          call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
!           msg = " missingvalue is only supported on the mesh elements", &
!            ESMF_CONTEXT, rcToReturn=rc)
!          return
!      endif

    if (dstMissingValue .and. (localDstFileType == ESMF_FILEFORMAT_SCRIP .or. &
        localDstFileType == ESMF_FILEFORMAT_ESMFMESH)) then
      call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
              msg = " missingvalue is only supported for UGRID and GRIDSPEC", &
        ESMF_CONTEXT, rcToReturn=rc)
      return
    endif

!      if (dstMissingValue .and. localDstFileType == ESMF_FILEFORMAT_UGRID .and. &
!          localRegridMethod /= ESMF_REGRIDMETHOD_CONSERVE) then
!          call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
!           msg = " missingvalue is only supported on the mesh elements", &
!           ESMF_CONTEXT, rcToReturn=rc)
!          return
!      endif

    if (present(unmappedaction)) then
      localUnmappedaction = unmappedaction
    else
      localUnmappedaction = ESMF_UNMAPPEDACTION_ERROR
    endif

    if (present(ignoreDegenerate)) then
      localIgnoreDegenerate = ignoreDegenerate
    endif

    if (present(srcRegionalFlag)) then
      srcIsRegional = srcRegionalFlag
    endif

    if (present(dstRegionalFlag)) then
      dstIsRegional = dstRegionalFlag
    endif

!    if (srcIsRegional .or. dstIsRegional) then
    if (srcIsRegional) then
      localPoleMethod = ESMF_POLEMETHOD_NONE
      localPoleNPnts = 0
    endif

    if (present(largefileFlag)) then
      localLargeFileFlag = largefileFlag
    endif

    if (present(netcdf4fileFlag)) then
      localNetcdf4FileFlag = netcdf4fileFlag
    endif

    if (present(weightOnlyFlag)) then
      localWeightOnlyFlag = weightOnlyFlag
    endif

    if (present(useUserAreaFlag)) then
       localUserAreaFlag = useUserAreaFlag
    endif

    if (present(useSrcCornerFlag)) then
       useSrcCorner = useSrcCornerFlag
    endif

    if (present(useDstCornerFlag)) then
       useDstCorner = useDstCornerFlag
    endif

    if (present(verboseFlag)) then
      localVerboseFlag = verboseFlag
    endif

    if ((useSrcCorner .and. localSrcFileType == ESMF_FILEFORMAT_MOSAIC) .or. &
       (useDstCorner .and. localDstFileType == ESMF_FILEFORMAT_MOSAIC)) then
      call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
              msg = " Only Center Stagger is supported for the multi-tile GRIDSPEC MOSAIC grid", &
              ESMF_CONTEXT, rcToReturn=rc)
      return
    endif

#if 0
    if ((localSrcFileType == ESMF_FILEFORMAT_MOSAIC .or. &
        localDstFileType == ESMF_FILEFORMAT_MOSAIC) .and. &
        .not. localWeightOnlyFlag) then
      call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
              msg = " If one of the grids is in GRIDSPEC MOSAIC format, the WeightOnlyFlag has to be TRUE", &
        ESMF_CONTEXT, rcToReturn=rc)
      return
    endif
#endif

    ! user area only needed for conservative regridding
    if (localUserAreaFlag .and. .not. ((localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE) .or. &
         (localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE_2ND))) then
       call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
            msg = " user defined area is only used for the conservative regridding", &
            ESMF_CONTEXT, rcToReturn=rc)
       return
    endif

    if (localUserAreaFlag .and. (localSrcFileType /= ESMF_FILEFORMAT_SCRIP .and. &
              localSrcFileType /= ESMF_FILEFORMAT_ESMFMESH) .and. &
              (localDstFileType /= ESMF_FILEFORMAT_SCRIP .and. &
              localDstFileType /= ESMF_FILEFORMAT_ESMFMESH)) then
      call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
         msg = "user defined areas is supported only when the source or dest grid is in SCRIP of ESMF format", &
         ESMF_CONTEXT, rcToReturn=rc)
      return
    endif

    ! --src_coordinates, --dst_coordinates for GRIDSPEC file if there are multiple
    ! coordinate variables
    if (localsrcFileType == ESMF_FILEFORMAT_GRIDSPEC) then
      if (present(useSrcCoordFlag)) then
        useSrcCoordVar = useSrcCoordFlag
      else
        useSrcCoordVar = .false.
      endif
      if (useSrcCoordVar) then
        if (.not. present(srcCoordinateVars)) then
          call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
            msg = "srcCoordinateVars argument is not given.", &
            ESMF_CONTEXT, rcToReturn=rc)
          return
        endif
      endif
    endif

    if (localdstFileType == ESMF_FILEFORMAT_GRIDSPEC) then
      if (present(useDstCoordFlag)) then
        useDstCoordVar = useDstCoordFlag
      else
        useDstCoordVar = .false.
      endif
      if (useDstCoordVar) then
        if (.not. present(dstCoordinateVars)) then
          call ESMF_LogSetError(rcToCheck=ESMF_RC_ARG_WRONG, &
            msg = "dstCoordinateVars argument is not given.", &
            ESMF_CONTEXT, rcToReturn=rc)
          return
        endif
      endif
    endif

    ! Use LocStream if the source file format is SCRIP and the regridmethod is nearest-neighbor
    if ((localSrcFileType /= ESMF_FILEFORMAT_GRIDSPEC .and. &
         localSrcFileType /= ESMF_FILEFORMAT_TILE .and. &
         localSrcFileType /= ESMF_FILEFORMAT_MOSAIC ) .and. &
        (localRegridMethod == ESMF_REGRIDMETHOD_NEAREST_STOD .or. &
        localRegridMethod == ESMF_REGRIDMETHOD_NEAREST_DTOS)) then
        srcUseLocStream = .TRUE.
    endif


    ! Check if we're using creep fill extrap
    usingCreepExtrap=.false.
    if (present(extrapMethod)) then
       if (extrapMethod == ESMF_EXTRAPMETHOD_CREEP) usingCreepExtrap=.true.
       if (extrapMethod == ESMF_EXTRAPMETHOD_CREEP_NRST_D) usingCreepExtrap=.true.
    endif

    ! Use LocStream if the dest file format is SCRIP and the regridmethod is non-conservative
    ! and we aren't using creep fill extrapolation
    if ((localDstFileType /= ESMF_FILEFORMAT_GRIDSPEC .and. &
         localDstFileType /= ESMF_FILEFORMAT_TILE .and. &
         localDstFileType /= ESMF_FILEFORMAT_MOSAIC) .and. &
        (localRegridMethod /= ESMF_REGRIDMETHOD_CONSERVE) .and. &
        (localRegridMethod /= ESMF_REGRIDMETHOD_CONSERVE_2ND) .and. &
        .not. usingCreepExtrap) then
        dstUseLocStream = .TRUE.
    endif

    ! Only set useSrcMask to false if srcMissingvalue is not given and the file type is
    ! either GRIDSPEC or UGRID, same for useDstMask
    if ((.not. srcMissingvalue) .and. (localSrcFileType == ESMF_FILEFORMAT_GRIDSPEC .or. &
         localSrcFileType == ESMF_FILEFORMAT_MOSAIC .or. &
         localSrcFileType == ESMF_FILEFORMAT_TILE)) &
      useSrcMask = .false.

    if ((.not. dstMissingvalue) .and. (localDstFileType == ESMF_FILEFORMAT_GRIDSPEC .or. &
         localDstFileType == ESMF_FILEFORMAT_MOSAIC .or. &
         localSrcFileType == ESMF_FILEFORMAT_TILE)) &
      useDstMask = .false.

    ! Should I have only PetNO=0 to open the file and find out the size?
    if (PetNo == 0) then
      if (localSrcFileType == ESMF_FILEFORMAT_SCRIP) then
        call ESMF_ScripInq(srcfile, grid_rank= srcrank, grid_dims=srcdims, rc=localrc)
        if (localVerboseFlag .and. localrc /= ESMF_SUCCESS) then
          write(*,*)
                print *, 'ERROR: Unable to get dimension information from:', srcfile
        endif
        if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
        if (srcrank == 2) then
                srcIsReg = .true.
        else
          srcIsReg = .false.
        endif
      elseif (localSrcFileType == ESMF_FILEFORMAT_GRIDSPEC) then
        if (useSrcCoordVar) then
           call ESMF_GridspecInq(srcfile, srcrank, srcdims, coord_names=srcCoordinateVars, rc=localrc)
        else
           call ESMF_GridspecInq(srcfile, srcrank, srcdims, rc=localrc)
        endif
        if (localVerboseFlag .and. localrc /= ESMF_SUCCESS) then
          write(*,*)
                print *, 'ERROR: Unable to get dimension information from:', srcfile
        endif
        if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
        srcIsReg = .true.
        srcrank = 2
      elseif (localSrcFileType == ESMF_FILEFORMAT_TILE) then
           ! this returns the size of the center stagger, not the supergrid
           call ESMF_GridSpecQueryTileSize(srcfile, srcdims(1),srcdims(2), rc=localrc)
           if (ESMF_LogFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rcToReturn=rc)) return
        srcIsReg = .true.
        srcrank = 2
      elseif (localSrcFileType == ESMF_FILEFORMAT_MOSAIC) then
        srcIsMosaic = .true.
      endif
      if (localdstFileType == ESMF_FILEFORMAT_SCRIP) then
        call ESMF_ScripInq(dstfile, grid_rank=dstrank, grid_dims=dstdims, rc=localrc)
        if (localVerboseFlag .and. localrc /= ESMF_SUCCESS) then
             write(*,*)
             print *, 'ERROR: Unable to get dimension information from:', dstfile
        endif
        if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
        if (dstrank == 2) then
                dstIsReg = .true.
        else
          dstIsReg = .false.
        endif
      elseif (localDstFileType == ESMF_FILEFORMAT_GRIDSPEC) then
        if (useDstCoordVar) then
            call ESMF_GridspecInq(dstfile, dstrank, dstdims, coord_names=dstCoordinateVars, rc=localrc)
        else
            call ESMF_GridspecInq(dstfile, dstrank, dstdims, rc=localrc)
        endif
        if (localVerboseFlag .and. localrc /= ESMF_SUCCESS) then
           write(*,*)
           print *, 'ERROR: Unable to get dimension information from:', dstfile
        endif
        if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
        dstrank = 2
        dstIsReg = .true.
      elseif (localDstFileType == ESMF_FILEFORMAT_TILE) then
        ! this returns the size of the center stagger, not the supergrid
        call ESMF_GridSpecQueryTileSize(dstfile, dstdims(1),dstdims(2), rc=localrc)
        if (ESMF_LogFoundError(localrc, &
                                     ESMF_ERR_PASSTHRU, &
                                     ESMF_CONTEXT, rcToReturn=rc)) return
        dstrank = 2
        dstIsReg = .true.
      elseif (localDstFileType == ESMF_FILEFORMAT_MOSAIC) then
        dstIsMosaic = .true.
      endif
      commandbuf(:) = 0
      if (srcIsReg) commandbuf(1) = 1
      if (dstIsReg) commandbuf(2) = 1
      if (srcIsMosaic) commandbuf(1) = 2
      if (dstIsMosaic) commandbuf(2) = 2
      if (srcIsReg) then
        commandbuf(3) = srcdims(1)
        commandbuf(4) = srcdims(2)
      endif
      if (dstIsReg) then
        commandbuf(5) = dstdims(1)
        commandbuf(6) = dstdims(2)
      endif
      call ESMF_VMBroadcast(vm, commandbuf, 6, 0, rc=rc)
      if (ESMF_LogFoundError(localrc, &
            ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
    else
      ! Not the Root PET
      call ESMF_VMBroadcast(vm, commandbuf, 6, 0, rc=rc)
      if (ESMF_LogFoundError(localrc, &
            ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
      if (commandbuf(1) == 1) then
        srcIsReg = .true.
      elseif (commandbuf(1) == 2) then
        srcIsMosaic = .true.
      endif
      if (commandbuf(2) == 1) then
        dstIsReg = .true.
      elseif (commandbuf(2) == 2) then
        dstIsMosaic = .true.
      endif
      srcdims(1) = commandbuf(3)
      srcdims(2) = commandbuf(4)
      dstdims(1) = commandbuf(5)
      dstdims(2) = commandbuf(6)
    endif

    ! Print the regrid options
    if (localVerboseFlag .and. PetNo == 0) then
      print *, "Starting weight generation with these inputs: "
      print *, "  Source File: ", trim(srcfile)
      print *, "  Destination File: ", trim(dstfile)
      if (present(weightFile)) then
        print *, "  Weight File: ", trim(weightFile)
      endif
      if (present(rhfile)) then
        print *, "  RouteHandle File: ", trim(rhfile)
      endif
      if (localWeightOnlyFlag) then
          print *, "    only output weights in the weight file"
      endif
      if (localSrcFileType == ESMF_FILEFORMAT_SCRIP) then
        print *, "  Source File is in SCRIP format"
      elseif (localSrcFileType == ESMF_FILEFORMAT_ESMFMESH) then
        print *, "  Source File is in ESMF format"
      elseif (localSrcFileType == ESMF_FILEFORMAT_UGRID) then
        print *, "  Source File is in UGRID format"
        if (srcMissingValue) then
           print *, "    Use attribute 'missing_value' of variable '", trim(srcMissingvalueVar),"' as the mask"
        endif
      elseif  (localSrcFileType == ESMF_FILEFORMAT_GRIDSPEC) then
        print *, "  Source File is in CF Grid format"
        if (useSrcCoordVar) then
           print *, "    Use '", trim(srcCoordinateVars(1)), "' and '", trim(srcCoordinateVars(2)), &
                       "' as the coordinate variables"
        endif
        if (srcMissingValue) then
           print *, "    Use the missing values of variable '", trim(srcMissingvalueVar),"' as the mask"
       endif
      elseif (localSrcFileType == ESMF_FILEFORMAT_TILE) then
        print *, "  Source File is in GRIDSPEC TILE format"
      else
        print *, "  Source File is in GRIDSPEC MOSAIC format"
      endif
      if (localSrcFileType /= ESMF_FILEFORMAT_MOSAIC) then
        if (srcIsRegional) then
           print *, "  Source Grid is a regional grid"
        else
           print *, "  Source Grid is a global grid"
        endif
      endif
      if (srcIsReg)   then
         print *, "  Source Grid is a logically rectangular grid"
      elseif (.not. srcIsMosaic) then
         print *, "  Source Grid is an unstructured grid"
      endif
      if (useSrcCorner) then
         print *, "  Use the corner coordinates of the source grid to do the regrid"
      else
         print *, "  Use the center coordinates of the source grid to do the regrid"
      endif
      if (localDstFileType == ESMF_FILEFORMAT_SCRIP) then
        print *, "  Destination File is in SCRIP format"
      elseif (localDstFileType == ESMF_FILEFORMAT_ESMFMESH) then
        print *, "  Destination File is in ESMF format"
      elseif (localDstFileType == ESMF_FILEFORMAT_UGRID) then
        print *, "  Destination File is in UGRID format"
        if (dstMissingValue) then
           print *, "    Use the missing value of '", trim(dstMissingvalueVar),"' as the mask"
        endif   
      elseif  (localDstFileType == ESMF_FILEFORMAT_GRIDSPEC) then
        print *, "  Destination File is in CF Grid format"
        if (useDstCoordVar) then
           print *, "    Use '", trim(dstCoordinateVars(1)), "' and '", trim(dstCoordinateVars(2)), &
                       "' as the coordinate variables"
        endif
        if (dstMissingValue) then
           print *, "    Use the missing value of '", trim(dstMissingvalueVar),"' as the mask"
        endif   
      elseif (localDstFileType == ESMF_FILEFORMAT_TILE) then
        print *, "  Destination File is in GRIDSPEC TILE format"
      else
        print *, "  Destination File is in GRIDSPEC MOSAIC format"
      endif
      if (localDstFileType /= ESMF_FILEFORMAT_MOSAIC) then
        if (dstIsRegional) then
           print *, "  Destination Grid is a regional grid"
        else
           print *, "  Destination Grid is a global grid"
        endif
      endif
      if (dstIsReg)   then
         print *, "  Destination Grid is a logically rectangular grid"
      elseif (.not. dstIsMosaic) then
         print *, "  Destination Grid is an unstructured grid"
      endif
      if (useDstCorner) then
         print *, "  Use the corner coordinates of the destination grid to do the regrid"
      else
         print *, "  Use the center coordinates of the destination grid to do the regrid"
      endif
      if (localRegridMethod == ESMF_REGRIDMETHOD_BILINEAR) then
        print *, "  Regrid Method: bilinear"
      elseif (localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE) then
        print *, "  Regrid Method: conserve"
      elseif (localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE_2ND) then
        print *, "  Regrid Method: conserve2nd"
      elseif (localRegridMethod == ESMF_REGRIDMETHOD_PATCH) then
        print *, "  Regrid Method: patch"
      elseif (localRegridMethod == ESMF_REGRIDMETHOD_NEAREST_STOD) then
        print *, "  Regrid Method: nearest source to destination"
      elseif (localRegridMethod == ESMF_REGRIDMETHOD_NEAREST_DTOS) then
        print *, "  Regrid Method: nearest destination to source"
      endif
      if (localPoleMethod .eq. ESMF_POLEMETHOD_NONE) then
         print *, "  Pole option: NONE"
      elseif (localPoleMethod .eq. ESMF_POLEMETHOD_ALLAVG) then
         print *, "  Pole option: ALL"
      elseif (localPoleMethod .eq. ESMF_POLEMETHOD_TEETH) then
         print *, "  Pole option: TEETH"
      else
         print *, "  Pole option: ", localPoleNPnts
      endif
      if (localUnmappedaction .eq. ESMF_UNMAPPEDACTION_IGNORE) then
         print *, "  Ignore unmapped destination points"
      endif
      if (localIgnoreDegenerate) then
         print *, "  Ignore degenerate cells in the input grids"
      endif
      if (localLargeFileFlag) then
         print *, "  Output weight file in 64bit offset NetCDF file format"
      endif
      if (localNetcdf4FileFlag) then
         print *, "  Output weight file in NetCDF4 file format"
      endif
      if (localUserAreaFlag) then
         print *, "  Use user defined cell area for both the source and destination grids"
      endif
      if (localLineType .eq. ESMF_LINETYPE_CART) then
         print *, "  Line Type: cartesian"
      elseif (localLineType .eq. ESMF_LINETYPE_GREAT_CIRCLE) then
         print *, "  Line Type: greatcircle"
      endif
      if (localNormType .eq. ESMF_NORMTYPE_DSTAREA) then
          print *, "  Norm Type: dstarea"
      elseif (localNormType .eq. ESMF_NORMTYPE_FRACAREA) then
          print *, "  Norm Type: fracarea"
      endif
      if (present(extrapMethod)) then
         if (extrapMethod%extrapmethod .eq. &
              ESMF_EXTRAPMETHOD_NONE%extrapmethod) then
            print *, "  Extrap. Method: none"
         else if (extrapMethod%extrapmethod .eq. &
              ESMF_EXTRAPMETHOD_NEAREST_STOD%extrapmethod) then
            print *, "  Extrap. Method: neareststod"
         else if (extrapMethod%extrapmethod .eq. &
              ESMF_EXTRAPMETHOD_NEAREST_IDAVG%extrapmethod) then
            print *, "  Extrap. Method: nearestidavg"
            if (present(extrapNumSrcPnts)) then
               print '(a,i0)', "   Extrap. Number of Source Points: ",extrapNumSrcPnts
            else
               print '(a,i0)', "   Extrap. Number of Source Points: ",8
            endif
            if (present(extrapDistExponent)) then
               print *, "  Extrap. Dist. Exponent: ",extrapDistExponent
            else
               print *, "  Extrap. Dist. Exponent: ",2.0
            endif
         else if (extrapMethod%extrapmethod .eq. &
              ESMF_EXTRAPMETHOD_NEAREST_D%extrapmethod) then
            print *, "  Extrap. Method: nearestd"
         else if (extrapMethod%extrapmethod .eq. &
              ESMF_EXTRAPMETHOD_CREEP%extrapmethod) then
            print *, "  Extrap. Method: creep"
            if (present(extrapNumLevels)) then
               print '(a,i0)', "   Extrap. Number of Levels: ",extrapNumLevels
            else
               print *,"   Extrap. Number of Levels: NOT PRESENT?"
            endif
         else if (extrapMethod%extrapmethod .eq. &
           ESMF_EXTRAPMETHOD_CREEP_NRST_D%extrapmethod) then
            print *, "  Extrap. Method: creepnrstd"
            if (present(extrapNumLevels)) then
               print '(a,i0)', "   Extrap. Number of Levels: ",extrapNumLevels
            else
               print *,"   Extrap. Number of Levels: NOT PRESENT?"
            endif
         else
          print *, "  Extrap. Method: unknown"
         endif
      else
          print *, "  Extrap. Method: none"
      endif
      if (present(tileFilePath)) then
          print *, "  Alternative tile file path: ", trim(tileFilePath)
      endif
      write(*,*)
    endif

    ! Set flags according to the regrid method
    convertSrcToDual=.false.
    convertDstToDual=.false.
    if ((localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE) .or. &
        (localRegridMethod == ESMF_REGRIDMETHOD_CONSERVE_2ND)) then
      isConserve=.true.
      addCorners=.true.
      meshloc=ESMF_MESHLOC_ELEMENT
    else
      isConserve=.false.
      addCorners=.false.
      if (.not. useSrcCorner) then
         convertSrcToDual=.true.
      endif
      if (.not. useDstCorner) then
         convertDstToDual=.true.
      endif
      meshloc=ESMF_MESHLOC_NODE
    endif

    if (srcIsRegional .and. dstIsRegional) then
      regridScheme = ESMF_REGRID_SCHEME_REGION3D
      srcIsSphere=.false.
      dstIsSphere=.false.
    elseif (srcIsRegional) then
      regridScheme = ESMF_REGRID_SCHEME_REGTOFULL3D
      srcIsSphere=.false.
      dstIsSphere=.true.
    elseif (dstIsRegional) then
      regridScheme = ESMF_REGRID_SCHEME_FULLTOREG3D
      srcIsSphere=.true.
      dstIsSphere=.false.
    else
      regridScheme = ESMF_REGRID_SCHEME_FULL3D
      srcIsSphere=.true.
      dstIsSphere=.true.
    endif

    ! Create a decomposition such that each PET will contain at least 2 column and 2 row of data
    ! otherwise, regrid will not work
    if (PetCnt == 1) then
            xpart = 1
            ypart = 1
    else
        bigFac = 1
        do i=2, int(sqrt(float(PetCnt)))
              if ((PetCnt/i)*i == PetCnt) then
                bigFac = i
        endif
      enddo
            xpets = bigFac
            ypets = PetCnt/xpets
      if (srcIsReg) then
              if ((srcdims(1) <= srcdims(2) .and. xpets <= ypets) .or. &
                  (srcdims(1) > srcdims(2) .and. xpets > ypets)) then
                xpart = xpets
                ypart = ypets
              else
                xpart = ypets
                ypart = xpets
              endif
              xdim = srcdims(1)/xpart
              ydim = srcdims(2)/ypart
              do while (xdim <= 1 .and. xpart>1)
                xpart = xpart-1
              xdim = srcdims(1)/xpart
        enddo
              do while (ydim <= 1 .and. ypart>1)
                ypart = ypart-1
              ydim = srcdims(2)/ypart
        enddo
      endif
    endif

    !Read in the srcfile and create the corresponding ESMF object (either
    ! ESMF_Grid or ESMF_Mesh

    if (srcUseLocStream) then
       if (srcMissingValue) then
         srcLocStream = ESMF_LocStreamCreate(srcfile, &
                              fileformat=localSrcFileType, &
                      indexflag=ESMF_INDEX_GLOBAL, &
                      varname=trim(srcMissingvalueVar), &
                      centerflag=.not. useSrcCorner, rc=localrc)
       else             
         srcLocStream = ESMF_LocStreamCreate(srcfile, &
                              fileformat=localSrcFileType, &
                      indexflag=ESMF_INDEX_GLOBAL, &
                      centerflag=.not. useSrcCorner, rc=localrc)
       endif
       if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
       srcField = ESMF_FieldCreate(srcLocStream, typekind=ESMF_TYPEKIND_R8, rc=localrc)
       if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
    elseif (localSrcFileType == ESMF_FILEFORMAT_GRIDSPEC .or. &
           localSrcFileType == ESMF_FILEFORMAT_TILE) then
       if (useSrcCoordVar) then
           if (srcMissingValue) then
              srcGrid = ESMF_GridCreate(srcfile, regDecomp=(/xpart,ypart/), &
                        addCornerStagger=addCorners, indexflag=ESMF_INDEX_GLOBAL, &
                        addMask=.true., varname=trim(srcMissingvalueVar), isSphere=srcIsSphere, &
                        coordNames = srcCoordinateVars, rc=localrc)
           else
             srcGrid = ESMF_GridCreate(srcfile, regDecomp=(/xpart,ypart/), &
                        addCornerStagger=addCorners, indexflag=ESMF_INDEX_GLOBAL, &
             isSphere=srcIsSphere, coordNames = srcCoordinateVars,rc=localrc)
           endif
        else
           if (srcMissingValue) then
             srcGrid = ESMF_GridCreate(srcfile, regDecomp=(/xpart,ypart/), &
                        addCornerStagger=addCorners, indexflag=ESMF_INDEX_GLOBAL, &
                        addMask=.true., varname=trim(srcMissingvalueVar), isSphere=srcIsSphere, rc=localrc)
           else
              srcGrid = ESMF_GridCreate(srcfile, regDecomp=(/xpart,ypart/), &
                        addCornerStagger=addCorners, indexflag=ESMF_INDEX_GLOBAL, &
              isSphere=srcIsSphere, rc=localrc)
           endif
         endif
         if (ESMF_LogFoundError(localrc, &
            ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
         srcField = ESMF_FieldCreate(srcGrid, typekind=ESMF_TYPEKIND_R8, &
                    staggerloc=ESMF_STAGGERLOC_CENTER, rc=localrc)
         if (ESMF_LogFoundError(localrc, &
            ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
    elseif (localSrcFileType == ESMF_FILEFORMAT_SCRIP) then
         if(srcIsReg) then
           srcGrid = ESMF_GridCreate(srcfile, regDecomp=(/xpart,ypart/), &
                            addCornerStagger=addCorners, indexflag=ESMF_INDEX_GLOBAL, &
                            isSphere=srcIsSphere, addUserArea =localUserAreaFlag, rc=localrc)
           if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
           srcField = ESMF_FieldCreate(srcGrid, typekind=ESMF_TYPEKIND_R8, &
                       staggerloc=ESMF_STAGGERLOC_CENTER, rc=localrc)
           if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
        else
           srcMesh = ESMF_MeshCreate(srcfile, ESMF_FILEFORMAT_SCRIP, &
                     convertToDual=convertSrcToDual, addUserArea=localUserAreaFlag, &
                      rc=localrc)
           if (ESMF_LogFoundError(localrc, &
                ESMF_ERR_PASSTHRU, &
                ESMF_CONTEXT, rcToReturn=rc)) return
           srcField=ESMF_FieldCreate(srcMesh,typekind=ESMF_TYPEKIND_R8,meshloc=meshloc,rc=localrc)
           if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
        endif
    elseif (localSrcFileType == ESMF_FILEFORMAT_MOSAIC) then
        ! multi-tile Mosaic Cubed Sphere grid
        srcGrid = ESMF_GridCreateMosaic(srcfile, tileFilePath=TileFilePath, &
                staggerLocList=(/ESMF_STAGGERLOC_CENTER, ESMF_STAGGERLOC_CORNER/), &
                rc=localrc)
        if (ESMF_LogFoundError(localrc, &
           ESMF_ERR_PASSTHRU, &
           ESMF_CONTEXT, rcToReturn=rc)) return
        srcField = ESMF_FieldCreate(srcGrid, typekind=ESMF_TYPEKIND_R8, &
                   staggerloc=ESMF_STAGGERLOC_CENTER, rc=localrc)
        if (ESMF_LogFoundError(localrc, &
              ESMF_ERR_PASSTHRU, &
              ESMF_CONTEXT, rcToReturn=rc)) return
    else
        ! if srcfile is not SCRIP, it is always unstructured
        if (srcMissingValue) then
           srcMesh = ESMF_MeshCreate(srcfile, localSrcFileType, &
               maskFlag =meshloc, &
               addUserArea=localUserAreaFlag, &
               convertToDual=convertSrcToDual, &
               varname=trim(srcMissingvalueVar), rc=localrc)
        else
           srcMesh = ESMF_MeshCreate(srcfile, localSrcFileType, &
                addUserArea=localUserAreaFlag, &
               convertToDual=convertSrcToDual, &
               rc=localrc)
        endif
        if (ESMF_LogFoundError(localrc, &
            ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
        srcField=ESMF_FieldCreate(srcMesh,typekind=ESMF_TYPEKIND_R8,meshloc=meshloc,rc=localrc)
        if (ESMF_LogFoundError(localrc, &
            ESMF_ERR_PASSTHRU, &
            ESMF_CONTEXT, rcToReturn=rc)) return
    endif

  end subroutine ESMF_RegridWeightGenFile

end module ESMF_RegridWeightGenMod
