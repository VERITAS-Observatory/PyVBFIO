#!/bin/bash
 
CC="gcc" \
CXX="g++" \
CFLAGS="$(python-config --cflags) -I$VBFSYS/include/VBF/" \
LDFLAGS="$(python-config --ldflags) $(vbfConfig --ldflags) -lz" \
python setup.py build_ext --inplace
