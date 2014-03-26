<<<<<<< makefile
# $Id: makefile,v 1.13.2.1 2010/01/28 21:24:03 amikstcyr Exp $
=======
# $Id: makefile,v 1.21 2010/05/17 23:37:32 peggyli Exp $
>>>>>>> 1.21

ALL: build_examples
run: run_examples
run_uni: run_examples_uni

# Work around an MPICH(2) issue
ESMF_CXXCOMPILECPPFLAGS += -DMPICH_IGNORE_CXX_SEEK

LOCDIR	  = src/Infrastructure/Mesh/examples


EXAMPLES_BUILD    = \
                      $(ESMF_EXDIR)/ESMC_RendEx \
                      $(ESMF_EXDIR)/ESMC_DCatEx \
                      $(ESMF_EXDIR)/ESMC_RefineEx \
<<<<<<< makefile
                      $(ESMF_EXDIR)/ESMC_PatchWghtEx \
                      $(ESMF_EXDIR)/ESMC_DPartEx  
=======
                      $(ESMF_EXDIR)/ESMC_RegridWgtGenEx \
                      $(ESMF_EXDIR)/ESMF_MeshEx \
                      $(ESMF_EXDIR)/ESMF_CubedSphereRegridEx
#                      $(ESMF_EXDIR)/ESMC_BreckEx \
>>>>>>> 1.21

ESMF_EXAMPLE_CubedSphereRegrid_OBJS = convertSCRIP.o
ESMF_CubedSphereRegridEx.o: $(ESMF_EXAMPLE_CubedSphereRegrid_OBJS)

EXAMPLES_RUN      = run_ESMF_MeshEx 

EXAMPLES_RUN_UNI  =


include $(ESMF_DIR)/makefile

DIRS	  = 

CLEANDIRS   = 
CLEANFILES  = $(EXAMPLES_BUILD)
CLOBBERDIRS =

run_ESMC_DPartEx: 
	$(MAKE) EXNAME=DPart

#
#  Run targets
#
run_ESMC_RefineEx:
	$(MAKE) EXNAME=Refine NP=4 excrun

run_ESMC_RefineEx_uni:
	echo "PASS: ESMF_RefineEx not set up to run on one processor." > $(ESMF_EXDIR)/ESMF_RefineEx.stdout

run_ESMF_MeshEx:
	cp -r data $(ESMF_EXDIR)
	chmod u+rw $(ESMF_EXDIR)/data/*
	$(MAKE) EXNAME=Mesh NP=6 exfrun

<<<<<<< makefile
run_ESMF_MeshEx_uni:
	echo "PASS: ESMF_MeshEx not set up to run on one processor." > $(ESMF_EXDIR)/ESMF_MeshEx.stdout

=======
>>>>>>> 1.21
