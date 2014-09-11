from django.conf.urls import patterns, url

from eca.models import ESMFAtomFeed
import views

urlpatterns = patterns('',
    # ex: Atom Feed stuff
    url(r'^feed/$', ESMFAtomFeed()),
    url(r'^feed/(?P<doc>[^/]+)/$', ESMFAtomFeed()),

    # ex: /eca/feed/files/CESM_Component.xml
    url(r'^feed/files/(?P<doc>[^/]+)/$', views.show_doc),

)