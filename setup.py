# setup.py file
import sys
import os
import shutil

from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
for root, dirs, files in os.walk(".", topdown=False):
    for name in files:
        if (name.startswith("PyVBF") and not(name.endswith(".pyx") or name.endswith(".pxd"))):
            os.remove(os.path.join(root, name))
    for name in dirs:
        if (name == "build"):
            shutil.rmtree(name)
# build "PyVBF.so" python extension to be added to "PYTHONPATH" afterwards...
setup(
    cmdclass = {'build_ext': build_ext},
    ext_modules = [
        Extension("PyVBF", 
                  sources=["PyVBF.pyx"],
                  libraries=["VBF"],          # refers to "libVBF.so"
                  language="c++",                   # remove this if C and not C++
                  extra_compile_args=["-O3"]
             )
        ]
)           
