FROM debian:stretch-slim 

# Build args - meaning should be self evident
ARG AEROSPIKE_BUILD_DIR=/aerospike_build
ARG AEROSPIKE_RUN_DIR=/aerospike
ARG RUN_TIME_USER=asd
ARG RUN_TIME_GROUP=root
ARG DATA_DIR=${AEROSPIKE_RUN_DIR}/opt/aerospike/data
ARG IS_ENTERPRISE=0
ARG FEATURE_KEY_FILE=features.conf

# These parameters are also used at run time
ENV AEROSPIKE_RUN_DIR $AEROSPIKE_RUN_DIR
ENV RUN_TIME_USER $RUN_TIME_USER

# Copy over build assets
COPY . $AEROSPIKE_BUILD_DIR/
COPY asd.start.sh /asd.start.sh

# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#
EXPOSE 3000 3001 3002 3003

# Build the non-root install assets
RUN	\
	apt-get update -y && \
  	apt-get install -y wget binutils xz-utils libcurl3 libreadline-dev && \
	useradd -u 10001 $RUN_TIME_USER -g $RUN_TIME_GROUP && \
    mkdir $AEROSPIKE_RUN_DIR && \
	COMMUNITY_FLAG=$(bash -c "if [[ $IS_ENTERPRISE -eq 0 ]]; then echo '-o' ; else echo ''; fi") && \
	ENTERPRISE_FLAG=$(bash -c "if [[ $IS_ENTERPRISE -eq 0 ]]; then echo '' ; else echo '-f $FEATURE_KEY_FILE'; fi") && \
	chmod a+rx-w /asd.start.sh && \
	cd $AEROSPIKE_BUILD_DIR && \
	$AEROSPIKE_BUILD_DIR/install-aerospike-non-root.sh -c aerospike.template.conf -d $AEROSPIKE_RUN_DIR $COMMUNITY_FLAG $ENTERPRISE_FLAG -i debian9 -p $DATA_DIR -u $RUN_TIME_USER -g $RUN_TIME_GROUP && \
    chown -R $RUN_TIME_USER:$RUN_TIME_GROUP $AEROSPIKE_RUN_DIR && \
    rm -rf $AEROSPIKE_BUILD_DIR

USER $RUN_TIME_USER
WORKDIR $AEROSPIKE_RUN_DIR

ENTRYPOINT ["/asd.start.sh"]
