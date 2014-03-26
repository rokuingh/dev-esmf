#ifndef ESMCI_MeshGMSH_h
#define ESMCI_MeshGMSH_h

#include <string>

namespace ESMCI {

class Mesh;
void ReadGMSHMesh(Mesh &mesh, const std::string &filename, int nstep = 1);

} // namespace

#endif
