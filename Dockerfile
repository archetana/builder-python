FROM python:3.7-slim-buster as base
FROM base as builder

RUN sed -i '/messagebus /d' /var/lib/dpkg/statoverride && \
    apt-get update && apt-get install -y \
    jq \
    curl \
    g++ \
    wget \
    unixodbc-dev \
    build-essential \
    cmake \
    git \
    openssh-client \
    libenchant1c2a \
    && rm -rf /var/lib/apt/lists/* &&\
    curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list && \
    curl https://baltocdn.com/helm/signing.asc | apt-key add - && \
    echo "deb https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list && \
    apt-get update &&  apt-get install -y kubectl helm

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

COPY install-packages.sh .
RUN /install-packages.sh

ADD spark-defaults.conf /usr/local/lib/python3.7/site-packages/pyspark/conf/spark-defaults.conf
  
ENV USER_NAME=root \
    PATH=/usr/lib/jvm/java-8-openjdk-amd64/bin:${PATH} \
    HOME=/tmp \
    SPARK_HOME=/usr/local/lib/python3.7/site-packages/pyspark \
    PYTHONPATH=/usr/local/lib/python3.7/site-packages

RUN chmod +rwx /etc/ssl/openssl.cnf && \
    sed -i 's/TLSv1.2/TLSv1/g' /etc/ssl/openssl.cnf && \
    sed -i 's/SECLEVEL=2/SECLEVEL=1/g' /etc/ssl/openssl.cnf
