FROM debian:bullseye

RUN apt update && \
  apt install -y bash curl git vim openssh-client python3 python3-pip \
  build-essential unzip && \
  apt clean

WORKDIR /workspace
