#!/bin/bash

path="/usr/local/nagios/etc/objects"
nagiosConfig="/usr/local/nagios/etc/nagios.cfg"
subnet="x.x.x.x/xx"
template="customtemplate.cfg"

#Returns hostname:ip address for each server in subnet
search=$(nmap -sP $subnet | awk -F '[ ()]' '/for [a-z]+/ {print $5 ":" $7}')

cd $path

for host in $search
do
	hostname=$(echo $host | cut -d ":" -f1)
	ip=$(echo $host | cut -d ":" -f2)
	alias=$(echo $hostname | cut -d "." -f1)
	
	hostfile="$alias.cfg"
	
	#If the VM config file does not exist and is not nagios then create a new hostfile
	if [ ! -e $hostfile ] && [ $alias != "nagios" ]; then
		cp $template $hostfile
		
		sed -i \
		-e "s/temp-hostname/$hostname/" \
		-e "s/temp-alias/$alias/" \
		-e "s/temp-address/$ip/" $hostfile
		
		#If hostfile path does not exist already add it to the Nagios cfg file
		grep -qxF "cfg_file=$path/$hostfile" $nagiosConfig || echo "cfg_file=$path/$hostfile" >> $nagiosConfig
	fi
	
done

systemctl restart nagios.service
