#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

//########################################################################
//
//  Pixie_InitGlobals:                                                                                  //
//     Initialize global variables, waves and paths.  
//                                         //
//########################################################################
Macro Pixie_InitGlobals()

	// Disable the display of Macro commands
	Silent 1
	
	// Create a new folder pixie4
	NewDataFolder/o root:pixie4
	
	Variable/G root:pixie4:ViewerVersion = 0x63E		// Pixie4 Viewer version set above in version check
	
	///////////////////////////////////////////////////////////// 
	// New Pixie-Net Variables
	///////////////////////////////////////////////////////////// 
		
	String/G root:pixie4:MZip = "192.168.1.59"
	Variable/G root:pixie4:evsize = 332
	Variable/G root:pixie4:localfile = 0
	Variable/G root:pixie4:webops = 1
	Variable/G root:pixie4:messages = 1
	Variable/G root:pixie4:warnings = 1
	Variable/G root:pixie4:RunType = 0x500
	Variable/G root:pixie4:tracesinpxp =0
	Variable/G root:pixie4:ModuleTypeXL=0		// 0/1 for Pixie Net / Pixie-Net XL
	Variable/G root:pixie4:ModuleType  = 0xA142	// the HW ID of a module from the LM data stream
	Variable/G root:pixie4:ChannelMapQuad1=0
	Variable/G root:pixie4:ChannelMapQuad2=0
	Variable/G root:pixie4:ChannelMapQuad3=0
	Variable/G root:pixie4:LMeventChannel
	String/G root:pixie4:lmfilename = "LMdata.bin"
	String/G root:pixie4:page
	String/G root:pixie4:parametername
	String/G root:pixie4:parametervalues
	make/o/n=32/u/i root:pixie4:LMfileheader
	make/o/n=32/u/i root:pixie4:LMeventheader
	make/o/n=23/u/i root:pixie4:LMeventheader104		// TODO: check if still needed
	make/o/n=1/u/i root:pixie4:LMtrace
	Pixie_Make_LMheadernames400()
	
	// top level waves for imports
	// RS.csv
	make/t/o/n=1 ParameterM, Module, ParameterC, Channel0, Channel1, Channel2, Channel3
	
	//list mode traces
	make/o/n=1 trace0
	make/t/o/n=8 header0

	make/o/n=1 alltraces
	
	// timing routines
	Pixie_Tdiff_globals()
	
	// PNXL specific
	Variable/G PlotCh0 =0
	Variable/G PlotCh1 =1
	Variable/G PlotCh2 =2
	Variable/G PlotCh3 =3
	Variable/G PlotCh4 =4
	Variable/G PlotCh5 =5
	Variable/G PlotCh6 =6
	Variable/G PlotCh7 =7
	
	// support up to 4 Pixie-Net XL boxes
	Variable/G root:pixie4:Nmodules = 4
	Variable/G root:pixie4:MaxNmodules = 4
	Variable/G root:pixie4:ModNum = 0
	Variable/G root:pixie4:WRdelay	// TODO: maybe this can be consolitated with WR_RTCtrl
	Variable/G root:pixie4:apply_all
	Variable/G root:pixie4:Run_Type     // the parameter in settings.ini
	Variable/G root:pixie4:Run_Time
	Variable/G root:pixie4:Zynq_CSR
	Variable/G root:pixie4:WR_RT_CTRL
	Variable/G root:pixie4:Data_Flow
	Variable/G root:pixie4:WR_TM_TAI
	
	make/t/o/n=(root:pixie4:MaxNmodules) root:pixie4:MZ_ip = {"192.168.1.96","192.168.1.97","192.168.1.98","192.168.1.99"}
	make/t/o/n=(root:pixie4:MaxNmodules) root:pixie4:MZ_user = {"webops","webops","webops","webops"}
	make/t/o/n=(root:pixie4:MaxNmodules) root:pixie4:MZ_pw = {"xia17pxn","xia17pxn","xia17pxn","xia17pxn"}
	
	String/G root:pixie4:ServerResponse
	
	Variable/G root:pixie4:MaxNchannelsPN   = 4
	Variable/G root:pixie4:MaxNchannelsPNXL = 16
	make/o/n=(root:pixie4:MaxNchannelsPNXL) root:pixie4:polarity
	make/o/n=(root:pixie4:MaxNchannelsPNXL) root:pixie4:voffset
	make/o/n=(root:pixie4:MaxNchannelsPNXL) root:pixie4:analog_gain
	make/o/n=(root:pixie4:MaxNchannelsPNXL) root:pixie4:digital_gain
	make/o/n=(root:pixie4:MaxNchannelsPNXL) root:pixie4:tau
	
	// For parsing LM data -- defaults to 0x400
	Variable/G root:pixie4:EventLength
	Variable/G root:pixie4:iMType = 7
	Variable/G root:pixie4:iHitL  = 0
	Variable/G root:pixie4:iHitM  = 1
	Variable/G root:pixie4:iTimeL = 4
	Variable/G root:pixie4:iTimeM = 5
	Variable/G root:pixie4:iTimeH = 6
	Variable/G root:pixie4:iTimeX = 7
	Variable/G root:pixie4:iEnergy  = 8
	Variable/G root:pixie4:iChannel = 9
	Variable/G root:pixie4:iCFDresult = 11
	Variable/G root:pixie4:iPSAmax = 10
	Variable/G root:pixie4:iPSAbase = 12
	Variable/G root:pixie4:iPSAsum0 = 13
	Variable/G root:pixie4:iPSAsum1 = 14
	Variable/G root:pixie4:iPSAresult = 15
	Variable/G root:pixie4:iCFDinfo  = -1
	Variable/G root:pixie4:iCFDsum1  = -1
	Variable/G root:pixie4:iCFDsum12 = -1
	Variable/G root:pixie4:iCFDsum2  = -1
	
	
	///////////////////////////////////////////////////////////// 
	// Constants definitions                         //
	////////////////////////////////////////////////////////////
	
	Variable/G root:pixie4:NumberOfModules = 1	
	Variable/G root:pixie4:NumberOfChannels = 4		// number of channels	
	Variable/G root:pixie4:ADCTraceLen = 8192			// maximum ADC trace length
	Variable/G root:pixie4:MCALen = 32768				// maximum MCA histogram length

	///////////////////////////////////////////////////////////// 
	// System Setup global variables		//
	////////////////////////////////////////////////////////////
	
	Variable/G root:pixie4:ChosenModule
	Variable/G root:pixie4:ChosenChannel
	Variable/G root:pixie4:HideDetail // how many controls to show
	Variable/G root:pixie4:FirstTimeUse		
	Variable/G root:pixie4:Pixie4Offline
	
	///////////////////////////////////////////////////////////// 
	// Calibrate global variables	                          //
	////////////////////////////////////////////////////////////	

	Variable/G root:pixie4:LastTau
	Variable/G root:pixie4:TauDeviation

	///////////////////////////////////////////////////////////// 
	// Analyze global variables	                   //
	////////////////////////////////////////////////////////////
	
	Variable/G root:pixie4:StartTime_s		//start time/date in seconds from 1904
	Variable/G root:pixie4:StopTime_s		//stop time/date in seconds from 1904
	Variable/G root:pixie4:CurrentTime_s	//last statistics readout time/date in seconds from 1904
	String/G root:pixie4:InfoSource			//can be file or read from module
	String/G root:pixie4:MCASource			//can be file or read from module
	String/G root:pixie4:StartTime
	String/G root:pixie4:SeriesStartTime
	String/G root:pixie4:StopTime
	
	Variable/G root:pixie4:EFRT  = 0.1	// filter variables
	Variable/G root:pixie4:EFFT  = 0.1
	Variable/G root:pixie4:EFINT = 0
	Variable/G root:pixie4:TFRT  = 0.048
	Variable/G root:pixie4:TFFT  = 0.048
	Variable/G root:pixie4:TFTH  = 10
	
	
	///////////////////////////////////////////////////////////// 
	// Graph global variables	                   //
	////////////////////////////////////////////////////////////

	Variable/G root:pixie4:FFTbin
	Make/o/n=(root:pixie4:ADCTraceLen) root:pixie4:TauTrace
	Make/o/n=(root:pixie4:ADCTraceLen) root:pixie4:TraceFFT
	Make/o/n=(root:pixie4:ADCTraceLen) root:pixie4:TraceFilter
	Make/o/n=(root:pixie4:ADCTraceLen) root:pixie4:TraceFilterSF
	Make/o/n=(root:pixie4:ADCTraceLen) root:pixie4:TraceFilterFF
	Make/o/n=(root:pixie4:ADCTraceLen) root:pixie4:TraceFilterSFMarkers
	Make/o/n=(root:pixie4:ADCTraceLen) root:pixie4:TraceTH
	// Added /i/u to avoid "bit errors" obvious with test patterns
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch0
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch1
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch2
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch3
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch4
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch5
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch6
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch7
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch8
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch9
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch10
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch11
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch12
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch13
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch14
	Make/o/i/u/n=(root:pixie4:ADCTraceLen) root:pixie4:ADCch15
	Make/o/n=1 root:pixie4:sf
	Make/o/n=1 root:pixie4:ff
	Make/o/n=1 root:pixie4:seltrace
	Make/o/n=1 root:pixie4:th
	Make/o/n=1 root:pixie4:sfmarkers
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch0
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch1
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch2
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch3
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch4
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch5
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch6
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch7
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch8
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch9
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch10
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch11
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch12
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch13
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch14
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAch15
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAref		
	Make/o/i/u/n=(root:pixie4:MCALen) root:pixie4:MCAsum	
	Make/o/i/u/n=1 root:pixie4:Spectrum0
	Make/o/i/u/n=1 root:pixie4:Spectrum1
	Make/o/i/u/n=1 root:pixie4:Spectrum2
	Make/o/i/u/n=1 root:pixie4:Spectrum3
	Make/o/i/u/n=1 root:pixie4:Spectrum4
	Make/o/i/u/n=1 root:pixie4:Spectrum5
	Make/o/i/u/n=1 root:pixie4:Spectrum6
	Make/o/i/u/n=1 root:pixie4:Spectrum7
	Make/o/i/u/n=1 root:pixie4:SpectrumRef					
	Variable/G root:pixie4:xmax
	Variable/G root:pixie4:xmin	
	Make/o/i/n=1 root:pixie4:trace0
	Make/o/i/n=1 root:pixie4:trace1
	Make/o/i/n=1 root:pixie4:trace2
	Make/o/i/n=1 root:pixie4:trace3
	Make/o/i/n=1 root:pixie4:trace4
	Make/o/i/n=1 root:pixie4:trace5
	Make/o/i/n=1 root:pixie4:trace6
	Make/o/i/n=1 root:pixie4:trace7
	Make/o/i/n=1 root:pixie4:trace8
	Make/o/i/n=1 root:pixie4:trace9
	Make/o/i/n=1 root:pixie4:trace10
	Make/o/i/n=1 root:pixie4:trace11
	Make/o/i/n=1 root:pixie4:trace12
	Make/o/i/n=1 root:pixie4:trace13
	Make/o/i/n=1 root:pixie4:trace14
	Make/o/i/n=1 root:pixie4:trace15
	Make/o/i/n=1 root:pixie4:traceRef					
	Variable/G root:pixie4:wftimescale	// sampling interval of LM traces (seconds)
	
	///////////////////////////////////////////////////////////// 
	// Gauss fit global variables                    //
	////////////////////////////////////////////////////////////
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAStartFitChannel
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAEndFitChannel
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAFitRange
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAscale
	root:pixie4:MCAStartFitChannel = 1
	root:pixie4:MCAEndFitChannel = 32768
	root:pixie4:MCAFitRange = 1
	root:pixie4:MCAscale = 1
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAChannelPeakPos
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAChannelPeakEnergy
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAChannelFWHMPercent
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAChannelFWHMAbsolute
	Make/o/n=(root:pixie4:NumberOfChannels*2+2) root:pixie4:MCAChannelPeakArea
	Make/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListStartFitChannel
	Make/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListEndFitChannel
	Make/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListChannelPeakPos
	Make/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListChannelFWHMPercent
	Make/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListChannelPeakArea
	
	Variable/G root:pixie4:MCAfitOption


	///////////////////////////////////////////////////////////// 
	// Histogram global variables                  //
	////////////////////////////////////////////////////////////	
	Variable/G root:pixie4:NHistoBins
	Variable/G root:pixie4:HistoDE
	Variable/G root:pixie4:HistoEmin
	Variable/G root:pixie4:HistoFirstEvent
	Variable/G root:pixie4:HistoLastEvent
	Make/o/n=(root:pixie4:NumberOfChannels) root:pixie4:Emink
	Make/o/n=(root:pixie4:NumberOfChannels) root:pixie4:dxk	
	Make/o/n=(root:pixie4:NumberOfChannels) root:pixie4:Nbink
	
	///////////////////////////////////////////////////////////// 
	// Pulse Shape Analysis global variables //
	////////////////////////////////////////////////////////////
	Variable/G root:pixie4:ChosenEvent
	variable/G root:pixie4:EventHitpattern
	variable/G root:pixie4:EventTimeHI
	variable/G root:pixie4:EventTimeLO
	Make/u/i/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListModeChannelEnergy
	Make/u/i/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListModeChannelTrigger
	Make/u/i/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListModeChannelXIA
	Make/u/i/o/n=(root:pixie4:NumberOfChannels+1) root:pixie4:ListModeChannelUser
	Variable/G root:pixie4:EvHit_Front
	Variable/G root:pixie4:EvHit_Accept
	Variable/G root:pixie4:EvHit_Status
	Variable/G root:pixie4:EvHit_Token
	Variable/G root:pixie4:EvHit_CoincOK
	Variable/G root:pixie4:EvHit_Veto
	Variable/G root:pixie4:EvHit_PiledUp
	Variable/G root:pixie4:EvHit_WvFifoFull
	Variable/G root:pixie4:EvHit_ChannelHit
	Variable/G root:pixie4:EvHit_OOR
	Variable/G root:pixie4:EvHit_Derror
	
	///////////////////////////////////////////////////////////// 
	//color wave for lists			             //
	////////////////////////////////////////////////////////////
	Make/o/u/w/n=(9,3) root:pixie4:ListColorWave
	root:pixie4:ListColorWave[0][0]=61440 // color 0: unused?: light green 
	root:pixie4:ListColorWave[0][1]=64256
	root:pixie4:ListColorWave[0][2]=57600
//	root:pixie4:ListColorWave[1][0]=51456 // color 1: default non-editable cells: purple
//	root:pixie4:ListColorWave[1][1]=44032
//	root:pixie4:ListColorWave[1][2]=58880
//	root:pixie4:ListColorWave[1][0]=61440 // color 1: default non-editable cells: light green
//	root:pixie4:ListColorWave[1][1]=64256
//	root:pixie4:ListColorWave[1][2]=57600	
	root:pixie4:ListColorWave[1][0]=62256 // color 1: default non-editable cells: almost white
	root:pixie4:ListColorWave[1][1]=62256
	root:pixie4:ListColorWave[1][2]=62256	
	root:pixie4:ListColorWave[2][0]=60928 // color 2: editable cells: light gray
	root:pixie4:ListColorWave[2][1]=60928
	root:pixie4:ListColorWave[2][2]=60928
	root:pixie4:ListColorWave[3][0]=65280 // color 3: ch.0: red
	root:pixie4:ListColorWave[3][1]=0
	root:pixie4:ListColorWave[3][2]=0
	root:pixie4:ListColorWave[4][0]=0 // color 4: ch.1: bright green
	root:pixie4:ListColorWave[4][1]=58880
	root:pixie4:ListColorWave[4][2]=0
	root:pixie4:ListColorWave[5][0]=0 // color 5: ch.2: blue
	root:pixie4:ListColorWave[5][1]=15872
	root:pixie4:ListColorWave[5][2]=65280
	root:pixie4:ListColorWave[6][0]=0 // color 6: ch.3: dark green
	root:pixie4:ListColorWave[6][1]=26112
	root:pixie4:ListColorWave[6][2]=0
	root:pixie4:ListColorWave[7][0]=30000 // color 7: ref channel/other: dark gray (for black)
	root:pixie4:ListColorWave[7][1]=30000
	root:pixie4:ListColorWave[7][2]=30000
	root:pixie4:ListColorWave[8][0]=36864 // color 8: addback/other purple
	root:pixie4:ListColorWave[8][1]=14592
	root:pixie4:ListColorWave[8][2]=58880
	
	// initialize lists
	Pixie_MakeList_AllRunStats(0)
	Pixie_MakeList_LMHisto()
	Pixie_MakeList_MCA(0)
	Pixie_MakeList_Traces(0)
	
	///////////////////////////////////////////////////////////// 
	// User accessible output data	             //
	////////////////////////////////////////////////////////////	
	
	// Create a new folder for output data
	NewDataFolder/o root:results
	
	//statistics
	Variable/G root:results:RunTime
	Variable/G root:results:EventRate
	Variable/G root:results:NumEvents		
	Make/o/n=(root:pixie4:NumberOfChannels) root:results:ChannelCountTime
	Make/o/n=(root:pixie4:NumberOfChannels) root:results:ChannelInputCountRate
	String/G root:results:StartTime
	String/G root:results:StopTime
	
	//MCAs
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch0
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch1
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch2
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch3
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch4
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch5
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch6
	Make/o/n=(root:pixie4:MCALen) root:results:MCAch7
	make/o/n=16384 root:results:MCAsum
	
	//traces and list mode data
	Make/o/n=1 root:results:trace0
	Make/o/n=1 root:results:trace1
	Make/o/n=1 root:results:trace2
	Make/o/n=1 root:results:trace3
	Make/o/n=1 root:results:trace4
	Make/o/n=1 root:results:trace5
	Make/o/n=1 root:results:trace6
	Make/o/n=1 root:results:trace7
	
	
	///////////////////////////////////////////////////////////// 
	// Call to user routine			             //
	////////////////////////////////////////////////////////////	
	
	NewDataFolder/o root:user						//create the user data folder
	Variable/G root:user:UserVersion = 0x0200	// the version of the user function calls defined by XIA
	User_Globals()
	
	SetDataFolder root:
	

EndMacro



Function Pixie_Tdiff_globals()

	NewDataFolder/O root:LM

	Variable/G  root:LM:oldNevents 	=0			// remember previous number of events
	Variable/G  root:LM:Nevents 					// number of events
	Variable/G  root:LM:MaxEvents 	=1000		// maximum number of events to process
	
	Variable/G root:LM:DiffA_P						// specify channels to build difference
	Variable/G root:LM:DiffA_N
	Variable/G root:LM:DiffB_P
	Variable/G root:LM:DiffB_N
	Variable/G root:LM:DiffC_P
	Variable/G root:LM:DiffC_N

	Variable/G  root:LM:DiffA_CFD 				// use CFD or just TS
	Variable/G  root:LM:DiffB_CFD
	Variable/G  root:LM:DiffC_CFD
		
	Variable/G root:LM:NbinsTA = 256				// histogramming options
	Variable/G root:LM:BinsizeTA = 8
	Variable/G root:LM:NbinsTB = 256
	Variable/G root:LM:BinsizeTB = 8
	Variable/G root:LM:NbinsTC = 256
	Variable/G root:LM:BinsizeTC = 8
	make/o/n=1 root:LM:ThistoA, root:LM:ThistoB, root:LM:ThistoC	
	
	Variable/G  root:LM:CFD_Mode_online	// select from online, Igor from traces, Igor from 4 raw, etc 
	Variable/G  root:LM:CFD_Mode_4raw
	Variable/G  root:LM:CFD_Mode_Igorwf
	
	Variable/G  root:LM:DiffA_cut
	Variable/G  root:LM:ElowP = 8200			// limits for energy cut
	Variable/G  root:LM:EhighP = 8900	
	Variable/G  root:LM:ElowN = 7200
	Variable/G  root:LM:EhighN = 8000
	
	
	
	Pixie_Make_Tdiffwaves(1)	// makes waves for the LM header values
	
	// variables for trace processing	
	variable/G  root:LM:LB = 12 					// length of baseline sum
	variable/G  root:LM:RTlow = 0.5				// CF threshold
	variable/G  root:LM:TSscale = 1
	variable/G  root:LM:defaultTriggerPos =20	// starting point to look for triggers. must be greater than LB
	String/G    root:LM:CFDsource = " "

End



//########################################################################
//
//  Pixie_Cleanup:                                                                                      //
//     resize and remove global arrays              
//                                             
//########################################################################
Proc Pixie_Cleanup()

	// set default values that are hidden, Clib or Igor only, and may interfere with acquisition unexpectedly
	Pixie_Ctrl_CommonButton("ResetScaleMCA")
	
	make/t/o/n=1 ParameterM, Module, ParameterC, Channel0, Channel1, Channel2, Channel3	// RS import
	make/o/n=1 trace0
	make/t/o/n=8 header0
	make/o/n=1 alltraces
	make/o/n=(100,2) wfarray
	
	KillDataFolder/Z root:test
	
	Killwaves/Z exmem, buffer
	Killwaves/Z LMdata0, LMheader
	Killwaves/Z bin, MCAch0, MCAch1, MCAch2, MCAch3	// MCA import
	Killwaves/Z bin, MCAch4, MCAch5, MCAch6, MCAch7	// MCA import
	Killwaves/Z adc0, adc1, adc2, adc3	// ADC import PN
	Killwaves/Z sample
	Killwaves/Z adc00, adc01, adc02, adc03, adc04, adc05, adc06, adc07	// ADC import PNXL
	Killwaves/Z adc08, adc09, adc10, adc11, adc12, adc13, adc14, adc15	// ADC import PNXL
	
	Pixie_Make_Tdiffwaves(1)	

End


//########################################################################
//
// LM data file analysis definitions
//
//########################################################################
Function Pixie_SetTimeScales()

	Nvar ModuleType = root:pixie4:ModuleType
	Nvar wftimescale = root:pixie4:wftimescale			// sample interval in seconds  as read from the file (or entered manually)
	Nvar WFscale =root:pixie4:WFscale 					// sample interval in ns (user entry in panel)	
	Nvar TSscale = root:LM:TSscale

	if(ModuleType>0)		// extract sampling rate from DB type TODO: add Pixie-Net, PH, P4e
		if((ModuleType&0x0FF0)==0x0110)			// Pixie-Net XL
			WFscale = 8
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x0120)
			WFscale = 4
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x0140)
			WFscale = 4
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x0150)
			WFscale = 4	
			TSscale = 1				
		elseif((ModuleType&0x0FF0)==0x0160)
			WFscale = 4
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x0170)
			WFscale = 2
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x0180)
			WFscale = 4
			TSscale = 1	
		elseif((ModuleType&0x0FF0)==0x0190)
			WFscale = 4
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x01A0)
			WFscale = 2
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x0990)		// Pixie-Net
			WFscale = 4
			TSscale = 1
		elseif((ModuleType&0x0FF0)==0x0190)		// Pixie Hybrid 16/250
			WFscale = 4
			TSscale = 2
		elseif((ModuleType&0x0FF0)==0x0190)		// Pixie Hybrid 14/500
			WFscale = 2
			TSscale = 2
		elseif((ModuleType&0x0FF0)==0x0190)		// Pixie Hybrid 14/100
			WFscale = 10
			TSscale = 2	// double check
		elseif((ModuleType&0x0FF0)==0x0550)		// Pixie-4e 16/125
			WFscale = 8
			TSscale = 2
		elseif((ModuleType&0x0FF0)==0x05E0)		// Pixie-4e 14/500
			WFscale = 4
			TSscale = 2					
		endif
	else
		//print "Can not get waveform sampling interval from file, using the user provided number"						
	endif
	wftimescale = WFscale*1e-9	// use [updated] panel value

End

Function Pixie_Make_LMheadernames110()

	make/t/o/n=64 root:pixie4:LMheadernames
	wave/t LMheadernames = root:pixie4:LMheadernames
	LMheadernames = " "
	LMheadernames[0]  = "HdLen "	
	LMheadernames[1]  = "ModuleType "	
	LMheadernames[2]  = "RunType "	
	LMheadernames[3]  = "Crate/Slot/ChanID"
	LMheadernames[4]  = "EvHdLen "
	LMheadernames[5]  = "EvtimeL "
	LMheadernames[6]  = "EvtimeM "
	LMheadernames[7]  = "EvtimeH "
	LMheadernames[8]  = "CFD frac+bits "
	LMheadernames[9]  = "Energy "
	LMheadernames[10] = "TraceLen+OOR "
	LMheadernames[11] = "Tsum / PSA max"
	LMheadernames[12] = "Tsum / PSA base"
	LMheadernames[13] = "Lsum / PSA sum 0"
	LMheadernames[14] = "Lsum / PSA sum 1"
	LMheadernames[15] = "Gsum / CFD info"
	LMheadernames[16] = "Gsum / CFD sum 1"
	LMheadernames[17] = "BL / CFD sum 2/1"
	LMheadernames[18] = "BL / CFD sum 2"
	LMheadernames[19] = "ExtTSL "
	LMheadernames[20] = "ExtTSM "	
	LMheadernames[21] = "ExtTSH "
	LMheadernames[22] = "unused "	
	
	// set the indices
	Nvar iMType = root:pixie4:iMType 
	Nvar iHitL  = root:pixie4:iHitL 
	Nvar iHitM  = root:pixie4:iHitM 
	Nvar iTimeL = root:pixie4:iTimeL 
	Nvar iTimeM = root:pixie4:iTimeM 
	Nvar iTimeH = root:pixie4:iTimeH
	Nvar iTimeX = root:pixie4:iTimeX 
	Nvar iEnergy    = root:pixie4:iEnergy  
	Nvar iChannel   = root:pixie4:iChannel 
	Nvar iCFDresult = root:pixie4:iCFDresult 
	Nvar iPSAmax    = root:pixie4:iPSAmax 
	Nvar iPSAbase   = root:pixie4:iPSAbase 
	Nvar iPSAsum0   = root:pixie4:iPSAsum0 
	Nvar iPSAsum1   = root:pixie4:iPSAsum1 
	Nvar iPSAresult = root:pixie4:iPSAresult 
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2
	iMType = 1
	iHitL  = -1
	iHitM  = -1 
	iTimeL = 5 
	iTimeM = 6 
	iTimeH = 7
	iTimeX = -1
	iEnergy    = 9 
	iChannel   = -1
	iCFDresult = -1
	iPSAmax    = 11
	iPSAbase   = 12
	iPSAsum0   = 13
	iPSAsum1   = 14
	iPSAresult = -1
	iCFDinfo   = 15
	iCFDsum1   = 16
	iCFDsum12  = 17
	iCFDsum2   = 18
	
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype
	evsize = LMfileheader[0] + (LMfileheader[10] & 0x7FFF) 		// assuming all are the same as ch.0 
	runtype = LMfileheader[2]
	
	Nvar ModuleType = root:pixie4:ModuleType
	ModuleType = LMfileheader[iMType]
	Pixie_SetTimeScales()
	
	Svar CFDsource  =  root:LM:CFDsource
	CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	//CFDsource = "none"

End

Function Pixie_Make_LMheadernames116()	// P16 0x100, not P4 0x100

	make/t/o/n=64 root:pixie4:LMheadernames
	wave/t LMheadernames = root:pixie4:LMheadernames
	LMheadernames = " "
	LMheadernames[0]  = "Crate/Slot/ChanID"
	LMheadernames[1]  = "EvHdLen "
	LMheadernames[2]  = "EvtimeL "
	LMheadernames[3]  = "EvtimeM "
	LMheadernames[4]  = "EvtimeH "
	LMheadernames[5]  = "CFD frac+bits "
	LMheadernames[6]  = "Energy "
	LMheadernames[7]  = "TraceLen+OOR "
	LMheadernames[8]  = "Tsum / PSA max"
	LMheadernames[9]  = "Tsum / PSA base"
	LMheadernames[10] = "Lsum / PSA sum0"
	LMheadernames[11] = "Lsum / PSA sum1"
	LMheadernames[12] = "Gsum / CFD info"
	LMheadernames[13] = "Gsum / CFD sum1"
	LMheadernames[14] = "BL / CFD sum 2/1"
	LMheadernames[15] = "BL / CFD sum 2"
	LMheadernames[16] = "ExtTSL "
	LMheadernames[17] = "ExtTSM "	
	LMheadernames[18] = "ExtTSH "
	LMheadernames[19] = "unused "	
	
	// set the indices
	Nvar iMType = root:pixie4:iMType 
	Nvar iHitL  = root:pixie4:iHitL 
	Nvar iHitM  = root:pixie4:iHitM 
	Nvar iTimeL = root:pixie4:iTimeL 
	Nvar iTimeM = root:pixie4:iTimeM 
	Nvar iTimeH = root:pixie4:iTimeH
	Nvar iTimeX = root:pixie4:iTimeX 
	Nvar iEnergy    = root:pixie4:iEnergy  
	Nvar iChannel   = root:pixie4:iChannel 
	Nvar iCFDresult = root:pixie4:iCFDresult 
	Nvar iPSAmax    = root:pixie4:iPSAmax 
	Nvar iPSAbase   = root:pixie4:iPSAbase 
	Nvar iPSAsum0   = root:pixie4:iPSAsum0 
	Nvar iPSAsum1   = root:pixie4:iPSAsum1 
	Nvar iPSAresult = root:pixie4:iPSAresult 
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2 
	iMType = -1
	iHitL  = -1
	iHitM  = -1 
	iTimeL = 2 
	iTimeM = 3 
	iTimeH = 4
	iTimeX = -1
	iEnergy    = 6 
	iChannel   = -1
	iCFDresult = 5
	iPSAmax    = 8
	iPSAbase   = 9
	iPSAsum0   = 10
	iPSAsum1   = 11
	iPSAresult = -1
	iCFDinfo   = 12
	iCFDsum1   = 13
	iCFDsum12  = 14
	iCFDsum2   = 15
	
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype
	evsize = (LMfileheader[1] & 0x7FFE)		// assuming all are the same as ch.0 
	runtype = 0x116
	
	// no moduletype, waveform time scale is unknown
	Nvar wftimescale = root:pixie4:wftimescale			// sample interval in seconds  as read from the file (or entered manually)
	Nvar WFscale =root:pixie4:WFscale 					// sample interval in ns (user entry in panel)	
	Nvar TSscale = root:LM:TSscale
	TSscale = 8	
	wftimescale = WFscale*1e-9	// use [updated] panel value
	
	Svar CFDsource  =  root:LM:CFDsource
	//CFDsource = "FPGA (4w raw)"
	CFDsource = "DSP/ARM (1w fraction)"
	//CFDsource = "none"

End


Function Pixie_Make_LMheadernames400()

	make/t/o/n=64 root:pixie4:LMheadernames
	wave/t LMheadernames = root:pixie4:LMheadernames
	LMheadernames = " "
	LMheadernames[0] = "BlkSize"
	LMheadernames[1] = "ModNum "
	LMheadernames[2] = "RunFormat "
	LMheadernames[3] = "ChanHeadLen "
	LMheadernames[4] = "CoincPat "
	LMheadernames[5] = "CoincWin "
	LMheadernames[6] = "MaxCombEventLen"
	LMheadernames[7] = "Module Type "
	LMheadernames[8] = "EventLength0 "
	LMheadernames[9] = "EventLength1 "
	LMheadernames[10] = "EventLength2 "
	LMheadernames[11] = "EventLength3 "
	LMheadernames[12] = "Serial Number "
	LMheadernames[32] = "EvtPattern "
	LMheadernames[33] = "EvtInfo  "
	LMheadernames[34] = "NumTraceBlks "
	LMheadernames[35] = "NumTraceBlksPrev "
	LMheadernames[36] = "TrigTimeLO "
	LMheadernames[37] = "TrigTimeMI "
	LMheadernames[38] = "TrigTimeHI "
	LMheadernames[39] = "TrigTimeX "
	LMheadernames[40] = "Energy "
	LMheadernames[41] = "ChanNo "
	LMheadernames[42] = "User PSA Value (A)"
	LMheadernames[43] = "XIA PSA Value (CFD)"
	LMheadernames[44] = "Extended PSA Values0 (B)"
	LMheadernames[45] = "Extended PSA Values1 (Q0)"
	LMheadernames[46] = "Extended PSA Values2 (Q1)"
	LMheadernames[47] = "Extended PSA Values3 (R)"
	LMheadernames[48] = "8 lo"
	LMheadernames[49] = "8 hi"
	LMheadernames[50] = "9 lo"
	LMheadernames[51] = "9 hi"
	LMheadernames[52] = "10 lo"
	LMheadernames[53] = "10 hi"
	LMheadernames[54] = "11 lo"
	LMheadernames[55] = "11 hi"
	LMheadernames[56] = "12 lo"
	LMheadernames[57] = "12 hi"
	LMheadernames[58] = "13 lo"
	LMheadernames[59] = "13 hi"
	LMheadernames[60] = "checksum"
	LMheadernames[61] = "checksum"
	LMheadernames[62] = "watermark"
	LMheadernames[63] = "watermark"
	
	// set the indices
	Nvar iMType = root:pixie4:iMType 
	Nvar iHitL  = root:pixie4:iHitL 
	Nvar iHitM  = root:pixie4:iHitM 
	Nvar iTimeL = root:pixie4:iTimeL 
	Nvar iTimeM = root:pixie4:iTimeM 
	Nvar iTimeH = root:pixie4:iTimeH
	Nvar iTimeX = root:pixie4:iTimeX 
	Nvar iEnergy    = root:pixie4:iEnergy  
	Nvar iChannel   = root:pixie4:iChannel 
	Nvar iCFDresult = root:pixie4:iCFDresult 
	Nvar iPSAmax    = root:pixie4:iPSAmax 
	Nvar iPSAbase   = root:pixie4:iPSAbase 
	Nvar iPSAsum0   = root:pixie4:iPSAsum0 
	Nvar iPSAsum1   = root:pixie4:iPSAsum1 
	Nvar iPSAresult = root:pixie4:iPSAresult
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2 
	iMType = 7 
	iHitL  = 0
	iHitM  = 1 
	iTimeL = 4 
	iTimeM = 5 
	iTimeH = 6 
	iTimeX = 7 
	iEnergy    = 8 
	iChannel   = 9
	iCFDresult = 11
	iPSAmax    = 10
	iPSAbase   = 12
	iPSAsum0   = 13
	iPSAsum1   = 14
	iPSAresult = 15
	iCFDinfo   = -1
	iCFDsum1   = -1
	iCFDsum12  = -1
	iCFDsum2   = -1
	
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype

	variable blksize
	BlkSize = LMfileheader[0]
	evsize = LMfileheader[8]	* BlkSize		// assuming all are the same as ch.0 
	runtype = LMfileheader[2]
	
	
	Nvar ModuleType = root:pixie4:ModuleType
	ModuleType = LMfileheader[iMType]
	Pixie_SetTimeScales()
	
	Svar CFDsource  =  root:LM:CFDsource
	//CFDsource = "FPGA (4w raw)"
	CFDsource = "DSP/ARM (1w fraction)"
	//CFDsource = "none"

End

Function Pixie_Make_LMheadernames402()

	make/t/o/n=64 root:pixie4:LMheadernames
	wave/t LMheadernames = root:pixie4:LMheadernames
	LMheadernames = " "
	LMheadernames[0] = "BlkSize"
	LMheadernames[1] = "ModNum "
	LMheadernames[2] = "RunFormat "
	LMheadernames[3] = "ChanHeadLen "
	LMheadernames[4] = "CoincPat "
	LMheadernames[5] = "CoincWin "
	LMheadernames[6] = "MaxCombEventLen "
	LMheadernames[7] = "Module Type "
	LMheadernames[8] = "EventLength0 "
	LMheadernames[9] = "EventLength1 "
	LMheadernames[10] = "EventLength2 "
	LMheadernames[11] = "EventLength3 "
	LMheadernames[12] = "Serial Number "
	LMheadernames[32] = "EvtPattern "
	LMheadernames[33] = "EvtInfo  "
	LMheadernames[34] = "NumTraceBlks "
	LMheadernames[35] = "NumTraceBlksPrev "
	LMheadernames[36] = "TrigTimeHI "
	LMheadernames[37] = "TrigTimeX "
	LMheadernames[38] = "E sum "
	LMheadernames[39] = " "
	LMheadernames[40] = "TrigTimeLO_0 "
	LMheadernames[41] = "TrigTimeMI_0 "
	LMheadernames[42] = "Energy_0"
	LMheadernames[43] = "NumTraceBlks_0 "
	LMheadernames[44] = "TrigTimeLO_1"
	LMheadernames[45] = "TrigTimeMI_1"
	LMheadernames[46] = "Energy_1"
	LMheadernames[47] = "NumTraceBlks_1"
	LMheadernames[48] = "TrigTimeLO_2"
	LMheadernames[49] = "TrigTimeMI_2"
	LMheadernames[50] = "Energy_2"
	LMheadernames[51] = "NumTraceBlks_2"
	LMheadernames[52] = "TrigTimeLO_3"
	LMheadernames[53] = "TrigTimeMI_3"
	LMheadernames[54] = "Energy_3"
	LMheadernames[55] = "NumTraceBlks_3"
	LMheadernames[56] = "Evt info 0,1"
	LMheadernames[57] = "Evt info 2,3"
	LMheadernames[58] = "EventTimeLO"
	LMheadernames[59] = "EventTimeMI"
	LMheadernames[60] = "checksum"
	LMheadernames[61] = "checksum"
	LMheadernames[62] = "watermark"
	LMheadernames[63] = "watermark"
	
	// set the indices
	Nvar iMType = root:pixie4:iMType 
	Nvar iHitL  = root:pixie4:iHitL 
	Nvar iHitM  = root:pixie4:iHitM 
	Nvar iTimeL = root:pixie4:iTimeL 
	Nvar iTimeM = root:pixie4:iTimeM 
	Nvar iTimeH = root:pixie4:iTimeH
	Nvar iTimeX = root:pixie4:iTimeX 
	Nvar iEnergy    = root:pixie4:iEnergy  
	Nvar iChannel   = root:pixie4:iChannel 
	Nvar iCFDresult = root:pixie4:iCFDresult 
	Nvar iPSAmax    = root:pixie4:iPSAmax 
	Nvar iPSAbase   = root:pixie4:iPSAbase 
	Nvar iPSAsum0   = root:pixie4:iPSAsum0 
	Nvar iPSAsum1   = root:pixie4:iPSAsum1 
	Nvar iPSAresult = root:pixie4:iPSAresult 
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2 
	iMType = 7 
	iHitL  = 0
	iHitM  = 1 
	iTimeL = 26 
	iTimeM = 27 
	iTimeH = 4
	iTimeX = 5 
	iEnergy    = -1 
	iChannel   = -1
	iCFDresult = -1
	iPSAmax    = -1
	iPSAbase   = -1
	iPSAsum0   = -1
	iPSAsum1   = -1
	iPSAresult = -1
	iCFDinfo   = -1
	iCFDsum1   = -1
	iCFDsum12  = -1
	iCFDsum2   = -1
	
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype
	variable blksize
	BlkSize = LMfileheader[0]
	evsize = LMfileheader[6]	* BlkSize		// assuming all are the same as ch.0 
	runtype = LMfileheader[2]
	
	Nvar ModuleType = root:pixie4:ModuleType
	ModuleType = LMfileheader[iMType]
	Pixie_SetTimeScales()
	
	Svar CFDsource  =  root:LM:CFDsource
	//CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	CFDsource = "none"
	
End

Function Pixie_Make_LMheadernames404()

	make/t/o/n=64 root:pixie4:LMheadernames
	wave/t LMheadernames = root:pixie4:LMheadernames
	LMheadernames = " "
	LMheadernames[0] = "EventHeadLen"
	LMheadernames[1] = "ModuleType "
	LMheadernames[2] = "RunType"
	LMheadernames[3] = "ADC rate "
	LMheadernames[4] = "ADC bits "
	LMheadernames[5] = "FW version "
	LMheadernames[6] = "UDP_COUNT "
	
	LMheadernames[07] = "EvtPattern "
	LMheadernames[08] = "EvtInfo "
	LMheadernames[09] = "NumTraceBlks "
	LMheadernames[10] = "  "
	LMheadernames[11] = "TrigTimeLO "
	LMheadernames[12] = "TrigTimeMI "
	LMheadernames[13] = "TrigTimeHI "
	LMheadernames[14] = "TrigTimeX "
	LMheadernames[15] = "Energy "	
	LMheadernames[16] = "ChanNo "
	LMheadernames[17] = "QDC0 (lo)  "
	LMheadernames[18] = "QDC0 (hi)  "
	LMheadernames[19] = "QDC1 (lo)  "
	LMheadernames[20] = "QDC1 (hi)  "
	LMheadernames[21] = "QDC2 (lo)  "
	LMheadernames[22] = "QDC2 (hi)  "
	
	LMheadernames[23] = "QDC3 (lo)  "
	LMheadernames[24] = "QDC3 (hi)  "
	LMheadernames[25] = "QDC4 (lo)  "
	LMheadernames[26] = "QDC4 (hi)  "
	LMheadernames[27] = "QDC5 (lo)  "
	LMheadernames[28] = "QDC5 (hi)  "
	LMheadernames[29] = "QDC6 (lo)  "
	LMheadernames[30] = "QDC6 (hi)  "
	LMheadernames[31] = "QDC7 (lo)  "
	LMheadernames[32] = "QDC7 (hi)  "
	LMheadernames[33] = "base "
	LMheadernames[34] = "max "	
	LMheadernames[35] = "ext TS (lo)"
	LMheadernames[36] = "ext TS (hi)"
	LMheadernames[37] = "watermark"
	LMheadernames[38] = "watermark"
	
	LMheadernames[47] = "EvtPattern "
	LMheadernames[48] = "EvtInfo "
	LMheadernames[49] = "NumTraceBlks "
	LMheadernames[50] = "  "
	LMheadernames[51] = "TrigTimeLO "
	LMheadernames[52] = "TrigTimeMI "
	LMheadernames[53] = "TrigTimeHI "
	LMheadernames[54] = "TrigTimeX "
	LMheadernames[55] = "Energy "	
	LMheadernames[56] = "ChanNo "
	
	// set the indices
	Nvar iMType = root:pixie4:iMType 
	Nvar iHitL  = root:pixie4:iHitL 
	Nvar iHitM  = root:pixie4:iHitM 
	Nvar iTimeL = root:pixie4:iTimeL 
	Nvar iTimeM = root:pixie4:iTimeM 
	Nvar iTimeH = root:pixie4:iTimeH
	Nvar iTimeX = root:pixie4:iTimeX 
	Nvar iEnergy    = root:pixie4:iEnergy  
	Nvar iChannel   = root:pixie4:iChannel 
	Nvar iCFDresult = root:pixie4:iCFDresult 
	Nvar iPSAmax    = root:pixie4:iPSAmax 
	Nvar iPSAbase   = root:pixie4:iPSAbase 
	Nvar iPSAsum0   = root:pixie4:iPSAsum0 
	Nvar iPSAsum1   = root:pixie4:iPSAsum1 
	Nvar iPSAresult = root:pixie4:iPSAresult
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2  
	iMType = 1
	iHitL  = 7
	iHitM  = 8 
	iTimeL = 11 
	iTimeM = 12 
	iTimeH = 13
	iTimeX = 14
	iEnergy    = 15 
	iChannel   = 16
	iCFDresult = -1
	iPSAmax    = 34
	iPSAbase   = 33
	iPSAsum0   = 17
	iPSAsum1   = 19
	iPSAresult = -1
	iCFDinfo   = -1
	iCFDsum1   = -1
	iCFDsum12  = -1
	iCFDsum2   = -1
	
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype
	variable blksize
	BlkSize = 32
	evsize = LMfileheader[9]*BlkSize  + LMfileheader[0]// assuming all are the same as ch.0 
	runtype = LMfileheader[2]
	
	Nvar ModuleType = root:pixie4:ModuleType
	ModuleType = LMfileheader[iMType]
	Pixie_SetTimeScales()
	
	Svar CFDsource  =  root:LM:CFDsource
	//CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	CFDsource = "none"

End

Function Pixie_Make_LMheadernames410()

	make/t/o/n=64 root:pixie4:LMheadernames
	wave/t LMheadernames = root:pixie4:LMheadernames
	LMheadernames = " "
	LMheadernames[0] = "EventHeadLen"
	LMheadernames[1] = "ModuleType "
	LMheadernames[2] = "RunType"
	LMheadernames[03] = "EvtPattern "
	LMheadernames[04] = "EvtInfo "
	LMheadernames[05] = "NumTraceBlks "
	LMheadernames[06] = "  "
	LMheadernames[07] = "TrigTimeLO "
	LMheadernames[08] = "TrigTimeMI "
	LMheadernames[09] = "TrigTimeHI "
	LMheadernames[10] = "TrigTimeX "
	LMheadernames[11] = "Energy "	
	LMheadernames[12] = "ChanNo "
	LMheadernames[13] = "PSA max "
	LMheadernames[14] = "(CFD)  "
	LMheadernames[15] = "PSA base  "
	LMheadernames[16] = "PSA sum 0  "
	LMheadernames[17] = "PSA sum 1   "
	LMheadernames[18] = "(PSA R) "	
	LMheadernames[19] = "CFD info  "
	LMheadernames[20] = "CFD sum 1  "
	LMheadernames[21] = "CFD sum 2/1  "
	LMheadernames[22] = "CFD sum 2  "
	LMheadernames[23] = "ExtTSL  "
	LMheadernames[24] = "ExtTSM  "
	LMheadernames[25] = "ExtTSH  "
	LMheadernames[26] = "reserved  "
	
	// set the indices
	Nvar iMType = root:pixie4:iMType 
	Nvar iHitL  = root:pixie4:iHitL 
	Nvar iHitM  = root:pixie4:iHitM 
	Nvar iTimeL = root:pixie4:iTimeL 
	Nvar iTimeM = root:pixie4:iTimeM 
	Nvar iTimeH = root:pixie4:iTimeH
	Nvar iTimeX = root:pixie4:iTimeX 
	Nvar iEnergy    = root:pixie4:iEnergy  
	Nvar iChannel   = root:pixie4:iChannel 
	Nvar iCFDresult = root:pixie4:iCFDresult 
	Nvar iPSAmax    = root:pixie4:iPSAmax 
	Nvar iPSAbase   = root:pixie4:iPSAbase 
	Nvar iPSAsum0   = root:pixie4:iPSAsum0 
	Nvar iPSAsum1   = root:pixie4:iPSAsum1 
	Nvar iPSAresult = root:pixie4:iPSAresult 
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2 
	iMType = 1
	iHitL  = 3
	iHitM  = 4 
	iTimeL = 7 
	iTimeM = 8 
	iTimeH = 9
	iTimeX = 10
	iEnergy    = 11 
	iChannel   = 12
	iCFDresult = -1
	iPSAmax    = 13
	iPSAbase   = 15
	iPSAsum0   = 16
	iPSAsum1   = 17
	iPSAresult = -1
	iCFDinfo   = 19
	iCFDsum1   = 20
	iCFDsum12  = 21
	iCFDsum2   = 22
	
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype
	variable blksize
	BlkSize = 32
	evsize = LMfileheader[5]*BlkSize  + LMfileheader[0]// assuming all are the same as ch.0 
	runtype = LMfileheader[2]
	//evsize = LMfileheader[5]*BlkSize/8  + LMfileheader[0]		// assuming all are the same as ch.0 // debug, multi-UDP events

	
	Nvar ModuleType = root:pixie4:ModuleType
	ModuleType = LMfileheader[iMType]
	Pixie_SetTimeScales()
	
	Svar CFDsource  =  root:LM:CFDsource
	CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	//CFDsource = "none"
	
End

Function Pixie_Make_LMheadernames411()

	make/t/o/n=64 root:pixie4:LMheadernames
	wave/t LMheadernames = root:pixie4:LMheadernames
	LMheadernames = " "
	LMheadernames[00] = "0xAAAA"
	LMheadernames[01] = "0xAAAA "
	LMheadernames[02] = "User Packet Data"
	LMheadernames[03] = "Geo Addr "
	LMheadernames[04] = "TrigTimeLO "
	LMheadernames[05] = "TrigTimeMI "
	LMheadernames[06] = "TrigTimeHI "
	LMheadernames[07] = "Types "
	LMheadernames[08] = "CFD info "
	LMheadernames[09] = "CFD sum 1 "
	LMheadernames[10] = "CFD sum 2/1 "
	LMheadernames[11] = "CFD sum 2 "	
	LMheadernames[12] = "BL "
	LMheadernames[13] = "BL "
	LMheadernames[14] = "Lsum  "
	LMheadernames[15] = "Lsum  "
	LMheadernames[16] = "Tsum  "
	LMheadernames[17] = "Tsum   "
	LMheadernames[18] = "Energy "
	LMheadernames[19] = "PSA max  "
	LMheadernames[20] = "PSA base  "
	LMheadernames[21] = "PSA sum 0 "
	LMheadernames[22] = "PSA sum 1 "
	LMheadernames[23] = "ExtTSL  "
	LMheadernames[24] = "ExtTSM  "
	LMheadernames[25] = "ExtTSH  "
	LMheadernames[26] = "ModuleType  "
	LMheadernames[28] = "Channel  "

	
	// set the indices
	Nvar iMType = root:pixie4:iMType 
	Nvar iHitL  = root:pixie4:iHitL 
	Nvar iHitM  = root:pixie4:iHitM 
	Nvar iTimeL = root:pixie4:iTimeL 
	Nvar iTimeM = root:pixie4:iTimeM 
	Nvar iTimeH = root:pixie4:iTimeH
	Nvar iTimeX = root:pixie4:iTimeX 
	Nvar iEnergy    = root:pixie4:iEnergy  
	Nvar iChannel   = root:pixie4:iChannel 
	Nvar iCFDresult = root:pixie4:iCFDresult 
	Nvar iPSAmax    = root:pixie4:iPSAmax 
	Nvar iPSAbase   = root:pixie4:iPSAbase 
	Nvar iPSAsum0   = root:pixie4:iPSAsum0 
	Nvar iPSAsum1   = root:pixie4:iPSAsum1 
	Nvar iPSAresult = root:pixie4:iPSAresult 
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2 
	iMType = 26
	iHitL  = -1
	iHitM  = -1 
	iTimeL = 4 
	iTimeM = 5 
	iTimeH = 6
	iTimeX = -1
	iEnergy    = 18 
	iChannel   = 28
	iCFDresult = -1
	iPSAmax    = 19
	iPSAbase   = 20
	iPSAsum0   = 21
	iPSAsum1   = 22
	iPSAresult = -1
	iCFDinfo   =  8
	iCFDsum1   =  9
	iCFDsum12  = 10
	iCFDsum2   = 11
	
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype
	variable blksize
	BlkSize = 32
	evsize = (LMfileheader[3] & 0x07FF) +2 	// assuming all are the same as ch.0 
	runtype = 0x411
	
	Nvar ModuleType = root:pixie4:ModuleType
	ModuleType = LMfileheader[iMType]
	Pixie_SetTimeScales()
	
	Svar CFDsource  =  root:LM:CFDsource
	CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	//CFDsource = "none"
	
End


//########################################################################
//
// Pixie_Make_Tdiffwaves:
//		Create result waves for LM and time analysis
//
//########################################################################
Function Pixie_Make_Tdiffwaves(nevents)
	Variable nevents 

	String text, allwaves
	Variable k
	
	Nvar oldNevents =   root:LM:oldNevents 
	if(nevents != oldNevents)
		print  "Making new waves, N events:", nevents
	endif
		
	// Waves for all events
	allwaves = "Energy;Energy0;Energy1;Energy2;Energy3;LocTime0;LocTime1;LocTime2;LocTime3;TrigTimeL;TrigTimeH;TdiffA;TdiffB;TdiffC"
	allwaves+= ";hit;energy;chnum;CFD0;CFD1;CFD2;CFD3;CFDtime"
	
			
	NewDataFolder/O/S root:LM	
	for(k=0;k<ItemsInList(allwaves);k+=1)
		text = StringFromList(k,allwaves)
//		if(nevents != oldNevents)
			KillWaves/Z $(text)
			Make/d/o/n=(Nevents) $(text)
//		endif
		wave wav = $(text)
		wav = NaN
	endfor
	
	SetDataFolder root:
		
End


//########################################################################
//
//	Pixie_MakeList_AllRunStats: 
//           Initialize Run Statistics List Data for Whole System
//
//########################################################################

Function Pixie_MakeList_AllRunStats(mode)
Variable mode	//0 - initialize when opening panel
				//1 - update values only

	// text waves with RS data read from csv file
	Wave/T ParameterM
	Wave/T Module
	Wave/T ParameterC
	
	Nvar NumberOfModules = root:pixie4:NumberOfModules
	
	if(mode==0)
		Make/o/t/n=(4*NumberOfModules,9) root:pixie4:AllChRunStats
		Make/o/b/n=(4*NumberOfModules,9,2) root:pixie4:AllChRunstats_S
		
		Make/o/t/n=(NumberOfModules,7) root:pixie4:AllModRunStats
		Make/o/b/n=(NumberOfModules,7,2) root:pixie4:AllModRunstats_S
	endif
		
	
	Wave/T AllChRunStats=root:pixie4:AllChRunStats
	Wave AllChRunstats_S=root:pixie4:AllChRunstats_S
	Wave/T AllModRunStats=root:pixie4:AllModRunStats
	Wave AllModRunstats_S=root:pixie4:AllModRunstats_S
	
	Variable ch
	
	// Channel statistics list
	for (ch=0;ch<4;ch+=1)
		wave/T csvsource = $("Channel"+num2str(ch))
		AllChRunStats[ch][0]=num2str(floor(ch/4))					//module
		AllChRunStats[ch][1]=num2str(mod(ch,4))					//channel
		AllChRunStats[ch][2]=(csvsource[Pixie_Find_NameInWave("COUNT_TIME", "ParameterC")])			//channel count time
		AllChRunStats[ch][3]=(csvsource[Pixie_Find_NameInWave("INPUT_COUNT_RATE", "ParameterC")])	//channel ICR
		AllChRunStats[ch][4]=(csvsource[Pixie_Find_NameInWave("OUTPUT_COUNT_RATE", "ParameterC")])	//channel OCR
		AllChRunStats[ch][5]=(csvsource[Pixie_Find_NameInWave("PASS_PILEUP_RATE", "ParameterC")])	//channel PPR
		AllChRunStats[ch][6]=(csvsource[Pixie_Find_NameInWave("SFDT", "ParameterC")])					//channel SFDT
		AllChRunStats[ch][7]=(csvsource[Pixie_Find_NameInWave("GATE_RATE", "ParameterC")])			//channel GCR
		AllChRunStats[ch][8]=(csvsource[Pixie_Find_NameInWave("GDT", "ParameterC")])					//channel GDT
	endfor

	
	if(mode==0)
		// All list data are not editable
		AllChRunstats_S=0
		
		// Set up for background color
		AllChRunstats_S[][][1]=1
	
		String labelStr1="Count Time [s]"
		String labelStr2="ICR [cps]"
		String labelStr3="OCR [cps]"
		String labelStr4="PPR [cps]"
		String labelStr5="Filter dead time [s]"
		String labelStr6="Gate Rate [cps]"
		String labelStr7="Gate Time [s]"
		setdimlabel 1,0,Module,AllChRunStats
		setdimlabel 1,1,Channel,AllChRunStats
		setdimlabel 1,2,$labelStr1,AllChRunStats
		setdimlabel 1,3,$labelStr2,AllChRunStats
		setdimlabel 1,4,$labelStr3,AllChRunStats
		setdimlabel 1,5,$labelStr4,AllChRunStats
		setdimlabel 1,6,$labelStr5,AllChRunStats
		setdimlabel 1,7,$labelStr6,AllChRunStats
		setdimlabel 1,8,$labelStr7,AllChRunStats
		setdimlabel 2,1,backColors,AllChRunStats_S
	endif
	
	
	// Module statistics list
	ch = Pixie_Find_NameInWave("PS code version", "ParameterM")
	AllModRunStats[][0]=num2str(p)					//module
	AllModRunStats[][1]=(Module[Pixie_Find_NameInWave(" RUN_TIME", "ParameterM")])			//module run time
	AllModRunStats[][2]=(Module[Pixie_Find_NameInWave(" EVENT_RATE", "ParameterM")])			// module event rate = NumEvents/Runtime
	AllModRunStats[][3]=" "
	AllModRunStats[][4]=(Module[Pixie_Find_NameInWave(" TOTAL_TIME", "ParameterM")])			// module total time
	AllModRunStats[][5]=(Module[Pixie_Find_NameInWave(" PS code version", "ParameterM")])	// SW rev
	AllModRunStats[][6]=(Module[Pixie_Find_NameInWave(" REVISION", "ParameterM")])			// FW rev
	
	if(mode==0)
		// All list data are not editable
		AllModRunstats_S=0
		
		// Set up for background color
		AllModRunstats_S[][][1]=1
	
		labelStr1="Run Time [s]"
		labelStr2="Event Rate [cps]"
		labelStr3="DAQ Fraction [%]"
		labelStr4="Total Time [s]"
		labelStr5="SW Rev."
		labelStr6="FW Rev."
		setdimlabel 1,0,Module,AllModRunStats
		setdimlabel 1,1,$labelStr1,AllModRunStats
		setdimlabel 1,2,$labelStr2,AllModRunStats
		setdimlabel 1,3,$labelStr3,AllModRunStats
		setdimlabel 1,4,$labelStr4,AllModRunStats
		setdimlabel 1,5,$labelStr5,AllModRunStats
		setdimlabel 1,6,$labelStr6,AllModRunStats
		setdimlabel 2,1,backColors,AllModRunstats_S
	endif
	
	
End


//########################################################################
//
//	Pixie_MakeList_LMHisto: Initialize List Mode Spectrum List Data
//
//########################################################################
Function Pixie_MakeList_LMHisto()

	String strLabel
	
	make/o/t/n=(5,6) root:pixie4:ListModeSpecListData
	make/o/b/n=(5,6,2) root:pixie4:ListModeSpecSListData
	
	Wave/T ListModeSpecListData=root:pixie4:ListModeSpecListData
	Wave ListModeSpecSListData=root:pixie4:ListModeSpecSListData
	
	Wave ListStartFitChannel=root:pixie4:ListStartFitChannel
	Wave ListEndFitChannel=root:pixie4:ListEndFitChannel
	Wave ListChannelPeakPos=root:pixie4:ListChannelPeakPos
	Wave ListChannelFWHMPercent=root:pixie4:ListChannelFWHMPercent
	Wave ListChannelPeakArea=root:pixie4:ListChannelPeakArea				
	
	ListModeSpecListData[][0]=num2str(p)
	ListModeSpecListData[4][0]="Ref"
	ListModeSpecListData[][1]=num2str(ListStartFitChannel[p])
	ListModeSpecListData[][2]=num2str(ListEndFitChannel[p])
	ListModeSpecListData[][3]=num2str(ListChannelPeakPos[p])
	ListModeSpecListData[][4]=num2str(ListChannelFWHMPercent[p])
	ListModeSpecListData[][5]=num2str(ListChannelPeakArea[p])

	// Most list data are not editable except StartFitChannel and EndFitChannel
	ListModeSpecSListData=0
	ListModeSpecSListData[][0][]=0x30
	ListModeSpecSListData[4][0][]=0x20
	ListModeSpecSListData[][1][]=2
	ListModeSpecSListData[][2][]=2
	
	// Set up color
	ListModeSpecSListData[][][1]=1	//default non-editable: purple
	ListModeSpecSListData[][1,3][1]=2
	ListModeSpecSListData[0][0][1]=3	//ch.0: red
	ListModeSpecSListData[1][0][1]=4	//ch.1: bright green
	ListModeSpecSListData[2][0][1]=5	//ch.2: blue
	ListModeSpecSListData[3][0][1]=6	//ch.3: dark green
	ListModeSpecSListData[4][0][1]=7	//ref: dark gray


	setdimlabel 1,0,Channel,ListModeSpecListData
	setdimlabel 1,1,Min,ListModeSpecListData
	setdimlabel 1,2,Max,ListModeSpecListData
	setdimlabel 1,3,Peak,ListModeSpecListData
	
	strLabel="FWHM [%]"
	setdimlabel 1,4,$strLabel,ListModeSpecListData

	strLabel="Peak Area"
	setdimlabel 1,5,$strLabel,ListModeSpecListData
		
	setdimlabel 2,1,backColors,ListModeSpecSListData

End



//########################################################################
//
//	Pixie_MakeList_MCA: Initialize MCA Spectrum List Data
//
//########################################################################
Function Pixie_MakeList_MCA(init)
	Variable init	//0 - first open graph
				//1 - update fit values - do not change checkboxes.

	String strLabel
	
	if(init==0)
		make/o/t/n=(6,9) root:pixie4:MCASpecListData
		make/o/b/n=(6,9,2) root:pixie4:MCASpecSListData
	endif
	
	Wave/T MCASpecListData=root:pixie4:MCASpecListData
	Wave MCASpecSListData=root:pixie4:MCASpecSListData
	
	Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
	Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
	Wave MCAFitRange=root:pixie4:MCAFitRange
	Wave MCAscale=root:pixie4:MCAscale
	Wave MCAChannelPeakPos=root:pixie4:MCAChannelPeakPos
	Wave MCAChannelFWHMPercent=root:pixie4:MCAChannelFWHMPercent
	Wave MCAChannelFWHMAbsolute=root:pixie4:MCAChannelFWHMAbsolute
	Wave MCAChannelPeakArea=root:pixie4:MCAChannelPeakArea				
	
	
	MCASpecListData[][0]=num2str(p)
	MCASpecListData[4][0]="Ref"
	MCASpecListData[5][0]="Addback"
	MCASpecListData[][1]=num2str(MCAFitRange[p])
	MCASpecListData[][2]=num2str(MCAStartFitChannel[p])
	MCASpecListData[][3]=num2str(MCAEndFitChannel[p])
	MCASpecListData[][4]=num2str(MCAscale[p])
	MCASpecListData[][5]=num2str(MCAChannelPeakPos[p])
	MCASpecListData[][6]=num2str(MCAChannelFWHMPercent[p])
	MCASpecListData[][7]=num2str(MCAChannelFWHMAbsolute[p])
	MCASpecListData[][8]=num2str(MCAChannelPeakArea[p])
		
	if (init==0)
		// Most list data are not editable except StartFitChannel, EndFitChannel, FitRange, and Scale
		// channel number are checkboxes
		MCASpecSListData=0
		MCASpecSListData[][0][]=0x30
		MCASpecSListData[4][0][]=0x20
		MCASpecSListData[5][0][]=0x20
		MCASpecSListData[][1][]=2
		MCASpecSListData[][2][]=2
		MCASpecSListData[][3][]=2
		MCASpecSListData[][4][]=2
		
		// Set up color
		MCASpecSListData[][][1]=1	//default non-editable: purple
		MCASpecSListData[][1,4][1]=2
		MCASpecSListData[0][0][1]=3	//ch.0: red
		MCASpecSListData[1][0][1]=4	//ch.1: bright green
		MCASpecSListData[2][0][1]=5	//ch.2: blue
		MCASpecSListData[3][0][1]=6	//ch.3: dark green
		MCASpecSListData[4][0][1]=7	//other: black
		MCASpecSListData[5][0][1]=8	//other: purple			
						
		setdimlabel 1,0,Channel,MCASpecListData
		
		strLabel="Range [%]"
		setdimlabel 1,1,$strLabel,MCASpecListData	
		
		setdimlabel 1,2,Min,MCASpecListData
		setdimlabel 1,3,Max,MCASpecListData
		
		strLabel="keV/bin"
		setdimlabel 1,4,$strLabel,MCASpecListData
		
		setdimlabel 1,5,Peak,MCASpecListData
		
		strLabel="FWHM [%]"
		setdimlabel 1,6,$strLabel,MCASpecListData
	
		strLabel="FWHM [abs]"
		setdimlabel 1,7,$strLabel,MCASpecListData
				
		strLabel="Peak Area"
		setdimlabel 1,8,$strLabel,MCASpecListData
			
		setdimlabel 2,1,backColors,MCASpecSListData
	endif
End



//########################################################################
//
//	Pixie_MakeList_Traces: Initialize Channel Energy List Data
//
//########################################################################
Function Pixie_MakeList_Traces(init)
Variable init	//0 - first open graph
			//1 - update fit values - do not change checkboxes.

	String strLabel
	
	if (init==0)
		Make/o/t/n=(5,5) root:pixie4:ListModeEnergyListData
		Make/o/b/n=(5,5,2) root:pixie4:ListModeEnergySListData
	endif
	
	Wave/T ListModeEnergyListData=root:pixie4:ListModeEnergyListData
	Wave ListModeEnergySListData=root:pixie4:ListModeEnergySListData
	
	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
	Wave ListModeChannelTrigger=root:pixie4:ListModeChannelTrigger
	Wave ListModeChannelXIA=root:pixie4:ListModeChannelXIA
	Wave ListModeChannelUser=root:pixie4:ListModeChannelUser

	ListModeEnergyListData[][0]=num2istr(p)	
	ListModeEnergyListData[4][0]="Ref"
	ListModeEnergyListData[][1]=num2istr(ListModeChannelEnergy[p])	
	ListModeEnergyListData[][2]=num2istr(ListModeChannelTrigger[p])	
	ListModeEnergyListData[][3]=num2istr(ListModeChannelXIA[p])	
	ListModeEnergyListData[][4]=num2istr(ListModeChannelUser[p])	
	
	if (init==0)	
		// Most list data fields are not editable except channel numbers are checkboxes
		ListModeEnergySListData=0
		ListModeEnergySListData[][0][]=0x30
		ListModeEnergySListData[4][0][]=0x20	// unchecked
			
		// Set up color
		ListModeEnergySListData[][][1]=1	//default non-editable: purple
		ListModeEnergySListData[0][0][1]=3	//ch.0: red
		ListModeEnergySListData[1][0][1]=4	//ch.1: bright green
		ListModeEnergySListData[2][0][1]=5	//ch.2: blue
		ListModeEnergySListData[3][0][1]=6	//ch.3: dark green
		ListModeEnergySListData[4][0][1]=7	//ref: black
			
		setdimlabel 1,0,Channel,ListModeEnergyListData
		strLabel="Energy (16bit)"
		setdimlabel 1,1,$strLabel,ListModeEnergyListData
		setdimlabel 1,2,TimeStamp,ListModeEnergyListData
		setdimlabel 1,3,XIA_PSA,ListModeEnergyListData
		setdimlabel 1,4,User_PSA,ListModeEnergyListData
		setdimlabel 2,1,backColors,ListModeEnergySListData
	endif
	
	
End

