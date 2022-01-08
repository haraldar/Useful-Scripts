#!/usr/bin/bash

# Author: Harald Asmus
# Development period: Jan 1st, 2022 - Jan 6th, 2022
# Reason: As a newbie to nmap trying to discover live responding hosts in my home
#		is kind of inconsistent, so with this script I basically run all
#		the different nmap ping flavors in one go and collect the
# 		responding IPs.
# Functioning:
#	1 - Get the users IPv4 addresses.
# 	2 - User chooses range to scan.
# 	3 - Run the different nmap pings and collect all discovered IPs.
#	4 - Finally clean the IPs of any errors and ouput the result.

# This program runs nmap scans with sudo, therefore the user must have root privileges and that
# is the case when EUID is 0.
if [ "$EUID" -ne 0 ]; then
	echo "The script must be run as root."
	exit
fi

#if [[ $# == 0 ]]; then
## 	SCAN_LEVEL is our global variable indicating how many lines of scan techniques we want
##	to use. Accepted values are 1 to 3 (default: 2). Higher defaults to 3, lower to 1.
#	echo "No SCAN_LEVEL parameter has been passed. Defaulting to 2."
#	SCAN_LEVEL=2
#else
#	SCAN_LEVEL=$1
#	if (( $SCAN_LEVEL > 3 )); then
#		echo "SCAN_LEVEL cannot be bigger than 3. Defaulting to 3."
#		SCAN_LEVEL=3
#	elif (( $SCAN_LEVEL < 1 )); then
#		echo "SCAN_LEVEL cannot be smaller than 1. Defaulting to 2."
#		SCAN_LEVEL=1
#	fi
#fi

# Displays the help.
function display_help(){
	echo "getlive is a command-line tool for discovering multiple hosts in the same network using"
	echo "nmap scan techniques."
	echo "Usage: getlive [option]"
	echo "	-i, --ips		prints the system's IPv4s"
	echo "	-n, --nmap_scans	prints the different nmap scan techniques"
	echo "	-h, --help		prints the help"
	echo "	[value]			runs the main program with the value (default: 2)"
}

# get_ipv4s() filters out and returns the IPv4's returned by the 'ip addr show' command.
# Returns: Stringified array containing the IPv4's.
function get_ipv4s(){
	local ip_addrs=($(ip addr show | awk '/inet / {print $2}'))
	echo "${ip_addrs[@]}"
}

# display_options() displays an array of different options with indices.
# Params: Stringified array containing the options to display.
function display_options(){
	local options=($1)
	options_amount=$((${#options[@]}-1))
	for i in $(seq 0 $options_amount)
	do
		echo "$i ${options[$i]}"
	done
}

# select_option() reads the user's input and returns the selection from the array passed.
# Params: Stringified array of options.
# Returns: The selected item from the array.
function select_option(){
	read selection
	local options=($1)
	echo "${options[$selection]}"
}

# nmap_techniques() finds the different scan techniques in the 'nmap -h' command.
# Returns: Stringified array of scan techniques.
function nmap_techniques(){
	local techniques_section=$(nmap -h | grep "SCAN TECHNIQUES:" --after-context=$SCAN_LEVEL\
		--line-buffered | awk '/ -s/ {print $1}')
	techniques_section=$(tr '\n' ' ' <<< "$techniques_section" | tr -d ':' |\
		tr -d '-' | tr '/' ' ' | xargs)
	echo "$techniques_section"
}

# run_pings() runs the given scan techniques on a specified range.
# Params:
#	(1) The IPv4 range to scan.
#	(2) Stringified array of scan tachniques to run.
# Returns: Stringified array containing all responding IPs from all scans (non-unique array).
function run_pings(){
	local flavors=($2)
	local responding=""
	for i in $(seq 0 $((${#flavors[@]}-1)))
	do
		responding+=$(sudo nmap -n -${flavors[$i]} "$1" --host-timeout=5\
				| awk '/Nmap s/ {print $NF}')
		responding+=" "
	done
	echo "${responding[@]}"
}

# distinctify_array() removes all duplicate values.
# Params: Stringified array.
# Returns: Stringified array containing only unique values.
function distinctify_array(){
	local arr=($1)
	arr=($(tr ' ' '\n' <<< "${arr[@]}" | tr -d '()' | sort -u | tr '\n' ' '))
	echo "${arr[@]}"
}

function main(){
	local teqs=$(nmap_techniques)
	echo "Choose IPv4 address to scan."
	local ipv4s=$(get_ipv4s)
	display_options "$ipv4s"
	local selected_ipv4=$(select_option "$ipv4s")
	echo "$selected_ipv4"
	echo "Running discovery pings ($teqs) now."
	local results=$(run_pings "$selected_ipv4" "$teqs")
	echo "Finished."
	local distinct_results=$(distinctify_array "${results[@]}")
	echo "Responding hosts:"
	echo "${distinct_results[@]}"
}

if [[ $# == 0 ]]; then
	echo "No SCAN_LEVEL parameter has been passed. Defaulting to 2."
	SCAN_LEVEL=2
	main
else
	case $1 in
		'')
			SCAN_LEVEL=2
			echo "No SCAN_LEVEL parameter has been passed. Defaulting to 2."
			main
			exit
			;;
		 *[0-9]*)
			SCAN_LEVEL=$1
			main
			exit
			;;
		'-h' | '--help')
			display_help
			exit
			;;
		'-i' | '--ips')
			get_ipv4s
			exit
			;;
		'-n' | '--nmap_scans')
			SCAN_LEVEL=3
			nmap_techniques
			exit
			;;
	esac
fi

