#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

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
	
	Variable/G root:PrintCoef
	
	Variable/G root:PSAchannel
	Variable/G root:energy_Igor
	Variable/G root:energy_File
	
	Make/o/n=1 root:trace
	Make/o/n=1 root:ff
	
	Make/o/n=6 root:xp
	make/o/n=100 triggers, piledup
	Make/o/n=1 root:sumlimits
	Make/o/n=1 root:triglimits

	make/o/n=20 root:EdbgIgor


End

Window AnalysisControl() : Panel
	
	NewPanel/K=1 /W=(930,20,1250,370)
	ModifyPanel cbRGB=(57344,65280,48896)
	SetVariable setvar0,pos={10,6},size={180,18},title="SL (# samples at full rate)",value= SL, fsize=11
	SetVariable setvar1,pos={10,30},size={180,18},title="SG (# samples at full rate)",value= SG, fsize=11
	SetVariable setvar2,pos={10,54},size={180,18},title="Tau (us)          ",value= tau, fsize=11
	SetVariable setvar3,pos={10,78},size={180,18},title="dT (us) = (full rate)",value= DeltaT, fsize=11
	SetVariable setvar6,pos={10,102},size={180,18},title="trig pos near" ,value= defaultTriggerPos, fsize=11
	SetVariable setvar10,pos={10,126},size={180,18},title="samples to skip",value= SkipInitialPoints, fsize=11

	
	SetVariable setvar7,pos={10,150},size={90,18},title="FL",value= FL, fsize=11
	SetVariable setvar8,pos={10,172},size={90,18},title="FG",value= FG, fsize=11
	SetVariable setvar9,pos={10,194},size={90,18},title="TH",value= Threshold, fsize=11
	CheckBox setvar11, pos = {10,216}, title = "Print E coeficients", variable = PrintCoef, fsize=11
		
	SetVariable setvar4,pos={210,50},size={80,18},title="channel",value= PSAchannel, fsize=11
	
	SetVariable AnalysisReadEvents, pos={10,250},size={150,18},proc=Analysis_CommonSetVariable
	SetVariable AnalysisReadEvents, limits={0,Inf,1},value= root:pixie4:ChosenEvent,format="%d"
	SetVariable AnalysisReadEvents, title="Event Number ",fstyle=1,fsize=11
	
	SetVariable res01,  pos={ 10,300},size={140,18}, noedit=1, noproc, value=energy_Igor, title="Energy (Igor)"
	SetVariable res02,  pos={155,300},size={100,18}, noedit=1, noproc, value=energy_File, title=" (File)"
	Button ShowFilter,  pos={ 10,320},size={80,20}, proc=Analysis_CommonButton, title="Filter"

EndMacro

Window AnalysisPlot_Filter() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /K=1/W=(125.25,55.25,558,393.5) ff
	AppendToGraph/L=L1/B=HorizCrossing trace
	AppendToGraph/L=L1 sumlimits,triglimits
	ModifyGraph mode(ff)=6,mode(trace)=6,mode(sumlimits)=3,mode(triglimits)=3
	ModifyGraph marker(sumlimits)=29,marker(triglimits)=14
	ModifyGraph rgb(sumlimits)=(51456,44032,58880),rgb(triglimits)=(0,0,0)
	ModifyGraph lblPos(left)=47,lblPos(bottom)=37,lblPos(L1)=49,lblPos(HorizCrossing)=24
	ModifyGraph lblLatPos(L1)=7,lblLatPos(HorizCrossing)=124
	ModifyGraph freePos(L1)={0,bottom}
	ModifyGraph freePos(HorizCrossing)={0,left}
	ModifyGraph tickZap(HorizCrossing)={0}
	ModifyGraph axisEnab(left)={0.5,1}
	ModifyGraph axisEnab(L1)={0,0.45}
	Cursor/P A ff 250;Cursor/P B ff 249
	ShowInfo

EndMacro

Function Analysis_CommonButton(ctrlName)
String ctrlName

	StrSwitch(ctrlName)
	
		Case "ShowFilter":
		
			Execute "AnalysisPlot_Filter()"
			break
						
		Default:
			break
	EndSwitch

End

Function Analysis_CommonSetVariable(ctrlName,varNum,varStr,varName) : SetVariableControl
	String ctrlName,varStr,varName
	Variable varNum

	// global variables and waves
	
	StrSwitch(ctrlName)	
				
		Case "AnalysisReadEvents":
		
			Pixie_File_ReadEvent()
			ComputeE()
			break
						
		Default:
			break
	EndSwitch

End




//*********************************************************************************
// Offline energy computation
//*********************************************************************************

Function ComputeE()

	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
	Nvar PSAchannel
	Nvar energy_Igor
	Nvar energy_File
	ComputeE_triggers()		// finds triggerpos and checks for pileup
	ComputeE_MarkSF() 		// marks energy sum limits
	energy_Igor = ComputeE_trapezoid()
	energy_File = ListModeChannelEnergy[PSAchannel]
	
	
	return(energy_Igor)
End


Function ComputeE_trapezoid()

	Nvar SL = SL
	Nvar SG =SG
	Nvar Tau
	Nvar DeltaT	
	Nvar PSAchannel
	Nvar TriggerPos = root:TriggerPos
	Nvar SkipInitialPoints
	Nvar PrintCoef
	
	Wave xp=xp
	Wave sumlimits=root:sumlimits
	Wave EdbgIgor = root:EdbgIgor

	Wave trace =  $("root:pixie4:trace"+num2str(PSAchannel))
	
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
	if(PrintCoef)
		print "q = ",q,"; elm = ",(q^SL),"; C0 = ",C0,"; Cg = ",Cg,"; C1 = ", C1 
	endif
	
	// Calculate energy
	energy=C0*sum(trace,xp[0],xp[1]) + Cg*sum(trace,xp[2],xp[3]) + C1*sum(trace,xp[4],xp[5])
	//print "energy (no BL) = ", energy

	
	//calculate baselines
	off=TriggerPos -SL - 10
	numbases = floor( (off-SkipInitialPoints) / (SL+SG+SL))
	
	if(numbases == 0)
		printf "Warning: event w/o baseline\r"
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
	
	Wave trace =  $("root:pixie4:trace"+num2str(PSAchannel))
	Wave sumlimits
	Wave xp
	
	duplicate/o trace, sumlimits
	sumlimits=nan

	Variable p0, p1, p2, p3, p4, p5,p6, p7

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
	Nvar SkipInitialPoints
	Nvar RTlow = root:PW:RTlow //= 0.1
	Nvar LB =  root:PW:LB 
	
	Wave src_trace =  $("root:pixie4:trace"+num2str(PSAchannel))
	Wave triggers
	
	variable k, base, j , ampl, THlevel, off, numTriggers
	variable x0,x1, x2,x3, m
	Variable npnts
	wavestats/q src_trace
	npnts = V_npnts

	duplicate/o src_trace, ff
	duplicate/o src_trace, triglimits
	duplicate/o src_trace, trace
	Wave ff	
	Wave triglimits
	Wave trace	
	triggers = nan
	triglimits = nan
	
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
			triggers[m]= floor(k	-FL/2	)	// adjust to fall before the rising edge
			triglimits[triggers[m]] = trace[triggers[m]]
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


Function Fit4peaks(channel)
Variable channel

	Wave MCAStartFitChannel=root:pixie4:MCAStartFitChannel
	Wave MCAEndFitChannel=root:pixie4:MCAEndFitChannel
	Nvar MCAfitOption =  root:pixie4:MCAfitOption
	
	Variable Npeaks, peak, xa, xb
	String wvn, tracename
	Variable popNum
	String ctrlName,popStr
	Npeaks=4
	
	popNum = channel+1
	ctrlName = "GaussFitMCA"
	popStr = ""
	wvn = "root:pixie4:MCAch"+num2str(channel)
	wave wav =$(wvn)
	tracename = "MCAch"+num2str(channel)
	
	xa = 0				
	xb = 32000
	MCAfitOption = 4			// fit within cursors
	Execute "Pixie_Plot_MCA_XL()"		// bring plot to front
	
	
	
	for(peak=0;peak<Npeaks;peak+=1)
	
		Findlevel/q/R=(xa,xb) wav, 100
		
		if(V_flag==1)
			print "No peak found"
		else
			cursor/W=MCASpectrumDisplayXL A $tracename (V_LevelX-100)
			cursor/W=MCASpectrumDisplayXL B $tracename (V_LevelX+100)
			
			Pixie_Math_GaussFit_XL(ctrlName,popNum,popStr)
			
			xa = V_LevelX+200
		endif
	
	
	endfor



End