TARGET = adcinit bootfpga cgitraces.cgi gettraces progfippi runstats cgistats.cgi startdaq mcadaq pollcsr\
         findsettings cgireadsettings.cgi cgiwritesettings.cgi cgiprinttraces.cgi rampdacs udpena udpdis 
LIBS = -lm 
CFLAGS = -std=c99 -Wall
CXXFLAGS = -Wall -O3 -DNDEBUG   -pthread -std=gnu++98
INCDIRS = -I/usr  -I/usr/include -I/usr/local/include
LINKFLAGS =  -static -static-libstdc++
BOOSTLIBS = -L/usr/local/lib -lboost_date_time -lboost_chrono -lboost_atomic -lboost_program_options -lboost_system -lboost_thread -lrt -pthread
ZMQLIBS = -L/usr/local/lib -lzmq -lm

.PHONY: default all clean

default: $(TARGET)
all: default

%.o: %.c 
	gcc  $(CFLAGS) -c $< -o $@

%.o: %.cpp 
	g++  $(CXXFLAGS) $(INCDIRS) -c $< -o $@

adcinit: adcinit.o PixieNetCommon.o PixieNetDefs.h
	gcc adcinit.o PixieNetCommon.o $(LIBS) -o adcinit

bootfpga: bootfpga.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ bootfpga.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o bootfpga
	
cgitraces.cgi: cgitraces.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ cgitraces.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o cgitraces.cgi

cgireadsettings.cgi: cgireadsettings.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ cgireadsettings.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o cgireadsettings.cgi

cgiprinttraces.cgi: cgiprinttraces.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ cgiprinttraces.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o cgiprinttraces.cgi

gettraces: gettraces.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ gettraces.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o gettraces

rampdacs: rampdacs.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ rampdacs.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o rampdacs

progfippi: progfippi.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ progfippi.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o progfippi

runstats: runstats.o PixieNetCommon.o PixieNetDefs.h
	gcc runstats.o PixieNetCommon.o $(LIBS) -o runstats

cgistats.cgi: cgistats.o PixieNetCommon.o PixieNetDefs.h
	gcc cgistats.o PixieNetCommon.o $(LIBS) -o cgistats.cgi

startdaq: startdaq.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ startdaq.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o startdaq

mcadaq: mcadaq.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ mcadaq.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o mcadaq

coincdaq: coincdaq.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ coincdaq.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o coincdaq

findsettings: findsettings.o PixieNetConfig.o PixieNetDefs.h
	g++ findsettings.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o findsettings

acquire: acquire.o PixieNetConfig.o PixieNetCommon.o PixieNetDefs.h
	g++ acquire.o PixieNetCommon.o PixieNetConfig.o -rdynamic $(LINKFLAGS) $(LIBS) $(BOOSTLIBS) -o acquire

cgiwaveforms.cgi: cgiwaveforms.o PixieNetCommon.o PixieNetDefs.h
	gcc cgiwaveforms.o PixieNetCommon.o $(LIBS) -o cgiwaveforms.cgi

clockprog: clockprog.o PixieNetCommon.o PixieNetDefs.h
	gcc clockprog.o PixieNetCommon.o $(LIBS) -o clockprog

pollcsr: pollcsr.o PixieNetDefs.h
	gcc pollcsr.o $(LIBS) -o pollcsr

cgiwritesettings.cgi: cgiwritesettings.o PixieNetDefs.h
	g++ cgiwritesettings.o PixieNetCommon.o  $(LIBS) -o cgiwritesettings.cgi

udpena: udpena.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ udpena.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o udpena

udpdis: udpdis.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ udpdis.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o udpdis

writeI2C: writeI2C.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ writeI2C.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o writeI2C

clean:
	-rm -f *.o
	-rm -f $(TARGET)
