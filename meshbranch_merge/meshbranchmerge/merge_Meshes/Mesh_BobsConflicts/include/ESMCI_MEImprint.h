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
#ifndef ESMCI_MEImprint_h
#define ESMCI_MEImprint_h

#include <Mesh/include/ESMCI_MeshObj.h>
#include <Mesh/include/ESMCI_MEField.h>

#include <string>
#include <vector>


namespace ESMCI {

class MasterElementBase;

void MEImprintValSets(const MasterElementBase &me, std::set<std::pair<UChar,UInt> > &sets);

// Imprint a mesh object with the necessary contexts to define a field
// A common name should be used when imprinting a family of objects, e.g.
// linear lagrange
// Returns number of distinct contexts found
void MEImprint(MEFieldBase::CtxtMap &l2c, MeshObj &obj,
               const MasterElementBase &me);

} // namespace

#endif
