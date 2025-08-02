#!/bin/bash

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

SHARUN="https://github.com/VHSgunzo/sharun/releases/latest/download/sharun-${ARCH}-aio"

BUILD_DIR=$(realpath "$1")
APPDIR="${BUILD_DIR}/mesa/AppDir"

cd "${BUILD_DIR}"
sudo ninja install

mkdir -p "${APPDIR}"
cd "${APPDIR}"

cp -v /usr/share/applications/org.eden_emu.eden.desktop ./eden.desktop
cp -v /usr/share/icons/hicolor/scalable/apps/org.eden_emu.eden.svg ./eden.svg
ln -sfv ./eden.svg ./.DirIcon

wget --retry-connrefused --tries=30 "$SHARUN" -O ./sharun-aio
chmod +x ./sharun-aio
xvfb-run -a ./sharun-aio l -p -v -e -s -k \
    /usr/bin/eden \
    /usr/lib/lib*GL*.so* \
    /usr/lib/dri/* \
    /usr/lib/vdpau/* \
    /usr/lib/libvulkan* \
    /usr/lib/libXss.so* \
    /usr/lib/libdecor-0.so* \
    /usr/lib/libgamemode.so* \
    /usr/lib/qt6/plugins/imageformats/* \
    /usr/lib/qt6/plugins/iconengines/* \
    /usr/lib/qt6/plugins/platforms/* \
    /usr/lib/qt6/plugins/platformthemes/* \
    /usr/lib/qt6/plugins/platforminputcontexts/* \
    /usr/lib/qt6/plugins/styles/* \
    /usr/lib/qt6/plugins/xcbglintegrations/* \
    /usr/lib/qt6/plugins/wayland-*/* \
    /usr/lib/pulseaudio/* \
    /usr/lib/pipewire-0.3/* \
    /usr/lib/spa-0.2/*/* \
    /usr/lib/alsa-lib/*

rm -f ./sharun-aio

if [ "$ARCH" = 'aarch64' ]; then
	# allow the host vulkan to be used for aarch64 given the sad situation
	echo 'SHARUN_ALLOW_SYS_VKICD=1' > ./.env
fi

ln -fv ./sharun ./AppRun
./sharun -g
