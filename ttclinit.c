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

// gcc -Wall ttclinit.c PixieNetCommon.o -lm -o ttclinit

// This is a debug function to initialize the TTCL interface card

#include "PixieNetDefs.h"
#include "PixieNetCommon.h"



int main( int argc, char *argv[] ) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;

  unsigned int addr=0;
  unsigned int data=0;  
  unsigned int Mdelay=200;
  unsigned int Tdelay=50;
  unsigned int k7; //, k;
  unsigned int reghi, reglo;
  unsigned int cs[N_K7_FPGAS] = {CS_K0,CS_K1};

  // set a few constants for the addresses
  unsigned int A_PULSED_CONTROL_REG = 0;
  unsigned int A_SERDES_CTL_REG = 1;
  unsigned int A_DIAGNOSTIC_CTL_REG = 3;
  unsigned int A_TIMESTAMP_OFFSET_REG = 7;
  unsigned int A_ACCEPT_MSG_DELAY_REG = 8;
  unsigned int A_STATUS_REG = 13;
  unsigned int A_CODE_DATE = 126;
  unsigned int A_CODE_REVISION = 127;

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

 


 // ************************ parse arguments *********************************

  if( argc!=3)  {
     printf( "Please give arguments\n");
     printf( " 1) for ACCEPT_MSG_DELAY_REG (message propagation, default 0x200)\n");
     printf( " 2) for TIMESTAMP OFFSET REG (Pixie energy filter, default 0x50)\n");
     return -1;
   }

   Mdelay = strtol(argv[1], NULL, 0);     
   Tdelay = strtol(argv[2], NULL, 0); 

   
   // ************************ prepare to write *********************************
    
   k7=1; // TODO: loop over both FPGAs 
   for(k7=0;k7<2;k7++)
   {
      mapped[AMZ_DEVICESEL] = cs[k7];	            // select FPGA  
      mapped[AMZ_EXAFWR]    = AK7_PAGE;            // write to  K7's addr        addr 3 = channel/system, select    
      mapped[AMZ_EXDWR]     = PAGE_SYS;            //  0x000  = system page                
      printf( " Configuring Kintex # %d \n", k7);      

        // -------------------------------------------------------------------
       // 0. Read Spartan 6 FW date and revision
       // -------------------------------------------------------------------

      addr = A_CODE_DATE;
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
      printf( "  Code Date: 0x%04X  \n", data);      


      addr = A_CODE_REVISION;
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
      printf( "  Code Revision: %d  \n", data); 
   
   
       // -------------------------------------------------------------------
       //1,3. After power up and initialization, read STATUS_REG, address 13.  
       // The first thing to check is bit 0 of this register, DS92LV18 LOCK*
       // -------------------------------------------------------------------
   
      addr = A_STATUS_REG;
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
   
      if((data & 0x0001)==1)
      {
         printf( "  DS92LV18 not locked, skipping this Kintex.  Reg 13: 0x%04X \n", data);   
         //flock( fd, LOCK_UN );
         //munmap(map_addr, size);
         //close(fd);
         //return(-1);
         continue;
      }
      else
      {
         printf( "  DS92LV18 locked, Reg 13: 0x%04X \n", data); 
      }
   
      // -------------------------------------------------------------------
      // 2. b.	The TTCL interface card powers up ... SERDES_CTL_REG, address 1 default value is 0x67
      // -------------------------------------------------------------------

      addr = A_SERDES_CTL_REG;
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

      if((data & 0x00FF)!=0x67)
      {
         printf( "  Unexpected default value, skipping this Kintex.  Reg 1: 0x%04X \n", data);   
         //flock( fd, LOCK_UN );
         //munmap(map_addr, size);
         //close(fd);
         //return(-1);
         continue;
      }
      else
      {
         printf( "  Reg 1: 0x%04X (expected default value)\n", data); 
      }
   
   
      // -------------------------------------------------------------------
      //  3+. initialize jitter cleaner via I2C, use config file
      // -------------------------------------------------------------------
        printf( "  Skipping the programming of the SiLabs jitter cleaner\n"); 
   /*
         ctrl[7] = 1;      // TTCL Si jitter cleaner device address
         ctrl[6] = 1;
         ctrl[5] = 0;
         ctrl[4] = 1;  
         ctrl[3] = 0;
         ctrl[2] = 0;       // A1 SM jumper select
         ctrl[1] = 0;       // A0 SM jumper select
         ctrl[0] = 0;       // r/w
   
         fil = fopen(ini_file,"r");
         if (fil == NULL) {
           printf("Error opening file");
           flock( fd, LOCK_UN );
           munmap(map_addr, size);
           close(fd);
           return(-1);
         }
         fgets(line, LINESZ, fil);     // read first line, number of entries
         Nwrites = strtol(line, NULL, 10);
         //printf( " file name %s \n", ini_file );
         //printf( " first line %s (%d)\n", line, Nwrites );
   
         do{
            fgets(line, LINESZ, fil);     // read next line, address etc
            comment = strstr(line, s2);   // check if it's a comment
            if(comment) {
               printf(" comment line %s",line);
               linecount++;
             }
         } while ((comment!=NULL) & (linecount < Nwrites-1));
   
         vc = sscanf(line, "0x%X, 0x%X, %d, %d", &addr, &data, &rw, &a0a1);
         if(vc<4)        // import from SL tool register map has only adderess and data to write
         {
            rw   = 0;      // default write
            a0a1 = 2+k7;   // default address pins 10 for Kintex #0, 11 for Kintex #1
         }
         printf( " addr 0x%X, data 0x%X, rw %d, a0a1 %d \n", addr, data, rw, a0a1 );
         ctrl[2] = a0a1 & 0x0002;       // SM jumper select
         ctrl[1] = a0a1 & 0x0001;       // SM jumper select
   
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
            
            if(wc2==3)   usleep(30000);    // for programming sequence exported from SL tool, pause for init after write #3
         
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
                  rw   = 0;       // default write
                  a0a1 = 2+k7;   // default address pins 10 for Kintex #0, 11 for Kintex #1
               }
               if((wc2<10) | (wc2%10==1)) printf( " addr 0x%X, data 0x%X, rw %d, a0a1 %d \n", addr, data, rw, a0a1 );
               ctrl[2] = a0a1 & 0x0002;       // SM jumper select
               ctrl[1] = a0a1 & 0x0001;       // SM jumper select
            }
      
         } //end for
   
         fclose(fil);
   */
         // TODO: determine if jitter cleaner needs reset via S6 register #3
         // must use read/modify/write
   
      // -------------------------------------------------------------------
      //  4. read status and check if jitter cleaner clock ok
      // -------------------------------------------------------------------
      addr = A_STATUS_REG;
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

      if((data & 0x0006)!=0x0006)      // check bits 2,3 high
      {
         printf( "  TRIG_CLK_PRESENT and TRIG_PLL_LOCKED not 1, skipping this Kintex.  Reg 13: 0x%04X \n", data);   
         //flock( fd, LOCK_UN );
         //munmap(map_addr, size);
         //close(fd);
         //return(-1);
         continue;
      }
      else
      {
         printf( "  TRIG_CLK_PRESENT and TRIG_PLL_LOCKED both 1, proceeding. Reg 13: 0x%04X \n", data); 
      }
   
      // -------------------------------------------------------------------
      //  6. switch from local to TTCL clock (from jitter cleaner)
      // -------------------------------------------------------------------
   
      // switch clock
      addr = A_PULSED_CONTROL_REG;
      data = 0x8000;                            // set bit 15 in the control register 
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      // reset SERDES_SM_LOST_LOCK
      addr = A_PULSED_CONTROL_REG;
      data = 0x0020;                            // clear the  SERDES_SM_LOST_LOCK bit (now that we have a good clock) 
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

      // read status
      addr = A_STATUS_REG;
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

      if(data!=0x001E)      // check bits 2,3 high
      {
         printf( "  Unexpected status, should be 0x1E.  Reg 13: 0x%04X \n", data);   
         //flock( fd, LOCK_UN );
         //munmap(map_addr, size);
         //close(fd);
         //return(-1);
      }
      else
      {
         printf( "  Status register indicates '0x1E', proceeding. Reg 13: 0x%04X \n", data); 
      }
   
      // -------------------------------------------------------------------
      //  8. program delays
      // -------------------------------------------------------------------
   
      // program  timestamp additive offset for reception of the trigger message (reg 8)
      // program   delay of the trigger pulse  (reg 7, then write to bit 1 of reg0 to apply)
   
      //    use defaults for now
   
      //       Enable the delayed-trigger logic by setting bit 14 of the register at address 3.  
      //       Again, this would require a read-modify-write as other bits in this register do other things; 
   
      // read addr , DIAGNOSTIC_CTL_REG
      addr = A_DIAGNOSTIC_CTL_REG;
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

      printf( "  DIAGNOSTIC_CTL_REG current value is 0x%4x, now turning on delayed trigger logic \n", data); 
 
      // set bit 14
      data = data | 0x4000;
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   

      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);


      // read back addr 3
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

      printf( "  DIAGNOSTIC_CTL_REG read back after change: 0x%4x  \n", data); 
      
   
   
      // -------------------- set MESSAGE delay in register 8   --------------------
      // read addr 8
      addr = A_ACCEPT_MSG_DELAY_REG;
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
      
      printf( "  ACCEPT_MSG_DELAY_REG current value is 0x%x, now writing new delay 0x%x \n", data, Mdelay); 
      
      // set delay value
      data = Mdelay; //                         // TODO: use value  from ini file  
                                                // 200 is a reasonable delay for message propagation
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
      
      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);
      
      
      // read back addr 8
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
      
      printf( "  ACCEPT_MSG_DELAY_REG: 0x%x read back after change  \n", data); 
      
      
      // -------------------- set Pixie delay (for E sum) in register 7   --------------------
      
      // set delay value
      addr = A_TIMESTAMP_OFFSET_REG;
      data = Tdelay;                            // TODO: use value  from ini file  
                                             // 1 tick = 20ns
      printf( "  TIMESTAMP_OFFSET_REG: now writing requested value 0x%x  \n", data); 
      
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
      
      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);
      
      // activate
      addr = 0;
      data = 0x0001;                            //set bit 0 in pulsed control register to apply
                                             
      reghi = (addr & 0x7F);                    // 7 bits of address, bit 8 = 0 for write
      mapped[AMZ_EXAFWR] = AK7_PLLSPIA;         // write to  K7's addr     addr 0x1B = SPIA  
      mapped[AMZ_EXDWR]  = reghi;               // write to ADC SPI register   
      
      reglo = (data & 0xFFFF);     
      mapped[AMZ_EXAFWR] = AK7_PLLSPID;         // write to K7's addr     addr 0x1C = SPID and starts the serial output
      mapped[AMZ_EXDWR]  = reglo;               // write to ADC SPI       data should be ignored, instead TTCL fills register in K7
      usleep(100);

  } // end for Kintex

   // ************************ clean up  *********************************

 
 // clean up  
 flock( fd, LOCK_UN );
 munmap(map_addr, size);
 close(fd);
 return data;
}










