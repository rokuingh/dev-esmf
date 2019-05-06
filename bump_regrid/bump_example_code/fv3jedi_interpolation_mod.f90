! (C) Copyright 2019 UCAR
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.

module fv3jedi_interpolation_mod

use type_bump, only: bump_type
use config_mod

use fv3jedi_kinds_mod, only: kind_real

implicit none
private

public :: bilinear_bump_init, bilinear_bump_apply

! ------------------------------------------------------------------------------

contains

! ------------------------------------------------------------------------------

subroutine bilinear_bump_init(isc_in, iec_in, jsc_in, jec_in, lat_in, lon_in, &
                              isc_ou, iec_ou, jsc_ou, jec_ou, lat_ou, lon_ou, bump, bumpid)

  implicit none

  !Arguments
  integer,              intent(in)    :: isc_in, iec_in, jsc_in, jec_in
  real(kind=kind_real), intent(in)    :: lat_in(isc_in:iec_in,jsc_in:jec_in) !Degrees -90 to 90
  real(kind=kind_real), intent(in)    :: lon_in(isc_in:iec_in,jsc_in:jec_in) !Degrees -180 to 180
  integer,              intent(in)    :: isc_ou, iec_ou, jsc_ou, jec_ou
  real(kind=kind_real), intent(in)    :: lat_ou(isc_ou:iec_ou,jsc_ou:jec_ou) !Degrees -90 to 90
  real(kind=kind_real), intent(in)    :: lon_ou(isc_ou:iec_ou,jsc_ou:jec_ou) !Degrees -180 to 180
  type(bump_type),      intent(inout) :: bump
  integer,              intent(in)    :: bumpid

  !Locals
  integer :: ngrid_in, ngrid_ou
  real(kind=kind_real), allocatable :: lat_in_us(:,:), lon_in_us(:,:) !Unstructured
  real(kind=kind_real), allocatable :: lat_ou_us(:,:), lon_ou_us(:,:) !Unstructured

  real(kind=kind_real), allocatable :: area(:),vunit(:,:)
  logical, allocatable :: lmask(:,:)

  character(len=5)    :: cbumpcount
  character(len=1024) :: bump_nam_prefix

  integer :: ii, ji, jj

  ! Each bump%nam%prefix must be distinct
  ! -------------------------------------
  write(cbumpcount,"(I0.5)") bumpid
  bump_nam_prefix = 'fv3jedi_bumpobsop_data_'//cbumpcount


  ! Put latlon into unstructured format
  ! -----------------------------------
  ngrid_in = (iec_in - isc_in + 1) * (jec_in - jsc_in + 1)
  allocate(lat_in_us(ngrid_in,1))
  allocate(lon_in_us(ngrid_in,1))

  ii = 0
  do jj = jsc_in, jec_in
    do ji = isc_in, iec_in
      ii = ii + 1
      lat_in_us(ii, 1) = lat_in(ji, jj)
      lon_in_us(ii, 1) = lon_in(ji, jj)
    enddo
  enddo

  ngrid_ou = (iec_ou - isc_ou + 1) * (jec_ou - jsc_ou + 1)
  allocate(lat_ou_us(ngrid_ou,1))
  allocate(lon_ou_us(ngrid_ou,1))

  ii = 0
  do jj = jsc_ou, jec_ou
    do ji = isc_ou, iec_ou
      ii = ii + 1
      lat_ou_us(ii, 1) = lat_ou(ji, jj)
      lon_ou_us(ii, 1) = lon_ou(ji, jj)
    enddo
  enddo


  ! Namelist options
  ! ----------------

  !Important namelist options
  call bump%nam%init
  bump%nam%obsop_interp = 'bilin'     ! Interpolation type (bilinear)

  !Less important namelist options (should not be changed)
  bump%nam%prefix = trim(bump_nam_prefix)   ! Prefix for files output
  bump%nam%default_seed = 1
  bump%nam%new_obsop = .true.

  bump%nam%write_obsop = .false.
  bump%nam%verbosity = "none"

  ! Initialize geometry
  ! -------------------
  allocate(area(ngrid_in))
  allocate(vunit(ngrid_in,1))
  allocate(lmask(ngrid_in,1))
  area = 1.0_kind_real   ! Dummy area
  vunit = 1.0_kind_real  ! Dummy vertical unit
  lmask = .true.         ! Mask

  ! Initialize BUMP
  ! ---------------
  call bump%setup_online( ngrid_in,1,1,1,lon_in_us,lat_in_us,area,vunit,lmask, &
                          nobs=ngrid_ou,lonobs=lon_ou_us(:,1),latobs=lat_ou_us(:,1))

  !Run BUMP drivers
  call bump%run_drivers

  !Partial deallocate option
  !call bump%partial_dealloc

  ! Release memory
  ! --------------
  deallocate(area)
  deallocate(vunit)
  deallocate(lmask)
  deallocate(lat_in_us,lat_ou_us)
  deallocate(lon_in_us,lon_ou_us)

end subroutine bilinear_bump_init

! ------------------------------------------------------------------------------

subroutine bilinear_bump_apply( isc_in, iec_in, jsc_in, jec_in, npz_in, field_in, &
                                isc_ou, iec_ou, jsc_ou, jec_ou, npz_ou, field_ou, bump )

  implicit none

  !Arguments
  integer,              intent(in)    :: isc_in, iec_in, jsc_in, jec_in, npz_in
  real(kind=kind_real), intent(in)    :: field_in(isc_in:iec_in,jsc_in:jec_in,npz_in)
  integer,              intent(in)    :: isc_ou, iec_ou, jsc_ou, jec_ou, npz_ou
  real(kind=kind_real), intent(inout) :: field_ou(isc_ou:iec_ou,jsc_ou:jec_ou,npz_ou)
  type(bump_type),      intent(inout) :: bump

  integer :: ngrid_in, ngrid_ou
  integer :: ii, ji, jj, jk
  real(kind=kind_real), allocatable :: field_in_us(:,:) !Unstructured
  real(kind=kind_real), allocatable :: field_ou_us(:,:) !Unstructured

  ! Check for matching vertical number of levels
  if (npz_in .ne. npz_ou) &
    call abor1_ftn("fv3jedi_interpolation_mod.apply_bump does not support different vertical levels")


  ! Put field into unstructured format
  ! ----------------------------------
  ngrid_in = (iec_in - isc_in + 1) * (jec_in - jsc_in + 1)
  allocate(field_in_us(ngrid_in,1))

  ngrid_ou = (iec_ou - isc_ou + 1) * (jec_ou - jsc_ou + 1)
  allocate(field_ou_us(ngrid_ou,1))
  field_ou_us = 0.0_kind_real

  do jk = 1,npz_in

    ii = 0
    do jj = jsc_in, jec_in
      do ji = isc_in, iec_in
        ii = ii + 1
        field_in_us(ii, 1) = field_in(ji, jj, jk)
      enddo
    enddo

    call bump%apply_obsop(field_in_us,field_ou_us)

    ii = 0
    do jj = jsc_ou, jec_ou
      do ji = isc_ou, iec_ou
        ii = ii + 1
        field_ou(ji, jj, jk) = field_ou_us(ii, 1)
      enddo
    enddo

  enddo

  deallocate(field_in_us,field_ou_us)

end subroutine bilinear_bump_apply

! ------------------------------------------------------------------------------

end module fv3jedi_interpolation_mod
