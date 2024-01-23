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
  int k,ch, k7, ch_k7;      // ch = abs ch. no; ch_k7 = ch. no in k7
  FILE * fil;
  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
  unsigned int adc[NCHANNELS][NTRACE_SAMPLES];
  char line[LINESZ];
  unsigned int GOOD_CH[NCHANNELS];
  unsigned int dt[NCHANNELS];
  unsigned int revsn, NCHANNELS_PER_K7, NCHANNELS_PRESENT, mval;


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


  // **************** mMin code begins **********************

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

  for( ch = 0; ch < NCHANNELS; ch ++ )
  {
      GOOD_CH[ch]  =  ( fippiconfig.CHANNEL_CSRA[ch] & (1<<CCSRA_GOOD) ) >0; 
      dt[ch]       =  (int)floor( fippiconfig.XDT[ch]*FILTER_CLOCK_MHZ_MOST);       // not supporting 75 MHz variant with this
      // printf( "ch %d, good %d, dt %d \n", ch, GOOD_CH[ch], dt[ch] );
  }

  // ************************** check HW version ********************************

   revsn = hwinfo(mapped,I2C_SELMAIN);    // some settings may depend on HW variants
   if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_12_250) |
       ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB02_14_250) |
       ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB04_14_250) |
       ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB08_14_250) )
   {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB02;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB02;
   }
   else
   {
      NCHANNELS_PRESENT =  NCHANNELS_PRESENT_DB01;
      NCHANNELS_PER_K7  =  NCHANNELS_PER_K7_DB01;
   }

     
   // ******************* read 8K samples from ADC register ********************
   // sampling is truly periodic only with new ADC FIFO
   
   for(k7=0;k7<N_K7_FPGAS;k7++)
   {
      mapped[AMZ_DEVICESEL] = cs[k7];	            // select FPGA 
      
      for(ch_k7=0;ch_k7<NCHANNELS_PER_K7;ch_k7++) {
         ch = ch_k7+k7*NCHANNELS_PER_K7;
  
         // buffered FIFO read
         mapped[AMZ_EXAFWR] = AK7_PAGE;     // write to  k7's addr        
         mapped[AMZ_EXDWR] = PAGE_SYS;                                           

         if(GOOD_CH[ch]==1)
         {

            // write channel and dt
            mval =  ch_k7 + ((dt[ch]&0xFF)<<8);        // ch and lower byte of XDT
            mapped[AMZ_EXAFWR] = AK7_ADC_CHANNEL;      // write to  k7's addr to select register for write
            mapped[AMZ_EXDWR]  = mval;                 // write lower 16 bit
            mval = (dt[ch]>>8) & 0xFFFF;               // upper 2 bytes of XDT
            mapped[AMZ_EXAFWR] = AK7_ADC_INTERVAL;     // write to  k7's addr to select register for write
            mapped[AMZ_EXDWR]  = mval;                 // write upper 16 bit and start collecting
    
            // read samples
            for(k=0;k<NTRACE_SAMPLES/2;k++) {
               mapped[AMZ_EXAFRD] = AK7_ADC_FIFO_L;     // write to  k7's addr
               adc[ch][2*k+0] = mapped[AMZ_EXDRD]; 
   
               // alternate high/low to get data from each ADC core (14/500)
               mapped[AMZ_EXAFRD] = AK7_ADC_FIFO_H;     // write to  k7's addr
               adc[ch][2*k+1] = mapped[AMZ_EXDRD]; 

            }       //    end for NTRACE_SAMPLES  

            // suppress the first few samples, may be bogus
            adc[ch][0] = adc[ch][6]; 
            adc[ch][1] = adc[ch][7]; 
            adc[ch][2] = adc[ch][8]; 
            adc[ch][3] = adc[ch][9]; 

         }
         else
         {
            for(k=0;k<NTRACE_SAMPLES;k++) {
               adc[ch][k] = 1;    // non-good channels: set to +1 
            }    //    end for NTRACE_SAMPLES 
         }  // end good/bad channel

       /*  old style: direct read
         mapped[AMZ_EXAFWR] = AK7_PAGE;     // write to  k7's addr        addr 3 = channel/syste, select    
         mapped[AMZ_EXDWR] = PAGE_CHN+ch_k7;                                //  0x100  =channel 0                  
         
         if(GOOD_CH[ch]==1)
         {
            mapped[AMZ_EXAFRD] = AK7_ADC;     // write to  k7's addr  // dummy read
            adc[ch][0] = mapped[AMZ_EXDRD]; 
            for(k=0;k<NTRACE_SAMPLES;k++) {
               mapped[AMZ_EXAFRD] = AK7_ADC;     // write to  k7's addr
               //        usleep(1);
               adc[ch][k] = mapped[AMZ_EXDRD];    
            }       //    end for NTRACE_SAMPLES  
          }
          else
            for(k=0;k<NTRACE_SAMPLES;k++) {
               adc[ch][k] = 1;    // non-good channels: set to +1 
            }    //    end for NTRACE_SAMPLES 
          */


      } // end for channels
   }  // end for K7s



   // read the webpage template and print 
   fil = fopen("adcpage.html","r");
   for( k = 0; k < 147; k ++ )
   {
      fgets(line, LINESZ, fil);     // read from template, first part
      if(k==69)
         printf("<h1>Pixie-Net ADC Traces (current)</h1>\n");            // "print" to webserver on stdout  
      else if(k==84)
         printf("<i><p>This page displays the ADC waveforms just read from the Pixie-Net</p>\n");            // "print" to webserver on stdout  
      else
         printf("%s",line);            // "print" to webserver on stdout  
   }   
   
   fgets(line, LINESZ, fil);        // read from template, the line listing the ADC.csv file. This is not printed
   printf("          \"sample");
   for(ch=0;ch<NCHANNELS_PRESENT;ch++) printf(",adc%d",ch);
   printf("\\n\"  +  \n");

   // print the data
   for( k = 0; k < NTRACE_SAMPLES; k ++ )
   {
     // printf("\"%d",k);                  // sample number
     // printf("\"%d",k*(int)floor( fippiconfig.XDT[ch]*1000)  );           // time in ns
        printf("\"%f",k* fippiconfig.XDT[0]  );           // time in us
        for(ch=0;ch<NCHANNELS_PRESENT;ch++) printf(",%d",adc[ch][k]);    // print channel data
        printf("\\n \"  + \n");
   }

   // dummy line: comma, not + required in last line
   //printf("\"%d",k);                  // sample number
   printf("\"%f",k* fippiconfig.XDT[0]  );           // time in us
   for(ch=0;ch<NCHANNELS_PRESENT;ch++)  printf(",%d",adc[ch][k-1]);    // print channel data
   printf("\\n \"  , \n");


   // finish printing the webpage
   for( k = 148; k < 176; k ++ )
   {
      fgets(line, LINESZ, fil);        // read from template
      printf("%s",line);               // "print" to webserver on stdout
   }   

// clean up  
munmap(map_addr, size);
close(fd);
fclose(fil);
return 0;
}
