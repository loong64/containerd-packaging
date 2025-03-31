#!/bin/bash
#
CONTAINERD_VERSION=v1.7.27

BUILD_DEB=0
BUILD_RPM=0

while [[ $# > 0 ]]; do
    lowerI="$(echo $1 | awk '{print tolower($0)}')"
    case $lowerI in
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Global Options:"
            echo -e "  -h, --help  \t Show this help message and exit"
            echo -e "  --deb  \t Build Debian-trixie deb package"
            echo -e "  --rpm  \t Build OpenCloudOS-23 rpm package"
            exit 0
            ;;
        --deb)
            BUILD_DEB=1
            shift
            ;;
        --rpm)
            BUILD_RPM=1
            shift
            ;;
        *)
            echo "install: Unknown option $1"
            echo "eg: $0 --deb --rpm"
            exit 1
            ;;
    esac
    shift
done

################################################################
# REF: v2.0.0
#
REF=${CONTAINERD_VERSION}

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/containerd-packaging "${TMPDIR}"

cp -f containerd.patch /tmp/containerd.patch
cp -f opencloudos-23/Dockerfile "${TMPDIR}/dockerfiles/rpm.dockerfile"

pushd "${TMPDIR}" || exit 1
################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
# sed -i '/syntax=docker/d' dockerfiles/deb.dockerfile
sed -i 's@GOLANG_IMAGE=golang@GOLANG_IMAGE=ghcr.io/loong64/golang@g' common/common.mk
sed -i 's@ARCH=$(shell uname -m)@ARCH=loong64@g' Makefile

################################################################
# See. https://github.com/opencontainers/runc
# libcontainer/seccomp/patchbpf/enosys_linux.go not support linux/loong64
# vendor/github.com/seccomp/libseccomp-golang/seccomp_internal.go not support linux/loong64
#
# See. https://github.com/containerd/containerd
# libcontainer/system/syscall_linux_64.go not support linux/loong64
# vendor/github.com/cilium/ebpf not support linux/loong64
#

git apply /tmp/containerd.patch || exit 1

if [ "${BUILD_DEB}" = '1' ]; then
    make REF=${REF} BUILD_IMAGE=ghcr.io/loong64/debian:trixie-slim
fi
if [ "${BUILD_RPM}" = '1' ]; then
    make REF=${REF} BUILD_IMAGE=ghcr.io/loong64/opencloudos:23
fi

popd || exit 1

mkdir -p dist
if [ "${BUILD_DEB}" = '1' ]; then
    mv ${TMPDIR}/build/debian/trixie/loong64/* dist/
fi
if [ "${BUILD_RPM}" = '1' ]; then
    mv ${TMPDIR}/build/opencloudos/23/loongarch64/* dist/
fi

rm -rf "${TMPDIR:?}"