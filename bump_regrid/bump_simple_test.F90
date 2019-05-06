program bump_simple_test

  use type_bump, only: bump_type
 
  implicit none

  type(bump_type) :: bump
 
  integer :: mod_num, ls_num
  real(8), allocatable :: mod_lon(:), mod_lat(:)
  real(8), allocatable :: ls_lon(:), ls_lat(:)

  real(8), allocatable :: area(:),vunit(:,:)
  logical, allocatable :: lmask(:,:)
  
  real(8), allocatable :: fld(:,:),obs(:,:)

  ! test of simple coords to only be run in serial
  mod_num = 9
  allocate( mod_lon(mod_num), mod_lat(mod_num) )
  mod_lon = (/60, 120, 180, 60, 120, 180, 60, 120, 180/)
  mod_lat = (/0, 0, 0, 30, 30, 30, 60, 60, 60/)
 
  ls_num = 3
  allocate( ls_lon(ls_num), ls_lat(ls_num) )
  ls_lon = (/60, 120, 180/)
  ls_lat = (/0, 30, 60/)
 
  !Initialize geometry
  allocate(area(mod_num))
  allocate(vunit(mod_num,1))
  allocate(lmask(mod_num,1))
  area = 1.0           ! Dummy area
  vunit = 1.0          ! Dummy vertical unit
  lmask = .true.       ! Mask

  !Open BUMP log file
  open(unit=10,file='bump_simple_test.log',status='replace')

  !Initialize BUMP
  call bump%nam%init
  bump%nam%prefix = 'bump_simple_test'
  bump%nam%new_obsop = .true.
  call bump%setup_online( mod_num,1,1,1,mod_lon,mod_lat,area,vunit,lmask, &
                          nobs=ls_num,lonobs=ls_lon(:),latobs=ls_lat(:),lunit=10 )

  !Run BUMP drivers
  call bump%run_drivers

  !Initialize field
  allocate(fld(mod_num,1))
  call random_number(fld)
 
  !Apply observation interpolator
  allocate(obs(ls_num,1))
  call bump%apply_obsop(fld,obs)

  !Close BUMP log file
  close(unit=10)

  !Check values
  write(*,*) 'Field value: ',fld(1,1),'/',' - obs. value: ',obs(1,1)
  write(*,*) 'Field value: ',fld(5,1),'/',' - obs. value: ',obs(2,1)
  write(*,*) 'Field value: ',fld(9,1),'/',' - obs. value: ',obs(3,1)

  !Release memory
  deallocate(area)
  deallocate(vunit)
  deallocate(lmask)
  deallocate(mod_lon, mod_lat)
  deallocate(ls_lon, ls_lat)

end program bump_simple_test

