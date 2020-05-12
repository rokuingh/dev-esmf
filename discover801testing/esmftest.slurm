#!/bin/bash 
#SBATCH -J %testname%
#SBATCH --ntasks=16
#SBATCH --time=4:00:00
#SBATCH -o output.%j
#SBATCH --account=s1184

%homedir%
%logdir%

%modules%

%esmfdir%
# commonesmfvars before esmfenv to overwrite ESMF_MPIRUN for mpiuni cases
%commonesmfvars%
%esmfenv%
%esmfbopt%

bash $homedir/test_esmf_local > out.out

exit 0
