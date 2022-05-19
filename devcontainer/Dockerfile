# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.234.0/containers/ubuntu/.devcontainer/base.Dockerfile

# [Choice] Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): ubuntu-22.04, ubuntu-20.04, ubuntu-18.04
# ARG VARIANT="jammy"
# FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>





# elementary OS Odin STABLE
FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install --no-install-recommends software-properties-common && \
    add-apt-repository -u -y ppa:elementary-os/os-patches && \
    add-apt-repository -u -y ppa:elementary-os/stable && \
    apt-get install -y --no-install-recommends elementary-os-overlay && \
    apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install --no-install-recommends -y elementary-sdk && \
    apt-get install --no-install-recommends -y vala-language-server && \
    apt-get -y autoremove && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/*
