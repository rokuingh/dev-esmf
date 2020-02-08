import numpy as np
import ESMF

timein = 4000 # number of time points

ESMF.Manager(debug=True) 

            # Read destination grid for ESMF interpolation
esmfgrid_rho = ESMF.Grid(filename="Lake_erie_grd_v1.nc", filetype=ESMF.FileFormat.GRIDSPEC,
                         is_sphere=False, coord_names=['lon_rho', 'lat_rho'],
                                          add_mask=False)
#modLon = esmfgrid_rho.get_coords(0)
#modLat = esmfgrid_rho.get_coords(1)
 
            # Read source  grid for ESMF interpolation
esmfgrid = ESMF.Grid(filename="airtemp.nc", filetype=ESMF.FileFormat.GRIDSPEC,
                         is_sphere=False, coord_names=['lon', 'lat'],
                                          add_mask=False)

#SrcLon = esmfgrid.get_coords(0)
#SrcLat = esmfgrid.get_coords(1)

#Read source field
fieldSrc = ESMF.Field(esmfgrid, "airtemp",staggerloc=ESMF.StaggerLoc.CENTER,ndbounds=[timein])

 
fieldSrc.read(filename="airtemp.nc", variable="airtemp",timeslice=0)

#Create destination field
fieldDst_rho = ESMF.Field(esmfgrid_rho, "Tair",staggerloc=ESMF.StaggerLoc.CENTER,ndbounds=[timein])

# regrid
regridSrc2Dst_rho = ESMF.Regrid(fieldSrc, fieldDst_rho, regrid_method=ESMF.RegridMethod.BILINEAR,
                                                       unmapped_action=ESMF.UnmappedAction.IGNORE)

fieldDst_rho = regridSrc2Dst_rho(fieldSrc, fieldDst_rho)

