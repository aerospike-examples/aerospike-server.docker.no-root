#!/bin/bash

##############################################################
# 
# Script Name : run_aerospike_non_root.sh
#
# Author : Ken Tune
# Date : 2020-02-11
#
# Description : Start and stop asd from a non-root install
#
# Usage : run_aerospike_non_root.sh start | stop
#
# Notes : Also supplied as a template file - if so you will see a replacement token for $INSTALL_DIR
#
# Copyright (C) 2020 Aerospike, Inc.
#
##############################################################


#---------------------------
# Static variables
#---------------------------
INSTALL_DIR=#LOCAL_AEROSPIKE_DIR#
ASD_CONFIG=$INSTALL_DIR/etc/aerospike/aerospike.conf
ASD_EXE=$INSTALL_DIR/usr/bin/asd
PID_FILE=$INSTALL_DIR/var/run/aerospike/asd.pid
TEMP_FILE_DIR="/tmp/"

USAGE="$0 start|stop"

#---------------------------
# Utility functions
#---------------------------

# Generate temporary file name
temp_file_name(){
        TEMP_FILE_PATH="${TEMP_FILE_DIR}$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
}

# Check if asd is running
# Returns 0 if asd running
asd_check(){
	pgrep ^asd$ 1>/dev/null 2>&1
	return $? # return $? is redundant but for clarity...
}

echo "Setting ulimit to #FD_LIMIT#"
ulimit -n #FD_LIMIT#

# Get argument
ARG=$1
shift

if [ -z $ARG ] 
then
	echo "No argument supplied"
	echo $USAGE
	exit 1
fi

case $ARG in 
	start)  asd_check
		if (( $? == 0 ))
		then
			echo "Aerospike already running"
			exit 1
		fi
		$ASD_EXE --config-file $ASD_CONFIG
		echo "Aerospike started"
	;;
	stop)	if [ -e $PID_FILE ]
		then
			ps -p $(cat $PID_FILE) 1>/dev/null 2>&1
			# Result of ps -p to check if asd running
			if (( $? == 0 ))
			then
				echo "Stopping Aerospike"
				kill -s TERM $(cat $PID_FILE) 1>/dev/null 2>&1
				while (( $(ps -p $(cat $PID_FILE) | wc -l) > 1 ))
				do
					sleep 1
				done
				asd_check
				if (( $? == 0 ))
	                        then
        	                        echo "Other Aerospike process found"
                	                echo "PID : $(pgrep ^asd$)"
                                	exit 1
                        	else
                                	echo "Aerospike stopped"
                        	fi

			else
				echo "Aerospike started as pid $(cat $PID_FILE) not running"
				# Is asd running under a different pid?
				asd_check
				if (( $? == 0 ))
				then
					echo "Additional Aerospike process found however"
					echo "PID : $(pgrep ^asd$)"
					exit 1
				else
					echo "Aerospike stopped"
				fi
			fi
		else
			echo "PID file for Aerospike not found"
			asd_check
			if (( $? == 0 )) 
			then
				echo "but Aerospike process running - may need to kill manually"
				echo "PID : $(pgrep ^asd$)"
				exit 1
			else
				echo "Aerospike not running"
			fi
		fi
	;;
	*)
		echo "Argument $ARG not recognized"
		echo $USAGE
		exit 1
	;;
esac

exit 0
