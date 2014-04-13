from django.conf.urls import patterns, include, url

urlpatterns = patterns('',
    url(r'^cafe/', include('GIS.cafe.urls')),
)
