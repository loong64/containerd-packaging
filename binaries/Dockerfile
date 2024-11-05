ARG GOLANG_VERSION=1.23

FROM ghcr.io/loong64/golang:${GOLANG_VERSION}-trixie AS builder

ARG DEPENDENCIES="\
    dpkg-dev \
    git \
    git-lfs \
    make \
    pkg-config\
    libbtrfs-dev \
    libseccomp-dev \
    btrfs-progs \
    gcc"

RUN set -ex; \
    apt-get update; \
    apt-get install -y ${DEPENDENCIES}; \
    rm -rf /var/lib/apt/lists/*

ARG CONTAINERD_VERSION=v2.0.0

ENV CONTAINERD_VERSION=${CONTAINERD_VERSION}

ARG WORKDIR=/opt/containerd

RUN set -ex; \
    git clone -b ${CONTAINERD_VERSION} --depth=1 https://github.com/containerd/containerd ${WORKDIR}

WORKDIR ${WORKDIR}

RUN set -ex; \
    make release static-release cri-release cri-cni-release; \
    mkdir dist; \
    cp -f releases/containerd-* dist/; \
    cp -f releases/cri-containerd-* dist/

FROM ghcr.io/loong64/debian:trixie-slim

WORKDIR /opt/containerd

COPY --from=builder /opt/containerd/dist /opt/containerd/dist

VOLUME /dist

CMD cp -rf dist/* /dist/