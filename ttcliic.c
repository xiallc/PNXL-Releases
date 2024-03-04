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

// gcc -Wall ttcliic.c PixieNetCommon.o -lm -o ttcliic


#include "PixieNetDefs.h"
#include "PixieNetCommon.h"

int main( int argc, char *argv[] ) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;
  int k;

  unsigned int a0a1 = 0;
  unsigned int addr = 0x01;
  unsigned int data = 0x00;
  unsigned int rw = 0;
  unsigned int i2cdata[8] = {0};
  unsigned int mval = 0;
  unsigned int ctrl[8];
  unsigned int version = 2;

  const char *ini_file = "ttcliic.ini";   
  unsigned int Nwrites, vc;
  unsigned int linecount=1;
  unsigned int wc2=0;
  FILE * fil;
  char line[LINESZ];
  char* comment;
  char s2[] = "# ";



  ctrl[7] = 1;      // TTCL Si jitter cleaner device address
  ctrl[6] = 1;
  ctrl[5] = 0;
  ctrl[4] = 1;  
  ctrl[3] = 0;
  ctrl[2] = 0;       // A1 SM jumper select
  ctrl[1] = 0;       // A0 SM jumper select
  ctrl[0] = 0;       // r/w

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

  if( !(argc==5 || argc==2) ) {
     printf( "Please give arguments\n");
     printf( " 1) addr (0x##) for read/write\n");
 //  printf( "    0x01 page, 02/03 p/n ...\n" );
     printf( " 2) data (0x##) for write \n" );
     printf( " 3) 0 for write, 1 for read\n");   
     printf( " 4) A0/A1 as decimal (0-3 for 00, 01, 10, 11) \n");  
     printf( "  \n");  
     printf( " or just one argument with the ini file name \n");  
     printf( "  \n");  
     printf( "  ( ttliic version %d) \n", version);
     return 2;
   }

   if (argc==5)
   {
      addr = strtol(argv[1], NULL, 16);      // address from test read
      data = strtol(argv[2], NULL, 16);      // data 
      rw   = strtol(argv[3], NULL, 10);      // read or write
      a0a1 = strtol(argv[4], NULL, 10);      // device address bits
      ctrl[2] = a0a1 & 0x0002;       // SM jumper select
      ctrl[1] = a0a1 & 0x0001;       // SM jumper select
      Nwrites = 1;
   }

   if (argc==2)
   {
      ini_file = argv[1];
      fil = fopen(ini_file,"r");
      if (fil == NULL) {
        printf("Error opening file");
        return(-1);
      }
      fgets(line, LINESZ, fil);              // read first line, number of entries (total # lines with comments)
      Nwrites = strtol(line, NULL, 10);
      printf( " file name %s \n", ini_file );
      printf( " first line %s (%d)\n", line, Nwrites );

      do{
         fgets(line, LINESZ, fil);     // read next line, address etc
         comment = strstr(line, s2);   // check if it's a comment
         if(comment) {
            printf(" comment line %s",line);
            linecount++;
          }
      } while ((comment!=NULL) & (linecount < Nwrites-1));

      vc = sscanf(line, "0x%X, 0x%X, %d, %d", &addr, &data, &rw, &a0a1);
      if(vc<4)       // import from SL tool register map has only adderess and data to write
      {
         rw   = 0;   // default write
         a0a1 = 3;   // default address pins 00
      }
      printf( " addr 0x%X, data 0x%X, rw %d, a0a1 %d (read first %d from file) \n", addr, data, rw, a0a1, vc );
      ctrl[2] = a0a1 & 0x0002;       // SM jumper select
      ctrl[1] = a0a1 & 0x0001;       // SM jumper select

//      return(0);
    }


   // ************************ prepare to write *********************************

   mapped[AMZ_DEVICESEL] = CS_MZ;	  // read/write from/to MZ IO block
   mval = I2C_SELMAIN ;             // set bit 4 to select MZ I2C pins
   mapped[AAUXCTRL] = mval;
   


   for(linecount=linecount;linecount<Nwrites;linecount++)
   {

      if(a0a1>3) {
         printf( "invalid A0/A1 \n" );
         fclose(fil);
         mapped[AAUXCTRL] = 0;
         flock( fd, LOCK_UN );
         munmap(map_addr, size);
         if (argc==2) close(fd);
         return -2;
      }
      
      if(wc2==3)   usleep(30000);    // for programming sequence exported from SL tool, pause for 300ms init after write #3

   
        // ************************ I2C programming EEPROM *********************************
      
   
       if (rw==0) {  
         wc2++;      // count actual writes
    
          // ============== write the data to the addr ======================
          
             // 3 bytes: ctrl, addr, data  : 

            // addr = 0x2D;
            // data = 0x44;

            I2Cstart(mapped);
            ctrl[0] = 0;   // R/W*
            I2Cbytesend(mapped, ctrl);     // I2C control byte: write
            I2Cslaveack(mapped);  
         
            mval = addr;   // register address  
            i2cdata[7] = (mval & 0x0080) >> 7 ;    
            i2cdata[6] = (mval & 0x0040) >> 6 ;    
            i2cdata[5] = (mval & 0x0020) >> 5 ;    
            i2cdata[4] = (mval & 0x0010) >> 4 ;
            i2cdata[3] = (mval & 0x0008) >> 3 ;    
            i2cdata[2] = (mval & 0x0004) >> 2 ;   
            i2cdata[1] = (mval & 0x0002) >> 1 ;    
            i2cdata[0] = (mval & 0x0001)      ;   
            I2Cbytesend(mapped, i2cdata);
            I2Cslaveack(mapped);
         
            mval = data;  //  register data  
            i2cdata[7] = (mval &  0x0080) >> 7 ;    
            i2cdata[6] = (mval &  0x0040) >> 6 ;    
            i2cdata[5] = (mval &  0x0020) >> 5 ;    
            i2cdata[4] = (mval &  0x0010) >> 4 ; 
            i2cdata[3] = (mval &  0x0008) >> 3 ;    
            i2cdata[2] = (mval &  0x0004) >> 2 ;   
            i2cdata[1] = (mval &  0x0002) >> 1 ;   
            i2cdata[0] = (mval &  0x0001)      ;  
            I2Cbytesend(mapped, i2cdata);
            I2Cslaveack(mapped);
         
            I2Cstop(mapped);
            usleep(10000);
         
            if((wc2<10) | (wc2%10==1))  printf(" -- write %d done\n", wc2);  
   
        }   // end write
        else
        {
   
         
       // ************* read from addr  ***********************
   
           // 2 bytes: ctrl, addr  
         I2Cstart(mapped);
         ctrl[0] = 0;   // R/W*         // write starting addr to read from
         I2Cbytesend(mapped, ctrl);
         I2Cslaveack(mapped);
   
         mval = addr;   
         i2cdata[7] = (mval & 0x0080) >> 7 ;    
         i2cdata[6] = (mval & 0x0040) >> 6 ;    
         i2cdata[5] = (mval & 0x0020) >> 5 ;    
         i2cdata[4] = (mval & 0x0010) >> 4 ;
         i2cdata[3] = (mval & 0x0008) >> 3 ;    
         i2cdata[2] = (mval & 0x0004) >> 2 ;   
         i2cdata[1] = (mval & 0x0002) >> 1 ;    
         i2cdata[0] = (mval & 0x0001)      ;   
         I2Cbytesend(mapped, i2cdata);
         I2Cslaveack(mapped);
   
         I2Cstop(mapped);
         usleep(1000);
   
      
         // 2 bytes: ctrl, data  
         I2Cstart(mapped);
         ctrl[0] = 1;   // R/W*         // write device ID, then read a word
         I2Cbytesend(mapped, ctrl);
         I2Cslaveack(mapped);
   
         mval = 0;
         I2Cbytereceive(mapped, i2cdata);
         for( k = 0; k < 8; k ++ )
            if(i2cdata[k])
               mval = mval + (1<<(k));
         I2Cmasterack(mapped);
      
         //I2Cmasterack(mapped);
         I2Cmasternoack(mapped);
         I2Cstop(mapped);
   
         usleep(10000); 

         printf(" -- I2C read from 0x%02X:  0x%02X\n",addr & 0xFF, mval);
      
      }    // end read
      
   
      


      if(linecount<Nwrites-1)   // get next line
      {
         do{
            fgets(line, LINESZ, fil);     // read next line, address etc
            comment = strstr(line, s2);   // check if it's a comment
            if(comment) {
               printf(" comment line %s",line);
               linecount++;
             }
         } while ((comment!=NULL) & (linecount < Nwrites-1));

         vc = sscanf(line, "0x%X, 0x%X, %d, %d", &addr, &data, &rw, &a0a1);
         if(vc<4)       // import from SL tool register map has only adderess and data to write
         {
            rw   = 0;   // default write
            a0a1 = 0;   // default address pins 00
         }
         if((wc2<1000) | (wc2%10==1)) printf( " addr 0x%X, data 0x%X, rw %d, a0a1 %d (read first %d from file) \n", addr, data, rw, a0a1, vc );
         ctrl[2] = a0a1 & 0x0002;       // SM jumper select
         ctrl[1] = a0a1 & 0x0001;       // SM jumper select
      }

   } //end for
     
 
 // clean up  
 if (argc==2) fclose(fil);
 mapped[AAUXCTRL] = 0;

 flock( fd, LOCK_UN );
 munmap(map_addr, size);
 close(fd);
 return 0;
}










