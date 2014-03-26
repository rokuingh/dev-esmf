// $Id$
// Earth System Modeling Framework
// Copyright 2002-2010, University Corporation for Atmospheric Research, 
// Massachusetts Institute of Technology, Geophysical Fluid Dynamics 
// Laboratory, University of Michigan, National Centers for Environmental 
// Prediction, Los Alamos National Laboratory, Argonne National Laboratory, 
// NASA Goddard Space Flight Center.
// Licensed under the University of Illinois-NCSA License.

//
//-----------------------------------------------------------------------------
#ifndef ESMCI_MeshRead
#define ESMCI_MeshRead

#include <mpi.h>

#include <Mesh/include/ESMCI_Mesh.h>

namespace ESMCI {

enum { ESMCI_FILE_EXODUS = 0, ESMCI_FILE_VTK=1, ESMCI_FILE_VTKXML=2, ESMCI_FILE_GMSH=3 };

// Read the mesh in parallel (append the correct strings to the local filename)
// Create the shared CommRel.
void ReadMesh(Mesh &mesh, const std::string &fbase, bool skin=true, int file_type=ESMCI_FILE_EXODUS);

void WriteMesh(const Mesh &mesh, const std::string &fbase, int step = 1, double tstep=0.0, int file_type=ESMCI_FILE_EXODUS);

void WriteMeshTimeStep(const Mesh &mesh, const std::string &fbase, int step = 1, double tstep = 0.0);

} // namespace

#endif
