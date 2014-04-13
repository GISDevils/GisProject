# -*- coding: utf-8 -*-
from rest_framework.serializers import Serializer
from GIS.cafe.models import Address, Cafe


class CafeSerializer(Serializer):
    class Meta(Serializer.Meta):
        model = Cafe
        exclude = ['id']


class AddressSerializer(Serializer):
    class Meta(Serializer.Meta):
        model = Address
        exclude = ['cafe', 'id']

    cafe = CafeSerializer()
