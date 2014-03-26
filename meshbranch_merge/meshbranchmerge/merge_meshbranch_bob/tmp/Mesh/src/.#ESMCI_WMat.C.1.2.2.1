#include <Mesh/include/ESMCI_WMat.h>
#include <Mesh/include/ESMCI_Attr.h>
#include <Mesh/include/ESMCI_MeshUtils.h>

namespace ESMCI {



/*-----------------------------------------------------------------*/
// WMat 
/*-----------------------------------------------------------------*/
WMat::WMat() :
weights(),
mig_sum(false)
{
}

WMat::WMat(const WMat &rhs)
{
}

WMat::~WMat() {
}

WMat &WMat::operator=(const WMat &rhs) 
{

  if (this == &rhs) return *this;

  weights = rhs.weights;
  
  return *this;
}

void WMat::InsertRow(const Entry &row, const std::vector<Entry> &cols, bool sum_flag) {
  Trace __trace("WMat::InsertRow(const Entry &row, const std::vector<Entry> &cols, bool sum_flag)");

  std::pair<Entry, std::vector<Entry> > ipair(row, cols);

  std::sort(ipair.second.begin(), ipair.second.end());
  
  std::pair<WeightMap::iterator, bool> wi =
    weights.insert(ipair);
    
  if (wi.second == false) {

    std::vector<Entry> &tcol = wi.first->second;

    if (sum_flag == false) {

      // Just verify that entries are the same
      ThrowRequire(tcol.size() == ipair.second.size());
      for (UInt i = 0; i < ipair.second.size(); i++) {
  
        if ((tcol[i].id != ipair.second[i].id) || (tcol[i].idx != ipair.second[i].idx)
               || (std::abs(tcol[i].value-ipair.second[i].value) > 1e-5)) 
        {
          Par::Out() << "Insert row.  Row exists, but is different!!" << std::endl;
          Par::Out() << "Row there:";
          for (UInt j = 0; j < tcol.size(); j++) {
            Par::Out() << tcol[j] << " ";
          }
          Par::Out() << std::endl << "New row:";
          for (UInt j = 0; j < ipair.second.size(); j++) {
            Par::Out() << ipair.second[j] << " ";
          }
        }
      } // i
    } else {
      // sum_flag == true
      std::copy(ipair.second.begin(), ipair.second.end(), std::back_inserter(tcol));

      condense_row(wi.first->second);

    }
  }
  
}

void WMat::Print(std::ostream &os) {
  
  WeightMap::iterator wi = weights.begin(), we = weights.end();
  
  for (; wi != we; ++wi) {
    os << "Row:" << wi->first;
    std::vector<Entry> &col = wi->second;
    
    double sum = 0.0;
    for (UInt i = 0; i < col.size(); i++) {
      
      os << col[i] << ", ";
      
      sum += col[i].value;
      
    }
    
    os << "SUM=" << sum << std::endl;
  }
  
}

WMat::WeightMap::const_iterator WMat::find(const Entry &ent) const {

  return weights.find(ent);

}

//void WMat::Migrate(CommRel &crel) {
void WMat::Migrate(Mesh &mesh) { 
  Trace __trace("WMat::Migrate(Mesh &mesh)");
  
  // Gather pole constraints
  {
    std::vector<UInt> mesh_dist, iw_dist;
    
    Context c; c.set(Attr::ACTIVE_ID);
    Attr a(MeshObj::NODE, c);
    getMeshGIDS(mesh, a, mesh_dist);
    GetRowGIDS(iw_dist);
    
    Migrator mig(mesh_dist.size(), mesh_dist.size() > 0 ? &mesh_dist[0] : NULL, 0,
        iw_dist.size(), iw_dist.size() > 0 ? &iw_dist[0] : NULL);
    
    mig.Migrate(*this);
    
//#define CHECK_WEIGHT_MIG
#ifdef CHECK_WEIGHT_MIG
// Check something: should have 1 to 1 coresp ids and entries
for (UInt i = 0; i < mesh_dist.size(); i++) {
  Entry ent(mesh_dist[i]);
  WeightMap::iterator wi = weights.lower_bound(ent);
  if (wi == weights.end() || wi->first.id != ent.id)
    Throw() << "Did not find id:" << ent.id << std::endl;
}
// And the other way
std::sort(mesh_dist.begin(), mesh_dist.end());
WeightMap::iterator wi = weights.begin(), we = weights.end();
for (; wi != we; ++wi) {
  std::vector<UInt>::iterator lb =
    std::lower_bound(mesh_dist.begin(), mesh_dist.end(), wi->first.id);
  
  if (lb == mesh_dist.end() || *lb != wi->first.id)
    Throw() << "Weight entry:" << wi->first.id << " not a mesh id!";
}
#endif
  
    
  }
  
  return;
  
}
  
void WMat::clear() {
  
  // Loop weightmap; swap each row out
  WeightMap::iterator wi = begin_row(), we = end_row();
  
  for (; wi != we; ++wi)
    std::vector<Entry>().swap(wi->second);
  
  WeightMap().swap(weights);
  
}  

struct entry_mult {
  entry_mult(double _mval) : mval(_mval) {}
  WMat::Entry operator()(const WMat::Entry &rhs) {
    return WMat::Entry(rhs.id, rhs.idx, rhs.value*mval);
  }
  double mval;
};

void WMat::AssimilateConstraints(const WMat &constraints) {
  Trace __trace("WMat::AssimilateConstraints(const WMat &constraints)");
  
  // Loop the current entries; see if any constraint rows need to be resolved;
  WeightMap::iterator wi = weights.begin(), we = weights.end();
  
  for (; wi != we; ++wi) {
    
    std::vector<Entry> &col = wi->second;
    
    // Loop constraints; find the entries
    WeightMap::const_iterator ci = constraints.weights.begin(), ce = constraints.weights.end();
    
    for (; ci != ce; ++ci) {
      
      const Entry &crow = ci->first;
      
      std::vector<Entry>::iterator lb = 
        std::lower_bound(col.begin(), col.end(), crow);
        
      // If we found an entry, condense;
      if (lb != col.end() && *lb == crow) {
        
        double val = lb->value;
        
        const std::vector<Entry> &ccol = ci->second;
        
        // Delete entry
        col.erase(lb);
        
        // Add replacements to end
        std::transform(ccol.begin(), ccol.end(), std::back_inserter(col), entry_mult(val));
        
        // Now sort
        std::sort(col.begin(), col.end());
        
        // And condense any duplicates
        std::vector<Entry>::iterator condi = col.begin(), condn, cond_del;

        
        while (condi != col.end()) {

          
          condn = condi; condn++;
          
          // Sum in result while entries are duplicate
          while (condn != col.end() && *condn == *condi) {
            
            condi->value += condn->value;
            
            ++condn;
          }
          
          // Move to next entry
          ++condi;

          // Condense the list if condn != condi (there were duplicaes)
          if (condn != condi) {
            cond_del = std::copy(condn, col.end(), condi);
            
            col.erase(cond_del, col.end());
          }
          
        }  // condi; condensation loop
        
      } // Found an entry
      
    } // for ci
    
  } // for wi
  
}

void WMat::Condense() {

  WeightMap::iterator wi = weights.begin(), we = weights.end();

  for (; wi != we; ++wi) {

    condense_row(wi->second);

  }

}

void WMat::condense_row(std::vector<Entry> &col) {

  // Now sort
  std::sort(col.begin(), col.end());
       
  // And condense any duplicates
  std::vector<Entry>::iterator condi = col.begin(), condip1, condn, cond_del;
       
/*
Par::Out() << "About to condense" << std::endl;
*/

  while (condi != col.end()) {

/*
Par::Out() << "condi=" << *condi << std::endl;
std::copy(col.begin(), col.end(), std::ostream_iterator<Entry>(Par::Out(), "\n"));
Par::Out() << ".." << std::endl;
*/
         
     condn = condi; condn++;
         
     // Sum in result while entries are duplicate
     while (condn != col.end() && *condn == *condi) {
           
       condi->value += condn->value;
         
       ++condn;
    }
         
    // Move to next entry
    condip1 = condi; ++condip1;

    // Condense the list if condn != condi (there were duplicaes)
    if (condn != condip1) {
       cond_del = std::copy(condn, col.end(), condip1);
         
       col.erase(cond_del, col.end());
    }

    // Move forward, finally
    ++condi;
/*
Par::Out() << "After erase" << std::endl;
std::copy(col.begin(), col.end(), std::ostream_iterator<Entry>(Par::Out(), "\n"));
Par::Out() << ".." << std::endl;
if (condi != col.end()) Par::Out() << "condi=" << *condi << std::endl;
*/
         
  }  // condi; condensation loop

}

void WMat::GatherToCol(WMat &rhs) {
  Trace __trace("WMat::GatherToCol(WMat &rhs)");
  
  // Gather rhs to col dist of this
  {
    std::vector<UInt> distd, dists;
    
    this->GetColGIDS(distd);
    rhs.GetRowGIDS(dists);
    
    Migrator mig(distd.size(), distd.size() > 0 ? &distd[0] : NULL, 0,
        dists.size(), dists.size() > 0 ? &dists[0] : NULL);
    
    mig.Migrate(rhs);
    
  }
}

void WMat::GetRowGIDS(std::vector<UInt> &gids) {
  Trace __trace("WMat::GetRowGIDS(std::vector<UInt> &gids)");
  
  gids.clear();
  
  WeightMap::iterator ri = weights.begin(), re = weights.end();
  
  for (; ri != re;) {
    
    gids.push_back(ri->first.id);
    
    UInt gid = ri->first.id;
    
    // Don't repeat a row:
    while (ri != re && ri->first.id == gid)
      ++ri;
    
  }
  
}

void WMat::RightMultiply(const WMat &B) {
  Trace __trace("WMat::RightMultiply(const WMat &B)");

  WeightMap::iterator wi = weights.begin(), we = weights.end();

  for (; wi != we; ++wi) {

    std::vector<Entry> &col = wi->second;
    std::vector<Entry> ncol;
 
    for (UInt c = 0; c < col.size(); ++c) {

      WeightMap::const_iterator bi =
        B.find(Entry(col[c]));

      if (bi == B.end_row()) {
        Throw() << "Could not find row:" << Entry(col[c]) << " in matrix B";
      }

      for (UInt cb = 0; cb < bi->second.size(); ++cb) {

        const Entry &b = bi->second[cb];

        ncol.push_back(Entry(b.id, b.idx, b.value*col[c].value));

      } // cb

    } // c

    wi->second.swap(ncol);
    condense_row(wi->second);

  } // wi

}

void WMat::GetColGIDS(std::vector<UInt> &gids) {
  Trace __trace("WMat::GetColGIDS(std::vector<UInt> &gids)");
  
  gids.clear();
  
  std::set<UInt> _gids; // use a set for efficieny

  WeightMap::iterator wi = weights.begin(), we = weights.end();
  
  for (; wi != we; ++wi) {
    
    std::vector<Entry> &col = wi->second;
    
    for (UInt i = 0; i < col.size(); i++) {
      
      _gids.insert(col[i].id);
      
    }
    
  }
  
  std::copy(_gids.begin(), _gids.end(), std::back_inserter(gids));
  
}

std::pair<int, int> WMat::count_matrix_entries() const {
  
  int n_s = 0;
  int max_idx = 0;
  
  WMat::WeightMap::const_iterator wi = begin_row(), we = end_row();
  
  for (; wi != we; ++wi) {
    n_s += wi->second.size();
    if (wi->first.idx > max_idx) max_idx = wi->first.idx;
  }
  
  return std::make_pair(n_s, max_idx);
    
}

void WMat::LocalTranspose() {
  
  WeightMap newweights;

  std::vector<Entry> col_adder(1);

  WeightMap::iterator wi = weights.begin(), we = weights.end();

  for (; wi != we; ++wi) {

    const Entry &row = wi->first;

    std::vector<Entry> &col = wi->second;

    for (UInt c = 0; c < col.size(); ++c) {

      Entry &cole = col[c];

      Entry nrow(cole);  nrow.value = 0.0;
      Entry ncol(row);  ncol.value = cole.value;

      col_adder[0] = ncol;

      std::pair<WeightMap::iterator, bool> addci =
        newweights.insert(std::make_pair(cole, col_adder));

      if (addci.second == false) {

         std::vector<Entry> &oncol = addci.first->second;
         oncol.push_back(ncol);

      }

    } // c


  } // wi

  WeightMap::iterator nwi = newweights.begin(), nwe = newweights.end();
  
  for (; nwi != nwe; ++nwi) {

    std::vector<Entry> &ncol = nwi->second;

    std::sort(ncol.begin(), ncol.end());

  }

  weights.swap(newweights);

}

// SparsePack/Unpack
SparsePack<WMat::WeightMap::value_type>::SparsePack(SparseMsg::buffer &b, WMat::WeightMap::value_type &t)
{
 // UInt res = 0;
  
  const WMat::Entry &row = t.first;
  
  std::vector<WMat::Entry> &col = t.second;

  // GID
  SparsePack<WMat::Entry::id_type>(b, row.id);
  
  // IDX
 SparsePack<WMat::Entry::idx_type>(b, row.idx);
  
  // Number of columns, this row/idx
  SparsePack<UInt>(b, col.size());
      
    for (UInt i = 0; i < col.size(); i++) {
      
    WMat::Entry &cent = col[i];
      
    // col id
    SparsePack<WMat::Entry::id_type>(b, cent.id);
    
    // col idx
    SparsePack<WMat::Entry::idx_type>(b, cent.idx);
    
    // Matrix value
    SparsePack<WMat::Entry::value_type>(b, cent.value);
      
    } // i
}

UInt SparsePack<WMat::WeightMap::value_type>::size(WMat::WeightMap::value_type &t)
{
  
  UInt res = 0;
  
  //const WMat::Entry &ent = t.first;
  
  std::vector<WMat::Entry> &col = t.second;

  // GID
  res += SparsePack<WMat::Entry::id_type>::size();
  
  // IDX
  res += SparsePack<WMat::Entry::idx_type>::size();
  
  // Number of columns, this row/idx
  res += SparsePack<UInt>::size();
      
    for (UInt i = 0; i < col.size(); i++) {
      
    // col id
    res += SparsePack<WMat::Entry::id_type>::size();
    
    // col idx
    res+= SparsePack<WMat::Entry::idx_type>::size();
    
    // Matrix value
    res += SparsePack<WMat::Entry::value_type>::size();
      
    } // i
    
    return res;
    
}

SparseUnpack<WMat::WeightMap::value_type>::SparseUnpack(SparseMsg::buffer &b, WMat::WeightMap::value_type &t)
{
  
  WMat::Entry &row = const_cast<WMat::Entry&>(t.first);
  
  // GID
  SparseUnpack<WMat::Entry::id_type>(b, row.id);
  
  // Idx
  SparseUnpack<WMat::Entry::idx_type>(b, row.idx);
  
  // ncols
  UInt ncols;
  SparseUnpack<UInt>(b, ncols);
  
  std::vector<WMat::Entry> &col = t.second;
  
  col.clear(); col.reserve(ncols);
  
  for (UInt i = 0; i < ncols; i++) {
    
    WMat::Entry cent;
    
    // Col id
    SparseUnpack<WMat::Entry::id_type>(b, cent.id);
    
    // col idx
    SparseUnpack<WMat::Entry::idx_type>(b, cent.idx);
    
    // value
    SparseUnpack<WMat::Entry::value_type>(b, cent.value);
    
    col.push_back(cent);
    
  } // i
  
}

std::ostream &operator <<(std::ostream &os, const WMat::Entry &ent) {
  os << "{id=" << ent.id << ", idx:" << (int) ent.idx << ", " << ent.value << "}";
  return os;
}

} // namespace
