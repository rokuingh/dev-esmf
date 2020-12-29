# Reproducer for 3615028
# August 21, 2020
# Ryan O'Kuinghttons

import os
from ESMF import *
import numpy as np

# This call enables debug logging
Manager(debug=True)

# Create a global grid from a SCRIP formatted file
mesh = Mesh(filename="mesh.mx025.nc", filetype=FileFormat.ESMFMESH)

# mesh._write_("mesh.mx025")

## fails with meshloc=MeshLoc.ELEMENT
srcfield = Field(mesh, meshloc=MeshLoc.ELEMENT)
dstfield = Field(mesh, meshloc=MeshLoc.ELEMENT)
## passes with meshloc=MeshLoc.NODE (default)
# srcfield = Field(mesh, meshloc=MeshLoc.NODE)
# dstfield = Field(mesh, meshloc=MeshLoc.NODE)

# rh = Regrid(srcfield, dstfield, pole_method=PoleMethod.NONE)
rh = Regrid(srcfield, dstfield, pole_method=PoleMethod.ALLAVG)
# rh = Regrid(srcfield, dstfield)

