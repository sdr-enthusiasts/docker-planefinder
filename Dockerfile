FROM debian:stable-slim

ENV BEASTPORT=30005 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    apt-get update && \
    apt-get install --no-install-recommends -y \
        bash \
        bc \
        ca-certificates \
        curl \
        file \
        libc6 \
        lsb-base \
        procps \
        && \
    bash /scripts/install_pfclient.sh && \
    mkdir -p /var/log/pfclient && \
    chown -R nobody /var/log/pfclient && \
    mkdir /config && \
    chown -R nobody /config && \
    rm -rf /config/* /var/log/pfclient/* /etc/pfclient-config.json && \
    touch /run/pfclient.pid && \
    chown nobody /run/pfclient.pid && \
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    echo "pfclient $(pfclient --version | head -1 | rev | cut -d " " -f 1 | rev)" >> /VERSION && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /src /tmp/* && \
    grep 'pfclient' /VERSION | cut -d ' ' -f2- > /CONTAINER_VERSION

ENTRYPOINT [ "/init" ]

EXPOSE 30053/tcp 30054/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s  CMD /scripts/healthcheck.sh
