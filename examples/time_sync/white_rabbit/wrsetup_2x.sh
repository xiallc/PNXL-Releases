#!/bin/bash
# This is a simple script to set up 2 Pixie-Net XL for White Rabbit DAQ from 
# a remote host
# 
# Remember to set up public key login on Pixie-Net XL to avoid 
# having to type PW all the time
# create key on local machine (PC):  ssh-keygen -t rsa
# copy key to remote machine (Pixie-Net XL):   ssh-copy-id remote_host
# or better   : ssh-copy-id -o ControlPath=none root@192.168.1.71
#  followed by: ssh-add		(this is a bug fix of some sort)
# requires /etc/ssh/sshd_config has line 
#    AuthorizedKeysFile  .ssh/authorized_keys

# Specify IP numbers for PN modules
IP1="192.168.1.93"
IP2="192.168.1.45"

# Basic initialization steps of Pixie-Net
# the addl. clockprog call is required for PTP unless the
# PTP PLL EEPROM is configured to send the PTP clock to the FPGA
ssh root@$IP1 'cd /var/www; ./bootfpga; ./progfippi'
ssh root@$IP2 'cd /var/www; ./bootfpga; ./progfippi'

# todo: add findsettings

# WR functions start automatically after FPGA is booted
# WR MAC Ethernet IP address is taken from WR PROM
# WR PROM can be written via the WR UART I/O (type minicom in Pixie-Net XL terminal)

