# $Id: makefile,v 1.1.2.1 2009/02/03 22:31:23 amikstcyr Exp $

ALL: build_here 

# Workaround an MPICH(2) issue
ESMF_CXXCOMPILECPPFLAGS += -DMPICH_IGNORE_CXX_SEEK

SOURCEC	  = 	ex_conv.c ex_utils.c exclos.c excn2s.c excopy.c excre.c exerr.c exgatm.c \
		exgcns.c exgcon.c exgcor.c exgcss.c exgean.c exgeat.c exgebi.c exgelb.c \
		exgelc.c exgem.c exgenm.c exgev.c exgevid.c exgevt.c exgfrm.c exggv.c \
		exggvt.c exgids.c exginf.c exgini.c exgmap.c exgmp.c exgnam.c exgnams.c \
		exgnm.c exgnnm.c exgnp.c exgns.c exgnsd.c exgnsi.c exgnstt.c exgnsv.c \
		exgnsvid.c exgnv.c exgnvid.c exgnvt.c exgnvv.c exgoea.c exgotv.c exgp.c \
		exgpa.c exgpem.c exgpn.c exgqa.c exgsnl.c exgsp.c exgss.c exgssc.c exgssd.c \
		exgssi.c exgssn.c exgsstt.c exgssv.c exgssvid.c exgtim.c exgtt.c exgvan.c \
		exgvid.c exgvnm.c exgvp.c exgvtt.c exgvv.c exinq.c exopen.c exopts.c expclb.c \
		expcns.c expcon.c expcor.c expcss.c expean.c expeat.c expelb.c expelc.c \
		expem.c expenm.c expev.c expfrm.c expgv.c expinf.c expini.c expmap.c expmp.c \
		expnam.c expnams.c expnm.c expnnm.c expnp.c expns.c expnsd.c expnstt.c expnsv.c \
		expnv.c expnvv.c expoea.c expp.c exppa.c exppem.c exppn.c expqa.c expsp.c expss.c \
		expssd.c expsstt.c expssv.c exptim.c exptt.c expvan.c expvnm.c expvp.c expvpa.c \
		expvpc.c expvtt.c expvv.c exupda.c

SOURCEF	  = 
SOURCEH	  =  exodusII.h  exodusII_int.h

# List all .h files which should be copied to common include dir
STOREH	  = 

OBJSC     = $(addsuffix .o, $(basename $(SOURCEC)))
OBJSF     = $(addsuffix .o, $(basename $(SOURCEF)))

LIBBASE	  = libesmf
LOCDIR	  = src/Infrastructure/Mesh/src/ExodusII

CLEANDIRS   =
CLEANFILES  = 
CLOBBERDIRS =

include ${ESMF_DIR}/makefile

DIRS	  = 

# XLC++ on BGL systems has trouble with some of the Zoltan code in -O mode.
# -> this seems to be a compiler bug and we may be able to take this out once
# IBM has it fixed.
ifeq ($(ESMF_OS),Linux)
ifeq ($(ESMF_COMPILER),xlf)
ESMF_OPTLEVEL = 0
endif
endif
