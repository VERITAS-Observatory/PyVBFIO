#distutils: language= c++
from libcpp.string cimport string 
from libcpp cimport bool
from cython cimport view
cimport numpy as np
from VBF_C cimport *
import numpy as np

cdef class PyVBFreader:
    cdef VBankFileReader* c_reader
    cdef VPacket*         c_packet
    cdef VSimulationHeader* c_simheader
    cdef VArrayEvent*       c_arrayevent
    cdef VEvent*            c_event
    cdef bool             is_loaded
    cdef uword32          packet_type
    cdef view.array       samples 
   
    def __cinit__(self,str fname,bool map_index=True,bool read_only=True):
        self.c_reader = new VBankFileReader(fname,map_index,read_only)
        self.c_packet = self.c_reader.readPacket(0)
        self.__check_packet_type__()
        self.is_loaded = False
        self.read_packet()

    cdef __check_packet_type__(self):
         if(self.c_packet.hasSimulationHeader()):
             self.packet_type = 0     
         if(self.c_packet.hasArrayEvent()):
             self.packet_type = 1     
         if(self.c_packet.hasSimulationData()):
             self.packet_type = 2
         if(self.c_packet.hasCorsikaSimulationData()):
             self.packet_type = 3

    def get_packet_type(self):
         return self.packet_type

    cpdef go_to_packet(self,int i):
        del  self.c_packet 
        self.c_packet = self.c_reader.readPacket(i)
        self.__check_packet_type__()      
        self.read_packet()
 
    cdef read_packet(self):
        if(self.packet_type == 0): 
           try:
              self.c_simheader = self.c_packet.getSimulationHeader()
           except:
              pass #Temp solution 
        if(self.packet_type == 1):
            self.c_arrayevent = self.c_packet.getArrayEvent() 

        self.is_loaded = True

    cdef loadEvent(self,int i):
        self.c_event = self.c_arrayevent.getEventByNodeNumber(i)  
        
    cdef loadSamples(self):
         numSamples = self.c_event.getNumSamples()
         numChannels = self.c_event.getNumChannels()
         self.samples = <np.uint8_t[:numChannels, :numSamples]> self.c_event.getSamplePtr(0,0) 

    cpdef getSamples(self,int i):
         self.loadEvent(i)
         if (self.c_event == NULL):
            return np.ones((500,20),dtype='uint8')*-1
         self.loadSamples()
         numpy_array = np.asarray(self.samples)
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

        
