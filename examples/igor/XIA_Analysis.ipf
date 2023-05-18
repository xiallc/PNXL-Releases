#pragma rtGlobals=1		// Use modern global access method.
#include ":P4_TestIO"
#include ":XIA_ModuleTest"

Function SaveRunstats(num,ch)
Variable num
variable ch

Wave CT
Wave ICR 
Wave OCR 
Wave PPR
Wave FPeaks
Wave Noutch
Wave NPPI
Wave SFDT
Wave EvRate
Wave NumEvmod
Wave FTDT
Wave RT
Wave TT
Wave GDT
Wave Gcountch
Wave Grate
Wave DAQfraction
Wave Cocount_corr
Wave Cscount_corr
Wave NCTrig
Wave CSFDT
Wave CCT
Wave CICR
Wave Co11count
Wave Co11count_corrOI
Wave Co11count_corrSFDT
Wave Co13count
Wave Co13count_corrOI
Wave Co13count_corrSFDT
Wave Co24count
Wave Co24count_corrOI
Wave Co24count_corrSFDT

Svar dgfpath 
Nvar ncp = root:pixie4:NumChannelPar
Wave CDP = $(dgfpath+"Display_Channel_Parameters")
Wave MDP = $(dgfpath+"Display_Module_Parameters")

 //make/o/n=100  RT, TT,EvRate, NumEvmod,CT, ICR, OCR, PPR, FPeaks, Noutch, NPPI, SFDT
  //make/o/n=100 FTDT, GDT, Gcountch, Grate, Cscount, Cocount, DAQfraction, Cscount_corr
   //make/o/n=100 Cocount_corr, NCTrig, CSFDT, CCT, CICR
//	Variable ch =0
	// save runstats into array. named ch only
	CT[num] = cdp[26+ncp*ch]
	ICR[num] = cdp[27+ncp*ch]
	OCR[num] = cdp[29+ncp*ch]
	PPR[num] = cdp[48+ncp*ch]
	FPeaks[num] = cdp[28+ncp*ch]
	Noutch[num] = cdp[30+ncp*ch]
	NPPI[num] = cdp[47+ncp*ch]
	SFDT[num] = cdp[34+ncp*ch]
	EvRate[num] = mdp[22]
	NumEvmod[num] = mdp[20]
	FTDT[num]=cdp[33+ncp*ch]
	RT[num] = mdp[21]
	TT[num] = mdp[23]
	GDT[num] = cdp[35+ncp*ch]
	Gcountch[num] = cdp[32+ncp*ch]
	Grate[num] = cdp[31+ncp*ch]
	DAQfraction[num] = RT[num] / TT[num]
	NCTrig[num] = mdp[68]
	CSFDT[num] = mdp[69]
	CCT[num] = mdp[70]
	CICR[num] = mdp[71]

	Variable DAQtime
	Nvar StartTime_s = root:pixie4:StartTime_s
	Nvar StopTime_s = root:pixie4:StopTime_s
	DAQtime =  StopTime_s  - StartTime_s 	
//	DAQfraction[num] = RT[num] / DAQtime
	// save MCA counts also: Cs137 peak and Co60 peaks combined
//	wave MCA = $("root:pixie4:mcach"+num2str(ch))
//	wave Cscount
//	wave cocount
//	Cscount[num] = sum(MCA, 5932, 6131)
//	Cocount[num] = sum(MCA, 6270, 6330)// sum(MCA, 2683, 2823) 
//	Co11count[num] = sum(MCA, 2810, 2873)
//	Co13count[num] = sum(MCA, 3179, 3264)
//	Co24count[num] = sum(MCA, 6010, 6060)
//
//	
//	//Cocount_corr = Cocount * 600/CT *ICR/PPR
//	//Cscount_corr = Cocount * 600/CT
//		Cocount_corr = Cocount * 1800/CT *ICR/PPR
//		Gcountch = Cocount * 600/CT *ICR/PPR
//		Co11count_corrOI = Co11count * 1800/CT *ICR/PPR
//		Co13count_corrOI = Co13count * 1800/CT *ICR/PPR
//		Co24count_corrOI = Co24count * 1800/CT *ICR/PPR
//	//Cscount_corr = Cocount * 600/CT
//	// Cscount_corr = Cscount * 600/CT *ICR/PPR


End

Function ExtractRunstats()
// read run stats from .set file

	GBLoadWave/B/N=dsppar/T={80,4}/W=1 

	
	Wave dsppar 
	print "runtime", DoubleFrom3U16("dsppar0",260)/75*1E-6
	print "total time", DoubleFrom3U16("dsppar0",278)/75*1E-6
	print "N events", DoubleFrom2U16("dsppar0",266)
	print " "
	print "LT = ", DoubleFrom3U16("dsppar0",320)/75*16E-6,DoubleFrom3U16("dsppar0",320+24)/75*16E-6,DoubleFrom3U16("dsppar0",320+48)/75*16E-6,DoubleFrom3U16("dsppar0",320+72)/75*16E-6
	print "FTDT = ", DoubleFrom3U16("dsppar0",325)/75*1E-6,DoubleFrom3U16("dsppar0",325+24)/75*1E-6, DoubleFrom3U16("dsppar0",325+48)/75*1E-6, DoubleFrom3U16("dsppar0",325+72)/75*1E-6
	print "SFDT = ", DoubleFrom3U16("dsppar0",328)/75*16E-6, DoubleFrom3U16("dsppar0",328+24)/75*16E-6, DoubleFrom3U16("dsppar0",328+48)/75*16E-6, DoubleFrom3U16("dsppar0",328+72)/75*16E-6
	print "GT = ", DoubleFrom3U16("dsppar0",335)/75*16E-6, DoubleFrom3U16("dsppar0",335+24)/75*16E-6, DoubleFrom3U16("dsppar0",335+48)/75*16E-6, DoubleFrom3U16("dsppar0",335+72)/75*16E-6
	print "Gcount = ", DoubleFrom2U16("dsppar0",331), DoubleFrom2U16("dsppar0",331+24), DoubleFrom2U16("dsppar0",331+48), DoubleFrom2U16("dsppar0",331+72)
	print "Ncount = ", DoubleFrom2U16("dsppar0",333), DoubleFrom2U16("dsppar0",333+24), DoubleFrom2U16("dsppar0",333+48), DoubleFrom2U16("dsppar0",333+72)
	print "Fpeak = ", DoubleFrom2U16("dsppar0",323), DoubleFrom2U16("dsppar0",323+24), DoubleFrom2U16("dsppar0",323+48), DoubleFrom2U16("dsppar0",323+72)



End


Function CheckLMrunstats(type)
Variable type 		// 0 - adc, 1- LM

	wave adcch0 =  root:pixie4:adcch0
	wave trace1 = root:pixie4:trace0
	make/o/n=32 rs0, rs1, rs2, rs3, hdr
	
		variable k, off
		
		
if(type==0)	

	for (k=0;k<16;k+=1)
		hdr[2*k+0] = adcch0[k] & 0xFFFF
		hdr[2*k+1] = floor(adcch0[k] / 65536)
	endfor
	
	off = 16
	for (k=0;k<32;k+=1)
		rs0[k] = adcch0[2*k+off+0]	& 0xFFFF
		rs1[k] =  floor(adcch0[2*k+off+0] / 65536)
		rs2[k] = adcch0[2*k+off+1]	& 0xFFFF
		rs3[k] =  floor(adcch0[2*k+off+1] / 65536)
	endfor
endif

if(type==1)	

	hdr=0
	
	off = 0
	for (k=0;k<32;k+=1)
		rs0[k] = trace1[4*k+off+0]
		rs1[k]  = trace1[4*k+off+1]
		rs2[k]  = trace1[4*k+off+2]
		rs3[k]  = trace1[4*k+off+3]
	endfor
endif


End

Function PollDMAbuffer(start)
Variable start


	Nvar NumberOfModules = root:pixie4:NumberOfModules
	Svar OutputFileName = root:pixie4:OutputFileName
	
	Variable/G fileposwords
	
	Variable ret
	Variable Nof2MB = 524288*10
	Make/o/u/i/n=(Nof2MB) userData		// 2MB buffer, 4bytes each for U32
	Make/o/u/i/n=(2*Nof2MB) userData16
	wave userData
	wave userData16
	userData[0] = start
	print/D "request new data from word", start
	ret = Pixie4_Acquire_Data(0x40FA, userData, OutputFileName, NumberOfModules)	//poll and if DMA idle, save data
	print/d " read file up to word", ret
	if(ret>0)
		fileposwords = ret
	
		if(fileposwords>start)
			Variable k
			for(k=0;k<(fileposwords-start);k+=1)
				userData16[2*k] = userData[k] & 0xFFFF
				userData16[2*k+1] = floor(userData[k] / 65536)
			endfor
		endif
	endif
End



Function ShowU16()
	wave userData
	wave userData16
	Variable k
			for(k=0;k<100000;k+=1)
				userData16[2*k] = userData[k] & 0xFFFF
				userData16[2*k+1] = floor(userData[k] / 65536)
			endfor


End


Function Savefakedata(N)
Variable N
	
	Svar OutputFileName = root:pixie4:OutputFileName

	variable fnum
	make/o/u/i/n=(N*4096) wave0
	wave0=p
	
	open fnum as OutputFileName
	fbinwrite/F=2/U fnum, wave0
	close fnum

End

Function TrigScope(ModNum)
// triggered oscilloscope routine
Variable ModNum

	Variable runtype,  k
	make/u/i/o/n=1 dummy
	make/u/i/o/n=131072 exmem
	make/o/n=8192 alltraces
	make/o/n=2046 trace0,trace1,trace2,trace3
	
//	DoWindow/F scopeplot
//	if(V_flag!=1)
//		Display/K=1 /W=(485.25,281.75,879.75,490.25) alltraces
//		Label left "ADC steps"
//		Label bottom "Time"
//		SetAxis left 0,60000
//		DoWindow/C scopeplot
//	endif
//	setscale/P x, 0, 600e-9, "s",  alltraces
	
	DoWindow/F scopeplotch
	if(V_flag!=1)
		Display/K=1 /W=(10,10,450,250) trace0,trace1,trace2,trace3
		Label left "ADC steps"
		Label bottom "Time"
		SetAxis left 0,45000
		ModifyGraph rgb(trace1)=(0,52224,0),rgb(trace2)=(0,12800,52224),rgb(trace3)=(0,26112,0)

		DoWindow/C scopeplotch
	endif
	setscale/P x, 0, 600e-9, "s",  trace0		// starts at 0; delta 600
	setscale/P x, 146.7e-9, 600e-9, "s",  trace1
	setscale/P x, 239.3e-9, 600e-9, "s",  trace2
	setscale/P x, 440.0e-9, 600e-9, "s",  trace3
	
	print "click abort to stop"
	runtype=33
	pixie4_Acquire_Data(runtype, dummy, "",ModNum)		// start controltask 33 - triggered ADC trace capture to EM
	
	runtype=0x9003		// read EM 
	do				
		pixie4_Acquire_Data(runtype, exmem, "",ModNum)
		exmem=exmem	
		for(k=0;k<8192;k+=1)
			alltraces[2*k]=(exmem[k] & 0xFFFF)
			alltraces[2*k+1] =floor(exmem[k]/65536) 	
		endfor
		alltraces[8191]=nan
		trace0 = alltraces[1+p]
		trace1 = alltraces[2049+p]
		trace2 = alltraces[4097+p]
		trace3 = alltraces[6145+p]
		DoUpdate
	while(1)
	
	//Note: Controltask continues in DSP. Most new runs are proceeded by a "stop run" command in the C library. 
	//         Otherwise issue something like the following "stop run" command after "aborting":
	//         Pixie4_Acquire_Data(0x3000, dummy, "", NumberOfModules)  // Stop run in all modules
End	

Function DoubleFrom3U16(wav,loc)
String wav
Variable loc

	Variable ret
	String wv
	wv = wav
	Wave data = $wav
	ret = data[loc]*2^32+ data[loc+1]*2^16 + data[loc+2]
	return ret
End

Function DoubleFrom2U16(wav,loc)
String wav
Variable loc

	Variable ret
	Wave data = $wav
	ret = data[loc]*2^16+ data[loc+1]
	return ret
End





// New parameter modification scheme
//	Wave Display_Channel_Parameters = root:pixie4:Display_Channel_Parameters
//	Nvar index_BASEPC = root:pixie4:index_BASEPC
//	Nvar ncp = root:pixie4:NumChannelPar
//	String name
//
//	Wave Display_Channel_Parameters = root:pixie4:Display_Channel_Parameters
//	Nvar index_LIVETIME = root:pixie4:index_LIVETIME
//	Nvar index_ICR = root:pixie4:index_ICR
//	Nvar ncp = root:pixie4:NumChannelPar

//Display_Channel_Parameters[index_BASEPC+m*ncp] = percent
//name = "ADC_BASELINE_PERCENT"+num2str(m)
//Pixie_IO_ChanVarControl(name,0,"","")
//
//
//root:pixie4:Display_Channel_Parameters[ root:pixie4:index_BASEPC+m*root:pixie4:NumChannelPar] = 10
//name = "ADC_BASELINE_PERCENT"+num2str(m)
//Pixie_IO_ChanVarControl(name,0,"","")



//	Variable Filterrange = Display_Module_Parameters[index_FilterRange]
//Wave Display_Module_Parameters = root:pixie4:Display_Module_Parameters
//	Nvar index_FilterRange = root:pixie4:index_FilterRange
//	Nvar index_RunTime = root:pixie4:index_RunTime
//	Nvar index_EvRate = root:pixie4:index_EvRate
//index_RunTime
//index_EvRate
//index_NumEv

Function InitAnalysisglobals()

	Variable/G root:SL
	Variable/G root:SG
	Variable/G root:SFR
	Variable/G root:Tau
	Variable/G root:DeltaT
	Variable/G root:TriggerPos
	Variable/G root:defaultTriggerPos
	Variable/G root:FL
	Variable/G root:FG
	Variable/G root:Threshold
	Variable/G root:SkipInitialPoints
	
	Variable/G root:UseTrapFilter
	Variable/G root:RemovePileup
	Variable/G root:IgnoreRT
	

	Variable/G root:PSAchannel
	
	Make/o/n=1 root:trace
	
	Make/o/n=6 root:xp
	make/o/n=100 triggers, piledup
	Make/o/n=1 root:sumlimits
	Make/o/n=1 root:RTlimits
	Make/o/n=1 root:PSAlimits
	
	Variable/G root:E0
	Variable/G root:E1
	Variable/G root:Eg

	make/o/n=20 root:EdbgIgor
	make/o/n=20 root:EdbgDSP
	make/o/t/n=20 root:EdbgNames

	Variable/G root:Numwords

End

Window AnalysisControl() : Panel
	
	NewPanel/K=1 /W=(930,20,1250,370)
	ModifyPanel cbRGB=(57344,65280,48896)
	SetVariable setvar0,pos={10,6},size={180,18},title="SL (DSP value * FR)",value= SL, fsize=11
	SetVariable setvar1,pos={10,30},size={180,18},title="SG (DSP value * FR)",value= SG, fsize=11
	SetVariable setvar2,pos={10,54},size={180,18},title="Tau (us)          ",value= tau, fsize=11
	SetVariable setvar3,pos={10,78},size={180,18},title="dT (us) = 1 / FILTER clk",value= DeltaT, fsize=11
	SetVariable setvar6,pos={10,102},size={180,18},title="trig pos near" ,value= defaultTriggerPos, fsize=11
	SetVariable setvar10,pos={10,126},size={180,18},title="samples to skip",value= SkipInitialPoints, fsize=11

	
	CheckBox UTF, pos = {10,150}, title = "trapezoidal filter", variable = UseTrapFilter, fsize=11
	CheckBox UPI, pos = {10,175}, title = "remove pileup", variable = RemovePileup, fsize=11
	SetVariable setvar7,pos={10,200},size={90,18},title="FL",value= FL, fsize=11
	SetVariable setvar8,pos={10,222},size={90,18},title="FG",value= FG, fsize=11
	SetVariable setvar9,pos={10,244},size={90,18},title="TH",value= Threshold, fsize=11
	
	CheckBox noRT, pos = {10,285}, title = "ignore RT in PSA", variable = IgnoreRT, fsize=11

		
	SetVariable setvar4,pos={210,50},size={80,18},title="channel",value= PSAchannel, fsize=11

EndMacro






Function LM_ReadSpills(Newfile)
Variable Newfile // 0 - reprocess old file, 1 - select new file by dialog, 2 - load LM data file
	Svar dgfpath 
	Svar longDataFilename = $(dgfpath+"longDataFilename")
	
	if (NewFile==1)
		GBLoadWave/B/O/A=LMData/T={80,4}/W=1
	endif
	
	if (NewFile==2)
		GBLoadWave/B/O/A=LMData/T={80,4}/W=1 longDataFilename
	endif
		
	Wave LMData0
	Variable k, index, numbuffers,filltime,m,nummodules, highTime
	
	Nvar Numwords
	
	// check how many buffers
	wavestats/q LMData0
	numwords = V_npnts
	index=0
	do 
		if(LMData0[index]	>0)
			index+=LMData0[index]	
		else
			print " found zerobuffer length at", index
			break	
		endif
		numbuffers+=1
	while(index<numwords)
	print "Number of 8k buffers:", numbuffers
	
	// get buffer headers and number of modules
	make/o/n=(numbuffers) root:test:Nwords, root:test:ModNum, root:test:RunType, root:test:BufStartTime, root:test:BufStartLoc
	make/o/n=(numbuffers) root:test:CumSpillTime
	make/o/n=(numbuffers) root:test:FirstEventTime, root:test:LastEventTime103onech, root:test:EventDeadTime103onech
	
	
	
	Wave Nwords = root:test:Nwords
	Wave ModNum = root:test:ModNum
	Wave RunType = root:test:RunType
	Wave BufStartTime = root:test:BufStartTime
	Wave BufStartLoc = root:test:BufStartLoc
	
	Wave CumSpillTime = root:test:CumSpillTime
	
	Wave FirstEventTime = root:test:FirstEventTime
	Wave LastEventTime103onech = root:test:LastEventTime103onech
	Wave EventDeadTime103onech = root:test:EventDeadTime103onech
	
	CumSpillTime=nan
	EventDeadTime103onech=nan

	make/o/n=18 root:test:lasteventtimeinspill,  root:test:firstbuffertimeinspill, root:test:firstspillformodule
	Wave lasteventtimeinspill = root:test:lasteventtimeinspill
	lasteventtimeinspill = 0
	Wave firstspillformodule = root:test:firstspillformodule
	firstspillformodule = 1
	Wave firstbuffertimeinspill = root:test:firstbuffertimeinspill
	firstbuffertimeinspill = 0
	Variable prevMod
	
	nummodules=1
	index =0
	for (k=0;k<numbuffers;k+=1)
	
		BufStartLoc[k] = index
		Nwords[k] = LMData0[index]	// words in buffer
		ModNum[k] = LMData0[index+1]	//Module number
		if(nummodules<(LMData0[index+1]+1))
			nummodules = LMData0[index+1]+1
		endif
		
		
		RunType[k] = LMData0[index+2]	// runtype
		highTime = LMData0[index+3]*65536^2
		BufStartTime[k]= (highTime + 	LMData0[index+4]*65536+ LMData0[index+5])*13.33e-9 //timestamp of buffer header
		FirstEventTime[k]= (highTime + 	LMData0[index+7]*65536+ LMData0[index+8])*13.33e-9 //timestamp of first event
		index+=LMData0[index]
		// works only for 0x103  with one channel active
		LastEventTime103onech[k]= (highTime + 	LMData0[index-4]*65536+ LMData0[index-3])*13.33e-9 //timestamp of last event
		
		// works only for 0x103  with 4 channels active
		//LastEventTime103onech[k]= (highTime + 	LMData0[index-10]*65536+ LMData0[index-9])*13.33e-9 //timestamp of last event

	
		if(k==0)
			prevMod = ModNum[k]
			firstbuffertimeinspill[prevMod] = BufStartTime[k]
			firstspillformodule[prevMod]=0
		else
			if (ModNum[k]==prevMod)
				// works only for 0x103  with one channel active
				EventDeadTime103onech[k] = BufStartTime[k] - LastEventTime103onech[k-1]		// time between last event and restart of acquisition in new buffer 

	//			CumSpillTime[k] =  BufStartTime[k] - firstbuffertimeinspill[prevMod]
			else
				//old module		
				// works only for 0x103  with one channel active		
				lasteventtimeinspill[prevMod] = LastEventTime103onech[k-1]
				
				// new module
				prevMod = ModNum[k]
				if(firstspillformodule[prevMod]==0)
					EventDeadTime103onech[k]  = BufStartTime[k] - lasteventtimeinspill[prevMod]        // time between last event and restart of acquisition in new buffer 
				else
					firstspillformodule[prevMod]=0
				endif
				firstbuffertimeinspill[prevMod] = BufStartTime[k]
			endif
		endif
	endfor
	

//	if(mod(numbuffers,32)==0)	//32spill mode
//		make/o/n=(numbuffers/4,6) root:test:bufheaders32
//		Wave bufheaders32 = root:test:bufheaders32
//		for (k=0;k<numbuffers/32;k+=1)
//			bufheaders32[k][] = bufheaders[k*32][q]	
//			//average time to fill buffer and transfer to EM
//			filltime=(bufheaders[k*32+31][4]-bufheaders[k*32][4])/31 //start of first to start of 32nd
//			bufheaders32[k][4] = filltime
//			bufheaders32[k][5] = bufheaders[k*32+32*nummodules][4] - bufheaders[k*32+31][4] -filltime  //est. readout time
//		endfor
//	else
//			print "data not taken in 32buffer/spill mode"
//	endif

	DoWindow/F BufHeadTable
	if(V_flag!=1)
		edit/K=0 root:test:BufStartLoc, root:test:Nwords, root:test:ModNum, root:test:RunType, root:test:BufStartTime //, root:test:CumSpillTime, 
		AppendToTable root:test:FirstEventTime, root:test:LastEventTime103onech, root:test:EventDeadTime103onech
		DoWindow/C BufHeadTable
		ModifyTable width(Nwords)=59,width(ModNum)=54,format(RunType)=10,width(RunType)=56
	//	ModifyTable format(CumSpillTime)=3,digits(CumSpillTime)=6
		ModifyTable format(BufStartTime)=3,digits(BufStartTime)=6,format(FirstEventTime)=3
		ModifyTable digits(FirstEventTime)=6,format(LastEventTime103onech)=3,digits(LastEventTime103onech)=6
		ModifyTable width(LastEventTime103onech)=96,format(EventDeadTime103onech)=3,digits(EventDeadTime103onech)=6
		ModifyTable width(EventDeadTime103onech)=98
	endif
	
	return(numbuffers)

End


Function LM_ListEvents(SpillNo)	// analyze LM data to extract event header of one spill
Variable SpillNo						// Assumes LM_ReadSpills has just been executed

	Wave Nwords = root:test:Nwords
	Wave ModNum = root:test:ModNum
	Wave RunType = root:test:RunType
	Wave BufStartTime = root:test:BufStartTime
	Wave LMData0
	
	Nvar 	Numwords
	
	Nvar ADCClockMHz = root:pixie4:ADCClockMHz 
	Variable dt = 1/ADCClockMHz*1e-6
	
	Variable Nmod, Nspills, Nbuffers, index, numbuffers, highTime
	Variable k, numbufferwords, eventnum, hit, addtoindex, startindex
	// determine # of modules and # spills
	wavestats/q ModNum
	
	Nmod = V_max+1
	Nbuffers = V_npnts
	Nspills = Nbuffers/Nmod
//	print "Number of spills", Nspills
	
	
	// find first buffer of interest

	//wavestats/q LMData0
	//numwords = V_npnts
	index=0
	do 
		if(LMData0[index]	>0)
			index+=LMData0[index]	
		else
			print " found zerobuffer length"
			break	
		endif
		numbuffers+=1
	while((index<numwords) & (numbuffers <SpillNo*Nmod))	
	print "assuming 1x buffer mode. Fix to include 32x mode"
	if((numbuffers == 1 ) & (SpillNo==0))
		numbuffers = 0
		index = 0
	endif
	print "Spill",SpillNo,"starts at buffer number", numbuffers, "location",index
	
	
	
	if((RunType[0] & 0xFFF) == 0x103)
		addtoindex = 2
	endif
	if((RunType[0] & 0xFFF) == 0x102)
		addtoindex = 4
	endif
	if((RunType[0] & 0xFFF) == 0x101)
		addtoindex = 9
	endif
	if((RunType[0] & 0xFFF) == 0x100)
		addtoindex =309	// read from data later
	endif
		
	make/o/n=(3000,Nmod) root:test:Hitpattern
	make/o/d/n=(3000,Nmod) root:test:Hitpattern, root:test:EventTime, root:test:EventTime_dif, root:test:EventLoc
	Wave HitPattern = root:test:HitPattern
	Wave EventTime = root:test:EventTime
	Wave EventTime_dif = root:test:EventTime_dif
	Wave EventLoc = root:test:EventLoc
	Hitpattern = nan
	EventTime = nan
	make/o/n=(3000,Nmod*4) root:test:ChEnergy, root:test:ChTime
	Wave ChEnergy = root:test:ChEnergy
	Wave ChTime = root:test:ChTime
	ChEnergy = nan
	ChTime = nan	


	for(k=0;k<Nmod; k+=1)
		eventnum = 0
		
		numbufferwords = LMData0[index]
		startindex = index
	//	print index, numbufferwords
		index+=6
		do
			hit = LMData0[index]
			Hitpattern[eventnum][k] = hit
			EventTime[eventnum][k] = (LMData0[index+1]*65536 +  LMData0[index+2] )*dt
			EventLoc[eventnum][k] = index
			index+=3
	
			if( ((RunType[0] & 0xFFF)==0x100) | ((RunType[0] & 0xFFF)==0x101) )		// add different number depending on tracelength (soon)
				addtoindex = LMData0[index]
				if (hit & 0x1) 
					ChTime[eventnum][k*4+0] = LMData0[index+1]
					ChEnergy[eventnum][k*4+0] = LMData0[index+2]
					index +=	 addtoindex
				endif
				if (hit & 0x2) 
					ChTime[eventnum][k*4+1] = LMData0[index+1]
					ChEnergy[eventnum][k*4+1] = LMData0[index+2]
					index +=	 addtoindex
				endif
				if (hit & 0x4) 
					ChTime[eventnum][k*4+2] = LMData0[index+1]
					ChEnergy[eventnum][k*4+2] = LMData0[index+2]
					index +=	 addtoindex
				endif
				if (hit & 0x8) 
					ChTime[eventnum][k*4+3] = LMData0[index+1]
					ChEnergy[eventnum][k*4+3] = LMData0[index+2]
					index +=	 addtoindex
				endif		
			else		// add a fixed number for every channel hit
				if (hit & 0x1) 
					ChTime[eventnum][k*4+0] = LMData0[index+0]
					ChEnergy[eventnum][k*4+0] = LMData0[index+1]
					index +=	 addtoindex
				endif
				if (hit & 0x2) 
					ChTime[eventnum][k*4+1] = LMData0[index+0]
					ChEnergy[eventnum][k*4+1] = LMData0[index+1]
					index +=	 addtoindex
				endif
				if (hit & 0x4) 
					ChTime[eventnum][k*4+2] = LMData0[index+0]
					ChEnergy[eventnum][k*4+2] = LMData0[index+1]
					index +=	 addtoindex
				endif
				if (hit & 0x8) 
					ChTime[eventnum][k*4+3] = LMData0[index+0]
					ChEnergy[eventnum][k*4+3] = LMData0[index+1]
					index +=	 addtoindex
				endif
			endif
			
			eventnum+=1
			
		while(index < (startindex +numbufferwords) )
		index = (startindex +numbufferwords)
	endfor
	print "number of events:", eventnum
	
	//Differentiate  root:test:EventTime/D= root:test:EventTime_dif
	//Differentiate  EventTime/D= EventTime_dif
	EventTime_dif=nan
	for(k=0;k<eventnum-1;k+=1)
		EventTime_dif[k] = EventTime[k+1] - EventTime[k]
		
	endfor
	//make/o/n=1000 ETdif_hist
	histogram/A/B={0,64e-9,10000} EventTime_dif, ETdif_hist

End




Function LM_ListEventsAll(num)
Variable num

	Variable k
	for(k=0;k<num;k+=1)
		LM_ListEvents(k)
		DoUpdate
	endfor
End

Function LM_ETdistribution(app)	//histogram event time stamp differences (within spill)
Variable app

	Variable num, Nevents, m,k, ret, index
	if(app==0)
		make/o/n=1000 ETdif_hist, ETdif_histtotal
	endif
	wave ETdif_hist
	wave ETdif_histtotal
	ETdif_hist = 0


	num = LM_ReadSpills(2)
	LM_ListEventsAll(num)

	if (app==0)
		duplicate/o ETdif_hist, ETdif_histtotal
	else
		ETdif_histtotal += ETdif_hist
	endif
	
	DoWindow/F Tdistribution
	if(V_flag!=1)
		display/K=0 ETdif_hist, ETdif_histtotal
		DoWindow/C Tdistribution
		Label bottom "delta T (s)"
	endif
	
End

//Function User_NewFileDuringRun(Runtype)
//String Runtype	// "List" for list mode runs, "MCA" for MCA runs
//
//	//called from Pixie_CheckRun (executed every polling period) in those occasions 
//	//when Igor automatically saves files and increments run file number after N spills or seconds. 
//	// called after data is saved to current files, before new files are made and run resumes
//	
//	//Use to process output data, modify parameters, or add comments in between auto saves
//	// use if statements below to distinguish between run types
//	
//		// to process output data
//	Nvar MaxNumModules = root:pixie4:MaxNumModules
//	Nvar PRESET_MAX_MODULES = root:pixie4:PRESET_MAX_MODULES	
//	Nvar NumberOfModules = root:pixie4:NumberOfModules
//	Svar OutBaseName = root:pixie4:OutBaseName
//	Nvar RunNumber = root:pixie4:RunNumber
//	Nvar ProcessBeforeNewRun = root:user:ProcessBeforeNewRun
//		Svar dgfpath 
//	
//	Variable ret, fn, num
//	String filename, LMdatafilename, ErrMSG, savename
//	
//	 if(cmpstr(Runtype, "List")==0)
//		// roll back current run number by one
//		num = RunNumber-1
//		sprintf filename, "%s%04d.bin", OutBaseName, num
//		Open/R/P=EventPath fn as filename
//		PathInfo EventPath
//	
//		if(fn == 0)
//			sprintf ErrMSG, "Error: can not open file %s\r", filename
//			 DoAlert 0,ErrMSG
//			 return(-1)
//		else
//			close fn
//		endif
//		LMdatafilename = S_Path + filename
//		LMdatafilename = Pixie_FileNameConversion(LMdatafilename)	
//	
//	Svar longDataFilename = $(dgfpath+"longDataFilename")
//	savename = longDataFilename
//	longDataFilename = LMdatafilename
//	
//		LM_ETdistribution(1)
//		longDataFilename = savename
//	 endif
//	
//	// if(cmpstr(Runtype, "MCA")==0)
//	//
//	// endif
//	
//	// for example, uncomment below to save Igor
//	//saveExperiment
//End

Function LM_CTdistribution()	//histogram event time stamp differences (within spill)

	Variable Nevents, m,k
	
		
	Nvar ChosenEvent = root:pixie4:ChosenEvent
	Nvar ChosenModule = root:pixie4:ChosenModule
	wave listmodewave = root:pixie4:listmodewave	
	Nevents=listmodewave[ChosenModule]
	
//	Killwaves/Z root:pixie4:EventPSAValues
//	make/o/u/i/n=(nevents*8*NumberOfChannels) root:pixie4:EventPSAValues
//	
//	// event by event, always 8 words for ch 0-1-2-3: energy, XIA, user, user_2, user_3, user_4, user_5
//	Wave PSAvalues = root:pixie4:eventpsavalues
//		
//	// parse the list mode event file
//	ret = Pixie4_Acquire_Data(0x7006, PSAvalues, longDataFilename, ChosenModule)
//	if(ret < 0)
//		Doalert 0, "Can not read event PSA values from the list mode event file."
//		return(-1)
//	endif

	
	Variable ch =0
	make/o/n=(nevents) CT, CTdiff
	
	Variable len, ret
	Variable ModLoc = 0
	wave eventposlen = root:pixie4:eventposlen
	len = 2000 // ensure enough room for full channel headers
	make/o/u/i/n=(len) root:pixie4:eventwave
	wave eventwave = root:pixie4:eventwave
	Svar longDataFilename = root:pixie4:longDataFilename

	
	for(m=0;m<nevents;m+=1)
		
		ChosenEvent=m
		
		//Pixie_IO_ReadEvent()
		eventwave=0
		eventwave[0] = eventposlen[ModLoc+ChosenEvent*3]		// event location
		eventwave[1] = eventposlen[ModLoc+ChosenEvent*3+1]	// corresponding buffer header location
		eventwave[2] = eventposlen[ModLoc+ChosenEvent*3+2]	// length of event
		eventwave[3] = 100000	// >64K to switch off looking for related pulses
		// read event
		ret = Pixie4_Acquire_Data(0x7008, eventwave, longDataFilename, ChosenModule)
		if(ret < 0)
			DoAlert 0, "There are no events in this list mode file for this module"
			return(ret)
		endif
		
		
		CT[m]   	= eventwave[7+6+3+ch*9+1]		
	endfor
	
	CTdiff=nan
	for(k=0;k<Nevents-1;k+=1)
		CTdiff[k] = CT[k+1] - CT[k]
		
	endfor
	make/o/n=1000 CTdiff_hist
	histogram/B={0,500e-9,10000} CTdiff, CTdiff_hist


	
	
	DoWindow/F Tdistribution
	if(V_flag!=1)
		Display /W=(405,203.75,930,527) CTdiff_hist
		DoWindow/C Tdistribution
		AppendToGraph/L=L1/B=B1 CT,fit_CT
		AppendToGraph/L=Res_L1/B=B1 Res_CT
		ModifyGraph mode(CTdiff_hist)=2
		ModifyGraph lSize(CTdiff_hist)=3,lSize(CT)=2
		ModifyGraph rgb(CTdiff_hist)=(0,15872,65280),rgb(CT)=(0,0,0),rgb(Res_CT)=(65280,0,0)
		ModifyGraph lblPos(left)=57,lblPos(bottom)=37,lblPos(L1)=32,lblPos(B1)=39,lblPos(Res_L1)=33
		ModifyGraph lblLatPos(L1)=9,lblLatPos(B1)=25,lblLatPos(Res_L1)=-2
		ModifyGraph freePos(L1)={0,B1}
		ModifyGraph freePos(B1)={0,L1}
		ModifyGraph freePos(Res_L1)={0,B1}
		ModifyGraph axisEnab(left)={0,1}
		ModifyGraph axisEnab(L1)={0.45,0.75}
		ModifyGraph axisEnab(B1)={0.45,0.95}
		ModifyGraph axisEnab(Res_L1)={0.77,0.9}
		ModifyGraph manTick(Res_L1)={0,2,6,0},manMinor(Res_L1)={0,50}
		Label left "N events"
		Label bottom "delta T (s)"
		Label L1 "Timestamp"
		Label B1 "Event Number"
		SetAxis left 0,10000
		SetAxis bottom 0,0.00015
		ShowInfo
	endif
	
End



Function LM_ExtractHPET()	// analyze LM data to extract hit pattern and event time from all spills
Variable SpillNo						// Assumes LM_ReadSpills has just been executed

	Wave Nwords = root:test:Nwords
	Wave ModNum = root:test:ModNum
	Wave RunType = root:test:RunType
	Wave BufStartTime = root:test:BufStartTime
	Wave LMData0
	
	Variable Nmod, Nspills, Nbuffers, numwords, index, numbuffers, highTime
	Variable k, numbufferwords, hit, addtoindex, startindex, evnummax
	// determine # of modules and # spills
	wavestats/q ModNum
	
	Nmod = V_max+1
	Nbuffers = V_npnts
	Nspills = Nbuffers/Nmod
	print "Number of spills", Nspills
	
	
	// find first buffer of interest

	wavestats/q LMData0
	numwords = V_npnts
	index=0
	
	if((RunType[0] & 0xFFF) == 0x103)
		addtoindex = 2
	endif
	if((RunType[0] & 0xFFF) == 0x102)
		addtoindex = 4
	endif
	if((RunType[0] & 0xFFF) == 0x101)
		addtoindex = 9
	endif
	if((RunType[0] & 0xFFF) == 0x100)
		addtoindex =309	// read from data later
	endif
		
	make/o/n=(3000,Nmod) root:test:Hitpattern, root:test:EventTime
	make/o/n=(Nmod) eventnum
	Wave HitPattern = root:test:HitPattern
	Wave EventTime = root:test:EventTime
	Hitpattern = nan
	EventTime = nan
	
	eventnum = 0	
do	
	for(k=0;k<Nmod; k+=1)
		
	
		
		numbufferwords = LMData0[index]
		startindex = index
//		print index, numbufferwords
		index+=6
		do
			hit = LMData0[index]
			Hitpattern[eventnum[k]][k] = hit
			EventTime[eventnum[k]][k] = (LMData0[index+1]*65536 +  LMData0[index+2] )//*13.33e-9
			index+=3
	
			if((RunType[0] & 0xFFF)==0x100)		// add different number depending on tracelength (soon)
				
				if (hit & 0x1) 
					addtoindex = LMData0[index]
					index +=	 addtoindex		
				endif
				if (hit & 0x2) 
					addtoindex = LMData0[index]
					index +=	 addtoindex		
				endif
				if (hit & 0x4) 
					addtoindex = LMData0[index]
					index +=	 addtoindex		
				endif
				if (hit & 0x8) 
					addtoindex = LMData0[index]
					index +=	 addtoindex		
				endif		
			else		// add a fixed number for every channel hit
				if (hit & 0x1) 
					index +=	 addtoindex
				endif
				if (hit & 0x2) 
					index +=	 addtoindex
				endif
				if (hit & 0x4) 
					index +=	 addtoindex
				endif
				if (hit & 0x8) 
					index +=	 addtoindex
				endif
			endif
			
			eventnum[k]+=1
			
		while(index < (startindex +numbufferwords) )
		index = (startindex +numbufferwords)
	endfor
	
	evnummax =0
	for(k=0;k<Nmod; k+=1)
		evnummax = max(evnummax, eventnum[k])	
	endfor
	eventnum = evnummax
	
while (index<numwords)

End

Function LM_GetCTdiff(chA,chB)		// compute difference betwen 2 channel's timestamps
Variable chA, chB
		// apparently, eventwave has to be open as a table for timestamps to be read properly
		Svar dgfpath 
		wave listmodewave = $(dgfpath+"listmodewave")
		Nvar ChosenModule = $(dgfpath+"ChosenModule")
		Nvar ChosenEvent = $(dgfpath+"ChosenEvent")
		wave eventwave = $(dgfpath+"eventwave")
		
		Variable BufHeadLen = 6//$(dgfpath+"BufHeadLen")
		Variable EventHeadLen = 3//$(dgfpath+"EventHeadLen")
		Variable ChanHeadLen = 9//$(dgfpath+"ChanHeadLen")
	
		
		Variable NumEvents, ew_header2,k, index
		
		NumEvents = listmodewave[ChosenModule]
		ew_header2 = 7+BufHeadLen+EventHeadLen 
		
		make/o/n=(NumEvents) TimeA, TimeB, diffAB
		make/o/n=2048 diffAB_histo
		
		for(k=0;k<NumEvents;k+=1)
			ChosenEvent = k
			Pixie_IO_ReadEvent()
			index = ew_header2+chA*9+1
			TimeA[k] = eventwave[ew_header2+chA*9+1]
			TimeB[k] = eventwave[ew_header2+chB*9+1]
			diffAB[k] = TimeA[k]-TimeB[k]
			if (diffAB[k] >60000)
				diffAB[k]-=65536
			endif
			if (diffAB[k] <-60000)
				diffAB[k]+=65536
			endif
		endfor

		//diffAB = TimeA-TimeB
		wavestats/q diffAB 
		histogram/B={-1024, 1,2048} diffAB, diffAB_histo
		
End

//
// GetLMdata: extract channel information from list mode header for all events in file
//
Function GetLMdata(channel)
Variable channel

	
	Variable Nevents, ch
	Variable k,m, len,n, index, E, ret, recordlength
	String text
	
	recordlength =8		// valid for run type 0x100 or 0x101 only

	// *** 1 *** get data from file
	Svar dgfpath 
	Svar DataFile = $(dgfpath+"DataFile")
	Svar longDataFilename = $(dgfpath+"LongDataFilename")	
	Nvar ChosenModule = $(dgfpath+"ChosenModule")
	Nvar NumberOfChannels = $(dgfpath+"NumberOfChannels")
	Nvar ChosenEvent = $(dgfpath+"ChosenEvent")
	wave listmodewave = $(dgfpath+"listmodewave")
	
	// event by event, always 8 words for ch 0-1-2-3: energy, XIA, user, user_2, user_3, user_4, user_5
	Nevents=listmodewave[ChosenModule]
	Killwaves/Z $(dgfpath+"EventPSAValues")
	make/o/u/i/n=(nevents*recordlength*NumberOfChannels) $(dgfpath+"EventPSAValues")
	Wave PSAvalues = $(dgfpath+"eventpsavalues")
				
	// parse the list mode event file
	ret = Pixie4_Acquire_Data(0x7006, PSAvalues, longDataFilename, ChosenModule)
	if(ret < 0)
		Doalert 0, "Can not read event PSA values from the list mode event file."
		return(-1)
	endif
	
	Killwaves/Z root:test:energy, root:test:timestamp, root:test:XIAPSA, root:test:UserPSA, root:test:User2,  root:test:User3,  root:test:User4,  root:test:User5 		
	make/o/n=(Nevents) root:test:energy, root:test:timestamp, root:test:XIAPSA, root:test:UserPSA, root:test:User2,  root:test:User3,  root:test:User4,  root:test:User5 	

	Wave energy = root:test:energy
	Wave timestamp = root:test:timestamp
	Wave XIAPSA = root:test:XIAPSA
	Wave UserPSA = root:test:UserPSA
	Wave User2 = root:test:User2
	Wave User3 = root:test:User3
	Wave User4 = root:test:User4
	Wave User5 = root:test:User5
	
	// *** 2 *** sort data from file or memory into waves, do some error checks
		
	for(m=0;m<nevents;m+=1)
		index = (m*NumberOfChannels+Channel)*recordlength
		timestamp[m] = PSAvalues[index+0]		
		energy[m]    =   PSAvalues[index+1]		
		XIAPSA[m]  =   PSAvalues[index+2]		// rise time
		UserPSA[m]=  PSAvalues[index+3]			// event type
		User2[m]      =  PSAvalues[index+4]		// sum P
		User3[m]      =  PSAvalues[index+5]
		User4[m]      =  PSAvalues[index+6]
		User5[m]      =  PSAvalues[index+7]					
	endfor	
	

	// a few application specific operations
	duplicate/o root:test:user2, PE
	Wave PE
	PE =user2/energy
	
	make/o/n=100 histo_RT
	Wave hist_RT
	histogram/B=4 root:test:XIAPSA, histo_RT

End




//*********************************************************************************
// Offline energy computation
//*********************************************************************************

Function ComputeE()

	Nvar UseTrapFilter
	Variable energy
	ComputeE_triggers()		// finds triggerpos and checks for pileup
	ComputeE_MarkSF() 		// marks energy sum limits
	
	if (UseTrapFilter)
		energy = ComputeE_trapezoid()
	else
		energy =ComputeE_Integrator()
	endif

	return(energy)
End

Function EdgbofDSP()

	wave EdbgDSP = EdbgDSP
	Svar dgfpath
	Pixie_EX_MemoryScan(0)
	wave MV = $(dgfpath+"Memoryvalues")
	variable k = 3632
	EdbgDSP[6] = MV[k+1]*65536+MV[k+2]	// B0
	EdbgDSP[3] = MV[k+3]*65536+MV[k+4]	// E0
	EdbgDSP[0] = MV[k+7]*65536+MV[k+8]	// C0
	EdbgDSP[5] = MV[k+13]*65536+MV[k+14]	// E1
	EdbgDSP[8] = MV[k+11]*65536+MV[k+12]	// B0
	EdbgDSP[1] = MV[k+19]*65536+MV[k+20]	// C1
	EdbgDSP[7] = MV[k+21]*65536+MV[k+22]	// Bg
	EdbgDSP[4] = MV[k+23]*65536+MV[k+24]	// Eg
	EdbgDSP[2] = MV[k+33]	// Cg
	EdbgDSP[9] = MV[k+34]	// energy

End




Function ComputeE_trapezoid()

	Nvar SL = SL
	Nvar SG =SG
	Nvar Tau
	Nvar DeltaT	
	Nvar PSAchannel
	Nvar TriggerPos = root:TriggerPos
	Nvar SkipInitialPoints
	
	Wave xp=xp
	Wave sumlimits=root:sumlimits
	Wave EdbgIgor = root:EdbgIgor

	
	Svar dgfpath 
	Wave trace =  $(dgfpath+"trace"+num2str(PSAchannel))
	Nvar ChosenEvent = $(dgfpath+"ChosenEvent")	
	
	Variable C0, Cg, C1, q, off, x0, x1, x2, x3, x4, x5, energy, baseline, numbases, k, offnew

	
	// Calculate energy filter coefficients		
	q=exp(-DeltaT/Tau)
	C0=-(1-q)/(1-q^SL)*q^SL
	Cg=1-q
	C1=(1-q)/(1-q^SL)	
	EdbgIgor[0] = C0
	EdbgIgor[1] = Cg
	EdbgIgor[2] = C1
	EdbgIgor[3] = sum(trace,xp[0],xp[1]) 
	EdbgIgor[4] = sum(trace,xp[2],xp[3]) 
	EdbgIgor[5] = sum(trace,xp[4],xp[5])
	print "q = ",q,"; elm = ",(q^SL),"; C0 = ",C0,"; Cg = ",Cg,"; C1 = ", C1 
	
	// Calculate energy
	energy=C0*sum(trace,xp[0],xp[1]) + Cg*sum(trace,xp[2],xp[3]) + C1*sum(trace,xp[4],xp[5])
	print "energy = ", energy

	
	//calculate baselines
	off=TriggerPos -SL - 10
	numbases = floor( (off-SkipInitialPoints) / (SL+SG+SL))
	
	if(numbases == 0)
		printf "Warning: event # %d w/o baseline\r", ChosenEvent
		energy=0
		baseline = 0
	else
		baseline = 0
		for(k=0; k<numbases; k+=1)
			offnew=off - (SL+SG+SL)*(k+1)
			x0=pnt2x(trace, offnew)
			x1=pnt2x(trace, offnew+SL-1)
			x2=pnt2x(trace, offnew+SL)
			x3=pnt2x(trace, offnew+SL+SG-1)
			x4=pnt2x(trace, offnew+SL+SG)
			x5=pnt2x(trace, offnew+2*SL+SG-1)
			baseline += C0*sum(trace,x0,x1) + Cg*sum(trace,x2,x3) + C1*sum(trace,x4,x5)
			sumlimits[offnew]=trace[offnew]

		endfor
		baseline /= numbases					
	endif
	energy -= baseline

	EdbgIgor[9] = energy


	
	return(energy)
End


Function ComputeE_MarkSF() 	// use filter parameters and trigger position to
					// calculate limits for filter sums, 
					// set markes in trace duplicates to display limits in graph
	Nvar SL
	Nvar SG
	Nvar Threshold
	Nvar PSAchannel
	Nvar TriggerPos
	Nvar UseTrapFilter
	
	Svar dgfpath 
	Wave trace =  $(dgfpath+"trace"+num2str(PSAchannel))
	Wave sumlimits
	Wave xp
	
	duplicate/o trace, sumlimits
	sumlimits=nan

	Variable p0, p1, p2, p3, p4, p5,p6, p7

	
	if(UsetrapFilter)	
		//Std
		p0=TriggerPos -SL// - 10 // -25
		p1 = p0+SL-1
		p2 = p0+SL
		p3 = p0+SL+SG-1
		p4 = p0+SL+SG
		p5 = p0+2*SL+SG-1
		p7 = TriggerPos + SG +SL	// end of pileup inspection
		xp[0]=pnt2x(trace, p0)
		xp[1]=pnt2x(trace, p1)
		xp[2]=pnt2x(trace, p2)
		xp[3]=pnt2x(trace, p3)
		xp[4]=pnt2x(trace, p4)
		xp[5]=pnt2x(trace, p5)
				
		sumlimits[p0]=trace[p0]	//E0 begin
		sumlimits[p1]=trace[p1]	//E0 end
		sumlimits[p2]=trace[p2]	//gap begin
		sumlimits[p3]=trace[p3]	//gap end
		sumlimits[p4]=trace[p4]	
		sumlimits[p5]=trace[p5]
		//sumlimits[p7]=trace[p7]
	else
		// int
		p3 = TriggerPos - 10
		p4 = TriggerPos - 5
		p5 = p4 + SL 
		
		xp[3]=pnt2x(trace, p3)
		xp[4]=pnt2x(trace, p4)
		xp[5]=pnt2x(trace, p5)
	
		sumlimits[p3]=trace[p3]
		sumlimits[p4]=trace[p4]	//E1 begin
		sumlimits[p5]=trace[p5]	// E1 end	
	endif
		
End

Function ComputeE_Integrator()
	Nvar SL = SL
	Nvar SG =SG
	Nvar Tau
	Nvar DeltaT
	Nvar SkipInitialPoints
	Nvar PSAchannel
	
	
	Nvar TriggerPos = root:TriggerPos
	Wave xp=xp
	Wave sumlimits=root:sumlimits

	Svar dgfpath 
	Wave trace =  $(dgfpath+"trace"+num2str(PSAchannel))
	Nvar ChosenEvent = $(dgfpath+"ChosenEvent")	


	// Calculate energy filter coefficients
	Variable off, E0, E1, energy, baseline, numbases, k, offnew,  b1, x0, x1
	
	b1=	0.003
		
	// Calculate energy
	energy = sum(trace,xp[4],xp[5])
	
	//calculate baselines
	off=TriggerPos - 10
	numbases = floor( (off-SkipInitialPoints) / (SL) )
//	print TriggerPos, numbases
	
	if(numbases == 0)
//		printf "Warning: event # %d w/o baseline\r", ChosenEvent
		energy=0
		baseline = 0
	else
		baseline = 0
		for(k=0; k<numbases; k+=1)
			offnew=off - (SL)*(k+1)
			x0=pnt2x(trace, offnew)
			x1=pnt2x(trace, offnew+SL-1)
			
			baseline += sum(trace,x0,x1) 
			sumlimits[offnew]=trace[offnew]

		endfor
		baseline /= numbases					
	endif
	energy -= baseline
	
	energy *= b1
//	print baseline, energy
	return(energy)
End


Function ComputeE_triggers()
	Nvar SL
	Nvar SG
	Nvar FL
	Nvar FG
	Nvar Threshold 
	Nvar PSAchannel 
	Nvar TriggerPos 	// first trigger in trace after default position
	Nvar defaultTriggerPos
	Nvar RemovePileup	
	Nvar SkipInitialPoints
	
	Nvar RTlow = root:PW:RTlow //= 0.1
	Nvar LB =  root:PW:LB 
	
	Svar dgfpath 
	Wave trace =  $(dgfpath+"trace"+num2str(PSAchannel))
	
	variable k, base, j , ampl, THlevel, off, numTriggers
	variable x0,x1, x2,x3, m
	Variable npnts
	wavestats/q trace
	npnts = V_npnts
	
	if (RemovePileup==0)
		return 0	
	endif

	duplicate/o trace, ff
	duplicate/o trace, RTlimits
	Wave ff
	Wave triggers
	triggers = nan
	Wave RTlimits
	RTlimits = nan
	
	// compute fast filter
	off=2*FL+FG-1
	ff=0
	k=off
	do
		x0=pnt2x(trace,k+FL+FG-off)
		x1=pnt2x(trace,k+FG+2*FL-1-off)
		x2=pnt2x(trace,k-off)
		x3=pnt2x(trace,k+FL-1-off)
		ff[k]=sum(trace,x0,x1)-sum(trace,x2,x3)
		k+=1
	while(k<npnts)
	ff/=FL
	
	// find triggers
	k=SkipInitialPoints
	m=0
	numTriggers = 0
	do
		if( ff[k] > Threshold) 
			numTriggers += 1
			triggers[m]= floor(k	-FL/2	)	
			RTlimits[triggers[m]] = trace[triggers[m]]
			m+=1
			// loop until ff[k] lower than TriggerThreshold again
			do
				k += 1
			while( (ff[k] > (Threshold-10)) && (k < (npnts-(2*FL+FG))))
		else
			k += 1
		endif	
				
	while(k < (npnts-(2*FL+FG)))
	
	// check for pileup
	Wave piledup
	piledup=0
	Variable prevTrig
	prevTrig = triggers[0]
	for (m=1;m<numTriggers; m+=1)
		if( (triggers[m]-prevTrig) < (SL +SG) )		// if too close to prev, both are bad
			piledup[m] = 1
			piledup[m-1]=1
		endif
	endfor
	
	//look for best trigger
//	TriggerPos = nan
//	for (m=0;m<numTriggers; m+=1)
//		if( (triggers[m]-defaultTriggerPos) < (SL/2) )		// find trigger within SL/2 of expectation
//		if(piledup[m]==0)
//			TriggerPos = triggers[m]	-1
//		endif
//		endif
//	endfor
	
	// take first trigger
	TriggerPos = triggers[0]	-1
	
	return (numTriggers)


End



//*********************************************************************************

Function XIA_SlowTraces(Numblocks, filename)
Variable Numblocks
String filename
	
	Svar dgfpath 
	Nvar ChosenModule = $(dgfpath+"ChosenModule")
	Wave MemoryValues = $(dgfpath+"MemoryValues")
	Variable runtype, k, csr, WCR, filenum
	String Outputfilename, ErrMSG
	
	runtype=24
	make/u/i/o/n=4096 buffer
	make/u/i/o/n=1 dummy
	
	dummy[0] = Numblocks
	
	// create output file
	Open/P=EventPath filenum as filename
	PathInfo EventPath

	if(filenum == 0)
		sprintf ErrMSG, "Error: can not open file %s\r", filename
		 DoAlert 0,ErrMSG
		 return(-1)
	else
		close filenum
	endif
	OutputFileName = S_Path + filename
	OutputFileName = Pixie_FileNameConversion(OutputFileName)
	Pixie4_Acquire_Data(24, dummy, OutputFileName, ChosenModule)

End


//########################################################################
//
//	Wait N seconds, reacts quickly to abort
//
//########################################################################
Function Wait(N)
Variable N

	variable refnum,count,m
	
	N*=1e6
	count=0
	m=stopMsTimer(0)
	do
		refnum=startmstimer
		m=0
		do
			m+=1
		while(m<1e3)
		count+=stopMStimer(refnum)
	while(count<N)
	return(count/1e6)

End




// *******************************************************************************************
// A function to parse IFM files from a series of runs, extracting
// total run time, live time, number of events, number of triggers and 
// lists of ICR, OCR, run times, live times
//
// basename: path and file basename, e.g. "C:XIA:Pixie4:testfile" for files named "testfile####.ifm"
// von: starting run number
// bis: ending run number (inclusive)
// *******************************************************************************************

Function FileSeries_ParseIFM(basename,von,bis)
String basename
Variable von,bis
	Svar dgfpath 
	Nvar NumberOfModules = $(dgfpath+"NumberOfModules")
	Nvar NumberOfChannels = $(dgfpath+"NumberOfChannels")
	
	Variable filenum,i,k,index0, index1, index2, index3,len,m, w, j
	String filename,wav, line, text, StartTime, StopTime
	Variable Mnum, Chnum, RT, LT, ER, ICR, NumberMod
	
	Make/o/n=18  root:results:RT_tot, root:results:NEv_tot
	Make/o/n=(18,4)  root:results:LT_tot, root:results:NTg_tot
	Wave RT_tot = root:results:RT_tot
	Wave NEv_tot = root:results:Nev_tot
	Wave LT_tot = root:results:LT_tot
	Wave NTg_tot = root:results:NTg_tot
	RT_tot =0
	NEv_tot =0
	LT_tot =0
	NTg_tot =0
	
	Variable numfiles
	numfiles = bis-von+1
	make/o/n=(numfiles,18) root:results:OCRs, root:results:RunTimes
	make/o/n=(numfiles,4,18) root:results:ICRs, root:results:LiveTimes
	Wave OCRs = root:results:OCRs
	Wave RunTimes = root:results:RunTimes
	Wave ICRs = root:results:ICRs
	Wave LiveTimes = root:results:LiveTimes
	OCRs = 0
	Runtimes = 0
	ICRs = 0
	LiveTimes = 0
	
	j=0
	
	for(w=von; w<=bis;w+=1)
		sprintf filename, "%s%04d.ifm", basename, w
		print filename		
		
		if (cmpstr(filename,"")!=0)		// if file defined succesfully
			Open/R/Z/T="????" filenum as filename 
			
			FReadline filenum, line
			if (cmpstr(line[0,8], "XIA Pixie") !=0)
				DoAlert 0, "Not a valid .ifm file, exiting"
				close/a
				return (0)
			endif
			
			FReadline filenum, line
			len = strlen(line)
			StartTime = line[23,len-2]
			print StartTime
			
			FReadline filenum, line
			len = strlen(line)
			StopTime = line[11,len-2]
			print StopTime
			
			
			FReadline filenum, line	//blank
			FReadline filenum, line
			sscanf line, "Number of Modules: %d\r", NumberMod
			FReadline filenum, line	//module header
			k=0
			do
				FReadline filenum, line
				sscanf line, "%d %g %g", Mnum, RT, ER
				RT_tot[k] += RT
				NEv_tot[k] += ER*RT
				RunTimes[j][k] = RT
				OCRs[j][k] = ER		
				k+=1
			while (k<NumberMod)
			
			FReadline filenum, line	//blank
			FReadline filenum, line	//channel header
			k=0
			do
				for(i=0;i<NumberOfChannels;i+=1)
					FReadline filenum, line
					sscanf line, "%d %d %g %g", Mnum, Chnum, LT, ICR
					LT_tot[k][i] +=LT
					NTg_tot[k][i] +=ICR*LT
					LiveTimes[j][i][k] = LT
					ICRs[j][i][k] = ICR
				endfor
				k+=1
			while (k<NumberMod)
			close filenum
			
		else		// if file opened not successfully
			printf "Parse_IFM: open statistics file failed, skipping ...\r" 
			
		endif
		
		
		j+=1
	endfor
	
	DoWindow/F ModTotals
	if (V_flag==0)
		edit/K=1/W=(500,20,665,350) RT_tot, NEv_tot as "Total RT, # Events by Module"
		DoWindow/C ModTotals
		ModifyTable width(Point)=20,width(:results:RT_tot)=50
		ModifyTable width(:results:NEv_tot)=70, sigDigits(:results:NEv_tot)=9,format(:results:NEv_tot)=2
	endif
	
	DoWindow/F ModList1
	if (V_flag==0)
		edit/K=1/W=(20,200,420,600) RunTimes as "RT by file and module"
		DoWindow/C ModList1
		ModifyTable width(Point)=20,width(:results:RunTimes)=50
	endif
	
	DoWindow/F ModList2
	if (V_flag==0)
		edit/K=1/W=(40,220,440,620) OCRs as "OCR by file and module"
		DoWindow/C ModList2
		ModifyTable width(Point)=20
		ModifyTable width(:results:OCRs)=50
	endif
	
	DoWindow/F ChanTotals1
	if (V_flag==0)
		edit/K=1/W=(680,20,930,350) LT_tot as "LT totals by chan/mod"
		DoWindow/C ChanTotals1
		ModifyTable width(Point)=20,width(:results:LT_tot)=50
	endif
	
	DoWindow/F ChanTotals2
	if (V_flag==0)
		edit/K=1/W=(750,40,1100,400) NTg_tot as "# Trigger totals by chan/mod"
		DoWindow/C ChanTotals2
		ModifyTable width(Point)=20
		ModifyTable width(:results:NTg_tot)=70, sigDigits(:results:NTg_tot)=9,format(:results:NTg_tot)=2
	endif
	
End	

Function FitMultiplePeaks(ch)
Variable ch	//0-3 for ch0-3, 4=all, 5=sum

	// wave declarations
	Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
	Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
	Wave MCAFitRange=root:pixie4:MCAFitRange
	Wave MCAChannelPeakPos=root:pixie4:MCAChannelPeakPos
	Wave MCAChannelPeakEnergy=root:pixie4:MCAChannelPeakEnergy
	Wave MCAChannelFWHMPercent=root:pixie4:MCAChannelFWHMPercent
	Wave MCAChannelFWHMAbsolute=root:pixie4:MCAChannelFWHMAbsolute
	Wave MCAChannelPeakArea=root:pixie4:MCAChannelPeakArea
	Wave dcp = root:pixie4:Display_channel_parameters
	Nvar MCAfitOption =  root:pixie4:MCAfitOption
	
	Nvar RunNumber =  root:pixie4:RunNumber
	
	// position definitions - edit
	Variable Npeaks = 8
	Make/o/n=(Npeaks) xstart, xend, Eres
	wave xstart
	wave xend
	xstart = {1327,655, 338, 117, 87, 39.5, 29, 20}
	xend = {1337,669, 350, 127, 91, 44, 36, 25.6}
	MCAfitOption=4
	
	Variable k
	DoWindow/F MCASpectrumDisplay
	
	for(k=0;k<Npeaks;k+=1)
		cursor A, MCAch0, xstart[k]
		cursor B, MCAch0, xend[k]
		setaxis/W=MCASpectrumDisplay bottom, xstart[k]*0.6, xend[k]*1.4
		
		Pixie_Math_GaussFit("GaussFitMCA",ch+1,"") 
		sleep/t 30
		Eres[k] = MCAChannelFWHMPercent[ch]
	endfor
	print RunNumber-1, dcp[27], Eres


	


End

Function PSA_shiftCsI()

	wave P500e_CsIgamma
	variable m
	// adjust for trigger offset
	wavestats/q P500e_CsIgamma
	Variable toff = 16
	for(m=V_npnts;m>=toff;m-=1)
		P500e_CsIgamma[m] = P500e_CsIgamma[m-toff]
	endfor

End


