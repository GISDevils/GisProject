# -*- coding: utf-8 -*-
from rest_framework.fields import DecimalField, IntegerField
from rest_framework.relations import RelatedField
from rest_framework.serializers import ModelSerializer, Serializer
from GIS.cafe.models import Address, Cafe
from GIS.fields import ListField


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


class AddressFilterSerializer(Serializer):
    latitude = DecimalField(max_digits=20, decimal_places=16, required=False)
    longitude = DecimalField(max_digits=20, decimal_places=16, required=False)
    distance = IntegerField(required=False)
    cuisines = ListField(field=IntegerField(required=True),
                         required=False)
    max_price = IntegerField(required=False)
