import os
import ESMF

ESMF.Manager(debug=True)

# set up the DATADIR
DATADIR = "/home/ryan/data/UGRID"
meshdata = []
# meshdata.append("FVCOM_grid2d_20120314.nc")
# meshdata.append(ESMF.FileFormat.UGRID)
# meshdata.append("fvcom_mesh")
# meshdata.append("ConcaveQuadUGRID1.nc")
# meshdata.append(ESMF.FileFormat.UGRID)
# meshdata.append("mesh")
meshdata.append("ne30np4-t2UGRID.nc")
meshdata.append(ESMF.FileFormat.UGRID)
meshdata.append("mesh")


# create an ESMF formatted unstructured mesh with clockwise cells removed
mesh = ESMF.Mesh(filename=os.path.join(DATADIR, meshdata[0]),
                 filetype=meshdata[1], meshname=meshdata[2])

import psutil
process = psutil.Process(os.getpid())
print("Total memory usage: "+
      str(process.memory_info().rss/1024./1024.)+
      " Mb")
