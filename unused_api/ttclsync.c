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
#include <assert.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/file.h>

// gcc -Wall ttclsync.c  -o ttclsync

// This is a debug function to read the current TTCL time from TTCL adapter (via SPI), compute a future time to sync, 
// and write it to the TTCL adapter and the Kintex 

#include "PixieNetDefs.h"
//#include "PixieNetCommon.h"



int main( int argc, char *argv[] ) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;

   unsigned int addr, data, k7;
   unsigned int reghi, reglo;
   unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};
   unsigned long long offset, TTCL_current_time, TTCL_sync_time;
   unsigned int tmp0, tmp1, tmp2;

   // TTCL adapter constants (for now)
   unsigned int TTCL_APC = 0;          // pulse control register
   unsigned int TTCL_ATS_LO = 4;       // addresses for current time registers
   unsigned int TTCL_ATS_MI = 5;
   unsigned int TTCL_ATS_HI = 6;
   unsigned int TTCL_ASYNCT_LO = 9;       // addresses for taget sync time registers  TODO: confirm
   unsigned int TTCL_ASYNCT_MI = 10;
   unsigned int TTCL_ASYNCT_HI = 11;
 
  // *************** PS/PL IO initialization *********************
  // open the device for PD register I/O
  fd = open("/dev/uio0", O_RDWR);
  if (fd < 0) {
    perror("Failed to open devfile");
    return 1;
  }

  //Lock the PL address space so multiple programs cant step on eachother.
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

 


 // ************************ parse arguments *********************************

  if( argc!=2)  {
     printf( "Please give arguments\n");
     printf( " 1) Sync offset to current time\n");
     return -1;
   }

   offset  = strtol(argv[2], NULL, 10);      // offset


   // ************************ loop over both Kintex *********************************

   for(k7=0;k7<N_K7_FPGAS;k7++)
   {

      mapped[AMZ_DEVICESEL] = cs[k7];	            // select FPGA  
      mapped[AMZ_EXAFWR]    = AK7_PAGE;            // write to  K7's addr        addr 3 = channel/system, select    
      mapped[AMZ_EXDWR]     = PAGE_SYS;            // 0x000  = system page                

      // get current TTCL time from TTCL adapter
      // a) write to latch time
      addr = TTCL_APC;
      data = 1;      // TODO: bit pattern to latch time
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B =  SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;          // write to K7's addr     addr 0x1C =  SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI
      usleep(100);

      // b) read 3 registers
      addr = TTCL_ATS_LO;
      data = 0;
         // subroutine SPI read
         reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
         mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
         mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
         reglo = (data & 0xFFFF);     
         mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
         mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
         usleep(100);
         mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      tmp0 =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  tmp0 =  mapped[AMZ_EXDRD];  // again to capture properly    

      addr = TTCL_ATS_MI;
      data = 0;
         // subroutine SPI read
         reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
         mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
         mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
         reglo = (data & 0xFFFF);     
         mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
         mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
         usleep(100);
         mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      tmp1 =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  tmp1 =  mapped[AMZ_EXDRD];  // again to capture properly    


      addr = TTCL_ATS_HI;
      data = 0;
         // subroutine SPI read
         reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
         mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
         mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
         reglo = (data & 0xFFFF);     
         mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
         mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
         usleep(100);
         mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      tmp2 =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  tmp2 =  mapped[AMZ_EXDRD];  // again to capture properly  
  
      // combine into 48 bit time
      TTCL_current_time = tmp0 +  65536*tmp1 + TWOTO32*tmp2;
      printf( "Current TTCL time %llu  (0x%04x %04x %04x)\n",TTCL_current_time, tmp2, tmp1, tmp0 );

      // add offset
      TTCL_sync_time = TTCL_current_time + offset;
      printf( "Target Sync TTCL time %llu \n",TTCL_sync_time );

      // write target sync time to Kintex
      mapped[AMZ_EXAFWR] =  AK7_TTCL_STNC_TIME+0;   // specify   K7's addr:    TTCL sync time register
      mapped[AMZ_EXDWR]  =  TTCL_sync_time      & 0x00000000FFFF;
      mapped[AMZ_EXAFWR] =  AK7_TTCL_STNC_TIME+1;   // specify   K7's addr:    TTCL sync time register
      mapped[AMZ_EXDWR]  =  (TTCL_sync_time>>16) & 0x00000000FFFF;
      mapped[AMZ_EXAFWR] =  AK7_TTCL_STNC_TIME+2;   // specify   K7's addr:    TTCL sync time register
      mapped[AMZ_EXDWR]  =  (TTCL_sync_time>>32) & 0x00000000FFFF;

      // write time to TTCL adapter  (3 registers)
      addr = TTCL_ASYNCT_LO;
      data = TTCL_sync_time      & 0x00000000FFFF;
         // subroutine SPI write
         reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
         mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B =  SPIA  
         mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
         reglo = (data & 0xFFFF);     
         mapped[AMZ_EXAFWR] = AK7_PLLSPID;          // write to K7's addr     addr 0x1C =  SPID and starts the serial output
         mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI
         usleep(100);

      addr = TTCL_ASYNCT_MI;
      data = (TTCL_sync_time>>16) & 0x00000000FFFF;
         // subroutine SPI write
         reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
         mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B =  SPIA  
         mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
         reglo = (data & 0xFFFF);     
         mapped[AMZ_EXAFWR] = AK7_PLLSPID;          // write to K7's addr     addr 0x1C =  SPID and starts the serial output
         mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI
         usleep(100);

      addr = TTCL_ASYNCT_HI;
      data = (TTCL_sync_time>>32) & 0x00000000FFFF;
         // subroutine SPI write
         reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
         mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B =  SPIA  
         mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
         reglo = (data & 0xFFFF);     
         mapped[AMZ_EXAFWR] = AK7_PLLSPID;          // write to K7's addr     addr 0x1C =  SPID and starts the serial output
         mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI
         usleep(100);

      // TODO: check if a write to PC is needed to apply the time

      // wait some more for the sync to happen, then check 
      usleep(10000);

      //this reads the current time from Kintex
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+0;   
      tmp0 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp0 =  mapped[AMZ_EXDRD];
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+1;   
      tmp1 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp1 =  mapped[AMZ_EXDRD];
      mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+2;   
      tmp2 =  mapped[AMZ_EXDRD];
      if(SLOWREAD)      tmp2 =  mapped[AMZ_EXDRD];
      TTCL_current_time = tmp0 +  65536*tmp1 + TWOTO32*tmp2;
      printf( "Current TTCL time (Kintex) %llu  (0x%04x %04x %04x)\n",TTCL_current_time, tmp2, tmp1, tmp0 );

      // can read TTCL adapter time again

   } // end for Kintex


  

   // ************************ clean up  *********************************

 
 // clean up  
 flock( fd, LOCK_UN );
 munmap(map_addr, size);
 close(fd);
 return data;
}










