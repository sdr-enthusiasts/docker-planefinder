FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

ARG TARGETPLATFORM TARGETOS TARGETARCH

ENV BEASTPORT=30005 \
  S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086,SC2039,SC2068
RUN set -x && \
  TEMP_PACKAGES=() && \
  KEPT_PACKAGES=() && \
  # Deps for healthchecks
  KEPT_PACKAGES+=(jq) && \
  KEPT_PACKAGES+=(net-tools) && \
  KEPT_PACKAGES+=(procps) && \
  # Deps for pfclient
  KEPT_PACKAGES+=(ca-certificates) && \
  if [[ "${TARGETARCH}" == "arm64" ]]; then \
  DOWNLOAD_URL="http://client.planefinder.net/pfclient_5.3.29_arm64.tar.gz"; \
  DOWNLOAD_MD5SUM=d8b5e7cf6d6d2fbde74dc560b8666f4e; \
  elif [[ "${TARGETARCH}" == "amd64" ]]; then \
  DOWNLOAD_URL="http://client.planefinder.net/pfclient_5.3.29_amd64.tar.gz"; \
  DOWNLOAD_MD5SUM=b655a6479625d6fb08763abc11fc76da; \
  else \
  DOWNLOAD_URL="http://client.planefinder.net/pfclient_5.3.29_armhf.tar.gz"; \
  DOWNLOAD_MD5SUM=0949c252cb24d423f53b0203f47d5389; \
  fi && \
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
  "${DOWNLOAD_URL}" \
  && \
  # Check md5sum
  md5sum /tmp/pfclient.tar.gz && \
  echo "${DOWNLOAD_MD5SUM}  /tmp/pfclient.tar.gz" > /tmp/pfclient.md5sum && \
  echo md5sum /tmp/pfclient.tar.gz && \
  md5sum --check /tmp/pfclient.md5sum && \
  # Extract pfclient
  tar \
  xvf "/tmp/pfclient.tar.gz" \
  -C /usr/local/bin/ \
  && \
  # Clean up
  apt-get remove -y ${TEMP_PACKAGES[@]} && \
  apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y && \
  apt-get clean -y && \
  rm -rf /src /tmp/* /var/lib/apt/lists/* /git /var/cache/* && \
  # Document version and make sure the binary can be loaded with the linked libraries
  pfclient --version && \
  echo "pfclient $(/usr/local/bin/pfclient --version | head -1 | rev | cut -d " " -f 1 | rev)" >> /VERSION && \
  grep 'pfclient' /VERSION | cut -d ' ' -f2- > /CONTAINER_VERSION && \
  cat /CONTAINER_VERSION

EXPOSE 30053/tcp 30054/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
