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



// global variables
unsigned int Random_Set[NTRACE_SAMPLES];			// Random indices used by TauFinder and BLCut

// subroutines
int Tau_Finder (
				volatile unsigned int *mapped,
            unsigned int ch_k7,		    // Pixie channel number in K7      
            unsigned FL, 
            unsigned FG,
            double   xdt,
				double *Tau );		          // Tau value

double Tau_Fit (
				unsigned int  *Trace,	    // ADC trace data
				unsigned int  kmin,		    // lower end of fitting range
				unsigned int  kmax,		    // uuper end of fitting range
				double dt );		          // sampling interval of ADC trace data

double Phi_Value (
				  unsigned int  *ydat,	    // source data for search
				  double qq,		          // search parameter
				  unsigned int  kmin,	    // search lower limit
				  unsigned int  kmax );	    // search upper limit

double Thresh_Finder (
					  unsigned int *Trace,	 // ADC trace data
					  double *Tau,		       // Tau value
					  double *FF,		       // return values for fast filter
					  double *FF2,		       // return values for fast filter
					  unsigned int  FL,	    // fast length
					  unsigned int  FG,	    // fast gap
					  double dt );		       // xdt

int RandomSwap(void);

unsigned int RoundOff(double x);

#ifndef MAX
   #define MAX(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef MIN
   #define MIN(a,b)            (((a) < (b)) ? (a) : (b))
#endif


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
  unsigned int GOOD_CH[NCHANNELS], FL[NCHANNELS], FG[NCHANNELS];
  double Tau, xdt[NCHANNELS];
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
  if ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB10_12_500)  ADCmax = 4095;

  NCHANNELS_PRESENT = NCHANNELS_PER_K7*N_K7_FPGAS;    

  mapped[AMZ_DEVICESEL] =  CS_MZ;      // select MZ controller	
  saveaux = mapped[AAUXCTRL];
  //mapped[AAUXCTRL] = 0;              // turn off pulser, other stuff  -- better to keep on, in case pulser is used as signal
  mapped[AMZ_CSRIN] = 0x0000;          // all off

  // shorthand a few parameters
  for( ch = 0; ch < NCHANNELS; ch ++ )
  {
      GOOD_CH[ch]  =  ( fippiconfig.CHANNEL_CSRA[ch] & (1<<CCSRA_GOOD) ) >0;  
      targetBL[ch] =  (unsigned int)floor(ADCmax*fippiconfig.BASELINE_PERCENT[ch]/100);
      xdt[ch]       =   fippiconfig.XDT[ch];       // not supporting 75 MHz variant with this
      FL[ch]       = (int)floorf(fippiconfig.TRIGGER_RISETIME[ch] * FILTER_CLOCK_MHZ_MOST);
      FG[ch]       = (int)floorf(fippiconfig.TRIGGER_FLATTOP[ch] * FILTER_CLOCK_MHZ_MOST);
  }



  // ----------- swap channels odd/even if necessary  -------------
  if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_14_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250) |
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250) )
      {
//  if(0){
       printf("Checking for swapped channel pairs ...\n");

       // program one ADC output to known value, check if that comes through
       // Note: this is now quick enough so that it could be done as part of booting or progfippi

       // set the test pattern
       for(k7=0;k7<N_K7_FPGAS;k7++)
       {        
           for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7; ch_k7 = ch_k7+2 )     // check every other channel
           {
              ch = ch_k7/2;     // here "ch" is the chip number (0-3, each with 2 channels)
              
              ADCSPI_Write06(mapped, k7, ch, 0x05, 0x01);   // write 0x01 to address 0x05 - changes only for channel A 
              ADCSPI_Write06(mapped, k7, ch, 0xFF, 0x01);   // write to the transfer register to apply
              
              ADCSPI_Write06(mapped, k7, ch, 0x0D, 0x04);   // write 0x04 to address 0x0D - turn on "checkerboard" test mode
              ADCSPI_Write06(mapped, k7, ch, 0xFF, 0x01);   // write to the transfer register to apply


            } // endfor  channels
       } // endfor K7s


      // read the ADC back
       for(k7=0;k7<N_K7_FPGAS;k7++)
       {        
           for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7; ch_k7 = ch_k7+2 )     // check every other channel
           {
               ch = ch_k7+k7*NCHANNELS_PER_K7;

               mapped[AMZ_DEVICESEL] =  cs[k7];	                  // select FPGA
               mapped[AMZ_EXAFWR]    = AK7_PAGE;                  // write to  k7's addr        addr 3 = channel/system, select    
               mapped[AMZ_EXDWR]     = PAGE_CHN+ch_k7;            //  0x100  =channel 0                  
               mapped[AMZ_EXAFRD]    = AK7_ADC;                   // write to  k7's addr
               usleep(1);
               mapped[AMZ_EXAFRD]    = AK7_ADC;                   // write to  k7's addr
               adc = mapped[AMZ_EXDRD];                           // read K7 data from MZ
               if((adc==2730) | (adc==13653))  adcchanged[ch]++ ; // check if it's one of the expected values
               //printf(" Channel %u: ADC value %d \n",ch, adc);
               mapped[AMZ_EXAFRD]    = AK7_ADC;                   // write to  k7's addr
               adc = mapped[AMZ_EXDRD];                           // read K7 data from MZ
               if((adc==2730) | (adc==13653))  adcchanged[ch]++ ; // check if it's one of the expected values
               //printf(" Channel %u: ADC value %d \n",ch, adc);
               mapped[AMZ_EXAFRD]    = AK7_ADC;                   // write to  k7's addr
               adc = mapped[AMZ_EXDRD];                           // read K7 data from MZ
               if((adc==2730) | (adc==13653))  adcchanged[ch]++ ; // check if it's one of the expected values
               //printf(" Channel %u: ADC value %d \n",ch, adc);
               mapped[AMZ_EXAFRD]    = AK7_ADC;                   // write to  k7's addr
               adc = mapped[AMZ_EXDRD];                           // read K7 data from MZ
               if((adc==2730) | (adc==13653))  adcchanged[ch]++ ; // check if it's one of the expected values
               //printf(" Channel %u: ADC value %d \n",ch, adc);

               if (adcchanged[ch] < 3)  {                         // one missed read is ok
                  bit = 0x0001 << (ch_k7/2);                      // compute bit to toggle per ADC channel pair
                  mapped[AMZ_DEVICESEL]   =  cs[k7];	            // select FPGA
                  mapped[AMZ_EXAFWR]      = AK7_PAGE;             // write to  k7's addr        addr 3 = channel/system, select    
                  mapped[AMZ_EXDWR]       = PAGE_SYS;                                              
                  mapped[AMZ_EXAFRD]      = AK7_ADCCTRL;          // write to  k7's addr
                  usleep(1);
                  mval = mapped[AMZ_EXDRD];                       // read K7 data from MZ
                  //printf(" ADC swap pattern was 0x%x ",mval);
   
                  mval = mval ^ bit;
                  printf(" now changed to  0x%x \n",mval);
                  mapped[AMZ_EXAFWR]      = AK7_ADCCTRL;          // write to  k7's addr        addr 3 = channel/system, select    
                  mapped[AMZ_EXDWR]       = mval;                 // swap 0/1                                 
   
                  printf(" Channel %u: ADC values does not change to test value. Swapped channel inputs\n",ch);
               }   // end unchanged


           } // endfor  channels
       } // endfor K7s


       // undo the test pattern
       for(k7=0;k7<N_K7_FPGAS;k7++)
       {        
           for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7; ch_k7 = ch_k7+2 )     // check every other channel
           {
              ch = ch_k7/2;     // here "ch" is the chip number (0-3, each with 2 channels)
              
              ADCSPI_Write06(mapped, k7, ch, 0x05, 0x03);   // write 0x03 to address 0x05 - changes for both channels 
              ADCSPI_Write06(mapped, k7, ch, 0xFF, 0x01);   // write to the transfer register to apply
              
              ADCSPI_Write06(mapped, k7, ch, 0x0D, 0x00);   // write 0x04 to address 0x0D - turn off "checkerboard" test mode
              ADCSPI_Write06(mapped, k7, ch, 0xFF, 0x01);   // write to the transfer register to apply


            } // endfor  channels
       } // endfor K7s



     if(0)  // old style check with DAC ramping
     {
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
   
                  printf(" try %d, Channel %02u: DAC value %u, adc %u, adcdiff %d\n",k, ch,dac,adc,abs(oldadc[ch]-adc));
                  oldadc[ch] = adc;
      
              } // endfor  channels
           } // endfor K7s
   
           k=k+1;
           dac = dac+4096;
           if(k==1) dac = 64000;       // try full range change to shorten search time
           if(k==2) dac = 4096;
   
         } while ( ( (sumchchanged*2)<(NCHANNELS_PRESENT)) & (k<17) );        //  dac loop half the channels (all tested) changed or full DAC range done
   
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
   
                  printf(" Channel %u: ADC values does not change with DAC. Swapped channel inputs\n",ch);
              }   // end unchanged
   
            } // endfor  channels
         } // endfor K7s

      }   // end old style check with DAC ramping

  }    // end version check for channel swap
  printf("\n");
 
  
  // ----------- need to have correct polarity  -------------

  // TODO!

  // ----------- calibrate the ADC bit slip   -------------

  if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_125) | ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_75) )
  // if DB01, need to adjust the bitslip
  {
     printf("Initializing ADCs:\n\n");

     ADCinit_DB01(mapped);
     // TODO: check return value for success

  }   //  end version check 


  // ----------- tau finder  -------
  // (TODO: for unknown reasons, this has to come before the offsets)

  if(1)     // optionally skip this (for debug)
  {
      printf("Determining decay time TAU (correct polarity required) ...\n"); 
      printf(" Tau finder depends on current TAU (for min. fit range) and XDT (for ADC data)\n");
      printf(" Suggested TAU values for settings file (if 0, ignore)\n  ");
      for(k7=0;k7<N_K7_FPGAS;k7++)
      {
      //k7 = 1;
         mapped[AMZ_DEVICESEL] =  cs[k7];	            // select FPGA 
         
         for(ch_k7=0;ch_k7<NCHANNELS_PER_K7;ch_k7++) {
         //ch_k7 = 0;
            ch = ch_k7+k7*NCHANNELS_PER_K7;
   
            //printf("TauFinder: channel %d \n", ch);
            Tau = fippiconfig.TAU[ch];
            if(GOOD_CH[ch])
               Tau_Finder ( mapped, ch_k7, FL[ch], FG[ch], xdt[ch], &Tau );
            else
               Tau = 0.0;  // report value that indicates not found
            printf("  %4.3f", Tau);
         }
       }
       printf(" \n\n");
   } // end debug switch


  // ----------- adjust offset: search for two DAC settings with valid ADC response, then extrapolate  -------

  if(1)     // optionally skip this (for debug)
  {
     printf("Adjusting DC offsets (correct polarity required) ...\n");
     printf(" target offset (ch.0) = %d\n", targetBL[0] );
   
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
   
     //printf("Suggested DAC voltages for settings file (ADC at 2000)\n");
     //for( ch = 0; ch < NCHANNELS_PRESENT; ch ++ )    // should be NCHANNELS
     //{
     //    printf("  %5.2f", (1.0 - (double)DACofADC2k[ch]/32768.0) * V_OFFSET_MAX );       
     //}
     //printf("\n");
   
   
     // set to target value
     for( ch = 0; ch < NCHANNELS_PRESENT ; ch ++ )
     {
         DACvalues[ch] = DACofADC2k[ch]; //default 2000;
         if(GOOD_CH[ch]) DACvalues[ch] = floor( (double)DACofADC2k[ch] + ((double)targetBL[ch]-2000.0)/slopes[ch] ); //25000
         if( (DACvalues[ch] <= 0) || (DACvalues[ch] > 64000) ) 
         {  
            DACvalues[ch]= 16000;      // pick reasonable default value
            printf(" Channel %d: no valid offset found, setting to default\n", ch);
         }
   
         //printf("DACvalues[%d] = %d\n", ch, DACvalues[ch]);
     }
   
     printf(" Offsets have been updated for 'GOOD' channels, but settings file is unchanged \n");
     printf(" Suggested VOFFSET voltages for settings file (ADC at BASELINE_PERCENT)\n");
     for( ch = 0; ch < NCHANNELS_PRESENT; ch ++ )    // should be NCHANNELS
     {
         printf("  %5.2f", (1.0 - (double)DACvalues[ch]/32768.0) * V_OFFSET_MAX );       
     }
     printf("\n\n");
   
     if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250)
         setdacs04(mapped,DACvalues);       // TODO: this occasionally causes stack smashing?
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
  
  }   // end adjust offset




  // ----------- done ----------------------

  mapped[AMZ_DEVICESEL] = CS_MZ;	  // read from IO block
  mapped[AAUXCTRL] = saveaux;       // restore AUCCTRL

  // clean up  
  munmap(map_addr, size);
  close(fd);
  return 0;
}


// ----------------------------------------------------------------------------------------
// tau finder subroutines from Pixie-4 
// ----------------------------------------------------------------------------------------

/****************************************************************
*	Tau_Finder function:
*		Find the exponential decay constant of the detector/preamplifier
*		signal connected to one channel of a Pixie module.
*			
*		Tau is both an input and output parameter: 
*     it is used as the initial guess of Tau enforcing a min. fit region of 3*tau
*     then used for returning the new Tau value (average of up to 10 successful fits).
*
*		Return Value:
*			 0 - success
*			-1 - failure to acquire ADC traces
*
****************************************************************/

int Tau_Finder (
				volatile unsigned int *mapped,
            unsigned int ch_k7,			// Pixie channel number in K7      calling function must loop over all channels, find ch in K7, ignore not "GOOD" channels, select K7
            unsigned FL, 
            unsigned FG,
            double  xdt,      // in us
				double *Tau )		// Tau value in us
{

	unsigned int  Trace[NTRACE_SAMPLES];
	unsigned int  TFcount;                
	unsigned int  ndat, k, kmin, kmax, n, tcount, MaxTimeIndex, Ntaufound;
	unsigned int  Trig[NTRACE_SAMPLES];
	double threshold, t0, t1, TriggerLevelShift, avg, MaxTimeDiff, fitted_tau;
	double FF[NTRACE_SAMPLES], FF2[NTRACE_SAMPLES], TimeStamp[NTRACE_SAMPLES/4];
	double input_tau, Tau_avg;
   double dt;
   unsigned int dn;  
	int mval;
   int debug=0;
   FILE * fil;     // for debug

	/* Save input Tau value */
	input_tau=*Tau * 1e-6;      // in seconds

	/* Generate random indices */
	RandomSwap();




   ndat=NTRACE_SAMPLES;
   dn = (int)floor( xdt*FILTER_CLOCK_MHZ_MOST);   // in samples
   dt = xdt * (1e-6);                             // in seconds
   Ntaufound = 0;

   //printf("TauFinder: channel %d, FL %d, FG %d, xdt %6.2f, dt %f, dn %d, initial Tau %f\n", ch_k7, FL, FG, xdt, dt, dn, *Tau);
   
   TFcount=0;  /* Initialize TFcount */
   Ntaufound = 0;
   Tau_avg = 0;
   do
   {
      /* get ADC trace */
      
      // calling function must select which K7
      
      // buffered FIFO read
      mapped[AMZ_EXAFWR] = AK7_PAGE;     // write to  k7's addr        
      mapped[AMZ_EXDWR]  = PAGE_SYS;    
      
      // write channel and dn
      mval =  ch_k7 + ((dn&0xFF)<<8);            // ch and lower byte of  dn
      mapped[AMZ_EXAFWR] = AK7_ADC_CHANNEL;      // write to  k7's addr to select register for write
      mapped[AMZ_EXDWR]  = mval;                 // write lower 16 bit
      mval = (dn>>8) & 0xFFFF;                   // upper 2 bytes of dn
      mapped[AMZ_EXAFWR] = AK7_ADC_INTERVAL;     // write to  k7's addr to select register for write
      mapped[AMZ_EXDWR]  = mval;                 // write upper 16 bit and start collecting
      
      // read samples
      for(k=0;k<NTRACE_SAMPLES/2;k++) 
      {
         mapped[AMZ_EXAFRD] = AK7_ADC_FIFO_L;     // write to  k7's addr
         Trace[2*k+0] = mapped[AMZ_EXDRD]; 
         
         // alternate high/low to get data from each ADC core (14/500)
         mapped[AMZ_EXAFRD] = AK7_ADC_FIFO_H;     // write to  k7's addr
         Trace[2*k+1] = mapped[AMZ_EXDRD]; 
      }       //    end for NTRACE_SAMPLES  
      
      // suppress the first few samples, may be bogus
      Trace[0] = Trace[6]; 
      Trace[1] = Trace[7]; 
      Trace[2] = Trace[8]; 
      Trace[3] = Trace[9]; 
      
      //printf("\nTauFinder: Trace %d %d %d %d %d %d %d %d\n", Trace[4], Trace[5],Trace[6],Trace[7],Trace[8],Trace[9],Trace[10],Trace[11]);
      
      // debug: save the trace
      if(debug)
      {
         // open the output file
         fil = fopen("ADC.csv","w");
         fprintf(fil,"sample, adc0\n");
         
         //  write to file
         for( k = 0; k < NTRACE_SAMPLES; k ++ )
         {
            //fprintf(fil,"%d",k);                  // sample number
            fprintf(fil,"%f",k*xdt );           // time in us
            fprintf(fil,",%d",Trace[k]);    // print channel data
            fprintf(fil,"\n");
         }
      } // end debug

		/* Find threshold */          
		threshold=Thresh_Finder(Trace, Tau, FF, FF2, FL, FG, dt);
      if(debug) printf("TauFinder:  threshold %f\n", threshold);

      /* find triggers (rising edges) */   

      // initialize
		kmin=2*FL+FG;
		for(k=0;k<kmin;k+=1) Trig[k]= 0;

		// Find average FF shift 
		avg=0.0;
		n=0;
		for(k=kmin;k<(ndat-1);k+=1)
		{
			if((FF[k+1]-FF[k])<threshold)
			{
				avg+=FF[k];
				n+=1;
			}
		}

		avg/=n;
		for(k=kmin;k<(ndat-1);k+=1)
		{
			FF[k]-=avg;
		}

		for(k=kmin;k<(ndat-1);k+=1)  /* look for rising edges */
		{
			Trig[k]= (FF[k]>threshold)?1:0;
		}

		tcount=0;
		for(k=kmin;k<(ndat-1);k+=1)  /* record trigger times */
		{
			if((Trig[k+1]-Trig[k])==1)
			{
				TimeStamp[tcount++]=k+2;  /* there are tcount triggers */
			}
		}
		if(debug) printf("*INFO* (Tau_Finder): found  %d triggers\n", tcount);

      /* select the best pulse to fit */
		if(tcount>2)
		{
			TriggerLevelShift=0.0;
			for(n=0; n<(tcount-1); n+=1)
			{
				avg=0.0;
				kmin=(unsigned int )(TimeStamp[n]+2*FL+FG);
				kmax=(unsigned int )(TimeStamp[n+1]-1);
				if((kmax-kmin)>0)
				{
					for(k=kmin;k<kmax;k+=1)
					{
						avg+=FF2[k];
					}
				}
				TriggerLevelShift+=avg/(kmax-kmin);
			}
			TriggerLevelShift/=tcount;
		}

		switch(tcount)
		{
   		case 0:
   			// Increment TFcount 
   			TFcount ++;
   			continue;
   		case 1:
   			t0=TimeStamp[0]+2*FL+FG;
   			t1=ndat-2;
   			break;
   		default:
   			MaxTimeDiff=0.0;
   			for(k=0;k<(tcount-1);k+=1)
   			{
   				if((TimeStamp[k+1]-TimeStamp[k])>MaxTimeDiff)
   				{
   					MaxTimeDiff=TimeStamp[k+1]-TimeStamp[k];
   					MaxTimeIndex=k;
   				}
   			}
   
   			if((ndat-TimeStamp[tcount-1])<MaxTimeDiff)
   			{
   				t0=TimeStamp[MaxTimeIndex]+2*FL+FG;
   				t1=TimeStamp[MaxTimeIndex+1]-1;
   			}
   			else
   			{
   				t0=TimeStamp[tcount-1]+2*FL+FG;
   				t1=ndat-2;
   			}


   			break;
		}  // end switch

		if(debug) printf("*INFO* (Tau_Finder): boundaries at points %6.2f  and %6.2f\n   (time %6.2f and %6.2f)\n", t0,t1, t0*xdt, t1*xdt);
		if(((t1-t0)*dt)<3*(input_tau))
		{
         if(debug) printf("*INFO* (Tau_Finder): interval too small, try again \n");
			// Increment TFcount 
			TFcount ++;
			continue;
		}

      /* fit the trace segment */
   	fitted_tau=Tau_Fit(Trace, (unsigned int )t0, (unsigned int )t1, dt);
		if(fitted_tau > 0)	// Check if returned Tau value is valid 
		{
			//*Tau=fitted_tau;
         Tau_avg=Tau_avg+fitted_tau;
         Ntaufound ++;
         if(debug) printf("*INFO* (Tau_Finder):found tau = %f (us)\n",fitted_tau*1e6);

		}


		TFcount ++;

		//	} while((*Tau == input_tau) && (TFcount < 10)); /* Try 10 times at most to get a valid Tau value */
         } while(TFcount < 20); /* Try 10 times at most to get a valid Tau value */
      // } while(Ntaufound <1 && TFcount < 10);   // stop at first valid

         if(Ntaufound>0)
            *Tau=Tau_avg/Ntaufound*1e6;       // then use average
         else
            *Tau = 0.0;
         if(debug) printf("*INFO* (Tau_Finder):found average tau = %f (us) from %d traces\n",Tau_avg/Ntaufound*1e6, Ntaufound);

	return(0);

}




/****************************************************************
*	Tau_Fit function:
*		Exponential fit of the ADC trace.
*
*		Return Value:
*			Tau value if successful
*			-1 - Geometric search did not find an enclosing interval
*			-2 - Binary search could not find small enough interval
*
****************************************************************/

double Tau_Fit (
				unsigned int  *Trace,		// ADC trace data
				unsigned int  kmin,		// lower end of fitting range
				unsigned int  kmax,		// uuper end of fitting range
				double dt )		// sampling interval in seconds
{
	double mutop,mubot,valbot,eps,dmu,mumid,valmid; // valtop
	unsigned int  count;
  // double dt;

   //dt = xdt*1e-6;      // xdt is in us
	eps=1e-3;
	mutop=10e6; /* begin the search at tau=100ns (=1/10e6) */
	//valtop=Phi_Value(Trace,exp(-mutop*dt),kmin,kmax);
	mubot=mutop;
	count=0;

   //printf( "*INFO* (Tau_Fit): kmin %d, kmax %d\n",kmin, kmax);

	do  /* geometric progression search */
	{
	//	printf( "*INFO* (Tau_Fit): mubot %e, mutop %e, valbot %e\n",mubot, mutop, valbot);
      mubot=mubot/2.0;
		valbot=Phi_Value(Trace,exp(-mubot*dt),kmin,kmax);
		count+=1;
		if(count>20)
		{
			//printf( "*ERROR* (Tau_Fit): geometric search did not find an enclosing interval\n");
			return(-1);
		}	/* Geometric search did not find an enclosing interval */
      //printf( "*INFO* (Tau_Fit): mubot %e, mutop %e, valbot %e\n",mubot, mutop, valbot);
	} while(valbot>0);	/* tau exceeded 100ms */

   //printf( "*INFO* (Tau_Fit): after geo: mubot %e, mutop %e, valbot %e\n",mubot, mutop, valbot);
	mutop=mubot*2.0;
	//valtop=Phi_Value(Trace,exp(-mutop*dt),kmin,kmax);
	count=0;
	do  /* binary search */
	{
		
      mumid=(mutop+mubot)/2.0;
		valmid=Phi_Value(Trace,exp(-mumid*dt),kmin,kmax);
		if(valmid>0)
		{
			mutop=mumid;
		}
		else
		{
			mubot=mumid;
		}

		dmu=mutop-mubot;
		count+=1;
		if(count>20)
		{
			//printf("*ERROR* (Tau_Fit): Binary search could not find small enough interval\n");
			return(-2);  /* Binary search could not find small enough interval */
		}
      //printf( "*INFO* (Tau_Fit): mumid %e, valmid %e\n", mumid, valmid);
	} while(fabs(dmu/mubot) > eps);

	return(1/mutop);  /* success */
}


/****************************************************************
*	Phi_Value function:
*		geometric progression search.
*
*		Return Value:
*			search result
*
****************************************************************/

double Phi_Value (
				  unsigned int  *ydat,		// source data for search
				  double qq,		// search parameter
				  unsigned int  kmin,		// search lower limit
				  unsigned int  kmax )		// search upper limit
{
	int ndat;
	double s0,s1,s2,qp;
	double A,B,Fk,F2k,Dk,Ek,val;
	unsigned int  k;

	ndat=kmax-kmin+1;
	s0=0; s1=0; s2=0;
	qp=1;

	for(k=kmin;k<=kmax;k+=1)
	{
		s0+=ydat[k];
		s1+=qp*ydat[k];
		s2+=qp*ydat[k]*(k-kmin)/qq;
		qp*=qq;
	}

	Fk=(1-pow(qq,ndat))/(1-qq);
	F2k=(1-pow(qq,(2*ndat)))/(1-qq*qq);
	Dk=-(ndat-1)*pow(qq,(2*ndat-1))/(1-qq*qq)+qq*(1-pow(qq,(2*ndat-2)))/pow((1-qq*qq),2);
	Ek=-(ndat-1)*pow(qq,(ndat-1))/(1-qq)+(1-pow(qq,(ndat-1)))/pow((1-qq),2);
	A=(ndat*s1-Fk*s0)/(ndat*F2k-Fk*Fk) ;
	B=(s0-A*Fk)/ndat;

	val=s2-A*Dk-B*Ek;

	return(val);

} 

/****************************************************************
*	Thresh_Finder function:
*		Threshold finder used for Tau Finder function.
*
*		Return Value:
*			Threshold
*
****************************************************************/

double Thresh_Finder (
					  unsigned int  *Trace,		// ADC trace data
					  double *Tau,		// Tau value
					  double *FF,		// return values for fast filter
					  double *FF2,		// return values for fast filter
					  unsigned int  FL,			// fast length
					  unsigned int  FG,			// fast gap
					  double dt )		// samoming interval in seconds
{

	unsigned int  ndat,kmin,k,ndev,n,m;
	double xx,c0,sum0,sum1,deviation,threshold;


	ndev=8;		/* threshold will be 8 times sigma */
	ndat=NTRACE_SAMPLES;

	// sprintf(str,"XWAIT%d",ChanNum);
	// idx=Find_Xact_Match(str, DSP_Parameter_Names, N_DSP_PAR);
	// Xwait=(double)Pixie_Devices[ModNum].DSP_Parameter_Values[idx];
   // dt=Xwait/SYSTEM_CLOCK_MHZ*1e-6;
	xx=dt/(*Tau);
	c0=exp(-xx*(FL+FG));

	kmin=2*FL+FG;
	/* zero out the initial part,where the true filter values are unknown */
	for(k=0;k<kmin;k+=1)
	{
		FF[k]=0;
	}

	for(k=kmin;k<ndat;k+=1)
	{
		sum0=0;	sum1=0;
		for(n=0;n<FL;n++)
		{
			sum0+=Trace[k-kmin+n];
			sum1+=Trace[k-kmin+FL+FG+n];
		}
		FF[k]=sum1-sum0*c0;
	}

	/* zero out the initial part,where the true filter values are unknown */
	for(k=0;k<kmin;k+=1)
	{
		FF2[k]=0;
	}

	for(k=kmin;k<ndat;k+=1)
	{
		sum0=0;	sum1=0;
		for(n=0;n<FL;n++)
		{
			sum0+=Trace[k-kmin+n];
			sum1+=Trace[k-kmin+FL+FG+n];
		}
		FF2[k]=(sum0-sum1)/FL;
	}

	deviation=0;
	for(k=0;k<ndat;k+=2)
	{
		deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);
	}

	deviation/=(ndat/2);
	threshold=ndev/2*deviation/2;

	m=0; deviation=0;
	for(k=0;k<ndat;k+=2)
	{
		if(fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]])<threshold)
		{
			m+=1;
			deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);
		}
	}
	deviation/=m;
	deviation*=sqrt(PI)/2;
	threshold=ndev*deviation;

	m=0; deviation=0;
	for(k=0;k<ndat;k+=2)
	{
		if(fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]])<threshold)
		{
			m+=1;
			deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);
		}
	}

	deviation/=m;
	deviation*=sqrt(PI)/2;
	threshold=ndev*deviation;

	m=0; deviation=0;
	for(k=0;k<ndat;k+=2)
	{
		if(fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]])<threshold)
		{
			m+=1;
			deviation+=fabs(FF[Random_Set[k]]-FF[Random_Set[k+1]]);
		}
	}
	deviation/=m;
	deviation*=sqrt(PI)/2;
	threshold=ndev*deviation;

	return(threshold);
}


/****************************************************************
*	RandomSwap function:
*		Generate a random set. The size of the set is NTRACE_SAMPLES.
*
****************************************************************/

int RandomSwap(void)
{

	unsigned int  rshift,Ncards;
	unsigned int  k,MixLevel,imin,imax;
	unsigned int  a;

	for(k=0; k<NTRACE_SAMPLES; k++) Random_Set[k]=(unsigned int )k;

	Ncards=NTRACE_SAMPLES;
	rshift= (unsigned int )(log(((double)RAND_MAX+1.0)/(double)NTRACE_SAMPLES)/log(2.0));
	MixLevel=5;

	for(k=0; k<MixLevel*Ncards; k++)
	{
		imin=(rand()>>rshift); 
		imax=(rand()>>rshift);
		a=Random_Set[imax];
		Random_Set[imax]=Random_Set[imin];
		Random_Set[imin]=a;
	}

	return(0);

}




/****************************************************************
*	RoundOff function:
*		Round a floating point number to the nearest integer.
*
*		Return Value:
*			rounded 32-bit integer
*
****************************************************************/

unsigned int  RoundOff(double x) { return((unsigned int )floor(x+0.5)); }





