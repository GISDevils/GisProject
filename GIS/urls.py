from django.conf.urls import patterns, include, url
from django.views.generic.base import TemplateView
from GIS import settings

urlpatterns = patterns(
    '',
    url(r'^cafe/', include('GIS.cafe.urls')),
    url(r'^$', TemplateView.as_view(template_name="index.html")),
    url(r'^media/(?P<path>.*)$', 'django.views.static.serve',
        {'document_root': settings.MEDIA_ROOT}),
)
