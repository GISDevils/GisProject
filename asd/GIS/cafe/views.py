# -*- coding: utf-8 -*-
from rest_framework.response import Response
from rest_framework.status import HTTP_400_BAD_REQUEST
from rest_framework.viewsets import GenericViewSet
from rest_framework import mixins
from asd.GIS.cafe.filters import AddressFilterBackend
from asd.GIS.cafe.models import Address
from asd.GIS.cafe.serializers import AddressSerializer


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
