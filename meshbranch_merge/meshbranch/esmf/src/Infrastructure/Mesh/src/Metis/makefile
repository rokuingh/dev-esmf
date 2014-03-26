# $Id: makefile,v 1.1.2.2 2010/02/17 19:44:56 amikstcyr Exp $

ALL: build_here 

# Workaround an MPICH(2) issue
ESMF_CXXCOMPILECPPFLAGS += -DMPICH_IGNORE_CXX_SEEK

SOURCEC	  =	balance.c bucketsort.c ccgraph.c coarsen.c compress.c debug.c \
		estmem.c fm.c fortran.c frename.c graph_metis.c initpart.c kmetis.c \
		kvmetis.c kwayfm.c kwayrefine.c kwayvolfm.c kwayvolrefine.c \
		match.c mbalance.c mbalance2.c mcoarsen.c memory.c mesh.c \
		meshpart.c mfm.c mfm2.c mincover.c minitpart.c minitpart2.c \
		mkmetis.c mkwayfmh.c mkwayrefine.c mmatch.c mmd.c mpmetis.c \
		mrefine.c mrefine2.c mutil.c myqsort.c ometis.c parmetis.c \
		pmetis.c pqueue.c refine.c separator.c sfm.c srefine.c stat.c \
		subdomains.c timing.c util.c

SOURCEF	  = 
SOURCEH	  =  defs.h macros.h metis.h proto.h rename.h struct.h

# List all .h files which should be copied to common include dir
STOREH	  = 

OBJSC     = $(addsuffix .o, $(basename $(SOURCEC)))
OBJSF     = $(addsuffix .o, $(basename $(SOURCEF)))

LIBBASE	  = libesmf
LOCDIR	  = src/Infrastructure/Mesh/src/Metis

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
