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

#include "PixieNetDefs.h"


long long main(void) {

  int fd;
  void *map_addr;
  int size = 4096;
  volatile unsigned int *mapped;
  char * query;
  unsigned int mval;
  unsigned int mode;
  long long WR_tm_tai;


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

  // ************** Main code begins **************************

 /* mode options

   0 CSR from MZ/PZ controller
   1 CSR from K7 #0
   2 CSR from K7 #1
   3 WR time from PZ controller
   4 WR time from K7 #0
   5 WR time from K7 #1

 */

  // get form data
  query = getenv("QUERY_STRING");
  if( (query != NULL) && (sscanf(query,"MODE=%d",&mval)==1) )  {
      mode =  mval;
  } else {
      mode=0;   // default to MZ/PZ controller CSR if no web query string
      // todo: use argv as fallback for command line call? Or just set an env varible before calling ?
  }
// printf("QS = %s, mode = %d\n", query, mode);

 if(mode==0)
 {
    mval = mapped[AMZ_CSROUTL];
    printf("0x%04X\n", mval);
    WR_tm_tai = mval;
 }

 if(mode==1 || mode==2)
 {
   if(mode==1)   mapped[AMZ_DEVICESEL] = CS_K0;	      // specify which K7 
   if(mode==2)   mapped[AMZ_DEVICESEL] = CS_K1;	      // specify which K7 
   mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr:    PAGE register
   mapped[AMZ_EXDWR]  = PAGE_SYS;         // PAGE 0: system, page 0x10n = channel n 

   mapped[AMZ_EXAFRD] = AK7_CSROUT;   
   mval =  mapped[AMZ_EXDRD];    
   if(SLOWREAD)      mval =  mapped[AMZ_EXDRD];
   printf("0x%04X\n", mval);
   WR_tm_tai = mval;
}

 if(mode==3)
 {
    mval = mapped[AMZ_WR_READ_TAI+0];
    WR_tm_tai = mval;
    mval = mapped[AMZ_WR_READ_TAI+1];
    WR_tm_tai = WR_tm_tai + mval*65536;
    mval = mapped[AMZ_WR_READ_TAI+2];
    WR_tm_tai = WR_tm_tai + mval*TWOTO32;
    printf("%llu\n", WR_tm_tai);
 }

 if(mode==4 || mode==5)
 {
   if(mode==4)   mapped[AMZ_DEVICESEL] = CS_K0;	      // specify which K7 
   if(mode==5)   mapped[AMZ_DEVICESEL] = CS_K1;	      // specify which K7 
   mapped[AMZ_EXAFWR] = AK7_PAGE;         // specify   K7's addr:    PAGE register
   mapped[AMZ_EXDWR]  = PAGE_SYS;         // PAGE 0: system, page 0x10n = channel n

   mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+0; 
   mval =  mapped[AMZ_EXDRD];    
   if(SLOWREAD)      mval =  mapped[AMZ_EXDRD];
   WR_tm_tai = mval;
   //printf("0x%x, %llu\n",mval, WR_tm_tai);
   
   mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+1; 
   mval =  mapped[AMZ_EXDRD];    
   if(SLOWREAD)      mval =  mapped[AMZ_EXDRD];
   WR_tm_tai = WR_tm_tai + (long long)(mval*65536);
   //printf("0x%x, %llu\n",mval, WR_tm_tai);

   mapped[AMZ_EXAFRD] = AK7_WR_TM_TAI+2; 
   mval =  mapped[AMZ_EXDRD];    
   if(SLOWREAD)      mval =  mapped[AMZ_EXDRD];
   WR_tm_tai = WR_tm_tai + (long long)(mval*TWOTO32);
   //printf("0x%x, %llu\n",mval, WR_tm_tai);
   printf("%llu\n", WR_tm_tai);
 }


 if(mode>5)
 {
    printf("unknown polling mode\n");
 }
   
  // clean up  
  munmap(map_addr, size);
  close(fd);
  return WR_tm_tai;
}
