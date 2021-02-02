FROM debian:stretch-slim 

# Build args - meaning should be self evident
ARG AEROSPIKE_BUILD_DIR=/aerospike_build
ARG AEROSPIKE_RUN_DIR=/aerospike
ARG RUN_TIME_USER=asd
ARG RUN_TIME_GROUP=asd
ARG DATA_DIR=${AEROSPIKE_RUN_DIR}/opt/aerospike/data
ARG IS_ENTERPRISE=0
ARG FEATURE_KEY_FILE=features.conf
ARG AEROSPIKE_VERSION=latest

# These parameters used at run time
ENV AEROSPIKE_RUN_DIR $AEROSPIKE_RUN_DIR
ENV RUN_TIME_USER $RUN_TIME_USER
ENV ASD_CONFIG_PATH=${AEROSPIKE_RUN_DIR}/etc/aerospike/aerospike.conf
ENV ASD_EXE=${AEROSPIKE_RUN_DIR}/usr/bin/asd
ENV HOME=/aerospike

# Copy over build assets
COPY . $AEROSPIKE_BUILD_DIR/

# Build the non-root install assets
RUN	\
# Install the things we need
apt-get update -y && \
apt-get install -y wget binutils xz-utils libcurl3 libreadline-dev python3 && \
# Add run time user and group
groupadd $RUN_TIME_GROUP && \
useradd -u 10001 $RUN_TIME_USER -g $RUN_TIME_GROUP && \
# Build the non-root assets
mkdir $AEROSPIKE_RUN_DIR && \
COMMUNITY_FLAG=$(bash -c "if [[ $IS_ENTERPRISE -eq 0 ]]; then echo '-o' ; else echo ''; fi") && \
ENTERPRISE_FLAG=$(bash -c "if [[ $IS_ENTERPRISE -eq 0 ]]; then echo '' ; else echo '-f $FEATURE_KEY_FILE'; fi") && \
cd $AEROSPIKE_BUILD_DIR && \
$AEROSPIKE_BUILD_DIR/install-aerospike-non-root.sh -c aerospike.template.conf -d $AEROSPIKE_RUN_DIR -v $AEROSPIKE_VERSION $COMMUNITY_FLAG $ENTERPRISE_FLAG \
-i debian9 -p $DATA_DIR -u $RUN_TIME_USER -g $RUN_TIME_GROUP && \
# Permissions
chown -R $RUN_TIME_USER:$RUN_TIME_GROUP $AEROSPIKE_RUN_DIR && \
# Tidy up. Note that this makes sure you don't inadvertently leave content from the COPY . above
rm -rf $AEROSPIKE_BUILD_DIR

# Expose Aerospike ports
#
#   3000 – service port, for client connections
#   3001 – fabric port, for cluster communication
#   3002 – mesh port, for cluster heartbeat
#   3003 – info port
#
EXPOSE 3000 3001 3002 3003

USER $RUN_TIME_USER
WORKDIR $AEROSPIKE_RUN_DIR

ENTRYPOINT exec $ASD_EXE --config-file $ASD_CONFIG_PATH --foreground
