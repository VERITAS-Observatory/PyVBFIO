#public public distutils: language= c++
from libcpp.string cimport string 
from libcpp cimport bool
from cython cimport view
cimport numpy as np
from VBF_C cimport *
import numpy as np

cdef struct Event:
    VEvent* c_event
    int     GPSTimeLen
    int     numSamples
    int     numChannels
    ubyte*  samplesPtr
    uword16*  GPSTime
    VArrayTrigger* array_trigger
    ubyte   EventTypeCode
    TriggerType trigger 
    ubyte   GPSYear
    uword32 eventNumber
    int     fGPSStatus
    int     fGPSDays 
    int     fGPSHrs
    int     fGPSMins
    double  fGPSSecs
    
cdef void decodeGPS(Event* evt,uword16* GPSTime):
    evt.fGPSStatus = (GPSTime[0] >>4 & 0xF)
    evt.fGPSDays   = ( 100*(GPSTime[0] & 0x000F)     +
                        10*(GPSTime[1]>>12 & 0x000F) +
                           (GPSTime[1]>>8  & 0x000F)
                     )

    evt.fGPSHrs    = ( 10*(GPSTime[1] >>4 & 0x000F) +
                        (GPSTime[1] >> 0 & 0x000F))

    evt.fGPSMins   = ( 10* (GPSTime[2]>>12 & 0x000F) +
                       (GPSTime[2]>>8 & 0x000F) )

    evt.fGPSSecs   = ( 10* (GPSTime[2]>>4 & 0x000F)   +
                       (GPSTime[2]>>0 & 0x000F)
                     )
    evt.fGPSSecs += ( 1E-1*(GPSTime[3]>>12 & 0x000F) +
    1E-2*(GPSTime[3]>>8 & 0x000F)  +
    1E-3*(GPSTime[3]>>4 & 0x000F)  +
    1E-4*(GPSTime[3]>>0 & 0x000F)  +
    1E-5*(GPSTime[4]>>12 & 0x000F) +
    1E-6*(GPSTime[4]>>8 & 0x000F)  +
    1E-7*(GPSTime[4]>>4 & 0x000F) )

cdef class PyVBFreader:
    cdef VBankFileReader* c_reader
    cdef VPacket*         c_packet
    cdef VSimulationHeader* c_simheader
    cdef VArrayEvent*       c_arrayevent
    cdef bool             is_loaded
    cdef Event            c_evt_struct
 
    def __cinit__(self,str fname,bool map_index=True,bool read_only=True):
        self.c_reader = new VBankFileReader(fname.encode(),map_index,read_only)
        self.c_packet = self.c_reader.readPacket(0)
        self.is_loaded = False
        self.read_packet()

    # Getter function for packet type functions
    cpdef hasSimulationHeader(self):
        return self.c_packet.hasSimulationHeader()

    cpdef hasArrayEvent(self):
        return self.c_packet.hasArrayEvent()

    cpdef hasSimulationData(self):
        return self.c_packet.hasSimulationData()

    cpdef hasCorsikaSimulationData(self):
        return self.c_packet.hasCorsikaSimulationData()

    # Packet Loading
    cpdef go_to_packet(self,int i):
        del  self.c_packet 
        self.c_arrayevent = NULL
        self.c_simheader  = NULL
        self.c_packet = self.c_reader.readPacket(i)
        self.read_packet()
 
    cdef read_packet(self):
        if(self.c_packet.hasSimulationHeader()): 
            self.c_simheader = self.c_packet.getSimulationHeader()

        elif(self.c_packet.hasArrayEvent()):
            self.c_arrayevent = self.c_packet.getArrayEvent() 
        else:
            self.is_loaded = False
        self.is_loaded = True

    cpdef loadEvent(self,int i):
        if (self.c_arrayevent == NULL):
           raise Exception("No ArrayEvent Loaded")
        self.c_evt_struct.c_event = self.c_arrayevent.getEventByNodeNumber(i)  
        if (self.c_evt_struct.c_event == NULL):
           raise Exception("No Telescope Event Loaded")
        else:
            self.c_evt_struct.array_trigger = self.c_arrayevent.getTrigger()
            self.c_evt_struct.numSamples  = self.c_evt_struct.c_event.getNumSamples()
            self.c_evt_struct.numChannels = self.c_evt_struct.c_event.getNumChannels()
            self.c_evt_struct.samplesPtr = self.c_evt_struct.c_event.getSamplePtr(0,0)  
            self.c_evt_struct.GPSTime    = self.c_evt_struct.c_event.getGPSTime()
            self.c_evt_struct.EventTypeCode = self.c_evt_struct.c_event.getRawEventTypeCode()
            self.c_evt_struct.trigger = self.c_evt_struct.c_event.getEventType().trigger
            self.c_evt_struct.GPSTimeLen    = 5
            self.c_evt_struct.GPSYear       = self.c_evt_struct.c_event.getGPSYear()
            self.c_evt_struct.eventNumber   = self.c_evt_struct.c_event.getEventNumber()
            decodeGPS(&(self.c_evt_struct),self.c_evt_struct.c_event.getGPSTime())             

    cpdef getGPSYear(self):
         return self.c_evt_struct.GPSYear
    
    cpdef getGPSTimeRaw(self):
         cdef int length = self.c_evt_struct.GPSTimeLen
         return np.asarray(<np.uint16_t[:length]> self.c_evt_struct.GPSTime)

    cpdef getGPSStatus(self):
         return self.c_evt_struct.fGPSStatus

    cpdef getGPSDays(self):
         return self.c_evt_struct.fGPSDays

    cpdef getGPSHrs(self):
         return self.c_evt_struct.fGPSHrs

    cpdef getGPSMins(self):
         return self.c_evt_struct.fGPSMins

    cpdef getGPSSecs(self):
         return self.c_evt_struct.fGPSSecs

    cpdef getEventNumber(self):
         return self.c_evt_struct.eventNumber

    cpdef getHiLo(self):
         if (self.c_evt_struct.c_event == NULL):
            return np.zeros(500,dtype='bool')

         cdef int numChannels  = self.c_evt_struct.numChannels
         numpy_array = np.zeros(numChannels,dtype='bool')
         for i in range(numChannels):
             numpy_array[i] = self.c_evt_struct.c_event.getHiLo(i)
         return numpy_array           

    cpdef getTriggerPattern(self):
         if (self.c_evt_struct.c_event == NULL):
            return np.zeros(500,dtype='bool')

         cdef int numChannels  = self.c_evt_struct.numChannels
         numpy_array = np.zeros(numChannels,dtype='bool')
         for i in range(numChannels):
             numpy_array[i] = self.c_evt_struct.c_event.getTriggerBit(i)
         return numpy_array           
    
    cpdef getTriggerTelescopeId(self):
         if (self.c_evt_struct.c_event == NULL):
            return np.zeros(4,dtype='uint32')
         cdef ubyte numTelescopes = self.c_evt_struct.array_trigger.getNumTriggerTelescopes() 
         numpy_array = np.zeros(numTelescopes,dtype='uint32')
         for i in range(numTelescopes):
             numpy_array[i] = self.c_evt_struct.array_trigger.getTriggerTelescopeId(i)
         return numpy_array

    cpdef getL2CountsRaw(self):
         if (self.c_evt_struct.c_event == NULL):
            return np.zeros(3,dtype='uint32')
         cdef ubyte numSubarray = self.c_evt_struct.array_trigger.getNumSubarrayTelescopes() 
         numpy_array = np.zeros((numSubarray,3),dtype='uint32')
         for i in range(numSubarray):
            for j in range(3):
             numpy_array[i,j] = self.c_evt_struct.array_trigger.getL2CountsArray(i)[j]
         return numpy_array

    cpdef getL2ScalarRate(self):
         if (self.c_evt_struct.c_event == NULL):
            return np.zeros(1,dtype='uint32')
         cdef ubyte numSubarray = self.c_evt_struct.array_trigger.getNumSubarrayTelescopes() 
         numpy_array = np.zeros(numSubarray,dtype='uint32')
         for i in range(numSubarray):
            numpy_array[i] = self.c_evt_struct.array_trigger.getL2ScalarRate(i)
         return numpy_array

    cpdef getRawEventTypeCode(self):
         return self.c_evt_struct.EventTypeCode

    cpdef getTriggerType(self):
         if(self.c_evt_struct.c_event == NULL):
             return 'NOT_LOADED'
         if(self.c_evt_struct.trigger == L2_TRIGGER):
             return 'L2_TRIGGER'
         if(self.c_evt_struct.trigger == PED_TRIGGER):
             return 'PED_TRIGGER'
         if(self.c_evt_struct.trigger == HIGH_MULT_TRIGGER):
             return 'HIGH_MULT_TRIGGER'
         if(self.c_evt_struct.trigger == NEW_PHYS_TRIGGER):
             return 'NEW_PHYS_TRIGGER'
         if(self.c_evt_struct.trigger == CAL_TRIGGER):
             return 'CAL_TRIGGER'

    cpdef getSamples(self):
         if (self.c_evt_struct.c_event == NULL):
            return np.ones((500,20),dtype='uint8')
         cdef int numChannels = self.c_evt_struct.numChannels  
         cdef int numSamples = self.c_evt_struct.numSamples  
         numpy_array = np.asarray(<np.uint8_t[:numChannels, :numSamples]>self.c_evt_struct.samplesPtr)
         return numpy_array.copy() 
 
    def get_sim_header(self):
        if(self.c_simheader == NULL):
            raise Exception("No simulation header loaded.")
        return self.c_simheader.fSimConfigFile         

    def get_current_packet_size(self):
        return self.c_packet.size()     

    def get_numPackets(self):
        return self.c_reader.numPackets()

    def get_RunNumber(self):
        return self.c_reader.getRunNumber()


    def __dealloc__(self):
        del self.c_packet
        del self.c_reader   

        
