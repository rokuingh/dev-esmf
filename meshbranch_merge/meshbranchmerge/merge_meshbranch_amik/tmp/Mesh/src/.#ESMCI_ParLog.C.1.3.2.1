#include <Mesh/include/ESMCI_ParLog.h>

#include <mpi.h>
#include <cstdlib>


namespace ESMCI {

ParLog *ParLog::instance(const std::string &fstem) {
  
  if (classInstance) return classInstance;

  int rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  char buf[512];
  std::sprintf(buf, "%s.%d", fstem.c_str(), rank);
  classInstance = new ParLog(buf);
  return classInstance;
}

ParLog::ParLog(const std::string &fname) :
of(fname.c_str(), std::ios::out)
{
}

} // namespace
