#!/bin/bash
# This is a simple script to copy the LM files 
# from 3 Pixie-Nets to the local controller host

# Specify IP numbers for PN modules
IP1="192.168.1.96"
IP2="192.168.1.98"
IP3="192.168.1.100"

# scp copy command <remote source> to <local destination>
# get .b00 file for run type 0x400, 0x402
scp root@$IP1:/var/www/LMdata.b00 LMData_$IP1.b00
scp root@$IP1:/var/www/RS.csv RS_$IP1.csv
scp root@$IP1:/var/www/MCA.csv MCA_$IP1.csv

scp root@$IP2:/var/www/LMdata.b00 LMData_$IP2.b00
scp root@$IP2:/var/www/RS.csv RS_$IP2.csv
scp root@$IP2:/var/www/MCA.csv MCA_$IP2.csv

scp root@$IP3:/var/www/LMdata.b00 LMData_$IP3.b00
scp root@$IP3:/var/www/RS.csv RS_$IP3.csv
scp root@$IP3:/var/www/MCA.csv MCA_$IP3.csv

