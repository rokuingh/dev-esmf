#!/usr/bin/env python

###############################################################################
#
#  Harvest the interface changes from the html version of the reference manual
#  from two different tags and then diff them to make a report.
#
#  This script depends on a Python package called Fabric, this can be downloaded
#  using:
#
#  pip install fabric
#
#  The script is run with the following command:
#
#  fab harvestInterfaceChanges:<esmf_dir>,<tag1>,<tag2>
#
#  The interface changes report is returned to the execution directory with the
#  name:
#
#  diff-<tag1>-<tag2>.out
#
#  The env.hosts, env.user and env.password variables may need to be changed.

###############################################################################

from fabric.context_managers import cd, shell_env
from fabric.decorators import task
from fabric.operations import run, get
from fabric.api import env, settings, prefix
from fabric.contrib.files import exists

env.hosts = ['pluto.esrl.svc']

env.user = "ryan.okuinghttons"
env.password = "password"


class FabricException(Exception):
    pass


@task
def harvestInterfaceChanges(esmfdir, tag1, tag2):
    output1 = "APIs-"+tag1+".out"
    output2 = "APIs-"+tag2+".out"
    diffile = "diff-"+tag1+"-"+tag2+".out"
    do(esmfdir, output1, tag1)
    do(esmfdir, output2, tag2)

    # and now on the local machine
    import os
    os.system("diff "+output1+" "+output2+" > "+diffile)


@task
# development run (only builds esmf and docs once)
def do(esmfdir, outputfile, tag):
    import os
    TAGDATADIR = tag + "_data"
    DRYDIR = os.path.join(run("pwd"), TAGDATADIR)

    # Build ESMF docs and move appropriate doc files for transfer to local
    if not exists(DRYDIR):
        build_esmf_docs(esmfdir, tag)
        dryrun(esmfdir, DRYDIR)
        clean_esmf(esmfdir)

    # transfer appropriate html doc files to local
    get(remote_path=DRYDIR, local_path=os.getcwd())

    # get local file names and parse them into outputfile
    files = gather_source_files_on_local(os.path.join(os.getcwd(), TAGDATADIR))
    parse(outputfile, files)
    clean_dry_dir(TAGDATADIR)


# build esmf docs
@task
def build_esmf_docs(esmfdir, tag):
    with cd(esmfdir):
        with shell_env(ESMF_DIR=esmfdir), \
             prefix("module load gfortran/4.7.2/gcc/4.7.2/gcc"), \
             settings(abort_exception=FabricException):
            run("git checkout master")
            run("git pull")
            run("git checkout tags/" + tag)
            run("make distclean > /dev/null 2>&1")
            try:
                run("make > temp.out 2>&1")
            except FabricException:
                run("tail -50 temp.out")
                run("rm temp.out")
            try:
                run("make doc > temp.out 2>&1")
            except FabricException:
                run("tail -50 temp.out")
                run("rm temp.out")
                raise RuntimeError


@task
def clean_esmf(esmfdir):
    with cd(esmfdir):
        with shell_env(ESMF_DIR=esmfdir):
            run("make distclean > /dev/null 2>&1")
            run("git checkout master")


@task
# gather html esmf doc files and put them in a temp directory
def dryrun(esmfdir, DRYDIR):
    files = gather_source_files(esmfdir)
    run("mkdir "+DRYDIR)
    for f in files:
        run("cp "+f+" "+DRYDIR)


@task
# pull together html files from esmf docs
def gather_source_files(esmfdir):
    import os
    REFDOCDIR = os.path.join(esmfdir, "doc/ESMF_refdoc")

    if not exists(REFDOCDIR):
        raise ValueError("Directory: " + REFDOCDIR + " was not found.  DING!")

    # have to get the files i want to search (all node*.html)
    files = []
    output = run("ls " + REFDOCDIR)
    listdir = output.split()
    for htmlfile in listdir:
        if 'node' in htmlfile:
            addfile = (os.path.join(REFDOCDIR, htmlfile))
            files.append(addfile)
    files.remove(os.path.join(REFDOCDIR, "footnode.html"))
    files.remove(os.path.join(REFDOCDIR, "node1.html"))
    files.remove(os.path.join(REFDOCDIR, "node2.html"))
    files.remove(os.path.join(REFDOCDIR, "node3.html"))

    # sort list and move 10 to after 9
    files.sort()
    files.append(files.pop(0))

    return files


def clean_dry_dir(tagdatadir):
    import os
    if os.path.exists(tagdatadir):
        os.system("rm -rf " + tagdatadir)


# gather html doc files and return names in a list on LOCAL
def gather_source_files_on_local(localdir):
    import os
    if not os.path.exists(localdir):
        raise ValueError("Directory: " + localdir + " was not found.  DING!")

    # have to get the files i want to search (all node*.html)
    files = []
    for htmlfile in os.listdir(localdir):
        files.append(os.path.join(localdir,htmlfile))

    # sort list and move 10 to after 9
    files.sort()
    files.append(files.pop(0))

    return files


def parse(outputfile, files):
    """
    This routine harvests the ESMF Fortran APIs from the html version of the
    reference manual and puts them in a file for text based searches (grep).

    :param outputfile: file name of harvested APIs
    :param files: sorted list of html files to parse
    """
    import re

    START = 'INTERFACE'
    END = 'DESCRIPTION'
    # END_NOARGS = ['ARGUMENTS', 'RETURN VALUE', 'PARAMETERS', 'DESCRIPTION']

    with open(outputfile, "w") as OUTFILE:
        writeline = ""
        # write all lines between START and END
        for f in files:
            flag = False
            with open(f) as infile:
                for line in infile:
                    # this is END for no arguments
                    # if any(enditer in line for enditer in END_NOARGS):
                    # this is END for with arguments
                    if END in line:
                        if flag:
                            OUTFILE.write("\n")
                        flag = False
                    # write the line
                    if flag:
                        OUTFILE.write(writeline+" "+line)
                    # get the section number
                    if re.search("\..*\..* ESMF.* - ",line) != None:
                        writeline = line.split(" ")[0]
                    # this is START
                    if START in line:
                        flag = True
