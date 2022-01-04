#!/usr/bin/bash

# Author: Harald Asmus
# Development period: Jan 1st, 2022 - Jan 4th, 2022
# Reason: As a newbie to nmap trying to discover live responding hosts in my home
#		is kind of inconsistent, so with this script I basically run all
#		the different nmap ping flavors in one go and collect the
# 		responding IPs.
# Functioning:
#	1 - Get the users IPv4 addresses with 'ip addr show'.
# 	2 - User chooses range to scan.
# 	3 - After selection immediately run pings and simply collect all responding IPs.
#	4 - Finally clean the IPs of any errors and ouput the result.
# TODO:
#	1 - surpress the name resolution.
#	2 - use key value array for all filters.
# 	3 - split choose_ipv4 into get_ipv4s() and choose_ipv4s(), so that latter one may
# 		return a string with echo instead of using a global.
#	4 - clean the code and more documentation on code parts.
#	5 - check if script is run with admin privileges. --> DONE, Jan 4th 22
#	6 - add wrapper function for the nmap-cmds in run_pings. - DONE, Jan 4th 22

if [ "$EUID" -ne 0 ]
	then echo "The script must be run as root."
	exit
fi

end=""
iprange=""

function choose_ipv4(){
	local ip_addrs=($(ip addr show | awk '/inet / {print $2}'))
	local ip_amount=$((${#ip_addrs[@]}-1))
	for i in $(seq 0 $ip_amount)
	do
		echo "$i ${ip_addrs[$i]}"
	done
	read ip_select
	iprange=${ip_addrs[$ip_select]}
}

function nmap_wrap(){
	local message=$2
	echo "$message"
	end+=$(sudo nmap $1 $iprange | awk '/Nmap s/ {print $NF}')
	end+=" "
}

function run_pings(){
	local flavors=("-sS" "-sA" "-sn -PS" "-sn -PU" "-sY")
	local msgs=("Default stealth ping ..." "TCP ACK ping ..."
			"TCP SYN ping ..." "UDP ping ..."
			"SCTP Init ping ...")
	for i in $(seq 0 $((${#flavors[@]}-1)))
	do
		nmap_wrap "${flavors[$i]}" "${msgs[$i]}"
	done
	end=($end)
}

function distinctify_array(){
	declare -a arr=("${!1}")
	arr=($(tr ' ' '\n' <<< "${arr[@]}" | tr -d '()' | sort -u | tr '\n' ' '))
	echo "${arr[@]}"
}

function main(){
	echo "Choose IPv4 address to scan."
	choose_ipv4
	echo "Running discovery pings on $iprange now."
	run_pings
	echo "Finished."
	local resultset=$(distinctify_array end[@])
	echo "Responding hosts:"
	echo "${resultset[@]}"
}

main
