/*----------------------------------------------------------------------
 * Copyright (c) 2019 XIA LLC
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

// refs for shared functions

#pragma once
#ifdef __cplusplus
extern "C"
{
#endif
  
  void I2Cstart(      volatile unsigned int *mapped);
  void I2Cstop(       volatile unsigned int *mapped);
  void I2Cslaveack(   volatile unsigned int *mapped);
  void I2Cmasterack(  volatile unsigned int *mapped);
  void I2Cmasternoack(volatile unsigned int *mapped);
  void I2Cbytesend(   volatile unsigned int *mapped, unsigned int *data);
  void I2Cbytereceive(volatile unsigned int *mapped, unsigned int *data);
  void I2Csend3bytes( volatile unsigned int *mapped, unsigned int *data0,  unsigned int *data1,  unsigned int *data2);
  void I2Csend4bytes( volatile unsigned int *mapped, unsigned int *data0,  unsigned int *data1,  unsigned int *data2,  unsigned int *data3);

  unsigned int setbit( unsigned int par, unsigned int bitc, unsigned int bitf);
  unsigned int byte2array( unsigned int abyte, unsigned int *array);

  unsigned int hwinfo( volatile unsigned int *mapped,unsigned int I2Csel );
  float board_temperature( volatile unsigned int *mapped, unsigned int I2Csel  );
  float zynq_temperature();

  int read_print_runstats(int mode, int dest, volatile unsigned int *mapped );
  int read_print_runstats_XL_2x4(int mode, int dest, volatile unsigned int *mapped );
  int read_print_rates_XL_2x4(int dest, volatile unsigned int *mapped );

  int ADCinit_DB01(volatile unsigned int *mapped );
  int PLLinit(volatile unsigned int *mapped );

  int setdacs01(volatile unsigned int *mapped, unsigned int *dacs); 
  int setdacs04(volatile unsigned int *mapped, unsigned int *dacs); 
  int setdacs08(volatile unsigned int *mapped, unsigned int *dacs); 
  unsigned int ADCSPI_Write06(volatile unsigned int *mapped, unsigned int k7, unsigned int ch_k7, unsigned int addr, unsigned int data);
  unsigned int ADCSPI_Read06(volatile unsigned int *mapped, unsigned int k7, unsigned int ch_k7, unsigned int addr);

  int ramp_dacs(   volatile unsigned int *mapped,  // address space for MZ I/O
            unsigned int revsn,                    // HW revision and s/n
            unsigned int DACstart,                 // starting value of DAC ramp
            unsigned int DACend,                   // ending value of DAC ramp
            unsigned int DACstep,                  // DAC increment per step
            double *noiseL,                        // result[NCHANNELS x Ngains]: lowest noise in ramp 
            double *noiseH,                        // result[NCHANNELS x Ngains]: highest noise in ramp 
            double *slopes,                        // result[NCHANNELS x Ngains]: ADC per DAC slope
            double *I2Eoffset,                     // result[NCHANNELS]: offset mismatch between even and odd 
            double *I2Eslope,                      // result[NCHANNELS]: gain mismatch between even and odd 
            unsigned int *DACofADC2k               // result[NCHANNELS x Ngains]: DAC value that brings ADC to ~2000 (Todo)
            );

#ifdef __cplusplus
}
#endif




