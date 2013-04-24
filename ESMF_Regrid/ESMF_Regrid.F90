! $Id:  Exp $
!
! Earth System Modeling Framework
! Copyright 2002-2012, University Corporation for Atmospheric Research,
! Massachusetts Institute of Technology, Geophysical Fluid Dynamics
! Laboratory, University of Michigan, National Centers for Environmental
! Prediction, Los Alamos National Laboratory, Argonne National Laboratory,
! NASA Goddard Space Flight Center.
! Licensed under the University of Illinois-NCSA License.
!
!===============================================================================
!                            ESMF_Regrid.F90
!
! This is an external demo of Field regridding
!===============================================================================

program Regrid

!------------------------------------------------------------------------------
! SPECIFICATION
!------------------------------------------------------------------------------
! !USES:
  use ESMF

  use netcdf

  implicit none

!------------------------------------------------------------------------------
! EXECUTION
!------------------------------------------------------------------------------
      integer :: localPet, nPet
      integer :: failCnt, numarg
      integer :: localrc, rc

      type(ESMF_VM) :: vm

      character(ESMF_MAXPATHLEN) :: srcgridfile, dstgridfile, weightfile, title

      real(ESMF_KIND_R8), pointer :: factorList(:)
      integer, pointer            :: factorIndexList(:,:)

      real(ESMF_KIND_R8), pointer :: src_lat(:), src_lon(:), &
                                     dst_lat(:), dst_lon(:), &
                                     src_area(:), dst_area(:), &
                                     src_mask(:), dst_mask(:), &
                                     src_frac(:), dst_frac(:)

      integer :: src_dim, dst_dim
      integer :: i, src, dst

      logical :: srcIsSphere


      real(ESMF_KIND_R8), parameter :: two = 2.0
      real(ESMF_KIND_R8), parameter :: d2r = 3.141592653589793238/180
      real(ESMF_KIND_R8), parameter :: UNINITVAL = 422397696

      real(ESMF_KIND_R8), allocatable :: FsrcArray(:)
      real(ESMF_KIND_R8), allocatable :: FdstArray(:), FdstArrayX(:)
      real(ESMF_KIND_R8), pointer :: FdstArrayPtr(:)

      type(ESMF_DistGrid) :: src_distgrid, dst_distgrid
      type(ESMF_ArraySpec):: src_arrayspec, dst_arrayspec
      type(ESMF_Array) :: srcArray, dstArray
      type(ESMF_RouteHandle) :: routehandle
      type(ESMF_Grid) :: srcGrid, dstGrid
      type(ESMF_Field) :: srcField, dstField

      real(ESMF_KIND_R8) :: reltotError, reltwoError, avgError
      real(ESMF_KIND_R8) :: totErrDif, twoErrDif, twoErrX
      real(ESMF_KIND_R8) :: err, maxerr, minerr, maxneg, maxpos
      real(ESMF_KIND_R8) :: grid1min, grid1max, grid2min, grid2max
      real(ESMF_KIND_R8), pointer :: grid1area(:), grid2area(:)
      real(ESMF_KIND_R8), pointer :: grid1areaXX(:), grid2areaXX(:)

      ! Initialize ESMF
      call ESMF_Initialize (defaultCalKind=ESMF_CALKIND_GREGORIAN, &
        defaultlogfilename="RegridWeightGenCheck.Log", &
        logkindflag=ESMF_LOGKIND_MULTI, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! set log to flush after every message
      call ESMF_LogSet(flush=.true., rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! get all vm information
      call ESMF_VMGetGlobal(vm, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! set up local pet info
      call ESMF_VMGet(vm, localPet=localPet, petCount=nPet, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! Usage:  ESMF_Regrid srcgrid_file dstgrid_file weight_file
      call ESMF_UtilGetArgC (numarg)
      if (numarg < 1) then
        if (nPet == 0) then
          print *, 'ERROR: insufficient arguments'
          print *, 'USAGE: ESMF_Regrid weight_file'
          print *, 'The weight_file is the output weight file in SCRIP format'
        endif
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
      endif
      call ESMF_UtilGetArg(1, argvalue=weightfile)

      !Set finalrc to success
      rc = ESMF_SUCCESS
      failCnt = 0

      ! read in the grid dimensions
      call NCFileInquire(weightfile, title, src_dim, dst_dim, localrc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

    !  only read the data on PET 0 until we get ArrayRead going...
    if (localPet == 0) then

      allocate(src_lat(src_dim))
      allocate(src_lon(src_dim))
      allocate(src_area(src_dim))
      allocate(src_mask(src_dim))
      allocate(src_frac(src_dim))
      allocate(dst_lat(dst_dim))
      allocate(dst_lon(dst_dim))
      allocate(dst_area(dst_dim))
      allocate(dst_mask(dst_dim))
      allocate(dst_frac(dst_dim))

      call GridReadCoords(weightfile, src_lat, src_lon, src_area, src_mask, src_frac, &
        dst_lat, dst_lon, dst_area, dst_mask, dst_frac, localrc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! create Fortran arrays
      allocate(FsrcArray(src_dim))
      allocate(FdstArray(dst_dim))
      allocate(FdstArrayX(dst_dim))

      ! Initialize data
      FsrcArray = two + cos(src_lat)**2*cos(two*src_lon)
      FdstArrayX = two + cos(dst_lat)**2*cos(two*dst_lon)
      FdstArray = UNINITVAL

      ! deallocate arrays
      deallocate(src_lat)
      deallocate(src_lon)
      deallocate(dst_lat)
      deallocate(dst_lon)
    endif

      ! create DistGrids for the ESMF Arrays
      src_distgrid = ESMF_DistGridCreate(minIndex=(/1/), &
        maxIndex=(/src_dim/), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
      dst_distgrid = ESMF_DistGridCreate(minIndex=(/1/), &
        maxIndex=(/dst_dim/), rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! create dummy grids for fields
      srcGrid = ESMF_GridCreate(src_distgrid, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
      dstGrid = ESMF_GridCreate(dst_distgrid, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! create ArraySpecs for the ESMF Arrays
      call ESMF_ArraySpecSet(src_arrayspec, typekind=ESMF_TYPEKIND_R8, rank=1, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
      call ESMF_ArraySpecSet(dst_arrayspec, typekind=ESMF_TYPEKIND_R8, rank=1, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! create the ESMF Arrays
      srcArray = ESMF_ArrayCreate(arrayspec=src_arrayspec, distgrid=src_distgrid, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
      dstArray = ESMF_ArrayCreate(farray=FdstArray, distgrid=dst_distgrid, &
                   indexflag=ESMF_INDEX_DELOCAL, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! Scatter the ESMF Arrays
      call ESMF_ArrayScatter(srcArray, farray=FsrcArray, rootPet=0, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! create fields on the empty grid and arrays
      srcField = ESMF_FieldCreate(srcGrid, srcArray, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! create fields on the empty grid and arrays
      dstField = ESMF_FieldCreate(dstGrid, dstArray, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

    if (localPet == 0) then
      ! read in the regriding weights from specified file -> factorList and factorIndex list
      call ESMF_FieldRegridReadSCRIPFileP(weightfile, factorList, factorIndexList, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
    endif


#if 0
!-------------------- diagnostics -----------------------------------------------
print *, "size of factorList = (", size(factorList,1),")"
print *, "size of factorIndexList = (", size(factorIndexList,1), ",", size(factorIndexList,2),")"

do i=1,size(factorList)
src = factorIndexList(1,i)
dst = factorIndexList(2,i)
FdstArray(dst) = FdstArray(dst) + factorList(i)*FsrcArray(src)
!print *, FdstArray(dst), "  ", FsrcArray(factorIndexList(1,i)), "  ", factorList(i)
!print *, factorList(i), FsrcArray(factorIndexList(1,i)), "  ", FdstArrayX(factorIndexList(2,i))
enddo
#endif

      ! Field and Grid way of doing things
      ! store the factorList and factorIndex list into a routehandle for SMM
      call ESMF_FieldSMMStore(srcField=srcField, dstField=dstField, routehandle=routehandle, &
        factorList=factorList, factorIndexList=factorIndexList, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! compute a Regrid from srcField to dstField
      call ESMF_FieldRegrid(srcField, dstField, routehandle, &
        zeroregion=ESMF_REGION_SELECT, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

#if 0
      ! Array way of doing things
      ! store the factorList and factorIndex list into a routehandle for SMM
      call ESMF_ArraySMMStore(srcArray=srcArray, dstArray=dstArray, routehandle=routehandle, &
        factorList=factorList, factorIndexList=factorIndexList, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! *************************************************************
      ! compute a SMM from srcArray to dstArray
      call ESMF_ArraySMM(srcArray, dstArray, routehandle, &
        zeroregion=ESMF_REGION_SELECT, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)
#endif

      ! ArrayGather the dst array
      call ESMF_ArrayGather(dstArray, farray=FdstArray, rootPet=0, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      ! -----------------------------------------------------------------------
      ! ERROR ANALYSIS - serial
      ! -----------------------------------------------------------------------
    if (localPet == 0) then
      totErrDif = 0
      twoErrDif = 0
      twoErrX = 0
      maxerr = 0
      minerr = 1

     ! source error
     grid1min = UNINITVAL
     grid1max = 0
     do i=1,src_dim
       if (src_mask(i) /=0) then
         if(FsrcArray(i) < grid1min) grid1min = FsrcArray(i)
         if(FsrcArray(i) > grid1max) grid1max = FsrcArray(i)
       endif
     enddo

      ! destination error
      grid2min = UNINITVAL
      grid2max = 0
      do i=1,dst_dim
        ! don't look in masked cells
        ! if frac is below .999, then a significant portion of this cell is
        ! missing from the weight calculation and error is misleading here
        ! also don't look in unitialized cells, for the regional to global cases
        if (dst_mask(i) /= 0 .and. dst_frac(i) > .999 .and. FdstArray(i) /= UNINITVAL) then
          err = abs(FdstArray(i)) - abs(FdstArrayX(i))
          totErrDif = totErrDif + err
          twoErrDif = twoErrDif + err**2
          twoErrX = twoErrX + FdstArrayX(i)**2
          if(err < minerr) minerr = err
          if(err > maxerr) maxerr = err

          ! masking will screw this one up
          if (FdstArray(i) < grid2min) grid2min = FdstArray(i)
          if (FdstArray(i) > grid2max) grid2max = FdstArray(i)
        endif
      enddo

      ! maximum negative weight
      maxneg = 0
      maxneg = minval(factorList)
      if (maxneg > 0) maxneg = 0

      ! maximum positive weight
      maxpos = 0
      maxpos = maxval(factorList)

      ! relative error
      reltotError = totErrDif/maxval(FdstArrayX)
      reltwoError = sqrt(twoErrDif)/sqrt(twoErrX)
      avgError = (minerr + maxerr)/2

      ! area calculations
      ! use one of src_ or dst_frac, but NOT both!
      allocate(grid1area(src_dim))
      allocate(grid2area(dst_dim))
      allocate(grid1areaXX(src_dim))
      allocate(grid2areaXX(dst_dim))
      grid1area = FsrcArray*src_area*src_frac

      ! Only calculate dst area over region that is unmasked and initialized
      grid2area=0.0
      do i=1,dst_dim
         if ((dst_mask(i) /= 0) .and. (FdstArray(i) /=UNINITVAL)) then
            grid2area(i) = FdstArray(i)*dst_area(i)
         endif
      enddo

      grid1areaXX = FsrcArray*src_area
      grid2areaXX = FdstArray*dst_area*dst_frac

      print *, trim(weightfile), " - ", trim(title)
      print *, " "
      print *, "Grid 1 min: ", grid1min, "    Grid 1 max: ", grid1max
      print *, "Grid 2 min: ", grid2min, "    Grid 2 max: ", grid2max
      print *, " "
      print *, "Maximum negative weight = ", maxneg
      print *, "Maximum positive weight = ", maxpos
      print *, " "
      print *, "Absolute error - 1 norm = ", reltotError
      print *, "Relative error - 2 norm = ", reltwoError
      print *, "Average error - (SCRIP) = ", avgError
      print *, " "
      print *, "Grid 1 area = ", sum(grid1area)
      print *, "Grid 2 area = ", sum(grid2area)
      print *, "Conservation error = ", abs(sum(grid2area)-sum(grid1area))
!      print *, " "
!      print *, "reverse fracs  - Grid 1 area = ", sum(grid1areaXX)
!      print *, "reverse fracs  - Grid 2 area = ", sum(grid2areaXX)
!      print *, "reverse - Conservation error = ", abs(sum(grid2areaXX)-sum(grid1areaXX))
      deallocate(grid1area)
      deallocate(grid2area)
      deallocate(grid1areaXX)
      deallocate(grid2areaXX)
      deallocate(src_area)
      deallocate(src_frac)
      deallocate(dst_area)
      deallocate(FsrcArray)
      deallocate(FdstArray)
      deallocate(FdstArrayX)
    endif

      ! destroy and deallocate
      call ESMF_ArrayDestroy(srcArray, rc=localrc)
      call ESMF_ArrayDestroy(dstArray, rc=localrc)
      if (ESMF_LogFoundError(rcToCheck=localrc, msg=ESMF_LOGERR_PASSTHRU, &
        line=__LINE__, file=__FILE__, rcToReturn=rc)) &
        call ESMF_Finalize(endflag=ESMF_END_ABORT)

      call ESMF_Finalize()

contains

!***********************************************************************************
! Read in the grid dimensions info from the weights file.
! The weights file should have the source and destination grid information
! provided.
!***********************************************************************************
  subroutine NCFileInquire (wgtfile, title, src_dim, dst_dim, localrc)

    character(ESMF_MAXPATHLEN), intent(in)  :: wgtfile
    character(ESMF_MAXPATHLEN), intent(out)  :: title
    integer, intent(out)                :: src_dim
    integer, intent(out)                :: dst_dim
    integer, intent(out), optional      :: localrc

    integer :: ncstat,  nc_file_id,  nc_srcdim_id, nc_dstdim_id
    integer :: titleLen

    character(ESMF_MAXPATHLEN) :: msg

      !-----------------------------------------------------------------
      ! open netcdf file
      !-----------------------------------------------------------------

      ncstat = nf90_open(wgtfile, NF90_NOWRITE, nc_file_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_open error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! source grid dimensions
      !-----------------------------------------------------------------

      ncstat = nf90_inquire_attribute(nc_file_id, nf90_global, 'title', len=titleLen)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inquire_attribute error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      if(len(title) < titleLen) then
        print *, "Not enough space to put title."
        return
      end if
      ncstat = nf90_get_att(nc_file_id, nf90_global, "title", title)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_att error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! source grid dimensions
      !-----------------------------------------------------------------

      ncstat = nf90_inq_dimid(nc_file_id, 'n_a', nc_srcdim_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_dimid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_inquire_dimension(nc_file_id, nc_srcdim_id, len=src_dim)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inquire_variable error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! destination grid dimensions
      !-----------------------------------------------------------------

      ncstat = nf90_inq_dimid(nc_file_id, 'n_b', nc_dstdim_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_dimid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_inquire_dimension(nc_file_id, nc_dstdim_id, len=dst_dim)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inquire_variable error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !------------------------------------------------------------------------
      !     close input file
      !------------------------------------------------------------------------

      ncstat = nf90_close(nc_file_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_close error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      if(present(localrc)) localrc = ESMF_SUCCESS

  end subroutine NCFileInquire

!***********************************************************************************
! Read in the grid info from the weights file.
! The weights file should have the source and destination grid information
! provided.
!***********************************************************************************
  subroutine GridReadCoords (wgtfile, src_lat, src_lon, src_area, &
                             src_mask, src_frac, &
                             dst_lat, dst_lon, dst_area, dst_mask, &
                             dst_frac, localrc)

    character(ESMF_MAXPATHLEN), intent(in)  :: wgtfile
    real(ESMF_KIND_R8), pointer         :: src_lat(:)
    real(ESMF_KIND_R8), pointer         :: src_lon(:)
    real(ESMF_KIND_R8), pointer         :: src_area(:)
    real(ESMF_KIND_R8), pointer         :: src_mask(:)
    real(ESMF_KIND_R8), pointer         :: src_frac(:)
    real(ESMF_KIND_R8), pointer         :: dst_lat(:)
    real(ESMF_KIND_R8), pointer         :: dst_lon(:)
    real(ESMF_KIND_R8), pointer         :: dst_area(:)
    real(ESMF_KIND_R8), pointer         :: dst_mask(:)
    real(ESMF_KIND_R8), pointer         :: dst_frac(:)
    integer, intent(out), optional      :: localrc

    integer :: ncstat,  nc_file_id
    integer :: nc_srcgridlat_id, nc_srcgridlon_id, &
               nc_dstgridlat_id, nc_dstgridlon_id, &
               nc_srcarea_id, nc_dstarea_id, &
               nc_srcmask_id, nc_dstmask_id, &
               nc_srcfrac_id, nc_dstfrac_id
    integer :: unitsLen

    character(ESMF_MAXPATHLEN) :: units, buffer
    character(ESMF_MAXPATHLEN) :: msg

    real(ESMF_KIND_R8), parameter :: d2r = 3.141592653589793238/180

      !-----------------------------------------------------------------
      ! open netcdf file
      !-----------------------------------------------------------------

      ncstat = nf90_open(wgtfile, NF90_NOWRITE, nc_file_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_open error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__, rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! get the grid coordinates
      !-----------------------------------------------------------------

      ncstat = nf90_inq_varid(nc_file_id, 'yc_a', nc_srcgridlat_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_srcgridlat_id, &
        values=src_lat)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ! get the units of the grid coordinates
      ncstat = nf90_inquire_attribute(nc_file_id, nc_srcgridlat_id, 'units', &
        len=unitsLen)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inquire_attribute error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      if(len(units) < unitsLen) then
        print *, "Not enough space to get units."
        return
      endif
      ncstat = nf90_get_att(nc_file_id, nc_srcgridlat_id, "units", buffer)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_att error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      units = buffer(1:unitsLen)
      ! convert to radians if coordinates are in degrees
      if (trim(units)==trim("degrees")) then
        src_lat = src_lat*d2r
      else if (trim(units)/=trim("radians")) then
        write (msg, '(a,i4)') "- units are not 'degrees' or 'radians'"
        call ESMF_LogSetError(ESMF_RC_OBJ_BAD, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ncstat = nf90_inq_varid(nc_file_id, 'xc_a', nc_srcgridlon_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_srcgridlon_id, &
        values=src_lon)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ! get the units of the grid coordinates
      ncstat = nf90_inquire_attribute(nc_file_id, nc_srcgridlon_id, 'units', &
        len=unitsLen)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inquire_attribute error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      if(len(units) < unitsLen) then
        print *, "Not enough space to get units."
        return
      endif
      ncstat = nf90_get_att(nc_file_id, nc_srcgridlon_id, "units", buffer)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_att error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      units = buffer(1:unitsLen)
      ! convert to radians if coordinates are in degrees
      if (trim(units)==trim("degrees")) then
        src_lon = src_lon*d2r
      else if (trim(units)/=trim("radians")) then
        write (msg, '(a,i4)') "- units are not 'degrees' or 'radians'"
        call ESMF_LogSetError(ESMF_RC_OBJ_BAD, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! get the grid coordinates
      !-----------------------------------------------------------------
      ncstat = nf90_inq_varid(nc_file_id, 'yc_b', nc_dstgridlat_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_dstgridlat_id, &
        values=dst_lat)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ! get the units of the grid coordinates
      ncstat = nf90_inquire_attribute(nc_file_id, nc_dstgridlat_id, 'units', &
        len=unitsLen)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inquire_attribute error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      if(len(units) < unitsLen) then
        print *, "Not enough space to get units."
        return
      endif
      ncstat = nf90_get_att(nc_file_id, nc_dstgridlat_id, "units", buffer)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_att error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      units = buffer(1:unitsLen)
      ! convert to radians if coordinates are in degrees
      if (trim(units)==trim("degrees")) then
        dst_lat = dst_lat*d2r
      else if (trim(units)/=trim("radians")) then
        write (msg, '(a,i4)') "- units are not 'degrees' or 'radians'"
        call ESMF_LogSetError(ESMF_RC_OBJ_BAD, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ncstat = nf90_inq_varid(nc_file_id, 'xc_b', nc_dstgridlon_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_dstgridlon_id, &
        values=dst_lon)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ! get the units of the grid coordinates
      ncstat = nf90_inquire_attribute(nc_file_id, nc_dstgridlon_id, 'units', &
        len=unitsLen)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inquire_attribute error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      if(len(units) < unitsLen) then
        print *, "Not enough space to get units."
        return
      endif
      ncstat = nf90_get_att(nc_file_id, nc_dstgridlon_id, "units", buffer)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_att error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      units = buffer(1:unitsLen)
      ! convert to radians if coordinates are in degrees
      if (trim(units)==trim("degrees")) then
        dst_lon = dst_lon*d2r
      else if (trim(units)/=trim("radians")) then
        write (msg, '(a,i4)') "- units are not 'degrees' or 'radians'"
        call ESMF_LogSetError(ESMF_RC_OBJ_BAD, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! get the grid areas
      !-----------------------------------------------------------------
      ncstat = nf90_inq_varid(nc_file_id, 'area_a', nc_srcarea_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_srcarea_id, &
        values=src_area)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ncstat = nf90_inq_varid(nc_file_id, 'area_b', nc_dstarea_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_dstarea_id, &
        values=dst_area)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! get the grid masks
      !-----------------------------------------------------------------
      ncstat = nf90_inq_varid(nc_file_id, 'mask_a', nc_srcmask_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_srcmask_id, &
        values=src_mask)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ncstat = nf90_inq_varid(nc_file_id, 'mask_b', nc_dstmask_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_dstmask_id, &
        values=dst_mask)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !-----------------------------------------------------------------
      ! get the grid fracs
      !-----------------------------------------------------------------
      ncstat = nf90_inq_varid(nc_file_id, 'frac_a', nc_srcfrac_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_srcfrac_id, &
        values=src_frac)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      ncstat = nf90_inq_varid(nc_file_id, 'frac_b', nc_dstfrac_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif
      ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_dstfrac_id, &
        values=dst_frac)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      !------------------------------------------------------------------------
      !     close input file
      !------------------------------------------------------------------------

      ncstat = nf90_close(nc_file_id)
      if(ncstat /= 0) then
        write (msg, '(a,i4)') "- nf90_close error:", ncstat
        call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
          line=__LINE__, file=__FILE__ , rcToReturn=rc)
        return
      endif

      if(present(localrc)) localrc = ESMF_SUCCESS

  end subroutine GridReadCoords


!------------------------------------------------------------------------------

   subroutine ESMF_FieldRegridReadSCRIPFileP(remapFile, factorList, factorIndexList, rc)
!------------------------------------------------------------------------
!     call arguments
!------------------------------------------------------------------------

     character (ESMF_MAXPATHLEN), intent(in)         :: remapFile
     real(ESMF_KIND_R8), pointer                 :: factorList(:)
     integer, pointer                            :: factorIndexList(:,:)
     integer, intent(out), optional              :: rc

!------------------------------------------------------------------------
!     local variables
!------------------------------------------------------------------------

     integer :: ncstat,  nc_file_id,  nc_numlinks_id, nc_numwgts_id, &
     nc_dstgrdadd_id, nc_srcgrdadd_id, nc_rmpmatrix_id

     integer :: num_links, num_wts

     character (ESMF_MAXPATHLEN) :: nm, msg

     integer, allocatable  :: address(:), localSize(:), localOffset(:)
     type(ESMF_VM)         :: vm
     integer               :: i, localpet, npet, nlinksPPet, FlocalPet

     ! get lpe number
     call ESMF_VMGetCurrent(vm, rc=rc)
     if(rc /= ESMF_SUCCESS) then
       write (msg, '(a,i4)') "- failed to get current vm", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif

     call ESMF_VMGet(vm, localPet=localPet, petCount=npet, rc=rc)
     if(rc /= ESMF_SUCCESS) then
       write (msg, '(a,i4)') "- failed to get current vm", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif

    ! set the localPet to localPet +1 for fortran array indices
    FlocalPet = localPet+1

!-----------------------------------------------------------------------
!     open remap file and read meta data
!-----------------------------------------------------------------------
     !-----------------------------------------------------------------
     ! open netcdf file
     !-----------------------------------------------------------------

     ncstat = nf90_open(remapFile, NF90_NOWRITE, nc_file_id)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_open error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif

!-----------------------------------------------------------------------
! read source grid meta data for consistency check
!-----------------------------------------------------------------------
     !-----------------------------------------------------------------
     ! number of address pairs in the remappings
     !-----------------------------------------------------------------

     ncstat = nf90_inq_dimid(nc_file_id, 'n_s', nc_numlinks_id)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_inq_dimid error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
     ncstat = nf90_inquire_dimension(nc_file_id, nc_numlinks_id, len=num_links)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_inquire_dimension error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif

     !-----------------------------------------------------------------
     ! number of weights per point/order of interpolation method
     ncstat = nf90_inq_dimid(nc_file_id, 'num_wgts', nc_numwgts_id)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_inq_dimid error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
     ncstat = nf90_inquire_dimension(nc_file_id, nc_numwgts_id, len=num_wts)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_inquire_dimension error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif

     ! split the input data between PETs
     ! allocate factorList and factorIndexList
#if 0
     allocate( localSize(npet), localOffset(npet) )
     nlinksPPet = num_links/npet
     localSize(:) = nlinksPPet

     do i = 1, npet
         localOffset(i) = 1 + (i-1)*nlinksPPet
     enddo
     localSize(npet) = nlinksPPet+MOD(num_links, npet)

     allocate( factorIndexList(2,localSize(FlocalPet)) )
     allocate( factorList(localSize(FlocalPet)) )
#endif
     allocate( factorIndexList(2,num_links) )
     allocate( factorList(num_links) )
     !-----------------------------------------------------------------
     ! source addresses for weights
     !-----------------------------------------------------------------

     allocate( address(num_links) )
     ncstat = nf90_inq_varid(nc_file_id, 'col', nc_srcgrdadd_id)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
     ncstat = nf90_get_var(ncid=nc_file_id, varid=nc_srcgrdadd_id, &
       values=address)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
     factorIndexList(1,:) = address

     !-----------------------------------------------------------------
     ! destination addresss for weights
     !-----------------------------------------------------------------

     ncstat = nf90_inq_varid(nc_file_id, 'row', nc_dstgrdadd_id)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
     ncstat = nf90_get_var(nc_file_id, nc_dstgrdadd_id, address)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
     factorIndexList(2,:) = address
     deallocate( address )

     !-----------------------------------------------------------------
     !     read all variables
     !-----------------------------------------------------------------

     ncstat = nf90_inq_varid(nc_file_id, 'S', nc_rmpmatrix_id)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_inq_varid error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
       write (msg, '(a,i4)') "- nf90_get_var error:", ncstat
     ncstat = nf90_get_var(nc_file_id, nc_rmpmatrix_id, factorList)
!       localOffset(FlocalPet), localSize(FlocalPet))
     if(ncstat /= 0) then
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif
!------------------------------------------------------------------------
!     close input file
!------------------------------------------------------------------------

     ncstat = nf90_close(nc_file_id)
     if(ncstat /= 0) then
       write (msg, '(a,i4)') "- nf90_close error:", ncstat
       call ESMF_LogSetError(ESMF_RC_SYS, msg=msg, &
         line=__LINE__, file=__FILE__, rcToReturn=rc)
       return
     endif

     if(present(rc)) rc = ESMF_SUCCESS

   end subroutine ESMF_FieldRegridReadSCRIPFileP

!------------------------------------------------------------------------------
end program Regrid
