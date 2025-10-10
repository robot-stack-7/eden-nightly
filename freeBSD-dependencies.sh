#!/bin/sh

sed -i '' -e 's/quarterly/latest/' /etc/pkg/FreeBSD.conf

export ASSUME_ALWAYS_YES=true

pkg install autoconf bash boost-libs catch2 ccache cmake enet ffmpeg fusefs-libs \
            gmake git glslang llvm20 libfmt libzip liblz4 lzlib nasm \
            ninja nlohmann-json openssl opus pkgconf qt6-base qt6ct \
            qt6-tools qt6-translations qt6-wayland sdl2 sdl3 unzip vulkan-tools vulkan-loader wget zip zstd
