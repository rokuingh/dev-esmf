########Use of module to do resolution downscaling

import os
from netCDF4 import Dataset
os.chdir('/Users/gao/Desktop/esmpy regridding/')

#Import self designed module
from regridding import gregrid

src, dst = gregrid(
        srcfile = 'pr_Amon_GFDL-CM3_rcp45_r1i1p1_200601-230012.nc',
        dstfile = 'test.nc', 
                   variable = 'pr', latres = 2.5, lonres = 2.5)




