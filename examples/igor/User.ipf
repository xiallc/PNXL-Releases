#pragma rtGlobals=1		// Use modern global access method.

// This procedure file contains templates for user functions.
// The functions are called at certain points in the standard operation, e.g. 
// at the beginning or end of a run. Users can modify the functions to 
// execute custom routines at these points. 
// Output data is located in root:results 
// The variable root:user:UserVersion specifies the version of XIA's user calls in the main code, defined in main code
// The variable root:user:UserVariant specifies the user code variant (=application)
// The variable root:user:UserCode specifies the user code version (=updates, builds for a given application)

// ****************************************************************************************
// User Functions called by general code
// ****************************************************************************************


Function User_Globals()
	// called from Pixie_InitGlobals. Use to define and create global variables

	Variable/G root:user:UserVariant = 0x0000	// the user code variant (= application). variant numbers 0x0000-0x7FFF reserved for code written by XIA 
	// Variant 0x0000 = generic
	// Variant 0x0100 = Xe PW
	// Variant 0x0110 = Xe SAUNA
	// Variant 0x0200 = MPI
	// Variant 0x0300 = gamma neutron
	// Variant 0x0400 = general PSA
	
	Variable/G root:user:UserCode= 0x0001// the user code version = updates and modifications of code for the same application
	String/G root:user:UserTitle = "User"	// This string may be used in a number of panels and displays. Replace for a particular application
	
	// add additional user global variables below
End



Function User_ChangeChannelModule()
	//called when changing Module Number or Channel Number

	//User_GetDSPValues("")	//read data back from DSP of current module
	
	//add custom code below
	
End

Function User_ReadEvent()
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
	endif
	
	//add custom code below
	PSA_ReadEvent()
	
End




// ****************************************************************************************
// User Control Panels 
// ****************************************************************************************


Window User_Control() : Panel
	PauseUpdate; Silent 1		// building window...
	// sample user control panel
	User_GetDSPValues("")		//update values
	
	DoWindow/F User_Control		// bring panel to front, if open
	if (V_flag!=1)					// only if not already open, make new panel
		NewPanel /K=1/W=(446,197,1000,556) 
		ModifyPanel cbRGB=(65280,59904,48896)
		DoWindow/C User_Control
		SetDrawLayer UserBack
		SetDrawEnv fsize= 14,fstyle= 1
		DrawText 5,25,"DSP Input Parameters"
		SetDrawEnv fsize= 14,fstyle= 1
		DrawText 200,26,"Options"
		SetDrawEnv fsize= 14,fstyle= 1
		DrawText 400,25,"DSP Output Values"
		
//		Variable ncp =  root:pixie4:NumChannelPar
//		SetVariable ADV_ModCSRB,pos={7,32},size={120,16},title="ModCSRB",help={"Module CSRB - set bit 0 to enable User code"}
//		SetVariable ADV_ModCSRB,fSize=10,format="%X",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_MCSRB], proc=Pixie_IO_ModVarControl
//		SetVariable ADV_CHANNEL_CSRB0,pos={7,52},size={120,16},title="CCSRB0   ",help={"Channel 0 CSRB - set bit 0 to enable User code"}
//		SetVariable ADV_CHANNEL_CSRB0,fSize=10,format="%X",value=root:pixie4:Display_Channel_Parameters[root:pixie4:index_CCSRB+0*ncp], proc=Pixie_IO_ChanVarControl
//		SetVariable ADV_CHANNEL_CSRB1,pos={7,72},size={120,16},title="CCSRB1   ",help={"Channel 1 CSRB - set bit 0 to enable User code"}
//		SetVariable ADV_CHANNEL_CSRB1,fSize=10,format="%X",value= root:pixie4:Display_Channel_Parameters[root:pixie4:index_CCSRB+1*ncp], proc=Pixie_IO_ChanVarControl
//		SetVariable ADV_CHANNEL_CSRB2,pos={7,92},size={120,16},title="CCSRB2   ",help={"Channel 2 CSRB - set bit 0 to enable User code"}
//		SetVariable ADV_CHANNEL_CSRB2,fSize=10,format="%X",value=root:pixie4:Display_Channel_Parameters[root:pixie4:index_CCSRB+2*ncp], proc=Pixie_IO_ChanVarControl
//		SetVariable ADV_CHANNEL_CSRB3,pos={7,112},size={120,16},title="CCSRB3   ",help={"Channel 3 CSRB - set bit 0 to enable User code"}
//		SetVariable ADV_CHANNEL_CSRB3,fSize=10,format="%x",value= root:pixie4:Display_Channel_Parameters[root:pixie4:index_CCSRB+3*ncp], proc=Pixie_IO_ChanVarControl
//		
//				// change name and appareance, but not the index for DSPValues
//		SetVariable UserIn00,pos={10,142},size={120,16},title="User Input 0 ",help={"User Input 0"}
//		SetVariable UserIn00,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn], proc=Pixie_IO_ModVarControl
//		SetVariable UserIn01,pos={10,160},size={120,16},title="User Input 1 ",help={"User Input 1"}
//		SetVariable UserIn01,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn+1], proc=Pixie_IO_ModVarControl
//		SetVariable UserIn02,pos={10,182},size={120,16},title="User Input 2 ",help={"User Input 2"}
//		SetVariable UserIn02,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn+2], proc=Pixie_IO_ModVarControl
//		SetVariable UserIn03,pos={10,200},size={120,16},title="User Input 3 ",help={"User Input 3"}
//		SetVariable UserIn03,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn+3], proc=Pixie_IO_ModVarControl
//		SetVariable UserIn04,pos={10,222},size={120,16},title="User Input 4 ",help={"User Input 4"}
//		SetVariable UserIn04,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn+4], proc=Pixie_IO_ModVarControl
//		SetVariable UserIn05,pos={10,240},size={120,16},title="User Input 5 ",help={"User Input 5"}
//		SetVariable UserIn05,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn+5], proc=Pixie_IO_ModVarControl
//		SetVariable UserIn06,pos={10,262},size={120,16},title="User Input 6 ",help={"User Input 6"}
//		SetVariable UserIn06,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn+6], proc=Pixie_IO_ModVarControl
//		SetVariable UserIn07,pos={10,280},size={120,16},title="User Input 7 ",help={"User Input 7"}
//		SetVariable UserIn07,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserIn+7], proc=Pixie_IO_ModVarControl
//		//etc, max 15 inputs UserIn08 .. UserIn15
//		
//		// better: using module parameters from C library
//		ValDisplay UserOut0,pos={405,142},size={120,16},title="UserOut[0] ",help={"User Output 0"}
//		ValDisplay UserOut0,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserOUT]
//		ValDisplay UserOut1,pos={405,162},size={120,16},title="UserOut[1] ",help={"User Output 1"}
//		ValDisplay UserOut1,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserOUT+1]
//		ValDisplay UserOut2,pos={405,182},size={120,16},title="UserOut[2] ",help={"User Output 2"}
//		ValDisplay UserOut2,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserOUT+2]
//		ValDisplay UserOut3,pos={405,202},size={120,16},title="UserOut[3] ",help={"User Output 3"}
//		ValDisplay UserOut3,fSize=10,format="%g",value= root:pixie4:Display_Module_Parameters[root:pixie4:index_UserOUT+3]	
//		//etc, max 15 outputs
//		
//		Checkbox EnableUserCode, pos = {207,32}, size={60,20},proc=User_CheckBoxControl,title="Enable User DSP code"
//		Checkbox EnableUserCode, fsize=11,font="Arial",help={"Sets bits in Module CSRB and Channel CSRB to switch on user code in DSP"}
		
		Button About,pos={240,310},size={90,25},proc=User_Version,title="Version",fsize=11

	endif
EndMacro

// ****************************************************************************************
// User Control Panel Functions 
// ****************************************************************************************

Window User_Version(ctrlName) : ButtonControl
String ctrlName

	DoWindow/F User_Version		// bring panel to front, if open
	if (V_flag!=1)					// only if not already open, make new panel
		//NewPanel /K=1/W=(446,197,1103,556) 
		NewPanel /K=1/W=(20,20,250,150) as "User Version"
		ModifyPanel cbRGB=(65280,59904,48896)
		DoWindow/C User_Version
		
		ValDisplay UserV0,pos={10,20},size={140,16},title="Igor User Calls:     0x",help={"Version of Igor function calls from main code to user code"}
		ValDisplay UserV0,fSize=10,format="%X",value= root:user:UserVersion
		ValDisplay UserV1,pos={10,45},size={140,16},title="Igor User Variant: 0x",help={"Variant of Igor user functions (application)"}
		ValDisplay UserV1,fSize=10,format="%X",value= root:user:UserVariant 
//		ValDisplay UserV2,pos={10,95},size={140,16},title="DSP User Code:   0x",help={"Version of user DSP code"}
//		ValDisplay UserV2,fSize=10,format="%X",value= root:pixie4:DSPValues[Pixie_Find_DSPname("UserOut")]
//		ValDisplay UserV3,pos={10,70},size={140,16},title="Igor User Code:    0x",help={"Version of Igor user functions (build number)"}
//		ValDisplay UserV3,fSize=10,format="%X",value= root:user:UserCode
	endif
End











//**************************************************************************************************
// Other subroutines
//**************************************************************************************************

Function User_DuplicateResults()
	// duplicate selected run output data to variables and waves in the "results" data folder
	
	//statistics
	
	if(0)	// only execute when necessary	

		Svar StartTime = root:pixie4:StartTime
		Svar StopTime = root:pixie4:StopTime
		
		Svar StartTimeU = root:results:StartTime
		Svar StopTimeU = root:results:StopTime
		
	
		StartTimeU = StartTime
		StopTimeU = StopTime
		

//		Wave ChannelCountTime = root:results:ChannelCountTime
//		Wave ChannelInputCountRate =  root:results:ChannelInputCountRate
//		ChannelCountTime[0] = Display_Channel_Parameters[index_COUNTTIME+0*ncp]
//		ChannelCountTime[1] = Display_Channel_Parameters[index_COUNTTIME+1*ncp]
//		ChannelCountTime[2] = Display_Channel_Parameters[index_COUNTTIME+2*ncp]
//		ChannelCountTime[3] = Display_Channel_Parameters[index_COUNTTIME+3*ncp]
//		ChannelInputCountRate[0] = Display_Channel_Parameters[index_ICR+0*ncp]
//		ChannelInputCountRate[1] = Display_Channel_Parameters[index_ICR+1*ncp]
//		ChannelInputCountRate[2] = Display_Channel_Parameters[index_ICR+2*ncp]
//		ChannelInputCountRate[3] = Display_Channel_Parameters[index_ICR+3*ncp]
		
		
		//MCAs
		Wave MCAch0 =  root:pixie4:MCAch0
		Duplicate/o MCAch0, root:results:MCAch0
		Wave MCAch1 =  root:pixie4:MCAch1
		Duplicate/o MCAch1, root:results:MCAch1
		Wave MCAch2 =  root:pixie4:MCAch2
		Duplicate/o MCAch2, root:results:MCAch2
		Wave MCAch2 =  root:pixie4:MCAch2
		Duplicate/o MCAch2, root:results:MCAch2
		Wave MCAsum =  root:pixie4:MCAsum
		Duplicate/o MCAsum, root:results:MCAsum
		
		
		//traces and list mode data
		Wave trace0 =  root:pixie4:trace0
		Duplicate/o trace0, root:results:trace0
		Wave trace1 =  root:pixie4:trace1
		Duplicate/o trace1, root:results:trace1
		Wave trace2 =  root:pixie4:trace2
		Duplicate/o trace2, root:results:trace2
		Wave trace3 =  root:pixie4:trace3
		Duplicate/o trace3, root:results:trace3

	endif
	
End
