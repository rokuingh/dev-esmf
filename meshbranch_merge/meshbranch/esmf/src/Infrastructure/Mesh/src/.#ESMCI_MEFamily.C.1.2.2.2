#include <Mesh/include/ESMCI_MEFamily.h>
#include <Mesh/include/ESMCI_Exception.h>

#include <Mesh/include/ESMCI_ShapeHierarchic.h>
#include <Mesh/include/ESMCI_ShapeLagrange.h>
#include <Mesh/include/ESMCI_SFuncAdaptor.h>
#include <Mesh/include/ESMCI_ShapeMini.h>
#include <cstdio>

namespace ESMCI {

/*
MasterElement<METraits<> > *MEFamily::getME(const std::string &toponame) const {
  return getME(toponame, METraits<>());
};
*/

const intgRule *MEFamily::GetIntg(const std::string &toponame) const {
  return Topo2Intg()(this->getME(toponame, METraits<>())->IntgOrder(), toponame);
}


// STD
MEFamilyStd *MEFamilyStd::classInstance = NULL;

MEFamilyStd::MEFamilyStd() :
MEFamily(),
fname("Standard Lagrange")
{
}

const MEFamilyStd &MEFamilyStd::instance() {
  if (classInstance == NULL) {
    classInstance = new MEFamilyStd();
  }

  return *classInstance;
}

MasterElement<METraits<> > *MEFamilyStd::getME(const std::string &toponame, METraits<>) const {
  return Topo2ME<METraits<> >()(toponame);
}


// LOW
MEFamilyLow *MEFamilyLow::classInstance = NULL;

MEFamilyLow::MEFamilyLow() :
MEFamily(),
fname("Linear Lagrange")
{
}

const MEFamilyLow &MEFamilyLow::instance() {
  if (classInstance == NULL) {
    classInstance = new MEFamilyLow();
  }

  return *classInstance;
}

MasterElement<METraits<> > *MEFamilyLow::getME(const std::string &toponame, METraits<>) const {
  return Topo2ME<METraits<> >()(toponame+"_L");
}

// DG
std::map<UInt,MEFamilyDG*> MEFamilyDG::classInstances;

static const std::string get_dg_name(int ndof) {
  char buf[512];
  std::sprintf(buf, "DG_%03d", ndof);

  return std::string(buf);
}

MEFamilyDG::MEFamilyDG(UInt _ndof) :
MEFamily(),
fname(get_dg_name(_ndof)),
ndof(_ndof)
{
}

const MEFamilyDG &MEFamilyDG::instance(UInt ndof) {

  std::map<UInt, MEFamilyDG*>::iterator fi = classInstances.find(ndof);
  MEFamilyDG *mef;
  if (fi == classInstances.end()) {
    mef = new MEFamilyDG(ndof);
    classInstances[ndof] = mef;
  } else mef = fi->second;

  return *mef;
}

MasterElement<METraits<> > *MEFamilyDG::getME(const std::string &toponame, METraits<>) const {
  // First get a suitable mapping
  const MeshObjTopo *topo = GetTopo(toponame);
  if (!topo) Throw() << "DG0 get Me, couldn't get topo";
  if (topo->parametric_dim == 2) {
    return MasterElementDG<METraits<> >::instance(ndof);
  } else if (topo->parametric_dim == 3) {
    return MasterElementDG<METraits<> >::instance(ndof);
  } else Throw() << "DG0 getME, unexpected pdim";
}

// Hier
std::map<UInt, MEFamilyHier*> MEFamilyHier::classInstances;

MEFamilyHier::MEFamilyHier(UInt _order) :
MEFamily(),
fname("Hier"),
order(_order)
{
}

const MEFamilyHier &MEFamilyHier::instance(UInt order) {
  std::map<UInt, MEFamilyHier*>::iterator fi = classInstances.find(order);
  MEFamilyHier *mef;
  if (fi == classInstances.end()) {
    mef = new MEFamilyHier(order);
    classInstances[order] = mef;
  } else mef = fi->second;

  return *mef;
}

MasterElement<METraits<> > *MEFamilyHier::getME(const std::string &name, METraits<>) const {
  if (name == "SHELL" || name == "SHELL4" || name == "QUAD" || name == "QUAD4" || name == "QUAD_3D") {
    return MasterElementV<METraits<> >::instance(QuadHier::instance(order));
  } else if (name == "SHELL3" || name == "TRI" || name == "TRI3" || name == "TRISHELL") {
    return MasterElementV<METraits<> >::instance(TriHier::instance(order));
  } else Throw() << "Hierar not implemented for topo:" << name;
}

// Lagrange

std::map<UInt, MEFLagrange*> MEFLagrange::classInstances;

MEFLagrange::MEFLagrange(UInt _order) :
MEFamily(),
fname("Lagrange"),
order(_order)
{
}

const MEFLagrange &MEFLagrange::instance(UInt order) {
  std::map<UInt, MEFLagrange*>::iterator fi = classInstances.find(order);
  MEFLagrange *mef;
  if (fi == classInstances.end()) {
    mef = new MEFLagrange(order);
    classInstances[order] = mef;
  } else mef = fi->second;

  return *mef;
}

MasterElement<METraits<> > *MEFLagrange::getME(const std::string &name, METraits<>) const {
  if (name == "SHELL" || name == "SHELL4" || name == "QUAD" || name == "QUAD4" || name == "QUAD_3D") {
    return MasterElementV<METraits<> >::instance(ShapeLagrangeQuad::instance(order));

  } else if (name == "HEX") {
    return MasterElementV<METraits<> >::instance(ShapeLagrangeHex::instance(order));
  } else Throw() << "Lagrange not implemented for topo:" << name;
}

// Lagrange DG
std::map<UInt, MEFLagrangeDG*> MEFLagrangeDG::classInstances;

MEFLagrangeDG::MEFLagrangeDG(UInt _order) :
MEFamily(),
fname("LagrangeDG"),
order(_order)
{
}

const MEFLagrangeDG &MEFLagrangeDG::instance(UInt order) {
  std::map<UInt, MEFLagrangeDG*>::iterator fi = classInstances.find(order);
  MEFLagrangeDG *mef;
  if (fi == classInstances.end()) {
    mef = new MEFLagrangeDG(order);
    classInstances[order] = mef;
  } else mef = fi->second;

  return *mef;
}

MasterElement<METraits<> > *MEFLagrangeDG::getME(const std::string &name, METraits<>) const {
  if (name == "SHELL" || name == "SHELL4" || name == "QUAD" || name == "QUAD4" || name == "QUAD_3D") {
    return MasterElementV<METraits<> >::instance(ShapeLagrangeQuadDG::instance(order));
  } else Throw() << "Hierar not implemented for topo:" << name;
}

// Mini
MEFMini *MEFMini::classInstance = NULL;

MEFMini::MEFMini() :
MEFamily(),
fname("Mini")
{
}

const MEFMini &MEFMini::instance() {
  MEFMini *mef;
  if (classInstance == NULL) {
    mef = new MEFMini();
    classInstance = mef;
  } else mef = classInstance;

  return *mef;
}

MasterElement<METraits<> > *MEFMini::getME(const std::string &name, METraits<>) const {
  if (name == "TRI" || name == "TRI3") {
    return MasterElementV<METraits<> >::instance(ShapeMiniTri::instance());
  } else Throw() << "Mini not implemented for topo:" << name;
}

// Stacked
std::map<std::string, MEFStacked*> MEFStacked::classInstances;

MEFStacked::MEFStacked(const std::string &_fname, const std::vector<MEFamily*> &stack) :
MEFamily(),
fname(_fname)
{
}

const MEFStacked &MEFStacked::instance(const std::vector<MEFamily*> &stack) {
  std::string _fname;
  for (UInt i = 0; i < stack.size(); ++i) 
    _fname += (stack[i]->name() + "_");

  std::map<std::string, MEFStacked*>::iterator fi = classInstances.find(_fname);

  MEFStacked *mef;
  if (fi == classInstances.end()) {

    mef = new MEFStacked(_fname, stack);
    classInstances[_fname] = mef;
  } else mef = fi->second;

  return *mef;
}

MasterElement<METraits<> > *MEFStacked::getME(const std::string &name, METraits<>) const {
  if (name == "SHELL" || name == "SHELL4" || name == "QUAD" || name == "QUAD4" || name == "QUAD_3D") {
    //return MasterElementV<METraits<> >::instance(ShapeLagrangeQuadDG::instance(order));
  Throw() << "Stacked not implemented for topo:" << name;
  } else Throw() << "Stacked not implemented for topo:" << name;
}

} // namespace 

