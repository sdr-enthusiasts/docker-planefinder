FROM debian:stable-slim

ENV BEASTPORT=30005 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Deps for healthchecks
    KEPT_PACKAGES+=(bc) && \
    TEMP_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(net-tools) && \
    KEPT_PACKAGES+=(procps) && \
    # Deps for s6-overlay & pfclient install
    TEMP_PACKAGES+=(curl) && \
    TEMP_PACKAGES+=(file) && \
    TEMP_PACKAGES+=(gnupg) && \
    # Deps for pfclient
    KEPT_PACKAGES+=(ca-certificates) && \
    KEPT_PACKAGES+=(libc6) && \
    KEPT_PACKAGES+=(lsb-base) && \
    # Install packages.
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    # Install pfclient
    bash /scripts/install_pfclient.sh && \
    rm -rf /config/* /var/log/pfclient/* /etc/pfclient-config.json && \
    # Deploy healthchecks framework
    git clone \
      --depth=1 \
      https://github.com/mikenye/docker-healthchecks-framework.git \
      /opt/healthchecks-framework \
      && \
    rm -rf \
      /opt/healthchecks-framework/.git* \
      /opt/healthchecks-framework/*.md \
      /opt/healthchecks-framework/tests \
      && \
    # Deploy s6-overlay
    curl -s https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh && \
    # Clean up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /src /tmp/* && \
    # Container version
    echo "pfclient $(pfclient --version | head -1 | rev | cut -d " " -f 1 | rev)" >> /VERSION && \
    grep 'pfclient' /VERSION | cut -d ' ' -f2- > /CONTAINER_VERSION

ENTRYPOINT [ "/init" ]

EXPOSE 30053/tcp 30054/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s  CMD /scripts/healthcheck.sh
