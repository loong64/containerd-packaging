#!/bin/bash
#
CONTAINERD_VERSION=v1.6.32

################################################################
# REF: v1.6.32
#
REF=${CONTAINERD_VERSION}

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/containerd-packaging "${TMPDIR}"
cp container.patch "${TMPDIR}"

pushd "${TMPDIR}" || exit 1

################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
sed -i '/syntax=docker/d' dockerfiles/deb.dockerfile
sed -i 's@FROM ${GOLANG_IMAGE}@FROM ghcr.io/loong64/${GOLANG_IMAGE}@g' dockerfiles/deb.dockerfile

################################################################
# See. https://github.com/containerd/containerd
# libcontainer/system/syscall_linux_64.go not support linux/loong64
# vendor/github.com/cilium/ebpf not support linux/loong64
#
git apply container.patch || exit 1

make REF=${REF} BUILD_IMAGE=ghcr.io/loong64/debian:trixie-slim

popd || exit 1

mkdir -p dist
mv ${TMPDIR}/build/debian/trixie/loongarch64/* dist/

rm -rf "${TMPDIR:?}"