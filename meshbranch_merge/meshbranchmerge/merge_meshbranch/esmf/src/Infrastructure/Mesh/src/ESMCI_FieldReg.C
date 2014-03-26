#include <Mesh/include/ESMCI_FieldReg.h>
#include <Mesh/include/ESMCI_MEImprint.h>
#include <Mesh/include/ESMCI_ParEnv.h>

#include <algorithm>

namespace ESMCI {

  FieldReg::FieldReg() :
    is_committed(false),
    fmap(),
    _fmap(),
    nfields(0),
    fields(),
    ndfields(),
    efields()
  {
  }

  FieldReg::~FieldReg() {
    // Erase all fields
    // MEFields
    {
      FMapType::iterator fi = fmap.begin(), fe = fmap.end();
      for (; fi!=fe; ++fi) {
	delete fi->second;
      }
    }
    // _fields
    {
      fMapType::iterator fi = _fmap.begin(), fe = _fmap.end();
      for (; fi!=fe; ++fi) {
	delete fi->second;
      }
    }
  }

  MEField<> *FieldReg::GetCoordField() const {
    Trace __trace("FieldReg::GetCoordField()");
  
    MEField<> *cf = GetField("coordinates");
    ThrowAssert(cf);
    return cf;
  }

  void FieldReg::MatchFields(UInt nfields, MEField<> **fds, std::vector<MEField<>*> &res) const {
    for (UInt i = 0; i < nfields; i++) {
      MEField<> *mf = GetField(fds[i]->name());
      ThrowRequire(mf);
      res.push_back(mf);
    }
  }

  MEField<> *FieldReg::RegisterField(const std::string &name, const MEFamily &mef,
				     UInt obj_type, const Context &ctxt, 
				     UInt dim, bool out, 
				     bool interp,
				     const _fieldTypeBase &ftype)
  {

    if (is_committed)
      Throw() << "FieldReg is already committed when registering:" << name;

    FMapType::iterator fi = fmap.lower_bound(name);

    MEField<> *nf;
    if (fi == fmap.end() || fi->first != name) {
      // Create the new field
      nf = new MEField<>(name, mef, obj_type, ctxt, dim, out, interp, ftype);
      fmap.insert(fi, std::make_pair(name, nf));
      Fields.push_back(nf);
    } else {
      // Check. If specs match, then just return the fields, otherwise
      // throw error.
      nf = fi->second;
    
      // TODO: a more thourough check of specs (context, etc...)
      if (obj_type != nf->ObjType() || dim != nf->dim())
	Throw() << "MEField name:" << name << " already registered, with different specs";
    }

    return nf;
  }

  _field *FieldReg::Registerfield(const std::string &name, const _fieldTypeBase &_ftype)
  {

<<<<<<< ESMCI_FieldReg.C
_field *FieldReg::Registerfield(const std::string &name,
                                const _fieldLocale &floc,
                                const _fieldTypeBase &_ftype)
{
=======
    _field *fd;
>>>>>>> 1.2.2.7

    fMapType::iterator fi = _fmap.lower_bound(name);
    if (fi == _fmap.end() || fi->first != name) {
      // Create the new field
      fd = new _field(name, _ftype);
      _fmap.insert(fi, std::make_pair(fd->name(), fd));
    } else {
    }

<<<<<<< ESMCI_FieldReg.C
  fMapType::iterator fi = _fmap.lower_bound(name);
  if (fi == _fmap.end() || fi->first != name) {
    // Create the new field
    fd = new _field(name, floc, _ftype);
    _fmap.insert(fi, std::make_pair(fd->name(), fd));
  } else {
    fd = fi->second;
    fd->add_locale(floc);
}
  return fd;
}
=======
    return fd;
  }

  _field *FieldReg::Registerfield(const std::string &name,
				  const _fieldLocale &floc,
				  const _fieldTypeBase &_ftype)
  {
>>>>>>> 1.2.2.7

    _field *fd;

    fMapType::iterator fi = _fmap.lower_bound(name);
    if (fi == _fmap.end() || fi->first != name) {
      // Create the new field
      fd = new _field(name, floc, _ftype);
      _fmap.insert(fi, std::make_pair(fd->name(), fd));
    } else {
      fd = fi->second;
      fd->add_locale(floc);
    }

    return fd;
  }

  MEField<> *FieldReg::GetField(const std::string &fname) const {
    FMapType::const_iterator fi = fmap.find(fname);

    return fi == fmap.end() ? NULL : fi->second;
  }

  _field *FieldReg::Getfield(const std::string &fname) const {
    fMapType::const_iterator fi = _fmap.find(fname);
  
    return fi == _fmap.end() ? NULL : fi->second;
  }

  void FieldReg::CreateDBFields() {


    // Nodal fields become lagrange fields
    Context ctxt;
    ctxt.flip();
    {
      UInt n = ndfields.size();
      // Use the standard lagrange 
      for (UInt i = 0; i < n; i++) {

<<<<<<< ESMCI_FieldReg.C
  // Nodal fields become lagrange fields
  Context ctxt;
  ctxt.flip();
  {
    UInt n = ndfields.size();
    // Use the standard lagrange 
    for (UInt i = 0; i < n; i++) {
      if (ndfields[i]->name() == "_OWNER") continue; // skip owner field
      //std::cout << "P:" << Par::Rank() << "nodal field:" << ndfields[i]->name() << std::endl;
      IOField<NodalField> &nf = *ndfields[i];
      RegisterField(nf.name(), MEFamilyStd::instance(), MeshObj::ELEMENT,
         ctxt, nf.dim(), nf.output_status());
=======
	if (ndfields[i]->name() == "_OWNER") continue; // skip owner field

	//std::cout << "P:" << Par::Rank() << "nodal field:" << ndfields[i]->name() << std::endl;
	IOField<NodalField> &nf = *ndfields[i];
	RegisterField(nf.name(), MEFamilyStd::instance(), MeshObj::ELEMENT,
		      ctxt, nf.dim(), nf.output_status());
      }
>>>>>>> 1.2.2.7
    }

<<<<<<< ESMCI_FieldReg.C
  // Element fields become lagrange fields
  {
    UInt n = efields.size();
    // Use the standard lagrange 
    for (UInt i = 0; i < n; i++) {
      IOField<ElementField> &ef = *efields[i];
      RegisterField(ef.name(), MEFamilyDG::instance(1), MeshObj::ELEMENT,
              ctxt, ef.dim(), ef.output_status());
=======
    // Element fields become lagrange fields
    {
      UInt n = efields.size();
      // Use the standard lagrange 
      for (UInt i = 0; i < n; i++) {
	IOField<ElementField> &ef = *efields[i];
	RegisterField(ef.name(), MEFamilyDG::instance(1), MeshObj::ELEMENT,
		      ctxt, ef.dim(), ef.output_status());
      }
>>>>>>> 1.2.2.7
    }
  }

  void FieldReg::PopulateDBFields(MeshDB &mesh) {
    UInt nnodes = mesh.num_nodes();

    if (nnodes == 0) return;

<<<<<<< ESMCI_FieldReg.C
  // Nodal field first
  {
    UInt n = ndfields.size();
    // Use the standard lagrange 
    for (UInt i = 0; i < n; i++) {
      IOField<NodalField> &nf = *ndfields[i];
       if (nf.name() == "_OWNER") continue;
      MEField<> *mf = GetField(nf.name());
      if (mf == NULL) Throw() << "Populate, could not get nodal field:" << nf.name();

      if (mf->GetMEFamily().is_nodal() != true) Throw() << "Nodal field should have nodal ME";

      UInt fdim = nf.dim();
      if (fdim != mf->dim()) Throw() << "PopDB, fields dims do not match:(" << fdim << ", " << mf->dim() << ")";
      _field *llf = mf->GetNodalfield();
      if (llf == NULL) Throw() << "No primaryfield dof field in nodal Populate";

      // Loop mesh, assigning values.  We assume that all nodes are represented
      MeshDB::iterator ni = mesh.node_begin(), ne = mesh.node_end();
      for (ni=mesh.node_begin(); ni != ne; ++ni) {
        if (ni->get_data_index() < 0) Throw() << "Node:" << *ni << " has unassigned data index!!";
        double *d = nf.data(*ni);
        double *newd = llf->data(*ni);
        if (newd == NULL) Throw() << "Null data!!" << *ni;
        double *endd = newd + fdim;
        while (newd != endd) *newd++ = *d++;
      } // ni
=======
    // Nodal field first
    {
      UInt n = ndfields.size();
      // Use the standard lagrange 
      for (UInt i = 0; i < n; i++) {
	IOField<NodalField> &nf = *ndfields[i];

	if (nf.name() == "_OWNER") continue;

	MEField<> *mf = GetField(nf.name());
	if (mf == NULL) Throw() << "Populate, could not get nodal field:" << nf.name();

	if (mf->GetMEFamily().is_nodal() != true) Throw() << "Nodal field should have nodal ME";

	UInt fdim = nf.dim();
	if (fdim != mf->dim()) Throw() << "PopDB, fields dims do not match:(" << fdim << ", " << mf->dim() << ")";
	_field *llf = mf->GetNodalfield();
	if (llf == NULL) Throw() << "No primaryfield dof field in nodal Populate";
        
	// Loop mesh, assigning values.  We assume that all nodes are represented
	MeshDB::iterator ni = mesh.node_begin(), ne = mesh.node_end();
	for (ni=mesh.node_begin(); ni != ne; ++ni) {
	  if (ni->get_data_index() < 0) Throw() << "Node:" << *ni << " has unassigned data index!!";
	  double *d = nf.data(*ni);
	  double *newd = llf->data(*ni);
	  if (newd == NULL) Throw() << "Null data!!" << *ni;
	  double *endd = newd + fdim;
	  while (newd != endd) *newd++ = *d++;
	} // ni
>>>>>>> 1.2.2.7
      
      } // nfields
    }
  

    { // Element fields
      UInt n = efields.size();
      // Use the standard lagrange 
      for (UInt i = 0; i < n; i++) {
	IOField<ElementField> &ef = *efields[i];
	MEField<> *mf = GetField(ef.name());
	if (mf == NULL) Throw() << "Populate, could not get element field:" << ef.name();

	if (mf->GetMEFamily().is_elemental() != true) Throw() << "Element field should have elemental ME";

	UInt fdim = ef.dim();
	if (fdim != mf->dim()) Throw() << "PopDB, fields dims do not match:(" << fdim << ", " << mf->dim() << ")";
	_field *llf = mf->GetElementfield();
	if (llf == NULL) Throw() << "No 1 dof field in element Populate";

	// Loop mesh, assigning values.  We assume that all nodes are represented
	MeshDB::iterator ni = mesh.elem_begin(), ne = mesh.elem_end();
	for (; ni != ne; ++ni) {
	  if (ni->get_data_index() < 0) Throw() << "Node:" << *ni << " has unassigned data index!!";
	  double *d = ef.data(*ni);
	  double *newd = llf->data(*ni);
	  if (newd == NULL) Throw() << "Null data!!";
	  double *endd = newd + fdim;
	  while (newd != endd) *newd++ = *d++;
	} // ni
      
      } // nfields
    }
  }

  void FieldReg::ReleaseDBFields() {
    {
      UInt n = ndfields.size();
      for (UInt i = 0; i < n; i++) {
	delete ndfields[i];
      }
      std::vector<IOField<NodalField>*>().swap(ndfields);
    }
    {
      UInt n = efields.size();
      for (UInt i = 0; i < n; i++) {
	delete efields[i];
      }
      std::vector<IOField<ElementField>*>().swap(efields);
    }
  }

  // Union the two sets in parallel
  static void parallel_union_field_info(std::set<std::pair<UChar,UInt> > &locSet)
  {

    UInt csize = Par::Size();

    if (csize == 1) return; 

    std::vector<UInt> nvs;
    std::vector<UInt> nvso;

    std::set<std::pair<UChar,UInt> >::iterator si = locSet.begin(), se = locSet.end();

    for (; si != se; ++si) {
      nvs.push_back(si->second); nvso.push_back(si->first);
    }

<<<<<<< ESMCI_FieldReg.C
// Union the two sets in parallel
static void parallel_union_field_info(std::set<std::pair<UChar,UInt> > &locSet)
{
  UInt csize = Par::Size();
=======
    // First share how many each processor wishes to send
    std::vector<int> num_val(csize, 0);
    // BOB UInt num_val_l = locSet.size();
    int num_val_l = locSet.size();

    if(sizeof(int) == 4)MPI_Allgather(&num_val_l, 1, MPI_UNSIGNED, &*num_val.begin(), 1, MPI_UNSIGNED, Par::Comm());
    // BOB   if(sizeof(int) == 8)MPI_Allgather(&num_val_l, 1, MPI_UNSIGNED, &*num_val.begin(), 1, MPI_UNSIGNED_LONG, Par::Comm());
    if(sizeof(int) == 8)MPI_Allgather(&num_val_l, 1, MPI_UNSIGNED_LONG, &*num_val.begin(), 1, MPI_UNSIGNED_LONG, Par::Comm());


    std::vector<int> rdisp(csize+1, 0);
    for (UInt i = 0; i < csize; i++) {
      rdisp[i+1] = rdisp[i] + num_val[i];
    }
>>>>>>> 1.2.2.7

    std::vector<UInt> allval(rdisp[csize], 0);

<<<<<<< ESMCI_FieldReg.C
  std::vector<UInt> nvs;
  std::vector<UInt> nvso;

  std::set<std::pair<UChar,UInt> >::iterator si = locSet.begin(), se = locSet.end();
=======
    if(sizeof(UInt) == 4)MPI_Allgatherv(&*nvs.begin(), nvs.size(), MPI_UNSIGNED, &*allval.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED, Par::Comm());
    if(sizeof(UInt) == 8)MPI_Allgatherv(&*nvs.begin(), nvs.size(), MPI_UNSIGNED_LONG, &*allval.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED_LONG, Par::Comm());
>>>>>>> 1.2.2.7

<<<<<<< ESMCI_FieldReg.C
   for (; si != se; ++si) {
     nvs.push_back(si->second); nvso.push_back(si->first);
   }
=======
    std::vector<UInt> allvalo(rdisp[csize], 0);
>>>>>>> 1.2.2.7

<<<<<<< ESMCI_FieldReg.C
  // First share how many each processor wishes to send
  std::vector<int> num_val(csize, 0);
     // BOB UInt num_val_l = locSet.size();
     int num_val_l = locSet.size();
=======
    if(sizeof(UInt) == 4)MPI_Allgatherv(&*nvso.begin(), nvs.size(), MPI_UNSIGNED, &*allvalo.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED, Par::Comm());
    if(sizeof(UInt) == 8)MPI_Allgatherv(&*nvso.begin(), nvs.size(), MPI_UNSIGNED_LONG, &*allvalo.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED_LONG, Par::Comm());
>>>>>>> 1.2.2.7

<<<<<<< ESMCI_FieldReg.C
     if(sizeof(int) == 4)MPI_Allgather(&num_val_l, 1, MPI_UNSIGNED, &*num_val.begin(), 1, MPI_UNSIGNED, Par::Comm());
     // BOB   if(sizeof(int) == 8)MPI_Allgather(&num_val_l, 1, MPI_UNSIGNED, &*num_val.begin(), 1, MPI_UNSIGNED_LONG, Par::Comm());
     if(sizeof(int) == 8)MPI_Allgather(&num_val_l, 1, MPI_UNSIGNED_LONG, &*num_val.begin(), 1, MPI_UNSIGNED_LONG, Par::Comm());
=======
    // Loop through results
    for (UInt i = 0; i < (UInt) rdisp[csize]; i++) {
>>>>>>> 1.2.2.7

      locSet.insert(std::make_pair(allvalo[i], allval[i]));

    }

<<<<<<< ESMCI_FieldReg.C
     if(sizeof(UInt) == 4)MPI_Allgatherv(&*nvs.begin(), nvs.size(), MPI_UNSIGNED, &*allval.begin(),
       &*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED, Par::Comm());
     if(sizeof(UInt) == 8)MPI_Allgatherv(&*nvs.begin(), nvs.size(), MPI_UNSIGNED_LONG, &*allval.begin(),
       &*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED_LONG, Par::Comm());
=======
  }

  void FieldReg::Commit(MeshDB &mesh) {
    Trace __trace("FieldReg::Commit(MeshDB &mesh)");
>>>>>>> 1.2.2.7

    // Step 0: order the mefields
    {
      FMapType::iterator fi = fmap.begin(), fe = fmap.end();
      UInt ord = 0; // number MEFields
      for ( ;fi !=fe; ++fi) {
	MEField<> &f = *fi->second;
	f.ordinal = ord++;
      }
    }

<<<<<<< ESMCI_FieldReg.C
     if(sizeof(UInt) == 4)MPI_Allgatherv(&*nvso.begin(), nvs.size(), MPI_UNSIGNED, &*allvalo.begin(),
       &*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED, Par::Comm());
     if(sizeof(UInt) == 8)MPI_Allgatherv(&*nvso.begin(), nvs.size(), MPI_UNSIGNED_LONG, &*allvalo.begin(),
       &*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED_LONG, Par::Comm());
=======
    // Step 0: Get the imprint contexts that will be used; share in parallel
    // and define these contexts.
    {
      FMapType::iterator fi = fmap.begin(), fe = fmap.end();

      for ( ;fi !=fe; ++fi) {
>>>>>>> 1.2.2.7

<<<<<<< ESMCI_FieldReg.C
  // Loop through results
  for (UInt i = 0; i < (UInt) rdisp[csize]; i++) {
    locSet.insert(std::make_pair(allvalo[i], allval[i]));
=======
	std::set<std::pair<UChar,UInt> > locSet;

	MEField<> &f = *fi->second;

	// Loop obj type
	KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end(), kn;

	for (; ki != ke; ) {
>>>>>>> 1.2.2.7

	  kn = ki; ++kn; // manage iterators in case imprint changes kernel list
	  Kernel &ker = *ki;

<<<<<<< ESMCI_FieldReg.C
}
=======
	  // if kernel wrong type or context doesnt match, move on
	  if (ker.type() == f.GetType() && ker.GetContext().any(f.GetContext())) {
  
	    const MeshObjTopo *otopo = ker.GetTopo();
>>>>>>> 1.2.2.7

	    if (!otopo)
	      Throw() << "Field " << f.name() << " has no topo on matching kernel";

	    const MEFamily &mef = f.GetMEFamily();
	    //std::cout << "Field " << f.name() << "has topo = " << otopo->name << std::endl;
	    MasterElement<> &me = *mef.getME(otopo->name, METraits<>());

	    // Get all of the (type,nval) sets for the me.
	    MEImprintValSets(me, locSet);

<<<<<<< ESMCI_FieldReg.C
   // Step 0: order the mefields
  {
    FMapType::iterator fi = fmap.begin(), fe = fmap.end();
    UInt ord = 0; // number MEFields
    for ( ;fi !=fe; ++fi) {
      MEField<> &f = *fi->second;
      f.ordinal = ord++;
     }
   }
 
   // Step 0: Get the imprint contexts that will be used; share in parallel
   // and define these contexts.
   {
     FMapType::iterator fi = fmap.begin(), fe = fmap.end();
 
     for ( ;fi !=fe; ++fi) {

       std::set<std::pair<UChar,UInt> > locSet;

       MEField<> &f = *fi->second;

      // Loop obj type
      KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end(), kn;

      for (; ki != ke; ) {

        kn = ki; ++kn; // manage iterators in case imprint changes kernel list
        Kernel &ker = *ki;

        // if kernel wrong type or context doesnt match, move on
        if (ker.type() == f.GetType() && ker.GetContext().any(f.GetContext())) {
  

          const MeshObjTopo *otopo = ker.GetTopo();
          if (!otopo)
            Throw() << "Field " << f.name() << " has no topo on matching kernel";

          const MEFamily &mef = f.GetMEFamily();

          MasterElement<> &me = *mef.getME(otopo->name, METraits<>());
           // Get all of the (type,nval) sets for the me.
           MEImprintValSets(me, locSet);
        }
=======
	  }
>>>>>>> 1.2.2.7
  
<<<<<<< ESMCI_FieldReg.C
        ki = kn;
      } // for k

 std::set<std::pair<UChar,UInt> >::iterator si = locSet.begin(), se = locSet.end();
#if 0
 Par::Out() << "f:" << f.name() << ", locSet before exchange:" << std::endl;
 for (; si !=se; ++si) {
   Par::Out() << "(" << (int) si->first << ", " << si->second << ")" << std::endl;
 }
#endif
      // Must parallel union nvalSet and nvalSetObj
       parallel_union_field_info(locSet);
 
 si = locSet.begin(); se = locSet.end();
#if 0
 Par::Out() << "f:" << f.name() << ", locSet after exchange:" << std::endl;
 for (; si !=se; ++si) {
   Par::Out() << "(" << (int) si->first << ", " << si->second << ")" << std::endl;
 }
#endif
=======
	  ki = kn;
	} // for k
>>>>>>> 1.2.2.7

	std::set<std::pair<UChar,UInt> >::iterator si = locSet.begin(), se = locSet.end();
#if 0
	Par::Out() << "f:" << f.name() << ", locSet before exchange:" << std::endl;
	for (; si !=se; ++si) {
	  Par::Out() << "(" << (int) si->first << ", " << si->second << ")" << std::endl;
	}
#endif
	// Must parallel union nvalSet and nvalSetObj
	parallel_union_field_info(locSet);

	si = locSet.begin(); se = locSet.end();
#if 0
	Par::Out() << "f:" << f.name() << ", locSet after exchange:" << std::endl;
	for (; si !=se; ++si) {
	  Par::Out() << "(" << (int) si->first << ", " << si->second << ")" << std::endl;
	}
#endif
	// Register low level fields and define the contexts
	std::set<std::pair<UChar,UInt> >::iterator li = locSet.begin(), le = locSet.end();

	MEField<>::CtxtMap & loc2ctxt = f.GetCMap();
	loc2ctxt.clear(); // just in case

	char llname[1024];
	std::sprintf(llname, "_me_%s", f.name().c_str());

	std::vector<UInt> ctxts;
	for (; li !=le; ) {

	  UChar otype = li->first;

	  UInt num_ctxt_per_otype = 0;


	  // Loop through all objects of a given type.  If there are multiple entries
	  // for an object type, we can not use the same context; we must create another context.
	  while (li != le && li->first == otype) {

	    UInt c_id = 0;

<<<<<<< ESMCI_FieldReg.C
      // Register low level fields and define the contexts
       std::set<std::pair<UChar,UInt> >::iterator li = locSet.begin(), le = locSet.end();
 
       MEField<>::CtxtMap & loc2ctxt = f.GetCMap();
       loc2ctxt.clear(); // just in case

       char llname[1024];
       std::sprintf(llname, "_me_%s", f.name().c_str());

       std::vector<UInt> ctxts;
       for (; li !=le; ) {

         UChar otype = li->first;

         UInt num_ctxt_per_otype = 0;


         // Loop through all objects of a given type.  If there are multiple entries
         // for an object type, we can not use the same context; we must create another context.
         while (li != le && li->first == otype) {

           UInt c_id = 0;

           if (num_ctxt_per_otype < ctxts.size()) {
             c_id = ctxts[num_ctxt_per_otype];
           } else {
             // Create a context for imprinting objects.
        char buf[1024];
               Par::Out() << "NAME = " << f.name() << " is context = " <<  num_ctxt_per_otype << std::endl;
             std::sprintf(buf, "_me_%s_%d", f.name().c_str(), num_ctxt_per_otype);
             UInt tc_id = mesh.DefineContext(buf);

             ctxts.push_back(tc_id);

             c_id = ctxts[num_ctxt_per_otype];

      }
      
           loc2ctxt[std::make_pair(li->first,li->second)] = c_id;
        
           f.setfield(Registerfield(llname, _fieldLocale(li->first, c_id, li->second*f.dim()), f.FType()));

           ++num_ctxt_per_otype;
           ++li;
         }

       } // li

       // For an empty mesh, we may not have registered the field, so create it
       {
         _field *lf = Getfield(llname);
         if (!lf)
           f.setfield(Registerfield(llname, f.FType()));
        }

 MEFieldBase::CtxtMap::iterator cmi = loc2ctxt.begin(), cme = loc2ctxt.end();
 #if 0
         Par::Out() << "l2ctxt:" << std::endl;
 for (; cmi != cme; ++cmi) {
   Par::Out() << "(" << (int) cmi->first.first << ", " << cmi->first.second << ") -> " << cmi->second << std::endl;
      }
#endif      
       if (f.has_interp()) {

         if (!f.is_nodal()) Throw() << "Interp for non-nodal not yet implemented, field=" << f.name() << std::endl;

         f.SetInterp(f.Getfield());

       }

       // Now actually loop and imprint.
       ki = mesh.set_begin(), ke = mesh.set_end();

       for (; ki != ke; ) {

         kn = ki; ++kn; // manage iterators in case imprint changes kernel list
         Kernel &ker = *ki;

         // if kernel wrong type or context doesnt match, move on
         if (ker.type() == f.GetType() && ker.GetContext().any(f.GetContext())) {

           const MeshObjTopo *otopo = ker.GetTopo();

           if (!otopo)
             Throw() << "Field " << f.name() << " has no topo on matching kernel";

           const MEFamily &mef = f.GetMEFamily();

           MasterElement<> &me = *mef.getME(otopo->name, METraits<>());

           Kernel::obj_iterator oi = ker.obj_begin(), oe = ker.obj_end(), on;
           for (; oi != oe; ) {

             on = oi; ++on;

             MEImprint(loc2ctxt, *oi, me);

             oi = on;
           } // oi


   }
=======
	    if (num_ctxt_per_otype < ctxts.size()) {
	      c_id = ctxts[num_ctxt_per_otype];
	    } else {
	      // Create a context for imprinting objects.
	      char buf[1024];
	      Par::Out() << "NAME = " << f.name() << " is context = " <<  num_ctxt_per_otype << std::endl;
	      std::sprintf(buf, "_me_%s_%d", f.name().c_str(), num_ctxt_per_otype);
	      UInt tc_id = mesh.DefineContext(buf);
      
	      ctxts.push_back(tc_id);
>>>>>>> 1.2.2.7

<<<<<<< ESMCI_FieldReg.C
         ki = kn;
       } // for k

     } // for fi
    }


 /*
=======
	      c_id = ctxts[num_ctxt_per_otype];
>>>>>>> 1.2.2.7

	    }

	    loc2ctxt[std::make_pair(li->first,li->second)] = c_id;

	    f.setfield(Registerfield(llname, _fieldLocale(li->first, c_id, li->second*f.dim()), f.FType()));

<<<<<<< ESMCI_FieldReg.C
    } // for f
   }
*/
=======
	    ++num_ctxt_per_otype;
	    ++li;
	  }
>>>>>>> 1.2.2.7

<<<<<<< ESMCI_FieldReg.C
  // Linearize fields.  Use the ordering implied by MEField, since this is the order
  // kernel commit uses later.
 for (UInt i = 0; i < Fields.size(); i++) {
    MEField<> *meF = static_cast<MEField<>*>(Fields[i]);
     fields.push_back(meF->Getfield());
 }

 nfields = fields.size();
 {
   for (UInt i = 0; i < nfields; i++) 
     fields[i]->set_ordinal(i);
 }
 
 // Loop through _fields; there may be some that are not associated with MEFields,
 // so we need to count and number these.
 {
  fMapType::iterator fi = _fmap.begin(), fe = _fmap.end();
  
  for (; fi != fe; ++fi) {
    _field *_f = fi->second;
    
    if (_f->GetOrdinal() < 0) {
      _f->set_ordinal(nfields++);
      fields.push_back(_f);
    }
  }
  
 }
=======
	} // li
>>>>>>> 1.2.2.7

	// For an empty mesh, we may not have registered the field, so create it
	{
	  _field *lf = Getfield(llname);
	  if (!lf)
	    f.setfield(Registerfield(llname, f.FType()));
	}

	MEFieldBase::CtxtMap::iterator cmi = loc2ctxt.begin(), cme = loc2ctxt.end();
#if 0
	Par::Out() << "l2ctxt:" << std::endl;
	for (; cmi != cme; ++cmi) {
	  Par::Out() << "(" << (int) cmi->first.first << ", " << cmi->first.second << ") -> " << cmi->second << std::endl;
	}
#endif
	if (f.has_interp()) {

	  if (!f.is_nodal()) Throw() << "Interp for non-nodal not yet implemented, field=" << f.name() << std::endl;

	  f.SetInterp(f.Getfield());

	}

	// Now actually loop and imprint.
	ki = mesh.set_begin(), ke = mesh.set_end();

	for (; ki != ke; ) {

	  kn = ki; ++kn; // manage iterators in case imprint changes kernel list
	  Kernel &ker = *ki;

	  // if kernel wrong type or context doesnt match, move on
	  if (ker.type() == f.GetType() && ker.GetContext().any(f.GetContext())) {
  
	    const MeshObjTopo *otopo = ker.GetTopo();

	    if (!otopo)
	      Throw() << "Field " << f.name() << " has no topo on matching kernel";

	    const MEFamily &mef = f.GetMEFamily();

	    MasterElement<> &me = *mef.getME(otopo->name, METraits<>());

	    Kernel::obj_iterator oi = ker.obj_begin(), oe = ker.obj_end(), on;
	    for (; oi != oe; ) {

	      on = oi; ++on;

	      MEImprint(loc2ctxt, *oi, me);

	      oi = on;
	    } // oi


	  }
  
	  ki = kn;
	} // for k

      } // for fi
    }

    /*
    // Step 1: Imprint the objects for low level fields
    {
    FMapType::iterator fi = fmap.begin(), fe = fmap.end();
    for ( ;fi !=fe; ++fi) {
    MEField<> &f = *fi->second;
    //std::cout << "Imprinting MEField:" << f.name() << std::endl;
    // Loop obj type
    KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end(), kn;
    for (; ki != ke; ) {
    kn = ki; ++kn; // manage iterators in case imprint changes kernel list
    Kernel &ker = *ki;
    // if kernel wrong type or context doesnt match, move on
    if (ker.type() == f.GetType() && ker.GetContext().any(f.GetContext())) {
  
    const MeshObjTopo *otopo = ker.GetTopo();
    if (!otopo)
    Throw() << "Field " << f.name() << " has no topo on matching kernel";
    const MEFamily &mef = f.GetMEFamily();
    MasterElement<> &me = *mef.getME(otopo->name, METraits<>());
    //std::cout << "topo:" << otopo->name << " yields me:" << me.name << std::endl;
    // loop objects, imprint
    Kernel::obj_iterator oi = ker.obj_begin(), oe = ker.obj_end(), on;
    for (; oi != oe; ) {
    on = oi; ++on;
    MEImprint(f.name(), *oi, me);
    oi = on;
    } // oi
    }
  
    ki = kn;
    } // for k

    } // for f
    }
    */

    // Linearize fields.  Use the ordering implied by MEField, since this is the order
    // kernel commit uses later.
    for (UInt i = 0; i < Fields.size(); i++) {
      MEField<> *meF = static_cast<MEField<>*>(Fields[i]);
      fields.push_back(meF->Getfield());
    }

    nfields = fields.size();
    {
      for (UInt i = 0; i < nfields; i++) 
	fields[i]->set_ordinal(i);
    }
 
    // Loop through _fields; there may be some that are not associated with MEFields,
    // so we need to count and number these.
    {
      fMapType::iterator fi = _fmap.begin(), fe = _fmap.end();
  
      for (; fi != fe; ++fi) {
	_field *_f = fi->second;
    
	if (_f->GetOrdinal() < 0) {
	  _f->set_ordinal(nfields++);
	  fields.push_back(_f);
	}
      }
  
    }
    is_committed = true;
  }


  IOField<NodalField> *FieldReg::RegisterNodalField(const MeshDB &mesh, const std::string &name, UInt dim) {
  
    ndfields.push_back(new IOField<NodalField>(mesh, name, dim));
    return ndfields.back();
  }

  IOField<ElementField> *FieldReg::RegisterElementField(const MeshDB &mesh, const std::string &name, UInt dim) {
  
    efields.push_back(new IOField<ElementField>(mesh, name, dim));
    return efields.back();
  }

} // namespace
