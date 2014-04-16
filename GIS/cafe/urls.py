# -*- coding: utf-8 -*-
from django.conf.urls import patterns, url, include
from rest_framework.routers import SimpleRouter
from GIS.cafe.views import AddressesViewSet, CuisineTypesViewSet, CafeTypesViewSet

router = SimpleRouter()
router.register('addresses', AddressesViewSet)
router.register('cuisines', CuisineTypesViewSet)
router.register('cafetypes', CafeTypesViewSet)

urlpatterns = patterns(
    '',
    url(r'^api/', include(router.urls)),
)
