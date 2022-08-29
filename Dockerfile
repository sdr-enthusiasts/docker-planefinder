FROM ghcr.io/sdr-enthusiasts/docker-baseimage:qemu

ENV BEASTPORT=30005 \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    dpkg --add-architecture armhf && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Deps for healthchecks
    TEMP_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(jq) && \
    KEPT_PACKAGES+=(net-tools) && \
    KEPT_PACKAGES+=(procps) && \
    # Deps for pfclient
    KEPT_PACKAGES+=(ca-certificates) && \
    KEPT_PACKAGES+=(libc6:armhf) && \
    KEPT_PACKAGES+=(lsb-base:armhf) && \
    # pfclient install & healthchecks
    KEPT_PACKAGES+=(curl) && \
    # Install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ${KEPT_PACKAGES[@]} \
        ${TEMP_PACKAGES[@]} \
        && \
    # Install pfclient for AMD64
    curl \
      --location \
      --output "/tmp/pfclient.tar.gz" \
      "http://client.planefinder.net/pfclient_5.0.162_amd64.tar.gz" \
      && \
    # Check md5sum
    echo "3bb9734b43e665b16a5a9ef4c43bfed3  /tmp/pfclient.tar.gz" > /tmp/pfclient.md5sum && \
    md5sum --check /tmp/pfclient.md5sum && \
    # Extract pfclient
    tar \
      xvf "/tmp/pfclient.tar.gz" \
      -C /usr/local/bin/ \
      && \
    mv /usr/local/bin/pfclient /usr/local/bin/pfclient-amd64 && \
    rm /tmp/pfclient* && \
    # Install pfclient for ARM
    curl \
      --location \
      --output "/tmp/pfclient.tar.gz" \
      "http://client.planefinder.net/pfclient_5.0.161_armhf.tar.gz" \
      && \
    # Check md5sum
    echo "0f1e6b90f292833060020d039b8d2fb1  /tmp/pfclient.tar.gz" > /tmp/pfclient.md5sum && \
    md5sum --check /tmp/pfclient.md5sum && \
    # Extract pfclient
    tar \
      xvf "/tmp/pfclient.tar.gz" \
      -C /usr/local/bin/ \
      && \
    mv /usr/local/bin/pfclient /usr/local/bin/pfclient-armhf && \
    rm /tmp/pfclient* && \
    # Clean up
    apt-get remove -y ${TEMP_PACKAGES[@]} && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /src /tmp/* && \
    # Document version
    if /usr/local/bin/pfclient --version > /dev/null 2>&1; \
        then \ 
          echo "pfclient $(/usr/local/bin/pfclient --version | head -1 | rev | cut -d " " -f 1 | rev)" >> /VERSION; \
          ln -s /usr/local/bin/pfclient-armhf /usr/local/bin/pfclient; \
        else \
          echo "pfclient $(/usr/local/bin/pfclient-amd64 --version | head -1 | rev | cut -d " " -f 1 | rev)" >> /VERSION; \
          ln -s /usr/local/bin/pfclient-amd64 /usr/local/bin/pfclient; \
        fi \
        && \
    grep 'pfclient' /VERSION | cut -d ' ' -f2- > /CONTAINER_VERSION && \
    cat /CONTAINER_VERSION

EXPOSE 30053/tcp 30054/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
