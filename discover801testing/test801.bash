#!/bin/bash

# Ryan O'Kuinghttons
# May 9, 2020
# script to run all discover platforms for ESMF testing
# view jobs in queue with squeue --user=<user>


# discover platforms (g and O for all):
# 
# lib: 
# gfortran481mpiunilib
# gfortran481mvapich2lib
# gfortran481openmpilib
# intel17mvapich2lib
# intel1803openmpilib
# intel1805mpiunilib
# intel1805impilib
# nag62mpiunilib
# pgi14mvapich2lib
# pgi17mpiunilib
# pgi17openmpilib
# 
# esmpy:
# gfortran492mpiuniesmpy
# gfortran492mvapich2esmpy
# intel17mpiuniesmpy
# intel17mvapich2esmpy
# pgi17openmpiesmpy
# 
# external demos/bfb:
# intel1801impied
# pgi18openmpied

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function gfortran481mpiunilib () {
modules='module purge; module load other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mpiuni; export ESMF_NETCDF=standard; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS=-fbounds-check; export ESMF_F90COMPILEOPTS=-fbounds-check; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}
function gfortran481mvapich2lib () {
modules='module purge; module load other/comp/gcc-4.8.1 other/mpi/mvapich2-1.9/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mvapich2; export ESMF_NETCDF=standard; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS=-fbounds-check; export ESMF_F90COMPILEOPTS=-fbounds-check'
}
function gfortran481openmpilib () {
modules='module purge; module load other/comp/gcc-4.8.1 other/mpi/openmpi/1.7.2-gcc-4.8.1-shared'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=openmpi; export ESMF_NETCDF=standard; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS=-fbounds-check; export ESMF_F90COMPILEOPTS=-fbounds-check'
}

function gfortran492mpiuniesmpy () {
modules='module purge; module load other/comp/gcc-4.9.2-sp3 lib/mkl-15.0.2.164 other/mpi/mvapich2-2.1/gcc-4.9.2-sp3 other/SIVO-PyD/spd_1.24.0_gcc-4.9.2-sp3_mkl-15.0.2.164_mvapich2-2.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
localesmfenv='export ESMF_COMPILER=gfortran export ESMF_COMM=mpiuni export ESMF_NETCDF=split export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib export ESMF_PROJ4=external export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}
function gfortran492mvapich2esmpy () {
modules='module purge; module load other/comp/gcc-4.9.2-sp3 lib/mkl-15.0.2.164 other/mpi/mvapich2-2.1/gcc-4.9.2-sp3 other/SIVO-PyD/spd_1.24.0_gcc-4.9.2-sp3_mkl-15.0.2.164_mvapich2-2.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mvapich2; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
localesmfenv='export ESMF_COMPILER=gfortran export ESMF_COMM=mvapich2 export ESMF_NETCDF=split export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib export ESMF_PROJ4=external export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib'
}

function intel17mvapich2lib () {
modules='module purge; module load comp/intel-17.0.4.196 other/mpi/mvapich2-2.3b/intel-17.0.4.196 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mvapich2; export ESMF_NETCDF=/usr/local/other/netcdf/4.1.2_intel-14.0.3/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_PNETCDF=standard; export ESMF_PNETCDF_INCLUDE=/usr/local/other/SLES11.1/pnetcdf/1.4.1/intel-14.0.1.106-impi-4.1.1.036/include; export ESMF_PNETCDF_LIBPATH=/usr/local/other/SLES11.1/pnetcdf/1.4.1/intel-14.0.1.106-impi-4.1.1.036/lib'
}

function intel17mpiuniesmpy () {
modules='module purge; module load comp/intel-17.0.4.196 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/intel-12.1.0.233/bin; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
localesmfenv='export ESMF_COMPILER=intel export ESMF_COMM=mpiuni export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/intel-12.1.0.233/bin export ESMF_PROJ4=external export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib export ESMF_YAMLCPP=OFF export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}

function intel17mvapich2esmpy () {
modules='module purge; module load comp/intel-17.0.4.196 other/mpi/mvapich2-2.3b/intel-17.0.4.196 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mvapich2; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/intel-12.1.0.233/bin; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
localesmfenv='export ESMF_COMPILER=intel export ESMF_COMM=mvapich2 export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/intel-12.1.0.233/bin export ESMF_PROJ4=external export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib export ESMF_YAMLCPP=OFF'
}

function intel1801impied () {
modules='module purge; module load comp/intel-18.0.1.163 mpi/impi-5.1.2.150 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_NETCDF=/usr/local/other/netcdf/4.1.2_intel-14.0.3/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS="-g -traceback -fp-model precise"; export ESMF_F90COMPILEOPTS="-g -traceback -fp-model precise"; export ESMF_NUM_PROCS=16; export ESMF_OPTLEVEL=2'
}

function intel1801impibfb () {
modules='module purge; module load comp/intel-18.0.1.163 mpi/impi-5.1.2.150 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_NETCDF=/usr/local/other/netcdf/4.1.2_intel-14.0.3/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS="-g -traceback -fp-model precise"; export ESMF_F90COMPILEOPTS="-g -traceback -fp-model precise"; export ESMF_NUM_PROCS=16; export ESMF_OPTLEVEL=2; export ESMF_MPIMPMDRUN=/apps/slurm/default/bin/srun'
}

function intel1803openmpilib () {
modules='module purge; module load comp/intel-18.0.3.222 other/mpi/openmpi/3.1.1-intel-18.0.3.222 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=openmpi; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

function intel1805mpiunilib () {
modules='module purge; module load comp/intel-18.0.5.274 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpiuni; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}

function intel1805impilib () {
modules='module purge; module load comp/intel-18.0.5.274 mpi/impi-18.0.5.274 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

function nag62mpiunilib () {
modules='module purge; module load comp/nag-6.2-6204 other/comp/gcc-4.8.5'
esmfenv='export ESMF_COMM=mpiuni; export ESMF_COMPILER=nag; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}

function pgi14mvapich2lib () {
modules='module purge; module load comp/pgi-14.1.0 other/mpi/mvapich2-2.0b/pgi-14.1.0'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mvapich2; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

function pgi17mpiuniesmpy () {
modules='module purge; module load comp/pgi-17.5.0 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun; export ESMF_YAMLCPP=OFF'
localesmfenv='export ESMF_COMPILER=pgi export ESMF_COMM=mpiuni export ESMF_NETCDF=split export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun export ESMF_YAMLCPP=OFF'
}

function pgi17openmpiesmpy () {
modules='module purge; module load comp/pgi-17.5.0 other/mpi/openmpi/2.1.1-pgi-17.5.0 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; ESMF_YAMLCPP=OFF'
localesmfenv='export ESMF_COMPILER=pgi export ESMF_COMM=openmpi export ESMF_NETCDF=split export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib export ESMF_PROJ4=external export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib ESMF_YAMLCPP=OFF'
}

function pgi17mpiunilib () {
modules='module purge; module load comp/pgi-17.7.0'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}

function pgi17openmpilib () {
modules='module purge; module load comp/pgi-17.7.0 other/mpi/openmpi/2.1.1-pgi-17.7.0-k40'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

function pgi18openmpied () {
modules='module purge; module load comp/pgi-18.5.0 other/mpi/openmpi/3.1.1-pgi-18.5.0-k40'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=/usr/local/other/SLES11.1/netcdf4/pgi-14.9.0/bin/nc-config;  export ESMF_YAMLCPP=OFF'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

clearesmfvars='unset ESMF_OS ESMF_ABI ESMF_SITE ESMF_TESTEXHAUSTIVE ESMF_TESTWITHTHREADS ESMF_MPIRUN ESMF_COMPILER ESMF_COMM ESMF_NETCDF ESMF_NETCDF_INCLUDE ESMF_NETCDF_LIBPATH ESMF_PNETCDF ESMF_PNETCDF_INCLUDE ESMF_PNETCDF_LIBPATH ESMF_PROJ4 ESMF_PROJ4_INCLUDE ESMF_PROJ4_LIBPATH ESMF_YAMLCPP ESMF_CXXCOMPILEOPTS ESMF_F90COMPILEOPTS ESMF_NUM_PROCS ESMF_OPTLEVEL ESMF_MPIMPMDRUN'

commonesmfvars='export ESMF_OS=Linux; export ESMF_ABI=64; export ESMF_SITE=default; export ESMF_TESTEXHAUSTIVE=ON; export ESMF_TESTWITHTHREADS=OFF; export ESMF_MPIRUN=mpirun'
localcommonesmfvars='export ESMF_OS=Linux export ESMF_ABI=64 export ESMF_SITE=default export ESMF_TESTEXHAUSTIVE=ON export ESMF_TESTWITHTHREADS=OFF export ESMF_MPIRUN=mpirun'

# all cases (disk quota issues on discover)
# declare -a LibTests=("gfortran481mpiunilib" "gfortran481mvapich2lib" "gfortran481openmpilib" "intel17mvapich2lib" "intel1803openmpilib" "intel1805mpiunilib" "intel1805impilib" "nag62mpiunilib" "pgi14mvapich2lib" "pgi17mpiunilib" "pgi17openmpilib")

# gfortran481
# declare -a LibTests=("gfortran481mpiunilib" "gfortran481mvapich2lib" "gfortran481openmpilib")

# intel
# declare -a LibTests=("intel17mvapich2lib" "intel1803openmpilib" "intel1805mpiunilib" "intel1805impilib")

# nag and pgi
# declare -a LibTests=("nag62mpiunilib" "pgi14mvapich2lib" "pgi17mpiunilib" "pgi17openmpilib")
# declare -a LibTests=("nag62mpiunilib" "pgi17mpiunilib" "pgi17openmpilib")

# esmpy
declare -a LibTests=("gfortran492mpiuniesmpy" "gfortran492mvapich2esmpy" "intel17mpiuniesmpy" "intel17mvapich2esmpy" "pgi17mpiuniesmpy" "pgi17openmpiesmpy")

# g and O
declare -a Mode=("g" "O")

# set working directories
# following are for local tests
# scriptdir=/home/ryan/sandbox/esmf_dev/discover801testing
# homedir='export homedir=/home/ryan/sandbox/test_scripts/manual_testing'
# workdir=/home/ryan/discovertesting801
scriptdir=$NOBACKUP/sandbox/esmf_dev/discover801testing
homedir='export homedir=$NOBACKUP/sandbox/test_scripts/manual_testing'
workdir=$NOBACKUP/discovertesting801

# create rundir
RUNDIR=$(python $scriptdir/run_id.py $workdir 2>&1)
mkdir $RUNDIR

for test in "${LibTests[@]}"; do
  cd $RUNDIR

  # activate the specific test variables
  $localcommonesmfvars
  $test
  $modules
  $localesmfenv

  for mode in "${Mode[@]}"; do
    # create test directory
    TESTDIR=$RUNDIR/$test-$mode
    mkdir $TESTDIR
    cd $TESTDIR
    echo $TESTDIR
    
    # set up test parameters
    esmfdir='export ESMF_DIR=$TESTDIR/esmf'
    esmfbopt='export ESMF_BOPT=$mode'
    logdir='export LOGDIR=$TESTDIR/logs'
    mkdir $TESTDIR/logs

    # clone esmf and checkout appropriate tag
    git clone git@github.com:esmf-org/esmf.git
    cd esmf
    git checkout ESMF_8_0_1

    # special handling for external demos, esmpy, etc
    case $test in
      *esmpy)
        # dryrun for regrid_from_file
        cd $TESTDIR/esmf
        export ESMF_BOPT=$mode
        make -j8 1> make.out 2>&1
        export ESMFMKFILE=$TESTDIR/esmf/lib/lib$mode/$ESMF_OS.$ESMF_COMPILER.$ESMF_ABI.$ESMF_COMM.$ESMF_SITE/esmf.mk
        echo $ESMFMKFILE
        cd $TESTDIR/esmf/src/addon/ESMPy
        python setup.py build
        python setup.py test_regrid_from_file_dryrun

        # add esmpy test target
        sed "s&test_esmf_local&test_esmpy_local&g;" $scriptdir/esmftest.slurm > esmftest-$test-$mode.slurm
      ;;
      # # NOTE: doesn't work well because of need to dryrun RWGC and RC on login node before submitting to queue
      # *ed)
      #   # checkout external demos
      #   echo "cloning external_demos..."
      #   git clone git://git.code.sf.net/p/esmf/external_demos external_demos >/dev/null 2>&1
      #   cd external_demos
      #   git checkout ESMF_8_0_1
      #   mkdir ESMF_RegridWeightGenCheck/input
      #   cp $scriptdir/rwgdata/* ESMF_RegridWeightGenCheck/input/
      #   cd ..
      # 
      #   # set the demodir variable
      #   demodir="export DEMODIR=$TESTDIR/external_demos"
      # 
      #   # modify esmftest.slurm script to call test_external_demos_local and include demodir
      #   cp esmftest-$test-$mode.slurm esmftest-$test-$mode.slurmtemp
      #   sed "s&test_esmf_local&test_external_demos_local&g; s&#demodir#&$demodir&g" esmftest-$test-$mode.slurmtemp > esmftest-$test-$mode.slurm
      #   rm esmftest-$test-$mode.slurmtemp
      # ;;
    esac

    # set up the script for submission
    cd $TESTDIR
    cp esmftest-$test-$mode.slurm esmftest-$test-$mode.slurmtemp
    sed "s&#testname#&$test-$mode&g; s&#homedir#&$homedir&g; s&#logdir#&$logdir&g; s&#modules#&$modules&g; s&#clearesmfvars#&$clearesmfvars&g; s&#esmfdir#&$esmfdir&g; s&#commonesmfvars#&$commonesmfvars&g; s&#esmfenv#&$esmfenv&g; s&#esmfbopt#&$esmfbopt&g" esmftest-$test-$mode.slurmtemp > esmftest-$test-$mode.slurm
    rm esmftest-$test-$mode.slurmtemp


    # run the test
    echo "sbatch esmftest-$test-$mode.slurm"
    sbatch esmftest-$test-$mode.slurm
  done
done
