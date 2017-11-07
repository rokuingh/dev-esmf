import csv
import ESMF
import numpy as np
import netCDF4 as nc

# file names have no path information, python working directory assumed
# to be set to data directory.

#=======================================================================
# read point data from csv and create LocStream
#=======================================================================

# file to read, loc stream raw
file_ls = "points.csv"

# as list of dictionaries
with open(file_ls, 'rb') as f:
	reader = csv.DictReader(f)
	points = []
	for row in reader:
		points.append(row)

# create locstream
locstream = ESMF.LocStream(len(points), coord_sys=ESMF.CoordSys.SPH_DEG)
locstream["ESMF:Lon"]    = [float(e['longitude_deg']) for e in points]
locstream["ESMF:Lat"]    = [float(e['latitude_deg']) for e in points]
# locstream["ESMF:Radius"] = [float(e['elevation_m']) for e in points]
# NOTE: the radius must be removed from the LocStream for it to be considered a 2D object for regridding purposes
#       i.e. bilinear regridding from 2D Grid will not work unless LocStream is also 2D


#=======================================================================
# 2D interpolation of one variable (time, latitude, longitude) to time
# series output for LocStreams
#=======================================================================

# file to read, ERA-Interim surface forecast
file_sf = "era_sf.nc"

#list variables that should be interpolated
variables = ["ssrd","strd","tp"]

# open netcdf file handle
n2D = nc.Dataset(file_sf, 'r')

# get dimensions
time = n2D.variables['time'][:]
lat  = n2D.variables['latitude'][:]
lon  = n2D.variables['longitude'][:]

# create a uniform global latlon grid from a SCRIP formatted file
srcg2D = ESMF.Grid(filename=file_sf, filetype=ESMF.FileFormat.GRIDSPEC)

# create a field on the center stagger locations of the source grid
srcf2D = ESMF.Field(srcg2D, name='srcf2D',
                    staggerloc=ESMF.StaggerLoc.CENTER,
                    ndbounds=[len(variables), len(time)])

# assign data from ncdf: (variale, time, latitude, longitude) 
for n, var in enumerate(variables):
    srcf2D.data[n,:,:,:] = n2D.variables[var][:,:,:]

# create destination field
# npoint = len(locstream["ESMF:Lon"])
# dstf2D = ESMF.Field(locstream, name='dstf2D')
# dstf2D.data = np.empty([len(variables), len(time), npoint])
dstf2D = ESMF.Field(locstream, name='dstf2D', ndbounds=[len(variables), len(time)])

# get regridding
regrid2D = ESMF.Regrid(srcf2D, dstf2D,
                       regrid_method=ESMF.RegridMethod.BILINEAR,
                       unmapped_action=ESMF.UnmappedAction.ERROR,
                       dst_mask_values=None)

#=======================================================================
# 3D interpolation of one variable (time, level, latitude, longitude) to 
# time series output for LocStreams, elevation as given by LocStream
#=======================================================================

# Add a 3rd dimension to the LocStream (it is now considered a 3D object for regridding purposes)
locstream["ESMF:Radius"] = [float(e['elevation_m']) for e in points]

# file to read
file_pl = "era_pl.nc"

#list variables that should be interpolated
variables = ["t","r","z","u","v"]

# open netcdf file handle
n3D = nc.Dataset(file_pl, 'r')

# get dimensions
time = n3D.variables['time'][:]
lev  = n3D.variables['level'][:]
lat  = n3D.variables['latitude'][:]
lon  = n3D.variables['longitude'][:]

# create a uniform global latlon grid from a SCRIP formatted file
srcg3D = ESMF.Grid(filename=file_pl, filetype=ESMF.FileFormat.GRIDSPEC)

# create an intermediate "fixed" pressure level 3D Grid to use when interpolating to a 3D LocStream
fixg3D = ESMF.Grid(max_index=np.array([len(lon), len(lat), len(lev)]), staggerloc=ESMF.StaggerLoc.CENTER_VCENTER)

fixg3D_lon = fixg3D.get_coords(0)
fixg3D_lat = fixg3D.get_coords(0)
fixg3D_lev = fixg3D.get_coords(0)

xx, yy, zz = np.meshgrid(lon, lat, lev)

fixg3D_lon[:] = xx
fixg3D_lat[:] = yy
fixg3D_lev[:] = zz

# create a field on the center stagger locations of the source grid
srcf3D = ESMF.Field(fixg3D, name='srcf3D',
                      staggerloc=ESMF.StaggerLoc.CENTER_VCENTER,
                      ndbounds=[len(variables), len(time)])

# assign data from ncdf: (variale, time, level, latitude, longitude) 
for n, var in enumerate(variables):
    for t in range(len(time)):
        for l in range(len(lev)):
            srcf3D.data[n,t,:,:,l] = n3D.variables[var][t,l,:,:]

# create destination field
# npoint = len(locstream["ESMF:Lon"])
# dstf3D = ESMF.Field(locstream, name='dstf3D')
#dstf3D.data = np.empty([len(variables), len(time), len(lev), npoint])
dstf3D = ESMF.Field(locstream, name='dstf3D',
                    ndbounds=[len(variables), len(time)])


# NOTE: this regridding operation fails with an error about unmapped destination points
#       I believe this is due to the fact that the LocStream radius is below the
#       minimum pressure level (outside the domain of the 3D Grid).
# get regridding
regrid3D = ESMF.Regrid(srcf3D, dstf3D,
                      regrid_method=ESMF.RegridMethod.BILINEAR,
                      unmapped_action=ESMF.UnmappedAction.ERROR,
                      dst_mask_values=None)

