import numpy as np
import xarray as xr
import ESMF
import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature

# Test script to read the global WOA oxygen climatology (12 monthly timesteps, 57 depths) dataset and interpolate / regrid to
# a higher resolution grid for a segment of the West Coast of the US. The interpolation is done in 3D for each timestep. The result is
# weird.

def grid_create_from_coordinates_3d(xcoords, ycoords, zcoords, xcorners=False, ycorners=False, zcorners=False,
                                    corners=False, domask=False, doarea=False):
    """
    Create a 3 dimensional Grid using the xcoordinates, ycoordinates and zcoordinates.
    :param xcoords: The 1st dimension or 'x' coordinates at cell centers, as a Python list or numpy Array
    :param ycoords: The 2nd dimension or 'y' coordinates at cell centers, as a Python list or numpy Array
    :param zcoords: The 3rd dimension or 'z' coordinates at cell centers, as a Python list or numpy Array
    :param xcorners: The 1st dimension or 'x' coordinates at cell corners, as a Python list or numpy Array
    :param ycorners: The 2nd dimension or 'y' coordinates at cell corners, as a Python list or numpy Array
    :param zcorners: The 3rd dimension or 'z' coordinates at cell corners, as a Python list or numpy Array
    :param corners: boolean to determine whether or not to add corner coordinates to this grid
    :param domask: boolean to determine whether to set an arbitrary mask or not
    :param doarea: boolean to determine whether to set an arbitrary area values or not
    :return: grid
    """
    [x, y, z] = [0, 1, 2]

    # create a grid given the number of grid cells in each dimension, the center stagger location is allocated and the
    # Cartesian coordinate system is specified
    max_index = np.array([len(xcoords), len(ycoords), len(zcoords)])
    grid = ESMF.Grid(max_index, staggerloc=[ESMF.StaggerLoc.CENTER_VCENTER], coord_sys=ESMF.CoordSys.CART)

    # set the grid coordinates using numpy arrays, parallel case is handled using grid bounds
    gridXCenter = grid.get_coords(x)
    x_par = xcoords[
            grid.lower_bounds[ESMF.StaggerLoc.CENTER_VCENTER][x]:grid.upper_bounds[ESMF.StaggerLoc.CENTER_VCENTER][
                x]]
    gridXCenter[...] = x_par.reshape(x_par.size, 1, 1)

    gridYCenter = grid.get_coords(y)
    y_par = ycoords[
            grid.lower_bounds[ESMF.StaggerLoc.CENTER_VCENTER][y]:grid.upper_bounds[ESMF.StaggerLoc.CENTER_VCENTER][
                y]]
    gridYCenter[...] = y_par.reshape(1, y_par.size, 1)

    gridZCenter = grid.get_coords(z)
    z_par = zcoords[
            grid.lower_bounds[ESMF.StaggerLoc.CENTER_VCENTER][z]:grid.upper_bounds[ESMF.StaggerLoc.CENTER_VCENTER][
                z]]
    gridZCenter[...] = z_par.reshape(1, 1, z_par.size)

    # create grid corners in a slightly different manner to account for the bounds format common in CF-like files
    if corners:
        grid.add_coords([ESMF.StaggerLoc.CORNER_VFACE])
        lbx = grid.lower_bounds[ESMF.StaggerLoc.CORNER_VFACE][x]
        ubx = grid.upper_bounds[ESMF.StaggerLoc.CORNER_VFACE][x]
        lby = grid.lower_bounds[ESMF.StaggerLoc.CORNER_VFACE][y]
        uby = grid.upper_bounds[ESMF.StaggerLoc.CORNER_VFACE][y]
        lbz = grid.lower_bounds[ESMF.StaggerLoc.CORNER_VFACE][z]
        ubz = grid.upper_bounds[ESMF.StaggerLoc.CORNER_VFACE][z]

        gridXCorner = grid.get_coords(x, staggerloc=ESMF.StaggerLoc.CORNER_VFACE)
        for i0 in range(ubx - lbx - 1):
            gridXCorner[i0, :, :] = xcorners[i0 + lbx, 0]
        gridXCorner[i0 + 1, :, :] = xcorners[i0 + lbx, 1]

        gridYCorner = grid.get_coords(y, staggerloc=ESMF.StaggerLoc.CORNER_VFACE)
        for i1 in range(uby - lby - 1):
            gridYCorner[:, i1, :] = ycorners[i1 + lby, 0]
        gridYCorner[:, i1 + 1, :] = ycorners[i1 + lby, 1]

        gridZCorner = grid.get_coords(z, staggerloc=ESMF.StaggerLoc.CORNER_VFACE)
        for i2 in range(ubz - lbz - 1):
            gridZCorner[:, :, i2] = zcorners[i2 + lbz, 0]
        gridZCorner[:, :, i2 + 1] = zcorners[i2 + lbz, 1]

    # add an arbitrary mask
    if domask:
        mask = grid.add_item(ESMF.GridItem.MASK)
        mask[:] = 1
        mask[np.where((1.75 < gridXCenter.data < 2.25) &
                      (1.75 < gridYCenter.data < 2.25) &
                      (1.75 < gridZCenter.data < 2.25))] = 0

    # add arbitrary areas values
    if doarea:
        area = grid.add_item(ESMF.GridItem.AREA)
        area[:] = 5.0

    return grid


def setup_source_and_destination_3D_grids(woa_ds: xr.Dataset, glorys12v1_ds: xr.Dataset):
    woa_grid = grid_create_from_coordinates_3d(woa_ds.lon.values, woa_ds.lat.values, woa_ds.depth.values, )
    glorys12v1_grid = grid_create_from_coordinates_3d(glorys12v1_ds.longitude.values,
                                                      glorys12v1_ds.latitude.values,
                                                      glorys12v1_ds.depth.values)

    srcfield = ESMF.Field(woa_grid, name="srcfield", staggerloc=ESMF.StaggerLoc.CENTER, ndbounds=[12])
    dstfield = ESMF.Field(glorys12v1_grid, name="dstfield", staggerloc=ESMF.StaggerLoc.CENTER, ndbounds=[12])
    xctfield = ESMF.Field(glorys12v1_grid, name="xctfield", staggerloc=ESMF.StaggerLoc.CENTER, ndbounds=[12])

    return woa_grid, glorys12v1_grid, srcfield, dstfield, xctfield


def setup_ESMF_weights(srcfield, dstfield, mg):
    # write regridding weights to file
    filename = "esmpy_weight_file.nc"
    if ESMF.local_pet() == 0:
        import os
        if os.path.isfile(
                os.path.join(os.getcwd(), filename)):
            os.remove(os.path.join(os.getcwd(), filename))

    mg.barrier()
    # regrid = ESMF.Regrid(srcfield, dstfield,  # filename=filename,
    #                      regrid_method=ESMF.RegridMethod.BILINEAR,
    #                      unmapped_action=ESMF.UnmappedAction.IGNORE)

    regrid = ESMF.Regrid(srcfield, dstfield,  # filename=filename,
                         regrid_method=ESMF.RegridMethod.BILINEAR,
                         unmapped_action=ESMF.UnmappedAction.IGNORE,
                         # this is the simpler option
                         # extrap_method=ESMF.ExtrapMethod.NEAREST_STOD)
                         # this is the more complex option
                         extrap_method=ESMF.ExtrapMethod.NEAREST_IDAVG,
                         extrap_num_src_pnts=7,
                         extrap_dist_exponent=3.0)

    # # create a regrid object from file
    # regrid = ESMF.RegridFromFile(srcfield, dstfield, filename)
    return regrid


def interpolate_from_woa_to_glorys12v1_grids(glorys12v1_ds: xr.Dataset, woa_ds: xr.Dataset):
    mg = ESMF.Manager(debug=True)

    woa_grid, glorys12v1_grid, srcfield, dstfield, xctfield = setup_source_and_destination_3D_grids(woa_ds,
                                                                                                    glorys12v1_ds)

    regrid = setup_ESMF_weights(srcfield, dstfield, mg)
    dstfield.data[:] = 1e20

    woa_ds_transposed = woa_ds.transpose('lon', 'lat', 'depth', 'time')
    print(woa_ds_transposed.head())

    # import ipdb; ipdb.set_trace()
   # srclonm, srclatm = np.meshgrid(woa_ds.lon.values, woa_ds.lat.values, indexing='ij')
   # dstlonm, dstlatm = np.meshgrid(glorys12v1_ds.longitude.values, glorys12v1_ds.latitude.values, indexing='ij')

    # *(lval+tval+1)
    """
    deg2rad = 3.14159 / 180
    for level, lval in enumerate(woa_ds.depth.values):
        for timestep, tval in enumerate(woa_ds.time.values):
            srcfield.data[:, :, level, timestep] = 10.0 + \
                                                   (srclonm * deg2rad) ** 2 + (srclonm * deg2rad) * (
                                                               srclatm * deg2rad) + \
                                                   (srclatm * deg2rad) ** 2

    for level, lval in enumerate(glorys12v1_ds.depth.values):
        for timestep, tval in enumerate(woa_ds.time.values):
            xctfield.data[..., level, timestep] = 10.0 + \
                                                  (dstlonm * deg2rad) ** 2 + (dstlonm * deg2rad) * (dstlatm * deg2rad) + \
                                                  (dstlatm * deg2rad) ** 2

    dstfield = regrid(srcfield, dstfield)

    # compute the mean relative interpolation error
    from operator import mul
    num_nodes = np.prod(xctfield.data.shape[:])
    relerr = 0
    meanrelerr = 0

    if num_nodes != 0:
        ind = np.where((dstfield.data != 1e20) & (xctfield.data != 0))
        relerr = np.sum(np.abs(dstfield.data[ind] - xctfield.data[ind]) / np.abs(xctfield.data[ind]))
        meanrelerr = relerr / num_nodes

    print("Mean relative interpolation error = ", meanrelerr)
    """
    # import ipdb;
    # ipdb.set_trace()

    srcfield.data[:, :, :, :] = woa_ds_transposed["o_an"].values
    dstfield = regrid(srcfield, dstfield)
    d2 = np.moveaxis(dstfield.data, -1, 0)
    final_array = d2 * 0.0229  # convert micromole O2/kg to ml/L

    coords = {
        "time": woa_ds.time,
        "longitude": glorys12v1_ds.longitude.values,
        "latitude": glorys12v1_ds.latitude.values,
        "depth": glorys12v1_ds.depth.values,
    }
    xarr = xr.DataArray(
        name="oxygen_interp",
        data=final_array,
        coords=coords,
        dims=["time", "longitude", "latitude", "depth"]
    )
    xarr.to_netcdf("test_to_file.nc")
    print(xarr)
    plot_monthly_climatology(xarr)


def plot_monthly_climatology(climatology):
    # monthly - climatology
    months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
    ]

    lev = np.arange(5,7, 0.2)

    fig = plt.figure(figsize=(12, 12), dpi=150)
    for i in range(12):
        ax = fig.add_subplot(3, 4, i + 1, projection=ccrs.PlateCarree())
        land_10m = cfeature.NaturalEarthFeature('physical', 'land', '10m')
        ax.add_feature(land_10m, color="lightgrey", edgecolor="black")
        ax.coastlines(resolution='10m', linewidth=1.5, color='black', alpha=0.8, zorder=4)

        mydata = np.squeeze(climatology[i, :, :, 0].values).T
        print("shape of mydata : {} and mean : {}".format(np.shape(mydata),np.nanmean(mydata)))
        ax.contourf(
            climatology.longitude.values,
            climatology.latitude.values,
            mydata,
            levels=lev,
            cmap="RdBu_r",
            zorder=2,
            alpha=0.9,
            extend="both", transform=ccrs.PlateCarree())
      #  plt.colorbar(
      #      fraction=0.03,
      #      orientation="horizontal",
      #      ticks=[*range(int(lev[0]), int(lev[-1]) + 1, 2)]
      #  )
        plt.title(months[i])

    plt.tight_layout(h_pad=1)

    plotfile = "test_oxygen_monthly_clim_GLORYS12V1.png"
    plt.savefig(plotfile, dpi=150)
    plt.show()


woa_ds = xr.open_dataset("test_data/woa_test.nc", decode_times=False)
glorys12v1_ds = xr.open_dataset("test_data/glorys12v1_test.nc")
print(woa_ds)
interpolate_from_woa_to_glorys12v1_grids(glorys12v1_ds, woa_ds)
