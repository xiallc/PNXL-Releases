#!/bin/bash
# echo "test"
# Basic shell scrip to run 
# a synchronized DAQ for 3 Pixie-Nets
# assumes progfippi and clockprog have been
# executed already
# and LinuxPTP has been started in the background  

# Specify IP numbers
IP1="192.168.1.71"
IP2="192.168.1.72"
IP3="192.168.1.73"

# A few shortcuts
pt="./ptp-mii-tool/ptp-mii-tool"

# Get current time from one of the modules
PTPTIME=`$pt -t | cut -c 21-29`
echo "current time:" $PTPTIME

# Ask for start time and duration
echo "Start Time in s?"
read start_time_in_s
echo "Duration in s?"
read duration_in_s

# set up PTP managed DAQ gating
echo $pt --enable=$start_time_in_s --duration=$duration_in_s
$pt --enable=$start_time_in_s --duration=$duration_in_s

# Here could use sed command to set REQ_RUNTIME to duration + some extra

# Start DAQ
./acquire


