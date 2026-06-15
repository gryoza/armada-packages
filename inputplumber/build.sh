#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"; REPO=$PWD
source ./BASE.env

mkdir -p out; rm -f out/*
podman run --rm -v "${REPO}:/work:Z" -w /work --platform linux/aarch64 fedora:44 bash -euxc '
    dnf -y install git cargo rust clang clang-devel lld make cmake pkgconf-pkg-config \
        systemd-devel libevdev-devel libiio-devel openssl-devel dbus-devel
    git clone https://github.com/ShadowBlip/InputPlumber /tmp/ip
    git -C /tmp/ip checkout '"${COMMIT}"'
    for p in /work/patches/*.patch; do git -C /tmp/ip apply "$p"; done
    ( cd /tmp/ip && cargo build --release )
    cp /tmp/ip/target/release/inputplumber /work/out/
'
