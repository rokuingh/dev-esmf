#!/bin/bash

# Ryan O'Kuinghttons
# May 19, 2020
# script to run all cheyenne platforms for ESMF testing

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function intel1805mptlib () {
modules='module purge; module load ncarenv/1.3 ncarcompilers/0.5.0 intel/18.0.5 mpt/2.19 netcdf/4.6.3'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpt; export ESMF_MPIRUN=mpiexec_mpt'
}

function intel1805openmpilib () {
modules='module purge; module load ncarenv/1.3 ncarcompilers/0.5.0 intel/18.0.5 openmpi/3.1.4 netcdf/4.6.3'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=openmpi;'
}

function intel1805impilib () {
modules='module purge; module load ncarenv/1.3 ncarcompilers/0.5.0 intel/18.0.5 impi/2018.4.274 netcdf/4.6.3'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi;'
}

function intel1902mptlib () {
modules='module purge; module load ncarenv/1.3 ncarcompilers/0.5.0 intel/19.0.2 mpt/2.19 netcdf-mpi/4.7.1 pnetcdf/1.11.0'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpt; export ESMF_NETCDF=nc-config; export ESMF_PIO=internal; export ESMF_TESTTRACE=ON; export ESMF_YAMLCPP=internal; export ESMF_MPIRUN=mpiexec_mpt'
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

clearesmfvars="unset ESMF_OS; unset ESMF_ABI; unset ESMF_SITE; unset ESMF_TESTEXHAUSTIVE; unset ESMF_TESTWITHTHREADS; unset ESMF_MPIRUN; unset ESMF_COMPILER; unset ESMF_COMM; unset ESMF_NETCDF; unset ESMF_NETCDF_INCLUDE; unset ESMF_NETCDF_LIBPATH; unset ESMF_PNETCDF; unset ESMF_PNETCDF_INCLUDE; unset ESMF_PNETCDF_LIBPATH; unset ESMF_PROJ4; unset ESMF_PROJ4_INCLUDE; unset ESMF_PROJ4_LIBPATH; unset ESMF_YAMLCPP; unset ESMF_CXXCOMPILEOPTS; unset ESMF_F90COMPILEOPTS; unset ESMF_NUM_PROCS; unset ESMF_OPTLEVEL; unset ESMF_MPIMPMDRUN"

commonesmfvars="export ESMF_OS=Linux; export ESMF_ABI=64; export ESMF_SITE=default; export ESMF_TESTEXHAUSTIVE=ON; export ESMF_TESTWITHTHREADS=OFF; export ESMF_MPIRUN=mpirun"


declare -a LibTests=("intel1805mptlib" "intel1805openmpilib" "intel1805impilib" "intel1902mptlib")

# g and O
declare -a Mode=("g" "O")

# set working directories
# following are for local tests
scriptdir=/home/ryan/sandbox/esmf_dev/cheyenne801testing
homedir="export homedir=/home/ryan/sandbox/test_scripts/manual_testing"
workdir=/home/ryan/cheyennetesting801
# scriptdir=/glade/work/rokuingh/sandbox/esmf_dev/cheyenne801testing
# homedir="export homedir=/glade/work/rokuingh/sandbox/test_scripts/manual_testing"
# workdir=/glade/work/rokuingh/cheyennetesting801

# create rundir
RUNDIR=$(python $scriptdir/run_id.py $workdir 2>&1)
mkdir $RUNDIR

for test in "${LibTests[@]}"; do
  cd $RUNDIR

  # activate the specific test variables
  $test

  for mode in "${Mode[@]}"; do
    # create test directory
    TESTDIR=$RUNDIR/$test-$mode
    mkdir $TESTDIR
    cd $TESTDIR
    echo $TESTDIR
    
    # set up test parameters
    esmfdir="export ESMF_DIR=$TESTDIR/esmf"
    esmfbopt="export ESMF_BOPT=$mode"
    logdir="export LOGDIR=$TESTDIR/logs"
    mkdir $TESTDIR/logs

    # clone esmf and checkout appropriate tag
    echo "cloning esmf..."
    # git clone git@github.com:esmf-org/esmf.git >/dev/null 2>&1
    # cd esmf
    # git checkout ESMF_8_0_1
    # cd ..

    # sbatch --export,--get-user-env doesn't work, so manually set the environment
    sed "s&#testname#&$test-$mode&g; s&#homedir#&$homedir&g; s&#logdir#&$logdir&g; s&#modules#&$modules&g; s&#clearesmfvars#&$clearesmfvars&g; s&#esmfdir#&$esmfdir&g; s&#commonesmfvars#&$commonesmfvars&g; s&#esmfenv#&$esmfenv&g; s&#esmfbopt#&$esmfbopt&g" $scriptdir/esmftest.pbs > esmftest-$test-$mode.pbs
  
    # run the test
    echo "qsub esmftest-$test-$mode.pbs"
    # qsub esmftest-$test-$mode.pbs
  done
done
