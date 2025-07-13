#!/bin/bash

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1 
export ARCH=$(uname -m)

BUILD_DIR=$(realpath "$1")
APPDIR="${BUILD_DIR}/light/AppDir"

cd "${BUILD_DIR}"

# Install base files to AppDir
DESTDIR="${APPDIR}" ninja install

# Prepare linuxdepoly
curl -fsSLo ./linuxdeploy "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage"
chmod +x ./linuxdeploy
curl -fsSLo ./linuxdeploy-plugin-qt "https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-${ARCH}.AppImage"
chmod +x ./linuxdeploy-plugin-qt
curl -fsSLo ./linuxdeploy-plugin-checkrt.sh https://github.com/darealshinji/linuxdeploy-plugin-checkrt/releases/download/continuous/linuxdeploy-plugin-checkrt.sh
chmod +x ./linuxdeploy-plugin-checkrt.sh

# Setup linuxdeploy environment variables
export QMAKE="/usr/bin/qmake6"
export QT_SELECT=6
export QT_QPA_PLATFORM="wayland;xcb"
export EXTRA_PLATFORM_PLUGINS="libqwayland-egl.so;libqwayland-generic.so;libqxcb.so"
export EXTRA_QT_PLUGINS="svg;wayland-decoration-client;wayland-graphics-integration-client;wayland-shell-integration;waylandcompositor;xcb-gl-integration;platformthemes/libqt6ct.so"

# start to deploy
NO_STRIP=1 ./linuxdeploy --appdir ./light/AppDir --plugin qt --plugin checkrt

# remove libvulkan because it causes issues with gamescope
rm -fv ./light/AppDir/usr/lib/libvulkan.so*

# Bundle libsdl3 to AppDir, needed for steamdeck
cp /usr/lib/libSDL3.so* ./light/AppDir/usr/lib/

# include lsfg-vk
if [ "$ARCH" = "x86_64" ]; then
  (
    cd ./light/AppDir/usr
    wget --retry-connrefused --tries=30 "https://pancake.gay/lsfg-vk/lsfg-vk.zip"
    unzip -o ./lsfg-vk.zip
    rm -f ./lsfg-vk.zip
  )
fi

# manually set XDG_DATA_DIRS to make sure lsfg-vk included
sed -i '/^this_dir=.*$/a\
export XDG_DATA_DIRS="\$this_dir/usr/share:\${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"' ./light/AppDir/AppRun
