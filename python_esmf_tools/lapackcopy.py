import os, re
from shutil import copyfile

blas = True

# LAPACK
files = ["dgeev", "dgehrd", "dtrevc3", "dgebal", "dhseqr", "dorghr", "dgebak",
         "dgehd2", "dlahqr", "dlahr2", "dlaln2", "dlaqr0", "dorgqr",
         "dorg2r", "dlanv2", "dladiv", "dlaqr5", "dlaqr4", "dlaqr3",
         "dtrexc", "dormhr", "dlaqr2", "dlaqr1",
         "dlaexc",
         "dlarfx", "dlasy2",
         "dlansy", "dsterf", "dstedc", "dsytrd", "dormtr",
         "dlae2", "dlatrd", "dsytd2", "dormql", "dsteqr", "dlaed0",
         "dlaev2", "dorm2l", "dlaed1", "dlaed7",
         "dlaed8", "dlaed9", "dlaed3", "dlaeda", "dlaed2",
         "dlaed4", "dlaed5"]

# BLAS
if blas:
    files = ["dsyr2k", "dsyr2", "dsymv"]

for file in files:
    print("#define "+file.upper()+" ESMF_"+file.upper())

# SRC = "/home/ryan/sandbox/lapack-3.8.0/SRC"
# if blas:
#     SRC = "/home/ryan/sandbox/lapack-3.8.0/BLAS/SRC"
# 
# DST = "/home/ryan/sandbox/esmf/src/Infrastructure/Mesh/src/Lapack/"
# if blas:
#     DST = "/home/ryan/sandbox/esmf/src/Infrastructure/Mesh/src/BLAS/"
# 
# for file in files:
#     srcfile = os.path.join(SRC, file)+".f"
#     dstfile = os.path.join(DST, file)+".F90"
#     # copyfile(srcfile, dstfile)
# 
#     with open(srcfile, 'r') as fd:
#         contents = fd.read()
# 
#     header = "#include \"ESMF_LapackBlas.inc\"\n"
#     contents = header + contents
# 
#     # newcontents = contents.replace("\n\*", "\n!")
#     # new2contents = newcontents.replace("\n     \$", " &\n      ")
# 
#     contents = re.sub("\n\*", "\n!", contents)
#     contents = re.sub("\n     \$", " &\n      ", contents)
#     # if blas:
#     #     contents = re.sub("\n     \+", " &\n      ", contents)
# 
#     with open(dstfile, 'w') as fd:
#         fd.write(contents)
# 
#     print ("processed "+file)
