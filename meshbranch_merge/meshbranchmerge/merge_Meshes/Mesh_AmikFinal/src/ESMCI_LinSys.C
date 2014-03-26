#include <Mesh/include/ESMCI_LinSys.h>
#include <Mesh/include/ESMCI_Mesh.h>
#include <Mesh/include/ESMCI_MeshObjConn.h>
#include <Mesh/include/ESMCI_MeshUtils.h>
#include <Mesh/include/ESMCI_GlobalIds.h>
#include <Mesh/include/ESMCI_ParEnv.h>
#include <Mesh/include/ESMCI_SparseMsg.h>
#include <Mesh/include/ESMCI_Exception.h>
#include <Mesh/include/ESMCI_ShapeFunc.h>
#include <Mesh/include/ESMCI_Kernel.h>
#include <Mesh/include/ESMCI_RefineTopo.h>
#include <Mesh/include/ESMCI_HAdapt.h>
#include <Mesh/include/ESMCI_WMat.h>
#include <Mesh/include/ESMCI_DDir.h>

#ifdef ESMCI_TRILINOS
#include <Epetra_MpiComm.h>
#include <Epetra_FECrsGraph.h>
#include <AztecOO.h>
#define HAVE_ML_EPETRA
#include "ml_include.h"
#include <ml_epetra_utils.h>
#include "ml_MultiLevelPreconditioner.h"
#include "ml_MultiLevelOperator.h"
#endif

namespace ESMCI {

LinSys::LinSys(Mesh &_mesh, UInt nfields, MEField<> **fields, const LinSysParam &_lsp) :
 Fields(),
 mesh(_mesh),
 elem_dofs(),
 field_on(),
 nelem_dofs(0),
#ifdef ESMCI_TRILINOS
 map(NULL),
 umap(NULL),
 matrix(NULL),
 x(NULL),
 b(NULL),
#endif
has_neg_dofs(false),
lsp(_lsp)
{
  for (UInt i = 0; i < nfields; i++) {

    // For the moment, only allow element fields
    if (fields[i]->ObjType() != MeshObj::ELEMENT) 
      Throw() << "Lin Sys currently only supports element fields";
 
    Fields.push_back(fields[i]);
    
    // Clone the field to store the dof numbering into the linalg vector.
    DFields.push_back(mesh.RegisterField("_dof" + fields[i]->name(),
                          fields[i]->GetMEFamily(),
                          fields[i]->GetType(),
                          fields[i]->GetContext(),
                          fields[i]->dim(),
                          false, // no output 
                          false, // no interp 
                          _fieldType<DField_type>::instance()
        ));
  }

}

void LinSys::delete_epetra_objs() {
#ifdef ESMCI_TRILINOS
  if (map) {
    delete map;
    map = NULL;
  }
  if (umap) {
    delete umap;
    umap = NULL;
  }
  if (matrix) {
    delete matrix;
    matrix = NULL;
  }
  if (x) {
    delete x; x = NULL;
  }
  if (b) {
    delete b; b = NULL;
  }
#endif
}

void LinSys::clear() {

  delete_epetra_objs();
  
}

UInt LinSys::Setup(Kernel &ker) {
  
  UInt ndofs = 0;
  
  UInt nfields = Fields.size();

  field_on.resize(nfields);
  
  for (UInt f = 0; f < nfields; f++) {
    if ((ker.type() == Fields[f]->GetType())
          && (ker.GetContext().any(Fields[f]->GetContext()))) {
      ndofs += GetME(*Fields[f], ker).num_functions()*Fields[f]->dim();

      field_on[f] = 1;
    } else field_on[f] = 0;
  }  

  nelem_dofs = ndofs;

  elem_dofs.resize(nelem_dofs);
  elem_dof_signs.resize(nelem_dofs, 1);
  
  return ndofs;
}

void LinSys::ReInit(MeshObj &elem) {

  UInt nfields = Fields.size();
  
  UInt cur_loc = 0;

  has_neg_dofs = false;
  for (UInt f = 0; f < nfields; f++) {
    if (field_on[f]) {

      UInt ndofs = GetME(*Fields[f], elem).num_functions()*Fields[f]->dim();

      const MasterElement<> &me = static_cast<const MasterElement<>&>(GetME(*DFields[f], elem));
//Par::Out() << "Gathering" << std::endl;
      GatherElemData<METraits<>,MEField<>,DField_type>(me, static_cast<MEField<>&>(*DFields[f]), elem, &elem_dofs[cur_loc]);

      // Some elements may negate the dofs, so adjust this
      if (me.orientation() == ShapeFunc::ME_SIGN_ORIENTED) {
        for (UInt i = 0; i < ndofs; i++) {
          if (elem_dofs[cur_loc+i] >= 0) {
            elem_dof_signs[cur_loc+i] = 1;
            //elem_dofs[cur_loc+i] = std::abs(elem_dofs[cur_loc+i]);
          } else {
            has_neg_dofs = true;
            elem_dof_signs[cur_loc+i] = -1;
            elem_dofs[cur_loc+i] = -1*elem_dofs[cur_loc+i];
          }
        }
      }

      cur_loc += ndofs;

    } // field on
  }  

  

/*
Par::Out() << "elem dofs, signs:" << std::endl;
std::copy(elem_dofs.begin(), elem_dofs.end(), std::ostream_iterator<DField_type>(Par::Out(), " "));
Par::Out() << std::endl;
std::copy(elem_dof_signs.begin(), elem_dof_signs.end(), std::ostream_iterator<DField_type>(Par::Out(), " "));
Par::Out() << std::endl;
*/
}

void LinSys::BeginAssembly() {

#ifdef ESMCI_TRILINOS
 matrix->PutScalar(0); //matrix->FillComplete();
 b->PutScalar(0);
#endif

}

void LinSys::GlobalAssemble() {
#ifdef ESMCI_TRILINOS

  //matrix->GlobalAssemble(*umap, *umap);
  matrix->GlobalAssemble(false);

  // Sum rhs together
  b->GlobalAssemble();
#endif

}

void LinSys::EndAssembly() {
#ifdef ESMCI_TRILINOS

  bool iglobal = matrix->IndicesAreGlobal();

  //matrix->GlobalAssemble(*umap, *umap);
  matrix->FillComplete();
  matrix->OptimizeStorage();

  // First time completing.  Fill out column map local idx
  if (iglobal) {

    global2local_col.clear();

    const Epetra_Map &colmap = matrix->ColMap();

    int ncolm = colmap.NumMyElements();

    my_column.resize(ncolm);

    const int *colel = colmap.MyGlobalElements();

    for (UInt i = 0; i < ncolm; ++i) {
      global2local_col[colel[i]] = i;
      my_column[i] = colel[i];
    }

  }

  // Sum rhs together
#endif

}

void LinSys::ApplyHNodeConstraints(HAdapt &hadapt) {
  Trace __trace("LinSys::ApplyHNodeConstraints(HAdapt &hadapt)");
#ifdef ESMCI_TRILINOS

  ThrowRequire(&hadapt.GetMesh() == &mesh);

  // Map of element, constrained side
  std::vector<std::pair<MeshObj*, int> > celems;

  hadapt.ConstrainedElems(celems);

  WMat constraints;

  // Okay, now we have the constrained objects, so we loop through them.
  // Gather the dofs for the parent, and then for the children
  for (UInt e = 0; e < celems.size(); ++e) {
//#define DBG_HNODE

#ifdef DBG_HNODE
Par::Out() << "constrained element:(" << celems[e].first->get_id() << ", " << celems[e].second << ")" << std::endl;
//Par::Out() << *celems[e].first;
#endif

    MeshObj &pelem = *celems[e].first;
    UInt side_num = celems[e].second;
    const MeshObjTopo *ptopo = GetMeshObjTopo(pelem);

    const MeshObjTopo *stopo = ptopo->side_topo(side_num);

    // Loop the fields
    for (UInt f = 0; f < Fields.size(); f++) {

      MEField<> &mf = static_cast<MEField<>&>(*DFields[f]);

      // Is the field on the object?
      if (!GetMeshObjContext(pelem).any(mf.GetContext())) continue;

      const MEFamily &mef = mf.GetMEFamily();

      MasterElement<> &pme = *mef.getME(ptopo->name, METraits<>());

      MasterElement<> &sme = *pme.side_element(side_num);

#ifdef DBG_HNODE
Par::Out() << "\tsme=" << sme.name << std::endl;
#endif

      std::vector<DField_type> pdofs(sme.num_functions()*mf.dim());

      // Since we are going from parent to child side, we must
      // make sure we gather according to a fixed orientation.  The
      // child element's side is not guaranteed to orient correctly
      // to the parent's side.  We fix this by choosing an orientation
      // at the start and finding the orientation of the element wrt 
      // our chosen view.  If there is a side present, we gather 
      // in accord to that side, otherwise we choose the side nodes.
      UInt protation;
      bool ppolarity;

      bool has_side = false;
      MeshObj *sobj = 0;
      {
        MeshObjRelationList::iterator si = 
           MeshObjConn::find_relation(pelem, mesh.side_type(), side_num, MeshObj::USES);
  
        if (si != pelem.Relations.end()) {
          has_side = true;
          protation = si->rotation;
          ppolarity = si->polarity;
          sobj = si->obj;
        } else {
          // choose the parent's point of view
          protation = 0;
          ppolarity = true;
        }
        
      }

      // Gather dofs to parent's
      GatherSideData1<METraits<>,MEField<>,DField_type>(sme, mf, pelem, side_num, ppolarity, protation, &pdofs[0]);

#ifdef DBG_HNODE
std::copy(pdofs.begin(), pdofs.end(), std::ostream_iterator<DField_type>(Par::Out(), " "));
Par::Out() << std::endl;
#endif

      // Now loop the children, gathering dofs.  For the moment assume a homogeneous 
      // topology.
      const RefineTopo *rtopo = GetHomoRefineTopo(stopo);
      ThrowRequire(rtopo);

      // Get the prolongation matrices.  There will define the constraints. 
      const RefDual *sprolong = RefDual::instance(rtopo, &sme);

      for (UInt c = 0; c < rtopo->NumChild(); ++c) {

         const double *pmatrix = sprolong->prolongation_matrix(c);

         // Now gather the child dofs.  As noted above, we need these 
         // oriented in the refinement topology of the parent dofs.
         std::vector<DField_type> cdofs(sme.num_functions()*mf.dim());

         // If a side exists, then we can use its orientation
         int crotation = 0;
         int cpolarity = true;
         MeshObj *suelem = 0;
         int cordinal = 0;
         if (has_side) {
           MeshObjRelationList::iterator sci =
             MeshObjConn::find_relation(*sobj, sobj->get_type(), c, MeshObj::CHILD);

           ThrowRequire(sci != sobj->Relations.end());

           // Now get a 'uses' element
           MeshObjRelationList::iterator cei = 
              MeshObjConn::find_relation(*sci->obj, MeshObj::ELEMENT);

           bool uses_elem_found = false;
           for (; cei != sci->obj->Relations.end() &&
                  cei->obj->get_type() == MeshObj::ELEMENT &&
                  !(uses_elem_found = (cei->type == MeshObj::USED_BY)); ++cei); 
           ThrowRequire(uses_elem_found);

           crotation = cei->rotation;
           cpolarity = cei->polarity;
           suelem = cei->obj;
           cordinal = cei->ordinal;

         } else {
           // If you though that was hard, try this.  We must get the child side nodes, 
           // find a uses element, and take the orientation.

           std::vector<MeshObj*> side_child_node;

           const int *side_nodes = ptopo->get_side_nodes(side_num);
           const UInt *side_child_nodes = rtopo->ChildNode(c);

           for (UInt cn = 0; cn < rtopo->ChildTopo(c)->num_nodes; ++cn) {

             side_child_node.push_back(
                 pelem.Relations[side_nodes[side_child_nodes[cn]]].obj);

           } // cn

           // Now get the child element.  There should be only one match
           std::vector<MeshObj*> celem;
           MeshObjConn::common_objs(side_child_node.begin(),
              side_child_node.end(), MeshObj::USED_BY, MeshObj::ELEMENT, celem);

           if (celem.size() != 1) {
              Par::Out() << "celem size:" << celem.size() << std::endl;
              Par::Out() << "child face nodes:";
              for (UInt j = 0; j < side_child_node.size(); ++j)
                Par::Out() << *side_child_node[j];
              Par::Out() << std::endl;
              for (UInt i = 0; i < celem.size(); ++i) Par::Out() << *celem[i];
              Throw() << "Error celem size wrong!!";
           }

           // And, finally, get the polarity info
           if (mesh.side_type() == MeshObj::FACE) {

             MeshObjConn::face_info(side_child_node.begin(),
               side_child_node.end(), celem.begin(), celem.end(),
               &cordinal, &cpolarity, &crotation);

           } else {

             MeshObjConn::edge_info(side_child_node.begin(),
               side_child_node.end(), celem.begin(), celem.end(),
               &cordinal, &cpolarity);

           }

           suelem = celem[0];

         }

         // At this point, we have the child element with the correct orientation
         // to the side, so we can gather the child dofs.
         GatherSideData1<METraits<>,MEField<>,DField_type>(sme, mf, *suelem,
                     cordinal, (cpolarity==1), crotation, &cdofs[0]);

#ifdef DBG_HNODE
Par::Out() << "\tchild:" << c << ", dofs:";
for (UInt df = 0; df < cdofs.size(); ++df)
  Par::Out() << cdofs[df] << " ";
Par::Out() << std::endl;
#endif

         UInt snfunc = sme.num_functions();

         ThrowRequire(Fields.size() == 1);
                                      // TODO: generalize to field of dim > 1.  Also to nfield >1
                                      // This shouldn't be hard.  I should probably write a
                                      // function in lin sys that maps i ->(field,nfunc,fdim)
                                      // and (field,nfunc,fdium)->i
                                      // This way if I change things under the hood, later,
                                      // I won't have to rewrite a bunch of code.
  
         UInt mfdim = mf.dim();
         for (UInt nf = 0; nf < snfunc; ++nf) {
           for (UInt fd = 0; fd < mfdim; ++fd) {

           UInt cd = nf*mfdim+fd;

           // If child dof is also a parent dof, then
           // ignore the constraint.
           if (std::find(pdofs.begin(), pdofs.end(), cdofs[cd]) != pdofs.end()) continue;


           WMat::Entry row(cdofs[cd]);

           std::vector<WMat::Entry> col;

#ifdef DBG_HNODE
Par::Out() << "cdof:" << cdofs[cd] << ":";
#endif
          
           for (UInt pd = 0; pd < snfunc; ++pd) {

             double mval = pmatrix[nf*snfunc+pd];

             if (std::abs(mval) > 1e-7)
               col.push_back(WMat::Entry(pdofs[pd*mfdim+fd], 0, mval));

#ifdef DBG_HNODE
Par::Out() << "(" << pdofs[pd*mfdim+fd] << ", " << mval << ") ";
#endif
           }
#ifdef DBG_HNODE
Par::Out() << std::endl;
#endif

           constraints.InsertRow(row, col);

           } // fd
         } // nf

       } // c

    } // f  

  } // e


  // Migrate the constraints to the 'onwed decomposition' so that we may insert
  // the constraint rows in the matrix.
  DDir<> ddir;
  std::vector<UInt> oid, lid;

  // TODO:Flaw.  Unfortunately, have to copy id's over to UInt.
  {
    std::copy(my_owned.begin(), my_owned.end(), std::back_inserter(oid));
    lid.resize(oid.size(),1);

    UInt osize = oid.size();
  
    ddir.Create(osize, osize > 0 ? &oid[0] : NULL, osize > 0 ? &lid[0] : 0);

    std::vector<UInt> src_ids;
    constraints.GetRowGIDS(src_ids);
    UInt dsize = src_ids.size();

    Migrator mig(ddir, dsize, dsize > 0 ? &src_ids[0] : 0);

    mig.Migrate(constraints);

  }

#ifdef DBG_HNODE
Par::Out() << "Constraint Matrix" << std::endl;
constraints.Print(Par::Out());
#endif

  /*---------------------------------------------------------------------------*/
  // Now create the owned, constrained matrix so that we can ship these values
  // over to the non-constrained values that need them.
  // Also zero out the matrix/rhs (except a 1 on diagonal).
  /*---------------------------------------------------------------------------*/

  WMat crows, crhs;

  UInt nfields = Fields.size();

  KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end();

  for (; ki != ke; ++ki) {

    Kernel &ker = *ki;

    if (!ker.is_active() || !ker.is_constrained() || !ker.is_owned()) continue;

    const Context &ctxt = ker.GetContext();

    Kernel::obj_iterator oi = ker.obj_begin(), oe = ker.obj_end();

    bool on_kernel = false;
    std::vector<int> field_on(nfields,0);
  
    for (UInt f = 0; f < nfields; f++) {
      if (Fields[f]->Getfield()->OnAttr(ker.GetAttr(), false)) {
        field_on[f] = 1;
        on_kernel = true;
      }
    }

    if (!on_kernel) continue;
 
 
    for (; oi != oe; ++oi) {

      MeshObj &obj = *oi;

#ifdef DBG_HNODE
Par::Out() << "Checking obj:" << MeshObjTypeString(obj.get_type()) << " " << obj.get_id() << std::endl;
#endif

      for (UInt f = 0; f < nfields; ++f) {

        if (!field_on[f]) continue;

        MEField<> &df = *DFields[f];

        _field &dfll = *df.Getfield();

        UInt fdim = dfll.dim(obj);

        DField_type *data = dfll.data(obj);

#ifdef DBG_HNODE
Par::Out() << fdim << " dofs on obj:" << std::endl;
#endif

        for (UInt d = 0; d < fdim; ++d) {

          DField_type dof = data[d];
#ifdef DBG_HNODE
Par::Out() << "\t dof:" << dof << std::endl;
#endif

          double *old_row;
          int *old_indices;
          int nentries = 0;

          // Extract the row view, add to crows matrix
         int ret = 0;
         UInt lidx = 0;
         bool iglobal = matrix->IndicesAreGlobal();
         if (iglobal) {
           ret = matrix->ExtractGlobalRowView(dof, nentries, old_row, old_indices);
         } else {

           std::map<int,int>::iterator li = global2local.find(dof);
           ThrowRequire(li != global2local.end());
           lidx = li->second;

           ret = matrix->ExtractMyRowView(lidx, nentries, old_row, old_indices);
         }

         //if (ret != 0 && nentries == 0) Throw() << "Bad row extract, dof=" << dof << " nentries=" << nentries << ", obj=" << obj;
         if (ret != 0) Throw() << "Bad row extract, dof=" << dof << " nentries=" << nentries << "ret=" << ret << ", obj=" << obj;

          WMat::Entry row(dof);
          std::vector<WMat::Entry> col;

          // And now, create the matrix while zero'ing out the row, save a 1.0 on the diagonal
          for (UInt n = 0; n < nentries; ++n) {

            int gidx = iglobal ? old_indices[n] : my_column[old_indices[n]];

            col.push_back(WMat::Entry(gidx, 0, old_row[n]));

            if (gidx == dof) { old_row[n] = 0.0; } else { old_row[n] = 0; }

          } // n
//Par::Out() << "updating dof:" << dof << std::endl;
 

          // Now update the matrix row with the constraint
          WMat::WeightMap::const_iterator cri =
            constraints.find(row);
          if (cri == constraints.end_row())
            Throw() << "Could not find entry:" << row << " in constraints!";

          // Use insert global values in case value is not present
          UInt ncol = cri->second.size();
          std::vector<int> cidx(ncol+1);
          std::vector<double> cvals(ncol+1);
          for (UInt l = 0; l < ncol; ++l) {
            std::map<int,int>::iterator li;
            if (!iglobal) {
              li = global2local_col.find(cri->second[l].id);
              if (li == global2local_col.end()) Throw() << "could not find idx:" << cri->second[l].id;
            }
            cidx[l] = iglobal ? cri->second[l].id : li->second;
            cvals[l] = cri->second[l].value;
          }

          cidx[ncol] = iglobal ? dof : lidx; cvals[ncol] = -1.0; // The diagonal

          int iret = 0;
          if (matrix->IndicesAreGlobal()) {
            matrix->InsertGlobalValues(dof, ncol+1, &cvals[0], &cidx[0]);
          } else
            iret = matrix->ReplaceMyValues(lidx, ncol+1, &cvals[0], &cidx[0]);

          if (iret != 0) 
            Throw() << "Error insert/replace, iret=" << iret;

          // Insert the matrix row to be shipped.
          crows.InsertRow(row, col);

          // Save the rhs val and zero
          std::vector<int>::iterator lb =
            std::lower_bound(my_owned.begin(), my_owned.end(), dof);

          if (lb == my_owned.end() || *lb != dof) Throw() << "Could not get rhs:" << dof;

          UInt off = std::distance(my_owned.begin(), lb);

          double rhs_val = (*b)[0][off];
          (*b)[0][off]  = 0.0;

          // Put the rhs in a matrix to be sent with the constraints
          {
            WMat::Entry rhsrow(dof);
            std::vector<WMat::Entry> rhscol(cri->second);

            for (UInt l = 0; l < rhscol.size(); l++) 
              rhscol[l].value *= rhs_val;

            crhs.InsertRow(rhsrow, rhscol);

          }

        } // d

      } //f

    } // oi

  } // ki



  // Transpose the constraints so they may be shipped to the column space.
  constraints.LocalTranspose();
  crhs.LocalTranspose();

#ifdef DBG_HNODE
Par::Out() << "Constraint Matrix Transpose" << std::endl;
constraints.Print(Par::Out());
#endif

#ifdef DBG_HNODE
Par::Out() << "crows:" << std::endl;
crows.Print(Par::Out());
#endif

  // Form the contributions for the non-constrained dofs
  constraints.RightMultiply(crows);

  crows.clear();

  // Now migrate everyone to the column distribution:
  //  * constraints
  //  * crhs
  {
    UInt osize = oid.size();

    // Use a summation policy
    constraints.SetMigSum(true);
  
    std::vector<UInt> src_ids;
    constraints.GetRowGIDS(src_ids);
    UInt dsize = src_ids.size();

    Migrator mig(ddir, dsize, dsize > 0 ? &src_ids[0] : 0);

    mig.Migrate(constraints);
 }

 {
    UInt osize = oid.size();

    // Use a summation policy
    crhs.SetMigSum(true);
  
    std::vector<UInt> src_ids;
    crhs.GetRowGIDS(src_ids);
    UInt dsize = src_ids.size();

    Migrator mig(ddir, dsize, dsize > 0 ? &src_ids[0] : 0);

    mig.Migrate(crhs);
 }

#ifdef DBG_HNODE
Par::Out() << "After mult, migrate Constrained:" << std::endl;
constraints.Print(Par::Out());
#endif

#ifdef DBG_HNODE
Par::Out() << "rhs contribs:" << std::endl;
crhs.Print(Par::Out());
#endif

  // Sum in the rhs contribs
  {
    WMat::WeightMap::const_iterator ri = crhs.begin_row(), re = crhs.end_row();

    for (; ri != re; ++ri) {

      UInt sdof = ri->first.id;

      UInt nent = ri->second.size();

      double sval = 0.0;
      for (UInt j = 0; j < ri->second.size(); ++j) {
        sval += ri->second[j].value;
      } // j

      int ret = b->SumIntoGlobalValue(sdof, 0, sval);
#ifdef DBG_HNODE
Par::Out() << "Summing " << sval << " into " << sdof << std::endl;
#endif
      ThrowRequire(!ret);

    } // ri

  }

  // Sum in the matrix contributions
  {

    WMat::WeightMap::iterator wi = constraints.begin_row(), we = constraints.end_row();

    for (; wi != we; ++wi) {

      int dof = wi->first.id;  
  
      double *old_row;
      int *old_indices;
      int nentries = 0;

      int ret = 0;
      UInt lidx = 0;

      bool iglobal = matrix->IndicesAreGlobal();

      if (iglobal) {
           ret = matrix->ExtractGlobalRowView(dof, nentries, old_row, old_indices);
      } else {

         std::map<int,int>::iterator li = global2local.find(dof);
         ThrowRequire(li != global2local.end());

         lidx = li->second;

         ret = matrix->ExtractMyRowView(lidx, nentries, old_row, old_indices);
       }
  
      ThrowRequire(ret == 0);
  
      std::vector<WMat::Entry> col;
   
      for (UInt i = 0; i < nentries; ++i) {

        int gidx = iglobal ? old_indices[i] : my_column[old_indices[i]];

        col.push_back(WMat::Entry(gidx, 0, old_row[i]));
        old_row[i] = 0.0;
      }
   
      // Add in the matrix values
      std::copy(wi->second.begin(), wi->second.end(), std::back_inserter(col));
   
      WMat::condense_row(col);
   
      std::vector<int> nidx(col.size());
      std::vector<double> nval(col.size());
  
      for (UInt i = 0; i < col.size(); ++i) {
 
        std::map<int,int>::iterator li;

        if (!iglobal) {
          li = global2local_col.find(col[i].id);
          if (li == global2local_col.end())
            Throw() << "could not find id:" << col[i].id;
        }
   
        nidx[i] = iglobal ? col[i].id : li->second;
        nval[i] = col[i].value;
  
      } // i
  
      int iret = 0;
      if (iglobal) 
        matrix->InsertGlobalValues(dof, col.size(), &nval[0], &nidx[0]);
      else
        iret = matrix->ReplaceMyValues(lidx, col.size(), &nval[0], &nidx[0]);

/*
if (iglobal) {
  Par::Out() << "**inserting dof= " << dof << std::endl;
   for (UInt i = 0; i < col.size(); ++i)
     Par::Out() << "\t" << nidx[i] << " ";
   Par::Out() << std::endl;
}
*/

      if (iret != 0) {
         Par::Out() << "**Error: lidx=" << lidx << std::endl;
         for (UInt i = 0; i < col.size(); ++i)
           Par::Out() << "\t" << nidx[i] << " ";
         Par::Out() << std::endl;
         Throw() << "Failed insert/replace, iret = " << iret;
      }

    }

  }
  

#else
  Throw() << "Please recompile with Trilinos enabled";
#endif
}

void LinSys::SumToGlobal(UInt row, const double mat_row[], double rhs_val) {
#ifdef ESMCI_TRILINOS 
/*
Par::Out() << "add row:" << elem_dofs[row] << std::endl;
for (UInt i = 0; i < nelem_dofs; i++) {
  Par::Out() << "\t(" << elem_dofs[i] << ", " << mat_row[i] << ")" << std::endl; 
}
*/
/*
  if (elem_dof_signs[row] < 0) {

for (UInt i = 0; i < nelem_dofs; i++) {
  const_cast<double&>(mat_row[i])*=-1.0;
}

  }
*/
//if (elem_dof_signs[row] > 0) {

  // If the me is oriented, we have to negate all such columns (except on the diagonal, since
  // the dof will have cancelled itself)
  if(has_neg_dofs) {
  for (UInt i = 0; i < nelem_dofs; i++) {
    if (elem_dof_signs[row] < 0 && row != i) const_cast<double&>(mat_row[i])*=-1.0;
  }
  }

/*
  int ret = matrix->SumIntoGlobalValues(elem_dofs[row],
            static_cast<int>(nelem_dofs), const_cast<double*>(&mat_row[0]), &elem_dofs[0]);
*/

  int ret = matrix->SumIntoGlobalValues(1, &elem_dofs[row],
            static_cast<int>(nelem_dofs), &elem_dofs[0],
            const_cast<double*>(&mat_row[0]));

//Par::Out() << "\tret=" << ret << std::endl;
  //ThrowRequire(ret == 0);
  
  b->SumIntoGlobalValues(1, &elem_dofs[row], &rhs_val);
#endif
}

void LinSys::SetFadCoef(UInt offset, std::vector<double> &mcoef, std::vector<fad_type> &fad_coef) {

/*
  for (UInt i = 0; i < nelem_dofs; i++) {
    if (elem_dof_signs[i] < 0) {
      fad_coef[offset + i] = -mcoef[i];
      fad_coef[offset + i].diff(offset+i, nelem_dofs);
      fad_coef[offset + i] *= -1.0;
    } else {
      fad_coef[offset + i] = mcoef[i];
      fad_coef[offset + i].diff(offset+i, nelem_dofs);
    }
  }
*/
  for (UInt i = offset; i < nelem_dofs; i++) {
      fad_coef[i-offset] = mcoef[i-offset];
      fad_coef[i-offset].diff(i, nelem_dofs);
  }

}

/**
 * Loop the dof field entries.  call dof_action at every object, with nval and fdim,
 * the object, and pointer:
 * dof_act(obj, nval, fdim, fptr)
 */
template <typename dof_action>
void LinSys::loop_dofs(dof_action &dact) {

  UInt nfields = Fields.size();

  KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end();

  for (; ki != ke; ++ki) {

    Kernel &ker = *ki;

    if (!ker.is_active()) continue;

    Kernel::obj_iterator oi = ker.obj_begin(), oe = ker.obj_end();

    bool on_kernel = false;
    std::vector<int> field_on(nfields,0);
  
    for (UInt f = 0; f < nfields; f++) {
      if (Fields[f]->Getfield()->OnAttr(ker.GetAttr(), false)) {
        field_on[f] = 1;
        on_kernel = true;
      }
    }

    if (!on_kernel) continue;
 
 
    for (; oi != oe; ++oi) {

      MeshObj &obj = *oi;

      for (UInt f = 0; f < nfields; ++f) {

        if (field_on[f] != 1) continue;

         const _field &llf = *DFields[f]->Getfield();
                
         const _field &lf = *Fields[f]->Getfield();

                dact(obj, llf.dim(obj), (DField_type*) llf.data(obj),
                    (double*) lf.data(obj));
      } // f 

    } //oi

  } // ki
}

struct dof_action_set {
dof_action_set(LinSys::DField_type val) {_val = val;}
LinSys::DField_type _val;
void operator()(MeshObj &obj, UInt fdim, LinSys::DField_type *dfptr,double*) {
  
  // First zero:
  for (UInt c = 0; c < fdim; c++) dfptr[c] = _val;
}
};

struct dof_action_count {
dof_action_count() { count = 0;}
UInt count;
void operator()(MeshObj &obj, UInt fdim, LinSys::DField_type *dfptr,double*) {
  
  if (GetMeshObjContext(obj).is_set(Attr::OWNED_ID) && dfptr[0] == 0) {
    
    dfptr[0] = 1;
    
    count += fdim;
    
  }
  
}
};

struct dof_action_assign {
dof_action_assign(const std::vector<long> &needed_ids) : _ids(needed_ids), id(0) {}
const std::vector<long> &_ids;
UInt id;
void operator()(MeshObj &obj, UInt fdim, LinSys::DField_type *dfptr,double*) {
  
  if (GetMeshObjContext(obj).is_set(Attr::OWNED_ID) && dfptr[0] == 0) {
    
    for (UInt c = 0; c < fdim; ++c) {
      dfptr[c] = _ids[id++];
//Par::Out() << "set obj:" << obj.get_id() << " to " << _ids[id-1] << std::endl;
    }
    
  }
  
}
};

struct dof_action_print {
void operator()(MeshObj &obj, UInt fdim, LinSys::DField_type *dfptr,double*) {
  
  for (UInt c = 0; c < fdim; ++c) {
    Par::Out() << "obj:" << obj.get_id() << " is " << dfptr[c] << std::endl;
  }
  
}
};

void LinSys::BuildDofs() {
  Trace __trace("LinSys::BuildDofs()");
  
  UInt nfields = Fields.size();

  std::vector<long> used_ids;
  std::vector<long> needed_ids;

  // The local numbering of dof
  int local_id = 0;

  // First zero the dof field.
  {
    dof_action_set das(0);
    loop_dofs(das);
  }
  
  // Next, we count the unique dofs.  We do this by looping and setting a 1
  // in the first meshobj entry of each locally owned object.  If we haven't
  // visited yet, it is zero, and count every dof on the object.
  UInt num_needed = 0;
  {
    dof_action_count dac;
    loop_dofs(dac);
    num_needed = dac.count;
  }
Par::Out() << "Num needed=" << num_needed << std::endl;

  used_ids.resize(0);
  needed_ids.resize(num_needed);
  
  // Get the global ids.  These are >= 1
  GlobalIds(used_ids, needed_ids);

  // Zero again, since we will use nonzero to mean already assigned
  {
    dof_action_set das(0);
    loop_dofs(das);
  }
  
  {
    dof_action_assign dass(needed_ids);
    loop_dofs(dass);
    ThrowRequire(dass.id == needed_ids.size());
  }

  // Now share the parallel ids.  Can use swap add, since non-locally owned have
  // zero.
  std::vector<MEField<> *> df;
  for (UInt i = 0; i < DFields.size(); i++) {
    df.push_back(static_cast<MEField<> *>(DFields[i]));
  }
  
  mesh.SwapOp<DField_type>(df.size(), &df[0], CommRel::OP_SUM);

/*
  {
    dof_action_print dac;
    loop_dofs(dac);
  }
*/

  if (Par::Rank() == Par::Size()-1 && needed_ids.size() > 0) {
    std::cout << needed_ids[needed_ids.size()-1] << " degrees of freedom" << std::endl;
  }
  
}

struct dof_get_ids {
dof_get_ids(std::vector<int> &my_global, bool _store_local, bool _store_non_local) :
  _ids(my_global), store_local(_store_local), store_non_local(_store_non_local) {}
std::vector<int> &_ids;
bool store_non_local;
bool store_local;
void operator()(MeshObj &obj, UInt fdim, LinSys::DField_type *dfptr,double*) {
  
  bool owned = GetMeshObjContext(obj).is_set(Attr::OWNED_ID);
  if((owned && store_local) || (!owned && store_non_local)) {
    for (UInt c = 0; c < fdim; ++c) {
      std::vector<int>::iterator lb =
        std::lower_bound(_ids.begin(), _ids.end(), dfptr[c]);
//Par::Out() << MeshObjTypeString(obj.get_type()) << " " << obj.get_id() << " dof:" << dfptr[c] << std::endl;

      if (lb == _ids.end() || *lb != dfptr[c]) {
        _ids.insert(lb, dfptr[c]);
      }
      
    }
  }
    
}
};

void LinSys::BuildMatrix() {
  Trace __trace("LinSys::BuildMatrix()");
#ifdef ESMCI_TRILINOS

  
  delete_epetra_objs(); // in case they are still around.

  UInt nfields = Fields.size();
  // First the epetra map
  my_global.clear();
  my_owned.clear();  
  {
    std::vector<int> tmp;
    dof_get_ids dgi(my_owned, true, false);
    loop_dofs(dgi);
    
    dof_get_ids dgi1(tmp, false, true);
    loop_dofs(dgi1);

    std::sort(my_owned.begin(), my_owned.end());
    std::sort(tmp.begin(), tmp.end());
    
    std::copy(my_owned.begin(), my_owned.end(), std::back_inserter(my_global));
    std::copy(tmp.begin(), tmp.end(), std::back_inserter(my_global));
    
    // Fit memory to vector.
    std::vector<int>(my_global).swap(my_global);
  }
/*
Par::Out() << "my_owned:" << std::endl;
std::copy(my_owned.begin(), my_owned.end(), std::ostream_iterator<int>(Par::Out(), "\n")); 
*/
  
  Epetra_MpiComm comm(Par::Comm());

  //map = new Epetra_Map(-1, my_global.size(), &my_global[0], 0, comm);

  umap = new Epetra_Map(-1, my_owned.size(), &my_owned[0], 0, comm);

  global2local.clear();

  for (UInt i = 0; i < my_owned.size(); ++i) global2local[my_owned[i]] = i;


  x = new Epetra_FEVector(*umap);
  //b = new Epetra_FEVector(*umap);
  b = new Epetra_FEVector(*umap);

  // Now to the matrix
  // Loop elements.  Build a vector of DofKey for each element
  int max_df = 0;

  // The first time through, store how man entries per dof.
  std::map<int, int> max_df_map;

  // Loop twice.  First time, just find the max_df.  Second time build matrix.
  for (UInt lp = 0; lp < 2; lp++) {

  if (lp == 1) {

    std::map<int,int>::iterator mi = max_df_map.begin(), me = max_df_map.end();
    for (; mi != me; ++mi) {
      if (mi->second > max_df) max_df = mi->second;
    }

    Par::Out() << "max_df=" << max_df << std::endl;
    matrix = new Epetra_FECrsMatrix(Copy, *umap, max_df); // 100 = approx entries per row??
  }

  KernelList::iterator ki = mesh.set_begin(), ke = mesh.set_end();
    for (; ki != ke; ++ki) {
      Kernel &ker = *ki;

      // only process active
      if (!ker.is_active()) continue;


      // Find out which fields live on kernel
      bool on_kernel = false;
      std::vector<int> field_on(nfields,0);

      for (UInt f = 0; f < nfields; f++) {
        if ((ker.type() == Fields[f]->GetType())
              && (field_on[f] = ker.GetContext().any(Fields[f]->GetContext())))
          on_kernel = true;
      }
    
      if (!on_kernel) continue; 

      // At least one of the fields is on the kernel, so request id's for the
      // objects in this kernel
      Kernel::obj_iterator oi = ker.obj_begin(), oe = ker.obj_end();

        for (; oi !=oe; ++oi) {
          MeshObj &elem = *oi;

          std::vector<int> dofindices;

          for (UInt f = 0; f < nfields; f++) {
            if (field_on[f]) {
  
              MEFieldBase &mef = *DFields[f];
             
              UInt fdim = mef.dim();
              
              MEField<> &dmef = static_cast<MEField<>&>(*DFields[f]);

              MasterElementBase &meb = GetME( mef, elem);
              
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

                UInt nval = meb.GetDofValSet(df);
                
                const _field &llf = *dmef.Getfield();
 
                DField_type *dft = llf.data(*dofobj);
                
                for (UInt d = 0; d < fdim; d++) {

                  // Push back the global id
                  dofindices.push_back(dft[dd[2]*fdim+d]);

                } // for d

              } // dofs

            } // field on obj
          } // for fields
          // Now that we have the dofkeys, add the rows of the matrix; for each
          // owned key, add all others.

          int msize = dofindices.size();
          std::vector<double> vals(msize*msize, 0.0);
          
/*
if (lp ==1) {
Par::Out() << "insert global rows:";
for (UInt i = 0; i < msize; i++) {
  Par::Out() << dofindices[i] << " ";
}
Par::Out() << std::endl;
}
*/
   
          if (lp == 1) {
            if (matrix->InsertGlobalValues(msize, &dofindices[0], 
              &vals[0]) != 0) {
                 Throw() << "Error inserting matrix values:"
                     << "msize=" << msize;
            }

          }
          else {

            for (UInt d = 0; d < msize; d++) {

              std::pair<std::map<int,int>::iterator,bool> mi =
                max_df_map.insert(std::make_pair(dofindices[d], msize));

              // Add msize if already there
              if (mi.second == false) {
//std::cout << dofindices[d] << " already in map, new msize=" << mi.first->second + msize << std::endl;
                mi.first->second += msize;
              }

            } // d

          }

        } // for oi on kernel

    
    } // for kernels
    } //lp

//Par::Out() << *matrix << std::endl;
    //matrix->GlobalAssemble();  
    //matrix->FillComplete();

#else
    Throw() << "This function requires trilinos";
#endif
}

void LinSys::PrintMatrix(std::ostream &os) {
#ifdef ESMCI_TRILINOS

  os << "*** Matrix *** " << std::endl;
  os << *matrix << std::endl; 

  os << "*** rhs ***" << std::endl;
  os << *b << std::endl;
#endif
}

void LinSys::Solve(UInt &lin_iter, double &lin_res) {
#ifdef ESMCI_TRILINOS
#ifdef NOT
                                 // The Direct option selects the Amesos solver.
  if (solver_params.SOLVER == solver_params_type::DIRECT) {
   
                                 // Setup for solving with
                                 // Amesos.
     Epetra_LinearProblem prob;
     prob.SetOperator(Matrix);
     Amesos_BaseSolver *solver;
     Amesos Factory;

                                 // Other solvers are available
                                 // and may be selected by changing this
                                 // string.
     char *stype = "Amesos_Klu";

     solver = Factory.Create(stype, prob);

     Assert (solver != NULL, ExcInternalError());

                                 // There are two parts to the direct solve.
                                 // As I understand, the symbolic part figures
                                 // out the sparsity patterns, and then the
                                 // numerical part actually performs Gaussian
                                 // elimination or whatever the approach is.
     if (solver_params.OUTPUT == solver_params_type::VERBOSE)
       std::cout << "Starting Symbolic fact\n" << std::flush;

     solver->SymbolicFactorization();

     if (solver_params.OUTPUT == solver_params_type::VERBOSE)
         std::cout << "Starting Numeric fact\n" << std::flush;

     solver->NumericFactorization();

    
                                 // Define the linear problem by setting the
                                 // right hand and left hand sides.
     prob.SetRHS(&b);
     prob.SetLHS(&x);
                                 // And finally solve the problem.
     if (solver_params.OUTPUT == solver_params_type::VERBOSE)
       std::cout << "Starting solve\n" << std::flush;
     solver->Solve();
     niter = 0;
     lin_residual = 0;

                                 // We must free the solver that was created
                                 // for us.
     delete solver;

  } else if (solver_params.SOLVER == solver_params_type::GMRES) {
#endif

  Par::Out() << "*** Beginning linear solve ***" << std::endl;

  ThrowRequire(lsp.method == LinSysParam::GMRES);
struct solver_params_type {
 enum {QUIET = 0, VERBOSE=1};

 UInt OUTPUT;
 double ILUT_DROP; 
 double ILUT_FILL;
 double ILUT_ATOL;
 double ILUT_RTOL;
 int MAX_ITERS;
 double RES;
};

solver_params_type solver_params;
solver_params.OUTPUT = solver_params_type::QUIET;
//solver_params.OUTPUT = solver_params_type::VERBOSE;
solver_params.ILUT_DROP = 1e-10;
solver_params.ILUT_FILL = 1.3;
solver_params.ILUT_ATOL = 1e-3;
solver_params.ILUT_RTOL = 1.01;
solver_params.MAX_ITERS = 200;
solver_params.RES = 1e-10;

                                 // For the iterative solvers, we use Aztec.
    AztecOO Solver;
    Solver.SetUserMatrix(matrix);
    Solver.SetRHS(b);
    Solver.SetLHS(x);
                                 // Select gmres.  Other solvers are available.
    Solver.SetAztecOption(AZ_solver, AZ_gmres);


    ML *ml_handle;
    ML_Aggregate *agg_object;
    ML_Epetra::MultiLevelOperator *MLop;

  if (lsp.preconditioner == LinSysParam::ILUT) {

                                 // Set up the ILUT preconditioner.  I do not know
                       // why, but we must pretend like we are in parallel
                                 // using domain decomposition or the preconditioner
                                 // refuses to activate.
    Solver.SetAztecOption(AZ_precond, AZ_dom_decomp);
    Solver.SetAztecOption(AZ_subdomain_solve, AZ_ilut);
    Solver.SetAztecOption(AZ_overlap, 2);
    Solver.SetAztecParam(AZ_athresh, lsp.ILUT_ATOL);
    Solver.SetAztecParam(AZ_rthresh, lsp.ILUT_RTOL);
    Solver.SetAztecOption(AZ_reorder, 0);

                                 // ILUT parameters as described above.
    Solver.SetAztecParam(AZ_drop, lsp.ILUT_DROP);
    Solver.SetAztecParam(AZ_ilut_fill, lsp.ILUT_FILL);
  } else if (lsp.preconditioner == LinSysParam::ML) {

    int N_levels = lsp.ml_levels;
    ML_Set_PrintLevel(lsp.output == LinSysParam::VERBOSE ? 3 : 0);
    ML_Create(&ml_handle,N_levels);
    EpetraMatrix2MLMatrix(ml_handle, 0, matrix);
    ML_Aggregate_Create(&agg_object);
    N_levels = ML_Gen_MGHierarchy_UsingAggregation(ml_handle,
    0,
    ML_INCREASING,
    agg_object);
    ML_Gen_Smoother_SymGaussSeidel(ml_handle, ML_ALL_LEVELS,
    ML_BOTH, 1, ML_DEFAULT);
    ML_Gen_Solver (ml_handle, ML_MGV, 0, N_levels-1);
    Epetra_MpiComm comm(Par::Comm());
    MLop = new ML_Epetra::MultiLevelOperator(ml_handle,comm,*umap,*umap);
    Solver.SetPrecOperator(MLop);

  }

    

                                 // Select the appropriate level of verbosity.
    if (lsp.output == LinSysParam::QUIET)
      Solver.SetAztecOption(AZ_output, AZ_none);

    if (lsp.output == LinSysParam::VERBOSE)
      Solver.SetAztecOption(AZ_output, AZ_all);

    Solver.SetAztecOption(AZ_kspace, lsp.max_iters+1);

                                 // Run the solver iteration.  Collect the number
                                 // of iterations and the residual.
    Solver.Iterate(lsp.max_iters, lsp.residual);
    UInt niter = Solver.NumIters();
    double lin_residual = Solver.TrueResidual();

    if (lsp.preconditioner == LinSysParam::ML) {
      ML_Aggregate_Destroy(&agg_object);
      ML_Destroy(&ml_handle);
      delete MLop;
    }

    lin_iter = niter;
    lin_res = lin_residual;

  Par::Out() << "*** End linear solve ***, res=" << lin_residual << std::endl;
  
  scatter_sol();
 #endif 
}

void LinSys::Dirichlet(DField_type row_id, double val, bool owned) {
#ifdef ESMCI_TRILINOS
  
  
  std::vector<double> new_row;
  double *old_row;
  int *old_indices;
  int nentries = 0;
  double diag_val;

  int ret = matrix->ExtractGlobalRowView(row_id, nentries, old_row, old_indices);
 
if (nentries == 0) {Par::Out() << "row:" << row_id << ", nentries = 0" << std::endl; return;}
  if (ret == -2)
    Throw() << "Extract view failed.  Perhaps EndAssemble not called before dirichlet??";
  
  //ThrowRequire(ret == 0);
  
  //Par::Out() << "Extract ret=" << ret << std::endl;

  if (nentries <= 0)
    Throw() << "nentries==0, for row_id=" << row_id;

  new_row.resize(nentries, 0.0);

  // Find my index
  int k;
  for (k = 0; k < nentries; k++) {
    if (old_indices[k] == row_id) break;
  }
  ThrowRequire(k < nentries);

  new_row[k] = owned ? 1.0 : 0.0;
  
Par::Out() << "Replacing row:" << row_id;
for (UInt i = 0; i < nentries; ++i) {
  Par::Out() << "\tidx:" << old_indices[i] << ", oldval:" << old_row[i] << " -> " << new_row[i] << std::endl;
}
Par::Out() << std::endl;
  
  matrix->ReplaceGlobalValues(1, &row_id, nentries, old_indices, &new_row[0]);

  if (!owned) val = 0.0;
  x->ReplaceGlobalValues(1, &row_id, &val);

  double rhs_val = val;
  b->ReplaceGlobalValues(1, &row_id, &rhs_val);

#endif
}

#ifdef ESMCI_TRILINOS
struct dof_scatter_sol {
dof_scatter_sol(Epetra_FEVector &_x, std::vector<int> &_my_g) :x(_x), my_g(_my_g) {}

void operator()(MeshObj &obj, UInt fdim, LinSys::DField_type *dfptr,double *fval) {
  
    for (UInt c = 0; c < fdim; ++c) {
      
      int idx = static_cast<int>(dfptr[c]);
      
      std::vector<int>::iterator lb =
        std::lower_bound(my_g.begin(), my_g.end(), idx);
      
      if (lb == my_g.end() || *lb != idx) continue;
      /*
      if (lb == my_g.end() || *lb != idx) {

        Par::Out() << "my_g:";
        std::copy(my_g.begin(), my_g.end(), std::ostream_iterator<int>(Par::Out(), "\n"));
        Par::Out() << "Could not find idx:" << idx << std::endl;
        Throw() << "did not find idx:" << idx;
      }
      */
      
      UInt off = std::distance(my_g.begin(), lb);
      

      
      fval[c] = x[0][off];
      //std::cout << "scatter dof:" << idx << ", off=" << off << " val ="  << fval[c] << std::endl;
      
    }
    
}

Epetra_FEVector &x;
std::vector<int> &my_g;
};
#endif


void LinSys::scatter_sol() {
#ifdef ESMCI_TRILINOS
  
  //Par::Out() << "x=" << *x << std::endl;

  dof_scatter_sol dss(*x, my_owned);
  
  loop_dofs(dss);

  //mesh.SwapOp<double>(Fields.size(), &Fields[0], CommRel::OP_SUM);
  mesh.HaloFields(Fields.size(), &Fields[0]);
#endif
}

void LinSys::RhsNorm(double &res_norm) {
#ifdef ESMCI_TRILINOS
  b->Norm2(&res_norm);
#endif
}


void LinSysParam::declare_parameters(ParameterHandler &prm) {

  prm.enter_subsection("linear solver");
    prm.declare_entry("output", "quiet",
                     Patterns::Selection(
                     "quiet|verbose"),
                      "<quiet|verbose>");
    prm.declare_entry("method", "gmres",
                     Patterns::Selection(
                     "gmres|direct"),
                      "<gmres|direct>");
    prm.declare_entry("residual", "1e-10",
                     Patterns::Double(),
                     "linear solver residual");
    prm.declare_entry("max iters", "300",
                     Patterns::Double(),
                     "maximum solver iterations");
    prm.declare_entry("preconditioner", "ml",
                     Patterns::Selection(
                     "ml|ilut"),
                      "<ml|ilut>");
    prm.declare_entry("ilut fill", "2",
                     Patterns::Double(),
                     "ilut preconditioner fill");
    prm.declare_entry("ilut absolute tolerance", "1e-9",
                     Patterns::Double(),
                     "ilut preconditioner tolerance");
    prm.declare_entry("ilut relative tolerance", "1.1",
                     Patterns::Double(),
                     "rel tol");
    prm.declare_entry("ilut drop tolerance", "1e-10",
                     Patterns::Double(),
                     "ilut drop tol");
    prm.declare_entry("ml levels", "10",
                     Patterns::Double(),
                     "ml levels");
  prm.leave_subsection();


}

void LinSysParam::load_parameters(ParameterHandler &prm) {

                    // The linear solver.
 prm.enter_subsection("linear solver");
    const std::string &op = prm.get("output");

    if (op == "verbose") output = VERBOSE; else output = QUIET;

    const std::string &sv = prm.get("method");
    if (sv == "direct") {
      method = DIRECT;
    } else if (sv == "gmres") {
      method = GMRES;
    } 

    residual = prm.get_double("residual");
    max_iters = (int) prm.get_double("max iters");

    const std::string &pop = prm.get("preconditioner");

    if (pop == "ml") preconditioner = ML; else preconditioner = ILUT;

    ILUT_FILL = prm.get_double("ilut fill");
    ILUT_ATOL = prm.get_double("ilut absolute tolerance");
    ILUT_RTOL = prm.get_double("ilut relative tolerance");
    ILUT_DROP = prm.get_double("ilut drop tolerance");

    ml_levels = (int) (prm.get_double("ml levels")+0.5);
  prm.leave_subsection();

}


} // namespace
