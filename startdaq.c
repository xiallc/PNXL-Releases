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

//Functional modifications
// use files to signal stop:  file 'startok' indicates run in progress, file 'donesignal' indicated run should stop
// 222 Code to enable external STOP signal (presence of file 'donesignal')
// 444 Program should now always start by removing file 'donesignal' (to prevent "forgotten
//     file from immediately stoping the run...)
// 555 Create a file 'startok' once run is safely underway, as a signal to user process.
//     Start execution by removing any previously existing 'startok'.


// 222 Use of popen(), pclose() requires this definition
#define _XOPEN_SOURCE 500
// 222 Use of popen(), pclose() requires this definition


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
  int k;
  FILE * filmca;
  FILE * fil;
  char * query;

  char filename[64];
  unsigned int RunType, SyncT, ReqRunTime, PollTime, WR_RTCtrl, AllowStop;
  unsigned int SL[NCHANNELS], CCSRA[NCHANNELS], PILEUPCTRL[NCHANNELS];
  float Tau[NCHANNELS], Dgain[NCHANNELS];
  unsigned int BLavg[NCHANNELS], BLcut[NCHANNELS], Binfactor[NCHANNELS];
  unsigned int TL[NCHANNELS], TRACEENA[NCHANNELS]; 
  unsigned int GoodChanMASK[N_K7_FPGAS] = {0} ;
  double C0[NCHANNELS], C1[NCHANNELS], Cg[NCHANNELS];
  double baseline[NCHANNELS] = {0};
  double dt, ph, elm, q, tmpD, bscale;
  time_t starttime, currenttime;
  unsigned int w0, w1, tmp0, tmp1, tmp2, cfdout1, cfdout2, cfdsrc, cfdfrc, cfd; 
  unsigned long long WR_tm_tai_start, tmp_ll;
  unsigned int hdr[32];
  unsigned int out0, out2, out3, pileup, exttsL, exttsH, hdrids, passpileup, passTTCL;
  unsigned int evstats, udpok, R1, timeL, timeH, hit;
  unsigned int lsum, tsum, gsum, wsum, energy, energyF, bin, over; 
  unsigned int mca[NCHANNELS][MAX_MCA_BINS] ={{0}};    // full MCA for end of run
  unsigned int wmca[NCHANNELS][WEB_MCA_BINS] ={{0}};    // smaller MCA during run
  unsigned int wf[MAX_TL/2];    // two 16bit values per word
  unsigned int onlinebin, loopcount, eventcount, NumPrevTraceBlks, TraceBlks, eventcount_ch[NCHANNELS];
  unsigned int MCA0counts, MCA1counts;
  unsigned short buffer1[FILE_HEAD_LENGTH_400] = {0};
  unsigned char buffer2[CHAN_HEAD_LENGTH_400*2] = {0};
  unsigned int wm = WATERMARK;
  unsigned int BLbad[NCHANNELS];
  onlinebin=MAX_MCA_BINS/WEB_MCA_BINS;

  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
  unsigned int revsn, NCHANNELS_PER_K7, NCHANNELS_PRESENT;
  unsigned int ADC_CLK_MHZ, FILTER_CLOCK_MHZ; 
  int k7, ch_k7, ch, chw;  // ch = abs ch. no; ch_k7 = ch. no in k7
  unsigned int psa_base, psa_Q0, psa_Q1, psa_ampl, psa_R;
  
  int verbose = 1;      // TODO: control with argument to function 
  // 0 print errors and minimal info only
  // 1 print errors and full info
  int maxmsg = 10;    // number of events to report during processing
  if(!verbose) maxmsg = 0;
  int rejectcount =0;


   // *************** PS/PL IO initialization *********************
  // open the device for PD register I/O
  fd = open("/dev/uio0", O_RDWR);
  if (fd < 0) {
    perror("Failed to open devfile");
    return -2;
  }

  //Lock the PL address space so multiple programs cant step on each other.
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
  FILTER_CLOCK_MHZ  =  FILTER_CLOCK_MHZ_MOST;    // default

  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_75)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB01_75;             
      FILTER_CLOCK_MHZ  =  FILTER_CLOCK_MHZ_DB01;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_125)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB01_125;             
  } 
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB02;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_14_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB02;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB02;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_16_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB06_250;             
  } 
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_14_500)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB06_500;             
  } 
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB02;
  }
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB10_12_500)
  {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB10_500;             
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
  hdrids       = (CHAN_HEAD_LENGTH_100<<12) & 0xF000;
  hdrids       = hdrids + (fippiconfig.CRATE_ID<<8);
  hdrids       = hdrids + (fippiconfig.SLOT_ID<<4);
  AllowStop    = (fippiconfig.C_CONTROL & 0x1000)>0;

  if(AllowStop)
  {
     // 555
     system("rm -f ./startok");
     // 555
  }

  if( (RunType==0x100) || (RunType==0x105) || (RunType==0x110) || (RunType==0x111) || 
      (RunType==0x400) || (RunType==0x404) || (RunType==0x410) || (RunType==0x411) ) {      // check run type
      // 0x301 no longer supported because header memory is disabled for pure MCA runs, use mcadaq instead
         // runtype ok, do nothing
  } else {
      printf( "This function only supports runtypes 0x100 (P16), 0x105, 0x110, 0x111, 0x400, 0x404, 0x410, 0x411, not 0x%x \n",RunType);
      return(-1);
  }

  for(k7=0;k7<N_K7_FPGAS;k7++)  {
     for( ch_k7=0; ch_k7 < NCHANNELS_PER_K7; ch_k7++) {
         ch = ch_k7+k7*NCHANNELS_PER_K7;
         SL[ch]          = (int)floor(fippiconfig.ENERGY_RISETIME[ch]*FILTER_CLOCK_MHZ);       // multiply time in us *  # ticks per us = time in ticks
   //    SG[ch]          = (int)floor(fippiconfig.ENERGY_FLATTOP[ch]*FILTER_CLOCK_MHZ);        // multiply time in us *  # ticks per us = time in ticks
         Dgain[ch]       = fippiconfig.DIG_GAIN[ch];
         TL[ch]          = MULT_TL*(int)floor(fippiconfig.TRACE_LENGTH[ch]*ADC_CLK_MHZ/MULT_TL);
         Binfactor[ch]   = fippiconfig.BINFACTOR[ch];
         Tau[ch]         = fippiconfig.TAU[ch];
         BLcut[ch]       = fippiconfig.BLCUT[ch];
         BLavg[ch]       = 65536 - fippiconfig.BLAVG[ch];
         if(BLavg[ch]<0)          BLavg[ch] = 0;
         if(BLavg[ch]==65536)     BLavg[ch] = 0;
         if(BLavg[ch]>MAX_BLAVG)  BLavg[ch] = MAX_BLAVG;
         BLbad[ch] = MAX_BADBL;   // initialize to indicate no good BL found yet
         CCSRA[ch]       =  fippiconfig.CHANNEL_CSRA[ch]; 
         TRACEENA[ch]    = (( CCSRA[ch] & (1<<CCSRA_TRACEENA)) >0) && (RunType!=0x301) && (RunType!=0x401); 
         PILEUPCTRL[ch] =  ( CCSRA[ch] & (1<<CCSRA_PILEUPCTRL) ) >0;   // if bit set, only allow "single" non-piledup events
         //Emin[ch]  = fippiconfig.EMIN[ch];  
         if( (CCSRA[ch] & (1<<CCSRA_GOOD)) >0 )
            GoodChanMASK[k7] = GoodChanMASK[k7] + (1<<ch_k7) ;   // build good channel mask
     }   // end for channels
  }      // end for FPGAs


  // --------------------------------------------------------
  // ------------------- Main code begins --------------------
  // --------------------------------------------------------


  // **********************  Compute Coefficients for E Computation  ********************** 
  dt = 1.0/FILTER_CLOCK_MHZ;
  for( k = 0; k < NCHANNELS_PRESENT; k ++ )
  { 
      q = exp(-1.0*dt/Tau[k]);
      elm = exp(-1.0*dt*SL[k]/Tau[k]);
      C0[k] = (q-1.0)*elm/(1.0-elm);
      Cg[k] = 1.0-q;
      C1[k] = (1.0-q)/(1.0-elm);
     // printf("E coefs ch %d:  %f  %f   %f\n", k, C0[k], Cg[k], C1[k]);    
 
      C0[k] = C0[k] * Dgain[k];
      Cg[k] = Cg[k] * Dgain[k];
      C1[k] = C1[k] * Dgain[k];
  }


  // ********************** Run Start **********************

  NumPrevTraceBlks = 0;
  loopcount  = 0;
  eventcount = 0;
  MCA0counts = 0;
  MCA1counts = 0;
  for( ch=0; ch < NCHANNELS; ch++) eventcount_ch[ch] = 0;
  starttime = time(NULL);                         // capture OS start time

   // prepare LM files
   
   if( (RunType==0x100) || (RunType==0x105) ){
     // write a 0x100 header  -- actually there is no header, just events
     sprintf(filename, "LMdata%d.bin", fippiconfig.MODULE_ID);
     fil = fopen(filename,"wb");
   }  
     
   if(RunType==0x400){
     // write a 0x400 header
     // this is limited to the first 4 channels for now
     // fwrite is slow so we will write to a buffer, and then to the file.
     sprintf(filename, "LMdata%d.b00", fippiconfig.MODULE_ID);
     fil = fopen(filename,"wb");
     buffer1[0] = BLOCKSIZE_400;
     buffer1[1] = 0;                                       // module number (get from settings file?)
     buffer1[2] = RunType;
     buffer1[3] = CHAN_HEAD_LENGTH_400;
     buffer1[4] = 0xFFFF;                                // legact coincidence pattern
     buffer1[5] = fippiconfig.FASTTRIG_BACKLEN[0]*2;     // use ch.0's FASTTRIG_BACKLEN as CW
     buffer1[7] = revsn>>16;               // HW revision from EEPROM
     buffer1[12] = revsn & 0xFFFF;         // serial number from EEPROM
     for( ch = 0; ch < NCHANNEL_MAX400; ch++) {         // TODO: Runtype 0x400 records all channels as 0-3 (using lowest 2 bits), but tracelength in header is from ch.0-3)
         buffer1[6]   +=(int)floor((TL[ch]*TRACEENA[ch] + CHAN_HEAD_LENGTH_400) / BLOCKSIZE_400);         // combined event length, in blocks
         buffer1[8+ch] =(int)floor((TL[ch]*TRACEENA[ch] + CHAN_HEAD_LENGTH_400) / BLOCKSIZE_400);			// each channel's event length, in blocks
       //  printf( "N blocks %d \n",(int)floor((TL[ch]*TRACEENA[ch] + CHAN_HEAD_LENGTH_400) / BLOCKSIZE_400));
     }
     fwrite( buffer1, 2, FILE_HEAD_LENGTH_400, fil );     // write to file
   }  
   
  /*
   if(RunType==0x401){
      // write a 0x401 header
      sprintf(filename,"%s_m%d.dt3","LMdata",fippiconfig.MODULE_ID); //file name: .dt3
      fil = fopen(filename, "w"); // create .dt3 file
      fprintf(fil, "\nModule:\t%hu\n",         fippiconfig.MODULE_ID);
      fprintf(fil, "Run Type:\t%hu\n",         0x401);
      fprintf(fil, "Run Start Time :\t %lld \n\n", (long long)starttime);
      fprintf(fil, "Event\tChannel\tTimeStamp\tEnergy\tRT\tApeak\tBsum\tQ0\tQ1\tPSAval\n");
   }
   */
   // currently no local output file for 0x110, 0x111, 0x410, 0x411


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

  // disable MCA fifo output when not needed 
  mapped[AMZ_DEVICESEL] = CS_MZ;	// select MZ
  if( (fippiconfig.DATA_FLOW == 4) || (fippiconfig.DATA_FLOW == 5))  
      mapped[AMZ_RUNCTRL] = 0x0008;    // MCA FIFO enabled 
  else
      mapped[AMZ_RUNCTRL] = 0x0000;    // MCA FIFO disabled
  // TODO: FIFO full check stops DAQ in DF=4 for 1G?
//   printf( "  Debug: MMFIFOFULL ignored\n");
 
  // finally, start run
  mapped[AMZ_CSRIN] = 0x0001;      // RunEnable=1 > nLive=0 (DAQ on)
  // this is a bit in a MZ register tied to a line to both FPGAs
  // falling edge of nLive clears counters and memory address pointers
  // line ignored for WR_RTCtrl in K7, but still useful for TotalTime in MZ  

  
  /* DATA_FLOW options
     DATA_FLOW 0,1 control BL reads: // full BL read (DATA_FLOW==0) or combined BL read  (DATA_FLOW==1)
     DATA_FLOW >=2 always use FPGA's energy 
     DATA_FLOW 0-2  save LM data to local file and use LM E to increment MCA
     DATA_FLOW 3 controls LM data transfer to UDP and uses LM energy to increment MCA
     DATA_FLOW 4 lets FPA transfer LM data automaticallt and uses MCA FIFO energy to increment MCA

     FPGA output data comes from          which is advanced by
        LM header memory                   0-2: read AK7_HDRMEM_D to advance           3: 1 read from AK7_HDRMEM_D, rest by UDP   4: UDP process advances read point
                                                                                           (read 5 AK7_HDRMEM_D if piled up)

        LM trace memory address            0-2: read AK7_SKIPTRACE to loads new addr   3: UDP process loads new address           4: UDP process loads new address 
                                                                                          (read AK7_SKIPTRACE if piled up)

        LM trace memory                    0-2: read AK7_TRCMEM_B to advance           3: UDP process advances read point         4: UDP process advances read point

        E FIFO for MCA                     0-2: read AK7_NEXTEVENT to advance          3: UDP process advances read point         4: UDP process advances read point
                                               (FIFO never read, full flag ignored)      (FIFO never read, full flag ignored)        SW reads AMZ_RDMCA0 
  */

    if(AllowStop)
    {
      // 444 Remove 'donesignal'
      system("rm -f ./donesignal");
      // 444
      // 555
      system("touch ./startok");
      // 555
    }


  // ********************** Run Loop **********************
  do {

    
     //----------- Periodically read BL and update average -----------
     // legacy code: this has been moved into the FPGA and DF<2 is not really supported any more
     if(fippiconfig.DATA_FLOW<2) {   // full BL read (DATA_FLOW==0) or combined BL read  (DATA_FLOW==1)
        if((loopcount % BLREADPERIOD == 0) || (loopcount ==0) ) {     // sometimes 0 mod N not zero and first few events have wrong E? watch
           for(k7=0;k7<N_K7_FPGAS;k7++)
           {
              mapped[AMZ_DEVICESEL] =  cs[k7];	            // select FPGA 
     
              for( ch_k7=0; ch_k7 < NCHANNELS_PER_K7; ch_k7++) {
   
                 ch = ch_k7+k7*NCHANNELS_PER_K7;
   
                 if( (GoodChanMASK[k7] & (1<<ch_k7)) >0 ) {
                  
                    // read raw BL sums 
                    mapped[AMZ_EXAFWR] = AK7_PAGE;     // specify   K7's addr     addr 3 = channel/system
                    mapped[AMZ_EXDWR]  = PAGE_CHN+ch_k7;      //                         0x10n  = channel n     -> now addressing channel ch page of K7-0
         
                    mapped[AMZ_EXAFRD] = AK7_BLLOCK;    // read from 0xD4 to lock BL registers (no data)
                    tmp0 = mapped[AMZ_EXDRD];
         
                    if(fippiconfig.DATA_FLOW==0) {       // full BL read
                       mapped[AMZ_EXAFRD] = AK7_BLSTART+0;        // lsum low 16 bit
                       tmp0 =  mapped[AMZ_EXDRD];
                       if(SLOWREAD)  tmp0 =  mapped[AMZ_EXDRD];
                       mapped[AMZ_EXAFRD] = AK7_BLSTART+1;        // lsum high 16 bit
                       tmp1 =  mapped[AMZ_EXDRD];
                       if(SLOWREAD) tmp1 =  mapped[AMZ_EXDRD];
                       lsum = tmp0 + (tmp1<<16); 
            
                       mapped[AMZ_EXAFRD] = AK7_BLSTART+2;        // tsum low 16 bit
                       tmp0 =  mapped[AMZ_EXDRD];
                       if(SLOWREAD)  tmp0 =  mapped[AMZ_EXDRD];
                       mapped[AMZ_EXAFRD] = AK7_BLSTART+3;        // tsum high 16 bit
                       tmp1 =  mapped[AMZ_EXDRD];
                       if(SLOWREAD) tmp1 =  mapped[AMZ_EXDRD];
                       tsum = tmp0 + (tmp1<<16); 
            
                       mapped[AMZ_EXAFRD] = AK7_BLSTART+6;        // gsum low 16 bit
                       tmp0 =  mapped[AMZ_EXDRD];
                       if(SLOWREAD)  tmp0 =  mapped[AMZ_EXDRD];
                       mapped[AMZ_EXAFRD] = AK7_BLSTART+7;        // gsum high 16 bit, unlock
                       tmp1 =  mapped[AMZ_EXDRD];
                       if(SLOWREAD) tmp1 =  mapped[AMZ_EXDRD];
                       gsum = tmp0 + (tmp1<<16); 
   
                       ph = C1[ch]*lsum+Cg[ch]*gsum+C0[ch]*tsum; 
                       if (tsum>0 && ((tsum&0x80000000)==0) )		// tum=0 or high bit set indicates bad baseline
                       {
                          if( (BLcut[ch]==0) || (abs(ph-baseline[ch])<BLcut[ch]) || (BLbad[ch] >=MAX_BADBL) )       // only accept "good" baselines < BLcut, or if too many bad in a row (to start over)
                          {
                             if( (BLavg[ch]==0) || (BLbad[ch] >=MAX_BADBL) )
                             {
                                baseline[ch] = ph;
                                BLbad[ch] = 0;
                             } else {
                                // BL average: // avg = old avg + (new meas - old avg)/2^BLavg
                                baseline[ch] = baseline[ch] + (ph-baseline[ch])/(1<<BLavg[ch]);
                                BLbad[ch] = 0;                                
                             } // end BL avg
                          } else {
                             BLbad[ch] = BLbad[ch]+1;
                          }     // end BLcut check                                     
                       }       // end tsum >0 check
                    } // end DATA_FLOW==0 
                    else 
                    {   // BL average read, DATA_FLOW==1

                        mapped[AMZ_EXAFRD] = AK7_BLSTART+4;        // BL average low 16 bit
                        tmp0 =  mapped[AMZ_EXDRD];
                        if(SLOWREAD)  tmp0 =  mapped[AMZ_EXDRD];
                        mapped[AMZ_EXAFRD] = AK7_BLSTART+5;        // BL average high 16 bit
                        tmp1 =  mapped[AMZ_EXDRD];
                        if(SLOWREAD) tmp1 =  mapped[AMZ_EXDRD];
                        wsum = tmp0 + (tmp1<<16);      
                        
                        mapped[AMZ_EXAFRD] = AK7_BLSTART+7;        // gsum high 16 bit, unlock
                        tmp1 =  mapped[AMZ_EXDRD];
   
                        ph = (double)wsum;
                        baseline[ch] = ph;
                        if(eventcount<maxmsg) printf( "BL avg FPGA: 0x%x \n", wsum );
                    }     // end DATA_FLOW 0/1
                 }        // end if good channel
              }          // end for channels
           }             // end for K7s
        }             // end periodicity check
     } // end legacy code (DATA_FLOW<2) 
         
      
     // -----------poll for events -----------
     // if data ready. read out, compute E, increment MCA *********
      
     for(k7=0;k7<N_K7_FPGAS;k7++)
     {
          
        // .................................... event readout DATA_FLOW=4  .................................
        // DATA_FLOW == 4 : K7 streams UDP data to Ethernet automatically and MCA data to a FIFO in MZ
        if(fippiconfig.DATA_FLOW == 4)
        {
           // read MCA FIFOs
           mapped[AMZ_DEVICESEL] = CS_MZ;	// select MZ
           tmp2 = mapped[AMZ_CSROUTL];

           // for Kintex #0
           if ( (tmp2 & 0x00000080)>0 )  // check MCAdataready bit
           {
              
              if(MCA0counts==0) tmp0 = mapped[AMZ_RDMCA0]; // dummy read
              tmp0 = mapped[AMZ_RDMCA0+1];      // channel and other info
              tmp1 = mapped[AMZ_RDMCA0];        // energy  and advance FIFO
              ch       = (tmp0 & 0x7);          // + NCHANNELS_PER_K7*((tmp0 & 0x8) >> 3);   // 3 bits for channel number, bit 4 is K7 ID
              energy   = tmp1 & 0xFFFE;
              over     = (tmp0 & 0x10) > 0;     // negative or overflow
              pileup   = (tmp0 & 0x20) > 0;     // pileup
              passTTCL = (tmp0 & 0x80) == 0;    // pass if (no VETO) OR (TTCL ok)
              if(eventcount<maxmsg) printf( "K7#0: CSR: 0x%x MCA FIFO: ch %d, E %d (0x %x %x)\n", tmp2, ch, energy, tmp0, tmp1 );                

              if( (PILEUPCTRL[ch]==0)     || (PILEUPCTRL[ch]==1 && !pileup )    )  // this pileup check is probably redundant, also applied in FPGA 
              {
                 if(passTTCL)  // only bin events that are acceptable  (also redundant)
                 {
                    bin = energy >> Binfactor[ch];
                    if( (bin<MAX_MCA_BINS) && (over==0) ) {
                       mca[ch][bin] =  mca[ch][bin] + 1;	// increment mca
                       bin = bin >> WEB_LOGEBIN;
                       if(bin>0) wmca[ch][bin] = wmca[ch][bin] + 1;	// increment wmca
                       if(eventcount<maxmsg) printf( "  event binned into MCA (pileup %d, valid %d) \n", pileup, passTTCL);
                    } 
                 }
                 else
                 {
                    if(eventcount<maxmsg) printf( "  event rejected from histogramming (valid %d) \n", passTTCL);
                 }
              }
              else
              {
                 if(eventcount<maxmsg) printf( "  event rejected from histogramming (pileup %d, valid %d) \n", pileup, passTTCL);
              }
             
             
              MCA0counts++;
              eventcount++;    
              eventcount_ch[ch]++;
           }

           // for Kintex #1
           tmp2 = mapped[AMZ_CSROUTL];
           if ( (tmp2 & 0x00000100)>0 )  // check MCAdataready bit
           {
           
              if(MCA1counts==0) tmp0 = mapped[AMZ_RDMCA1]; // dummy read
              tmp0 = mapped[AMZ_RDMCA1+1];                  // channel and other info
              tmp1 = mapped[AMZ_RDMCA1];                    // energy  and advance FIFO
              ch       = (tmp0 & 0x7) + NCHANNELS_PER_K7;   //*((tmp0 & 0x8) >> 3);   // 3 bits for channel number, bit 4 is K7 ID
              energy = tmp1 & 0xFFFE;
              over     = (tmp0 & 0x10) > 0;                 // negative or overflow
              pileup   = (tmp0 & 0x20) > 0;                 // pileup
              passTTCL = (tmp0 & 0x80) == 0;                // VETO OR !TTCL
              if(eventcount<maxmsg) printf( "K7#1: CSR: 0x%x MCA FIFO: ch %d, E %d (0x %x %x)\n", tmp2, ch, energy, tmp0, tmp1 );

              if( (PILEUPCTRL[ch]==0)     || (PILEUPCTRL[ch]==1 && !pileup )    )  // this pileup check is probably redundant, also in FPGA 
              {
                 if(passTTCL)  // only bin events that are acceptable
                 {
                    bin = energy >> Binfactor[ch];
                    if( (bin<MAX_MCA_BINS) && (over==0) ) {
                       mca[ch][bin] =  mca[ch][bin] + 1;	// increment mca
                       bin = bin >> WEB_LOGEBIN;
                       if(bin>0) wmca[ch][bin] = wmca[ch][bin] + 1;	// increment wmca
                       if(eventcount<maxmsg) printf( "  event binned into MCA (pileup %d, valid %d) \n", pileup, passTTCL);
                    } 
                 }
                 else
                 {
                    if(eventcount<maxmsg) printf( "  event rejected from histogramming (valid %d) \n", passTTCL);
                 }
              }
              else
              {
                 if(eventcount<maxmsg) printf( "  event rejected from histogramming (pileup %d, valid %d) \n", pileup, passTTCL);
              }
             
              MCA1counts++;
              eventcount++;    
              eventcount_ch[ch]++;
           }

           // todo: checking both FPGAs in each loop. Can move DF=4 outside the k7 loop. 

        }  // end DATA_FLOW==4

         // .................................... event readout DATA_FLOW<4  .................................
        else 
        { 
           // Non-AutoUDP: ARM needs to poll K7 if data ready
           // then, if UDP (DATA_FLOW=3), give command to send out data to Ethernet, adding a CFD value
           //       if not UDP (DATA_FLOW<3), read all data and store locally (slow)
           // energy can be computed by ARM from raw sums or by FPGA 

           mapped[AMZ_DEVICESEL] =  cs[k7];	         // select FPGA 
           mapped[AMZ_EXAFWR] = AK7_PAGE;            // specify   K7's addr     addr 3 = channel/system
           mapped[AMZ_EXDWR]  = PAGE_SYS;            //                         0x0  = system  page

           // check if UDP transfer is still ongoing
           if(fippiconfig.DATA_FLOW == 3)      
           {
              mapped[AMZ_EXAFRD] = AK7_CSROUT;     // read CSR
              tmp0 =  mapped[AMZ_EXDRD];    
              if(SLOWREAD)  tmp0 = mapped[AMZ_EXDRD]; 
              udpok = ((tmp0 & 0x0400)==0) ;       // check flag for DF in progress, must be zero
              if(eventcount<maxmsg && !udpok) printf( "K7 %d: DF busy: CSR = 0x%x, test=0x%x \n", k7, tmp0,(tmp0 & 0x0400) );
           } else {     
              udpok = 1;
           }
   

           // Read Header DPM status
           mapped[AMZ_EXAFRD] = AK7_SYSSYTATUS;      // write to  k7's addr for read -> reading from 0x85 system status register
           evstats = mapped[AMZ_EXDRD];              // bits set for every channel that has data in header memory
           if(SLOWREAD)  evstats = mapped[AMZ_EXDRD];   
           evstats = evstats & GoodChanMASK[k7];     // mask non-good channels
      
           // event readout compatible with P16 DSP code
           // very slow and inefficient; can improve or better bypass completely in final WR data out implementation
           if(evstats && udpok)     // if there are events in any [good] channel
           {                    
              if(eventcount+rejectcount<maxmsg) printf( "\nK7 %d read from AK7_SYSSYTATUS (0x85), masked for good channels: 0x%X\n",k7, evstats );

              for( ch_k7=0; ch_k7 < NCHANNELS_PER_K7; ch_k7++)
              {

                 ch = ch_k7+k7*NCHANNELS_PER_K7;              // total channel count
                 R1 = 1 << ch_k7;
                 if(evstats & R1)		                        //  if there is an event in the header memory for this channel
                 {
                    mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr     addr 3 = channel/system
                    mapped[AMZ_EXDWR]  = PAGE_CHN+ch_k7;   //                         0x10n  = channel n     -> now addressing channel ch page of K7-0
                         
                    // read 1 64bit word from header (CFD data requiring division, pileup info etc)
                    // by now,  E is computed in FPGA and is only calculated here in non-UDP mode 
                    k=0;
                    mapped[AMZ_EXAFRD] = AK7_HDRMEM_A;   // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                    hdr[4*k+3] = mapped[AMZ_EXDRD];      // read 16 bits
                    if(SLOWREAD)  hdr[4*k+3] = mapped[AMZ_EXDRD];      // read 16 bits
                    mapped[AMZ_EXAFRD] = AK7_HDRMEM_B;   // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                    hdr[4*k+2] = mapped[AMZ_EXDRD];      // read 16 bits
                    if(SLOWREAD)  hdr[4*k+2] = mapped[AMZ_EXDRD];      // read 16 bits
                    mapped[AMZ_EXAFRD] = AK7_HDRMEM_C;   // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                    hdr[4*k+1] = mapped[AMZ_EXDRD];      // read 16 bits
                    if(SLOWREAD)  hdr[4*k+1] = mapped[AMZ_EXDRD];      // read 16 bits
                    if(fippiconfig.DATA_FLOW < 3)     // avoid conflict in advancing header pointers in DF=3
                    {
                        mapped[AMZ_EXAFRD] = AK7_HDRMEM_D;   // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                        hdr[4*k+0] = mapped[AMZ_EXDRD];      // read 16 bits
                        if(SLOWREAD)   hdr[4*k+0] = mapped[AMZ_EXDRD];      // read 16 bits
                    }
                    // the next 5 words only need to be read if storing data locally 
                    if(eventcount+rejectcount<maxmsg)  printf( " Ch. %d: Event count [ch] %d, total %d, rejected %d\n",ch, eventcount_ch[ch],eventcount,rejectcount );
                    if(eventcount+rejectcount<maxmsg)  printf( " Read 0 H-L: 0x %X %X %X %X\n",hdr[ 3], hdr[ 2], hdr[ 1], hdr[ 0] );
                 

                    // extract pileup and accept bits   
                    if(fippiconfig.DATA_FLOW < 3) {
                        pileup  = (hdr[0] & 0x0008) >0;
                        passTTCL= (hdr[0] & 0x1000) >0;
                    } else {
                        pileup  = (hdr[2] & 0x0100) >0;                                               
                        if( RunType>0x400) 
                           passTTCL = 1;    // TODO: run types with "long headers" do not report the Valid flag in hdr[1-3] and hdr[0] is not read in DF=3
                        else
                           passTTCL= (hdr[2] & 0x0200) >0;
                    }
                    passpileup = (PILEUPCTRL[ch]==0)     || (PILEUPCTRL[ch]==1 && !pileup ); // either don't care  OR pilup test required and  pileup flag not set
                    // if(eeventcount+rejectcount<maxmsg) printf( "ch. %d, cfdout1 %d, cfdout2 %d, cfdsrc %d, cfdfrc %d ",ch,cfdout1,cfdout2,cfdsrc,cfdfrc);
                    if(eventcount+rejectcount<maxmsg) printf( " Ch. %d, passpileup %d, passTTCL %d \n",ch,passpileup,passTTCL);
       
                    if(passpileup & passTTCL)
                    {   
                       //printf( " pileup test passed, start computing E\n");      
           
                       // cfd needs some more computation
                       cfdout1 =  hdr[0]     + ((hdr[1]&0xFF) <<16);
                       cfdout2 = ((hdr[1]&0xFF00)>>8) + (hdr[2]<<8);          // TODO: was <<16?
                       cfdsrc  = (hdr[3]>>1)&0x1;            // cfd source (sample in group for >125 MHz ADCs)
                       cfdfrc  = (hdr[3]>>2)&0x1;            // cfd forced if 1

                       cfdout1 =  (hdr[3]&0xFFFC)     + ((hdr[2]&0xFF) <<16);
                       cfdout2 = ((hdr[1]&0xFC00)>>8) + ( hdr[1]        <<8);          // TODO: was <<16?
                       cfdsrc  = (hdr[3]&0x0001)>0;            // cfd source (sample in group for >125 MHz ADCs)
                       cfdfrc  = (hdr[3]&0x0002)>0;            // cfd forced if 1
                       // TODO: different bits for DF=3

                       cfdout2 = 0x1000000 - cfdout2;        // convert to positive
                       ph = (double)cfdout1 / ( (double)cfdout1 + (double)cfdout2 );              
                       //printf(", frac %f \n ",ph); 
                       if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250) | 
                           ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250) |
                           ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_16_250) | 
                           ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250) )   {
                          cfd = (int)floor(ph*16384); 
                          cfd = (cfd&0x3FFF);                  // combine cfd value and bits
                          cfd = cfd + (cfdsrc<<14);         
                          cfd = cfd + (cfdfrc<<15);
                       } else {
                          cfd = (int)floor(ph*32768); 
                          cfd = (cfd&0x7FFF);                  // combine cfd value and bits
                          cfd = cfd + (cfdfrc<<15);
                       }     
                       // TODO: add CFD 500 MHz
             
                       // read FPGA E
                       mapped[AMZ_EXAFRD] = AK7_EFIFO;              // select the "EFIFO" address in channel's page
                       energyF = mapped[AMZ_EXDWR];                 // read 16 bits
                       if(SLOWREAD)  energyF = mapped[AMZ_EXDRD];   // read 16 bits
                       if(eventcount<maxmsg) printf(" Read FPGA E: %d\n",energyF ); 

                       // Advance E fifo AFTER read. But in DF=3, moving data to UDP already advances the E fifo, so it's not needed  
                       if(fippiconfig.DATA_FLOW < 3) {                     
                          mapped[AMZ_EXAFRD] = AK7_NEXTEVENT;              // select the "nextevent" address in channel's page
                          tmp0 = mapped[AMZ_EXDWR];                        // any read ok, advances E fifo 
                       }
                    
                       // at this point, key data of event is known. Now save to local or remote storage    

                       if(fippiconfig.DATA_FLOW == 3)             // Ethernet remote storage 
                       {
                                             
                          mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr:    PAGE register
                          mapped[AMZ_EXDWR]  = PAGE_SYS;         //  PAGE 0: system, page 0x10n = channel n
                     
                          mapped[AMZ_EXAFWR] =  AK7_ETH_CFD;     // specify   K7's addr:    cfd for Eth data packet
                          mapped[AMZ_EXDWR]  =  cfd;

                          w0 = 0;                 
                          // w0 = (1-passpileup) <<2;            // if not passing pilup, only read data from channel memory, but don't move into output FIFO 
                          // if( eventcount<50000) w0=8;         // debug: disable DF readout for some time
                          mapped[AMZ_EXAFWR] =  AK7_ETH_CTRL;    // specify   K7's addr:    Ethernet output control register  [4-bit ch# | 4-bit type of transfer | 8 bit Trace length in blocks ]
                                                                 // type of transfer: bit 3 pause UDP output (memory still is filled); bit 2 read event data but don't move into memory, bit 1 unused, bit 0 trace or no trace                               
                          mapped[AMZ_EXDWR]  =  (ch_k7<<12) + ((w0+TRACEENA[ch])<<8) + (TL[ch]>>5);  // This write starts the transfer to memory, then UDP 
                          
                        //  if(passpileup)  
                        //  {
                              if(eventcount<maxmsg)  printf( " issued command to send UDP package\n");
                         /* }
                          else
                          {
                          if (rejectcount <maxmsg)
                           {
                             printf( " issued command to advance pointers for piled up event w0=0x%x, passpileup=%d \n",w0,passpileup );
                             printf( " Ch. %d: Event count [ch] %d, total %d\n",ch, eventcount_ch[ch],eventcount );
                             printf( " Read 0 H-L: 0x %X %X %X %X\n",hdr[ 3], hdr[ 2], hdr[ 1], hdr[ 0] );
                             rejectcount++;
                           }
                         }
                         */
                          energy = energyF & 0xFFFE;   // overwrite local E computation with FPGA result  (bit 0 is pileup)  for MCA binning below

                       } 
                       else  // local storage DATA_FLOW == 0,1,2
                       {
                          // read 5 more 64bit words from header (still in channel page)
                          for( k=0; k < 5; k++)
                          {
                             mapped[AMZ_EXAFRD] = AK7_HDRMEM_A;           // write to  k7's addr for read -> reading from AK7_HDRMEM_A channel header fifo, low 16bit
                             hdr[4*k+3] = mapped[AMZ_EXDRD];                  // read 16 bits
                             if(SLOWREAD)  hdr[4*k+3] = mapped[AMZ_EXDRD];    // read 16 bits
                             mapped[AMZ_EXAFRD] = AK7_HDRMEM_B;           // write to  k7's addr for read -> reading from AK7_HDRMEM_B channel header fifo, low 16bit
                             hdr[4*k+2] = mapped[AMZ_EXDRD];                  // read 16 bits
                             if(SLOWREAD)  hdr[4*k+2] = mapped[AMZ_EXDRD];    // read 16 bits
                             mapped[AMZ_EXAFRD] = AK7_HDRMEM_C;           // write to  k7's addr for read -> reading from AK7_HDRMEM_C channel header fifo, low 16bit
                             hdr[4*k+1] = mapped[AMZ_EXDRD];                  // read 16 bits
                             if(SLOWREAD)  hdr[4*k+1] = mapped[AMZ_EXDRD];    // read 16 bits
                             mapped[AMZ_EXAFRD] = AK7_HDRMEM_D;           // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                             hdr[4*k+0] = mapped[AMZ_EXDRD];                  // read 16 bits
                             if(SLOWREAD)  hdr[4*k+0] = mapped[AMZ_EXDRD];    // read 16 bits
                           }  // the next 8 64bit words only need to be read if reading QDC data

                          // waveform read (if accepted)
                          if(TRACEENA[ch]==1)  
                          {   

                             mapped[AMZ_EXAFRD] = AK7_SKIPTRACE;              // select the "skiptrace" address in channel's page
                             tmp0 = mapped[AMZ_EXDWR];                        // any read ok  -- advances read pointer to start of next trace 

                             for( k=0; k < (TL[ch]/4); k++)
                             {
                                mapped[AMZ_EXAFRD] = AK7_TRCMEM_A;     // write to  k7's addr for read -> reading from AK7_TRCMEM_A channel header memory, next 16bit
                                w0 = mapped[AMZ_EXDRD];      // read 16 bits
                                if(SLOWREAD)  w0 = mapped[AMZ_EXDRD];
                                mapped[AMZ_EXAFRD] = AK7_TRCMEM_B;     // write to  k7's addr for read -> reading from AK7_TRCMEM_B channel header memory, high 16bit and addr increase
                                w1 = mapped[AMZ_EXDRD];      // read 16 bits  , increments trace memory address
                                if(SLOWREAD) w1 = mapped[AMZ_EXDRD]; 
                                wf[2*k+0] = w0+(w1<<16);   // re-order 2 sample words from 32bit FIFO
      
                                mapped[AMZ_EXAFRD] = AK7_TRCMEM_C;     // write to  k7's addr for read -> reading from AK7_TRCMEM_A channel header memory, next 16bit
                                w0 = mapped[AMZ_EXDRD];      // read 16 bits
                                if(SLOWREAD)  w0 = mapped[AMZ_EXDRD];
                                mapped[AMZ_EXAFRD] = AK7_TRCMEM_D;     // write to  k7's addr for read -> reading from AK7_TRCMEM_B channel header memory, high 16bit and addr increase
                                w1 = mapped[AMZ_EXDRD];      // read 16 bits  , increments trace memory address
                                if(SLOWREAD) w1 = mapped[AMZ_EXDRD]; 
                                wf[2*k+1] = w0+(w1<<16);   // re-order 2 sample words from 32bit FIFO   

                             }  // end trace length   
                          }   // end if trace enabled

                          // if(eventcount<maxmsg) printf( " Read 1 H-L: 0x %X %X %X %X\n",hdr[ 3], hdr[ 2], hdr[ 1], hdr[ 0] );
                          // if(eventcount<maxmsg) printf( " Read 2 H-L: 0x %X %X %X %X\n",hdr[ 7], hdr[ 6], hdr[ 5], hdr[ 4] );
                          // if(eventcount<maxmsg) printf( " Read 3 H-L: 0x %X %X %X %X\n",hdr[11], hdr[10], hdr[ 9], hdr[ 8] );
                          // if(eventcount<maxmsg) printf( " Read 4 H-L: 0x %X %X %X %X\n",hdr[15], hdr[14], hdr[13], hdr[12] );
                          // if(eventcount<maxmsg) printf( " Read 5 H-L: 0x %X %X %X %X\n",hdr[19], hdr[18], hdr[17], hdr[16] );

                          // now assemble list mode data
                          timeL   =  hdr[2]     + (hdr[3]<<16);
                          timeH   =  hdr[4];
                          exttsL  =  hdr[16]    + (hdr[17]<<16);
                          exttsH  =  hdr[18];
                          tsum    =  hdr[8]     + (hdr[9]<<16);
                          lsum    =  hdr[10]    + (hdr[11]<<16);
                          gsum    =  hdr[12]    + (hdr[13]<<16);

                          //if(eventcount<maxmsg) printf( " tsum %d, lsum %d, gsum %d\n",tsum, lsum, gsum );  
                          //if(eventcount<maxmsg) printf( " timeL %d, timeH %d\n",timeL, timeH);  
                          //if(eventcount<maxmsg) printf( " BL avg: %f\n",baseline[ch] );
                          //if(eventcount<maxmsg) printf( " BL avg FPGA: 0x%x \n", wsum );

                          // compute and histogram E
                          ph = C1[ch]*(double)lsum+Cg[ch]*(double)gsum+C0[ch]*(double)tsum;
                          //if(eventcount<maxmsg) printf( " raw ph: %f\n",ph );
   
                          ph = (double)ph-baseline[ch];  // ph = ph-baseline[ch];
                          if ((ph<0.0)|| (ph>65536.0))	ph =0.0;	// out of range energies -> 0
                          energy = (int)floor(ph);
                          if(eventcount<maxmsg)  printf(" ch %d: Energy ph ARM %05d \n",ch, energy);

                          if(fippiconfig.DATA_FLOW == 2)  energy = energyF & 0xFFFE;   // overwrite local computation with FPGA result  (bit 0 is pileup)
                     
                          // compute PSA results from raw data  
                          // need to subtract baseline in correct scale (1/4) and length (QDC#_LENGTH[ch])
                          // printf( " Read PSA words (12-15): %d %d %d %d\n",hdr[12], hdr[13], hdr[14], hdr[15] );
                          psa_base = hdr[0];
                          if( fippiconfig.QDCLen4[ch]) 
                             bscale = 32.0;
                          else
                             bscale = 4.0;
                        
                          tmpD = (double)hdr[19] - (double)psa_base/bscale * fippiconfig.QDCLen0[ch]; //  subtract QDCL0 x base/bscale from raw value
                          if( (tmpD>0) && (tmpD<65535))
                             psa_Q0 = (int)floor(tmpD);
                          else
                             psa_Q0 = 0;
                        
                          tmpD = (double)hdr[5] - (double)psa_base/bscale * fippiconfig.QDCLen1[ch]; //  subtract QDCL1 x base/bscale from raw value
                          if( (tmpD>0) && (tmpD<65535))
                             psa_Q1 = (int)floor(tmpD);
                          else
                             psa_Q1 = 0;
                        
                          psa_ampl = hdr[6] - psa_base;
      
                          if(psa_Q0!=0)
                             psa_R = (int)floor(1000.0*(double)psa_Q1/(double)psa_Q0);
                          else
                             psa_R = 0;
   
                          // write event to LM data file 
                          if( (RunType==0x100)  || (RunType==0x105) )   
                          {   
                            /* if(RunType==0x104){     // or 0x110, 111
                                // extra 3 words for 0x104. Should normally not be used for writing to SD card, though 
                                buffer1[0] = P16_HDR_LEN*2+3;           // 0x100 style event header plus 3 extra words
                                buffer1[1] = revsn>>16;                 // HW revision from EEPROM
                                buffer1[2] = RunType;
                                fwrite( buffer1, 2, 3, fil );           // write to file
                             }  
                             */
                             // assemble the header words. For now, report always 10 32bit word headers (all except QDC)
                             out0  = hdrids + ch  + (hdr[1]<<16); // pileup, EL, HL, and crate/slot/channel #
                             out2  = timeH + (cfd<<16)   ;            // h[4]=timeH, h[5]=cfd placeholder
                             out3 = energy + (hdr[7]<<16);            // h[6]=energy placeholder, h[7] = flag and TL
                     
                             memcpy( buffer2 + 0,  &(out0),  4 );
                             memcpy( buffer2 + 4,  &(timeL), 4 );
                             memcpy( buffer2 + 8,  &(out2),  4 );
                             memcpy( buffer2 + 12, &(out3),  4 );
                             out2 = hdr[8];
                             memcpy( buffer2 + 16, &(out2),  2 );
                             out2 = hdr[9];
                             memcpy( buffer2 + 18, &(out2),  2 );
                             out2 = hdr[10];
                             memcpy( buffer2 + 20, &(out2),  2 );
                             out2 = hdr[11];
                             memcpy( buffer2 + 22, &(out2),  2 );
                             out2 = hdr[12];
                             memcpy( buffer2 + 24, &(out2),  2 );
                             out2 = hdr[13];
                             memcpy( buffer2 + 26, &(out2),  2 );
                             out2 = hdr[14];
                             memcpy( buffer2 + 28, &(out2),  2 );
                             out2 = hdr[15];
                             memcpy( buffer2 + 30, &(out2),  2 );     
                             //memcpy( buffer2 + 16, &(tsum),  4 );
                             //memcpy( buffer2 + 20, &(lsum),  4 );   
                             //memcpy( buffer2 + 24, &(gsum),  4 );
                             //memcpy( buffer2 + 28, &(out7),  4 );      // BL      
                             memcpy( buffer2 + 32, &(exttsL), 4 );      // ext TS
                             memcpy( buffer2 + 36, &(exttsH), 4 );      // ext TS
                             fwrite( buffer2, 1, CHAN_HEAD_LENGTH_100*4, fil );
                
                             if( TRACEENA[ch] )  {   // previously checked if TL >0 and traces are recorded (bit 8 of CCSRA)                          
                                fwrite( wf, TL[ch]/2, 4, fil );                        
                             }   // end trace write                   
                          }      // 0x100    
                          
      
                          if(RunType==0x400) // && ch<NCHANNEL_MAX400)   
                          {
                          // if( energy > Emin[ch]) {

                                out2 = hdr[0]    + (hdr[18]<<16);    // raw PSA for debug
                                out3 = hdr[5]    + (hdr[6]<<16);
                                chw = ch & 0x03;         // map channels into 0-3, assume only one set of 4 connected
                                hit = (1<<chw) + 0x20 + (0x100<<chw);
                                if(TRACEENA[ch])
                                    TraceBlks = (int)floor(TL[ch]/BLOCKSIZE_400);
                                else 
                                    TraceBlks = 0;
                                memcpy( buffer2 + 0, &(hit), 4 );
                                memcpy( buffer2 + 4, &(TraceBlks), 2 );
                                memcpy( buffer2 + 6, &(NumPrevTraceBlks), 2 ); 
                                memcpy( buffer2 + 8, &(timeL), 4 );
                                memcpy( buffer2 + 12, &(timeH), 4 );
                                memcpy( buffer2 + 16, &(energy), 2 );
                                memcpy( buffer2 + 18, &(chw), 2 );
                                memcpy( buffer2 + 20, &(psa_ampl), 2 );
                                memcpy( buffer2 + 22, &(cfd), 2 );   // actually cfd time
                                memcpy( buffer2 + 24, &(psa_base), 2 );
                                memcpy( buffer2 + 26, &(psa_Q0), 2 );
                                memcpy( buffer2 + 28, &(psa_Q1), 2 );
                                memcpy( buffer2 + 30, &(psa_R), 2 );  
                                memcpy( buffer2 + 32, &(out2), 2 );      // debug
                                memcpy( buffer2 + 34, &(out3), 2 );   
                                memcpy( buffer2 + 36, &(exttsL), 4 );      // debug
                                memcpy( buffer2 + 40, &(exttsH), 4 );   
                                // no checksum  for now
                                memcpy( buffer2 + 60, &(wm), 4 );
                                fwrite( buffer2, 1, CHAN_HEAD_LENGTH_400*2, fil );
                                NumPrevTraceBlks = TraceBlks;
         
                                if( TRACEENA[ch] )  {   // previously checked if TL >0 and traces are recorded (bit 8 of CCSRA)     
                                    fwrite( wf, TL[ch]/2, 4, fil );
                                }   // end trace write

                          // } //energy limit
                          }  // 0x400

                           if(RunType==0x401) // && ch<NCHANNEL_MAX400)   {
                          {
                          // ASCII file, no trace (like AutoPRocessLMData=3)
                             chw = ch & 0x03;         // map channels into 0-3, assume only one set of 4 connected
                             tmp_ll = (unsigned long long)timeL + TWOTO32* (unsigned long long)timeH;  // full timestamp 
                             // "Event\tChannel\tTimeStamp\tEnergy\tRT\tApeak\tBsum\tQ0\tQ1\tPSAval\n
                             fprintf(fil, "%u\t%hu\t%llu\t%hu\t%hu\t%hu\t%hu\t%hu\t%hu\t%hu\n", 
                                eventcount, 
                                chw,
                                tmp_ll>>1,     // full timestamp in 2ns units  
                                energy, 
                                0,             // no rise time
                                psa_ampl, 
                                psa_base,
                                psa_Q0,
                                psa_Q1,
                                psa_R       );
                          }    // 0x401      

                       } // end DATA_FLOW < 3

                       //  histogramming if E< max mcabin
                       bin = energy >> Binfactor[ch];
                       if( (bin<MAX_MCA_BINS) && (bin>0) ) {
                          mca[ch][bin] =  mca[ch][bin] + 1;	// increment mca
                          bin = bin >> WEB_LOGEBIN;
                          if(bin>0) wmca[ch][bin] = wmca[ch][bin] + 1;	// increment wmca
                       }
                     
                       eventcount++;    
                       eventcount_ch[ch]++;
                    }     // end good event processing

                    // .................................... bad events handling .................................
                    else  // event not acceptable (piled up)      
                    {  
                       rejectcount++;
                    
                       if(fippiconfig.DATA_FLOW == 3) {

                          //w0 = 0;  
                          if( !passpileup | !passTTCL)  w0 = 4; // if not passing pilup and TTCL, only read data from channel memory, but don't move into output FIFO 
                          //w0 = (1-passpileup) <<2;             // if not passing pilup, only read data from channel memory, but don't move into output FIFO 
                          // if( eventcount<50000) w0=8;         // debug: disable DF readout for some time
                          mapped[AMZ_EXAFWR] =  AK7_ETH_CTRL;    // specify   K7's addr:    Ethernet output control register  [4-bit ch# | 4-bit type of transfer | 8 bit Trace length in blocks ]
                                                                 // type of transfer: bit 3 pause UDP output (memory still is filled); bit 2 read event data but don't move into memory, bit 1 unused, bit 0 trace or no trace                               
                          mapped[AMZ_EXDWR]  =  (ch_k7<<12) + ((w0+TRACEENA[ch])<<8) + (TL[ch]>>5);  // This write starts the UDP transfer 

                          if (rejectcount <maxmsg) printf( " Advancing pointers for rejected event passpileup=%d, passTTCL=%d \n",passpileup,passTTCL );

                       }    // end DF=3
                       else
                       {     
                          // read FPGA E
                          mapped[AMZ_EXAFRD] = AK7_EFIFO;              // select the "EFIFO" address in channel's page
                          energyF = mapped[AMZ_EXDWR];                 // read 16 bits
                          mapped[AMZ_EXAFRD] = AK7_NEXTEVENT;          // select the "nextevent" address in channel's page
                          tmp0 = mapped[AMZ_EXDWR];                    // any read ok, advances E fifo 

                          // advance header memory by 5 x4 words
                          for( k=0; k < 5; k++)
                          {  
                             mapped[AMZ_EXAFRD] = AK7_HDRMEM_D;     // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                             hdr[k] = mapped[AMZ_EXDRD];      // read 16 bits, no double read required
                             // the next 8 words only need to be read if reading QDC data
                          }
   
                          //  now also advance trace memory address if traces are enabled 
                          if(TRACEENA[ch]==1)  { 
                              mapped[AMZ_EXAFRD] = AK7_SKIPTRACE;             // select the "skiptrace" address in channel's page
                              tmp0 = mapped[AMZ_EXDWR];     // any read ok
                          }  // end if trace enabled 

                          if (rejectcount <maxmsg) printf( " Advancing pointers for rejected event passpileup=%d, passTTCL=%d \n",passpileup,passTTCL );
                        
                       } // end DF<3

                    }  // end not acceptable    
                 }     // end event in this channel
              }        // end for ch
           }           // end event in any channel  
        } // end auto UDP
     }    // end for K7s



     // ----------- Periodically save MCA, PSA, and Run Statistics  -----------
       
     if(loopcount % PollTime == 0) 
     {
    
        // 1) Run Statistics 

        // for debug purposes, print to std out so we see what's going on
        mapped[AMZ_DEVICESEL] = CS_MZ;
        tmp0 = mapped[AMZ_RS_TT+1];   // address offset by 1?
        tmp1 = mapped[AMZ_RS_TT+2];
        if(verbose) printf("%s %4.5G \n","Total_Time",((double)tmp0*65536+(double)tmp1*TWOTO32)*1e-9);    
        // print (small) set of RS to file, visible to web
        //read_print_runstats_XL_2x4(1, 0, 1 mapped);      // print all, print to file, P4e statistics
        read_print_rates_XL_2x4(0,mapped);
   

        // 2) MCA
        filmca = fopen("MCA.csv","w");
        fprintf(filmca,"bin");
        for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",MCAch%d",ch);
        fprintf(filmca,"\n");
        for( k=0; k <WEB_MCA_BINS; k++)       // report the 4K spectra during the run (faster web update)
        {
           fprintf(filmca,"%d",k*onlinebin);                  // bin number
           for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",%d",wmca[ch][k]);    // print channel data
           fprintf(filmca,"\n");
        }
        fclose(filmca);    

     }

  	    // 222 Code to enable external STOP signal (presence of file 'donesignal')
       if(AllowStop)
       {
   	    char command[1000];
   	    sprintf(command,"ls donesignal 2> /dev/null | wc -l");
   	    FILE *fp;
   	    char processes[1035];
   	    fp = popen(command, "r");
   	    if (fp == NULL) {
   	      printf("\nCheckExecution failed to run popen command\n" );fflush(stdout);
   	      exit(1);
   	    }
   	    int nproc;
   	    while (fgets(processes, sizeof(processes)-1, fp) != NULL) {
   	      sscanf(processes,"%d",&nproc);
   	    }
   	    pclose(fp);	    
   	    if(nproc>0){
   	      system("rm -f donesignal");
   	      break; // presence of file 'donesignal' means run should finish
   	    }
       }
	    // 222 Code to enable external STOP signal      
        
     // ----------- loop housekeeping -----------

     loopcount ++;
     currenttime = time(NULL);
  } while (currenttime <= starttime+ReqRunTime); // run for a fixed time   
  // } while (eventcount <= 2100); // run for a fixed number of events   



  // ********************** Run Stop **********************

  // set nLive bit to stop run
  mapped[AMZ_DEVICESEL] = CS_MZ;	 // select MZ
  mapped[AMZ_CSRIN] = 0x0000; // all off       
  // todo: there may be events left in the buffers. need to stop, then keep reading until nothing left


  /* info and debug */

  if(WR_RTCtrl>0) WRrunstop(mapped, WR_RTCtrl );    // print out White Rabbit related info at end of run

  if(fippiconfig.DATA_FLOW<4) 
  {
     printf( "\nRun completed. Events transferred %d, rejected %d, total %d\n",eventcount,rejectcount, eventcount+rejectcount );
  } 
  else 
  {
     printf( "\nRun completed. Events histogramed %d\n",MCA0counts+MCA1counts);
     for(k7=0;k7<N_K7_FPGAS;k7++)
     { 
        mapped[AMZ_DEVICESEL] =  cs[k7];	         // select FPGA 
        mapped[AMZ_EXAFWR] = AK7_PAGE;             // specify   K7's addr     addr 3 = channel/system
        mapped[AMZ_EXDWR]  = PAGE_SYS;             //                         0x0  = system  page
         
        mapped[AMZ_EXAFRD] = AK7_MEM_OCNT;         // read memory output counter
        tmp0 =  mapped[AMZ_EXDRD]; 
        if(SLOWREAD)  tmp0 = mapped[AMZ_EXDRD]; 
         
        mapped[AMZ_EXAFRD] = AK7_MEM_OCNT+1;       // read memory output counter
        tmp1 =  mapped[AMZ_EXDRD]; 
        if(SLOWREAD)  tmp1 = mapped[AMZ_EXDRD]; 

        tmp_ll = tmp0 +  65536*tmp1;
        printf( "UDP events transmitted (port %d) %llu\n",k7, tmp_ll);
     }
  }

  // analyze MCAs for single peak FWHM. MCA base assumed to be 0 outside peak, peak min 50 high
  if(verbose)  MCAquickfit(NCHANNELS_PRESENT, &mca[0][0]);
       

  /* end info and debug */
  
                  
  // final save MCA and RS
  filmca = fopen("MCA.csv","w");
  fprintf(filmca,"bin");
  for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",MCAch%d",ch);
  fprintf(filmca,"\n");
  //fprintf(filmca,"bin,MCAch0,MCAch1,MCAch2,MCAch3,MCAch4,MCAch5,MCAch6,MCAch7\n");
  for( k=0; k <MAX_MCA_BINS; k++)
  {
     // fprintf(filmca,"%d,%u,%u,%u,%u\n ", k,mca[0][k],mca[1][k],mca[2][k],mca[3][k] );
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
  if( (RunType==0x100) || (RunType==0x105) ||  (RunType==0x400)  )  { 
     fclose(fil);
  }
  flock( fd, LOCK_UN );
  munmap(map_addr, size);
  close(fd);
  return 0;
}
