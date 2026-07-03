#!/bin/bash
set -euxo pipefail
cd "$(dirname "$0")"; REPO=$PWD
source ./BASE.env
source ../toolchain.env

mkdir -p out; rm -f out/*
podman run --rm -e VERSION="${VERSION}" -e ARMADA_MARCH="${ARMADA_MARCH}" -v "${REPO}:/work:Z" -w /work --platform linux/aarch64 "${BUILDER_IMAGE}" bash -euxc '
    dnf -y install --skip-unavailable \
        rpm-build rpmdevtools dnf-plugins-core spectool catch-devel \
        cmake gcc gcc-c++ git-core meson ninja-build \
        glm-devel google-benchmark-devel libXcursor-devel libXmu-devel \
        hwdata-devel libavif-devel libcap-devel libdecor-devel \
        libdisplay-info-devel libdrm-devel libei-devel libeis-devel libliftoff-devel \
        pipewire-devel systemd-devel luajit-devel openvr-devel \
        SDL2-devel vulkan-loader-devel wayland-protocols-devel \
        wayland-devel wlroots0.18-devel libX11-devel libXcomposite-devel \
        libXdamage-devel libXext-devel libXfixes-devel libxkbcommon-devel \
        libXrender-devel libXres-devel libXtst-devel libXxf86vm-devel \
        spirv-headers-devel stb_image-devel stb_image-static \
        stb_image_resize-devel stb_image_resize-static \
        stb_image_write-devel stb_image_write-static glslang
    rpmdev-setuptree
    cat >/etc/rpm/macros.armada <<EOF
%_buildhost armada-builder
%packager Armada
%vendor Armada
EOF
    cp gamescope.spec ~/rpmbuild/SPECS/
    sed -i "s/^Version:.*/Version:        ${VERSION}/" ~/rpmbuild/SPECS/gamescope.spec
    sed -i "/^%build$/i %global build_cflags %{build_cflags} ${ARMADA_MARCH}" ~/rpmbuild/SPECS/gamescope.spec
    sed -i "/^%build$/i %global build_cxxflags %{build_cxxflags} ${ARMADA_MARCH}" ~/rpmbuild/SPECS/gamescope.spec
    cp patches/*.patch stb.pc ~/rpmbuild/SOURCES/
    spectool -g -R ~/rpmbuild/SPECS/gamescope.spec
    rpmbuild -bb ~/rpmbuild/SPECS/gamescope.spec
    cp ~/rpmbuild/RPMS/aarch64/*.rpm /work/out/
'
