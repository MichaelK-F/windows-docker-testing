# syntax=docker/dockerfile:1

ARG VERSION_ARG="latest"
FROM scratch AS build-amd64

COPY --from=qemux/qemu:7.12 / /

ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

RUN set -eu && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
        samba \
        wimtools \
        dos2unix \
        cabextract \
        libxml2-utils \
        libarchive-tools \
        netcat-openbsd \
        wget \
        unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install build dependencies and compile Guacamole server (VNC only)
RUN apt-get update && \
    apt-get --no-install-recommends -y install \
        build-essential \
        libcairo2-dev \
        libjpeg-dev \
        libpng-dev \
        libtool \
        uuid-dev \
        libvncserver-dev \
        libssl-dev \
        libpango1.0-dev \
        libwebp-dev \
        libssh2-1-dev \
        autoconf \
        automake \
        pkg-config && \
    cd /tmp && \
    wget -q https://archive.apache.org/dist/guacamole/1.6.0/source/guacamole-server-1.6.0.tar.gz && \
    tar -xzf guacamole-server-1.6.0.tar.gz && \
    cd guacamole-server-1.6.0 && \
    autoreconf -fiv && \
    ./configure --prefix=/opt/guacamole --with-init-dir=/etc/init.d --disable-rdp --disable-ssh --disable-telnet --disable-kubernetes && \
    make && \
    make install && \
    ldconfig && \
    cd / && \
    rm -rf /tmp/guacamole-server-1.6.0* && \
    apt-get remove -y build-essential autoconf automake pkg-config libtool && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Extract Guacamole web client JavaScript libraries
RUN mkdir -p /usr/share/guacamole/guacamole-common-js && \
    cd /tmp && \
    wget -q https://archive.apache.org/dist/guacamole/1.6.0/binary/guacamole-1.6.0.war && \
    unzip -q guacamole-1.6.0.war guacamole-common-js/* && \
    cp -r guacamole-common-js /usr/share/guacamole/ && \
    rm -rf /tmp/guacamole-1.6.0.war /tmp/guacamole-common-js

# Remove NoVNC 
RUN rm -rf /usr/share/novnc

COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /run/assets

# Copy custom nginx config for Guacamole
COPY --chmod=644 ./src/web.conf /etc/nginx/sites-enabled/web.conf

# Copy Guacamole HTML client
COPY --chmod=644 ./src/index.html /usr/share/guacamole/index.html

ADD --chmod=755 https://raw.githubusercontent.com/christgau/wsdd/refs/tags/v0.9/src/wsdd.py /usr/sbin/wsdd
ADD --chmod=664 https://github.com/qemus/virtiso-whql/releases/download/v1.9.47-0/virtio-win-1.9.47.tar.xz /var/drivers.txz

FROM dockurr/windows-arm:${VERSION_ARG} AS build-arm64
FROM build-${TARGETARCH}

ARG VERSION_ARG="0.00"
RUN echo "$VERSION_ARG" > /run/version

VOLUME /storage
EXPOSE 3389 8006

ENV VERSION="11"
ENV RAM_SIZE="4G"
ENV CPU_CORES="2"
ENV DISK_SIZE="64G"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
