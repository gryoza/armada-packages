#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"; REPO=$PWD
source ./BASE.env

mkdir -p out; rm -f out/*
podman run --rm -e SRPM="${SRPM}" -v "${REPO}:/work:Z" -w /work --platform linux/aarch64 fedora:44 bash -euxc '
    export HOME=/tmp
    dnf -y install rpm-build rpmdevtools koji "dnf-command(builddep)"
    rpmdev-setuptree
    cat >/etc/rpm/macros.armada <<EOF
%_buildhost armada-builder
%packager Armada
%vendor Armada
EOF
    cd /tmp
    koji download-build --arch=src "${SRPM}"
    rpm -i "${SRPM}.src.rpm"
    SPEC=$HOME/rpmbuild/SPECS/mangohud.spec
    cp /work/patches/0001-Qualcomm-GPU-support.patch /work/patches/0002-SM8550-GPU.patch $HOME/rpmbuild/SOURCES/
    # inject patches after stock %prep unpacks rc1 + subprojects (fuzz: rc1 offsets)
    sed -i "/-D -T -a6/a patch -p1 --fuzz=5 < %{_sourcedir}/0001-Qualcomm-GPU-support.patch\npatch -p1 --fuzz=5 < %{_sourcedir}/0002-SM8550-GPU.patch" "$SPEC"
    REL="${SRPM##*-}"   # release from the pinned NVR (e.g. 2.fc44)
    sed -i "s/^Release:.*%autorelease.*/Release:        ${REL}.armada/" "$SPEC"
    sed -i "/^%autochangelog/d" "$SPEC"
    grep -n "fuzz=5" "$SPEC" || { echo "patch injection failed"; exit 1; }
    dnf -y builddep "$SPEC"
    rpmbuild -bb "$SPEC"
    cp $HOME/rpmbuild/RPMS/*/mangohud-[0-9]*.armada.*.rpm /work/out/
'
