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
    apt-get install -y elementary-sdk git vala-language-server json-glib-1.0 libsecret-1-dev libsoup2.4-dev libgnutls28-dev && \
    apt-get -y autoremove && \
    apt-get autoclean && \
    ln -s /bin/gpg /usr/local/bin/gpg