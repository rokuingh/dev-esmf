from django.conf.urls import patterns, include, url
from django.contrib import admin

urlpatterns = patterns('',
    url(r'^eca/', include('eca.urls')),
    url(r'^admin/', include(admin.site.urls)),
)
