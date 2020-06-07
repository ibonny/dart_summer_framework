FROM debian:stretch

RUN apt-get update && apt-get -y install git curl unzip

RUN apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /home/gitpod

RUN cd /home/gitpod && \
    curl -O https://storage.googleapis.com/dart-archive/channels/beta/release/2.9.0-8.2.beta/sdk/dartsdk-linux-x64-release.zip && \
    unzip dartsdk-linux-x64-release.zip

WORKDIR /home/gitpod

ENV PUB_CACHE=/home/gitpod/.pub_cache
ENV PATH="/home/gitpod/dartksdk/bin:/home/gitpod/flutter/bin:$PATH"

RUN curl -O https://storage.googleapis.com/dart-archive/channels/stable/release/2.8.4/sdk/dartsdk-linux-x64-release.zip && \
    unzip -o dartsdk-linux-x64-release.zip
