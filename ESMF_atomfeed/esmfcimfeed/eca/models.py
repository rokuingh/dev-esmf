from django.contrib.syndication.views import Feed
from django.utils.feedgenerator import Atom1Feed

class ESMFAtomFeed(Feed):

    feed_type   = Atom1Feed
    title       = "ESMF CIM Documents"
    link        = "/feed/"
    subtitle    = "Currently Published ESMF CIM Documents"

    def __init__(self):
        from lxml import etree
        parser = etree.XMLParser(remove_blank_text=True)
        tree = etree.parse("/Users/ryan.okuinghttons/sandbox/esmf_dev/ESMF_atomfeed/data/CESM_Component.xml", parser)

        super(ESMFAtomFeed,self).__init__()

        self.objects = {}
        self.objects["CESM_Component.xml"] = etree.tostring(tree, pretty_print=True)

    def get_object(self, request):
        return self.objects

    def items(self):
        return self.objects

    def item_title(self,item):
        return item.title

    def item_link(self, item):
        url = "/feed/%s" % ('CESM_Component.xml')
        return url

    def item_description(self,item):
        try:
            description = item.description
            if len(description):
                return description
            else:
                return ""
        except:
            return ""
