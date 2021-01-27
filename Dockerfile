FROM debian:stretch-slim 

# Build args - meaning should be self evident
ARG AEROSPIKE_BUILD_DIR=/aerospike_build
ARG AEROSPIKE_RUN_DIR=/aerospike
ARG RUN_TIME_USER=asd
ARG RUN_TIME_GROUP=root
ARG DATA_DIR=${AEROSPIKE_RUN_DIR}/opt/aerospike/data

# These parameters are also used at run time
ENV AEROSPIKE_RUN_DIR $AEROSPIKE_RUN_DIR
ENV RUN_TIME_USER $RUN_TIME_USER

# Preliminary build steps including directory creation
RUN \
	apt-get update -y && \
  	apt-get install -y wget binutils xz-utils libcurl3 libreadline-dev && \
	useradd -u 10001 $RUN_TIME_USER -g $RUN_TIME_GROUP && \
    mkdir $AEROSPIKE_BUILD_DIR && \
    mkdir $AEROSPIKE_RUN_DIR

# Copy over build assets
COPY aerospike.template.conf $AEROSPIKE_BUILD_DIR
COPY install-aerospike-non-root.sh $AEROSPIKE_BUILD_DIR
COPY lib/ $AEROSPIKE_BUILD_DIR/lib
COPY templates/ $AEROSPIKE_BUILD_DIR/templates
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
	chmod a+rx-w /asd.start.sh && \
	cd $AEROSPIKE_BUILD_DIR && \
	$AEROSPIKE_BUILD_DIR/install-aerospike-non-root.sh -c aerospike.template.conf -d $AEROSPIKE_RUN_DIR -o -i debian9 -p $DATA_DIR -u $RUN_TIME_USER -g $RUN_TIME_GROUP && \
    chown -R $RUN_TIME_USER:$RUN_TIME_GROUP $AEROSPIKE_BUILD_DIR && \
    chown -R $RUN_TIME_USER:$RUN_TIME_GROUP $AEROSPIKE_RUN_DIR && \
    rm -rf $AEROSPIKE_BUILD_DIR

USER $RUN_TIME_USER
WORKDIR $AEROSPIKE_RUN_DIR

ENTRYPOINT ["/asd.start.sh"]
