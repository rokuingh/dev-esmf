#include <Mesh/include/ESMCI_MEFieldBlas.h>
#include <Mesh/include/ESMCI_MeshllField.h>
#include <Mesh/include/ESMCI_Mesh.h>

#include <Mesh/include/ESMCI_ParEnv.h>

#include <typeinfo>


namespace ESMCI {

template <typename Number>
void MEFieldFill(const Mesh &mesh, MEField<> &Field, Number n) {

  const _fieldTypeBase &ft = Field.FType();
  ThrowRequire(ft.type() == typeid(Number));

  _field &llf = *Field.Getfield();

  // Loop kernels
  KernelList::const_iterator ki = mesh.set_begin(), ke = mesh.set_end();

  for (; ki != ke; ++ki) {

    const Kernel &ker = *ki;

    if (!ker.is_active()) continue;

    // Is field on kernel?
    const _fieldLocale *lfp;
    if (!(lfp=llf.OnAttr(ker.GetAttr(), false))) continue;
 
    UInt dim = lfp->dim;

    Kernel::store_const_iterator sb = ker.store_begin(), se = ker.store_end();

    for (; sb != se; ++sb) {

      const _fieldStore &store = *sb;

      Number *data = _fieldValuePtr(store.Offset(llf.GetOrdinal()), ft.type());

      Number *end_data = data + dim*store.NOBJS;

      while (data != end_data) *data++ = n;


    } // sb

  } // ki

}

template void MEFieldFill(const Mesh &mesh, MEField<> &Field, double n);
template void MEFieldFill(const Mesh &mesh, MEField<> &Field, int n);
template void MEFieldFill(const Mesh &mesh, MEField<> &Field, char n);
template void MEFieldFill(const Mesh &mesh, MEField<> &Field, UChar n);

template <typename Number>
void MEFieldAdd(const Mesh &mesh, MEField<> &Field, Number a, MEField<> &RhsField) {

  const _fieldTypeBase &ft = Field.FType();
  ThrowRequire(ft.type() == typeid(Number));
  const _fieldTypeBase &ftr = RhsField.FType();
  ThrowRequire(ftr.type() == typeid(Number));

  _field &llf = *Field.Getfield();
  _field &rllf = *RhsField.Getfield();

  // Loop kernels
  KernelList::const_iterator ki = mesh.set_begin(), ke = mesh.set_end();

  for (; ki != ke; ++ki) {

    const Kernel &ker = *ki;

    if (!ker.is_active()) continue;

    // Is field on kernel?
    const _fieldLocale *lfp = llf.OnAttr(ker.GetAttr(), false);
    const _fieldLocale *rlfp = rllf.OnAttr(ker.GetAttr(), false);

    // Either both are NULL of neither
    ThrowRequire((!lfp && !rlfp) || (lfp && rlfp));
    if (!lfp) continue; 

    ThrowRequire(lfp->dim == rlfp->dim);

    UInt dim = lfp->dim;

    Kernel::store_const_iterator sb = ker.store_begin(), se = ker.store_end();

    for (; sb != se; ++sb) {

      const _fieldStore &store = *sb;

      Number *data = _fieldValuePtr(store.Offset(llf.GetOrdinal()), ft.type());
      Number *rdata = _fieldValuePtr(store.Offset(rllf.GetOrdinal()), ft.type());

      Number *end_data = data + dim*store.NOBJS;

      while (data != end_data) *(data++) += (*(rdata++))*a;

    } // sb

  } // ki

}

template void MEFieldAdd(const Mesh &mesh, MEField<> &Field, double a, MEField<> &RhsField);

template <typename Number>
void MEFieldSAdd(const Mesh &mesh, MEField<> &Field, Number s, Number a, MEField<> &RhsField) {

  const _fieldTypeBase &ft = Field.FType();
  ThrowRequire(ft.type() == typeid(Number));
  const _fieldTypeBase &ftr = RhsField.FType();
  ThrowRequire(ftr.type() == typeid(Number));

  _field &llf = *Field.Getfield();
  _field &rllf = *RhsField.Getfield();

  // Loop kernels
  KernelList::const_iterator ki = mesh.set_begin(), ke = mesh.set_end();

  for (; ki != ke; ++ki) {

    const Kernel &ker = *ki;

    if (!ker.is_active()) continue;

    // Is field on kernel?
    const _fieldLocale *lfp = llf.OnAttr(ker.GetAttr(), false);
    const _fieldLocale *rlfp = rllf.OnAttr(ker.GetAttr(), false);

    // Either both are NULL of neither
    ThrowRequire((!lfp && !rlfp) || (lfp && rlfp));
    if (!lfp) continue; 

    ThrowRequire(lfp->dim == rlfp->dim);

    UInt dim = lfp->dim;

    Kernel::store_const_iterator sb = ker.store_begin(), se = ker.store_end();

    for (; sb != se; ++sb) {

      const _fieldStore &store = *sb;

      Number *data = _fieldValuePtr(store.Offset(llf.GetOrdinal()), ft.type());
      Number *rdata = _fieldValuePtr(store.Offset(rllf.GetOrdinal()), ft.type());

      Number *end_data = data + dim*store.NOBJS;

      while (data != end_data) {

        *data = s*(*data) + a*(*rdata);
         data++; rdata++;
      }

    } // sb

  } // ki

}

template void MEFieldSAdd(const Mesh &mesh, MEField<> &Field, double s, double a, MEField<> &RhsField);


template <typename Number>
void MEFieldAssign(const Mesh &mesh, MEField<> &Field, MEField<> &RhsField) {

  const _fieldTypeBase &ft = Field.FType();
  ThrowRequire(ft.type() == typeid(Number));
  const _fieldTypeBase &ftr = RhsField.FType();
  ThrowRequire(ftr.type() == typeid(Number));

  _field &llf = *Field.Getfield();
  _field &rllf = *RhsField.Getfield();

  // Loop kernels
  KernelList::const_iterator ki = mesh.set_begin(), ke = mesh.set_end();

  for (; ki != ke; ++ki) {

    const Kernel &ker = *ki;

    if (!ker.is_active()) continue;

    // Is field on kernel?
    const _fieldLocale *lfp = llf.OnAttr(ker.GetAttr(), false);
    const _fieldLocale *rlfp = rllf.OnAttr(ker.GetAttr(), false);

    // Either both are NULL of neither
    ThrowRequire((!lfp && !rlfp) || (lfp && rlfp));
    if (!lfp) continue; 

    ThrowRequire(lfp->dim == rlfp->dim);

    UInt dim = lfp->dim;

    Kernel::store_const_iterator sb = ker.store_begin(), se = ker.store_end();

    for (; sb != se; ++sb) {

      const _fieldStore &store = *sb;

      Number *data = _fieldValuePtr(store.Offset(llf.GetOrdinal()), ft.type());
      Number *rdata = _fieldValuePtr(store.Offset(rllf.GetOrdinal()), ft.type());

      Number *end_data = data + dim*store.NOBJS;

      while (data != end_data) *data++ = *rdata++;


    } // sb

  } // ki

}

template void MEFieldAssign<double>(const Mesh &mesh, MEField<> &Field, MEField<> &RhsField);

} // namespace
