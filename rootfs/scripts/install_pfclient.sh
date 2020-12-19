#!/usr/bin/env bash
#shellcheck shell=bash

set -x

# Get arch
# Make sure `file` (libmagic) is available
FILEBINARY=$(which file)
if [ -z "$FILEBINARY" ]; then
  echo "ERROR: 'file' (libmagic) not available, cannot detect architecture!"
  exit 1
fi
FILEOUTPUT=$("${FILEBINARY}" -L "${FILEBINARY}")

# 32-bit x86
# Example output:
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386.so.1, stripped
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=d48e1d621e9b833b5d33ede3b4673535df181fe0, stripped  
if echo "${FILEOUTPUT}" | grep "Intel 80386" > /dev/null; then
  PFCLIENTURL="http://client.planefinder.net/pfclient_4.1.1_i386.deb"
fi

# x86-64
# Example output:
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, stripped
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=6b0b86f64e36f977d088b3e7046f70a586dd60e7, stripped
if echo "${FILEOUTPUT}" | grep "x86-64" > /dev/null; then
  PFCLIENTURL="http://client.planefinder.net/pfclient_4.1.1_i386.deb"
fi

# armel
# /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=f57b617d0d6cd9d483dcf847b03614809e5cd8a9, stripped
if echo "${FILEOUTPUT}" | grep "ARM" > /dev/null; then

  # armhf
  # Example outputs:
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-armhf.so.1, stripped  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  if echo "${FILEOUTPUT}" | grep "armhf" > /dev/null; then
    PFCLIENTURL="http://client.planefinder.net/pfclient_4.1.1_armhf.deb"
  fi

  # arm64
  # Example output:
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, BuildID[sha1]=a8d6092fd49d8ec9e367ac9d451b3f55c7ae7a78, stripped
  if echo "${FILEOUTPUT}" | grep "aarch64" > /dev/null; then
    PFCLIENTURL="http://client.planefinder.net/pfclient_4.1.1_armhf.deb"    
  fi

fi

# If we don't have an architecture at this point, there's been a problem and we can't continue
if [ -z "${PFCLIENTURL}" ]; then
  echo "ERROR: Unable to determine architecture or unsupported architecture!"
  exit 1
fi

# Get link to pfclient download
USERAGENT='Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:81.0) Gecko/20100101 Firefox/81.0'
# curl -c /tmp/cookiejar -A "$USERAGENT" --location "https://planefinder.net/" > /dev/null 2>&1
# PFCLIENTURL=$(curl --location -b /tmp/cookiejar -A "$USERAGENT" "https://planefinder.net/coverage/client" | grep -oE "$PFCLIENTREGEX")
echo "pfclient download URL is: ${PFCLIENTURL}"

# Download pfclient
curl -A "$USERAGENT" -o /tmp/pfclient.deb "${PFCLIENTURL}" 

# Install pfclient
dpkg --install /tmp/pfclient.deb

# Kill running pfclient
kill -9 "$(cat /run/pfclient.pid)"
rm /run/pfclient.pid
