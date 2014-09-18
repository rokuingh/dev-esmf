from django.contrib.syndication.views import Feed
from django.utils.feedgenerator import Atom1Feed

class CIMFile(object):
    def __init__(self, title, xmlstring):
        self.title = title
        self.link = "/eca/feed/{}".format(title)
        self.subtitle = "ESMF CIM XML file: "+str(title)
        self.xmlstring = xmlstring


class ESMFAtomFeed(Feed):

    feed_type   = Atom1Feed
    title       = "ESMF CIM Documents"
    link        = "/eca/feed/"
    subtitle    = "Currently Published ESMF CIM Documents"

    def __init__(self):
        from lxml import etree
        from os.path import join
        from glob import glob
        import os

        DATADIR = os.path.join(os.getcwd(), "../data/")
        files = glob(join(DATADIR, "*.xml"))

        parser = etree.XMLParser()

        self.cimfiles = []
        for file in files:
            tree = etree.parse(file, parser)
            filename = file.rsplit("/")[-1]
            xmlstring = etree.tostring(tree, pretty_print=True)
            self.cimfiles.append(CIMFile(filename, xmlstring))

        super(ESMFAtomFeed,self).__init__()

    def items(self):
        return self.cimfiles

    def item_title(self,item):
        return item.title

    def item_link(self, item):
        return item.link

    def item_description(self,item):
        return item.subtitle
