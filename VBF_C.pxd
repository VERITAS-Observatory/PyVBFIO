#distutils: laguage= c++
from libcpp.string cimport string 
from libcpp cimport bool
from cython cimport view
cimport numpy as np

cdef extern from "Words.h":
    ctypedef np.int8_t      byte
    ctypedef np.int16_t   word16
    ctypedef np.int32_t   word32
    ctypedef np.int64_t   word64
    ctypedef np.uint8_t    ubyte
    ctypedef np.uint16_t uword16
    ctypedef np.uint32_t uword32
    ctypedef np.uint64_t uword64

cdef extern from "VSimulationHeader.h":
    cdef cppclass VSimulationHeader:
         VSimulationHeader()
         string fSimConfigFile
         uword32 fAtmosphericModel
         uword32 fDateOfArrayForSims
         uword32 fSimulationPackage
         uword32 fDateOfSimsUTC

cdef extern from "VDatum.h":
    cdef cppclass VEvent:
         uword16 getNumSamples()    
         uword16 getNumChannels()    
         uword16 getMaxNumChannels()    
         ubyte*  getSamplePtr(unsigned channel,unsigned sample) except +

cdef extern from "VArrayEvent.h":
    cdef cppclass VArrayEvent:
         VArrayEvent()
         VEvent* getEventByNodeNumber(unsigned telnum)

   

cdef extern from "VPacket.h":
    cdef cppclass VPacket:
         VPacket()
         unsigned size()
         bool    empty()
         bool hasSimulationHeader()     # 0
         bool hasArrayEvent()           # 1 
         bool hasSimulationData()       # 2
         bool hasCorsikaSimulationData() # 3
         VSimulationHeader* getSimulationHeader() except +
         VArrayEvent*       getArrayEvent() 

cdef extern from "VBankFileReader.h":
    cdef cppclass VBankFileReader:
       VBankFileReader(string& filename,bool map_index,bool read_only) except +
       uword32 numPackets() except +
       VPacket* readPacket(uword32 i) except +
       long getRunNumber()


