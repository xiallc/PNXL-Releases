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

#include "PixieNetDefs.h"
#include "PixieNetCommon.h"
#include "PixieNetConfig.h"

int main(void) {		 

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;
  int ch;      // ch = abs ch. no; ch_k7 = ch. no in k7
  unsigned int revsn;                        // HW revision and s/n
  unsigned int DACstart;                     // starting value of DAC ramp
  unsigned int DACend;                       // ending value of DAC ramp
  unsigned int DACstep;                      // DAC increment per step
  double noiseL[NCHANNELS*MAX_NGAINS] ={10000.0} ;      // result[NCHANNELS x Ngains]: lowest noise in ramp 
  double noiseH[NCHANNELS*MAX_NGAINS] ={0.1};      // result[NCHANNELS x Ngains]: highest noise in ramp 
  double slopes[NCHANNELS*MAX_NGAINS] ={0.0};      // result[NCHANNELS x Ngains]: ADC per DAC slope
  unsigned int DACofADC2k[NCHANNELS*MAX_NGAINS] ={20000};   // result[NCHANNELS x Ngains]: DAC value that brings ADC to ~2000 (Todo)
  unsigned int DACvalues[NCHANNELS];
  double I2Eoffset[NCHANNELS], I2Eslope[NCHANNELS] ;
  double mis;
  unsigned int NCHANNELS_PRESENT;

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


  // **************** Main code begins **********************
   
  // ******************* read ini file and fill struct with values ********************
  /* 
  PixieNetFippiConfig fippiconfig;		// struct holding the input parameters
  const char *defaults_file = "defaults.ini";
  int rval = init_PixieNetFippiConfig_from_file( defaults_file, 0, &fippiconfig );   // first load defaults, do not allow missing parameters
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
  */

  revsn = hwinfo(mapped,I2C_SELMAIN);    // some settings may depend on HW variants


  if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250) | 
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_14_250) | 
      ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250) )  {

         NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
         DACstart = 12000;
         DACend   = 55000; 
         DACstep  = 1000;         // also depends on gain!
  } else {
         NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
         DACstart = 10000;
         DACend   = 45000; 
         DACstep  = 500;         // also depends on gain!
  }

  printf(" Ramping offsets, this may take a while ...\n");

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

  printf(" noiseL      noiseH  slope  DACfor2K  I2E offset  I2E gain  at current gain\n");
  for( ch = 0; ch < NCHANNELS_PRESENT; ch ++ )    // should be NCHANNELS
  {
      printf(" %8.2f  %8.2f  %7.3f  %d    %7.3f   %7.3f\n",noiseL[ch], noiseH[ch], fabs(slopes[ch]), DACofADC2k[ch], I2Eoffset[ch], I2Eslope[ch] );
  }

  mis=0.0;
  for( ch = 0; ch < NCHANNELS_PRESENT; ch ++ )    // should be NCHANNELS
  {
      mis = mis+ I2Eoffset[ch]*I2Eoffset[ch];
      mis = mis+ 100*(I2Eslope[ch] *I2Eslope[ch]);
  }
  printf("Combined mismatch   %7.4f  \n",sqrt(mis));

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
  }

  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250)
         setdacs04(mapped,DACvalues);
  else
         setdacs01(mapped,DACvalues); 
  
  usleep(300000);    // extra  settling time
 
 // clean up  
 munmap(map_addr, size);
 close(fd);
 return 0;
}
