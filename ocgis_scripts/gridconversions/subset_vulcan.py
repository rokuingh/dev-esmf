import ocgis

PATH_IN = "/software/co2flux/Saved_WRF_runs/reversed_vulcan_fossilCO2_ioapi.nc"
PATH_OUT = '/software/co2flux/Saved_WRF_runs/subset_reversed_vulcan_fossilCO2_ioapi.nc'
PATH_IN = 'data/reversed_vulcan_fossilCO2_ioapi.nc'
PATH_OUT = 'data/subset_reversed_vulcan_fossilCO2_ioapi.nc'

rd = ocgis.RequestDataset(PATH_IN)
vc = rd.get_variable_collection()

oo = ocgis.OcgOperations(dataset=rd, geom=[-125, 35, -119, 40], output_format='nc',
                         prefix=PATH_OUT)
res = oo.execute()
