from django.conf.urls import patterns, include, url
from django.contrib import admin

urlpatterns = patterns('',
    # Examples:
    # url(r'^$', 'esmfcimfeed.views.home', name='home'),
    # url(r'^blog/', include('blog.urls')),

    url(r'^eca/', include('eca.urls')),
    url(r'^admin/', include(admin.site.urls)),
)
