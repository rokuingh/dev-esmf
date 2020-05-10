#!/bin/bash 
#SBATCH -J test_esmf_local
#SBATCH --ntasks=16
#SBATCH --time=4:00:00
#SBATCH -o output.%j
#SBATCH --account=s1184

%homedir%
%logdir%

%modules%

%esmfdir%
%esmfenv%
%esmfbopt%
%commonesmfvars%

bash $homedir/test_esmf_local > out.out

exit 0