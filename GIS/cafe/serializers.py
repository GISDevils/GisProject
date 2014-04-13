# -*- coding: utf-8 -*-
from rest_framework.relations import RelatedField
from rest_framework.serializers import ModelSerializer
from GIS.cafe.models import Address, Cafe


class CafeSerializer(ModelSerializer):
    class Meta:
        model = Cafe
        fields = ['name', 'phones', 'min_price', 'cuisines', 'types']

    cuisines = RelatedField(many=True)
    types = RelatedField(many=True)


class AddressSerializer(ModelSerializer):
    class Meta:
        model = Address
        exclude = ['id']

    cafe = CafeSerializer()

    def to_native(self, obj):
        result = super(AddressSerializer, self).to_native(obj)
        result['cuisines'] = result['cafe']['cuisines']
        result['types'] = result['cafe']['types']
        result['phones'] = result['cafe']['phones']
        result['min_price'] = result['cafe']['min_price']
        result['cafe'] = result['cafe']['name']
        return result
