#!/bin/bash

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH=$(uname -m)

BUILD_DIR=$(realpath "$1")
APPDIR="${BUILD_DIR}/light/AppDir"

cd "${BUILD_DIR}"

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
export EXTRA_QT_MODULES="svg;waylandcompositor"

# start to deploy into AppDir
# bundle libSDL3 for steamdeck
NO_STRIP=1 ./linuxdeploy \
  --appdir "${APPDIR}" \
  -e ./bin/eden \
  -d ../dist/org.eden_emu.eden.desktop \
  -i ../dist/org.eden_emu.eden.svg \
  -l /usr/lib/libSDL3.so* \
  --plugin qt \
  --plugin checkrt

ln -sfv "usr/share/icons/hicolor/scalable/apps/org.eden_emu.eden.svg" "${APPDIR}/.DirIcon"
