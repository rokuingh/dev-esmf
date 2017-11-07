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
locstream["ESMF:Radius"] = [float(e['elevation_m']) for e in points]


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
npoint = len(locstream["ESMF:Lon"])
dstf2D = ESMF.Field(locstream, name='dstf2D')
#dstf2D.data = np.empty([len(variables), len(time), npoint])

# get regridding
#regrid2D = ESMF.Regrid(srcf2D, dstf2D,
#                       regrid_method=ESMF.RegridMethod.BILINEAR,
#                       unmapped_action=ESMF.UnmappedAction.ERROR,
#                       dst_mask_values=None)

#=======================================================================
# 3D interpolation of one variable (time, level, latitude, longitude) to 
# time series output for LocStreams, elevation as given by LocStream
#=======================================================================


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

# create a field on the center stagger locations of the source grid
srcf3D = ESMF.Field(srcg3D, name='srcf3D',
                      staggerloc=ESMF.StaggerLoc.CENTER,
                      ndbounds=[len(variables), len(time), len(lev)])

# assign data from ncdf: (variale, time, level, latitude, longitude) 
for n, var in enumerate(variables):	
	srcf3D.data[n,:,:,:,:] = n3D.variables[var][:,:,:,:]

# create destination field
npoint = len(locstream["ESMF:Lon"])
dstf3D = ESMF.Field(locstream, name='dstf3D')
#dstf3D.data = np.empty([len(variables), len(time), len(lev), npoint])

# get regridding
#regrid3D = ESMF.Regrid(srcf3D, dstf3D,
#                       regrid_method=ESMF.RegridMethod.BILINEAR,
#                       unmapped_action=ESMF.UnmappedAction.ERROR,
#                       dst_mask_values=None)
