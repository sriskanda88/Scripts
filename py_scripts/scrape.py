#!/usr/bin/python

from bs4 import BeautifulSoup as BSoup
from urllib import urlopen

url = urlopen('http://www.google.com').read()
soup = BSoup(url)
print soup
