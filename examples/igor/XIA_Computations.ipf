#pragma rtGlobals=1		// Use modern global access method.



//########################################################################
//
//	Pixie_FilterTrace:
//		Display filters and threshold on an ADC trace.
//
//########################################################################
Function Pixie_FilterADCTraceCalc(Trace)
Wave Trace

	Nvar ChosenChannel = root:pixie4:ChosenChannel
	Nvar FilterClockMHz=root:pixie4:FilterClockMHz
	
	Wave Display_Channel_Parameters = root:pixie4:Display_Channel_Parameters
	Nvar index_SL = root:pixie4:index_SL
	Nvar index_SG = root:pixie4:index_SG
	Nvar index_FL = root:pixie4:index_FL
	Nvar index_FG = root:pixie4:index_FG	
	Nvar index_TH = root:pixie4:index_TH
	Nvar index_XDT = root:pixie4:index_XDT
	Nvar ncp =  root:pixie4:NumChannelPar	
	Nvar ModuleType = root:pixie4:ModuleType


	Variable len,df
	
	len=numpnts(Trace)
	// can not use duplicate since source wave is unsigned integer and results are floats
	make/o/n=(len) root:pixie4:TraceFilter, root:pixie4:TraceFilterSF, root:pixie4:TraceFilterFF, root:pixie4:TraceFilterSFMarkers, root:pixie4:TraceTH, root:pixie4:TraceGate
	Wave TraceFilter=root:pixie4:TraceFilter
	Wave TraceFilterSF=root:pixie4:TraceFilterSF
	Wave TraceFilterFF=root:pixie4:TraceFilterFF
	Wave TraceFilterSFMarkers=root:pixie4:TraceFilterSFMarkers
	Wave TraceTH = root:pixie4:TraceTH
	Wave TraceGate = root:pixie4:TraceGate
	CopyScales Trace, TraceFilter, TraceFilterSF, TraceFilterFF, TraceFilterSFMarkers, TraceTH, TraceGate
	TraceFilter = Trace
	TraceFilterFF  = Trace
	TraceFilterSF  = Trace
	TraceTH  = Trace
	TraceFilterSFMarkers = Nan
	TraceGate = Trace & 0x0001
	
	
	Variable k, dt, xdt
	Variable SL,SG,FL,FG
	
	xdt = Display_Channel_Parameters[index_XDT+ncp*ChosenChannel]
	
	SL=Display_Channel_Parameters[index_SL+ncp*ChosenChannel]/xdt
	SG=Display_Channel_Parameters[index_SG+ncp*ChosenChannel]/xdt
	FL=Display_Channel_Parameters[index_FL+ncp*ChosenChannel]/xdt 
	FG=Display_Channel_Parameters[index_FG+ncp*ChosenChannel]/xdt


		
	Variable FLpFG
	FLpFG = FL + FG
	
	

	Variable ndat, off, x0,x1,x2,x3
	off=2*SL+SG-1
	ndat=numpnts(TraceFilter)
	if(ndat > 0)  // we won't calculate digital filter value for null trace
		TraceFilterSF=nan
		k=off
		do
			x0=pnt2x(TraceFilter,k+SL+SG-off)
			x1=pnt2x(TraceFilter,k+SG+2*SL-1-off)
			x2=pnt2x(TraceFilter,k-off)
			x3=pnt2x(TraceFilter,k+SL-1-off)
			TraceFilterSF[k]=sum(TraceFilter,x0,x1)-sum(TraceFilter,x2,x3)
			k+=1
		while(k<ndat)
		TraceFilterSF*=xdt/0.0133
	
		off=2*FL+FG-1
		TraceFilterFF=nan
		k=off
		do
			x0=pnt2x(TraceFilter,k+FLpFG-off)
			x1=pnt2x(TraceFilter,k+FLpFG+FL-1-off)
			x2=pnt2x(TraceFilter,k-off)
			x3=pnt2x(TraceFilter,k+FL-1-off)
			TraceFilterFF[k]=sum(TraceFilter,x0,x1)-sum(TraceFilter,x2,x3)
			k+=1
		while(k<ndat)
		TraceFilterFF*=xdt*FilterClockMHz
	endif
	if(ModuleType ==500)
		TraceTH = Display_Channel_Parameters[index_TH+ncp*ChosenChannel]* (FL)*xdt*FilterClockMHz 
	else
		TraceTH = Display_Channel_Parameters[index_TH+ncp*ChosenChannel]* (FL)*xdt*FilterClockMHz *4 //(TriggerRiseTime/13.33e-3)*8/FL
	endif
		
//	print FL, FG, FLpFG, xdt, ncp, index_TH+ncp*ChosenChannel
End

// threshold entered in control panel is about 1/4 of amplitude that is still just triggered on, but only for a square pulse (fast rise time, long decay, TF flat top large)


//########################################################################
//
//	Pixie_Math_SumHisto:
//		Sum counts under the MCA histogram (minus background).
//
//########################################################################
Function Pixie_Math_SumHisto(ctrlName,popNum,popStr): PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr
	
	Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
	Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
	Wave MCAChannelPeakPos=root:pixie4:MCAChannelPeakPos
	Wave MCAChannelPeakEnergy=root:pixie4:MCAChannelPeakEnergy
	Wave MCAChannelFWHMPercent=root:pixie4:MCAChannelFWHMPercent
	Wave MCAChannelFWHMAbsolute=root:pixie4:MCAChannelFWHMAbsolute
	Wave MCAChannelPeakArea=root:pixie4:MCAChannelPeakArea
		
	Wave ListStartFitChannel=root:pixie4:ListStartFitChannel
	Wave ListEndFitChannel=root:pixie4:ListEndFitChannel
	Wave ListChannelPeakPos=root:pixie4:ListChannelPeakPos
	Wave ListChannelFWHMPercent=root:pixie4:ListChannelFWHMPercent
	Wave ListChannelPeakArea=root:pixie4:ListChannelPeakArea				
	
	String waveCursorAIsOn, waveCursorBIsOn, wav
	Variable len,a,b,de,bckgnd,ChanNum, ListNum
	
	waveCursorAIsOn = CsrWave(A)
	waveCursorBIsOn = CsrWave(B)

	if(cmpstr(ctrlName, "SumHistoMCAch") == 0)
		ListNum=0
		do
		
			// 0..4 normal channels and ref spectrum 
				ChanNum=ListNum							
				wav="root:pixie4:MCAch"+num2str(ChanNum)
			if (ListNum==5)	
				ChanNum= 0	
				wav="root:pixie4:MCAsum"		// addback
			endif
			if (ListNum>5)						// cumulative
				ChanNum= ListNum-6					// 
				wav = "root:pixie4:MCAtotal"+num2str(ChanNum)
			endif

		
			//if cursor is anywhere (any channel) on graph, use it as fit limit for selected channel
			// else use min/max set in user control for selected channel
			variable xa, xb
			if(cmpstr(CsrWave(A),"")==0)
			 	xa=MCAStartFitChannel[ListNum]
			 else 
			 	xa = xcsr(A)
			 endif
			
			 if(cmpstr(CsrWave(B),"")==0)
			 	xb=MCAEndFitChannel[ListNum]
			 else 
			 	xb = xcsr(B)
			 endif
			
			if(xa <= xb)
				MCAStartFitChannel[ListNum]=xa
				MCAEndFitChannel[ListNum]=xb
			else
				MCAStartFitChannel[ListNum]=xb
				MCAEndFitChannel[ListNum]=xa
			endif
			xa=MCAStartFitChannel[ListNum]		// use xa, xb as shorthand
			xb=MCAEndFitChannel[ListNum]
				
			wavestats/q $wav
			if (popNum==3) // sum all
				xa = 0
				xb=(V_npnts)*deltax($wav)-1
			endif
		
			// compute area
			MCAChannelPeakArea[ListNum]=sum($wav,xa,xb)		
			
			// determine FWHM
			WaveStats/Q/R=(xa,xb) $wav
			FindLevel/q  /R=(V_maxLoc,xa) $wav,(V_min+(V_max-V_min)/2)
			a=V_LevelX
			FindLevel/q  /R=(V_maxLoc,xb) $wav,(V_min+(V_max-V_min)/2)		
			b=V_LevelX
			MCAChannelFWHMAbsolute[ListNum]=(b-a)
			MCAChannelFWHMPercent[ListNum]=(b-a)/V_maxLoc*100
			
			// subtract background
			de=deltax($wav)
			a=sum($wav,xa,xa+2*de)/3	// average around start
			b=sum($wav,xb,xb-2*de)/3		// average around end
			bckgnd=(b+a)/2*(xb-xa)/de		// compute trapezoid under averaged end points
			if((popNum==2) || (popNum==3))
				bckgnd=0
			endif
			MCAChannelPeakArea[ListNum]-=bckgnd
			MCAChannelPeakPos[ListNum]=V_maxloc
			MCAChannelPeakEnergy[ListNum]=MCAChannelPeakEnergy[ListNum]		

			ListNum+=1
		while (ListNum<10)		// include ref
		Pixie_MakeList_MCA(1)	

	elseif(cmpstr(ctrlName, "SumHistoListModech") == 0)
		ChanNum=0
		do
			//if cursor is anywhere (any channel) on graph, use it as fit limit for selected channel
			// else use min/max set in user control for selected channel
			if(cmpstr(CsrWave(A),"")==0)
			 	xa=ListStartFitChannel[ChanNum]
			 else 
			 	xa = xcsr(A)
			 endif
			
			 if(cmpstr(CsrWave(B),"")==0)
			 	xb=ListEndFitChannel[ChanNum]
			 else 
			 	xb = xcsr(B)
			 endif
			
			if(xa <= xb)
				ListStartFitChannel[ChanNum]=xa
				ListEndFitChannel[ChanNum]=xb
			else
				ListStartFitChannel[ChanNum]=xb
				ListEndFitChannel[ChanNum]=xa
			endif
			xa=ListStartFitChannel[ChanNum]	// use xa, xb as shorthand
			xb=ListEndFitChannel[ChanNum]
				
			wav="root:pixie4:Spectrum"+num2str(ChanNum)
			wavestats/q $wav
			if (popNum==3) // sum all
				xa = 0
				xb=(V_npnts)*deltax($wav)-1
			endif
			
			// compute area
			ListChannelPeakArea[ChanNum]=sum($wav,xa,xb)		
			
			// determine FWHM
			WaveStats/Q/R=(xa,xb) $wav
			FindLevel/q  /R=(V_maxLoc,xa) $wav,(V_min+(V_max-V_min)/2)
			a=V_LevelX
			FindLevel/q  /R=(V_maxLoc,xb) $wav,(V_min+(V_max-V_min)/2)		
			b=V_LevelX
			ListChannelFWHMPercent[ChanNum]=(b-a)/V_maxLoc*100			
			
			// subtract background
			de=deltax($wav)
			a=sum($wav,xa,xa+2*de)/3
			b=sum($wav,xb,xb-2*de)/3
			bckgnd=(b+a)/2*(xb-xa)/de
			if((popNum==2) || (popNum==3))
				bckgnd=0
			endif
			ListChannelPeakArea[ChanNum]-=bckgnd
			ListChannelPeakPos[ChanNum]=V_maxloc		
			ChanNum+=1
		while (Channum<5)		// include ref
		Pixie_MakeList_LMHisto()
	endif
End

//########################################################################
//
//	Pixie_Math_GaussFit:
//		Gaussian fit of energy spectrum.
//
//########################################################################
Function Pixie_Math_GaussFit(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr

	Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
	Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
	Wave MCAFitRange=root:pixie4:MCAFitRange
	Wave MCAChannelPeakPos=root:pixie4:MCAChannelPeakPos
	Wave MCAChannelPeakEnergy=root:pixie4:MCAChannelPeakEnergy
	Wave MCAChannelFWHMPercent=root:pixie4:MCAChannelFWHMPercent
	Wave MCAChannelFWHMAbsolute=root:pixie4:MCAChannelFWHMAbsolute
	Wave MCAChannelPeakArea=root:pixie4:MCAChannelPeakArea
	
	Wave ListStartFitChannel=root:pixie4:ListStartFitChannel
	Wave ListEndFitChannel=root:pixie4:ListEndFitChannel
	Wave ListChannelPeakPos=root:pixie4:ListChannelPeakPos
	Wave ListChannelFWHMPercent=root:pixie4:ListChannelFWHMPercent
	Wave ListChannelPeakArea=root:pixie4:ListChannelPeakArea				
		
	Nvar MCAfitOption =  root:pixie4:MCAfitOption
	
	String waveCursorAIsOn, waveCursorBIsOn, wavname, foldername, wvn
	Variable ChanNum, EndNum, xa, xb, peakloc, xtemp, Listnum
	foldername="root:pixie4:"
	
	ChanNum=popNum-1					// channel number in loop and wave ref
	EndNum=ChanNum+1					// end of loop number
	Listnum=ChanNum					// entry in the MCA resutls array
	wavname = "MCAch"
	if (popNum==5)	
		ChanNum= 0	
		EndNum = 4					// run through 0..3
		Listnum=0
		wavname = "MCAch"
	endif
	if (popNum==6)
		ChanNum= 4					// "channel 4" is the ref spectrum
		EndNum=ChanNum+1
		Listnum=4
		wavname = "MCAch"
	endif
	if (popNum==7)					// 7 is addback
		ChanNum= -1					// indicate no channel suffix
		EndNum=ChanNum+1
		Listnum=5
		wavname = "MCAsum"
	endif
	if (popNum>7)
		ChanNum=popNum-8
		EndNum=ChanNum+1
		Listnum= ChanNum+6
		wavname = "MCAtotal"
	endif


	if(cmpstr(ctrlName, "GaussFitMCA") == 0)

		DoWindow/F MCASpectrumDisplay
		do	
				 
			Wave W_Coef=W_Coef
			if(ChanNum>=0)
				wvn = foldername+wavname+num2str(ChanNum)
			else
				wvn = foldername+wavname
			endif
			wave wav =$(wvn)
			wavestats/q wav
				
			if(MCAfitOption==1)
				peakloc = V_maxloc	//in x
				//xa = x2pnt(wav,peakloc*(1-MCAFitRange[Listnum]/100))
				//xb = x2pnt(wav,peakloc*(1+MCAFitRange[Listnum]/100))	 
				xa = peakloc*(1-MCAFitRange[Listnum]/100)
				xb = peakloc*(1+MCAFitRange[Listnum]/100)	 
			endif
			
			if(MCAfitOption==2)
				findlevel/q/R=[32767,0] wav, V_max/10
				peakloc = V_LevelX	//in x
				//xa = x2pnt(wav,peakloc*(1-MCAFitRange[Listnum]/100))
				//xb = x2pnt(wav,peakloc*(1+MCAFitRange[Listnum]/100))
				xa = peakloc*(1-MCAFitRange[Listnum]/100)
				xb = peakloc*(1+MCAFitRange[Listnum]/100)	 	 
			endif
			
			if(MCAfitOption==3)
				xa = MCAStartFitChannel[Listnum]
				xb = MCAEndFitChannel[Listnum]
			endif
			
			if(MCAfitOption==4)
				//if cursor is anywhere (any channel) on graph, use it as fit limit for selected channel
				// else use min/max set in user control for selected channel
				if(cmpstr(CsrWave(A),"")==0)
				 	xa=MCAStartFitChannel[Listnum]
				 else 
				 	xa = xcsr(A)
				 endif
				
				 if(cmpstr(CsrWave(B),"")==0)
				 	xb=MCAEndFitChannel[Listnum]
				 else 
				 	xb = xcsr(B)
				 endif
				
				if(xa > xb)
					xtemp=xa
					xa=xb
					xb=xtemp
				endif
			endif
			
			W_Coef = nan
			CurveFit/Q gauss wav(xa,xb) /D
			MCAChannelPeakPos[Listnum]=W_Coef[2]
			MCAChannelPeakEnergy[Listnum]=MCAChannelPeakPos[Listnum]
			MCAChannelFWHMPercent[Listnum]=100*W_coef[3]*2*sqrt(ln(2))/W_coef[2]
			MCAChannelFWHMAbsolute[Listnum]=W_coef[3]*2*sqrt(ln(2))
			MCAChannelPeakArea[Listnum]=W_coef[3]*W_coef[1]*sqrt(Pi)/deltax(wav)
			
			ChanNum+=1
			Listnum+=1
		while (ChanNum<EndNum)
		
		Pixie_MakeList_MCA(1)	
		
	elseif(cmpstr(ctrlName, "GaussFitListModech") == 0)
		do	
			//if cursor is anywhere (any channel) on graph, use it as fit limit for selected channel
			// else use min/max set in user control for selected channel
			if(cmpstr(CsrWave(A),"")==0)
			 	xa=ListStartFitChannel[Listnum]
			 else 
			 	xa = xcsr(A)
			 endif
			
			 if(cmpstr(CsrWave(B),"")==0)
			 	xb=ListEndFitChannel[Listnum]
			 else 
			 	xb = xcsr(B)
			 endif
			
			if(xa <= xb)
				ListStartFitChannel[Listnum]=xa
				ListEndFitChannel[Listnum]=xb
			else
				ListStartFitChannel[Listnum]=xb
				ListEndFitChannel[Listnum]=xa
			endif
		
			wavname="root:pixie4:Spectrum"+num2str(ChanNum)
			wave wav =$wavname
			Wave W_Coef=W_Coef
			CurveFit/Q gauss wav(ListStartFitChannel[Listnum],ListEndFitChannel[Listnum]) /D
			ListChannelPeakPos[Listnum]=W_Coef[2]
			ListChannelFWHMPercent[Listnum]=100*W_coef[3]*2*sqrt(ln(2))/W_coef[2]
			ListChannelPeakArea[Listnum]=W_coef[3]*W_coef[1]*sqrt(Pi)/deltax(wav)	
			
			ChanNum+=1
			Listnum+=1
		while (ChanNum<EndNum)
	
		Pixie_MakeList_LMHisto()
			
	endif
End



//########################################################################
//
//	Pixie_Math_TauFit:
//		Single exponential fit of a ADC trace.
//
//########################################################################
Function Pixie_Math_TauFit(channel) 
Variable channel
	
	Wave TauTrace=$("root:pixie4:ADCch"+num2str(channel)) 
	Wave TauReswave=$("Res_ADCch"+num2str(channel)) 
	Wave TauFitwave=$("fit_ADCch"+num2str(channel)) 
	Nvar LastTau=root:pixie4:LastTau
	Nvar TauDeviation=root:pixie4:TauDeviation
	Variable xa,xb
	
	// ensure target waves exist and are clean
	duplicate/o TauTrace, TauReswave
	duplicate/o TauTrace, TauFitwave
	TauReswave = 0
	TauFitwave = nan
	
	//if cursor is anywhere on graph, use it as fit limit
	if( (cmpstr(CsrWave(A),"")==0) || (cmpstr(CsrWave(B),"")==0) )
		DoAlert 0, "Please define the fit range with the cursors"
		ShowInfo
		return(-1)
	endif
	xa = xcsr(A)/1e-6
	xb = xcsr(B)/1e-6
	
	CurveFit/Q exp_XOffset TauTrace(xa*1e-6,xb*1e-6) /D/R
	LastTau=1e6/K2
	
	Wave W_sigma=W_sigma
	Wave W_coef=W_coef
	TauDeviation=W_sigma[2]*1e6
	LastTau=W_coef[2]*1e6
End



//########################################################################
//
//	Pixie_FilterFFT:
//		Simulate the effect of energy filter on the FFT noise spectrum.
//
//########################################################################
Function Pixie_FilterFFT()

	Wave TraceFFT=root:pixie4:TraceFFT
	Nvar ChosenChannel=root:pixie4:ChosenChannel
	Nvar FilterClockMHz=root:pixie4:FilterClockMHz
	
	// New parameter modification scheme
	Wave Display_Channel_Parameters = root:pixie4:Display_Channel_Parameters
	Nvar index_SL = root:pixie4:index_SL
	Nvar index_SG = root:pixie4:index_SG
	Nvar ncp = root:pixie4:NumChannelPar
	Variable EnergyRiseTime = Display_Channel_Parameters[index_SL+ChosenChannel*ncp]
	Variable EnergyFlatTop = Display_Channel_Parameters[index_SG+ChosenChannel*ncp]
	Variable L,G,dt,dec
	String cc,wav

	cc=num2str(ChosenChannel)
	wav = "root:pixie4:ADCch"+cc
	Pixie_FFTtrace($wav)	 // recompute before applying a different filter
	
	TraceFFT*=2*abs(sin(Pi*x*EnergyRiseTime)*sin(Pi*x*(EnergyRiseTime+EnergyFlatTop))/((EnergyRiseTime*FilterClockMHz)*sin(Pi*x*1e-6/FilterClockMHz)))
	TraceFFT[0]=0

End


//########################################################################
//
//	Pixie_FFTtrace:
//		Calculate the FFT noise spectrum of the ADC trace.
//
//########################################################################
Function Pixie_FFTtrace(Trace)
Wave Trace

	
	Nvar FFTbin=root:pixie4:FFTbin
	Variable len,df
	Duplicate/o Trace, TauFFT
	len=numpnts(TauFFT)
	if(mod(len,2)==1)
		DeletePoints len-2,1, TauFFT
	endif
	len/=2
	make/o/n=(len) root:pixie4:TraceFFT
	Wave TraceFFT=root:pixie4:TraceFFT
	
	FFT/DEST=TauFFT Trace
	TraceFFT=sqrt(magsqr(TauFFT))/len // normalize to peak amplitude
	df=deltax(TauFFT)
	CopyScales TauFFT, TraceFFT	 // copy scales halves df
	SetScale/P x,0,df, TraceFFT
	TraceFFT[0]=0
	DeletePoints len,len, root:pixie4:TraceFFT
	FFTbin=df
	KillWaves TauFFT
	
End


//########################################################################
//
//	Pixie_Tdiff_compute_diff:
//		Compute time difference between 2 channels
//		3 times but only result A is usually shown
//
//########################################################################
Function Pixie_Tdiff_compute_diff()	

	Nvar DiffA_P = root:LM:DiffA_P	// specify channel A & B to subtract
	Nvar DiffA_N = root:LM:DiffA_N
	Nvar DiffB_P = root:LM:DiffB_P
	Nvar DiffB_N = root:LM:DiffB_N
	Nvar DiffC_P = root:LM:DiffC_P
	Nvar DiffC_N = root:LM:DiffC_N
	Nvar TSscale  = root:LM:TSscale // units of time stamps
	Nvar DiffA_CFD = root:LM:DiffA_CFD 	// specify to use CFD or just TS
	Nvar DiffB_CFD = root:LM:DiffA_CFD 
	Nvar DiffC_CFD = root:LM:DiffA_CFD 

	
	String 	text = "root:LM"
	Wave TdiffA = $(text+":TdiffA")				// user defined time difference
	Wave TdiffB = $(text+":TdiffB")		
	Wave TdiffC = $(text+":TdiffC")		
	
	Variable lsb_ig =1	// lsbs to ignore
 	
	//  compute user defined time differences 
	// TS repeats from previous valid entry for channels without hit, so current TS is last valid for all channels
	
	wave PA = $("root:LM:LocTime"+num2str(DiffA_P))
	wave NA = $("root:LM:LocTime"+num2str(DiffA_N))
	wave PD = $("root:LM:CFD"+num2str(DiffA_P))
	wave ND = $("root:LM:CFD"+num2str(DiffA_N))
	

	if(DiffA_CFD)
		TdiffA =TSscale*(  PA - NA)  + PD - ND	// include CFD time scaled in ns
	else
		TdiffA =TSscale*(PA -  NA)	// in ns  TSscale*abs(PA -  NA)	// in ns
	endif

	wave PA = $("root:LM:LocTime"+num2str(DiffB_P))
	wave NA = $("root:LM:LocTime"+num2str(DiffB_N))
	wave PD = $("root:LM:CFD"+num2str(DiffA_P))
	wave ND = $("root:LM:CFD"+num2str(DiffA_N))

	if(DiffB_CFD)
		TdiffB =TSscale*(PA -  NA + PD/256 - ND/256)	// include CFD time
	else
		TdiffB = TSscale*abs(PA -  NA)	// in ns
	endif
	
	wave PA = $("root:LM:LocTime"+num2str(DiffC_P))
	wave NA = $("root:LM:LocTime"+num2str(DiffC_N))
	wave PD = $("root:LM:CFD"+num2str(DiffA_P))
	wave ND = $("root:LM:CFD"+num2str(DiffA_N))

	if(DiffC_CFD)
		TdiffC =TSscale*(PA -  NA + PD/256 - ND/256)	// include CFD time
	else
		TdiffC = TSscale*abs(PA -  NA)	// in ns
	endif
	
	// make time histograms
	
 	Pixie_Tdiff_histo()
 	

End	


//########################################################################
//
//	Pixie_Tdiff_histo:
//		Histogram time differences
//
//########################################################################
Function Pixie_Tdiff_histo()

	Nvar NbinsTA = root:LM:NbinsTA
	Nvar BinsizeTA = root:LM:BinsizeTA
	Nvar NbinsTB = root:LM:NbinsTB
	Nvar  BinsizeTB = root:LM:BinsizeTB
	Nvar NbinsTC = root:LM:NbinsTC
	Nvar BinsizeTC =  root:LM:BinsizeTC

	histogram/B={-BinsizeTA*NbinsTA/2,BinsizeTA,NbinsTA} root:LM:TdiffA,   root:LM:ThistoA
	histogram/B={-BinsizeTB*NbinsTB/2,BinsizeTB,NbinsTB} root:LM:TdiffB,   root:LM:ThistoB
	histogram/B={-BinsizeTC*NbinsTC/2,BinsizeTC,NbinsTC} root:LM:TdiffC,   root:LM:ThistoC
//	print "Total in Tdiff histo: A:",sum( root:LM:ThistoA), "B:",sum( root:LM:ThistoB), "C:",sum( root:LM:ThistoC)

End




//########################################################################
//
//	Some bit manipulations, for 16-bit words
//
//########################################################################
Function CLRbit(bit,value)
	Variable value,bit
	value=SETbit(bit,value)
	return(value %^ (2^bit) )
End

Function SETbit(bit,value)
	Variable value,bit
	return(value %| ( 2^bit) )
End

Function TGLbit(bit,value)
	Variable value,bit
	return(value %^ ( 2^bit) )
End

Function TSTbit(bit,value)
	Variable value,bit
	return((value %& ( 2^bit))/2^bit )
End








//########################################################################
//
//	Print a decimal number in hexadecimal format
//
//########################################################################
Function ph(num)
Variable num

	printf "0x%X\r",num

End







//########################################################################
//
// check for updates
//
//########################################################################
Function Pixie_CheckForPVupdates(ctrlName) : ButtonControl
	String ctrlName

	Nvar ViewerVersion = root:pixie4:ViewerVersion
	variable ret

	// connect to XIA support page
	String releasepage, searchstr, vn
	releasepage = fetchURL("http://support.xia.com/default.asp?W365")
	Variable error = GetRTError(1)		// Check for error before using response
	if (error != 0)
		// FetchURL produced an error
		// so don't try to use the response.
		if (cmpstr(ctrlname,"Noalert")==0)
			print "Could not connect to the XIA support web page."
		else
			DoAlert 0, "Could not connect to the XIA support web page."
		endif
		return(-1)
	endif
	
	// check response
	sprintf searchstr, "Pixie-4e_4.%02x_setup.exe", (ViewerVersion-0x400)	// release package file name (two version digits filled in)
	ret= strsearch(releasepage,searchstr,0)		// -1 if not found
	if(ret<0)
		// if not found, the current release is not on the webpage, so there must be a newer one (or, during development, an older one)
		if (cmpstr(ctrlname,"Noalert")==0)
			print "There is a new release on XIA's support web page http://support.xia.com/default.asp?W365"
		else
			DoAlert 1, "There is a new release on XIA's support web page. Open in web browser?"
			if(V_flag==1)
				BrowseURL "http://support.xia.com/default.asp?W365"
			endif
		endif
	else
		if (cmpstr(ctrlname,"Noalert")==0)
			print "This PixieViewer software is up to date"
		else
			DoAlert 0, "This PixieViewer software is up to date"
		endif
	endif
End



//########################################################################
//
//	Pixie_Math_GaussFit_XL:
//		Gaussian fit of energy spectrum for XL spectrum display.
//
//########################################################################
Function Pixie_Math_GaussFit_XL(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr

	Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
	Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
	Wave MCAFitRange=root:pixie4:MCAFitRange
	Wave MCAChannelPeakPos=root:pixie4:MCAChannelPeakPos
	Wave MCAChannelPeakEnergy=root:pixie4:MCAChannelPeakEnergy
	Wave MCAChannelFWHMPercent=root:pixie4:MCAChannelFWHMPercent
	Wave MCAChannelFWHMAbsolute=root:pixie4:MCAChannelFWHMAbsolute
	Wave MCAChannelPeakArea=root:pixie4:MCAChannelPeakArea
			
	Nvar MCAfitOption =  root:pixie4:MCAfitOption
	//MCAfitOption = 4	// always use cursors
	Variable range = 1	// fit range around largest peak in %
	
	String waveCursorAIsOn, waveCursorBIsOn, wavname, foldername, wvn
	Variable ChanNum, EndNum, xa, xb, peakloc, xtemp, Listnum
	foldername="root:pixie4:"
	
	ChanNum=popNum-1					// channel number in loop and wave ref
	EndNum=ChanNum+1				// end of loop number
	Listnum=ChanNum					// entry in the MCA resutls array
	wavname = "MCAch"
	if (popNum==9)	
		ChanNum= 0	
		EndNum = 8						// run through 0..7
		Listnum=0
		wavname = "MCAch"
	endif
	if (popNum==10)
		ChanNum= -1						// "channel 8" is the ref spectrum
		EndNum=ChanNum+1
		Listnum=4
		wavname = "MCAref"
	endif

	if(cmpstr(ctrlName, "GaussFitMCA") == 0)


		DoWindow/F MCASpectrumDisplayXL
		do	
				 
			Wave W_Coef=W_Coef
			if(ChanNum>=0)
				wvn = foldername+wavname+num2str(ChanNum)
			else
				wvn = foldername+wavname
			endif
			wave wav =$(wvn)
			wavestats/q wav
			
			if(MCAfitOption<4)		// 2,3 not supported
				MCAfitOption=1
			endif
			
				
			if(MCAfitOption==1)
				peakloc = V_maxloc	//in x

				xa = peakloc*(1-range/100)
				xb = peakloc*(1+range/100)	 
			endif			
			
			if(MCAfitOption==4)
				//if cursor is anywhere (any channel) on graph, use it as fit limit for selected channel
				// else use min/max set in user control for selected channel
				if(cmpstr(CsrWave(A),"")==0)
				 	//xa=MCAStartFitChannel[Listnum]
				 	 DoAlert 0, "Cursor not on graph!"
				 	 xa = 0
				 else 
				 	xa = xcsr(A)
				 endif
				
				 if(cmpstr(CsrWave(B),"")==0)
				 	//xb=MCAEndFitChannel[Listnum]
				 	DoAlert 0, "Cursor not on graph!"
				 	xb = 32000
				 else 
				 	xb = xcsr(B)
				 endif
				
				if(xa > xb)
					xtemp=xa
					xa=xb
					xb=xtemp
				endif
			endif
			
			W_Coef = nan
			CurveFit/Q gauss wav(xa,xb) /D
//			MCAChannelPeakPos[Listnum]=W_Coef[2]
//			MCAChannelPeakEnergy[Listnum]=MCAChannelPeakPos[Listnum]
//			MCAChannelFWHMPercent[Listnum]=100*W_coef[3]*2*sqrt(ln(2))/W_coef[2]
//			MCAChannelFWHMAbsolute[Listnum]=W_coef[3]*2*sqrt(ln(2))
//			MCAChannelPeakArea[Listnum]=W_coef[3]*W_coef[1]*sqrt(Pi)/deltax(wav)
			print "channel",ChanNum,"FWHM =",100*W_coef[3]*2*sqrt(ln(2))/W_coef[2],"%,   pos = ",W_Coef[2]
			
			ChanNum+=1
			Listnum+=1
		while (ChanNum<EndNum)
		
			
	endif
End




//########################################################################
//
//Pixie_Find_NameInWave:
//	Find the index of  a named parameter in wave
//
//########################################################################
Function Pixie_Find_NameInWave(name, wvname)
String name, wvname

	Wave/T names = $(wvname)
	Variable i, wavelen,index
	
	i=0
	wavelen = numpnts(names)
	do	
		if(cmpstr(name, names[i]) == 0)
			index=i
			break
		endif
		i=i+1	
	while(i<wavelen)

	return(index)
End


//########################################################################
//
//	Pixie_FilterLMTraceCalc:
//		Calculate digital trapezoidal filter response of a list mode trace.
//
//########################################################################
Function Pixie_FilterLMTraceCalc()

	Nvar ChosenChannel = root:pixie4:ChosenChannel
	Nvar wftimescale = root:pixie4:wftimescale			// sampling interval in seconds as read from the file or user entry
	
	Wave sf=root:pixie4:sf
	Wave ff=root:pixie4:ff
	Wave seltrace=root:pixie4:seltrace
	Wave SFmarkers=root:pixie4:SFmarkers
	Wave th = root:pixie4:th
	
	Nvar EFRT =  root:pixie4:EFRT	// filter variables in us
	Nvar EFFT = root:pixie4:EFFT
	Nvar EFINT = root:pixie4:EFINT
	Nvar TFRT = root:pixie4:TFRT	
	Nvar TFFT = root:pixie4:TFFT
	Nvar TFTH = root:pixie4:TFTH

	Variable k, dt, len, rate, s0,m, s1, s2, s3
	Variable SL,SG,FL,FG, INT

	String wav
	wav="root:pixie4:Trace"+num2str(ChosenChannel)
	//Duplicate/o $wav,root:pixie4:seltrace,root:pixie4:sf,root:pixie4:ff,root:pixie4:th,root:pixie4:sfmarkers
	wave Trace = $(wav)
	
	len=numpnts(Trace)
	// can not use duplicate since source wave is unsigned integer and results are floats
	make/o/n=(len) root:pixie4:seltrace, root:pixie4:sf, root:pixie4:ff, root:pixie4:th, root:pixie4:sfmarkers,root:pixie4:cfd
	Wave seltrace=root:pixie4:seltrace
	Wave sf=root:pixie4:sf
	Wave ff=root:pixie4:ff
	Wave cfd=root:pixie4:cfd
	Wave th = root:pixie4:th
	CopyScales Trace, seltrace, sf, ff, sfmarkers, th, cfd
	seltrace = Trace
	ff  = Trace
	sf  = Trace
	th  = Trace
	cfd  = Trace
	sfmarkers = Nan
	rate = 1e-6/wftimescale
	
	SL=EFRT*rate
	SG=EFFT*rate
	FL=TFRT*rate
	FG=TFFT*rate
	INT = EFINT
	
	Variable FLpFG
	FLpFG = FL + FG

	Variable ndat, off, x0,x1,x2,x3
	Variable cfd_B = 4
	Variable cfd_D = 4
	
	// slow filter *************************************************************************
	off=2*SL+SG-1
	ndat=numpnts(seltrace)
	if(ndat > 0 && off <ndat)  // we won't calculate digital filter value for null trace or when flter too long
		sf=nan
		k=off
		do
			if(INT!=1)		// INT==0 is so simplified (no gap, no tau) that it is the same as INT=2
				s0=0
				for(m=0;m<SL;m+=1)
					s0 -= seltrace[k+m-off]
					s0 += seltrace[SL+SG+k+m-off]
				endfor
				sf[k]=s0
				
			else
				s0=0
				for(m=0;m<SG;m+=1)
					s0 += seltrace[k+m-SG]
				endfor
				sf[k]=s0
			endif
			
			k+=1
		while(k<ndat-1)
		
		// fast filter *************************************************************************
		off=2*FL+FG-1
		ff=nan
		k=off
		do
			s0=0
			for(m=0;m<FL;m+=1)
				s0 -= seltrace[k+m-off]
				s0 += seltrace[FL+FG+k+m-off]
			endfor
			ff[k]=s0
			k+=1
		while(k<ndat)
		
		// CFD *************************************************************************
		off=cfd_B+cfd_D+4
		cfd=nan
		k=off
		do

			s0 = seltrace[k]+seltrace[k-1]							// sample avg (length L = 2)
			s1 =  seltrace[k-cfd_B]+seltrace[k-cfd_B-1]				// sample avg (delayed)
			s2 =  seltrace[k-cfd_D]+seltrace[k-cfd_D-1]				
			s3 =  seltrace[k-cfd_B-cfd_D]+seltrace[k-cfd_B-cfd_D-1]	

			cfd[k]=((s0-s1) - (s2-s3))/2
			k+=1
		while(k<ndat)
		
	endif

	th = TFTH*16*(FL)

	
End



//########################################################################
//
//	Pixie_Math_CFDfrom4raw: 
//      compute the CFD fraction from the 4 raw values in the LM file (fully imported)
//
//########################################################################
Function Pixie_Math_CFDfrom4raw(no)
Variable no // event number in wfarray
	Wave wfarray
	Nvar iMType = root:pixie4:iMType 
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2 
	Nvar WFscale = root:pixie4:WFscale

	// use the 4 raw values and compute CFD
	Variable cfdout1, cfdout2, cfdsrc, cfdfrc, ph, cfd
		
	cfdsrc 	= (wfarray[iCFDinfo][no]==1)
	cfdfrc 	= (wfarray[iCFDinfo][no]>1)	
	cfdout1	=  wfarray[iCFDsum1][no] + (wfarray[iCFDsum12][no] & 0x00FF)*65536
	cfdout2	= (wfarray[iCFDsum12][no] & 0xFF00)/256 + wfarray[iCFDsum2][no]*256
	cfdout2 	= 0x1000000 - cfdout2;        // convert to positive
	ph = cfdout1 / ( cfdout1 + cfdout2 )
	
							
	// compute as fraction of sample for now
	cfd = ph
	if(cfdsrc)
		cfd=cfd-1		// CHECK: should be +1 but perhaps sample order is swapped in FPGA and so -1 is correct
	endif
							

	if(cfdfrc)		// result invalid if "forced"
		cfd=0
	endif
	

	return cfd*WFscale	// in ns

End

//########################################################################
//
//	Pixie_Math_CFDfrom4hdr: 
//      compute the CFD fraction from the 4 raw values in the LM file header
//
//########################################################################
Function Pixie_Math_CFDfrom4hdr()
Variable no // event number in wfarray
	wave LMeventheader = root:pixie4:LMeventheader
	Nvar iCFDinfo   = root:pixie4:iCFDinfo 
	Nvar iCFDsum1   = root:pixie4:iCFDsum1 
	Nvar iCFDsum12  = root:pixie4:iCFDsum12 
	Nvar iCFDsum2   = root:pixie4:iCFDsum2 
	Nvar WFscale = root:pixie4:WFscale

	// use the 4 raw values and compute CFD
	Variable cfdout1, cfdout2, cfdsrc, cfdfrc, ph, cfd
		
	cfdsrc 	= (LMeventheader[iCFDinfo][no]==1)
	cfdfrc 	= (LMeventheader[iCFDinfo][no]>1)	
	cfdout1	=  LMeventheader[iCFDsum1][no] + (LMeventheader[iCFDsum12][no] & 0x00FF)*65536
	cfdout2	= (LMeventheader[iCFDsum12][no] & 0xFF00)/256 + LMeventheader[iCFDsum2][no]*256
	cfdout2 	= 0x1000000 - cfdout2;        // convert to positive
	ph = cfdout1 / ( cfdout1 + cfdout2 )
	
							
	// compute as fraction of sample for now
	cfd = ph
	if(cfdsrc)
		cfd=cfd-1		// CHECK: should be +1 but perhaps sample order is swapped in FPGA and so -1 is correct
	endif
							

	if(cfdfrc)		// resut invalid if "forced"
		cfd=0
	endif
	

	return cfd*WFscale	// in ns

End


//########################################################################
//
//	Pixie_Math_CFDfromTrace: 
//      compute the CFD fraction from the current trace
//
//########################################################################
Function Pixie_Math_CFDfromTrace(ch)
Variable ch

	//Nvar defaultTriggerPos = root:LM:defaultTriggerPos	//Nvar defaultTriggerPos = root:LM:defaultTriggerPos
	Nvar LB = root:LM:LB					//Nvar LB =  root:LM:LB //= 12 // length of baseline sum
	Nvar RTlow =  root:LM:RTlow				//Nvar RTlow = root:LM:RTlow //= 0.1
		
		Variable defaultTriggerPos =0
	String wav, wv2
	
	Variable maxlocA,  npntsA, rms, goodevent, cfdt
	Variable k,j, baseA, amplA, lev10,  lev1p, lev1x, lev2p, lev2x
	Variable max1p, max2p, cfdlevel, sep
	
	
	wav="root:pixie4:trace"+num2str(ch)
	wave traceA = $wav
	
	goodevent = WaveExists(traceA)==1 	// only analyze traces that are present
	wavestats/q/z	traceA
	npntsA = V_npnts
	goodevent = goodevent && (npntsA>1) 	// only analyze traces that have points
	
	if(goodevent)	
		wv2 = "root:LM:triglocsA"
		duplicate/o traceA,  $(wv2)
		Wave triglocsA = $(wv2)
		triglocsA = nan
	
		
		// ***************  calculate base and amplitude  ***************
		baseA = 0
		for(j=defaultTriggerPos-LB;j<defaultTriggerPos;j+=1)
			baseA+=traceA[j]
		endfor
		baseA/=LB
		
		//find max
		wavestats/q/z	traceA
		amplA = V_max-baseA
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
		triglocsA[lev1p] = traceA[lev1p]		// mark waveform
		cfdt = lev1x  *1e9	//in ns
		
	else
	
		cfdt = -1
		
	endif
	
	return(cfdt)

			
			
End
