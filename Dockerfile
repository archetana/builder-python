FROM python:3.7-slim-buster

apt-get update && \
apt-get install g++ unixodbc-dev

COPY install-packages.sh .
RUN ./install-packages.sh

COPY requirements.txt /app/python/requirements.txt
COPY install-pyrequirements.sh .
RUN ./install-pyrequirements.sh

ENV PATH="/usr/lib/jvm/java-8-openjdk-amd64/bin:${PATH}"
WORKDIR /app
