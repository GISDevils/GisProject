#!/usr/bin/env python

from setuptools import setup

setup(
    name='GisProject',
    version='0.1',
    description='OpenShift App',
    author='Dmitry Yantsen, Liza Lukicheva, Evgeny Muralev, Elena Kozhevina',
    author_email='d.yantse@gmail.com',
    url='http://www.python.org/sigs/distutils-sig/',
    install_requires=['Django==1.5', 'geopy', 'djangorestframework==2.3.12', 'mysql-python'],
)
