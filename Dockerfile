FROM python:3.7-slim-buster as base
FROM base as builder

RUN sed -i '/messagebus /d' /var/lib/dpkg/statoverride && \
    apt-get update && apt-get install -y \
    curl \
    g++ \
    wget \
    unixodbc-dev \
    build-essential \
    cmake \
    git \
    openssh-client \
    libenchant1c2a \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list

# install SQL Server tools
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17

COPY requirements.txt /app/python/requirements.txt
COPY install-pyrequirements.sh .
RUN /install-pyrequirements.sh

RUN git clone git://git.samba.org/nss_wrapper.git /tmp/nss_wrapper && \
    mkdir /tmp/nss_wrapper/build && \
    cd /tmp/nss_wrapper/build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local/lib64 .. && \
    make && \
    make install && \
    rm -rf /tmp/nss_wrapper


FROM base
COPY --from=builder /usr/local/lib64/lib /usr/local/lib
COPY --from=builder /usr/local/lib/python3.7/site-packages /usr/local/lib/python3.7/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/bin/ /usr/bin
COPY --from=builder /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu
COPY --from=builder /usr/share /usr/share
COPY --from=builder /opt /opt


COPY install-packages.sh .
RUN /install-packages.sh

ADD spark-defaults.conf /usr/local/lib/python3.7/site-packages/pyspark/conf/spark-defaults.conf
  
ENV USER_NAME=root \
    NSS_WRAPPER_PASSWD=/tmp/passwd \
    NSS_WRAPPER_GROUP=/tmp/group \
    PATH=/usr/lib/jvm/java-8-openjdk-amd64/bin:${PATH} \
    HOME=/tmp \
    SPARK_HOME=/usr/local/lib/python3.7/site-packages/pyspark \
    PYTHONPATH=/usr/local/lib/python3.7/site-packages

RUN chgrp -R 0 /tmp/ && \
    chmod -R g=u /tmp/  && \
    chgrp -R 0  /usr/local/ && \
    chmod -R g=u  /usr/local/


RUN for path in "$NSS_WRAPPER_PASSWD" "$NSS_WRAPPER_GROUP"; do \
  touch $path && chmod 666 $path ; done

COPY nss-wrap.sh /nss-wrap.sh

RUN chmod +rwx /etc/ssl/openssl.cnf && \
    sed -i 's/TLSv1.2/TLSv1/g' /etc/ssl/openssl.cnf && \
    sed -i 's/SECLEVEL=2/SECLEVEL=1/g' /etc/ssl/openssl.cnf

ENTRYPOINT ["/nss-wrap.sh"]
