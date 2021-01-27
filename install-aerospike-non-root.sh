#!/bin/bash

################################################################
#
# Script Name : install-aerospike-non-root.sh
#
# Author : Ken Tune
# Date : 2020-02-11
#
# Description : Allows running of Aerospike (asd) without needing root or sudo privileges
#		Will download specified version of Aerospike and set up 'local' version under INSTALL_DIRECTORY (see below)
#
# Usage : 
#	install-aerospike-non-root.sh -c <AEROSPIKE_CONFIG_PATH> -f <FEATURE_KEY_FILE> [ -d INSTALL_DIRECTORY] [ -v AEROSPIKE_VERSION ] [ -p DATA_PARTITION ] [ -o ] [ -u RUN_TIME_USER ] [ -g RUN_TIME_GROUP ]
#
#	AEROSPIKE_CONFIG_PATH - location of aerospike.conf to be used. Mandatory argument - no default.
#	FEATURE_KEY_FILE - location of Aerospike Enterprise feature key file. Mandatory - no default.
#	INSTALL_DIRECTORY - directory into which Aerospike will be installed. Defaults to $PWD/${DEFAULT_INSTALL_SUB_DIRECTORY}
#	AEROSPIKE_VERSION - version of Aerospike to download and use. Defaults to 'latest'
# 	DATA_PARTITION - used to replace #DATA_FILE# in aerospike.conf - location of a filesystem based Aerospike datafile. 
#			 Defaults to INSTALL_DIRECTORY/opt/aerospike/data.data. /data.dat appended if a directory
#   Use the -o flag to install community, rather than Enterprise
#
# Copyright (C) 2020 Aerospike, Inc.
#
################################################################

#-----------------
# Dependencies
#-----------------
source lib/util-functions.sh

#-----------------
# Static Variables
#-----------------
USAGE="$0 -c <AEROSPIKE_CONFIG_PATH> -f <FEATURE_KEY_FILE> [ -d INSTALL_DIRECTORY] [ -v AEROSPIKE_VERSION ] [ -p DATA_PARTITION ] [ -o ] [ -i DISTRIBUTION ] [ -u RUN_TIME_USER ] [ -g RUN_TIME_GROUP ]"
CURRENT_DIRECTORY=$(pwd)
DEFAULT_LOCAL_AEROSPIKE_DIR=$(pwd)/${DEFAULT_INSTALL_SUB_DIRECTORY}
DEFAULT_DISTRIBUTION=el6
RECOMMENDED_FD_LIMIT=15000
TEMP_FILE_DIR=/tmp
IS_COMMUNITY=0
PERMITTED_DISTRIBUTIONS="$DEFAULT_DISTRIBUTION el7 el8 debian8 debian9 debian10 ubuntu14 ubuntu 16 ubuntu18"
DISTRIBUTION=$DEFAULT_DISTRIBUTION
DEFAULT_RUN_TIME_USER=root
DEFAULT_RUN_TIME_GROUP=root

#------------------
# Utility Functions
#------------------

# Function checks if current user can write to a given file path
# Returns 0 if true otherwise non-zero
check_writeable_file(){
	touch $1 2>/dev/null
	CHECK_WRITEABLE_FILE=$?
	rm $1 2>/dev/null
}

# Generate a temporary file name
# Store in TEMP_FILE_PATH
temp_file_name(){
        TEMP_FILE_PATH="${TEMP_FILE_DIR}/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)"
}

# Check if a supplied executable is available
# Aborts if not
# Used to check for dependencies
check_exe_available(){
	EXE=$1
	which $EXE 1>/dev/null 2>&1
	EXE_AVAILABLE=$?
	if (( $EXE_AVAILABLE != 0 ))
	then
		echo "$EXE not found but required to run this script- aborting"
        	exit 1	
	fi
}

# Is supplied path local or relative
# Returns 1 if local, 0 if absolute
is_local_path(){
	case "$1" in 
		/*)	IS_LOCAL_PATH=0
		;;
		*)	IS_LOCAL_PATH=1
	esac
}

# Will attempt to create a directory with supplied name if not available using the -p (create parents) option
# Returns 0 if successful, non-zero if not
safe_mkdir(){
	DIR=$1
	if [ ! -d ${DIR} ]
	then
		mkdir -p $DIR
		return $?
	else
		return 0
	fi
}

# Check relevant binaries available
# Will exit if not available
for exe in which diff
do
	check_exe_available $exe
done

#-------------------------------
# Process command line arguments
#-------------------------------
while getopts ":d:c:f:p:v:i:g:u:o" arg ; do
	case ${arg} in
	    c)	AEROSPIKE_CONFIG=$OPTARG
		;;	
		d)	LOCAL_AEROSPIKE_DIR=$OPTARG
		;;
		f)	FEATURE_KEY_FILE=$OPTARG
		;;
		i)	DISTRIBUTION=$OPTARG
		;;
		o)	IS_COMMUNITY=1
		;;
		p)	DATA_PARTITION=$OPTARG
		;;
		v)	AEROSPIKE_VERSION=$OPTARG
		;;
		u)	RUN_TIME_USER=$OPTARG
		;;
		g)	RUN_TIME_GROUP=$OPTARG
		;;
		:)	echo "Invalid option: $OPTARG requires an argument"
			echo "Usage : $USAGE"
			exit 1
		;;
	esac	
done

# Handle AEROSPIKE_CONFIG - exit if not supplied, or if supplied file does not exist
if [ -z $AEROSPIKE_CONFIG ]
then
	echo "No Aerospike configuration file provided"
	echo "Usage : $USAGE"
	exit 1
elif [ ! -f $AEROSPIKE_CONFIG ]
then
	echo "Specified configuration file $AEROSPIKE_CONFIG does not exist"
	exit 1
fi	

# Make config file path absolute if relative
is_local_path $AEROSPIKE_CONFIG
if (( $IS_LOCAL_PATH ==1 ))
then
        AEROSPIKE_CONFIG=$CURRENT_DIRECTORY/$AEROSPIKE_CONFIG
fi

# Handle FEATURE_KEY_FILE - exit if not supplied, or if supplied file does not exist
if (( $IS_COMMUNITY==0 ))
then
	if [ -z $FEATURE_KEY_FILE ]
	then
		echo "No Aerospike feature key file provided"
		echo "Usage : $USAGE"
		exit 1
	elif [ ! -f $FEATURE_KEY_FILE ]
	then
		echo "Specified feature key file $FEATURE_KEY_FILE does not exist"
		exit 1
	fi
	# Make feature key file path absolute if relative
	is_local_path $FEATURE_KEY_FILE
	if (( $IS_LOCAL_PATH ==1 ))
	then
		FEATURE_KEY_FILE=$CURRENT_DIRECTORY/$FEATURE_KEY_FILE
	fi
fi
# Handle data partition argument
# This is used to replace #DATA_PARTITION# in aerospike.conf
# If a directory is given, turn into a file name, by suffixing /data.dat
# Will check that the resulting path is writeable
if [ ! -z $DATA_PARTITION ]
then
	safe_mkdir $DATA_PARTITION	
	if [ -d $DATA_PARTITION ]
	then
		DATA_PARTITION=${DATA_PARTITION}/data.dat
	fi
	check_writeable_file $DATA_PARTITION
	if [ ! 0 -eq $CHECK_WRITEABLE_FILE ]
	then
		echo "Cannot write to $DATA_PARTITION - aborting"
		exit 1
	fi
else
	DATA_PARTITION=${DEFAULT_LOCAL_AEROSPIKE_DIR}/opt/aerospike
	safe_mkdir $DATA_PARTITION
	DATA_PARTITION=${DATA_PARTITION}/data.dat
fi

DISTRIBUTION_CHECK=0
for DIST in $PERMITTED_DISTRIBUTIONS
do
	if [ $DIST == $DISTRIBUTION ]
	then
		DISTRIBUTION_CHECK=1
	fi
done

if (( $DISTRIBUTION_CHECK == 0 ))
then
	echo "Distribution $DISTRIBUTION is not a permitted distribution. Should be one of $PERMITTED_DISTRIBUTIONS"
	exit 1
fi

# Make use of defaults where options not provided ( -d -v -p options )
LOCAL_AEROSPIKE_DIR=${LOCAL_AEROSPIKE_DIR:=$DEFAULT_LOCAL_AEROSPIKE_DIR}
AEROSPIKE_VERSION=${AEROSPIKE_VERSION:=latest}
RUN_TIME_USER=${RUN_TIME_USER:=$DEFAULT_RUN_TIME_USER}
RUN_TIME_GROUP=${RUN_TIME_GROUP:=$DEFAULT_RUN_TIME_GROUP}

# Need to create install directory if we're using current working directory
# If we have been given a local directory need to checjk it exists and is writeable
if [ $LOCAL_AEROSPIKE_DIR == $DEFAULT_LOCAL_AEROSPIKE_DIR ]
then
	safe_mkdir $LOCAL_AEROSPIKE_DIR
elif [ ! -d $LOCAL_AEROSPIKE_DIR ]
then
	echo "Nominated install directory $LOCAL_AEROSPIKE_DIR does not exist"
	exit 1
elif [ ! -w $LOCAL_AEROSPIKE_DIR ]
then
	echo "Install directory $LOCAL_AEROSPIKE_DIR is not writeable"
	exit 1
fi

# Summarize provided options
echo "Installing Aerospike to $LOCAL_AEROSPIKE_DIR"
echo "Using configuration file $AEROSPIKE_CONFIG"
if (( $IS_COMMUNITY == 0 ))
then
	echo "Feature key file $FEATURE_KEY_FILE"
else
	echo "Using community edition"
fi
echo "Using data partition $DATA_PARTITION"

#---------------------------------
# Download and 'install' Aerospike
#---------------------------------
AEROSPIKE_SERVER_INSTALL=aerospike-${AEROSPIKE_VERSION}-${DISTRIBUTION}-server.tgz

# Install Directory
safe_mkdir ${LOCAL_AEROSPIKE_DIR}/install

cd ${LOCAL_AEROSPIKE_DIR}/install

# Download if required
if [ ! -f $AEROSPIKE_SERVER_INSTALL ]
then
	echo "Downloading Aerospike version $AEROSPIKE_VERSION $DISTRIBUTION distribution"
	temp_file_name
	WGET_BUFFER=$TEMP_FILE_PATH
	if (( $IS_COMMUNITY == 1 ))
	then
		DOWNLOAD_PREFIX=http://www.aerospike.com/download/server/
	else
		DOWNLOAD_PREFIX=http://www.aerospike.com/enterprise/download/server/
	fi
	wget -O $AEROSPIKE_SERVER_INSTALL ${DOWNLOAD_PREFIX}${AEROSPIKE_VERSION}/artifact/${DISTRIBUTION} > $WGET_BUFFER 2>&1
	WGET_EXIT_CODE=$?
	if (($WGET_EXIT_CODE == 0))
	then
		rm $WGET_BUFFER
	elif (($WGET_EXIT_CODE == 8))
	then
		echo "Aerospike version $AEROSPIKE_VERSION not found"
		rm $AEROSPIKE_SERVER_INSTALL
		rm $WGET_BUFFER
		exit 8
	else
		echo "Error occurred when downloading $AEROSPIKE_SERVER_INSTALL"
		rm $AEROSPIKE_SERVER_INSTALL
		tail -n 2 $WGET_BUFFER
		rm $WGET_BUFFER
		exit $WGET_EXIT_CODE
	fi
else
	echo "Existing ${AEROSPIKE_SERVER_INSTALL} found - using that"
fi

# Untar and unpack rpm
tar xf $AEROSPIKE_SERVER_INSTALL
# Hack as Ubuntu distribution appears as 14.04/16.04/18.04 in tar file
cd *-${DISTRIBUTION} 2>/dev/null || cd *-${DISTRIBUTION}.04

if [[ $DISTRIBUTION == el* ]]
then
	for exe in rpm2cpio cpio
	do
		check_exe_available $exe
	done
	rpm2cpio aerospike-server-*.${DISTRIBUTION}.x86_64.rpm 2>/dev/null | cpio -idmv 1>/dev/null 2>&1
	rpm2cpio aerospike-tools-*.${DISTRIBUTION}.x86_64.rpm 2>/dev/null | cpio -idmv 1>/dev/null 2>&1
elif [[ $DISTRIBUTION == deb* || $DISTRIBUTION == ubuntu* ]]
then
	check_exe_available ar
 	ar x aerospike-server-*.${DISTRIBUTION}*.x86_64.deb 
 	tar xf control.tar.*
 	tar xf data.tar.*
 	ar x aerospike-tools-*.${DISTRIBUTION}*.x86_64.deb
 	tar xf control.tar.*
    tar xf data.tar.*
fi

	#statements

# Move contents to 'local aerospike' directory
for sub_dir in etc opt usr var 
do
	rm -rf ${LOCAL_AEROSPIKE_DIR}/$sub_dir
	if [ -d $sub_dir ]
	then
		mv $sub_dir ${LOCAL_AEROSPIKE_DIR}
	fi
done
# Take care of some soft linking
for exe in aql asadm asbackup asbenchmark asinfo asloader asloglatency asrestore
do
	rm ${LOCAL_AEROSPIKE_DIR}/usr/bin/$exe
	ln -s ${LOCAL_AEROSPIKE_DIR}/opt/aerospike/bin/$exe ${LOCAL_AEROSPIKE_DIR}/usr/bin/$exe
done
rm -rf ../*-${DISTRIBUTION}

# Create required system directories
for DIR in /var/log/aerospike /var/udf/lua /var/smd /var/run/aerospike /share/udf/lua /smd
do
	safe_mkdir ${LOCAL_AEROSPIKE_DIR}${DIR}
done


# Copy feature key into local Aerospike
if (( $IS_COMMUNITY == 0 ))
then
	cp $FEATURE_KEY_FILE ${LOCAL_AEROSPIKE_DIR}/etc/aerospike/features.conf
fi
#---------------------------------------------
# Set fd limit if we can. Warn if not possible
# --------------------------------------------
ulimit -n $RECOMMENDED_FD_LIMIT > /dev/null 2>&1
if (( $? != 0)) 
then
	echo "WARNING : Unable to modify file descriptor limit"
fi	
FD_LIMIT=$(ulimit -n)
if (( $FD_LIMIT < $RECOMMENDED_FD_LIMIT )) 
then
	echo "WARNING : File descriptor limit $FD_LIMIT is lower than recommended limit $RECOMMENDED_LIMIT"
	echo "This may affect Aerospike performance."
fi

#---------------------------------------------
# Copy supplied config file into local Aerospike area
# Replace special tokens if used
# ASD_USER, ASD_GROUP, DATA_FILE, LOCAL_AEROSPIKE_DIR, FD_LIMIT
#---------------------------------------------

ASD_CONFIG_PATH=${LOCAL_AEROSPIKE_DIR}/etc/aerospike/aerospike.conf
cp ${AEROSPIKE_CONFIG} $ASD_CONFIG_PATH
sed -i "s/#ASD_USER#/$RUN_TIME_USER/" $ASD_CONFIG_PATH
sed -i "s/#ASD_GROUP#/$RUN_TIME_GROUP/" $ASD_CONFIG_PATH
ESCAPED_DATA_PARTITION=$(echo $DATA_PARTITION | sed 's/\//\\\//g')
ESCAPED_LOCAL_DIR=$(echo $LOCAL_AEROSPIKE_DIR | sed 's/\//\\\//g')
sed -i "s/#DATA_FILE#/${ESCAPED_DATA_PARTITION}/" $ASD_CONFIG_PATH
sed -i "s/#LOCAL_AEROSPIKE_DIR#/${ESCAPED_LOCAL_DIR}/" $ASD_CONFIG_PATH
sed -i "s/#FD_LIMIT#/${FD_LIMIT}/" $ASD_CONFIG_PATH

RUN_ASD_NON_ROOT_PATH=${LOCAL_AEROSPIKE_DIR}/usr/bin/run-asd-non-root.sh
cp ${CURRENT_DIRECTORY}/templates/run_asd_non_root_template.sh $RUN_ASD_NON_ROOT_PATH
sed -i "s/#LOCAL_AEROSPIKE_DIR#/${ESCAPED_LOCAL_DIR}/" $RUN_ASD_NON_ROOT_PATH
sed -i "s/#FD_LIMIT#/${FD_LIMIT}/" $RUN_ASD_NON_ROOT_PATH

echo "Install to $LOCAL_AEROSPIKE_DIR complete"
