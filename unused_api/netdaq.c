/*----------------------------------------------------------------------
 * Copyright (c) 2019 XIA LLC
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


/*
 * NTS trigger/buffering output key:
 * . - received INIT while waiting for START
 * d - duplicate/overlap: accept range overlaps previously stored trigger
 * f - flush a stored trigger
 * i - insert trigger in used buffer slot
 * s - store trigger
 * u - unknown accept timestamp range
 * x - overwrite a sent but not-(yet)-accepted trigger
 * w - wrap next/back pointer
 * W - wrap start/front pointer
 */

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <limits.h>
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

#include "nts.h"
#include "log.h"

#define NTS_POLL_INTERVAL 1


int main(int argc, const char **argv) {
    int fd;
    void *map_addr;
    int size = 4096;
    volatile unsigned int *mapped;
    int ch, k;
    FILE * filmca;
    FILE * fil;

    // PN only
 //   int tmpS;
 //   unsigned int Accept, CW;
 //   double cfdlev, ph;
 //   unsigned int startTS, m, c0, c1, c2, c3, tmpI;
 //   unsigned int psa0, psa1, cfd0,  timeL, timeH;
 //   unsigned int cfdout, cfdlow, cfdhigh, cfdticks, cfdfrac, ts_max;
//    unsigned int binx, biny;
//    unsigned int mca2D[NCHANNELS][MCA2D_BINS*MCA2D_BINS] ={{0}};    // 2D MCA for end of run
//    unsigned int chaddr; 


    // PNXL only 
    char filename[64];
    unsigned int WR_RTCtrl;
    unsigned int CCSRA[NCHANNELS], PILEUPCTRL[NCHANNELS];
    unsigned int TRACEENA[NCHANNELS], Emin[NCHANNELS];
    unsigned int GoodChanMASK[N_K7_FPGAS] = {0} ;
    unsigned int tmp0, tmp1, tmp2, cfd; //cfdout1, cfdout2, cfdsrc, cfdfrc; //, tmp3;
    unsigned long long WR_tm_tai, WR_tm_tai_start, WR_tm_tai_stop, WR_tm_tai_next;
    unsigned int hdr[32];
 //   unsigned int out0, out2, out3, out7, pileup, exttsL, exttsH;
    unsigned int  hdrids, udpok;
    unsigned int  energyF; //, wsum, over; 
    unsigned int eventcount_ch[NCHANNELS];
    unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
    unsigned int NCHANNELS_PER_K7, NCHANNELS_PRESENT;
    unsigned int ADC_CLK_MHZ, FILTER_CLOCK_MHZ; //  SYSTEM_CLOCK_MHZ,
    int k7, ch_k7; //, chw;  // ch = abs ch. no; ch_k7 = ch. no in k7
    int verbose = 1;      // TODO: control with argument to function 
      // 0 print errors and minimal info only
      // 1 print errors and full info
    int maxmsg = 5;


    // common
    unsigned int RunType, SyncT, ReqRunTime, PollTime;
    unsigned int SL[NCHANNELS];
    //unsigned int SG[NCHANNELS];
    float Tau[NCHANNELS], Dgain[NCHANNELS];
 //   unsigned int BLavg[NCHANNELS], BLcut[NCHANNELS];
    unsigned int TL[NCHANNELS], Binfactor[NCHANNELS];
    double C0[NCHANNELS], C1[NCHANNELS], Cg[NCHANNELS];
  //  double baseline[NCHANNELS] = {0};
    double dt, elm, q;
 //   double tmpD, bscale;
    time_t starttime, currenttime;
 //   unsigned int w0, w1, hit;
    unsigned int revsn, evstats, R1, pileup, bin;
 //   unsigned int psa_base, psa_Q0, psa_Q1, psa_ampl, psa_R;
    unsigned int mca[NCHANNELS][MAX_MCA_BINS] ={{0}};    // full MCA for end of run
    unsigned int wmca[NCHANNELS][WEB_MCA_BINS] ={{0}};    // smaller MCA during run
 //   unsigned int wf[MAX_TL/2];    // two 16bit values per word
    unsigned int onlinebin, loopcount, eventcount;
 //   unsigned int NumPrevTraceBlks, TraceBlks;   
 //   unsigned short buffer1[FILE_HEAD_LENGTH_400] = {0};
 //   unsigned char buffer2[CHAN_HEAD_LENGTH_400*2] = {0};
 //   unsigned int wm = WATERMARK;
 //   unsigned int BLbad[NCHANNELS];
    onlinebin=MAX_MCA_BINS/WEB_MCA_BINS;

    // SW trig only
    const char *nts_host = "192.168.1.84";
    unsigned int nts_triggered = 0, nts_sent = 0, nts_received = 0;
    int nts_run = 1;
    NTS *nts;
    void *nts_event_data;
    int poll_result;

    if (argc > 1) {
        nts_host = argv[1];
    }

    printf("NTS host: %s\n", nts_host);

    // ******************* set up logging ******************
    if (pn_log_open("netdaq.log")) {
        printf("Failed to open log\n");
        return -1;
    }

    // *************** PS/PL IO initialization *********************
    // open the device for PD register I/O
    fd = open("/dev/uio0", O_RDWR);
    if (fd < 0) {
        perror("Failed to open devfile");
        return -2;
    }

    //Lock the PL address space so multiple programs cant step on eachother.
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
   if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250)
   {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB02;
      FILTER_CLOCK_MHZ  =  FILTER_CLOCK_MHZ_DB02;
   }
   if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_125)
   {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB01_125;             
      FILTER_CLOCK_MHZ  =  FILTER_CLOCK_MHZ_DB02;
   } 
   if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_75)
   {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB01_75;             
      FILTER_CLOCK_MHZ  =  FILTER_CLOCK_MHZ_DB01;
   }
   if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_16_250)
   {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      ADC_CLK_MHZ       =  ADC_CLK_MHZ_DB06_250;             
      FILTER_CLOCK_MHZ  =  FILTER_CLOCK_MHZ_DB06;
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
//    Accept       = fippiconfig.ACCEPT_PATTERN;
    RunType      = fippiconfig.RUN_TYPE;
    SyncT        = fippiconfig.SYNC_AT_START;
    ReqRunTime   = fippiconfig.REQ_RUNTIME;
    PollTime     = fippiconfig.POLL_TIME;
   // CW           = (int)floor(fippiconfig.COINCIDENCE_WINDOW*FILTER_CLOCK_MHZ);       // multiply time in us *  # ticks per us = time in ticks

    WR_RTCtrl    = fippiconfig.WR_RUNTIME_CTRL;
    hdrids       = (CHAN_HEAD_LENGTH_100<<12) & 0xF000;
    hdrids       = hdrids + (fippiconfig.CRATE_ID<<8);
    hdrids       = hdrids + (fippiconfig.SLOT_ID<<4);


     if( (RunType==0x100)  ) {      // check run type
      // 0x100 are ok
      // 0x301 no longer supported because header memory is disabled for pure MCA runs, use mcadaq instead
     } else {
         printf( "This function only supports runtypes 0x100 (P16) \n");
         return(-1);
     }


     for(k7=0;k7<N_K7_FPGAS;k7++)  {
        for( ch_k7=0; ch_k7 < NCHANNELS_PER_K7; ch_k7++) {
            ch = ch_k7+k7*NCHANNELS_PER_K7;
            SL[ch]          = (int)floor(fippiconfig.ENERGY_RISETIME[ch]*FILTER_CLOCK_MHZ);       // multiply time in us *  # ticks per us = time in ticks
      //    SG[ch]          = (int)floor(fippiconfig.ENERGY_FLATTOP[ch]*FILTER_CLOCK_MHZ);       // multiply time in us *  # ticks per us = time in ticks
            Dgain[ch]       = fippiconfig.DIG_GAIN[ch];
            TL[ch]          = MULT_TL*(int)floor(fippiconfig.TRACE_LENGTH[ch]*ADC_CLK_MHZ/MULT_TL);
            Binfactor[ch]   = fippiconfig.BINFACTOR[ch];
            Tau[ch]         = fippiconfig.TAU[ch];
     //       BLcut[ch]       = fippiconfig.BLCUT[ch];
     //       BLavg[ch]       = 65536 - fippiconfig.BLAVG[ch];
     //       if(BLavg[ch]<0)          BLavg[ch] = 0;
     //       if(BLavg[ch]==65536)     BLavg[ch] = 0;
     //       if(BLavg[ch]>MAX_BLAVG)  BLavg[ch] = MAX_BLAVG;
      //      BLbad[ch] = MAX_BADBL;   // initialize to indicate no good BL found yet
            CCSRA[ch]       =  fippiconfig.CHANNEL_CSRA[ch]; 
            TRACEENA[ch]    = (( CCSRA[ch] & (1<<CCSRA_TRACEENA)) >0) && (RunType!=0x301) && (RunType!=0x401); 
            PILEUPCTRL[ch] =  ( CCSRA[ch] & (1<<CCSRA_PILEUPCTRL) ) >0;   // if bit set, only allow "single" non-piledup events
            Emin[ch]  = fippiconfig.EMIN[ch];  
            if( (CCSRA[ch] & (1<<CCSRA_GOOD)) >0 )
               GoodChanMASK[k7] = GoodChanMASK[k7] + (1<<ch_k7) ;   // build good channel mask
        }
    }


    if(fippiconfig.DATA_FLOW!=6) { 
         printf( "This function only supports option DATA_FLOW = 6 \n");
         return(-1);
    }
 

    // --------------------------------------------------------
    // - Software triggering setup
    // --------------------------------------------------------

    nts = nts_open(nts_host, 5591);
    if (!nts) {
        printf("Failed to open NetTimeSync software triggering\n");
        return -5;
    }

    printf("DAQ starting\n");

    // --------------------------------------------------------
    // ------------------- Main code begins --------------------
    // --------------------------------------------------------


    // **********************  Compute Coefficients for E Computation  **********************
    dt = 1.0/FILTER_CLOCK_MHZ;
    for( k = 0; k < NCHANNELS; k ++ )
    {
        q = exp(-1.0*dt/Tau[k]);
        elm = exp(-1.0*dt*SL[k]/Tau[k]);
        C0[k] = (q-1.0)*elm/(1.0-elm);
        Cg[k] = 1.0-q;
        C1[k] = (1.0-q)/(1.0-elm);
        // printf("%f  %f   %f\n", C0[k], Cg[k], C1[k]);

        C0[k] = C0[k] * Dgain[k];
        Cg[k] = Cg[k] * Dgain[k];
        C1[k] = C1[k] * Dgain[k];
    }

    // ********************** Run Start **********************


  //  NumPrevTraceBlks = 0;
    loopcount =  0;
    eventcount = 0;
    for( ch=0; ch < NCHANNELS; ch++) eventcount_ch[ch] = 0;
    starttime = currenttime = time(NULL);                         // capture OS start time
    pn_log("Run start");
    printf("log: Run start\n");

    if( (RunType==0x100)  )  {    // list mode runtypes  
       
      if(RunType==0x100){
        // write a 0x100 header  -- actually there is no header, just events
        sprintf(filename, "LMdata%d.bin", fippiconfig.MODULE_ID);
        fil = fopen(filename,"wb");
      }  
        

    }  // end supported run types

     // Run Start Control
   for(k7=0;k7<N_K7_FPGAS;k7++)
   {     
      mapped[AMZ_DEVICESEL] =  cs[k7];	   // select FPGA 
      mapped[AMZ_EXAFWR] = AK7_PAGE;      // specify   K7's addr:    PAGE register
      mapped[AMZ_EXDWR]  = PAGE_SYS;      //  PAGE 0: system, page 0x10n = channel n
      
      mapped[AMZ_EXAFWR] =  AK7_HOSTCLR;  // specify   K7's addr:    write to clear SDRAM, DEEPFIFO 
      mapped[AMZ_EXDWR]  =  0;            // any write ok
      usleep(10);                         // memory reset may need some time
   }

   mapped[AMZ_DEVICESEL] = CS_MZ;	           // select MZ
   if(SyncT==1)  mapped[ARTC_CLR] = 0x0001;    // any write will create a pulse to clear timers




   if(WR_RTCtrl==1)                       // RunEnable/Live set via WR time comparison  (if startT < WR time < stopT => RunEnable=1) 
   {
      mapped[AMZ_DEVICESEL] = CS_K1;	   // specify which K7 
      mapped[AMZ_EXAFWR] = AK7_PAGE;      // specify   K7's addr:    PAGE register
      mapped[AMZ_EXDWR]  = PAGE_SYS;      //  PAGE 0: system, page 0x10n = channel n

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


   
   mapped[AMZ_DEVICESEL] = CS_MZ;	// select MZ
   if( (fippiconfig.DATA_FLOW == 4) || (fippiconfig.DATA_FLOW == 5) || (fippiconfig.DATA_FLOW == 6))  
      mapped[AMZ_RUNCTRL] = 0x0008;    // MCA FIFO enabled 
   else
      mapped[AMZ_RUNCTRL] = 0x0000;    // MCA FIFO disabled
 
   mapped[AMZ_CSRIN] = 0x0001;      // RunEnable=1 > nLive=0 (DAQ on)
   // this is a bit in a MZ register tied to a line to both FPGAs
   // falling edge of nLive clears counters and memory address pointers
   // line ignored for WR_RTCtrl in K7, but still useful for TotalTime in MZ  
   

    // ********************** Run Loop **********************
    do {
        pn_log_loop(loopcount);

        //----------- Periodically read BL and update average -----------
        // not needed in DATA_FLOW>=2
        // this HAS BEEN moved into the FPGA 

        // poll MCA FIFO (unnecessary, but FPGA expects MCA FIFO to be active (for now))
         mapped[AMZ_DEVICESEL] = CS_MZ;	// select MZ
         tmp2 = mapped[AMZ_CSROUTL];
         if ( (tmp2 & 0x00000100)>0 )  // check MCAdataready bit
         {  
            if(eventcount==0) tmp0 = mapped[AMZ_RDMCA]; // dummy read
            tmp0 = mapped[AMZ_RDMCA+1];   // channel and other info
            tmp1 = mapped[AMZ_RDMCA];   // energy  and advance FIFO
         }

        // -----------poll for events -----------
        // if data ready. read out, compute E, increment MCA *********
        Stopwatch sw_stats = sw_start();
     //   evstats = mapped[AEVSTATS];
        sw_check(&sw_stats, "AEVSTATS");
      for(k7=0;k7<N_K7_FPGAS;k7++)
      {

            // Non-AutoUDP: ARM first needs to poll K7 if data ready
            // then, give command to send out data to FIFO, adding a CFD value 
            // then, if DM approves, give command to send out data to WR Ethernet (in subroutine nts poll > nts_store_remote)
 
            mapped[AMZ_DEVICESEL] =  cs[k7];	         // select FPGA 
            mapped[AMZ_EXAFWR] = AK7_PAGE;            // specify   K7's addr     addr 3 = channel/system
            mapped[AMZ_EXDWR]  = PAGE_SYS;            //                         0x0  = system  page

            // check if UDP transfer is still ongoing
            mapped[AMZ_EXAFRD] = AK7_CSROUT;     // read CSR
            tmp0 =  mapped[AMZ_EXDRD];    
            if(SLOWREAD)  tmp0 = mapped[AMZ_EXDRD]; 
            udpok = ((tmp0 & 0x0400)==0) ;       // check flag for DF in progress, must be zero
            if(eventcount<maxmsg && !udpok) printf( "K7 %d: DF busy: CSR = 0x%x, test=0x%x \n", k7, tmp0,(tmp0 & 0x0400) );

            // Read Header DPM status
            mapped[AMZ_EXAFRD] = AK7_SYSSYTATUS;      // write to  k7's addr for read -> reading from 0x85 system status register
            evstats = mapped[AMZ_EXDRD];              // bits set for every channel that has data in header memory
            if(SLOWREAD)  evstats = mapped[AMZ_EXDRD];   
            evstats = evstats & GoodChanMASK[k7];     // mask non-good channels

            // event readout compatible with P16 DSP code
            // very slow and inefficient; can improve or better bypass completely in final WR data out implementation
            if(evstats && udpok) {					  // if there are events in any [good] channel
               if(eventcount<maxmsg) printf( "\nK7 0 read from AK7_SYSSYTATUS (0x85), masked for good channels: 0x%X\n", evstats );
               for( ch_k7=0; ch_k7 < NCHANNELS_PER_K7; ch_k7++)
               {

                  Stopwatch sw_lm = sw_start();

                  ch = ch_k7+k7*NCHANNELS_PER_K7;              // total channel count
                  R1 = 1 << ch_k7;
                  if(evstats & R1)	{	                        //  if there is an event in the header memory for this channel
         
                       mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr     addr 3 = channel/system
                       mapped[AMZ_EXDWR]  = PAGE_CHN+ch_k7;   //                         0x10n  = channel n     -> now addressing channel ch page of K7-0

                           // read 1 64bit word from header (CFD data requiring division, pileup info etc)
                           // by now,  E is computed in FPGA 
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
                           mapped[AMZ_EXAFRD] = AK7_HDRMEM_D;   // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                           hdr[4*k+0] = mapped[AMZ_EXDRD];      // read 16 bits
                            if(SLOWREAD)   hdr[4*k+0] = mapped[AMZ_EXDRD];      // read 16 bits
                           // the next 5 words only need to be read if storing data locally 
       
                         if(eventcount<maxmsg) { 
                           printf( "Ch. %d: Event count [ch] %d, total %d\n",ch, eventcount_ch[ch],eventcount );
                           printf( "Read 0 H-L: 0x %X %X %X %X\n",hdr[ 3], hdr[ 2], hdr[ 1], hdr[ 0] );
                        }    
                 
                        // extract the WR timestamp
                        //   timeL   =  hdr[1]     + (hdr[2] <<16);
                        //   timeH   =  hdr[3];
    
                        // extract pileup bit
   
                        pileup  = (hdr[0]>>3)&0x1;
                    //    printf( "ch. %d, cfdout1 %d, cfdout2 %d, cfdsrc %d, cfdfrc %d ",ch,cfdout1,cfdout2,cfdsrc,cfdfrc); 

                     // read FPGA E
                     mapped[AMZ_EXAFRD] = AK7_EFIFO;              // select the "EFIFO" address in channel's page
                     energyF = mapped[AMZ_EXDWR];                 // read 16 bits
                     if(SLOWREAD)  energyF = mapped[AMZ_EXDRD];   // read 16 bits
                     if(eventcount<maxmsg) printf( "Read FPGA E: %d\n",energyF ); 
      
          
                    if( ((PILEUPCTRL[ch]==0)     || (PILEUPCTRL[ch]==1 && !pileup )) && (energyF>Emin[ch])    )
                    {    // either don't care  OR pilup test required and  pileup bit not set
                         //printf( "pileup test passed, start computing E\n");      
           
                        // cfd is not reported in DATA_FLOW==6
                        cfd =0;
             
 
   
                        // at this point, key data of event is known. Now can
                        // send it to DM for further decision making
                        // Also move to SDRAM deepfifo while waiting for DM decision
   
                        sw_check(&sw_lm, "List mode ch=%u", ch); 

                        // Send triggers to the NTS DM.
                        nts_event_data = NULL;
                        //unsigned long long ts = (unsigned long long)eventcount;
                        unsigned long long ts =   hdr[1] + 65536*hdr[2] + TWOTO32* hdr[3];
                        nts_triggered++;
                        pn_log("TRIGGER t=%llu n=%u ch=%u", ts, nts_triggered, ch);
                        nts_trigger(nts, revsn, ch, cs[k7], ts, energyF, currenttime, nts_event_data);
                        nts_sent++;

                        // advance data to SDRAM FIFO (waiting for DM approval)
                        mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr:    PAGE register
                        mapped[AMZ_EXDWR]  = PAGE_SYS;         // PAGE 0:   system, page 0x10n = channel n                    
                        mapped[AMZ_EXAFWR] = AK7_ETH_CFD;      // specify   K7's addr:    cfd for Eth data packet
                        mapped[AMZ_EXDWR]  = cfd;
                             
                        R1=0;
                        //  if( eventcount<50000) R1=8;        // debug: disable DF readout for some time by setting high bit in PAYLOAD_TYPE
                        mapped[AMZ_EXAFWR] =  AK7_ETH_CTRL;    // specify   K7's addr:    Ethernet output control register
                        mapped[AMZ_EXDWR]  =  (ch_k7<<12) + ((R1+TRACEENA[ch])<<8) + (TL[ch]>>5);  // channel, payload type with/without trace, TL blocks   
                        if(eventcount<maxmsg) printf( "issued command to UDP send\n");
                         
                        //  histogramming if E< max mcabin
                        bin = energyF >> Binfactor[ch];
                        if( (bin<MAX_MCA_BINS) && (bin>0) ) {
                           mca[ch][bin] =  mca[ch][bin] + 1;	// increment mca
                           bin = bin >> WEB_LOGEBIN;
                           if(bin>0) wmca[ch][bin] = wmca[ch][bin] + 1;	// increment wmca
                        }

                        eventcount++;
                        eventcount_ch[ch]++;
                    }
                    else { // event not acceptable (piled up) 
   
                        //eventcount_ch[ch+1]++; // debug
                          // advance header memory by 5 x4 words
                          for( k=0; k < 5; k++)
                           {
                              mapped[AMZ_EXAFRD] = AK7_HDRMEM_D;     // write to  k7's addr for read -> reading from AK7_HDRMEM_D channel header fifo, low 16bit
                              hdr[k] = mapped[AMZ_EXDRD];      // read 16 bits, no double read required
                             
                            }
   
                          //  now also advance trace memory address if traces are enabled
                          if(TRACEENA[ch]==1)  { 
                             mapped[AMZ_EXAFRD] = AK7_SKIPTRACE;             // select the "skiptrace" address in channel's page
                             tmp0 = mapped[AMZ_EXDWR];     // any read ok
                          }  // end if trace enabled 
                     }  // end not acceptable
                }     // end event in this channel
            }        //end for ch
        }           // end event in any channel
      }              // end for K7s



/*      // debug
       // Send triggers to the NTS DM.
       if( loopcount % (PollTime/10) == 0) {
            unsigned long long ts = ((unsigned long long)timeH << 32) + eventcount;
            nts_triggered++;
            pn_log("Trigger t=%llu n=%u ch=%u", ts, nts_triggered, 0);
          //   printf("log: Trigger t=%llu n=%u ch=%u\n", ts, nts_triggered, 0);
            nts_trigger(nts, revsn, 0, cs[0], ts, currenttime, nts_event_data);
            nts_sent++;

            eventcount++;
            //usleep(10000);
        }
*/

        // ----------- Periodically save MCA, PSA, and Run Statistics  -----------

        if(loopcount % PollTime == 0)
        {
            pn_log("Save statistics");

            // 1) Run Statistics 

            // for debug purposes, print to std out so we see what's going on
            mapped[AMZ_DEVICESEL] = CS_MZ;
            tmp0 = mapped[AMZ_RS_TT+0];   // address offset by 1?
            tmp1 = mapped[AMZ_RS_TT+1];
             if(verbose) printf("%s %4.5G \n","Total_Time",((double)tmp0*65536+(double)tmp1*TWOTO32)*1e-9);    
            // print (small) set of RS to file, visible to web
            //read_print_runstats_XL_2x4(1, 0, mapped);
            read_print_rates_XL_2x4(0,mapped);
      

            // 2) MCA
            filmca = fopen("MCA.csv","w");
            fprintf(filmca,"bin");
            for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",MCAch%02d",ch);
            fprintf(filmca,"\n");
            for( k=0; k <WEB_MCA_BINS; k++)       // report the 4K spectra during the run (faster web update)
            {
               fprintf(filmca,"%d",k*onlinebin);                  // bin number
               for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",%d",wmca[ch][k]);    // print channel data
               fprintf(filmca,"\n");
            }
            fclose(filmca);    

        }

        // ----------- Receive NTS accept/reject decisions    -----------
        //while (nts_sent % NTS_POLL_INTERVAL == 0 && (poll_result = nts_poll(nts)) != 0) {
        poll_result = nts_poll(nts, mapped);
        if( poll_result !=0) 
        {
            pn_log("Poll ret=%d", poll_result);
            if (poll_result > 0 && poll_result != NTS_IGNORE) {
                nts_received += poll_result;
            }
            else if (poll_result < 0) {
                pn_log("Poll ret=%d", poll_result);
                nts_run = 0;
            }
        }

        // ----------- periodically send status message so dm does not hang while waiting for trigger    -----------
        if(loopcount % (PollTime/10) == 0)
        {
            nts_send_status(nts);
        }
        // ----------- loop housekeeping -----------

        loopcount ++;
        currenttime = time(NULL);
    } while (currenttime <= starttime+ReqRunTime && nts_run); // run for a fixed time and stop on nts error
    //     } while (eventcount <= 6); // run for a fixed number of events
    //     } while (nts_received <= 6); // run for a fixed number of events

    pn_log_loop(UINT_MAX);

    // ********************** Run Stop **********************
    printf("Stopping the run\n");


     /* debug */
   
      mapped[AMZ_DEVICESEL] = CS_K1;	   // specify which K7 
      mapped[AMZ_EXAFWR] = AK7_PAGE;      // specify   K7's addr:    PAGE register
      mapped[AMZ_EXDWR]  = PAGE_SYS;      //  PAGE 0: system, page 0x10n = channel n

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

      
      printf( "Run completed. Current WR time %llu\n",WR_tm_tai );
      //printf( "Events transfered %d, rejected %d\n",eventcount_ch[13],eventcount_ch[14] );
      printf( "WR time 0x %X %X %X",tmp2, tmp1, tmp0 );
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+3;   
      tmp1 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp1 =  mapped[AMZ_EXDRD];
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+4;   
      tmp2 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp2 =  mapped[AMZ_EXDRD];
       printf( " -- %X %X\n",tmp2, tmp1 );
     
      
      /* end debug */

    // clear RunEnable bit to stop run
   mapped[AMZ_DEVICESEL] = CS_MZ;	 // select MZ
    mapped[AMZ_CSRIN] = 0x0000; // all off       
   // todo: there may be events left in the buffers. need to stop, then keep reading until nothing left

     // final save MCA and RS
   filmca = fopen("MCA.csv","w");
   fprintf(filmca,"bin");
   for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",MCAch%d",ch);
   fprintf(filmca,"\n");
   //fprintf(filmca,"bin,MCAch0,MCAch1,MCAch2,MCAch3,MCAch4,MCAch5,MCAch6,MCAch7\n");
   for( k=0; k <MAX_MCA_BINS; k++)
   {
    //  fprintf(filmca,"%d,%u,%u,%u,%u\n ", k,mca[0][k],mca[1][k],mca[2][k],mca[3][k] );
       fprintf(filmca,"%d",k);                  // bin number
       for(ch=0;ch<NCHANNELS_PRESENT;ch++) fprintf(filmca,",%d",mca[ch][k]);    // print channel data
       fprintf(filmca,"\n");
   }
   fclose(filmca);

   mapped[AMZ_DEVICESEL] = CS_MZ;
   read_print_runstats_XL_2x4(0, 0, mapped);
   read_print_rates_XL_2x4(0,mapped);
   mapped[AMZ_DEVICESEL] = CS_MZ;

    // Drain NTS accept/reject decisions
    while ((poll_result = nts_poll(nts, mapped)) > 0) {
        if (poll_result != NTS_IGNORE) {
            nts_received += poll_result;
        }
    }

    // Clean up NTS networking.
    //printf("Cleaning up trigger sockets\n");
    nts_destroy(&nts);
    printf("NTS triggered %u, sent %u, accepted %u\n", nts_triggered, nts_sent, nts_received);

    fflush(stdout);

    pn_log_close();

    if( (RunType==0x100) || (RunType==0x400) )  {
        fclose(fil);
    }
    flock( fd, LOCK_UN );
    munmap(map_addr, size);
    close(fd);
    return 0;
}
