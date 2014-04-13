# -*- coding: utf-8 -*-
from rest_framework.viewsets import GenericViewSet
from rest_framework import mixins
from GIS.cafe.models import Address
from GIS.cafe.serializers import AddressSerializer


class AddressesViewSet(mixins.ListModelMixin, GenericViewSet):
    serializer_class = AddressSerializer
    model = Address
