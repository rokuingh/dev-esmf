from django.contrib.syndication.views import Feed
from django.utils.feedgenerator import Atom1Feed

class CIMFile(object):
    def __init__(self, title, xmlstring):
        self.title = title
        self.link = "/feed/{}".format(title)
        self.subtitle = "ESMF CIM XML"
        self.xmlstring = xmlstring


class ESMFAtomFeed(Feed):

    feed_type   = Atom1Feed
    title       = "ESMF CIM Documents"
    link        = "/feed/"
    subtitle    = "Currently Published ESMF CIM Documents"

    cimfiles = []

    from lxml import etree
    from os.path import join
    from glob import glob

    DATADIR = "/Users/ryan.okuinghttons/sandbox/esmf_dev/ESMF_atomfeed/data/"
    files = glob(join(DATADIR,"*.xml"))

    parser = etree.XMLParser()
    for file in files:
        tree = etree.parse(file, parser)
        filename = file.rsplit("/")[-1]
        xmlstring = etree.tostring(tree, pretty_print=True)
        cimfiles.append(CIMFile(filename, xmlstring))


    def __init__(self):
        super(ESMFAtomFeed,self).__init__()

    def get_object(self, doc):
        return next((x.xmlstring for x in self.cimfiles if x.title == doc), None)

    def items(self):
        return self.cimfiles

    def item_title(self,item):
        return item.title

    def item_link(self, item):
        return item.link

    def item_description(self,item):
        return item.subtitle
