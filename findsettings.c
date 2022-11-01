/*----------------------------------------------------------------------
 * Copyright (c) 2017,2021 XIA LLC
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
#include <time.h>
#include <signal.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <math.h>
// need to compile with -lm option

#include "PixieNetDefs.h"
#include "PixieNetCommon.h"
#include "PixieNetConfig.h"


int main(void) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;
  int k, adc, dac;
  unsigned int mval, bit;
  
  unsigned int targetBL[NCHANNELS] = {1600};     
  unsigned int oldadc[NCHANNELS] = {0};
  unsigned int adcchanged[NCHANNELS] = {0};
  unsigned int dacs[NCHANNELS] = {0};
  unsigned int saveaux, sumchchanged;
  //unsigned int GOOD_CH[NCHANNELS];
  int k7, ch, ch_k7;                                           // ch = abs ch. no; ch_k7 = ch. no in k7
  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
  unsigned int ADCmax; 
  unsigned int revsn, NCHANNELS_PER_K7, NCHANNELS_PRESENT;
  unsigned int DACstart;                                       // starting value of DAC ramp
  unsigned int DACend;                                         // ending value of DAC ramp
  unsigned int DACstep;                                        // DAC increment per step
  double noiseL[NCHANNELS*MAX_NGAINS] ={10000.0} ;             // result[NCHANNELS x Ngains]: lowest noise in ramp 
  double noiseH[NCHANNELS*MAX_NGAINS] ={0.1};                  // result[NCHANNELS x Ngains]: highest noise in ramp 
  double slopes[NCHANNELS*MAX_NGAINS] ={0.0};                  // result[NCHANNELS x Ngains]: ADC per DAC slope
  unsigned int DACofADC2k[NCHANNELS*MAX_NGAINS] ={20000};      // result[NCHANNELS x Ngains]: DAC value that brings ADC to ~2000 (Todo)
  unsigned int DACvalues[NCHANNELS];
  double I2Eoffset[NCHANNELS], I2Eslope[NCHANNELS] ;



  // *************** PS/PL IO initialization *********************
  // open the device for PD register I/O
  fd = open("/dev/uio0", O_RDWR);
  if (fd < 0) {
    perror("Failed to open devfile");
    return 1;
  }

  map_addr = mmap( NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

  if (map_addr == MAP_FAILED) {
    perror("Failed to mmap");
    return 1;
  }

  mapped = (unsigned int *) map_addr;


  // ******************* Main code begins ********************

  // ******************* read ini file and fill struct with values ********************
  
  PixieNetFippiConfig fippiconfig;		// struct holding the input parameters
  const char *defaults_file = "defaults.ini";
  int rval = init_PixieNetFippiConfig_from_file( defaults_file, 0, &fippiconfig );   // first load defaults, do not allow missing parameters (0)
  if( rval != 0 )
  {
    printf( "Failed to parse FPGA settings from %s, rval=%d\n", defaults_file, rval );
    return rval;
  }
  const char *settings_file = "settings.ini";
  rval = init_PixieNetFippiConfig_from_file( settings_file, 2, &fippiconfig );   // second override with user settings, do allow missing and no warning (2)
  if( rval != 0 )
  {
    printf( "Failed to parse FPGA settings from %s, rval=%d\n", settings_file, rval );
    return rval;
  }

  
  // ***** check HW info *********
  revsn = hwinfo(mapped,I2C_SELMAIN);   // assuming all DBs are the same!
 
  if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250) | 
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_14_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250) )
  {
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
      DACstart = 12000;
      DACend   = 55000; 
      DACstep  = 1000;         // also depends on gain!
  }
  else
  {
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
      DACstart = 10000;
      DACend   = 45000; 
      DACstep  = 500;         // also depends on gain!
  }
  ADCmax = 16383;      // most DBs have 14 bit ADCs
  if ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250)  ADCmax = 4095;
  if ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_16_250)  ADCmax = 65535;

  NCHANNELS_PRESENT = NCHANNELS_PER_K7*N_K7_FPGAS;    

  mapped[AMZ_DEVICESEL] =  CS_MZ;      // select MZ controller	
  saveaux = mapped[AAUXCTRL];
  mapped[AAUXCTRL] = 0;                // turn off pulser, other stuff
  mapped[AMZ_CSRIN] = 0x0000;          // all off


  for( ch = 0; ch < NCHANNELS; ch ++ )
  {
      //GOOD_CH[ch]  =  ( fippiconfig.CHANNEL_CSRA[ch] & (1<<CCSRA_GOOD) ) >0;  
      targetBL[ch] =  (unsigned int)floor(ADCmax*fippiconfig.BASELINE_PERCENT[ch]/100);
  }

  printf( "targetBL[0]=%d\n", targetBL[0] );

  // ----------- swap channels odd/even if necessary  -------------
  if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_14_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250) )
  {
  printf("Checking for swapped channels ...\n");

     // scan through DAC settings, find if change of DAC changes ADC
     sumchchanged = 0;
     k=0;
     adc = 0;
     dac = 0; 
     do {

        // set the DACs
        for(k7=0;k7<N_K7_FPGAS;k7++)
        {        
           for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7; ch_k7 = ch_k7+2 )     // check every other channel
           {
              ch = ch_k7+k7*NCHANNELS_PER_K7;
              dacs[ch] = dac;

            } // endfor  channels
        } // endfor K7s
        if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250)
            setdacs08(mapped, dacs);
        else
            setdacs04(mapped, dacs);
        
        usleep(600000);    // extra  settling time
  
        // read the ADC back
        for(k7=0;k7<N_K7_FPGAS;k7++)
        {        
           for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7; ch_k7 = ch_k7+2 )     // check every other channel
           {
              ch = ch_k7+k7*NCHANNELS_PER_K7;

               mapped[AMZ_DEVICESEL] =  cs[k7];	         // select FPGA
               mapped[AMZ_EXAFWR]    = AK7_PAGE;         // write to  k7's addr        addr 3 = channel/system, select    
               mapped[AMZ_EXDWR]     = PAGE_CHN+ch_k7;   //  0x100  =channel 0                  
               mapped[AMZ_EXAFRD]    = AK7_ADC;          // write to  k7's addr
               usleep(1);
               adc = mapped[AMZ_EXDRD];                  // read K7 data from MZ
               adc = adc+ mapped[AMZ_EXDRD];             // read K7 data from MZ, average a few samples
               adc = adc+ mapped[AMZ_EXDRD];             // read K7 data from MZ, average a few samples
               adc = adc+ mapped[AMZ_EXDRD];             // read K7 data from MZ, average a few samples
               adc =adc>>2;

               if (k!=0)   
               {
                  if ( abs(oldadc[ch]-adc)>200)          // look for a change > 200 steps. Not foolproof with pulses!
                  {
                     if(!adcchanged[ch]) sumchchanged = sumchchanged+1;    // count the first time a channel changes
                     adcchanged[ch] = 1;   
                  }
               }

               printf("try %d, Channel %02u: DAC value %u, adc %u, adcdiff %d\n",k, ch,dac,adc,abs(oldadc[ch]-adc));
               oldadc[ch] = adc;
   
           } // endfor  channels
        } // endfor K7s

        k=k+1;
        dac = dac+4096;

      } while ( ( (sumchchanged*2)<(NCHANNELS_PRESENT)) & (k<16) );        //  dac loop half the channels (all tested) changed or full DAC range done

      // check if there was a change, if not, swap channels
      for(k7=0;k7<N_K7_FPGAS;k7++)
      {        
         for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7; ch_k7 = ch_k7+2 )       // check every other channel
         {
           ch = ch_k7+k7*NCHANNELS_PER_K7;

           if (adcchanged[ch] != 1)  {
               bit = 0x0001 << (ch_k7/2);                  // compute bit to toggle per ADC channel pair
               mapped[AMZ_DEVICESEL]   =  cs[k7];	     // select FPGA
               mapped[AMZ_EXAFWR]      = AK7_PAGE;      // write to  k7's addr        addr 3 = channel/system, select    
               mapped[AMZ_EXDWR]       = PAGE_SYS;                                              
               mapped[AMZ_EXAFRD]      = AK7_ADCCTRL;   // write to  k7's addr
               usleep(1);
               mval = mapped[AMZ_EXDRD];                // read K7 data from MZ

               mval = mval ^ bit;
               mapped[AMZ_EXAFWR]      = AK7_ADCCTRL;   // write to  k7's addr        addr 3 = channel/system, select    
               mapped[AMZ_EXDWR]       = mval;          // swap 0/1                                 

               printf("Channel %u: ADC values does not change with DAC. Swapped channel inputs\n",ch);
           }   // end unchanged

         } // endfor  channels
      } // endfor K7s

  }    // end version check
 
  
  // ----------- need to have correct polarity  -------------

  // TODO!

  // ----------- calibrate the ADC bit slip   -------------

  if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_125) | ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_75) )
  // if DB01, need to adjust the bitslip
  {
     printf("Initializing ADCs:\n");

     ADCinit_DB01(mapped);
     // TODO: check return value for success

  }   //  end version check 


  // ----------- adjust offset: search for two DAC settings with valid ADC response, then extrapolate  -------

  printf("Adjusting DC offsets (correct polarity required) ...\n");
  printf(" still preliminary, not precise, slow ...\n");

  ramp_dacs( mapped,                   // address space for MZ I/O
             revsn,                    // HW revision and s/n
             DACstart,                 // starting value of DAC ramp
             DACend,                   // ending value of DAC ramp
             DACstep,                  // DAC increment per step
             noiseL,                   // result[NCHANNELS x Ngains]: lowest noise in ramp 
             noiseH,                   // result[NCHANNELS x Ngains]: highest noise in ramp 
             slopes,                   // result[NCHANNELS x Ngains]: ADC per DAC slope
             I2Eoffset,                // result[NCHANNELS]: offset mismatch between even and odd 
             I2Eslope,                 // result[NCHANNELS]: gain mismatch between even and odd 
             DACofADC2k                // result[NCHANNELS x Ngains]: DAC value that brings ADC to ~2000 (Todo)
            );

  printf("Suggested DAC voltages for settings file\n");
  for( ch = 0; ch < NCHANNELS_PRESENT; ch ++ )    // should be NCHANNELS
  {
      printf("  %5.2f", (1.0 - (double)DACofADC2k[ch]/32768.0) * V_OFFSET_MAX );
  }
  printf("\n");
 
  // before closing, set to something in the middle (DACofADC2k?)
  for( ch = 0; ch < NCHANNELS ; ch ++ )
  {
      DACvalues[ch] = DACofADC2k[ch]; //25000;
      //printf("DACvalues[%d] = %d\n", ch, DACvalues[ch]);
  }

  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250)
      setdacs04(mapped,DACvalues);       // TODO: this occasionally causes stack smashing?
      //printf("setting DACs to 2k\n");
  else
     if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250)
     {
        setdacs08(mapped,DACvalues);         
     }
     else     // any other DB
     {

         setdacs01(mapped,DACvalues); 
     }

  usleep(300000);    // extra  settling time
    

  // ----------- done ----------------------

  mapped[AMZ_DEVICESEL] = CS_MZ;	  // read from IO block
  mapped[AAUXCTRL] = saveaux;       // restore AUCCTRL

  // clean up  
  munmap(map_addr, size);
  close(fd);
  return 0;
}







