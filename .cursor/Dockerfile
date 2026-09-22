FROM ubuntu:24.04

ARG DART_VERSION=2.19.6

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/dartsdk.zip \
        "https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-linux-x64-release.zip" \
    && unzip -q /tmp/dartsdk.zip -d /usr/lib \
    && rm /tmp/dartsdk.zip

ENV PATH="/usr/lib/dart-sdk/bin:${PATH}"
ENV PUB_CACHE="/home/ubuntu/.pub-cache"

USER ubuntu
