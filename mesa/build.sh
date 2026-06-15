#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"; REPO=$PWD

source ./BASE.env
SRPM_NVR="$SRPM"
MESA_VER="${SRPM_NVR#mesa-}"; MESA_VER="${MESA_VER%%-*}"
# Rawhide SRPM (BASE.env pins the fcNN) rebuilt on fedora:44 for the runtime ABI.
DIST=".fc44.armada"
SUBPKGS="mesa-filesystem mesa-libgbm mesa-dri-drivers mesa-vulkan-drivers mesa-libGL mesa-libEGL"

# ccache: CI persists CCACHE_DIR; default to a repo-local dir for dev builds
CCACHE_DIR="${CCACHE_DIR:-${REPO}/.ccache}"; mkdir -p "${CCACHE_DIR}"

mkdir -p out; rm -f out/*
podman run --rm \
    -v "${REPO}:/work:Z" -w /work \
    -v "${CCACHE_DIR}:/ccache:Z" \
    -e CCACHE_DIR=/ccache -e CCACHE_MAXSIZE=2G \
    --platform linux/aarch64 \
    fedora:44 bash -euxc "
        export HOME=/tmp
        dnf -y install rpm-build rpmdevtools koji 'dnf-command(builddep)' ccache
        export PATH=/usr/lib64/ccache:\$PATH CC=gcc CXX=g++
        ccache -z
        rpmdev-setuptree
        cat >/etc/rpm/macros.armada <<EOF
%_buildhost armada-builder
%packager Armada
%vendor Armada
EOF
        cd /tmp
        koji download-build --arch=src ${SRPM_NVR}
        rpm -i ${SRPM_NVR}.src.rpm
        SPEC=\$HOME/rpmbuild/SPECS/mesa.spec

        sed -i 's/^Release:.*%autorelease.*/Release:        1%{?dist}/' \"\$SPEC\"
        sed -i '/^%autochangelog/d' \"\$SPEC\"

        LAST=\$(grep -nE '^(Patch|Source)[0-9]*:' \"\$SPEC\" | tail -1 | cut -d: -f1)
        [ -n \"\$LAST\" ] || { echo 'ERROR: no Source/Patch line to anchor the patch on'; exit 1; }
        cp /work/patches/0001-fix-freedreno-vulkan.patch \$HOME/rpmbuild/SOURCES/
        sed -i \"\${LAST}a Patch9001:       0001-fix-freedreno-vulkan.patch\" \"\$SPEC\"
        cp /work/patches/0002-add-a830-chip-id.patch \$HOME/rpmbuild/SOURCES/
        sed -i \"/^Patch9001:/a Patch9002:       0002-add-a830-chip-id.patch\" \"\$SPEC\"

        # two-pass: %generate_buildrequires emits a nosrc; install its BRs then build for real
        dnf -y builddep \"\$SPEC\"
        rpmbuild -bb --define \"dist ${DIST}\" \"\$SPEC\" || true
        NOSRC=\$(ls \$HOME/rpmbuild/SRPMS/mesa-${MESA_VER}-*${DIST}.buildreqs.nosrc.rpm 2>/dev/null | head -1)
        [ -n \"\$NOSRC\" ] && dnf -y builddep \"\$NOSRC\"
        rpmbuild -bb --define \"dist ${DIST}\" \"\$SPEC\"
        ccache -s

        for p in ${SUBPKGS}; do
            cp \$HOME/rpmbuild/RPMS/*/\${p}-${MESA_VER}-*${DIST}.*.rpm /work/out/
        done
    "
