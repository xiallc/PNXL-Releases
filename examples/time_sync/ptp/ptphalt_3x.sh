#!/bin/bash
# This is a simple script to shut down 3 Pixie-Nets from 
# a remote host

# Specify IP numbers for PN modules
IP1="192.168.1.96"
IP2="192.168.1.98"
IP3="192.168.1.100"

# Issue the halt command
ssh root@$IP1 'halt'
ssh root@$IP2 'halt'
ssh root@$IP3 'halt'

