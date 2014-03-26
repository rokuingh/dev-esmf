#include <Mesh/include/ESMCI_Migrator.h>
#include <Mesh/include/ESMCI_ParEnv.h>

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
    lids.resize(ndest_gids);
    for (UInt i = 0; i < ndest_gids; i++)
      lids[i] = i;
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
