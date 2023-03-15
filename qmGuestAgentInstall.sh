#!/bin/bash

vmid=$(grep -o '".[0-9]*"' /etc/pve/.vmlist | sed 's/"//g')
vmNames=$(pvesh get /cluster/resources --type vm --output-format json | grep -Po '"name".*?[^\\]",' | cut -d ":" -f 2 | sed 's/"//g; s/,//g')

#Gets running Virtual Machines on each cluster node
runningVMIDs=$(qm list | awk '$3 ~ /running/' | cut -d ' ' -f8)


username=""

#Run on each Proxmox server
for i in $runningVMIDs
do
	#Returns name of iso
	isoVersion=$(qm config $i | grep -o "\/.*\.iso" | cut -c 2-)
	runningVMName=$(qm config $i | grep ^name | awk '{print $2}')
	agentCheck=$(qm agent $i ping &> /dev/null)
	
	#If QEMU Guest Agent is installed no action, otherwise install it
	if [[ $? -eq 0 ]]; then
		echo "QEMU Guest Agent is installed on: $runningVMName"
	else
		#If VM is a Linux OS
		if [ $isoVersion == *"Linux"* ]; then
			ssh -T $username@$runningVMName <<-EOF
				apt-get install qemu-guest-agent;
				systemctl enable qemu-guest-agent;
				systemctl start qemu-guest-agent;
			EOF
		fi
	fi
done
