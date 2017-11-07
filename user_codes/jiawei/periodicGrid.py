
import numpy as np
import matplotlib.pyplot as plt
import ESMF

lon_in = np.arange(-175, 175.1, 10)
lat_in = np.arange(-88, 88.1, 4)
# lon_in_corner = np.arange(-180, 180, 10)
# lat_in_corner = np.arange(-90, 90.1, 4)

lon_out = np.arange(-177.5, 177.5 + 0.1, 5)
lat_out = np.arange(-88, 88.1, 4)
# lon_out_corner = np.arange(-180, 180, 5)
# lat_out_corner = np.arange(-90, 90.1, 4)

sourcegrid = ESMF.Grid(np.array([lon_in.size, lat_in.size]), 
                       staggerloc = [ESMF.StaggerLoc.CENTER],#, ESMF.StaggerLoc.CORNER],
                       coord_sys = ESMF.CoordSys.SPH_DEG,
                       num_peri_dims = 1)

source_lon = sourcegrid.get_coords(0)
source_lat = sourcegrid.get_coords(1)
#source_lon_corner = sourcegrid.get_coords(0, staggerloc=ESMF.StaggerLoc.CORNER)
#source_lat_corner = sourcegrid.get_coords(1, staggerloc=ESMF.StaggerLoc.CORNER)

source_lon[...], source_lat[...] = np.meshgrid(lon_in, lat_in, indexing='ij')
#source_lon_corner[...], source_lat_corner[...] = np.meshgrid(lon_in_corner, lat_in_corner, indexing='ij')

destgrid = ESMF.Grid(np.array([lon_out.size, lat_out.size]), 
                       staggerloc = [ESMF.StaggerLoc.CENTER],#, ESMF.StaggerLoc.CORNER],
                       coord_sys = ESMF.CoordSys.SPH_DEG,
                       num_peri_dims = 1)


dest_lon = destgrid.get_coords(0)
dest_lat = destgrid.get_coords(1)
#dest_lon_corner = destgrid.get_coords(0, staggerloc=ESMF.StaggerLoc.CORNER)
#dest_lat_corner = destgrid.get_coords(1, staggerloc=ESMF.StaggerLoc.CORNER)

dest_lon[...], dest_lat[...] = np.meshgrid(lon_out, lat_out, indexing='ij')
#dest_lon_corner[...], dest_lat_corner[...] = np.meshgrid(lon_out_corner, lat_out_corner, indexing='ij')

sourcefield = ESMF.Field(sourcegrid)
destfield = ESMF.Field(destgrid)

sourcefield.data[:] = 0

regrid_bi = ESMF.Regrid(sourcefield, destfield, 
                        regrid_method = ESMF.RegridMethod.BILINEAR,
                        unmapped_action = ESMF.UnmappedAction.ERROR)

wave = lambda x,k:  np.sin(x*k*np.pi/180.0)
sourcefield.data[...] = np.outer(wave(lon_in,3), wave(lat_in,3)) + 1

destfield = regrid_bi(sourcefield, destfield)

# import ipdb; ipdb.set_trace()

fig = plt.figure(1, (15, 6))
fig.suptitle('ESMPy Periodic Grids', fontsize=14, fontweight='bold')

ax = fig.add_subplot(1, 2, 1)
im = ax.imshow(sourcefield.data, vmin=0, vmax=2, cmap='gist_ncar', aspect='auto',
               extent=[min(lon_in), max(lon_in), min(lat_in), max(lat_in)])
ax.set_xbound(lower=min(lon_in), upper=max(lon_in))
ax.set_ybound(lower=min(lat_in), upper=max(lat_in))
ax.set_xlabel("Longitude")
ax.set_ylabel("Latitude")
ax.set_title("Source Data")

ax = fig.add_subplot(1, 2, 2)
im = ax.imshow(destfield.data, vmin=0, vmax=2, cmap='gist_ncar', aspect='auto',
               extent=[min(lon_out), max(lon_out), min(lat_out), max(lat_out)])
ax.set_xlabel("Longitude")
ax.set_ylabel("Latitude")
ax.set_title("Regrid Solution")

fig.subplots_adjust(right=0.8)
cbar_ax = fig.add_axes([0.9, 0.1, 0.01, 0.8])
fig.colorbar(im, cax=cbar_ax)

plt.show()