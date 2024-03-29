<<<<<<< ESMCI_Migrator.C
=======
// $Id: ESMCI_Migrator.C,v 1.5 2010/03/04 18:57:45 svasquez Exp $
//
// Earth System Modeling Framework
// Copyright 2002-2010, University Corporation for Atmospheric Research, 
// Massachusetts Institute of Technology, Geophysical Fluid Dynamics 
// Laboratory, University of Michigan, National Centers for Environmental 
// Prediction, Los Alamos National Laboratory, Argonne National Laboratory, 
// NASA Goddard Space Flight Center.
// Licensed under the University of Illinois-NCSA License.
//
//==============================================================================
>>>>>>> 1.5
#include <Mesh/include/ESMCI_Migrator.h>
#include <Mesh/include/ESMCI_ParEnv.h>

//-----------------------------------------------------------------------------
// leave the following line as-is; it will insert the cvs ident string
// into the object file for tracking purposes.
static const char *const version = "$Id: ESMCI_Migrator.C,v 1.5 2010/03/04 18:57:45 svasquez Exp $";
//-----------------------------------------------------------------------------

namespace ESMCI { 

Migrator::Migrator(UInt ndest_gids, const UInt dest_gids[],
    const UInt *dest_lids,
    UInt nsrc_gids, const UInt src_gids[]) :
  dir(),
  response(),
  ndest_gid(ndest_gids)
{
  Trace __trace("Migrator::Migrator(UInt ndest_gids, const UInt dest_gids[], const UInt *dest_lids, UInt nsrc_gids, const UInt src_gids[])");
  
  std::vector<UInt> lids;
  
  // Assign default lids, if not provided
  if (!dest_lids) {
    if (ndest_gids > 0) {
      lids.resize(ndest_gids);
      for (UInt i = 0; i < ndest_gids; i++)
        lids[i] = i;
    } else {
      lids.resize (1);
      lids[0] = 0;
    }
  }
  
  dir.Create(ndest_gids, dest_gids, dest_lids ? dest_lids : &lids[0]);
  //dir.Print(Par::Out());
  
  // Get the responses.  Use the first line to
  // assure that each object ends up somewhere (true flag).  In the second
  // line, it is possible that an entry will be lost (if no one requests it)
  dir.RemoteGID(nsrc_gids, src_gids, response, false);
  //dir.RemoteGID(nsrc_gids, src_gids, response);
  
  // We don't need the directory anymore
  dir.clear();
  
}

Migrator::Migrator(DDir<> &_dir, UInt nsrc_gids, const UInt src_gids[]) :
  dir(),
  response(),
  ndest_gid(0)
{
  Trace __trace("Migrator::Migrator(UInt ndest_gids, const UInt dest_gids[], const UInt *dest_lids, UInt nsrc_gids, const UInt src_gids[])");
  
  //dir.Print(Par::Out());
  
  // Get the responses.  Use the first line to
  // assure that each object ends up somewhere (true flag).  In the second
  // line, it is possible that an entry will be lost (if no one requests it)
  _dir.RemoteGID(nsrc_gids, src_gids, response, false);
  //dir.RemoteGID(nsrc_gids, src_gids, response);
  
}


} // namespace
