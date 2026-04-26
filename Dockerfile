# syntax=docker/dockerfile:1

ARG VERSION_ARG="latest"
FROM scratch AS build-amd64

COPY --from=qemux/qemu:7.29 / /

ARG TARGETARCH
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

RUN set -eu && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
        dos2unix \
        curl \
        unzip \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 ./src /run/

ARG VERSION_ARG="0.00"
RUN echo "$VERSION_ARG" > /run/version

VOLUME /storage
EXPOSE 8006 5555 5900

ENV VERSION="11"
ENV RAM_SIZE="4G"
ENV CPU_CORES="2"
ENV DISK_SIZE="16G"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
