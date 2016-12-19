# setup.py file
import sys
import os
import shutil

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import numpy as np

for root, dirs, files in os.walk(".", topdown=False):
    for name in files:
        if (name.startswith("PyVBF") and not(name.endswith(".pyx") or name.endswith(".pxd"))):
            os.remove(os.path.join(root, name))
    for name in dirs:
        if (name == "build"):
            shutil.rmtree(name)
# Set LDFLGAS

os.environ['LDFLAGS'] = os.popen('vbfConfig --ldflags').read().strip('\n') + '-lz'

# build "PyVBF.so" python extension to be added to "PYTHONPATH" afterwards...
include_dirs = [ os.environ['VBFSYS'] + '/include/VBF/',
                 np.get_include()]

setup(
    cmdclass = {'build_ext': build_ext},
    ext_modules = [
        Extension("PyVBF", 
                  sources=["PyVBF.pyx"],
                  libraries=["VBF"],          # refers to "libVBF.so"
                  language="c++",                   # remove this if C and not C++
                  include_dirs = include_dirs,
                  extra_compile_args=["-O3"]
             )
        ]
)           
