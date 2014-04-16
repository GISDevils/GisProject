# -*- coding: utf-8 -*-
import json
from decimal import Decimal
from django.test.client import Client

from django.test import TestCase
from GIS.cafe.models import Cafe, Address, CafeType, CuisineType, Cuisine, Type


class ValidationTest(TestCase):
    fixtures = ['cafe_testing']

    def test_validate(self):
        self.assertEqual(Cafe.objects.count(), 2)
        self.assertEqual(Address.objects.count(), 4)
        self.assertEqual(CafeType.objects.count(), 3)
        self.assertEqual(CuisineType.objects.count(), 3)
        self.assertEqual(Cuisine.objects.count(), 3)
        self.assertEqual(Type.objects.count(), 4)


class ApiTest(TestCase):
    fixtures = ['cafe_testing']

    CUISINES_URL = '/cafe/api/cuisines/'
    CAFE_TYPES_URL = '/cafe/api/cafetypes/'
    ADDRESSES_URL = '/cafe/api/addresses/'

    def setUp(self):
        self.client = Client()

    def test_cuisines_list(self):
        response = self.client.get(self.CUISINES_URL, content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 3)
        self.assertEqual(result['results'][0]['name'], u'Test_cuisine1')
        self.assertEqual(result['results'][1]['name'], u'Test_cuisine2')
        self.assertEqual(result['results'][2]['name'], u'Test_cuisine3')

    def test_types_list(self):
        response = self.client.get(self.CAFE_TYPES_URL, content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 3)
        self.assertEqual(result['results'][0]['name'], u'Test_type1')
        self.assertEqual(result['results'][1]['name'], u'Test_type2')
        self.assertEqual(result['results'][2]['name'], u'Test_type3')

    def test_address_list(self):
        response = self.client.get(self.ADDRESSES_URL, content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 4)
        self.assertIn('name', result['results'][1])
        self.assertIn('street', result['results'][1])
        self.assertIn('building', result['results'][1])
        self.assertIn('avg_price', result['results'][1])
        self.assertIn('latitude', result['results'][1])
        self.assertIn('longitude', result['results'][1])
        self.assertIn('phones', result['results'][1])
        self.assertEqual(result['results'][0]['name'], u'Test_cafe1')
        self.assertEqual(result['results'][0]['street'], u'Test_street1')
        self.assertEqual(result['results'][1]['name'], u'Test_cafe2')
        self.assertEqual(result['results'][2]['name'], u'Test_cafe2')
        self.assertEqual(result['results'][3]['name'], u'Test_cafe2')

    def test_address_filters(self):
        # test max avg price
        response = self.client.get(
            self.ADDRESSES_URL,
            data={'max_price': 50},
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 0)

        response = self.client.get(
            self.ADDRESSES_URL,
            data={'max_price': 100},
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 3)
        for res in result['results']:
            self.assertEqual(res['name'], 'Test_cafe2')

        response = self.client.get(
            self.ADDRESSES_URL,
            data={'max_price': 400},
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 4)
        self.assertEqual(result['results'][0]['name'], 'Test_cafe1')
        self.assertEqual(result['results'][1]['name'], 'Test_cafe2')
        self.assertEqual(result['results'][2]['name'], 'Test_cafe2')
        self.assertEqual(result['results'][3]['name'], 'Test_cafe2')

        # test cuisines
        response = self.client.get(
            self.ADDRESSES_URL,
            data={'cuisines': 1},
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 4)
        self.assertEqual(result['results'][0]['name'], 'Test_cafe1')
        self.assertEqual(result['results'][1]['name'], 'Test_cafe2')
        self.assertEqual(result['results'][2]['name'], 'Test_cafe2')
        self.assertEqual(result['results'][3]['name'], 'Test_cafe2')

        response = self.client.get(
            self.ADDRESSES_URL,
            data={'cuisines': 2},
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 1)
        self.assertEqual(result['results'][0]['name'], 'Test_cafe1')

        response = self.client.get(
            self.ADDRESSES_URL,
            data=[('cuisines', 1),
                  ('cuisines', 2)],
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 1)
        self.assertEqual(result['results'][0]['name'], 'Test_cafe1')

        # test distance
        response = self.client.get(
            self.ADDRESSES_URL,
            data={
                'distance': 1000,
                'latitude': Decimal("55.1623709802915100"),
                'longitude': Decimal("61.4648799802915100"),
            },
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 1)
        self.assertEqual(result['results'][0]['name'], 'Test_cafe1')

        response = self.client.get(
            self.ADDRESSES_URL,
            data={
                'distance': 5000,
                'latitude': Decimal("55.1623709802915100"),
                'longitude': Decimal("61.4648799802915100"),
            },
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 2)
        self.assertEqual(result['results'][0]['name'], 'Test_cafe1')
        self.assertEqual(result['results'][1]['name'], 'Test_cafe2')

        response = self.client.get(
            self.ADDRESSES_URL,
            data={
                'distance': 40000,
                'latitude': Decimal("55.1623709802915100"),
                'longitude': Decimal("61.4648799802915100"),
            },
            content_type='application/json')
        self.assertEqual(response.status_code, 200)
        result = json.loads(response.content)
        self.assertEqual(result['count'], 3)
        self.assertEqual(result['results'][0]['name'], 'Test_cafe1')
        self.assertEqual(result['results'][1]['name'], 'Test_cafe2')
        self.assertEqual(result['results'][2]['name'], 'Test_cafe2')
