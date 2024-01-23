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
  char * query;

  unsigned int RunType, SyncT, ReqRunTime,  WR_RTCtrl;  
  unsigned int tmp0; 
  unsigned long long WR_tm_tai_start;



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
         // runtype ok, do nothing
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

  if(WR_RTCtrl>0)    // White Rabbit run synchronization
  {
     // get form data
     query = getenv("QUERY_STRING");
     if(query != NULL) 
         sscanf(query,"WR_tm_tai_start=%llu",&WR_tm_tai_start);
     else  
         WR_tm_tai_start = 0;
     
     // call subroutine. Updates ReqRunTime to accommodate WR setup delay
     ReqRunTime = WRrunstart(mapped, WR_RTCtrl, ReqRunTime, WR_tm_tai_start );
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
