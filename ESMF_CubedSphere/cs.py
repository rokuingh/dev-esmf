import ESMF
cs_grid = ESMF.Grid(tilesize=6, name="cubed_sphere")
cs_lon = cs_grid.get_coords(0)
cs_lat = cs_grid.get_coords(1)
print str(ESMF.local_pet())+"    "+str(cs_lon)
print str(ESMF.local_pet())+"    "+str(cs_lat)
