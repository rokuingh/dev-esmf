#include <Mesh/include/ESMCI_ReMap.h>
#include <Mesh/include/ESMCI_MEField.h>
#include <Mesh/include/ESMCI_MeshObjConn.h>
#include <Mesh/include/ESMCI_MEFamily.h>
#include <Mesh/include/ESMCI_MeshUtils.h>

#include <limits>
#include <math.h>

namespace ESMCI {


  const double ReMap::pi_  =  3.141592653589793238462643383279;
  const double ReMap::a_   =  2.0*double(std::numeric_limits<double>::epsilon());

  //template<class Derived>
  //Derived* AbstractSingleton<Derived>::pInstance_ = 0;
  template<>
  ReMap* AbstractSingleton<ReMap>::pInstance_ = 0;

  //ReMap* AbstractSingleton<ReMap>::pInstance_ = 0;
  
  void ReMap::SetReMapType(ReMapType rt){rt_ = rt; AbstractSingleton<ReMap>::IsSet=true;}
  void ReMap::Set2DScaling(double Lx, double Ly){Lx_ = Lx;Ly_ = Ly;}
  void ReMap::SetTorus_r(double r){r_ = r;}
  void ReMap::SetTorus_R(double R){R_ = R;}
  
  void ReMap::PrintType(){
    if(AbstractSingleton<ReMap>::IsSet){
      std::cout << "SINGLETON:REMAP HAS TYPE : ";
      if(rt_ == IDENTITY)    std::cout << "IDENTITY" << std::endl;
      if(rt_ == TORUS)       std::cout << "TORUS" << std::endl;
      if(rt_ == CUBED_SPHERE)std::cout << "CUBED_SPHERE" << std::endl;
      if(rt_ == CYLINDER)    std::cout << "CYLINDER" << std::endl;
    }else{
      std::cout << "SINGLETON:REMAP was NOT set" << std::endl;;
    }  
  }

  bool ReMap::Test(const double &x, const double &y, const double &z){

    if(AbstractSingleton<ReMap>::IsSet == true){
      if(rt_ == IDENTITY)return false;
      switch(rt_){
      case TORUS:
	return TestTorus(x,y,z);
	break;
      case CUBED_SPHERE:
	return TestCubedSphere(x,y,z);
	  break;
      case CYLINDER:
	return TestCylinder(x,y,z);
	break;
      };
    }
  };

  void ReMap::ConvertFrom(double &x, double &y, double &z){
    if(AbstractSingleton<ReMap>::IsSet == true){
      if(rt_ == IDENTITY)return;
      switch(rt_){
      case TORUS:
	ConvertFromTorus(x,y,z);
	break;
      case CUBED_SPHERE:
	ConvertFromCubedSphere(x,y,z);
	  break;
      case CYLINDER:
	ConvertFromCylinder(x,y,z);
	break;
      };
    }
  };
  
  void ReMap::ConvertTo(double &u, double &v, double &w){

    
    if(AbstractSingleton<ReMap>::IsSet == true){
      if(rt_ == IDENTITY)return;
      switch(rt_){
      case TORUS:
	ConvertToTorus(u,v,w);
	break;
      case CUBED_SPHERE:
	ConvertToCubedSphere(u,v,w);
	break;
      case CYLINDER:
	ConvertToCylinder(u,v,w);
	break;
      };
    }
  };

  void ReMap::ReprojectTo(double &u, double &v, double &w){

    
    if(AbstractSingleton<ReMap>::IsSet == true){
      if(rt_ == IDENTITY)return;
      switch(rt_){
      case TORUS:
	ReprojectToTorus(u,v,w);
	break;
      case CUBED_SPHERE:
	ReprojectToCubedSphere(u,v,w);
	break;
      case CYLINDER:
	ReprojectToCylinder(u,v,w);
	break;
      };
    }
  };
  
  void ReMap::ConvertFromTorus(double &x, double &y, double &z){

    double u,v;
    double atan_,asin_;    

    // 3D coordinates lying on Torus transformed to u,v

    // The points might not be on the torus exactly 
    // (e.g. linear interpolation) so we 
    // reproject them first
    double eps_ = 0.0;
    atan_=0.5*pi_*(1.0-x/(fabs(x)+fabs(y)+eps_));
    if(y<0.0)atan_=-atan_;

    asin_  = 0.5*pi_*(fabs(x) + fabs(y) - R_ + r_)/(r_+eps_);
    if(z<0.0)asin_=-asin_;

    u = Lx_*(0.5 + (0.5/pi_)*atan_);
    v = Ly_*(0.5 + (0.5/pi_)*asin_);

    z = 0.0;
    x = u;
    y = v;
    
  };

  void ReMap::ConvertFromCubedSphere(double &x, double &y, double &z){
    ReprojectToCubedSphere(x,y,z);// puts on the sphere our cube 
  };

  void ReMap::ConvertFromCylinder(double &x, double &y, double &z){
    //ReprojectToCylinder(x,y,z); // makes sure we are on cylinder...    
    double atan_,eps_=30.0*std::numeric_limits<double>::epsilon();
    atan_=0.5*pi_*(1.0-x/(r_+0.*eps_));
    if(y<-double(0))atan_=-atan_;
    x =Lx_*(0.5 + (0.5/pi_)*atan_);
    y=Ly_*(z/R_+0.5);
    z=0.;
  };
  
  void ReMap::ConvertToTorus(double &u, double &v, double &w){
    double x,y,z;

    // u,v --> x,y,z
    
    x = (R_ + r_*cos(v*2.0*pi_/Ly_))*cos(u*2.0*pi_/Lx_);
    y = (R_ + r_*cos(v*2.0*pi_/Ly_))*sin(u*2.0*pi_/Lx_);
    z = r_*sin(v*2.0*pi_/Ly_);
    u =x;v=y;w=z;

  };

  void ReMap::ConvertToCubedSphere(double &x, double &y, double &z){};
  void ReMap::ConvertToCylinder(double &x, double &y, double &z){};
  
  void ReMap::ReprojectToTorus(double &x, double &y, double &z){

    double atan_ = atan2(y,x);
    double xc = R_*cos(atan_);
    double yc = R_*sin(atan_);
    double t = sqrt(r_*r_/((x-xc)*(x-xc)+(y-yc)*(y-yc) + z*z));
    x = t*(x-xc) + xc;y = t*(y-yc)+yc; z = z*t;

  };


  void ReMap::ReprojectToCubedSphere(double &x, double &y, double &z){
    double n = 1.0/sqrt(x*x+y*y+z*z);
    x=n*x;y=n*y;z=z*n;
  };

  void ReMap::ReprojectToCylinder(double &x, double &y, double &z){
    double n = 1.0/sqrt(x*x+y*y);
    x=n*x;y=n*y;
  };

  bool ReMap::TestTorus(const double &x, const double &y, const double &z){

    if((fabs(y) < a_) || (fabs(z) < a_))return true;
    return false;

  };
  
  bool ReMap::TestCylinder(const double &x, const double &y, const double &z){
    if((x < -a_) && (fabs(y) < a_))return true;
    return false;
  };

  bool ReMap::TestCubedSphere(const double &x, const double &y, const double &z){return false;};

  void ReMap::ConvertFrom(ESMCI::Mesh &imesh){

    Mesh::iterator ei = imesh.node_begin(), ee = imesh.node_end();

    MEField<> &coords = *imesh.GetCoordField();

    for (; ei != ee; ++ei) {
      MeshObj &node = *ei;
      double *data = coords.data(node);
      ConvertFrom(data[0],data[1],data[2]);
    }
  };

  void ReMap::ReprojectTo(ESMCI::Mesh &imesh){
    
    Mesh::iterator ei = imesh.node_begin(), ee = imesh.node_end();
    
    MEField<> &coords = *imesh.GetCoordField();
    
    for (; ei != ee; ++ei) {
      MeshObj &node = *ei;
      double *data = coords.data(node);
      ReprojectTo(data[0],data[1],data[2]);
    }
  };

 
  void ReMap::RelaxToBarycenter(const double &a_,Mesh& imesh){
    if(ESMCI::ReMap::Instance().IsNotIdentity()){

      const double b_=1.0-a_;
      double *data[400];
      double bc[400];
      double tmp;
      bool modify=false;
    
      MEField<> &coords = *imesh.GetCoordField();
    
      Mesh::iterator ei = imesh.elem_begin(), ee = imesh.elem_end();
    
      for (; ei != ee; ++ei) {
      
	MeshObj &elem = *ei;
	
	MasterElement<> &me = dynamic_cast<MasterElement<>&>(GetME(coords, elem));
	
	const UInt npts_me = me.NumInterpPoints();	
	
	if (me.is_nodal()) {
	  
	  double invfunc = 1.0/double(me.num_functions());
	  //std::cout << " NUM POINTS : " <<  me.num_functions() << std::endl;
	  
	  for (UInt d = 0; d < coords.dim(); d++)bc[d] = 0.;
	  

	  modify=false;
	  for (UInt n = 0; n < me.num_functions(); n++) {
	    const MeshObj &node = *elem.Relations[n].obj;
	    data[n] = coords.data(node);//careful points to !!
	    for (UInt d = 0; d < coords.dim(); d++) {
	      bc[d] = bc[d] + invfunc*data[n][d];//compute center
	    } // dim
	    if(Test(data[n][0],data[n][1],data[n][2]))modify=true;
	  } // for nfunc
	  

	  if(modify){
	    //shift points inside
	    for (UInt n = 0; n < me.num_functions(); n++) {
	      if(Test(data[n][0],data[n][1],data[n][2])){
		for (UInt d = 0; d < coords.dim(); d++) {
		  data[n][d] = a_*bc[d] + b_*data[n][d];
		}
	      }
	    }
	  }
	} 
      }
    
    }
  }


  int ReMap::ElementIsPeriodic(std::vector<bool> &is_on_bnd,const MeshObj &elem, MEField<> &coords){
    if(IsNotIdentity()){
      
      const MeshObjTopo &topo = *GetMeshObjTopo(elem);    

      // works for 2D elements in 2 or 3 dimensions
      ThrowAssert(topo.parametric_dim == 2);

      const UInt nd = topo.spatial_dim;      
      double bc[nd],bcT[nd];

      // Compute physical barycenter
      elemCentroid<>(coords,elem,bc);

      // change topology
      ConvertFrom(bc[0],bc[1],bc[2]);

      const UInt npe = topo.num_nodes;

      is_on_bnd.reserve(npe);

      double corners[npe][nd];
      const double fac = 1.0/double(npe);

      for (UInt d = 0; d < nd; d++)bcT[d] = 0.;

      for (UInt n = 0; n < npe; n++) {
	const MeshObj &node = *(elem.Relations[n].obj);
	const double *fd = coords.data(node);
	
	corners[n][2] =0.0; // in case of shell 
	// copy node (we are about to transform it!)
	for (UInt d = 0; d < nd; d++)corners[n][d] = fd[d];

	is_on_bnd[n] = Test(corners[n][0],corners[n][1],corners[n][2]);
	ConvertFrom(corners[n][0],corners[n][1],corners[n][2]);
	
	// this is the barycenter after the mapping
	for (UInt d = 0; d < nd; d++)bcT[d] += fac*corners[n][d];
      }
      double eps_ = (Lx_+Ly_)*double(std::numeric_limits<double>::epsilon());
      double norm[]={0,0,0};
      for(int k=0;k<nd;k++)norm[k]=fabs(bc[k] - bcT[k]);

      PeriodicityType per=NOTPERIODIC;
      
      if(norm[0] > eps_) per=XPERIODIC;
      if(norm[1] > eps_) per=YPERIODIC;
      if((norm[0] > eps_) && (norm[1] > eps_)) per=XYPERIODIC;

#if 0
      if(per != NOTPERIODIC){
	std::cout << per << " BARYCENTER FOR ELEMENT " << elem.get_id() <<  " IS ";
	std::cout << bc[0] << "," << bc[1] << "," << bc[2] << std::endl;
      }
#endif

      return per;

    }
    return NOTPERIODIC;
  };

  ReMap::ReMap() {rt_ = IDENTITY;Lx_= Ly_ = 1.0; r_ = R_=1.0;}

  void ReMap::CorrectForPeriodicity(double &x, double &y, double &z,const PeriodicityType &isper){
    
  
    if(isper == NOTPERIODIC || !IsNotIdentity())return;
    
    const double eps_ = (Lx_+Ly_)*std::numeric_limits<double>::epsilon();

    if(1==0){//rt_ == CYLINDER){ 
      if(isper == XPERIODIC){if(fabs(x) +eps_ >= Lx_){x = 0.;}else if(fabs(x) <= eps_){x = Lx_;}}
    }else{
#if 0
      std::cout << "x     = " << x << std::endl;
      std::cout << "y     = " << y << std::endl;
      std::cout << "eps   = " << eps_ << std::endl;
      std::cout << "Lx    = " << Lx_ << std::endl;
      std::cout << "Ly    = " << Ly_ << std::endl;
      std::cout << "isper = " << isper << std::endl;
#endif
      if(isper == XPERIODIC){if(fabs(x) +eps_ >= Lx_){x = 0.;}else if(fabs(x) <= eps_){x = Lx_;}}
      if(isper == YPERIODIC){if(fabs(y) +eps_>= Ly_){y = 0.;}else if(fabs(y) <= eps_){y = Ly_;}}
      if(isper == XYPERIODIC){
	if(fabs(x) +eps_>= Lx_){x = 0.;}else if(fabs(x) <= eps_){x = Lx_;}
	if(fabs(y) +eps_>= Ly_){y = 0.;}else if(fabs(y) <= eps_){y = Ly_;}
      }
    }

  }

};
