#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.


//########################################################################
//
//	Pixie_CallHelp: Display help messages
//
//########################################################################
Function Pixie_CallHelp(ctrlName): ButtonControl
String ctrlname

	String topic
	Variable len,k
	

		len = strlen(ctrlname)
		topic = ctrlname[4,len-1] // Control Name must be "help" + (help topic); use "_" for space
	
		do 									// replace '_' by ' '
			k=strsearch(topic,"_",0)
			if (k>=0)
				topic[k,k]=" "
			endif
		while(k>=0)

		DisplayHelpTopic topic
		
End



//########################################################################
//
//	Pixie_Ctrl_CheckTrace:
//		Show/hide traces in a plot.
//
//########################################################################
Function Pixie_Ctrl_CheckTrace(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	Variable k,n
	String wav
	Silent 1
	k=strlen(ctrlName)
	n=str2num(ctrlName[k-1,k-1])
	wav=ctrlName
	if(checked)
		AppendToGraph $("root:pixie4:"+wav)
		do
			if(n==1)
				ModifyGraph rgb($wav)=(0,65280,0)
			endif
			if(n==2)
				ModifyGraph rgb($wav)=(0,15872,65280)
			endif
			if(n==3)
				ModifyGraph rgb($wav)=(0,26112,0)
			endif
			if(cmpstr(wav,"MCASum")==0)
				ModifyGraph rgb($wav)=(0,0,0)
			endif
		while(0)
		ModifyGraph mode=6
		ModifyGraph grid=1
		ModifyGraph mirror(bottom)=2
		ModifyGraph mirror(left)=2
	else
		RemoveFromGraph/Z $(wav)
		wav="fit_"+wav
		RemoveFromGraph/Z $(wav)
	endif

End


//########################################################################
//
//	Pixie_Ctrl_CheckTraceXL: 
//      show/hide traces on plots
//
//########################################################################

Function Pixie_Ctrl_CheckTraceXL(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked
	Variable k,n
	String wav
	
	if(cmpstr("MCAchRefShow",ctrlName)==0)
		if(checked)
			RemoveFromGraph/Z MCAref			// remove first to ensure no duplicates
			RemoveFromGraph/Z MCAref_fit
			AppendToGraph $("root:pixie4:MCAref")
			ModifyGraph lstyle(MCAref)=3,lsize(MCAref)=2
			ModifyGraph rgb(MCAref)=(65535,0,52428)
		else
			RemoveFromGraph/Z MCAref			// remove 
			RemoveFromGraph/Z MCAref_fit
		endif
		return(0)
	endif
	
	Silent 1
	k=strlen(ctrlName)
	n=str2num(ctrlName[k-1,k-1])
	wav=ctrlName
	if(checked)
		AppendToGraph $("root:pixie4:"+wav)
		do
			if(n==1)
				ModifyGraph rgb($wav)=(0,65280,0)
			endif
			if(n==2)
				ModifyGraph rgb($wav)=(0,15872,65280)
			endif
			if(n==3)
				ModifyGraph rgb($wav)=(0,26112,0)
			endif
			if(n==4)
				ModifyGraph rgb($wav)=(0,0,0)
			endif
			if(n==5)
				ModifyGraph rgb($wav)=(65280,49152,16384)
			endif
			if(n==6)
				ModifyGraph rgb($wav)=(36864,14592,58880)
			endif
			if(n==7)
				ModifyGraph rgb($wav)=(0,52224,52224)
			endif
		while(0)
		ModifyGraph mode=6
		ModifyGraph grid=1
		ModifyGraph mirror(bottom)=2
		ModifyGraph mirror(left)=2
	else
		RemoveFromGraph/Z $(wav)
		wav="fit_"+wav
		RemoveFromGraph/Z $(wav)
	endif

End


//########################################################################
//
//	Pixie_Ctrl_DAQ1clk:
//		Handle button  for all-in-one DAQ
//
//########################################################################
Function Pixie_Ctrl_DAQ1clk(ctrlName) : ButtonControl
	String ctrlName
	
	Nvar  Run_Time  =  root:pixie4:Run_Time 
	
	variable RT
	// Enable UDP
	Pixie_Ctrl_WebIO("webenaudp")
	
	// Start DAQ (timed)
	Pixie_Ctrl_WebIO("webstartdaq")
	
	for(RT=Run_Time;RT>0;RT-=2)
		sleep/S/C=4 2
		printf "RT remaining: %d ",RT
		Pixie_Ctrl_WebIO("webpolludp")
		DoUpdate
	endfor
	
	
	// Stop DAQ (if timed -- no need to stop)
	//Pixie_Ctrl_CommonButton("webstartdaq")
	
	// Disable UDP
	Pixie_Ctrl_WebIO("webdisudp")
	
End


//########################################################################
//
//	Pixie_Ctrl_CommonButton:
//		Handle button click routines.
//
//########################################################################
Function Pixie_Ctrl_CommonButton(ctrlName) : ButtonControl
	String ctrlName

	// global variables and waves
	Wave ADCch0 = root:pixie4:ADCch0
	Wave ADCch1 = root:pixie4:ADCch1
	Wave ADCch2 = root:pixie4:ADCch2
	Wave ADCch3 = root:pixie4:ADCch3
	Svar lmfilename = root:pixie4:lmfilename
	
	Nvar PlotCh0 
	Nvar PlotCh1 
	Nvar PlotCh2 
	Nvar PlotCh3
	Nvar PlotCh4 
	Nvar PlotCh5 
	Nvar PlotCh6 
	Nvar PlotCh7	

	// local variables
	Variable len,filnum,i,j,totaltraces,ret,searchStr,lastcolonPos,dt,tmax,tmin,old_tau
	Variable 	xleftold, xrightold, xdiff, xleftnew, xrightnew
	Variable 	 foundpulse, fref

	StrSwitch(ctrlName)
	
		CAse "EventList":
			Execute "Pixie_Table_EventList()"
			break
	
		Case "Rebin_Tdiff":
			Pixie_Tdiff_histo()
			break
			
		Case "Fit_Tdiff":
			wave W_Coef
			String wavesinplot, wfname
			Variable Nwaves, m
			Nvar RTlow = root:LM:RTlow
			Svar CFDsource  =  root:LM:CFDsource
			Execute "Pixie_Plot_Thisto()"
			wavesinplot = TraceNameList("Tdiffhisto",",",1)
			Nwaves = ItemsInList(wavesinplot,",")
			for(m=0;m<Nwaves;m+=1)
				wfname = StringFromList(m,wavesinplot,",")
				if( stringmatch(wfname,"fit_*") ==0)			// only fit the histos, not any fits that are already in the plot
					Wave histo = $("root:LM:"+wfname)		// default: wave in Tdiff folder
					if(WaveExists(histo)==0)
						Wave histo = $(wfname)						// but top level saved copies may exist also
					endif
					if(WaveExists(histo)==1)
						CurveFit/q/NTHR=0/TBOX=0 gauss histo [pcsr(A),pcsr(B)] /D 
						//print wfname,"(CFD from", CFDsource,", Igor cfd =",RTlow,")"
						print wfname,"- CFD from", CFDsource
						print "peak position (ns):",W_Coef[2] 
						print "FWHM (ps):",W_coef[3]*2*sqrt(ln(2))*1000
					endif
				endif
			endfor
			
			return(0)
			break
		
	
		Case "Plot_Thisto":
			Execute "Pixie_Plot_Thisto()"
			break
	
		Case "Compute_Tdiff":
			Pixie_Tdiff_compute_diff()
			break
	
		Case "Table_LMList":
			Execute "Pixie_Table_LMList()"
			break
	
		Case "LMcleanup":
			Execute "Pixie_Cleanup()"
			break
					
		Case "ReadSortLMigor":
			Pixie_File_ReadAsListIgor(1)
			break
	
		Case "ReadSortLM4xx":
			Pixie_File_ReadAsList4xx()
			break
	
		Case "ReadSortLM11x":
			Pixie_File_ReadAsList11x()
			break		
			
		Case "ShowIPtable":
			Execute "Pixie_Table_IP()"
			break
	
		Case "showsettings":
			Execute "Pixie_Table_Settings()"
			break	
			
		Case "ADCDisplaySave":
			save/t root:pixie4:adcch0, root:pixie4:adcch1, root:pixie4:adcch2, root:pixie4:adcch3, root:pixie4:adcch4, root:pixie4:adcch5, root:pixie4:adcch6, root:pixie4:adcch7 as "Oscilloscope.itx"
			break	
			

		Case "FFTDisplay":	
			Execute "Pixie_Plot_FFTdisplay()"
			break
			
		Case "FilterFFT":		
			Pixie_FilterFFT()
			break
					
		Case "AutoScaleMCA":			
			SetAxis/A/W=MCASpectrumDisplay
			break
			
		Case "ResetScaleMCA":
					
			wave MCAch0 = root:pixie4:MCAch0
			wave MCAch1 = root:pixie4:MCAch1
			wave MCAch2 = root:pixie4:MCAch2
			wave MCAch3 = root:pixie4:MCAch3
			wave MCAsum = root:pixie4:MCAsum
			wave MCAscale = root:pixie4:MCAscale
			wave MCAStartFitChannel = root:pixie4:MCAStartFitChannel
			wave MCAEndFitChannel = root:pixie4:MCAEndFitChannel
			wave MCAChannelPeakPos = root:pixie4:MCAChannelPeakPos
			wave MCAChannelFWHMAbsolute = root:pixie4:MCAChannelFWHMAbsolute
			setscale/P x, 0,1, MCAch0
			setscale/P x, 0,1, MCAch1
			setscale/P x, 0,1, MCAch2
			setscale/P x, 0,1, MCAch3
			setscale/P x, 0,1, MCAsum
			
			MCAStartFitChannel/=MCAscale
			MCAEndFitChannel/=MCAscale
			MCAChannelPeakPos/=MCAscale
			MCAChannelFWHMAbsolute/=MCAscale
			
			MCAscale = 1
			Pixie_MakeList_MCA(1)
			break
			
		Case "ZoomInMCA":
		
			GetAxis/Q/W=MCASpectrumDisplay bottom
			xleftold = V_min
			xrightold = V_max
			xdiff = xrightold - xleftold
			
			xleftnew = xleftold + xdiff*0.1
			xrightnew = xrightold - xdiff*0.1
			
			if(xrightnew > xleftnew)
				SetAxis/W=MCASpectrumDisplay bottom xleftnew, xrightnew
				SetAxis/A/W=MCASpectrumDisplay left
			endif
			break		
			
		Case "ZoomOutMCA":
		
			GetAxis/Q/W=MCASpectrumDisplay bottom
			xleftold = V_min
			xrightold = V_max
			xdiff = xrightold - xleftold
			
			xleftnew = xleftold - xdiff*0.1
			xrightnew = xrightold + xdiff*0.1
			
			SetAxis/W=MCASpectrumDisplay bottom xleftnew, xrightnew
			SetAxis/A/W=MCASpectrumDisplay left
			break		

		Case "ZoomMCAToCursors":
		
			if(xcsr(A) < xcsr(B))
				xleftold = xcsr(A)
				xrightold = xcsr(B)
			else
				xleftold = xcsr(B)
				xrightold = xcsr(A)
			endif
			
			GetAxis/Q/W=MCASpectrumDisplay bottom
			// Make sure Cursors are really on the graph
			if((xleftold >= V_min) && (xrightold <= V_max))
			
				xdiff = xrightold - xleftold
				
				xleftnew = xleftold - xdiff*0.05
				xrightnew = xrightold + xdiff*0.05
				
				SetAxis/W=MCASpectrumDisplay bottom xleftnew, xrightnew
				SetAxis/A/W=MCASpectrumDisplay left 
			endif
					
			break
			
		Case "TauClear":
		
			Nvar LastTau = root:pixie4:LastTau	// Clear LastTau and TauDeviation
			Nvar TauDeviation = root:pixie4:TauDeviation
			TauDeviation = 0 
			LastTau = 0
			RemoveFromGraph/W= Pixie4Oscilloscope/Z Res_ADCch0
			RemoveFromGraph/W= Pixie4Oscilloscope/Z Res_ADCch1
			RemoveFromGraph/W= Pixie4Oscilloscope/Z Res_ADCch2
			RemoveFromGraph/W= Pixie4Oscilloscope/Z Res_ADCch3
			RemoveFromGraph/W= Pixie4Oscilloscope/Z fit_ADCch0
			RemoveFromGraph/W= Pixie4Oscilloscope/Z fit_ADCch1
			RemoveFromGraph/W= Pixie4Oscilloscope/Z fit_ADCch2
			RemoveFromGraph/W= Pixie4Oscilloscope/Z fit_ADCch3
			
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch0
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch1
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch2
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch3
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch4
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch5
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch6
			RemoveFromGraph/W= OscilloscopeXL/Z Res_ADCch7
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch0
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch1
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch2
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch3
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch4
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch5
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch6
			RemoveFromGraph/W= OscilloscopeXL/Z fit_ADCch7
			break
			
		Case "FindTraceDataFile":
			String fileFilters = "Data Files (*.txt,*.dat,*.b00,*.dt2,*.dt3,*.bin):.txt,.dat,.b00,.dt2,.dt3,.bin;"
			open/D/R/M="Select LM file"/F=fileFilters/P=home fref
			lmfilename  = S_fileName
			break
			
		Case "ADCRefresh":
		Case "ADCFilterDisplayRefresh":
			ret = Pixie_IO_Serial("gettraces")
			Sleep/T 20
			if(ret>=0)
				Pixie_IO_ReadADCMCA("ADC")
			endif
			break
			
		Case "AdjustDC":
			ret = Pixie_IO_Serial("findsettings")
			if(ret>=0) 
				Pixie_IO_Serial("gettraces")
				Pixie_IO_ReadADCMCA("ADC")
			endif
			break
			
		Case "ADCDisplayCapture":
			foundpulse = 0
			do
				ret = Pixie_IO_Serial("gettraces")
				if(ret>=0)
					Pixie_IO_ReadADCMCA("ADC")
					DoUpdate
					wavestats/q ADCch0 
					if( (V_max - V_min) > 100)
						foundpulse =1
					endif
					wavestats/q ADCch1 
					if( (V_max - V_min) > 100)
						foundpulse =1
					endif
					wavestats/q ADCch2 
					if( (V_max - V_min) > 100)
						foundpulse =1
					endif
					wavestats/q ADCch3 
					if( (V_max - V_min) > 100)
						foundpulse =1
					endif
				else
					foundpulse =1	// exit if serial I/O not working
				endif
			while (foundpulse==0)
			break
			
				// --------------------- display control buttons --------------------------
		
		
		Case "Show8adc":
			Pixie_Ctrl_CheckTraceXL("ADCch0",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch0",1)
			Checkbox ADCch0, value=1
			Pixie_Ctrl_CheckTraceXL("ADCch1",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch1",1)
			Checkbox ADCch1, value=1
			Pixie_Ctrl_CheckTraceXL("ADCch2",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch2",1)
			Checkbox ADCch2, value=1
			Pixie_Ctrl_CheckTraceXL("ADCch3",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch3",1)
			Checkbox ADCch3, value=1
			Pixie_Ctrl_CheckTraceXL("ADCch4",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch4",1)
			Checkbox ADCch4, value=1
			Pixie_Ctrl_CheckTraceXL("ADCch5",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch5",1)
			Checkbox ADCch5, value=1
			Pixie_Ctrl_CheckTraceXL("ADCch6",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch6",1)
			Checkbox ADCch6, value=1
			Pixie_Ctrl_CheckTraceXL("ADCch7",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("ADCch7",1)
			Checkbox ADCch7, value=1
			break
		
		
		Case "Hide8adc":
			Pixie_Ctrl_CheckTraceXL("ADCch0",0)		
			Checkbox ADCch0, value=0
			Pixie_Ctrl_CheckTraceXL("ADCch1",0)		
			Checkbox ADCch1, value=0
			Pixie_Ctrl_CheckTraceXL("ADCch2",0)		
			Checkbox ADCch2, value=0
			Pixie_Ctrl_CheckTraceXL("ADCch3",0)		
			Checkbox ADCch3, value=0
			Pixie_Ctrl_CheckTraceXL("ADCch4",0)	
			Checkbox ADCch4, value=0
			Pixie_Ctrl_CheckTraceXL("ADCch5",0)		
			Checkbox ADCch5, value=0
			Pixie_Ctrl_CheckTraceXL("ADCch6",0)		
			Checkbox ADCch6, value=0
			Pixie_Ctrl_CheckTraceXL("ADCch7",0)		
			Checkbox ADCch7, value=0
			break
		
		
		Case "Show8mca":
			Pixie_Ctrl_CheckTraceXL("MCAch0",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch0",1)
			Checkbox MCAch0, value=1
			Pixie_Ctrl_CheckTraceXL("MCAch1",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch1",1)
			Checkbox MCAch1, value=1
			Pixie_Ctrl_CheckTraceXL("MCAch2",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch2",1)
			Checkbox MCAch2, value=1
			Pixie_Ctrl_CheckTraceXL("MCAch3",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch3",1)
			Checkbox MCAch3, value=1
			Pixie_Ctrl_CheckTraceXL("MCAch4",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch4",1)
			Checkbox MCAch4, value=1
			Pixie_Ctrl_CheckTraceXL("MCAch5",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch5",1)
			Checkbox MCAch5, value=1
			Pixie_Ctrl_CheckTraceXL("MCAch6",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch6",1)
			Checkbox MCAch6, value=1
			Pixie_Ctrl_CheckTraceXL("MCAch7",0)		// hide first, then show to avoid duplicates
			Pixie_Ctrl_CheckTraceXL("MCAch7",1)
			Checkbox MCAch7, value=1
			break
		
		
		Case "Hide8mca":
			Pixie_Ctrl_CheckTraceXL("MCAch0",0)		
			Checkbox MCAch0, value=0
			Pixie_Ctrl_CheckTraceXL("MCAch1",0)		
			Checkbox MCAch1, value=0
			Pixie_Ctrl_CheckTraceXL("MCAch2",0)		
			Checkbox MCAch2, value=0
			Pixie_Ctrl_CheckTraceXL("MCAch3",0)		
			Checkbox MCAch3, value=0
			Pixie_Ctrl_CheckTraceXL("MCAch4",0)	
			Checkbox MCAch4, value=0
			Pixie_Ctrl_CheckTraceXL("MCAch5",0)		
			Checkbox MCAch5, value=0
			Pixie_Ctrl_CheckTraceXL("MCAch6",0)		
			Checkbox MCAch6, value=0
			Pixie_Ctrl_CheckTraceXL("MCAch7",0)		
			Checkbox MCAch7, value=0
			break
		
		
		Case "Remove8fit":
			RemoveFromGraph/Z fit_MCAch0,fit_MCAch1,fit_MCAch2,fit_MCAch3
			RemoveFromGraph/Z fit_MCAch4,fit_MCAch5,fit_MCAch7,fit_MCAch6
			break
		
		Case "Next8mca":
			if(PlotCh0<8)
				PlotCh0+=8
				PlotCh1+=8
				PlotCh2+=8
				PlotCh3+=8
				PlotCh4+=8
				PlotCh5+=8
				PlotCh6+=8
				PlotCh7+=8
			endif
			// update  plot
			Pixie_Ctrl_SetDisplayChannel("MCAch0sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch1sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch2sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch3sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch4sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch5sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch6sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch7sv", 0,"","")		
			break
		
		
		Case "Prev8mca":
			if(PlotCh0>=8)
				PlotCh0-=8
				PlotCh1-=8
				PlotCh2-=8
				PlotCh3-=8
				PlotCh4-=8
				PlotCh5-=8
				PlotCh6-=8
				PlotCh7-=8
			endif
			// update  plot
			Pixie_Ctrl_SetDisplayChannel("MCAch0sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch1sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch2sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch3sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch4sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch5sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch6sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("MCAch7sv", 0,"","")
			break
		
	
		Case "Next8adc":
			if(PlotCh0<8)
				PlotCh0+=8
				PlotCh1+=8
				PlotCh2+=8
				PlotCh3+=8
				PlotCh4+=8
				PlotCh5+=8
				PlotCh6+=8
				PlotCh7+=8
			endif
			// update  plot
			Pixie_Ctrl_SetDisplayChannel("ADCch0sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch1sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch2sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch3sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch4sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch5sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch6sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch7sv", 0,"","")
			break
		
		
		Case "Prev8adc":
			if(PlotCh0>=8)
				PlotCh0-=8
				PlotCh1-=8
				PlotCh2-=8
				PlotCh3-=8
				PlotCh4-=8
				PlotCh5-=8
				PlotCh6-=8
				PlotCh7-=8
			endif
			// update  plot
			Pixie_Ctrl_SetDisplayChannel("ADCch0sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch1sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch2sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch3sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch4sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch5sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch6sv", 0,"","")
			Pixie_Ctrl_SetDisplayChannel("ADCch7sv", 0,"","")
			break
			
		Case "noise":
			variable ch
			for(ch=0;ch<8;ch+=1)
				Wave adc = $("root:pixie4:adcch"+num2str(ch))
				wavestats/q adc
				print "Noise",ch,V_sdev
				
			endfor
			break
	

	
					
		Default:
			break
	EndSwitch
	
End




//########################################################################
//
//	Pixie_Ctrl_CommonPopup:
//		Handle popup menu changes.
//
//########################################################################
Function Pixie_Ctrl_CommonPopup(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr

	// global variables and waves
	Nvar MCAfitOption =  root:pixie4:MCAfitOption
	

	StrSwitch(ctrlName)
	
		Case "MCAFitOptionsXL":
			MCAfitOption = popnum
			PopupMenu MCAFitOptions, mode=popnum, win = MCASpectrumDisplayXL
			break	
			
		Case "MCAFitOptions":
			MCAfitOption = popnum
			PopupMenu MCAFitOptions, mode=popnum, win = MCASpectrumDisplay
			break				
			
		Case "TauFit":
			Pixie_Math_TauFit(popnum-1)
			break			
			
		Case "LMRefSelect":
			Wave src = $("root:pixie4:trace"+num2str(popnum-1))
			duplicate/o src, root:pixie4:traceRef
			Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
			Wave ListModeChannelTrigger=root:pixie4:ListModeChannelTrigger
			Wave ListModeChannelXIA=root:pixie4:ListModeChannelXIA
			Wave ListModeChannelUser=root:pixie4:ListModeChannelUser
			ListModeChannelEnergy[4] = ListModeChannelEnergy[popnum-1]
			ListModeChannelTrigger[4] = ListModeChannelTrigger[popnum-1]
			ListModeChannelXIA[4] = ListModeChannelXIA[popnum-1]
			ListModeChannelUser[4] = ListModeChannelUser[popnum-1]
			Pixie_MakeList_Traces(1)
			break
			
		Case "MCARefSelect":
			Wave src = $("root:pixie4:mcach"+num2str(popnum-1))
			duplicate/o src, root:pixie4:MCAref
			Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
			Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
			Wave MCAFitRange=root:pixie4:MCAFitRange
			Wave MCAscale=root:pixie4:MCAscale
			Wave MCAChannelPeakPos=root:pixie4:MCAChannelPeakPos
			Wave MCAChannelPeakEnergy=root:pixie4:MCAChannelPeakEnergy
			Wave MCAChannelFWHMPercent=root:pixie4:MCAChannelFWHMPercent
			Wave MCAChannelFWHMAbsolute=root:pixie4:MCAChannelFWHMAbsolute
			Wave MCAChannelPeakArea=root:pixie4:MCAChannelPeakArea
			MCAStartFitChannel[4] = MCAStartFitChannel[popnum-1]
			MCAEndFitChannel[4] = MCAEndFitChannel[popnum-1]
			MCAFitRange[4] = MCAFitRange[popnum-1]
			MCAscale[4] = MCAscale[popnum-1]			
			MCAChannelPeakPos[4] = MCAChannelPeakPos[popnum-1]
			MCAChannelPeakEnergy[4] = MCAChannelPeakEnergy[popnum-1]
			MCAChannelFWHMPercent[4] = MCAChannelFWHMPercent[popnum-1]
			MCAChannelFWHMAbsolute[4] = MCAChannelFWHMAbsolute[popnum-1]
			MCAChannelPeakArea[4] = MCAChannelPeakArea[popnum-1]		
			
			Pixie_MakeList_MCA(1)
			break
			
		Case "LMSRefSelect":
			Wave src = $("root:pixie4:spectrum"+num2str(popnum-1))
			duplicate/o src, root:pixie4:spectrumRef
			Wave ListStartFitChannel=root:pixie4:ListStartFitChannel
			Wave ListEndFitChannel=root:pixie4:ListEndFitChannel
			Wave ListChannelPeakPos=root:pixie4:ListChannelPeakPos
			Wave ListChannelFWHMPercent=root:pixie4:ListChannelFWHMPercent
			Wave ListChannelPeakArea=root:pixie4:ListChannelPeakArea
			ListStartFitChannel[4] = ListStartFitChannel[popnum-1]
			ListEndFitChannel[4] = ListEndFitChannel[popnum-1]
			ListChannelPeakPos[4] = ListChannelPeakPos[popnum-1]
			ListChannelFWHMPercent[4] = ListChannelFWHMPercent[popnum-1]			
			ListChannelPeakArea[4] = ListChannelPeakArea[popnum-1]
			
			Pixie_MakeList_LMHisto()
			break
			
							
		Default:
			break
	Endswitch
	
End







//########################################################################
//
//	Pixie_Ctrl_CommonSetVariable:
//		Handle variable value changes.
//
//########################################################################
Function Pixie_Ctrl_CommonSetVariable(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum

	// global variables and waves
	Nvar HistoEmin = root:pixie4:HistoEmin
	Nvar HistoDE = root:pixie4:HistoDE
	Nvar NHistoBins = root:pixie4:NHistoBins			
	Nvar ChosenChannel = root:pixie4:ChosenChannel
	Wave Emink=root:pixie4:Emink
	Wave dxk=root:pixie4:dxk
	Wave Nbink=root:pixie4:Nbink	
	
	StrSwitch(ctrlName)
		Case "SetHistoEmin":
		
			Emink[ChosenChannel]=HistoEmin
			break
			
		Case "SetHistoDE":
		
			dxk[ChosenChannel]=HistoDE		
			break
			
		Case "SetNbin":
		
			Nbink[ChosenChannel]=NHistoBins		
			break
				
		Case "CallReadEvents":
		
			Pixie_File_ReadEvent()
			break
						
		Default:
			break
	EndSwitch

End




//########################################################################
//
//	Pixie_Ctrl_SelectModChan: 
//      Switch between modules or channels
//
//########################################################################
Function Pixie_Ctrl_SelectModChan(ctrlName,varNum,varStr,varName) : SetVariableControl
String ctrlName
Variable varNum
String varStr
String varName

	Nvar ChosenModule = root:pixie4:ChosenModule
	Nvar ChosenChannel = root:pixie4:ChosenChannel
	Nvar NumberOfChannels = root:pixie4:NumberOfChannels
	Nvar NumberOfModules = root:pixie4:NumberOfModules

	Nvar FilterClockMHz = root:pixie4:FilterClockMHz

	Nvar HistoEmin = root:pixie4:HistoEmin
	Nvar HistoDE = root:pixie4:HistoDE
	Nvar NHistoBins = root:pixie4:NHistoBins
			
	Wave Channel_Parameter_Values = root:pixie4:Channel_Parameter_Values
	Wave Module_Parameter_Values = root:pixie4:Module_Parameter_Values
	Wave mcawave = root:pixie4:mcawave
	Wave Emink = root:pixie4:Emink
	Wave dxk = root:pixie4:dxk
	Wave Nbink = root:pixie4:Nbink


	Variable dt, tmin, tmax,i,strpos
	String str
	
	if(ChosenModule>(NumberOfModules-1))
		ChosenModule = (NumberOfModules-1)
	endif
	
	
		// Update TraceFFT display
		String wav
		wav="root:pixie4:ADCch"+num2str(ChosenChannel)
		Pixie_FFTtrace($wav)
		DoWindow/F FFTDisplay	
		if (V_Flag==1)
			Switch(ChosenChannel)
				Case 0:
					ModifyGraph rgb(TraceFFT)=(65280,0,0)
					break				
				Case 1:
					ModifyGraph rgb(TraceFFT)=(0,65280,0)
					break
				Case 2:
					ModifyGraph rgb(TraceFFT)=(0,15872,65280)
					break			
				Case 3:
					ModifyGraph rgb(TraceFFT)=(0,26112,0)
					break
			EndSwitch
		endif
	
	
		// Update ADC Filter display
		wav="root:pixie4:ADCch"+num2str(ChosenChannel)
		Pixie_FilterADCTraceCalc($wav)
		DoWindow/F ADCFilterDisplay	
		if (V_Flag==1)
			Switch(ChosenChannel)
				Case 0:
					ModifyGraph rgb(TraceFilter)=(65280,0,0)
					break				
				Case 1:
					ModifyGraph rgb(TraceFilter)=(0,65280,0)
					break
				Case 2:
					ModifyGraph rgb(TraceFilter)=(0,15872,65280)
					break			
				Case 3:
					ModifyGraph rgb(TraceFilter)=(0,26112,0)
					break
			EndSwitch
		endif
	
	// Update Digital Filter (list mode trace) display
	DoWindow/F Pixie4FilterDisplay
	if(V_Flag == 1)
		Pixie_FilterLMTraceCalc()
	endif
	
	// Update histogram controls on list mode spectrum display
	HistoEmin = Emink[ChosenChannel]
	HistoDE = dxk[ChosenChannel]
	NHistoBins = Nbink[ChosenChannel]
	
	//////////////////////////////////////////////////////////// 
	// Call to user routine			             //
		User_ChangeChannelModule()
	////////////////////////////////////////////////////////////	

End




//########################################################################
//
//	Pixie_Ctrl_SetDisplayChannel:
//		Choose the channel to display.
//
//########################################################################
Function Pixie_Ctrl_SetDisplayChannel(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum
	
	Nvar PlotCh0 
	Nvar PlotCh1 
	Nvar PlotCh2 
	Nvar PlotCh3
	Nvar PlotCh4 
	Nvar PlotCh5 
	Nvar PlotCh6 
	Nvar PlotCh7  
	Nvar ModuleTypeXL = root:pixie4:ModuleTypeXL
	
	string wvname
	String ComStr
	
	
	StrSwitch(ctrlName)		
		Case "MCAch0sv":
			sprintf wvname "MCAch%d", PlotCh0
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch0
			break
			
		Case "MCAch1sv":
			sprintf wvname "MCAch%d", PlotCh1
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch1
			break
			
		Case "MCAch2sv":
			sprintf wvname "MCAch%d", PlotCh2
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch2
			break
				
		Case "MCAch3sv":
			sprintf wvname "MCAch%d", PlotCh3
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch3
			break
			
		Case "MCAch4sv":
			sprintf wvname "MCAch%d", PlotCh4
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch4
			break			
			
		Case "MCAch5sv":
			sprintf wvname "MCAch%d", PlotCh5
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch5
			break			
		
		Case "MCAch6sv":
			sprintf wvname "MCAch%d", PlotCh6
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch6
			break
			
		Case "MCAch7sv":
			sprintf wvname "MCAch%d", PlotCh7
			wave wav = $wvname
			duplicate/o wav root:pixie4:MCAch7
			break						
				
		Case "ADCch0sv":
			sprintf wvname "adc%d", PlotCh0
			wave wav = $wvname
			duplicate/o wav root:pixie4:ADCch0
			break
			
		Case "ADCch1sv":
			sprintf wvname "adc%d", PlotCh1
			wave wav = $wvname
			duplicate/o wav root:pixie4:ADCch1
			break
			
		Case "ADCch2sv":
			sprintf wvname "adc%d", PlotCh2
			wave wav = $wvname
			duplicate/o wav root:pixie4:ADCch2
			break
			
		Case "ADCch3sv":
			sprintf wvname "adc%d", PlotCh3
			wave wav = $wvname
			duplicate/o wav root:pixie4:ADCch3
			break	
			
		Case "ADCch4sv":
			if(!ModuleTypeXL)
				break
			else
				sprintf wvname "adc%d", PlotCh4
				wave wav = $wvname
				duplicate/o wav root:pixie4:ADCch4
				break
			endif
			
			
		Case "ADCch5sv":
			if(!ModuleTypeXL)
				break
			else
				sprintf wvname "adc%d", PlotCh5
				wave wav = $wvname
				duplicate/o wav root:pixie4:ADCch5
				break
			endif

			
		Case "ADCch6sv":
			if(!ModuleTypeXL)
				break
			else
				sprintf wvname "adc%d", PlotCh6
				wave wav = $wvname
				duplicate/o wav root:pixie4:ADCch6
				break
			endif

			
		Case "ADCch7sv":
			if(!ModuleTypeXL)
				break
			else
				sprintf wvname "adc%d", PlotCh7
				wave wav = $wvname
				duplicate/o wav root:pixie4:ADCch7
				break					
			endif

						
		Default:
			break
	EndSwitch	
	
End






//########################################################################
//
//	Pixie_Ctrl_CommonButton:
//		Handle button click routines.
//
//########################################################################
//Function PN_Ctrl_CommonButton(ctrlName) : ButtonControl
//	String ctrlName
//
//	Wave ADCch0 = root:pixie4:ADCch0
//	Wave ADCch1 = root:pixie4:ADCch1
//	Wave ADCch2 = root:pixie4:ADCch2
//	Wave ADCch3 = root:pixie4:ADCch3
//	
//	Svar lmfilename = root:pixie4:lmfilename
//
//	// local variables
//	Variable 	 foundpulse, fref, ret
//	
//	StrSwitch(ctrlName)
//	
//		Case "FindTraceDataFile":
//			String fileFilters = "Data Files (*.txt,*.dat,*.b00,*.dt2,*.dt3,*.bin):.txt,.dat,.b00,.dt2,.dt3,.bin;"
//			open/D/R/M="Select LM file"/F=fileFilters/P=home fref
//			lmfilename  = S_fileName
//			break
//			
//		Case "ADCRefresh":
//		Case "ADCFilterDisplayRefresh":
//			ret = Pixie_IO_Serial("gettraces")
//			Sleep/T 20
//			if(ret>=0)
//				Pixie_IO_ReadADCMCA("ADC")
//			endif
//			break
//			
//		Case "AdjustDC":
//			ret = Pixie_IO_Serial("findsettings")
//			if(ret>=0) 
//				Pixie_IO_Serial("gettraces")
//				Pixie_IO_ReadADCMCA("ADC")
//			endif
//			break
//			
//		Case "ADCDisplayCapture":
//			foundpulse = 0
//			do
//				ret = Pixie_IO_Serial("gettraces")
//				if(ret>=0)
//					Pixie_IO_ReadADCMCA("ADC")
//					DoUpdate
//					wavestats/q ADCch0 
//					if( (V_max - V_min) > 100)
//						foundpulse =1
//					endif
//					wavestats/q ADCch1 
//					if( (V_max - V_min) > 100)
//						foundpulse =1
//					endif
//					wavestats/q ADCch2 
//					if( (V_max - V_min) > 100)
//						foundpulse =1
//					endif
//					wavestats/q ADCch3 
//					if( (V_max - V_min) > 100)
//						foundpulse =1
//					endif
//				else
//					foundpulse =1	// exit if serial I/O not working
//				endif
//			while (foundpulse==0)
//			break
//			
//		Default:
//			break
//	EndSwitch
//	
//End


//########################################################################
//
// Pixie_Ctrl_WebIO
//		Button Control for web IO fucntions
//
//########################################################################
Function Pixie_Ctrl_WebIO(ctrlName) : ButtonControl
	String ctrlName
	
	// some commands loop over all units, optionally. Define loop here 
	Nvar apply_all = root:pixie4:apply_all
	Nvar warnings = root:pixie4:warnings 
	Nvar Nmodules = root:pixie4:Nmodules
	Nvar ModNum = root:pixie4:ModNum
	Nvar MaxNchannelsPNXL = root:pixie4:MaxNchannelsPNXL
	Nvar MaxNchannelsPN = root:pixie4:MaxNchannelsPN
	Nvar ADCTraceLen = root:pixie4:ADCTraceLen
	Nvar ModuleTypeXL = root:pixie4:ModuleTypeXL
	Nvar Run_Type = root:pixie4:Run_Type     
	Nvar Run_Time = root:pixie4:Run_Time
	Nvar Data_Flow = root:pixie4:Data_Flow
	Nvar WR_RT_CTRL = root:pixie4:WR_RT_CTRL
	Nvar WRdelay = root:pixie4:WRdelay	
	Nvar Zynq_CSR = root:pixie4:Zynq_CSR
	Nvar WR_TM_TAI = root:pixie4:WR_TM_TAI
	Svar ServerResponse=  root:pixie4:ServerResponse
	
	wave polarity     = root:pixie4:polarity
	wave voffset      = root:pixie4:voffset
	wave analog_gain  = root:pixie4:analog_gain
	wave digital_gain = root:pixie4:digital_gain
	wave tau          = root:pixie4:tau

	Wave/t MZ_ip   = root:pixie4:MZ_ip
	Wave/t MZ_user = root:pixie4:MZ_user 
	Wave/t MZ_pw   = root:pixie4:MZ_pw 
	
	Variable mo, ch, sa,refNum, MaxNchannels
	String cmd, cmdwrite, chval, wvname, fullFilePath
	Variable webio =0
	
	Variable Mstart, Mend
	if(apply_all)
		Mstart = 0
		Mend = Nmodules
	else
		Mstart = ModNum
		Mend = ModNum+1
	endif
	
	if(ModuleTypeXL)
		MaxNchannels = MaxNchannelsPNXL
	else
		MaxNchannels = MaxNchannelsPN
	endif
	
	
	
	if(cmpstr(ctrlName,"haltssh")==0)	
		DoAlert 0, "Programmatic shutdown is discouraged. Instead, this routine opens a cmd window for ssh - root to Pixie-Net. Please enter root password, then type 'halt' to shut down Linux. Type 'exit' to close cmd window."
		cmd = "ssh root@"+MZ_ip[ModNum]
		ExecuteScriptText cmd
	endif
		
	
	if(cmpstr(ctrlName,"webreadsettings")==0)
		cmd = "cgireadsettings.cgi"									// specify command
		mo = ModNum														// no loop for reading settings
		Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)		// execute

		// assign values to local arrays
		for(ch=0;ch<MaxNchannels;ch+=1)
			polarity[ch]     = str2num(StringFromList( 7+6*ch, ServerResponse, ","))
			voffset[ch]      = str2num(StringFromList( 8+6*ch, ServerResponse, ","))
			analog_gain[ch]  = str2num(StringFromList( 9+6*ch, ServerResponse, ","))
			digital_gain[ch] = str2num(StringFromList(10+6*ch, ServerResponse, ","))
			tau[ch]          = str2num(StringFromList(11+6*ch, ServerResponse, ","))
		endfor	
		// add runtype, run time
		variable dbg = 1+6*(MaxNchannels+1)

		if(ModuleTypeXL)
			// PNXL read data procedure reports the max. 32 channels of settings, therefore need MaxNchannels*2
			Run_Type =  str2num(StringFromList( 1+6*(MaxNchannels*2+1), ServerResponse, ","))  
			Run_Time =  str2num(StringFromList( 3+6*(MaxNchannels*2+1), ServerResponse, ","))
			Data_Flow =  str2num(StringFromList( 5+6*(MaxNchannels*2+1), ServerResponse, ","))   
			WR_RT_CTRL =  str2num(StringFromList( 7+6*(MaxNchannels*2+1), ServerResponse, ","))
		else
			Run_Type =  str2num(StringFromList( 1+6*(MaxNchannels+1), ServerResponse, ","))  
			Run_Time =  str2num(StringFromList( 3+6*(MaxNchannels+1), ServerResponse, ","))
			Data_Flow =   0
			WR_RT_CTRL = 0
		endif	
		
		// show in table
		Execute "Pixie_Table_Settings()"
		
		return(0)
	endif
	
	
	if(cmpstr(ctrlName,"webwritesettings")==0)	
		cmd = "cgiwritesettings.cgi"									// specify command
		
		// update the POLARITY parameter
		cmdwrite=cmd+"?CCSRA_INVERT_05=CHANNEL"					// add parameter name to IP string 
		for(ch=0;ch<MaxNchannels;ch+=1)
			sprintf chval,"&v%d=%d",ch, polarity[ch]		
			cmdwrite = cmdwrite + chval								// add parameter values to IP string
		endfor
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the VOFFSET parameter
		cmdwrite=cmd+"?VOFFSET=CHANNEL"
		for(ch=0;ch<MaxNchannels;ch+=1)
			sprintf chval,"&v%d=%4f",ch, voffset[ch]
			cmdwrite = cmdwrite + chval
		endfor
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the ANALOG_GAIN parameter
		cmdwrite=cmd+"?ANALOG_GAIN=CHANNEL"
		for(ch=0;ch<MaxNchannels;ch+=1)
			sprintf chval,"&v%d=%3f",ch, analog_gain[ch]
			cmdwrite = cmdwrite + chval
		endfor
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the DIG_GAIN parameter
		cmdwrite=cmd+"?DIG_GAIN=CHANNEL"
		for(ch=0;ch<MaxNchannels;ch+=1)
			sprintf chval,"&v%d=%3f",ch, digital_gain[ch]
			cmdwrite = cmdwrite + chval
		endfor
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the TAU parameter
		cmdwrite=cmd+"?TAU=CHANNEL"
		for(ch=0;ch<MaxNchannels;ch+=1)
			sprintf chval,"&v%d=%4f",ch, tau[ch]
			cmdwrite = cmdwrite + chval
		endfor
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the RUN_TYPE parameter
		cmdwrite=cmd+"?RUN_TYPE=MODULE"
		sprintf chval,"&v%d=0x%x",ch, Run_Type
		cmdwrite = cmdwrite + chval
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the REQ_RUNTIME parameter
		cmdwrite=cmd+"?REQ_RUNTIME=MODULE"
		sprintf chval,"&v%d=%d",ch, Run_Time
		cmdwrite = cmdwrite + chval
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the WR_RUNTIME_CTRL parameter
		cmdwrite=cmd+"?WR_RUNTIME_CTRL=MODULE"
		sprintf chval,"&v%d=%d",ch, WR_RT_CTRL
		cmdwrite = cmdwrite + chval
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		// update the DATA_FLOW parameter
		cmdwrite=cmd+"?DATA_FLOW=MODULE"
		sprintf chval,"&v%d=%d",ch, Data_Flow
		cmdwrite = cmdwrite + chval
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmdwrite,0)		// execute
		endfor
		
		return(0)
	endif
	
	
	if(cmpstr(ctrlName,"webprogfippi")==0)	
		cmd = "progfippi.cgi"
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)
		endfor
		return(0)
	endif
	
	
	if(cmpstr(ctrlName,"webadjust")==0)	
		DoAlert 0, "Offsets will be adjusted, but settings file will not be updated. See log for details." 
		if(ModuleTypeXL)
			cmd = "findsettings.cgi" //"rampdacs.cgi"
		else
			cmd = "findsettings.cgi"
		endif
		
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)
		endfor
		return(0)
	endif
	
	
	if(cmpstr(ctrlName,"webrefresh")==0)
		cmd = "cgiprinttraces.cgi"	
		mo = ModNum														// no loop for reading traces
		Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)		// execute
		
		// save to local file
		Open/D=2/M="Save File As..."/T="????" /P=home refNum as "localdataXL.csv"
		fullFilePath = S_fileName
		if (strlen(fullFilePath) > 0) // No error and user didn't cancel in dialog.
		// Open the selected file so that it can later be written to.
			Open/Z/T="????" refNum as fullFilePath
			if (V_flag != 0)
				Print "There was an error opening the local destination file."
			else
				FBinWrite refNum, ServerResponse
				Close refNum
			endif
		endif
		
		//read back from local file into top level waves
		Loadwave/J/O/A/W fullFilePath		// loads data into waves named by header
		
		//copy to display waves 
		Pixie_Ctrl_SetDisplayChannel("ADCch0sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch1sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch2sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch3sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch4sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch5sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch6sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch7sv", 0,"","")
		
		return(0)
	endif
	
	// ---------------- button functions for xop ---------------------
	
	if(cmpstr(ctrlName,"webenaudp")==0)	
		if(ModuleTypeXL==0)
			print "udp output not supported for Pixie-Net"
			return(0)
		endif

#if Exists("udp_receive_start")
		Button webenaudp,   disable=2, win=PNXLpanel
		Button webdisudp,   disable=0, win=PNXLpanel
		Pixie_IO_udp_start()
#else	
		print "udp xop not loaded into Igor, check Igor Extensions and/or try 64bit version of Igor?"
#endif
		return(0)
	endif
	
	
	if(cmpstr(ctrlName,"webdisudp")==0)	
		if(ModuleTypeXL==0)
			print "udp output not supported for Pixie-Net"
			return(0)
		endif
		
#if Exists("udp_receive_start")
		Button webenaudp,   disable=0, win=PNXLpanel
		Button webdisudp,   disable=2, win=PNXLpanel	
		Pixie_IO_udp_stop()
#else	
		print "udp xop not loaded into Igor, check Igor Extensions and/or try 64bit version of Igor?"
#endif
		return(0)
	endif
	
		
	if(cmpstr(ctrlName,"webpolludp")==0)	
		if(ModuleTypeXL==0)
			print "udp output not supported for Pixie-Net"
			return(0)
		endif
		
#if Exists("udp_receive_start")

		sa = Pixie_IO_udp_poll()
#else	
		print "udp xop not loaded into Igor, check Igor Extensions and/or try 64bit version of Igor?"
#endif
		return(sa)
	endif
	
	
	// ------------------- daq buttons ------------------------
	
	if(cmpstr(ctrlName,"webacquire")==0)
	
		if(ModuleTypeXL==1)
			print "acquire not supported for Pixie-Net XL"
			return(0)
		endif	
		
		if(warnings)
			DoAlert 0,"DAQ will execute for the specified time. Please wait for completion"
		else
			print "DAQ will execute for the specified time. Please wait for completion"
		endif
		
	
		cmd = "acquire.cgi" // default
		for(mo=Mstart; mo<Mend;mo+=1)	
		//mo = ModNum		// no looping; WebIO waits for complete run to execute, i.e. runs in multiple units would be started one after another 
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd, 1)	// wait for only 1s
		endfor
		
		return(0)
	
	endif
	
	
	if(cmpstr(ctrlName,"webcoincdaq")==0)	
	
		if(ModuleTypeXL==1)
			print "coincdaq not supported for Pixie-Net XL"
			return(0)
		endif
		
		if(warnings)
			DoAlert 0,"DAQ will execute for the specified time. Please wait for completion"
		else
			print "DAQ will execute for the specified time. Please wait for completion"
		endif
			
		cmd = "coincdaq.cgi" // default
		for(mo=Mstart; mo<Mend;mo+=1)	
		//mo = ModNum		// no looping; WebIO waits for complete run to execute, i.e. runs in multiple units would be started one after another 
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd, 1)	// wait for only 1s
		endfor
		
		return(0)
	
	endif
	
	
	
	if(cmpstr(ctrlName,"webmcadaq")==0)	
	
		if(warnings)
			DoAlert 0,"DAQ will execute for the specified time. Please wait for completion"
		else
			print "DAQ will execute for the specified time. Please wait for completion"
		endif
			
		cmd = "mcadaq.cgi"
		for(mo=Mstart; mo<Mend;mo+=1)	
		//mo = ModNum		// no looping; WebIO waits for complete run to execute, i.e. runs in multiple units would be started one after another 
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd, 1)	// wait for only 1s
		endfor
		
		return(0)
		
	endif
	
	
	if(cmpstr(ctrlName,"webstartdaq")==0)	
	
		if(warnings)
			DoAlert 0,"DAQ will execute for the specified time. Please wait for completion"
		else
			print "DAQ will execute for the specified time. Please wait for completion"
		endif
			
		cmd = "startdaq.cgi" // default
		if(WRdelay)
			// For synchronous run start via WR
			
			// 1. get WR time, WR_RT_CTRL
				cmd = "pollcsr.cgi?MODE=5"									// specify command. // PNXL uses query string
				mo = ModNum														// no loop for reading CSR
				Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,1)		// execute
				print ServerResponse
				WR_TM_TAI = str2num(ServerResponse)
				
			// 2. add fixed delay from current time (10s)					// TODO: this will not work for repeated clicks for different units, need to start on same time base
				WR_TM_TAI = WR_TM_TAI+10
			// 3. if WR_RT_CTRL =3 or 4, add start time to query as 
			//   	WR_tm_tai_start=%llu
				if(WR_RT_CTRL==3 || WR_RT_CTRL==4)
					cmd = "startdaq.cgi?WR_tm_tai_start="+num2str(WR_TM_TAI)
				endif
				
			//	4. if WR_RT_CTRL = 1,2 print message reminder, DAQ starts at next 10s rollover
				if(WR_RT_CTRL==1 || WR_RT_CTRL==2)
					cmd = "startdaq.cgi"
					print "WR_RT_CTRL= 1 or 2, DAQ will start at next 10s rollover of WR time"
				endif
				
			// 5. if WR_RT_CTRL = 0   print message reminder that that's contradicting the WRdelay checkbox
			 	if(WR_RT_CTRL==0)
					cmd = "startdaq.cgi"
					print "WR_RT_CTRL= 0, DAQ will start without WR synq"
				endif
		
		endif
		
		for(mo=Mstart; mo<Mend;mo+=1)	
		//mo = ModNum		// no looping; WebIO waits for complete run to execute, i.e. runs in multiple units would be started one after another 
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd, 1)	// wait for only 1s
		endfor
		
		return(0)
	
	endif
	
	
	if(cmpstr(ctrlName,"webenadaq")==0)	
		if(ModuleTypeXL==0)
			print "udp output not supported for Pixie-Net"
			return(0)
		endif
		Button webenadaq,   disable=2, win=PNXLpanel
		Button webdisdaq,   disable=0, win=PNXLpanel	
		
		cmd = "udpena.cgi" // default
		if(WRdelay)
			// For synchronous run start via WR
			
			// 1. get WR time, WR_RT_CTRL
				cmd = "pollcsr.cgi?MODE=5"									// specify command. // PNXL uses query string
				mo = ModNum														// no loop for reading CSR
				Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)		// execute
				print ServerResponse
				WR_TM_TAI = str2num(ServerResponse)
				
			// 2. add fixed delay from current time (10s)
				WR_TM_TAI = WR_TM_TAI+10
				
			// 3. if WR_RT_CTRL =3 or 4, add start time to query as 
			//   	WR_tm_tai_start=%llu
				if(WR_RT_CTRL==3 || WR_RT_CTRL==4)
					cmd = "udpena.cgi?WR_tm_tai_start="+num2str(WR_TM_TAI)
				endif
				
			//	4. if WR_RT_CTRL = 1,2 print message reminder, DAQ starts at next 10s rollover
				if(WR_RT_CTRL==1 || WR_RT_CTRL==2)
					cmd = "udpena.cgi"
					print "WR_RT_CTRL= 1 or 2, DAQ will start at next 10s rollover of WR time"
				endif
				
			// 5. if WR_RT_CTRL = 0   print message reminder that that's contradicting the WRdelay checkbox
			 	if(WR_RT_CTRL==0)
					cmd = "udpena.cgi"
					print "WR_RT_CTRL= 0, DAQ will start without WR synq"
				endif
		
		endif
		
		//cmd = "udpena.cgi"
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)
		endfor
		
		return(0)
	endif
	
	
	if(cmpstr(ctrlName,"webdisdaq")==0)	
		if(ModuleTypeXL==0)
			print "udp output not supported for Pixie-Net"
			return(0)
		endif
		Button webenadaq,   disable=0, win=PNXLpanel
		Button webdisdaq,   disable=2, win=PNXLpanel	
		
		cmd = "udpdis.cgi"
		for(mo=Mstart; mo<Mend;mo+=1)
			Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)
		endfor
		
		return(0)
	endif


	if(cmpstr(ctrlName,"webpollcsr0")==0)
		if(ModuleTypeXL==0)
			cmd = "pollcsr.cgi"									// specify command 
			print "CSR polling not supported for Pixie-Net"
			Zynq_CSR = 0
			return(0)
		else
			cmd = "pollcsr.cgi?MODE=1"							// PNXL uses query string
			//cmd = "pollcsr.cgi"
		endif
		mo = ModNum														// no loop for reading CSR
		Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)		// execute
		print ServerResponse
		Zynq_CSR = str2num(ServerResponse)
	endif
	
	
	if(cmpstr(ctrlName,"webpollcsr5")==0)
		if(ModuleTypeXL==0)
			print "udp output not supported for Pixie-Net"
			WR_TM_TAI = 0
			return(0)
		endif
		cmd = "pollcsr.cgi?MODE=5"									// specify command. // PNXL uses query string
		mo = ModNum														// no loop for reading CSR
		Pixie_IO_WebRequest(MZ_ip[mo],MZ_user[mo],MZ_pw[mo],cmd,0)		// execute
		print ServerResponse
		WR_TM_TAI = str2num(ServerResponse)
	endif
	
	
End


//########################################################################
//
//	PNXL_Ctrl_CommonPopup:
//		Handle popup menu changes.
//
//########################################################################
//Function PNXL_Ctrl_CommonPopup(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum	
//	String popStr
//
//	// global variables and waves
//	Nvar MCAfitOption =  root:pixie4:MCAfitOption
//	
//
//	StrSwitch(ctrlName)
//			
//		Case "MCAFitOptions":
//			MCAfitOption = popnum
//			PopupMenu MCAFitOptions, mode=popnum, win = MCASpectrumDisplayXL
//			break				
//			
//		Default:
//			break
//	Endswitch
//	
//End



//########################################################################
//
//	Pixie_GetFitOption: Retrieve MCA fit option
//
//########################################################################
Function Pixie_GetFitOption()
	Nvar MCAfitOption =  root:pixie4:MCAfitOption

	
	variable ret
	
	ret = 0
	ret = MCAfitOption
	
	if(ret==0)			// pick default value if nothing is selected
		MCAfitOption=4
		ret=4
	endif
	
	return(ret)
End



//########################################################################
//
//	Pixie_ListProc_LMHisto: Track and update List Mode Spectrum List Data
//
//########################################################################
Function Pixie_ListProc_LMHisto(ctrlName,row,col,event)
	String ctrlName		// name of this control
	Variable row			// row if click in interior, -1 if click in title
	Variable col			// column
	Variable event		// event code: 6 is begin edit, 7 is finish edit.

	Wave ListStartFitChannel=root:pixie4:ListStartFitChannel
	Wave ListEndFitChannel=root:pixie4:ListEndFitChannel
	Wave ListChannelPeakPos=root:pixie4:ListChannelPeakPos

	Wave/T ListModeSpecListData=root:pixie4:ListModeSpecListData
	Wave ListModeSpecSListData=root:pixie4:ListModeSpecSListData
	String wav
	
	if((event==7) && (col==1))  // StartFitChannel was changed
		ListStartFitChannel[row]=str2num(ListModeSpecListData[row][col])
		DoWindow ListModeSpectrumDisplay
		if (V_flag!=0)
			wav = "Spectrum"+num2str(row)
			cursor/W=ListModeSpectrumDisplay A $wav ListStartFitChannel[row]		
		endif		
	endif
	
	if((event==7) && (col==2))  // EndFitChannel was changed
		ListEndFitChannel[row]=str2num(ListModeSpecListData[row][col])
		DoWindow ListModeSpectrumDisplay
		if (V_flag!=0)
			wav = "Spectrum"+num2str(row)
			cursor/W=ListModeSpectrumDisplay B $wav ListEndFitChannel[row]
		endif		
	endif
	
	if((event==7) && (col==3))  // ChannelPeakPos was changed
		ListChannelPeakPos[row]=str2num(ListModeSpecListData[row][col])
	endif
	
	if((event==2) && (col==0))  // Channel was selected/deselected
		Silent 1
		wav="Spectrum"+num2str(row)
	//	if (row ==4) //sum
	//		wav="MCAsum"
	//	endif	
		if((ListModeSpecSListData[row][col] & 0x10) ==0x10 )
			AppendToGraph $("root:pixie4:"+wav)
			do
				if(row==1)
					ModifyGraph rgb($wav)=(0,65280,0)
				endif
				if(row==2)
					ModifyGraph rgb($wav)=(0,15872,65280)
				endif
				if(row==3)
					ModifyGraph rgb($wav)=(0,26112,0)
				endif
				if(row==4)	//ref
					ModifyGraph rgb($wav)=(0,0,0)
				endif
		//		if(row==4)	//sum
		//			ModifyGraph rgb($wav)=(0,0,0)
		//		endif
			while(0)
			ModifyGraph mode=6
			ModifyGraph grid=1
			ModifyGraph mirror(bottom)=2
			ModifyGraph mirror(left)=2
		else
			RemoveFromGraph/Z $(wav)
			wav="fit_"+wav
			RemoveFromGraph/Z $(wav)
		endif
	endif

	return 0			// other return values reserved
end



//########################################################################
//
//	Pixie_ListProc_MCA: Track and update MCA Spectrum List Data
//
//########################################################################
Function Pixie_ListProc_MCA(ctrlName,row,col,event)
	String ctrlName		// name of this control
	Variable row			// row if click in interior, -1 if click in title
	Variable col			// column
	Variable event		// event code: 6 is begin edit, 7 is finish edit.
	
	Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
	Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
	Wave MCAChannelPeakPos=root:pixie4:MCAChannelPeakPos
	Wave MCAFitRange=root:pixie4:MCAFitRange
	Wave MCAscale=root:pixie4:MCAscale
	Wave MCAChannelPeakEnergy=root:pixie4:MCAChannelPeakEnergy
	Wave MCAChannelFWHMAbsolute=root:pixie4:MCAChannelFWHMAbsolute
	Wave/T MCASpecListData=root:pixie4:MCASpecListData
	Wave MCASpecSListData=root:pixie4:MCASpecSListData
	Nvar  NumberOfModules=root:pixie4:NumberOfModules
	Variable ratio, dx
	String wav, fitwav
	
	if(row==5)
		wav="MCAsum"
	else
		if(row<5)
			wav="MCAch"+num2str(row)
		else
			wav="MCAtotal"+num2str(row-6)
		endif
	endif
	fitwav = "fit_"+wav
		
	if((event==7) && (col==1))  // Fit Range was changed
		MCAFitRange[row]=str2num(MCASpecListData[row][col])
	endif	
		
	if((event==7) && (col==2))  // StartFitChannel was changed
		MCAStartFitChannel[row]=str2num(MCASpecListData[row][col])
	endif
	
	if((event==7) && (col==3))  // EndFitChannel was changed
		MCAEndFitChannel[row]=str2num(MCASpecListData[row][col])
	endif
	
	if((event==7) && (col==4))  // kev/bin was changed
	
		ratio = str2num(MCASpecListData[row][col])/MCAscale[row]		// new/old
		
		Wave w=$("root:pixie4:"+wav)
		dx=str2num(MCASpecListData[row][col])
		SetScale/P x,0,dx," ",w
		
		MCAscale[row]*=ratio
		MCAStartFitChannel[row]*=ratio
		MCAEndFitChannel[row]*=ratio
		MCAChannelFWHMAbsolute[row]*=ratio
		MCAChannelPeakPos[row]*=ratio
		
		// Update display
		MCASpecListData[row][2]=num2str(MCAStartFitChannel[row])
		MCASpecListData[row][3]=num2str(MCAEndFitChannel[row])
		MCASpecListData[row][5]=num2str(MCAChannelPeakPos[row])
		MCASpecListData[row][7]=num2str(MCAChannelFWHMAbsolute[row])
		
		RemoveFromGraph/z $fitwav
	endif
	
	if((event==2) && (col==0))  // Channel was selected/deselected
		Silent 1

		if((MCASpecSListData[row][col] & 0x10) ==0x10 )
			AppendToGraph $("root:pixie4:"+wav)
			do
				if(row==1)
					ModifyGraph rgb($wav)=(0,65280,0)
				endif
				if(row==2)
					ModifyGraph rgb($wav)=(0,15872,65280)
				endif
				if(row==3)
					ModifyGraph rgb($wav)=(0,26112,0)
				endif
				if(row==4)	//ref
					ModifyGraph rgb($wav)=(0,0,0)
				endif
				if(row==5)	//sum
					ModifyGraph rgb($wav)=(36864,14592,58880)
				endif
			while(0)
			ModifyGraph mode=6
			ModifyGraph grid=1
			ModifyGraph mirror(bottom)=2
			ModifyGraph mirror(left)=2
		else
			RemoveFromGraph/Z $(wav)
			wav="fit_"+wav
			RemoveFromGraph/Z $(wav)
		endif
	endif

	return 0  // other return values reserved
end



//########################################################################
//
//	Pixie_ListProc_Traces: Select List Mode Traces in Trace Display
//
//########################################################################
Function Pixie_ListProc_Traces(ctrlName,row,col,event)
	String ctrlName		// name of this control
	Variable row			// row if click in interior, -1 if click in title
	Variable col			// column
	Variable event		// event code: 6 is begin edit, 7 is finish edit.

	
	Wave/T ListModeEnergyListData=root:pixie4:ListModeEnergyListData
	Wave ListModeEnergySListData=root:pixie4:ListModeEnergySListData
	String wav
		
	if((event==2) && (col==0))  // Channel was selected/deselected
		wav="Trace"+num2str(row)
		
		if((ListModeEnergySListData[row][col] & 0x10) ==0x10 )
			AppendToGraph $("root:pixie4:"+wav)
			do
				if(row==1)
					ModifyGraph rgb($wav)=(0,65280,0)
				endif
				if(row==2)
					ModifyGraph rgb($wav)=(0,15872,65280)
				endif
				if(row==3)
					ModifyGraph rgb($wav)=(0,26112,0)
				endif
				if(row==4)
					ModifyGraph rgb($wav)=(0,0,0)
				endif
			while(0)
			ModifyGraph mode=6
			ModifyGraph grid=1
			ModifyGraph mirror(bottom)=2
			ModifyGraph mirror(left)=2
		else
			RemoveFromGraph/Z $(wav)
			wav="fit_"+wav
			RemoveFromGraph/Z $(wav)
		endif
	endif

	return 0			// other return values reserved
end

