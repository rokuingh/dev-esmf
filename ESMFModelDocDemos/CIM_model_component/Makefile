# $Id: Exp $
#===============================================================================
#                            Makefile
# 
# This is the makefile for the Regrid external demo
#===============================================================================

################################################################################
### Finding and including esmf.mk ##############################################

# Note: This fully portable Makefile template depends on finding environment
#       variable "ESMFMKFILE" set to point to the appropriate "esmf.mk" file,
#       as is discussed in the User's Guide.
#       However, you can still use this Makefile template even if the person
#       that installed ESMF on your system did not provide for a mechanism to
#       automatically set the environment variable "ESMFMKFILE". In this case
#       either manually set "ESMFMKFILE" in your environment or hard code the
#       location of "esmf.mk" into the include statement below.
#       Notice that the latter approach has negative impact on portability.

ifneq ($(origin ESMFMKFILE), environment)
$(error Environment variable ESMFMKFILE was not set.)
endif

include $(ESMFMKFILE)

################################################################################
### Compiler and linker rules using ESMF_ variables supplied by esmf.mk ########

.SUFFIXES: .f90 .F90

%.o : %.f90
	$(ESMF_F90COMPILER) -c $(ESMF_F90COMPILEOPTS) $(ESMF_F90COMPILEPATHS) $(ESMF_F90COMPILEFREENOCPP) $<

%.o : %.F90
	$(ESMF_F90COMPILER) -c $(ESMF_F90COMPILEOPTS) $(ESMF_F90COMPILEPATHS) $(ESMF_F90COMPILEFREECPP) $(ESMF_F90COMPILECPPFLAGS) $<
        
################################################################################
### Sample targets for user ESMF applications ##################################

all: ModelGridDemo dust

ModelDemo: user_model1.o user_model2.o user_model3.o user_model4.o user_coupler.o CIM_model_demo.o 
	$(ESMF_F90LINKER) $(ESMF_F90LINKOPTS) $(ESMF_F90LINKPATHS) $(ESMF_F90LINKRPATHS) -o $@ $^ $(ESMF_F90ESMFLINKLIBS)
CIM_model_demo.o: user_model1.o user_model2.o user_model3.o user_model4.o user_coupler.o

ModelGridDemo: user_model1grids.o user_model2.o user_model3.o user_model4.o user_coupler.o CIM_model_demo_with_grids.o 
	$(ESMF_F90LINKER) $(ESMF_F90LINKOPTS) $(ESMF_F90LINKPATHS) $(ESMF_F90LINKRPATHS) -o $@ $^ $(ESMF_F90ESMFLINKLIBS)
CIM_model_demo_with_grids.o: user_model1grids.o user_model2.o user_model3.o user_model4.o user_coupler.o

.PHONY: clean
clean:
	rm -f  *.o *.mod *.Log *.out *.err *.vtk *.xml ModelDemo ModelGridDemo

.PHONY: dust
dust:
	rm -f *.o *.mod 

###############################################################################
