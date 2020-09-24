FROM python:3.7-slim-buster as base
FROM base as builder

apt-get update && \
apt-get install g++ unixodbc-dev build-essential cmake git

COPY requirements.txt /app/python/requirements.txt
COPY install-pyrequirements.sh .
RUN ./install-pyrequirements.sh

FROM base
COPY --from=builder /root/.local /root/.local

COPY install-packages.sh .
RUN ./install-packages.sh

ENV PATH="/usr/lib/jvm/java-8-openjdk-amd64/bin:${PATH}"
WORKDIR /app
