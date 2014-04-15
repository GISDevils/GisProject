# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models


class CafeType(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=20L, unique=True)

    class Meta:
        db_table = 'cafe_types'


class Cafe(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=50L, unique=True)
    phones = models.CharField(max_length=30L, blank=True)
    avg_price = models.IntegerField(null=True, blank=True)

    class Meta:
        db_table = 'cafes'


class Address(models.Model):
    cafe = models.ForeignKey(Cafe)
    street = models.CharField(max_length=50L)
    building = models.CharField(max_length=10L)
    latitude = models.DecimalField(null=True, max_digits=20, decimal_places=16, blank=True)
    longitude = models.DecimalField(null=True, max_digits=20, decimal_places=16, blank=True)

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
