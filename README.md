# PyVBFIO
VBF wrapper written in Cython

# Requirement
1. Cython
2. Numpy
3. VBF

Remember to set environment variable VBFSYS to point to your VBF installation.

# Build Instruction
Simply run:
```
./setup.sh
```
This will build the PyVBF interface in the directory of the code. I haven't implement the full installation script yet.  
So, to use PyVBF in your script/jupyter-notebook, the easist way is to add the directory of code in sys.path.  
Example:
```Python
import sys  
sys.path.append('/path/to/your/PyVBF')  
import PyVBF 
```
An example of using PyVBF can be found [here](https://gist.github.com/2c5d8cc40e951f76e425dfc37928b83e.git).
