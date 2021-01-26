#!/bin/bash

DEFAULT_INSTALL_SUB_DIRECTORY=aerospike_local

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


