#!/bin/bash 
#SBATCH -J #testname#
#SBATCH --ntasks=16
#SBATCH --time=4:00:00
#SBATCH -o output.%j
#SBATCH --account=s1184

#homedir#
#logdir#

#modules#

#clearesmfvars#

#esmfdir#

# commonesmfvars before esmfenv to overwrite ESMF_MPIRUN for mpiuni cases
#commonesmfvars#
#esmfenv#
#esmfbopt#

#demodir#

bash $homedir/test_esmf_local > test_esmf_local.out

exit 0
