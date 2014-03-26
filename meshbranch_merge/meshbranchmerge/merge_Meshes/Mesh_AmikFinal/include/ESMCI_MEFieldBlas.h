#ifndef ESMCI_MEFieldBlas_h
#define ESMCI_MEFieldBlas_h

#include <Mesh/include/ESMCI_MeshTypes.h>
#include <Mesh/include/ESMCI_MEField.h>

namespace ESMCI {

class Mesh;

/** 
 * Fill all of the active dofs for this field to the value n
 */
template <typename Number>
void MEFieldFill(const Mesh &mesh, MEField<> &Field, Number n);

/**
 * Set Field = Field + a*RhsField
 * Fields should be registered on the same part of the mesh.
 */
template <typename Number>
void MEFieldAdd(const Mesh &mesh, MEField<> &Field, Number a, MEField<> &RhsField);

/**
 * set Field = s*field + a*RhsField
 */
template <typename Number>
void MEFieldSAdd(const Mesh &mesh, MEField<> &Field, Number s, Number a, MEField<> &RhsField);

/**
 * Set Field = RhsField. 
 */
template <typename Number>
void MEFieldAssign(const Mesh &mesh, MEField<> &Field, MEField<> &RhsField);

} // namespace


#endif
