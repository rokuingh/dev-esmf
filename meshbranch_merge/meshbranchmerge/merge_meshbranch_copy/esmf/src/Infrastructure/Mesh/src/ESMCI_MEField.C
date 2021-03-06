// $Id$
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
#include <Mesh/include/ESMCI_MEField.h>
#include <Mesh/include/ESMCI_MeshField.h>
#include <Mesh/include/ESMCI_MeshUtils.h>
#include <Mesh/include/ESMCI_MeshObjConn.h>

#include <Mesh/include/ESMCI_ParEnv.h>

//-----------------------------------------------------------------------------
// leave the following line as-is; it will insert the cvs ident string
// into the object file for tracking purposes.
static const char *const version = "$Id$";
//-----------------------------------------------------------------------------

namespace ESMCI {

// ********** New style fields ************
// MEFieldBase (no templates)
MEFieldBase::MEFieldBase(const std::string &_name, const MEFamily &_mef,
    UInt _obj_type, const Context &_ctxt, UInt dim, bool out, bool _interp, const _fieldTypeBase &_ftype) :
fname(_name),
mef(_mef),
obj_type(_obj_type),
my_ctxt(_ctxt),
fdim(dim),
output(out),
interp(_interp),
ftype(_ftype),
ordinal(0)
{
}

MEFieldBase::~MEFieldBase() {
}

template<typename _FIELD>
void MEField<_FIELD>::Addfield(_FIELD *f, UInt nval) {
  // Store as a hash of fields by nval;
  std::vector<UInt>::iterator i = 
    std::lower_bound(fidx_table.begin(), fidx_table.end(), nval);
  
  // Error if already there
  if (i == fidx_table.end() || *i != nval) {
    i = fidx_table.insert(i, nval);
  } else Throw() << "Field:" << fname << ", already added nval:" << nval;
  
  // Insert field at same spot.
  UInt pos = std::distance(fidx_table.begin(), i);
  typename std::vector<_FIELD*>::iterator fi = fields.begin() + pos;
  UInt cursize = fields.size();
  if (cursize == 0) primaryfield = f;
  // if nval is larger, resize.  Keeps old fields, assigns null elsewhere
  ThrowAssert(fields.size() <= pos);
  fields.insert(fi, f);
}

template<typename _FIELD>
UInt MEField<_FIELD>::Numfields() const {
  return fidx_table.size();
}

template<typename _FIELD>
_FIELD *MEField<_FIELD>::Getfield(UInt nval) const {
  std::vector<UInt>::const_iterator i = 
    std::lower_bound(fidx_table.begin(), fidx_table.end(), nval);
  // Error if not there
  if (i == fidx_table.end() || *i != nval) {
    Throw() << "Field:" << fname << ", could not get nval:" << nval;
  }

  UInt pos = std::distance(fidx_table.begin(), i);
  return *(fields.begin() + pos);
};

template<typename _FIELD>
void MEField<_FIELD>::Getfields(std::vector<_FIELD*> &res) const {
  for (UInt i = 0; i < fields.size(); i++) {
    if (fields[i]) res.push_back(fields[i]);
  }
}

// ****** MEField ********
template<typename _FIELD>
MEField<_FIELD>::MEField(const std::string &_name, const MEFamily &_mef,
    UInt _obj_type, const Context &_ctxt, UInt dim, bool out, bool interp, const _fieldTypeBase &_ftype) :
MEFieldBase(_name, _mef, _obj_type, _ctxt, dim, out, interp, _ftype),
primaryfield(NULL),
interpfield(NULL)
{
}

template<typename _FIELD>
MEField<_FIELD>::~MEField() {
}

// MEField<SField> specialization
MEField<SField>::MEField(MEField<_field> &rhs) :
MEFieldBase(rhs.name(), rhs.GetMEFamily(), rhs.ObjType(), rhs.GetContext(), rhs.dim(), false, false, rhs.FType()),
primaryfield(NULL),
f(rhs),
dof_buffer(0)
{
  primaryfield = new SField(*rhs.Getfield());
  
  MEFieldBase::ordinal = rhs.ordinal;
  
}


/*-------------------------------------------------------*/
// The MEField<SField> specialization
/*-------------------------------------------------------*/

MEField<SField>::~MEField() {
  
  delete primaryfield;

}




UInt MEField<SField>::AssignElement(MeshObj &element) {
  
  cur_elems.clear();
  
  cur_elems.push_back(&element);
  
  return do_assign_elements(cur_elems);
}

UInt MEField<SField>::do_assign_elements(std::vector<MeshObj*> &elems) {
  
  UInt fdim = f.dim();
  
  primaryfield->Reset();
  field_objs.clear();
  
  UInt dof_count;
  
  // Count the unique degrees of freedom.  Set aside the objects for each
  // sfield.
  for (UInt e = 0; e < elems.size(); ++e) {
    
    MeshObj &elem = *cur_elems[e];

    MasterElementBase &meb = GetME( f, elem);

    // Loop dofs
    for (UInt df = 0; df < meb.num_functions(); df++) {
      
      const int *dd = meb.GetDofDescription(df);

      // Get the object;
      MeshObj *dofobj = NULL;

      if (dof2mtype(dd[0]) != MeshObj::ELEMENT) {
        
        MeshObjRelationList::const_iterator ri =
           MeshObjConn::find_relation(elem, dof2mtype(dd[0]), dd[1], MeshObj::USES);

        ThrowRequire(ri != elem.Relations.end());

        dofobj = ri->obj;

      } else dofobj = &elem;
      
      field_objs.insert(dofobj);
      
    } // num_func
    
    
  } // for e
  
  // Count of dofs is:
  UInt count = 0;
  std::set<MeshObj*>::iterator fsi = field_objs.begin(), fse = field_objs.end();
 
  for (; fsi != fse; ++fsi)
    count += primaryfield->dim(**fsi);
  
  return count;
}

void MEField<SField>::ReInit(fad_type *_dof_buffer) {
  
  dof_buffer = _dof_buffer;
  
  // Assign the dof buffer to each SField
  UInt cur = 0;

  primaryfield->SetData(field_objs.begin(), field_objs.end(), dof_buffer);

}

void MEField<SField>::set_diff(UInt offset, UInt total_dofs) {
  
  UInt idx = offset;
  
  ThrowRequire(cur_elems.size() == 1);
  
  UInt fdim = f.dim();
  
  MeshObj &elem = *cur_elems[0];
  
  MasterElementBase &meb = GetME( f, elem);
  
  UInt nfunc = meb.num_functions();
  
  // Loop dofs
  for (UInt df = 0; df < meb.num_functions(); df++) {
    
    const int *dd = meb.GetDofDescription(df);

    // Get the object;
    MeshObj *dofobj = NULL;

    if (dof2mtype(dd[0]) != MeshObj::ELEMENT) {
      
      MeshObjRelationList::const_iterator ri =
         MeshObjConn::find_relation(elem, dof2mtype(dd[0]), dd[1], MeshObj::USES);

      ThrowRequire(ri != elem.Relations.end());

      dofobj = ri->obj;

    } else dofobj = &elem;

    SField &llf = *Getfield();
    fad_type *fad = llf.data(*dofobj);
//Par::Out() << "sdof: " << llf.name() << std::endl;
    
    for (UInt d = 0; d < fdim; ++d) {
    
/*
Par::Out() << "\tfad[" << dd[2]*fdim+d << "] = diff:" << offset+d*nfunc+df << std::endl;
Par::Out() << "\t&fad[" << &fad[dd[2]*fdim+d] << "] = diff:" << offset+d*nfunc+df << std::endl;
fad[dd[2]*fdim+d] = df;
*/
      fad[dd[2]*fdim+d].diff(offset + d*nfunc + df,total_dofs);
      
    }
    
  } // num_func
  
}

//************* Instantiations ***************
template class MEField<_field>;

} // namespace
