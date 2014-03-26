#ifndef ESMCI_MeshllField_h
#define ESMCI_MeshllField_h

#include <Mesh/include/ESMCI_MeshTypes.h>
#include <Mesh/include/ESMCI_Attr.h>
#include <Mesh/include/ESMCI_List.h>

#include <typeinfo>
#include <cstddef>
#include <string>
#include <ostream>


/**
 * @defgroup BaseField
 * 
 * A subsystem that implements a fixed size field on a given set of
 * mesh objects (described by an Attr).
 * 
 * @ingroup field
 */

namespace ESMCI {

class _field;

/**
 * The basic field storage object for a set of mesh objects that
 * all have the same fields present.  All fields for a small set of
 * objects of homogenous attribute are store in this object in an
 * array (actually a table) of values.
 * @ingroup BaseField
*/
class _fieldStore : public ListNode<_fieldStore> {
public:

// Number of objects to store
const UInt NOBJS;

/**
 * We can store at max 254 objects in table due to using
 * a UChar as the next free index.
*/
enum { TABLE_FULL = 255 };

// Pass the fields that live on the mesh and the context for
// the Kernel this store services.
_fieldStore(UInt _nobj);
~_fieldStore();

/**
 * Note: one should send the ENTIRE registrar of fields to EVERY
 * store.  The store figures out whether or not the field will live
 * here, but the offset table expects all fields.
 */
void Create(UInt nfields, _field **fields, const Attr &attr);

/**
 * Copy the data for an object into this store.  The object is
 * still pointing to the old store.  idx is the index in this store
 * to place the object.
 */
void CopyIn(UInt nfields, _field **fields, MeshObj &obj, UInt idx);

/**
 * Print the offset/fdim, etc info stored at the beginning of
 * the store
 */
void PrintMetaData(std::ostream &, UInt nfields, _field *const*fields) const;

/*
 * Zero out a slot for an object.
 */
void Zero(UInt nfields, _field **fields, UInt idx);

bool Full() const { return next_free == TABLE_FULL; }
bool empty() const { return num_objs == 0; }

/*
 * Free a data slot referenced by idx.
 */
void remove(UInt idx); 

/*
 * Insert an object (return slot number) into the next free (should check
 * to make sure not full first)
 */
UInt insert();

/**
 * Return the offset into buffer for a given field.
 */
UChar *Offset(UInt fnum) const { ThrowAssert(fnum < nfield && is_committed); return offsets[fnum];}

/** 
 * Return the stride (fdim*datasize) of the field
 */
UInt Stride(UInt fnum) const { ThrowAssert(fnum < nfield && is_committed); return fstrides[fnum];}

/**
 * Return dimension of the given field on this kernel
 */
UInt fieldDim(UInt fnum) const { ThrowAssert(fnum < nfield && is_committed); return fdims[fnum];}

UChar *GetData() const { return data;}

/*
 * Return number of objects in store.
 */
UInt NumObjs() const { return num_objs; }

/* 
 * Return ration of num slots used / total num
 */
double FillRatio() const;

/**
 * Return the size of the data buffer.
 */
long MemUsage() const { return totsize; }

static long nstores;

private:

/** offset table for fields into storage */
UChar **offsets;
UInt offsize;

/** Next free table */
UChar *nfree;
UInt nfreesize;

/** Array of field dimensions */
UInt *fdims;
UInt fdimsize;

/**
 * Array of field strides (fdim*data_size).  Store these
 * to avoid an unnecessary multiply
 */
UInt *fstrides;
UInt fstridesize;

UChar next_free;

/** Stride of first field.  Used to store the next object list */
UInt free_stride; // stride of first field
UChar *data;

/** Beginning of field data */
UChar *field_data;

bool is_committed;

/** Number of fields living on the kernel */
UInt nfield;
UInt num_objs;

long totsize;


};

/**
 * A class to help encapsulate the C++ type a given field is.  This
 * class helps provide type safety in debug mode.
 * @ingroup BaseField
*/
class _fieldTypeBase {
public:
  _fieldTypeBase() {}
  _fieldTypeBase(const _fieldTypeBase &rhs) {}
  virtual ~_fieldTypeBase() {}
  virtual std::size_t size() const = 0;
  virtual const std::type_info &type() const = 0;
};
/**
 * Provide an easy template style interface to the base
 * @ingroup BaseField
 */
template<typename SCALAR>
class _fieldType : public _fieldTypeBase {
public:
  ~_fieldType();
  void non_virtual_func();
  std::size_t size() const;
  const std::type_info &type() const { return ti;}
  static const _fieldTypeBase &instance();
private:
  _fieldType(const _fieldType &rhs) : ti(rhs.ti) {}
  static _fieldTypeBase *classInstance;
  _fieldType();
  const std::type_info &ti;
};

/**
 * Object that facilitates casting a block of memory to a type pointer.
 * Provides for type checking in debug mode, and fast casting in optimized.
 * @ingroup BaseField
*/
class _fieldValuePtr {
public:

#ifdef NDEBUG
_fieldValuePtr(void *dptr, const std::type_info &) : data(dptr) {}
_fieldValuePtr(const _fieldValuePtr &rhs) : data(rhs.data) {}

// Constructors from  specific types
_fieldValuePtr(UChar *dptr) : data(dptr){}
_fieldValuePtr(char *dptr) : data(dptr){}
_fieldValuePtr(int *dptr) : data(dptr) {}
_fieldValuePtr(long *dptr) : data(dptr) {}
_fieldValuePtr(float *dptr) : data(dptr) {}
_fieldValuePtr(double *dptr) : data(dptr) {}
_fieldValuePtr(fad_type *dptr) : data(dptr) {}
#else
_fieldValuePtr(void *dptr, const std::type_info &_ti) : data(dptr), ti(_ti) {}
_fieldValuePtr(const _fieldValuePtr &rhs) : data(rhs.data), ti(rhs.ti) {}

// Constructors from  specific types
_fieldValuePtr(UChar *dptr) : data(dptr), ti(typeid(UChar)) {}
_fieldValuePtr(char *dptr) : data(dptr), ti(typeid(char)) {}
_fieldValuePtr(int *dptr) : data(dptr), ti(typeid(int)) {}
_fieldValuePtr(long *dptr) : data(dptr), ti(typeid(long)) {}
_fieldValuePtr(float *dptr) : data(dptr), ti(typeid(float)) {}
_fieldValuePtr(double *dptr) : data(dptr), ti(typeid(double)) {}
_fieldValuePtr(fad_type *dptr) : data(dptr), ti(typeid(fad_type)) {}
#endif

// Cast to pointer
operator UChar*() const { ThrowAssert(ti == typeid(UChar)); return static_cast<UChar*>(data); }
operator char*() const { ThrowAssert(ti == typeid(char)); return static_cast<char*>(data); }
operator int*() const { ThrowAssert(ti == typeid(int)); return static_cast<int*>(data); }
operator long*() const { ThrowAssert(ti == typeid(long)); return static_cast<long*>(data); }
operator float*() const { ThrowAssert(ti == typeid(float)); return static_cast<float*>(data); }
operator double*() const { ThrowAssert(ti == typeid(double)); return static_cast<double*>(data); }
operator fad_type*() const { ThrowAssert(ti == typeid(fad_type)); return static_cast<fad_type*>(data); }

// Cast to reference
operator UChar&() const { ThrowAssert(ti == typeid(UChar)); return *static_cast<UChar*>(data); }
operator char&() const { ThrowAssert(ti == typeid(char)); return *static_cast<char*>(data); }
operator int&() const { ThrowAssert(ti == typeid(int)); return *static_cast<int*>(data); }
operator long&() const { ThrowAssert(ti == typeid(long)); return *static_cast<long*>(data); }
operator float&() const { ThrowAssert(ti == typeid(float)); return *static_cast<float*>(data); }
operator double&() const { ThrowAssert(ti == typeid(double)); return *static_cast<double*>(data); }
operator fad_type&() const { ThrowAssert(ti == typeid(fad_type)); return *static_cast<fad_type*>(data); }

private:
void *data;
#ifdef NDEBUG
#else
const std::type_info &ti;
#endif
};

/**
 * Define the attributes for a homogenous locale of a field.
 * fdim is not in the key because fdim must be the same for 
 * the same obj_type and contextId.
 */
struct _fieldLocale {

  _fieldLocale(UChar _obj_type, UInt _contextId, UInt _dim) :
    obj_type(_obj_type), contextId(_contextId), dim(_dim) {}

  UChar obj_type;
  UInt contextId;
  UInt dim;

  bool operator<(const _fieldLocale &rhs) const {
    if (obj_type != rhs.obj_type) return obj_type < rhs.obj_type;
    return contextId < rhs.contextId;
  }

  bool operator==(const _fieldLocale &rhs) const {
    return (obj_type == rhs.obj_type) && (contextId == rhs.contextId);
  }

  bool operator!=(const _fieldLocale &rhs) const {
    return !(*this == rhs);
  }
};

/**
 * Basic class representing a BaseField that lives on some set of
 * mesh objects.
 * This field lives on the union of subsets described by a context value.
 * i.e. if the context is 1000111, the field will life on any kernel that
 * has any one of these bits set.
 * @ingroup BaseField
*/
class _field {
public:
_field(const std::string &name, const _fieldLocale &floc, const _fieldTypeBase &_ftype); 

/**
 * Create with no locale.
 */
_field(const std::string &name, const _fieldTypeBase &_ftype); 

/**
 * Add a locale to the field.
 */
void add_locale(const _fieldLocale &loc);

const std::string &name() const { return fname;}

/**
 * Return the ordinal of this field within the scheme of all fields
 */
int GetOrdinal() { return ordinal; }

/**
 * Return the pointer to a meshObj/_field pair.  Uses the kernel and index
 * store in the object + field ordinal to arrive at the given location.
 */
_fieldValuePtr data(const MeshObj &obj) const {
  const std::pair<_fieldStore*,UInt> &st = obj.GetStore();
  UChar *offset = st.first->Offset(ordinal);
  return offset ? 
      _fieldValuePtr(
      &offset[st.second*st.first->Stride(ordinal)], ti)
       : _fieldValuePtr(NULL, ti);
}

/**
 * Return the dimension of this field on the given mesh object.
 */
UInt dim(const MeshObj &obj) const {
  const std::pair<_fieldStore*,UInt> &st = obj.GetStore();
 
  return st.first->fieldDim(ordinal);
}

/**
 * Return true if the field is on this object, else false
 */
bool OnObj(const MeshObj &obj) const;

/** If this field lives on the given attr, return the locale, else
 * return NULL.  If !verify, returns the first, otherwise makes
 * sure there are not conflicting locales on the attr.
 */
const _fieldLocale *OnAttr(const Attr &attr, bool verify) const;

/**
 * Set the ordinal of the field 
 */
void set_ordinal(UInt ord) { ordinal = ord;}

/**
 * Return a union of the types this field lives on.
 */
UChar UnionType() const { return union_type; }

const std::type_info &tinfo() const { return ti;}

/**
 * Size of the underlying data type stored by the field.
 */
UInt DataSize() const { return data_size; }

std::vector<_fieldLocale>::const_iterator locale_begin() const { return my_loc.begin(); };
std::vector<_fieldLocale>::const_iterator locale_end() const { return my_loc.end(); };

private:
std::string fname;
std::vector<_fieldLocale> my_loc;
int ordinal; // ordinal in field registry
const std::type_info &ti;

/** size of a data entity */
UInt data_size;
UChar union_type;
};



} // namespace


#endif
