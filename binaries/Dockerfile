FROM ghcr.io/loong64/golang:1.21-trixie AS builder

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

ARG CONTAINERD_VERSION=v1.7.22

ENV CONTAINERD_VERSION=${CONTAINERD_VERSION}

ARG WORKDIR=/opt/containerd

RUN set -ex; \
    git clone -b ${CONTAINERD_VERSION} --depth=1 https://github.com/containerd/containerd ${WORKDIR}

ADD *.patch /opt/

WORKDIR ${WORKDIR}

RUN set -ex; \
    sed -i 's@|| riscv64@|| riscv64 || loong64@g' vendor/github.com/cilium/ebpf/internal/endian_le.go; \
    sed -i 's@ppc64le riscv64@ppc64le riscv64 loong64@g' vendor/github.com/cilium/ebpf/internal/endian_le.go; \
    sed -i "s@--dirty='.m' @@g" Makefile; \
    sed -i 's@$(shell if ! git diff --no-ext-diff --quiet --exit-code; then echo .m; fi)@@g' Makefile; \
    git apply /opt/*.patch; \
    go mod tidy

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