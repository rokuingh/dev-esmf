#!/bin/bash

# Ryan O'Kuinghttons
# May 9, 2020
# script to run all discover platforms for ESMF testing
# view jobs in queue with squeue --user=<user>


# discover platforms (g and O for all):
# 
# lib: 
# esmfgfortran481mpiuni - fail (c++11?)
# esmfgfortran481mvapich2
# esmfgfortran481openmpi
# esmfintel17mvapich2
# esmfintel1803openmpi
# esmfintel1805mpiuni
# esmfintel1805impi
# esmfnag
# esmfpgi14mvapich2
# esmfpgi17mpiuni
# esmfpgi17openmpi
# 
# esmpy:
# esmpygfortran492mpiuni
# esmpygfortran492mvapich2
# esmpyintel17mpiuni
# esmpyintel17mvapich2
# esmpypgi17openmpi
# 
# mapl:
# maplintel15impi
# 
# external demos/bfb:
# edintel1801impi
# edpgi18openmpi

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

shopt -s expand_aliases

commonesmfvars="export ESMF_OS=Linux; export ESMF_ABI=64; export ESMF_SITE=default; export ESMF_TESTEXHAUSTIVE=ON; export ESMF_TESTWITHTHREADS=OFF; export ESMF_MPIRUN=mpirun"

# alias clearesmfvars="unset ESMF_COMPILER; unset ESMF_COMM; unset ESMF_NETCDF; unset ESMF_NETCDF_INCLUDE; unset ESMF_NETCDF_LIBPATH; unset ESMF_PNETCDF; unset ESMF_PNETCDF_INCLUDE; unset ESMF_PNETCDF_LIBPATH; unset ESMF_CXXCOMPILEOPTS; unset ESMF_F90COMPILEOPTS; unset ESMF_PROJ4; unset ESMF_PROJ4_INCLUDE; unset ESMF_PROJ4_LIBPATH; unset ESMF_YAMLCPP"

# run g and O of all three
function esmfgfortran481mpiuni () {
modules='module purge; module load other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mpiuni; export ESMF_NETCDF=standard; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS=-fbounds-check; export ESMF_F90COMPILEOPTS=-fbounds-check'
}
function esmfgfortran481mvapich2 () {
modules='module purge; module load other/comp/gcc-4.8.1 other/mpi/mvapich2-1.9/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mvapich2; export ESMF_NETCDF=standard; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS=-fbounds-check; export ESMF_F90COMPILEOPTS=-fbounds-check'
}
function esmfgfortran481openmpi () {
modules='module purge; module load other/comp/gcc-4.8.1 other/mpi/openmpi/1.7.2-gcc-4.8.1-shared'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=openmpi; export ESMF_NETCDF=standard; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/3.6.3/gcc-4.8.1/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_CXXCOMPILEOPTS=-fbounds-check; export ESMF_F90COMPILEOPTS=-fbounds-check'
}

# run g and O of both, for esmpy
function esmpygfortran492mpiuni () {
modules='module purge; module load other/comp/gcc-4.9.2-sp3 lib/mkl-15.0.2.164 other/mpi/mvapich2-2.1/gcc-4.9.2-sp3 other/SIVO-PyD/spd_1.24.0_gcc-4.9.2-sp3_mkl-15.0.2.164_mvapich2-2.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib'
}
function esmpygfortran492mvapich2 () {
modules='module purge; module load other/comp/gcc-4.9.2-sp3 lib/mkl-15.0.2.164 other/mpi/mvapich2-2.1/gcc-4.9.2-sp3 other/SIVO-PyD/spd_1.24.0_gcc-4.9.2-sp3_mkl-15.0.2.164_mvapich2-2.1'
esmfenv='export ESMF_COMPILER=gfortran; export ESMF_COMM=mvapich2; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_gcc-4.9.2_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O, for mapl
function maplintel15impi () {
modules='module purge; module load comp/intel-15.0.2.164 mpi/impi-5.0.3.048 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_intel-14.0.3.174_sp3/include; export ESMF_NETCDF_LIBPATH=/discover/nobackup/projects/lis/libs/netcdf/4.3.3.1_intel-14.0.3.174_sp3/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O of mvapich2 for the lib
function esmfintel17mvapich2 () {
modules='module purge; module load comp/intel-17.0.4.196 other/mpi/mvapich2-2.3b/intel-17.0.4.196 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mvapich2; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_PNETCDF=standard; export ESMF_PNETCDF_INCLUDE=/usr/local/other/SLES11.1/pnetcdf/1.4.1/intel-14.0.1.106-impi-4.1.1.036/include; export ESMF_PNETCDF_LIBPATH=/usr/local/other/SLES11.1/pnetcdf/1.4.1/intel-14.0.1.106-impi-4.1.1.036/lib'
}

# run g and O of mpiuni and mvapich2, for esmpy
function esmpyintel17mpiuni () {
modules='module purge; module load comp/intel-17.0.4.196 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/lib; export ESMF_YAMLCPP=OFF'
}
function esmpyintel17mvapich2 () {
modules='module purge; module load comp/intel-17.0.4.196 other/mpi/mvapich2-2.3b/intel-17.0.4.196 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mvapich2; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.3/netcdf4/4.5.0/intel-17.0.4.196/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

# run g and O (maybe with optlevel=2), for external demos b4b
function edintel1801impi () {
modules='module purge; module load comp/intel-18.0.1.163 mpi/impi-5.1.2.150 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_NETCDF=/usr/local/other/netcdf/4.1.2_intel-14.0.3/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O, for lib, no netcdf
function esmfintel1803openmpi () {
modules='module purge; module load comp/intel-18.0.3.222 other/mpi/openmpi/3.1.1-intel-18.0.3.222 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=openmpi; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O of both, for lib, no netcdf
function esmfintel1805mpiuni () {
modules='module purge; module load comp/intel-18.0.5.274 other/comp/gcc-4.8.1'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=mpiuni; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}
function esmfintel1805impi () {
modules='module purge; module load comp/intel-18.0.5.274 mpi/impi-18.0.5.274'
esmfenv='export ESMF_COMPILER=intel; export ESMF_COMM=intelmpi; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O, for lib
function esmfnag () {
modules='module purge; module load comp/nag-6.2-6204'
esmfenv='export ESMF_COMM=mpiuni; export ESMF_COMPILER=nag; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib;'
}

# run g and O for mvapich2
# function esmfpgi14mpiuni='module purge; module load comp/pgi-14.1.0; export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config'
function esmfpgi14mvapich2 () {
modules='module purge; module load comp/pgi-14.1.0 other/mpi/mvapich2-2.0b/pgi-14.1.0'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mvapich2; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

# run g and O for both, for esmpy, regridfromfile test on O, openmpi
# function esmpypgi17mpiuni () {
# modules='module purge; module load comp/pgi-17.5.0'
# esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib'
# }
function esmpypgi17openmpi () {
modules='module purge; module load comp/pgi-17.5.0 other/mpi/openmpi/2.1.1-pgi-17.5.0 other/SSSO_Ana-PyD/SApd_4.2.0_py3.5'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=split; export ESMF_NETCDF_INCLUDE=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/include; export ESMF_NETCDF_LIBPATH=/usr/local/other/SLES11.1/netcdf/4.3.2/pgi-14.3.0/lib; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; ESMF_YAMLCPP=OFF'
}

# run g and O for both
function esmfpgi17mpiuni () {
modules='module purge; module load comp/pgi-17.7.0'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}
function esmfpgi17openmpi () {
modules='module purge; module load comp/pgi-17.7.0 other/mpi/openmpi/2.1.1-pgi-17.7.0-k40'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=/usr/local/other/SLES11/netcdf/4.1.3/pgi-12.6.0/bin/nc-config; export ESMF_PROJ4=external; export ESMF_PROJ4_INCLUDE=/home/scvasque/proj4/include; export ESMF_PROJ4_LIBPATH=/home/scvasque/proj4/lib; export ESMF_YAMLCPP=OFF'
}

# run g and O for openmpi, for external demos
# function esmfpgi18mpiuni () {
# modules='module purge; module load comp/pgi-18.5.0'
# esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=mpiuni; export ESMF_NETCDF=/usr/local/other/SLES11.1/netcdf4/pgi-14.9.0/bin/nc-config'
# }
function edpgi18openmpi () {
modules='module purge; module load comp/pgi-18.5.0 other/mpi/openmpi/3.1.1-pgi-18.5.0-k40'
esmfenv='export ESMF_COMPILER=pgi; export ESMF_COMM=openmpi; export ESMF_NETCDF=/usr/local/other/SLES11.1/netcdf4/pgi-14.9.0/bin/nc-config'
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# declare -a LibTests=("esmfgfortran481mpiuni" "esmfgfortran481mvapich2" "esmfgfortran481openmpi" "esmfintel17mvapich2" "esmfintel1803openmpi" "esmfintel1805mpiuni" "esmfintel1805impi" "esmfnag" "esmfpgi14mvapich2" "esmfpgi17mpiuni" "esmfpgi17openmpi")
# test with just one
declare -a LibTests=("esmfintel17mvapich2")

# g and O
# declare -a Mode=("g" "O")
# test with just one
declare -a Mode=("g")

homedir="export homedir=/discover/nobackup/rokuingh/sandbox/test_scripts/manual_testing"
# homedir="export homedir=/home/ryan/sandbox/test_scripts/manual_testing"
export scriptdir=/discover/nobackup/rokuingh/sandbox/esmf_dev/discover801testing
# export scriptdir=/home/ryan/sandbox/esmf_dev/discover801testing

# set the run number
workdir=/discover/nobackup/rokuingh/discovertesting801
# workdir=/home/ryan/discovertesting801
# create rundir
RUNDIR=$(python $scriptdir/run_id.py $workdir 2>&1)
echo $RUNDIR
mkdir $RUNDIR

for test in "${LibTests[@]}"; do
  for mode in "${Mode[@]}"; do
    cd $RUNDIR

    # create test directory
    mkdir $test-$mode
    cd $test-$mode
    echo $PWD

    # clone esmf
    echo "cloning esmf..."
    git clone git@github.com:esmf-org/esmf.git >/dev/null 2>&1
    cd esmf
    git checkout ESMF_8_0_1_beta_snapshot_13
    cd ..
  
    # set up test parameters
    mkdir logs
    logdir="export LOGDIR=$PWD/logs"
    esmfdir="export ESMF_DIR=$PWD/esmf"
    esmfbopt="export ESMF_BOPT=$mode"
  
    # set the case specific variables, via function
    $test

    # sbatch --export,--get-user-env doesn't work, so manually set the environment
    sed "s&%homedir%&$homedir&g; s&%logdir%&$logdir&g; s&%modules%&$modules&g; s&%esmfdir%&$esmfdir&g; s&%esmfenv%&$esmfenv&g; s&%esmfbopt%&$esmfbopt&g; s&%commonesmfvars%&$commonesmfvars&g" $scriptdir/test_esmf.slurm > test_esmf.slurm

    # run the test
    echo "sbatch test_esmf.slurm"
    sbatch test_esmf.slurm
  
    # do anything special with the output?

  done
done
