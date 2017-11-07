import os
import ESMF

ESMF.Manager(debug=True)

# set up the DATADIR
DATADIR = "/home/ryan/data/UGRID"
meshdata = []
# meshdata.append("/home/ryan/data/UGRID/FVCOM_grid2d_20120314.nc")
# meshdata.append(ESMF.FileFormat.UGRID)
# meshdata.append("fvcom_mesh")
# meshdata.append("/home/ryan/data/UGRID/ConcaveQuadUGRID1.nc")
# meshdata.append(ESMF.FileFormat.UGRID)
# meshdata.append("mesh")
# meshdata.append("/home/ryan/data/UGRID/ne30np4-t2UGRID.nc")
# meshdata.append(ESMF.FileFormat.UGRID)
# meshdata.append("mesh")
meshdata.append("/home/ryan/data/data/ne30np4-t2.nc")
meshdata.append(ESMF.FileFormat.ESMFMESH)
meshdata.append("mesh")


# create an ESMF formatted unstructured mesh with clockwise cells removed
mesh = ESMF.Mesh(filename=meshdata[0], filetype=meshdata[1], meshname=meshdata[2])

import psutil
process = psutil.Process(os.getpid())
print("Total memory usage: "+
      str(process.memory_info().rss/1024./1024.)+
      " Mb")
