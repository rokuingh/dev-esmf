
import numpy as np
np.set_printoptions(threshold=np.nan)
import matplotlib.pyplot as plt
import ESMF


def esmf_grid(lon, lat):
    '''
    Create an ESMF.Grid object, for contrusting ESMF.Field and ESMF.Regrid
    '''
    staggerloc = ESMF.StaggerLoc.CENTER
    
    grid = ESMF.Grid(np.array(lon.shape), staggerloc=staggerloc,
                     coord_sys=ESMF.CoordSys.SPH_DEG)
    lon_pointer = grid.get_coords(coord_dim=0, staggerloc=staggerloc)
    lat_pointer = grid.get_coords(coord_dim=1, staggerloc=staggerloc)

    lon_pointer[...] = lon
    lat_pointer[...] = lat

    return grid

def add_corner(grid, lon_b, lat_b):
    '''
    Add corner information to ESMF.Grid for conservative regridding.
    '''
    staggerloc = ESMF.StaggerLoc.CORNER 
    
    grid.add_coords(staggerloc=staggerloc)
    lon_b_pointer = grid.get_coords(coord_dim=0, staggerloc=staggerloc)
    lat_b_pointer = grid.get_coords(coord_dim=1, staggerloc=staggerloc)

    lon_b_pointer[...] = lon_b
    lat_b_pointer[...] = lat_b


# cell centers
lon_in, lat_in = np.meshgrid(np.linspace(-20, 20, 5), np.linspace(-15, 15, 4))
# cell bounds
lon_in_b, lat_in_b = np.meshgrid(np.linspace(-25, 25, 6), np.linspace(-20, 20, 5))

# stretch the grid in diagonal direction?
# Switch to False will remove the bug
stretch = True
if stretch:
    lon_in += lat_in  
    lat_in += lon_in
    lon_in_b += lat_in_b
    lat_in_b += lon_in_b

data = np.arange(20).reshape(4, 5) # a boring data

plot = False

if plot:
    plt.pcolormesh(lon_in, lat_in, data)
    plt.scatter(lon_in, lat_in, label='cell center')
    plt.legend()
    plt.title('input data and grid')
    plt.show()

lon_out_b = np.linspace(-50, 50, 51)
lon_out = 0.5*(lon_out_b[1:]+lon_out_b[:-1])

lat_out_b = np.linspace(-80, 80, 51)
lat_out = 0.5*(lat_out_b[1:]+lat_out_b[:-1])

# 1D -> 2D
lon_out, lat_out = np.meshgrid(lon_out, lat_out)
lon_out_b, lat_out_b = np.meshgrid(lon_out_b, lat_out_b)

# make ESMF.Grid object

grid_in = esmf_grid(lon_in, lat_in)
add_corner(grid_in, lon_in_b, lat_in_b)

grid_out = esmf_grid(lon_out, lat_out)
add_corner(grid_out, lon_out_b, lat_out_b)

# make ESMF.Regrid object

sourcefield = ESMF.Field(grid_in)
destfield = ESMF.Field(grid_out)
xctfield = ESMF.Field(grid_out)
# 
# regrid = ESMF.Regrid(sourcefield, destfield, 
#                      regrid_method=ESMF.RegridMethod.BILINEAR,
#                      unmapped_action=ESMF.UnmappedAction.IGNORE)

# Apply regridding

# sourcefield.data[...] = data
# destfield = regrid(sourcefield, destfield)
# data_out = destfield.data

# if plot:
#     plt.pcolormesh(lon_out_b, lat_out_b, data_out)
#     plt.show()



# make ESMF.Regrid object
regrid_con = ESMF.Regrid(sourcefield, destfield, 
                        regrid_method=ESMF.RegridMethod.CONSERVE,
                        line_type=ESMF.LineType.GREAT_CIRCLE,
                        unmapped_action=ESMF.UnmappedAction.IGNORE)

# Apply regridding
sourcefield.data[...] = data
destfield = regrid_con(sourcefield, destfield)
data_out_con = destfield.data

plot = True
if plot:

    fig = plt.figure(1, (15, 6))
    fig.suptitle('ESMPy Regridding', fontsize=14, fontweight='bold')
    
    ax = fig.add_subplot(1, 2, 1)
    im = ax.imshow(sourcefield.data, vmin=0, vmax=np.max(sourcefield.data), cmap='gist_ncar', aspect='auto',
                extent=[np.min(lon_in), np.max(lon_in), np.min(lat_in), np.max(lat_in)])
    ax.set_xbound(lower=np.min(lon_in), upper=np.max(lon_in))
    ax.set_ybound(lower=np.min(lat_in), upper=np.max(lat_in))
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Source Data")
    
    ax = fig.add_subplot(1, 2, 2)
    im = ax.imshow(destfield.data, vmin=0, vmax=np.max(destfield.data), cmap='gist_ncar', aspect='auto',
                extent=[np.min(lon_out), np.max(lon_out), np.min(lat_out), np.max(lat_out)])
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.set_title("Regrid Solution")
    
    fig.subplots_adjust(right=0.8)
    cbar_ax = fig.add_axes([0.9, 0.1, 0.01, 0.8])
    fig.colorbar(im, cax=cbar_ax)
    
    plt.show()
