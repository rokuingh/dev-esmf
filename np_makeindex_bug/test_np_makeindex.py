# test a possible numpy versioning issue in ESMP

def test_makeindex():
    import numpy as np

    def make_index_3d(nx, ny, nz):
        '''
        Return an array, of size (nz, ny, nx) that is
        an index, ie runs from 0 to (nx*ny*nz)-1
        '''

        return np.arange(nx * ny * nz).reshape(nz, ny, nx)

    print "numpy version {0}".format(np.__version__)

    [i, j, k] = [2, 2, 2]

    pts = make_index_3d(i, j, k)

    array = np.empty(i * j * k)

    for i0 in range(i):
        array[pts[:, :, i0]] = float(i0)

    for i0 in range(i):
        assert ((array[pts[:, :, i0]] == float(i0)).all())
