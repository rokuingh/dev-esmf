#!/usr/local/bin/python
#  CGI script to create the ESMF atom feed page for automatic XML document
#   archival onto ESGF node using pyesdoc

import cgi
import os
import cgitb
import unittest
cgitb.enable()

class ESMFAtomFeed(object):
    def __init__(self, title=None):

        # Deal with the optional title
        if title is None:
            title = "Current ESMF CIM test documents"

        # Create the header and footer
        self.header = """<?xml version="1.0" encoding="utf-8"?>\n<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en-us"><title>ESMF CIM Documents</title><link href="http://www.earthsystemmodeling.org/xml_feed/" rel="alternate"></link><link href="http://www.earthsystemmodeling.org/xml_feed/" rel="self"></link><id>http://www.earthsystemmodeling.org/xml_feed/</id><updated>2014-09-18T21:59:29Z</updated><subtitle>"""
        self.header += title
        self.header += "</subtitle>"

        self.footer = "</feed>\n"

        # Create the entry list

        self.entries = ""
        datadir = os.path.join(os.path.split(os.getcwd())[0], "data")
        if os.path.isdir(datadir):
            filenames = next(os.walk(datadir))[2]
            for file in filenames:
                self.entries += self.make_entry(file)

    def __repr__(self):
        return self.header+self.entries+self.footer

    def make_entry(self, file):
        entry = "<entry>"
        entry += "<title>"+file+ "</title>"
        entry += "<link href=\"http://www.earthsystemmodeling.org/xml_feed/"+file+\
                 "\" rel=\"alternate\"></link>"
        entry += "<id>http://www.earthsystemmodeling.org/xml_feed/"+file+"</id>"
        entry += "<summary type=\"html\">ESMF CIM XML file: "+file+"</summary>"
        entry += "</entry>"

        return entry

class TestESMFAtomFeed(unittest.TestCase):
    # this test will start to fail as we add more files the the CESM_Component.xml to the data directory..
    def test_esmfatomfeed(self):
        esmfatomfeed = ESMFAtomFeed(title="Currently Published ESMF CIM Documents")

        # This is what we want to reproduce

        originalfeed="""<?xml version="1.0" encoding="utf-8"?>\n<feed xmlns="http://www.w3.org/2005/Atom" xml:lang="en-us"><title>ESMF CIM Documents</title><link href="http://www.earthsystemmodeling.org/xml_feed/" rel="alternate"></link><link href="http://www.earthsystemmodeling.org/xml_feed/" rel="self"></link><id>http://www.earthsystemmodeling.org/xml_feed/</id><updated>2014-09-18T21:59:29Z</updated><subtitle>Currently Published ESMF CIM Documents</subtitle><entry><title>CESM_Component.xml</title><link href="http://www.earthsystemmodeling.org/xml_feed/CESM_Component.xml" rel="alternate"></link><id>http://www.earthsystemmodeling.org/xml_feed/CESM_Component.xml</id><summary type="html">ESMF CIM XML file: CESM_Component.xml</summary></entry></feed>\n"""
        assert(str(esmfatomfeed)==originalfeed)


print "Content-type: text/xml"
print

esmfatomfeed = ESMFAtomFeed()

print str(esmfatomfeed)

