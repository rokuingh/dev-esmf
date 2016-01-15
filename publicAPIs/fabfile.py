#!/usr/bin/env python

###############################################################################
#
#  Harvest the APIs from the html version of the reference manual from two
#  different tags and then diff them to make a report of the interface changes.
#
###############################################################################

# usage: fab harvestAPIs:<dir_of_esmf>,<tag_of_baseline>,<tag_of_new_release>

from fabric.context_managers import cd, shell_env
from fabric.decorators import task
from fabric.operations import run, get
from fabric.api import env
from fabric.contrib.files import exists

env.user = "ryan.okuinghttons"
env.hosts = ['pluto.esrl.svc']
env.password = "split(Y)ariposa(Y)allorca"

@task
def harvestAPIs(esmfdir, tag1, tag2):
    output1 = "APIs-"+tag1+".out"
    output2 = "APIs-"+tag2+".out"
    diffile = "diff-"+tag1+"-"+tag2+".out"
    do(esmfdir, output1, tag1)
    #do(esmfdir, output2, tag2)
    #run("diff "+output1+" "+output2+" > "+diffile)
    #get(diffile)

# normal run
@task
def do(esmfdir, outputfile, tag):
    build_esmf_docs(esmfdir, tag)
    #files = gather_source_files(esmfdir)
    #parse(esmfdir, outputfile, files)
    #clean_esmf(esmfdir)

@task
# development run (only builds esmf and docs once)
def dev_run(esmfdir, outputfile, tag):
    DRYDIR = tag+"_data"
    if not exists(DRYDIR):
        build_esmf_docs(esmfdir, tag)
        dryrun(esmfdir, DRYDIR)
        clean_esmf(esmfdir)
    files = gather_source_files_after_dryrun(esmfdir)
    parse(esmfdir, outputfile, files)

@task
def clean_dry_dir(tag):
    DRYDIR = tag + "_data"
    if exists(DRYDIR):
        run("rm -rf "+DRYDIR)

# build esmf docs
@task
def build_esmf_docs(esmfdir, tag):
    with cd(esmfdir):
        with shell_env(ESMF_DIR=esmfdir):
            run("env | grep ESMF")
            run("module list")
            run("git checkout master")
            run("git pull")
            run("git checkout tags/" + tag)
            run("make distclean > /dev/null 2>&1")
            #This command is not working
            run("make")
            run("make doc > /dev/null 2>&1")

@task
def clean_esmf(esmfdir):
    with cd(esmfdir):
        with shell_env(ESMF_DIR=esmfdir):
            run("make distclean > /dev/null 2>&1")
            run("git checkout master")

# pull together html files from esmf docs
def gather_source_files(esmfdir):
    DIR = 'doc/ESMF_refdoc'
    REFDOCDIR = esmfdir + DIR

    if not exists(REFDOCDIR):
        raise ValueError("Directory: " + REFDOCDIR + " was not found.  DING!")

    # have to get the files i want to search (all node*.html)
    files = []
    output = run("ls " + REFDOCDIR)
    listdir = output.split()
    for file in listdir:
        if 'node' in file:
            addfile = (REFDOCDIR + '/' + file)
            files.append(addfile)
    files.remove(REFDOCDIR + '/' + 'footnode.html')
    files.remove(REFDOCDIR + '/' + 'node1.html')
    files.remove(REFDOCDIR + '/' + 'node2.html')
    files.remove(REFDOCDIR + '/' + 'node3.html')

    # sort list and move 10 to after 9
    files.sort()
    files.append(files.pop(0))

    return files

# gather html doc files and return names in a list
def gather_source_files_after_dryrun(esmfdir):
    REFDOCDIR = esmfdir

    if not exists(REFDOCDIR):
        raise ValueError("Directory: " + REFDOCDIR + " was not found.  DING!")

    # have to get the files i want to search (all node*.html)
    files = []
    output = run("ls "+REFDOCDIR)
    listdir = output.split()
    for file in listdir:
        files.append(REFDOCDIR+file)

    # sort list and move 10 to after 9
    files.sort()
    files.append(files.pop(0))

    return files

# gather html esmf doc files and put them in a temp directory
def dryrun(esmfdir, DRYDIR):
    files = gather_source_files(esmfdir)
    run("mkdir "+DRYDIR)
    for f in files:
        run("cp "+f+" "+DRYDIR)

# esmfdir - the directory of the esmf version from which you want to gather APIs
# outputfile - file name of place you want your APIs to appear
# files - sorted list of html files to parse
# intent of this routine is to harvest the ESMF Fortran APIs from the html version
# of the reference manual and put them in a file for text based searches (grep)
def parse(esmfdir, outputfile, files):
    import re

    OUTFILE = open(outputfile, "w")

    START = 'INTERFACE'
    END = ['ARGUMENTS', 'RETURN VALUE', 'PARAMETERS', 'DESCRIPTION']
    END_WITHARGS = 'DESCRIPTION'

    # sort list and move 10 to after 9
    files.sort()
    files.append(files.pop(0))

    writeline = ""
    # write all lines between START and END
    for f in files:
        flag = False
        print f
        file = open(f)

        for line in file:
            # this is END for no arguments
            #if any(enditer in line for enditer in END):
            # this is END for with arguments
            if 'DESCRIPTION' in line:
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

    OUTFILE.close()
