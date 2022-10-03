#pragma rtGlobals=1		// Use modern global access method.


// Functions imported and unmodified from Pixie-4e SW


















////########################################################################
////
////	Pixie_File_RunStats:
////		Store/Read run statistics
////
////########################################################################
//
//Function Pixie_File_RunStats(ctrlName,popNum,popStr) : PopupMenuControl
//	String ctrlName
//	Variable popNum	
//	String popStr
//	
//	
//	Nvar NumberOfModules = root:pixie4:NumberOfModules
//	Nvar NumberOfChannels = root:pixie4:NumberOfChannels
////	Nvar CloverAdd = root:pixie4:CloverAdd
//
//	Nvar NumModulePar = root:pixie4:NumModulePar
//	Nvar NumChannelPar = root:pixie4:NumChannelPar
//	Wave/T Channel_Parameter_Names = root:pixie4:Channel_Parameter_Names
//	Wave/T Module_Parameter_Names = root:pixie4:Module_Parameter_Names
//	Wave CPV = root:pixie4:Channel_Parameter_Values
//	Wave Module_Parameter_Values = root:pixie4:Module_Parameter_Values
//	Wave/T System_Parameter_Names = root:pixie4:System_Parameter_Names
//	Wave System_Parameter_Values = root:pixie4:System_Parameter_Values
//	
//	Nvar NumChannelParIFM = root:pixie4:NumChannelParIFM 		//  number of input user variables (applicable to each channel) for .ifm file
//	Nvar NumModuleInParIFM = root:pixie4:NumModuleInParIFM 		//  number of input global variables (applicable to each module) for .ifm file
//	Nvar NumSystemInParIFM = root:pixie4:NumSystemInParIFM 		//  number of input global variables (applicable to system) for .ifm file
//
//
//	Svar StartTime = root:pixie4:StartTime
//	Svar StopTime = root:pixie4:StopTime
//	Svar InfoSource = root:pixie4:InfoSource
//	Svar StatisticsFileName = root:pixie4:StatisticsFileName
//	Svar OutBaseName = root:pixie4:OutBaseName
//	
//	Variable filenum,i,k,index0, index1, index2, index3,len,m
//	String filename,wav, line, text
//	Variable Mnum, Chnum, RT, LT, ER, ICR, NumberMod, TT, OCR, GCR, SFDT, GDT, PPR
//	
//	Nvar index_COUNTTIME = root:pixie4:index_COUNTTIME
//	Nvar index_ICR = root:pixie4:index_ICR
//	Nvar index_OCR = root:pixie4:index_OCR
//	Nvar index_GCR = root:pixie4:index_GCR
//	Nvar index_SFDT = root:pixie4:index_SFDT
//	Nvar index_GDT = root:pixie4:index_GDT
//	Nvar index_FTDT = root:pixie4:index_FTDT
//	Nvar index_PPR = root:pixie4:index_PPR
//
//		
//	Nvar index_RunTime = root:pixie4:index_RunTime
//	Nvar index_TotTime = root:pixie4:index_TotTime
//	Nvar index_EvRate = root:pixie4:index_EvRate
//	Nvar index_NumEv = root:pixie4:index_NumEv
//	
//	Nvar  ViewerVersion =  root:pixie4:ViewerVersion
//		
//	if(popnum == 1) // save as .ifm file	
// 			
//		if (cmpstr(ctrlName,"StopRun")==0)
//			Open filenum as StatisticsFileName
//			filename=S_fileName	// full path and name of file opened, or "" if cancelled
//		else
//			Open/D/T="????"/M="Save Run Statistics in Text File (.ifm)"/P=MCAPath filenum as "*.ifm"
//			filename=S_fileName	// full path and name of file opened, or "" if cancelled
//		endif
//		
//		if (cmpstr(filename,"")!=0)		// if file defined succesfully
//			Open/Z/T="????" filenum as filename
//			
//			len = strlen(filename)
//			text = filename[0,len-4]
//			fprintf filenum, "XIA Pixie DAQ run saved to files %sxxx \r", text
//			fprintf filenum, "Acquisition started at %s \r",StartTime
//			fprintf filenum, "stopped at %s\r\r", StopTime
//			
//			fprintf filenum, "Number of Modules: %d\r", NumberOfModules
//	
//			fprintf filenum, "Module\t Run Time(s)\t Event rate (cps)\t Total time (s)\r" 
//			for(k=0;k<NumberOfModules;k+=1)
//				fprintf filenum, "%d\t %g\t %g\t %g\r", k, Module_Parameter_Values[index_RunTime][k],Module_Parameter_Values[index_EvRate][k], Module_Parameter_Values[index_TotTime][k]
//			endfor	
//			
//			fprintf filenum, "\rModule\t Channel\t Count Time(s)\t Input Count Rate (cps)\t Output Count Rate (cps)\t Pass Pileup Rate (cps)\t Filter dead time (s)\t Gate Rate (cps)\t Gate Time (s)\r" 
//			for(k=0;k<NumberOfModules;k+=1)
//				for(i=0; i<NumberOfChannels; i+=1)
//					fprintf filenum, "%d\t %d\t %g\t %g\t %g\t %g\t %g\t %g\t %g\r", k,i, CPV[index_COUNTTIME][i][k], CPV[index_ICR][i][k], CPV[index_OCR][i][k], CPV[index_PPR][i][k], CPV[index_SFDT][i][k], CPV[index_GCR][i][k], CPV[index_GDT][i][k]
//				endfor
//			endfor		
//			
//			fprintf filenum, "\r\r***** System Settings ****** \r\r"
//			
//			fprintf filenum, "Pixie Viewer release %x\r", ViewerVersion
//			
//			for(m=0;m<(NumSystemInParIFM+NumberOfModules);m+=1)  // number of input system parameters (or useful output variables)
//				text = System_Parameter_Names[m]
//				fprintf filenum, "%s\t", text
//				fprintf filenum, "%g\t", System_Parameter_Values[m]
//				fprintf filenum, "\r"
//			endfor
//			fprintf filenum, "\r"
//			
//			
//			for(m=0;m<NumModuleInParIFM;m+=1)  // number of input module parameters (or useful output variables)
//				text = Module_Parameter_Names[m]
//				fprintf filenum, "%s\t", text
//				for(k=0;k<NumberOfModules;k+=1)	
//					fprintf filenum, "%g\t", Module_Parameter_Values[m][k]
//				endfor	
//				fprintf filenum, "\r"
//			endfor
//			
//			//channel header
//			fprintf filenum, "\r%s\t", "Module Number"
//			for(k=0;k<NumberOfModules;k+=1)	
//				for(i=0;i<NumberOfChannels;i+=1)	
//					fprintf filenum, "%d\t", k
//				endfor
//			endfor	
//			fprintf filenum, "\r"
//			
//			fprintf filenum, "%s\t", "Channel Number"
//			for(k=0;k<NumberOfModules;k+=1)	
//				for(i=0;i<NumberOfChannels;i+=1)	
//					fprintf filenum, "%d\t", i
//				endfor
//			endfor	
//			fprintf filenum, "\r"
//						
//			for(m=0;m<NumChannelParIFM;m+=1)  // number of  input channel parameters (or useful output variables)
//				text = Channel_Parameter_Names[m]
//				fprintf filenum, "%s\t", text
//				for(k=0;k<NumberOfModules;k+=1)	
//					for(i=0;i<NumberOfChannels;i+=1)	
//						fprintf filenum, "%g\t", CPV[m][i][k]
//					endfor
//				endfor	
//				fprintf filenum, "\r"
//			endfor
//			
//			close filenum
//		else		// if file opened not successfully
//			printf "Pixie_File_RunStats: open statistics file failed, exiting ...\r" 
//			return(0)
//		endif
//	endif
//	
//	if(popnum == 2) // read from ifm file
//		
//		Open/D/R/T="????"/M="Read Run Statistics from Text File (.ifm)"/P=MCAPath filenum as "*.ifm"
//		filename=S_fileName	// full path and name of file opened, or "" if cancelled
//		
//		if (cmpstr(filename,"")!=0)		// if file defined succesfully
//			Open/R/Z/T="????" filenum as filename
//			
//			FReadline filenum, line
//			if (cmpstr(line[0,8], "XIA Pixie") !=0)
//				DoAlert 0, "Not a valid .ifm file, exiting"
//				close/a
//				return (0)
//			endif
//			
//			FReadline filenum, line
//			len = strlen(line)
//			StartTime = line[23,len-2]
//			
//			FReadline filenum, line
//			len = strlen(line)
//			StopTime = line[11,len-2]
//			
//			FReadline filenum, line	//blank
//			FReadline filenum, line
//			sscanf line, "Number of Modules: %d\r", NumberMod
//			FReadline filenum, line	//module header
//			k=0
//			do
//				FReadline filenum, line
//				sscanf line, "%d %g %g %g", Mnum, RT, ER, TT
//				Module_Parameter_Values[index_RunTime][Mnum] = RT
//				Module_Parameter_Values[index_NumEv][Mnum] = ER*RT
//				Module_Parameter_Values[index_TotTime][Mnum] = TT
//				Module_Parameter_Values[index_EvRate][Mnum] = ER
//			
//				k+=1
//			while (k<NumberMod)
//			
//			FReadline filenum, line	//blank
//			FReadline filenum, line	//channel header
//			k=0
//			do
//				for(i=0;i<NumberOfChannels;i+=1)
//					FReadline filenum, line
//					sscanf line, "%d %d %g %g %g %g %g %g %g", Mnum, Chnum, LT, ICR, OCR, PPR, SFDT, GCR, GDT
//					CPV[index_COUNTTIME][Chnum][Mnum] = LT
//					CPV[index_ICR][Chnum][Mnum] = ICR
//					CPV[index_OCR][Chnum][Mnum] = OCR
//					CPV[index_PPR][Chnum][Mnum] = PPR
//					CPV[index_SFDT][Chnum][Mnum] = SFDT
//					CPV[index_GCR][Chnum][Mnum] = GCR
//					CPV[index_GDT][Chnum][Mnum] = GDT
//				endfor
//				k+=1
//			while (k<NumberMod)
//			close filenum
//			InfoSource = filename
//			Pixie_RC_UpdateRunstats("ifmfile")
//		else		// if file opened not successfully
//			printf "Pixie_File_RunStats: open statistics file failed, exiting ...\r" 
//			return(0)
//		endif
//	endif
//	
//End	




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
	EndNum=ChanNum+1				// end of loop number
	Listnum=ChanNum					// entry in the MCA resutls array
	wavname = "MCAch"
	if (popNum==5)	
		ChanNum= 0	
		EndNum = 4						// run through 0..3
		Listnum=0
		wavname = "MCAch"
	endif
	if (popNum==6)
		ChanNum= 4						// "channel 4" is the ref spectrum
		EndNum=ChanNum+1
		Listnum=4
		wavname = "MCAch"
	endif
	if (popNum==7)						// 7 is addback
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


















//******************************************************************************************************************************
//******************************************************************************************************************************
// check for updates
//******************************************************************************************************************************
//******************************************************************************************************************************
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


