#!/bin/bash
#
CONTAINERD_VERSION=v2.0.0

################################################################
# REF: v2.0.0
#
REF=${CONTAINERD_VERSION}

TMPDIR=$(mktemp -d)

git clone --depth=1 https://github.com/docker/containerd-packaging "${TMPDIR}"
pushd "${TMPDIR}" || exit 1

################################################################
# See. https://hub.docker.com/r/docker/dockerfile/tags
# docker.io/docker/dockerfile not support linux/loong64
#
sed -i '/syntax=docker/d' dockerfiles/deb.dockerfile
sed -i 's@ca-certificates@ca-certificates libbtrfs-dev@g' dockerfiles/deb.dockerfile
sed -i 's@GOLANG_IMAGE=golang@GOLANG_IMAGE=ghcr.io/loong64/golang@g' common/common.mk
sed -i 's@ARCH=$(shell uname -m)@ARCH=loong64@g' Makefile

make REF=${REF} BUILD_IMAGE=ghcr.io/loong64/debian:trixie-slim

popd || exit 1

mkdir -p dist
mv ${TMPDIR}/build/debian/trixie/loong64/* dist/

rm -rf "${TMPDIR:?}"