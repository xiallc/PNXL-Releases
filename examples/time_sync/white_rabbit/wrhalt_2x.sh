#!/bin/bash
# This is a simple script to shut down 2 Pixie-Net XL from 
# a remote host

# Specify IP numbers for PN modules
IP1="192.168.1.93"
IP2="192.168.1.45"

# Issue the halt command
ssh root@$IP1 'halt'
ssh root@$IP2 'halt'

