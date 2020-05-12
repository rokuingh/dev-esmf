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
# mapl:
# intel15impimapl
# 
# external demos/bfb:
# intel1801impied
# pgi18openmpied

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# run g and O of all three
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

# run g and O of both, for esmpy
function gfortran492mpiuniesmpy () {
modules='module purge; module load other/comp/gcc-4.9.2-sp3 lib/mkl-15.0.2.164 other/mpi/mvapich2-2.1/gcc-4.9.2-sp3 other/SIVO-PyD/spd_1.24.0_gcc-4.9.2-sp3_mkl-15.0.2.164_mvapich2-2.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}
function gfortran492mvapich2esmpy () {
modules='module purge; module load other/comp/gcc-4.9.2-sp3 lib/mkl-15.0.2.164 other/mpi/mvapich2-2.1/gcc-4.9.2-sp3 other/SIVO-PyD/spd_1.24.0_gcc-4.9.2-sp3_mkl-15.0.2.164_mvapich2-2.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mvapich2; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O, for mapl
function intel15impimapl () {
modules='module purge; module load comp/intel-15.0.2.164 mpi/impi-5.0.3.048 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_intel-14.0.3.174_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_intel-14.0.3.174_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O of mvapich2 for the lib
function intel17mvapich2lib () {
modules='module purge; module load comp/intel-17.0.4.196 other/mpi/mvapich2-2.3b/intel-17.0.4.196 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mvapich2; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_PNETCDF=standard; export ESMF_PNETCDF_INCLUDE=/usr/local/other/SLES11.1/pnetcdf/1.4.1/intel-14.0.1.106-impi-4.1.1.036/include; export ESMF_PNETCDF_LIBPATH=/usr/local/other/SLES11.1/pnetcdf/1.4.1/intel-14.0.1.106-impi-4.1.1.036/lib'
}

# run g and O of mpiuni and mvapich2, for esmpy
function intel17mpiuniesmpy () {
modules='module purge; module load comp/intel-17.0.4.196 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/lib; export ESMF_YAMLCPP=OFF; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}
function intel17mvapich2esmpy () {
modules='module purge; module load comp/intel-17.0.4.196 other/mpi/mvapich2-2.3b/intel-17.0.4.196 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mvapich2; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

# run g and O (maybe with optlevel=2), for external demos b4b
function intel1801impied () {
modules='module purge; module load comp/intel-18.0.1.163 mpi/impi-5.1.2.150 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_NETCDF=/usr/local/other/netcdf/4.1.2_intel-14.0.3/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O, for lib, no netcdf
function intel1803openmpilib () {
modules='module purge; module load comp/intel-18.0.3.222 other/mpi/openmpi/3.1.1-intel-18.0.3.222 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=openmpi; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O of both, for lib, no netcdf
function intel1805mpiunilib () {
modules='module purge; module load comp/intel-18.0.5.274 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpiuni; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}
function intel1805impilib () {
modules='module purge; module load comp/intel-18.0.5.274 mpi/impi-18.0.5.274'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O, for lib
function nag62mpiunilib () {
modules='module purge; module load comp/nag-6.2-6204'
esmfenv='export ESMF_COMM=mpiuni; export ESMF_COMPILER=nag; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}

# run g and O for mvapich2
# function pgi14mpiunilib='module purge; module load comp/pgi-14.1.0; export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
function pgi14mvapich2lib () {
modules='module purge; module load comp/pgi-14.1.0 other/mpi/mvapich2-2.0b/pgi-14.1.0'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mvapich2; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

# run g and O for both, for esmpy, regridfromfile test on O, openmpi
# function pgi17mpiuniesmpy () {
# modules='module purge; module load comp/pgi-17.5.0'
# esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
# }
function pgi17openmpiesmpy () {
modules='module purge; module load comp/pgi-17.5.0 other/mpi/openmpi/2.1.1-pgi-17.5.0 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; ESMF_YAMLCPP=OFF'
}

# run g and O for both
function pgi17mpiunilib () {
modules='module purge; module load comp/pgi-17.7.0'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
}
function pgi17openmpilib () {
modules='module purge; module load comp/pgi-17.7.0 other/mpi/openmpi/2.1.1-pgi-17.7.0-k40'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

# run g and O for openmpi, for external demos
# function pgi18mpiunilib () {
# modules='module purge; module load comp/pgi-18.5.0'
# esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11.1/netcdf4/pgi-14.9.0/bin/nc-config; export ESMF_MPIRUN=$ESMF_DIR/src/Infrastructure/stubs/mpiuni/mpirun'
# }
function pgi18openmpied () {
modules='module purge; module load comp/pgi-18.5.0 other/mpi/openmpi/3.1.1-pgi-18.5.0-k40'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=/usr/local/other/SLES11.1/netcdf4/pgi-14.9.0/bin/nc-config'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

commonesmfvars="export ESMF_OS=Linux; export ESMF_ABI=64; export ESMF_SITE=default; export ESMF_TESTEXHAUSTIVE=ON; export ESMF_TESTWITHTHREADS=OFF; export ESMF_MPIRUN=mpirun"


# all cases (disk quota issues on discover)
# declare -a LibTests=("gfortran481" "intel17" "intel1803" "intel1805" "nag62" "pgi14" "pgi17")

# gfortran
declare -a LibTests=("gfortran481")

# intel
# declare -a LibTests=("intel17" "intel1803" "intel1805")

# nagpgi
# declare -a LibTests=("nag62" "pgi14" "pgi17")

# test with just one
# declare -a LibTests=("intel17mvapich2lib")


# gfortran481
declare -a gfortran481=("gfortran481mpiunilib" "gfortran481mvapich2lib" "gfortran481openmpilib")

# intel17
declare -a intel17=("intel17mvapich2lib")

# intel1803
declare -a intel1803=("intel1803openmpilib")

# intel1805
declare -a intel1805=("intel1805mpiunilib" "intel1805impilib")

# nag62
declare -a nag62=("nag62mpiunilib")

# pgi14
declare -a pgi14=("pgi14mvapich2lib")

# pgi17
declare -a pgi17=("pgi17mpiunilib" "pgi17openmpilib")

# g and O
declare -a Mode=("g" "O")

# set working directories
# following are for local tests
# scriptdir=/home/ryan/sandbox/esmf_dev/discover801testing
# homedir="export homedir=/home/ryan/sandbox/test_scripts/manual_testing"
# workdir=/home/ryan/discovertesting801
scriptdir=$NOBACKUP/sandbox/esmf_dev/discover801testing
homedir="export homedir=$NOBACKUP/sandbox/test_scripts/manual_testing"
workdir=$NOBACKUP/discovertesting801

# create rundir
RUNDIR=$(python $scriptdir/run_id.py $workdir 2>&1)
mkdir $RUNDIR

# function to replace nameref in >4.3 bash (thank you discover)
submitcombos ()
{
  # nameref magic
  local testproxy="${1}[@]"
  local testproxyname="${1}"
  local testproxyvals=("${!testproxy}")

  # set up test parameters
  TESTPROXYDIR=$RUNDIR/$testproxyname
  mkdir $TESTPROXYDIR/logs
  logdir="export LOGDIR=$TESTPROXYDIR/logs"
  esmfdir="export ESMF_DIR=$TESTPROXYDIR/esmf"
  

  # actually iterate the combos and submit the jobs
  for combo in "${testproxyvals[@]}"; do
    # set the case specific variables, via function
    $combo

    for mode in "${Mode[@]}"; do
      # set up test parameters
      esmfbopt="export ESMF_BOPT=$mode"
    
      # sbatch --export,--get-user-env doesn't work, so manually set the environment
      sed "s&%testname%&$combo-$mode&g; s&%homedir%&$homedir&g; s&%logdir%&$logdir&g; s&%modules%&$modules&g; s&%esmfdir%&$esmfdir&g; s&%commonesmfvars%&$commonesmfvars&g; s&%esmfenv%&$esmfenv&g; s&%esmfbopt%&$esmfbopt&g" $scriptdir/esmftest.slurm > esmftest-$combo-$mode.slurm
  
      # run the test
      echo "sbatch esmftest-$combo-$mode.slurm"
      # sbatch esmftest--$combo-$mode.slurm
    done
  done
}

for test in "${LibTests[@]}"; do
  cd $RUNDIR
  
  # create test directory
  TESTDIR=$RUNDIR/$test
  mkdir $TESTDIR
  cd $TESTDIR
  echo $TESTDIR
  
  # clone esmf and checkout appropriate tag
  echo "cloning esmf..."
  git clone git@github.com:esmf-org/esmf.git >/dev/null 2>&1
  cd esmf
  git checkout ESMF_8_0_1_beta_snapshot_13
  cd ..

  submitcombos $test

done
