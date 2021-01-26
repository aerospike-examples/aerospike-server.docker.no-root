#!/bin/bash

${AEROSPIKE_RUN_DIR}/usr/bin/run-asd-non-root.sh start

while [ 1 ]
do
	sleep 1000
done
