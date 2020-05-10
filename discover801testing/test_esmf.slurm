#!/bin/bash 
#SBATCH -J test_esmf_local
#SBATCH --ntasks=16
#SBATCH --time=4:00:00
#SBATCH -o output.%j
#SBATCH --account=s1184
#SBATCH --workdir=/discover/nobackup/rokuingh



bash $homedir/test_esmf_local > out.out

#mv mailMessage esmfintel17mvapich2.out

exit 0