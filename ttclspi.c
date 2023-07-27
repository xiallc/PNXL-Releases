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

// gcc -Wall ttclspi.c  -o ttclspi

// This is a debug function to re-run the WR clock PLL programming 
// normally part of booting. 

#include "PixieNetDefs.h"
//#include "PixieNetCommon.h"



int main( int argc, char *argv[] ) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;

   unsigned int addr, data, rw, k7;
   unsigned int reghi, reglo;
   unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};



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

  if( argc!=5)  {
     printf( "Please give arguments\n");
     printf( " 1) addr (0x##) for read/write\n");
     printf( " 2) data (0x####) for write \n" );
     printf( " 3) 0 for write, 1 for read\n");   
     printf( " 4) FPGA number (0 or 1) \n");   
     return -1;
   }

   addr = strtol(argv[1], NULL, 16);      // address 
   data = strtol(argv[2], NULL, 16);      // write data
   rw   = strtol(argv[3], NULL, 10);      // read or write
   k7   = strtol(argv[4], NULL, 10);      // FPGA/slot ID

   // ************************ prepare to write *********************************
        
   mapped[AMZ_DEVICESEL] = cs[k7];	            // select FPGA  
   mapped[AMZ_EXAFWR]    = AK7_PAGE;            // write to  K7's addr        addr 3 = channel/system, select    
   mapped[AMZ_EXDWR]     = PAGE_SYS;            //  0x000  = system page                

   if(rw==0)
   {
      // write 
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B =  SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;          // write to K7's addr     addr 0x1C =  SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI
      usleep(100);
   }
   else
   {
       // read 
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
      
      printf( " Return value 0x%4x \n", data);   
   }

  

   // ************************ clean up  *********************************

 
 // clean up  
 flock( fd, LOCK_UN );
 munmap(map_addr, size);
 close(fd);
 return data;
}










