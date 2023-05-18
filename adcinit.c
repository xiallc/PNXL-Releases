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
#include <math.h>
#include <time.h>
#include <signal.h>
#include <assert.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/file.h>

// gcc -Wall adcinit.c -o adcinit


#include "PixieNetDefs.h"
#include "PixieNetCommon.h"

/* This function is for DB01 and DB06 only */

int main( int argc, char *argv[] ) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;

  unsigned int mval = 0;
  unsigned int trys;
  unsigned int upper, lower;
  unsigned int frame;

  int k, k7, ch, ch_k7;                                     // ch = abs ch. no; ch_k7 = ch. no in k7
  unsigned int adc[NCHANNELS_PER_K7_DB01][14];
  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
  unsigned int goodframe = ADC_FRAME_DB01;                  // depends on FPGA compile?

  unsigned int revsn;                                       // HW revision and s/n
  unsigned int DACstart;                                    // starting value of DAC ramp
  unsigned int DACend;                                      // ending value of DAC ramp
  unsigned int DACstep;                                     // DAC increment per step
  unsigned int DACofADC2k[NCHANNELS*MAX_NGAINS] ={20000};   // result[NCHANNELS x Ngains]: DAC value that brings ADC to ~2000 (Todo)
  double noiseL[NCHANNELS*MAX_NGAINS] ={10000.0} ;          // result[NCHANNELS x Ngains]: lowest noise in ramp 
  double noiseH[NCHANNELS*MAX_NGAINS] ={0.1};               // result[NCHANNELS x Ngains]: highest noise in ramp 
  double slopes[NCHANNELS*MAX_NGAINS] ={0.0};               // result[NCHANNELS x Ngains]: ADC per DAC slope
  double I2Eoffset[NCHANNELS], I2Eslope[NCHANNELS] ;        // result[NCHANNEL] : odd/even sample mismatch
  double mis;
  double cfo =  3.24;                                       // adjustment coefficient for offsets  
  double cfs = -0.23;                                       // adjustment coefficient for gains    (depends on DAC step)
  double dval;
  unsigned int NI2EPAR = 10;                                // total 10 parameters for each ADC core
  unsigned int I2Edata[NI2EPAR*NCHANNELS];                  
  int I2Epolarity[NCHANNELS_PER_K7_DB01] = {1,-1,-1,-1};	   // depends on FPGA compile?
  long addr, data, mode;
 

  // *************** PS/PL IO initialization *********************
  // open the device for PD register I/O
  fd = open("/dev/uio0", O_RDWR);
  if (fd < 0) {
    perror("Failed to open devfile");
    return 1;
  }

  //Lock the PL address space so multiple programs cant step on each other.
  if( flock( fd, LOCK_EX | LOCK_NB ) )
  {
    printf( "Failed to get file lock on /dev/uio0\n" );
    return 1;
  }
  
  map_addr = mmap( NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);

  if (map_addr == MAP_FAILED) {
    perror("Failed to mmap");
    return 1;
  }

  mapped = (unsigned int *) map_addr;

  

  revsn = hwinfo(mapped,I2C_SELMAIN);    // some settings may depend on HW variants


  // ======================= DB01 ADC SPI programming =======================

  if( ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_125) ||
       ((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB01_14_75)   )
  {

      printf("Target frame pattern is 0x%02x\n",goodframe);  
   
   /*  // LVDS drive strength
      mapped[AMZ_DEVICESEL] = CS_K0;	                     // select FPGA 0 
      mapped[AMZ_EXAFWR] = AK7_ADCSPI;                      // write to  k7's addr     addr 5 = SPI
      mval = 0 << 15;                                       // SPI write (high bit=0)
      mval = mval + (0x02 << 8);                            // SPI reg address  (bit 13:8)
      mval = mval + 0x40;                                   // test pattern on, pattern bits [13:8]  = 0A
      mapped[AMZ_EXDWR] = mval;                             //  write to ADC SPI
      usleep(5);
    */
   
      // TODO: simply call function in PixieNetCommon.c?
   
      for(k7=0;k7<N_K7_FPGAS;k7++)
      {
         trys = 0;
         frame= 0;
      
         do {
            // read frame 
            mapped[AMZ_DEVICESEL] = cs[k7];	               // select FPGA  
             usleep(5);
            mapped[AMZ_EXAFWR] = AK7_PAGE;                  // write to  k7's addr        addr 3 = channel/system, select    
            mapped[AMZ_EXDWR] = PAGE_SYS;                   // 0x000  = system page                
            mapped[AMZ_EXAFRD] = AK7_ADCFRAME;              // write register address to  K7
            usleep(1);
            frame = mapped[AMZ_EXDRD] & 0xFF; 
            printf( "K7 %d: frame pattern is 0x%x (try %d) \n", k7, frame, trys);
            
            if(0) 
            {
               // todo: make test pattern optional
               for(k=0;k<14;k++) {
               
                  // set up test pattern            
                  if(k<8) {
                     upper = 0x0;
                     lower = (1<<k);
                  } else {
                     upper = (1<<(k-8));
                     lower = 0x0;
                  }         
               
                  mapped[AMZ_EXAFWR] = AK7_ADCSPI;          // write to  k7's addr     addr 5 = SPI
                  mval = 0 << 15;                           // SPI write (high bit=0)
                  mval = mval + (0x03 << 8);                // SPI reg address  (bit 13:8)
                  mval = mval + 0x80 +upper;                // test pattern on, pattern bits [13:8]  = 0A
                  mapped[AMZ_EXDWR] = mval;                 // write to ADC SPI
                  usleep(5);
                  
                  mapped[AMZ_EXAFWR] = AK7_ADCSPI;          // write to  k7's addr     addr 5 = SPI
                  mval = 0 << 15;                           // SPI write (high bit=0)
                  mval = mval + (0x04 << 8);                // SPI reg address  (bit 14:8)
                  mval = mval + lower;                      // test pattern on, pattern bits [7:0]  = BC
                  mapped[AMZ_EXDWR] = mval;                 // write to ADC SPI              
                  usleep(5);
                  //  printf( "test pattern is 0x%x \n", (addr<<8));
         
                  // read 1 sample from ADC register                               
                  for(ch_k7=0;ch_k7<NCHANNELS_PER_K7_DB01;ch_k7++) {    
                     mapped[AMZ_EXAFWR] = AK7_PAGE;         // write to  k7's addr        addr 3 = channel/syste, select    
                     mapped[AMZ_EXDWR] = PAGE_CHN+ch_k7;    // 0x100+ch  = page channel ch                         
                     mapped[AMZ_EXAFRD] = AK7_ADC;          // write register address to  K7
                     usleep(1);
                     adc[ch_k7][k] = mapped[AMZ_EXDRD];      
                  } // end for channels
                  
                  printf( "test pattern 0x%04x: adc0 0x%04x, adc1 0x%04x, adc2 0x%04x, adc3 0x%04x \n", (upper<<8)+lower, adc[0][k],adc[1][k],adc[2][k],adc[3][k] );
               }    // end for tespatterns
            } // end disable if
            
            
            // turn testpattern off again
            mapped[AMZ_EXAFWR] = AK7_ADCSPI;                // write to  k7's addr     addr 5 = SPI
            mval = 0 << 15;                                 // SPI write (high bit=0)
            mval = mval + (0x03 << 8);                      // SPI reg address  (bit 13:8)
            mval = mval + 0;                                // test pattern off
            mapped[AMZ_EXDWR] = mval;                       // write to ADC SPI
            usleep(5);
      
      
            if(frame!=goodframe) {
               // trigger a bitslip         
               mapped[AMZ_EXAFWR] = AK7_PAGE;               // write to  k7's addr        addr 3 = channel/system, select    
               mapped[AMZ_EXDWR] = PAGE_SYS;                // 0x000  = system page                           
               mapped[AMZ_EXAFWR] = AK7_ADCBITSLIP;         // write register address to  K7
               mapped[AMZ_EXDWR] = 0;                       // any write will do
            }
      
            trys = trys+1;
      
          } while(frame!=goodframe && trys<16);
   
          if(frame==goodframe)
            printf( "K7 %d: ADC initialized ok \n", k7);
          else
            printf( "K7 %d: ADC not initialized, try again? \n", k7);
   
      } // end for K7s
            
      mapped[AMZ_DEVICESEL] = CS_MZ;	                     // deselect FPGA 0  

  } // end DB01

   
  if((revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_16_250)
  {

     if (argc == 2) {
        addr    = strtol(argv[1], NULL, 16);
     }
     else
     {
         printf( "DB06 16/250 ADC  \n");
         printf( " 1 argument(s): specifies ADC register addr to read (hex)   \n");  
         return(0);
     }
    
     // test read
     k7    = 1;
     ch_k7 = 0;
     //addr  = 0x08;
     mval = ADCSPI_Read06(mapped, k7, ch_k7, addr);         // coarse offset, core 0
     printf( " Readback K7 %d, ch %d: ADC reg 0x%02X = 0x%02X \n", k7, ch_k7, (int)addr, mval);
     
     return(0);

  }
  
  
  // ======================= DB06 ADC I2E  =======================       

  if( (revsn & PNXL_DB_VARIANT_MASK) == PNXL_DB06_14_500)
  {

      if (argc == 5) {    // exactly 4 arguments write a value to an ADC register, then read back

        
        k7    = strtol(argv[1], NULL, 10);
        ch_k7 = strtol(argv[2], NULL, 10);
        addr  = strtol(argv[3], NULL, 16);
        data  = strtol(argv[4], NULL, 16);
        printf( " Writing to FPGA %d channel %d, address 0x%x, data 0x%lx \n", k7, ch_k7, (unsigned int)addr, data);

        ADCSPI_Write06(mapped, k7, ch_k7, addr, data) ;     
        usleep(1000);

        mval = ADCSPI_Read06(mapped, k7, ch_k7, addr);      // read I2E ctrl
        printf( " Readback K7 %d, ch %d: ADC reg 0x%02X = 0x%02X \n", k7, ch_k7, (unsigned int)addr, mval);
 
        return(0);
     } 

     if (argc == 2) {
        mode    = strtol(argv[1], NULL, 10);
     }
     else
     {
         printf( "DB06 14/500 ADC calibration requires ANALOG_GAIN = 2.4, CCSRA_POLARITY_05 = 1  \n");
         printf( " 1 argument(s): 0: measure mismatch and print,  \n");  
         printf( "                1: autoset values, freeze, measure mismatch and print \n");
         printf( "                2: init default values, freeze, measure mismatch and print  \n");
         printf( "                3: calibration procedure  \n");
         printf( " 4 argument(s): args specify FPGA, channel in FPGA, address (hex), data (hex) to write; \n");
         printf( "                write one register, readback, and exit  \n");
         return(0);
     }

    /* 
     // test read
     k7    = 1;
     ch_k7 = 0;
     addr  = 0x08;
     mval = ADCSPI_Read06(mapped, k7, ch_k7, addr);         // coarse offset, core 0
     printf( " Readback K7 %d, ch %d: ADC reg 0x%02X = 0x%02X \n", k7, ch_k7, (int)addr, mval);
     
     return(0);
     */

     DACstart = 15000;                                      // initialize
     DACend   = 40000; 
     DACstep  = 2000;
     mis = 100.0;
     trys = 0;

      // ----------  enable and freeze I2C to initialize ------------------
     for(k7=0;k7<N_K7_FPGAS;k7++)
     {
         for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7_DB01 ; ch_k7 ++ )
         {
            ch = ch_k7+k7*NCHANNELS_PER_K7_DB01;            // pre-compute channel number 

       /*   
            // print before init
            mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x30);   // read I2E status
            printf( " ch %d: ADC I2E status %02X \n", ch, mval);
            
            mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x31);   // read I2E ctrl
            printf( " ch %d: ADC I2E ctrl %02X \n", ch, mval);
            
            I2Edata[NI2EPAR*ch + 0] = ADCSPI_Read06(mapped, k7, ch_k7, 0x20); // coarse offset, core 0
            I2Edata[NI2EPAR*ch + 1] = ADCSPI_Read06(mapped, k7, ch_k7, 0x21); // fine offset, core 0
            I2Edata[NI2EPAR*ch + 2] = ADCSPI_Read06(mapped, k7, ch_k7, 0x22); // coarse gain, core 0
            I2Edata[NI2EPAR*ch + 3] = ADCSPI_Read06(mapped, k7, ch_k7, 0x23); // medium gain, core 0
            I2Edata[NI2EPAR*ch + 4] = ADCSPI_Read06(mapped, k7, ch_k7, 0x24); // fine gain, core 0
            
            I2Edata[NI2EPAR*ch + 5] = ADCSPI_Read06(mapped, k7, ch_k7, 0x26); // coarse offset, core 1
            I2Edata[NI2EPAR*ch + 6] = ADCSPI_Read06(mapped, k7, ch_k7, 0x27); // fine offset, core 1
            I2Edata[NI2EPAR*ch + 7] = ADCSPI_Read06(mapped, k7, ch_k7, 0x28); // coarse gain, core 1
            I2Edata[NI2EPAR*ch + 8] = ADCSPI_Read06(mapped, k7, ch_k7, 0x29); // medium gain, core 1
            I2Edata[NI2EPAR*ch + 9] = ADCSPI_Read06(mapped, k7, ch_k7, 0x2A); // fine gain, core 1
            
            printf( " ch %d: read addr 0x%02X (coarse offset 0) %02X \n", ch, 0x20, I2Edata[NI2EPAR*ch + 0]);
            printf( " ch %d: read addr 0x%02X (fine offset 0)   %02X \n", ch, 0x21, I2Edata[NI2EPAR*ch + 1]);
            printf( " ch %d: read addr 0x%02X (coarse gain 0)   %02X \n", ch, 0x22, I2Edata[NI2EPAR*ch + 2]);
            printf( " ch %d: read addr 0x%02X (medium gain 0)   %02X \n", ch, 0x23, I2Edata[NI2EPAR*ch + 3]);
            printf( " ch %d: read addr 0x%02X (fine gain 0)     %02X \n", ch, 0x24, I2Edata[NI2EPAR*ch + 4]);
            
            printf( " ch %d: read addr 0x%02X (coarse offset 1) %02X \n", ch, 0x26, I2Edata[NI2EPAR*ch + 5]);
            printf( " ch %d: read addr 0x%02X (fine offset 1)   %02X \n", ch, 0x27, I2Edata[NI2EPAR*ch + 6]);
            printf( " ch %d: read addr 0x%02X (coarse gain 1)   %02X \n", ch, 0x28, I2Edata[NI2EPAR*ch + 7]);
            printf( " ch %d: read addr 0x%02X (medium gain 1)   %02X \n", ch, 0x29, I2Edata[NI2EPAR*ch + 8]);
            printf( " ch %d: read addr 0x%02X (fine gain 1)     %02X \n", ch, 0x2A, I2Edata[NI2EPAR*ch + 9]);

            */
           
            if(mode>0)    // auto init in any case except read only mode 0
            {
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, 0x20) ; // addr 0x31: I2E control, value 0x20 = disable
               usleep(1000);
               
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, 0x21) ; // addr 0x31: I2E control, value 0x21 = enable
               usleep(100000);
               
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, 0x23) ; // addr 0x31: I2E control, value 0x23 = freeze
               usleep(1000);
               
               mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x30);  // read I2E status
               printf( " ch %d: ADC I2E status %02X \n", ch, mval);
               
               mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x31);  // read I2E ctrl
               printf( " ch %d: ADC I2E ctrl %02X \n", ch, mval);
            }

            I2Edata[NI2EPAR*ch + 0] = ADCSPI_Read06(mapped, k7, ch_k7, 0x20); // coarse offset, core 0
            I2Edata[NI2EPAR*ch + 1] = ADCSPI_Read06(mapped, k7, ch_k7, 0x21); // fine offset, core 0
            I2Edata[NI2EPAR*ch + 2] = ADCSPI_Read06(mapped, k7, ch_k7, 0x22); // coarse gain, core 0
            I2Edata[NI2EPAR*ch + 3] = ADCSPI_Read06(mapped, k7, ch_k7, 0x23); // medium gain, core 0
            I2Edata[NI2EPAR*ch + 4] = ADCSPI_Read06(mapped, k7, ch_k7, 0x24); // fine gain, core 0
            
            I2Edata[NI2EPAR*ch + 5] = ADCSPI_Read06(mapped, k7, ch_k7, 0x26); // coarse offset, core 1
            I2Edata[NI2EPAR*ch + 6] = ADCSPI_Read06(mapped, k7, ch_k7, 0x27); // fine offset, core 1
            I2Edata[NI2EPAR*ch + 7] = ADCSPI_Read06(mapped, k7, ch_k7, 0x28); // coarse gain, core 1
            I2Edata[NI2EPAR*ch + 8] = ADCSPI_Read06(mapped, k7, ch_k7, 0x29); // medium gain, core 1
            I2Edata[NI2EPAR*ch + 9] = ADCSPI_Read06(mapped, k7, ch_k7, 0x2A); // fine gain, core 1
            
            printf( " ch %d: read addr 0x%02X (coarse offset 0) %02X \n", ch, 0x20, I2Edata[NI2EPAR*ch + 0]);
            printf( " ch %d: read addr 0x%02X (fine offset 0)   %02X \n", ch, 0x21, I2Edata[NI2EPAR*ch + 1]);
            //printf( " ch %d: read addr 0x%02X (coarse gain 0)   %02X \n", ch, 0x22, I2Edata[NI2EPAR*ch + 2]);
            printf( " ch %d: read addr 0x%02X (medium gain 0)   %02X \n", ch, 0x23, I2Edata[NI2EPAR*ch + 3]);
            printf( " ch %d: read addr 0x%02X (fine gain 0)     %02X \n", ch, 0x24, I2Edata[NI2EPAR*ch + 4]);
            
            printf( " ch %d: read addr 0x%02X (coarse offset 1) %02X \n", ch, 0x26, I2Edata[NI2EPAR*ch + 5]);
            printf( " ch %d: read addr 0x%02X (fine offset 1)   %02X \n", ch, 0x27, I2Edata[NI2EPAR*ch + 6]);
            //printf( " ch %d: read addr 0x%02X (coarse gain 1)   %02X \n", ch, 0x28, I2Edata[NI2EPAR*ch + 7]);
            printf( " ch %d: read addr 0x%02X (medium gain 1)   %02X \n", ch, 0x29, I2Edata[NI2EPAR*ch + 8]);
            printf( " ch %d: read addr 0x%02X (fine gain 1)     %02X \n", ch, 0x2A, I2Edata[NI2EPAR*ch + 9]);  

      //    printf("\n");

            if (mode == 1 ) {   // .......... auto init and freeze ..........
               
               printf( "Mode 1: autoset values, then freeze \n\n");
               
            } // end if mode ==1
      
            if (mode == 2 ) {   // .......... init and write default I2E parameters ..........
                
               printf( "Mode 2: write default values, then freeze \n\n");

               // disable
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, 0x20);     // addr 0x31: I2E control, value 0x20 = disable
               usleep(1000);
      
               // write
               ADCSPI_Write06(mapped, k7, ch_k7, 0x20, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x21, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x22, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x23, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x24, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x26, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x27, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x28, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x29, 0x91) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x2A, 0x91) ;

               //freeze
               mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x31);     //I2E control
               mval = mval | 2;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, mval) ;    //bit 1: freeze
               usleep(1000);

               // enable but keep frozen
               mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x31);     //I2E control
               mval = mval | 1;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, mval) ;    // bit 0: run
               usleep(1000);

            } // end if mode ==2

         } // end for ch per K7
     } // end for K7
  

     // ---------- first round, just measure ------------------
     printf(" Ramping DACs ...  \n");
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
   
     printf("  ch I2C offset mismatch     gain mismatch  \n");
     mis=0.0;
     for( ch = 0; ch < 8; ch ++ )    // should be NCHANNELS
     {
         printf(" %2d        %7.4f             %7.4f\n",ch, I2Eoffset[ch], I2Eslope[ch] );
         mis = mis+ I2Eoffset[ch]*I2Eoffset[ch];
         mis = mis+ 100*(I2Eslope[ch] *I2Eslope[ch]);
     }
     printf("Combined mismatch   %7.4f  \n",sqrt(mis));


    // Mode 0-2 exits after init & measure
    if (mode <= 2) {
        return( 0);
    } 

    printf( "\n Mode 3: trying to calibrate, this will take several iterations \n");

    
    // ---------- loop a few times and improve -----------------
    while( (mis>2.0) && (trys <6) )    
    {

         for(k7=0;k7<N_K7_FPGAS;k7++)
         {
            for( ch_k7 = 0; ch_k7 < NCHANNELS_PER_K7_DB01 ; ch_k7 ++ )
            {
               ch = ch_k7+k7*NCHANNELS_PER_K7_DB01;            // pre-compute channel number 
                                                                                                                                                      

            // .......... read I2E parameters from ADC ..........

            // read/print status
            // mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x30); // I2E status
            // printf( " ch %d: read addr 0x%02X (I2E status) %02X \n", ch, 0x30, mval);
            // mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x31); //I2E control
            // printf( " ch %d: read addr 0x%02X (I2E control) %02X \n", ch, 0x31, mval);
                                        
               I2Edata[NI2EPAR*ch + 0] = ADCSPI_Read06(mapped, k7, ch_k7, 0x20); // coarse offset, core 0
               I2Edata[NI2EPAR*ch + 1] = ADCSPI_Read06(mapped, k7, ch_k7, 0x21); // fine offset, core 0
               I2Edata[NI2EPAR*ch + 2] = ADCSPI_Read06(mapped, k7, ch_k7, 0x22); // coarse gain, core 0
               I2Edata[NI2EPAR*ch + 3] = ADCSPI_Read06(mapped, k7, ch_k7, 0x23); // medium gain, core 0
               I2Edata[NI2EPAR*ch + 4] = ADCSPI_Read06(mapped, k7, ch_k7, 0x24); // fine gain, core 0

               I2Edata[NI2EPAR*ch + 5] = ADCSPI_Read06(mapped, k7, ch_k7, 0x26); // coarse offset, core 1
               I2Edata[NI2EPAR*ch + 6] = ADCSPI_Read06(mapped, k7, ch_k7, 0x27); // fine offset, core 1
               I2Edata[NI2EPAR*ch + 7] = ADCSPI_Read06(mapped, k7, ch_k7, 0x28); // coarse gain, core 1
               I2Edata[NI2EPAR*ch + 8] = ADCSPI_Read06(mapped, k7, ch_k7, 0x29); // medium gain, core 1
               I2Edata[NI2EPAR*ch + 9] = ADCSPI_Read06(mapped, k7, ch_k7, 0x2A); // fine gain, core 1

               if(0)  // optional print
               {
                  printf( " ch %d: read addr 0x%02X (coarse offset 0) %02X \n", ch, 0x20, I2Edata[NI2EPAR*ch + 0]);   
                  printf( " ch %d: read addr 0x%02X (coarse offset 1) %02X \n", ch, 0x26, I2Edata[NI2EPAR*ch + 5]);
                  printf( " ch %d: read addr 0x%02X (fine offset 1)   %02X \n", ch, 0x27, I2Edata[NI2EPAR*ch + 6]);
                  //printf( " ch %d: read addr 0x%02X (coarse gain 1)   %02X \n", ch, 0x28, I2Edata[NI2EPAR*ch + 7]);
                  printf( " ch %d: read addr 0x%02X (medium gain 1)   %02X \n", ch, 0x29, I2Edata[NI2EPAR*ch + 8]);
                  printf( " ch %d: read addr 0x%02X (fine gain 1)     %02X \n", ch, 0x2A, I2Edata[NI2EPAR*ch + 9]);
               }

            // .......... modify I2E parameters ..........
              
            // debug: fixed adjustment  
            // I2Edata[0+ch*NI2EPAR]=  (int)floor(I2Edata[ch*NI2EPAR]- I2Eoffset[ch]/2.0 );
            // if(I2Eoffset[ch] >0) 
            //      I2Edata[0+ch*NI2EPAR] = I2Edata[0+ch*NI2EPAR] -4;
            // else
            //      I2Edata[0+ch*NI2EPAR] = I2Edata[0+ch*NI2EPAR] +4;            

               if(fabs(I2Eoffset[ch]/cfo) >1)                  // coarse offset adjustment
               {
                  dval = (double)I2Edata[5+ch*NI2EPAR]+ I2Eoffset[ch]/cfo*(double)I2Epolarity[ch_k7];		// adjust coarse offset
                  //     printf(" coarse offset old  %f; mismatch %f; new %f\n", (double)I2Edata[ch*NI2EPAR], I2Eoffset[ch], dval);
                  
                  if(dval>=255.0)                              // this should not happen. If it does, probably the gain is off?
                  {
                     printf(" ch. %d coarse offset OOR: adjusting core 0 also\n", ch);
                     dval = I2Edata[0+ch*NI2EPAR] - 30.0;
                     if(dval<=0.0)
                        I2Edata[0+ch*NI2EPAR] = 5;
                     else 
                        I2Edata[0+ch*NI2EPAR] = dval;
                     
                     I2Edata[5+ch*NI2EPAR] = 252 ;  
                  }
                  else if(dval<=0.0)                           // this should not happen. If it does, adjust the other core
                  {
                     printf(" ch. %d coarse offset OOR: adjusting core 0 also\n", ch);
                     dval = I2Edata[0+ch*NI2EPAR] + 30.0;
                     if(dval>=255.0)
                        I2Edata[0+ch*NI2EPAR] = 250;
                     else 
                        I2Edata[0+ch*NI2EPAR] = dval;
                     
                     I2Edata[5+ch*NI2EPAR] = 2 ; 
                  }
                  else 
                     I2Edata[5+ch*NI2EPAR] = (int)floor(dval);
               } 
               else                                            // fine offset adjustment
               {
                  dval = (double)I2Edata[6+ch*NI2EPAR]+ I2Eoffset[ch]/cfo*20*(double)I2Epolarity[ch_k7];	// adjust fine offset
                  printf(" fine offset old  %f; mismatch %f; new %f\n", (double)I2Edata[ch*NI2EPAR+1], I2Eoffset[ch], dval);
                  I2Edata[6+ch*NI2EPAR] = (int)floor(dval);
                  if (dval <=0.0)                              // if out of range, adjust coarse instead
                  {
                     I2Edata[6+ch*NI2EPAR] = 50 ;
                     I2Edata[5+ch*NI2EPAR] -= 2 ;
                  }	
                  if (dval >=255.0)
                  {
                     I2Edata[6+ch*NI2EPAR] = 205 ;
                     I2Edata[5+ch*NI2EPAR] += 2 ;
                  }   
               } // end offset coarse/fine


               if(fabs(I2Eslope[ch]/cfs) >1)                   // medium gain adjustement
               {
                  dval = (double)I2Edata[8+ch*NI2EPAR]+I2Eslope[ch]/cfs*(double)I2Epolarity[ch_k7];		// adjust medium gain
                  I2Edata[8+ch*NI2EPAR] = (int)floor(dval);
                  if(dval>=255.0) I2Edata[8+ch*NI2EPAR] =  255;
                  if(dval<=0.0)   I2Edata[8+ch*NI2EPAR] =  0 ;
               }
               else                                            // fine gain adjustment
               {
                  dval = (double)I2Edata[9+ch*NI2EPAR]+I2Eslope[ch]/cfs*5*(double)I2Epolarity[ch_k7];	// adjust fine gain
                  printf(" fine gain old  %f; mismatch %f; new %f\n", (double)I2Edata[ch*NI2EPAR+4], I2Eoffset[ch], dval);
                  I2Edata[9+ch*NI2EPAR] = (int)floor(dval);
                  if (dval <=0.0)									// if out of range, adjust medium instead
                  {
                     I2Edata[9+ch*NI2EPAR] = 20  ;
                     I2Edata[8+ch*NI2EPAR] -= 2  ;
                  }
                  if (dval >=255.0)
                  {                              
                     I2Edata[9+ch*NI2EPAR] = 235 ;
                     I2Edata[8+ch*NI2EPAR] += 2  ;
                  }
               }  // end med/fine gain
      

               // .......... write back I2E parameters ..........

               // required sequence for parameters to stick: disable/write/freeze/enable(frozen)

               printf( " ch %d: proposed write addr 0x%02X %02X \n", ch, 0x20, I2Edata[NI2EPAR*ch + 0]);
               printf( " ch %d: proposed write addr 0x%02X %02X \n", ch, 0x26, I2Edata[NI2EPAR*ch + 5]);
               printf( " ch %d: proposed write addr 0x%02X %02X \n", ch, 0x27, I2Edata[NI2EPAR*ch + 6]);
               //printf( " ch %d: proposed write addr 0x%02X %02X \n", ch, 0x28, I2Edata[NI2EPAR*ch + 7]);
               printf( " ch %d: proposed write addr 0x%02X %02X \n", ch, 0x29, I2Edata[NI2EPAR*ch + 8]);
               printf( " ch %d: proposed write addr 0x%02X %02X \n", ch, 0x2A, I2Edata[NI2EPAR*ch + 9]);
              
               // disable
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, 0x20) ;    // addr 0x31: I2E control, value 0x20 = disable
               usleep(1000);
     
               // write
               ADCSPI_Write06(mapped, k7, ch_k7, 0x20, I2Edata[NI2EPAR*ch + 0]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x21, I2Edata[NI2EPAR*ch + 1]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x22, I2Edata[NI2EPAR*ch + 2]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x23, I2Edata[NI2EPAR*ch + 3]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x24, I2Edata[NI2EPAR*ch + 4]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x26, I2Edata[NI2EPAR*ch + 5]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x27, I2Edata[NI2EPAR*ch + 6]) ;        
               ADCSPI_Write06(mapped, k7, ch_k7, 0x28, I2Edata[NI2EPAR*ch + 7]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x29, I2Edata[NI2EPAR*ch + 8]) ;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x2A, I2Edata[NI2EPAR*ch + 9]) ;

               //freeze
               mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x31); //I2E control
            // printf( " ch %d: read addr 0x%02X (I2E control) %02X \n", ch, 0x31, mval&0xFF);
               mval = mval | 2;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, mval) ;    //bit 1: freeze
               usleep(1000);

               // enable but keep frozen
               mval = ADCSPI_Read06(mapped, k7, ch_k7, 0x31); //I2E control
           //  printf( " ch %d: read addr 0x%02X (I2E control) %02X \n", ch, 0x31, mval&0xFF);
               mval = mval | 1;
               ADCSPI_Write06(mapped, k7, ch_k7, 0x31, mval) ;    // bit 0: run
               usleep(100000);

                printf("\n");
      
            }  // end for channels per K7
         } // end for K7
      
      
        // .......... measure again ..........
        printf("  Ramping DACs ...  \n");
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
      
        printf("  ch I2C offset mismatch     gain mismatch  \n");
        mis=0.0;
        for( ch = 0; ch < 8; ch ++ )    // should be NCHANNELS
        {
            printf(" %2d        %7.4f             %7.4f\n",ch, I2Eoffset[ch], I2Eslope[ch] );
            mis = mis+ I2Eoffset[ch]*I2Eoffset[ch];
            mis = mis+ 100*(I2Eslope[ch] *I2Eslope[ch]);
        }
        printf("Combined mismatch   %7.4f  \n",sqrt(mis));

        trys++;    
     }  // end loop
   
   
     if (mis<= 10.0)
         printf("  ADC calibration done  \n");
     else
          printf("  ADC calibration not sucessful, please try again \n");
 
}  // end DB06 14/500

 
 // clean up  
 flock( fd, LOCK_UN );
 munmap(map_addr, size);
 close(fd);
 return 0;
}










