from copy import deepcopy

import ocgis
from ocgis import GeometryVariable, VariableCollection
from shapely.geometry import box

dat = [["ll1280x1280_grid.esmf.nc", [-121.2, 59.7, -120.1, 60.5], "ll1280x1280_grid.esmf.sub.bwk.nc"],
       ["tx0.1v2_nomask.esmf.nc", [-121, 59.9, -120.3, 60.3], "tx0.1v2_nomask.esmf.sub.bwk.nc"]]

# for a box around point 4323801 at 270.000000000024      ,    1.89967885786903
dat = [["ll1280x1280_grid.esmf.nc", [269.9, 1.7, 270.2, 2.0], "ll1280x1280.esmf.sub.nc"],
       ["tx0.1v2_nomask.esmf.nc", [270, 1.8, 270.1, 1.9], "tx0.1v2.esmf.sub.nc"]]

for i  in range(len(dat)):
    PATH_IN = dat[i][0]
    PATH_OUT = dat[i][2]
    poly = box(*dat[i][1])

    rd = ocgis.RequestDataset(PATH_IN,  driver='netcdf-esmf-unstruct', crs=ocgis.crs.Spherical(), grid_is_isomorphic=True,
                              grid_abstraction='point')
    field = rd.create_field()
    subfield = deepcopy(field)
    grid = field.grid
    print('grid wrapped state:', grid.wrapped_state)

    gvar = GeometryVariable(name="geom", value=poly, is_bbox=True, ugid=1, dimensions="ngeom", crs=ocgis.crs.Spherical())
    gvar.unwrap()
    print('geometry wrapped state:', gvar.wrapped_state)
    print('geometry extent:', gvar.extent)

    print('grid shape before:', grid.shape)
    print('grid extent before:', grid.extent)
    print('grid.x:', grid.x.v())
    print('grid.y:', grid.y.v())
    sub, slc = grid.get_intersects(gvar, optimized_bbox_subset=True, return_slice=True)
    # sub.reduce_global()
    print('grid shape after:', sub.shape)
    vc = VariableCollection(variables=subfield.values(), force=True)
    vcsub = vc[{'elementCount': slc}]
    print(vcsub.shapes)
    vcsub.write(PATH_OUT)
