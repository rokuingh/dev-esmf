from mpi4py import MPI

import ESMF


comm = MPI.COMM_WORLD
gtot = comm.reduce(comm.rank, op=MPI.SUM)

mg = ESMF.Manager()

# if comm.rank == 0:
#  print gtot
