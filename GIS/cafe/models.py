# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models


class DistanceManager(models.Manager):
    def within_distance(self, distance, current_location):
        from django.db import connection
        cursor = connection.cursor()
        cursor.execute("""
            SELECT id, latitude, longitude, (6367 * acos(cos(radians({0}))
                * cos(radians(latitude)) * cos(radians(longitude-{1}))
                + sin(radians({0})) * sin(radians(latitude)))) AS distance
            FROM addresses
            HAVING distance < {2}
            """.format(current_location[0], current_location[1], distance/1000.0))
        id_list = [row[0] for row in cursor.fetchall()]
        return self.get_query_set().filter(id__in=id_list)


class CafeType(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=20L, unique=True)

    class Meta:
        db_table = 'cafe_types'


class Cafe(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=50L, unique=True)
    phones = models.CharField(max_length=30L, null=True, default=None)
    avg_price = models.IntegerField(null=True, blank=True)

    class Meta:
        db_table = 'cafes'


class Address(models.Model):
    cafe = models.ForeignKey(Cafe)
    street = models.CharField(max_length=50L)
    building = models.CharField(max_length=10L)
    latitude = models.DecimalField(null=True, max_digits=20, decimal_places=16, blank=True)
    longitude = models.DecimalField(null=True, max_digits=20, decimal_places=16, blank=True)
    objects = DistanceManager()

    class Meta:
        db_table = 'addresses'


class CuisineType(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=40L, unique=True)

    class Meta:
        db_table = 'cuisine_types'


class Cuisine(models.Model):
    cafe = models.ForeignKey(Cafe, related_name='cuisines')
    cuisine = models.ForeignKey(CuisineType)

    class Meta:
        db_table = 'cuisines'

    def __unicode__(self):
        return '%s' % self.cuisine.name


class Type(models.Model):
    cafe = models.ForeignKey(Cafe, related_name='types')
    type = models.ForeignKey(CafeType)

    class Meta:
        db_table = 'types'

    def __unicode__(self):
        return '%s' % self.type.name
