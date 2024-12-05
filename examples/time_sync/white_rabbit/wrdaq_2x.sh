#!/bin/bash
# echo "test"
# A simple shell script to run a White Rabbit synchronized DAQ for 2 Pixie-Net XL
#
# assumes 
# - bootfpga progfippi been executed already (see wrsetup_2x.sh)
# - the WR core has been started and locked automatically    
# - option WR_RUNTIME_CTRL is defined as 1 in settings.ini
#   (so that software/firmware run for a defined WR time span)

# Specify IP numbers for PN modules
IP1="192.168.1.93"
IP2="192.168.1.45"

# Ask for run duration
echo "WR enabled run time in s?"
read DUR

# Specify duration as REQ_RUNTIME for Pixie-Nets
# 0 s added (another 10 in ./startdaq
# (use sed -i to change settings file)
echo "Updating settings.ini, please wait"
RRT=$((DUR + 0))	
CMD="sed -i '/REQ_RUNTIME/c REQ_RUNTIME $RRT ' /var/www/settings.ini"
#echo $CMD
ssh root@$IP1 "$CMD"
ssh root@$IP2 "$CMD"
echo "Done updating settings.ini"

# Start DAQ as BG tasks that don't end when logging out
echo "--- Now starting DAQs ---"
ssh root@$IP1 "sh -c 'cd /var/www; nohup ./startdaq > daq.log 2>&1 < /dev/null &'"
ssh root@$IP2 "sh -c 'cd /var/www; nohup ./startdaq > daq.log 2>&1 < /dev/null &'"
echo "DAQs started successfully"
echo "Script done, please wait for DAQ completion"

	


