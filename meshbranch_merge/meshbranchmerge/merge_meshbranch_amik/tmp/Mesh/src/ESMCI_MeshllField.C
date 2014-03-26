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
#include <Mesh/include/ESMCI_MeshllField.h>

//-----------------------------------------------------------------------------
// leave the following line as-is; it will insert the cvs ident string
// into the object file for tracking purposes.
static const char *const version = "$Id$";
//-----------------------------------------------------------------------------

namespace ESMCI {


template<typename SCALAR>
_fieldTypeBase *_fieldType<SCALAR>::classInstance = NULL;

template<typename SCALAR>
const _fieldTypeBase &_fieldType<SCALAR>::instance() {
  if (classInstance == NULL) {
    classInstance = new _fieldType();
  }
  return *classInstance;
}

template<typename SCALAR>
_fieldType<SCALAR>::_fieldType() :
_fieldTypeBase(),
ti(typeid(SCALAR))
{
}

template<typename SCALAR>
_fieldType<SCALAR>::~_fieldType() {
}

template<typename SCALAR>
void _fieldType<SCALAR>::non_virtual_func() {
}

template<typename SCALAR>
std::size_t _fieldType<SCALAR>::size() const {
  return sizeof(SCALAR);
}

template class _fieldType<char>;
template class _fieldType<long>;
template class _fieldType<int>;
template class _fieldType<UChar>;
template class _fieldType<float>;
template class _fieldType<double>;


// ******* low level fields *********
static UInt round_to_dword(UInt size) {
  UInt dwsz = sizeof(void*)*4;
  //UInt dwsz = sizeof(void*)*2;
  //UInt dwsz = 64;
  UInt rm = size % dwsz;
  return rm ? size + (dwsz - rm) : size;
}


_field::_field(const std::string &name, const _fieldLocale &floc, const _fieldTypeBase &_ftype) :
fname(name),
my_loc(),
ordinal(-1),
ti(_ftype.type()),
data_size(_ftype.size()),
union_type(floc.obj_type)
{
  my_loc.push_back(floc);
}

_field::_field(const std::string &name, const _fieldTypeBase &_ftype) :
fname(name),
my_loc(),
ordinal(-1),
ti(_ftype.type()),
data_size(_ftype.size()),
union_type(0)
{
}

void _field::add_locale(const _fieldLocale &floc) {
  std::vector<_fieldLocale>::iterator lb =
    std::lower_bound(my_loc.begin(), my_loc.end(), floc);

  if (lb == my_loc.end() || floc != *lb) {

    my_loc.insert(lb, floc);

    union_type |= floc.obj_type;

  } else {
    // Make sure the dimensions agree.
    if (floc.dim != lb->dim) Throw() << "Error registering field" << fname << ", dims do"
      << " not agree:" << floc.dim << "!=" << lb->dim << std::endl;
  }
}

const _fieldLocale *_field::OnAttr(const Attr &attr, bool verify) const {

  const _fieldLocale *fret = 0;

  std::vector<_fieldLocale>::const_iterator fl = my_loc.begin(), fe = my_loc.end();

  for (; fl != fe; ++fl) {
  
    if ((fl->obj_type & attr.GetType()) && attr.GetContext().is_set(fl->contextId)) {

     
      if (!verify) return &*fl;

      // Make sure any other matches have same dim
      if (fret && fret->dim != fl->dim) {
        Throw() << "Error. Field dims do not agree on attr.  fdim1=" << fret->dim << ", fdim2=" << fl->dim << ", attr=" << attr;
      }

      fret = &*fl;

    } // matches

  } // fl

  return fret;
  
}

bool _field::OnObj(const MeshObj &obj) const {
  // Quickest check:  Just look at the offset
  const std::pair<_fieldStore*,UInt> &st = obj.GetStore();
  UChar *offset = st.first->Offset(ordinal);
  return offset != NULL;
}


// ******* Field storage **********

long _fieldStore::nstores = 0;

_fieldStore::_fieldStore(UInt _nobj) :
NOBJS(_nobj),
offsets(NULL),
offsize(0),
fdims(0),
fdimsize(0),
fstrides(0),
fstridesize(0),
next_free(0),
free_stride(0),
data(NULL),
is_committed(false),
nfield(0),
num_objs(0)
{
  ++nstores;
  if (NOBJS > 254) Throw() << "Max NOBJS=254, due to using UCHAR for next free";
}

_fieldStore::~_fieldStore() {

  --nstores;
  delete [] data;

}


void _fieldStore::Create(UInt nfields, _field **fields, const Attr &attr) {

  nfield = nfields;

  // Loop fields; if field lives here, add storage.
  std::size_t bufSize = 0;

  // store offsets at beginning of data block
  offsize = round_to_dword(sizeof(UChar*)*nfields);
  bufSize += offsize;

  // Store field dims at beginning of buffer
  fdimsize = round_to_dword(sizeof(UInt)*nfields);
  bufSize += fdimsize;

  // Store field strides at beginning of buffer
  fstridesize = round_to_dword(sizeof(UInt)*nfields);
  bufSize += fstridesize;

  nfreesize = round_to_dword(sizeof(UChar)*NOBJS);
  bufSize += nfreesize;

  // first a sizing pass
  int first_field = -1;
  int fieldsOnKer = 0;
  for (UInt f = 0; f < nfields; f++) {
    _field &fd = *fields[f];

    const _fieldLocale *floc; 

    // Get the size of field.  Also, make sure we are not in an inconsistent
    // intersection, i.e. the field dimension is multivalued
    if ((floc = fd.OnAttr(attr, true))) {
      fieldsOnKer++;
      if (first_field < 0) first_field = f;
      bufSize += round_to_dword(NOBJS*floc->dim*fd.DataSize());
    }

  }

  // allocate
  ThrowRequire(data == 0);
  data = new UChar[bufSize];

  totsize = bufSize;

  UChar *end = data + bufSize;

  // Pointer to the field data
  field_data = data + (offsize + fdimsize + fstridesize + nfreesize);

  std::fill(data, end, (UChar) 0);
  //std::memset(data,'0',bufSize*sizeof(data[0]));

  // Set up the offsets buffer, fdim, fstride
  offsets = reinterpret_cast<UChar**>(data);
  fdims = reinterpret_cast<UInt*>(&data[offsize]);
  fstrides = reinterpret_cast<UInt*>(&data[offsize+fdimsize]);
  nfree = reinterpret_cast<UChar*>(&data[offsize+fdimsize+fstridesize]);

  UInt dataSize = 0;
  for (UInt f = 0; f < nfields; f++) {

    _field &fd = *fields[f];

    const _fieldLocale *floc; 

    if ((floc = fd.OnAttr(attr, false))) {

      offsets[f] = &field_data[dataSize];
      dataSize += round_to_dword(NOBJS*floc->dim*fd.DataSize());
      fdims[f] = floc->dim;
      fstrides[f] = floc->dim*fd.DataSize();

    } else {

      offsets[f] = NULL;
      fdims[f] = 0;
      fstrides[f] = 0;

    }

  } // f
  

  // The stride of the next free table;
  free_stride = sizeof(UChar);

  // set up next free table
  for (UChar i = 0; i < NOBJS-1; i++) {
    nfree[i*free_stride] = i+1;
  }

  nfree[(NOBJS-1)*free_stride] = TABLE_FULL; // end of free

  is_committed = true;

}

void _fieldStore::remove(UInt idx) {

  nfree[idx*free_stride] = next_free;
  next_free = idx;
  num_objs--;

}

UInt _fieldStore::insert() {

  ThrowRequire(is_committed);

  if (next_free == TABLE_FULL)
    Throw() << "Inserting into full freeStore!!";
  UInt idx = next_free;
//std::cout << "next_free=" << next_free << " fs:" << free_stride << std::endl;
  next_free = nfree[next_free*free_stride];

  num_objs++;

  return idx;
}

void _fieldStore::CopyIn(UInt nfields, _field **fields, MeshObj &obj, UInt idx) {

  for (UInt f = 0; f < nfields; f++) {

    UChar *newloc = Offset(f);

    if (newloc == NULL) continue;
    const UInt stride = fstrides[f];
    newloc += idx*stride; // move to correct object
    UChar *oldloc = obj.GetStore().first->Offset(f);
    int oldidx = obj.GetStore().second;
    if (oldloc == NULL) {
      // zero out data
      std::fill(newloc, newloc + stride, 0);
      //std::memset(newloc,'0',stride*sizeof(newloc[0]));
      continue;
    }
    oldloc += oldidx*stride;
    std::copy(oldloc, oldloc + stride, newloc);
    //std::memcpy(newloc, oldloc,stride*sizeof(newloc[0]));
  }
}

void _fieldStore::Zero(UInt nfields, _field **fields, UInt idx) {
  for (UInt f = 0; f < nfields; f++) {
    UChar *newloc = Offset(f);
    if (newloc == NULL) continue;
    const UInt stride = fstrides[f];
    newloc += idx*stride;
    //std::fill(newloc, newloc + stride, 0);
    std::fill_n(newloc, stride, 0);
    //std::memset(newloc,'0',stride*sizeof(newloc[0]));
  }
}

double _fieldStore::FillRatio() const {

  // Traverse the free list to see how many slots left;
  UInt left = 0;
  
  UChar next = next_free;
  while (next != TABLE_FULL) {
    next = nfree[next*free_stride];
    left++;
  }
  return (double) (NOBJS - left) / NOBJS;
}

void _fieldStore::PrintMetaData(std::ostream &os, UInt nfields, _field *const*fields) const {

  os << "Store (fields,fdim,fstride,offset): ";
  for (UInt i = 0; i < nfields; ++i) {

    os << "\t(" << fields[i]->name() << ", " << fdims[i] << ", " << fstrides[i] << ", " << offsets[i] << ")" << std::endl;

  }

}

} // namespace
