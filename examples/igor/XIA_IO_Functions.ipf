#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method but not strict wave access.



//########################################################################
//
//  Pixie_File_ReadEvent:                                                                                                                   //
//   Extract one event from a LM file                                                                                                   //
// Unlike the function in P4e SW, does not use C library API for events from runtypes 0x400, 402  
//
//########################################################################

Function Pixie_File_ReadEvent()

	Nvar ChosenModule = root:pixie4:ChosenModule
	Nvar ChosenChannel = root:pixie4:ChosenChannel
	Nvar LMeventChannel = root:pixie4:LMeventChannel
	Nvar NumberOfChannels = root:pixie4:NumberOfChannels
	Nvar EventHitpattern = root:Pixie4:EventHitpattern
	Nvar EventTimeHI = root:Pixie4:EventTimeHI
	Nvar EventTimeLO = root:Pixie4:EventTimeLO
	Nvar wftimescale = root:pixie4:wftimescale			// sample interval in seconds  as read from the file (or entered manually)
	Nvar WFscale =root:pixie4:WFscale 					// sample interval in ns (user entry in panel)	
	
	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
	Wave ListModeChannelTrigger=root:pixie4:ListModeChannelTrigger
	Wave ListModeChannelXIA=root:pixie4:ListModeChannelXIA
	Wave ListModeChannelUser=root:pixie4:ListModeChannelUser
		
	Nvar evsize = root:pixie4:evsize					// number of words (lines) per event
	Nvar ChosenEvent = root:pixie4:ChosenEvent		// number of event to read
	Svar lmfilename = root:pixie4:lmfilename
	Nvar runtype = root:pixie4:runtype
	Nvar tracesinpxp = root:pixie4:tracesinpxp
	Nvar messages = root:pixie4:messages
	Nvar ModuleType = root:pixie4:ModuleType
//	Nvar  TSscale = root:LM:TSscale

	
	// local variables
	Variable i,j,len,NumTraces,NumEvents,ModLoc,index,filnum,totaltraces,dt,ret
	Variable tmin, tmax
	String wav
	Variable BufHeadLen = 4
	Variable EventHeadLen = 3
	Variable energy, userpsa, xiapsa
	variable evpos, chnum
	Variable TL, BlkSize,  RunFormat, CHL,FHL,  EL, CFD16, cfdsrc
	Variable Chstart, Chend
	//Variable ModuleType
	String ext
	
	wave LMfileheader =  root:pixie4:LMfileheader
	wave LMeventheader = root:pixie4:LMeventheader
	
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
					
	// read event
	// check file format
	len = strlen(lmfilename)			// length of file name
	ext = lmfilename[len-3,len-1]		// last 3 characters of file name
	strswitch(ext)
		case "txt":
			runtype = 0x500
			break
			
		case "dat":
			runtype = 0x501
			DoAlert 0, "LM event read for 0x501-503 not implemented yet"
			return(-1)	
			break
			
		case "dt2":
			runtype = 0x502
			DoAlert 0, "LM event read for 0x501-503 not implemented yet"
			return(-1)
			break
			
		case "dt3":
			runtype = 0x503
			DoAlert 0, "LM event read for 0x501-503 not implemented yet"
			return(-1)
			break
			
	endswitch
	
	
	if(runtype==0x500)
		
		evpos = BufHeadLen+evsize*ChosenEvent
		
		if(tracesinpxp==0)
			wave alltraces
			wave pn_energy =  root:LM:energy
			// load trace into numeric wave trace0
			LoadWave/Q/G/L={0,evpos+8,evsize-8,0,0}/O/N=trace/P=home lmfilename
			wave trace0
			
			//load header
			LoadWave/Q/J/L={0,evpos,8,0,0}/O/N=header/P=home/K=2 lmfilename
			wave/t header0
			
			energy  = str2num(header0[5])
		else
			make/o/n=(evsize-8) trace0
			wave trace0 
			trace0 = alltraces[p][ChosenEvent]
			
			energy  = pn_energy[ChosenEvent]
		endif
		
		// populate event header data
		ChosenChannel = str2num(header0[1])
		LMeventChannel = ChosenChannel
		LMeventheader[9] = ChosenChannel		// make ch# accessible to other functions also, as if it was 0x40?
		sscanf header0[2], "0x%x", EventHitpattern
		EventTimeHI =str2num(header0[3])
		EventTimeLO = str2num(header0[4])
		
		// extract header data
		ListModeChannelEnergy=0		// zero all channels
		ListModeChannelTrigger=0
		ListModeChannelXIA=0
		ListModeChannelUser=0	
		ListModeChannelEnergy[ChosenChannel]=energy	// fill selected channels
		ListModeChannelTrigger[ChosenChannel]=EventTimeLO
		ListModeChannelXIA[ChosenChannel]=str2num(header0[6])
		ListModeChannelUser[ChosenChannel]=str2num(header0[7])
		
		// distribute traces to the four channels and scale	
		wftimescale = WFscale* 1e-9		// use panel value. better: find from module type in file header
		for(i=0; i<NumberOfChannels; i+=1)
			wav="root:pixie4:trace"+num2str(i)
			wave listtrace = $wav
			duplicate/o trace0, listtrace
			if(i != ChosenChannel)
				listtrace =nan
			endif
			
			SetScale/P x,0,wftimescale,"s",$wav		
		endfor
		
		
	endif // 0x500
	
	if(runtype<0x500)
	

		variable off=0
		variable RTok=0
		BlkSize = 32		// default unless specified in file
	
		// check if file exists
		filnum =-1
		open/R/M="Open binary LM file"/P=home filnum as lmfilename
		if(filnum==-1)
			print "Could not open LM file"
			return (-1)
		endif
		
		// check file
		Fstatus filnum
		if(V_logEOF<16)
			print "LM file has fewer bytes than expected, aborting"
			return (-1)
		endif
	
		// read file header
		Fbinread	/b=3/U/F=2 filnum, LMfileheader
		
		// check the run type
		if( (LMfileheader[2] == 0x110) || (LMfileheader[2] == 0x111) || (LMfileheader[2] == 0x104) ) 
		//	evsize = LMfileheader[0] + (LMfileheader[10] & 0x7FFF) 		// assuming all are the same as ch.0 
			Pixie_Make_LMheadernames110()										// repopulate header names and indices
		//	runtype=LMfileheader[2]
			FHL = 0
			CHL = LMfileheader[0]
			TL 	 = evsize - CHL //TL 	 = LMfileheader[10] & 0x7FFF
			ModuleType = LMfileheader[iMType]
			RTok=3
		endif
		
		if(LMfileheader[2] == 0x400)
			BlkSize = LMfileheader[0]
		//	evsize = LMfileheader[8]	* BlkSize		// assuming all are the same as ch.0 
			Pixie_Make_LMheadernames400()				// repopulate header names 
		//	runtype=LMfileheader[2]
			FHL = BlkSize
			CHL = LMfileheader[3]
			TL 	 = evsize - CHL
			ModuleType = LMfileheader[iMType]
			RTok=1
		endif
		if(LMfileheader[2] == 0x402)
			BlkSize = LMfileheader[0]
		//	evsize = LMfileheader[6]	* BlkSize		// always all 4 channels are read
			Pixie_Make_LMheadernames402()				// repopulate header names for runtype 0x402
		//	runtype=LMfileheader[2]
			FHL = BlkSize
			CHL = LMfileheader[3]
			TL 	 = evsize - CHL
			ModuleType = LMfileheader[iMType]
			RTok=1
		endif
		if(LMfileheader[2] == 0x404)
		//	evsize = LMfileheader[9]*BlkSize  + LMfileheader[0]	// assuming all are the same as ch.0 
			Pixie_Make_LMheadernames404()								// repopulate header names 
		//	runtype=LMfileheader[2]
			FHL = 0
			CHL = LMfileheader[0]
			TL = LMfileheader[9]*BlkSize
			ModuleType = LMfileheader[iMType]
			RTok=3
		endif
		if(LMfileheader[2] == 0x410)
		//	evsize = LMfileheader[5]*BlkSize  + LMfileheader[0]	// assuming all are the same as ch.0  TODO: change to word 5
			Pixie_Make_LMheadernames410()								// repopulate header names 
		//	runtype=LMfileheader[2]
			FHL = 0
			CHL = LMfileheader[0]
			TL 	 = evsize - CHL
			ModuleType = LMfileheader[iMType]
			RTok=3
		endif
		if(LMfileheader[0] == 0xAAAA)		
		//	evsize = LMfileheader[9]*BlkSize +  LMfileheader[0]	// assuming all are the same as ch.0 	TODO: change to word 5
			Pixie_Make_LMheadernames411()								// repopulate header names 
		//	runtype=LMfileheader[2]
			FHL = 0
			CHL = (LMfileheader[7] & 0xFC00) / 1024  +2
			TL 	 = evsize - CHL
			ModuleType = LMfileheader[iMType]
			RTok=3
		endif
		
		if(RTok == 0)	// try P16 0x100 or 0x105 (called 0x116 here)  
		//	evsize =  (LMfileheader[1] & 0x7FFE)		
			Pixie_Make_LMheadernames116()							// repopulate header names
		//	runtype=0x116
			FHL = 0
			//CHL = 36//2* ( (LMfileheader[0] & 0xF000)/2^12 + (LMfileheader[1] & 0x0001)*16 ) 
			CHL = 2* ( (LMfileheader[0] & 0xF000)/2^12 + (LMfileheader[1] & 0x0001)*16 ) 
			TL 	= LMfileheader[7] & 0x7FFF		// assuming here, all events are the same length! 
			ModuleType = 0
			RTok=2	
		endif
					
			
		// move to the chosen event 
		evpos 		= (FHL+(ChosenEvent*evsize) )*2		
		Fstatus filnum
		if(evpos >= V_logEOF)	// evpos and V_logEOF in bytes
			print "end of file reached, aborting"
			return(-1)
		endif
		FSetPos filnum, evpos
		
		// read the header
		make/o/n=(CHL)/u/i root:pixie4:LMeventheader
		wave LMeventheader = root:pixie4:LMeventheader
		Fbinread	/b=3/U/F=2 filnum, LMeventheader	
			
			
		// -------- at this point we have the event header loaded into Igor. Now sort values into display variables
		// ChosenChannel: channel number modulo 4, for LM trace dispaly etc
		// LMeventChannel: actual channel number in file
		// chnum:	same as ChosenChannel TODO unify?
			
		// channel
		if(runtype==0x400 || runtype==0x404 || runtype==0x410)
			ChosenChannel = LMeventheader[iChannel]  & 0x3		// contract to channels 0-3
			LMeventChannel = LMeventheader[iChannel]
			chnum = ChosenChannel
		elseif(runtype==0x411)		
			ChosenChannel = LMeventheader[28] & 0x3		// contract to channels 0-3
			LMeventChannel = LMeventheader[28] & 0xF
			chnum = ChosenChannel
		elseif(runtype==0x116)		
			ChosenChannel = LMeventheader[0] & 0x3		// contract to channels 0-3
			LMeventChannel = LMeventheader[0] & 0xF
			chnum = ChosenChannel
		elseif(runtype==0x110 || runtype==0x111)		
			ChosenChannel = LMeventheader[3] & 0x3		// contract to channels 0-3
			LMeventChannel = LMeventheader[3] & 0xF
			chnum = ChosenChannel
		// todo: sort out 0x402, uses 0
		else
			ChosenChannel =  0
			LMeventChannel = ChosenChannel
			chnum = ChosenChannel
		endif
		
		if(runtype!=0x402)		// 0x402 loops over all channels
			Chstart = ChosenChannel
			Chend = ChosenChannel+1
		else
			Chstart = 0			
			Chend = NumberOfChannels
			ChosenChannel = 0
		endif	
					
		// hit pattern 
		if(runtype==0x400 || runtype==0x402 || runtype==0x404 || runtype==0x410)
			EventHitpattern = LMeventheader[iHitL]+65536*LMeventheader[iHitM]
		else 
			EventHitpattern = 0
		endif
		if(runtype==0x116)
			EventHitpattern = 2^chnum +2^20 + 2^5 + 2^(chnum+8)	// extract hit pattern into P4e style
			if(LMeventheader[1] & 0x8000 >0)
				EventHitpattern += 2^18
			endif
			if(LMeventheader[7] & 0x8000 >0)
				EventHitpattern += 2^21
			endif
		endif
		if(runtype==0x110 || runtype==0x111)
			EventHitpattern = 2^chnum +2^20 + 2^5 + 2^(chnum+8)	// extract hit pattern into P4e style
			if(LMeventheader[4] & 0x8000 >0)
				EventHitpattern += 2^18
			endif
			if(LMeventheader[10] & 0x8000 >0)
				EventHitpattern += 2^21
			endif
		endif
		
		// event time low
		EventTimeLO =  LMeventheader[iTimeL]+65536*LMeventheader[iTimeM]
		
		// event time high
		if(runtype==0x400 || runtype==0x402 || runtype==0x404 || runtype==0x410)
			EventTimeHI = LMeventheader[iTimeH]+65536*LMeventheader[iTimeX]		
		else
			EventTimeHI = LMeventheader[iTimeH]
		endif
			
			
		
		// fill LM Display table
		ListModeChannelEnergy=0
		ListModeChannelTrigger=0
		ListModeChannelXIA=0
		ListModeChannelUser=0	
		for(i=Chstart; i<Chend; i+=1)
			if(runtype==0x402)
				ListModeChannelEnergy[i]=LMeventheader[10+4*i]
				ListModeChannelTrigger[i]=LMeventheader[8+4*i]+65536*LMeventheader[9+4*i]
			else			
				ListModeChannelEnergy[i]=LMeventheader[iEnergy]
				ListModeChannelTrigger[i]=EventTimeLO
				if(runtype==0x400 || runtype== 0x116)
					ListModeChannelXIA[i]=LMeventheader[iCFDresult]					// CFD
				elseif (runtype==0x410 || runtype==0x411 || runtype==0x110 || runtype==0x111)
					ListModeChannelXIA[i] = Pixie_Math_CFDfrom4hdr()	// TDOD: use LMeventheader, not wfarray
				else
					ListModeChannelXIA[i] = 0
				endif
				ListModeChannelUser[i]= 0// ExtTS or perhaps PSA
			endif
		endfor 
		
		// read the trace(s)			
		// wftimescale set by LMheadernames functions
		
		for(i=0; i<NumberOfChannels; i+=1)				// loop over all channels
			wav="root:pixie4:trace"+num2str(i)
			wave listtrace = $wav
			if( (i>=Chstart) && (i<Chend) )				// read trace for channels present in this event
				if(TL>0)
					make/o/n=(TL) trace0
					wave trace0
					Fbinread	/b=3/U/F=2 filnum, trace0	// read the trace
					duplicate/o trace0, listtrace
				else
					listtrace =nan
				endif	
			else			
				listtrace =nan						// clear  trace for channels NOT present in this event
			endif
			
			SetScale/P x,0,wftimescale,"s",$wav	
	
		endfor
		
		close filnum

	
	endif // <0x500
	
	
	if(messages)
		Variable sdev
		wavestats/q/R=[0,30] trace0
		sdev = V_sdev
		wavestats/q trace0
		printf "Channel %d, loaded %d samples, HP = %X, base sdev = %f, ampl = %d\r",ChosenChannel, TL,EventHitpattern, sdev, V_max-V_min
	
	endif

	Pixie_MakeList_Traces(1)
	
	Pixie_FilterLMTraceCalc()  // Calculate digital filter for the trace in the ChosenChannel
					
	// populate event info variables
	Nvar EvHit_Front = root:Pixie4:EvHit_Front
	Nvar EvHit_Accept = root:Pixie4:EvHit_Accept
	Nvar EvHit_Status = root:Pixie4:EvHit_Status
	Nvar EvHit_Token = root:Pixie4:EvHit_Token
	Nvar EvHit_CoincOK = root:Pixie4:EvHit_CoincOK
	Nvar EvHit_Veto = root:Pixie4:EvHit_Veto
	Nvar EvHit_PiledUp = root:Pixie4:EvHit_PiledUp
	Nvar EvHit_WvFifoFull = root:Pixie4:EvHit_WvFifoFull
	Nvar EvHit_ChannelHit = root:Pixie4:EvHit_ChannelHit
	Nvar EvHit_OOR = root:Pixie4:EvHit_OOR
	Nvar EvHit_Derror = root:Pixie4:EvHit_Derror
	EvHit_Front     = (EventHitpattern&(2^4))>0
	EvHit_Accept    = (EventHitpattern&(2^5))>0
	EvHit_Status    = (EventHitpattern&(2^6))>0
	EvHit_Token     = (EventHitpattern&(2^7))>0
	EvHit_CoincOK   = (EventHitpattern&(2^16))>0
	EvHit_Veto      = (EventHitpattern&(2^17))>0
	EvHit_PiledUp   = (EventHitpattern&(2^18))>0
	EvHit_WvFifoFull= (EventHitpattern&(2^19))>0
	EvHit_ChannelHit= (EventHitpattern&(2^20))>0
	EvHit_OOR       = (EventHitpattern&(2^21))>0
	EvHit_Derror    = (EventHitpattern&(2^31))>0 
	
	
	//////////////////////////////////////////////////////////// 
	// Call to user routine			             //
	User_ReadEvent()
	////////////////////////////////////////////////////////////	
	
	return (0)
			
End




//########################################################################
//
//  Pixie_IO_Serial:                                                                                        
//    send a [series of] string[s] to Pixie-Net using Igor's VDT2 plug-in          
//
//########################################################################
Function Pixie_IO_Serial(ctrlName) : ButtonControl
	String ctrlName	
	
	String cmd 
	Svar page = root:pixie4:page
	Nvar messages = root:pixie4:messages
	Nvar ModuleTypeXL = root:pixie4:ModuleTypeXL
	Variable k, readtry
	Svar parametername = root:pixie4:parametername
	Svar parametervalues = root:pixie4:parametervalues
	Nvar webops =root:pixie4:webops
	
	if(webops)
		Doalert 0, "Please deselect webops option for serial I/O operation"
		return(-2)
	endif
	
	
	strswitch(ctrlname)	// string switch
		case "setup":		// execute if case matches expression
	// 		better do this manually; COM number is variable	
	//		VDTClosePort2 COM9	// close open port in case of power cycle on MZ
	//		Sleep/T 5
	//		VDTOpenPort2 COM9
	//		Sleep/T 5
	//		VDTOperationsPort2 COM9
	//		Sleep/T 5
			
	//		VDTwrite2/O=1 "chmod 777 /dev/uio0\r"
			VDTwrite2/O=1 "cd /var/www\r"
			if(ModuleTypeXL)
				VDTwrite2/O=1 "./bootfpga"
			endif
			VDTwrite2/O=1 "./progfippi\r"
			if(ModuleTypeXL)
				print "Pixie-Net XL currently does not perform 'findsettings' properly"
			else
				VDTwrite2/O=1 "./findsettings\r"
			endif
			Sleep/T 600
			VDTwrite2/O=1 "./gettraces\r"
			break						// exit from switch
			
		case "sed":		// execute if case matches expression
			cmd = "sed -i '/"+parametername+"/c "+parametername+"        "+parametervalues+" ' settings.ini\r"
			VDTwrite2/O=1 	cmd	
			break
			
		case "halt":		// execute if case matches expression
			cmd = ctrlName+"\r"
			VDTwrite2/O=1 	cmd		
			break
			
		case "print":
			// do nothing
			messages = 1
			break
			
		default:							// optional default expression executed
			cmd = "./"+ctrlName+"\r"
			VDTwrite2/O=1 	cmd
			break				// when no case matches
	endswitch
	
	
	if(cmpstr(ctrlname,"findsettings")==0)
		Sleep/T 600
		readtry = 200
	else
		Sleep/T 5
		readtry = 20
	endif
	
	
		k=0
		do
			VDTread2/Q/O=1/T="\r" 	page
			if(messages)
				print " >>> Pixie-Net:",page
			endif
			//Sleep/T 1
			k+=1
		while( (k<readtry) && (V_VDT>0)  )
	
	
End

//########################################################################
//
//  Pixie_IO_ReadADCMCA:                                                                                                  
//    Read an ADC or MCA file from the Pixie-Net's website (or local/network path)       
//
//########################################################################


Function Pixie_IO_ReadADCMCA(ctrlName) : ButtonControl
	String ctrlName		// ADC or MCA

	//Svar MZip = root:pixie4:MZip
	Wave/t MZ_ip   = root:pixie4:MZ_ip
	Wave/t MZ_user = root:pixie4:MZ_user 
	Wave/t MZ_pw   = root:pixie4:MZ_pw 
	Nvar ModNum = root:pixie4:ModNum
	Svar page = root:pixie4:page
	Nvar localfile = root:pixie4:localfile
	Nvar messages = root:pixie4:messages
	Nvar ModuleTypeXL = root:pixie4:ModuleTypeXL
	Nvar webops =root:pixie4:webops
	
	
	String fullFilePath, dwvname, twvname, zeropad, url
	Variable refNum, error, adctimescale, ch

 	if(!localfile)// get the file from the web and save locally, then reopen
 	
 		if(webops)
 			url = "http://"+MZ_user[ModNum]+":"+MZ_pw[ModNum]+MZ_ip[ModNum]+"@"+"/webops/"+ctrlname+".csv" // for debug
 			page =  fetchURL("http://"+MZ_user[ModNum]+":"+MZ_pw[ModNum]+"@"+MZ_ip[ModNum]+"/webops/"+ctrlname+".csv")
 		else
 			page =  fetchURL("http://"+MZ_ip[ModNum]+"/"+ctrlname+".csv")
 		endif

		error = GetRTError(1)		// Check for error before using response
		if (error != 0)
				DoAlert 0, "Could not connect to the web page. Please double check IP setup table."
			return(-1)
		endif
		
		// can't use the string as is, save to a local file

		Open/D=2/M="Save File As..."/T="????" /P=home refNum as "localdata.csv"
		fullFilePath = S_fileName
		if (strlen(fullFilePath) > 0) // No error and user didn't cancel in dialog.
		// Open the selected file so that it can later be written to.
			Open/Z/T="????" refNum as fullFilePath
			if (V_flag != 0)
				Print "There was an error opening the local destination file."
			else
				FBinWrite refNum, page
				Close refNum
			endif
		endif
	else // get the file from a local (or network) folder
		Open/R/D/T="????"/M="Looking for *.csv" refNum 
		fullFilePath = S_fileName
		if (strlen(fullFilePath) == 0) // error or user  canceled in dialog.
			return(-1)
		else
			//Close refNum //the open above only looks for file, not actually opens it
		endif
	endif
	
	//read back from local file into top level waves
	// todo: clear waves first?
	Loadwave/J/O/A/W fullFilePath		// loads data into waves named by header
	
	if(ModuleTypeXL)
		 // sort data into display waves
		Pixie_Ctrl_SetDisplayChannel("MCAch0sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("MCAch1sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("MCAch2sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("MCAch3sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("MCAch4sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("MCAch5sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("MCAch6sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("MCAch7sv", 0,"","")
		
		Pixie_Ctrl_SetDisplayChannel("ADCch0sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch1sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch2sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch3sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch4sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch5sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch6sv", 0,"","")
		Pixie_Ctrl_SetDisplayChannel("ADCch7sv", 0,"","")
	endif
	
	
	//copy to display waves 
	// "d" = destination, "t" = source
	if(cmpstr(ctrlname,"MCA")==0)
		dwvname = ctrlname+"ch"	//loaded MCAch# to root:pixie:MCAch#
		twvname = ctrlname+"ch"
		if(ModuleTypeXL)
			zeropad = ""		// PNXL has 1-2 digit numbering for MCA spectra
		endif
	else
		dwvname = ctrlname+"ch"		//loaded ADC# to root:pixie:ADCch#
		twvname = ctrlname
		if(ModuleTypeXL)
			zeropad = ""		// PNXL NO LONGER has two digit numbering for ADC traces
		endif
	endif

	// destination wave names
	wave d0 = $("root:pixie4:"+dwvname+"0")
	wave d1 = $("root:pixie4:"+dwvname+"1")
	wave d2 = $("root:pixie4:"+dwvname+"2")
	wave d3 = $("root:pixie4:"+dwvname+"3")
	wave d4 = $("root:pixie4:"+dwvname+"4")
	wave d5 = $("root:pixie4:"+dwvname+"5")
	wave d6 = $("root:pixie4:"+dwvname+"6")
	wave d7 = $("root:pixie4:"+dwvname+"7")
	
	// text file wave names (source)
	if(ModuleTypeXL)
		wave sm = sample		// PNXL uses "sample" to report time in us
		adctimescale = (sm[1] - sm[0])*1e-6		
	else
		adctimescale = 230e-9
		
		wave t0 = $(twvname+"0")
		wave t1 = $(twvname+"1")
		wave t2 = $(twvname+"2")
		wave t3 = $(twvname+"3")
		
		d0=t0
		d1=t1
		d2=t2
		d3=t3
	endif
	
	// apply scaling
	if(cmpstr(ctrlname,"ADC")==0)
		setscale/P x,0,adctimescale, "s", d0
		setscale/P x,0,adctimescale, "s", d1
		setscale/P x,0,adctimescale, "s", d2
		setscale/P x,0,adctimescale, "s", d3	
		setscale/P x,0,adctimescale, "s", d4
		setscale/P x,0,adctimescale, "s", d5
		setscale/P x,0,adctimescale, "s", d6
		setscale/P x,0,adctimescale, "s", d7	
			
		if(messages)
			wavestats/q d0
			print "sigma ch.0", V_sdev
			wavestats/q d1
			print "sigma ch.1", V_sdev
			wavestats/q d2
			print "sigma ch.2", V_sdev
			wavestats/q d3
			print "sigma ch.3", V_sdev	
		endif
	
	endif

End

//########################################################################
//
//  Pixie_IO_ReadRS:                                                                                            
//    Read an runstats file from the Pixie-Net's website (or local/network path)              
//
//########################################################################
Function Pixie_IO_ReadRS(ctrlName) : ButtonControl
	String ctrlName		

	//Svar MZip = root:pixie4:MZip
	Svar page = root:pixie4:page
	Nvar localfile = root:pixie4:localfile
	Nvar messages = root:pixie4:messages
	Nvar ModuleTypeXL = root:pixie4:ModuleTypeXL
	Nvar webops =root:pixie4:webops
	Wave/t MZ_ip   = root:pixie4:MZ_ip
	Wave/t MZ_user = root:pixie4:MZ_user 
	Wave/t MZ_pw   = root:pixie4:MZ_pw 
	Nvar ModNum = root:pixie4:ModNum

	
	String fullFilePath, dwvname, twvname, url
	Variable refNum, error, adctimescale

 	if(!localfile)// get the file from the web and save locally, then reopen
 		
 	
 		if(webops)
 			url = "http://"+MZ_user[ModNum]+":"+MZ_pw[ModNum]+MZ_ip[ModNum]+"@"+"/webops/RS.csv" // for debug
 			page =  fetchURL("http://"+MZ_user[ModNum]+":"+MZ_pw[ModNum]+"@"+MZ_ip[ModNum]+"/webops/RS.csv")
 			//page =  fetchURL("http://"+MZip+"/webops/RS.csv")
 		else
 			page =  fetchURL("http://"+MZ_ip[ModNum]+"/RS.csv")
		endif

		error = GetRTError(1)		// Check for error before using response
		if (error != 0)
				DoAlert 0, "Could not connect to the web page. Please double check IP Setup table"
			return(-1)
		endif
		
		// can't use the string as is, save to a local file

		Open/D=2/M="Save File As..."/T="????" /P=home refNum as "RS.csv"
		fullFilePath = S_fileName
		if (strlen(fullFilePath) > 0) // No error and user didn't cancel in dialog.
		// Open the selected file so that it can later be written to.
			Open/Z/T="????" refNum as fullFilePath
			if (V_flag != 0)
				Print "There was an error opening the local destination file."
			else
				FBinWrite refNum, page
				Close refNum
			endif
		endif
	else // get the file from a local (or network) folder
		Open/R/D/T="????"/M="Looking for *.csv" refNum 
		fullFilePath = S_fileName
		if (strlen(fullFilePath) == 0) // error or user  canceled in dialog.
			return(-1)
		else
			//Close refNum the open above only looks for file, not actually opens it
		endif
	endif
	
	//read back from local file into top level waves
	Loadwave/J/O/A/W/K=2 fullFilePath		// loads data into TEXT waves named by header
	
	if(ModuleTypeXL)
		Execute "Pixie_Table_RunStats()"
	else
		// make the list for the display
		Pixie_MakeList_AllRunStats(1)
	endif
	


End


//########################################################################
//  Pixie_IO_ReadLM:                                                                                                
//    Read a LM file from the Pixie-Net's website (or local/network path)                       
//   using the fetchURL command, only words for text "webpages"
//
//########################################################################
Function Pixie_IO_ReadLM(ctrlName) : ButtonControl
	String ctrlName		// txt or dat

	//Svar MZip = root:pixie4:MZip
	Svar page = root:pixie4:page
	Nvar localfile = root:pixie4:localfile
	Nvar messages = root:pixie4:messages
	Nvar ModuleTypeXL = root:pixie4:ModuleTypeXL
	Wave/t MZ_ip   = root:pixie4:MZ_ip
	Wave/t MZ_user = root:pixie4:MZ_user 
	Wave/t MZ_pw   = root:pixie4:MZ_pw 
	Nvar ModNum = root:pixie4:ModNum
	
	String fullFilePath, localfilename
	String ext, basename
	Variable refNum, error
	
	if(ModuleTypeXL)					// PN XL has module number in file name, here always use 0
		basename = "LMdata0"
		ext = ctrlName[0,2]
		if(cmpstr(ctrlname,"dt3e")==0)
			basename = "LMdata_m0"			// P4e dt3 filename convention
		else
			DoAlert 0, "Pixie-Net XL currently does not suport Runtype 0x500-503"
			return (0)
		endif
	else
		basename = "LMdata"
		ext = ctrlName[0,2]
		if(cmpstr(ctrlname,"dt3e")==0)
			DoAlert 0, "Pixie-Net currently does not suport Runtype 0x401"
			return (0)
		endif
	endif

 	page =  fetchURL("http://"+MZ_ip[ModNum]+"/"+basename+"."+ext)

	error = GetRTError(1)		// Check for error before using response
	if (error != 0)
			DoAlert 0, "Could not connect to the web page."
		return(-1)
	endif
	
	//  save to a local file
	localfilename =basename+"."+ext
	Open/D=2/M="Save File As..."/T="????" /P=home refNum as localfilename
	fullFilePath = S_fileName
	if (strlen(fullFilePath) > 0) // No error and user didn't cancel in dialog.
	// Open the selected file so that it can later be written to.
		Open/Z/T="????" refNum as fullFilePath
		if (V_flag != 0)
			Print "There was an error opening the local destination file."
		else
			FBinWrite refNum, page
			Close refNum
		endif
	endif

End

//########################################################################
//
//  Pixie_File_ReadRawLMdata:                                         
//    Read a LM file and display raw values in a table 
//
//########################################################################
Function Pixie_File_ReadRawLMdata(CtrlName):ButtonControl	
String CtrlName

	Variable refnum
	Svar lmfilename = root:pixie4:lmfilename
	open/P=home/D/R/T="????" refnum 
	lmfilename = S_fileName
	if(cmpstr(S_fileName,"")==0)
		print "File selection cancelled, aborting"
		return(-1)
	endif

	// load currently specified LM file as a wave LMdata0
	//Svar lmfilename = root:pixie4:lmfilename
	GBLoadWave/B/O/A=LMData/T={80,4}/W=1 lmfilename
	Wave LMData0
	wave LMfileheader =  root:pixie4:LMfileheader
	Nvar runtype = root:pixie4:runtype
	Nvar evsize =  root:pixie4:evsize
	LMfileheader = LMData0		// fill the header wave with the first values of the file
	
	Variable eventlength, numwords, numevents, RTok
	RTok=0
	if( (LMData0[2] == 0x110) || (LMData0[2] == 0x111) || (LMData0[2] == 0x104) ) 
	//	eventlength = LMData0[0] + (LMData0[10] & 0x7FFF)		// assuming all are the same as ch.0 
		Pixie_Make_LMheadernames110()									// repopulate header names 
	//	runtype=LMData0[2]
		RTok=3
	endif
	
	if(LMData0[2] == 0x400)
	//	eventlength = LMData0[8]	* LMData0[0]				// assuming all are the same as ch.0 
		Pixie_Make_LMheadernames400()							// repopulate header names 
	//	runtype=LMData0[2]
		RTok=1
	endif
	if(LMData0[2] == 0x402)
	//	eventlength = LMData0[6]	* LMData0[0]				// always all 4 channels are read
		Pixie_Make_LMheadernames402()							// repopulate header names for runtype 0x402
	//	runtype=LMData0[2]
		RTok=1
	endif
	if(LMData0[2] == 0x404)
	//	eventlength = LMData0[9]*32  + LMData0[0]			// assuming all are the same as ch.0 
		Pixie_Make_LMheadernames404()							// repopulate header names 
	//	runtype=LMData0[2]
		RTok=3
	endif
	if(LMData0[2] == 0x410)
	//	eventlength = LMData0[5]*32  + LMData0[0]			// assuming all are the same as ch.0  TODO: change to word 5
		Pixie_Make_LMheadernames410()							// repopulate header names 
	//	runtype=LMData0[2]
		RTok=3
	endif
	if(LMData0[0] == 0xAAAA)		
	//	eventlength = (LMData0[7] & 0x03FF)  +18			// assuming all are the same as ch.0 	TODO: change to word 5
		Pixie_Make_LMheadernames411()							// repopulate header names 
	//	runtype=0x411
		RTok=3
	endif
	
	if(RTok == 0)	// try P16 0x100 or 0x105 (called 0x116 here)  	
	//	eventlength =  (LMData0[1] & 0x7FFE)		
		Pixie_Make_LMheadernames116()							// repopulate header names for runtype 0x100 P16
	//	runtype=0x116
		RTok=2	
	endif
	
	//evsize = eventlength										// save extracted length as global value
	

	// copy first 32 words into a header array
	make/o/n=32 LMheader
	Wave LMheader
	LMheader = LMdata0
		
	if(RTok == 1)	// only display header separately for 0x400,402
		DoWindow/F FileHeaderTable
		if(V_flag!=1)
			PauseUpdate; Silent 1		// building window...
			edit/K=1/W=(5,30,220,400) root:pixie4:LMheadernames, LMheader
			DoWindow/C FileHeaderTable
			ModifyTable format(Point)=1,width(LMheader)=50
		endif
		DeletePoints 0,32, LMData0 					// remove header from data wave
	endif
	
	// sort LMData into a 2D array
	wavestats/q LMData0
	numwords = V_npnts
	numevents = floor(numwords/evsize) +1	// just in case there is an end run record
	make/o/n=(evsize,numevents) wfarray
	wfarray = LMData0	// this essentially sorts the 1D data into a 2D array, first index is # word in event, second index is event #
	make/t/o/n=64 root:pixie4:EVheadernames
	Wave/t EVheadernames =  root:pixie4:EVheadernames
	Wave/t LMheadernames =  root:pixie4:LMheadernames
	if(RTok == 1)
		EVheadernames = LMheadernames[p+32]
	else
		EVheadernames = LMheadernames[p]
	endif
	
	print/D "Loaded", numevents," number of events (rounded up), length ",evsize
	printf "Runtype 0x%03x\n", runtype
	
	DoWindow/F EventArrayTable
	if(V_flag!=1)
		PauseUpdate; Silent 1		// building window...
		Edit/K=1/W=(230,30,840,400) root:pixie4:EVheadernames, wfarray
		DoWindow/C EventArrayTable
		ModifyTable format(Point)=1,width(wfarray)=50, width(EVheadernames)=130
	endif
	
	killwaves/Z LMData0
	
End

//########################################################################
//
//	Pixie_File_SaveRawLMdata:
//		Save the wfarray to a binary file (e.g. after manual editing)
//
//########################################################################

Function Pixie_File_SaveRawLMdata(CtrlName):ButtonControl	
String CtrlName

	Wave LMheader
	Wave wfarray
	
	Variable filelength, fnum
	wavestats/q wfarray
	filelength = V_npnts	// number of points in wfarray  
	make/o/n=(filelength) LMdata0
	LMdata0 = wfarray		// 2D into 1D wave
	insertpoints 0,32, LMdata0
	LMdata0[0,31] = LMheader
	
	open/M="Select new binary file name" fnum 
	fbinwrite/F=2/U fnum, LMdata0
	close fnum
	

	DoWindow/K EventArrayTable
	Killwaves/Z LMdata0, wfarray, LMheader

End



//########################################################################
//
//	Pixie_File_ExportCHN:
//		Export MCA spectrum to a ORTEC format .CHN file.
//
//########################################################################
Function Pixie_File_ExportCHN(ch)
Variable ch


	Variable HistogramLength, filenum, k, len, hour, binratio, truncate
	Variable data, numch, firstch, pos
	Variable CHN =-1
	String headerchar, datestring, timestring, strng, Msg, filename

	Svar StartTime = root:pixie4:StartTime
	Svar StopTime = root:pixie4:StopTime
	timestring = StartTime[0,8]
	truncate = 0

	wave mcawave=$("root:pixie4:MCACh"+num2str(ch))
	wavestats/q mcawave
	HistogramLength =V_npnts
	
	// Check if HistogramLength exceeds 16K channels
	if( HistogramLength> 16384)
		Sprintf Msg, "To be compatible with ORTEC® .CHN file format, histogram length should not exceed 16384. Current histogram length is %d. Click Yes below to rebin the histogram to 16384 bins and save as a .CHN file. Click No to truncate", HistogramLength
		DoAlert 1, Msg
		if(V_flag == 2)	// No is clicked
			//Return(0)
			truncate=1
			print "Truncating spectrum during export"
		else		// Yes is clicked
			// Rebin the histogram
			Make/o/d/n=16384 CHNformatMCAWave
			
			binratio = HistogramLength / 16384
			if(binratio == 4)	// 64K spectrum
				for(k=0; k<16384; k+=1)
					CHNformatMCAWave[k] = mcawave[k*binratio] + mcawave[k*binratio+1] + mcawave[k*binratio+2] + mcawave[k*binratio+3]
				endfor
			elseif(binratio == 2)	// 32K spectrum
				for(k=0; k<16384; k+=1)
					CHNformatMCAWave[k] = mcawave[k*binratio] + mcawave[k*binratio+1]
				endfor
			endif						
		endif
	endif


	Open/D/T="????"/M="Save MCA as .CHN file"/P=MCAPath filenum
	if(cmpstr(S_filename, "") == 0)
		return(-1)
	endif
	Open/P=MCAPath filenum as S_filename

	FbinWrite/F=2 filenum, CHN		// data format -1 for .CHN files
	data =1
	FbinWrite/U/F=2 filenum, data		// MCA number = 1
	FbinWrite/U/F=2 filenum, data		// Segment number = 1
	
	strng =StringfromList( 2,timestring,":") 	// ss AM
	headerchar = strng[0,1]				// ss 
	FbinWrite filenum, headerchar			// sec
	
	Wave Display_Channel_Parameters = root:pixie4:Display_Channel_Parameters
	Wave Display_Module_Parameters = root:pixie4:Display_Module_Parameters
	Nvar index_RunTime = root:pixie4:index_RunTime
	Nvar index_LIVETIME = root:pixie4:index_LIVETIME
	Nvar ncp = root:pixie4:NumChannelPar
	
	Variable Realtime = Display_Module_Parameters[index_RunTime]		// TODO find equivalent P4 value 
	data = Realtime*50
	FbinWrite/F=3 filenum, data		// in 20ms ticks
	Variable Livetime = Display_Channel_Parameters[ index_LIVETIME+ch*ncp]		// TODO find equivalent P4 value 
	data = Livetime*50
	FbinWrite/F=3 filenum, data		// in 20ms ticks

	headerchar = "xxxxxxxxxxxx"
	strng = StringfromList( 0,timestring,":")	
	headerchar[8,9]=strng						// hour
	strng = StringfromList( 1,timestring,":")		// min
	headerchar[10,11] = strng
	strng=headerchar[0,11]
	FbinWrite filenum, strng

	firstch = 0
	FbinWrite/U/F=2 filenum, firstch	// Starting Channel
	
	// Check if HistogramLength exceeds 16K channels
	if(HistogramLength <= 16384)

		Wavestats/q mcawave
		numch = V_npnts
		FbinWrite/U/F=2 filenum, numch	// Number of Channels 	
		
		for(k=firstch;k<firstch+numch;K+=1)
			data  = mcawave[k]
			FbinWrite/F=3 filenum, data
		endfor
		
	else		// Histogram length > 16384
	
		numch = 16384
		FbinWrite/U/F=2 filenum, numch	// Number of Channels 	
		
		for(k=firstch;k<firstch+numch;K+=1)
			if(truncate)
				data  = mcawave[k]
			else
				data  = CHNformatMCAWave[k]
			endif
			FbinWrite/F=3 filenum, data
		endfor
	
		// CHNformatMCAWave no longer needed
		KillWaves/Z CHNformatMCAWave
		
	endif
	
	// add footer -- 256 unknown words
	data=0
	for(k=0;k<256;k+=1)
		Switch(k)
			Case 0:
				data = 0xFF9A    // required by some programs, though not Ortec Gammavision
				break
			Case 5:
				data = 0x3F80    // required by some programs, though not Ortec Gammavision
				break
			Case 160:   
				data = 0x581D    // A text string can be encoded starting from word 160 X
				break
			Case 161:   
				data = 0x4149	// AI
				break
			Case 162:   
				data = 0x5020   // P_
				break
			Case 163:   
				data = 0x7869  //xi	//0x6C6F   //lo
				break
			Case 164:   
				data = 0x6569  //ei 	0x7261   //ra
				break
			Case 165:   
				data = 0  // 0x7369   //si
				break
			default:
				data = 0
		EndSwitch

  		FbinWrite/U/F=2 filenum, data
  	endfor

	Close filenum
	
	Return(0)
	
End

//########################################################################
//
//	Pixie_File_MCA:
//		Read MCA histogram from a previously saved MCA file.
//
//########################################################################
Function Pixie_File_MCA(ctrlName,popNum,popStr) : PopupMenuControl
	String ctrlName
	Variable popNum	
	String popStr
	
	Svar MCAsource = root:pixie4:MCASource
	
	if(popnum == 1) // save as itx file
		Nvar NumberOfChannels = root:pixie4:NumberOfChannels
		Nvar CloverAdd = root:pixie4:CloverAdd
		Svar StartTime = root:pixie4:StartTime
		Svar StopTime = root:pixie4:StopTime
		Svar SeriesStartTime = root:pixie4:SeriesStartTime
		
		Wave Display_Channel_Parameters = root:pixie4:Display_Channel_Parameters
		Wave Display_Module_Parameters = root:pixie4:Display_Module_Parameters
		Nvar index_RunTime = root:pixie4:index_RunTime
		Nvar index_EvRate = root:pixie4:index_EvRate
		Nvar index_COUNTTIME = root:pixie4:index_COUNTTIME
		Nvar index_ICR = root:pixie4:index_ICR
		Nvar ncp = root:pixie4:NumChannelPar
		
		variable MCA16nSum, RunType
		Wave RunTasks = root:pixie4:RunTasks
		Nvar WhichRun = root:pixie4:WhichRun
		RunType=RunTasks[WhichRun-1]
		MCA16nSum = ( (RunType==0x402) || (CloverAdd==1) )
		
		
		Variable filenum,i
		String filename,wav
		
		Open/T="IGTX"/M="Save MCA as Igor Text File (.itx)"/P=MCAPath filenum
		filename=S_fileName	// full path and name of file opened, or "" if cancelled
		if (cmpstr(filename,"")!=0)		// if file opened succesfully
			fprintf filenum, "IGOR\r"
			fprintf filenum, "X // XIA Pixie4 MCA data saved %s, %s; Run started %s, ended %s\r",date(),time(),StartTime, StopTime
			fprintf filenum, "X // File series started %s, \r",SeriesStartTime
	
			Variable RunTime = Display_Module_Parameters[index_RunTime]
			fprintf filenum, "X // Run Time [s]= %g\r", RunTime
		
			Variable EventRate = Display_Module_Parameters[index_EvRate]
			fprintf filenum, "X // Event Rate [cps]= %g\r", EventRate
			
			for(i=0; i<NumberOfChannels; i+=1)
				fprintf filenum, "X // Channel %g\r", i
				fprintf filenum, "X // Count Time [s]= %g\r", Display_Channel_Parameters[index_COUNTTIME+i*ncp]
				fprintf filenum, "X // Input Count Rate [cps] = %g\r", Display_Channel_Parameters[ index_ICR+i*ncp]
			endfor
			close filenum
			
			for(i=0; i<NumberOfChannels; i+=1)
				wav="root:pixie4:MCACh"+num2str(i)
				Save/A/t/p=MCAPath $wav as filename
			endfor
			
			if (MCA16nSum==1)	//Addback spectrum
				wav="root:pixie4:MCAsum"
				Save/A/t/p=MCAPath $wav as filename
			endif
			
			for(i=0; i<NumberOfChannels; i+=1)
				wav="root:pixie4:MCAtotal"+num2str(i)
				Save/A/t/p=MCAPath $wav as filename
			endfor
					
		else		// if file opened not successfully
			printf "Pixie_SaveMCA: open MCA spectrum file failed, exiting ..." 
			return(0)
		endif
	endif
	
	if(popnum == 2) // read from itx file
		String fldr
		
		fldr = GetDataFolder(1)
		SetDataFolder "root:pixie4"
		LoadWave/o/t/p=MCAPath
		SetDataFolder fldr
		
	
		MCASource = S_fileName
	endif
	
	if(popnum == 3) // read from auto saved binary file
		
		
		GBLoadWave/O/B/N=dummy/T={96,96}/W=1/p=MCAPath
		//Svar S_fileName = root:S_fileName
		if(V_flag==0)
			print "Error reading file or user cancelled"
			return(0)
		endif
		
		Wave dummy0=dummy0
		Wave MCAch0 = root:pixie4:MCAch0
		Wave MCAch1 = root:pixie4:MCAch1
		Wave MCAch2 = root:pixie4:MCAch2
		Wave MCAch3 = root:pixie4:MCAch3
		Wave MCAsum = root:pixie4:MCAsum
		Nvar ChosenModule = root:pixie4:ChosenModule
		Svar MCAsource = root:pixie4:MCASource
		
		wavestats/q dummy0
		if (V_npnts < (4* 32768*ChosenModule))
			DoAlert 0, "There is no data in the file for module "+num2str(ChosenModule)
		else
			if (MCA16nSum==1)	//Addback spectrum
				MCAch0 = dummy0[p+4*32768*ChosenModule]
				MCAch1 = dummy0[p+16384+4*32768*ChosenModule]
				MCAch2 = dummy0[p+2*16384+4*32768*ChosenModule]
				MCAch3 = dummy0[p+3*16384+4*32768*ChosenModule]
				MCAsum= dummy0[p+4*16384+4*32768*ChosenModule]
			else
				MCAch0 = dummy0[p+4*32768*ChosenModule]
				MCAch1 = dummy0[p+32768+4*32768*ChosenModule]
				MCAch2 = dummy0[p+2*32768+4*32768*ChosenModule]
				MCAch3 = dummy0[p+3*32768+4*32768*ChosenModule]
				MCAsum=0
			endif
			MCASource = S_fileName
		endif
		
		Killwaves dummy0
	endif
	
	if(popnum > 3) // Export CHN
		Pixie_File_ExportCHN(popnum-4)
	endif
End	



//########################################################################
//
//	Pixie_File_GenerateVersionText:
//		Create a text file containing version information.
//
//########################################################################
Function Pixie_File_GenerateVersionText(ctrlName) : ButtonControl
	String ctrlName

	Nvar ViewerVersion = root:pixie4:ViewerVersion
	Nvar CLibraryRelease = root:pixie4:CLibraryRelease
	Nvar CLibraryBuild = root:pixie4:CLibraryBuild
	Nvar index_DSPrelease = root:pixie4:index_DSPrelease
	Nvar index_DSPbuild = root:pixie4:index_DSPbuild
	Nvar index_FippiID = root:pixie4:index_FippiID
	Nvar index_SystemID = root:pixie4:index_SystemID
	Nvar index_BoardVersion = root:pixie4:index_BoardVersion
	Nvar index_SerialNum = root:pixie4:index_SerialNum
	
	Wave Display_Module_Parameters = root:pixie4:Display_Module_Parameters
		
	Variable filnum
	Open/T="TEXT" filnum
	if(cmpstr(S_fileName, "") != 0)
		fprintf filnum, "Pixie4-Viewer=%04x\r", ViewerVersion
		fprintf filnum, "C-library release=%04x\r", CLibraryRelease
		fprintf filnum, "C-library build=%04X\r", CLibraryBuild
		fprintf filnum, "DSP code release=%04x\r", Display_Module_Parameters[index_DSPrelease]
		fprintf filnum, "DSP code build=%04X\r", Display_Module_Parameters[index_DSPbuild]
		fprintf filnum, "FiPPI version=%04X\r", Display_Module_Parameters[index_FippiID]
		fprintf filnum, "System version=%04X\r", Display_Module_Parameters[index_SystemID]
		fprintf filnum, "Board version=%04X\r", Display_Module_Parameters[index_BoardVersion]
		fprintf filnum, "Serial number=%d\r", Display_Module_Parameters[index_SerialNum]			
		
		close(filnum)
	else
		DoAlert 0,"Version information file can not be opened"
	endif
End

//########################################################################
//
//	Pixie_File_ReadAsList4xx: 
//      Read binary files 0x400, 0x402, 0x404, 0x410, 0x411 and sort result into a table
//
//########################################################################
Function Pixie_File_ReadAsList4xx()

	// use P4e function to select file and read into wfarray
	Pixie_File_ReadRawLMdata("")

	// define source waves created by Pixie_File_ReadRawLMdata function
	Wave wfarray
	Wave LMheader
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
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype = root:pixie4:runtype
	NVAR CFD_Mode_online = root:LM:CFD_Mode_online	// select from online, Igor from traces, Igor from 4 raw, etc 
	NVAR CFD_Mode_4raw   = root:LM:CFD_Mode_4raw
	NVAR CFD_Mode_Igorwf = root:LM:CFD_Mode_Igorwf



	// find number of events
	Nvar oldNevents = root:LM:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:LM:MaxEvents 
	Nvar Nevents = root:LM:Nevents 				// number of events
	wavestats/q wfarray
	Nevents = V_npnts/evsize
	Nevents = min(Nevents,MaxEvents)
	Pixie_Make_Tdiffwaves(nevents+1)	// creates/resizes, and sets to nan 	// +1 just in case there is an end run record
	oldNevents = nevents		
	

	// define destination waves
	String text = "root:LM"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")			// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave CFD0 = $(text+":CFD0")					// CFD for each event
	Wave CFD1 = $(text+":CFD1")			
	Wave CFD2 = $(text+":CFD2")			
	Wave CFD3 = $(text+":CFD3")			
	
	//Variable runtype = LMheader[2]	
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
	
	// determine CFD mode
	if(runtype==0x400)	// TODO: Pixie-Net XL's 0x400 CFD result is in P16 0x100 format!		
		CFD_Mode_online = 1
		CFD_Mode_4raw   = 0
		CFD_Mode_Igorwf = 0
	endif
	if(runtype==0x404)	// 0x404 has no CFD entry
		CFD_Mode_online = 0
		CFD_Mode_4raw   = 0
		CFD_Mode_Igorwf = 0
	endif
	if(runtype==0x410)
		CFD_Mode_online = 0
		CFD_Mode_4raw   = 1		// only choice
		CFD_Mode_Igorwf = 0
	endif
	if(runtype==0x411)
		CFD_Mode_online = 0
		CFD_Mode_4raw   = 1		// only choice
		CFD_Mode_Igorwf = 0
	endif
	
	
	
		
	for(no=0;no<Nevents;no+=1)
	//	if (mod(no,10000)==0)
	//		print "reading event #",no
	//		DoUpdate
	//	endif

		// ------------- hit pattern ------------------
		hit[no] = wfarray[iHitL][no]+65536*wfarray[iHitM][no]
		
		// ------------- time stamp ------------------
		TrigTimeL[no] =  wfarray[iTimeL][no]+65536*wfarray[iTimeM][no] 
		if(runtype==0x411)
			TrigTimeH[no] =  wfarray[iTimeH][no]
		else
			TrigTimeH[no] =  wfarray[iTimeH][no]+65536*wfarray[iTimeX][no]		
		endif
		
		// ------------- channel and energy ------------------
		
		if(runtype==0x402)
			chnum[no] = 0
	
			energy[no] 		= wfarray[6][no]
			Energy0[no] 		= wfarray[10][no]
			LocTime0[no] 	= wfarray[26][no]+65536*wfarray[27][no] 	
			Energy1[no] 		= wfarray[14][no]
			LocTime1[no] 	= wfarray[12][no]+65536*wfarray[13][no]
			Energy2[no] 		= wfarray[18][no]
			LocTime2[no] 	= wfarray[16][no]+65536*wfarray[17][no]		
			Energy3[no] 		= wfarray[22][no]
			LocTime3[no] 	= wfarray[20][no]+65536*wfarray[21][no]
		else
			chnum[no] = wfarray[iChannel][no]
			energy[no] = wfarray[iEnergy][no]	
			
			
			// ------------- CFD ------------------
			
			if(runtype==0x400)	
				// TODO: Pixie-Net XL's 0x400 CFD result is in P16 0x100 format!		
				currentCFD = -1* wfarray[iCFDresult][no]/256	//in ns
			endif
			if(runtype==0x404)
				currentCFD = 0	// 0x404 has no CFD entry
			endif
			if(runtype==0x410)
				currentCFD = Pixie_Math_CFDfrom4raw(no)
			endif
			if(runtype==0x411)
				currentCFD = Pixie_Math_CFDfrom4raw(no)
			endif
			
			// ------------- map to 0-3 for table ------------------
			
			if((0x3 & chnum[no])==0)		
				lastE0 = energy[no]
				lastT0 = TrigTimeL[no]
				lastC0 = currentCFD
			endif
	
			if((0x3 & chnum[no])==1)
				lastE1 = energy[no]
				lastT1 = TrigTimeL[no]
				lastC1 = currentCFD
			endif
			
			if((0x3 & chnum[no])==2)
				lastE2 = energy[no]
				lastT2 = TrigTimeL[no]
				lastC2 = currentCFD
			endif
	
			if((0x3 & chnum[no])==3)
				lastE3 = energy[no]
				lastT3 = TrigTimeL[no]	
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

		endif
	endfor
	
	// hide the raw value table, show the sorted instead
	DoWindow/K FileHeaderTable
	DoWindow/K EventArrayTable
	Execute "Pixie_Table_LMList()"
	killwaves/Z root:wfarray, root:LMheader
	
	print Nevents, "total"
	
	Svar CFDsource  =  root:LM:CFDsource
	Nvar RTlow = root:LM:RTlow
	//CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	CFDsource = "none"
	if(CFD_Mode_online)
		CFDsource = "DSP/ARM (1w fraction)"
	endif
	if(CFD_Mode_4raw)
		CFDsource = "FPGA (4w raw)"
	endif
	if(CFD_Mode_Igorwf)
		CFDsource = "Igor, cfd = "+num2str(RTlow)
	endif
	

End

//########################################################################
//
//	Pixie_File_ReadAsList11x: 
//      Read binary files 0x100, 0x105, 0x110, 0x111 and sort result into a table
//
//########################################################################
Function Pixie_File_ReadAsList11x()

	// use P4e function to select file and read into wfarray
	Pixie_File_ReadRawLMdata("")

	// define source waves created by Pixie_File_ReadRawLMdata function
	Wave wfarray
	Wave LMheader
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
	Nvar evsize    =  root:pixie4:evsize
	Nvar runtype   = root:pixie4:runtype
	Nvar WFscale = root:pixie4:WFscale
	
	NVAR CFD_Mode_online = root:LM:CFD_Mode_online	// select from online, Igor from traces, Igor from 4 raw, etc 
	NVAR CFD_Mode_4raw   = root:LM:CFD_Mode_4raw
	NVAR CFD_Mode_Igorwf = root:LM:CFD_Mode_Igorwf



	// find number of events
	Nvar oldNevents = root:LM:oldNevents 				// remember previous number of events
	Nvar MaxEvents = root:LM:MaxEvents 
	Nvar Nevents = root:LM:Nevents 				// number of events
	wavestats/q wfarray
	Nevents = V_npnts/evsize
	Nevents = min(Nevents,MaxEvents)
	Pixie_Make_Tdiffwaves(nevents+1)	// creates/resizes, and sets to nan 	// +1 just in case there is an end run record
	oldNevents = nevents		

	// define destination waves
	String text = "root:LM"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")			// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave CFD0 = $(text+":CFD0")					// CFD for each event
	Wave CFD1 = $(text+":CFD1")			
	Wave CFD2 = $(text+":CFD2")			
	Wave CFD3 = $(text+":CFD3")			
	
	//Variable runtype = LMheader[2]	
	Variable no, ModuleType
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
	Variable cfdsrc, cfdfrc, ph
	
	// determine CFD mode
	if(runtype==0x110)
			CFD_Mode_online = 0
			CFD_Mode_4raw   = 0		// no choice
			CFD_Mode_Igorwf = 0
	endif
	if(runtype==0x111)
			CFD_Mode_online = 0
			CFD_Mode_4raw   = 1		// only choice
			CFD_Mode_Igorwf = 0
	endif
	if(runtype==0x116)
		// no adjustment. can not determine 0x100 or 0x105, could be raw or online 
	endif
	
		
	for(no=0;no<Nevents;no+=1)
	//	if (mod(no,10000)==0)
	//		print "reading event #",no
	//		DoUpdate
	//	endif

		// ------------- hit pattern ------------------

		hit[no] = wfarray[iHitL][no]+65536*wfarray[iHitM][no]
		
		// -------------- time stamp ------------------
		TrigTimeL[no] =  wfarray[iTimeL][no]+65536*wfarray[iTimeM][no] 
		TrigTimeH[no] =  wfarray[iTimeH][no]//+65536*wfarray[iTimeX][no]		
		
		// -------------- channel ------------------
		if(runtype==0x116)
			chnum[no] = wfarray[0][no] & 0x03
		else
			chnum[no] = wfarray[3][no] & 0x03		// map into 3 traditional channels
		endif
		
		// -------------- energy ------------------
		energy[no] = wfarray[iEnergy][no]
		
		// -------------- CFD ------------------
		if(runtype==0x111)
			currentCFD = Pixie_Math_CFDfrom4raw(no)		// technically the 0x111 format has a final CFD field, but it is unlikely to be valid. use raw data and compute 

		
		elseif(runtype==0x116)	// 100, 105 (no run type indicator field in file
			
			
			//if(0)
			if(wfarray[iCFDresult][no]>0)	// CFD result computed, likely P16 0x100 with CFD enabled in DF=2
				if(CFD_Mode_online)		// user wants DSP/ARM result
					
					if(WFscale==4)	// TODO: this timescale does not seem quite right
						
						// if the "src" bit adds 1, can just use result as is (bit 14 just adds 1)
						// currentCFD = (wfarray[iCFDresult][no] & 0x7FFF) / 16384 * 4 // in ns
						// todo: zero for forced bit = 1
						
						//if the src bit add -1, have to disentangle
						cfdsrc = (wfarray[iCFDresult][no] & 0x4000) > 0 	// check bit 14
						cfdfrc = (wfarray[iCFDresult][no] & 0x8000) > 0 	// check bit 15
						ph = (wfarray[iCFDresult][no] & 0x3FFF) / 16384
						if(cfdsrc)
							ph = ph-1
						endif
						
						if(cfdfrc)
							ph=0
						endif
						
						currentCFD = ph *4 // in ns
						
						
					elseif(WFscale==8)
						currentCFD = (wfarray[iCFDresult][no] & 0x7FFF) / 32768 * 8 // in ns
						if((wfarray[iCFDresult][no] & 0x8000) > 0)
							currentCFD = 0		// force bit: result invalid
						endif
					
					elseif(WFscale==2)
						currentCFD = (wfarray[iCFDresult][no] & 0x7FFF) /  8192 * 2 // in ns	
						// todo: add the src and force bits
					
					else
						currentCFD = 0 	//invalid WFscale
					
					endif
				
				else // user wants result from FPGA raw words
					currentCFD = Pixie_Math_CFDfrom4raw(no)		//  invalid if not 0x105
				endif

			else	// CFD result NOT computed, likely P16 0x105 with CFD enabled in DF=4
				currentCFD = Pixie_Math_CFDfrom4raw(no)
			endif
			
		else	// other run types
			currentCFD = 0 	//iCFDresult	not valid, no raw data. includes 0x110

		endif
		
		// ------------------ sort into channel columns ---------------
		
		if(chnum[no]==0)
			lastE0 = energy[no]
			lastT0 = TrigTimeL[no]
			lastC0 = currentCFD
		endif
		
		if(chnum[no]==1)
			lastE1 = energy[no]
			lastT1 = TrigTimeL[no]
			lastC1 = currentCFD
		endif
		
		if(chnum[no]==2)
			lastE2 = energy[no]
			lastT2 = TrigTimeL[no]
			lastC2 = currentCFD
		endif
		
		if(chnum[no]==3)
			lastE3 = energy[no]
			lastT3 = TrigTimeL[no]	
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
	
	// hide the raw value table, show the sorted instead
	DoWindow/K FileHeaderTable
	DoWindow/K EventArrayTable
	Execute "Pixie_Table_LMList()"
	killwaves/Z root:wfarray, root:LMheader
	
	print Nevents, "total"
	
	Svar CFDsource  =  root:LM:CFDsource
	Nvar RTlow = root:LM:RTlow
	//CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	CFDsource = "none"
	if(CFD_Mode_online)
		CFDsource = "DSP/ARM (1w fraction)"
	endif
	if(CFD_Mode_4raw)
		CFDsource = "FPGA (4w raw)"
	endif
	if(CFD_Mode_Igorwf)
		CFDsource = "Igor, cfd = "+num2str(RTlow)
	endif

End


//########################################################################
//
//	Pixie_File_ReadAsListIgor: 
//      read event by event, compute CFD in Igor, and sort result into a table
//
//########################################################################
Function Pixie_File_ReadAsListIgor(newfile)
Variable newfile
//Variable ch		// this function assumes single channel event records
// don't load the whole file, just read event by event and compute CFD time
// for huge files

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
	Nvar runtype     = root:pixie4:runtype
	Nvar evsize      =  root:pixie4:evsize
	Nvar oldNevents  = root:LM:oldNevents 		// remember previous number of events
	Nvar MaxEvents   = root:LM:MaxEvents 
	Nvar Nevents     = root:LM:Nevents 			// number of events
	Nvar ChosenEvent = root:pixie4:ChosenEvent		// number of event to read
	Nvar WFscale = root:pixie4:WFscale

	oldNevents = MaxEvents	
	Nevents = MaxEvents	
	
	// options
	//	Nvar  TSscale = root:LM:TSscale

	// local variables
	Variable no, ret, ch

	// source waves and globals from ReadEvents function
	Wave ListModeChannelEnergy=root:pixie4:ListModeChannelEnergy
	Wave ListModeChannelTrigger=root:pixie4:ListModeChannelTrigger
	Wave ListModeChannelUser = root:pixie4:ListModeChannelUser
	Wave ListModeChannelXIA = root:pixie4:ListModeChannelXIA
	Nvar EventTimeHI = root:Pixie4:EventTimeHI
	Nvar EventTimeLO = root:Pixie4:EventTimeLO
	Nvar EventHitpattern = root:Pixie4:EventHitpattern
	Nvar ChosenChannel = root:pixie4:ChosenChannel	// Pixie_File_ReadEvent sets that channel number
	
	NVAR CFD_Mode_online = root:LM:CFD_Mode_online	// select from online, Igor from traces, Igor from 4 raw, etc 
	NVAR CFD_Mode_4raw   = root:LM:CFD_Mode_4raw
	NVAR CFD_Mode_Igorwf = root:LM:CFD_Mode_Igorwf


	
	// destination waves and globals
	Pixie_Make_Tdiffwaves(Nevents)
	
	String text = "root:LM"
	Wave chnum = $(text+":chnum")	
	Wave hit = $(text+":hit")	
	Wave energy = $(text+":energy")				// any or sum energy
	Wave Energy0 = $(text+":Energy0")			// energy for each event
	Wave Energy1 = $(text+":Energy1")			
	Wave Energy2 = $(text+":Energy2")			
	Wave Energy3 = $(text+":Energy3")			
	Wave LocTime0 = $(text+":LocTime0")			// loca time stamp for each event
	Wave LocTime1 = $(text+":LocTime1")		
	Wave LocTime2 = $(text+":LocTime2")		
	Wave LocTime3 = $(text+":LocTime3")		
	Wave TrigTimeL = $(text+":TrigTimeL")		// latch (event) time stamp for each event
	Wave TrigTimeH = $(text+":TrigTimeH")		// latch (event) time stamp for each event
	Wave CFD0 = $(text+":CFD0")					// CFD for each event
	Wave CFD1 = $(text+":CFD1")			
	Wave CFD2 = $(text+":CFD2")			
	Wave CFD3 = $(text+":CFD3")	
	Wave CFDtime = $(text+":CFDtime")		
	
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
		if (mod(no,1000)==0)
			print "reading event #",no
			DoUpdate
		endif
		ChosenEvent = no
		ret = Pixie_File_ReadEvent()	
		ch = ChosenChannel
			
		if(ret>=0)
		
			// copy E, T, etc	
			// ------------------ hit ---------------
			hit[no] = EventHitpattern
			
			// ------------------ time stamp ---------------
			TrigTimeL[no] = EventTimeLO 
			TrigTimeH[no] = EventTimeHI	
			
			// ------------------ channel ---------------					
			chnum[no] = ChosenChannel		// this is modulo 4 already
			
			// ------------------ energy ---------------
			energy[no] = ListModeChannelEnergy[ch]
		
			// ------------------ CFD ---------------
			// compute CFD time
			CFDtime[no] = 0		// default
			if(CFD_Mode_online)
				if(WFscale==4)	// TODO: this timescale does not seem quite right
					CFDtime[no] = (ListModeChannelXIA[ch] & 0x7FFF) / 16384 * 4 // in ns
				elseif(WFscale==8)
					CFDtime[no] = (ListModeChannelXIA[ch] & 0x7FFF) / 32768 * 8 // in ns
				elseif(WFscale==2)
					CFDtime[no] = (ListModeChannelXIA[ch] & 0x7FFF) /  8192 * 2 // in ns	
				else
					CFDtime[no] = 0 	//invalid WFscale
				endif
				//CFDtime[no] = ListModeChannelXIA[ch]	
			endif
			if(CFD_Mode_4raw)
				CFDtime[no] = Pixie_Math_CFDfrom4hdr()  		// in ns	
			endif
			if(CFD_Mode_Igorwf)
				CFDtime[no] = Pixie_Math_CFDfromTrace(ch) 
			endif
			
			//Wave Eventvalues = root:PW:Eventvalues
			// todo: add option to radio buttons for Igor original minus scaled/delayed implementation
			//CFDtime[no] = Eventvalues[37]	*4	// CFD fraction from PSA_readEvent, online algorithm
				
				
			// ------------------ sort into channel columns ---------------
				
			// channel specific
			if((0x3 & chnum[no])==0)		// map to 0-3 for table
				lastE0 = energy[no]
				lastT0 =  TrigTimeL[no]	
				lastC0 = CFDtime[no]
			endif
	
			if((0x3 & chnum[no])==1)
				lastE1 = energy[no]			
				lastT1 =  TrigTimeL[no]
				lastC1 = CFDtime[no]
			endif
			
			if((0x3 & chnum[no])==2)
				lastE2 = energy[no]
				lastT2 =  TrigTimeL[no]
				lastC2 = CFDtime[no]
			endif
	
			if((0x3 & chnum[no])==3)
				lastE3 = energy[no]
				lastT3 =  TrigTimeL[no]
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
	
	Svar CFDsource  =  root:LM:CFDsource
	Nvar RTlow = root:LM:RTlow
	//CFDsource = "FPGA (4w raw)"
	//CFDsource = "DSP/ARM (1w fraction)"
	CFDsource = "none"
	if(CFD_Mode_online)
		CFDsource = "DSP/ARM (1w fraction)"
	endif
	if(CFD_Mode_4raw)
		CFDsource = "FPGA (4w raw)"
	endif
	if(CFD_Mode_Igorwf)
		CFDsource = "Igor, cfd = "+num2str(RTlow)
	endif
	
End





//########################################################################
//
//	Pixie_IO_udp_start: 
//      start the xop funtion to receive UDP data
//
//########################################################################
Function Pixie_IO_udp_start()	// start the xop funtion to receive UDP data

	Variable RTsource = 0x100	// data format from the Pixie-Net XL, currently ignored
	Variable RTfile = 0x100	// data format to write to file, currently ignored (always save in original format)
	Variable MaxPackages = 0	// Number of events (UDP packages) to capture, 0=infinite
	
#if Exists("udp_receive_start")
	udp_receive_start(MaxPackages,RTfile,RTsource)	// xop function runs as separate thread
#endif	

End


//########################################################################
//
//	Pixie_IO_udp_stop: 
//      stop the xop funtion to receicve UDP data
//
//########################################################################
Function Pixie_IO_udp_stop()	// stop the xop funtion to receicve UDP data

#if Exists("udp_receive_start")	
	udp_receive_stop(0,0)	// two arguments, currently unused
#endif	

End


//########################################################################
//
//	Pixie_IO_udp_poll: 
//     poll the xop funtion to receicve UDP data. 
//		 Result printed in history window
//
//########################################################################
Function Pixie_IO_udp_poll()	// poll the xop funtion to receicve UDP data
variable ret=0
#if Exists("udp_receive_start")	
	ret = udp_receive_poll(0,0)	// two arguments, currently unused
#endif	

	return ret

End



//########################################################################
//
//	Pixie_IO_WebRequest: 
//		Web API calls to Pixie-Net
//
//########################################################################
Function Pixie_IO_WebRequest(ip,usr,pw,cmd, timeout)
	String ip
	String usr
	String pw
	String cmd
	Variable timeout
	Nvar messages = root:pixie4:messages
	Svar ServerResponse=  root:pixie4:ServerResponse

	String urlstring 
	urlstring = ip+"/webops/"+cmd

	URLrequest/Z/TIME=(timeout)/AUTH={usr,pw} url=urlstring	

	if(messages || cmpstr(cmd,"findsettings.cgi")==0 || cmpstr(cmd,"rampdacs.cgi")==0 )
		print S_serverResponse
	endif	
	
	ServerResponse = S_serverResponse

End


