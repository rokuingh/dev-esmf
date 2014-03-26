from ocgis import OcgOperations, RequestDataset, RequestDatasetCollection, env
import os.path


## Directory holding climate data.
DATA_DIR = '/Users/ryan.okuinghttons/netCDFfiles/climate_data/'
## Filename to variable name mapping.
NCS = 'tas_day_CanCM4_decadal2000_r2i1p1_20010101-20101231.nc'
	   #'tasmin_day_CanCM4_decadal2000_r2i1p1_20010101-20101231.nc':'tasmin',
       #'tas_day_CanCM4_decadal2000_r2i1p1_20010101-20101231.nc':'tas',
       #'tasmax_day_CanCM4_decadal2000_r2i1p1_20010101-20101231.nc':'tasmax'}
## Always start with a snippet.
SNIPPET = True
## Data returns will overwrite in this case. Use with caution!!
env.OVERWRITE = True

env.DIR_SHPCABINET = '/Users/ryan.okuinghttons/netCDFfiles/shapefiles/ocgis_data/shp'

## RequestDatasetCollection ####################################################

rdc = RequestDatasetCollection([RequestDataset(os.path.join(DATA_DIR,NCS),'tas')])

## Return In-Memory ############################################################

## Data is returned as a dictionary with 51 keys (don't forget Puerto Rico...).
## A key in the returned dictionary corresponds to a geometry "ugid" with the
## value of type OcgCollection.
print('returning numpy...')
ops = OcgOperations(dataset=rdc,spatial_operation='clip',aggregate=True,
                    snippet=SNIPPET,geom='state_boundaries')
path = ops.execute()

## Write to Shapefile ##########################################################

print('returning shapefile...')
ops = OcgOperations(dataset=rdc,spatial_operation='clip',aggregate=True,
                    snippet=SNIPPET,geom='state_boundaries',output_format='shp')
path = ops.execute()

## Write All Data to Keyed Format ##############################################

## Without the snippet, we are writing all data to the linked CSV-Shapefile
## output format. The operation will take considerably longer.
print('returning csv+...')
ops = OcgOperations(dataset=rdc,spatial_operation='clip',aggregate=True,
                    snippet=False,geom='state_boundaries',output_format='csv+')
path = ops.execute()