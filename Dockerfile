FROM ubuntu:16.04
# Set default shell to bash
SHELL ["/bin/bash", "-c"]
# Set automatic acceptance of MicroSoft licence terms.
ARG ACCEPT_EULA=Y
# Envars for Freetds tarball sources (used to source tsql)
ENV FREETDS_TARBALL_FILENAME=freetds-patched.tar.gz
ENV FREETDS_TARBALL_MD5_FILENAME=$FREETDS_TARBALL_FILENAME.md5
ENV FREETDS_TARBALL_URL=http://www.freetds.org/files/stable/$FREETDS_TARBALL_FILENAME
ENV FREETDS_TARBALL_MD5_URL=$FREETDS_TARBALL_URL.md5
ENV FREETDS_BUILD_DIR=freetds_build

ENV PATH="/data01/casebook_migration:/opt/mssql-tools/bin:$PATH"

# Generate GB locale - this is required for the ETL script so that transliteration of
# e.g. £ signs are converted from UTF-8 to ASCII consistently.
RUN apt-get clean && apt-get update && apt-get install -y locales && locale-gen en_GB.UTF-8

RUN apt-get update && apt-get install -y apt-transport-https curl software-properties-common

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
        && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | \
            tee /etc/apt/sources.list.d/msprod.list

RUN apt-get update && apt-get install -y postgresql-client mysql-client \
    openjdk-8-jdk openjdk-8-jre gcc make wget python3 \
    python3-pip python3-setuptools groff less mssql-tools \
    && apt-get clean

RUN mkdir ~/$FREETDS_BUILD_DIR
RUN \
    # Download the Freetds utils tarball and md5 checksum file
    wget -P ~/$FREETDS_BUILD_DIR $FREETDS_TARBALL_URL && \
    wget -P ~/$FREETDS_BUILD_DIR $FREETDS_TARBALL_MD5_URL && \
    cd ~/$FREETDS_BUILD_DIR && \
    # Check the MD5 checksum
    [[ \
        $(head -1 freetds-patched.tar.gz.md5 | awk '{print $NF}') == \
        $(md5sum freetds-patched.tar.gz | awk '{print $1}') \
    ]] && \
    # Unzip and install the Freetds utils
    tar xzvfp freetds-patched.tar.gz && \
    cd freetds-* && ./configure && make && make install && \
    ln -s /usr/local/lib/libsybdb.so.5 /usr/lib/libsybdb.so.5 && \
    cd / && rm -rf ~/$FREETDS_BUILD_DIR

# Install AWS client
RUN pip3 --no-cache-dir install awscli pyentrypoint==0.7.1 --upgrade

