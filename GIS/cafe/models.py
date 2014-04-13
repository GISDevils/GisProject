# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models


class Addresses(models.Model):
    cafe = models.ForeignKey('Cafes')
    street = models.CharField(max_length=50L)
    building = models.IntegerField()
    latitude = models.DecimalField(null=True, max_digits=20, decimal_places=16, blank=True)
    longitude = models.DecimalField(null=True, max_digits=20, decimal_places=16, blank=True)

    class Meta:
        db_table = 'addresses'


class CafeTypes(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=20L, unique=True)

    class Meta:
        db_table = 'cafe_types'


class Cafes(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=50L, unique=True)
    phones = models.CharField(max_length=30L, blank=True)
    min_price = models.IntegerField(null=True, blank=True)

    class Meta:
        db_table = 'cafes'


class CuisineTypes(models.Model):
    id = models.IntegerField(primary_key=True)
    name = models.CharField(max_length=40L, unique=True)

    class Meta:
        db_table = 'cuisine_types'


class Cuisines(models.Model):
    cafe = models.ForeignKey(Cafes)
    cuisine = models.ForeignKey(CuisineTypes)

    class Meta:
        db_table = 'cuisines'


class Types(models.Model):
    cafe = models.ForeignKey(Cafes)
    type = models.ForeignKey(CafeTypes)

    class Meta:
        db_table = 'types'

