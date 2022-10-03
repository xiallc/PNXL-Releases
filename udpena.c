/*----------------------------------------------------------------------
 * Copyright (c) 2019,2021 XIA LLC
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, 
 * with or without modification, are permitted provided 
 * that the following conditions are met:
 *
 *   * Redistributions of source code must retain the above 
 *     copyright notice, this list of conditions and the 
 *     following disclaimer.
 *   * Redistributions in binary form must reproduce the 
 *     above copyright notice, this list of conditions and the 
 *     following disclaimer in the documentation and/or other 
 *     materials provided with the distribution.
 *   * Neither the name of XIA LLC
 *     nor the names of its contributors may be used to endorse 
 *     or promote products derived from this software without 
 *     specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND 
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 * IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE 
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON 
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF 
 * SUCH DAMAGE.
 *----------------------------------------------------------------------*/

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <math.h>
#include <time.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/file.h>
// need to compile with -lm option

#include "PixieNetDefs.h"
#include "PixieNetCommon.h"
#include "PixieNetConfig.h"


int main(void) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;
  //int k;
  char * query;

  unsigned int RunType, SyncT, ReqRunTime,  WR_RTCtrl;  // PollTime,
  //double dt, ph, elm, q, tmpD, bscale;
  unsigned int tmp0, tmp1, tmp2; //w0, w1, tmp0, tmp1, tmp2; //, tmp3;
  unsigned long long WR_tm_tai, WR_tm_tai_start, WR_tm_tai_stop, WR_tm_tai_next;



  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
  int k7; //, ch_k7, ch, chw;  // ch = abs ch. no; ch_k7 = ch. no in k7
  
  //int verbose = 1;      // TODO: control with argument to function 
  // 0 print errors and minimal info only
  // 1 print errors and full info
  //int maxmsg = 10;
  //int rejectcount =0;


   // *************** PS/PL IO initialization *********************
  // open the device for PD register I/O
  fd = open("/dev/uio0", O_RDWR);
  if (fd < 0) {
    perror("Failed to open devfile");
    return -2;
  }

  /* no locking
  //Lock the PL address space so multiple programs cant step on eachother.
  if( flock( fd, LOCK_EX | LOCK_NB ) )
  {
    printf( "Failed to get file lock on /dev/uio0\n" );
    return -3;
  }
  */

  map_addr = mmap( NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

  if (map_addr == MAP_FAILED) {
    perror("Failed to mmap");
    return -4;
  }

  mapped = (unsigned int *) map_addr;

  // ************************** pre-DAQ checks ********************************


  // check if FPGA booted
  tmp0 = mapped[AMZ_CSROUTL];
  if( (tmp0 & 0x4000) ==0) {
       printf( "FPGA not booted, please run ./bootfpga first\n" );
       return -5;
  }



  // ******************* read ini file and fill struct with values ********************
  
  PixieNetFippiConfig fippiconfig;		// struct holding the input parameters
  const char *defaults_file = "defaults.ini";
  int rval = init_PixieNetFippiConfig_from_file( defaults_file, 0, &fippiconfig );   // first load defaults, do not allow missing parameters
  if( rval != 0 )
  {
    printf( "Failed to parse FPGA settings from %s, rval=%d\n", defaults_file, rval );
    return rval;
  }
  const char *settings_file = "settings.ini";
  rval = init_PixieNetFippiConfig_from_file( settings_file, 2, &fippiconfig );   // second override with user settings, do allow missing, don't print missing
  if( rval != 0 )
  {
    printf( "Failed to parse FPGA settings from %s, rval=%d\n", settings_file, rval );
    return rval;
  }

  // assign to local variables, including any rounding/discretization
  RunType      = fippiconfig.RUN_TYPE;
  WR_RTCtrl    = fippiconfig.WR_RUNTIME_CTRL;
  SyncT        = fippiconfig.SYNC_AT_START;
  ReqRunTime   = fippiconfig.REQ_RUNTIME;


  if( (RunType==0x100) || (RunType==0x105) || (RunType==0x110) || (RunType==0x111) || 
      (RunType==0x404) || (RunType==0x410) || (RunType==0x411) ) {      // check run type
   // 0x301 no longer supported because header memory is disabled for pure MCA runs, use mcadaq instead
  } else {
      printf( "This function only supports runtypes 0x100 (P16), 0x105, 0x110, 0x111, 0x404, 0x410, 0x411, not 0x%x \n",RunType);
      return(-1);
  }

  if(fippiconfig.DATA_FLOW != 4)
  {
      printf( "This function only supports DATA_FLOW == 4 , not %d \n",fippiconfig.DATA_FLOW);
      return(-2);
  }



  // --------------------------------------------------------
  // ------------------- Main code begins --------------------
  // --------------------------------------------------------

  // ********************** Run Start **********************

  // initialize memories
  for(k7=0;k7<N_K7_FPGAS;k7++)
  {     
      mapped[AMZ_DEVICESEL] =  cs[k7];	      // select FPGA 
      mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr:    PAGE register
      mapped[AMZ_EXDWR]  = PAGE_SYS;         // PAGE 0: system, page 0x10n = channel n
      
      mapped[AMZ_EXAFWR] =  AK7_HOSTCLR;     // specify   K7's addr:    write to clear SDRAM, DEEPFIFO 
      mapped[AMZ_EXDWR]  =  0;               // any write ok
      usleep(10);                            // memory reset may need some time
  }

  // synchronize timers
  mapped[AMZ_DEVICESEL] = CS_MZ;	            // select MZ
  if(SyncT==1)  mapped[ARTC_CLR] = 0x0001;   // any write will create a pulse to clear time stamps. This is ignored for WR_RTCtrl=2

  if(WR_RTCtrl==3 || WR_RTCtrl==4)            // RunEnable/Live set via WR time comparison in Kintex or PZ, user specified start time from web query 
  {
      // get form data
     query = getenv("QUERY_STRING");
     if( (query != NULL) && (sscanf(query,"WR_tm_tai_start=%llu",&WR_tm_tai_start)==1) )  {

       WR_tm_tai_stop  =  WR_tm_tai_start + ReqRunTime - 1;


       if(WR_RTCtrl==3)                           // RunEnable/Live set via WR time comparison in Kintex 
       {
         // write start/stop to both K7
         // todo: this requires both K7s to be a WR slave with valid time from master
         for(k7=0;k7<N_K7_FPGAS;k7++)
         {     
            mapped[AMZ_DEVICESEL] =  cs[k7];	   // select FPGA 
            mapped[AMZ_EXAFWR] = AK7_PAGE;      // specify   K7's addr:    PAGE register
            mapped[AMZ_EXDWR]  = PAGE_SYS;      //  PAGE 0: system, page 0x10n = channel n
   
            mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_START+0;   // specify   K7's addr:    WR start time register
            mapped[AMZ_EXDWR]  =  WR_tm_tai_start      & 0x00000000FFFF;
            mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_START+1;   // specify   K7's addr:    WR start time register
            mapped[AMZ_EXDWR]  =  (WR_tm_tai_start>>16) & 0x00000000FFFF;
            mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_START+2;   // specify   K7's addr:    WR start time register
            mapped[AMZ_EXDWR]  =  (WR_tm_tai_start>>32) & 0x00000000FFFF;
      
            mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_STOP+0;   // specify   K7's addr:    WR stop time register
            mapped[AMZ_EXDWR]  =  WR_tm_tai_stop      & 0x00000000FFFF;
            mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_STOP+1;   // specify   K7's addr:    WR stop time register
            mapped[AMZ_EXDWR]  =  (WR_tm_tai_stop>>16) & 0x00000000FFFF;
            mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_STOP+2;   // specify   K7's addr:    WR stop time register
            mapped[AMZ_EXDWR]  =  (WR_tm_tai_stop>>32) & 0x00000000FFFF; 
         } // end K7s

       } //end  WR_RTCtrl==3

       if(WR_RTCtrl==4)   
       {
         // write start/stop to PZ
         mapped[AMZ_WR_START_TAI]    =   WR_tm_tai_start      & 0x00000000FFFF;
         mapped[AMZ_WR_START_TAI+1]  =  (WR_tm_tai_start>>16) & 0x00000000FFFF;
         mapped[AMZ_WR_START_TAI+2]  =  (WR_tm_tai_start>>32) & 0x00000000FFFF;
         mapped[AMZ_WR_STOP_TAI]     =   WR_tm_tai_stop       & 0x00000000FFFF;
         mapped[AMZ_WR_STOP_TAI+1]   =  (WR_tm_tai_stop>>16)  & 0x00000000FFFF;
         mapped[AMZ_WR_STOP_TAI+2]   =  (WR_tm_tai_stop>>32)  & 0x00000000FFFF; 
       }  //end  WR_RTCtrl==4

     } else {
         printf( "WARNING: No start time given for WR_RTCtrl=3 (or 4). Continuing as WR_RTCtrl=1 (or 2) \n" );
         WR_RTCtrl = WR_RTCtrl - 2;
     }

  }   //end  WR_RTCtrl==3 or 4  

  if(WR_RTCtrl==1)                           // RunEnable/Live set via WR time comparison in Kintex  (if startT < WR time < stopT => RunEnable=1) 
  {
      mapped[AMZ_DEVICESEL] = CS_K1;	      // specify which K7 
      mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr:    PAGE register
      mapped[AMZ_EXDWR]  = PAGE_SYS;         // PAGE 0: system, page 0x10n = channel n

      // check if WR locked
      mapped[AMZ_EXAFRD] = AK7_CSROUT;   
      tmp0 =  mapped[AMZ_EXDRD];    
      if( (tmp0 & 0x0300) ==0) {
          printf( "WARNING: WR link down or time not valid, please check via minicom\n" );
      }

      // get current WR time
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+0;   
      tmp0 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp0 =  mapped[AMZ_EXDRD];
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+1;   
      tmp1 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp1 =  mapped[AMZ_EXDRD];
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+2;   
      tmp2 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp2 =  mapped[AMZ_EXDRD];
      WR_tm_tai = tmp0 +  65536*tmp1 + TWOTO32*tmp2;

      //find next "round" time point 
      WR_tm_tai_next = WR_TAI_STEP*(unsigned long long)floor(WR_tm_tai/WR_TAI_STEP)+ WR_TAI_STEP;   // next coarse time step
     // if( WR_tm_tai_next - WR_tm_tai < WR_TAI_MARGIN)                                          // if too close, 
     //       WR_tm_tai_next = WR_tm_tai_next + WR_TAI_STEP;                                     // one more step   
     // probably bogus. a proper scheme to ensure multiple modules start at the same time should be implemented on the DAQ network master 
    
      WR_tm_tai_start =  WR_tm_tai_next;
      WR_tm_tai_stop  =  WR_tm_tai_next + ReqRunTime - 1;
      ReqRunTime = ReqRunTime + WR_TAI_STEP;    // increase time for local DAQ counter accordingly

      printf( "Current WR time %llu s\n",WR_tm_tai );
      printf( "Start time %llu s\n",WR_tm_tai_start );
      printf( "Stop time %llu s\n",WR_tm_tai_stop +1);

      // write start/stop to both K7
      // todo: this requires both K7s to be a WR slave with valid time from master
      for(k7=0;k7<N_K7_FPGAS;k7++)
      {     
         mapped[AMZ_DEVICESEL] =  cs[k7];	   // select FPGA 
         mapped[AMZ_EXAFWR] = AK7_PAGE;      // specify   K7's addr:    PAGE register
         mapped[AMZ_EXDWR]  = PAGE_SYS;      //  PAGE 0: system, page 0x10n = channel n

         mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_START+0;   // specify   K7's addr:    WR start time register
         mapped[AMZ_EXDWR]  =  WR_tm_tai_start      & 0x00000000FFFF;
         mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_START+1;   // specify   K7's addr:    WR start time register
         mapped[AMZ_EXDWR]  =  (WR_tm_tai_start>>16) & 0x00000000FFFF;
         mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_START+2;   // specify   K7's addr:    WR start time register
         mapped[AMZ_EXDWR]  =  (WR_tm_tai_start>>32) & 0x00000000FFFF;
   
         mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_STOP+0;   // specify   K7's addr:    WR stop time register
         mapped[AMZ_EXDWR]  =  WR_tm_tai_stop      & 0x00000000FFFF;
         mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_STOP+1;   // specify   K7's addr:    WR stop time register
         mapped[AMZ_EXDWR]  =  (WR_tm_tai_stop>>16) & 0x00000000FFFF;
         mapped[AMZ_EXAFWR] =  AK7_WR_TM_TAI_STOP+2;   // specify   K7's addr:    WR stop time register
         mapped[AMZ_EXDWR]  =  (WR_tm_tai_stop>>32) & 0x00000000FFFF; 
      } // end K7s
  }  

  if(WR_RTCtrl==2)                       // RunEnable/Live set via WR time comparison in PicoZed (if startT < WR time < stopT => RunEnable=1) 
  {
      mapped[AMZ_DEVICESEL] = CS_MZ;	   // specify MZ
  
      // check if WR locked
      tmp0 =  mapped[AMZ_CSROUTL];    
      if( (tmp0 & 0x0008) ==0) {
          printf( "WARNING: WR link down or time not valid (CSR = 0x%X, please check via minicom\n", tmp0 );
      }

      // get current WR time  
      tmp0 =  mapped[AMZ_WR_READ_TAI+0];    
      tmp1 =  mapped[AMZ_WR_READ_TAI+1]; 
      tmp2 =  mapped[AMZ_WR_READ_TAI+2];
      WR_tm_tai = tmp0 +  65536*tmp1 + TWOTO32*tmp2;

      //find next "round" time point 
      WR_tm_tai_next = WR_TAI_STEP*(unsigned long long)floor(WR_tm_tai/WR_TAI_STEP)+ WR_TAI_STEP;   // next coarse time step 
     // probably bogus. a proper scheme to ensure multiple modules start at the same time should be implemented on the DAQ network master 
    
      WR_tm_tai_start =  WR_tm_tai_next;
      WR_tm_tai_stop  =  WR_tm_tai_next + ReqRunTime - 1;
      ReqRunTime = ReqRunTime + WR_TAI_STEP;    // increase time for local DAQ counter accordingly

      printf( "Current WR time %llu (0x %x %x %x)\n",WR_tm_tai, tmp2, tmp1, tmp0 );
      printf( "Start time %llu\n",WR_tm_tai_start );
      printf( "Stop time %llu\n",WR_tm_tai_stop +1);

      // write start/stop to PZ
      mapped[AMZ_WR_START_TAI]    =   WR_tm_tai_start      & 0x00000000FFFF;
      mapped[AMZ_WR_START_TAI+1]  =  (WR_tm_tai_start>>16) & 0x00000000FFFF;
      mapped[AMZ_WR_START_TAI+2]  =  (WR_tm_tai_start>>32) & 0x00000000FFFF;
      mapped[AMZ_WR_STOP_TAI]     =   WR_tm_tai_stop      & 0x00000000FFFF;
      mapped[AMZ_WR_STOP_TAI+1]   =  (WR_tm_tai_stop>>16) & 0x00000000FFFF;
      mapped[AMZ_WR_STOP_TAI+2]   =  (WR_tm_tai_stop>>32) & 0x00000000FFFF; 

  }  

  // disable MCA fifo output -- not needed for pure LM runs
  mapped[AMZ_DEVICESEL] = CS_MZ;	// select MZ
  mapped[AMZ_RUNCTRL] = 0x0000;    // MCA FIFO disabled

 
  // finally, start run
  mapped[AMZ_CSRIN] = 0x0001;      // RunEnable=1 > nLive=0 (DAQ on)
  // this is a bit in a MZ register tied to a line to both FPGAs
  // falling edge of nLive clears counters and memory address pointers
  // line ignored for WR_RTCtrl in K7, but still useful for TotalTime in MZ  

  printf("UDP DAQ started");
 
  // flock( fd, LOCK_UN );      no locking above
  munmap(map_addr, size);
  close(fd);
  return 0;
}
