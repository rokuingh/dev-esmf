# test a possible numpy versioning issue in ESMP

def make_index_3d( nx, ny, nz ):
    '''
    Return an array, of size (nz, ny, nx) that is
    an index, ie runs from 0 to (nx*ny*nz)-1
    '''
    import numpy as np

    return np.arange( nx*ny*nz ).reshape( nz, ny, nx )


def test_makeindex():

    import numpy as np

    print np.__version__

    [x,y,z] = [0,1,2]

    [i,j,k] = [2,2,2]

    pts = make_index_3d(i,j,k)

    Xarray = np.empty(i * j * k)
    Yarray = np.empty(i * j * k)
    Zarray = np.empty(i * j * k)

    for i0 in range(i):
        Xarray[pts[i0, :, :]] = float(i0)

    # for i1 in range(j):
    #     Yarray[pts[:, i1, :]] = float(i1)
    #
    # for i2 in range(k):
    #     Zarray[pts[i2, :, :]] = float(i2)

    correct = True
    for i0 in range(i):
        if (Xarray[pts[i0, :, :]] != float(i0)).any():
            correct = False
            print "FAIL - Xarray[:,:," + str(i0) + "] = " + str(Xarray[pts[i0, :, :]])

    # for i1 in range(j):
    #     if (Yarray[pts[:, i1, :]] != float(i1)).any():
    #         correct = False
    #         print "FAIL - Yarray[:," + str(i1) + ",:] = " + str(Yarray[pts[:, i1, :]])
    #
    # for i2 in range(k):
    #     if (Zarray[pts[i2, :, :]] != float(i2)).any():
    #         correct = False
    #         print "FAIL - Zarray[" + str(i2) + ",:,:] = " + str(Zarray[pts[i2, :, :]])


    assert(correct)



