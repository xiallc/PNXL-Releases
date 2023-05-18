#pragma rtGlobals=1		// Use modern global access method.
//#include ":Time_Analysis"

Function PSA_Globals()
	// called from Pixie_InitGlobals. Use to define and create global variables

	
	// add additional user global variables below
	NewDataFolder/O root:PW

	// constants
	Variable/G  root:PW:PWrecordlength =8 //= 8 // number of PSA return values per channel, incl. energy but not NchanDat 
	
	//  processing variables and options
	Variable/G  root:PW:maxevents = 1000
	Variable/G  root:PW:PWchannel = 0		// channel to be analyzed
	Variable/G root:PW:Nevents 		      		// number of events 
	Variable/G  root:PW:oldNevents = 0			// remember previous number of events
	Variable/G root:PW:source = 0
	Variable/G root:PW:PSAoption = 0			// 0: Q0/Q1; 1: (Q0-Q1)/Q1
	Variable/G root:PW:Q1startoption = 1		// relative to high or low threshold
	Variable/G root:PW:PSAdiv8 = 0 			// divide result by 8
	Variable/G root:PW:PSAletrig =1			// use leading edge trigger
	Variable/G root:PW:PSAth = 40			// trigger threshold in % (CFD) or ADC steps (LE)
	Variable/G root:PW:CFDoffset = 276		// offset correcting for Igor counting from start of trace vs FPGA counting from trigger
	Variable/G root:PW:CompDSP2Igor =0		// go into debug mode when reading/computing PSA values for comarison between DSP/FPGA and Igor
	Variable/G  root:PW:Allchannels =0			// loop over all channels and modules when processing file(s)
//	Variable/G root:PW:ALMproc3 =1			// variables for radio button to switch between AutoLMprocess 3 or 5
//	Variable/G root:PW:ALMproc5 =0
	Variable/G root:user:AWEpanels =0

	
	// Run statistics
	String/G root:PW:IFMStartTime
	String/G root:PW:IFMStopTime
	Make/o/n=18  root:PW:RT_tot, root:PW:Nev_tot
	Make/o/n=(18,4)  root:PW:LT_tot, root:PW:Ntrig_tot
	Make/o/n=18  root:PW:RT_ifm, root:PW:Nev_ifm
	Make/o/n=(18,4) root:PW:LT_ifm, root:PW:Ntrig_ifm
	
	//Igor "acquisition parameters" when computing PSA values from traces
	Variable/G root:PW:LoQ1 //= 12 // length of sum P and its baseline
	Variable/G root:PW:LoQ0 //= 12 // length of sum C and its baseline
	Variable/G root:PW:SoQ1 //= 0	// starting point of P relative to 10% or 90% level
	Variable/G root:PW:SoQ0 //= 24	// starting point of C relative to 10% level	
	Variable/G root:PW:RTlow = 0.1	// fraction for rise time and CFD
	Variable/G root:PW:RThigh =0.9
	
	//Igor "acquisition parameters" when computing CFD values from traces (P16 style)
	Variable/G root:PW:CFD_FL
	Variable/G root:PW:CFD_FG
	Variable/G root:PW:CFD_scale
	Variable/G root:PW:CFD_delay
	Variable/G root:PW:CFD_threshold
	
	
	// names for waves in configurable plots
	String/G  root:PW:destwavenamex = "energy"
	String/G  root:PW:destwavenamey = "PSAval"
	String/G  root:PW:destwavenamez = "Ratio0"
	String/G  root:PW:destwavenameN0 = "Q0sm"
	String/G  root:PW:destwavenameD0 = "energy"
	String/G  root:PW:destwavenameN1 = "Q1sm"
	String/G  root:PW:destwavenameD1 = "energy"
	
	PW_process_makethewaves(1)	// makes waves for the event result parameters
	
	// histograms
	Variable/G root:PW:nbins =256
	Nvar nbins = root:PW:nbins
	make/o/n=(nbins) root:PW:RT_histo			// waves for histograms
	make/o/n=(nbins) root:PW:Q0_histo
	make/o/n=(nbins) root:PW:Q1_histo
	make/o/n=(nbins) root:PW:Bsm_histo
	make/o/n=(nbins) root:PW:PSAval_histo
	make/o/n=(nbins) root:PW:Ratio0_histo
	make/o/n=(nbins) root:PW:Ratio1_histo
	make/o/n=(nbins) root:PW:amp_histo
	make/o/n=(nbins*nbins) x2D, y2D, z2D
	Variable/G root:PW:scalex = (nbins)
	Variable/G root:PW:scaley = (nbins)
	Variable/G root:PW:offx = 0
	Variable/G root:PW:offy = 0
	
	// a dummy wave
	make/o/n=1 root:pixie4:dummy
	
	// event values and names
	make/d/o/n=49 root:PW:Eventvalues
	make/t/o/n=49 root:PW:EventvalueNames

End

Function PSAHistoCut(TH)
Variable TH
	Wave energy =root:PW:energy
	//Wave Ratio0 =root:PW:Ratio0
	Wave Ratio0 =root:PW:PSAval
	
	Variable Nevents, m
	make/o/n=1 root:PW:Ratio0_cut_histo
	
	duplicate/o Ratio0, Ratio0_cut
	wavestats/q Ratio0
	Nevents = V_npnts
	for(m=0;m<Nevents;m+=1)
		if(energy[m] < TH)
			Ratio0_cut[m] = -0.2
		endif
	endfor	
	
	histogram/B={-0.2,0.002,1024} Ratio0_cut,  root:PW:Ratio0_cut_histo
	//histogram/B={0,1,16384} Ratio0_cut,  root:PW:Ratio0_cut_histo
	Wave Ratio0_cut_histo = root:PW:Ratio0_cut_histo
	Ratio0_cut_histo[0] = 0


End

// Function to fit double peak of distribution and compute figure of merit (diff peaks / sum widths)
// need to check quality of fit; in particular avoid those with "vertical ends" of the Gaussian
Function FoM(wavname)
String wavname		// e.g. "Histo_4_40_0_32"

	Wave histo = $(wavname)
	Wave W_coef
	
	variable zerop, width1, pos1, width2, pos2
	zerop = x2pnt(histo,-0.04)
	//zerop = x2pnt(histo,100)
	
	CurveFit/q/NTHR=0 gauss histo[zerop,pcsr(A)] /D 
	width1 = W_coef[3]*2*sqrt(ln(2))
	pos1 = W_coef[2]
	sleep/T 80
	
	CurveFit/q/NTHR=0 gauss histo[pcsr(A),pcsr(B)] /D 
	width2 = W_coef[3]*2*sqrt(ln(2))
	pos2 = W_coef[2]
	
	print "FoM", (pos2-pos1) / (width1+width2)
	
	


End

Proc SaveOnline1xLE()
	// 1, process file in offline mode 1xLE
	
	// 2, save results
//	duplicate/o root:PW:Q0sm, Q0_offline1xLE
//	duplicate/o root:PW:Q1sm, Q1_offline1xLE
//	duplicate/o root:PW:Amp, A_offline1xLE
//	duplicate/o root:PW:Bsm, B_offline1xLE
//	duplicate/o root:PW:PSAval, R_offline1xLE
	
	// 3 process file in other mode
	
	// 4 copy "other" mode to online waves
	duplicate/o root:PW:Q0sm, root:PW:channel
	duplicate/o root:PW:Q1sm, root:PW:rt
	duplicate/o root:PW:Amp, root:PW:ratio0
	duplicate/o root:PW:Bsm, root:PW:TrigTime
	duplicate/o root:PW:PSAval, root:PW:ratio1
	
	// 5  copy 1xLE results back into offline waves
	duplicate/o Q0_offline1xLE, root:PW:Q0sm
	duplicate/o Q1_offline1xLE, root:PW:Q1sm
	duplicate/o A_offline1xLE, root:PW:Amp
	duplicate/o B_offline1xLE, root:PW:Bsm
	duplicate/o R_offline1xLE, root:PW:PSAval
	
	// 6 multiply ratio by 1000 to make look like from online
	 root:PW:ratio1 *= 1000
	 
	 // 7 run the comparison
	 CompareDSP2Igor(0)

	
End

Function ScanPSApar()

	Nvar source = root:PW:source
	Nvar LoQ1 = root:PW:LoQ1 // = 12 // length of sum Q1 and its baseline
	Nvar LoQ0 = root:PW:LoQ0 // = 12 // length of sum Q0	 and its baseline
	Nvar SoQ1 = root:PW:SoQ1 // = 0	// starting point of Q1 relative to high or low RT level
	Nvar SoQ0 =root:PW:SoQ0 //= 24	// starting point of Q0 relative to low RT level

	
	Variable strt
	source = 1
	
//	for(strt = 4; strt <= 24;strt+=4)
//		LoQ0 = strt
//		PW_file_getPSAdata()
//		histogram/B={-0.1,0.004,1024} root:PW:Ratio1,  root:PW:Ratio1_histo
//		duplicate/o  root:PW:Ratio1_histo, $("histo_"+num2str(strt)+"_48_0_32")
//	endfor
	
	for(strt = 8; strt <= 48;strt+=8)
		SoQ1 = strt
		PW_file_getPSAdata()
		histogram/B={-0.1,0.004,1024} root:PW:Ratio1,  root:PW:Ratio1_histo
		duplicate/o  root:PW:Ratio1_histo, $("histo_12_64_0_"+num2str(strt))
	endfor

//	for(strt = 8; strt <= 104;strt+=8)
//		LoQ1 = strt
//		PW_file_getPSAdata()
//		histogram/B={-0.1,0.004,1024} root:PW:Ratio1,  root:PW:Ratio1_histo
//		duplicate/o  root:PW:Ratio1_histo, $("histo_12_"+num2str(strt)+"_0_32")
//	endfor
	

	
	
	source = 0

End


Proc CheckDiffHistos()
	print "+/- 1% fraction"
	variable range=1
	print "Q0' diff:" ,sum(root:PW:histo_DiffQ0,-range,range)/root:PW:nevents
	print "Q1' diff:" ,sum(root:PW:histo_DiffQ1,-range,range)/root:PW:nevents
	print "Ampl diff:" ,sum(root:PW:histo_DiffAmpl,-range,range)/root:PW:nevents
	print "Base diff:" ,sum(root:PW:histo_DiffBase,-range,range)/root:PW:nevents
	print "Ratio diff:" ,sum(root:PW:histo_DiffRatio,-range,range)/root:PW:nevents
	
	print "+/- 2% fraction"
	range=2
	print "Q0' diff:" ,sum(root:PW:histo_DiffQ0,-range,range)/root:PW:nevents
	print "Q1' diff:" ,sum(root:PW:histo_DiffQ1,-range,range)/root:PW:nevents
	print "Ampl diff:" ,sum(root:PW:histo_DiffAmpl,-range,range)/root:PW:nevents
	print "Base diff:" ,sum(root:PW:histo_DiffBase,-range,range)/root:PW:nevents
	print "Ratio diff:" ,sum(root:PW:histo_DiffRatio,-range,range)/root:PW:nevents
	
	print "+/- 10% fraction"
	range=10
	print "Q0' diff:" ,sum(root:PW:histo_DiffQ0,-range,range)/root:PW:nevents
	print "Q1' diff:" ,sum(root:PW:histo_DiffQ1,-range,range)/root:PW:nevents
	print "Ampl diff:" ,sum(root:PW:histo_DiffAmpl,-range,range)/root:PW:nevents
	print "Base diff:" ,sum(root:PW:histo_DiffBase,-range,range)/root:PW:nevents
	print "Ratio diff:" ,sum(root:PW:histo_DiffRatio,-range,range)/root:PW:nevents
	

End

Window Graph0() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(529.5,335.75,1050,659) :PW:Ratio0_histo,histo_SoQ1_8,histo_SoQ1_16,histo_SoQ1_40
	AppendToGraph histo_SoQ1_48,histo_SoQ1_32,histo_SoQ1_24
	ModifyGraph lSize(histo_SoQ1_8)=2,lSize(histo_SoQ1_16)=2,lSize(histo_SoQ1_40)=2
	ModifyGraph lSize(histo_SoQ1_48)=2,lSize(histo_SoQ1_32)=2,lSize(histo_SoQ1_24)=2
	ModifyGraph rgb(Ratio0_histo)=(0,0,0),rgb(histo_SoQ1_8)=(65280,0,0),rgb(histo_SoQ1_16)=(65280,43520,0)
	ModifyGraph rgb(histo_SoQ1_40)=(0,15872,65280),rgb(histo_SoQ1_48)=(29440,0,58880)
	ModifyGraph rgb(histo_SoQ1_32)=(0,52224,52224),rgb(histo_SoQ1_24)=(26112,52224,0)
	SetAxis bottom -0.0892182741116751,0.353908629441624
	Legend/C/N=text0/J/A=MC/X=38.27/Y=23.22 "\\s(Ratio0_histo) Ratio0_histo\r\\s(histo_SoQ1_8) histo_SoQ1_8\r\\s(histo_SoQ1_16) histo_SoQ1_16"
	AppendText "\\s(histo_SoQ1_24) histo_SoQ1_24\r\\s(histo_SoQ1_32) histo_SoQ1_32\r\\s(histo_SoQ1_40) histo_SoQ1_40\r\\s(histo_SoQ1_48) histo_SoQ1_48"
	TextBox/C/N=text1/F=0/A=MC/X=21.83/Y=30.03 "LoQ0: 20 \rLoQ1: 40\rSoQ0:  0"
EndMacro

Function SaveD2Icomphistos()

	save/t  root:PW:histo_Q1Q0_DSP, root:PW:histo_Q1Q0_DSPIgor, root:PW:histo_Q1Q0_Igor
	
	save/t 	 root:PW:histo_DiffQ0,  root:PW:histo_DiffQ1, root:PW:histo_DiffAmpl, root:PW:histo_DiffBase, root:PW:histo_DiffRatio
	
End



Function PSA_repeat_process(basename,von,bis, new)	// process consecutive files, record each peak position, dE, runstats
String basename
Variable von,bis, new


	Svar datafile = root:pixie4:DataFile
	String filename
	Variable k, numfiles
	
	numfiles = bis+1	
	
	// Waves to store run statistics
	make/o/n=(numfiles) root:PW:OCRs,  root:PW:RunTimes,  root:PW:fileNo	
	make/o/n=(numfiles)  root:PW:StartTimes, root:PW:LiveTimes3
	make/o/n=1024 root:PW:allPSAval_histo	
	
	Wave OCRs =  root:PW:OCRs
	Wave fileNo =  root:PW:fileNo
	Wave RunTimes = root:PW:RunTimes
	Wave StartTimes = root:PW:StartTimes
	Wave LiveTimes3 = root:PW:LiveTimes3
	Wave  allPSAval_histo	=  root:PW:allPSAval_histo	
	
	if(new)
		OCRs=0
		RunTimes=0
		StartTimes=nan
		LiveTimes3=0
		Generate2DMCA(0)					// clear MCA
		allPSAval_histo = 0
		DoUpdate
	endif
	fileNo = p
	
	
	Nvar source = root:PW:source
	Nvar Allchannels = root:PW:Allchannels
	source = 0	
	
	
	// variables and waves for run statistics
	Svar FirstStartTime = root:PW:FirstStartTime
	Svar LastStopTime = root:PW:LastStopTime
	Svar IFMStartTime = root:PW:IFMStartTime
	Svar IFMStopTime = root:PW:IFMStopTime
	Nvar PWchannel = root:PW:PWchannel
	
	Wave RT_tot =  root:PW:RT_tot
	Wave Nev_tot =  root:PW:Nev_tot
	Wave LT_tot =  root:PW:LT_tot
	Wave Ntrig_tot =  root:PW:Ntrig_tot
	Wave RT_ifm =  root:PW:RT_ifm
	Wave Nev_ifm =  root:PW:Nev_ifm
	Wave LT_ifm =  root:PW:LT_ifm
	Wave Ntrig_ifm =  root:PW:Ntrig_ifm
	if(new)
		RT_tot =  0
		Nev_tot = 0
		LT_tot =  0
		Ntrig_tot = 0
	endif
	
		
	Variable filenum,i,len,m, j

	// now start the loop over files	
	for(j=von;j<=bis;j+=1)
	
		//1. process list mode data and add to cumulative spectra 
		sprintf filename, "%s%04d.b00", basename, j
		datafile = filename
	//	print filename		
	//	Pixie_Ctrl_CommonSetVariable("TraceDataFile",0,"","")
			
								// process
		if(Allchannels)
			//Pixie_Ctrl_CommonSetVariable("TraceDataFile",0,"","")
			PW_process_allchannels()
			//print "not tested yet in all channel mode"
		else
			Pixie_Ctrl_CommonSetVariable("TraceDataFile",0,"","")
			PW_file_getPSAdata()
		endif
		
		Generate2DMCA(1)										// append to MCA
		histogram/A/B={0,4,16384} root:PW:PSAval,  root:PW:allPSAval_histo		// histogram the PSA value
		DoUpdate
			
		
		//2. extract run information from .ifm file previously read

			if(j==von)
				FirstStartTime = IFMStartTime
			endif
			StartTimes[j] = (TimeDate2secs(IFMStartTime) - 3.26e9)/3600 - 2220		// in hours since July 23, 2007
			
			if(j==bis)
				LastStopTime = IFMStopTime
			endif

			RT_tot += RT_ifm
			Nev_tot += Nev_ifm
			RunTimes[j] = RT_ifm[0]			// assume always module 0
			OCRs[j] = Nev_ifm[0]/RT_ifm[0]		// assume always module 0
			
			LT_tot += LT_ifm
			Ntrig_tot += Ntrig_ifm	
			LiveTimes3[j] = LT_ifm[0][PWchannel] 	// assume always module 0, but channel can vary

	endfor

	print " "
	print "Total Runtime", sum(RunTimes),"s ;  Livetime", sum(LiveTimes3),"s"
	
End 

Function TimeDate2secs(datestring)	// converts a string created by Igor >> time()+" "+date() << into seconds from 1904
String datestring
	
	variable len, ret,k, dateinsec
	variable hour, minute, sec, year, month, day
	string  datum, text
	sscanf datestring, "%d:%d:%d", hour, minute, sec
	ret = strsearch(datestring,"PM",0)	
	if ((ret>0) & (hour !=12) )
		hour+=12
	endif
	ret = strsearch(datestring,"AM",0)	
	if ((ret>0) & (hour ==12) )
		hour-=12
	endif
	//print hour, minute, sec
	
	
	len = strlen(datestring)
	year = str2num(datestring[len-5,len-1])
	
	ret = strsearch(datestring,",",len-1,1)	// find last comma (after day)
	text = datestring[ret-2,len-1]
	day = str2num(text)
	for(k=1;k<13;k+=1)
		switch(k)	// numeric switch
			case 1:		// execute if case matches expression
				text = "Jan"
				break					// exit from switch
			case 2:		// execute if case matches expression
				text = "Feb"
				break					// exit from switch
			case 3:		// execute if case matches expression
				text = "Mar"
				break					// exit from switch
			case 4:		// execute if case matches expression
				text = "Apr"
				break					// exit from switch
			case 5:		// execute if case matches expression
				text = "May"
				break					// exit from switch
			case 6:		// execute if case matches expression
				text = "Jun"
				break					// exit from switch
			case 7:		// execute if case matches expression
				text = "Jul"
				break					// exit from switch
			case 8:		// execute if case matches expression
				text = "Aug"
				break					// exit from switch
			case 9:		// execute if case matches expression
				text = "Sep"
				break					// exit from switch
			case 10:		// execute if case matches expression
				text = "Oct"
				break					// exit from switch
			case 11:		// execute if case matches expression
				text = "Nov"
				break					// exit from switch
			case 12:		// execute if case matches expression
				text = "Dec"
				break					// exit from switch
			default:							// optional default expression executed
				print "bad month"					// when no case matches
		endswitch
 		ret = strsearch(datestring,text,0,2)	// find month
		if (ret>0)
			month= k
		endif
	endfor
	//print day, month, year
	dateinsec = date2secs(year,month,day) + 3600*hour + 60*minute + sec
	
	//print dateinsec
	return (dateinsec)
	

End






Function PSA_ReadEvent()
	//called when changing event number in list mode trace display or digital filter display
	
	
	if(0)	// only execute when necessary	
		//duplicate traces and list mode data
		Wave trace0 =  root:pixie4:trace0
		Duplicate/o trace0, root:results:trace0
		Wave trace1 =  root:pixie4:trace1
		Duplicate/o trace1, root:results:trace1
		Wave trace2 =  root:pixie4:trace2
		Duplicate/o trace2, root:results:trace2
		Wave trace3 =  root:pixie4:trace3
		Duplicate/o trace3, root:results:trace3
		Wave eventposlen =  root:pixie4:eventposlen
		Duplicate/o eventposlen, root:results:eventposlen
		Wave eventwave =  root:pixie4:eventwave
		Duplicate/o eventwave, root:results:eventwave
	endif
	
	//add custom code below
	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
	Wave ListModeChannelTrigger=root:pixie4:ListModeChannelTrigger
	Wave ListModeChannelXIA=root:pixie4:ListModeChannelXIA
	Wave ListModeChannelUser=root:pixie4:ListModeChannelUser
	
	Nvar Allchannels = root:PW:Allchannels 

	Nvar runtype = root:pixie4:runtype
	Nvar PWchannel = root:PW:PWchannel
	Nvar ChosenEvent = root:pixie4:ChosenEvent	
	Nvar ChosenChannel = root:pixie4:ChosenChannel		// selected channel 0-3
	Nvar LMeventChannel = root:pixie4:LMeventChannel		// actual channel reported 0-15 (31?)
	
	// PSA input parameters
	Nvar LoQ1 = root:PW:LoQ1 // = 12 // length of sum Q1 and its baseline
	Nvar LoQ0 = root:PW:LoQ0 // = 12 // length of sum Q0	 and its baseline
	Nvar SoQ1 = root:PW:SoQ1 // = 0	// starting point of Q1 relative to high or low RT level
	Nvar SoQ0 = root:PW:SoQ0 //= 24	// starting point of Q0 relative to low RT level
	Nvar RTlow = root:PW:RTlow //= 0.1
	Nvar RThigh = root:PW:RThigh //=0.9	
	Nvar PSAoption = root:PW:PSAoption			// 0: Q1/Q0; 1: (Q1-Q0)/Q0
	Nvar Q1startoption = root:PW:Q1startoption			// relative to high or low threshold
	Nvar PSAdiv8 = root:PW:PSAdiv8  			// divide result by 8
	Nvar PSAletrig = root:PW:PSAletrig			// use leading edge trigger
	Nvar PSAth = root:PW:PSAth 		// trigger threshold in % (CFD) or ADC steps (LE)
	Nvar CFDoffset = root:PW:CFDoffset
	Variable ADCClockMHz = 250
	
	Nvar CFD_FL =  root:PW:CFD_FL
	Nvar CFD_FG = root:PW:CFD_FG
	Nvar CFD_scale = root:PW:CFD_scale
	Nvar CFD_delay = root:PW:CFD_delay
	Nvar CFD_threshold = root:PW:CFD_threshold

	// scale as in FPGA
	Variable normQ0, normQ1
	if(PSAdiv8)
		normQ0 = 32//2^( floor(log(LoQ0)/log(2) )) 
		normQ1 = 32//2^( floor(log(LoQ1)/log(2) ))		
	else
		normQ0 = 4//2^( floor(log(LoQ0)/log(2) )) 
		normQ1 = 4//2^( floor(log(LoQ1)/log(2) ))		
	endif


	wave dummy = root:pixie4:dummy
	
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
	
	Wave Eventvalues = root:PW:Eventvalues		// wave of return values for this event
	Eventvalues =0
	wave/t EventvalueNames = root:PW:EventvalueNames
	EventvalueNames = ""
	EventvalueNames[0] = "energy (DSP/ARM/FPGA)"
	EventvalueNames[1] = "rise time or CFD time (DSP/FPGA)"				// UserRetVal +0
	EventvalueNames[2] = "amplitude (DSP/FPGA)"							// UserRetVal +1
	EventvalueNames[3] = "baseline (DSP/FPGA)"								// UserRetVal +2
	EventvalueNames[4] = "Q0 sum (DSP/FPGA) baseline subtracted "		// UserRetVal +3
	EventvalueNames[5] = "Q1 sum (DSP/FPGA) baseline subtracted "		// UserRetVal +4
	EventvalueNames[6] = "PSA value (DSP/FPGA)"							// UserRetVal +5
	EventvalueNames[7] = "timestamp (FPGA) "
	EventvalueNames[8] = "channel number "
	EventvalueNames[9] = "   "
	
	EventvalueNames[11] = "rise time (Igor) "							// was 15
	EventvalueNames[12] = "amplitude (Igor) "							// was 18
	EventvalueNames[13] = "baseline (Igor) "							// was 20
	EventvalueNames[14] = "Q0 sum (Igor) baseline subtracted "		// was 16
	EventvalueNames[15] = "Q1 sum (Igor) baseline subtracted "		// was 17
	EventvalueNames[16] = "ratio Q1/Q0 (Igor) "						// was 19
	EventvalueNames[17] = "maximum (Igor) "	
	
	EventvalueNames[20] = "timestamp refined by CFD time  (DSP/FPGA/Igor) "
	EventvalueNames[21] = "timestamp refined by CFD time  (Igor) "
	EventvalueNames[22] = "CFD time fraction (DSP/FPGA) "
	EventvalueNames[23] = "CFD time fraction (Igor) "
	EventvalueNames[24] = "trigger point (Igor) "
	EventvalueNames[25] = "trigger point offset to DSP/FPGA"
	
	// 30-39 debug FPGA/DSP, named in code
	// 40-49 debug Igor, named in code

	

	
	// ********************************************************************************************************
	//  Mode 0: Extract DSP values for "Event Detail"
	// ********************************************************************************************************
	Variable dbgbase = 1	// debug: set base to zero
	Variable cfd, ph	
		
	PWchannel = ChosenChannel	
		
	// Use LM table entries (always valid)	
	Eventvalues[0] = ListModeChannelEnergy[PWchannel]		// energy
	Eventvalues[1] = ListModeChannelXIA[PWchannel]			// rise time or CFD	
	Eventvalues[7] = ListModeChannelTrigger[PWchannel]		// lime stamp LO + MI
	
	
	// for all runtypes
	wave LMeventheader = root:pixie4:LMeventheader
	Eventvalues[2] = LMeventheader[iPSAmax]	// amplitude from DSP       	UserRetVal +1
	Eventvalues[3] = LMeventheader[iPSAbase]	// baseline sum from DSP  	UserRetVal +2
	Eventvalues[4] = LMeventheader[iPSAsum0]	// Q0 sum from DSP				UserRetVal +3
	Eventvalues[5] = LMeventheader[iPSAsum1]	// Q1 sum from DSP				UserRetVal +4
	Eventvalues[8] = LMeventChannel



	// PSA values
	// for run types reporing only raw PSA values, recompute here
	if(iPSAresult<0)
		Eventvalues[2] = LMeventheader[iPSAmax] - LMeventheader[iPSAbase] * dbgbase	// amplitude from DSP       	UserRetVal +1
		Eventvalues[3] = LMeventheader[iPSAbase]	// baseline sum from DSP  	UserRetVal +2
		Eventvalues[4] = LMeventheader[iPSAsum0] - LMeventheader[iPSAbase] * dbgbase*LoQ0/normQ0	// Q0 sum from DSP			UserRetVal +3
		Eventvalues[5] = LMeventheader[iPSAsum1] - LMeventheader[iPSAbase] * dbgbase*LoQ1	/normQ1// Q1 sum from DSP			UserRetVal +4
		Eventvalues[6] = Eventvalues[5] / Eventvalues[4]	// PSA Value  Q1/Q0
	else
		Eventvalues[6] = LMeventheader[iPSAresult]	// PSA Value
	endif
	
	// CFD values
	Eventvalues[30] =  LMeventheader[iCFDinfo]	
	EventvalueNames[30] = "CFD info "	
		
	Eventvalues[31] =  LMeventheader[iCFDsum1] + (0x00FF & LMeventheader[iCFDsum12])*65536
	EventvalueNames[31] = "CFD sum 1 "	
	
	Eventvalues[32] =  (0xFF00 & LMeventheader[iCFDsum12])/256 + LMeventheader[iCFDsum2]*256
	EventvalueNames[32] = "CFD sum 2 "
	
	Eventvalues[33] =  0x1000000 - Eventvalues[32]	// convert to positive	
	EventvalueNames[33] = "CFD sum 2 (positive)"
	
	if(iCFDresult<0)
		ph = Eventvalues[31] / (Eventvalues[31] + Eventvalues[33] )
		Eventvalues[34] = ph
		EventvalueNames[34] = "CFD ratio "
		cfd = ph * 16384
		cfd = cfd & 0x3FFF
		Eventvalues[1] = cfd
	else
		Eventvalues[1] = LMeventheader[iCFDresult] & 0x3FFF	// Rise time or CFD result (without the force and source bits)
	endif

	
	
	
	if(runtype==0x400) 
		wave LMfileheader =  root:pixie4:LMfileheader
		wave LMeventheader = root:pixie4:LMeventheader

		Eventvalues[8] = LMeventheader[9]	  	// channel number
		if(Allchannels)
			PWchannel = Eventvalues[8]	// automatically pick the current channel (won't work for 0x402, 503)
		endif
	
		Eventvalues[2] = LMeventheader[10]	// amplitude from DSP       	UserRetVal +1
		Eventvalues[3] = LMeventheader[12]	// baseline sum from DSP  	UserRetVal +2
		Eventvalues[4] = LMeventheader[13]	// Q0 sum from DSP			UserRetVal +3
		Eventvalues[5] = LMeventheader[14]	// Q1 sum from DSP			UserRetVal +4
		Eventvalues[6] = LMeventheader[15]	// PSA Value
		
		Eventvalues[30] =  LMeventheader[16]	// debug
		EventvalueNames[30] = "debug "		
		Eventvalues[31] =  LMeventheader[17]
		EventvalueNames[31] = "debug "	
		Eventvalues[32] =  LMeventheader[19]	// LMeventheader[19]	// Q0 raw/4
		EventvalueNames[32] = "Q0 raw/4 "
		Eventvalues[33] =  LMeventheader[20]	// Q1 raw/4
		EventvalueNames[33] = "Q1 raw/4 "
	endif
	
	if( (runtype==0x404) )
	
		wave LMfileheader =  root:pixie4:LMfileheader
		wave LMeventheader = root:pixie4:LMeventheader
	
		Eventvalues[8] = LMeventheader[16]	  	// channel number
		if(Allchannels)
			PWchannel = Eventvalues[8]	// automatically pick the current channel (won't work for 0x402, 503)
		endif
		
		Variable base_scaled = LMeventheader[33]
		
		Eventvalues[2] = LMeventheader[34]	- 	base_scaled	// amplitude from DSP      		UserRetVal +1
		Eventvalues[3] = LMeventheader[33] 					// baseline sum from DSP  	UserRetVal +2	
		// for UDP output, values are not BL subtracted. We assume here the "4" is the usual scaling factor, but could be 32
		Eventvalues[4] = 0 //LMeventheader[10+off] - base_scaled*LoQ0/4  // Q0 sum from ARM			UserRetVal +3		
		Eventvalues[5] = 0 //LMeventheader[11+off] - base_scaled*LoQ1/4		
		Eventvalues[6] = 0 //	Eventvalues[4] / Eventvalues[5]	// PSA Value  Q1/Q0
		
		Eventvalues[30] =  LMeventheader[34]	// debug: maximum
		EventvalueNames[30] = "maximum (FPGA)"	
			
		Eventvalues[31] =  LMeventheader[18]* 65536 + LMeventheader[17]
		EventvalueNames[31] = "Q0 full sum (FPGA) "	
		
		Eventvalues[32] =  LMeventheader[20]* 65536 + LMeventheader[19]
		EventvalueNames[32] = "Q1 full sum  (FPGA) "
		
		Eventvalues[33] =  LMeventheader[22]* 65536 + LMeventheader[21]
		EventvalueNames[33] = "Q2 full sum (FPGA) "	
		
		Eventvalues[34] =  LMeventheader[24]* 65536 + LMeventheader[23]
		EventvalueNames[34] = "Q3 full sum  (FPGA) "
		
		Eventvalues[35] =  LMeventheader[36]* 65536 + LMeventheader[35]
		EventvalueNames[35] = "Ext TS  (FPGA) "
		
			
	endif
	
	if( (runtype==0x116) )
	
		wave LMfileheader =  root:pixie4:LMfileheader
		wave LMeventheader = root:pixie4:LMeventheader116

		variable off=0
		if((runtype==0x404) )
			off = 3				// in 0x404, words are shifted down by 3  
		endif

		
		Eventvalues[8] = LMeventheader[0+off] & 0x000F	  	// channel number
		if(Allchannels)
			PWchannel = Eventvalues[8]	// automatically pick the current channel (won't work for 0x402, 503)
		endif
		
		base_scaled = LMeventheader[18+off]
		
	//	Eventvalues[2] = LMeventheader[19+off]	- 	base_scaled	// amplitude from DSP      		UserRetVal +1
	//	Eventvalues[3] = LMeventheader[18+off] 					// baseline sum from DSP  	UserRetVal +2	
	//	// for UDP output, values are not BL subtracted. We assume here the "4" is the usual scaling factor, but could be 32
	//	Eventvalues[4] = 0 //LMeventheader[10+off] - base_scaled*LoQ0/4  // Q0 sum from ARM			UserRetVal +3		
	//	Eventvalues[5] = 0 //LMeventheader[11+off] - base_scaled*LoQ1/4		
	//	Eventvalues[6] = 0 //	Eventvalues[4] / Eventvalues[5]	// PSA Value  Q1/Q0
		
		Eventvalues[30] =  LMeventheader[19+off]	// debug: maximum
		EventvalueNames[30] = "maximum (FPGA)"	
			
		Eventvalues[31] =  LMeventheader[9+off]* 65536 + LMeventheader[8+off]
		EventvalueNames[31] = "Q0 full sum (FPGA) "	
		
		Eventvalues[32] =  LMeventheader[11+off]* 65536 + LMeventheader[10+off]
		EventvalueNames[32] = "Q1 full sum  (FPGA) "
		
		Eventvalues[33] =  LMeventheader[13+off]* 65536 + LMeventheader[12+off]
		EventvalueNames[33] = "Q2 full sum (FPGA) "	
		
		Eventvalues[34] =  LMeventheader[15+off]* 65536 + LMeventheader[14+off]
		EventvalueNames[34] = "Q3 full sum  (FPGA) "
		
		Eventvalues[35] =  LMeventheader[17+off]* 65536 + LMeventheader[16+off]
		EventvalueNames[35] = "Ext TS  (FPGA) "
		
			
	endif
	
	Variable ch
			
	// ********************************************************************************************************		
	//  Mode 1: Compute Igor PSA values for "event Detail" and/or processing
	// ********************************************************************************************************
		
	Wave trace = $("root:pixie4:trace"+num2str(PWchannel))
	
		
	wavestats/q dummy	// to set V_npnts to 1
	wavestats/q/z	trace
	
	if(V_npnts>1)
	
		Variable k,j, base, ampl, Q1sum, Q0sum, RT, lev10, lev90, TL	
		Variable Q1start, Q0start
		Variable LEthreshold = PSAth*1.27*4	// threshold for leading edge (not CFD) trigger, matching DSP/FPGA scaling
	
	
		// ***************  calculate base and amplitude  ***************
		// baseline
		base = 0
		for(j=4;j<4+8;j+=1)
			base+=trace[j]
		endfor
		base=base/8				// in single sample units
		Eventvalues[13] =base	
						
		//find max
		wavestats/q	trace
		TL = V_npnts
		ampl = V_max-base* dbgbase	// optionally set to zero for debug purposes
		Eventvalues[12] =ampl	
		Eventvalues[17] = V_max
			
		// ***************  calculate RiseTime  ***************
		// find 10% level before max, searching back from maximum
		findlevel/q/R=(V_maxloc,0) trace, (base+ampl*RTlow)
		lev10 = V_levelX	//in x units
	
		// find 90% level before max, searching back from maximum
		findlevel/q/R=(V_maxloc,0) trace, (base+ampl*RThigh) 
		lev90 = V_levelX	//in x units
		// compute rise time
		RT = (lev90-lev10) //in s
		//RT = RT *ADCClockMHz*1e6 *16 	// in 1/16 clock cycles
		RT = RT *1e9 	// in ns
		
		Eventvalues[11] = RT

		// *************** compute Q1sum  ***************
		
		Q1start = x2pnt(trace, lev10)		// in points
		//optional: leading edge trigger for Q1
		if(PSAletrig)
			findlevel/p/q trace, (base+LEthreshold)
			Q1start = ceil(V_levelX)	//in points 
			// use ceil here because FPGA picks first sample over threshold.  Findlevel/p reports e.g. point "50.2" so point 51 is over TH
			//	Q1start = ceil(Q1start/4)*4	// for 4 sample granularity
		endif
		Eventvalues[24] = Q1start
		
			
		Q1sum = 0
		for(j=Q1start+SoQ1;j<Q1start+SoQ1+LoQ1;j+=1)
			Q1sum = Q1sum + trace[j] - base* dbgbase	// optionally set to zero for debug purposes  // normal integration
			//Q1sum = Q1sum + 0.5* trace[j] + 0.5* trace[j+1] - base // trapeziod
		endfor
			
		Q1sum /= normQ1
		Eventvalues[15] = Q1sum 
		
		Eventvalues[42] = (Q1sum*normQ1 + (base* dbgbase * LoQ1))
		EventvalueNames[42] = "Q1 full sum (Igor)  "		
		
				
// debug - another instance of base starting near trigger
		//optional: leading edge trigger for P	with fixed threshold of LEthreshold
		findlevel/q/p trace, (base+LEthreshold)
		Q1start = ceil(V_levelX)	//in points
		Q1start = ceil(Q1start/4)*4	// for 4 sample granularity
		
		Q1sum = 0
		for(j=Q1start+SoQ1;j<Q1start+SoQ1+LoQ1;j+=1)
			Q1sum = Q1sum + trace[j] - base* dbgbase	// optionally set to zero for debug purposes // normal integration
			//Q1sum = Q1sum + 0.5* trace[j] + 0.5* trace[j+1] - base // trapeziod
		endfor	
		Q1sum /= normQ1
// end debug
		
		
		// *************** compute Q0sum  ***************
				
		Q0start = x2pnt(trace, lev10)		// in points
		//optional: leading edge trigger for C	with fixed threshold of LEthreshold
		if(PSAletrig)
			findlevel/q/p trace, (base+LEthreshold)
			Q0start = ceil(V_levelX)	//in points
	//		Q0start = ceil(Q0start/4)*4	// for 4 sample granularity
		endif
		
		Q0sum = 0
		for(j=Q0start+SoQ0;j<Q0start+SoQ0+LoQ0;j+=1)
			Q0sum = Q0sum + trace[j] - base * dbgbase	// optionally set to zero for debug purposes		
		endfor
		Q0sum /= normQ0
		Eventvalues[14] = Q0sum
		
		Q0sum = 0
		for(j=Q0start+SoQ0;j<Q0start+SoQ0+LoQ0;j+=1)
			Q0sum = Q0sum + trace[j] 	// always set to zero for debug purposes		
		endfor
		Eventvalues[41] = Q0sum
		EventvalueNames[41] = "Q0 full sum (Igor)  "
		
// debug - another instance of base starting near trigger		
		//optional: leading edge trigger for C	with fixed threshold of LEthreshold
		findlevel/q/p trace, (base+LEthreshold)
		Q0start = ceil(V_levelX)	//in points
	//	Q0start = ceil(Q0start/4)*4	// for 4 sample granularity

		Q0sum = 0
		for(j=Q0start+SoQ0;j<Q0start+SoQ0+LoQ0;j+=1)
			Q0sum = Q0sum + trace[j] - base * dbgbase	// optionally set to zero for debug purposes		
		endfor
		Q0sum /= normQ0
// end debug
		
		Variable shift
		Eventvalues[25] = nan 
		for (shift=-5; shift<=5; shift+=1)
		
			Q0sum = 0
			for(j=Q0start+SoQ0;j<Q0start+SoQ0+LoQ0;j+=1)
				Q0sum = Q0sum + trace[j+shift] 	// always set to zero for debug purposes		
			endfor
			
			if(Q0sum ==Eventvalues[31])
				Eventvalues[25] =shift
			//	print shift
			endif
			
		
		endfor
		
		// *************** compute PSAvalue  ***************
		Eventvalues[16] = Eventvalues[15]/Eventvalues[14]
		
		// *************** compute Q0 sum for every point of the trace  ***************
		duplicate/o trace, QDCintegral
		for(k=0;k<TL-LoQ0;k+=1)
			QDCintegral[k] = 0
			for(j=0; j<LoQ0; j+=1)
				QDCintegral[k] = QDCintegral[k] +trace[k+j]
			endfor
			QDCintegral[k] = QDCintegral[k]/normQ0
		endfor

	
		// *************** compute 50% CFD level  ***************
			
		// Igor compute from trace
		variable cfdlowp, cfdhighp
		variable cfdlow, cfdhigh, cfdlevel, cfdfracI, reltimeI
		cfdlevel = (base+ 0.5*ampl)
		findlevel/q/p trace, cfdlevel
		cfdlowp = floor(V_levelX)
		cfdlow = trace[cfdlowp]
		cfdhighp = ceil(V_levelX)
		cfdhigh = trace[cfdhighp]
		cfdfracI = 1 - (cfdlevel-cfdlow) / (cfdhigh - cfdlow)
		
// 		this code handles P4e CFDs, but needs to know the waveform timescale, not currently supported	
//		//if((wftimescale*1e9)<=5)	// comparison wftimescale == 2e-9 fails!
//		 if (eventwave[1] == 500)
//			// if 500MHz waveforms, cfdtime and offsets are in units of 2ns and also TS is in units of 2ns			
//			reltimeI = (Eventvalues[7] & 0xFFFFFFFF) +43 - cfdhighp - cfdfracI
//		endif
//		if (eventwave[1] == 125)
//			// if 125MHz waveforms, cfdtime and offsets are in units of 8ns but TS is in units of 2ns
//			reltimeI = (Eventvalues[7] & 0xFFFFFFFF) + 4*cfdhighp - 4*cfdfracI -324
//		endif
//		if (eventwave[1] == 250)
			// if 250 MHz waveforms from PN, cfdtime and offsets are in units of 4ns but TS is in units of 1ns
			reltimeI = Eventvalues[7] - 4*cfdfracI  + 4*cfdhighp
//		endif		
		
		
				
		// read from DSP	/FPGA		
		// Eventvalues[1] includes sample offset and fractional part, scaled differently for 125/250/500 MHz
		Variable  cfdticksF, cfdfracF, reltimeF
		//if((wftimescale*1e9)<=5)	// comparison wftimescale == 2e-9 fails!
//		 if (eventwave[1] == 500)
//			cfdfracF = (Eventvalues[1] & 0xFF)/256
//			reltimeF = Eventvalues[7]-Eventvalues[1]/256		
//		endif
//		if (eventwave[1] == 125)
//			cfdfracF = (Eventvalues[1] & 0x3FF)/1024
//			reltimeF = Eventvalues[7]-Eventvalues[1]/256		
//		endif	
//		if (eventwave[1] == 250)
			cfdticksF = floor((Eventvalues[1] & 0xFC00) /256/4)		// timestamp of max in units of 4ns
			cfdfracF =  (Eventvalues[1] & 0x3FF)/256/4
			reltimeF = Eventvalues[7]+ 200 - Eventvalues[1]/256  	
//		endif			
			
		// report		
		//Eventvalues[7] = 0	// debug					
		Eventvalues[20] = reltimeF 				// 10 timestamp refined by CFD time  (DSP/FPGA/Igor)
		Eventvalues[21] = reltimeI - CFDoffset		// 11 timestamp refined by CFD time  (Igor)
		Eventvalues[22] = cfdfracF					// 12 CFD time fraction (DSP/FPGA)
		Eventvalues[23] = cfdfracI					// 13 CFD time fraction (Igor)
	//	ph(Eventvalues[1])
		 
		// debug
		// C code computation
//		Variable ts_max, max_to_cfd, trig_to_max, ts_trig, trig_to_cfd
//		ts_max = Eventvalues[23]				// TS of max (8ns)
//		max_to_cfd = Eventvalues[22]			// time cfd to max (4ns)
//		ts_trig=  (Eventvalues[7] & 0x7F)/8		// lower bits of trigger TS (8ns)
//		trig_to_max =  ts_max - ts_trig			// time trigger to max (8ns)
//		if(trig_to_max < 0)
//		 	trig_to_max = trig_to_max + 16	// handle rollover
//		endif
//		trig_to_cfd = 2* trig_to_max - max_to_cfd // time trigger to cfd (4ns)
		 
		//Eventvalues[24] = cfdticksF
		//Eventvalues[25] = trig_to_cfd
		//Eventvalues[26] = Eventvalues[7] + 200 - 4*trig_to_cfd - 4*cfdfracF	// invalid if TS is set to zero for debug
		 
		
		// *************** compute CFD as in P16 FW ***************
		
		//Igor "acquisition parameters" when computing CFD values from traces (P16 style)
		//Variable/G root:PW:CFD_FL
		//Variable/G root:PW:CFD_FG
		//Variable/G root:PW:CFD_scale
		//Variable/G root:PW:CFD_delay
		//Variable/G root:PW:CFD_threshold
		
		duplicate/o trace, fftrace
		duplicate/o trace, cfdtrace
		//Variable off
		Variable nspc =2 // number of samples per cycle
		Variable arm, latch
		
		// a) fast trigger filter
		off=2*CFD_FL+CFD_FG-1
		fftrace = nan
		k=off
		do
			fftrace[k]=0
			for(j=0;j<CFD_FL*nspc;j+=nspc)
				fftrace[k] -= trace[k+j-off*nspc]
				fftrace[k] += trace[CFD_FL*nspc+CFD_FG*nspc+k+j-off*nspc]
			endfor
			fftrace[k] = fftrace[k]*2
			k+=nspc
		while(k<TL)
		
		// b) delay, scale and subtract
		cfdtrace = nan
		k=off
		arm = 0
		latch =0
		do
			cfdtrace[k] = fftrace[k] * (8-CFD_scale)/8 - fftrace[k-CFD_delay]
			if( (cfdtrace[k]>0) && (cfdtrace[k] > CFD_threshold) )
				arm=1
			endif
			if( (cfdtrace[k]<0) && (arm==1) && (latch==0))
	
				Eventvalues[35] =  cfdtrace[k-nspc]
				EventvalueNames[35] = "Igor CFD val 1 "
				
				Eventvalues[36] =  abs(cfdtrace[k])
				EventvalueNames[36] = "Igor CFD val 2 (positive) "
				
				ph = Eventvalues[35] / (Eventvalues[35] + abs(Eventvalues[36]) )
				Eventvalues[37] = ph				
				EventvalueNames[37] = "Igor CFD ratio "
				latch = 1
				
			endif

			k+=nspc
		while(k<TL)
		
		
		// c) find zero crossing
		

	endif
	
	
End

Function PW_restoresign(int) // correct for overflow/negative results
	Variable int
	if(int>63000)
		int=int-65536
	endif
	return int
End

Function PW_process_makethewaves(nevents)
	Variable nevents // D or I = 0 for DSP, 1 for Igor, 2 for both 

	String text, combwaves, Csiwaves,plasticwaves,otherwaves, allwaves
	Variable k
	
	Nvar oldNevents =   root:PW:oldNevents 
	if(nevents != oldNevents)
		print  "Making new waves, N events:", nevents
	endif
		
	// Waves for all events
	allwaves = "rt;energy;Q1sm;Q0sm;Bsm;PSAval;Amp;Ratio0;Ratio1;Channel;TrigTime;type"
	
			
	NewDataFolder/O/S root:PW	
	for(k=0;k<ItemsInList(allwaves);k+=1)
		text = StringFromList(k,allwaves)
		if(nevents != oldNevents)
			KillWaves/Z $(text)
			Make/o/n=(Nevents) $(text)
		endif
		wave wav = $(text)
		wav = NaN
	endfor
	
	SetDataFolder root:
		
End




//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// get data from files
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Function PW_process_allchannels()
	// a function to process all channels from all modules for the PSAval vs E scatter plot
	Nvar ChosenModule = root:pixie4:ChosenModule
	Nvar PWchannel	= root:PW:PWchannel 	
	Nvar NumberOfModules = root:pixie4:NumberOfModules
	Nvar NumberOfChannels = root:pixie4:NumberOfChannels
	Nvar  Nevents = root:PW:Nevents 				// number of events
	
	Svar OutputFileName = root:pixie4:OutputFileName
	Svar OutBaseName = root:pixie4:OutBaseName
	Nvar RunNumber = root:pixie4:RunNumber
	Svar DataFile = root:pixie4:DataFile
	Svar longDataFilename = root:pixie4:longDataFilename
	
	String	text = "root:PW"
	String filename, basefilename
	Variable mo, ch, fn, len, savePWchannel

	//Generate2DMCA(0)					// clear histogram
	//Execute "MCA_2D()"				// show histogram
	PW_AddCombinePSA(0)					// create/clear cumulative waves
	savePWchannel = PWchannel
	
	len = strlen(DataFile)
	basefilename = DataFile[0,len-3]
	

		for(ch=0;ch<NumberOfChannels;ch+=1)
			PWchannel = ch				// set channel
		 	PW_file_getPSAdata()		// process file for this channel
		 	DoUpdate
		 	PW_AddCombinePSA(1)			// add to cumulative waves
		endfor

	
	PW_AddCombinePSA(2)					// copy cumulative waves back to displayed waves
	PWchannel = savePWchannel
	
	PSA_histo()

End

// Function to combine PSA value and energy for multiple channels/modules/files
// into cumulative final waves
Function PW_AddCombinePSA(app)
Variable app // 0- start new, 1 --append, 2 -- copy back cumulative arrays


	String	text = "root:PW"

	// work on DSP specific waves
	Wave rt = $(text+":rt")					// rise time
	Wave energy = $(text+":energy")		// DSP energy
	Wave Q0sm = $(text+":Q0sm")			// PSA sum (Q0-B)
	Wave Q1sm = $(text+":Q1sm")			// PSA sum (Q1-B)
	Wave Bsm = $(text+":Bsm")			// PSA sum (B)
	Wave PSAval = $(text+":PSAval")		// PSA value (Q1/Q0 ratio)
	Wave Amp = $(text+":Amp")			// amplitude
	Wave Ratio0 = $(text+":Ratio0")		// arbitrary ratio 0
	Wave Ratio1 = $(text+":Ratio1")		// arbitrary ratio 1
	Wave TrigTime = $(text+":TrigTime")	// trigger time
	Wave Chan = $(text+":Channel")		// channel

	
	Nvar  Nevents = root:PW:Nevents 				// number of events
	Variable k,m
	
	if(app==0)	// create new waves and set to zero
		killwaves/Z  cumRT, cumE, cumQ0, cumQ1, cumB, cumPSA, cumA, cumR0, cumR1, cumTT, cumCH
		make/o/n=1  cumRT, cumE, cumQ0, cumQ1, cumB, cumPSA, cumA, cumR0, cumR1, cumTT, cumCH
		Wave cumRT 
		Wave cumE
		Wave cumQ0
		Wave cumQ1
		Wave cumB
		Wave cumPSA
		Wave cumA
		Wave cumR0
		Wave cumR1
		Wave cumTT
		Wave cumCH
		cumRT = 0
		cumE = 0
		cumQ0 = 0
		cumQ1 = 0
		cumB = 0
		cumPSA = 0
		cumA = 0
		cumR0 = 0
		cumR1 = 0
		cumTT = 0 
		cumCH = 0
	endif
	
	if(app==1)	// copy nonzero elements into cumulative waves
		Wave cumRT 
		Wave cumE
		Wave cumQ0
		Wave cumQ1
		Wave cumB
		Wave cumPSA
		Wave cumA
		Wave cumR0
		Wave cumR1
		Wave cumTT
		Wave cumCH
		wavestats/q cumRT
		m = V_npnts
		for(k=0;k<Nevents;k+=1)
			if( !(Bsm[k]==0) )		// Bsm[k]==0 would indicate an empty record
				Insertpoints m, 1, cumRT, cumE, cumQ0, cumQ1, cumB, cumPSA, cumA, cumR0, cumR1, cumTT, cumCH
				m+=1
				cumRT[m] = rt[k]
				cumE[m] = energy[k]
				cumQ0[m] = Q0sm[k]
				cumQ1[m] = Q1sm[k]
				cumB[m] = Bsm[k]
				cumPSA[m] = PSAval[k]
				cumA[m] = Amp[k]
				cumR0[m] = Ratio0[k]
				cumR1[m] = Ratio1[k]
				cumTT[m] = TrigTime[k]
				cumCH[m] = Chan[k]
			endif
		endfor
	endif
		
	if(app==2)	// copy cumulative waves back into original ones 
		duplicate/o cumRT, $(text+":rt")
		duplicate/o cumE, $(text+":energy")
		duplicate/o cumQ0, $(text+":Q0sm")		
		duplicate/o cumQ1, $(text+":Q1sm")		
		duplicate/o cumB, $(text+":Bsm")
		duplicate/o cumPSA, $(text+":PSAval")
		duplicate/o cumA, $(text+":Amp")
		duplicate/o cumR0, $(text+":Ratio0")	
		duplicate/o cumR1, $(text+":Ratio1")	
		duplicate/o cumTT,  $(text+":TrigTime")
		duplicate/o cumCH, $(text+":Channel")		
		killwaves/Z  cumRT, cumE, cumQ0, cumQ1, cumB, cumPSA, cumA, cumR0, cumR1, cumTT, cumCH
	endif

	
End



Function PW_file_getPSAdata()
	
	// processing parameters
	Nvar PWchannel	= root:PW:PWchannel 			// P4 channel to analyze
	Nvar PWrecordlength	= root:PW:PWrecordlength 	// number of PSA data words for all 4 channels
	Nvar messages = root:pixie4:messages
	Nvar  oldNevents = root:PW:oldNevents 				// remember previous number of events
	Nvar  Nevents = root:PW:Nevents 				// number of events
	Nvar source = root:PW:source
	Nvar CompDSP2Igor = root:PW:CompDSP2Igor
	Nvar maxevents = root:PW:maxevents
	Wave eventvalues = root:PW:Eventvalues
	Variable ch, NbadeventsIgor, NbadeventsDSP
	Variable k,m, len,n, index, E, ret, cnt, j, nev2proc
	String text
	
	// *** 1 *** get data from file
	Svar DataFile = root:pixie4:lmfilename
	Svar longDataFilename = root:pixie4:longDataFilename	
	Nvar ChosenModule = root:pixie4:ChosenModule
	Nvar NumberOfChannels = root:pixie4:NumberOfChannels
	Nvar ChosenEvent = root:pixie4:ChosenEvent
	wave listmodewave = root:pixie4:listmodewave
	
//	Nevents=listmodewave[ChosenModule]
	
	if(source==1)
		print " "
		print "Computing PSA data from traces, file", DataFile
		
		messages = 0	// turn off messages for waveform st.dev etc
		nevents = maxevents		// can not assume data file has been loaded properly
	
		Execute "Pixie_Plot_LMTraces()"	// open LM trace display since Igor processing needs it open
		PW_process_makethewaves(nevents)
		oldNevents = nevents	
	else
		print " "
		print "Reading PSA values from file", DataFile,"(DSP computed)"		
		print "not yet implemented"	
		return(0)
		
		if (nevents!= oldNevents)
			Killwaves/Z root:pixie4:EventPSAValues
			make/o/u/i/n=(nevents*PWrecordlength*NumberOfChannels) root:pixie4:EventPSAValues
		endif
		
		// event by event, always 8 words for ch 0-1-2-3: energy, XIA, user, user_2, user_3, user_4, user_5
		Wave PSAvalues = root:pixie4:eventpsavalues
		// parse the list mode event file
		//ret = Pixie4_Acquire_Data(0x7006, PSAvalues, longDataFilename, ChosenModule)
		if(ret < 0)
			Doalert 0, "Can not read event PSA values from the list mode event file."
			return(-1)
		endif
		
		PW_process_makethewaves(nevents)
		oldNevents = nevents			
	endif
	
	// *** 2 *** sort data from file or memory into waves, do some error checks
	
	text = "root:PW"

	// work on DSP specific waves
	Wave rt = $(text+":rt")					// rise time
	Wave energy = $(text+":energy")		// DSP energy
	Wave Q0sm = $(text+":Q0sm")			// PSA sum (Q0-B)
	Wave Q1sm = $(text+":Q1sm")			// PSA sum (Q1-B)
	Wave Bsm = $(text+":Bsm")			// PSA sum (B)
	Wave PSAval = $(text+":PSAval")		// PSA value (Q1/Q0 ratio)
	Wave Amp = $(text+":Amp")			// amplitude
	Wave Ratio0 = $(text+":Ratio0")		// arbitrary ratio 0
	Wave Ratio1 = $(text+":Ratio1")		// arbitrary ratio 1
	Wave TrigTime = $(text+":TrigTime")	// trigger time
	Wave Chan = $(text+":Channel")		// channel


	NbadeventsIgor = 0
	NbadeventsDSP = 0
	nev2proc = min(nevents, maxevents)
//	for(m=0;m<nevents;m+=1)		
	for(m=0;m<nev2proc;m+=1)		
		if(source==1)
			if (mod(m,10000)==0)
				print "processing event #",m
				DoUpdate
			endif
			ChosenEvent = m
			ret = Pixie_File_ReadEvent()
			if(ret < 0)
				print "Error reading new event"
				return(ret)
			endif
			
			energy[m]    	= Eventvalues[0]	// energy 
			rt[m]           	= Eventvalues[15] //RT
			Q0sm[m]      = Eventvalues[17] //Q0sum
			Q1sm[m]     	= Eventvalues[16] //Q1sum
			Bsm[m]  	= Eventvalues[20] //PSA sum (B)
			PSAval[m]  	= Eventvalues[19] //PSA value computed by Igor
			if(PSAval[m] <0)
				NbadeventsIgor+=1
			endif
			Amp[m] 		= Eventvalues[18] //Amplitude
			Chan[m]  	= PWchannel
			TrigTime[m] 	=  Eventvalues[7]			
			// debug -- use this to quantify difference betwen DSP and Igor results
			if (CompDSP2Igor)
				rt[m]           	= Eventvalues[4] // Q1 by DSP
				Chan[m]  	= Eventvalues[5] // Q0 by DSP
				TrigTime[m]	= Eventvalues[3] //base by DSP
				ratio0[m]     	= Eventvalues[2] //amplitude by DSP
				ratio1[m]     	= Eventvalues[6] //ratio by DSP
				if(ratio1[m] >65530)
					NbadeventsDSP+=1
				endif
			endif
		
		else	// source 0				
			index = (m*NumberOfChannels+PWchannel)*PWrecordlength			
			// read E, P, C, RT
			// index+0 is timestamp
			energy[m]   	= PSAvalues[index+1]		
			rt[m]           	= PW_restoresign(PSAvalues[index+2])
			Q0sm[m]      = PW_restoresign(PSAvalues[index+5])
			Q1sm[m]      = PW_restoresign(PSAvalues[index+6])
			Bsm[m]  	= PW_restoresign(PSAvalues[index+4])
			PSAval[m]  	= PW_restoresign(PSAvalues[index+7])
			if(PSAval[m] >65530)
				NbadeventsDSP+=1
			endif
			Amp[m] 		= PSAvalues[index+3]
			Chan[m]  	= PWchannel
			TrigTime[m] 	= PSAvalues[index]
		endif	
	endfor	
	print Nevents, "total,", NbadeventsDSP,"bad (DSP),", NbadeventsIgor,"bad (Igor)"
	// *** 3 *** read run statistics from .ifm file
//	String filename
//	len = strlen(DataFile)
//	filename = DataFile[0,len-5]+".ifm"
//	PW_file_readIFM(filename)
		
	// *** 4 *** compute histograms and user defined ratios 

	Svar  destwavenameN0 = root:PW:destwavenameN0 
	Svar  destwavenameD0 = root:PW:destwavenameD0
	Svar  destwavenameN1 = root:PW:destwavenameN1 
	Svar  destwavenameD1 = root:PW:destwavenameD1
	
	if (!CompDSP2Igor)
		wave numer0 = $("root:PW:"+destwavenameN0)
		wave denom0 = $("root:PW:"+destwavenameD0)
		Ratio0 = numer0 / denom0
		wave numer1 = $("root:PW:"+destwavenameN1)
		wave denom1 = $("root:PW:"+destwavenameD1)
		Ratio1 = numer1 / denom1
	endif
	
 	PSA_histo()
 	
		
End


	

Function PW_file_readIFM(filename)
String filename

	Svar IFMStartTime = root:PW:IFMStartTime
	Svar IFMStopTime = root:PW:IFMStopTime
	Nvar NumberOfChannels = root:pixie4:NumberOfChannels
	Nvar PWchannel = root:PW:PWchannel

	Wave RT_ifm =  root:PW:RT_ifm
	Wave Nev_ifm =  root:PW:Nev_ifm
	Wave LT_ifm =  root:PW:LT_ifm
	Wave Ntrig_ifm =  root:PW:Ntrig_ifm
	RT_ifm =0 
	Nev_ifm =0
	LT_ifm =0
	Ntrig_ifm =0

	
	Variable filenum,i,len,m, j,k
	String line
	Variable Mnum, Chnum, RT, LT, ER, ICR, NumberMod
		
	Open/R/P=EventPath/T="????" filenum as filename 
	if (cmpstr(S_fileName,"")!=0)		// if file defined succesfully
			
		FReadline filenum, line	// line 1
		if (cmpstr(line[0,8], "XIA Pixie") !=0)
			DoAlert 0, "Not a valid .ifm file, exiting"
			close/a
			return (0)
		endif
		
		FReadline filenum, line  // line 2
		len = strlen(line)
		IFMStartTime = line[23,len-2]
		print "start",IFMStartTime
		
		FReadline filenum, line // line 3
		len = strlen(line)
		IFMStopTime = line[11,len-2]
		print "stop",IFMStopTime
		
		FReadline filenum, line	// line 4: blank
		FReadline filenum, line	// line 5
		sscanf line, "Number of Modules: %d\r", NumberMod
		FReadline filenum, line	//module header
		k=0
		do
			FReadline filenum, line
			sscanf line, "%d %g %g", Mnum, RT, ER
			RT_ifm[k] = RT
			Nev_ifm[k] = RT*ER
			k+=1
		while (k<NumberMod)
		
		FReadline filenum, line	// line after module results: blank
		FReadline filenum, line	// channel results header: 
		k=0
		do
			for(i=0;i<NumberOfChannels;i+=1)
				FReadline filenum, line
				sscanf line, "%d %d %g %g", Mnum, Chnum, LT, ICR
				LT_ifm[k][i] =LT
				Ntrig_ifm[k][i] =ICR*LT
			endfor
			k+=1
		while (k<4)
	
		close filenum
		print "Runtime", RT_ifm[0],"s ;  Livetime", LT_ifm[0][PWchannel],"s"
		
	else		// if file opened not successfully
		printf "PW_file_readIFM: open statistics file failed, skipping ...\r" 
		
	endif
		
End



Function PSA_histo()
		histogram/B=1 root:PW:RT,  root:PW:RT_histo
		histogram/B={0,4,16384} root:PW:Q0sm,  root:PW:Q0_histo
		histogram/B={0,4,16384} root:PW:Q1sm,  root:PW:Q1_histo
		histogram/B={0,4,16384} root:PW:Bsm,  root:PW:Bsm_histo
		histogram/B={0,4,16384} root:PW:PSAval,  root:PW:PSAval_histo
		histogram/B=1 root:PW:Ratio0,  root:PW:Ratio0_histo
		histogram/B=1 root:PW:Ratio1,  root:PW:Ratio1_histo
		histogram/B={0,4,16384} root:PW:amp,  root:PW:amp_histo
End




Function PW_Panel_Call_Buttons(ctrlname)
String ctrlname

	Nvar source = root:PW:source
	Nvar Allchannels = root:PW:Allchannels
	
	if(cmpstr(ctrlname,"clr")==0)	
		Generate2DMCA(0)
		return 0
	endif
	
	if(cmpstr(ctrlname,"app")==0)	
		Generate2DMCA(1)
		return 0
	endif
	
	if(cmpstr(ctrlname,"shw")==0)	
		ShowROICursors()
		return 0
	endif
	
	if(cmpstr(ctrlname,"roi")==0)	
		Analyze_sumROIcsr()
		return 0
	endif
	
	if(cmpstr(ctrlname,"ReadDSPPSA")==0)	
		source = 0
		if(Allchannels)
			PW_process_allchannels()
		else
			PW_file_getPSAdata()
		endif
		return 0 
	endif
	
	if(cmpstr(ctrlname,"ReadDT3")==0)	
		
		LoadWave/G/O/P=Home/N=dt3import
		duplicate/o root:dt3import0,  root:PW:Ratio0	// resize to current length
		duplicate/o root:dt3import0,  root:PW:Ratio1
		duplicate/o root:dt3import1,  root:PW:Channel
		duplicate/o root:dt3import2,  root:PW:Trigtime
		duplicate/o root:dt3import3,  root:PW:energy
		duplicate/o root:dt3import4,  root:PW:rt
		duplicate/o root:dt3import5,  root:PW:Amp
		duplicate/o root:dt3import6,  root:PW:Bsm
		duplicate/o root:dt3import7,  root:PW:Q0sm
		duplicate/o root:dt3import8,  root:PW:Q1sm
		duplicate/o root:dt3import9,  root:PW:PSAval
		
		Svar  destwavenameN0 = root:PW:destwavenameN0 
		Svar  destwavenameD0 = root:PW:destwavenameD0
		Svar  destwavenameN1 = root:PW:destwavenameN1 
		Svar  destwavenameD1 = root:PW:destwavenameD1
		
		wave Ratio0 =  root:PW:Ratio0
		wave numer0 = $("root:PW:"+destwavenameN0)
		wave denom0 = $("root:PW:"+destwavenameD0)
		Ratio0 = numer0 / denom0
		wave Ratio1 =  root:PW:Ratio1
		wave numer1 = $("root:PW:"+destwavenameN1)
		wave denom1 = $("root:PW:"+destwavenameD1)
		Ratio1 = numer1 / denom1
		
		PSA_histo()

		
		killwaves/Z dt3import0, dt3import1, dt3import2, dt3import3, dt3import4, dt3import5
		killwaves/Z dt3import6, dt3import7, dt3import8, dt3import9
		return(0)
	endif
	
	
	if(cmpstr(ctrlname,"ComputeIgorPSA")==0)	
		source = 1
		if(Allchannels)
			PW_process_allchannels()
		else
			PW_file_getPSAdata()
		endif
		source = 0
		return 0 
	endif
	
	Execute (ctrlname+"()")
	
End


Window PW_EventPanel() : Panel
	PauseUpdate; Silent 1		// building window...
	Pixie_Plot_LMTraces()
	Dowindow/F PW_Events
	if (V_flag!=1)
		//NewPanel/K=1 /W=(600,450,920,850)
		NewPanel/K=1 /W=(600,450,850,850)
		Dowindow/C PW_Events
		ModifyPanel cbRGB=(65280,59904,48896)
		
		//ValDisplay valdisp0,pos={8,8},size={180,15},title="Event Number in File    "
		//ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000}, value= root:pixie4:ChosenEvent
		
		SetVariable CallReadEvents,pos={8,8},size={150,15},proc=Pixie_Ctrl_CommonSetVariable,title="Event Number   "
		SetVariable CallReadEvents,format="%d",fsize=10//,bodywidth=70
		SetVariable CallReadEvents,limits={0,Inf,1},value= root:pixie4:ChosenEvent
		
		Button PW_EventValues,pos={180, 8},size={40,20},proc=PW_Panel_Call_Buttons,title="Table"
		Button PW_EventValues,help={"Open Table with all Event values"}, fsize=11	

		
		Variable xio=145	
		Variable xfo=220	

		Variable xdo=18
		
		
		SetDrawEnv fsize= 11,fstyle= 2
		DrawText 12,42,"                       DSP/FPGA              Igor" //                   debug"
		
		ValDisplay valdisp1,pos={xdo,45},size={125,15},title="Energy      "
		ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[0]
		 
		ValDisplay valdisp2a,pos={xdo,65},size={125,15},title="Rise Time  "
		ValDisplay valdisp2a,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[1],valueColor=(50000,50000,50000 )
		ValDisplay valdisp2b,pos={xio,65},size={75,15},title="    "
		ValDisplay valdisp2b,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[11]
			
		ValDisplay valdisp3a,pos={xdo,85},size={125,15},title="Amplitude  "
		ValDisplay valdisp3a,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[2]
		ValDisplay valdisp3b,pos={xio,85},size={75,15},title="    "
		ValDisplay valdisp3b,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[12]
		
		ValDisplay valdisp4a,pos={xdo,105},size={125,15},title="B               "
		ValDisplay valdisp4a,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[3]
		ValDisplay valdisp4b,pos={xio,105},size={75,15},title="    "
		ValDisplay valdisp4b,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[13]
	//	ValDisplay valdisp4c,pos={xfo,105},size={75,15},title="    "
	//	ValDisplay valdisp4c,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[22] ,valueColor=(50000,50000,50000 )
	
		ValDisplay valdisp5a,pos={xdo,125},size={125,15},title="Q0 sum     "
		ValDisplay valdisp5a,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[4]
		ValDisplay valdisp5b,pos={xio,125},size={75,15},title="    "
		ValDisplay valdisp5b,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[14]
	//	ValDisplay valdisp5c,pos={xfo,125},size={75,15},title="    "
	//	ValDisplay valdisp5c,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[23] ,valueColor=(40000,40000,40000 )
		
		ValDisplay valdisp6a,pos={xdo,145},size={125,15},title="Q1 sum     "
		ValDisplay valdisp6a,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[5]
		ValDisplay valdisp6b,pos={xio,145},size={75,15},title="    "
		ValDisplay valdisp6b,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[15]
	//	ValDisplay valdisp6c,pos={xfo,145},size={75,15},title="    "
	//	ValDisplay valdisp6c,limits={0,0,0},barmisc={0,1000}, value= root:PW:Eventvalues[24] ,valueColor=(40000,40000,40000 )
								
		ValDisplay valdisp7a,pos={xdo,165},size={125,15},title="PSA value "
		ValDisplay valdisp7a,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[6]//	,valueColor=(50000,50000,50000 )
		ValDisplay valdisp7b,pos={xio,165},size={75,15},title="    "
		ValDisplay valdisp7b,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[16]
	
		ValDisplay valdisp8a,pos={xdo,185},size={125,15},title="Max           "
		ValDisplay valdisp8a,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[30]	,valueColor=(50000,50000,50000 )
		ValDisplay valdisp8b,pos={xio,185},size={75,15},title="    "
		ValDisplay valdisp8b,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[17]
	
	
		ValDisplay valdisp30,pos={xdo,210},size={125,15},title="raw 1 (max) "
		ValDisplay valdisp30,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[30]
		ValDisplay valdisp31,pos={xio,210},size={75,15},title="    "
		ValDisplay valdisp31,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[17]
		
		ValDisplay valdisp32,pos={xdo,230},size={125,15},title="raw 2 (Q0)   "
		ValDisplay valdisp32,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[31]
		ValDisplay valdisp33,pos={xio,230},size={75,15},title="    "
		ValDisplay valdisp33,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[41]	
		
		ValDisplay valdisp34,pos={xdo,250},size={125,15},title="raw 3 (Q1)   "
		ValDisplay valdisp34,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[32]
		ValDisplay valdisp35,pos={xio,250},size={75,15},title="    "
		ValDisplay valdisp35,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[42]
		
	Variable yoff = 90
	// 20 timestamp refined by CFD time  (DSP/FPGA/Igor)
	// 21 timestamp refined by CFD time  (Igor)
	// 22 CFD time fraction (DSP/FPGA)
	// 23 CFD time fraction (Igor)
	// 24 trigger point (Igor) 
		ValDisplay valdisp20,pos={xdo,185+yoff},size={125,15},title="CFD fraction"
		ValDisplay valdisp20,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[22]//	,valueColor=(50000,50000,50000 )
		ValDisplay valdisp21,pos={xio,185+yoff},size={75,15},title="    "
		ValDisplay valdisp21,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[23]
		
		ValDisplay valdisp22,pos={xdo,225+yoff},size={200,15},title="TS                      "
		ValDisplay valdisp22,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[7], format="%10.0f"
		ValDisplay valdisp23,pos={xdo,245+yoff},size={200,15},title="TS-CFD  (DSP)   "
		ValDisplay valdisp23,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[20], format="%10.5f"
		ValDisplay valdisp24,pos={xdo,265+yoff},size={200,15},title="TS-CFD  (Igor)    "
		ValDisplay valdisp24,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[21], format="%10.5f"
		ValDisplay valdisp25,pos={xdo,285+yoff},size={140,15},title="trig. point  (Igor)    "
		ValDisplay valdisp25,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[24]
		ValDisplay valdisp26,pos={xdo+140,285+yoff},size={70,15},title="shift "
		ValDisplay valdisp26,limits={0,0,0},barmisc={0,1000}, value=root:PW:Eventvalues[25]


	endif
	
	
EndMacro


Window PW_EventValues() : Table
DoWindow/F EvalList
	if (V_Flag!=1)
		PauseUpdate; Silent 1		// building window...
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:PW:
		Edit/k=1/W=(766.5,131.75,1144.5,650.75) EventvalueNames,Eventvalues
		DoWindow/C EvalList
		ModifyTable format(Point)=1,alignment(EventvalueNames)=0,width(EventvalueNames)=201
		SetDataFolder fldrSav0
	endif
EndMacro


Window PW_PSAList() : Table
	DoWindow/F PSAList
	if (V_Flag!=1)
		Edit/W=(280,50,800,450)/K=1 root:PW:energy,root:PW:rt,root:PW:Q0sm,root:PW:Q1sm, root:PW:Bsm
		DoWindow/C PSAList
		AppendToTable root:PW:PSAval,root:PW:Amp
		AppendToTable root:PW:Ratio0,  root:PW:Ratio1, root:PW:Trigtime,  root:PW:Channel
		ModifyTable width=40
		ModifyTable width( root:PW:Ratio0)=60
		ModifyTable width( root:PW:Ratio1)=60
		ModifyTable width( root:PW:rt)=60
		ModifyTable width( root:PW:PSAval)=60
		ModifyTable width( root:PW:amp)=60
		
		ModifyTable title(root:PW:energy)="Energy"
		ModifyTable title(root:PW:rt)="Rise Time"
		ModifyTable title(root:PW:Q0sm)="Q0-B"
		ModifyTable title(root:PW:Q1sm)="Q1-B"
		ModifyTable title(root:PW:Bsm)="B"
		ModifyTable title(root:PW:amp)="Amplitude"
		ModifyTable title(root:PW:PSAval)="PSA value"
		ModifyTable title(root:PW:Ratio0)="Ratio0"
		ModifyTable title(root:PW:Ratio1)="Ratio1"
		ModifyTable title(root:PW:Channel)="Channel"
		ModifyTable title(root:PW:Trigtime)="Trigtime"
	endif
EndMacro

Function PW_Panel_PopProc(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr
	
	if(cmpstr(ctrlName,"scattery")==0)
		Svar destwavename = root:PW:destwavenamey
	endif
	if(cmpstr(ctrlName,"scatterx")==0)
		Svar destwavename = root:PW:destwavenamex
	endif
	if(cmpstr(ctrlName,"scatterz")==0)
		Svar destwavename = root:PW:destwavenamez
	endif
	if(cmpstr(ctrlName,"ratioD0")==0)
		Svar destwavename = root:PW:destwavenameD0
	endif
	if(cmpstr(ctrlName,"ratioN0")==0)
		Svar destwavename = root:PW:destwavenameN0
	endif
	if(cmpstr(ctrlName,"ratioD1")==0)
		Svar destwavename = root:PW:destwavenameD1
	endif
	if(cmpstr(ctrlName,"ratioN1")==0)
		Svar destwavename = root:PW:destwavenameN1
	endif
	
	if(popNum==1)	
		destwavename = "<select>"	
	endif
		
	if(popNum==2)
		destwavename = "energy"
	endif
	
	if(popNum==3)
		destwavename = "rt"
	endif
	
	if(popNum==4)
		destwavename = "Q0sm"
	endif
	
	if(popNum==5)
		destwavename = "Q1sm"
	endif
	
	if(popNum==6)
		destwavename = "Bsm"
	endif
	
	if(popNum==7)
		destwavename = "PSAval"
	endif
	
	if(popNum==8)
		destwavename = "Amp"
	endif
	
	if(popNum==9)
		destwavename = "Ratio0"
	endif
	
	if(popNum==10)
		destwavename = "Ratio1"
	endif
	
	if(popNum==11)
		destwavename = "none"
	endif

	



	
End


Window PW_PSA_scatterplot() : Graph
	DoWindow/F PSAscatter	
	if (V_Flag!=1)
		SetDataFolder  root:PW
		Display /K=1/W=(485.25,248.75,911.25,475.25) $(root:PW:destwavenamey) vs  $(root:PW:destwavenamex)
		DoWindow/C PSAscatter
		ModifyGraph mode=2
		ModifyGraph lSize=1	
		ModifyGraph zero=1
		ModifyGraph mirror=2
		ModifyGraph lblMargin(left)=2,lblMargin(bottom)=3
		ModifyGraph lblLatPos(bottom)=-18
		Label left root:PW:destwavenamey
		Label bottom root:PW:destwavenamex
		if(cmpstr(root:PW:destwavenamez,"none")!=0)
			ModifyGraph zColor($(root:PW:destwavenamey))={$(root:PW:destwavenamez),*,*,Rainbow}
			ColorScale/C/N=text0/F=0/A=RC/X=0.8 trace=$(root:PW:destwavenamey)
		endif
		ShowInfo
		SetDataFolder  root:
	endif
EndMacro

Menu "&XIA_Extra"
	//"&User Control Panel", User_Control()
	"&PSA Analysis",PSA_Analysis()
	"&Event Detail",PW_EventPanel()
	"&2D MCA",MCA_2D()
	"-"
End

Function CFD_Analysis(): Panel
	PauseUpdate; Silent 1		// building window...
	
	DoWindow/F CFD__Analysis
	if (V_flag!=1)
		NewPanel /K=1/W=(350,70,585,300) as "CFD Results"
		ModifyPanel cbRGB=(65280,59904,48896)
		DoWindow/C CFD__Analysis	
		
		variable buttonx = 200
		Variable ctrlx = 16
		Variable sety = 30
		variable igory = 20
		SetDrawEnv fsize= 12,fstyle= 1
		DrawText 10,igory,"Parameters for Igor (offline) CFD"

		
		SetVariable Igor0,pos={ctrlx,igory+10},size={160,16},title="CFD fast filter length ",help={"number of samples in earlier sum"}
		SetVariable Igor0,fSize=10,format="%g",value= root:PW:CFD_FL		
		SetVariable Igor1,pos={ctrlx,igory+30},size={160,16},title="CFD fast filtergap     ",help={"number of samples in later sum"}
		SetVariable Igor1,fSize=10,format="%g",value= root:PW:CFD_FG	
	
		SetVariable Igor2,pos={ctrlx,igory+50},size={160,16},title="CFD_scale               ",help={"starting point of Q0 relative to low RT level"}
		SetVariable Igor2,fSize=10,format="%g",value= root:PW:CFD_scale
		SetVariable Igor3,pos={ctrlx,igory+70},size={160,16},title="CFD_delay               ",help={"starting point of Q1 relative to low or high RT level"}
		SetVariable Igor3,fSize=10,format="%g",value= root:PW:CFD_delay
		SetVariable Igor4,pos={ctrlx,igory+90},size={160,16},title="CFD_threshold         ",help={"starting point of Q1 relative to low or high RT level"}
		SetVariable Igor4,fSize=10,format="%g",value= root:PW:CFD_threshold

	endif	
End


Function PSA_Analysis() : Panel
	PauseUpdate; Silent 1		// building window...
	
	DoWindow/F PSA__Analysis
	if (V_flag!=1)
		NewPanel /K=1/W=(50,70,285,720) as "PSA Analysis"
		ModifyPanel cbRGB=(65280,59904,48896)
		DoWindow/C PSA__Analysis	

		variable buttonx = 200
		Variable ctrlx = 16
		Variable sety = 30

		SetDrawEnv fsize= 12,fstyle= 1
		DrawText 10,20,"General Analysis Settings"
		
		SetVariable Igor1a,pos={ctrlx,sety-2},size={130,16},title="Channel to process",help={"select 0..3"}, limits={0,3,1}
		SetVariable Igor1a,fSize=10,format="%g",value= root:PW:PWchannel
		Checkbox Igor1,pos={ctrlx+150,sety},size={160,16},title="all",help={"loop over all channels and modules when reading from file"}
		Checkbox Igor1,fSize=10,variable= root:PW:Allchannels
		sety+=2

		
		SetDrawEnv fsize= 16,fstyle= 0
		DrawText ctrlx+120,sety+40,"  /    "
		DrawText ctrlx+120,sety+60,"  /    "
		
		popupmenu ratioN0,  pos={ctrlx,sety+20}, title = "Ratio0 = ", proc = PW_Panel_PopProc, size ={120,20}
		popupmenu ratioN0, value="<select>;energy;risetime;Q0sum;Q1sum;Bsum;PSAvalue;Amplitude", mode=1
		popupmenu ratioN0, help={"Define a new parameter 'ratio0' from one PSA value divided by another"} 
		popupmenu ratioD0,  pos={ctrlx+130,sety+20}, title = " ", proc = PW_Panel_PopProc, size ={120,20}
		popupmenu ratioD0, value="<select>;energy;risetime;Q0sum;Q1sum;Bsum;PSAvalue;Amplitude", mode=1
		popupmenu ratioD0, help={"Define a new parameter 'ratio0' from one PSA value divided by another"} 

		popupmenu ratioN1,  pos={ctrlx,sety+45}, title = "Ratio1 = ", proc = PW_Panel_PopProc, size ={120,20}
		popupmenu ratioN1, value="<select>;energy;risetime;Q0sum;Q1sum;Bsum;PSAvalue;Amplitude;Ratio0", mode=1
		popupmenu ratioN1, help={"Define a new parameter 'ratio1' from one PSA value divided by another"} 
		popupmenu ratioD1,  pos={ctrlx+130,sety+45}, title = " ", proc = PW_Panel_PopProc, size ={120,20}
		popupmenu ratioD1, value="<select>;energy;risetime;Q0sum;Q1sum;Bsum;PSAvalue;Amplitude;Ratio0", mode=1
		popupmenu ratioD1, help={"Define a new parameter 'ratio1' from one PSA value divided by another"} 


		
		Variable filey = 127
		SetDrawEnv fsize= 12,fstyle= 1
		DrawText 10,filey,"Review PSA results from file"
		
		SetVariable TraceDataFile, value=root:pixie4:lmfilename, pos={ctrlx, filey+8},size={165,18},title="File"
		SetVariable TraceDataFile, fsize=10,proc=Pixie_Ctrl_CommonSetVariable//,bodywidth=100
		Button FindTraceDataFile, pos={ctrlx+170,filey+6},size={30,20},proc=Pixie_Ctrl_CommonButton,title="Find",fsize=11
		
		Button PW_eventPanel,proc=PW_Panel_Call_Buttons,title="Show PSA results with LM traces"
		Button PW_eventPanel,pos={ctrlx, filey +30},size={buttonx,20}, fsize=11, help={"Open panel with PSA results computed by DSP and Igor for each trace"} 
		
		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey+61, 220, filey+61
		
		filey+=20
		
		Button ReadDSPPSA,pos={ctrlx, filey+50},size={buttonx,20},proc=PW_Panel_Call_Buttons,title="Read DSP PSA Data from binary file"
		Button ReadDSPPSA,help={"Read list data from file, extract PSA values computed by DSP"}
		
		SetDrawEnv fsize= 8,fstyle= 0
		DrawText 105,filey+82,"-- or --"
		
		Button ComputeIgorPSA,pos={ctrlx, filey+84},size={buttonx,20},proc=PW_Panel_Call_Buttons,title="Compute PSA Data from traces"
		Button ComputeIgorPSA,help={"Read list data from file, compute PSA values from traces in Igor"}
		SetVariable maxevents, value=root:PW:maxevents, pos={ctrlx+10, filey+106},size={165,18},title="Stop at event"
		
		filey+=54
		SetDrawEnv fsize= 8,fstyle= 0
		DrawText 105,filey+82,"-- or --"
		
		Button ReadDT3,pos={ctrlx, filey+84},size={buttonx,20},proc=PW_Panel_Call_Buttons,title="Read DSP PSA Data from text file"
		Button ReadDT3,help={"Read dt3 file, extract PSA values computed by DSP. All channels in one module"}

		
		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey+115, 220, filey+115

		filey +=124
		Button PW_PSAList,pos={ctrlx, filey},size={buttonx,20},proc=PW_Panel_Call_Buttons,title="Open PSA Table"
		Button PW_PSAList,help={"Open Table with PSA raw data"}, fsize=11	
		
		Button PW_PSA_scatterplot,pos={ctrlx, filey+26},size={buttonx,20},proc=PW_Panel_Call_Buttons,title="Display scatter plot"
		Button PW_PSA_scatterplot,help={"Create scatter plot of one parameter vs another, select below"}, fsize=11
		
		popupmenu scattery,  pos={ctrlx+20,filey+50}, title = "y wave      ", proc = PW_Panel_PopProc, size ={120,20}
		popupmenu scattery, value="<select>;energy;risetime;Q0sum;Q1sum;Bsum;PSAvalue;Amplitude;Ratio0;Ratio1", mode=1
		
		popupmenu scatterx,  pos={ctrlx+20,filey+74}, title = "x wave      ", proc = PW_Panel_PopProc, size ={120,20}
		popupmenu scatterx, value="<select>;energy;risetime;Q0sum;Q1sum;Bsum;PSAvalue;Amplitude;Ratio0;Ratio1", mode=1
		
		popupmenu scatterz,  pos={ctrlx+20,filey+98}, title = "color wave", proc = PW_Panel_PopProc, size ={120,20}
		popupmenu scatterz, value="<select>;energy;risetime;Q0sum;Q1sum;Bsum;PSAvalue;Amplitude;Ratio0;Ratio1;none", mode=1
		
		
		variable igory = 476
		SetDrawEnv fsize= 12,fstyle= 1
		DrawText 10,igory,"Parameters for Igor (offline) PSA"

		ctrlx-=5
		SetVariable Igor2,pos={ctrlx,igory+10},size={130,16},title="Sum length LoQ0",help={"number of samples in earlier sum"}
		SetVariable Igor2,fSize=10,format="%g",value= root:PW:LoQ0		
		SetVariable Igor0,pos={ctrlx+145,igory+10},size={75,16},title="LoQ1",help={"number of samples in later sum"}
		SetVariable Igor0,fSize=10,format="%g",value= root:PW:LoQ1	

		
		SetVariable Igor5,pos={ctrlx,igory+30},size={130,16},title="Sum delay SoQ0  ",help={"starting point of Q0 relative to low RT level"}
		SetVariable Igor5,fSize=10,format="%g",value= root:PW:SoQ0
		SetVariable Igor4,pos={ctrlx+145,igory+30},size={75,16},title="SoQ1",help={"starting point of Q1 relative to low or high RT level"}
		SetVariable Igor4,fSize=10,format="%g",value= root:PW:SoQ1

		
		SetVariable Igor22,pos={ctrlx,igory+50},size={130,16},title="Trigger filter rise    ",help={"number of samples for trigger filter rise time"}
		SetVariable Igor22,fSize=10,format="%g",value= root:PW:CFD_FL		
		SetVariable Igor20,pos={ctrlx+145,igory+50},size={75,16},title="TF flat",help={"number of samples for trigger filter flat top"}
		SetVariable Igor20,fSize=10,format="%g",value= root:PW:CFD_FG	

	
		SetVariable Igor25,pos={ctrlx,igory+70},size={130,16},title="CFD delay          ",help={" "}
		SetVariable Igor25,fSize=10,format="%g",value= root:PW:CFD_delay
		SetVariable Igor24,pos={ctrlx+145,igory+70},size={75,16},title="scale",help={"0-7 for 1.000-0.125, but not 1 "}
		SetVariable Igor24,fSize=10,format="%g",value= root:PW:CFD_scale
		SetVariable Igor26,pos={ctrlx+145,igory+90},size={75,16},title="TH   ",help={"arming threshold "}
		SetVariable Igor26,fSize=10,format="%g",value= root:PW:CFD_threshold

//	Variable/G root:PW:CFD_threshold
		
		
	//	Checkbox Igor6,pos={ctrlx,igory+97},size={160,16},title="Q1 start relative to low RT",help={"0 - start at high RT level, 1- start at low RT level"}
	//	Checkbox Igor6,fSize=10,variable= root:PW:Q1startoption			
	//	Checkbox Igor9,pos={ctrlx,igory+115},size={160,16},title="PSA value = Q1/Q0    ",help={"0 - Q1/Q0, 1- (Q1-Q0)/Q0"}
	//	Checkbox Igor9,fSize=10,variable= root:PW:PSAoption
		Checkbox Igor10,pos={ctrlx,igory+97},size={160,16},title="Divide result by 8    ",help={"for long sums"}
		Checkbox Igor10,fSize=10,variable= root:PW:PSAdiv8
		Checkbox Igor11,pos={ctrlx,igory+115},size={160,16},title="Leading edge trigger    ",help={"use leading edge trigger instead of CFD"}
		Checkbox Igor11,fSize=10,variable= root:PW:PSAletrig
		SetVariable Igor12,pos={ctrlx,igory+133},size={140,16},title="PSA Threshold  ",help={"in % for CFD or in ADC steps for LE"}
		SetVariable Igor12,fSize=10,format="%g",value= root:PW:PSAth, limits={0,65535,1}
		SetVariable Igor13,pos={ctrlx,igory+151},size={140,16},title="CFD Offset (ns)    ",help={"Offset between Igor counting from start of trace vs FPGA counting from trigger"}
		SetVariable Igor13,fSize=10,format="%g",value= root:PW:CFDoffset//, limits={0,65535,1}



	endif
End

Function Eventtype()	// Assign a type ID according to wave characteristics

	Nvar  Nevents = root:PW:Nevents 				// number of events
	String text
	Variable m
	text = "root:PW"
	Wave rt = $(text+":rt")					// rise time
	Wave energy = $(text+":energy")		// DSP energy
	Wave Q0sm = $(text+":Q0sm")			// PSA sum (Q0-B)
	Wave Q1sm = $(text+":Q1sm")			// PSA sum (Q1-B)
	Wave Bsm = $(text+":Bsm")			// PSA sum (B)
	Wave PSAval = $(text+":PSAval")		// PSA value computed by DSP
	Wave Amp = $(text+":Amp")			// amplitude
	Wave Ratio0 = $(text+":Ratio0")			// arbitrary ratio
	Wave Ratio1 = $(text+":Ratio1")			// arbitrary ratio
	Wave TrigTime = $(text+":TrigTime")	// trigger time
	Wave Chan = $(text+":Channel")		// channel
	Wave type = $(text+":type")		// channel
	
	Variable QE0lowRn = 8.4
	Variable QE0highRn = 15
	Variable QE1lowRn =  2.35
	Variable QE1highRn =  5.3
	Variable QE0lowPl = 18
	Variable QE0highCo = QE0lowPl
	Variable QE0lowCo = 2.5
	Variable QE0highCs = QE0lowCo
	
	type = nan

	for(m=0;m<nevents;m+=1)
		if(Ratio0[m] <QE0highCs)
			type[m] = 10
		endif
		
		if(Ratio0[m] >QE0lowPl)
			type[m] = 20
		endif
		
		if( (Ratio0[m] >QE0lowCo) && (Ratio0[m] <QE0highCo) )
			type[m] = 30
		endif
		
		if( (Ratio0[m] >QE0lowRn) && (Ratio0[m] <QE0highRn) && (Ratio1[m] <QE1highRn) && (Ratio1[m] >QE1lowRn)  )
//		if(  (Ratio[m] >QE1lowRn)  )
	
			type[m] = 50
		endif
	endfor


End





Function Generate2DMCA(app)
Variable app	// append: 0= clear, recreate waves, 1 = append, 2 = rescale
	
	Nvar scalex = root:PW:scalex
	Nvar scaley = root:PW:scaley
	Nvar offx = root:PW:offx
	Nvar offy = root:PW:offy
	
	Svar destwavenamex = root:PW:destwavenamex
	Svar destwavenamey = root:PW:destwavenamey
	
	wave energy1list = $("root:PW:"+destwavenamex) 
	wave energy2list =$("root:PW:"+destwavenamey)


	Variable Nevents, Ex, Ey, xy,k
	Nvar nbins = root:PW:nbins
	
	make/o/n=(nbins*nbins) x2D, y2D, z2D
	wave x2D
	wave y2D
	wave z2D

	// 2D spectra
	wavestats/q energy1list
	Nevents = V_npnts
			
	if (app==0)
		z2D=0
	endif
	
	if(app==1)	
		for(k=0;k<Nevents;k+=1)
			Ex = floor((energy1list[k]-offx)/scalex) 
			Ey = floor((energy2list[k]-offy)/scaley) 
			if( (Ey<nbins) && (Ex <nbins) ) // if in range ...
				xy = Ex+(Ey*nbins)
				z2D[xy]+=1						
			endif
		endfor
			
		z2D[0]=0			
	endif
	
	// always
	x2d = mod(p,nbins)
	y2d = floor(p/nbins)
	x2D=x2D*scalex+offx
	y2D=y2D*scaley+offy
		
End

Window MCA_2D() : Graph
	PauseUpdate; Silent 1		// building window...
	
	DoWindow/F MCA_2D
	if(V_flag!=1)
		Display /K=1/W=(200,70,650,460) root:y2D vs root:x2D as "2D spectrum"
		DoWindow/C MCA_2D
		ControlBar 75
		SetVariable scx,pos={10,10},size={130,16},title="x scaling factor",fsize=11,value= root:PW:scalex
		SetVariable scx, help = {"Bin size in x axis. Use 256 for full range of DSP parameters. Possibly <0.1 for 'ratio'"}
		SetVariable ofx,pos={155,10},size={100,16},title="x offset",fsize=11,value= root:PW:offx
		SetVariable ofx, help = {"Offset in x axis (left limit)"}
		SetVariable scy,pos={10,35},size={130,16},title="y scaling factor",fsize=11,value= root:PW:scaley
		SetVariable scy, help = {"Bin size in y axis Use 256 for full range of DSP parameters. Possibly <0.1 for 'ratio'"}
		SetVariable ofy,pos={155,35},size={100,16},title="y offset",fsize=11,value= root:PW:offy
		SetVariable ofy, help = {"Offset in y axis (lower limit)"}
		Button clr, pos={280,10}, size = {80,20}, title="Clear/Rescale", proc=PW_Panel_Call_Buttons
		Button clr, help={"Clear the spectrum and apply current bin size"}
		Button app,  pos={280,35}, size = {80,20}, title="Append", proc=PW_Panel_Call_Buttons
		Button app, help={"Add the PSA waves from scatter plot to MCA"}
		Button shw,  pos={380,10}, size = {100,20}, title="Show cursor", proc=PW_Panel_Call_Buttons
		Button roi,  pos={380,35}, size = {100,20}, title="Sum ROI", proc=PW_Panel_Call_Buttons
		Button roi, help={"Sum the counts within the cursor box"} 
 
		ModifyGraph mode=2
		ModifyGraph marker=18
		ModifyGraph lSize=2
		ModifyGraph rgb=(0,0,0)
		ModifyGraph msize=2
		ModifyGraph logZColor=1,zColor(y2D)={z2D,1,*,Spectrum,0}
		ModifyGraph zColorMin(y2D)=(65535,65535,65535)
		ModifyGraph mirror=2
		Label left root:PW:destwavenamey
		Label bottom root:PW:destwavenamex
		ColorScale/N=text0/A=MC/X=38.45/Y=11.00/E=2 trace=y2D, nticks=8, log =1, minor=1
	endif
EndMacro

Function Analyze_sumROIcsr()

	Variable p1,p2, p3, ongraph
	
	ongraph=1
	if (cmpstr(csrinfo(A,  "MCA_2D"),"")==0)
		ongraph=0
	endif
	if (cmpstr(csrinfo(B,  "MCA_2D"),"")==0)
		ongraph=0
	endif
	if(ongraph==0)
		return(0)
	endif
	
	p1 = pcsr(A, "MCA_2D")
	p2 = pcsr(B, "MCA_2D")
	
	if(p1>p2)
		p3 = p1
		p1 = p2
		p2 = p3
	endif
	
	//print "points:", p1,p2
	Analyze_sumROIpts(p1,p2)
End


Function Analyze_sumROIpts(p1,p2)
Variable p1,p2
	
	Nvar nbins = root:PW:nbins
	Wave  x2D = root:x2D
	Wave  y2D = root:y2D
	Wave  z2D = root:z2D
	
	make/o/n=(nbins,nbins) root:MCA_2Dcount
	Wave  MCA_2Dcount =  root:MCA_2Dcount
	MCA_2Dcount = z2D		// MCA_2D[p][q]: p = x, q = y
	
	make/o/n=(nbins)  root:E1_roi,  root:E2_roi
	Wave E1_roi =  root:E1_roi
	Wave E2_roi =  root:E2_roi
	E1_roi = 0
	E2_roi = 0 
	
	Variable k, j, sumROI
	Variable x1,y1,x2,y2
	
	x1 = mod(p1,nbins)
	x2 = mod(p2,nbins)
	y1 = floor(p1/nbins)
	y2 = floor(p2/nbins)
	
//	print x1,y1,x2,y2
//	print x2D(p1)/x1, y2D(p1)/y1, x2D(p2)/x2, y2D(p2)/y2
	
	sumROI = 0
	for (k=x1;k<=x2;k+=1)
		for(j=y1;j<=y2;j+=1)
			sumROI += MCA_2Dcount[k][j]		
			E1_roi[k] += MCA_2Dcount[k][j]	
			E2_roi[j] += MCA_2Dcount[k][j]	
		endfor
	endfor
	
	setscale/P x,0,16, E1_roi	// PARAMETER 32 is scaling of 2D spectrum
	setscale/P x,0,16, E2_roi
	
	print "Counts in ROI:", sumROI
	return(sumROI)

End

Function ShowROICursors()
		Execute "MCA_2D()"
		ShowInfo
		Cursor/H=1 A y2D 2316
		Cursor/H=1 B y2D 11588
End


Proc CompareDSP2Igor(process)
Variable process		// if 1, reprocess file. if 0, just build ratios and histograms
	PauseUpdate; Silent 1	
//	Nvar CompDSP2Igor = root:PW:CompDSP2Igor
//	Nvar  Nevents = root:PW:Nevents 				// number of events
//	Nvar source = root:PW:source
	
	Variable k,m, len
	
//	Nvar LoQ1 = root:PW:LoQ1 // = 12 // length of sum Q1 and its baseline
//	Nvar LoQ0 = root:PW:LoQ0 // = 12 // length of sum Q0	 and its baseline
//	Nvar SoQ1 = root:PW:SoQ1 // = 0	// starting point of Q1 relative to high or low RT level
//	Nvar SoQ0 =root:PW:SoQ0 //= 24	// starting point of Q0 relative to low RT level

if(process)
	root:PW:CompDSP2Igor = 1	// go into debug mode
	root:PW:source =1			// "Computing PSA data from traces "
	
	PW_file_getPSAdata()	// process file, keeping arrays of online and offline results
  	root:PW:CompDSP2Igor = 0	// exit debug mode
	root:PW:source = 0			// Reading PSA values from file (default)
endif
	 
	make/o/n=( root:PW:nevents) root:PW:DiffQ0, root:PW:DiffQ1,  root:PW:DiffAmpl,  root:PW:DiffBase,  root:PW:DiffRatio

	 // in CompDSP2Igor mode, channel, rt, ratio0, TrigTime and ratio1 contain online result of Q0, Q1, ampl, base, PSAval=Q1/Q0
	//  root:PW:DiffQ0 =     (root:PW:Channel -  root:PW:Q0sm 	) /root:PW:Q0sm 	*100 //Q0(DSP) - Q0(Igor)
	//  root:PW:DiffQ1 =     (root:PW:rt -  root:PW:Q1sm)	 /root:PW:Q1sm 	*100		//Q1(DSP) - Q1(Igor)
	  root:PW:DiffAmpl = (root:PW:ratio0 -  root:PW:Amp)  /root:PW:Amp 	*100	//Ampl(DSP) - Ampl(Igor)
	  root:PW:DiffBase = (root:PW:TrigTime -  root:PW:Bsm) /root:PW:Bsm 	*100 	//base(DSP) - base(Igor)
	  root:PW:DiffRatio = (root:PW:ratio1/1000 -  root:PW:PSAval)  /root:PW:PSAval 	*100	//ratio(DSP) - ratio(Igor)
	 
	 // Q0, Q1 and ratio are strongly affected by error in B, try here to revert for Qs
	 duplicate/o root:PW:Channel, Qdsp
	 duplicate/o root:PW:Q0sm, Qigor
	 duplicate/o root:PW:TrigTime, Bdsp
	 duplicate/o root:PW:Bsm, Bigor
	  Qdsp = Qdsp-(root:PW:LoQ0*Bdsp/4)		// undo baseline subtraction
	  Qigor = Qigor-(root:PW:LoQ0*Bigor/4)
	  root:PW:DiffQ0 =    (root:Qdsp-root:Qigor)/root:Qdsp*100 
	  
	 duplicate/o root:PW:rt, Qdsp
	 duplicate/o root:PW:Q1sm, Qigor
	  Qdsp = Qdsp-(root:PW:LoQ1*Bdsp/4)		// undo baseline subtraction
	  Qigor = Qigor-(root:PW:LoQ1*Bigor/4)
	  root:PW:DiffQ1 =    (root:Qdsp-root:Qigor)/root:Qdsp*100 
	
	 
	 // another computation of ratio by Igor with DSP values
	  duplicate/o root:PW:ratio1, DSPIgorratio
	  DSPIgorratio = root:PW:rt / root:PW:Channel
	  

	 Variable bstart = -100
	 variable bsize = 0.1
	 Variable bnum = 2000
	 make/o/n=1 root:PW:histo_DiffQ0
	 histogram/B={bstart,bsize,bnum} root:PW:DiffQ0,  root:PW:histo_DiffQ0
	 make/o/n=1 root:PW:histo_DiffQ1
	 histogram/B={bstart,bsize,bnum} root:PW:DiffQ1,  root:PW:histo_DiffQ1
	 make/o/n=1 root:PW:histo_DiffAmpl
	 histogram/B={bstart,bsize,bnum} root:PW:DiffAmpl,  root:PW:histo_DiffAmpl
	 make/o/n=1 root:PW:histo_DiffBase
	 histogram/B={bstart,bsize,bnum} root:PW:DiffBase,  root:PW:histo_DiffBase
	 make/o/n=1 root:PW:histo_DiffRatio
	 histogram/B={bstart,bsize,bnum} root:PW:DiffRatio,  root:PW:histo_DiffRatio
	 
	   // histogram the ratios with specific bins
	   bstart = -0.1
	   bsize = 0.004
	   bnum = 1024
	   make/o/n=1 root:PW:histo_Q1Q0_DSP
	   make/o/n=1 root:PW:histo_Q1Q0_Igor
	   make/o/n=1 root:PW:histo_Q1Q0_DSPIgor
	   histogram/B={bstart,bsize,bnum} root:PW:PSAval,   root:PW:histo_Q1Q0_Igor
	   histogram/B={bstart,bsize,bnum} DSPIgorratio,   root:PW:histo_Q1Q0_DSPIgor
	   bstart *=1000
	   bsize *= 1000
	   histogram/B={bstart,bsize,bnum} root:PW:ratio1,   root:PW:histo_Q1Q0_DSP
		 
	 killwaves/Z Qdsp, Qigor, Bdsp, Bigor, DSPIgorratio

End





Window Q1Q0Histograms() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(366.75,125.75,761.25,347) :PW:histo_Q1Q0_Igor
	AppendToGraph/T  :PW:histo_Q1Q0_DSP
	AppendToGraph :PW:histo_Q1Q0_DSPIgor
	ModifyGraph mode(histo_Q1Q0_Igor)=6,mode(histo_Q1Q0_DSP)=6,mode(histo_Q1Q0_DSPIgor)=6
	ModifyGraph rgb(histo_Q1Q0_DSP)=(0,0,65280),rgb(histo_Q1Q0_DSPIgor)=(26368,0,52224)
	ModifyGraph log(left)=1
	SetAxis bottom -0.1,1
	SetAxis top -100,1000
	Cursor/P A histo_Q1Q0_DSP 49;Cursor/P B histo_Q1Q0_DSP 149
	ShowInfo
EndMacro


Window PSADiffHisttograms() : Graph
	PauseUpdate; Silent 1		// building window...
	String fldrSav0= GetDataFolder(1)
	SetDataFolder root:PW:
	Display/K=1 /W=(150.75,140,637.5,520.25) histo_DiffQ0,histo_DiffQ1,histo_DiffAmpl,histo_DiffBase
	AppendToGraph histo_DiffRatio
	SetDataFolder fldrSav0
	ModifyGraph mode=6
	ModifyGraph rgb(histo_DiffQ1)=(8704,8704,8704),rgb(histo_DiffAmpl)=(0,0,65280),rgb(histo_DiffBase)=(0,52224,0)
	ModifyGraph rgb(histo_DiffRatio)=(52224,0,41728)
	ModifyGraph log(left)=1
	ModifyGraph mirror=2
	Label left "N events"
	Label bottom "(Online - Offline)/Offline)*100 (%)"
	Legend/C/N=text0/J/F=0/A=MC/X=32.31/Y=35.12 "\\s(histo_DiffQ0) histo_DiffQ0\r\\s(histo_DiffQ1) histo_DiffQ1\r\\s(histo_DiffAmpl) histo_DiffAmpl"
	AppendText "\\s(histo_DiffBase) histo_DiffBase\r\\s(histo_DiffRatio) histo_DiffRatio"
EndMacro

Function ShowHideAWEcontrols()

	Nvar RunInProgress = root:pixie4:RunInProgress
	
	if(RunInProgress)
		SetVariable RUN_FileBase,disable=2,win = Pixie4MainPanel_AWE
		SetVariable RUN_Number, disable=2,win = Pixie4MainPanel_AWE
		Button cmnLoad, disable=2, win = Pixie4MainPanel_AWE	
		Button cmnSave, disable=2, win = Pixie4MainPanel_AWE	
		Button MainStartRun, disable=2, win = Pixie4MainPanel_AWE	
		Button MainStopRun, disable=0, win = Pixie4MainPanel_AWE			
		popupmenu RUN_WhichRun, disable=2, win = Pixie4MainPanel_AWE	
	//	Button ADCRefresh, disable=2, win = AWEOscilloscope	
	//	Button AdjustDC, disable=2, win = AWEOscilloscope	
	else
		SetVariable RUN_FileBase,disable=0,win = Pixie4MainPanel_AWE
		SetVariable RUN_Number, disable=0,win = Pixie4MainPanel_AWE
		Button cmnLoad, disable=0, win = Pixie4MainPanel_AWE
		Button cmnSave, disable=0, win = Pixie4MainPanel_AWE	
		Button MainStartRun, disable=0, win = Pixie4MainPanel_AWE
		Button MainStopRun, disable=2, win = Pixie4MainPanel_AWE	
		popupmenu RUN_WhichRun, disable=0, win = Pixie4MainPanel_AWE		
	//	Button ADCRefresh, disable=0, win = AWEOscilloscope	
	//	Button AdjustDC, disable=0, win = AWEOscilloscope	
	endif
End


Function Export_2D()

	make/o/n=(256,256) mca2D
	Wave mca2D
	Wave z2D
	mca2D = z2D
	
			//Wave z2Dsave = root:mca2D
		//save/A/J/M="\n"  z2Dsave as writefilename		// tab del. save. not valid for phd file
//	save/t mca2D
	
	Variable nbinx = 256	
	Variable nbiny  =256
	Variable k, i, filenum2
		Open/P=home filenum2 as "psa2D.csv"						// save 2D b-g-coincidence matrix
		
		// x index row
		fprintf filenum2, ""
		for (i=0;i<nbinx;i+=1)
			fprintf filenum2, ",%d",i	// Beta-gamma histogram value new way of saving
		endfor
		fprintf filenum2, "\n"
		
		for (k=0; k<nbiny; k+=1)		//  Store in IMS format:   value[bin#] value[bin#+1] value[bin#+2] value[bin#+3] value[bin#+4]  ... 
			//fprintf filenum2, "\n%d", k
			fprintf filenum2, "%d",k
			for (i=0;i<nbinx;i+=1)
			//	if(i==k)
			//		fprintf filenum2, ",%d",k		// Beta-gamma histogram value new way of saving
			//	else
						fprintf filenum2, ",%d",mca2D[k][i]		// Beta-gamma histogram value new way of saving
			//	endif
			endfor
			fprintf filenum2, "\n"
		endfor
		close/a
//	endif
	
	
End

