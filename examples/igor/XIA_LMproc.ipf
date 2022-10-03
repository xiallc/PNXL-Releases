#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "&XIA_Extra"
	"&Time Differences", Time_Panel()
	//"-"
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//		T diff histograms
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Function Tdiff_globals()

	NewDataFolder/O root:Tdiff

	Variable/G  root:Tdiff:oldNevents 	=0			// remember previous number of events
	Variable/G  root:Tdiff:Nevents 				// number of events
	Variable/G  root:Tdiff:MaxEvents 	=1000			// maximum number of events to process
	
	Variable/G root:Tdiff:DiffA_P
	Variable/G root:Tdiff:DiffA_N
	Variable/G root:Tdiff:DiffB_P
	Variable/G root:Tdiff:DiffB_N
	Variable/G root:Tdiff:DiffC_P
	Variable/G root:Tdiff:DiffC_N
	Variable/G root:Tdiff:DiffA_toEv
	Variable/G root:Tdiff:DiffB_toEv
	Variable/G root:Tdiff:DiffC_toEv
	Variable/G root:Tdiff:DiffA_toPTP
	Variable/G root:Tdiff:DiffB_toPTP
	Variable/G root:Tdiff:DiffC_toPTP
	Variable/G  root:Tdiff:DiffA_CFD 
	Variable/G  root:Tdiff:DiffB_CFD
	Variable/G  root:Tdiff:DiffC_CFD
	
	Variable/G root:Tdiff:UsePTPforLOC
	
	Variable/G root:Tdiff:NbinsTA = 256
	Variable/G root:Tdiff:BinsizeTA = 8
	Variable/G root:Tdiff:NbinsTB = 256
	Variable/G root:Tdiff:BinsizeTB = 8
	Variable/G root:Tdiff:NbinsTC = 256
	Variable/G root:Tdiff:BinsizeTC = 8
	
	Variable/G root:Tdiff:CW 
	Variable/G root:Tdiff:chanA
	Variable/G root:Tdiff:chanB
	Variable/G root:Tdiff:plotx 
	Variable/G root:Tdiff:ploty 

	Tdiff_process_makethewaves(1)	// makes waves for the event result parameters
	make/o/n=1 root:Tdiff:ThistoA, root:Tdiff:ThistoB, root:Tdiff:ThistoC
	
	Variable/G root:Tdiff:ExtractCoinc
	Variable/G root:Tdiff:ExtractHitPattern
	Variable/G root:Tdiff:ExtractHitPatternOR
	Variable/G root:Tdiff:ExtractHitPatternAND
	
	// from time analysis
	String/G root:Tdiff:suffix ="A"
	make/d/o/n=40 root:Tdiff:Eventvalues
	make/o/n=10 root:Tdiff:traceA
	make/o/n=10 root:Tdiff:traceB
	make/o/n=10 root:Tdiff:triglocsA
	make/o/n=10 root:Tdiff:triglocsB
	make/o/n=1 root:Tdiff:dthisto
	make/o/n=1 root:Tdiff:multiTS
	
	Variable/G root:Tdiff:TS500	=1//500 MHz Time stamps for P500
	Variable/G root:Tdiff:EvIncr	=2 //P500e: same data in multiple events. E.g. set to 2 for 2-channel data
	variable/G root:Tdiff:modA =0
	variable/G root:Tdiff:modB =0
	variable/G  root:Tdiff:defaultTriggerPos = 20		// ignore points before that
	variable/G  root:Tdiff:LB = 12 					// length of baseline sum
	variable/G  root:Tdiff:RTlow = 0.5				// CF threshold
	variable/G  root:Tdiff:Nevents 
	variable/G  root:Tdiff:ElowA
	variable/G  root:Tdiff:EhighA
	variable/G  root:Tdiff:ElowB
	variable/G  root:Tdiff:EhighB
	variable/G  root:Tdiff:RTlowA
	variable/G  root:Tdiff:RThighA
	variable/G  root:Tdiff:RTlowB
	variable/G  root:Tdiff:RThighB
	variable/G  root:Tdiff:cutE
	variable/G  root:Tdiff:cutRT
	variable/G  root:Tdiff:hist_binmin = -200
	variable/G  root:Tdiff:hist_binsize = 1
	variable/G  root:Tdiff:hist_binnumber =400
	variable/G  root:Tdiff:TSscale = 2		// time stamp time scale in ns
	//variable/G  root:Tdiff:WFscale = 2	// waveform sample time scale in ns
	//variable/G oot:pixie4:wftimescale
	
	make/o/n=(100) amplitudesA, amplitudesB, cfdA, cfdB, timediff, timediff_cut,energiesA, energiesB, tsA, tsB, rtA, rtB
	make/o/n=(100) tdiffdsp, tdiffdsp_cut, dspdtA, dspdtB
	make/o/n=(100)  timediff, timediff_cut, tdiffdsp, tdiffdsp_cut
	
	
End


Function Tdiff_cleanup()

	NewDataFolder/O root:Tdiff

	Tdiff_process_makethewaves(1)	// makes waves for the event result parameters
	
	make/o/n=1 root:Tdiff:ThistoA, root:Tdiff:ThistoB, root:Tdiff:ThistoC
	
	// delete auto generated waves from file read
	killwaves/Z	root:Event_No, root:Hit_Pattern, root:Event_Time_H, root:Event_Time_L, root:PTP_Time
	killwaves/Z    root:Time0, root:Time1, root:Time2, root:Time3, root:Energy0, root:Energy1, root:Energy2, root:Energy3
	killwaves/Z	root:No, root:Ch, root:Hit, root:Time_H, root:Time_L, root:Energy
	killwaves/Z root:wfarray, root:LMheader
	killwaves/Z alltraces
	
	killwaves/Z PTP_timesteps, PTP_timediff, PTP_timedev, PTP_timedev_Hist, root:Tdiff:CFDtime

	make/o/n=(100) amplitudesA, amplitudesB, cfdA, cfdB, timediff, timediff_cut,energiesA, energiesB, tsA, tsB, rtA, rtB
	make/o/n=(100) tdiffdsp, tdiffdsp_cut, dspdtA, dspdtB
	make/o/n=(100)  timediff, timediff_cut, tdiffdsp, tdiffdsp_cut
	
End



Function Tdiff_process_makethewaves(nevents)
	Variable nevents 

	String text, combwaves, Csiwaves,plasticwaves,otherwaves, allwaves
	Variable k
	
	Nvar oldNevents =   root:Tdiff:oldNevents 
	if(nevents != oldNevents)
		print  "Making new waves, N events:", nevents
	endif
		
	// Waves for all events
	allwaves = "Energy0;Energy1;Energy2;Energy3;LocTime0;LocTime1;LocTime2;LocTime3;TrigTimeL;TrigTimeH;TdiffA;TdiffB;TdiffC"
	allwaves+= ";ETx;ETy;Tdiffxy;PTP_Time;psa;rt;hit;energy;chnum;CFD0;CFD1;CFD2;CFD3"
	
			
	NewDataFolder/O/S root:Tdiff	
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
// LM_Analysis_Panel:
//		Control Panel for various list mode functions
//
//########################################################################
Function LM_Analysis_Panel() : Panel
	PauseUpdate; Silent 1		// building window...
	
	DoWindow/F LMAnalysis
	if (V_flag!=1)
		//Tdiff_globals()
		NewPanel /K=1/W=(50,50,335,750) as "LM File Analysis"
		//ModifyPanel cbRGB=(65280,59904,48896)
		DoWindow/C LMAnalysis	
		
		variable buttonx = 240
		Variable ctrlx = 16
		Variable sety = 220
		Variable filey = 10
		variable linelendx = 260
		
		SetVariable TraceDataFile, value=root:pixie4:lmfilename, pos={ctrlx, filey+4},size={240,18},title="File"
		SetVariable TraceDataFile,fsize=11,font="arial"//,bodywidth=100
		Button FindTraceDataFile, pos={ctrlx,filey+26},size={50,20},proc=Pixie_Ctrl_CommonButton,title="Select",fsize=11	,font="arial"	
		SetVariable setvar2,pos={165,filey+26},size={105,16},title="Run Type  0x",variable= root:pixie4:RunType,format="%X",font="arial",fsize=11
		SetVariable setvar3,pos={165,filey+46},size={105,16},title="Event Size    ",variable= root:pixie4:evsize	,font="arial",fsize=11
		SetVariable setvar4,pos={ctrlx,filey+46},size={140,16},title="Max # events ",variable= root:Tdiff:MaxEvents	,font="arial",fsize=11
		filey+=70
		
		SetVariable inp24,pos={ctrlx,filey},size={140,16},title="Time stamp unit (ns) ",value= root:Tdiff:TSscale,font="arial",fsize=11
		SetVariable inp24, help={"Time stamp units are 2ns for Pixie-4e (any), 13.333ns for Pixie-4, 1ns for Pixie-Net"}
		SetVariable inp25,pos={ctrlx,filey+20},size={140,16},title="Sample interval (ns) ",value= root:pixie4:WFscale,font="arial",fsize=11
		SetVariable inp25, help={"Waveform sampling intervals are 2ns for Pixie-4e (14/500), 8ns for Pixie-4e (16/125), 4ns for Pixie-Net, 13.333ns for Pixie-4"}
		filey+=45
	

		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey, linelendx, filey
		filey+=10
		
		Button ReadDSPresults500,pos={ctrlx, filey},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .txt file (0x500) [traces]"
		Button ReadDSPresults500,help={"Read list data from file (text, with traces), extract values computed by DSP"},fsize=11	,font="arial", disable=2
		Button ReadDSPresults501,pos={ctrlx, filey+22},size={buttonx/2,20},proc=Tdiff_Panel_Call_Buttons,title="... .dat file (0x501) [no traces]"
		Button ReadDSPresults501,help={"Read list data from file (text, no traces), extract values computed by DSP"},fsize=11	,font="arial", disable=2
		Button ReadDSPresults502,pos={ctrlx+buttonx/2, filey+22},size={buttonx/2,20},proc=Tdiff_Panel_Call_Buttons,title="... .dt2 file (0x502) [PSA]"	
		Button ReadDSPresults502,help={"Read list data from file (text, PSA and CFD), extract values computed by DSP"},fsize=11	,font="arial", disable=2
		Button ReadDSPresults503,pos={ctrlx, filey+44},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .dt3 file (0x503) [coinc]"
		Button ReadDSPresults503,help={"Read list data from file (coinc group), extract values computed by DSP"},fsize=11	,font="arial", disable=2
		
		Button ReadDSPresults400,pos={ctrlx, filey+66},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .b00 file (0x400, 0x402)"
		Button ReadDSPresults400,help={"Read list data from file (any binary), extract values computed by DSP"},fsize=11	,font="arial"
		Button ReadDSPresults116,pos={ctrlx, filey+88},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .bin file (0x100 P16)"
		Button ReadDSPresults116,help={"Read list data from file (Pixie-Net / P16), extract values computed by DSP"},fsize=11	,font="arial"
		Button ReadDSPresults404,pos={ctrlx, filey+110},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .bin file (0x404 Pixie-Net XL)"
		Button ReadDSPresults404,help={"Read list data from file (Pixie-Net / P16), extract values computed by DSP"},fsize=11	,font="arial"
		filey+=139
		
		Button Tdiff_CFDTraces,pos={ctrlx, filey},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Events from file, compute CFD (slow)"
		Button Tdiff_CFDTraces,help={"Process same file and replace file CFD with value computed from LM waveforms. Must be single event records (0x116, 400, etc"}, fsize=11	,font="arial"		
		filey+=30	
	
		Checkbox Igor99, variable= root:Tdiff:UsePTPforLOC, title = "LocTime = PTP/Ex time",pos={ctrlx+10,filey},font="arial",fsize=11
		Checkbox Igor99,help={"Replace the local trigger time with the External time stamp (PTP/WR) [0x116 only]"}	
		filey+=20	
		
		Button Tdiff_List,pos={ctrlx, filey},size={buttonx/2,20},proc=Tdiff_Panel_Call_Buttons,title="Open Data Table"
		Button Tdiff_List,help={"Open Table with imported raw data"}, fsize=11	,font="arial"
		filey+=30	

		
		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey, linelendx, filey
		filey+=10
		
		// -------------------------------------------------------------------------------------------------------------------------------
				
//		SetDrawEnv fsize= 12,fstyle= 1
//		DrawText 10,sety,"Time Difference Histogram Settings"
		Button Tdiff_compute_diff,pos={ctrlx, filey},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Compute Time Differences"
		Button Tdiff_compute_diff,help={"Loop over all events in file and compute Tdiff between specified channels or Event Time or PTP time"}, fsize=11,font="arial",fstyle= 1
		filey+=20
						
		SetVariable Igor100,pos={ctrlx,filey+10},size={120,16},title="Tdiff A: Channel ",help={"Channel number for time difference A"}
		SetVariable Igor100,fSize=11,format="%g",value= root:Tdiff:DiffA_P	, limits={0,3,1}	,font="arial"
		SetVariable Igor101,pos={ctrlx+123,filey+10},size={90,16},title=" minus ch.  ",help={"Channel number for time difference A"}
		SetVariable Igor101,fSize=11,format="%g",value= root:Tdiff:DiffA_N, limits={0,3,1}	,font="arial"
		
		Checkbox Igor121, variable= root:Tdiff:DiffA_toEv, title = "Ev Ti",pos={ctrlx+130,filey+32},font="arial",fsize=11
		Checkbox Igor121, help = {" Use event time instead of channel specific local time (0x402 only) "} 
		Checkbox Igor124, variable= root:Tdiff:DiffA_toPTP, title = "PTP",pos={ctrlx+185,filey+32},font="arial",fsize=11, disable=2
		Checkbox Igor124, help = {" Use PTP time instead of channel specific local time (outdated, use PTP to loc option above) "} 
		Checkbox Igor125, variable= root:Tdiff:DiffA_CFD, title = "CFD",pos={ctrlx+15,filey+32},font="arial",fsize=11
		Checkbox Igor125, help = {"Refine local time difference with CFD"}
		SetVariable Igor126,pos={ctrlx+60,filey+30},size={60,16},title="lvl",help={"CFD level for computation from traces"}
		SetVariable Igor126,fSize=11,format="%g",value= root:Tdiff:RTlow, limits={0,1,0.1},font="arial"	
		
		SetVariable Igor110,pos={ctrlx+38,filey+50},size={80,16},title="No. bins ",help={"Number of bins for Tdiff A histogram"}
		SetVariable Igor110,fSize=11,format="%g",value= root:Tdiff:NbinsTA, limits={0,65536,0},font="arial"	
		SetVariable Igor111,pos={ctrlx+123,filey+50},size={100,16},title="bin size (ns)",help={"bin size (ns) for Tdiff A histogram"}
		SetVariable Igor111,fSize=11,format="%g",value= root:Tdiff:BinsizeTA, limits={0,2048,0},font="arial"
		filey+=50
		
		Button Tdiff_plot_histos,pos={ctrlx, filey+26},size={100,20},proc=Tdiff_Panel_Call_Buttons,title="Display Histogram"
		Button Tdiff_plot_histos,help={"Create graph with histograms of time differences"}, fsize=11,font="arial"
		Button Tdiff_histo,pos={ctrlx+110, filey+26},size={60,20},proc=Tdiff_Panel_Call_Buttons,title="Rebin"
		Button Tdiff_histo,help={"rebin the histograms with specified bin size/number"}, fsize=11,font="arial"
		Button Tdiff_fit,pos={ctrlx+180, filey+26},size={60,20},proc=Tdiff_Panel_Call_Buttons,title="Fit"
		Button Tdiff_fit,help={"Apply Gauss fit between cursors"}, fsize=11,font="arial"
		filey+=55
		
//		sety+=40	
//		SetVariable Igor102,pos={ctrlx,sety+10},size={120,16},title="Tdiff B: Channel ",help={"Channel number for time difference B"}
//		SetVariable Igor102,fSize=10,format="%g",value= root:Tdiff:DiffB_P, limits={0,3,1}			
//		SetVariable Igor103,pos={ctrlx+123,sety+10},size={90,16},title=" minus ch.   ",help={"Channel number for time difference B"}
//		SetVariable Igor103,fSize=10,format="%g",value= root:Tdiff:DiffB_N, limits={0,3,1}		
//		SetVariable Igor112,pos={ctrlx+38,sety+30},size={80,16},title="No. bins ",help={"Number of bins for Tdiff B histogram"}
//		SetVariable Igor112,fSize=10,format="%g",value= root:Tdiff:NbinsTB, limits={0,2048,0}		
//		SetVariable Igor113,pos={ctrlx+123,sety+30},size={90,16},title="bin size (ns)",help={"bin size (ns) for Tdiff B histogram"}
//		SetVariable Igor113,fSize=10,format="%g",value= root:Tdiff:BinsizeTB, limits={0,2048,0}
//		Checkbox Igor122, variable= root:Tdiff:DiffB_toEv, title = "EvT",pos={ctrlx+220,sety+12}
//		Checkbox Igor125, variable= root:Tdiff:DiffB_toPTP, title = "PTP",pos={ctrlx+220,sety+32}
//		
//		sety+=40	
//		SetVariable Igor104,pos={ctrlx,sety+10},size={120,16},title="Tdiff C: Channel ",help={"Channel number for time difference C"}
//		SetVariable Igor104,fSize=10,format="%g",value= root:Tdiff:DiffC_P, limits={0,3,1}			
//		SetVariable Igor105,pos={ctrlx+123,sety+10},size={90,16},title=" minus ch.   ",help={"Channel number for time difference C"}
//		SetVariable Igor105,fSize=10,format="%g",value= root:Tdiff:DiffC_N	, limits={0,3,1}	
//		SetVariable Igor114,pos={ctrlx+38,sety+30},size={80,16},title="No. bins ",help={"Number of bins for Tdiff C histogram"}
//		SetVariable Igor114,fSize=10,format="%g",value= root:Tdiff:NbinsTC, limits={0,2048,0}		
//		SetVariable Igor115,pos={ctrlx+123,sety+30},size={90,16},title="bin size (ns)",help={"bin size (ns) for Tdiff C histogram"}
//		SetVariable Igor115,fSize=10,format="%g",value= root:Tdiff:BinsizeTC, limits={0,2048,0}
//		Checkbox Igor123, variable= root:Tdiff:DiffC_toEv, title = "EvT",pos={ctrlx+220,sety+12}
//		Checkbox Igor126, variable= root:Tdiff:DiffC_toPTP, title = "PTP",pos={ctrlx+220,sety+32}

		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey, linelendx, filey
		filey+=10	
		// -------------------------------------------------------------------------------------------------------------------------------

		Button LM_Extract_Tdiff,pos={ctrlx, filey},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Extract Coincidences"
		Button LM_Extract_Tdiff,help={"Loop through events and copy those matching coinc requirements"}, fsize=11,font="arial",fstyle= 1
		filey +=25
	//	ctrlx+=20
		SetVariable Igor201,pos={ctrlx,filey},size={185,20},title="Coinc .Window (ns)",help={"Coincidence Window (ns) for Energies"},fsize=11
		SetVariable Igor201,value= root:Tdiff:CW,font="arial" //,format="%8g"
		SetVariable chx,pos={ctrlx,filey+20},size={95,16},title="between ch.",value= root:Tdiff:chanA
		SetVariable chx, help = {"Channel number for coinc window."}	,fsize=11,font="arial"
		SetVariable chy,pos={ctrlx+110,filey+20},size={75,16},title=" and ch. ",value= root:Tdiff:chanB
		SetVariable chy, help = {"Channel number for coinc window."}	,fsize=11,font="arial"
		filey +=40
				
		Variable ypos=filey
		variable dy=20

		popupmenu pltx,  pos={ctrlx,ypos+0*dy}, title = "Plot as x", proc = Tdiff_Panel_PopProc, size ={120,20}
		popupmenu pltx, value="<select>;first channel;second channel;time difference", mode=1
		popupmenu pltx, help={"Define the quantty to plot on x axis in 2D histogram"} ,fsize=11,font="arial"
		popupmenu plty,  pos={ctrlx,ypos+1*dy}, title = "Plot as y", proc = Tdiff_Panel_PopProc, size ={120,20}
		popupmenu plty,  value="<select>;first channel;second channel;time difference", mode=1
		popupmenu plty, help={"Define the quantty to plot on y axis in 2D histogram"} ,fsize=11,font="arial"
		Button ExEyScatter,pos={ctrlx+135, filey},size={80,20},proc=Tdiff_Panel_Call_Buttons,title="Scatter Plot"
		Button ExEyScatter,help={"Plot coincidnec energies as scatter plot"}, fsize=11,font="arial",fstyle= 0

		filey+=50
		
		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey, linelendx, filey
		filey+=15	
		
		
		
		Button LM_Extract_HP,pos={ctrlx, filey},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Extract Matching Hitpatterns (memory)"
		Button LM_Extract_HP,help={"Loop through events and copy those matching hit pattern requirements"}, fsize=11,font="arial",fstyle= 1
		Button LM_File_ExtractHP_40x,pos={ctrlx, filey+25},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Extract Matching Hitpatterns (large file)"
		Button LM_File_ExtractHP_40x,help={"Parse though file and build MCA from events matching hit pattern requirements"}, fsize=11,font="arial",fstyle= 0

		filey +=50
		SetVariable Igor203,pos={ctrlx+20,filey},size={170,16},title="          Hit           OR 0x",value= root:Tdiff:ExtractHitPatternOR
		SetVariable Igor203, help = {"Hit pattern is first OR'ed with this pattern."}	,fsize=10,font="arial",format="%08x", limits={0,0xFFFFFFFF,0}
		
		SetVariable Igor204,pos={ctrlx+20,filey+30},size={80,16},title="0x",value= root:Tdiff:ExtractHitPatternAND
		SetVariable Igor204, help = {"Then Hit pattern compared with this pattern."}	,fsize=10,font="arial",format="%08x", limits={0,0xFFFFFFFF,0}
		SetVariable Igor205,pos={ctrlx+90,filey+30},size={100,16},title="  OR  0x",value= root:Tdiff:ExtractHitPatternOR
		SetVariable Igor205, help = {"Then Hit pattern compared with this pattern."}	,fsize=10,font="arial",format="%08x", limits={0,0xFFFFFFFF,0}
//		ctrlx-=20
		SetDrawEnv fsize= 8,fstyle= 0
		DrawText 115,filey+27,"||"
		filey+=30
				
		// -------------------------------------------------------------------------------------------------------------------------------
	endif
End

Function Tdiff_Panel_Call_Buttons(ctrlname): ButtonControl
String ctrlname

	Nvar source = root:Tdiff:source
	
	if(cmpstr(ctrlname,"ReadDSPresults503")==0)	
		source = 0
		LM_FileRead_503()
		return 0
	endif
	
	if(cmpstr(ctrlname,"ReadDSPresults502")==0)	
		source = 0
		LM_FileRead_502()
		return 0
	endif
	
	if(cmpstr(ctrlname,"ReadDSPresults501")==0)	
		source = 0
		LM_FileRead_501()
		return 0
	endif
	
	if(cmpstr(ctrlname,"ReadDSPresults500")==0)	
		source = 0
		LM_FileRead_500()
		return 0
	endif
	
	if(cmpstr(ctrlname,"ReadDSPresults400")==0)	
		source = 0
		Pixie_File_ReadAsList4xx()
		return 0
	endif
	
	if(cmpstr(ctrlname,"ReadDSPresults116")==0)	
		source = 0
		LM_FileRead_116()
		return 0
	endif
	
	if(cmpstr(ctrlname,"ReadDSPresults404")==0)	
		source = 0
		Pixie_File_ReadAsList4xx()	// for now they are close
		return 0
	endif
	
	
	if(cmpstr(ctrlName, "Tdiff_fit") == 0)
		wave W_Coef
		String wavesinplot, wfname
		Variable Nwaves, m
		Nvar RTlow = root:Tdiff:RTlow
		Execute "Tdiff_plot_histos()"
		wavesinplot = TraceNameList("Tdiffhistos",",",1)
		Nwaves = ItemsInList(wavesinplot,",")
		for(m=0;m<Nwaves;m+=1)
			wfname = StringFromList(m,wavesinplot,",")
			if( stringmatch(wfname,"fit_*") ==0)		// only fit the histos, not any fits that are already in the plot
				Wave histo = $("root:Tdiff:"+wfname)			// default: wave in Tdiff folder
				if(WaveExists(histo)==0)
					Wave histo = $(wfname)					// but top level saved copies may exist also
				endif
				if(WaveExists(histo)==1)
					CurveFit/q/NTHR=0/TBOX=0 gauss histo [pcsr(A),pcsr(B)] /D 
					print wfname,": peak position (ns):",W_Coef[2], "FWHM (ps):",W_coef[3]*2*sqrt(ln(2))*1000,"(cfd =",RTlow,")"
				endif
			endif
		endfor
		
		return(0)
	endif
	
	if(cmpstr(ctrlName, "Tdiff_CFDTraces") == 0)
		LM_File_ExtractCFD_singles(1)
		return 0
	endif

	Execute (ctrlname+"()")
	
	

End



Window Tdiff_List() : Table
	DoWindow/F TSList
	if (V_Flag!=1)
		Edit/W=(280,50,800,450)/K=1 root:Tdiff:Hit,root:Tdiff:chnum, root:Tdiff:energy//, root:Tdiff:psa, root:Tdiff:rt
		DoWindow/C TSList
		AppendToTable root:Tdiff:Energy0,root:Tdiff:Energy1,root:Tdiff:Energy2,root:Tdiff:Energy3
		AppendToTable root:Tdiff:TrigTimeH,root:Tdiff:TrigTimeL//,root:Tdiff:PTP_Time//0,root:Tdiff:TrigTime1, root:Tdiff:TrigTime2,root:Tdiff:TrigTime3
		AppendToTable root:Tdiff:LocTime0,root:Tdiff:LocTime1, root:Tdiff:LocTime2,root:Tdiff:LocTime3
		AppendToTable root:Tdiff:CFD0,root:Tdiff:CFD1, root:Tdiff:CFD2,root:Tdiff:CFD3
		//AppendToTable root:Tdiff:ETx,root:Tdiff:ETy,root:Tdiff:Tdiffxy
		AppendToTable root:Tdiff:TdiffA//,root:Tdiff:TdiffB, root:Tdiff:TdiffC
		ModifyTable width=40
		ModifyTable sigDigits=10
		ModifyTable format(root:Tdiff:Hit)=10
		ModifyTable width(root:Tdiff:Hit)=60
		ModifyTable sigDigits(root:Tdiff:Hit)=8
		ModifyTable width(root:Tdiff:chnum)=30
		
	endif
EndMacro


Window Tdiff_plot_histos() : Graph
	DoWindow/F Tdiffhistos
	if (V_Flag!=1)
		Display/W=(200,50,600,350)/K=1 root:Tdiff:ThistoA//,root:Tdiff:ThistoB,root:Tdiff:ThistoC
		DoWindow/C Tdiffhistos
		ModifyGraph mirror=2
		ModifyGraph mode=6
		//ModifyGraph rgb(ThistoB)=(0,0,65280),rgb(ThistoC)=(0,0,0)
		Label left "N counts"
		Label bottom "Time Difference (ns)"
		//Legend/C/N=text0/J/F=0/A=MC "\\s(ThistoA) T diff A\r\\s(ThistoB) T diff B\r\\s(ThistoC) T diff C"
		Legend/C/N=text0/J/F=0/A=MC "\\s(ThistoA) T diff A"
		ShowInfo
	endif
EndMacro

Window Tdiff_plot_histos_annotated() : Graph
	DoWindow/F TdiffhistosAn
	if (V_Flag!=1)
		Display/W=(200,50,600,350) root:Tdiff:ThistoA//,root:Tdiff:ThistoB,root:Tdiff:ThistoC
		DoWindow/C TdiffhistosAn
		ModifyGraph mirror=2
		ModifyGraph mode=6
		//ModifyGraph rgb(ThistoB)=(0,0,65280),rgb(ThistoC)=(0,0,0)
		Label left "N counts"
		Label bottom "Time Difference (ns)"
		//Legend/C/N=text0/J/F=0/A=MC "\\s(ThistoA) T diff A\r\\s(ThistoB) T diff B\r\\s(ThistoC) T diff C"
		Legend/C/N=text0/J/F=0/A=MC "\\s(ThistoA) T diff A"
		ShowInfo
	endif
EndMacro




Function Tdiff_histo()

	Nvar NbinsTA = root:Tdiff:NbinsTA
	Nvar BinsizeTA = root:Tdiff:BinsizeTA
	Nvar NbinsTB = root:Tdiff:NbinsTB
	Nvar  BinsizeTB = root:Tdiff:BinsizeTB
	Nvar NbinsTC = root:Tdiff:NbinsTC
	Nvar BinsizeTC =  root:Tdiff:BinsizeTC

	histogram/B={-BinsizeTA*NbinsTA/2,BinsizeTA,NbinsTA} root:Tdiff:TdiffA,   root:Tdiff:ThistoA
	histogram/B={-BinsizeTB*NbinsTB/2,BinsizeTB,NbinsTB} root:Tdiff:TdiffB,   root:Tdiff:ThistoB
	histogram/B={-BinsizeTC*NbinsTC/2,BinsizeTC,NbinsTC} root:Tdiff:TdiffC,   root:Tdiff:ThistoC
//	print "Total in Tdiff histo: A:",sum( root:Tdiff:ThistoA), "B:",sum( root:Tdiff:ThistoB), "C:",sum( root:Tdiff:ThistoC)

End



Function Tdiff_compute_diff()	

	Nvar DiffA_P = root:Tdiff:DiffA_P
	Nvar DiffA_N = root:Tdiff:DiffA_N
	Nvar DiffB_P = root:Tdiff:DiffB_P
	Nvar DiffB_N = root:Tdiff:DiffB_N
	Nvar DiffC_P = root:Tdiff:DiffC_P
	Nvar DiffC_N = root:Tdiff:DiffC_N
	Nvar DiffA_toEv = root:Tdiff:DiffA_toEv
	Nvar DiffB_toEv = root:Tdiff:DiffB_toEv
	Nvar DiffC_toEv = root:Tdiff:DiffC_toEv
	Nvar DiffA_toPTP = root:Tdiff:DiffA_toPTP
	Nvar DiffB_toPTP = root:Tdiff:DiffB_toPTP
	Nvar DiffC_toPTP = root:Tdiff:DiffC_toPTP
	Nvar TSscale  = root:Tdiff:TSscale 
	Nvar DiffA_CFD = root:Tdiff:DiffA_CFD 
	Nvar DiffB_CFD = root:Tdiff:DiffA_CFD 
	Nvar DiffC_CFD = root:Tdiff:DiffA_CFD 

	
	String 	text = "root:Tdiff"
	Wave TdiffA = $(text+":TdiffA")				// user defined time difference
	Wave TdiffB = $(text+":TdiffB")		
	Wave TdiffC = $(text+":TdiffC")		
	
	Variable lsb_ig =1	// lsbs to ignore
 	
	// *** 4 *** compute user defined time differences 
	// TS repeats from previous valid entry for channels without hit, so current TS is last valid for all channels
	
	wave PA = $("root:Tdiff:LocTime"+num2str(DiffA_P))
	wave NA = $("root:Tdiff:LocTime"+num2str(DiffA_N))
	wave PD = $("root:Tdiff:CFD"+num2str(DiffA_P))
	wave ND = $("root:Tdiff:CFD"+num2str(DiffA_N))
	
	//lsb_ig = 4
	
	if (DiffA_toEv)
		wave NA = root:Tdiff:TrigTimeL
	endif
	if (DiffA_toPTP)
		wave NA = root:Tdiff:PTP_Time
	endif
	if(DiffA_CFD)
		//TdiffA =TSscale*(  PA - NA  - PD/256 + ND/256)	// include CFD time -- scaled by DSP/FPGA in subcycle units!
		//TdiffA =TSscale*(  lsb_ig*floor(PA/lsb_ig) - lsb_ig*floor(NA/lsb_ig)  + PD/256 - ND/256)	// try ignoring lower bits
		TdiffA =TSscale*(  PA - NA)  - PD + ND	// include CFD time scaled in ns
	else
		TdiffA =TSscale*(PA -  NA)	// in ns  TSscale*abs(PA -  NA)	// in ns
	endif

	wave PA = $("root:Tdiff:LocTime"+num2str(DiffB_P))
	wave NA = $("root:Tdiff:LocTime"+num2str(DiffB_N))
	wave PD = $("root:Tdiff:CFD"+num2str(DiffA_P))
	wave ND = $("root:Tdiff:CFD"+num2str(DiffA_N))
	if (DiffB_toEv)
		wave NA = root:Tdiff:TrigTimeL
	endif
	if (DiffB_toPTP)
		wave NA = root:Tdiff:PTP_Time
	endif	
	if(DiffB_CFD)
		TdiffB =TSscale*(PA -  NA + PD/256 - ND/256)	// include CFD time
	else
		TdiffB = TSscale*abs(PA -  NA)	// in ns
	endif
	
	wave PA = $("root:Tdiff:LocTime"+num2str(DiffC_P))
	wave NA = $("root:Tdiff:LocTime"+num2str(DiffC_N))
	wave PD = $("root:Tdiff:CFD"+num2str(DiffA_P))
	wave ND = $("root:Tdiff:CFD"+num2str(DiffA_N))
	if (DiffC_toEv)
		wave NA = root:Tdiff:TrigTimeL
	endif
	if (DiffC_toPTP)
		wave NA = root:Tdiff:PTP_Time
	endif
	if(DiffC_CFD)
		TdiffC =TSscale*(PA -  NA + PD/256 - ND/256)	// include CFD time
	else
		TdiffC = TSscale*abs(PA -  NA)	// in ns
	endif
	
	// *** 5 *** make time histograms
	
 	Tdiff_histo()
 	
 	// *** 6 *** assemble coincident energies
 	
//	LM_Extract_Tdiff()
	
	// histogram into 2D MCA
//	Generate2DMCA(1)
	

End

Window ExEyScatter() : Graph
	PauseUpdate; Silent 1		// building window...

	DoWindow/F ExEyScatter
	if(V_flag!=1)
		Display/K=1/W=(35.25,42.5,429.75,251)  root:Tdiff:ETy vs root:Tdiff:ETx  as "Scatter plot"
		DoWindow/C ExEyScatter
		ModifyGraph mode=2
		ModifyGraph mirror=2
		Label left "Energy (DSP units)"
		Label bottom "Energy (DSP units)"
		ShowInfo
	endif
EndMacro

Function LM_Extract_Tdiff()

		// ****** assemble coincident energies
	
	Nvar chanA = root:Tdiff:chanA
	Nvar chanB = root:Tdiff:chanB
	Nvar CW  = root:Tdiff:CW 
	Nvar plotx =  root:Tdiff:plotx 
	Nvar ploty =  root:Tdiff:ploty 
	Nvar Nevents = root:Tdiff:Nevents 				// number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 	 
	Nvar TSscale  = root:Tdiff:TSscale 
		
	
	String text
	text = "root:Tdiff"
	wave EA =  $(text+":Energy"+num2str(chanA))
	wave EB =  $(text+":Energy"+num2str(chanB))
	wave TA =  $(text+":LocTime"+num2str(chanA))
	wave TB =  $(text+":LocTime"+num2str(chanB))
	Wave ETx = $(text+":ETx")				// energy or time for x axis
	Wave ETy = $(text+":ETy")				// energy or time for y axis
	wave Tdiffxy =  $(text+":Tdiffxy")			// time diff for those matching events

	Variable dt, sx, sy, m, ncoinc, nev
	 nev = min(Nevents,MaxEvents)
	
	// fill x and y waves for scatter plot
	ETx = 0
	ETy = 0
	Tdiffxy = nan
	ncoinc = 0
	for(m=0;m<nev;m+=1)		
			dt =TSscale*abs(TA[m]-TB[m])
						
			if(plotx==1)
				if(EA[m]>0)
					sx = EA[m]	// use last E > 0
				endif
			endif
			if(plotx==2)
				if(EB[m]>0)
					sx = EB[m]	// use last E > 0
				endif
			endif
			if(plotx==3)
				sx = dt
			endif
			
			if(ploty==1)
				if(EA[m]>0)
					sy = EA[m]	// use last E > 0
				endif
			endif
			if(ploty==2)
				if(EB[m]>0)
					sy = EB[m]	// use last E > 0
				endif
			endif
			if(ploty==3)
				sy = dt
			endif		
		
			if (dt <= CW) 
				ncoinc +=1
				ETx[m] = sx
				ETy[m] = sy
				Tdiffxy[m] = dt
			endif
	
	endfor
	
	print "number of coincidences", ncoinc

End



Function LM_Extract_HP()

		// ****** assemble  energies etc matching hit patterns
	
	//Nvar chanA = root:Tdiff:chanA
	Nvar ExtractHitPatternOR  = root:Tdiff:ExtractHitPatternOR 
	Nvar ExtractHitPatternAND  = root:Tdiff:ExtractHitPatternAND
	Nvar Nevents = root:Tdiff:Nevents 				// number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 	 
	
	String text
	text = "root:Tdiff"
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave Energy0 = $(text+":Energy0")				// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")		

	Variable nev, nmhp,m
	nev = min(Nevents,MaxEvents)
	nmhp = 0
	
	// check hit patterns
	for(m=0;m<nev;m+=1)		
		
		if ( (hit[m] | ExtractHitPatternOR) ==  (ExtractHitPatternAND | ExtractHitPatternOR)  ) 
			nmhp +=1
		else
			energy[m] = nan
			Energy0[m] = nan
			Energy1[m] = nan
			Energy2[m] = nan
			Energy3[m] = nan
		endif

	endfor
	
	print "number of matching hit patterns", nmhp
	
	Wave MCAch0 = root:pixie4:MCAch0
	Wave MCAch1 = root:pixie4:MCAch1
	Wave MCAch2 = root:pixie4:MCAch2
	Wave MCAch3 = root:pixie4:MCAch3
	Wave MCAsum = root:pixie4:MCAsum
	
	histogram/B={0,1,32768} Energy0, MCAch0
	MCAch0[0]=0
	histogram/B={0,1,32768} Energy1, MCAch1
	MCAch1[0]=0
	histogram/B={0,1,32768} Energy2, MCAch2
	MCAch1[0]=0
	histogram/B={0,1,32768} Energy3, MCAch3
	MCAch3[0]=0
	histogram/B={0,1,32768} energy, MCAsum
	MCAsum[0]=0

End


Function Tdiff_Panel_PopProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr
	
	Nvar plotx =  root:Tdiff:plotx 
	Nvar ploty =  root:Tdiff:ploty 
	
	if(cmpstr(ctrlName,"pltx")==0)
		plotx = popNum-1
	endif
	if(cmpstr(ctrlName,"plty")==0)
		ploty = popNum-1
	endif

End





Function ExtractPTPsteps()

	Wave PTP_time
	make/D/o/n=50960 PTP_timesteps, PTP_timediff, PTP_timedev
	Wave PTP_timesteps
	Wave PTP_timediff
	
	Variable m, nevents, lastPTP_time, pp, over
	
	pp=0
	over=0
	lastPTP_time  = PTP_time[0]
	PTP_timesteps[pp] = lastPTP_time
	
	
	wavestats/q PTP_time
	nevents = V_npnts
	 for(m=0;m<nevents;m+=1)
		 if(PTP_time[m] != lastPTP_time)
		 	pp+=1
		 	if(PTP_time[m]<lastPTP_time)
		 		over+= 2^32
		 	endif
		 	PTP_timesteps[pp] = PTP_time[m]+over
		 	
		 	PTP_timediff[pp-1] = PTP_timesteps[pp] - PTP_timesteps[pp-1]
		 	lastPTP_time  = PTP_time[m]	 
		 endif
	 endfor
	 
	 wavestats/q/R=[1,pp-1] PTP_timediff
	 PTP_timedev = floor(PTP_timediff - V_avg)
	 
	 make/o/n=1 PTP_timedev_Hist
	 wave PTP_timedev_Hist
	 Histogram/B={-3000,64,256}/R=[1,pp-1] PTP_timedev,PTP_timedev_Hist
	 
	 CurveFit/M=2/W=0 gauss, PTP_timedev_Hist/D
	 
	 wavestats/q/R=[1,pp-1] PTP_timediff
	 wave W_coef
	 print/D "PTP_timedif: avg",V_avg, "sdev", V_sdev
	 print "dev centroid",W_coef[2] , "FWHM", W_coef[3]*2*sqrt(ln(2))
	
	 print pp, "timesteps"
End



// *******************************************************************************************
// File I/O functions loading LM data from file into eventwaves
// (hit, chnum, energy#, LocTime# etc)
// *******************************************************************************************


Function LM_FileRead_500()

	// read traces, E from a 0x500 txt file into Igor 
	// faster than reading event by event with Pixie_File_ReadEvent for huge files, but uses a lot of PC memory. 
	// After lead, set  root:pixie4:tracesinpxp =1 to take data from memory, not file in Pixie_File_ReadEvent
	
	Nvar evsize =  root:pixie4:evsize
	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	Variable refNum
	Open/R refNum as ""				// Display dialog
	Svar lmfilename = root:pixie4:lmfilename
	lmfilename = S_fileName
	
	Nevents = MaxEvents
	make/o/n=(evsize-8,Nevents) alltraces
	//make/o/n=(MaxEvents) pn_energy
	Tdiff_process_makethewaves(Nevents)	// creates/resizes, and sets to nan
	oldNevents = nevents		
	
	// define waves
	String text = "root:Tdiff"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")		// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
//	Wave PTP_Time =  $(text+":PTP_Time")				// time stamp of external trigger
//	Wave rt = $(text+":rt")		
//	Wave psa = $(text+":psa")		

	Variable lineNumber, len
	Variable no, pt, k, ht, m
	no=0
	String buffer
	lineNumber = 0
	FReadLine refNum, buffer		// header reads
	FReadLine refNum, buffer
	FReadLine refNum, buffer
	FReadLine refNum, buffer
	for(no=0;no<MaxEvents;no+=1)
		if (mod(no,10000)==0)
			print "reading event #",no
			DoUpdate
		endif
		for(k=0;k<evsize;k+=1)
			FReadLine refNum, buffer
			len = strlen(buffer)
			if (len == 0)
				Close refNum
				no=MaxEvents					// No more lines to be read, break out of loops
				k=evsize
			else
				if(k==1)
					chnum[no] = str2num(buffer)
				endif
				if(k==2)
					sscanf buffer, "0x%x",ht
					 hit[no] = ht
				endif
				if(k==3)
					TrigTimeH[no] = str2num(buffer)
				endif
				if(k==4)
					TrigTimeL[no] = str2num(buffer)
				endif
				if(k==5)
					energy[no] = str2num(buffer)
				endif
				
				if(k>=8)
					alltraces[k-8][no] = str2num(buffer)
				endif
			endif	
			
		endfor
	endfor
	
	// sort channel E, T into Tdiff compatible arrays for each channel
	Variable lastE0, lastE1, lastE2, lastE3
	Variable lastT0, lastT1, lastT2, lastT3	
	lastE0 = nan
	lastE1 = nan
	lastE2 = nan
	lastE3 = nan
	lastT0 = nan
	lastT1 = nan
	lastT2 = nan
	lastT3 = nan
	for(m=0;m<Nevents;m+=1)
		if(chnum[m]==0)
			lastE0 = energy[m]
			lastT0 =  TrigTimeL[m]
		endif

		if(chnum[m]==1)
			lastE1 = energy[m]
			lastT1 =  TrigTimeL[m]
		endif
		
		if(chnum[m]==2)
			lastE2 = energy[m]
			lastT2 =  TrigTimeL[m]
		endif

		if(chnum[m]==3)
			lastE3 = energy[m]
			lastT3 =  TrigTimeL[m]		
		endif
		
		Energy0[m]   	= lastE0
		LocTime0[m] 	= lastT0
		Energy1[m]   	= lastE1
		LocTime1[m] 	= lastT1		
		Energy2[m]   	= lastE2
		LocTime2[m] 	= lastT2		
		Energy3[m]   	= lastE3
		LocTime3[m] 	= lastT3
	endfor

	Close refNum
	return 0
	
	print Nevents, "total"
End



Function LM_FileRead_501()

	// processing parameters
	Nvar TSrecordlength	= root:Tdiff:TSrecordlength 	// number of PSA data words for all 4 channels
	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	Svar lmfilename = root:pixie4:lmfilename
	
	String text
	Variable m
	Variable lastE0, lastE1, lastE2, lastE3
	Variable lastT0, lastT1, lastT2, lastT3
	
	// *** 1 *** get data from file

	LoadWave/P=home/O/J/L={2,3,0,0,0}/W/A/D  //  "LMdata.dat"
	lmfilename = S_fileName
	wave LM_ch = ch
	wave LM_time_L = time_L
	wave LM_time_H = time_H
	wave LM_energy = energy 
	wave LM_hit = hit 
	 wavestats/q LM_ch
	 nevents =  V_npnts
	 if(nevents==0)
	 	print "empty file, aborting"
	 	return(-1)
	 endif

	 Nevents = min(Nevents,MaxEvents)
//	if (nevents!= oldNevents)
		Tdiff_process_makethewaves(nevents)	// creates/resizes, and sets to nan
//	endif
	oldNevents = nevents		
	
	
	// *** 2 *** sort data from file or memory into waves, 
	
	// define waves
	text = "root:Tdiff"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave rt = $(text+":rt")					
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")		// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave PTP_Time =  $(text+":PTP_Time")				// time stamp of external trigger


	lastE0 = nan
	lastE1 = nan
	lastE2 = nan
	lastE3 = nan
	lastT0 = nan
	lastT1 = nan
	lastT2 = nan
	lastT3 = nan
	for(m=0;m<nevents;m+=1)								
		// fill Es and TSs
		energy[m] =  LM_energy[m]
		chnum[m] = LM_ch[m]
		hit[m] = LM_hit[m]
		TrigTimeL[m] = LM_time_L[m]
		TrigTimeH[m] = LM_time_H[m]
		// no PTP time in record
		
		if(LM_ch[m]==0)
			lastE0 = LM_energy[m]
			lastT0 =  LM_time_L[m]
		endif

		if(LM_ch[m]==1)
			lastE1 = LM_energy[m]
			lastT1 =  LM_time_L[m]
		endif
		
		if(LM_ch[m]==2)
			lastE2 = LM_energy[m]
			lastT2 =  LM_time_L[m]
		endif

		if(LM_ch[m]==3)
			lastE3 = LM_energy[m]
			lastT3 =  LM_time_L[m]		
		endif
		
		Energy0[m]   	= lastE0
		LocTime0[m] 	= lastT0
		Energy1[m]   	= lastE1
		LocTime1[m] 	= lastT1		
		Energy2[m]   	= lastE2
		LocTime2[m] 	= lastT2		
		Energy3[m]   	= lastE3
		LocTime3[m] 	= lastT3
						
	endfor	
	
	// delete auto generated waves from file read
	killwaves/Z	root:No, root:Ch, root:Hit, root:Time_H, root:Time_L, root:Energy
		
	
	print Nevents, "total"
	
	// *** 3 *** read run statistics from .ifm file
	// TODO get count time info for rates
	
	
End

Function LM_FileRead_502()

	// processing parameters
	Nvar TSrecordlength	= root:Tdiff:TSrecordlength 	// number of PSA data words for all 4 channels
	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	Svar lmfilename = root:pixie4:lmfilename
	
	String text
	Variable m
	Variable lastE0, lastE1, lastE2, lastE3
	Variable lastT0, lastT1, lastT2, lastT3
	Variable lastC0, lastC1, lastC2, lastC3, currentCFD
	
	// *** 1 *** get data from file

	LoadWave/P=home/O/J/L={2,3,0,0,0}/W/A/D  //  "LMdata.dat"
	lmfilename = S_fileName		
	wave LM_ch = Channel_No					// waves created by file read are auto-named with column title in file
	wave LM_time_L = Event_Time_L
	wave LM_time_H =  Event_Time_H
	wave LM_energy = energy 
	wave LM_hit = hit_pattern	
	wave LM_ampl = Amplitude
	wave LM_CFD =  CFD
	wave LM_base = Base 
	wave LM_Q0 = Q0
	wave LM_Q1 = Q1
	wave LM_PSA = PSAvalue
		
	 wavestats/q LM_ch
	 nevents =  V_npnts
	 if(nevents==0)
	 	print "empty file, aborting"
	 	return(-1)
	 endif

	 Nevents = min(Nevents,MaxEvents)
//	if (nevents!= oldNevents)
		Tdiff_process_makethewaves(nevents)	// creates/resizes, and sets to nan
//	endif
	oldNevents = nevents		
	
	
	// *** 2 *** sort data from file or memory into waves, 
	
	// define waves
	text = "root:Tdiff"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave rt = $(text+":rt")					
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")		// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave PTP_Time =  $(text+":PTP_Time")				// time stamp of external trigger
	Wave CFD0 = $(text+":CFD0")			// CFD for each event
	Wave CFD1 = $(text+":CFD1")			
	Wave CFD2 = $(text+":CFD2")			
	Wave CFD3 = $(text+":CFD3")		


	lastE0 = nan
	lastE1 = nan
	lastE2 = nan
	lastE3 = nan
	lastT0 = nan
	lastT1 = nan
	lastT2 = nan
	lastT3 = nan
	lastC0 = nan
	lastC1 = nan
	lastC2 = nan
	lastC3 = nan
	
	for(m=0;m<nevents;m+=1)								
		// fill Es and TSs
		energy[m] =  LM_energy[m]
		chnum[m] = LM_ch[m]
		hit[m] = LM_hit[m]
		TrigTimeL[m] = LM_time_L[m]
		TrigTimeH[m] = LM_time_H[m]
		// no PTP time in record
		
		if(LM_ch[m]==0)
			lastE0 = LM_energy[m]
			lastT0 =  LM_time_L[m]
			lastC0 = LM_CFD[m]
		endif

		if(LM_ch[m]==1)
			lastE1 = LM_energy[m]
			lastT1 =  LM_time_L[m]
			lastC1 = LM_CFD[m]
		endif
		
		if(LM_ch[m]==2)
			lastE2 = LM_energy[m]
			lastT2 =  LM_time_L[m]
			lastC2 = LM_CFD[m]
		endif

		if(LM_ch[m]==3)
			lastE3 = LM_energy[m]
			lastT3 =  LM_time_L[m]	
			lastC3 = LM_CFD[m]	
		endif
		
		Energy0[m]   	= lastE0
		Energy1[m]   	= lastE1
		Energy2[m]   	= lastE2
		Energy3[m]   	= lastE3
		
		
		LocTime0[m] 	= lastT0
		LocTime1[m] 	= lastT1	
		LocTime2[m] 	= lastT2	
		LocTime3[m] 	= lastT3		
		
		CFD0[m] 	= lastC0
		CFD1[m] 	= lastC1	
		CFD2[m] 	= lastC2	
		CFD3[m] 	= lastC3	
						
	endfor	
	
	// delete auto generated waves from file read
	killwaves/Z	root:Event_No, root:Channel_No, root:hit_pattern, root:Event_Time_H, root:Event_Time_L, root:Energy
	killwaves/Z	root:Amplitude, root:CFD, root:Base, root:Q0, root:Q1, root:PSAvalue	
	
	print Nevents, "total"
	
	// *** 3 *** read run statistics from .ifm file
	// TODO get count time info for rates
	
	
End


Function LM_FileRead_503()

	// processing parameters
	Nvar TSrecordlength	= root:Tdiff:TSrecordlength 	// number of PSA data words for all 4 channels
	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	Svar lmfilename = root:pixie4:lmfilename
	
	String text
	Variable m
	
	// *** 1 *** get data from file
	LoadWave/P=home/O/J/L={2,3,0,0,0}/W/A/D //  "LMdata.dt3"
	lmfilename = S_fileName
	wave LM_Event_Time_L = Event_Time_L
	wave LM_Event_Time_H = Event_Time_H
	wave LM_hit = Hit_Pattern 
	wave LM_Time0 = Time0
	wave LM_Time1 = Time1
	wave LM_Time2 = Time2
	wave LM_Time3 = Time3
	wave LM_Energy0 = Energy0
	wave LM_Energy1 = Energy1
	wave LM_Energy2 = Energy2
	wave LM_Energy3 = Energy3
	wave LM_PTP_Time = PTP_time
						
	wavestats/q LM_Event_Time_L
	nevents =  V_npnts
	if(nevents==0)
	 	print "empty file, aborting"
	 	return(-1)
	 endif

	 Nevents = min(Nevents,MaxEvents)
//	if (nevents!= oldNevents)
		Tdiff_process_makethewaves(nevents)	// creates/resizes, and sets to nan
//	endif
	oldNevents = nevents		
	
	
	// *** 2 *** sort data from file or memory into waves, 
	
	// define waves
	text = "root:Tdiff"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave rt = $(text+":rt")					
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")		// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave PTP_Time =  $(text+":PTP_Time")				// time stamp of external trigger


	for(m=0;m<nevents;m+=1)			

		hit[m] = LM_hit[m]
		TrigTimeL[m] 		= LM_Event_Time_L[m] 
		TrigTimeH[m] 		= LM_Event_Time_H[m] 
		PTP_Time[m]		= LM_PTP_Time[m]
		// no ch or energy in record
	
		Energy0[m]   	= LM_Energy0[m]
		LocTime0[m] 	= LM_Time0[m]
		Energy1[m]   	= LM_Energy1[m]
		LocTime1[m] 	= LM_Time1[m]	
		Energy2[m]   	= LM_Energy2[m]
		LocTime2[m] 	= LM_Time2[m]
		Energy3[m]   	= LM_Energy3[m]
		LocTime3[m] 	= LM_Time3[m]
	
	endfor	
	
	// delete auto generated waves from file read
	killwaves/Z	root:Event_No, root:Hit_Pattern, root:Event_Time_H, root:Event_Time_L, root:PTP_Time
	killwaves/Z    root:Time0, root:Time1, root:Time2, root:Time3, root:Energy0, root:Energy1, root:Energy2, root:Energy3

	print Nevents, "total"
	
	// *** 3 *** read run statistics from .ifm file
	// TODO get count time info for rates
	
	
End

//Function LM_FileRead_404()
//
//	Variable refnum
//	Svar lmfilename = root:pixie4:lmfilename
//	open/P=home/D/R/T="????" refnum 
//	lmfilename = S_fileName
//	if(cmpstr(S_fileName,"")==0)
//		print "File selection cancelled, aborting"
//		return(-1)
//	endif
//	
//	// use P4e function to read .b00 file into wfarray
//	Pixie_File_ReadRawLMdata("")
//
//
//
//	// define source waves created by  P4e function
//	Wave wfarray
//	Wave LMheader
//		
//	
//	// find number of events
//	Variable eventlength
//	Nvar evsize =  root:pixie4:evsize
//	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
//	Nvar MaxEvents = root:Tdiff:MaxEvents 
//	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
//	
//	eventlength = LMheader[9]	*  32+ LMheader[0]
//
//	wavestats/q wfarray
//	Nevents = V_npnts/eventlength
//	Nevents = min(Nevents,MaxEvents)
////	if (nevents!= oldNevents)
//		Tdiff_process_makethewaves(nevents+1)	// creates/resizes, and sets to nan 	// +1 just in case there is an end run record
////	endif
//	oldNevents = nevents		
//	
//
//	// define destination waves
//	String text = "root:Tdiff"
//	Wave chnum = $(text+":chnum")	
//	Wave hit = $(text+":hit")	
//	Wave energy = $(text+":energy")				// any or sum energy
//	Wave Energy0 = $(text+":Energy0")			// energy for each event
//	Wave Energy1 = $(text+":Energy1")			
//	Wave Energy2 = $(text+":Energy2")			
//	Wave Energy3 = $(text+":Energy3")			
//	Wave LocTime0 = $(text+":LocTime0")		// loca time stamp for each event
//	Wave LocTime1 = $(text+":LocTime1")		
//	Wave LocTime2 = $(text+":LocTime2")		
//	Wave LocTime3 = $(text+":LocTime3")		
//	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
//	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
////	Wave PTP_Time =  $(text+":PTP_Time")				// time stamp of external trigger
////	Wave rt = $(text+":rt")		
////	Wave psa = $(text+":psa")		
//	Wave CFD0 = $(text+":CFD0")			// CFD for each event
//	Wave CFD1 = $(text+":CFD1")			
//	Wave CFD2 = $(text+":CFD2")			
//	Wave CFD3 = $(text+":CFD3")			
//	
//	Variable runtype = LMheader[2]	
//	Variable no,Chstart, Chend
//	Variable lastE0, lastE1, lastE2, lastE3		// store "last" E, T, CFD value and copy in current event record
//	Variable lastT0, lastT1, lastT2, lastT3		// so that they can be matched across subsequent events in 0x400
//	Variable lastC0, lastC1, lastC2, lastC3, currentCFD
//	lastE0 = nan
//	lastE1 = nan
//	lastE2 = nan
//	lastE3 = nan
//	lastT0 = nan
//	lastT1 = nan
//	lastT2 = nan
//	lastT3 = nan
//	lastC0 = nan
//	lastC1 = nan
//	lastC2 = nan
//	lastC3 = nan
//		
//	for(no=0;no<Nevents;no+=1)
//
//
//		hit[no] = 0
//		
//		
//			TrigTimeL[no] =  wfarray[11][no]+65536*wfarray[12][no]
//			TrigTimeH[no] = wfarray[13][no]+65536*wfarray[14][no]	
//			chnum[no] = wfarray[16][no]
//			energy[no] = wfarray[15][no]
//			currentCFD = 0
//			
//			if(chnum[no]==0)
//				lastE0 = energy[no]
//				lastT0 =  TrigTimeL[no]
//				lastC0 = currentCFD
//			endif
//	
//			if(chnum[no]==1)
//				lastE1 = energy[no]
//				lastT1 =  TrigTimeL[no]
//				lastC1 = currentCFD
//			endif
//			
//			if(chnum[no]==2)
//				lastE2 = energy[no]
//				lastT2 =  TrigTimeL[no]
//				lastC2 = currentCFD
//			endif
//	
//			if(chnum[no]==3)
//				lastE3 = energy[no]
//				lastT3 =  TrigTimeL[no]	
//				lastC3 = currentCFD	
//			endif
//			
//			Energy0[no]   	= lastE0			
//			Energy1[no]   	= lastE1			
//			Energy2[no]   	= lastE2		
//			Energy3[no]   	= lastE3		
//			
//			LocTime0[no] 	= lastT0
//			LocTime1[no] 	= lastT1	
//			LocTime2[no] 	= lastT2	
//			LocTime3[no] 	= lastT3	
//			
//			CFD0[no] 	= lastC0
//			CFD1[no] 	= lastC1	
//			CFD2[no] 	= lastC2	
//			CFD3[no] 	= lastC3	
//
//	endfor
//	
//	//DoWindow/K FileHeaderTable
//	//DoWindow/K EventArrayTable
//	//killwaves/Z root:wfarray, root:LMheader
//	
//	print Nevents, "total"
//	
//	// *** 3 *** read run statistics from .ifm file
//	// TODO get count time info for rates
//
//End



Function LM_FileRead_116()

	Variable refnum
	Svar lmfilename = root:pixie4:lmfilename
	open/P=home/D/R/T="????" refnum 
	lmfilename = S_fileName
	if(cmpstr(S_fileName,"")==0)
		print "File selection cancelled, aborting"
		return(-1)
	endif
	
	Nvar runtype = root:pixie4:runtype
	
	// use P4e function to read .bin file into wfarray
	Pixie_File_ReadRawLMdata("")

		variable off=0
		if((runtype==0x104) )
			off = 3				// in 0x404, words are shifted down by 3  and the event is 3 words longer
		endif


	// define source waves created by  P4e function
	Wave wfarray
	Wave LMheader
	//Wave LMData0
	
	// find number of events
	Variable eventlength
	Nvar evsize =  root:pixie4:evsize
	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	eventlength = (LMheader[1+off] & 0x7FFE)	+off
	wavestats/q wfarray
	Nevents = V_npnts/eventlength
	Nevents = min(Nevents,MaxEvents)
//	if (nevents!= oldNevents)
		Tdiff_process_makethewaves(nevents+1)	// creates/resizes, and sets to nan 	// +1 just in case there is an end run record
//	endif
	oldNevents = nevents		
	

	// define destination waves
	String text = "root:Tdiff"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")		// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave PTP_Time =  $(text+":PTP_Time")				// time stamp of external trigger
//	Wave rt = $(text+":rt")		
//	Wave psa = $(text+":psa")		
	Wave CFD0 = $(text+":CFD0")			// CFD for each event
	Wave CFD1 = $(text+":CFD1")			
	Wave CFD2 = $(text+":CFD2")			
	Wave CFD3 = $(text+":CFD3")		
	Nvar UsePTPforLOC = root:Tdiff:UsePTPforLOC	
	
//	Variable runtype = 0x116
	Variable no,Chstart, Chend
	Variable lastE0, lastE1, lastE2, lastE3		// store "last" E, T, CFD value and copy in current event record
	Variable lastT0, lastT1, lastT2, lastT3		// so that they can be matched across subsequent events in 0x400
	Variable lastC0, lastC1, lastC2, lastC3, currentCFD
	lastE0 = nan
	lastE1 = nan
	lastE2 = nan
	lastE3 = nan
	lastT0 = nan
	lastT1 = nan
	lastT2 = nan
	lastT3 = nan
	lastC0 = nan
	lastC1 = nan
	lastC2 = nan
	lastC3 = nan
		
	for(no=0;no<Nevents;no+=1)
	//	if (mod(no,10000)==0)
	//		print "reading event #",no
	//		DoUpdate
	//	endif

		hit[no] = 0 //wfarray[0][no]+65536*wfarray[1][no]
		
		
			TrigTimeL[no] =  wfarray[2+off][no]+65536*wfarray[3+off][no]
			TrigTimeH[no] = wfarray[4+off][no]	
			chnum[no] = wfarray[0+off][no] & 0xF
			energy[no] = wfarray[6+off][no]
			currentCFD = wfarray[5+off][no]
			//PTP_Time[no] = (wfarray[19+off][no] & 0xFF00) / 256
			//PTP_Time[no] = wfarray[16+off][no]+65536*(wfarray[17+off][no] & 0x1FFF)	
			PTP_Time[no] = wfarray[16+off][no]+65536*(wfarray[17+off][no] )	// Careful: 3 upper bits of extts in WR mode are seconds ?
			
			if(mod(chnum[no],4)==0)
				lastE0 = energy[no]
				if(UsePTPforLOC)
					lastT0 =  PTP_Time[no]
				else
					lastT0 =  TrigTimeL[no]
				endif		
				lastC0 = currentCFD
			endif
	
			if(mod(chnum[no],4)==1)
				lastE1 = energy[no]			
				if(UsePTPforLOC)
					lastT1 =  PTP_Time[no]
				else
					lastT1 =  TrigTimeL[no]
				endif
				lastC1 = currentCFD
			endif
			
			if(mod(chnum[no],4)==2)
				lastE2 = energy[no]
				if(UsePTPforLOC)
					lastT2 =  PTP_Time[no]
				else
					lastT2 =  TrigTimeL[no]
				endif
				lastC2 = currentCFD
			endif
	
			if(mod(chnum[no],4)==3)
				lastE3 = energy[no]
				if(UsePTPforLOC)
					lastT3 =  PTP_Time[no]
				else
					lastT3 =  TrigTimeL[no]
				endif
				lastC3 = currentCFD	
			endif
			
			Energy0[no]   	= lastE0			
			Energy1[no]   	= lastE1			
			Energy2[no]   	= lastE2		
			Energy3[no]   	= lastE3		
			
			LocTime0[no] 	= lastT0
			LocTime1[no] 	= lastT1	
			LocTime2[no] 	= lastT2	
			LocTime3[no] 	= lastT3	
			
			CFD0[no] 	= lastC0
			CFD1[no] 	= lastC1	
			CFD2[no] 	= lastC2	
			CFD3[no] 	= lastC3	

	endfor
	
	DoWindow/K FileHeaderTable
//	DoWindow/K EventArrayTable
//	killwaves/Z root:wfarray, root:LMheader
	
	print Nevents, "total"
	
	// *** 3 *** read run statistics from .ifm file
	// TODO get count time info for rates

End





Function LM_File_ExtractHP_40x()
// don't load the whole file, just read event by event and increment MCAs
// for huge files

	// select file
	Variable refnum
	Svar lmfilename = root:pixie4:lmfilename
	open/P=home/D/R/T="????" refnum 
	lmfilename = S_fileName
	if(cmpstr(S_fileName,"")==0)
		print "File selection cancelled, aborting"
		return(-1)
	endif
	
	// find number of events
	Nvar runtype = root:pixie4:runtype
	Nvar evsize =  root:pixie4:evsize
	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	Nvar ChosenEvent = root:pixie4:ChosenEvent		// number of event to read
	oldNevents = MaxEvents	
	Nevents = MaxEvents	
	
	Nvar ExtractHitPatternOR  = root:Tdiff:ExtractHitPatternOR 
	Nvar ExtractHitPatternAND  = root:Tdiff:ExtractHitPatternAND

	Wave MCAch0 = root:pixie4:MCAch0
	Wave MCAch1 = root:pixie4:MCAch1
	Wave MCAch2 = root:pixie4:MCAch2
	Wave MCAch3 = root:pixie4:MCAch3
	MCAch0 = 0
	MCAch1 = 0
	MCAch2 = 0
	MCAch3 = 0
	
	Variable no,Chstart, Chend, ret,nmhp, ch

	
	Nvar EventHitpattern = root:Pixie4:EventHitpattern
	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy

		
	for(no=0;no<Nevents;no+=1)
		if (mod(no,10000)==0)
			print "reading event #",no
			DoUpdate
		endif
		ChosenEvent = no
		ret = Pixie_File_ReadEvent()
		
		if(ret>=0)
			if ( (EventHitpattern | ExtractHitPatternOR) ==  (ExtractHitPatternAND | ExtractHitPatternOR)  ) 
				nmhp +=1

				if(ListModeChannelEnergy[0]>0)
					MCAch0[floor(ListModeChannelEnergy[0]/2)]	+=1	// manual histogram with fixed binfactor
				endif

				if(ListModeChannelEnergy[1]>0)
					MCAch1[floor(ListModeChannelEnergy[1]/2)]	+=1	// manual histogram with fixed binfactor
				endif

				if(ListModeChannelEnergy[2]>0)
					MCAch2[floor(ListModeChannelEnergy[2]/2)]	+=1	// manual histogram with fixed binfactor
				endif

				if(ListModeChannelEnergy[3]>0)
					MCAch3[floor(ListModeChannelEnergy[3]/2)]	+=1	// manual histogram with fixed binfactor
				endif
				
			endif
		else
			print "end of file reached, aborting"
			break
		endif

	endfor
	
	oldNevents = no	
	Nevents = no	
	MCAch0[0] = 0
	MCAch1[0] = 0
	MCAch2[0] = 0
	MCAch3[0] = 0
	
	
	print Nevents, "total", nmhp, "matching hit pattern"
	
	
End



Function LM_File_ExtractCFD_singles(newfile)
Variable newfile
//Variable ch		// this function assumes single channel event records
// don't load the whole file, just read event by event and compute CFD time
// for huge files
// currently only manually called from command line

	// select file
	Svar lmfilename = root:pixie4:lmfilename
	if(newfile==1)
		Variable refnum
		Svar lmfilename = root:pixie4:lmfilename
		open/P=home/D/R/T="????" refnum 
		lmfilename = S_fileName
		if(cmpstr(S_fileName,"")==0)
			print "File selection cancelled, aborting"
			return(-1)
		endif
	endif
	print "loading data from",lmfilename
	
	// find number of events
	Nvar runtype = root:pixie4:runtype
	Nvar evsize =  root:pixie4:evsize
	Nvar  oldNevents = root:Tdiff:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:Tdiff:MaxEvents 
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	Nvar ChosenEvent = root:pixie4:ChosenEvent	// number of event to read
	oldNevents = MaxEvents	
	Nevents = MaxEvents	
	
	// options
	Nvar UsePTPforLOC = root:Tdiff:UsePTPforLOC	
	Nvar  TSscale = root:Tdiff:TSscale

	// local variables
	Variable no, ret, ch

	// source waves and globals
	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
	Wave ListModeChannelTrigger=root:pixie4:ListModeChannelTrigger
	Wave ListModeChannelUser = root:pixie4:ListModeChannelUser
	Nvar EventTimeHI = root:Pixie4:EventTimeHI
	Nvar EventTimeLO = root:Pixie4:EventTimeLO
	Nvar EventHitpattern = root:Pixie4:EventHitpattern
	Nvar ChosenChannel = root:pixie4:ChosenChannel	// Pixie_File_ReadEvent sets that channel number

	
	// destination waves and globals
	Tdiff_process_makethewaves(Nevents)
	// extra waves for CFD
	make/o/n=(Nevents) root:Tdiff:CFDtime
	wave CFDtime = root:Tdiff:CFDtime
	CFDtime = nan
	
	String text = "root:Tdiff"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")		// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave PTP_Time =  $(text+":PTP_Time")				// time stamp of external trigger
//	Wave rt = $(text+":rt")		
//	Wave psa = $(text+":psa")		
	Wave CFD0 = $(text+":CFD0")			// CFD for each event
	Wave CFD1 = $(text+":CFD1")			
	Wave CFD2 = $(text+":CFD2")			
	Wave CFD3 = $(text+":CFD3")		
	
	Variable lastE0, lastE1, lastE2, lastE3		// store "last" E, T, CFD value and copy in current event record
	Variable lastT0, lastT1, lastT2, lastT3		// so that they can be matched across subsequent events in 0x400
	Variable lastC0, lastC1, lastC2, lastC3, currentCFD
	lastE0 = nan
	lastE1 = nan
	lastE2 = nan
	lastE3 = nan
	lastT0 = nan
	lastT1 = nan
	lastT2 = nan
	lastT3 = nan
	lastC0 = nan
	lastC1 = nan
	lastC2 = nan
	lastC3 = nan
	
		
	for(no=0;no<MaxEvents;no+=1)
		if (mod(no,10000)==0)
			print "reading event #",no
			DoUpdate
		endif
		ChosenEvent = no
		ret = Pixie_File_ReadEvent()	
		ch = ChosenChannel
			
		if(ret>=0)
		
			// copy E, T, etc	
			hit[no] = EventHitpattern
			TrigTimeL[no] = EventTimeLO 
			TrigTimeH[no] = EventTimeHI						
			chnum[no] = ChosenChannel		// this is modulo 4 already
			energy[no] = ListModeChannelEnergy[ch]
			PTP_time[no] = ListModeChannelUser[ch]
		
			// compute CFD time
			//CFDtime[no] = LM_event_CFDfromtrace(ch) 		*256/TSscale		// scale from ns to DSP/FPGA fractions	// 250 MHz
			CFDtime[no] = LM_event_CFDfromtrace(ch) 		*256/TSscale		// scale from ns to DSP/FPGA fractions // 125 MHz
				
			// channel specific
			if(mod(chnum[no],4)==0)
				lastE0 = energy[no]
				if(UsePTPforLOC)
					lastT0 =  PTP_Time[no]
				else
					lastT0 =  TrigTimeL[no]
				endif		
				lastC0 = CFDtime[no]
			endif
	
			if(mod(chnum[no],4)==1)
				lastE1 = energy[no]			
				if(UsePTPforLOC)
					lastT1 =  PTP_Time[no]
				else
					lastT1 =  TrigTimeL[no]
				endif
				lastC1 = CFDtime[no]
			endif
			
			if(mod(chnum[no],4)==2)
				lastE2 = energy[no]
				if(UsePTPforLOC)
					lastT2 =  PTP_Time[no]
				else
					lastT2 =  TrigTimeL[no]
				endif
				lastC2 = CFDtime[no]
			endif
	
			if(mod(chnum[no],4)==3)
				lastE3 = energy[no]
				if(UsePTPforLOC)
					lastT3 =  PTP_Time[no]
				else
					lastT3 =  TrigTimeL[no]
				endif
				lastC3 = CFDtime[no]	
			endif
			
			Energy0[no]   	= lastE0			
			Energy1[no]   	= lastE1			
			Energy2[no]   	= lastE2		
			Energy3[no]   	= lastE3		
			
			LocTime0[no] 	= lastT0
			LocTime1[no] 	= lastT1	
			LocTime2[no] 	= lastT2	
			LocTime3[no] 	= lastT3	
			
			CFD0[no] 	= lastC0
			CFD1[no] 	= lastC1	
			CFD2[no] 	= lastC2	
			CFD3[no] 	= lastC3	
	
		else
			print "end of file reached, aborting"
			break
		endif	

	endfor
	
	oldNevents = no	
	Nevents = no	
	
	print Nevents, "total"
	
	
End



Function Time_process_event()
	
	// source globals
	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
	Wave ListModeChannelTrigger=root:pixie4:ListModeChannelTrigger
	Wave ListModeChannelXIA=root:pixie4:ListModeChannelXIA
	Nvar EventTimeHI = root:Pixie4:EventTimeHI
	Nvar EventTimeLO = root:Pixie4:EventTimeLO
	Nvar ChosenEvent = root:pixie4:ChosenEvent	// number of event to read
	Nvar runtype = root:pixie4:runtype
	Svar suffix = root:Tdiff:suffix
	
	// result globals
	Wave eventvalues = root:Tdiff:Eventvalues
	
	// options
	Nvar wftimescale =  root:Pixie4:wftimescale
	Nvar WFscale =  root:pixie4:WFscale
	Nvar TSscale =  root:Tdiff:TSscale
	
	Variable ret, offidx, cfdticksF, cfdfracF, CFD16, cfdsrc
	String wav, wv2
	Nvar ch = $("root:Tdiff:chan"+suffix)
	
	ret = Pixie_File_ReadEvent()
	

	
	if(ret>=0)
		wav="root:pixie4:trace"+num2str(ch)
		wave trace = $wav
		wv2 = "root:Tdiff:trace"+suffix
		duplicate/o trace,$(wv2)
		
		if(cmpstr(suffix,"A")==0)
			offidx = 0
		else
			offidx = 1
		endif
			
	
		eventvalues[4+offidx] = ListModeChannelEnergy[ch]
		eventvalues[8+offidx] = ListModeChannelTrigger[ch]	
		eventvalues[13+offidx] = ChosenEvent
		eventvalues[15+offidx] = EventTimeHI
		eventvalues[17+offidx] = EventTimeLO
			
		LM_event_CFDfromtrace(ch)
		
		// get FPGA values	
		if(runtype==0x116)	
			if(WFscale==4)	// P16 style CFD result for 250 MHz ADCs	
				cfdsrc =0
				CFD16 = ListModeChannelXIA[ch]
				if( (CFD16 & 0x8000)>0)		// CFD error flag
					cfdfracF=nan	
				endif
				if( (CFD16 & 0x4000)>0)		// CFD src flag for 250 MHz data
					cfdsrc = 1		
				endif
				cfdfracF = ((CFD16 & 0x3FFF)/16384 - cfdsrc)		// in sample units  x 10k (unit display)
				cfdticksF = 0
			endif
			if(WFscale==8)	// P16 style CFD result for 125 MHz ADCs	
			//  TODO: extract ticks and frac
			
			endif
		else		// PN/ P4e style CFD result 
			cfdticksF = floor((ListModeChannelXIA[ch] & 0xFC00) /256/4)		// timestamp of max in units of 4ns
			cfdfracF =  (ListModeChannelXIA[ch] & 0x3FF)/256/4
		endif
		Eventvalues[20+offidx] = cfdticksF
		Eventvalues[22+offidx] = cfdfracF
	else
	
		eventvalues[4+offidx] = nan
		eventvalues[8+offidx] = nan
		eventvalues[13+offidx] = nan
		eventvalues[15+offidx] = nan
		eventvalues[17+offidx] = nan
		
	endif
	
	return(ret)
End




Function LM_event_CFDfromtrace(ch)
Variable ch

	Wave eventvalues = root:Tdiff:Eventvalues
	Nvar defaultTriggerPos = root:Tdiff:defaultTriggerPos	//Nvar defaultTriggerPos = root:Tdiff:defaultTriggerPos
	Nvar LB = root:Tdiff:LB					//Nvar LB =  root:Tdiff:LB //= 12 // length of baseline sum
	Nvar RTlow =  root:Tdiff:RTlow				//Nvar RTlow = root:Tdiff:RTlow //= 0.1
	
	Svar suffix = root:Tdiff:suffix
	Variable offidx
		if(cmpstr(suffix,"A")==0)
			offidx = 0
		else
			offidx = 1
		endif
	
	String wav, wv2
	
	Variable maxlocA,  npntsA, rms, goodevent, cfdt
	Variable k,j, baseA, amplA, lev10,  lev1p, lev1x, lev2p, lev2x
	Variable max1p, max2p, cfdlevel, sep
	
	
	wav="root:pixie4:trace"+num2str(ch)
	wave traceA = $wav
//	duplicate/o traceA, root:Tdiff:traceA
	
	goodevent = WaveExists(traceA)==1 	// only analyze traces that are present
	wavestats/q/z	traceA
	npntsA = V_npnts
	goodevent = goodevent && (npntsA>1) 	// only analyze traces that have points
	
	if(goodevent)	
		wv2 = "root:Tdiff:triglocs"+suffix
		duplicate/o traceA,  $(wv2)
		Wave triglocsA = $(wv2)
		triglocsA = nan
	
		
		// ***************  calculate base and amplitude  ***************
		baseA = 0
		for(j=defaultTriggerPos-LB;j<defaultTriggerPos;j+=1)
			baseA+=traceA[j]
		endfor
		baseA/=LB
		Eventvalues[0+offidx] =baseA
		
		//find max
		wavestats/q/z	traceA
		amplA = V_max-baseA
		Eventvalues[2+offidx] =amplA
		maxlocA = x2pnt (traceA, V_maxloc)
		
		
		// ***************  find CFD crossing  ***************
				
		// find first 10% level before max
		cfdlevel = baseA+amplA*RTlow
		findlevel/q/R=[defaultTriggerPos,maxlocA] traceA, cfdlevel // coarse first
		lev1p = x2pnt (traceA, V_levelX)
				
		// refine maxima
		wavestats/q/z/R=[lev1p,lev1p+50] traceA			// find maximum within 50 cycles after rising edge 
		max1p = x2pnt (traceA, V_maxloc)				// assumes pulse rise time is less than 50 cycles	
		
		// find first crossing with refined maximum
		amplA = traceA[max1p] - baseA
		//amplA = (traceA[max1p]+traceA[max1p-1])/2 - baseA
		cfdlevel = baseA+amplA*RTlow
		findlevel/B=1/q/R=[defaultTriggerPos,max1p] traceA, cfdlevel // fine first
		lev1p = x2pnt (traceA, V_levelX)
		lev1x = V_levelX	//in x units
		Eventvalues[6+offidx] = lev1x  *1e9	//in ns
		triglocsA[lev1p] = traceA[lev1p]		// mark waveform
		//TriggerPos = lev1p
		cfdt = Eventvalues[6+offidx] 
		
	else
	
		eventvalues[0+offidx] = nan
		eventvalues[2+offidx] = nan
		eventvalues[6+offidx] = nan
		cfdt = -1
		
	endif
	
	return(cfdt)

			
			
End







Function Time_buttons(Ctrlname)
String Ctrlname
	
	if(cmpstr(ctrlName, "plot") == 0)
		Execute "Time_plot_traces()"
		return(0)
	endif
	
	if(cmpstr(ctrlName, "process") == 0)
		Time_process_file()
		return(0)
	endif
	
	if(cmpstr(ctrlName, "cuthisto") == 0)
		Time_process_cut()
		Time_process_histo()	
		return(0)
	endif
	
	if(cmpstr(ctrlName, "ShowHisto") == 0)
		Execute "Time_plot_dThisto()"
		return(0)
	endif
	
	if(cmpstr(ctrlName, "ShowTdiff") == 0)
		Execute "Time_plot_Tdiff()"
		return(0)
	endif
	
	if(cmpstr(ctrlName, "ShowTtable") == 0)
		Execute "Time_table()"
		return(0)
	endif
	
	if(cmpstr(ctrlName, "ShowTdiffvsE") == 0)
		Execute "Time_plot_TdiffVsEA()"
		Execute "Time_plot_TdiffVsEB()"
		return(0)
	endif
	
	if(cmpstr(ctrlName, "ShowTdiffvsRT") == 0)
		Execute "Time_plot_TdiffVsRTA()"
		Execute "Time_plot_TdiffVsRTB()"
		return(0)
	endif
	
	if(cmpstr(ctrlName, "fit") == 0)
		wave W_Coef
		Nvar defaultTriggerPos = root:Tdiff:defaultTriggerPos
		Nvar LB =  root:Tdiff:LB //= 12 // length of baseline sum
		Nvar RTlow = root:Tdiff:RTlow //= 0.1
		
		wave dthisto_cut= dthisto_cut
		wave dthisto = dthisto
		wave dtdsphisto = dtdsphisto
		wave dtdsphisto_cut = dtdsphisto_cut
		
		
		Execute "Time_plot_dThisto()"
		print "BL, CFD, pos:", LB, RTlow, defaultTriggerPos
		
		// only fit those that are present
		String wavesinplot, wfname
		Variable Nwaves, m
		//Execute "Tdiff_plot_histos()"
		wavesinplot = TraceNameList("Timinghisto",",",1)
		Nwaves = ItemsInList(wavesinplot,",")
		for(m=0;m<Nwaves;m+=1)
			wfname = StringFromList(m,wavesinplot,",")
			if(stringmatch(wfname,"fit_*")==0)			// only fit waves that are not fit_xxxx
				Wave histo = $(wfname)			// default: wave in root  folder
				if(WaveExists(histo)==0)
					Wave histo = $(wfname)		// but top level saved copies may exist also
				endif
				if(WaveExists(histo)==1)
					CurveFit/q/NTHR=0/TBOX=0 gauss histo [pcsr(A),pcsr(B)] /D 
					print wfname,": peak position (ns):",W_Coef[2], "FWHM (ps):",W_coef[3]*2*sqrt(ln(2))*1000
				endif
			endif
		endfor

//		
//		CurveFit/q/NTHR=0/TBOX=0 gauss  dthisto_cut[pcsr(A),pcsr(B)] /D 
//		print "BL, CFD, pos:", LB, RTlow, defaultTriggerPos
//		print "[Igor] peak position, with cut (ns):",W_Coef[2], "FWHM (ns):",W_coef[3]*2*sqrt(ln(2))
//		CurveFit/q/NTHR=0/TBOX=0 gauss  dthisto[pcsr(A),pcsr(B)] /D 
//		print "[Igor] peak position, without cut (ns):",W_Coef[2], "FWHM, (ns):",W_coef[3]*2*sqrt(ln(2))
//		CurveFit/q/NTHR=0/TBOX=0 gauss  dtdsphisto_cut[pcsr(A),pcsr(B)] /D 
//		print "[DSP] peak position, with cut (ns):",W_Coef[2], "FWHM (ns):",W_coef[3]*2*sqrt(ln(2))
//		CurveFit/q/NTHR=0/TBOX=0 gauss  dtdsphisto[pcsr(A),pcsr(B)] /D 
//		print "[DSP] peak position, without cut (ns):",W_Coef[2], "FWHM (ns):",W_coef[3]*2*sqrt(ln(2))
	endif
	
	


End


Window Time_plot_TdiffvsEA() : Graph
	DoWindow/F TdiffvsEA
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	Display/K=1 /W=(50,200,400,400) timediff vs energiesA
	DoWindow/C TdiffvsEA
	AppendToGraph timediff_cut vs energiesA
	ModifyGraph mode=2
	ModifyGraph lSize=1.5
	ModifyGraph rgb(timediff)=(0,52224,0)
	ModifyGraph rgb(timediff_cut)=(0,0,0)
	ModifyGraph mirror=2
	Label left "Time difference (ns)"
	Label bottom "Energy A (DSP units)"
	Legend/C/N=text0/A=MC
EndMacro

Window Time_plot_TdiffvsRTA() : Graph
	DoWindow/F TdiffvsRTA
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	Display/K=1 /W=(50,200,400,400) timediff vs rtA
	DoWindow/C TdiffvsRTA
	AppendToGraph timediff_cut vs rtA
	ModifyGraph mode=2
	ModifyGraph lSize=1.5
	ModifyGraph rgb(timediff)=(0,52224,0)
	ModifyGraph rgb(timediff_cut)=(0,0,0)
	ModifyGraph mirror=2
	Label left "Time difference (ns)"
	Label bottom "Rise time A (DSP units)"
	Legend/C/N=text0/A=MC
EndMacro

Window Time_plot_TdiffvsRTB() : Graph
	DoWindow/F TdiffvsRTB
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	Display/K=1 /W=(50,200,400,400) timediff vs rtB
	DoWindow/C TdiffvsRTB
	AppendToGraph timediff_cut vs rtB
	ModifyGraph mode=2
	ModifyGraph lSize=1.5
	ModifyGraph rgb(timediff)=(16384,28160,65280)
	ModifyGraph rgb(timediff_cut)=(0,0,0)
	ModifyGraph mirror=2
	Label left "Time difference (ns)"
	Label bottom "Rise time B (DSP units)"
	Legend/C/N=text0/A=MC
EndMacro

Window Time_plot_TdiffvsEB() : Graph
	DoWindow/F TdiffvsEB
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	Display/K=1 /W=(450,200,800,400) timediff vs energiesB
	DoWindow/C TdiffvsEB
	AppendToGraph timediff_cut vs energiesB
	ModifyGraph mode=2
	ModifyGraph lSize=1.5
	ModifyGraph rgb(timediff)=(16384,28160,65280)
	ModifyGraph rgb(timediff_cut)=(0,0,0)
	ModifyGraph mirror=2
	Label left "Time difference (ns)"
	Label bottom "Energy B (DSP units)"
	Legend/C/N=text0/A=MC
EndMacro



Window Time_plot_traces() : Graph
	DoWindow/F Timingtraces
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:Tdiff:
	Display/K=1/W=(400,20,700,220) traceA,triglocsA
	DoWindow/C Timingtraces
	AppendToGraph/L=L1 traceB,triglocsB
	SetDataFolder fldrSav0
	ModifyGraph mirror=2
	ModifyGraph lblPos(left)=52
	ModifyGraph freePos(L1)=0
	ModifyGraph axisEnab(left)={0,0.48}
	ModifyGraph axisEnab(L1)={0.52,1}
	ModifyGraph mode(traceA)=6,rgb(traceA)=(0,52224,0)
	ModifyGraph mode(triglocsA)=3,marker(triglocsA)=26, rgb(triglocsA)=(0,26112,0)
	ModifyGraph mode(traceB)=6,rgb(traceB)=(16384,28160,65280)
	ModifyGraph mode(triglocsB)=3, marker(triglocsB)=26,rgb(triglocsB)=(0,9472,39168)
	SetAxis left 0,16000
	SetAxis L1 0,16000
	ShowInfo
	Legend/C/N=text0/J/A=MC "\\s(traceB) traceB\r\\s(traceA) traceA"
	Label left "ADC steps"
	Label bottom "Time"
EndMacro

Window Time_plot_dThisto() : Graph
	DoWindow/F Timinghisto
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	Display/K=1/W=(400,20,700,220) dthisto, dthisto_cut
	AppendToGraph dtdsphisto, dtdsphisto_cut
	DoWindow/C Timinghisto
	ModifyGraph mirror=2
	ModifyGraph mode=6
	ModifyGraph rgb(dtdsphisto)=(0,0,0)
	ModifyGraph rgb(dtdsphisto_cut)=(0,0,0)
	ModifyGraph lstyle(dthisto_cut)=11,lsize(dthisto_cut)=2,lstyle(dtdsphisto_cut)=11, lsize(dtdsphisto_cut)=2
	ShowInfo
	Legend/C/N=text0/A=MC
	Label left "N events"
	Label bottom "Time difference (ns)"
EndMacro

Window Time_plot_Tdiff() : Graph
	DoWindow/F Tdiff_Event
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	Display/K=1/W=(630,482.75,917.25,650) timediff, timediff_cut
	DoWindow/C Tdiff_Event
	ModifyGraph mode=2
	ModifyGraph mirror=2
	ModifyGraph rgb(timediff_cut)=(0,0,0)
	Label left "Time diff (ns)"
	Label bottom "event number"
	ShowInfo
	Legend/C/N=text0/A=MC
EndMacro

Macro Time_table()
	DoWindow/F CFDtable
	if(V_flag!=1)
		edit/K=1	amplitudesA, amplitudesB, energiesA, energiesB, tsA, tsB, rtA, rtB, cfdA, cfdB, timediff, timediff_cut, dspdtA, dspdtB, tdiffdsp, tdiffdsp_cut
		ModifyTable width=60
	endif

EndMacro


Function Time_process_file()
	
	Nvar  Nevents = root:Tdiff:Nevents 				// number of events
	Nvar  MaxEvents = root:Tdiff:MaxEvents
	Wave eventvalues = root:Tdiff:Eventvalues
	Variable ch
	Variable k,m, len,n, index, E, ret, Nbadevents
	String text

	Nvar ChosenModule = root:pixie4:ChosenModule
	Nvar ChosenEvent = root:pixie4:ChosenEvent
	wave listmodewave = root:pixie4:listmodewave
	Nvar chanA = root:Tdiff:chanA
	Nvar chanB = root:Tdiff:chanB
	Nvar modA = root:Tdiff:modA
	Nvar modB = root:Tdiff:modB
	Svar suffix = root:Tdiff:suffix
	
	Nevents=MaxEvents

	make/o/n=(nevents) amplitudesA, amplitudesB, cfdA, cfdB, timediff, timediff_cut,energiesA, energiesB, tsA, tsB, rtA, rtB
	make/o/n=(nevents) tdiffdsp, tdiffdsp_cut, dspdtA, dspdtB
	wave amplitudesA
	wave amplitudesB
	wave energiesA
	wave energiesB
	wave cfdA
	wave cfdB
	wave tsA
	wave tsB
	wave timediff
	wave timediff_cut
	wave rtA
	wave rtB
	wave tdiffdsp
	wave tdiffdsp_cut
	wave dspdtA 
	wave dspdtB
	
	amplitudesA = nan
	amplitudesB = nan
	energiesA=nan
	energiesB=nan
	cfdA = nan	
	cfdB = nan	
	tsA=nan
	tsB=nan
	timediff=nan
	timediff_cut=nan	
	rtA=nan
	rtB=nan
	tdiffdsp=nan
	tdiffdsp_cut=nan
	dspdtA =nan
	dspdtB = nan
	
	Svar lmfilename = root:pixie4:lmfilename
	print "Processing file", lmfilename

	Nvar EvIncr= root:Tdiff:EvIncr
	
	Nbadevents =0
	for(m=0;m<nevents;m+=EvIncr)
//	for(m=0;m<1000;m+=EvIncr)
		if (mod(m,500)==0)
			DoUpdate
		endif
		ChosenEvent = m
		if(EvIncr==2)
			ret = Time_process_2events("",0,"","") 
		else
			ret = Time_process_event()
		endif
		if(ret < 0)
			print "Error processing new event"
			Time_process_cut()
			Time_process_histo()
			return(ret)
		endif
		amplitudesA[m] = Eventvalues[2]
		amplitudesB[m] = Eventvalues[3]
		energiesA[m] = Eventvalues[4]
		energiesB[m] = Eventvalues[5]
		cfdA[m] = Eventvalues[6]
		cfdB[m] = Eventvalues[7]	
		tsA[m]= Eventvalues[8]
		tsB[m]= Eventvalues[9]
		timediff[m]=Eventvalues[10]
		rtA[m] = Eventvalues[11]
		rtB[m] = Eventvalues[12]
		tdiffdsp[m] = Eventvalues[24]
		dspdtA[m] = Eventvalues[22]
		dspdtB[m] =  Eventvalues[23]

	endfor	
	Time_process_cut()
	Time_process_histo()
	
	print "N events without 2 traces", Nbadevents,"out of",nevents
End



Function Time_process_cut()
	
	wave energiesA
	wave energiesB
	wave rtA
	wave rtB
	wave timediff
	wave timediff_cut
	wave tdiffdsp
	wave tdiffdsp_cut
	
	Nvar  Nevents = root:Tdiff:Nevents 
	Nvar ElowA =  root:Tdiff:ElowA
	Nvar EhighA = root:Tdiff:EhighA
	Nvar ElowB = root:Tdiff:ElowB
	Nvar EhighB = root:Tdiff:EhighB
	Nvar RTlowA =  root:Tdiff:RTlowA
	Nvar RThighA = root:Tdiff:RThighA
	Nvar RTlowB = root:Tdiff:RTlowB
	Nvar RThighB = root:Tdiff:RThighB
	Nvar cutRT = root:Tdiff:cutRT
	Nvar cutE = root:Tdiff:cutE
	Nvar EvIncr= root:Tdiff:EvIncr
	
	Variable m, Eok, RTok, cutcount
	timediff_cut = nan
	cutcount=0
	for(m=0;m<nevents;m+=EvIncr)
		Eok=1-cutE	//if cut enabled, default not ok but modified below; in not enabled, default ok
		RTok=1-cutRT
		if ( (energiesA[m]>ElowA) && (energiesA[m]<EhighA) && (energiesB[m]>ElowB) && (energiesB[m]<EhighB) )
			Eok=1
		endif
		
		if ( (rtA[m]>RTlowA) && (rtA[m]<RThighA) && (rtB[m]>RTlowB) && (rtB[m]<RThighB) )
			RTok=1
		endif
		
		if ( (Eok==1) && (RTok==1) )
			timediff_cut[m] =timediff[m]
			tdiffdsp_cut[m] =tdiffdsp[m]
			cutcount+=1
		endif
	endfor

	print "total:",nevents/EvIncr,"  after cut:",cutcount,"fraction:",cutcount/(nevents/EvIncr)

End



Function Time_process_histo()
	
	Nvar  Nevents = root:Tdiff:Nevents 	
	Nvar NbinsTA = root:Tdiff:NbinsTA
	Nvar BinsizeTA = root:Tdiff:BinsizeTA
	Nvar NbinsTB = root:Tdiff:NbinsTB
	Nvar  BinsizeTB = root:Tdiff:BinsizeTB
	Nvar NbinsTC = root:Tdiff:NbinsTC
	Nvar BinsizeTC =  root:Tdiff:BinsizeTC
	
	wave timediff
	wave timediff_cut
	wave tdiffdsp
	wave tdiffdsp_cut
	
	
	make/o/n=1 dthisto, dthisto_cut
	wave dthisto
	wave dthisto_cut
	dthisto=0
	dthisto_cut=0
	make/o/n=1 dtdsphisto, dtdsphisto_cut
	wave dtdsphisto
	wave dtdsphisto_cut
	dtdsphisto=0
	dtdsphisto_cut=0

		histogram/A/B={-BinsizeTA*NbinsTA/2,BinsizeTA,NbinsTA}  timediff, dthisto
		histogram/A/B={-BinsizeTA*NbinsTA/2,BinsizeTA,NbinsTA} timediff_cut, dthisto_cut
		histogram/A/B={-BinsizeTA*NbinsTA/2,BinsizeTA,NbinsTA} tdiffdsp, dtdsphisto
		histogram/A/B={-BinsizeTA*NbinsTA/2,BinsizeTA,NbinsTA} tdiffdsp_cut, dtdsphisto_cut
	
//histogram/A/B=3 timediff, dthisto

End

Window Time_Panel() : Panel
	// Check if this panel has already been opened
	DoWindow/F TimingPanel
	if(V_Flag == 1)
		return 0
	endif	
	PauseUpdate; Silent 1		// building window...
	NewPanel/K=1 /W=(150,50,590,550)
	DoWindow/C TimingPanel
	ModifyPanel cbRGB=(51200,57088,45056)
	variable xinp = 10
	variable buttony = 415
	variable controly = 45
	variable boxheight = 380		
	variable xres = 185
	variable yres = 60
	
	SetVariable TraceDataFile, value=root:pixie4:lmfilename, pos={10,10},size={350,18},title="Data File"
	SetVariable TraceDataFile, fsize=10//,bodywidth=100	
	Button FindTraceDataFile, pos={xres+185,8},size={50,18},proc=Pixie_Ctrl_CommonButton,title="Find",fsize=11
	
		
	Groupbox inp, pos={xinp-7,30}, size={155,boxheight}, title="Controls", frame=0

	SetVariable inp22,pos={xinp,controly},size={140,16},title="Event increment",value= root:Tdiff:EvIncr,limits={1,4,1}
	SetVariable inp22, help={"P500e: same data in multiple events. E.g. set to 2 for 2-channel data. For processing of file only"}
	SetVariable inp23,pos={xinp,controly+20},size={140,16},title="Max. events      ",value= root:Tdiff:MaxEvents,limits={1,1e9,1}
	SetVariable inp23, help={"Limit the number of events to process (for larger files)"}
	
	SetVariable inp24,pos={xinp,controly+40},size={140,16},title="Time stamp unit (ns) ",value= root:Tdiff:TSscale
	SetVariable inp24, help={"Time stamp units are 2ns for Pixie-4e (any), 13.333ns for Pixie-4, 1ns for Pixie-Net"}
	SetVariable inp25,pos={xinp,controly+60},size={140,16},title="Sample interval (ns) ",value= root:pixie4:WFscale
	SetVariable inp25, help={"Waveform sampling intervals are 2ns for Pixie-4e (14/500), 8ns for Pixie-4e (16/125), 4ns for Pixie-Net, 13.333ns for Pixie-4"}



	controly = 130
	SetVariable inp3,pos={xinp,controly},size={80,16},title="Mod.  A",value= root:Tdiff:modA,limits={0,3,1}
	SetVariable inp4,pos={xinp+90,controly},size={50,16},title="B",value= root:Tdiff:modB,limits={0,3,1}
	SetVariable inp1,pos={xinp,controly+20},size={80,16},title="Chan. A",value= root:Tdiff:chanA,limits={0,3,1}, help={"Ch no in LM trace display, i.e. mod 4 for Pixie-Net XL"}
	SetVariable inp2,pos={xinp+90,controly+20},size={50,16},title="B",value= root:Tdiff:chanB,limits={0,3,1}
	
	SetVariable inp5,pos={xinp,controly+50},size={140,16},title="Baseline length     ",value= root:Tdiff:LB,limits={1,8000,1}, help={"in cycles"}
	SetVariable inp6,pos={xinp,controly+70},size={140,16},title="CFD threshold      ",value= root:Tdiff:RTlow, help={"e.g. 10 percent = 0.1"}
	SetVariable inp7,pos={xinp,controly+90},size={140,16},title="Default trigger pos",value= root:Tdiff:defaultTriggerPos,limits={1,8000,1}, help={"in cycles"}

	controly = 240
	Checkbox inp17,pos={xinp+110,controly+0},size={90,16},title="cut", variable= root:Tdiff:cutE, fsize = 9
	SetVariable inp8,pos={xinp,controly+0},size={100,16},title="Elow   A",value= root:Tdiff:ElowA,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}
	SetVariable inp9,pos={xinp,controly+20},size={100,16},title="           B",value= root:Tdiff:ElowB,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}
	SetVariable inp10,pos={xinp,controly+40},size={100,16},title="Ehigh  A",value= root:Tdiff:EhighA,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}
	SetVariable inp11,pos={xinp,controly+60},size={100,16},title="           B",value= root:Tdiff:EhighB,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}

	controly = 325
	Checkbox inp18,pos={xinp+110,controly+0},size={90,16},title="cut", variable= root:Tdiff:cutRT, fsize = 9
	SetVariable inp13,pos={xinp,controly+0},size={100,16},title="RTlow   A",value= root:Tdiff:RTlowA,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}
	SetVariable inp14,pos={xinp,controly+20},size={100,16},title="             B",value= root:Tdiff:RTlowB,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}
	SetVariable inp15,pos={xinp,controly+40},size={100,16},title="RThigh  A",value= root:Tdiff:RThighA,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}
	SetVariable inp16,pos={xinp,controly+60},size={100,16},title="             B",value= root:Tdiff:RThighB,limits={0,65535,1}, help={"energy limit for binning dt, in DSP units"}


	Button process, pos = {xinp,buttony}, size = {80,20}, title ="Process", proc = Time_buttons
	Button cuthisto, pos = {xinp,buttony+30}, size = {80,20}, title ="Cut E, histo", proc = Time_buttons
	Button fit, pos = {xinp,buttony+60}, size = {80,20}, title ="Fit histo", proc = Time_buttons
	
	SetVariable inp31,pos={xinp+90,buttony},size={135,16},title="Histo bin size (ns)",value= root:Tdiff:BinsizeTA,help={"bin size (ns) for Tdiff histogram"}
	SetVariable inp32,pos={xinp+90,buttony+20},size={135,16},title="No. of bins           ",value= root:Tdiff:NbinsTA,help={"Number of bins for Tdiff histogram"}
	Valdisplay inp30,pos={xinp+90,buttony+40},size={135,16},title="Start histo at (ns) ",value= (root:Tdiff:NbinsTA* root:Tdiff:BinsizeTA/-2)

	Groupbox res, pos={xres-7,30}, size={250,boxheight}, title="Pulse details", frame=0
	
	SetVariable CallReadEvents,pos={xres,55},size={130,18},proc=Time_process_2events,title="Event No. "
	SetVariable CallReadEvents,format="%d",fsize=10, fstyle=1//,bodywidth=70
	SetVariable CallReadEvents,limits={0,Inf,1},value= root:pixie4:ChosenEvent

	Button plot, pos = {xres+185,53}, size = {50,18}, title ="Traces", proc = Time_buttons
	


	SetVariable setvar0,pos={xres,30+yres},size={146,16},title="base               A"
	SetVariable setvar0,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[0],noedit= 1, format="%.4g"
	SetVariable setvar0a,pos={xres+150,30+yres},size={80,16},title="B"
	SetVariable setvar0a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[1],noedit= 1, format="%.4g"
	
	SetVariable setvar1,pos={xres,50+yres},size={146,16},title="amplitude      A"
	SetVariable setvar1,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[2],noedit= 1, format="%.4g"
	SetVariable setvar1a,pos={xres+150,50+yres},size={80,16},title="B"
	SetVariable setvar1a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[3],noedit= 1, format="%.4g"
	
	SetVariable setvar3,pos={xres,70+yres},size={146,16},title="energy            A"
	SetVariable setvar3,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[4],noedit= 1, format="%.5g"
	SetVariable setvar3a,pos={xres+150,70+yres},size={80,16},title="B"
	SetVariable setvar3a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[5],noedit= 1, format="%.5g"
	
	SetVariable setvar6,pos={xres,90+yres},size={146,16},title="rise time         A"
	SetVariable setvar6,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[11],noedit= 1, format="%.4g"
	SetVariable setvar6a,pos={xres+150,90+yres},size={80,16},title="B"
	SetVariable setvar6a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[12],noedit= 1, format="%.4g"
	
	SetVariable setvar2,pos={xres,110+yres},size={146,16},title="CFD pos (ns)  A"
	SetVariable setvar2,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[6],noedit= 1, format="%.4f"
	SetVariable setvar2a,pos={xres+150,110+yres},size={80,16},title="B"
	SetVariable setvar2a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[7],noedit= 1, format="%.4f"
	
	SetVariable setvar8,pos={xres,130+yres},size={146,16},title="ev time high  A"
	SetVariable setvar8,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[15],noedit= 1, format="%d"
	SetVariable setvar8a,pos={xres+150,130+yres},size={80,16},title="B"
	SetVariable setvar8a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[16],noedit= 1, format="%d"
	
	SetVariable setvar9,pos={xres,150+yres},size={146,16},title="ev time low   A"
	SetVariable setvar9,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[17],noedit= 1, format="%d"
	SetVariable setvar9a,pos={xres+150,150+yres},size={80,16},title="B"
	SetVariable setvar9a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[18],noedit= 1, format="%d"
	
	SetVariable setvar5,pos={xres,170+yres},size={146,16},title="ch T stamp   A"
	SetVariable setvar5,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[8],noedit= 1, format="%u"
	SetVariable setvar5a,pos={xres+150,170+yres},size={80,16},title="B"
	SetVariable setvar5a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[9],noedit= 1, format="%u"
	
	SetVariable setvar7,pos={xres,190+yres},size={146,16},title="event #          A"
	SetVariable setvar7,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[13],noedit= 1, format="%d"
	SetVariable setvar7a,pos={xres+150,190+yres},size={80,16},title="B"
	SetVariable setvar7a,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[14],noedit= 1, format="%d"


	SetVariable setvar4,pos={xres,220+yres},size={180,16},title="T difference (ns) "
	SetVariable setvar4,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[10],noedit= 1, format="%.5g"
	
	SetVariable setvar20,pos={xres,250+yres},size={146,16},title="FPGA ticks (4ns)  A"
	SetVariable setvar20,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[20],noedit= 1, format="%.4f"
	SetVariable setvar21,pos={xres+150,250+yres},size={80,16},title="B"
	SetVariable setvar21,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[21],noedit= 1, format="%.4f"
	
	SetVariable setvar22,pos={xres,270+yres},size={146,16},title="FPGA frac            A"
	SetVariable setvar22,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[22],noedit= 1, format="%.4f"
	SetVariable setvar23,pos={xres+150,270+yres},size={80,16},title="B"
	SetVariable setvar23,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[23],noedit= 1, format="%.4f"
	
	SetVariable setvar24,pos={xres,290+yres},size={180,16},title="FPGA T difference (ns) "
	SetVariable setvar24,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[24],noedit= 1, format="%.5g"
	
	SetVariable setvar30,pos={xres,310+yres},size={146,16},title="Igor frac  A"
	SetVariable setvar30,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[30],noedit= 1, format="%.4f"
	SetVariable setvar31,pos={xres+150,310+yres},size={80,16},title="B"
	SetVariable setvar31,limits={-inf,inf,0},value= root:Tdiff:Eventvalues[31],noedit= 1, format="%.4f"


	Button ShowHisto, pos = {xres+80,buttony}, size = {70,20}, title ="Show Histo", proc = Time_buttons
	Button ShowTdiff,  pos = {xres+80,buttony+30}, size = {70,20}, title ="Show T diff", proc = Time_buttons
	Button ShowTtable  pos = {xres+80,buttony+60}, size = {70,20}, title ="Show T table", proc = Time_buttons
	Button ShowTdiffvsE,  pos = {xres+160,buttony}, size = {70,20}, title ="T diff vs E", proc = Time_buttons
	Button ShowTdiffvsRT,  pos = {xres+160,buttony+30}, size = {70,20}, title ="T diff vs RT", proc = Time_buttons
	
	
EndMacro



Function Time_process_2events(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	Nvar ChosenEvent = root:pixie4:ChosenEvent	// number of event to read
	Nvar runtype = root:pixie4:runtype
	Nvar EvIncr= root:Tdiff:EvIncr
	Nvar chanA = root:Tdiff:chanA
	Nvar chanB = root:Tdiff:chanB
	Svar suffix = root:Tdiff:suffix
	Wave eventvalues = root:Tdiff:Eventvalues
	Wave ListModeChannelXIA=root:pixie4:ListModeChannelXIA
	Variable  cfdticksFA, cfdfracFA
	Variable  cfdticksFB, cfdfracFB
	
	// options
	Nvar TSscale =  root:Tdiff:TSscale
	
	ChosenEvent = floor(ChosenEvent/2)*2
	
	variable ret =0
	suffix="A"
	ret = Time_process_event()	
	// get FPGA values		
	//cfdticksFA = floor((ListModeChannelXIA[chanA] & 0xFC00) /256/4)		// timestamp of max in units of 4ns
	//cfdfracFA =  (ListModeChannelXIA[chanA] & 0x3FF)/256/4
	//Eventvalues[20] = cfdticksFA
	//Eventvalues[22] = cfdfracFA
	
	if(EvIncr==2)
		suffix="B"
		ChosenEvent = ChosenEvent+1
		ret = Time_process_event()
		// get FPGA values		
		//cfdticksFB = floor((ListModeChannelXIA[chanB] & 0xFC00) /256/4)		// timestamp of max in units of 4ns
		//cfdfracFB =  (ListModeChannelXIA[chanB] & 0x3FF)/256/4
		//Eventvalues[21] = cfdticksFB
		//Eventvalues[23] = cfdfracFB
	endif
	
	// build diff
	Eventvalues[10] = Eventvalues[7] - Eventvalues[6]		// dt in traces (Igor units = ns)
	Eventvalues[10]  +=  TSscale*Eventvalues[9] - TSscale*Eventvalues[8]	// add T stamp difference (TS units = 1ns)
	
	Eventvalues[24] = TSscale*Eventvalues[9] - TSscale*Eventvalues[8]		// T stamp difference	 (TS units = 1ns)
	Eventvalues[24] += 4*Eventvalues[22] - 4*Eventvalues[23]	//subtract fractions (sample units = 4ns)
	Eventvalues[24] += 4*Eventvalues[20] - 4*Eventvalues[21]	//subtract ticks from max to TS (sample units = 4ns)
	
	// debug
	Eventvalues[30] = 1- ((Eventvalues[6]/4) -  floor(Eventvalues[6]/4))
	Eventvalues[31] = 1- ((Eventvalues[7]/4) -  floor(Eventvalues[7]/4))
	
	return (ret)
End




Function SplitWF(ch)
Variable ch

	Variable npts, k
	Wave trace = $("root:pixie4:trace"+num2str(ch))
	
	// make destination waves
	wavestats/q trace
	npts = V_npnts
	make/o/n=(npts/2) traceodd, traceeven
	
	// split even/odd
	for(k=0;k<npts/2;k+=1)
		traceeven[k] = trace[2*k+0]
		traceodd[k] = trace[2*k+1]
	endfor
	
	// correct offset 
	Variable offe, offo
	wavestats/q/R=[0,40] traceeven 
	offe = V_avg
	wavestats/q/R=[0,40] traceodd 
	offo = V_avg	
	
	for(k=0;k<npts/2;k+=1)
		trace[2*k] = trace[2*k]+offo-offe
	endfor
	
	
	
	
End


Function Tdiff_CFDtraces_scan()
	Nvar RTlow = root:Tdiff:RTlow		
	Variable cfd, m
	make/o/n=40 cfdlev, Tres
	wave W_coef
	
	m=0
	Tres = nan
	cfdlev = nan
	for(cfd=0.04;cfd<0.62;cfd+=0.04)	
	
		RTlow = cfd	
	
		LM_File_ExtractCFD_singles(0)
		
		Tdiff_Panel_Call_Buttons("Tdiff_compute_diff")
		
		Tdiff_Panel_Call_Buttons("Tdiff_fit")	
		
		cfdlev[m] = cfd
		Tres[m] = W_coef[3]*2*sqrt(ln(2))*1000
		m=m+1
		
	endfor


End


Function CutNonCoinc(Nevents, evtsize)
Variable Nevents		// must manually specify the number of events (= columns), wavestats only reports total points in wfarray
Variable evtsize

	Wave wfarray
	
	killwaves/Z wfarray_coinc
	make/o/n=(evtsize,2) wfarray_coinc
	wavestats/q wfarray
	
	
	
	Variable evt, trigtime0, trigtime1
	Variable coinccount
	coinccount=0
	
	for(evt=0; evt<Nevents; evt+=1)
//	for(evt=0; evt<100; evt+=1)
		trigtime0 = wfarray[2][evt+0] + 65536*wfarray[3][evt+0]+65536*65536*wfarray[3][evt+0]
		trigtime1 = wfarray[2][evt+1] + 65536*wfarray[3][evt+1]+65536*65536*wfarray[3][evt+1]
		
		if(   abs(trigtime0-trigtime1) < 1000) 		// if coincident
			//print "coinc at", evt
			
			// save to new array, sorting by channel
			if(wfarray[0][evt+0] < wfarray[0][evt+1])
				wfarray_coinc[][coinccount+0] = wfarray[p][evt+0]		// lower channel first
				wfarray_coinc[][coinccount+1] = wfarray[p][evt+1]
			else
				wfarray_coinc[][coinccount+1] = wfarray[p][evt+0]		// lower channel last, so swap
				wfarray_coinc[][coinccount+0] = wfarray[p][evt+1]			
			endif
			
			
			InsertPoints/M=1 (coinccount+2), 2, wfarray_coinc		// add 2 columns for next coinc
			coinccount+=2
		endif
	
		
	
	endfor
	
	DeletePoints/M=1 coinccount,2, wfarray_coinc		// remove last 2 empty columns
	print "Number of coincident events",coinccount,"(", coinccount/2,"pairs)"
	
	
end

// This function can be used to save the modified raw P16 0x100 data
Function SaveRaw100to100(wfarrayname):ButtonControl	
String wfarrayname

	//Wave LMheader				// no header for 0x100
	Wave wfarray = $(wfarrayname)
	
	Variable filelength, fnum
	wavestats/q wfarray
	filelength = V_npnts	// number of points in wfarray  
	make/o/n=(filelength) LMdata0
	LMdata0 = wfarray		// 2D into 1D wave
	//insertpoints 0,32, LMdata0
	//LMdata0[0,31] = LMheader
	
	open/M="Select new binary file name" fnum 
	fbinwrite/F=2/U fnum, LMdata0
	close fnum

End

// This function can be used to save the data form a raw P16 0x100 data file as 0x400
Function SaveRaw100to400(wfarrayname,Nevents, eventlength100):ButtonControl	
String wfarrayname
Variable Nevents, eventlength100

	DoAlert 0, "Please verify LM header constants are appropriate"

	Wave wfarray = $(wfarrayname)
	
	Variable filelength, fnum
	
	
	// Modify channel header
	Variable chnum, evt, blks
	blks = (eventlength100-20)/32 +1		// event size for 0x400 in blocks
	
	InsertPoints/M=0 0,12, wfarray		// add 12 more header words
	//wfarray[0][q] = wfarray 
	
	for(evt=0; evt<Nevents;evt+=1)
		chnum =  mod(  (wfarray[12][evt] & 0xF),4)		// chanel number modulo 4
		wfarray[00][evt] =  2^chnum + 2^(chnum+8) + 0x0020	// EvtPattern
		wfarray[01][evt] = 1				// EvtInfo -- coinc bit set?
		
		wfarray[02][evt] = blks-1			// NumTraceBlks
		wfarray[03][evt] = blks-1			// NumTraceBlksPrev
		wfarray[03][0] = 0					// NumTraceBlksPrev -- event 0
		wfarray[04][evt] = wfarray[14][evt]	// Trigtime
		wfarray[05][evt] = wfarray[15][evt]	// 
		wfarray[06][evt] = wfarray[16][evt]	// 
		wfarray[07][evt] = 0				// TrgTime X
		
		wfarray[08][evt] = wfarray[18][evt]	// Energy
		wfarray[09][evt] = chnum 			// Channel
	
		wfarray[28][evt] = 0				// checksum
		wfarray[29][evt] = 0				// checksum		
		wfarray[30][evt] = 0x5678			// watermark
		wfarray[31][evt] = 0x1234			// watermark X	
	endfor
	
	// convert to 1D wave for saving
	wavestats/q wfarray
	filelength = V_npnts	// number of points in wfarray  
	make/o/n=(filelength) LMdata0
	LMdata0 = wfarray		// 2D into 1D wave
	
	// add header
	insertpoints 0,32, LMdata0
	LMdata0[00] = 32			// block size
	LMdata0[01] = 0			// module number
	LMdata0[02] = 0x400		// run format
	LMdata0[03] = 32			// ChanHedLen
	LMdata0[04] = 65536		// Coinc Pattern	
	LMdata0[05] = 1000		// Coinc Window
	LMdata0[06] = blks*4			// max combined  event length
	LMdata0[07] = 0xA5A1	// Pixie-4e, 14/250 variant (never built, but known in C)
	LMdata0[08] = blks			// channel event length (4x)
	LMdata0[09] = blks
	LMdata0[10] = blks
	LMdata0[11] = blks
	
	open/T="????"/M="Select new binary file name" fnum 
	fbinwrite/F=2/U fnum, LMdata0
	close fnum

End