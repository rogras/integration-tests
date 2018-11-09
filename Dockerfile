FROM ubuntu:16.04

ARG KAFKA_VERSION=1.0.0
ARG KAFKA_DIST=kafka_2.11-1.0.0

# COYOTE ENV
ARG COYOTEPATH=/opt/landoop/tools
ARG COYOTEEXAMPLES=$COYOTEPATH/share/coyote/examples
ENV COYOTE=/opt/landoop/tools/bin

# CONFLUENT ENV
ARG CONFLUENT_VERSION=4.1.1
ARG CONFLUENT_DIST=4.1.1-2.11

# PROPERTIES
ENV IS_CAAS=1
 
COPY coyote-entrypoint.sh .
RUN chmod +x coyote-entrypoint.sh


# UPDATE + DEPENDENCIES
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         #wget='1.17.1-1ubuntu1.4' \
         tar='1.28-2.1ubuntu0.1' \
         git='1:2.7.4-0ubuntu1.5' \
         curl='7.47.0-1ubuntu2.11' \
         openjdk-8-jre-headless='8u181-b13-1ubuntu0.16.04.1' \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
 
# ADD COYOTE
ARG COYOTE_VERSION=1.5
ARG COYOTE_URL="https://github.com/Landoop/coyote/releases/download/v${COYOTE_VERSION}/coyote-${COYOTE_VERSION}"
RUN mkdir -p $COYOTEPATH/bin/win \
             $COYOTEPATH/bin/mac \
             $COYOTEEXAMPLES \
    && curl -O -L "$COYOTE_URL"-linux-amd64  && mv "coyote-${COYOTE_VERSION}"-linux-amd64 "$COYOTEPATH/bin/coyote"  \
    && curl -O -L "$COYOTE_URL"-darwin-amd64  && mv "coyote-${COYOTE_VERSION}"-darwin-amd64 "$COYOTEPATH/bin/mac/coyote"  \
    && curl -O -L "$COYOTE_URL"-windows-amd64.exe && mv  "coyote-${COYOTE_VERSION}"-windows-amd64.exe "$COYOTEPATH/bin/win/coyote" \
    && chmod +x $COYOTEPATH/bin/coyote \
                $COYOTEPATH/bin/mac/coyote


# ADD KAFKACAT
RUN apt-get update && apt-get install --no-install-recommends -y kafkacat='1.2.0-2' &&  apt-get clean && rm -rf /var/lib/apt/lists/*


# ADD CONFLUENT PLATFORM
RUN curl -O "http://packages.confluent.io/archive/4.1/confluent-oss-${CONFLUENT_DIST}.tar.gz" && \
tar -zxvf confluent-oss-$CONFLUENT_DIST.tar.gz
COPY kafka-avro-console-producer /confluent-$CONFLUENT_VERSION/bin/
COPY kafka-avro-console-consumer /confluent-$CONFLUENT_VERSION/bin/

RUN apt-get update && apt-get install --no-install-recommends -y unzip='6.0-20ubuntu1' &&  apt-get clean && rm -rf /var/lib/apt/lists/*
# ORACLE ENV
ARG ORACLE_VERSION=12.2
ARG ORACLE_DIST=x64-12.2.0.1.0

RUN apt-get update && apt-get install --no-install-recommends -y libaio1='0.3.110-2' &&  apt-get clean && rm -rf /var/lib/apt/lists/*
# ADD ORACLE
COPY include/oracle-binaries/ /opt/oracle/
RUN unzip /opt/oracle/instantclient-sdk-linux.$ORACLE_DIST.zip -d /opt/oracle && \
	unzip /opt/oracle/instantclient-basiclite-linux-part1.$ORACLE_DIST.zip -d /opt/oracle && \
	unzip /opt/oracle/instantclient-basiclite-linux-part2.$ORACLE_DIST.zip -d /opt/oracle && \
	unzip /opt/oracle/instantclient-sqlplus-linux.$ORACLE_DIST.zip -d /opt/oracle && \
	unzip /opt/oracle/instantclient-jdbc-linux.$ORACLE_DIST.zip -d /opt/oracle && \
	mv /opt/oracle/instantclient_12_2 /opt/oracle/instantclient

# ADD DB2

RUN dpkg --add-architecture i386 && apt-get update && apt-get install --no-install-recommends -y sharutils='1:4.15.2-1ubuntu0.1' binutils='2.26.1-1ubuntu1~16.04.7' libstdc++6:i386='5.4.0-6ubuntu1~16.04.10' libpam0g:i386='1.1.8-3.2ubuntu2.1' && apt-get clean && rm -rf /var/lib/apt/lists/* && ln -s /lib/i386-linux-gnu/libpam.so.0 /lib/libpam.so.0
RUN apt-get update && apt-get install --no-install-recommends -y libxml2='2.9.3+dfsg1-1ubuntu0.6' &&  apt-get clean && rm -rf /var/lib/apt/lists/*
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN  \
   adduser --quiet --disabled-password -shell /bin/bash -home /home/db2clnt --gecos "DB2 Client" db2clnt && \
   echo "db2clnt:$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | uuencode -| head -n 2 | grep -v begin | cut -b 2-10)" | chgpasswd && \
   adduser db2clnt sudo && \
   echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install DB2
RUN mkdir /install

# Copy DB2 tarball - ADD command will expand it automatically
RUN curl -o v10.5fp10_linuxx64_rtcl.tar.gz https://www.dropbox.com/s/lrrvjhomv63276b/v10.5fp10_linuxx64_rtcl.tar.gz?dl=1 && mv v10.5fp10_linuxx64_rtcl.tar.gz /install/

# Copy response file
COPY  include/db2/db2rtcl_nr.rsp /install/
# Run  DB2 silent installer
RUN /install/rtcl/db2setup -u /install/db2rtcl_nr.rsp && rm -fr /install/rtcl

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/oracle/instantclient
ENV PATH=$PATH:/etc/$KAFKA_DIST/bin:/kafkacat-master:$COYOTE/

COPY kafka_tests.yml /
