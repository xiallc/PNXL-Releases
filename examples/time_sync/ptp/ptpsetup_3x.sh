#!/bin/bash
# This is a simple script to set up 3 Pixie-Nets for PTP DAQ from 
# a remote host
# 
# Remember to set up public key login on Pixie-Nets to avoid 
# having to type PW all the time
# create key on local machine:  ssh-keygen -t rsa
# copy key to remote machine:   ssh-copy-id remote_host
# or better   : ssh-copy-id -o ControlPath=none root@192.168.1.71
#  followed by: ssh-add		(this is a bug fix of some sort)
# requires /etc/ssh/sshd_config has line 
#    AuthorizedKeysFile  .ssh/authorized_keys

# Specify IP numbers for PN modules
IP1="192.168.1.96"
IP2="192.168.1.98"
IP3="192.168.1.100"

# Basic initialization steps of Pixie-Net
# the addl. clockprog call is required for PTP unless the
# PTP PLL EEPROM is configured to send the PTP clock to the FPGA
ssh root@$IP1 'cd /var/www; ./clockprog 2; ./progfippi; ./findsettings'
ssh root@$IP2 'cd /var/www; ./clockprog 2; ./progfippi; ./findsettings'
ssh root@$IP3 'cd /var/www; ./clockprog 2; ./progfippi; ./findsettings'

# Start LinuxPTP in background (alternative: start as service)
# this program manages the time synchronization over the network
# but kill any old process first
ssh root@$IP1 'pkill ptp4l'	
ssh root@$IP2 'pkill ptp4l'	
ssh root@$IP3 'pkill ptp4l'

ssh root@$IP1 "sh -c 'nohup ptp4l -i eth0 > /dev/null 2>&1 &'"	
ssh root@$IP2 "sh -c 'nohup ptp4l -i eth0 -s > /dev/null 2>&1 &'"	
ssh root@$IP3 "sh -c 'nohup ptp4l -i eth0 -s > /dev/null 2>&1 &'"
# option -s means slave only
# sometimes the ethernet shows up as eth0 or eth1, modify accordingly
