from django.conf.urls import patterns, url

from eca import views
from eca.models import ESMFAtomFeed

urlpatterns = patterns('',
    # ex: /eca/
    url(r'^$', views.index, name='index'),
    # ex: /eca/feed/
    url(r'^feed/$', ESMFAtomFeed()),
    # ex: /eca/CESM_Component.xml
    url(r'^feed/(?P<doc>[^/]+)/$', views.show_doc, name='show_doc'),

)