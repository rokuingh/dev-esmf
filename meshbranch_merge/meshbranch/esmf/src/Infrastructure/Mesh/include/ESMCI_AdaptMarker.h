#ifndef ESMCI_AdaptMarker_h
#define ESMCI_AdaptMarker_h

#include <Mesh/include/ESMCI_MEField.h>

/**
 * @defgroup markers
 * A group of marking strategies.  Marking takes an element error field as an input
 * and performs various statistical analysis to decide what elements to refine and
 * unrefine.  It then calls the underlying hadapt to mark the elements.
 */

namespace ESMCI {

class Mesh;
class HAdapt;

/**
 * Some classes to mark elements for refinement under
 * various strategies.
 * @ingroup markers
 */
class QuantileMarker {
public:

/**
 * Mark the elements based on quantiles.
 * @param top_frac refine elements above this quantile.
 * @param bot_frac unrefine elements below this quantile.
 * @param max_level maximum allowed levels of refinement (0 = infinite)
 */
QuantileMarker(HAdapt &hadapt, MEField<> &err, double top_frac, double bot_frac, UInt max_level);
};

} // namespace

#endif
