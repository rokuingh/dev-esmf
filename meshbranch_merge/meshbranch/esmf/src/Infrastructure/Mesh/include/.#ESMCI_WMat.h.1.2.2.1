#ifndef ESMCI_WMat_h
#define ESMCI_WMat_h

#include <Mesh/include/ESMCI_Migrator.h>

#include <ostream>

namespace ESMCI {

class CommRel;
class MeshObj;

class Mesh;
class Geom;

/**
 * A very non-efficient matrix for storing weights, constraints, etc...
 * The class can redistribute itself using the migrator class.
 */
class WMat {

public:

  /*
   * Matrix entry object.  Entries are not linearized at this
   * point (that is delayed).  Instead, they are indexed by object id
   * and index on object.
   */
  struct Entry {
    Entry() : id(0), idx(0), value(0.0) {}
    Entry(long _id, char _idx = 0, double _value = 0.0) :
      id(_id), idx(_idx), value(_value) {}
    
    Entry(const Entry &rhs) :
     id(rhs.id), idx(rhs.idx), value(rhs.value)
    {
    }
    
    Entry &operator=(const Entry &rhs) {
      if (this == &rhs) return *this;
      id = rhs.id;
      idx = rhs.idx;
      value = rhs.value;
      return *this;
    }
    
    typedef UInt id_type;
    typedef char idx_type;
    typedef double value_type;
    
    id_type id;  // MeshObj id
    idx_type idx; // field index
    value_type value; // weight
    
    bool operator<(const Entry &rhs) const {
      if (id != rhs.id) return id < rhs.id;
      return idx < rhs.idx;
    }
    
    // Equality does not consider value
    bool operator==(const Entry &rhs) {
      return (id == rhs.id && idx == rhs.idx);
    }
    
  };  
  
  WMat();

  virtual ~WMat();
  
  WMat(const WMat &);
  
  WMat &operator=(const WMat &);
  
    
  /**
   * Insert a matrix row.  If sum_flag = false, then values are not summed and
   * it is an error if the row already exists and is not identical.
   * If sum_flag = true, then the row is summed into what already exists.
   */
  void InsertRow(const Entry &row, const std::vector<Entry> &cols, bool sum_flag = false);
  
  void GetRowGIDS(std::vector<UInt> &gids);
  
  void GetColGIDS(std::vector<UInt> &gids);
  
  void Print(std::ostream &);
  
  /*
   * Migrate the matrix to the row decomposition given by
   * mesh.
   */
  void Migrate(Mesh &mesh);
  
  // Return the number of rows that use this id
  UInt NumRows(long id) const;
  
  void clear();
  
  /*
   * Gather the right hand side matrix rows to the column space of this
   * weightset.
   */
  void GatherToCol(WMat &rhs);

  /**
   * Multiply by B on the right.  
   * *this = (*this)*B
   */
  void RightMultiply(const WMat &B);

  /*
   * Removes the columns referencing the constraint row entries.  
   * Converts current column references to a constrained object into
   * a reference to non-constrained objects by assimilating the constrained
   * objects sensitivities.
   */
  void AssimilateConstraints(const WMat &constraints);

  /**
   * Transpose the matrix, but don't worry about resolving any global
   * entries.
   */
  void LocalTranspose();

  /**
   * Loop rows, sort.  If there are duplicates, sum values together
   */
  void Condense();

  // Sort, remove duplicates by summing
  static void condense_row(std::vector<Entry> &col_map);
  
  typedef std::map<Entry, std::vector<Entry> > WeightMap;
  
  WeightMap::iterator begin_row() { return weights.begin(); }
  WeightMap::iterator end_row() { return weights.end(); }
  WeightMap::const_iterator begin_row() const { return weights.begin(); }
  WeightMap::const_iterator end_row() const { return weights.end(); }
  
  void InsertRow(WeightMap::value_type &row, bool sum_flag = false) {
    InsertRow(row.first, row.second, sum_flag);
  }

  WeightMap::const_iterator find(const Entry &ent) const;

  std::pair<int, int> count_matrix_entries() const;

  void SetMigSum(bool _val) { mig_sum = _val; }

  bool MigSum() const { return mig_sum; }

  WeightMap weights;


  // If true, then migrate sums, else coincident rows must be identical
  bool mig_sum;

};

// Migration Traits for WMat

template <>
class SparsePack<WMat::WeightMap::value_type> {
public:
  SparsePack(SparseMsg::buffer &b, WMat::WeightMap::value_type &t);
  static UInt size(WMat::WeightMap::value_type &t);
};

template <>
class SparseUnpack<WMat::WeightMap::value_type> {
public:
  SparseUnpack(SparseMsg::buffer &b, WMat::WeightMap::value_type &t);

private:
};


template <>
struct MigTraits<WMat> {
  
  typedef WMat::WeightMap::iterator element_iterator;

  typedef WMat::WeightMap::value_type element_type;
  
  typedef SparsePack<element_type> element_pack;
  
  static UInt element_pack_size(element_type &t) { return element_pack::size(t); }
  
  typedef SparseUnpack<element_type> element_unpack;
  
  static UInt get_id(element_type &t) { return t.first.id; }
    
  static element_iterator element_begin(WMat &t) { return t.begin_row(); }
  
  static element_iterator element_end(WMat &t) { return t.end_row(); }
  
  static void insert_element(WMat & t, UInt , element_type &el) { t.InsertRow(el, t.MigSum()); }
  
  static void resize_object(WMat &, UInt) {}
  
  static void clear_object(WMat &t) { t.clear(); }
  
};
 
std::ostream &operator <<(std::ostream &os, const WMat::Entry &ent);

} // namespace

#endif
