/*----------------------------------------------------------------------
 * Copyright (c) 2023 XIA LLC
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

// gcc -Wall ttcltime.c PixieNetCommon.o -lm -o ttcltime

// This is a debug function to read the current time from the TTCL interface card

#include "PixieNetDefs.h"
#include "PixieNetCommon.h"



int main( int argc, char *argv[] ) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;

  unsigned int addr=0;
  unsigned int data=0;
  unsigned int k7; //, k;
  unsigned int reghi, reglo;
  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};

  unsigned long long ti_time, ki_time;

  /*  comment out to suppress warnings for unused I2C variables
  const char *ini_file = "ttcliic.ini";   
  unsigned int Nwrites, vc;
  unsigned int linecount=1;
  unsigned int wc2=0;
  FILE * fil;
  char line[LINESZ];
  char* comment;
  char s2[] = "# ";

  unsigned int a0a1 = 0;
  unsigned int rw = 0;
  unsigned int i2cdata[8] = {0};
  unsigned int mval = 0;
  unsigned int ctrl[8];
 */


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

 

    
   k7=1; // TODO: loop over both FPGAs 
   mapped[AMZ_DEVICESEL] = cs[k7];	            // select FPGA  
   mapped[AMZ_EXAFWR]    = AK7_PAGE;            // write to  K7's addr        addr 3 = channel/system, select    
   mapped[AMZ_EXDWR]     = PAGE_SYS;            //  0x000  = system page                


    // ********************************* read last TTCL trigger time *****************************



      // -------------------------------------------------------------------
      // 2.read time (high)   (continously latched by TTCL trigger)
      // -------------------------------------------------------------------

      addr = 6;
      reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      data =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  data =  mapped[AMZ_EXDRD];  // again to capture properly    

      printf( " TTCL trigger time   = 0x%04X ", data); 
      ti_time = (unsigned long long)data << 32;

      // -------------------------------------------------------------------
      // 3.read time (mid)
      // -------------------------------------------------------------------

      addr = 5;
      reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      data =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  data =  mapped[AMZ_EXDRD];  // again to capture properly    

      printf( " %04X ", data); 
      ti_time = ti_time + ((unsigned long long)data << 16);

      // -------------------------------------------------------------------
      // 4.read time (low)
      // -------------------------------------------------------------------

      addr = 4;
      reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      data =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  data =  mapped[AMZ_EXDRD];  // again to capture properly    

      printf( " %04X [latched] \n", data); 
      ti_time = ti_time + (unsigned long long)data;


   // ********************************* read current TTCL time *****************************

       // -------------------------------------------------------------------
       //1,Latch timestamp via pulsed control reg
       // The first thing to check is bit 0 of this register, DS92LV18 LOCK*
       // -------------------------------------------------------------------

      addr = 0;   // pulse control reg
      data = 0x4000;   // set bit 14
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);


      // -------------------------------------------------------------------
      // 2.read time (high)
      // -------------------------------------------------------------------

      addr = 6;
      reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      data =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  data =  mapped[AMZ_EXDRD];  // again to capture properly    

      printf( " TTCL current time   = 0x%04X ", data); 
      ti_time = (unsigned long long)data << 32;

      // -------------------------------------------------------------------
      // 3.read time (mid)
      // -------------------------------------------------------------------

      addr = 5;
      reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      data =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  data =  mapped[AMZ_EXDRD];  // again to capture properly    

      printf( " %04X ", data); 
      ti_time = ti_time + ((unsigned long long)data << 16);

      // -------------------------------------------------------------------
      // 4.read time (low)
      // -------------------------------------------------------------------

      addr = 4;
      reghi = (addr & 0x7F) + 0x80;             // 7 bits of address, bit 8 = 1 for read
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      mapped[AMZ_EXAFRD] = AK7_SPI_RETURN;      // write to K7's addr     addr 0x96 = SPI return value  
      data =  mapped[AMZ_EXDRD];                // read from K7
      if(SLOWREAD)  data =  mapped[AMZ_EXDRD];  // again to capture properly    

      printf( " %04X [latched] \n", data); 
      ti_time = ti_time + (unsigned long long)data;


      // ********************************* read Kintex time *****************************


      // -------------------------------------------------------------------
      // 1.read Kintex time (low)
      // -------------------------------------------------------------------


      mapped[AMZ_DEVICESEL] = cs[k7];
      mapped[AMZ_EXAFWR] = AK7_PAGE;     // specify   K7's addr     addr 3 = channel/system
      mapped[AMZ_EXDWR]  = PAGE_SYS;     //                         0x000  = system     -> now addressing system page of K7-0   

      mapped[AMZ_EXAFRD] = AK7_SYS_RS+15;    // read from system output range
      data = mapped[AMZ_EXDRD];
      if(SLOWREAD) data = mapped[AMZ_EXDRD];  
      printf( " Kintex time         = 0x%04X ", data); 
      ki_time = (unsigned long long)data << 32;

      mapped[AMZ_EXAFRD] = AK7_SYS_RS+14;    // read from system output range
      data = mapped[AMZ_EXDRD];
      if(SLOWREAD) data = mapped[AMZ_EXDRD];  
      printf( " %04X ", data); 
      ki_time = ki_time + (data << 16);

      mapped[AMZ_EXAFRD] = AK7_SYS_RS+13;    // read from system output range
      data = mapped[AMZ_EXDRD];
      if(SLOWREAD) data = mapped[AMZ_EXDRD];  
      printf( " %04X [not latched]\n", data); 
      ki_time = ki_time + data;

      // -------------------------------------------------------------------
      // 2. compare
      // -------------------------------------------------------------------

       printf( " difference %lld \n", (ti_time - ki_time)); 


      // ********************************* read trigger cont in Kintex *****************************


       mapped[AMZ_DEVICESEL] = cs[k7];
      mapped[AMZ_EXAFWR] = AK7_PAGE;     // specify   K7's addr     addr 3 = channel/system
      mapped[AMZ_EXDWR]  = PAGE_SYS;     //                         0x000  = system     -> now addressing system page of K7-0   

      mapped[AMZ_EXAFRD] = AK7_SYS_RS+7;    // read from system output range
      data = mapped[AMZ_EXDRD];
      if(SLOWREAD) data = mapped[AMZ_EXDRD];  
      printf( " Kintex trigger count = 0x%04X \n", data); 






   // ************************ clean up  *********************************

 
 // clean up  
 flock( fd, LOCK_UN );
 munmap(map_addr, size);
 close(fd);
 return data;
}










