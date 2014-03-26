#ifndef ESMCI_MEFamily_h
#define ESMCI_MEFamily_h

#include <Mesh/include/ESMCI_MasterElement.h>

#include <Mesh/include/ESMCI_Quadrature.h>

#include <map>
#include <string>

namespace ESMCI {


/**
 * The basic role of this class is to provide for master elements
 * and mesh heterogeneity to interact suitably.  It also provides
 * dimension independence for a master element.
 *
 * This class provides a mesh topology (QUAD, HEX, TRI) to master
 * element mapping.  Thus we can register a field that lives over
 * say, a mesh of quads and tri's, and treat the field as a single
 * entity, rather than two distinct fields.  
 * Also, we can register an ME type that is dimension independant,
 * i.e. 10th order lagrange.  Provided the master element is
 * implemented, the MEFamily will hand back the correct element, and
 * the users code will not have to switch on this element type.
 */
class MEFamily {
public:
MEFamily() {}
virtual ~MEFamily() {}
// Get standard specific trait versions
virtual MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const = 0;

template<typename METRAITS>
MasterElement<METRAITS> *getME(const std::string &toponame, METRAITS) const {
  return getME(toponame, METraits<>())->operator()(METRAITS());
}

// True if the dofs live strictly on the nodes. e.g. lagrangian
virtual bool is_nodal() const = 0;

// Default implementation using me for order, topo for type.
virtual const intgRule *GetIntg(const std::string &toponame) const;

// true if dofs live strictly on element. e.g. discontinous galerkin
virtual bool is_elemental() const = 0;

virtual const std::string &name() const = 0;
private:
MEFamily(const MEFamily&);
};

// A default MEfamily
class MEFamilyStd : public MEFamily {
MEFamilyStd();
static MEFamilyStd *classInstance;
public:
MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
static const MEFamilyStd &instance();
bool is_nodal() const { return true;} // lagrange
bool is_elemental() const { return false;}


const std::string &name() const { return fname;}
private:
MEFamilyStd(const MEFamilyStd&);
const std::string fname;
};

// A Low order default
class MEFamilyLow : public MEFamily {
MEFamilyLow();
static MEFamilyLow *classInstance;
public:
bool is_nodal() const { return true;} // lagrange
bool is_elemental() const { return false;} 
static const MEFamilyLow &instance();

MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
const std::string &name() const { return fname;}
private:
MEFamilyLow(const MEFamilyLow&);
const std::string fname;

};

// A non-descriptive element type me.  Does not give any shape functions, etc, 
// but lives only on the element and can be of whatever size/dim.
class MEFamilyDG : public MEFamily {
MEFamilyDG(UInt ndof);
static std::map<UInt,MEFamilyDG*> classInstances;
public:
bool is_nodal() const { return false;} 
bool is_elemental() const { return true;} 
static const MEFamilyDG &instance(UInt ndof);

MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
const std::string &name() const { return fname;}
private:
MEFamilyDG(const MEFamilyDG&);
const std::string fname;
UInt ndof;

};

// Hierarchical
class MEFamilyHier : public MEFamily {
MEFamilyHier(UInt order);
static std::map<UInt, MEFamilyHier *> classInstances;
public:
bool is_nodal() const { return false;} 
bool is_elemental() const { return false;} 
static const MEFamilyHier &instance(UInt order);

MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
const std::string &name() const { return fname;}
private:
MEFamilyHier(const MEFamilyHier&);
const std::string fname;
UInt order;

};

// High order lagrange
class MEFLagrange : public MEFamily {
MEFLagrange(UInt order);
static std::map<UInt, MEFLagrange*> classInstances;
public:
bool is_nodal() const { return false;} 
bool is_elemental() const { return false;} 
static const MEFLagrange &instance(UInt order);

MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
const std::string &name() const { return fname;}
private:
MEFLagrange(const MEFLagrange&);
const std::string fname;
UInt order;

};

// High order lagrange, DG
class MEFLagrangeDG : public MEFamily {
MEFLagrangeDG(UInt order);
static std::map<UInt, MEFLagrangeDG*> classInstances;
public:
bool is_nodal() const { return false;} 
bool is_elemental() const { return true;} 
static const MEFLagrangeDG &instance(UInt order);

MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
const std::string &name() const { return fname;}
private:
MEFLagrangeDG(const MEFLagrangeDG&);
const std::string fname;
UInt order;
};

// Mini element
class MEFMini : public MEFamily {
MEFMini();
static MEFMini *classInstance;
public:
bool is_nodal() const { return false;} 
bool is_elemental() const { return false;} 
static const MEFMini &instance();

MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
const std::string &name() const { return fname;}
private:
MEFMini(const MEFMini&);
const std::string fname;

};

// Stacked ME.  Composes a master element from a sequence of master element's
class MEFStacked : public MEFamily {
MEFStacked(const std::string &_fname, const std::vector<MEFamily*> &);
static std::map<std::string, MEFStacked*> classInstances;
public:
bool is_nodal() const { return false;} 
bool is_elemental() const { return false;} 
static const MEFStacked &instance(const std::vector<MEFamily*> &stack);

MasterElement<METraits<> > *getME(const std::string &toponame, METraits<>) const;
const std::string &name() const { return fname;}
private:
MEFStacked(const MEFStacked&);
const std::string fname;

};

} // namespace

#endif
