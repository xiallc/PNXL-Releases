#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Menu "&XIA"
	"&Pixie-Net XL Panel/F2",Pixie_Panel_PNXL()
	"&Oscilloscope XL/F3",Pixie_Plot_OscilloscopeXL()
	"&MCA Spectrum XL/F9",Pixie_Plot_MCA_XL()	
	"&List Mode Traces/F10",Pixie_Plot_LMTraces()
	"&Run Statistics XL/F12",Pixie_Table_RunStats()
	"-"
	"&List Mode File Analysis", Pixie_Panel_LM()
//	"&About Pixie Viewer", Pixie_Panel_About("")
	
End

Menu "&XIA_Extra"
	"-"
	"Pixie-Net Panel",Pixie_Panel_PN()
	"&Pixie-Net XL Panel Extended",Pixie_Panel_PNXL_Extended()
	"&Oscilloscope",Pixie_Plot_Oscilloscope()
	"&MCA Spectrum",Pixie_Plot_MCA()
//	"List Mode Spectrum/F11",PN_Plot_LMSpectrumDisplay()
	"&Run Statistics",Pixie_Panel_RunStats()
	"-"

End



//########################################################################
//
//  Pixie_Panel_PNXL:                                                                           
//     Main control panel with low level I/O buttons for Pixie-Net and Pixie-Net XL       
//
//########################################################################
Window Pixie_Panel_PNXL() : Panel
	DoWindow/F PNXLpanel
	if(V_Flag != 1)
		PauseUpdate; Silent 1		// building window...
		NewPanel/K=1/W=(10,10,655,490) as "Pixie-Net XL"
		DoWindow/C PNXLpanel
		ModifyPanel cbRGB=(63736,61937,64507)
		
		////////////////////// Operation (serial) ///////////////////////////////////		
		
		Variable boxheight = 460
		Variable buttonwidth_w=150
		Variable buttonwidth_r=130
	
		Variable netx=5
		Variable netx2=180
	
		
		////////////////////// Operation (network) ///////////////////////////////////		
		

		Variable nety= 10
		GroupBox netops title="Operation", pos={netx+5,nety},size={360,boxheight},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox netopstxt1 title="via network", pos={netx+15,nety+17},size={65,90},frame=0, fsize=10,font="Arial"
		Button ShowIPtable,     pos={netx+80,nety+20},size={60,15},title="IP Setup",proc=Pixie_Ctrl_CommonButton, help={"Open table to enter IP numbers, user ID, and passwords"}
		SetVariable webvar1,    pos={netx+10,nety+45},size={160,16},title="Number of active units",variable= root:pixie4:Nmodules, help={"The number of Pixie-Net [XL] units to control"}
		SetVariable webvar2,    pos={netx2+15,nety+45},size={160,16},title="Selected unit number ",variable= root:pixie4:ModNum, fstyle=1, help={"The current Pixie-Net [XL] unit to communicate with"}
		
		nety = 90		
		Button webreadsettings, pos={netx+20,nety},size={buttonwidth_w-40,20},title="Read Settings",proc=Pixie_Ctrl_WebIO 
		Button showsettings,	 pos={netx+20+buttonwidth_w-35,nety},size={35,20},title="Table",proc=Pixie_Ctrl_CommonButton
		SetVariable rty,  pos={netx+30,nety+22},size={120,16},title="Run Type  0x",variable= root:pixie4:Run_Type, format="%X" ,help={"Enter hex number with prefix '0x'. See manual for run type definitions"} 
		SetVariable rti,  pos={netx+30,nety+44},size={120,16},title="Run Time (s)",variable= root:pixie4:Run_Time 
		SetVariable wrc,  pos={netx+30,nety+66},size={120,16},title="\K(1,4,52428)WR_RT_Ctrl  ",variable= root:pixie4:WR_RT_CTRL,help={"See manual for definitions"}    
		SetVariable dtf,  pos={netx+30,nety+88},size={120,16},title="\K(1,4,52428)Data_Flow  ",variable= root:pixie4:Data_Flow,help={"See manual for definitions"}      
		 
		nety=215
		Button webwritesettings,pos={netx+20,nety+00},size={buttonwidth_w,20},title="Write Settings *",proc=Pixie_Ctrl_WebIO, help={"Write Igor's setting to the Pixie-Net's settings file. Requires 'apply'."}
		Button webprogfippi,    pos={netx+20,nety+25},size={buttonwidth_w,20},title="Apply (progfippi) *",proc=Pixie_Ctrl_WebIO, help={"Apply the parameters in the Pixie-Net settings file to the pulse processing FPGA"}
		Button webadjust,       pos={netx+20,nety+50},size={buttonwidth_w,20},title="Adjust Offsets *",proc=Pixie_Ctrl_WebIO, help={"Automatically adjust DC offsets. This will change offsets, but not the settings file."}
		Button webrefresh,      pos={netx+20,nety+75},size={buttonwidth_w,20},title="Refresh Traces",proc=Pixie_Ctrl_WebIO, help={"Read untriggered ADC samples from the Pixie-Net."}
		
		nety+=115
		Button webpollcsr0,     pos={netx+20,nety+00},size={buttonwidth_w,20},title="\K(1,4,52428)Poll CSR (Ctrl)",proc=Pixie_Ctrl_WebIO, help={"Read CSR value of Zynq controller"}
		SetVariable zycsr,  	 pos={netx+30,nety+22},size={120,16},title="\K(1,4,52428)CSR 0x",variable= root:pixie4:Zynq_CSR, format="%04X", noedit=1, limits={0,0xFFFF,0 } 	
		Button webpollcsr5,     pos={netx+20,nety+47},size={buttonwidth_w,20},title="\K(1,4,52428)Poll WR Time (K1)",proc=Pixie_Ctrl_WebIO, help={"Read White Rabbit time from 2nd pulse processing FPGA"} 
		SetVariable tmtai,  	 pos={netx+20,nety+69},size={150,16},title="\K(1,4,52428)TM_TAI ",variable= root:pixie4:WR_TM_TAI, noedit=1, limits={0,inf,0 }, format="%015u"
		
		nety+=110
		Button haltssh,			 pos={netx+20,nety+00},size={buttonwidth_w,20},title="Shutdown Linux",proc=Pixie_Ctrl_WebIO, help={"Open Windows cmd shell with ssh connection to shut down Pixie-Net"}


		// column 2		
		nety=106
		TitleBox daq01 title="DAQ for specified time", pos={netx2+20,nety-17},size={65,90},frame=0, fsize=10,font="Arial"
		Button webstartdaq,     pos={netx2+20,nety+ 00},size={buttonwidth_w,20},title="Start DAQ *",proc=Pixie_Ctrl_WebIO, help={"Start generic data acquisition in Pixie-Net [XL]. Igor will NOT pause until run complete"} 
		Button webacquire,      pos={netx2+20,nety+ 25},size={buttonwidth_w,20},title="\K(0,40000,0)Acquire *",proc=Pixie_Ctrl_WebIO, help={"Start 'acquire' data acquisition in Pixie-Net. Igor will NOT pause until run complete"} 
		Button webcoincdaq,     pos={netx2+20,nety+ 50},size={buttonwidth_w,20},title="\K(0,40000,0)Coinc DAQ ",proc=Pixie_Ctrl_WebIO, help={"Start 'coincdaq' data acquisition in Pixie-Net. Igor will NOT pause until run complete"} 
		Button webmcadaq,       pos={netx2+20,nety+ 75},size={buttonwidth_w,20},title="\K(1,4,52428)MCA only DAQ *",proc=Pixie_Ctrl_WebIO, disable=0, help={"Start MCA only data acquisition in Pixie-Net XL. Requires Runtype 0x301, Data_Flow 5"}

		nety+=115
		TitleBox daq02 title="DAQ until stopped", pos={netx2+20,nety+6},size={65,90},frame=0, fsize=10,font="Arial"
		Button webenadaq,       pos={netx2+20,nety+ 20},size={buttonwidth_w,20},title="\K(1,4,52428)Enable LM only DAQ *",proc=Pixie_Ctrl_WebIO, disable=0, help={"Start data acquisition in Pixie-Net XL. List mode data streamed as UDP packages until DAQ stopped"}
		Button webdisdaq,       pos={netx2+20,nety+ 45},size={buttonwidth_w,20},title="\K(1,4,52428)Disable LM only DAQ *",proc=Pixie_Ctrl_WebIO, disable=2, help={"Stop UDP streaming data acquisition in Pixie-Net XL."}
		Button webenaudp,       pos={netx2+20,nety+ 80},size={buttonwidth_w,20},title="\K(1,4,52428)Enable local UDP receiver",proc=Pixie_Ctrl_WebIO, disable=0, help={"Start a UDP receiver program on local PC, which will save LM data to local file. Requires udp_xop##.xop"}
		Button webdisudp,       pos={netx2+20,nety+105},size={buttonwidth_w,20},title="\K(1,4,52428)Disable local UDP receiver",proc=Pixie_Ctrl_WebIO, disable=2, help={"Stop UDP receiver on local PC"}
		Button webpolludp,      pos={netx2+20,nety+130},size={buttonwidth_w,20},title="\K(1,4,52428)Poll local UDP receiver",proc=Pixie_Ctrl_WebIO, disable=0, help={"Poll UDP receiver on local PC"}

		
		nety+=170
		TitleBox daq03 title="1-click DAQ (timed)", pos={netx2+20,nety+6},size={65,90},frame=0, fsize=10,font="Arial"
		Button webdaq1clk,       pos={netx2+20,nety+ 20},size={buttonwidth_w,20},title="\K(1,4,52428)UDP-DAQ-poll-stop *",proc=Pixie_Ctrl_DAQ1clk, disable=0, help={"Start UDP, then data acquisition in Pixie-Net XL. UDP stopped after specified Run Time"}

		
		////////////////////// Results ///////////////////////////////////
				
		netx=390
		nety= 35
		GroupBox net title="Results", pos={netx-5,nety-25},size={250,boxheight-190},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox nettxt1 title="via network", pos={netx+5,nety-8},size={65,90},frame=0, fsize=10,font="Arial"
		//SetVariable setvar0,pos={netx,nety+20},size={140,16},title="IP address",variable= root:pixie4:MZip, help={"IP address for reading files from Pixie-Net. For 'webops', values from IP table are used instead"}
		Checkbox box0, title="Use local files", pos={netx+10,nety+20}, variable =root:pixie4:localfile, help={"Instead of reading from Pixie-Net, use file open dialog to select files"}
		
		nety=87
		netx+=10
		TitleBox restxt1 title="Read csv file into Igor", pos={netx-5,nety},size={65,90},frame=0, fsize=10,font="Arial"
		Button ADC,pos={netx,nety+15},size={buttonwidth_r,20},title="Read ADC Data",proc=Pixie_IO_ReadADCMCA, help={"Read ADC.csv and display in Oscilloscop plot"}
		Button MCA,pos={netx,nety+40},size={buttonwidth_r,20},title="Read MCA Data",proc=Pixie_IO_ReadADCMCA, help={"Read MCA.csv and display in MCA plot"}
		Button ReadRS,pos={netx,nety+65},size={buttonwidth_r,20},title="Read Statistics", proc=Pixie_IO_ReadRS, help={"Read RS.csv and display in run statistics table"}
		
		nety+=110
		TitleBox restxt2 title="Read LM file into Igor", pos={netx-5,nety},size={65,90},frame=0, fsize=10,font="Arial"
		Button ReadRrawLM,   pos={netx,nety+15},size={buttonwidth_r,20},title="Read Raw LM data" , proc=Pixie_File_ReadRawLMdata, help={"Import binary LM data and display in a table"}
		nety+=50
	//	Button ReadSortLM4xx,pos={netx,nety+00},size={buttonwidth_r,20},title="Read & Sort 0x4##", proc=Pixie_Ctrl_CommonButton, help={"Import binary LM data and sort results in a table"}
	//	Button ReadSortLM11x,pos={netx,nety+25},size={buttonwidth_r,20},title="Read & Sort 0x11#", proc=Pixie_Ctrl_CommonButton, help={"Import binary LM data and sort results in a table"}
	//	SetVariable setMaxE4,pos={netx,nety+50},size={buttonwidth_r,16},title="Max # events ",variable= root:LM:MaxEvents	,font="arial",fsize=11

		nety=425
		Button LMcleanup,pos={netx,nety+15},size={buttonwidth_r,20},title="Clean up LM waves", proc=Pixie_Ctrl_CommonButton, help={"Delete or resize arrays for imported LM data"}

		////////////////////// Options ///////////////////////////////////		
			
				
		Variable optx=390
		Variable opty= 310
		GroupBox evt title="Options", pos={optx-5,opty-25},size={250,boxheight-opty+35},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		Checkbox box1, title="Print Messages", pos={optx,opty}, variable =root:pixie4:messages, help={"Print status and debug messages to the history window"}
		Checkbox box2, title="\K(1,4,52428)Pixie-Net XL   \K(0,40000,0)(not Pixie-Net)", pos={optx,opty+20}, variable =root:pixie4:ModuleTypeXL, help={"Check this box to operate a Pixie-Net XL"}
		Checkbox box6, title="webops operation", pos={optx,opty+40}, variable =root:pixie4:webops, help={"Check this box to use the network operation (web api) instead of the serial I/O. Uses settings and results in the webops folder"}
		Checkbox box10, title="Apply to all units (*)", pos={optx,opty+60}, variable =root:pixie4:apply_all, help={"Actions from buttons labeled with * are applied to all units"}
		Checkbox box11, title="\K(1,4,52428)Delay runstart for WR timing", pos={optx,opty+80}, variable =root:pixie4:WRdelay, help={"Synchronize the run start from multiple units to a White Rabbit time 10s in the future"}
		Checkbox box12, title="Show Igor Alert for critical warnings", pos={optx,opty+100}, variable =root:pixie4:warnings, help={"Show key warnings in a popup window rather than printing in history "}

		

	endif
EndMacro

//########################################################################
//
//  Pixie_Panel_PNXL_Extended:                                                                           
//     Copy of Main control panel with low level I/O buttons (serial also) for Pixie-Net and Pixie-Net XL       
//
//########################################################################
Window Pixie_Panel_PNXL_Extended() : Panel
	DoWindow/F PNXLpanel_Extended
	if(V_Flag != 1)
		PauseUpdate; Silent 1		// building window...
		NewPanel/K=1/W=(10,10,870,530) as "Pixie-Net XL (Extended)"
		DoWindow/C PNXLpanel_Extended
		ModifyPanel cbRGB=(63736,61937,64507)
		
		////////////////////// Operation (serial) ///////////////////////////////////		
		
		Variable boxheight = 500
		Variable buttonwidth_w=150
		Variable serx=175
		Variable sery= 35
		GroupBox ser title="Operation", pos={serx-5,sery-25},size={135,305},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox sertxt1 title="via serial port", pos={serx+5,sery-8},size={65,90},frame=0, fsize=10,font="Arial"
		sery-=50
		Button bootfpga, pos={serx,sery+ 75},size={120,20}, proc=Pixie_IO_Serial,title="\K(1,4,52428)bootfpga", help={"Configure pulse processing FPGAs (Pixie-Net XL only)"}
		Button gettraces,pos={serx,sery+100},size={120,20}, proc=Pixie_IO_Serial,title="gettraces"				  , help={"Acquire untriggered ADC traces and save to file on Pixie-Net"}
		Button startdaq, pos={serx,sery+125},size={120,20}, proc=Pixie_IO_Serial,title="startdaq"					, help={"Start data acquisition"}
		Button acquire,  pos={serx,sery+150},size={120,20}, proc=Pixie_IO_Serial,title="\K(0,40000,0)acquire"  , help={"Start fast data acquisition (Pixie-Net only)"}
		Button coincdaq, pos={serx,sery+175},size={120,20}, proc=Pixie_IO_Serial,title="\K(0,40000,0)coincdaq" , help={"Start coincidence mode data acquisition (Pixie-Net only)"}
		Button mcadaq,   pos={serx,sery+200},size={120,20}, proc=Pixie_IO_Serial,title="\K(1,4,52428)mcadaq"    , help={"Start MCA-only data acquisition (Pixie-Net XL only)"}
		Button runstats, pos={serx,sery+225},size={120,20}, proc=Pixie_IO_Serial,title="runstats"					, help={"Save run statistics to file on Pixie-Net"}
		Button adcinit,  pos={serx,sery+250},size={120,20}, proc=Pixie_IO_Serial,title="\K(1,4,52428)adcinit"   , help={"Run routine to intialize ADCs (Pixie-Net XL only)"}
		Button rampdacs, pos={serx,sery+275},size={120,20}, proc=Pixie_IO_Serial,title="\K(1,4,52428)rampdacs"  , help={"Search for offsets (Pixie-Net XL only)"}
		Button print,    pos={serx,sery+300},size={120,20}, proc=Pixie_IO_Serial,title="msg only"					, help={"Empty the serial port's message buffer"}
		
		
		////////////////////// Operation (network) ///////////////////////////////////		
		
		Variable netx=320
		Variable netx2=490
		Variable nety= 10
		GroupBox netops title="Operation", pos={netx-5,nety},size={360,boxheight},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox netopstxt1 title="via network", pos={netx+5,nety+17},size={65,90},frame=0, fsize=10,font="Arial"
		Button ShowIPtable,     pos={netx+80,nety+20},size={60,15},title="IP Setup",proc=Pixie_Ctrl_CommonButton, help={"Open table to enter IP numbers, user ID, and passwords"}
		SetVariable webvar1,    pos={netx+10,nety+45},size={160,16},title="Number of active units",variable= root:pixie4:Nmodules, help={"The number of Pixie-Net [XL] units to control"}
		SetVariable webvar2,    pos={netx2+15,nety+45},size={160,16},title="Selected unit number ",variable= root:pixie4:ModNum, fstyle=1, help={"The current Pixie-Net [XL] unit to communicate with"}
		
		nety = 90		
		netx = 310
		Button webreadsettings, pos={netx+20,nety},size={buttonwidth_w-40,20},title="Read Settings",proc=Pixie_Ctrl_WebIO 
		Button showsettings,	 pos={netx+20+buttonwidth_w-35,nety},size={35,20},title="Table",proc=Pixie_Ctrl_CommonButton
		SetVariable rty,  pos={netx+30,nety+22},size={120,16},title="Run Type  0x",variable= root:pixie4:Run_Type, format="%X" ,help={"Enter hex number with prefix '0x'. See manual for run type definitions"} 
		SetVariable rti,  pos={netx+30,nety+44},size={120,16},title="Run Time (s)",variable= root:pixie4:Run_Time 
		SetVariable wrc,  pos={netx+30,nety+66},size={120,16},title="\K(1,4,52428)WR_RT_Ctrl  ",variable= root:pixie4:WR_RT_CTRL,help={"See manual for definitions"}    
		SetVariable dtf,  pos={netx+30,nety+88},size={120,16},title="\K(1,4,52428)Data_Flow  ",variable= root:pixie4:Data_Flow,help={"See manual for definitions"}      
		 
		nety=215
		Button webwritesettings,pos={netx+20,nety+00},size={buttonwidth_w,20},title="Write Settings *",proc=Pixie_Ctrl_WebIO, help={"Write Igor's setting to the Pixie-Net's settings file. Requires 'apply'."}
		Button webprogfippi,    pos={netx+20,nety+25},size={buttonwidth_w,20},title="Apply (progfippi) *",proc=Pixie_Ctrl_WebIO, help={"Apply the parameters in the Pixie-Net settings file to the pulse processing FPGA"}
		Button webadjust,       pos={netx+20,nety+50},size={buttonwidth_w,20},title="Adjust Offsets *",proc=Pixie_Ctrl_WebIO, help={"Automatically adjust DC offsets. This will change offsets, but not the settings file."}
		Button webrefresh,      pos={netx+20,nety+75},size={buttonwidth_w,20},title="Refresh Traces",proc=Pixie_Ctrl_WebIO, help={"Read untriggered ADC samples from the Pixie-Net."}
		
		nety+=115
		Button webpollcsr0,     pos={netx+20,nety+00},size={buttonwidth_w,20},title="\K(1,4,52428)Poll CSR (Ctrl)",proc=Pixie_Ctrl_WebIO, help={"Read CSR value of Zynq controller"}
		SetVariable zycsr,  	 pos={netx+30,nety+22},size={120,16},title="\K(1,4,52428)CSR 0x",variable= root:pixie4:Zynq_CSR, format="%04X", noedit=1, limits={0,0xFFFF,0 } 	
		Button webpollcsr5,     pos={netx+20,nety+47},size={buttonwidth_w,20},title="\K(1,4,52428)Poll WR Time (K1)",proc=Pixie_Ctrl_WebIO, help={"Read White Rabbit time from 2nd pulse processing FPGA"} 
		SetVariable tmtai,  	 pos={netx+20,nety+69},size={150,16},title="\K(1,4,52428)TM_TAI ",variable= root:pixie4:WR_TM_TAI, noedit=1, limits={0,inf,0 }, format="%015u"
		
		nety+=110
		Button haltssh,			 pos={netx+20,nety+00},size={buttonwidth_w,20},title="Shutdown Linux",proc=Pixie_Ctrl_WebIO, help={"Open Windows cmd shell with ssh connection to shut down Pixie-Net"}


		// column 2		
		nety=106
		TitleBox daq01 title="DAQ for specified time", pos={netx2+20,nety-14},size={65,90},frame=0, fsize=10,font="Arial"
		Button webstartdaq,     pos={netx2+20,nety+ 00},size={buttonwidth_w,20},title="Start DAQ *",proc=Pixie_Ctrl_WebIO, help={"Start generic data acquisition in Pixie-Net [XL]. Igor will NOT pause until run complete"} 
		Button webacquire,      pos={netx2+20,nety+ 25},size={buttonwidth_w,20},title="\K(0,40000,0)Acquire *",proc=Pixie_Ctrl_WebIO, help={"Start 'acquire' data acquisition in Pixie-Net. Igor will NOT pause until run complete"} 
		Button webcoincdaq,     pos={netx2+20,nety+ 50},size={buttonwidth_w,20},title="\K(0,40000,0)Coinc DAQ ",proc=Pixie_Ctrl_WebIO, help={"Start 'coincdaq' data acquisition in Pixie-Net. Igor will NOT pause until run complete"} 
		Button webmcadaq,       pos={netx2+20,nety+ 75},size={buttonwidth_w,20},title="\K(1,4,52428)MCA only DAQ *",proc=Pixie_Ctrl_WebIO, disable=0, help={"Start MCA only data acquisition in Pixie-Net XL. Requires Runtype 0x301, Data_Flow 5"}

		nety+=115
		TitleBox daq02 title="DAQ until stopped", pos={netx2+20,nety+6},size={65,90},frame=0, fsize=10,font="Arial"
		Button webenadaq,       pos={netx2+20,nety+ 20},size={buttonwidth_w,20},title="\K(1,4,52428)Enable LM only DAQ *",proc=Pixie_Ctrl_WebIO, disable=0, help={"Start data acquisition in Pixie-Net XL. List mode data streamed as UDP packages until DAQ stopped"}
		Button webdisdaq,       pos={netx2+20,nety+ 45},size={buttonwidth_w,20},title="\K(1,4,52428)Disable LM only DAQ *",proc=Pixie_Ctrl_WebIO, disable=2, help={"Stop UDP streaming data acquisition in Pixie-Net XL."}
		Button webenaudp,       pos={netx2+20,nety+ 80},size={buttonwidth_w,20},title="\K(1,4,52428)Enable local UDP receiver",proc=Pixie_Ctrl_WebIO, disable=0, help={"Start a UDP receiver program on local PC, which will save LM data to local file. Requires udp_xop##.xop"}
		Button webdisudp,       pos={netx2+20,nety+105},size={buttonwidth_w,20},title="\K(1,4,52428)Disable local UDP receiver",proc=Pixie_Ctrl_WebIO, disable=2, help={"Stop UDP receiver on local PC"}
		Button webpolludp,      pos={netx2+20,nety+130},size={buttonwidth_w,20},title="\K(1,4,52428)Poll local UDP receiver",proc=Pixie_Ctrl_WebIO, disable=0, help={"Poll UDP receiver on local PC"}

		
		nety+=170
		TitleBox daq03 title="1-click DAQ (timed)", pos={netx2+20,nety+6},size={65,90},frame=0, fsize=10,font="Arial"
		Button webdaq1clk,       pos={netx2+20,nety+ 20},size={buttonwidth_w,20},title="\K(1,4,52428)UDP-DAQ-poll-stop *",proc=Pixie_Ctrl_DAQ1clk, disable=0, help={"Start UDP, then data acquisition in Pixie-Net XL. UDP stopped after specified Run Time"}

		
		////////////////////// Results ///////////////////////////////////
				
		netx=690
		nety= 35
		GroupBox net title="Results", pos={netx-5,nety-25},size={165,boxheight},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox nettxt1 title="via network", pos={netx+5,nety-8},size={65,90},frame=0, fsize=10,font="Arial"
		SetVariable setvar0,pos={netx,nety+25},size={140,16},title="IP address",variable= root:pixie4:MZip, help={"IP address for reading files from Pixie-Net. For 'webops', values from IP table are used instead"}
		Checkbox box0, title="Use local files instead", pos={netx+10,nety+45}, variable =root:pixie4:localfile, help={"Instead of reading from Pixie-Net, use file open dialog to select files"}
		
		nety=110
		netx+=10
		TitleBox restxt1 title="Read csv file into Igor", pos={netx-5,nety},size={65,90},frame=0, fsize=10,font="Arial"
		Button ADC,pos={netx,nety+15},size={115,20},title="Read ADC Data",proc=Pixie_IO_ReadADCMCA, help={"Read ADC.csv and display in Oscilloscop plot"}
		Button MCA,pos={netx,nety+40},size={115,20},title="Read MCA Data",proc=Pixie_IO_ReadADCMCA, help={"Read MCA.csv and display in MCA plot"}
		Button ReadRS,pos={netx,nety+65},size={115,20},title="Read Statistics", proc=Pixie_IO_ReadRS, help={"Read RS.csv and display in run statistics table"}
		
		nety+=110
		TitleBox restxt2 title="Read LM file into Igor", pos={netx-5,nety},size={65,90},frame=0, fsize=10,font="Arial"
		Button ReadRrawLM,   pos={netx,nety+15},size={120,20},title="Read Raw LM data" , proc=Pixie_File_ReadRawLMdata, help={"Import binary LM data and display in a table"}
		nety+=50
		Button ReadSortLM4xx,pos={netx,nety+00},size={120,20},title="Read & Sort 0x4##", proc=Pixie_Ctrl_CommonButton, help={"Import binary LM data and sort results in a table"}
		Button ReadSortLM11x,pos={netx,nety+25},size={120,20},title="Read & Sort 0x11#", proc=Pixie_Ctrl_CommonButton, help={"Import binary LM data and sort results in a table"}
		SetVariable setMaxE4,pos={netx,nety+50},size={120,16},title="Max # events ",variable= root:LM:MaxEvents	,font="arial",fsize=11

		nety=450
		Button LMcleanup,pos={netx,nety+25},size={120,20},title="Clean up LM waves", proc=Pixie_Ctrl_CommonButton, help={"Delete or resize arrays for imported LM data"}

		////////////////////// Options ///////////////////////////////////		
			
				
		Variable optx=15
		Variable opty= 345
		GroupBox evt title="Options", pos={optx-5,opty-25},size={295,boxheight-opty+35},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		Checkbox box1, title="Print Messages", pos={optx,opty}, variable =root:pixie4:messages, help={"Print status and debug messages to the history window"}
		Checkbox box2, title="\K(1,4,52428)Pixie-Net XL   \K(0,40000,0)(not Pixie-Net)", pos={optx,opty+20}, variable =root:pixie4:ModuleTypeXL, help={"Check this box to operate a Pixie-Net XL"}
		Checkbox box6, title="webops operation", pos={optx,opty+40}, variable =root:pixie4:webops, help={"Check this box to use the network operation (web api) instead of the serial I/O. Uses settings and results in the webops folder"}
		Checkbox box10, title="Apply to all units (*)", pos={optx,opty+60}, variable =root:pixie4:apply_all, help={"Actions from buttons labeled with * are applied to all units"}
		Checkbox box11, title="\K(1,4,52428)Delay runstart for WR timing", pos={optx,opty+80}, variable =root:pixie4:WRdelay, help={"Synchronize the run start from multiple units to a White Rabbit time 10s in the future"}
		Checkbox box12, title="Show Igor Alert for critical warnings", pos={optx,opty+100}, variable =root:pixie4:warnings, help={"Show key warnings in a popup window rather than printing in history "}

		
		////////////////////// Setup ///////////////////////////////////		
			
		Variable parx=15
		Variable pary= 35
		GroupBox par title="Setup", pos={parx-5,pary-25},size={150,opty-40},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1, help={"Execute setup procedure for serial I/O"}
		TitleBox partext1 title="Use Misc > VDT2", pos={parx+5,pary-8},size={65,90},frame=0, fsize=10,font="Arial"
		TitleBox partext2 title="to set up serial port", pos={parx+5,pary+5},size={65,90},frame=0, fsize=10,font="Arial"
		Button setup,pos={parx,pary+25},size={120,20},title="set up",proc=Pixie_IO_Serial, help={"Execute setup procedure for serial I/O"}
		Button findsettings,pos={parx,pary+50},size={120,20},title="findsettings",proc=Pixie_IO_Serial, help={"Execute prcedures to find offset etc"}
		
		Button sed,pos={parx,pary+75},size={120,20},title="change .ini line",proc=Pixie_IO_Serial, help={"In the fields below, type parameter name and values to update in the settings file"}
		SetVariable par0,pos={parx+15,pary+100},size={115,16},title="for",variable= root:pixie4:parametername
		SetVariable par1,pos={parx+15,pary+120},size={115,16},title="to ",variable= root:pixie4:parametervalues
		
		Button progfippi,pos={parx,pary+145},size={120,20},title="progfippi",proc=Pixie_IO_Serial, help={"Apply settings to pulse processing FPGA"}
		Button halt,pos={parx,pary+170},size={120,20},title="halt",proc=Pixie_IO_Serial, help={"Shut down Pixie-Net's Linux OS"}

	endif
EndMacro



//########################################################################
//
// Pixie_Panel_LM:
//		Control Panel for various list mode functions
//
//########################################################################
Function Pixie_Panel_LM() : Panel
	PauseUpdate; Silent 1		// building window...
	
	DoWindow/F LMAnalysis
	if (V_flag!=1)
		//Tdiff_globals()
		NewPanel /K=1/W=(50,50,335,600) as "LM File Analysis"
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
		SetVariable setvar4,pos={ctrlx+90,filey+26},size={140,16},title="Max # events ",variable= root:LM:MaxEvents	,font="arial",fsize=11
		filey+=50
		
		SetVariable inp24,pos={ctrlx,filey},size={140,16},title="Time stamp unit (ns) ",value= root:LM:TSscale,font="arial",fsize=11
		SetVariable inp24, help={"Time stamp units are 2ns for Pixie-4e (any), 13.333ns for Pixie-4, 1ns for Pixie-Net"}
		SetVariable inp25,pos={ctrlx,filey+20},size={140,16},title="Sample interval (ns) ",value= root:pixie4:WFscale,font="arial",fsize=11
		SetVariable inp25, help={"Waveform sampling intervals are 2ns for Pixie-4e (14/500), 8ns for Pixie-4e (16/125), 4ns for Pixie-Net, 13.333ns for Pixie-4"}
		SetVariable setvar2,pos={165,filey},size={105,16},title="Run Type  0x",variable= root:pixie4:RunType,format="%X",font="arial",fsize=11
		SetVariable setvar3,pos={165,filey+20},size={105,16},title="Event Size    ",variable= root:pixie4:evsize	,font="arial",fsize=11
		filey+=45
	

		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey, linelendx, filey
		filey+=10
		
//		Button ReadDSPresults500,pos={ctrlx, filey},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .txt file (0x500) [traces]"
//		Button ReadDSPresults500,help={"Read list data from file (text, with traces), extract values computed by DSP"},fsize=11	,font="arial", disable=2
//		Button ReadDSPresults501,pos={ctrlx, filey+22},size={buttonx/2,20},proc=Tdiff_Panel_Call_Buttons,title="... .dat file (0x501) [no traces]"
//		Button ReadDSPresults501,help={"Read list data from file (text, no traces), extract values computed by DSP"},fsize=11	,font="arial", disable=2
//		Button ReadDSPresults502,pos={ctrlx+buttonx/2, filey+22},size={buttonx/2,20},proc=Tdiff_Panel_Call_Buttons,title="... .dt2 file (0x502) [PSA]"	
//		Button ReadDSPresults502,help={"Read list data from file (text, PSA and CFD), extract values computed by DSP"},fsize=11	,font="arial", disable=2
//		Button ReadDSPresults503,pos={ctrlx, filey+44},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .dt3 file (0x503) [coinc]"
//		Button ReadDSPresults503,help={"Read list data from file (coinc group), extract values computed by DSP"},fsize=11	,font="arial", disable=2

		//Button ReadSortLM4xx,pos={netx,nety+00},size={120,20},title="Read & Sort 0x4##", proc=Pixie_Ctrl_CommonButton, help={"Import binary LM data and sort results in a table"}
		//Button ReadSortLM11x,pos={netx,nety+25},size={120,20},title="Read & Sort 0x11#", proc=Pixie_Ctrl_CommonButton, help={"Import binary LM data and sort results in a table"}

		
		//Button ReadDSPresults400,pos={ctrlx, filey+66},size={buttonx,20},proc=Tdiff_Panel_Call_Buttons,title="Read Data from .b00 file (0x400, 0x402)"
		//Button ReadDSPresults400,help={"Read list data from file (any binary), extract values computed by DSP"},fsize=11	,font="arial"
		//filey+=88
		
		Button ReadSortLM11x,pos={ctrlx, filey},size={buttonx,20},proc=Pixie_Ctrl_CommonButton,title="Read Data from .bin file (0x100 P16)"
		Button ReadSortLM11x,help={"Read list data from file (Pixie-Net / P16), extract values computed by DSP"},fsize=11	,font="arial"
		Button ReadSortLM4xx,pos={ctrlx, filey+22},size={buttonx,20},proc=Pixie_Ctrl_CommonButton,title="Read Data from .bin file (0x4xx Pixie-Net XL)"
		Button ReadSortLM4xx,help={"Read list data from file (Pixie-Net / P16), extract values computed by DSP"},fsize=11	,font="arial"
		filey+=51
		
		Button ReadSortLMigor,pos={ctrlx, filey},size={buttonx,20},proc=Pixie_Ctrl_CommonButton,title="Read Events from file, compute CFD (slow)"
		Button ReadSortLMigor,help={"Process LM file and replace file CFD with value computed from LM waveforms. Must be single event records (0x116, 400, etc"}, fsize=11	,font="arial"		
		filey+=30	
	
	//	Checkbox Igor99, variable= root:LM:UsePTPforLOC, title = "LocTime = PTP/Ex time",pos={ctrlx+10,filey},font="arial",fsize=11
	//	Checkbox Igor99,help={"Replace the local trigger time with the External time stamp (PTP/WR) [0x116 only]"}	
	//	filey+=20	
	
		Checkbox cfdmode_online, variable= root:LM:CFD_Mode_online, title = " Online CFD ratio (0x100, 0x105, 0x400)",pos={ctrlx+15,filey},font="arial",fsize=11
		Checkbox cfdmode_online, help = {"Use CFD result computed by DSP/ARM. Only for Runtype 0x100, 0x105, 0x400, DF=2. Will automatically adjust to runtype of file"},proc=Pixie_Ctrl_CommonCheckBox, mode=1
		filey+=18
		
		Checkbox cfdmode_4raw, variable= root:LM:CFD_Mode_4raw, title = " Online CFD from FPGA (4 words)",pos={ctrlx+15,filey},font="arial",fsize=11
		Checkbox cfdmode_4raw, help = {"Compute CFD from 4 raw FPGA values. Only for Runtype 0x105, 0x111, 0x410, 0x411. Will automatically adjust to runtype of file"},proc=Pixie_Ctrl_CommonCheckBox, mode=1
		filey+=18
		
		Checkbox cfdmode_igorwf, variable= root:LM:CFD_Mode_Igorwf, title = " Offline CFD from waveforms",pos={ctrlx+15,filey},font="arial",fsize=11
		Checkbox cfdmode_igorwf, help = {"Compute CFD from waveforms. All run types, but must use 'read Events...' button"},proc=Pixie_Ctrl_CommonCheckBox, mode=1
		SetVariable Igor126,pos={ctrlx+180,filey-3},size={60,16},title="lvl",help={"CFD level for computation from traces"}
		SetVariable Igor126,fSize=11,format="%g",value= root:LM:RTlow, limits={0,1,0.1},font="arial"	
		filey+=22
				
		Button Table_LMList,pos={ctrlx, filey},size={buttonx/2,20},proc=Pixie_Ctrl_CommonButton,title="Open Data Table"
		Button Table_LMList,help={"Open Table with imported raw data"}, fsize=11	,font="arial"
		filey+=30	


		
		SetDrawEnv linefgc= (39168,0,31232)
		DrawLine 10, filey, linelendx, filey
		filey+=10
		
		// -------------------------------------------------------------------------------------------------------------------------------
				
//		SetDrawEnv fsize= 12,fstyle= 1
//		DrawText 10,sety,"Time Difference Histogram Settings"
		Button Compute_Tdiff,pos={ctrlx, filey},size={buttonx,20},proc=Pixie_Ctrl_CommonButton,title="Compute Time Differences"
		Button Compute_Tdiff,help={"Loop over all events in file and compute Tdiff between specified channels or Event Time or PTP time"}, fsize=11,font="arial",fstyle= 1
		filey+=20
						
		SetVariable Igor100,pos={ctrlx,filey+10},size={120,16},title="Tdiff A: Channel ",help={"Channel number for time difference A"}
		SetVariable Igor100,fSize=11,format="%g",value= root:LM:DiffA_P	, limits={0,3,1}	,font="arial"
		SetVariable Igor101,pos={ctrlx+123,filey+10},size={90,16},title=" minus ch.  ",help={"Channel number for time difference A"}
		SetVariable Igor101,fSize=11,format="%g",value= root:LM:DiffA_N, limits={0,3,1}	,font="arial"
		
	//	Checkbox Igor121, variable= root:LM:DiffA_toEv, title = "Ev Ti",pos={ctrlx+130,filey+32},font="arial",fsize=11
	//	Checkbox Igor121, help = {" Use event time instead of channel specific local time (0x402 only) "} 
	//	Checkbox Igor124, variable= root:LM:DiffA_toPTP, title = "PTP",pos={ctrlx+185,filey+32},font="arial",fsize=11, disable=2
	//	Checkbox Igor124, help = {" Use PTP time instead of channel specific local time (outdated, use PTP to loc option above) "} 
		filey+=32
	
		Checkbox Igor125, variable= root:LM:DiffA_CFD, title = " Include CFD in time difference",pos={ctrlx+15,filey},font="arial",fsize=11
		Checkbox Igor125, help = {"Refine local time difference with CFD"}
		SetVariable oup01, pos={ctrlx+35,filey+18},size={160,16},title="CFD from",value= root:lm:CFDsource,font="arial",fsize=9
		filey+=45
		
		Checkbox Igor130, variable= root:LM:DiffA_cut, title = " Apply energy cut",pos={ctrlx+15,filey},font="arial",fsize=11
		Checkbox Igor130, help = {"Compute time diff separately for events within a certain energy window"}
		SetVariable Igor131, pos={ctrlx+035,filey+18},size={80,16},title="low ",value= root:lm:ElowP, font="arial",fsize=11
		SetVariable Igor132, pos={ctrlx+035,filey+36},size={80,16},title="high",value= root:lm:EhighP,font="arial",fsize=11
		SetVariable Igor133, pos={ctrlx+165,filey+18},size={80,16},title="low ",value= root:lm:ElowN, font="arial",fsize=11
		SetVariable Igor134, pos={ctrlx+165,filey+36},size={80,16},title="high",value= root:lm:EhighN,font="arial",fsize=11
		filey+=65

		
		SetVariable Igor110,pos={ctrlx+15,filey},size={80,16},title="No. bins ",help={"Number of bins for Tdiff A histogram"}
		SetVariable Igor110,fSize=11,format="%g",value= root:LM:NbinsTA, limits={0,65536,0},font="arial"	
		SetVariable Igor111,pos={ctrlx+110,filey},size={100,16},title="bin size (ns)",help={"bin size (ns) for Tdiff A histogram"}
		SetVariable Igor111,fSize=11,format="%g",value= root:LM:BinsizeTA, limits={0,2048,0},font="arial"
		filey+=26
		
		Button Plot_Thisto,pos={ctrlx, filey},size={100,20},proc=Pixie_Ctrl_CommonButton,title="Display Histogram"
		Button Plot_Thisto,help={"Create graph with histograms of time differences"}, fsize=11,font="arial"
		Button Rebin_Tdiff,pos={ctrlx+110, filey},size={60,20},proc=Pixie_Ctrl_CommonButton,title="Rebin"
		Button Rebin_Tdiff,help={"rebin the histograms with specified bin size/number"}, fsize=11,font="arial"
		Button Fit_Tdiff,pos={ctrlx+180, filey},size={60,20},proc=Pixie_Ctrl_CommonButton,title="Fit"
		Button Fit_Tdiff,help={"Apply Gauss fit between cursors"}, fsize=11,font="arial"
		filey+=30
		
//		sety+=40	
//		SetVariable Igor102,pos={ctrlx,sety+10},size={120,16},title="Tdiff B: Channel ",help={"Channel number for time difference B"}
//		SetVariable Igor102,fSize=10,format="%g",value= root:LM:DiffB_P, limits={0,3,1}			
//		SetVariable Igor103,pos={ctrlx+123,sety+10},size={90,16},title=" minus ch.   ",help={"Channel number for time difference B"}
//		SetVariable Igor103,fSize=10,format="%g",value= root:LM:DiffB_N, limits={0,3,1}		
//		SetVariable Igor112,pos={ctrlx+38,sety+30},size={80,16},title="No. bins ",help={"Number of bins for Tdiff B histogram"}
//		SetVariable Igor112,fSize=10,format="%g",value= root:LM:NbinsTB, limits={0,2048,0}		
//		SetVariable Igor113,pos={ctrlx+123,sety+30},size={90,16},title="bin size (ns)",help={"bin size (ns) for Tdiff B histogram"}
//		SetVariable Igor113,fSize=10,format="%g",value= root:LM:BinsizeTB, limits={0,2048,0}
//		Checkbox Igor122, variable= root:LM:DiffB_toEv, title = "EvT",pos={ctrlx+220,sety+12}
//		Checkbox Igor125, variable= root:LM:DiffB_toPTP, title = "PTP",pos={ctrlx+220,sety+32}
//		
//		sety+=40	
//		SetVariable Igor104,pos={ctrlx,sety+10},size={120,16},title="Tdiff C: Channel ",help={"Channel number for time difference C"}
//		SetVariable Igor104,fSize=10,format="%g",value= root:LM:DiffC_P, limits={0,3,1}			
//		SetVariable Igor105,pos={ctrlx+123,sety+10},size={90,16},title=" minus ch.   ",help={"Channel number for time difference C"}
//		SetVariable Igor105,fSize=10,format="%g",value= root:LM:DiffC_N	, limits={0,3,1}	
//		SetVariable Igor114,pos={ctrlx+38,sety+30},size={80,16},title="No. bins ",help={"Number of bins for Tdiff C histogram"}
//		SetVariable Igor114,fSize=10,format="%g",value= root:LM:NbinsTC, limits={0,2048,0}		
//		SetVariable Igor115,pos={ctrlx+123,sety+30},size={90,16},title="bin size (ns)",help={"bin size (ns) for Tdiff C histogram"}
//		SetVariable Igor115,fSize=10,format="%g",value= root:LM:BinsizeTC, limits={0,2048,0}
//		Checkbox Igor123, variable= root:LM:DiffC_toEv, title = "EvT",pos={ctrlx+220,sety+12}
//		Checkbox Igor126, variable= root:LM:DiffC_toPTP, title = "PTP",pos={ctrlx+220,sety+32}

//		SetDrawEnv linefgc= (39168,0,31232)
//		DrawLine 10, filey, linelendx, filey
//		filey+=10	

		Button Plot_Tdiff_dTvsEv,pos={ctrlx, filey},size={100,20},proc=Pixie_Ctrl_CommonButton,title="Tdiff vs events"
		Button Plot_Tdiff_dTvsEv,help={"Create scatter plot of time differences vs event number"}, fsize=11,font="arial"
		Button Plot_Tdiff_EvsE,pos={ctrlx +110, filey},size={60,20},proc=Pixie_Ctrl_CommonButton,title="E vs E"
		Button Plot_Tdiff_EvsE,help={"Create scatter plot of energy ('minus') vs energy ('plus')"}, fsize=11,font="arial"
		Button Plot_Tdiff_dTvsE,pos={ctrlx +180, filey},size={60,20},proc=Pixie_Ctrl_CommonButton,title="Tdiff vs E"
		Button Plot_Tdiff_dTvsE,help={"Create scatter plots of time difference vs energy "}, fsize=11,font="arial"
		filey+=30
	
	endif
End

	
//########################################################################
//
//  Pixie_Panel_PN:                                                                  
//     Main control panel with low level I/O buttons, but for PN only                                       
//
//########################################################################
Window Pixie_Panel_PN() : Panel
	DoWindow/F PNpanel
	if(V_Flag != 1)
		PauseUpdate; Silent 1		// building window...
		NewPanel/K=1/W=(10,10,500,470) as "Pixie-Net"
		DoWindow/C PNpanel
		ModifyPanel cbRGB=(61440,64256,57600)
		
		Variable boxheight = 435
		Variable serx=175
		Variable sery= 35
		GroupBox ser title="Operation", pos={serx-5,sery-25},size={135,295},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox sertxt1 title="via serial port", pos={serx+5,sery-8},size={65,90},frame=0, fsize=10,font="Arial"
		sery-=50
		Button bootfpga,pos={serx,sery+75},size={120,20},title="bootfpga",proc=Pixie_IO_Serial
		Button gettraces,pos={serx,sery+100},size={120,20},title="gettraces",proc=Pixie_IO_Serial
		Button startdaq,pos={serx,sery+125},size={120,20},title="startdaq",proc=Pixie_IO_Serial
		Button acquire,pos={serx,sery+150},size={120,20},title="acquire",proc=Pixie_IO_Serial
		Button coincdaq,pos={serx,sery+175},size={120,20},title="coincdaq",proc=Pixie_IO_Serial
		Button runstats,pos={serx,sery+200},size={120,20},title="runstats",proc=Pixie_IO_Serial
		Button adcinit,pos={serx,sery+225},size={120,20},title="adcinit",proc=Pixie_IO_Serial
		Button rampdacs,pos={serx,sery+250},size={120,20},title="rampdacs",proc=Pixie_IO_Serial
		Button print,pos={serx,sery+275},size={120,20},title="msg only",proc=Pixie_IO_Serial
				
		Variable netx=320
		Variable nety= 35
		GroupBox net title="Results", pos={netx-5,nety-25},size={165,boxheight},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox nettxt1 title="via network", pos={netx+5,nety-8},size={65,90},frame=0, fsize=10,font="Arial"
		SetVariable setvar0,pos={netx,nety+25},size={140,16},title="IP address",variable= root:pixie4:MZip
		Checkbox box0, title="Use local files instead", pos={netx+10,nety+45}, variable =root:pixie4:localfile
		nety-=15
		netx+=10
		TitleBox restxt1 title="Read Data Into Igor", pos={netx-5,nety+85},size={65,90},frame=0, fsize=10,font="Arial"
		Button ADC,pos={netx,nety+100},size={115,20},title="Read ADC Data",proc=Pixie_IO_ReadADCMCA
		Button MCA,pos={netx,nety+130},size={115,20},title="Read MCA Data",proc=Pixie_IO_ReadADCMCA
		Button ReadRS,pos={netx,nety+160},size={115,20},title="Read Statistics", proc=Pixie_IO_ReadRS

		nety-=15
		TitleBox restxt2 title="Copy LM txt Files to Local Folder", pos={netx-10,nety+210},size={65,90},frame=0, fsize=10,font="Arial"
		Button dt3e,pos={netx,nety+250},size={55,20},title="0x401",proc=Pixie_IO_ReadLM
		netx+=65
		Button txt,pos={netx,nety+225},size={55,20},title="0x500",proc=Pixie_IO_ReadLM
		Button dat,pos={netx,nety+250},size={55,20},title="0x501",proc=Pixie_IO_ReadLM
		Button dt2,pos={netx,nety+275},size={55,20},title="0x502",proc=Pixie_IO_ReadLM
		Button dt3,pos={netx,nety+300},size={55,20},title="0x503",proc=Pixie_IO_ReadLM				
				
		Variable optx=15
		Variable opty= 335
		GroupBox evt title="Options", pos={optx-5,opty-25},size={150,boxheight-opty+35},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		Checkbox box1, title="Print Messages", pos={optx,opty}, variable =root:pixie4:messages
		Checkbox box2, title="Pixie-Net XL", pos={optx,opty+20}, variable =root:pixie4:ModuleTypeXL
		Checkbox box3, title="Map ch.   4 -  7 to 0-3", pos={optx+10,opty+40}, variable =root:pixie4:ChannelMapQuad1
		Checkbox box4, title="Map ch.   8 -11 to 0-3", pos={optx+10,opty+60}, variable =root:pixie4:ChannelMapQuad2
		Checkbox box5, title="Map ch. 12 -15 to 0-3", pos={optx+10,opty+80}, variable =root:pixie4:ChannelMapQuad3
		
		
		GroupBox oth title="Other", pos={serx-5,opty-25},size={135,boxheight-opty+35},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1		
		Button ReadRrawLM,pos={serx,opty},size={120,20},title="Raw LM data (0x40#)", proc=Pixie_File_ReadRawLMdata

		
		Variable parx=15
		Variable pary= 35
		GroupBox par title="Setup", pos={parx-5,pary-25},size={150,opty-40},frame=0,fsize=12,fcolor=(1,1,1),fstyle=1
		TitleBox partext1 title="Use Misc > VDT2", pos={parx+5,pary-8},size={65,90},frame=0, fsize=10,font="Arial"
		TitleBox partext2 title="to set up serial port", pos={parx+5,pary+5},size={65,90},frame=0, fsize=10,font="Arial"
		Button setup,pos={parx,pary+25},size={120,20},title="set up",proc=Pixie_IO_Serial
		Button findsettings,pos={parx,pary+50},size={120,20},title="findsettings",proc=Pixie_IO_Serial
		
		Button sed,pos={parx,pary+75},size={120,20},title="change .ini line",proc=Pixie_IO_Serial
		SetVariable par0,pos={parx+15,pary+100},size={115,16},title="for",variable= root:pixie4:parametername
		SetVariable par1,pos={parx+15,pary+120},size={115,16},title="to ",variable= root:pixie4:parametervalues
		
		Button progfippi,pos={parx,pary+145},size={120,20},title="progfippi",proc=Pixie_IO_Serial
		Button halt,pos={parx,pary+170},size={120,20},title="halt",proc=Pixie_IO_Serial


		
	endif
EndMacro

//########################################################################
//
//	Pixie_Panel_About:
//		Display version information.
//
//########################################################################
Window Pixie_Panel_About(ctrlName) : ButtonControl
String ctrlName			

// TODO: show only Igor version, add button to read run stats		

	// Check if this panel has already been opened
	DoWindow/F VersionPanel
	if(V_Flag == 1)
		return 0
	endif	

	Silent 1
	NewPanel/K=1 /W=(150,50,585,310) as "Version Information"
	DoWindow/C VersionPanel
	ModifyPanel cbRGB=(51456,44032,58880)
	SetDrawLayer UserBack
	DrawPICT 230,12,0.859649122807017,0.941176470588235,xialogo_bmp
	DrawText 232,113,"XIA LLC"
	DrawText 230,133,"2744 East 11th St"
	DrawText 230,153,"Oakland, CA 94601"
	DrawText 230,213,"Support: .... support@xia.com"
	DrawText 230,233,"Web: .......... www.xia.com"

	ValDisplay ViewerVersion,pos={15,20},size={180,18},bodyWidth=80,title="Pixie Viewer release"
	ValDisplay ViewerVersion,format="%.04X",limits={0,0,0},barmisc={0,1000}
	ValDisplay ViewerVersion,value= #"root:pixie4:ViewerVersion"
	
	
	SetVariable ViewerType,pos={15,40},size={180,18},bodyWidth=80,title="for Pixie-"
	SetVariable ViewerType,value= root:pixie4:MTsuffix, noproc, noedit=1

	ValDisplay CLibraryRelease,pos={15,60},size={180,18},bodyWidth=80,title="C-library release"
	ValDisplay CLibraryRelease,format="%.04X",limits={0,0,0},barmisc={0,1000}
	ValDisplay CLibraryRelease,value= #"root:pixie4:CLibraryRelease"

	ValDisplay CLibraryBuild,pos={15,80},size={180,18},bodyWidth=80,title="C-library build"
	ValDisplay CLibraryBuild,format="%04X",limits={0,0,0},barmisc={0,1000}
	ValDisplay CLibraryBuild,value= #"root:pixie4:CLibraryBuild"
	
	ValDisplay DSPRelease,pos={15,100},size={180,18},bodyWidth=80,title="DSP code release"
	ValDisplay DSPRelease,format="%.04X",limits={0,0,0},barmisc={0,1000}
	ValDisplay DSPRelease,value= root:pixie4:Display_Module_Parameters[ root:pixie4:index_DSPrelease]

	ValDisplay DSPBuild,pos={15,120},size={180,18},bodyWidth=80,title="DSP code build"
	ValDisplay DSPBuild,format="%04X",limits={0,0,0},barmisc={0,1000}
	ValDisplay DSPBuild,value= root:pixie4:Display_Module_Parameters[ root:pixie4:index_DSPbuild]
	
	ValDisplay FiPPIversion,pos={15,140},size={180,18},bodyWidth=80,title="FiPPI version"
	ValDisplay FiPPIversion,format="%04X",limits={0,0,0},barmisc={0,1000},value=  root:pixie4:Display_Module_Parameters[ root:pixie4:index_FippiID]
	
	ValDisplay Hardversion,pos={15,160},size={180,18},bodyWidth=80,title="System version"
	ValDisplay Hardversion,format="%04X",limits={0,0,0},barmisc={0,1000},value=  root:pixie4:Display_Module_Parameters[ root:pixie4:index_SystemID]

	ValDisplay Boardversion,pos={15,180},size={180,18},bodyWidth=80,title="Board version"
	ValDisplay Boardversion,format="%04X",limits={0,0,0},barmisc={0,1000},value=  root:pixie4:Display_Module_Parameters[ root:pixie4:index_BoardVersion]

	ValDisplay SerialNumber,pos={15,200},size={180,18},bodyWidth=80,title="Serial number"
	ValDisplay SerialNumber,format="%d",limits={0,0,0},barmisc={0,1000},value=  root:pixie4:Display_Module_Parameters[ root:pixie4:index_SerialNum]
	
	Button VersionInformationFile,pos={15,225},size={85,30},proc=Pixie_File_GenerateVersionText,title="Output to file"
	Button PVupdates,pos={110,225},size={100,30},proc=Pixie_CheckForPVupdates,title="Check for Updates"
	//Button VersionPanelClose,pos={135,225},size={60,30},proc=Pixie_AnyPanelClose,title="Close"
End



//########################################################################
//
// Pixie_Table_IP:
//		display IP numbers for Pixie-Net units
//
//########################################################################
Window Pixie_Table_IP() : Table
	PauseUpdate; Silent 1		// building window...
	DoWindow/F PXNLiptable
	if(V_Flag != 1)
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:pixie4:
		Edit/K=1/W=(14.25,143,370.5,323) MZ_ip,MZ_user,MZ_pw
		DoWindow/C PXNLiptable
		ModifyTable format(Point)=1
		SetDataFolder fldrSav0
	endif
EndMacro

//########################################################################
//
// Pixie_Table_Settings:
//		display key parameters for Pixie-Net setup
//
//########################################################################
Window Pixie_Table_Settings() : Table
	PauseUpdate; Silent 1		// building window...
	DoWindow/F PXNLpartable
	if(V_Flag != 1)
		String fldrSav0= GetDataFolder(1)
		SetDataFolder root:pixie4:
		Edit/K=1/W=(10,300,500,600) polarity,voffset,analog_gain,digital_gain,tau
		DoWindow/C PXNLpartable
		ModifyTable format(Point)=1
		SetDataFolder fldrSav0
	endif
EndMacro

//########################################################################
//
// Pixie_Table_RunStats:
//		display run statistics for Pixie-Net XL
//
//########################################################################
Window Pixie_Table_RunStats() : Table
	PauseUpdate; Silent 1		// building window...
	DoWindow/F PXNLRStable
	if(V_Flag != 1)
		Edit/K=1/W=(10,50,1150,710) ParameterCo, Controller, ParameterSy, System0, System1, ParameterCh
		Appendtotable Channel0, Channel1, Channel2, Channel3, Channel4, Channel5, Channel6, Channel7
		Appendtotable Channel8, Channel9, Channel10, Channel11, Channel12, Channel13, Channel14, Channel15
		DoWindow/C PXNLRStable
		ModifyTable size=9
		ModifyTable width=48
		ModifyTable width(ParameterCo)=55
		ModifyTable width(ParameterCh)=55
		ModifyTable width(ParameterSy)=55
		ModifyTable width(point)=30

	endif
EndMacro



//########################################################################
//
// Pixie_Plot_FFTdisplay
//		Display FFT of ADC traces
//
//########################################################################
Window Pixie_Plot_FFTdisplay() : Graph

	DoWindow/F FFTDisplay
	if (V_Flag!=1)

		PauseUpdate; Silent 1  // building window...
		Display/K=1 /W=(100,150,450,450) root:pixie4:TraceFFT as "ADC Trace FFT"
		DoWindow/C FFTDisplay
	
		if(root:pixie4:ChosenChannel == 0)
			ModifyGraph rgb(TraceFFT)=(65280,0,0)
		endif
		if(root:pixie4:ChosenChannel == 1)
			ModifyGraph rgb(TraceFFT)=(0,65280,0)
		endif
		if(root:pixie4:ChosenChannel == 2)
			ModifyGraph rgb(TraceFFT)=(0,15872,65280)
		endif
		if(root:pixie4:ChosenChannel == 3)
			ModifyGraph rgb(TraceFFT)=(0,26112,0)
		endif
	
		ModifyGraph cbRGB=(61440,64256,57600)
		ModifyGraph mode=6
		ModifyGraph grid=1
		ModifyGraph mirror=2
		Label left "Signal Amplitude, ADC units"
		Label bottom "Frequency"
		SetAxis/A/N=1 left
		ShowInfo
		ControlBar 80
		
		SetVariable SelectedPixie4Channel pos={18,7}, size={100,20},title="Channel"
		SetVariable SelectedPixie4Channel limits={0,3,1}, fsize=11, value=root:pixie4:ChosenChannel
		SetVariable SelectedPixie4Channel proc=PN_IO_SelectModChan	
	
	
		ValDisplay valdisp0,pos={18,35},title="Frequency bin width, Hz "
		ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},fsize=11
		ValDisplay valdisp0,value= #"root:pixie4:FFTbin", size={200,20}
		
		Button FilterFFT,pos={235,15},size={65,50},proc=Pixie_Ctrl_CommonButton,title="Apply Filter",fsize=11
		Button FilterFFT,help={"Apply the current energy filter to the Fourier spectrum"}
		Button HelpFFTDisplay, pos={312,15},size={62,50},proc=Pixie_CallHelp,title="Help",fsize=11
		Button FFTDisplayClose,pos={385,15},size={62,50},proc=Pixie_AnyGraphClose,title="Close",fsize=11
	endif
	
EndMacro


//########################################################################
//
//	Display MCA spectrum
//
//########################################################################
Window Pixie_Plot_MCA() : Graph

	DoWindow/F MCASpectrumDisplay
	if (V_Flag!=1)

		PauseUpdate; Silent 1 // building window...
		
		//Display/K=1 /W=(150,150,725,500) root:pixie4:MCAch0,root:pixie4:MCAch1,root:pixie4:MCAch2,root:pixie4:MCAch3 as "MCA Spectrum"
		display/K=1 /W=(150,150,725,500) root:pixie4:mcach0 as "MCA Spectrum"//, root:pixie4:mcach1, root:pixie4:mcach2, root:pixie4:mcach3 
		DoWindow/C MCASpectrumDisplay	
		AppendToGraph root:pixie4:mcach1
		AppendToGraph root:pixie4:mcach2
		AppendToGraph root:pixie4:mcach3
		//AppendToGraph root:pixie4:MCAsum
		//ModifyGraph rgb(MCAsum)=(0,0,0)
		Label left "\\Z10Counts"
		Label bottom "\\Z10Channel"
		
		ModifyGraph cbRGB=(61440,64256,57600)
		ModifyGraph mode=6,grid=1
		ModifyGraph grid=1
		ModifyGraph mirror(bottom)=2
		ModifyGraph mirror(left)=2
		ModifyGraph rgb(MCAch1)=(0,65280,0),rgb(MCAch2)=(0,15872,65280),rgb(MCAch3)=(0,26112,0)
		SetAxis/A/N=1 left
		ShowInfo
		ControlBar 150	
	
		// Initialize MCA Spectrum List Data
		Pixie_MakeList_MCA(0)
		
		// Create the MCA Spectrum List Box
		ListBox MCASpectrumBox pos={20,10},size={515,100},frame=2,listWave=root:pixie4:MCASpecListData
		ListBox MCASpectrumBox widths={40,45, 40,40,40,45,45,45,50},selwave=root:pixie4:MCASpecSListData,fsize=10,font="arial"
		ListBox MCASpectrumBox mode=8,disable=0,colorWave=root:pixie4:ListColorWave,proc=Pixie_ListProc_MCA
	
		PopupMenu MCAFitOptions, pos={710,10},bodywidth=150,mode=Pixie_GetFitOption(),title=" ",proc=Pixie_Ctrl_CommonPopup
		PopupMenu MCAFitOptions, value="Fit tallest peaks in spectra;Fit peaks with highest E;Fit peaks between min/max;Fit peaks between cursors"
		PopupMenu MCAFitOptions, help={"Fit options"}
	
		PopupMenu GaussFitMCA, pos={555,10},bodywidth=60,mode=0,title="Fit",proc=Pixie_Math_GaussFit
		PopupMenu GaussFitMCA, value="Channel 0;Channel 1;Channel 2;Channel 3;All Single Channels;Reference;Addback"
		PopupMenu GaussFitMCA, help={"Apply Gauss fit between limits defined in Fit Option"}
		
		PopupMenu SumHistoMCAch, pos={555,45},bodywidth=60,mode=0,title="Sum",proc=Pixie_Math_SumHisto
		PopupMenu SumHistoMCAch, help={"Sum histogram"}
		PopupMenu SumHistoMCAch, value="Sum-Background between limits;Sum between limits;Sum complete MCA"
		
		PopupMenu StoreMCA, pos={625,45},bodywidth=60,proc=Pixie_File_MCA,title="Files", help={"Save, read and extract from file"}
		PopupMenu StoreMCA, value="Save MCA to Igor text file;Read MCA from Igor text file;Extract MCA from binary file (.mca);Export ch.0 as CHN;Export ch.1 as CHN;Export ch.2 as CHN;Export ch.3 as CHN;",mode=0
		
		PopupMenu MCARefSelect, pos={695,45},proc=Pixie_Ctrl_CommonPopup,title="Ref",bodywidth=60
		PopupMenu MCARefSelect, value="Set ch.0 as ref;Set ch.1 as ref;Set ch.2 as ref;Set ch.3 as ref",mode=0,disable=0	

	
		Button AutoScaleMCA, pos={20,120},size={60,20},proc=Pixie_Ctrl_CommonButton,title="Auto zoom", help={"Zoom to full range"},fsize=11
		Button ZoomInMCA, pos={90,120},size={52,20},proc=Pixie_Ctrl_CommonButton,title="Zoom in", help={"Zoom in MCA"},fsize=11
		Button ZoomOutMCA, pos={150,120},size={52,20},proc=Pixie_Ctrl_CommonButton,title="Zoom out", help={"Zoom out MCA"},fsize=11
		Button ZoomMCAToCursors, pos={210,120},size={90,20},proc=Pixie_Ctrl_CommonButton,title="Zoom to cursors", help={"Zoom MCA to Cursors"},fsize=11
		Button ResetScaleMCA, pos={310,120},size={70,20},proc=Pixie_Ctrl_CommonButton,title="Reset Scale", help={"Reset MCA scale to 1/bin"},fsize=11
	
		Button MCA, pos={545,80},size={60,30},proc=Pixie_IO_ReadADCMCA,title="Read MCA", help={"Read MCA over the network"},fsize=11
		Button HelpMCA_Spectrum,pos={615,80},size={60,30},proc=Pixie_CallHelp,title="Help", help={"Show details of Gauss fit"},fsize=11

	endif
	
EndMacro


//########################################################################
//
//	Pixie_Panel_RunStats:
//		Panel to display run statistics for Pixie-Net
//
//########################################################################
Window Pixie_Panel_RunStats() : Panel
	PauseUpdate; Silent 1		// building window...
	DoWindow/F SystemRunStatsPanel
	if (V_flag!=1)

		Variable height = min(root:pixie4:NumberOfModules,5)
		NewPanel /W=(500,25,1075,height*100+160) /K=1
		DoWindow/C SystemRunStatsPanel
		DoWindow/T SystemRunStatsPanel,"Pixie-Net Run Statistics"
		ModifyPanel cbRGB=(61440,64256,57600)
	
		SetDrawLayer UserBack
		SetDrawEnv fsize= 14
		
		Pixie_MakeList_AllRunStats(0)

//		SetVariable StartTime,bodywidth=270,pos={50,10},size={275,19},disable=0
//		SetVariable StartTime,noedit=1,font="Arial",format="%.03f",fsize=10,title="Run Start"
//		SetVariable StartTime,value=root:pixie4:StartTime,limits={0,Inf,0}
//		
//		SetVariable StopTime,bodywidth=270,pos={50,35},size={275,19},disable=0
//		SetVariable StopTime,noedit=1,font="Arial",format="%.03f",fsize=10,title="Run End"
//		SetVariable StopTime,value=root:pixie4:StopTime,limits={0,Inf,0}
	
//		SetVariable RunStatsSource,bodywidth=270,pos={50,60},size={275,19},disable=0
//		SetVariable RunStatsSource,noedit=1,font="Arial",format="%.03f",fsize=10,title="Source"
//		SetVariable RunStatsSource,value=root:pixie4:InfoSource	,limits={0,Inf,0}
//		
//		PopupMenu RunStatsFileIO, pos={118,85},bodywidth=110,proc=Pixie_File_RunStats,title="Files"
//		PopupMenu RunStatsFileIO, value="Save to text file (.ifm);Read from text file (.ifm)",mode=0,disable=0	
		Button UpdateRunStats,pos={20,15},size={120,20},title="Read Statistics",proc=Pixie_IO_ReadRS,disable=0
		
		ListBox AllModStatisticsBox pos={10,45}
		ListBox AllModStatisticsBox size={550,18*height+25},frame=2,listWave=root:pixie4:AllModRunStats
		ListBox AllModStatisticsBox selwave=root:pixie4:AllModRunStats_S,fsize=12
		ListBox AllModStatisticsBox mode=0,colorWave=root:pixie4:ListColorWave,font="Arial"
		ListBox AllModStatisticsBox userColumnResize=1 //, widths={45,70}
		
		ListBox AllChStatisticsBox pos={10, 85+15*height}
		ListBox AllChStatisticsBox size={550,75*height+35},frame=2,listWave=root:pixie4:AllChRunStats
		ListBox AllChStatisticsBox widths={45,50,70,55,55,55,95,80,95},selwave=root:pixie4:AllChRunStats_S,fsize=12
		ListBox AllChStatisticsBox mode=0,colorWave=root:pixie4:ListColorWave,font="Arial"
		
//		Button ShowTrackRates, pos={50,205+77*height},size={80,40},title="History",proc=Pixie_Ctrl_CommonButton
//		Button HelpRun_Statistics, pos={160,205+77*height},size={60,40},title="Help",proc=Pixie_CallHelp
//		Button SystemRunStatsPanelClose,pos={260,205+77*height},size={60,40},title="Close",proc=Pixie_AnyPanelClose
		
	endif
	
EndMacro



//########################################################################
//
//	Oscilloscope display
//
//########################################################################
Window Pixie_Plot_Oscilloscope() : Graph

	DoWindow/F Pixie4Oscilloscope
	if (V_Flag!=1)
	
		PauseUpdate; Silent 1	// building window...
		Display/K=1 /W=(50,200,450,450) root:pixie4:ADCch0,root:pixie4:ADCch1,root:pixie4:ADCch2,root:pixie4:ADCch3 as "Oscilloscope"
		DoWindow/C Pixie4Oscilloscope
	
		ModifyGraph cbRGB=(61440,64256,57600)
		ModifyGraph mode=6
		ModifyGraph grid=2
		ModifyGraph mirror(bottom)=2
		ModifyGraph mirror(left)=2
		ModifyGraph rgb(ADCch1)=(0,65280,0),rgb(ADCch2)=(0,15872,65280),rgb(ADCch3)=(0,26112,0)
		Label left "ADC Units"
		Label bottom "Time"
		SetAxis/A/N=1 left
		ControlBar 100
		ShowInfo
		
		Variable xpos = 10
		TitleBox group0 title="Channel",size={65,90}, pos={xpos+5,5}, frame=0
		Checkbox ADCch0, title="\K(65280,0,0)\f01||||||  0", 	    pos={xpos+5,21}, proc=Pixie_Ctrl_CheckTrace,value=1
		Checkbox ADCch1, title="\K(0,65280,0)\f01||||||  1", 	    pos={xpos+5,41}, proc=Pixie_Ctrl_CheckTrace,value=1
		Checkbox ADCch2, title="\K((0,15872,65280)\f01||||||  2",  pos={xpos+5,61}, proc=Pixie_Ctrl_CheckTrace,value=1
		Checkbox ADCch3, title="\K(0,26112,0)\f01||||||  3",       pos={xpos+5,81}, proc=Pixie_Ctrl_CheckTrace,value=1

		xpos = 90
		TitleBox serialio title="Online Serial I/O", pos={xpos,5},size={65,90},frame=0
		Button ADCRefresh,pos={xpos,25},size={80,20},proc=Pixie_Ctrl_CommonButton,title="Refresh",help={"Refresh graph with new data"},fsize=11
		Button AdjustDC,pos={xpos,50},size={80,20},proc=Pixie_Ctrl_CommonButton,title="Adjust Offsets",disable=0,fsize=11,help={"Automatically adjust offsets in all modules"}
		Button ADCDisplayCapture,pos={xpos,75},size={80,20},proc=Pixie_Ctrl_CommonButton,title="Capture",fsize=11
		Button ADCDisplayCapture,help={"Refresh graph with new data and repeat until a pulse is found"}, disable=0

		xpos = 190
		TitleBox actions title="Offline Tools", pos={xpos,5},size={65,90},frame=0
		Button FFTDisplay,pos={xpos,25},size={80,20},proc=Pixie_Ctrl_CommonButton,title="FFT",fsize=11,help={"Open plot with FFT analysis of trace"}, disable=0
		Button ADCDisplaySave,pos={xpos,50},size={80,20},proc=Pixie_Ctrl_CommonButton,title="Save",fsize=11
		Button ADCDisplaySave,help={"Save Oscilloscope waveforms to a file (Igor text format with time scale)"}, disable=
		
		xpos = 290
		TitleBox tau title="Tau", pos={xpos,5},size={120,90},frame=0
		Popupmenu TauFit, pos={xpos+105,25},bodywidth=155,mode=0,title="Fit Trace",proc=Pixie_Ctrl_CommonPopup
		PopupMenu TauFit, value="Channel 0;Channel 1;Channel 2;Channel 3",fsize=11
		PopupMenu TauFit, help={"Fit an oscilloscope trace between cursors to determine the decay time tau"}
				
		SetVariable LastTau, pos={xpos,50}, value =  root:pixie4:LastTau, fsize=11, help={"Result of Tau fit"}
		SetVariable LastTau ,title="Tau (µs)",size={105,20}, format="%.4f", noedit=1, limits={-inf,inf,0}
		SetVariable TauDeviation, pos={xpos+100,50}, value =  root:pixie4:TauDeviation, fsize=11, help={"Standard deviation of Tau fit"}
		SetVariable TauDeviation ,title="±",size={55,20}, format="%.4f", noedit=1, limits={-inf,inf,0}
		
		Button TauClear,pos={xpos,75},size={155,20},proc=Pixie_Ctrl_CommonButton,title="Remove Tau Fit From Graph",fsize=11

	
	endif
		
	
EndMacro



//########################################################################
//
//	Pixie_Plot_LMTraces
//		Display LM traces and other event information
//
//########################################################################
Window Pixie_Plot_LMTraces() : Graph

	DoWindow/F ListModeTracesDisplay
	if (V_Flag!=1)

		PauseUpdate; Silent 1		// building window...
		Display/K=1 /W=(50,175,620,500) root:pixie4:trace0,root:pixie4:trace1,root:pixie4:trace2,root:pixie4:trace3 as "List Mode Traces"
		DoWindow/C ListModeTracesDisplay
	
		ModifyPanel cbRGB=(63736,61937,64507)
		ModifyGraph mode=6
		ModifyGraph grid=1
		ModifyGraph mirror(bottom)=2
		ModifyGraph mirror(left)=2
		ModifyGraph rgb(trace1)=(0,65280,0),rgb(trace2)=(0,15872,65280),rgb(trace3)=(0,26112,0)
		SetAxis/A/N=1 left
		Label bottom "Time from first sample"
		Label left "Pulse Height (ADC steps)"
		ControlBar 135
		
		Variable dfy = 33
		Variable evtinfox =620
		Variable cby = 95
		Variable bux=531	
		
		SetVariable CallReadEvents, pos={290,12},size={150,18},proc=Pixie_Ctrl_CommonSetVariable
		SetVariable CallReadEvents, limits={0,Inf,1},value= root:pixie4:ChosenEvent,format="%d"
		SetVariable CallReadEvents, title="Event Number ",fstyle=1,fsize=11
		
		SetVariable DisplayCh, pos={450,12},size={45,18}
		SetVariable DisplayCh, limits={0,Inf,0},value= root:pixie4:LMeventChannel,format="%d"
		SetVariable DisplayCh, title="Ch. ",fsize=11, noedit=1

		GroupBox Files 				 pos={290,dfy},   size={207,92},fsize=11,title="Data File",fcolor=(1,1,1)
		SetVariable TraceDataFile, pos={298,dfy+18},size={190,18},fsize=11,title=" ",value=root:pixie4:lmfilename

		Button FindTraceDataFile, pos={298,dfy+37},size={ 40,18},fsize=11,title="Select",proc=Pixie_Ctrl_CommonButton
		SetVariable setvar2,      pos={370,dfy+36},size={115,16},fsize=11,title="Run Type  0x",                   variable=root:pixie4:RunType,format="%X"
		SetVariable setvar3,      pos={300,dfy+53},size={185,16},fsize=11,title="Event Size                    ", variable=root:pixie4:evsize
		SetVariable setvar4,      pos={300,dfy+70},size={185,16},fsize=11,title="Sample dt (most runtypes) ",     variable=root:pixie4:WFscale
		
		ValDisplay Hitpattern,    pos={evtinfox,5},size={150,20},fsize=10,title = "Hit Pattern 0x",value=root:Pixie4:EventHitpattern,format ="%8.8X" 
				
		// Initialize Channel Energy List Data
		Pixie_MakeList_Traces(0)
		
		// Create the Channel Energy List Box
		ListBox ChannelEnergyBox pos={20,10},size={250,115},frame=2,listWave=root:pixie4:ListModeEnergyListData
		ListBox ChannelEnergyBox widths={50,75,75,75,75},selwave=root:pixie4:ListModeEnergySListData,fsize=10,font="arial"
		ListBox ChannelEnergyBox mode=8,disable=0,colorWave=root:pixie4:ListColorWave,proc=Pixie_ListProc_Traces
	
		// control buttons
		Button EventFilterDisplay, pos={bux,20},size={55,22},proc=Pixie_Plot_FilterDisplay,title="Filter",fsize=11,disable=2
		PopupMenu LMRefSelect, pos={bux,50},proc=Pixie_Ctrl_CommonPopup,title="Ref",size={55,22}, bodywidth= 55
		PopupMenu LMRefSelect, value="Set ch.0 as ref;Set ch.1 as ref;Set ch.2 as ref;Set ch.3 as ref",mode=0,disable=0
		Button EventList, pos={bux,80},size={55,22},proc=Pixie_Ctrl_CommonButton,title="Table",fsize=11,disable=0	
		//Button HelpList_Mode_Traces, pos={bux,80},size={55,22},proc=Pixie_CallHelp,title="Help",fsize=11
		
		// event info spelled out
		Checkbox Evinfo5,  title = "Overall accept", 				pos ={evtinfox,  18}, fsize=9, variable = root:Pixie4:EvHit_Accept,     disable=2
		Checkbox Evinfo16, title = "Local coincidence test ok",pos ={evtinfox,  32}, fsize=9, variable = root:Pixie4:EvHit_CoincOK,    disable=2
		Checkbox Evinfo20, title = "Local channel hit", 			pos ={evtinfox,  46}, fsize=9, variable = root:Pixie4:EvHit_ChannelHit, disable=2
		Checkbox Evinfo18, title = "Pulse piled up", 				pos ={evtinfox,  60}, fsize=9, variable = root:Pixie4:EvHit_PiledUp,    disable=2
		Checkbox Evinfo21, title = "Pulse out of range", 		pos ={evtinfox,  74}, fsize=9, variable = root:Pixie4:EvHit_OOR,        disable=2
		Checkbox Evinfo19, title = "Waveform FIFO full", 		pos ={evtinfox,  88}, fsize=9, variable = root:Pixie4:EvHit_WvFifoFull, disable=2
		Checkbox Evinfo17, title = "Veto logic high", 			pos ={evtinfox, 102}, fsize=9, variable = root:Pixie4:EvHit_Veto,       disable=2
		Checkbox Evinfo22, title = "Data Transmission error", 	pos ={evtinfox, 116}, fsize=9, variable = root:Pixie4:EvHit_Derror,     disable=2
		
		//Checkbox Evinfo4, title = "Front panel input high", pos ={600, 5}, fsize=11, variable = root:Pixie4:EvHit_Front, disable=2
		//Checkbox Evinfo6, title = "Backplane Status input high", pos ={600, 60}, fsize=11, variable = root:Pixie4:EvHit_Status, disable=2
		//Checkbox Evinfo7, title = "Backplane Token input high", pos ={600, 80}, fsize=11, variable = root:Pixie4:EvHit_Token, disable=2

	endif
	
EndMacro



//########################################################################
//
//		Tdiff plots
//
//########################################################################

Window Pixie_Plot_Thisto() : Graph
	DoWindow/F Tdiffhisto
	if (V_Flag!=1)
		Display/W=(200,50,600,350)/K=1 root:LM:ThistoA//,root:LM:ThistoB,root:LM:ThistoC
		DoWindow/C Tdiffhisto
		ModifyGraph mirror=2
		ModifyGraph mode=6
		ModifyGraph rgb(ThistoA)=(0,0,0)
		Label left "N counts"
		Label bottom "Time Difference (ns)"
		Legend/C/N=text0/J/F=0/A=MC "\\s(ThistoA) T diff A"
		ShowInfo
	endif
EndMacro

Window Pixie_Plot_Tdiff_dTvsEv() : Graph
	DoWindow/F Tdiff_dTvsEv
	if (V_Flag!=1)
		Display/K=1/W=(35.25,41.75,429.75,250.25) root:LM:TdiffA
		DoWindow/C Tdiff_dTvsEv
		ModifyGraph mode=2
		ModifyGraph lSize=1.5
		Label left "T diff (ns)"
		Label bottom "Event #"
		ShowInfo
	endif
EndMacro

Window Pixie_Plot_Tdiff_EvsE() : Graph
	DoWindow/F Tdiff_EvsEv
	if (V_Flag!=1)
		Display/K=1/W=(35.25,41.75,429.75,250.25) $("root:LM:Energy"+num2str(root:LM:DiffA_N)) vs $("root:LM:Energy"+num2str(root:LM:DiffA_P))
		DoWindow/C Tdiff_EvsEv
		ModifyGraph mode=2
		ModifyGraph lSize=1.5
		Label left "Energy"+num2str(root:LM:DiffA_N)
		Label bottom "Energy"+num2str(root:LM:DiffA_P)
		ShowInfo
	endif
EndMacro

Window Pixie_Plot_Tdiff_dTvsE() : Graph
	DoWindow/F Tdiff_dTsEv
	if (V_Flag!=1)
		Display/K=1/W=(40,40,600,400) root:LM:TdiffA vs $("root:LM:Energy"+num2str(root:LM:DiffA_P))
		AppendtoGraph/B=B1/L=L1	root:LM:TdiffA vs $("root:LM:Energy"+num2str(root:LM:DiffA_N))
		DoWindow/C Tdiff_dTsEv
		ModifyGraph mode=2
		ModifyGraph lSize=1
		ModifyGraph axisEnab(bottom)={0,0.45},axisEnab(B1)={0.55,1},freePos(B1)={0,kwFraction}
		ModifyGraph freePos(L1)={0,B1}
		Label left "T diff (ns)"
		Label bottom "Energy"+num2str(root:LM:DiffA_P)
		Label B1 "Energy"+num2str(root:LM:DiffA_N)
		ShowInfo
	endif
EndMacro



//########################################################################
//
//	Pixie_Plot_OscilloscopeXL:
//		Oscilloscope display for PNXL
//
//########################################################################
Window Pixie_Plot_OscilloscopeXL() : Graph

	DoWindow/F OscilloscopeXL
	if (V_Flag!=1)
	
		PauseUpdate; Silent 1	// building window...
		Display/K=1 /W=(50,200,550,450) root:pixie4:ADCch0, root:pixie4:ADCch1, root:pixie4:ADCch2, root:pixie4:ADCch3 as "Oscilloscope (XL)"
		AppendtoGraph root:pixie4:ADCch4, root:pixie4:ADCch5, root:pixie4:ADCch6, root:pixie4:ADCch7
		DoWindow/C OscilloscopeXL
	
		ModifyPanel cbRGB=(63736,61937,64507)
		ModifyGraph mode=6
		ModifyGraph grid=2
		ModifyGraph mirror(bottom)=2
		ModifyGraph mirror(left)=2
		ModifyGraph rgb(ADCch1)=(0,65280,0),rgb(ADCch2)=(0,15872,65280),rgb(ADCch3)=(0,26112,0)
		ModifyGraph rgb(adcch4)=(0,0,0),rgb(adcch5)=(65280,49152,16384);DelayUpdate
		ModifyGraph rgb(adcch6)=(36864,14592,58880),rgb(adcch7)=(0,52224,52224)
		Label left "ADC Units"
		Label bottom "Sample Number"
		SetAxis/A/N=1 left
		ControlBar 110
		ShowInfo
		
		Variable xpos = 5
		Variable ypos = 5
		TitleBox group0 title="Channel",size={65,90}, pos={xpos+5,2}, frame=0
		Button Next8adc, size = {40,16}, title="All +8",   pos = {xpos+5,   15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
		Button Prev8adc, size = {40,16}, title="All -8",   pos = {xpos+55,  15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
		Button Show8adc, size = {50,16}, title="Show All", pos = {xpos+105, 15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
		Button Hide8adc, size = {50,16}, title="Hide All", pos = {xpos+165, 15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
			
		SetVariable ADCch0sv, size={70,16}, title="\K(65280,0,0)\f01|||||| ",      pos={xpos+5,ypos+30}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh0
		SetVariable ADCch1sv, size={70,16}, title="\K(0,65280,0)\f01|||||| ",      pos={xpos+5,ypos+48}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh1
		SetVariable ADCch2sv, size={70,16}, title="\K((0,15872,65280)\f01|||||| ", pos={xpos+5,ypos+66}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh2
		SetVariable ADCch3sv, size={70,16}, title="\K(0,26112,0)\f01|||||| ",      pos={xpos+5,ypos+84}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh3	
		Checkbox ADCch0, pos={xpos+82,ypos+30}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox ADCch1, pos={xpos+82,ypos+48}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox ADCch2, pos={xpos+82,ypos+66}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox ADCch3, pos={xpos+82,ypos+84}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
	
		xpos+=110
		SetVariable ADCch4sv, size={70,16}, title="\K(0,0,0)\f01|||||| ",             pos={xpos+5,ypos+30}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh4
		SetVariable ADCch5sv, size={70,16}, title="\K(65280,49152,16384)\f01|||||| ", pos={xpos+5,ypos+48}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh5
		SetVariable ADCch6sv, size={70,16}, title="\K(36864,14592,58880)\f01|||||| ", pos={xpos+5,ypos+66}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh6
		SetVariable ADCch7sv, size={70,16}, title="\K(0,52224,52224)\f01|||||| ",     pos={xpos+5,ypos+84}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh7
		Checkbox ADCch4, pos={xpos+82,ypos+30}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox ADCch5, pos={xpos+82,ypos+48}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox ADCch6, pos={xpos+82,ypos+66}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox ADCch7, pos={xpos+82,ypos+84}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "

		xpos += 110
		TitleBox serialio title="Online I/O", pos={xpos,2},size={65,90},frame=0
		Button ADCRefresh,pos={xpos,ypos+20},size={120,20},fsize=11,proc=Pixie_Ctrl_CommonButton,title="Refresh (serial)",help={"Refresh graph with new data (via serial command and nework file read)"}
 		Button webrefresh,pos={xpos,ypos+40},size={120,20},fsize=11,proc=Pixie_Ctrl_WebIO,  title="Refresh (network)",help={"Refresh graph with new data (via netwok I/O)"}		
 		Button AdjustDC,  pos={xpos,ypos+60},size={120,20},fsize=11,proc=Pixie_Ctrl_CommonButton,title="Adjust Offsets (ser)",help={"Automatically adjust offsets in all modules (via serial command)"}
 		Button webadjust, pos={xpos,ypos+80},size={120,20},fsize=11,proc=Pixie_Ctrl_WebIO,  title="Adjust Offsets (net)",help={"Automatically adjust offsets in all modules (via network I/O)"}

		xpos+= 130
		TitleBox tau title="Tau", pos={xpos,2},size={120,90},frame=0
		Popupmenu TauFit, pos={xpos+105,ypos+20},bodywidth=155,mode=0,title="Fit Trace",proc=Pixie_Ctrl_CommonPopup
		PopupMenu TauFit, value="Channel 0;Channel 1;Channel 2;Channel 3;Channel 4;Channel 5;Channel 6;Channel 7",fsize=11
		PopupMenu TauFit, help={"Fit an oscilloscope trace between cursors to determine the decay time tau"}
		
		SetVariable LastTau, pos={xpos,ypos+45}, value =  root:pixie4:LastTau, fsize=11, help={"Result of Tau fit"}
		SetVariable LastTau ,title="Tau (µs)",size={100,20}, format="%.4f", noedit=1, limits={-inf,inf,0}
		SetVariable TauDeviation, pos={xpos+100,ypos+45}, value =  root:pixie4:TauDeviation, fsize=11, help={"Standard deviation of Tau fit"}
		SetVariable TauDeviation ,title="±",size={55,20}, format="%.4f", noedit=1, limits={-inf,inf,0}
		
		Button TauClear,pos={xpos,70},size={155,ypos+20},proc=Pixie_Ctrl_CommonButton,title="Remove Tau Fit From Graph",fsize=11
		
		xpos+= 170
		Button noise,pos={xpos,ypos+20},size={100,20},proc=Pixie_Ctrl_CommonButton,title="Print Noise",disable=0,fsize=11,help={"Compute Std.dev for all channels in plot"}
		Button ADCDisplaySave,pos={xpos,ypos+40},size={100,20},proc=Pixie_Ctrl_CommonButton,title="Save",fsize=11
		Button ADCDisplaySave,help={"Save Oscilloscope waveforms to a file (Igor text format with time scale)"}
		
		//	Button ADCDisplayCapture,pos={xpos,75},size={80,20},proc=Pixie_Ctrl_CommonButton,title="Capture",fsize=11
		//	Button ADCDisplayCapture,help={"Refresh graph with new data and repeat until a pulse is found"}, disable=0

		//	xpos = 190
		//	TitleBox actions title="Offline Tools", pos={xpos,5},size={65,90},frame=0
		//	Button FFTDisplay,pos={xpos,25},size={80,20},proc=Pixie_Ctrl_CommonButton,title="FFT",fsize=11,help={"Open plot with FFT analysis of trace"}, disable=2

	
	endif		
	
EndMacro



//########################################################################
//
//	Display MCA spectrum
//
//########################################################################
Window Pixie_Plot_MCA_XL() : Graph

	DoWindow/F MCASpectrumDisplayXL
	if (V_Flag!=1)

		PauseUpdate; Silent 1 // building window...
		
		display/K=1 /W=(150,150,625,450)  root:pixie4:MCAch0 as "MCA Spectrum (XL)"
		DoWindow/C MCASpectrumDisplayXL
		AppendToGraph  root:pixie4:MCAch1
		AppendToGraph  root:pixie4:MCAch2
		AppendToGraph  root:pixie4:MCAch3
		AppendToGraph  root:pixie4:MCAch4
		AppendToGraph  root:pixie4:MCAch5
		AppendToGraph  root:pixie4:MCAch6
		AppendToGraph  root:pixie4:MCAch7
		Label left "\\Z10Counts"
		Label bottom "\\Z10Channel"
		
		ModifyPanel cbRGB=(63736,61937,64507)
		ModifyGraph mode=6,grid=1
		ModifyGraph grid=1
		ModifyGraph mirror(bottom)=2
		ModifyGraph mirror(left)=2
		ModifyGraph rgb(MCAch1)=(0,65280,0),rgb(MCAch2)=(0,15872,65280),rgb(MCAch3)=(0,26112,0)
		ModifyGraph rgb(MCAch4)=(0,0,0),rgb(MCAch5)=(65280,49152,16384);DelayUpdate
		ModifyGraph rgb(MCAch6)=(36864,14592,58880),rgb(MCAch7)=(0,52224,52224)
		SetAxis/A/N=1 left
		ShowInfo
		ControlBar 110	
		
		Variable xpos = 5
		Variable ypos = 5
		TitleBox group0 title="Channel",size={65,90}, pos={xpos+5,2}, frame=0
		Button Next8mca, size = {40,16}, title="All +8",   pos = {xpos+5,   15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
		Button Prev8mca, size = {40,16}, title="All -8",   pos = {xpos+55,  15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
		Button Show8mca, size = {50,16}, title="Show All", pos = {xpos+105, 15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
		Button Hide8mca, size = {50,16}, title="Hide All", pos = {xpos+165, 15}, proc = Pixie_Ctrl_CommonButton, fsize = 9
				
		SetVariable MCAch0sv, size={70,16}, title="\K(65280,0,0)\f01|||||| ",      pos={xpos+5,ypos+30}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh0
		SetVariable MCAch1sv, size={70,16}, title="\K(0,65280,0)\f01|||||| ",      pos={xpos+5,ypos+48}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh1
		SetVariable MCAch2sv, size={70,16}, title="\K((0,15872,65280)\f01|||||| ", pos={xpos+5,ypos+66}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh2
		SetVariable MCAch3sv, size={70,16}, title="\K(0,26112,0)\f01|||||| ",      pos={xpos+5,ypos+84}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh3	
		Checkbox MCAch0, pos={xpos+82,ypos+30}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox MCAch1, pos={xpos+82,ypos+48}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox MCAch2, pos={xpos+82,ypos+66}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox MCAch3, pos={xpos+82,ypos+84}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
	
		xpos+=110
		SetVariable MCAch4sv, size={70,16}, title="\K(0,0,0)\f01|||||| ",             pos={xpos+5,ypos+30}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh4
		SetVariable MCAch5sv, size={70,16}, title="\K(65280,49152,16384)\f01|||||| ", pos={xpos+5,ypos+48}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh5
		SetVariable MCAch6sv, size={70,16}, title="\K(36864,14592,58880)\f01|||||| ", pos={xpos+5,ypos+66}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh6
		SetVariable MCAch7sv, size={70,16}, title="\K(0,52224,52224)\f01|||||| ",     pos={xpos+5,ypos+84}, proc=Pixie_Ctrl_SetDisplayChannel,value=PlotCh7
		Checkbox MCAch4, pos={xpos+82,ypos+30}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox MCAch5, pos={xpos+82,ypos+48}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox MCAch6, pos={xpos+82,ypos+66}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
		Checkbox MCAch7, pos={xpos+82,ypos+84}, proc=Pixie_Ctrl_CheckTraceXL,value=1, title=" "
	
		// Initialize MCA Spectrum List Data
	//	Pixie_MakeList_MCA(0)
		
		// Create the MCA Spectrum List Box
	//	ListBox MCASpectrumBox pos={20,10},size={515,100},frame=2,listWave=root:pixie:MCASpecListData
	//	ListBox MCASpectrumBox widths={40,45, 40,40,40,45,45,45,50},selwave=root:pixie:MCASpecSListData,fsize=10,font="arial"
	//	ListBox MCASpectrumBox mode=8,disable=0,colorWave=root:pixie:ListColorWave,proc=Pixie_ListProc_MCA
	
		PopupMenu MCAFitOptionsXL, pos={425,10},bodywidth=160,mode=Pixie_GetFitOption(),title=" ",proc=Pixie_Ctrl_CommonPopup
		PopupMenu MCAFitOptionsXL, value="Fit tallest peaks in spectra;<unused>;<unused>;Fit peaks between cursors"
		PopupMenu MCAFitOptionsXL, help={"Fit options"}
	
		PopupMenu GaussFitMCA, pos={255,10},bodywidth=60,mode=0,title="Fit",proc=Pixie_Math_GaussFit_XL
		PopupMenu GaussFitMCA, value="Channel 0;Channel 1;Channel 2;Channel 3;Channel 4;Channel 5;Channel 6;Channel 7;All Single Channels;Reference"
		PopupMenu GaussFitMCA, help={"Apply Gauss fit between limits defined in Fit Option"}
		
		PopupMenu SumHistoMCAch, pos={255,45},bodywidth=60,mode=0,title="Sum",proc=Pixie_Math_SumHisto, disable=2
		PopupMenu SumHistoMCAch, help={"Sum histogram"}
		PopupMenu SumHistoMCAch, value="Sum-Background between limits;Sum between limits;Sum complete MCA"
		
		Button Remove8fit, pos={315,45},size={70,20},proc=Pixie_Ctrl_CommonButton,title="Remove Fits", fsize=10
		
		//PopupMenu StoreMCA, pos={625,45},bodywidth=60,proc=Pixie_File_MCA,title="Files", help={"Save, read and extract from file"}
		//PopupMenu StoreMCA, value="Save MCA to Igor text file;Read MCA from Igor text file;Extract MCA from binary file (.mca);Export ch.0 as CHN;Export ch.1 as CHN;Export ch.2 as CHN;Export ch.3 as CHN;",mode=0
		
		PopupMenu MCARefSelect, pos={425,45},proc=Pixie_Ctrl_CommonPopup,title="Ref",bodywidth=80, disable=2
		PopupMenu MCARefSelect, value="Set ch.0 as ref;Set ch.1 as ref;Set ch.2 as ref;Set ch.3 as ref;Set ch.4 as ref;Set ch.5 as ref;Set ch.6 as ref;Set ch.7 as ref",mode=0,disable=0	
		Checkbox MCAchRefShow, pos={397,ypos+75}, proc=Pixie_Ctrl_CheckTraceXL,value=0, title="Show Ref "
		
		Button MCA, pos={245,80},size={80,20},proc=Pixie_IO_ReadADCMCA,title="Read MCA", help={"Read MCA over the network"},fsize=11

	endif
	
EndMacro

//########################################################################
//
//	Pixie_Table_LMList: 
//      Show Table of imported binary data, sorted by parameter
//
//########################################################################
Window Pixie_Table_LMList() : Table
	// TODO: change arrays to "pixie"
	DoWindow/F LM_TSList
	if (V_Flag!=1)
		Edit/W=(280,50,800,450)/K=1 root:LM:Hit,root:LM:chnum, root:LM:energy//, root:LM:psa, root:LM:rt
		DoWindow/C LM_TSList
		AppendToTable root:LM:Energy0,root:LM:Energy1,root:LM:Energy2,root:LM:Energy3
		AppendToTable root:LM:TrigTimeH,root:LM:TrigTimeL//,root:LM:PTP_Time//0,root:LM:TrigTime1, root:LM:TrigTime2,root:LM:TrigTime3
		AppendToTable root:LM:LocTime0,root:LM:LocTime1, root:LM:LocTime2,root:LM:LocTime3
		AppendToTable root:LM:CFD0,root:LM:CFD1, root:LM:CFD2,root:LM:CFD3
		//AppendToTable root:LM:ETx,root:LM:ETy,root:LM:Tdiffxy
		AppendToTable root:LM:TdiffA//,root:LM:TdiffB, root:LM:TdiffC
							
											// TODO: add more values, eg PSA
		ModifyTable width=40
		ModifyTable sigDigits=10
		ModifyTable format(root:LM:Hit)=10
		ModifyTable width(root:LM:Hit)=60
		ModifyTable sigDigits(root:LM:Hit)=8
		ModifyTable width(root:LM:chnum)=30
		
	endif
EndMacro

//########################################################################
//
//	Pixie_Table_EventList: 
//      Show Table of list mode header
//
//########################################################################
Window Pixie_Table_EventList() : Table
	// TODO: change arrays to "pixie"
	DoWindow/F LM_EvList
	if (V_Flag!=1)
		Edit/W=(280,50,520,450)/K=1 root:pixie4:LMheadernames, root:pixie4:LMeventheader
		DoWindow/C LM_EvList	
		ModifyTable width(Point)=40			
	
	endif
EndMacro




Window Oscilloscope_Gated() : Graph
	PauseUpdate; Silent 1		// building window...
	Display/K=1/W=(480.75,180.5,1137.75,527.75) :pixie4:ADCch0
	AppendToGraph/L=L1 ttcl
	AppendToGraph/L=L2 htrig
	AppendToGraph/L=L3 ctrig
	AppendToGraph/L=L4 veto
	AppendToGraph/L=L5 ftrig
	ModifyGraph mode(ttcl)=6,mode(htrig)=6,mode(ctrig)=6,mode(veto)=6,mode(ftrig)=6
	ModifyGraph rgb(ttcl)=(1,39321,19939),rgb(ctrig)=(29524,1,58982),rgb(veto)=(3,52428,1)
	ModifyGraph rgb(ftrig)=(16385,16388,65535)
	ModifyGraph lblPosMode(L5)=3
	ModifyGraph lblPos(left)=42
	ModifyGraph lblLatPos(L5)=5
	ModifyGraph lblRot(L1)=-90,lblRot(L2)=-90,lblRot(L3)=-90,lblRot(L4)=-90,lblRot(L5)=-90
	ModifyGraph freePos(L1)={0,bottom}
	ModifyGraph freePos(L2)={0,bottom}
	ModifyGraph freePos(L3)={0,bottom}
	ModifyGraph freePos(L4)={0,bottom}
	ModifyGraph freePos(L5)={0,bottom}
	ModifyGraph axisEnab(left)={0.5,1}
	ModifyGraph axisEnab(L1)={0,0.08}
	ModifyGraph axisEnab(L2)={0.1,0.18}
	ModifyGraph axisEnab(L3)={0.2,0.28}
	ModifyGraph axisEnab(L4)={0.3,0.38}
	ModifyGraph axisEnab(L5)={0.4,0.48}
	ModifyGraph manTick(L1)={0,1,0,1},manMinor(L1)={0,50}
	ModifyGraph manTick(L2)={0,1,0,1},manMinor(L2)={0,50}
	ModifyGraph manTick(L3)={0,1,0,1},manMinor(L3)={0,50}
	ModifyGraph manTick(L4)={0,1,0,2},manMinor(L4)={0,50}
	ModifyGraph manTick(L5)={0,1,0,1},manMinor(L5)={0,50}
	Label left "Signal"
	Label L1 " TTCL Approved"
	Label L2 " Esum Latch"
	Label L3 " Coinc. Latch"
	Label L4 " Veto"
	Label L5 " Fast Trigger"
	SetAxis L1 0,1.2
	SetAxis L2 0,1.2
	SetAxis L3 0,1.2
	SetAxis L4 0,1.2
	SetAxis L5 0,1.2

EndMacro

Function ExtractUserGate()

	wave adcch0 = root:pixie4:adcch0
	//wave adcch0 = root:adc6
	wave adcch0 = root:adc0
	
	duplicate/o adcch0, ftrig
	duplicate/o adcch0, veto
	duplicate/o adcch0, ctrig
	duplicate/o adcch0, htrig
	duplicate/o adcch0, ttcl
	
	ttcl  = (ttcl & 0x0001)
	htrig = ((htrig & 0x0002))/2
	ctrig = ((ctrig & 0x0004))/4
	veto  = ((veto & 0x0008))/8
	ftrig = ((ftrig & 0x0010))/16
	

End









