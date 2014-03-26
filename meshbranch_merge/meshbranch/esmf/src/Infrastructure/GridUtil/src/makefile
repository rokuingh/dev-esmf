# $Id: makefile,v 1.8 2010/02/25 19:59:56 oehmke Exp $

ALL: build_here 

SOURCEC	  = ESMC_GridToMesh.C
SOURCEF	  =
SOURCEH	  = 

# List all .h files which should be copied to common include dir
STOREH	  = 

OBJSC     = $(addsuffix .o, $(basename $(SOURCEC)))
OBJSF     = $(addsuffix .o, $(basename $(SOURCEF)))

LIBBASE	  = libesmf
LOCDIR	  = src/Infrastructure/GridUtil/src

CLEANDIRS   =
CLEANFILES  =
CLOBBERDIRS =

include ${ESMF_DIR}/makefile

DIRS =

