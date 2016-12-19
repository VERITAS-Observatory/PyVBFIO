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

cdef extern from "VEventType.h":
    ctypedef enum TriggerType "VEventType::TriggerType":
             L2_TRIGGER        "VEventType::L2_TRIGGER"
             HIGH_MULT_TRIGGER "VEventType::HIGH_MULT_TRIGGER"
             NEW_PHYS_TRIGGER  "VEventType::NEW_PHYS_TRIGGER"
             CAL_TRIGGER       "VEventType::CAL_TRIGGER"
             PED_TRIGGER       "VEventType::PED_TRIGGER"
     
    cdef struct VEventType:
         TriggerType trigger

cdef extern from "VDatum.h":
    cdef cppclass VDatum:
         VDatum()
         ubyte getGPSYear()
         uword16* getGPSTime()
         ubyte    getRawEventTypeCode()
         VEventType getEventType() 

    cdef cppclass VEvent(VDatum):
         uword16 getNumSamples()    
         uword16 getNumChannels()    
         uword16 getMaxNumChannels()    
         ubyte*  getSamplePtr(unsigned channel,unsigned sample) except +
         bool    getHiLo(unsigned channel) except +

cdef extern from "VSimulationData.h":
    cdef cppclass VSimulationData:
         VSimulationData()
         uword32 fEventNumber
         float fEnergyGeV
  
         float fObservationZenithDeg
         float fObservationAzimuthDeg
         
         float fPrimaryZenithDeg
         float fPrimaryAzimuthDeg
       
         float fRefZenithDeg   
         float fRefAzimuthDeg  
         float fRefPositionAngleDeg
       
         float fCoreEastM
         float fCoreSouthM
         float fCoreElevationMASL

cdef extern from "VCorsikaSimulationData.h":
    cdef cppclass VCorsikaSimulationData:
         VCorsikaSimulationData()
         long fRunNumber
         uword32 fEventNumber
         float   fFirstInteractionHeight
         float   fFirstInteractionDepth
         word32 fShowerID
         word32 fCorsikaRunID
 
 
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



