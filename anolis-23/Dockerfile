# syntax=docker/dockerfile:1


#   Copyright 2018-2022 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ARG BUILD_IMAGE=ghcr.io/loong64/anolis:23
ARG GOLANG_IMAGE=ghcr.io/loong64/golang:latest

# Install golang from the official image, since the package managed
# one probably is too old and ppa's don't cover all distros
FROM ${GOLANG_IMAGE} AS golang

FROM golang AS go-md2man
ARG GOPROXY=direct
ARG MD2MAN_VERSION=v2.0.5
RUN go install github.com/cpuguy83/go-md2man/v2@${MD2MAN_VERSION}

FROM ${BUILD_IMAGE} AS distro-image
RUN dnf install -y rpm-build git dnf-plugins-core

FROM distro-image AS build-env
RUN mkdir -p /go
ENV GOPATH=/go
ENV GOTOOLCHAIN=local
ENV PATH="${PATH}:/usr/local/go/bin:${GOPATH}/bin"
ENV IMPORT_PATH=github.com/containerd/containerd
ENV GO_SRC_PATH="/go/src/${IMPORT_PATH}"
ENV CC=gcc
WORKDIR /root/rpmbuild

# Install build dependencies and build scripts
COPY --link --from=go-md2man /go/bin/go-md2man /go/bin/go-md2man
COPY --link rpm/containerd.spec SPECS/containerd.spec
COPY --link scripts/build-rpm    /root/
COPY --link scripts/.rpm-helpers /root/
RUN . /root/.rpm-helpers; install_build_deps SPECS/containerd.spec

ARG PACKAGE
ENV PACKAGE=${PACKAGE:-containerd.io}

FROM build-env AS build-packages
RUN mkdir -p /archive /build
COPY common/containerd.service common/containerd.toml SOURCES/
ARG CREATE_ARCHIVE
# NOTE: not using a cache-mount for /root/.cache/go-build, to prevent issues
#       with CGO when building multiple distros on the same machine / build-cache
RUN --mount=type=bind,from=golang,source=/usr/local/go/,target=/usr/local/go/ \
    --mount=type=bind,source=/src,target=/go/src,rw \
    --mount=type=bind,source=/src/github.com/containerd/containerd,target=/root/rpmbuild/SOURCES/containerd \
    --mount=type=bind,source=/src/github.com/opencontainers/runc,target=/root/rpmbuild/SOURCES/runc \
    /root/build-rpm
ARG UID=0
ARG GID=0
RUN chown -R ${UID}:${GID} /archive /build

# Verify that installing the package succeeds succesfully, and if we're able
# to run both containerd and runc. This is just a rudimentary check to make
# sure that package dependencies are installed and that the binaries are not
# completely defunct.
#
# For rpms, installing packages with 'rpm -ivh my-local-package.rpm' or
# 'yum --nogpgcheck localinstall packagename.arch.rpm' does not perform
# dependency resolution, so we need to setup a local repository to verify the
# installation (including dependencies).
#
# NOTE: Installation of source-packages is not currently tested here.
FROM distro-image AS verify-packages
COPY scripts/.rpm-helpers /root/
# On OpenSUSE/SLES, the package is now named `createrepo_c`
RUN . /root/.rpm-helpers; if [ -d "/etc/zypp/repos.d/" ]; then install_package createrepo_c; else install_package createrepo; fi
RUN if [ -d "/etc/zypp/repos.d/" ]; then ln -s "/etc/zypp/repos.d" "/etc/yum.repos.d"; fi \
 && echo -e "[local]\nname=Test Repo\nbaseurl=file:///build/\nenabled=1\ngpgcheck=0" >  "/etc/yum.repos.d/local.repo"
COPY --from=build-packages /build/. /build/
RUN createrepo /build \
 && . /root/.rpm-helpers \
 && install_package containerd.io \
 && rm -rf /build/repodata
RUN containerd --version
RUN ctr --version
RUN runc --version

FROM scratch AS packages
COPY --link --from=build-packages  /archive /archive
COPY --link --from=verify-packages /build   /build

# This stage is mainly for debugging (running the build interactively with mounted source)
FROM build-env AS runtime
ENV GOTOOLCHAIN=local
COPY --link --from=golang /usr/local/go/ /usr/local/go/
COPY --link common/containerd.service common/containerd.toml SOURCES/