ARG GOLANG_VERSION=1.23

FROM ghcr.io/loong64/golang:${GOLANG_VERSION}-trixie AS builder

ARG DEPENDENCIES="\
    dpkg-dev \
    git \
    make \
    pkg-config\
    libseccomp-dev \
    gcc"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' >/etc/apt/apt.conf.d/keep-cache \
    && apt-get update \
    && apt-get install -y ${DEPENDENCIES}

ARG CONTAINERD_VERSION=v1.7.25

ENV CONTAINERD_VERSION=${CONTAINERD_VERSION}

ARG WORKDIR=/opt/containerd

RUN set -ex \
    && git clone -b ${CONTAINERD_VERSION} --depth=1 https://github.com/containerd/containerd ${WORKDIR}

ADD *.patch /opt/

WORKDIR ${WORKDIR}

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -ex \
    && \
    if echo ${CONTAINERD_VERSION} | grep -q "v1"; then \
        sed -i 's@|| riscv64@|| riscv64 || loong64@g' vendor/github.com/cilium/ebpf/internal/endian_le.go; \
        sed -i 's@ppc64le riscv64@ppc64le riscv64 loong64@g' vendor/github.com/cilium/ebpf/internal/endian_le.go; \
        git apply /opt/install-imgcrypt.patch; \
    fi \
    && git apply /opt/install-runc.patch \
    && sed -i "s@--dirty='.m' @@g" Makefile \
    && sed -i 's@$(shell if ! git diff --no-ext-diff --quiet --exit-code; then echo .m; fi)@@g' Makefile \
    && go mod tidy

RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    set -ex \
    && make release static-release cri-release cri-cni-release \
    && mkdir dist \
    && cp -f releases/containerd-* dist/ \
    && cp -f releases/cri-containerd-* dist/

FROM ghcr.io/loong64/debian:trixie-slim

WORKDIR /opt/containerd

COPY --from=builder /opt/containerd/dist /opt/containerd/dist

VOLUME /dist

CMD cp -rf dist/* /dist/