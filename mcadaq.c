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

// this routine is a simplification of startdaq for only MCA runs

int main(void) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;
  int k;
  FILE * filmca;

  unsigned int RunType, SyncT, ReqRunTime, PollTime, WR_RTCtrl;
  unsigned int CCSRA[NCHANNELS], PILEUPCTRL[NCHANNELS];
  unsigned int Binfactor[NCHANNELS];
  unsigned int GoodChanMASK[N_K7_FPGAS] = {0} ;
  time_t starttime, currenttime;
  unsigned int tmp0, tmp1, tmp2;
  unsigned long long WR_tm_tai, WR_tm_tai_start, WR_tm_tai_stop, WR_tm_tai_next;
  unsigned int pileup;
  unsigned int evstats, R1;
  unsigned int energy, energyF, bin, over; 
  unsigned int mca[NCHANNELS][MAX_MCA_BINS] ={{0}};      // full MCA for end of run
  unsigned int wmca[NCHANNELS][WEB_MCA_BINS] ={{0}};     // smaller MCA during run
  unsigned int onlinebin, loopcount, eventcount, eventcount_ch[NCHANNELS];
  unsigned int MCA0counts, MCA1counts;
  onlinebin=MAX_MCA_BINS/WEB_MCA_BINS;
  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
  unsigned int revsn, NCHANNELS_PER_K7, NCHANNELS_PRESENT;
  int k7, ch_k7, ch;  // ch = abs ch. no; ch_k7 = ch. no in k7
  
  int verbose = 1;      // TODO: control with argument to function  ?
  // 0 print errors and minimal info only
  // 1 print errors and full info
  int maxmsg = 10;


  // *************** PS/PL IO initialization *********************
  // open the device for PD register I/O
  fd = open("/dev/uio0", O_RDWR);
  if (fd < 0) {
    perror("Failed to open devfile");
    return -2;
  }

  // Lock the PL address space so multiple programs cant step on eachother.
  if( flock( fd, LOCK_EX | LOCK_NB ) )
  {
    printf( "Failed to get file lock on /dev/uio0\n" );
    return -3;
  }

  map_addr = mmap( NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

  if (map_addr == MAP_FAILED) {
    perror("Failed to mmap");
    return -4;
  }

  mapped = (unsigned int *) map_addr;

  // ************************** check HW version ********************************

  revsn = hwinfo(mapped,I2C_SELMAIN);    // some settings may depend on HW variants
 
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_75)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;         
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_125)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;           
  } 
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_14_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_16_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;            
  } 
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_14_500)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;          
  } 

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
  PollTime     = fippiconfig.POLL_TIME;

  if( (RunType==0x301)  ) {      // check run type
  // 0x301 is ok
     printf( "Starting runtype  0x301 \n");
  } else {
     printf( "This function only supports runtype  0x301 \n");
     return(-1);
  }


  for(k7=0;k7<N_K7_FPGAS;k7++)  {
     for( ch_k7=0; ch_k7 < NCHANNELS_PER_K7; ch_k7++) {
         ch = ch_k7+k7*NCHANNELS_PER_K7;
   //    SG[ch]          = (int)floor(fippiconfig.ENERGY_FLATTOP[ch]*FILTER_CLOCK_MHZ);       // multiply time in us *  # ticks per us = time in ticks
         Binfactor[ch]   = fippiconfig.BINFACTOR[ch];
         CCSRA[ch]       =  fippiconfig.CHANNEL_CSRA[ch]; 
         PILEUPCTRL[ch] =  ( CCSRA[ch] & (1<<CCSRA_PILEUPCTRL) ) >0;   // if bit set, only allow "single" non-piledup events
         if( (CCSRA[ch] & (1<<CCSRA_GOOD)) >0 )
            GoodChanMASK[k7] = GoodChanMASK[k7] + (1<<ch_k7) ;   // build good channel mask
     }
  }


  // --------------------------------------------------------
  // ------------------- Main code begins --------------------
  // --------------------------------------------------------


  // ********************** Run Start **********************

  loopcount  = 0;
  eventcount = 0;
  MCA0counts = 0;
  MCA1counts = 0;
  for( ch=0; ch < NCHANNELS; ch++) eventcount_ch[ch] = 0;
  starttime = time(NULL);                      // capture OS start time



  // Run Start Control
  mapped[AMZ_DEVICESEL] = CS_MZ;	            // select MZ
  if(SyncT==1)  mapped[ARTC_CLR] = 0x0001;     // any write will create a pulse to clear timers

  if(WR_RTCtrl==1)                             // RunEnable/Live set via WR time comparison  (if startT < WR time < stopT => RunEnable=1) 
  {
      mapped[AMZ_DEVICESEL] = CS_K1;	         // specify which K7 
      mapped[AMZ_EXAFWR] = AK7_PAGE;            // specify   K7's addr:    PAGE register
      mapped[AMZ_EXDWR]  = PAGE_SYS;            //  PAGE 0: system, page 0x10n = channel n

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
      WR_tm_tai_next  =  WR_TAI_STEP*(unsigned long long)floor(WR_tm_tai/WR_TAI_STEP)+ WR_TAI_STEP;   // next coarse time step   
      WR_tm_tai_start =  WR_tm_tai_next;
      WR_tm_tai_stop  =  WR_tm_tai_next + ReqRunTime - 1;
      ReqRunTime      = ReqRunTime + WR_TAI_STEP;    // increase time for local DAQ counter accordingly

      printf( "Current WR time %llu\n",WR_tm_tai );
      printf( "Start time %llu\n",WR_tm_tai_start );
      printf( "Stop time %llu\n",WR_tm_tai_stop +1);

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
      mapped[AMZ_DEVICESEL] = CS_MZ;	   // specify which K7 
  
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

      printf( "Current WR time %llu\n",WR_tm_tai );
      printf( "Start time %llu\n",WR_tm_tai_start );
      printf( "Stop time %llu\n",WR_tm_tai_stop +1);

      // write start/stop to PZ
      mapped[AMZ_WR_START_TAI]    =   WR_tm_tai_start      & 0x00000000FFFF;
      mapped[AMZ_WR_START_TAI+1]  =  (WR_tm_tai_start>>16) & 0x00000000FFFF;
      mapped[AMZ_WR_START_TAI+2]  =  (WR_tm_tai_start>>32) & 0x00000000FFFF;
      mapped[AMZ_WR_STOP_TAI]     =   WR_tm_tai_stop      & 0x00000000FFFF;
      mapped[AMZ_WR_STOP_TAI+1]   =  (WR_tm_tai_stop>>16) & 0x00000000FFFF;
      mapped[AMZ_WR_STOP_TAI+1]   =  (WR_tm_tai_stop>>32) & 0x00000000FFFF; 

  }  


   
  mapped[AMZ_DEVICESEL] = CS_MZ;	// select MZ
  mapped[AMZ_CSRIN] = 0x0001;      // RunEnable=1 > nLive=0 (DAQ on)
   // this is a bit in a MZ register tied to a line to both FPGAs
   // falling edge of nLive clears counters and memory address pointers
   // line ignored for WR_RTCtrl in K7, but still useful for TotalTime in MZ  
   

    // ********************** Run Loop **********************
  do {

      // -----------poll for events -----------
      // if data ready. read out, compute E, increment MCA *********

      for(k7=0;k7<N_K7_FPGAS;k7++)
      {
         // DATA_FLOW == 5: K7 streams MCA data to a FIFO in MZ
         if(fippiconfig.DATA_FLOW == 5)
         {
            mapped[AMZ_DEVICESEL] = CS_MZ;	                     // select MZ
            tmp2 = mapped[AMZ_CSROUTL];

            // for Kintex #0
            if ( (tmp2 & 0x00000080)>0 )                          // check MCAdataready bit   
            {
            
               if(MCA0counts==0) tmp0 = mapped[AMZ_RDMCA0];       // dummy read
               tmp0 = mapped[AMZ_RDMCA0+1];                       // channel and other info
               tmp1 = mapped[AMZ_RDMCA0];                         // energy  and advance FIFO
               ch       = (tmp0 & 0x7) + NCHANNELS_PER_K7*((tmp0 & 0x8) >> 3);   // 3 bits for channel number, bit 4 is K7 ID
               energy   = tmp1 & 0xFFFE;
               over     = (tmp0 & 0x10) >> 4;                     // negative or overflow
               pileup   = (tmp0 & 0x20) >> 5;                     // pileup
               if(eventcount<maxmsg) printf( "CSR: 0x%x MCA FIFO: ch %d, E %d (0x %x %x)\n", tmp2, ch, energy, tmp0, tmp1 );
               
               if( (PILEUPCTRL[ch]==0)  || (PILEUPCTRL[ch]==1 && !pileup )  )  // this pileup check is probably redundant, already applied in FPGA 
               {
                  bin = energy >> Binfactor[ch];
                  if( (bin<MAX_MCA_BINS) && (over==0) ) {
                     mca[ch][bin] =  mca[ch][bin] + 1;	         // increment mca
                     bin = bin >> WEB_LOGEBIN;
                     if(bin>0) wmca[ch][bin] = wmca[ch][bin] + 1; // increment wmca
                  }  
                }
               
               MCA0counts++;
               eventcount++;    
               eventcount_ch[ch]++;
            }  // end K7 0
            
            // for Kintex #1
            if ( (tmp2 & 0x00000100)>0 )                          // check MCAdataready bit
            {
           
               if(MCA1counts==0) tmp0 = mapped[AMZ_RDMCA1];       // dummy read
               tmp0 = mapped[AMZ_RDMCA1+1];                       // channel and other info
               tmp1 = mapped[AMZ_RDMCA1];                         // energy  and advance FIFO
               ch       = (tmp0 & 0x7) + NCHANNELS_PER_K7*((tmp0 & 0x8) >> 3);   // 3 bits for channel number, bit 4 is K7 ID
               energy = tmp1 & 0xFFFE;
               over     = (tmp0 & 0x10) >> 4;                     // negative or overflow
               pileup   = (tmp0 & 0x20) >> 5;                     // pileup
               if(eventcount<maxmsg) printf( "CSR: 0x%x MCA FIFO: ch %d, E %d (0x %x %x)\n", tmp2, ch, energy, tmp0, tmp1 );

               if( (PILEUPCTRL[ch]==0)  || (PILEUPCTRL[ch]==1 && !pileup )  )  // this pileup check is probably redundant, also in FPGA 
               {
                  bin = energy >> Binfactor[ch];
                  if( (bin<MAX_MCA_BINS) && (over==0) ) {
                     mca[ch][bin] =  mca[ch][bin] + 1;	         // increment mca
                     bin = bin >> WEB_LOGEBIN;
                     if(bin>0) wmca[ch][bin] = wmca[ch][bin] + 1; // increment wmca
                  } 
               }
             
               MCA1counts++;
               eventcount++;    
               eventcount_ch[ch]++;
             }  // nd K7 1

         } else {
            // DATA_FLOW == 2: ARM needs to poll K7 if data ready
            // then read energy and increment MCA
            // energy is always taken from FPGA (use startdaq for ARM computation (slow))     
        
            mapped[AMZ_DEVICESEL] =  cs[k7];	         // select FPGA 
            mapped[AMZ_EXAFWR] = AK7_PAGE;            // specify   K7's addr     addr 3 = channel/system
            mapped[AMZ_EXDWR]  = PAGE_SYS;            //                         0x0  = system  page
       
            // Read Header DPM status
            mapped[AMZ_EXAFRD] = AK7_SYSSYTATUS;      // write to  k7's addr for read -> reading from 0x85 system status register
            evstats = mapped[AMZ_EXDRD];              // bits set for every channel that has data in header memory
            if(SLOWREAD)  evstats = mapped[AMZ_EXDRD];   
            evstats = evstats & GoodChanMASK[k7];     // mask non-good channels
      
            // event readout compatible with P16 DSP code slow and inefficient
            if(evstats) {					  // if there are events in any [good] channel
                if(eventcount<maxmsg) printf( "K7 0 read from AK7_SYSSYTATUS (0x85), masked for good channels: 0x%X\n", evstats );
   
               for( ch_k7=0; ch_k7 < NCHANNELS_PER_K7; ch_k7++)
               {
   
                  ch = ch_k7+k7*NCHANNELS_PER_K7;                 // total channel count
                  R1 = 1 << ch_k7;
                  if(evstats & R1)	{	                           //  if there is an event in the header memory for this channel
                                                               
                     mapped[AMZ_EXAFWR] = AK7_PAGE;               // specify   K7's addr     addr 3 = channel/system
                     mapped[AMZ_EXDWR]  = PAGE_CHN+ch_k7;         //                         0x10n  = channel n     -> now addressing channel ch page of K7-0
                                         
                     // read for nextevent
                     mapped[AMZ_EXAFRD] = AK7_NEXTEVENT;          // select the "nextevent" address in channel's page
                     tmp0 = mapped[AMZ_EXDWR];                    // any read ok
   
                    if(  eventcount_ch[ch]==0) {
                     // dummy reads
                        mapped[AMZ_EXAFRD] = AK7_HDRMEM_D;        // write to  k7's addr for read -> reading from AK7_HDRMEM_A channel header fifo, low 16bit
                        tmp0 = mapped[AMZ_EXDRD];                 // read 16 bits
                     }            
   
                     // read FPGA E
                     mapped[AMZ_EXAFRD] = AK7_EFIFO;              // select the "EFIFO" address in channel's page
                     energyF = mapped[AMZ_EXDWR];                 // read 16 bits
                     if(SLOWREAD)  energyF = mapped[AMZ_EXDRD];   // read 16 bits
           
                     // extract pileup bit
                     pileup  = energyF & 0x1;                     // last bit of FIFO E is pilup
              
                     if( (PILEUPCTRL[ch]==0)     || (PILEUPCTRL[ch]==1 && !pileup )    )
                     {    // either don't care  OR pilup test required and  pileup bit not set
              
                        energy = energyF & 0xFFFE;                // overwrite local computation with FPGA result
                        
                        //  histogramming if E< max mcabin
                        bin = energy >> Binfactor[ch];
                        if(eventcount<maxmsg)   printf( "now incrementing MCA, E(%d) = %d, bin = %d\n", ch, energy,bin); 
                        if( (bin<MAX_MCA_BINS) && (bin>0) ) {
                           mca[ch][bin] =  mca[ch][bin] + 1;	   // increment mca
                           bin = bin >> WEB_LOGEBIN;
                           if(bin>0) wmca[ch][bin] = wmca[ch][bin] + 1;	// increment wmca
                        }
                        
                        eventcount++;    
                        eventcount_ch[ch]++;
                     }  // end pileup check
                  }     // end event in this channel
               }        // end for ch
            }           // end event in any channel
         }           // end if DATA_FLOW == 2 or 5
      }              // end for K7s



        // ----------- Periodically save MCA, PSA, and Run Statistics  -----------
       
        if(loopcount % PollTime == 0) 
        {
       
            // 1) Run Statistics 

            // for debug purposes, print to std out so we see what's going on
            mapped[AMZ_DEVICESEL] = CS_MZ;
            tmp0 = mapped[AMZ_RS_TT+1];                     // address offset by 1?
            tmp1 = mapped[AMZ_RS_TT+2];
             if(verbose) printf("%s %4.5G \n","Total_Time",((double)tmp0*65536+(double)tmp1*TWOTO32)*1e-9);     

            // print (small) set of RS to file, visible to web
            //read_print_runstats_XL_2x4(1, 0, mapped);    // print all, print to file
             read_print_rates_XL_2x4(0,mapped);            // print rates only, to file
           
            // 2) MCA
            filmca = fopen("MCA.csv","w");
            fprintf(filmca,"bin");
            for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",MCAch%02d",ch);
            fprintf(filmca,"\n");
            for( k=0; k <WEB_MCA_BINS; k++)                // report the 4K spectra during the run (faster web update)
            {
               fprintf(filmca,"%d",k*onlinebin);           // bin number
               for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",%d",wmca[ch][k]);    // print channel data
               fprintf(filmca,"\n");
            }
            fclose(filmca);    
            
        }
        
        // ----------- loop housekeeping -----------

         loopcount ++;
         currenttime = time(NULL);
      } while (currenttime <= starttime+ReqRunTime); // run for a fixed time   
  //   } while (eventcount <= 100); // run for a fixed number of events   



   // ********************** Run Stop **********************

   /* debug */


   if(WR_RTCtrl==1) 
   {
      mapped[AMZ_DEVICESEL] = CS_K1;	   // specify which K7 
      mapped[AMZ_EXAFWR] = AK7_PAGE;      // specify   K7's addr:    PAGE register
      mapped[AMZ_EXDWR]  = PAGE_SYS;      // PAGE 0: system, page 0x10n = channel n

      // get current time
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

      printf( "Current WR time (K7) %llu\n",WR_tm_tai );     
   }


   if(WR_RTCtrl==2)                       // RunEnable/Live set via WR time comparison in PicoZed (if startT < WR time < stopT => RunEnable=1) 
   {
      mapped[AMZ_DEVICESEL] = CS_MZ;	   // specify which K7 
  
      // get current WR time  
      tmp0 =  mapped[AMZ_WR_READ_TAI+0];
      tmp1 =  mapped[AMZ_WR_READ_TAI+1]; 
      tmp2 =  mapped[AMZ_WR_READ_TAI+2];
      WR_tm_tai = tmp0 +  65536*tmp1 + TWOTO32*tmp2;

      printf( "Current WR time (PZ) %llu\n",WR_tm_tai );
   } 

   printf( "Run completed\n" );

   /* end debug */

   // set nLive bit to stop run
   mapped[AMZ_DEVICESEL] = CS_MZ;	 // select MZ
   mapped[AMZ_CSRIN] = 0x0000; // all off       
   // todo: there may be events left in the buffers. need to stop, then keep reading until nothing left
                      
   // final save MCA and RS
   filmca = fopen("MCA.csv","w");
   fprintf(filmca,"bin");
   for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",MCAch%d",ch);
   fprintf(filmca,"\n");
   for( k=0; k <MAX_MCA_BINS; k++)
   {
       fprintf(filmca,"%d",k);                  // bin number
       for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",%d",mca[ch][k]);    // print channel data
       fprintf(filmca,"\n");
   }
   fclose(filmca);

   mapped[AMZ_DEVICESEL] = CS_MZ;
   read_print_runstats_XL_2x4(0, 0, mapped);  // print all, print to file
   read_print_rates_XL_2x4(0,mapped);
   mapped[AMZ_DEVICESEL] = CS_MZ;

 
 // clean up  

 flock( fd, LOCK_UN );
 munmap(map_addr, size);
 close(fd);
 return 0;
}
