#include <Mesh/include/ESMCI_MEImprint.h>
#include <Mesh/include/ESMCI_MeshObjConn.h>
#include <Mesh/include/ESMCI_MeshUtils.h>
#include <Mesh/include/ESMCI_MasterElement.h>

#include <map>

namespace ESMCI {

void MEImprintValSets(const MasterElementBase &me,
               std::set<std::pair<UChar, UInt> > &sets) 
{

  for (UInt i = 0; i < me.num_functions(); i++) {
    const int *dd = me.GetDofDescription(i);
    UInt nval = me.GetDofValSet(i);
    UChar otype = dof2mtype(dd[0]);

    sets.insert(std::make_pair(otype,nval));

 }

}

// Map from (type,nval) to context
typedef std::map<std::pair<UChar,UInt>, std::string> vsetmap;

void MEImprint(MEFieldBase::CtxtMap &l2c, MeshObj &obj, const MasterElementBase &me) {
  MeshDB &mesh = GetMeshObjMesh(obj);


  for (UInt i = 0; i < me.num_functions(); i++) {

    const int *dd = me.GetDofDescription(i);

    UInt nval = me.GetDofValSet(i);
    UInt otype = dof2mtype(dd[0]);

    // get the context

    MEFieldBase::CtxtMap::iterator ci = 
         l2c.find(std::make_pair(otype,nval));

    if (ci == l2c.end()) Throw() << "could not find context for (otype,nval):" << otype << ", " << nval;

    UInt ctxt_id = ci->second;

    // Get the object.  If element, go right to it, else if side, go through parent
    MeshObjRelationList::iterator ri;

    // if doftype is same as objtype, just present self
    MeshObj *dobj = NULL;
    if (obj.get_type() == dof2mtype(dd[0])) {
      // should be ordinal 0, just check
      if (dd[1] != 0) Throw() << "object type same as imprint type, expected ordinal 0";
      dobj = &obj;
    } else if (obj.get_type() == MeshObj::ELEMENT) {

      ri =
         MeshObjConn::find_relation(obj, dof2mtype(dd[0]), dd[1]);

      dobj=ri->obj;

    if (ri == obj.Relations.end())
      Throw() << "MEImprint, could not find obj (" << MeshObjTypeString(dof2mtype(dd[0])) << ", " << dd[1] << ") for:" << obj
            << ".  Should edges or faces be on??";

    } else if (obj.get_type() == (UInt) mesh.side_type()) {
      ri = MeshObjConn::find_relation(obj, MeshObj::ELEMENT);

      if (ri == obj.Relations.end())
        Throw() << "MEImprint, could not find side parent";
 
      MeshObj &elem = *ri->obj; UInt side_ord = ri->ordinal;
      const MeshObjTopo *etopo = GetMeshObjTopo(elem);
      ri = MeshObjConn::find_relation(elem, dof2mtype(dd[0]), etopo->get_side_nodes(side_ord)[dd[1]]);
      if (ri == elem.Relations.end())
        Throw() << "MEImprint, could not find side node from parent";

      dobj=ri->obj;
    
    } else
      Throw() << "Imprint not supported for type:" << MeshObjTypeString(obj.get_type());
    // Add ctxt_id to object.
    MeshObj &iobj = *dobj;
    const Attr &oattr = GetAttr(iobj);
    const Context &ctxt = GetMeshObjContext(iobj);
    Context newctxt(ctxt);
    newctxt.set(ctxt_id);
    if (newctxt != ctxt) {
      Attr attr(oattr, newctxt);
      mesh.update_obj(&iobj, attr);
    }
  } // for i

} 

} // namespace
