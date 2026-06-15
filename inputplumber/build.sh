#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"; REPO=$PWD
source ./BASE.env

mkdir -p out; rm -f out/*
podman run --rm -e COMMIT="${COMMIT}" -e VERSION="${VERSION}" -v "${REPO}:/work:Z" -w /work --platform linux/aarch64 fedora:44 bash -euxc '
    export HOME=/tmp
    dnf -y install rpm-build rpmdevtools spectool "dnf-command(builddep)" git-core
    rpmdev-setuptree
    cat >/etc/rpm/macros.armada <<EOF
%_buildhost armada-builder
%packager Armada
%vendor Armada
EOF
    cp /work/inputplumber.spec ~/rpmbuild/SPECS/
    sed -i "s/^Version:.*/Version:        ${VERSION}/" ~/rpmbuild/SPECS/inputplumber.spec
    cp /work/patches/*.patch ~/rpmbuild/SOURCES/
    spectool -g -R --define "commit ${COMMIT}" ~/rpmbuild/SPECS/inputplumber.spec
    dnf -y builddep --define "commit ${COMMIT}" ~/rpmbuild/SPECS/inputplumber.spec
    rpmbuild -bb --define "commit ${COMMIT}" ~/rpmbuild/SPECS/inputplumber.spec
    cp ~/rpmbuild/RPMS/*/inputplumber-[0-9]*.armada.*.rpm /work/out/
'
