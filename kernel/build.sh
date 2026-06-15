#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"
if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y build-essential bc bison flex libssl-dev libelf-dev zstd
fi
source ./BASE.env
KERNEL_VERSION="$VERSION" exec ./scripts/build-kernel.sh
