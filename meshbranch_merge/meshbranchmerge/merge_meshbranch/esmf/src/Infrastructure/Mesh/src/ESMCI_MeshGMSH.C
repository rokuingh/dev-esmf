#include <Mesh/include/ESMCI_MeshGMSH.h>

#include <Mesh/include/ESMCI_MeshDB.h>
#include <Mesh/include/ESMCI_MeshObjTopo.h>
#include <iostream>
#include <fstream>
#include <stdexcept>
#include <sstream>
#include <iomanip>
#include <iterator>
#include <string>
#include <utility>

#include <Mesh/include/ESMCI_MeshField.h>
#include <Mesh/include/ESMCI_MeshUtils.h>
#include <Mesh/include/ESMCI_MeshSkin.h>

#include <Mesh/include/ESMCI_Exception.h>
#include <Mesh/include/ESMCI_ParEnv.h>
#include <Mesh/include/ESMCI_ReMap.h>

namespace ESMCI {

  
  void read_check_line(std::istream &is, const std::string val)
  {
    std::string line;
    is>>line;
    if(line!=val)
      Throw() << "LoadMeshDB GMSH error: expected \"" << val << "\" and not \"" << line << "\"\n";
  }
  /* Reads a GMSH mesh (http://www.geuz.org/gmsh) */
  /* We just consider 2d flat elements            */
  void ReadGMSHMesh(Mesh &mesh, const std::string &filename, int nstep) {
    UInt sdim(0),pdim(0);
    std::string line;
    UInt npoints;
    std::ifstream file ( filename.c_str() , std::ifstream::in );
    if (file.fail())
      Throw() << "LoadMeshDB GMSH error: cannot open file " << filename << std::endl;
    read_check_line(file, "$MeshFormat");
    int gmsh_format=0;
    file >> gmsh_format;
    if (gmsh_format != 2)
      Throw() << "LoadMeshDB GMSH error: can only read gmsh v2 files and not v" << gmsh_format << std::endl;
    getline(file,line);
    read_check_line(file,"$EndMeshFormat");
    read_check_line(file,"$Nodes");
    file >> npoints;
    // Read coordinates of nodes
    double coord[3*npoints];
    std::map<UInt,UInt> id_map;
    for (UInt i = 0; i < npoints; i++) {
      int file_id;
      file >> file_id;
      id_map[file_id]=i;
      for (UInt j = 0; j < 3; j++) {
	file >> coord[3*i+j];
      }
    }//npoints
    getline(file,line);
    read_check_line(file,"$EndNodes");
    read_check_line(file,"$Elements");
    //Read elements information
    UInt nelems;
    file >> nelems;
    //We just consider 2d flat elements
    std::vector<UInt*> tris_to_nodes;
    std::vector<UInt*> quads_to_nodes;
    UInt elemtypes[nelems];
    int tag;
    std::vector<UInt> nodes(3);
    int ntags,buf0,buf1;
    typedef std::map<std::pair <UInt,UInt>,int> tagmap;
    tagmap nodepairs_to_tags;
    for (UInt i = 0; i < nelems; i++) {
      file >> buf0;
      file >> elemtypes[i];
      file >> ntags;
      tag=0;
      if (ntags!=0)
	file >> tag;
      for (UInt j=1; j<ntags; j++)
	file >> buf0; //Just one tag (the first) is passed to ESMF
      switch (elemtypes[i]){
      case 1:{ //2-node line (tags used as sidesets)
	file >> buf0;
	file >> buf1;
	std::pair <UInt,UInt> nodepair (buf0,buf1);
	nodepairs_to_tags[nodepair]=tag;
	nodepair = std::make_pair(buf1,buf0);
	nodepairs_to_tags[nodepair]=tag;
	break;
      }
      case 2:{ //3-node triangle
	pdim=2;
	UInt *tri_to_nodes=new UInt[3];
	file >> tri_to_nodes[0];
	file >> tri_to_nodes[1];
	file >> tri_to_nodes[2];
	tris_to_nodes.push_back(tri_to_nodes);
	break;
      }
      case 3:{ //4-node quadrangle
	pdim=2;
	UInt *quad_to_nodes=new UInt[4];
	file >> quad_to_nodes[0];
	file >> quad_to_nodes[1];
	file >> quad_to_nodes[2];
	file >> quad_to_nodes[3];
	quads_to_nodes.push_back(quad_to_nodes);
	break;
      }
      case 15:{ //1-node point: just throw the data
	file >> buf0;
	break;
      }
      default:
	Throw() << "LoadMeshDB GMSH error: element type not supported: " << elemtypes[i] << std::endl;
      }
    }//nelems
    getline(file,line);
    read_check_line(file,"$EndElements");
    
    // Actually building the mesh
    
    // Nodes
    std::vector<MeshObj*> nodevect; nodevect.reserve(npoints);
    for (UInt i = 0; i < npoints; i++) {
      MeshObj *node = new MeshObj(MeshObj::NODE, -(i+1), i);
      nodevect.push_back(node);
      node->set_owner(Par::Rank());
      mesh.add_node(node, 0);
    }
    // Now, build an element_type -> block array.
    typedef std::map<UInt, UInt> bmap;
    bmap etype2blk;
    UInt cur_blk = 1;
    for (UInt i = 0; i < nelems; i++) {
      std::pair<bmap::iterator, bool> lk =
        etype2blk.insert(std::make_pair(elemtypes[i], cur_blk));
      // If insert was successful, this was a new block
      if (lk.second == true) cur_blk++;
    }
    // And another administrative detail: are we 3D physical or 2D space ?
    // Assume that if we are 2d the last coord is fixed...
    if (pdim == 2) {   
      double c3 = coord[2];
      bool coorddiff = false;
      for (UInt i = 0; !coorddiff && i < npoints; i++) {
	if (std::fabs(coord[3*i + 2] - c3) > 1e-5) coorddiff = true;
      }
      sdim = (coorddiff ? 3 : 2);
    }else sdim=3;
    mesh.set_parametric_dimension(pdim);
    mesh.set_spatial_dimension(sdim);
    // Add the elements
    UInt cur_off = 0;
    UInt tri_off = 0;
    UInt quad_off = 0;
    UInt elem_off = -1;
    std::vector<UInt*> *elems_to_nodes;
    for (UInt i = 0; i < nelems; i++) {
      const MeshObjTopo *topo=NULL; //1d lines are not elements in ESMF
      switch (elemtypes[i]){
      case 2:{
	topo=GetTopo(sdim==3?"SHELL3":"TRI3");
	cur_off=tri_off;
	tri_off++;
	elem_off++;
	elems_to_nodes=&tris_to_nodes;
	break;
      }
      case 3:{
	topo=GetTopo(sdim==3?"SHELL":"QUAD");
	cur_off=quad_off;
	quad_off++;
	elem_off++;
	elems_to_nodes=&quads_to_nodes;
	break;
      }
      }	
      if (topo!=NULL){
	MeshObj *elem = new MeshObj(MeshObj::ELEMENT, -(elem_off+1), elem_off);
	// Collect an array of the nodes.
	std::vector<MeshObj*> elemnodes; elemnodes.reserve(topo->num_nodes);
	for (UInt n = 0; n < topo->num_nodes; n++){
	  elemnodes.push_back(nodevect[id_map[(*elems_to_nodes)[cur_off][n]]]);
	}
	elem->set_owner(Par::Rank());
	mesh.add_element(elem, elemnodes, topo->number, topo);
	//Looking for sides with tags (sidesets)
	for (UInt s=0; s<topo->num_sides; s++){
	  std::pair <UInt,UInt> nodes_s((*elems_to_nodes)[cur_off][s],(*elems_to_nodes)[cur_off][(s+1)%topo->num_sides]);
	  tagmap::iterator it;
	  it=nodepairs_to_tags.find(nodes_s);
	  if (it!=nodepairs_to_tags.end()){
	    const MeshObjTopo * const stopo = topo->side_topo(s);
	    MeshObj::MeshObjType tp = topo->parametric_dim == 2 ? MeshObj::EDGE : MeshObj::FACE;
	    MeshObj *side = new MeshObj(tp, mesh.get_new_local_id(tp));
	    mesh.add_side_local(*side, *elem, s, it->second , stopo);
	  }
	}
      }
    }
    
    IOField<NodalField> *node_coord = mesh.RegisterNodalField(mesh, "coordinates", mesh.spatial_dim());
    
    // Copy coordinates into field
    MeshDB::const_iterator ni = mesh.node_begin(), ne = mesh.node_end();
    for (; ni != ne; ++ni) {
      double *c = node_coord->data(*ni);
      UInt idx = ni->get_data_index();
      c[0] = coord[3*idx];
      if (mesh.spatial_dim() >= 2) c[1] = coord[3*idx+1];
      if (mesh.spatial_dim() >= 3) c[2] = coord[3*idx+2];
    }

    for (int i=0; i<tris_to_nodes.size();i++)
      delete[] tris_to_nodes[i];
    for (int i=0; i<quads_to_nodes.size();i++)
      delete[] quads_to_nodes[i];
    //No data in gmsh mesh files
    if (Par::Rank()==0)
      std::cout << "MeshGMSH Load file " << filename << " complete." << std::endl;
  }//LoadGMSHMesh

} //namespace
