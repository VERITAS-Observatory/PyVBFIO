#public public distutils: language= c++
from libcpp.string cimport string 
from libcpp cimport bool
from cython cimport view
cimport numpy as np
from VBF_C cimport *
import numpy as np


cdef struct Event:
    VEvent* c_event
    int     numSamples
    int     numChannels
    ubyte*  samplesPtr
    
cdef class PyVBFreader:
    cdef VBankFileReader* c_reader
    cdef VPacket*         c_packet
    cdef VSimulationHeader* c_simheader
    cdef VArrayEvent*       c_arrayevent
    cdef bool             is_loaded
    cdef np.int8_t        packet_type
    cdef Event            c_evt_struct
   
    def __cinit__(self,str fname,bool map_index=True,bool read_only=True):
        self.c_reader = new VBankFileReader(fname,map_index,read_only)
        self.c_packet = self.c_reader.readPacket(0)
        self.__check_packet_type__()
        self.is_loaded = False
        self.read_packet()

    # Check Packet Type
    cdef __check_packet_type__(self):

         if(self.c_packet.hasSimulationHeader()):
             self.packet_type = 0     
         elif(self.c_packet.hasArrayEvent()):
             self.packet_type = 1     
         elif(self.c_packet.hasSimulationData()):
             self.packet_type = 2
         elif(self.c_packet.hasCorsikaSimulationData()):
             self.packet_type = 3
         else:
             self.packet_type =-1

    def get_packet_type(self):
         return self.packet_type

    # Packet Loading
    cpdef go_to_packet(self,int i):
        del  self.c_packet 
        self.c_packet = self.c_reader.readPacket(i)
        self.__check_packet_type__()      
        self.read_packet()
 
    cdef read_packet(self):
        if(self.packet_type == 0): 
            self.c_simheader = self.c_packet.getSimulationHeader()
        elif(self.packet_type == 1):
            self.c_arrayevent = self.c_packet.getArrayEvent() 
        self.is_loaded = True

    cpdef loadEvent(self,int i):
        if (self.c_arrayevent == NULL):
           raise Exception("No ArrayEvent Loaded")
        self.c_evt_struct.c_event = self.c_arrayevent.getEventByNodeNumber(i)  
        if (self.c_evt_struct.c_event == NULL):
            return 
        else:
            self.c_evt_struct.numSamples  = self.c_evt_struct.c_event.getNumSamples()
            self.c_evt_struct.numChannels = self.c_evt_struct.c_event.getNumChannels()
            self.c_evt_struct.samplesPtr = self.c_evt_struct.c_event.getSamplePtr(0,0)  

    cpdef getSamples(self):
         if (self.c_evt_struct.c_event == NULL):
            return np.ones((500,20),dtype='uint8')
         cdef int numChannels = self.c_evt_struct.numChannels  
         cdef int numSamples = self.c_evt_struct.numSamples  
         numpy_array = np.asarray(<np.uint8_t[:numChannels, :numSamples]>self.c_evt_struct.samplesPtr)
         return numpy_array 
 
    def get_sim_header(self):
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

        
