#!/bin/bash
# This is a simple script to copy the LM files 
# from 2 Pixie-Net to the local controller host

# Specify IP numbers for PN modules
IP1="192.168.1.93"
IP2="192.168.1.45"

# scp copy command <remote source> to <local destination>
# get .b00 file for run type 0x400, 0x402
# get .bin file for run type 0x100
scp root@$IP1:/var/www/LMdata*.b00 LMData_$IP1.b00
scp root@$IP1:/var/www/RS.csv RS_$IP1.csv
scp root@$IP1:/var/www/MCA.csv MCA_$IP1.csv

scp root@$IP2:/var/www/LMdata*.b00 LMData_$IP2.b00
scp root@$IP2:/var/www/RS.csv RS_$IP2.csv
scp root@$IP2:/var/www/MCA.csv MCA_$IP2.csv


