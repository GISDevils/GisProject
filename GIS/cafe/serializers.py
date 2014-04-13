# -*- coding: utf-8 -*-
from rest_framework.relations import RelatedField
from rest_framework.serializers import ModelSerializer
from GIS.cafe.models import Address, Cafe


class CafeSerializer(ModelSerializer):
    class Meta:
        model = Cafe
        fields = ['name', 'phones', 'avg_price', 'cuisines', 'types']

    cuisines = RelatedField(many=True)
    types = RelatedField(many=True)


class AddressSerializer(ModelSerializer):
    class Meta:
        model = Address
        exclude = ['id']

    cafe = CafeSerializer()

    def to_native(self, obj):
        result = super(AddressSerializer, self).to_native(obj)
        result.update(result['cafe'])
        result.pop('cafe')
        return result
