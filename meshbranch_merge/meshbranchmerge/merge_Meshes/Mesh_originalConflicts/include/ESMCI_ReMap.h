#ifndef ESMCI_ReMap
#define ESMCI_ReMap
#include <Mesh/include/ESMCI_Mesh.h>
#include <iostream>

namespace ESMCI {
  

  // 
  // Singleton class anything derived 
  // from this will be a Singleton.
  //
  
  template<class Derived>
  class AbstractSingleton{
    
    static Derived* pInstance_;
    
    AbstractSingleton(const AbstractSingleton &in){};
    
  protected:
    
    AbstractSingleton(): IsSet(false) {};
    bool IsSet;
    
  public:
    
    static Derived& Instance(){
      if(!pInstance_){
	static Derived obj;
	pInstance_ = &obj;
	return obj;
      }else{
	return *pInstance_;
      }
    }; 
  };
  
  //template<class Derived>
  //Derived* AbstractSingleton<Derived>::pInstance_ = 0;
  



  class ReMap : public AbstractSingleton<ReMap> {

  public:

    typedef enum {IDENTITY=0,TORUS, CUBED_SPHERE, CYLINDER} ReMapType;
   

  private:

    ReMapType rt_;
    double Lx_,Ly_,r_,R_;
    //    const static double pi_  =  3.141592653589793238462643383279;
    //    const static double a_   =  1.0/4096.0;
    const static double pi_;
    const static double a_;    

  public:

    typedef enum {NOTPERIODIC=0,XPERIODIC=1, YPERIODIC=2, XYPERIODIC=3} PeriodicityType;

    ReMap();
    // Set up the state of the unique object ...

    bool IsNotIdentity(){return AbstractSingleton<ReMap>::IsSet;}

    void SetReMapType(ReMapType rt);
    void Set2DScaling(double Lx, double Ly);
    void SetTorus_r(double r);
    void SetTorus_R(double R);

    // Node-wise ops
    void ConvertFrom(double &x, double &y, double &z);
    void ConvertTo(  double &u, double &v, double &w);
    void ReprojectTo(double &u, double &v, double &w);

    bool Test(const double &x, const double &y, const double &z);
    void CorrectForPeriodicity(double &x, double &y, double &z,const PeriodicityType &isper);

    // Element-wise ops

    int ElementIsPeriodic(std::vector<bool> &is_on_bnd,const MeshObj &elem, MEField<> &coords);

    // All mesh operations

    void ConvertFrom(ESMCI::Mesh &mesh);
    void ReprojectTo(ESMCI::Mesh &mesh);
    void RelaxToBarycenter(const double &a_,Mesh& imesh);

    // debug

    void PrintType();

  private:

    void ConvertFromTorus(double &x, double &y, double &z);
    void ConvertFromCubedSphere(double &x, double &y, double &z);
    void ConvertFromCylinder(double &x, double &y, double &z);

    void ConvertToTorus(double &u, double &v, double &w);
    void ConvertToCubedSphere(double &x, double &y, double &z);
    void ConvertToCylinder(double &x, double &y, double &z);

    void ReprojectToTorus(double &u, double &v, double &w);
    void ReprojectToCubedSphere(double &x, double &y, double &z);
    void ReprojectToCylinder(double &x, double &y, double &z);

    bool TestTorus(const double &u, const double &v, const double &w);
    bool TestCubedSphere(const double &x, const double &y, const double &z);
    bool TestCylinder(const double &x, const double &y, const double &z);
    
  };
  
}
#endif
