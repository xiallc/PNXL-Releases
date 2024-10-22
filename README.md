# Pixie-Net XL Release Notes

## Version 3.3F, March 2024 (preview release)
Release updates include
- changes to parameter values in defaults.ini: <br/>
  -- DEST_PORT0            61002<br/>
  -- SRC_PORT1             61004<br/>
  -- DATA_FLOW             2<br/>
  -- SLEEP_TIMEOUT         65535<br/>
  -- MCSRA_P4ERUNSTATS_01  1<br/>
  which matches recommended values in settings.ini
- the parameter EXTERN_DELAYLEN is applied internally with 4x the specified value <br/>
  for example EXTERN_DELAYLEN = 1.5, actual delay 6.0us. 
- the CLK_OUT connector now outputs the TTCL approval window
- the TRIG_OUT connector now outputs the hit flags (OR of channels 8-15) if GROUPMODE_FIP=1
- adjusted ADC clock delay for 14/250 variant to "10" for better ADC data capture 
- ttclinit routine now loops over both Kintex chips
- multiplicity count is output to TTCL interface board via XTRA[5:2]
- Firmware for Variant 1 not updated yet.

Known bugs:
- Variant 1: The automatic ADC initialization at boot time sometimes fails. This will be reported as a warning by ./progfippi. To correct, execute ./adcinit manually from the command line.

Note: Version 3.2x of the Zynq controller firmware is compatible with version 3.3x of the processing firmware and software, _except_ for DB08 and DB10 prototypes

Supported variants are 

| Part Number | Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------- | ----------------- | ----------------- | ----------------- |
| Pixie-Net-8-14-500 |7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3F71 |	[sw-arm-pnxl: 3.3F](./release_packages/sw-arm-pnxl-3p3F.zip) <br/> [sw-host-pnxl: 01232024](./release_packages/sw-host-pnxl-01232024.zip)<br/> [sw-igor-pnxl: 6.3E](./release_packages/sw-igor-pnxl-6p3E.zip) <br/> sd-bootfiles-pnxl: [ZT-3.32](./release_packages/sd-bootfiles-pnxl-zt-3p32.zip)  or [MZ-3.32](./release_packages/sd-bootfiles-pnxl-mz-3p32.zip) <br/> sd-image-pnxl: 09112023 <br/> [Pixie_Net_XL_Manual: 3.3F](./release_packages/Pixie_Net_XL_Manual.pdf) |
| Pixie-Net-16-14-250 | 4 <br/> 4T	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3F41 |   same as above |
| Pixie-Net-8-14-125 | 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3E11 | same as above |	
| Pixie-Net-16-14-250W | 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	[sw-arm-pnxl: 3.32](./release_packages/sw-arm-pnxl-3p32.zip) <br/>  [sw-host-pnxl: 01232024](./release_packages/sw-host-pnxl-01232024.zip) <br/>  [sw-igor-pnxl: 6.3E](./release_packages/sw-igor-pnxl-6p3E.zip) <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.3E](./release_packages/Pixie_Net_XL_Manual.pdf) |


 
## Release Information
A full Pixie-Net XL software/firmware release consists of the following components

| Component name | Description	| Install & Update |
| -------------- | ------------ | ----------------- |
| sw-arm-pnxl-[version] | The setup and DAQ procedures that go into /var/www on the Pixie Net XL’s Linux OS (including the firmware binaries for the pulse processing FPGAs). |	Unzip, then copy to /var/www on the Pixie Net XL’s Linux OS |
| sw-host-pnxl-[version] | 	Utilities for the UDP receiver and other DAQ utilities. Includes Igor xop version of UDP receiver |	Unzip, then copy executables to any folder on UDP receiver PC.  <br/> Igor extension udp_xop64.xop must be copied to C:\Program Files\WaveMetrics\Igor Pro 8 Folder\Igor Extensions (64-bit) or equivalent for Igor GUI |
| sw-igor-pnxl-[version]	| Igor GUI for setup, data acquisition, and data visualization via serial port or network. |	First install Igor Pro 8 or higher. <br/> Then unzip and copy to any folder on a Windows PC. |
| sd-bootfiles-pnxl-[version]	| The Zynq controller bootfiles for the FAT partition of the SD card. |	Unzip, then copy the 4 bootfiles to the FAT partition of the SD card
| sd-image-pnxl-[version] | The full (zip compressed) SD card image, includes sw-arm-pnxl, sd-bootfiles-pnxl, and all Linux OS files. Only updated for changes in Linux OS |	Unzip, then write to an SD card with a byte-by-byte image writer |
| Pixie_Net_XL_Manual.pdf | The user manual. It is also included in sw-arm-pnxl. | please read |

For first time users, please also see the [Quick Start guide](./release_packages/PixieNetXL_QuickStart.pdf) and the [Setup Notes](./release_packages/Setup_Pixie_Net_XL.pdf)

## Older Releases 

## Version 3.3E, January 2024
Release updates include
-	support for 12/500 MHz variant (in progress)
-	support for TTCL clock and trigger distribution (in progress)
-	logic for validation of events (at time of energy filter capture)
-	add subroutine to determine decay time TAU to findsettings
- update/improve adjust offset routine in findsettings
- speed up check for swapped channels in findsettings (DB02/04/08)
- support for long traces over UDP (multiple packages per event)
- UDP receiver example: suppress repeated headers in multi-package events
- manual: update parameter descriptions
- clean up progfippi function with subroutines
- remove unused parameters MAX_EVENTS, CW, COIN_PATTERN, TRIG_CONF0-3
  NOTE: old settings files may not function with this version of progfippi

Known bugs:
- Variant 1: The automatic ADC initialization at boot time sometimes fails. This will be reported as a warning by ./progfippi. To correct, execute ./adcinit manually from the command line.

Note: Version 3.2x of the Zynq controller firmware is compatible with version 3.3x of the processing firmware and software, _except_ for DB08 and DB10 prototypes

Supported variants are 

| Part Number | Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------- | ----------------- | ----------------- | ----------------- |
| Pixie-Net-8-14-500 |7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3E71 |	[sw-arm-pnxl: 3.3E](./release_packages/sw-arm-pnxl-3p3E.zip) <br/> [sw-host-pnxl: 01232024](./release_packages/sw-host-pnxl-01232024.zip)<br/> [sw-igor-pnxl: 6.3E](./release_packages/sw-igor-pnxl-6p3E.zip) <br/> sd-bootfiles-pnxl: [ZT-3.32](./release_packages/sd-bootfiles-pnxl-zt-3p32.zip)  or [MZ-3.32](./release_packages/sd-bootfiles-pnxl-mz-3p32.zip) <br/> sd-image-pnxl: 09112023 <br/> [Pixie_Net_XL_Manual: 3.3E](./release_packages/Pixie_Net_XL_Manual.pdf) |
| Pixie-Net-16-14-250 | 4 <br/> 4T	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3E41 |   same as above |
| Pixie-Net-8-14-125 | 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3E11 | same as above |	
| Pixie-Net-16-14-250W | 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	[sw-arm-pnxl: 3.32](./release_packages/sw-arm-pnxl-3p32.zip) <br/>  [sw-host-pnxl: 01232024](./release_packages/sw-host-pnxl-01232024.zip) <br/>  [sw-igor-pnxl: 6.3E](./release_packages/sw-igor-pnxl-6p3E.zip) <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.3E](./release_packages/Pixie_Net_XL_Manual.pdf) |


## Version 3.3B, September 2023
Release updates include
-	Fix bug in online CFD time stamping relative to waveforms
- make signal polarity consistent across models and variants. 
  (May need to change CCSRA_INVERT_05 from 0 <> 1 in existing settings to compensate)

Known bugs:
- Variant 1: The automatic ADC initialization at boot time sometimes fails. This will be reported as a warning by ./progfippi. To correct, execute ./adcinit manually from the command line.

Note: Version 3.2x of the Zynq controller firmware is compatible with version 3.3x of the processing firmware and software, _except_ for DB08 prototypes

Supported variants are 

| Part Number | Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------- | ----------------- | ----------------- | ----------------- |
| Pixie-Net-8-14-500 |7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3871 |	[sw-arm-pnxl: 3.3B](./release_packages/sw-arm-pnxl-3p3B.zip) <br/> [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip)<br/> [sw-igor-pnxl: 6.38](./release_packages/sw-igor-pnxl-6p38.zip) <br/> sd-bootfiles-pnxl: [ZT-3.32](./release_packages/sd-bootfiles-pnxl-zt-3p32.zip)  or [MZ-3.32](./release_packages/sd-bootfiles-pnxl-mz-3p32.zip) <br/> sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.3B](./release_packages/Pixie_Net_XL_Manual.pdf) |
| Pixie-Net-16-14-250 | 4 <br/> 4T	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3B41 |   same as above |
| Pixie-Net-8-14-125 | 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3811 | same as above |	
| Pixie-Net-16-14-250W | 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	[sw-arm-pnxl: 3.32](./release_packages/sw-arm-pnxl-3p32.zip) <br/>  [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip) <br/>  [sw-igor-pnxl: 6.38](./release_packages/sw-igor-pnxl-6p38.zip) <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.3A](./release_packages/Pixie_Net_XL_Manual.pdf) |

## Version 3.3A, July 2023
Release updates include
-	Fix typo in temporary MCA arrays' names (MCA.csv)
- New webops page to view/edit all settings in file settings.ini
- Better indication in webpages where data is coming from
- Add option for periodic updates in MCA webpage
- reactivate run type 0x401 (draft)
- make signal polarity consistent across models and variants. 
  (May need to change CCSRA_INVERT_05 from 0 <> 1 in existing settings to compensate)

Known bugs:
- Variant 1: The automatic ADC initialization at boot time sometimes fails. This will be reported as a warning by ./progfippi. To correct, execute ./adcinit manually from the command line.

Note: Version 3.2x of the Zynq controller firmware is compatible with version 3.3x of the processing firmware and software, _except_ for DB08 prototypes

Supported variants are 

| Part Number | Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------- | ----------------- | ----------------- | ----------------- |
| Pixie-Net-8-14-500 |7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3871 |	[sw-arm-pnxl: 3.3A](./release_packages/sw-arm-pnxl-3p3A.zip) <br/> [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip)<br/> [sw-igor-pnxl: 6.38](./release_packages/sw-igor-pnxl-6p38.zip) <br/> sd-bootfiles-pnxl: [ZT-3.32](./release_packages/sd-bootfiles-pnxl-zt-3p32.zip)  or [MZ-32](./release_packages/sd-bootfiles-pnxl-mz-3p32.zip) <br/> sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.3A](./release_packages/Pixie_Net_XL_Manual.pdf) |
| Pixie-Net-16-14-250 | 4	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3841 |   same as above |
| Pixie-Net-8-14-125 | 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3811 | same as above |	
| Pixie-Net-16-14-250W | 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	[sw-arm-pnxl: 3.32](./release_packages/sw-arm-pnxl-3p32.zip) <br/>  [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip) <br/>  [sw-igor-pnxl: 6.38](./release_packages/sw-igor-pnxl-6p38.zip) <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.3A](./release_packages/Pixie_Net_XL_Manual.pdf) |
 

## Version 3.38, April 2023
Release updates include
-	Bug fix in FW for time stamp (high word) for run type 0x411
-	Bug fix in SW for MCA spectra at high rates
-	Bug fix in Igor for extraction of listmode data for channel 3, CFD computation
-	Add new functionality and parameters for trigger distribution 

Known bugs:
- Variant 1: The automatic ADC initialization at boot time sometimes fails. This will be reported as a warning by ./progfippi. To correct, execute ./adcinit manually from the command line.

Note: Version 3.2x of the Zynq controller firmware is compatible with version 3.3x of the processing firmware and software, _except_ for DB08 prototypes

Supported variants are 

| Part Number | Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------- | ----------------- | ----------------- | ----------------- |
| Pixie-Net-8-14-500 |7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3871 |	[sw-arm-pnxl: 3.39](./release_packages/sw-arm-pnxl-3p39.zip) <br/> [sw-arm-pnxl: 3.38](./release_packages/sw-arm-pnxl-3p38.zip) <br/> [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip)<br/> [sw-igor-pnxl: 6.38](./release_packages/sw-igor-pnxl-6p38.zip) <br/> sd-bootfiles-pnxl: ZT-3.25 or ZT-3.32<br/> sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.38](./release_packages/Pixie_Net_XL_Manual.pdf) |
| Pixie-Net-16-14-250 | 4	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3841 |   same as above |
| Pixie-Net-8-14-125 | 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3811 | same as above |	
| Pixie-Net-16-14-250W | 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	[sw-arm-pnxl: 3.32](./release_packages/sw-arm-pnxl-3p32.zip) <br/>  [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip) <br/>  [sw-igor-pnxl: 6.21](./release_packages/sw-igor-pnxl-6p21.zip) <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.38](./release_packages/Pixie_Net_XL_Manual.pdf) |

## Version 3.32, November 2022
Release updates include
-	Debugged and tested CFD in variant 4W

Known bugs:
- Variant 1: The automatic ADC initialization at boot time sometimes fails. This will be reported as a warning by ./progfippi. To correct, execute ./adcinit manually from the command line.  

Supported variants are 

| Part Number | Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------- | ----------------- | ----------------- | ----------------- |
| Pixie-Net-8-14-500 |7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3171 |	[sw-arm-pnxl: 3.32](./release_packages/sw-arm-pnxl-3p32.zip) <br/> [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip)<br/> [sw-igor-pnxl: 6.21](./release_packages/sw-igor-pnxl-6p21.zip) <br/> sd-bootfiles-pnxl: ZT-3.25 <br/> sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.32](./release_packages/Pixie_Net_XL_Manual.pdf) |
| Pixie-Net-16-14-250 | 4	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3141 |   -"- |
| Pixie-Net-8-14-125 | 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3111 | -"- |	
| Pixie-Net-16-14-250W | 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	[sw-arm-pnxl: 3.32](./release_packages/sw-arm-pnxl-3p32.zip) <br/>  [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip) <br/>  [sw-igor-pnxl: 6.21](./release_packages/sw-igor-pnxl-6p21.zip) <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 <br/> [Pixie_Net_XL_Manual: 3.32](./release_packages/Pixie_Net_XL_Manual.pdf) |
 

## Version 3.31, October 2022
Release updates include
-	Debugged and tested CFD in variant 4
-	Updated TTCL interface for variant 1,4,7 (still preliminary)
-	Updated Igor list mode data displays and tables

Known bugs:
- Variant 1: The automatic ADC initialization at boot time sometimes fails. This will be reported as a warning by ./progfippi. To correct, execute ./adcinit manually from the command line.  

Supported variants are 

| Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------------- | ----------------- | ----------------- |
| 7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3171 |	[sw-arm-pnxl: 3.31](./release_packages/sw-arm-pnxl-3p31.zip) <br/> [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip) <br/> sw-igor-pnxl: 6.21 <br/> sd-bootfiles-pnxl: ZT-3.25 <br/> sd-image-pnxl: 09072022 |
| 4	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3141 |   -"- |
| 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3111 | -"- |	
| 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	sw-arm-pnxl: 3.31 <br/>  [sw-host-pnxl: 09072022](./release_packages/sw-host-pnxl-09072022.zip) <br/>  sw-igor-pnxl: 6.21 <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 |
 

### Version 3.30, September 2022
First commercial release. Supported variants are 

| Variant ID	| Hardware Revision |	Firmware Revision |	Software Revision |
| ----------- | ----------------- | ----------------- | ----------------- |
| 7  | DB06, 8  channel, <br/> 14 bit, 500 MSPS, <br/> 10G <br/> Z-Turn Zynq controller | 0x3071 |	sw-arm-pnxl: 3.30 <br/> sw-host-pnxl: 09072022 <br/> sw-igor-pnxl: 6.20 <br/> sd-bootfiles-pnxl: ZT-3.25 <br/> sd-image-pnxl: 09072022 |
| 4	 | DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 10G <br/> Z-Turn Zynq controller <br/> Optional TTCL adapter |	0x3041 |   -"- |
| 1	 | DB01, 8  channel, <br/> 14 bit, 125 MSPS, <br/> 10G <br/> Z-Turn Zynq controller |	0x3011 | -"- |	
| 4W	| DB04, 16  channel, <br/> 14 bit, 250 MSPS, <br/> 1G (White Rabbit) <br/> MicroZed Zynq controller	| 0x2540 <br/> (unchanged from pre-release) |	sw-arm-pnxl: 3.30 <br/>  sw-host-pnxl: 09072022 <br/>  sw-igor-pnxl: 6.20 <br/> sd-bootfiles-pnxl: MZ-3.25 <br/>  sd-image-pnxl: 09072022 |
