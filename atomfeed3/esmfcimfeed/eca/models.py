from django.db import models

from django.db import models
from django.contrib.syndication.views import Feed
from django.utils.feedgenerator import Atom1Feed

class ESMFCIMDocument(models.Model):
    title = models.CharField(max_length=200)
    pub_date = models.DateTimeField('date published')

class ESMFAtomFeed(Feed):

    feed_type   = Atom1Feed
    title       = "ESMF CIM Documents"
    link        = "/feed/"
    subtitle    = "Currently Published ESMF CIM Documents"

    items = ["doc1.xml", "doc2.xml"]

    # def get_object(self,request,document_name):
    #     return DATADIR+document_name

    def get_object(self,request,project_name="",version_number="",model_name=""):

        (project,version,model_class) = check_feed_parameters(request,project_name,version_number,model_name)

        self.project = project
        self.version = version

        if model_class:
            self.title = "CIM %s Documents for %s" % (model_class.getTitle(), project.getTitle())
            self.model_classes = [model_class]

        else:
            self.title = "CIM Documents for %s" % (project.getTitle())

            self.model_classes = \
                [model_class for model_class in version.getAllModelClasses() if model_class and model_class._is_metadata_document]


    def items(self):
        return self.items

    def item_link(self, item):
        url = "/feed/%s" % (item.name)
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

    def item_title(self,item):
        return u"%s" % (item.name)



