<<<<<<< ESMCI_FieldReg.C
=======
// $Id: ESMCI_FieldReg.C,v 1.6 2010/03/04 18:57:45 svasquez Exp $
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
>>>>>>> 1.6
#include <Mesh/include/ESMCI_FieldReg.h>
#include <Mesh/include/ESMCI_MEImprint.h>
#include <Mesh/include/ESMCI_ParEnv.h>

#include <algorithm>

//-----------------------------------------------------------------------------
// leave the following line as-is; it will insert the cvs ident string
// into the object file for tracking purposes.
static const char *const version = "$Id: ESMCI_FieldReg.C,v 1.6 2010/03/04 18:57:45 svasquez Exp $";
//-----------------------------------------------------------------------------

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

    _field *fd;

    fMapType::iterator fi = _fmap.lower_bound(name);
    if (fi == _fmap.end() || fi->first != name) {
      // Create the new field
      fd = new _field(name, _ftype);
      _fmap.insert(fi, std::make_pair(fd->name(), fd));
    } else {
    }

    return fd;
  }

  _field *FieldReg::Registerfield(const std::string &name,
				  const _fieldLocale &floc,
				  const _fieldTypeBase &_ftype)
  {

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

	if (ndfields[i]->name() == "_OWNER") continue; // skip owner field

	//std::cout << "P:" << Par::Rank() << "nodal field:" << ndfields[i]->name() << std::endl;
	IOField<NodalField> &nf = *ndfields[i];
	RegisterField(nf.name(), MEFamilyStd::instance(), MeshObj::ELEMENT,
		      ctxt, nf.dim(), nf.output_status());
      }
    }

    // Element fields become lagrange fields
    {
      UInt n = efields.size();
      // Use the standard lagrange 
      for (UInt i = 0; i < n; i++) {
	IOField<ElementField> &ef = *efields[i];
	RegisterField(ef.name(), MEFamilyDG::instance(1), MeshObj::ELEMENT,
		      ctxt, ef.dim(), ef.output_status());
      }
    }
  }

  void FieldReg::PopulateDBFields(MeshDB &mesh) {
    UInt nnodes = mesh.num_nodes();

    if (nnodes == 0) return;

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

    std::vector<UInt> allval(rdisp[csize], 0);

    if(sizeof(UInt) == 4)MPI_Allgatherv(&*nvs.begin(), nvs.size(), MPI_UNSIGNED, &*allval.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED, Par::Comm());
    if(sizeof(UInt) == 8)MPI_Allgatherv(&*nvs.begin(), nvs.size(), MPI_UNSIGNED_LONG, &*allval.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED_LONG, Par::Comm());

    std::vector<UInt> allvalo(rdisp[csize], 0);

    if(sizeof(UInt) == 4)MPI_Allgatherv(&*nvso.begin(), nvs.size(), MPI_UNSIGNED, &*allvalo.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED, Par::Comm());
    if(sizeof(UInt) == 8)MPI_Allgatherv(&*nvso.begin(), nvs.size(), MPI_UNSIGNED_LONG, &*allvalo.begin(),
					&*num_val.begin(), &*rdisp.begin(), MPI_UNSIGNED_LONG, Par::Comm());

    // Loop through results
    for (UInt i = 0; i < (UInt) rdisp[csize]; i++) {

      locSet.insert(std::make_pair(allvalo[i], allval[i]));

    }

  }

  void FieldReg::Commit(MeshDB &mesh) {
    Trace __trace("FieldReg::Commit(MeshDB &mesh)");

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
=======
  if (nvs.size ())
    MPI_Allgatherv(&nvs[0], nvs.size(), MPI_UNSIGNED, &allval[0],
        &num_val[0], &rdisp[0], MPI_UNSIGNED, Par::Comm());
  else {
    unsigned int zerobuf = 0;
    MPI_Allgatherv(&zerobuf, 0, MPI_UNSIGNED, &allval[0],
        &num_val[0], &rdisp[0], MPI_UNSIGNED, Par::Comm());
  }
>>>>>>> 1.6

	std::set<std::pair<UChar,UInt> > locSet;

	MEField<> &f = *fi->second;

<<<<<<< ESMCI_FieldReg.C
	// Loop obj type
	KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end(), kn;
=======
  if (nvs.size ())
    MPI_Allgatherv(&contig_nvso[0], nvs.size(), MPI_UNSIGNED, &allvalo[0],
        &num_val[0], &rdisp[0], MPI_UNSIGNED, Par::Comm());
  else {
    unsigned int zerobuf = 0;
    MPI_Allgatherv(&zerobuf, 0, MPI_UNSIGNED, &allvalo[0],
        &num_val[0], &rdisp[0], MPI_UNSIGNED, Par::Comm());
  }
>>>>>>> 1.6

	for (; ki != ke; ) {

	  kn = ki; ++kn; // manage iterators in case imprint changes kernel list
	  Kernel &ker = *ki;

	  // if kernel wrong type or context doesnt match, move on
	  if (ker.type() == f.GetType() && ker.GetContext().any(f.GetContext())) {
  
	    const MeshObjTopo *otopo = ker.GetTopo();

	    if (!otopo)
	      Throw() << "Field " << f.name() << " has no topo on matching kernel";

	    const MEFamily &mef = f.GetMEFamily();
	    //std::cout << "Field " << f.name() << "has topo = " << otopo->name << std::endl;
	    MasterElement<> &me = *mef.getME(otopo->name, METraits<>());

	    // Get all of the (type,nval) sets for the me.
	    MEImprintValSets(me, locSet);

	  }
  
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

<<<<<<< ESMCI_FieldReg.C
	    UInt c_id = 0;

	    if (num_ctxt_per_otype < ctxts.size()) {
	      c_id = ctxts[num_ctxt_per_otype];
	    } else {
	      // Create a context for imprinting objects.
	      char buf[1024];
	      Par::Out() << "NAME = " << f.name() << " is context = " <<  num_ctxt_per_otype << std::endl;
	      std::sprintf(buf, "_me_%s_%d", f.name().c_str(), num_ctxt_per_otype);
	      UInt tc_id = mesh.DefineContext(buf);
=======
  numSets=0;
  int nvalSetPos=0;
  nvalSetSizes.clear();
  nvalSetVals.clear();
  int nvalSetObjPos=0;
  nvalSetObjSizes.clear();
  nvalSetObjVals.clear();


  // Step 0: Get the imprint contexts that will be used; share in parallel
  // and define these contexts.
  {
    FMapType::iterator fi = fmap.begin(), fe = fmap.end();
    UInt ord = 0; // number MEFields
    for ( ;fi !=fe; ++fi) {
      std::vector<UInt> nvalSet; // keep track of sizes of _fields
      std::vector<UInt> nvalSetObj; // keep track of sizes of _fields
      MEField<> &f = *fi->second;
//std::cout << "Imprinting MEField:" << f.name() << std::endl;
      f.ordinal = ord++;
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
            MEImprintValSets(f.name(), *oi, me, nvalSet, nvalSetObj);
            oi = on;
          } // oi
        }
  
        ki = kn;
      } // for k

      // Must parallel union nvalSet and nvalSetObj
      parallel_union_field_info(nvalSet, nvalSetObj);


#if 0
      if (Par::Rank() == 0) {
	printf("C nvalset.size()=%d \n",nvalSet.size());
        for (int i=0; i<nvalSet.size(); i++) {
	  printf("C [%d]= %d \n",i,nvalSet[i]);
	}

	printf("C nvalsetobj.size()=%d \n",nvalSetObj.size());
        for (int i=0; i<nvalSetObj.size(); i++) {
	  printf("C [%d]= %d \n",i,nvalSetObj[i]);
	}
      }
#endif

      // Save values for creation of proxy Meshes
      nvalSetSizes.push_back(nvalSet.size());
      nvalSetVals.resize(nvalSetPos+nvalSet.size(),0);
      for (int i=0; i<nvalSet.size(); i++) {
	nvalSetVals[nvalSetPos]=nvalSet[i];
        nvalSetPos++;
      }

      nvalSetObjSizes.push_back(nvalSetObj.size());
      nvalSetObjVals.resize(nvalSetObjPos+nvalSetObj.size(),0);
      for (int i=0; i<nvalSetObj.size(); i++) {
	nvalSetObjVals[nvalSetObjPos]=nvalSetObj[i];
        nvalSetObjPos++;
      }

      numSets++;


      // Register low level fields and define the contexts
      for (UInt i = 0; i < nvalSet.size(); i++) {
        UInt nval = nvalSet[i];
        Context ctxt;
        char buf[1024];
        std::sprintf(buf, "%s_%d", f.name().c_str(), nval);
        UInt c_id = mesh.DefineContext(buf);
        ctxt.set(c_id);
        Attr fatt(nvalSetObj[nval], ctxt);
        f.Addfield(Registerfield(buf, fatt, f.FType(), nval*f.dim()), nval);
//std::cout << "Creating subfield:" << buf << std::endl;
      }
      
      // If field is to be interpolated, register an interpolant field.  This should be parallel
      // safe.
      if (f.has_interp()) {
        
        // IF the field is nodal, we will simply use the nodal field for interpolations,
        // otherwise we must create a special field for interpolation.
        if (!f.is_nodal()) {
          char buf[1024];
          std::sprintf(buf, "_interp_%s", f.name().c_str());
          UInt c_id = mesh.DefineContext(buf);
          Context ctxt;
          ctxt.set(c_id);
          Attr fatt(MeshObj::NODE | MeshObj::INTERP, ctxt);
          f.SetInterp(Registerfield(buf, fatt, f.FType(), f.dim()));
        } else {
          f.SetInterp(f.GetNodalfield());
        }
      }
      
    } // for fi
   }




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

  // Linearize fields.  Use the ordering implied by MEField, since this is the order
  // kernel commit uses later.
 for (UInt i = 0; i < Fields.size(); i++) {
    MEField<> *meF = static_cast<MEField<>*>(Fields[i]);
    meF->Getfields(fields); // will be unique fields
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


void FieldReg::ProxyCommit(MeshDB &mesh,
			   int numSetsArg,
			   std::vector<UInt> nvalSetSizesArg, std::vector<UInt> nvalSetValsArg,
			   std::vector<UInt> nvalSetObjSizesArg, std::vector<UInt> nvalSetObjValsArg) {
  Trace __trace("FieldReg::ProxyCommit(MeshDB &mesh)");

  int setPos=0;
  int nvalSetPos=0;
  int nvalSetObjPos=0;


  // Step 0: Get the imprint contexts that will be used; share in parallel
  // and define these contexts.
  {
    FMapType::iterator fi = fmap.begin(), fe = fmap.end();
    UInt ord = 0; // number MEFields
    for ( ;fi !=fe; ++fi) {
      MEField<> &f = *fi->second;

//std::cout << "Imprinting MEField:" << f.name() << std::endl;
      f.ordinal = ord++;

      // Fill values into Sets
      std::vector<UInt> nvalSet; // keep track of sizes of _fields
      std::vector<UInt> nvalSetObj; // keep track of sizes of _fields


      // Load values from deserialize
      nvalSet.resize(nvalSetSizesArg[setPos],0);
      for (int i=0; i<nvalSetSizesArg[setPos]; i++) {
	nvalSet[i]=nvalSetValsArg[nvalSetPos];
        nvalSetPos++;
      }

      nvalSetObj.resize(nvalSetObjSizesArg[setPos],0);
      for (int i=0; i<nvalSetObjSizesArg[setPos]; i++) {
	nvalSetObj[i]=nvalSetObjValsArg[nvalSetObjPos];
        nvalSetObjPos++;
      }

      setPos++;

#if 0
      //      if (Par::Rank() == 0) {
	printf("P nvalset.size()=%d \n",nvalSet.size());
        for (int i=0; i<nvalSet.size(); i++) {
	  printf("P [%d]= %d \n",i,nvalSet[i]);
	}

	printf("P nvalsetobj.size()=%d \n",nvalSetObj.size());
        for (int i=0; i<nvalSetObj.size(); i++) {
	  printf("P [%d]= %d \n",i,nvalSetObj[i]);
	}
	//      }
#endif


      // Register low level fields and define the contexts
      for (UInt i = 0; i < nvalSet.size(); i++) {
        UInt nval = nvalSet[i];
        Context ctxt;
        char buf[1024];
        std::sprintf(buf, "%s_%d", f.name().c_str(), nval);
        UInt c_id = mesh.DefineContext(buf);
        ctxt.set(c_id);
        Attr fatt(nvalSetObj[nval], ctxt);
        f.Addfield(Registerfield(buf, fatt, f.FType(), nval*f.dim()), nval);
//std::cout << "Creating subfield:" << buf << std::endl;
      }
>>>>>>> 1.6
      
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


<<<<<<< ESMCI_FieldReg.C
  IOField<NodalField> *FieldReg::RegisterNodalField(const MeshDB &mesh, const std::string &name, UInt dim) {
=======

void FieldReg::GetImprints(
			   int *numSetsArg,
			   UInt **nvalSetSizesArg, UInt **nvalSetValsArg,
			   UInt **nvalSetObjSizesArg, UInt **nvalSetObjValsArg) {
  Trace __trace("FieldReg::getImprints()");

  // Copy Info
  *numSetsArg=numSets;

  if (nvalSetSizes.size()) *nvalSetSizesArg=&nvalSetSizes[0];
  else *nvalSetSizesArg=NULL;

  if (nvalSetVals.size()) *nvalSetValsArg=&nvalSetVals[0];
  else *nvalSetValsArg=NULL;

  if (nvalSetObjSizes.size()) *nvalSetObjSizesArg=&nvalSetObjSizes[0];
  else *nvalSetObjSizesArg=NULL;

  if (nvalSetObjVals.size()) *nvalSetObjValsArg=&nvalSetObjVals[0];
  else *nvalSetObjValsArg=NULL;
  
}



IOField<NodalField> *FieldReg::RegisterNodalField(const MeshDB &mesh, const std::string &name, UInt dim) {
>>>>>>> 1.6
  
    ndfields.push_back(new IOField<NodalField>(mesh, name, dim));
    return ndfields.back();
  }

  IOField<ElementField> *FieldReg::RegisterElementField(const MeshDB &mesh, const std::string &name, UInt dim) {
  
    efields.push_back(new IOField<ElementField>(mesh, name, dim));
    return efields.back();
  }

} // namespace
