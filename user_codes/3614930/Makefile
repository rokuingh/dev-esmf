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

.SUFFIXES: .f90 .F90 .c .C

.f90:
	$(ESMF_F90COMPILER) -c $(ESMF_F90COMPILEOPTS) $(ESMF_F90COMPILEPATHS) \
          $(ESMF_F90COMPILEFREENOCPP) $<
	$(ESMF_F90LINKER) $(ESMF_F90LINKOPTS) $(ESMF_F90LINKPATHS) \
          $(ESMF_F90LINKRPATHS) -o $@ $*.o $(ESMF_F90ESMFLINKLIBS)
	rm -f $*.o

.F90:
	$(ESMF_F90COMPILER) -c $(ESMF_F90COMPILEOPTS) $(ESMF_F90COMPILEPATHS) \
          $(ESMF_F90COMPILEFREECPP) $(ESMF_F90COMPILECPPFLAGS) $<
	$(ESMF_F90LINKER) $(ESMF_F90LINKOPTS) $(ESMF_F90LINKPATHS) \
          $(ESMF_F90LINKRPATHS) -o $@ $*.o $(ESMF_F90ESMFLINKLIBS)
	rm -f $*.o
        
.c:
	$(ESMF_CXXCOMPILER) -c $(ESMF_CXXCOMPILEOPTS) \
          $(ESMF_CXXCOMPILEPATHSLOCAL) $(ESMF_CXXCOMPILEPATHS) \
          $(ESMF_CXXCOMPILECPPFLAGS) $<
	$(ESMF_CXXLINKER) $(ESMF_CXXLINKOPTS) $(ESMF_CXXLINKPATHS) \
          $(ESMF_CXXLINKRPATHS) -o $@ $*.o $(ESMF_CXXESMFLINKLIBS)
	rm -f $*.o

.C:
	$(ESMF_CXXCOMPILER) -c $(ESMF_CXXCOMPILEOPTS) \
          $(ESMF_CXXCOMPILEPATHSLOCAL) $(ESMF_CXXCOMPILEPATHS) \
          $(ESMF_CXXCOMPILECPPFLAGS) $<
	$(ESMF_CXXLINKER) $(ESMF_CXXLINKOPTS) $(ESMF_CXXLINKPATHS) \
          $(ESMF_CXXLINKRPATHS) -o $@ $*.o $(ESMF_CXXESMFLINKLIBS)
	rm -f $*.o

################################################################################
### Sample targets for user ESMF applications ##################################

ProfileWeightGenOptions:

.PHONY: clean
clean:
	rm -f  *.o *.Log *.log *.ESMF_LogFile *.out *.err *.vtk ProfileWeightGenOptions

.PHONY: dust
dust:
	rm -f *.o *.mod

###############################################################################
