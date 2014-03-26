#include <Mesh/include/ESMCI_MCoord.h>
#include <cmath>

namespace ESMCI {

MCoord::MCoord(const double c[], const double n[]) {
  for (UInt i = 0; i < SpaceDim(); i++) {
    ct[i] = c[i];
  }
  if(n != NULL){
    double tmp = std::sqrt(n[1]*n[1] + n[2]*n[2]);
    // An orthogonal basis for the cospace of the vector n;
    u[0] = 0; u[1] = n[2]/tmp; u[2] = -n[1]/tmp;
    u[3] = tmp; u[4] = -n[0]*n[1]/tmp; u[5] = -n[0]*n[2]/tmp;
  }else{
    for (UInt i = 0; i < 3; i++) {
      u[2*i] = 0;
      u[2*i+1] = 0;
    }
  }
}

MCoord::MCoord() {
  for (UInt i = 0; i < 3; i++) {
    ct[i] = 0;
    u[2*i] = 0;
    u[2*i+1] = 0;
  }
}

MCoord &MCoord::operator=(const MCoord &rhs) {
  if (this == &rhs) return *this;
  
  for (UInt i = 0; i < 3; i++) {
    ct[i] = rhs.ct[i];
    u[2*i] = rhs.u[2*i];
    u[2*i+1] = rhs.u[2*i+1];
  }

  return *this;
}

MCoord::MCoord(const MCoord &rhs) {

  *this = rhs;
  
}

void MCoord::Transform(const double in[], double out[]) const {
  for (UInt i = 0; i < ManifoldDim(); i++) {
    out[i] = 0;
    for (UInt j = 0; j < SpaceDim(); j++) {
      out[i] += (in[j] - ct[j])*u[i*SpaceDim() + j];
    }
  }
}

} // namespace
