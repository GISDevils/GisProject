# -*- coding: utf-8 -*-
from geopy.distance import distance
from rest_framework.filters import BaseFilterBackend
from GIS.cafe.models import Cafe, Cuisine, CuisineType
from GIS.cafe.serializers import AddressFilterSerializer


class AddressFilterBackend(BaseFilterBackend):
    serializer_class = AddressFilterSerializer

    @staticmethod
    def get_distance(current_location, cafe_latitude, cafe_longitude):
        return distance(current_location, (cafe_latitude, cafe_longitude)).meters

    def filter_queryset(self, request, queryset, view):
        serializer = self.serializer_class(data=request.QUERY_PARAMS)
        if serializer.is_valid():
            if serializer.object.get('distance', None):
                current_location = (serializer.object['latitude'], serializer.object['longitude'])
                max_distance = serializer.object['distance']
                for address in queryset:
                    if self.get_distance(current_location, address.latitude, address.longitude) > max_distance:
                        queryset = queryset.exclude(id=address.id)
            if serializer.object.get('max_price', None):
                queryset = queryset.filter(
                    cafe__in=Cafe.objects.filter(avg_price__lte=serializer.object['max_price']))
            if serializer.object.get('cuisines', None):
                for cuisine_id in serializer.object['cuisines']:
                    queryset = queryset.filter(
                        cafe__in=[
                            cuisine.cafe
                            for cuisine in Cuisine.objects.filter(
                                cuisine=CuisineType.objects.get(id=cuisine_id))])
        else:
            queryset = queryset.none()
        return queryset