FROM ghcr.io/sdr-enthusiasts/docker-baseimage:qemu

ENV BEASTPORT=30005 \
  S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086,SC2039,SC2068
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
  #KEPT_PACKAGES+=(lsb-base:armhf) && \
  # pfclient install & healthchecks
  KEPT_PACKAGES+=(curl) && \
  # Install packages
  apt-get update && \
  apt-get install -y --no-install-recommends \
  ${KEPT_PACKAGES[@]} \
  ${TEMP_PACKAGES[@]} \
  && \
  # Install pfclient
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
  # Clean up
  apt-get remove -y ${TEMP_PACKAGES[@]} && \
  apt-get autoremove -y && \
  apt-get clean -y && \
  rm -rf /var/lib/apt/lists/* /src /tmp/* && \
  # Document version
  if /usr/local/bin/pfclient --version > /dev/null 2>&1; \
  then echo "pfclient $(/usr/local/bin/pfclient --version | head -1 | rev | cut -d " " -f 1 | rev)" >> /VERSION; \
  else echo "pfclient $(qemu-arm-static /usr/local/bin/pfclient --version | head -1 | rev | cut -d " " -f 1 | rev)" >> /VERSION; \
  fi \
  && \
  grep 'pfclient' /VERSION | cut -d ' ' -f2- > /CONTAINER_VERSION && \
  cat /CONTAINER_VERSION

EXPOSE 30053/tcp 30054/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
