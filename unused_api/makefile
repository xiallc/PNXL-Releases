TARGET = pllinit adcinit bootfpga cgitraces.cgi gettraces progfippi runstats cgistats.cgi startdaq mcadaq netdaq findsettings cgireadsettings.cgi cgiwritesettings.cgi
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

pllinit: pllinit.o PixieNetCommon.o PixieNetDefs.h
	gcc pllinit.o PixieNetCommon.o $(LIBS) -o pllinit

bootfpga: bootfpga.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ bootfpga.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o bootfpga
	
cgitraces.cgi: cgitraces.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ cgitraces.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o cgitraces.cgi

cgireadsettings.cgi: cgireadsettings.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ cgireadsettings.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o cgireadsettings.cgi

gettraces: gettraces.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h
	g++ gettraces.o PixieNetCommon.o PixieNetConfig.o $(LIBS) -o gettraces

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

netdaq: netdaq.o PixieNetCommon.o PixieNetConfig.o PixieNetDefs.h log.o nts.o zhelpers.h
	g++ netdaq.o PixieNetCommon.o PixieNetConfig.o log.o nts.o $(ZMQLIBS) -o netdaq

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

clean:
	-rm -f *.o
	-rm -f $(TARGET)
