<<<<<<< makefile
# $Id: makefile,v 1.16.2.4 2010/04/28 22:50:21 sblaise Exp $
=======
# $Id: makefile,v 1.25 2010/04/21 22:30:37 rokuingh Exp $
>>>>>>> 1.25

# leave alone.
ALL: build_here 

# Workaround an MPICH2 issue
ESMF_CXXCOMPILECPPFLAGS += -DMPICH_IGNORE_CXX_SEEK

SOURCEC	  = \
           ESMCI_Attr.C \
           ESMCI_BBox.C \
           ESMCI_CommReg.C \
           ESMCI_CommRel.C \
           ESMCI_Context.C \
           ESMCI_DDir.C \
           ESMCI_Exception.C \
           ESMCI_Extrapolation.C \
           ESMCI_FieldReg.C \
	   ESMCI_FuncParser.C \
           ESMCI_GeomRendezvous.C \
           ESMCI_GlobalIds.C \
           ESMCI_HAdapt.C \
           ESMCI_Integrate.C \
           ESMCI_Interp.C \
           ESMCI_IOField.C \
           ESMCI_Kernel.C \
	   ESMCI_LinSys.C \
           ESMCI_Mapping.C \
           ESMCI_MasterElement.C \
           ESMCI_MCoord.C \
           ESMCI_MEFamily.C \
           ESMCI_MEField.C \
	   ESMCI_MEFieldBlas.C \
           ESMCI_MEImprint.C \
           ESMCI_Mesh.C \
           ESMCI_MeshDB.C \
           ESMCI_MeshExodus.C \
	   ESMCI_MeshllField.C \
           ESMCI_MeshField.C \
           ESMCI_MeshGen.C \
           ESMCI_MeshNC.C \
           ESMCI_MeshObj.C \
           ESMCI_MeshObjConn.C \
           ESMCI_MeshObjPack.C \
           ESMCI_MeshObjTopo.C \
           ESMCI_MeshPartition.C \
           ESMCI_MeshPNC.C \
           ESMCI_MeshRead.C \
           ESMCI_MeshRefine.C \
           ESMCI_MeshRegrid.C \
           ESMCI_MeshSkin.C \
           ESMCI_MeshUtils.C \
           ESMCI_MeshVTK.C \
           ESMCI_MeshGMSH.C \
           ESMCI_MEValues.C \
           ESMCI_Migrator.C \
<<<<<<< makefile
	   ESMCI_ParamHandler.C \
           ESMCI_OctBox3d.C \
=======
           ESMCI_OTree.C \
>>>>>>> 1.25
           ESMCI_ParEnv.C \
           ESMCI_ParLog.C \
           ESMCI_PatchRecovery.C \
           ESMCI_Polynomial.C \
           ESMCI_Quadrature.C \
           ESMCI_Rebalance.C \
           ESMCI_RefineTopo.C \
	   ESMCI_ReMap.C \
           ESMCI_Search.C \
           ESMCI_SFuncAdaptor.C \
           ESMCI_ShapeFunc.C \
	   ESMCI_ShapeHierarchic.C \
           ESMCI_ShapeLagrange.C \
	   ESMCI_ShapeMini.C \
           ESMCI_SmallAlloc.C \
           ESMCI_SparseMsg.C \
           ESMCI_WMat.C \
           ESMCI_WriteWeights.C \
           ESMCI_WriteWeightsPar.C \
           ESMCI_SpaceDir.C \
           ESMCI_FindPnts.C \
           ESMCI_MeshCXX.C

SOURCEF	  = ESMF_SolverUtil_C.F90 \

SOURCEH	  = ESMCI_MeshCXX.h

# List all .h files which should be copied to common include dir
STOREH	  = ESMCI_MeshCXX.h

OBJSC     = $(addsuffix .o, $(basename $(SOURCEC)))
OBJSF     = $(addsuffix .o, $(basename $(SOURCEF)))

LIBBASE	  = libesmf
LOCDIR	  = src/Infrastructure/Mesh/src

CLEANDIRS   =
CLEANFILES  = 
CLOBBERDIRS =

include ${ESMF_DIR}/makefile

DIRS	  = Zoltan ExodusII Metis

