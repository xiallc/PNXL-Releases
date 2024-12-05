# Time Synchronization Example

These scripts provide examples of how to synchronizatize multiple Pixie-Net XLs using 
PTP or White Rabbit. These scripts can be used on any system supporting scp and bash.
They'll work best if you configure passwordless SSH. That way you don't have to 
enter a password every time the SCP commands get called. 

Configuration-as-code tools make this process much simpler. We recommend 
[Ansible](https://www.ansible.com/). 