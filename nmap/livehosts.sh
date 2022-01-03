#!/usr/bin/bash

# Author: Harald Asmus
# Development period: Jan 1st, 2022 - Jan 3rd, 2022
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
#	5 - check if runs with admin privileges.
#	6 - put 'sudo nmap -xX *-xX args | awk "filter_args"' into a seperate function.

end=""
iprange=""
readonly ip_filter='/Nmap s/ {print $NF}'

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

function run_pings(){
	echo "Default Stealth ping ..."
	end+=$(sudo nmap -sS $iprange | awk "$ip_filter")
	end+=" "
	echo "TCP ACK ping ..."
	end+=$(sudo nmap -sA $iprange | awk "$ip_filter")
	end+=" "
	echo "TCP SYN ping ..."
	end+=$(sudo nmap -sn -PS $iprange | awk "$ip_filter")
	end+=" "
	echo "UDP ping ..."
	end+=$(sudo nmap -sn -PU $iprange | awk "$ip_filter")
	end+=" "
	echo "SCTP Init ping ..."
	end+=$(sudo nmap -sY $iprange | awk "$ip_filter")
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
	echo "Running discovery pings now."
	run_pings
	echo "Finished."
	local resultset=$(distinctify_array end[@])
	echo "Responding hosts:"
	echo "${resultset[@]}"
}

main
