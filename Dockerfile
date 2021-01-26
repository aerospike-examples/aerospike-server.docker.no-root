FROM debian:stretch-slim 


ARG AEROSPIKE_BUILD_DIR=/aerospike_build
ARG AEROSPIKE_RUN_DIR=/aerospike

ENV AEROSPIKE_RUN_DIR $AEROSPIKE_RUN_DIR

RUN \
	apt-get update -y && \
  	apt-get install -y wget binutils xz-utils libcurl3 libreadline-dev && \
    mkdir $AEROSPIKE_BUILD_DIR && \
	chgrp -R 0 $AEROSPIKE_BUILD_DIR && \
    chmod -R g=u $AEROSPIKE_BUILD_DIR && \
    mkdir $AEROSPIKE_RUN_DIR && \
	chgrp -R 0 $AEROSPIKE_RUN_DIR && \
    chmod -R g=u $AEROSPIKE_RUN_DIR

COPY aerospike.template.conf $AEROSPIKE_BUILD_DIR
COPY install-aerospike-non-root.sh $AEROSPIKE_BUILD_DIR
COPY lib/ $AEROSPIKE_BUILD_DIR/lib
COPY templates/ $AEROSPIKE_BUILD_DIR/templates
COPY /entrypoint.sh /entrypoint.sh

RUN	\
	cd $AEROSPIKE_BUILD_DIR && \
	$AEROSPIKE_BUILD_DIR/install-aerospike-non-root.sh -c aerospike.template.conf -d $AEROSPIKE_RUN_DIR -o -i debian9

CMD ["/entrypoint.sh"]
