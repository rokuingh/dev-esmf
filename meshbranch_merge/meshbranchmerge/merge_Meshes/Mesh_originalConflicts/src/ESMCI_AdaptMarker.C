#include <Mesh/include/ESMCI_AdaptMarker.h>
#include <Mesh/include/ESMCI_Mesh.h>
#include <Mesh/include/ESMCI_HAdapt.h>
#include <Mesh/include/ESMCI_ParEnv.h>
#include <Mesh/include/ESMCI_Exception.h>

#include <limits>
#include <cmath>
#include <mpi.h>


namespace ESMCI {

QuantileMarker::QuantileMarker(HAdapt &hadapt, MEField<> &err, double top_frac, double bot_frac, UInt max_level) {

  Mesh &mesh = hadapt.GetMesh();
  
  std::vector<double> evals; // Gather errors
  evals.reserve(mesh.num_elems());

  KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end();
  for (; ki != ke; ++ki) {

    Kernel &ker = *ki;

   
    
    if (!ker.type() == MeshObj::ELEMENT ||
        !ker.is_active()) continue;

    Kernel::obj_iterator oi = ker.obj_begin(), oe = ker.obj_end();
    for (; oi != oe; ++oi) {

      MeshObj &elem = *oi;
  
      double *e = err.data(elem);
  
      if (e) {
        evals.push_back(e[0]);
      }
    } // oi

  } // ki
  
  std::sort(evals.begin(), evals.end());

  int N = evals.size();

  MPI_Allreduce(&N, &N, 1, MPI_INT, MPI_SUM, Par::Comm());

  
  double min_err = std::numeric_limits<double>::max();
  double max_err = -std::numeric_limits<double>::max();

  UInt tN = (UInt) (N*top_frac+0.5), bN = (UInt) (N*bot_frac+0.5);
  
  if (evals.size() > 0) {

    min_err = *evals.begin();
    max_err = evals[evals.size()-1];

Par::Out() << "N=" << N << ", tN=" << tN << ", bN=" << bN << ", min err:" << min_err << ", max_err=" << max_err << std::endl;

  }

  double gmin_err, gmax_err;

  MPI_Allreduce(&min_err, &gmin_err, 1, MPI_DOUBLE, MPI_MIN, Par::Comm());
  MPI_Allreduce(&max_err, &gmax_err, 1, MPI_DOUBLE, MPI_MAX, Par::Comm());

Par::Out() << "gmin_err=" << gmin_err << ", gmax_err=" << gmax_err << std::endl;

  // Ok.  Here is a really dumb algorithm for trying to find the quantile.  Will
  // replace when a better comes along.  I think the algorithm is dumb
  // because it requires so many global reductions.

  const UInt num_iter = 7; // max iter

  double tguess = 0.5*(gmin_err + gmax_err);
  double bguess = tguess, lbguess = tguess;
  double ltguess = tguess;
  double stride = 0.5*(gmax_err - gmin_err);

  for (UInt i = 0; i < num_iter; i++) {

    // count how many are <= both quantiles
 
    std::vector<double>::iterator lb = 
      std::lower_bound(evals.begin(), evals.end(), tguess);

    std::vector<double>::iterator lb1 = 
      std::lower_bound(evals.begin(), evals.end(), bguess);

    int dist = 0;
    if (lb == evals.end()) {
      dist = evals.size(); 
    } else dist = std::distance(evals.begin(), lb);
    int dist1 = 0;
    if (lb == evals.end()) {
      dist1 = evals.size(); 
    } else dist1 = std::distance(evals.begin(), lb1);

    int gdist;
    MPI_Allreduce(&dist, &gdist, 1, MPI_INT, MPI_SUM, Par::Comm());

    int gdist1;
    MPI_Allreduce(&dist1, &gdist1, 1, MPI_INT, MPI_SUM, Par::Comm());

    Par::Out() << "tguess=" << tguess << ", gdist=" << gdist << std::endl;
    Par::Out() << "bguess=" << bguess << ", gdist1=" << gdist1 << std::endl;
    
    ltguess = tguess;
    lbguess = bguess;

    stride *= 0.5;

    if (gdist == tN && gdist1 == bN) break;
    if (gdist > tN) tguess -= stride;
    if (gdist < tN) tguess += stride;

    if (gdist1 > bN) bguess -= stride;
    if (gdist1 < bN) bguess += stride;

  } // for i


  // Now mark elements

  hadapt.ZeroMarker();

  Mesh::iterator ei = mesh.elem_begin(), ee = mesh.elem_end();
  for (; ei != ee; ++ei) {

    MeshObj &elem = *ei;
  
    double *e = err.data(elem);

    if (max_level == 0) {

      if (e[0] >= tguess) hadapt.MarkElement(elem, HAdapt::ELEM_REFINE);
      if (e[0] <= bguess) hadapt.MarkElement(elem, HAdapt::ELEM_UNREFINE);

    } else {
      UInt ref_level = HAdapt::RefineLevel(elem);

      if (ref_level < max_level && e[0] >= tguess)
        hadapt.MarkElement(elem, HAdapt::ELEM_REFINE);

      if (e[0] <= bguess) hadapt.MarkElement(elem, HAdapt::ELEM_UNREFINE);

    }

  }


}


} // namespace
