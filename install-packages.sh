#!/bin/bash
set -x #echo on

apt-get update && apt-get install -y --no-install-recommends \
  bzip2 \
  unzip \
  xz-utils &&
  rm -rf /var/lib/apt/lists/*

echo 'deb http://httpredir.debian.org/debian-security stretch/updates main' >/etc/apt/sources.list.d/jessie-backports.list

# Default to UTF-8 file.encoding
export LANG=C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
{ \
    echo '#!/bin/sh'; \
    echo 'set -e'; \
    echo; \
    echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
} > /usr/local/bin/docker-java-home \
&& chmod +x /usr/local/bin/docker-java-home

export JAVA_HOME=/usr/lib/jvm/java-8-openjre-amd64
export JAVA_DEBIAN_VERSION=8u272-b10-0+deb9u1

export CA_CERTIFICATES_JAVA_VERSION=20190405

set -x \
    && apt-get update \
    && apt-get install -y \
        openjdk-8-jre="$JAVA_DEBIAN_VERSION" \
        ca-certificates-java="$CA_CERTIFICATES_JAVA_VERSION" \
    && rm -rf /var/lib/apt/lists/* \
    && [ "$JAVA_HOME" = "$(docker-java-home)" ]

# see CA_CERTIFICATES_JAVA_VERSION notes above
/var/lib/dpkg/info/ca-certificates-java.postinst configure
