
import numpy as np
import ESMF

mgr = ESMF.Manager(debug=True)

sourcegrid = ESMF.Grid(filename="source.nc", filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True)

destgrid = ESMF.Grid(filename="destination.nc", filetype=ESMF.FileFormat.GRIDSPEC, add_corner_stagger=True)

sourcefield = ESMF.Field(sourcegrid)
destfield = ESMF.Field(destgrid)

regrid_bi = ESMF.Regrid(sourcefield, destfield, filename="weights.nc",
                        regrid_method = ESMF.RegridMethod.CONSERVE,
                        unmapped_action = ESMF.UnmappedAction.ERROR)
