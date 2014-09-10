from django.conf.urls import patterns, url

from eca import views
from eca.models import ESMFAtomFeed

urlpatterns = patterns('',
    # ex: /eca/
    url(r'^$', views.index, name='index'),
    # ex: /eca/feed/
    url(r'^eca/feed/$', ESMFAtomFeed()),
    # ex: /eca/CESM_Component.xml
    url(r'^(?P<document_id>[^/]+)/$', views.show_doc, name='show_doc'),

)