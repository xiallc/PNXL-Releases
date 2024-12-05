#!/bin/bash
# echo "test"
# A simple shell script to run a synchronized DAQ for 3 Pixie-Nets
#
# assumes progfippi and clockprog have been executed already
# and LinuxPTP has been started in the background  
# (see ptpsetup_3x.sh)

# Specify IP numbers for PN modules
IP1="192.168.1.96"
IP2="192.168.1.98"
IP3="192.168.1.100"

# A few shortcuts
pt="/var/www/ptp-mii-tool/ptp-mii-tool"
EXTRATIME="8"

# Ask for run duration
echo "PTP enabled run time in s?"
read DUR


# Specify duration +10s as REQ_RUNTIME for Pixie-Nets
# (use sed -i to change settings file)
echo "Updating settings.ini, please wait"
RRT=$((DUR + 10))	
CMD="sed -i '/REQ_RUNTIME/c REQ_RUNTIME $RRT ' /var/www/settings.ini"
#echo $CMD
ssh root@$IP1 "$CMD"
ssh root@$IP2 "$CMD"
ssh root@$IP3 "$CMD"
echo "Done updating settings.ini"


# Get current time from one of the modules
# The ptp-mii-tool command also reports the PTP master's system time
# for correlation of PTP time (in s) to current date/time
echo "---" $IP1 "---"
TIME1=`ssh root@$IP1 '/var/www/ptp-mii-tool/ptp-mii-tool -t'`
echo $TIME1
PTPTIME=$(echo $TIME1 | cut -c 21-32)
echo "Will enable DAQ in" $EXTRATIME "seconds" 
TON=`expr "$PTPTIME" + "$EXTRATIME"`
# echo "Start time=" $TON "PTP time = " $PTPTIME
 

# set up PTP managed DAQ gating
CMD="$pt --enable=$TON --duration=$DUR"
#echo $CMD
echo "---" $IP1 "---"
ssh root@$IP1 "$CMD"
echo "---" $IP2 "---" 
ssh root@$IP2 "$CMD"
echo "---" $IP3 "---" 
ssh root@$IP3 "$CMD"

# Start DAQ as BG tasks
echo "--- Now starting DAQs ---"
ssh root@$IP1 "sh -c 'cd /var/www; nohup ./acquire > daq.log 2>&1 < /dev/null &'"
ssh root@$IP2 "sh -c 'cd /var/www; nohup ./acquire > daq.log 2>&1 < /dev/null &'"
ssh root@$IP3 "sh -c 'cd /var/www; nohup ./acquire > daq.log 2>&1 < /dev/null &'"
echo "DAQs started successfully"
echo "Script done, please wait for DAQ completion"

	


