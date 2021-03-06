# -*- coding: utf-8 -*-
from rest_framework.response import Response
from rest_framework.status import HTTP_400_BAD_REQUEST
from rest_framework.viewsets import GenericViewSet
from rest_framework import mixins
from GIS.cafe.filters import AddressFilterBackend
from GIS.cafe.models import Address, CuisineType, CafeType
from GIS.cafe.serializers import AddressSerializer, CuisineTypeSerializer, CafeTypeSerializer


class AddressesViewSet(mixins.ListModelMixin, GenericViewSet):
    serializer_class = AddressSerializer
    model = Address
    filter_backend = AddressFilterBackend

    def list(self, request, *args, **kwargs):
        if ('distance' in request.QUERY_PARAMS and
                (not 'longitude' in request.QUERY_PARAMS or not 'latitude' in request.QUERY_PARAMS)):
            return Response('Specify your position (longitude & latitude) if you specify distance.',
                            status=HTTP_400_BAD_REQUEST)
        return super(AddressesViewSet, self).list(request, *args, **kwargs)


class CuisineTypesViewSet(mixins.ListModelMixin, GenericViewSet):
    serializer_class = CuisineTypeSerializer
    model = CuisineType

    def get_queryset(self):
        queryset = super(CuisineTypesViewSet, self).get_queryset()
        return queryset.extra(order_by=['id'])


class CafeTypesViewSet(mixins.ListModelMixin, GenericViewSet):
    serializer_class = CafeTypeSerializer
    model = CafeType

    def get_queryset(self):
        queryset = super(CafeTypesViewSet, self).get_queryset()
        return queryset.extra(order_by=['id'])
