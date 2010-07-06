#!/usr/bin/python
# -*- coding: utf-8 -*-

import codecs
import re
import sys

tex = ''
replace = {}
dct = { '@a': u'ą', 
         '@c': u'ć', 
         '@e': u'ę',
         '@l': u'ł',
         '@n': u'ń',
         '@o': u'ó',
         '@s': u'ś',
         '@x': u'ź',
         '@z': u'ż',
         '@A': u'Ą', 
         '@C': u'Ć', 
         '@E': u'Ę',
         '@L': u'Ł',
         '@N': u'Ń',
         '@O': u'Ó',
         '@S': u'Ś',
         '@X': u'Ź',
         '@Z': u'Ż'}

for char in dct:
    obj = re.compile(char)
    replace[obj] = dct[char]

text = codecs.open(sys.argv[1], 'r', 'utf-8').read()
codecs.open(sys.argv[1].replace('.tex', '.andbak'), 'w', 'utf-8').write(text)

for regex in replace:
    text = regex.sub(replace[regex], text)

codecs.open(sys.argv[1], 'w', 'utf-8').write(text)
