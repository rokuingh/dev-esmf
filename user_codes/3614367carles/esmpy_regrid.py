#!/usr/bin/env python

from timeit import default_timer as gettime
import ESMF
import os
import mpi4py

from mpi4py import MPI
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()


def esmpy_regridding(out_grid_file, input_file_list, weight_matrix_file, create_weight_matrix=False):

    st_time = gettime()

    regrid = None

    src_grid = ESMF.Grid(filename=input_file_list[0]['path'], filetype=ESMF.FileFormat.GRIDSPEC, is_sphere=True,
                         add_corner_stagger=True)

    dst_grid = ESMF.Grid(filename=out_grid_file, filetype=ESMF.FileFormat.GRIDSPEC, is_sphere=True,
                         add_corner_stagger=True)

    if create_weight_matrix:
        print "Weight matrix is not created. Let's try to create it."
        src_field = ESMF.Field(src_grid, name='my input field')
        src_field.read(filename=input_file_list[0]['path'], variable=input_file_list[0]['name'], timeslice=0)

        dst_field = ESMF.Field(dst_grid, name=input_file_list[0]['name'])

        ESMF.Regrid(src_field, dst_field, filename=weight_matrix_file, regrid_method=ESMF.RegridMethod.CONSERVE, )
    else:

        dst_field_list = []
        count = 1
        for single_file in input_file_list:

            print '\t {0} {1}/{2}'.format(single_file['name'], count, len(input_file_list))
            count += 1

            var_time1 = gettime()

            src_field = ESMF.Field(src_grid, name='my input field')
            src_field.read(filename=single_file['path'], variable=single_file['name'], timeslice=0)
            var_time2 = gettime()

            dst_field = ESMF.Field(dst_grid, name=single_file['name'])

            if regrid is None:
                regrid = ESMF.RegridFromFile(src_field, dst_field, weight_matrix_file)
            var_time3 = gettime()
            dst_field = regrid(src_field, dst_field)

            dst_field_list.append(dst_field)

            print '\tTIME -> Regrid {4} Rank {0} Read {1} RegridFF {2} SparseMM {3} s\n'.format(rank, round(var_time2 - var_time1, 3), \
                round(var_time3 - var_time2, 3), round(gettime() - var_time3, 3), single_file['name'])
        print 'TIME -> ConservativeRegrid.start_esmpy_regridding: {0} s\n'.format(round(gettime() - st_time, 2))

        return dst_field_list

if __name__ == '__main__':
    tmp_out_netcdf = os.path.join('inputs', 'temporal_coords.nc')
    var_list = [
        'bc', 'co', 'nh3', 'nox_no2', 'oc', 'pm10', 'pm25', 'so2', 'voc02', 'voc03', 'voc04', 'voc05', 'voc06', 'voc07',
        'voc08', 'voc09', 'voc12', 'voc13', 'voc14', 'voc15', 'voc16', 'voc17', 'voc21', 'voc22', 'voc23']

    file_list = []
    for var in var_list:
        file_list.append({'name': var, 'path': os.path.join('inputs', '{0}_201001.nc'.format(var))})

    if not os.path.exists(os.path.join('inputs', 'WeightMatrix.nc')):
        esmpy_regridding(tmp_out_netcdf, file_list, os.path.join('inputs', 'WeightMatrix.nc'),
                         create_weight_matrix=True)
    esmpy_regridding(tmp_out_netcdf, file_list, os.path.join('inputs', 'WeightMatrix.nc'))
