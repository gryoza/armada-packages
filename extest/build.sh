#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"; REPO=$PWD
source ./BASE.env

mkdir -p out; rm -f out/*
podman run --rm -v "${REPO}:/work:Z" -w /work --platform linux/aarch64 fedora:44 bash -euxc '
    dnf -y install git cargo rust gcc
    git clone https://github.com/Supreeeme/extest /tmp/extest
    git -C /tmp/extest checkout '"${COMMIT}"'
    # upstream forces x86
    rm -f /tmp/extest/.cargo/config.toml
    ( cd /tmp/extest && cargo build --release )
    cp /tmp/extest/target/release/libextest.so /work/out/
'
