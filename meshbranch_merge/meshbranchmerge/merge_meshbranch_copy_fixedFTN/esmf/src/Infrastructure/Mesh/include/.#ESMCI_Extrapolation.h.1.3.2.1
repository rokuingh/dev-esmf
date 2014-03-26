#ifndef ESMCI_EXTRAPOLATION_H_
#define ESMCI_EXTRAPOLATION_H_

#include <Mesh/include/ESMCI_MeshTypes.h>

namespace ESMCI {

class Mesh; class Context; class IWeights;

/*
 * Assuming the input grid has a north latitude just below the north pole,
 * add and triangulate the north pole region.  Set the given context id on the
 * manufactured pole node (to mark as a constrained node).  We identify
 * the northern boundary by finding the z coord
 * and taking exposed_boundary nodes > z_north.  Obviously this makes assumptions
 * that the lat/lon is mapped on the unit sphere, z=north.
 * We pass the elem_ctxt,
 * which will be imprinted on all newly created elements (hence their nodes
 * will receive the proper ME imprint.
 * 
 * This function should be called collectively, but while the entire mesh is still on
 * processor (for now) zero.
 * 
 * TODO: Make work for quadratic meshes;
 */
void MeshAddNorthPole(Mesh &mesh, const Context &elem_ctxt,
                      UInt constraint_id, 
                      double z_north,
                      IWeights &cweights);

void MeshAddPole(Mesh &mesh, UInt node_id,
                      UInt constraint_id,
                      IWeights &cweights);

} // namespace

#endif /*ESMCI_EXTRAPOLATION_H_*/
