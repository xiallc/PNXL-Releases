/*----------------------------------------------------------------------
 * Copyright (c) 2019, 2021 XIA LLC
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
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIITED WARRANTIES, 
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
 * MERCHANTABILY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
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

// system constants
#define PS_CODE_VERSION                   0x033B
#define PN_BOARD_VERSION_12_250_A         0xA990    
#define PN_BOARD_VERSION_12_250_B         0xA991  
#define PN_BOARD_VERSION_12_250_B_PTP     0xA981  
#define PNXL_MB_GTXCLK_MASK               0xF0000000   // mask to extract Main board GTX clocking option
#define PNXL_DB_VARIANT_MASK              0x00F00000   // mask to extract DB variant from EEPROM HW info
#define PNXL_MB_REV_MASK                  0x000F0000   // mask to extract Main board HW revision from EEPROM HW info
#define PNXL_DB01_14_75                   0x00000000   // value for DB01 with 14/75 MHZ ADC
#define PNXL_DB01_14_125                  0x00100000   // value for DB01 with 14/125 MHZ ADC
#define PNXL_DB02_12_250                  0x00200000   // value for DB02 with 12/250 MHZ ADC
#define PNXL_DB02_14_250                  0x00300000   // value for DB02 with 14/250 MHZ ADC
#define PNXL_DB04_14_250                  0x00400000   // value for DB04 with 14/250 MHZ ADC
#define PNXL_DB06_16_250                  0x00600000   // value for DB06 with 16/250 MHZ ADC
#define PNXL_DB06_14_500                  0x00700000   // value for DB06 with 14/500 MHZ ADC
#define PNXL_DB08_14_250                  0x00800000   // value for DB08 with 14/250 MHZ ADC
#define PNXL_MB_REVA                      0x00000000   // value for Rev A Main board
#define PNXL_MB_REVB                      0x00010000   // value for Rev B Main board
#define PNXL_MB_REVC                      0x00020000   // value for Rev C Main board
#define PNXL_MB_10G                       0xA0000000   // value for 10G clocking
#define PNXL_MB_WR                        0xB0000000   // value for 1G clocking + WR
#define PNXL_MB_TTCL                      0xC0000000   // value for 10G clocking + TTCL
#define PNXL_MB_WRPZ                      0xD0000000   // value for 10G clocking + WR in PZ

#define ADC_CLK_MHZ_DB01_75                75
#define ADC_CLK_MHZ_DB01_125              125
#define ADC_CLK_MHZ_DB02                  250
#define ADC_CLK_MHZ_DB04                  250
#define ADC_CLK_MHZ_DB06_250              250
#define ADC_CLK_MHZ_DB06_500              500
#define ADC_CLK_MHZ_DB08_250              250

#define SYSTEM_CLOCK_MHZ_DB01              75
#define SYSTEM_CLOCK_MHZ_MOST             125

#define FILTER_CLOCK_MHZ_DB01              75
#define FILTER_CLOCK_MHZ_MOST             125

#define NCHANNELS                         32          // number of channels in parameter files (=max)
#define NCHANNELS_PRESENT_DB02            16          // actual number of channels per module with DB02
#define NCHANNELS_PRESENT_DB01            8           // actual number of channels per module with DB01
#define NCHANNELS_PER_K7_DB02             8           // actual number of channels per K7 with DB02
#define NCHANNELS_PER_K7_DB01             4           // actual number of channels per K7 with DB01
#define NCHANNEL_MAX400                   4           // maximum number of channels recorded in a single 0x400 .bin file
#define N_K7_FPGAS                        2
#define MAX_NGAINS                        8

#define V_OFFSET_MAX                      1.25        // Pixie voltage offset maximum
#define MAX_MCA_BINS                      32768
#define WEB_MCA_BINS                      4096
#define MCA2D_BINS                        100         // in each dimension
#define WEB_LOGEBIN                       3
#define DACWAIT                           20          // usleep cycles to wait for DAC programming
#define DACSETTLE                         80000       // usleep cycles to wait for DAC stable output after filter
#define NTRACE_SAMPLES                    8192
#define TWOTO32                           4294967296
#define ICRSCALE                          15         // factor between current ICR read and ICR in cps
#define N_FPGA_BYTES_A                    6022736
#define N_FPGA_BYTES_B                    13385232
#define P16_HDR_LEN                       10         // fixed header length for P16 run type 0x100  (32bit words)
#define ETH_HDR_LEN_410                   90         // fixed Ethernet package header length for run type 0x404 in bytes
#define ETH_HDR_LEN_404                   122        // fixed Ethernet package header length for run type 0x404 in bytes
#define ETH_HDR_LEN_404x8                 674        // fixed Ethernet package header length for run type 0x404 with 8 events per package in bytes
#define ETH_HDR_LEN_110                   74         // fixed Ethernet package header length for run type 0x104 in bytes
#define ETH_HDR_LEN_104                   74         // fixed Ethernet package header length for run type 0x104 in bytes
#define ETH_HDR_LEN_100                   68         // fixed Ethernet package header length for run type 0x100 in bytes
#define MAX_UDP_SIZE_BYTES                1500          // anything above 1500 bytes total is a jumbo package. Might not transmit         


// Limits for settings
#define MAX_CRATE_ID                      15
#define MAX_SLOT_ID                       15
#define MAX_MODULE_ID                     15
#define MIN_CW                            5             // Coinc Window limits
#define MAX_CW                            511
#define MIN_SFR                           1             // FR limits
#define MAX_SFR                           6
#define MIN_FFR                           0             // FR limits
#define MAX_FFR                           0
#define MIN_SL                            2             // energy filter limits
#define MIN_SG                            3
#define MAX_SLSG                          127
#define MIN_FL                            2             // trigger filter limits
#define MIN_FG                            0
#define MAX_FLFG                          127
#define MAX_TH                            65535
#define GAIN_HIGH                         5             // gain limits  Pixie-Net
#define GAIN_LOW                          2
#define MAX_TL                            4092          // max length of captured waveform and pre-trigger delay
#define MULT_TL                           32            // trace lenght must be a multiple of this number
#define TWEAK_UD                          0             // adjustment to pre-trigger delay for internal pipelining
#define MAX_BFACT                         16
#define MAX_PSATH                         65530
#define MAX_GW                            255
#define MAX_GD                            255
#define MAX_CD                            255
#define MAX_QDCL                          60            // length of QDC sum samples
#define MIN_QDCL                          2             // length of QDC sum samples
#define MIN_QDCLD                         -2            // length plus delay of QDC sum, in samples
#define MAX_QDCLD                         500           // length plus delay of QDC sum, in samples
#define MIN_QDCLD_RS                      -64           // length plus delay of QDC sum, in samples (custom RS code)
#define MAX_QDCLD_RS                      440           // length plus delay of QDC sum, in samples (custom RS code)
#define VAL0_QDC_DIV                      4             // scaling factor for QDC sums
#define VAL1_QDC_DIV                      32
#define MAX_BLAVG                         16
#define MAX_BADBL                         20
#define DB01_GAIN0                        1.6
#define DB01_GAIN1                        2.4
#define DB01_GAIN2                        3.5
#define DB01_GAIN3                        5.4
#define DB01_GAIN4                        6.7
#define DB01_GAIN5                        9.9
#define DB01_GAIN6                        14.7
#define DB01_GAIN7                        22.6

// maxima for P16 style parameters
#define FASTTRIGBACKLEN_MAX               4095
#define FASTTRIGBACKLEN_MIN_100MHZFIPCLK  1
#define FASTTRIGBACKLEN_MIN_125MHZFIPCLK  2
#define CFDDELAY_MAX                      63
#define CFDDELAY_MIN                      1
#define CFDSCALE_MAX                      7
#define CFDSCALE_MIN                      0
#define CFDTHRESH_MAX                     65535
#define CFDTHRESH_MIN                     1
#define EXTTRIGSTRETCH_MAX                4095
#define EXTTRIGSTRETCH_MIN                1
#define VETOSTRETCH_MAX                   4095
#define VETOSTRETCH_MIN                   1
#define EXTDELAYLEN_MAX_REVBCD            255
#define EXTDELAYLEN_MAX_REVF              511
#define EXTDELAYLEN_MIN                   0
#define FASTTRIGBACKDELAY_MAX_REVBCD      255
#define FASTTRIGBACKDELAY_MAX_REVF        511
#define FASTTRIGBACKDELAY_MIN             0
#define QDCLEN_MAX                        32766
#define QDCLEN_MIN                        2
#define TRACELEN_MIN_500MHZADC		      10
#define TRACELEN_MIN_250OR100MHZADC	      4
#define TRACEDELAY_MAX                    1023
#define CHANTRIGSTRETCH_MAX               4095
#define CHANTRIGSTRETCH_MIN               1
#define MIN_XDT                           2            // in samples
#define MAX_XDT                           16777215     // in samples


// system reg addr defines
// block 0
#define ACSRIN                0x000
#define ACOINCPATTERN         0x001
#define AI2CREG               0x002
#define AOUTBLOCK             0x003
#define AHVDAC                0x004
#define ASERIALIO             0x005
#define AAUXCTRL              0x006
#define AFPGAPROG             0x007
#define AADCCTRL              0x007
#define ADSP_CLR              0x008
#define ACOUNTER_CLR          0x009
#define ARTC_CLR              0x00A
#define ABVAL                 0x00B
#define AFPGACONF             0x00D
#define CA_DAC                0x004

// block 1
#define ACSROUT               0x100
#define AEVSTATS              0x101
#define ABRDINFO              0x102
#define APPSTIME              0x103
#define AEVHIT                0x104
#define AEVTSL                0x105
#define AEVTSH                0x106
#define AEVPPS                0x107

// block 2
#define ARS0_MOD              0x200
#define AREALTIME             0x201

// channel reg addr defines
// block 1
// channel independent lower bits of event registers
#define CA_HIT                0x100
#define CA_TSL                0x101
#define CA_TSH                0x102
#define CA_PSAA               0x103
#define CA_PSAB               0x104
#define CA_CFDA               0x105
#define CA_CFDB               0x106
#define CA_LSUM               0x107
#define CA_TSUM               0x108
#define CA_GSUM               0x109
#define CA_REJECT             0x10A
#define CA_LSUMB              0x10B
#define CA_TSUMB              0x10C
#define CA_GSUMB              0x10D
// ADC registers
#define AADC0                 0x11F
#define AADC1                 0x12F
#define AADC2                 0x13F
#define AADC3                 0x14F
//block 2
#define ARS0_CH0              0x220
#define ARS0_CH1              0x240
#define ARS0_CH2              0x260
#define ARS0_CH3              0x280
// block 3
#define AWF0                  0x300
#define AWF1                  0x301
#define AWF2                  0x302
#define AWF3                  0x303

// outblocks
#define OB_IOREG              0x0         // I/O
#define OB_EVREG              0x1         // Event data
#define OB_RSREG              0x2         // run statistics
#define OB_WFREG              0x3         // channel waveforms

// PN XL specific
#define CS_MZ                 0x00
#define CS_K1                 0x04
#define CS_K0                 0x08
#define PAGE_SYS              0x000       // page number for system registers = 0x000
#define PAGE_CHN              0x100       // page number for channel registers = 0x100+ch

// I2C addresses
#define I2CW_PFC_LOW          0x44        // write to PFC chip for first 8 bits of gain/ GPIO
#define I2CW_PFC_HIGH         0x48        // write to PFC chip for second 8 bits of gain/ GPIO
#define I2CW_DACA_DB04        0x20        // write address to DAC chip for second 4 channels on DB04 (first 4:  +2)
#define I2CW_DACC_DB04        0x30        // write control to DAC chip on DB04 (low 2 bits are [scrambled!] channel numbers 0-3)
#define I2CW_DACA_DB08AD      0x18        // write address to AD5696 DAC chip on DB08 
#define I2CW_DACC_DB08AD      0x30        // write command "write value and update" to AD5696 DAC chip on DB08 (add in channel in lower 4 bits) 


// addresses in MZ controller - direct read/write
#define AMZ_CSRIN             0x00
#define AMZ_DEVICESEL         0x03
#define AMZ_PLLSTART          0x08
#define AMZ_RUNCTRL           0x0C
#define AMZ_PCB_VERSION       0x0E        
#define AMZ_FIRSTDAC          0x10
#define AMZ_EXAFWR            0x18
#define AMZ_EXAFRD            0x19
#define AMZ_EXDWR             0x1A
#define AMZ_EXDRD             0x1B
#define AMZ_RDMCA0            0x1C
#define AMZ_RDMCA1            0x1E
#define AMZ_RS                0x20
#define AMZ_CSROUTL           0x20
#define AMZ_CSROUTH           0x21
#define AMZ_HW_VER            0x24
#define AMZ_FW_VER            0x2C        
#define AMZ_RS_TT             0x28

#define AMZ_WR_START_TAI      0x20
#define AMZ_WR_STOP_TAI       0x23
#define AMZ_WR_READ_TAI       0x2C

// addresses in K7 -- read/write via AMZ_EX___
#define AK7_SCSRIN            0x00
#define AK7_ADCCTRL           0x02
#define AK7_PAGE              0x03
#define AK7_HOSTCLR           0x04
#define AK7_ADCSPI            0x05
#define AK7_ADCBITSLIP        0x06
#define AK7_WR_TM_TAI_START   0x07
#define AK7_WR_TM_TAI_STOP    0x0A
#define AK7_ETH_DEST_MAC      0x0D        // 3 addr for destination MAC
#define AK7_ETH_DEST_IP       0x10        // 2 addr for destination IP
#define AK7_ETH_SRC_IP        0x12        // 2 addr for source IP
#define AK7_ETH_CHECK_SHORT   0x14        // IPv4 checksum, precomputed for short package
#define AK7_ETH_CHECK_LONG    0x15        // IPv4 checksum, precomputed for long package
#define AK7_ETH_ENERGY        0x16        // energy of current event to send out
#define AK7_ETH_CFD           0x17        // cfd of current event to send out
#define AK7_ETH_CTRL          0x18        // channel number, trace length, type of data payload, also starts transfer if run in progress (nLive) 
#define AK7_HDR_IDS           0x19        // crate/slot ID and header length 
#define AK7_UDP_PAUSE         0x1A        // minimum time between UDP output packages to WR (to slow down data out rate)
#define AK7_PLLSPIA           0x1B        // address of PLL register
#define AK7_PLLSPID           0x1C        // data for PLL register (write starts transfer)
#define AK7_DM_CONTROL        0x1D        // write DM's accept/reject decision (write starts transfer to WR) 
#define AK7_ETH_DEST_PORT     0x1E        // 1 addr for destination IP
#define AK7_ETH_SRC_PORT      0x1F        // 1 addr for source IP
#define AK7_ETH_SRC_MAC       0x20        // 3 addr for source MAC
#define AK7_ADC_CHANNEL       0x23        // 2 addr for ADC FIFO  channels select and lower bits of dt
#define AK7_ADC_INTERVAL      0x24        // upper bits of dt and FIFO reset
#define AK7_SLEEP             0x25
#define AK7_RUNTYPE           0x26        // inform FPGA of Run type
#define AK7_USR_PCK_DATA      0x27        // arbitray word to include into 0x411 header
#define AK7_TTCL_STNC_TIME    0x28        // specify the time for synchronization
#define AK7_TTCL_APPR_WINDOW  0x2A        // length of TTCL acceptance window 
#define AK7_GROUPMODE_AB      0x2C        // number specifying the trigger distribution mode for channels
#define AK7_GROUPMODE_K7      0x30        // number specifying the trigger distribution mode for Kintex
#define AK7_GATE_LENGTH       0x31        // gating time window (when generated internally from other signals)

#define AK7_P16REG00          0x40
#define AK7_P16REG01          0x44
#define AK7_P16REG02          0x48
#define AK7_P16REG03          0x4C
#define AK7_P16REG05          0x4E
#define AK7_P16REG06          0x52
#define AK7_P16REG07          0x56
#define AK7_P16REG13          0x5A
#define AK7_P16REG17          0x5C
#define AK7_P16REG_C0         0x62
#define AK7_P16REG_CG         0x64
#define AK7_P16REG_C1         0x66
#define AK7_P16REG_ELO        0x68
#define AK7_P16REG_EHI        0x69

#define AK7_SYS_RS            0x80
#define AK7_CSROUT            0x80
#define AK7_SYSSYTATUS        0x81
#define AK7_MEM_OCNT          0x84
#define AK7_ADCFRAME          0x86
#define AK7_SYS_RS_RT         0x88
#define AK7_SYS_FW_VER        0x8C
#define AK7_WR_TM_TAI         0x8D
#define AK7_SPI_RETURN        0x96
#define AK7_ADC_FIFO_L        0x97     
#define AK7_ADC_FIFO_H        0x98 

#define AK7_CHN_RS_CT         0xC0
#define AK7_ADC               0xC4
#define AK7_BLSTART           0xC8
#define AK7_CHN_RS_NTRIG      0xD0
#define AK7_CHN_RS_NOUT       0xD4     
#define AK7_HDRMEM_A          0xD8
#define AK7_HDRMEM_B          0xD9
#define AK7_HDRMEM_C          0xDA
#define AK7_HDRMEM_D          0xDB
#define AK7_TRCMEM_A          0xDC
#define AK7_TRCMEM_B          0xDD
#define AK7_TRCMEM_C          0xDE
#define AK7_TRCMEM_D          0xDF
#define AK7_BLLOCK            0xE0
#define AK7_SKIPTRACE         0xE1
#define AK7_NEXTEVENT         0xE2
#define AK7_EFIFO             0xE3
#define AK7_CHN_RS_NPPI       0xE4
#define AK7_CHN_RS_FTDT       0xE8
#define AK7_CHN_RS_GDT        0xEC
#define AK7_CHN_RS_GCOUNT     0xF0
#define AK7_CHN_RS_ICR        0xF4
#define AK7_CHN_RS_OOR        0xF5
 
// program control constants
#define LINESZ                1024        // max number of characters in ini file line
#define I2CWAIT               4           // us between I2C clock toggles
#define SDA                   1           // bit definitions for I2C I/O
#define SCL                   2           // bit definitions for I2C I/O
#define SDAENA                4           // bit definitions for I2C I/O
#define I2C_SELMAIN           0x0010      // select bit for I2C I/O (write to AUX_CTRL), PX desk main I2C
#define I2C_SELDB1            0x0020      // select bit for I2C I/O (write to AUX_CTRL), PX desk DB0 I2C
#define I2C_SELDB0            0x0040      // select bit for I2C I/O (write to AUX_CTRL), PX desk DB1 I2C
#define N_PL_IN_PAR           16          // number of input parameters for system and each channel
#define N_PL_RS_PAR           32          // number of runstats parameters for system and each channel
#define N_USED_RS_PAR         30          // not all RS parapmeters are used, can save some readout and printout cycles
#define MAX_PAR_NAME_LENGTH   65          // Maximum length of parameter names
#define BLREADPERIOD          20
#define MIN_POLL_TIME         1000
#define BLOCKSIZE_400         32          // waveform block size (# 16bit words) in run type 0x400
#define BLOCKSIZE_100         2           // waveform block size (# 16bit words) in run type 0x100
#define FILE_HEAD_LENGTH_400  32          // file header size (# 16bit words) in run type 0x400
#define CHAN_HEAD_LENGTH_400  32          // event/channel header size (# 16bit words) in run type 0x400
#define CHAN_HEAD_LENGTH_100  10          // number of 32bit words in P16 0x100 run type
#define WATERMARK             0x12345678  // for LM QC routine
#define EORMARK               0x01000002  // End Of Run
#define SLOWREAD              1           // address write transfers data too slowly, read twice
#define ADC_FRAME_DB01        0x87
#define WR_TAI_STEP           10           // time boundary (in s) at which a WR run will start

// channel hit pattern & info in LM data
#define HIT_ACCEPT            5           //  result of local coincidence test & pileup & veto & rangebad
#define HIT_COINCTEST         16          //  result of local coincidence test
#define HIT_PILEUP            18          //  result of local pileup test
#define HIT_LOCALHIT          20          //  set if this channel has a hit
#define HIT_OOR               22          //  set if this channel had the out of range flag set

// P16 CSR bits defined in settings file
#define CCSRA_FTRIGSEL        0           // fast trigger selection - 1: select external fast trigger; 0: select local fast trigger
#define CCSRA_EXTTRIGSEL      1           // module validation signal selection - 1: select module gate signal; 0: select global validation signal (RevD & RevF only)
#define CCSRA_GOOD            2           // good-channel bit - 1: channel data will be read out; 0: channel data will not be read out
#define CCSRA_CHANTRIGSEL     3           // channel validation signal selection - 1: select channel gate signal; 0: select channel validation signal (RevD & RevF only)
#define CCSRA_SYNCDATAACQ     4           // block data acquisition if trace or header DPMs are full - 1: enable; 0: disable
#define CCSRA_POLARITY        5           // input signal polarity control
#define CCSRA_VETOENA         6           // veto channel trigger - 1: enable; 0: disable
#define CCSRA_HISTOE          7           // histogram energy in the on-board MCA
#define CCSRA_TRACEENA        8           // trace capture - 1: enable; 0: disable
#define CCSRA_QDCENA          9           // QDC summing and associated header data - 1: enable; 0: disable
#define CCSRA_CFDMODE         10          // CFD for real time, trace capture and QDC capture - 1: enable; 0: disable 
#define CCSRA_GLOBTRIG        11          // global trigger for validation - 1: enable; 0: disable
#define CCSRA_ESUMSENA        12          // raw energy sums and baseline in event header - 1: enable; 0: disable
#define CCSRA_CHANTRIG        13          // channel trigger for validation - 1: enable; 0: disable
#define CCSRA_ENARELAY        14          // Control input relay: 1: connect, 0: disconnect
#define CCSRA_PILEUPCTRL      15
#define CCSRC_INVERSEPILEUP   0
#define CCSRC_ENAENERGYCUT    1           // Enable "no trace for large pulses" feature - 1: enable; 0: disable
#define CCSRC_GROUPTRIGSEL    2           // Group trigger selection - 1: external group trigger; 0: local fast trigger
#define CCSRC_CHANVETOSEL     3           // Channel veto selection - 1: channel validation trigger; 0: front panel channel veto
#define CCSRC_MODVETOSEL      4           // Module veto selection - 1: module validation trigger; 0: front panel module veto
#define CCSRC_EXTTSENA        5           // External timestamps in event header - 1: enable; 0: disable
#define CCSRC_RBADDIS         6           // if 1, disable rangebad logic and accept even pulses going out of range      
#define CCSRC_PAUSE_PILEUP    7           // if 1, pause pileup inspection briefly after trigger
#define CCSRC_LOCAl_ENERGY    9           // if 1, use local trigger for energy filter capture
#define CCSRC_SIM_ADC         10          // if 1, replace ADC data with simulated data stream


// other CSR bits
#define WRC_RUNTIME_K7        0           // if set, Enable WR run time control in Kintex
#define WRC_RUNTIME_PZ        1           // if set, Enable WR run time control in PicoZed
#define MCSRA_P4ERUNSTATS     1           // if set, use P4e convention for live time etc
#define MCSRA_FP_COUNT        4           // option to count FP pulses as ext_ts, else local clock (or WR)     
#define MCSRA_FP_VETO         5           // option to use FP as VETO                                          
#define MCSRA_FP_EXTCLR       6           // option to use FP to clear ext_ts                                  
#define MCSRA_FP_PEDGE        7           // option to select rising/falling edge for count or clear.   

// P16 Fippi register bits
#define FiPPI_HALT            0           // Halt Fippi (lower 32-bit word)
#define FiPPI_INVRT           1           // Polarity (lower 32-bit word)
#define FiPPI_VETOENA         2           // Enable Veto (lower 32-bit word)
#define FiPPI_EXTTRIGSEL      3           // Select external validation trigger source (lower 32-bit word)
#define FiPPI_CHANTRIGSEL     21          // Select channel validation trigger source (lower 32-bit word)
#define FiPPI_SYNCDATAACQ     22          // Enable SYNC data DAQ (lower 32-bit word)
#define FiPPI_GROUPTRIGSEL    23          // Select group trigger source (lower 32-bit word)
#define FiPPI_CHANVETOSEL     29          // Select channel veto source (upper 32-bit word)
#define FiPPI_MODVETOSEL      30          // Select module veto source (upper 32-bit word)
#define FiPPI_ENARELAY        31          // Enable front end relay (upper 32-bit word)
#define FiPPI_GROUP           8           // Group trigger
#define FiPPI_LIVE            9           // Individual live time measurement
#define SelExtFastTrig        12          // Select external trigger to record event, instead of local fast trigger
#define FiPPI_TRACEENA        13
#define FiPPI_QDCENA          14
#define FiPPI_CFDMODE         15
#define FiPPI_GLOBTRIG        16
#define FiPPI_PAUSE_PILEUP    18
#define FiPPI_CHANTRIG        17
#define FiPPI_RBADDIS         19          // if 1, disable rangebad logic and accept even pulses going out of range
#define FiPPI_GOOD            29          // good-channel bit - 1: channel data will be read out; 0: channel data will not be read out
#define FiPPI_PILEUPCTRL      30
#define FiPPI_INVERSEPILEUP   31
#define FiPPI_LOCAl_ENERGY    6           // bit 5 in the "high" portion of Reg 2
#define FiPPI_SIM_ADC         7


// other FW control register bits
#define SCSR_WRRUNTIMECTRL    1           // Enable WR run time Control
#define SCSR_P4ERUNSTATS      2           // if set, use P4e convention for live time etc
#define SCSR_AUTOUDP          3           // if set, LM data is sent out via UDP without interaction with C code
#define SCSR_AUTOQSPI         4           // if set, E is sent out via QSPI without interaction with C code
#define SCSR_HDRENA           5           // if set, store LM output data in header memory (else only E in E fifo)
#define SCSR_DMCONTROL        6           // if set, Ethernet output data is held in SDRAM FIFO until DM approves
#define SCSR_TGTEST           7           // reserved
#define SCSR_FP_COUNT         8           // option to count FP pulses as ext_ts, else local clock (or WR)     
#define SCSR_FP_VETO          9           // option to use FP as VETO                                          
#define SCSR_FP_EXTCLR        10          // option to use FP to clear ext_ts                                  
#define SCSR_FP_PEDGE         11          // option to select rising/falling edge for count or clear.          
#define SCSR_HDRLONG          12          // enable long header for list mode data     
#define SCSR_SYNC_AT_LIVE     13          // option to clear time stamps in K7 at falling edge of Live 
#define SCSR_TTCL_CLK_OUT     14        
#define SCSR_TTCL_CLK_SL      15          
 
 
 
