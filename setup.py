#!/usr/bin/env python

from setuptools import setup
import os

setup(
    name='GisProject',
    version='0.1',
    description='OpenShift App',
    author='Dmitry Yantsen, Liza Lukicheva, Evgeny Muralev, Elena Kozhevina',
    author_email='d.yantse@gmail.com',
    url='http://www.python.org/sigs/distutils-sig/',
    install_requires=[open(os.path.join(os.path.dirname(__file__), 'requirements.txt')).readlines()],
)
