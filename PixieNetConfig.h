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
 
#ifndef PixieNetConfig_h
#define PixieNetConfig_h

#include <stdint.h>

#include "PixieNetDefs.h"

/*  Functions and structs in this header are mainly concerned with configuring 
    the FPGA, data runs, and eventually reading other information out from the
    MCA.
 
    Note the functions in this header are implemented in c++, but can still be
    called from C programs.

    To add new parameters, its name has to be typed 5 times
    1) add line in ini files (2x)
    2) add element to struct in PixieNetConfig.h
    3) add parse/read line in PixieNetConfig.cpp
    4) use in progfippi or equivalent
 */

#ifdef __cplusplus
extern "C" {
#endif

  
/** Struct that represents information used to program the FPGA.
 
    Currently the PIXIE-NET system needs some of this information, during an
    actual data run, but things like TAU should eventually not be needed after
    doing the 'progfippi' step.
   
    Note variable names left the same as the config.ini originally provided to
    Sandia, for ease of changing things in the future.  
    Also note, this is just a first pass of creating this structure.
    Fields can be seperated by one or more spaces, tabs, commas or semicolons
 
    TODO: document meaning of various values.
    TODO: Make enums for the bitmask variables, so things are clearer.
    TODO: shrink variable types into smaller type. Ex Use float instead of 
          double, or uint16_t instead of usinged int, etc.
    TODO: rename member variables to better names.
    TODO: check that there is no double->int convertion issues for things like
          the rise times.
    TODO: implement writing settings files out to disk.
    TODO: consider implementing these settings as an opaque struct
 */
typedef struct PixieNetFippiConfig {
  //Currently unused parameters.
  //int SYS_U8, SYS_U7, SYS_U6, SYS_U5, SYS_U4, SYS_U3, SYS_U2, SYS_U1, SYS_U0;
  
  // ***** 16 system parameters ******************************************************


    /** Reserved for options in the C code, e.g printing errors.
      Currently unused
   */
    unsigned int C_CONTROL;

    /** The clock/real time to aquire data for, in seconds.  This will be an
      approximation for list mode data collection.
   */
  double REQ_RUNTIME;//          300
  
  /** Number of data collection loops between grabbing the run statistic from 
      the FPGA.  This should probably be made in to a time in seconds, or 
      eliminated.  Typical value would be 900000
   */
  unsigned int POLL_TIME;

  /* ID numbers to be compatible with P16 data format      */
  unsigned int  CRATE_ID;
  unsigned int  SLOT_ID;
  unsigned int  MODULE_ID;

    /** Typical value of 1 
  Bit
   0 : pulser enabled   
   1 red LED on/off 
   2 reserved
   3 reserved - synchronize to PTP triggers
   4 select main I2C
   5 select DB0 I2C
   6 select DB1 I2C
   7 green LED on/off
   8 yellow LED on/off
 */
  unsigned int AUX_CTRL;

  unsigned int CLK_CTRL;            // switching the LMK ADC PLLs etc

  unsigned int WR_RUNTIME_CTRL;      // if 1, use WR time counters to determine start/stop of run

  unsigned int UDP_PAUSE;            // min time between UDP output packets 

  unsigned long long DEST_MAC0;      // destination MAC for data from first K7 
  unsigned long long DEST_MAC1;      // destination MAC for data from second K7 

  unsigned long long SRC_MAC0;      // source MAC for data from first K7  (ignored by WR core)
  unsigned long long SRC_MAC1;      // source MAC for data from second K7 

  unsigned long long DEST_IP0;       // destination IP for data from first K7 
  unsigned long long DEST_IP1;       // destination IP for data from second K7 

  unsigned long long SRC_IP0;        // source IP for data from first K7   (should match WR IP from PROM)
  unsigned long long SRC_IP1;        // source IP for data from second K7 

  unsigned int DEST_PORT0;          // UDP source and destination port for LM packages
  unsigned int DEST_PORT1;   
  unsigned int SRC_PORT0;   
  unsigned int SRC_PORT1;   

  unsigned int DATA_FLOW;           // options for readout 
      // if 0, ARM does everything
      // if 1, ARM uses FPGA's weighted sum result
      // if 2, ARM uses FPGA's baseline average and energy
      // if 3, ARM uses FPGA's baseline average and energy and directs data out via WR (adding CFD result)
      // if 4, FPGA sends out data via WR and ARM only increments the MCA with E values read from MZ  
      // if 5, ARM only increments the MCA with E values read from MZ (no LM data out)

  unsigned int SLEEP_TIMEOUT;       // when Kintex is not addressed for 64K x 40ns x this number, processing clocks are disabled

  unsigned int USER_PACKET_DATA;

  /* SYS_U## : reserved parameters  */

  // ***** end of system parameters ********************************************

  /** Control bits for whole module.
      Typical value of 2048.
      Module control bit A.0: report only one event per Coinc. Window (LM402),
      Module control bit A.5: enables MMCX input as global Veto, NYI
      Module control bit A.7: toggles active edge for front panel pulse counter, NYI
   */
  unsigned int MODULE_CSRA;
  
  /** Control bits for whole module.  TODO: document
      Typical value of 0.
      Module control bit B.1: if 1, termination for ch.0,1 is 50 Ohm
      Module control bit B.2: if 1, termination for ch.2,3 is 50 Ohm
   */
  unsigned int MODULE_CSRB;

    /** Dictates what type of data is saved and the format.
      1280 (0x500) means save listmode data with waveforms.
      1281 (0x501) means save listmode without waveforms
       768 (0x301) Histogram only, do not save listmode data (I assume?)
   */
  unsigned int RUN_TYPE;

   /** The module ends its spill when this number of events has been acquired. 
   */
   unsigned int MAX_EVENTS;
  
  /** Coincidence pattern for accepted between channels.
      0x0008 require channels 0 and 1 to be in coincidence.
      0x1000 require channels 2 and 3 to be in coincidence.
      0xFFFE = 65534 lets any hit pattern through.
   */
  unsigned int COINCIDENCE_PATTERN;
 
  /** Time between triggers, in micro-seconds, to consider the two hits to be a
      coincidence. 
      Typical value would be 0.040
   */
  double COINCIDENCE_WINDOW;
           
  
  /** If set to true, resets FPGA/DAC timers. */
  unsigned int SYNC_AT_START;
  
   /* reseved for daq resume */
   unsigned int RESUME;

     /** The clock decimation factor for calculating trigger and energy values.
      May be from 1 to 6.  
      See section 6.5 of Pixie4e users manual for description
      different values for slow and fast filter (some revisions)
   */
  unsigned int SLOW_FILTER_RANGE;
  unsigned int FAST_FILTER_RANGE;

 /* Enable sending fast trigger to backplane # 
    probably unused */
 unsigned int FASTTRIG_BACKPLANEENA;
  

  /* General trigger configuration */ 
  unsigned int TRIG_CONFIG0;
  unsigned int TRIG_CONFIG1;
  unsigned int TRIG_CONFIG2;
  unsigned int TRIG_CONFIG3;
  
  //Currently unused parameters.
  //unsigned int MOD_U3, MOD_U2, MOD_U1, MOD_U0;
  
  /** Options relating to the triggering of a single channel, as a bitmask.
    CCSRA_FTRIGSEL_00     // fast trigger selection - 1: select external fast trigger; 0: select local fast trigger
    CCSRA_EXTTRIGSEL_01   // module validation signal selection - 1: select module gate signal; 0: select global validation signal (RevD & RevF only)
    CCSRA_GOOD_02         // good-channel bit - 1: channel data will be read out; 0: channel data will not be read out
    CCSRA_CHANTRIGSEL_03  // channel validation signal selection - 1: select channel gate signal; 0: select channel validation signal (RevD & RevF only)
    CCSRA_SYNCDATAACQ_04  // block data acquisition if trace or header DPMs are full - 1: enable; 0: disable
    CCSRA_INVERT_05       // input signal polarity control
    CCSRA_VETOENA_06      // veto channel trigger - 1: enable; 0: disable
    CCSRA_HISTOE_07       // histogram energy in the on-board MCA
    CCSRA_TRACEENA_08     // trace capture - 1: enable; 0: disable
    CCSRA_QDCENA_09       // QDC summing and associated header data - 1: enable; 0: dsiable
    CCSRA_CFDMODE_10      // CFD for real time, trace capture and QDC capture - 1: enable; 0: disable 
    CCSRA_GLOBTRIG_11     // global trigger for validation - 1: enable; 0: disable
    CCSRA_ESUMSENA_12     // raw energy sums and baseline in event header - 1: enable; 0: disable
    CCSRA_CHANTRIG_13     // channel trigger for validation - 1: enable; 0: disable
    CCSRA_ENARELAY_14     // Control input relay: 1: connect, 0: disconnect
          
    // Control pileup rejection using bit 15 and 16 of ChanCSRA:
      // bits[16:15]
      // 00: record all events (trace, timestamps, etc., but no energy for piled-up events)
      // 01: only record single events (trace, energy, timestamps, etc.) (i.e., reject piled-up events)
      // 10: record trace, timestamps, etc., for piled-up events but do not record trace for single events
      // 11: only record trace, timestamps, etc., for piled-up events (i.e., reject single events)
   CCSRA_PILEUPCTRL_15  
   CCSRC_INVERSEPILEUP_00
  
   CCSRC_ENAENERGYCUT_01  // Enable "no trace for large pulses" feature - 1: enable; 0: disable
   CCSRC_GROUPTRIGSEL_02  // Group trigger selection - 1: external group trigger; 0: local fast trigger
   CCSRC_CHANVETOSEL_03  // Channel veto selection - 1: channel validation trigger; 0: front panel channel veto
   CCSRC_MODVETOSEL_04  // Module veto selection - 1: module validation trigger; 0: front panel module veto
   CCSRC_EXTTSENA_05  // External timestamps in event header - 1: enable; 0: disable

   */
  unsigned int CHANNEL_CSRA[NCHANNELS]; //         180    180    180      180
  unsigned int CHANNEL_CSRB[NCHANNELS]; //         0      0      0      0
  unsigned int CHANNEL_CSRC[NCHANNELS]; //         0      0      0      0
  
  double ANALOG_GAIN[NCHANNELS]; //                       Gain with switches/relays/VGAs
  double DIG_GAIN[NCHANNELS]; //                          Digital gain adjustment factor.
  double VOFFSET[NCHANNELS]; //                      V     Offset
  double ENERGY_RISETIME[NCHANNELS]; //              us     Energy filter rise time
  double ENERGY_FLATTOP[NCHANNELS]; //               us     Energy filter flat top
  double TRIGGER_RISETIME[NCHANNELS]; //             us     Trigger filter rise time
  double TRIGGER_FLATTOP[NCHANNELS]; //              us     Trigger filter flat top
  double TRIGGER_THRESHOLD[NCHANNELS]; //                 Trigger threshold 
  double THRESH_WIDTH[NCHANNELS]; //           us     Width for trigger above threshold
  double TRACE_LENGTH[NCHANNELS]; //                 us     Captured waveform length
  double TRACE_DELAY[NCHANNELS]; //                  us     Pre-trigger delay
  unsigned int BINFACTOR[NCHANNELS]; //                   MCA binning factor: divide by 2^N)
  unsigned int INTEGRATOR[NCHANNELS]; //                  Filter mode: 0-trapezoidal, 1-gap sum integral NYI, 2-ignore gap sum, NYI. 
  unsigned int BLCUT[NCHANNELS]; //                     Threshold for bad baseline measurements
  double BASELINE_PERCENT[NCHANNELS]; //                  Target offset for baseline, nominally in percent, NYI
  unsigned int BLAVG[NCHANNELS]; //                       Baseline averaging
  double TAU[NCHANNELS]; //                          us     Preamplifier decay time
  double XDT[NCHANNELS]; //                          us     Sampling interval in untriggered traces, NYI
  unsigned int MULTIPLICITY_MASKL[NCHANNELS]; //          Mask multiplicity contribution group - low 16-bit
  unsigned int MULTIPLICITY_MASKM[NCHANNELS]; //          Mask multiplicity contribution group - medium 16-bit
  unsigned int MULTIPLICITY_MASKH[NCHANNELS]; //          Mask multiplicity contribution group - high 16-bit
  unsigned int MULTIPLICITY_MASKX[NCHANNELS]; //          Mask multiplicity contribution group - extra 16-bit
  double FASTTRIG_BACKLEN[NCHANNELS];   //    us    //             Length of fast rigger signal on the backplane
  unsigned int CFD_THRESHOLD[NCHANNELS]; //               CFD trigger threshold
  unsigned int CFD_DELAY[NCHANNELS] ;         //    ticks    //              iThemba CFD delay
  unsigned int CFD_SCALE[NCHANNELS];                     //              iThemba CFD scale; 0(div2), 1(div4), 2(div8), 3(div16)
  double EXTTRIG_STRETCH[NCHANNELS];     //          //              iThemba external trigger stretch
  double VETO_STRETCH[NCHANNELS] ;       //          //              iThemba veto signal (channel gate or module gate) stretch
  double CHANTRIG_STRETCH[NCHANNELS];    //          //
  double EXTERN_DELAYLEN[NCHANNELS] ;    //          //               Delay length for each channel's input signal
  double FTRIGOUT_DELAY[NCHANNELS];      //          //               Fast trigger output delay for system synchronization; delay = (FtrigoutDelay + 4)*10ns 
  unsigned int QDCLen0[NCHANNELS];             //  ticks      QDC length #0 
  unsigned int QDCLen1[NCHANNELS];             //  ticks      QDC length #1 
  unsigned int QDCLen2[NCHANNELS];             //  ticks      QDC length #2 
  unsigned int QDCLen3[NCHANNELS];             //  ticks      QDC length #3 
  unsigned int QDCLen4[NCHANNELS];             //  ticks      QDC length #4 
  unsigned int QDCLen5[NCHANNELS];             //  ticks      QDC length #5 
  unsigned int QDCLen6[NCHANNELS];             //  ticks      QDC length #6 
  unsigned int QDCLen7[NCHANNELS];             //  ticks      QDC length #7 
  double QDCDel0[NCHANNELS];             //  ticks      QDC delay #0       // use double because it can be negative. 
  double QDCDel1[NCHANNELS];             //  ticks      QDC delay #1 
  double QDCDel2[NCHANNELS];             //  ticks      QDC delay #2 
  double QDCDel3[NCHANNELS];             //  ticks      QDC delay #3 
  double QDCDel4[NCHANNELS];             //  ticks      QDC delay #4 
  double QDCDel5[NCHANNELS];             //  ticks      QDC delay #5 
  double QDCDel6[NCHANNELS];             //  ticks      QDC delay #6 
  double QDCDel7[NCHANNELS];             //  ticks      QDC delay #7 
  unsigned int QDC_DIV[NCHANNELS];             //        scaling factor for QDC sums 
  unsigned int PSA_THRESHOLD[NCHANNELS];       //        threshold for PSA/QDC logic 
  unsigned int EMIN[NCHANNELS];                //  minimum Energy (in final DSP units) for histogramming or LM output

} PixieNetFippiConfig;


/** Parses the provided ini file into the provided PixieNetFipiConfig struct.
    \returns 0 upon success.
 
    Note that current requires that for each member variable of 
    PixieNetFipiConfig, the configuration file must have a line starting with 
    that identifier string, and followed by the expected number of numeric
    values.
 
    Blank lines, or lines starting with a '#' character are skipped, as are
    any lines with unrecognized identifiers.
 
    Integer numeric values that start with a '0x' prefix are assumed to be 
    hexidecimal.
 
    Currently does not due any range checking!  This is left to progfippi.

 */
int init_PixieNetFippiConfig_from_file( const char * const filename,
                                       int ignore_missing,
                                       struct PixieNetFippiConfig *config );
  
  
  
#ifdef __cplusplus
}
#endif

#endif
