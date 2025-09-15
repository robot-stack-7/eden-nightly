#!/bin/sh

set -ex

export ARCH="$(uname -m)"

cd ./eden
git config --global --add safe.directory .
COUNT="$(git rev-list --count HEAD)"

# hook the updater to check my repo
git apply ../patches/update.patch

# don't use bundled libusb
sed -i '' 's/PLATFORM_SUN OR PLATFORM_OPENBSD OR PLATFORM_FREEBSD/PLATFORM_SUN OR PLATFORM_OPENBSD/' externals/libusb/CMakeLists.txt

mkdir -p build
cd build
cmake .. -GNinja \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_FASTER_LD=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DYUZU_USE_CPM=ON \
    -DENABLE_QT_TRANSLATION=ON \
    -DENABLE_QT_UPDATE_CHECKER=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-w" \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DQt6_DIR=/usr/local/lib/cmake/Qt6
ninja
ccache -s-v

PKG_NAME="Eden-${COUNT}-FreeBSD-${ARCH}"
PKG_DIR="${PKG_NAME}/usr/local"
EDEN_PATH="${PKG_DIR}/bin/eden"

# Create base pkg dir
mkdir -p "${PKG_DIR}/bin"
cp -v ./bin/eden "${PKG_DIR}/bin"
mkdir -p "${PKG_DIR}/share/applications/"
cp -v ../dist/dev.eden_emu.eden.desktop "${PKG_DIR}/share/applications/"
mkdir -p "${PKG_DIR}/share/icons/hicolor/scalable/apps/"
cp -v ../dist/dev.eden_emu.eden.svg "${PKG_DIR}/share/icons/hicolor/scalable/apps/"

mkdir -p "${PKG_DIR}/lib/qt6"

# Copy all linked libs
ldd "$EDEN_PATH" | awk '/=>/ {print $3}' | while read -r lib; do
  case "$lib" in
    /lib*|/usr/lib*) ;;  # Skip system libs
    *)
      if echo "$lib" | grep -q '^/usr/local/lib/qt6/'; then
        cp -v "$lib" "${PKG_DIR}/lib/qt6/"
      else
        cp -v "$lib" "${PKG_DIR}/lib/"
      fi
      ;;
  esac
done

# Copy Qt6 plugins
QT6_PLUGINS="/usr/local/lib/qt6/plugins"
QT6_PLUGIN_SUBDIRS="
imageformats
iconengines
platforms
platformthemes
platforminputcontexts
styles
xcbglintegrations
wayland-decoration-client
wayland-graphics-integration-client
wayland-graphics-integration
wayland-shell-integration
"

for sub in $QT6_PLUGIN_SUBDIRS; do
  if [ -d "${QT6_PLUGINS}/${sub}" ]; then
    mkdir -p "${PKG_DIR}/lib/qt6/plugins/${sub}"
    cp -rv "${QT6_PLUGINS}/${sub}"/* "${PKG_DIR}/lib/qt6/plugins/${sub}/"
  fi
done

# Copy Qt6 translations
mkdir -p "${PKG_DIR}/share/translations"
cp -v src/yuzu/*.qm "${PKG_DIR}/share/translations/"

# Strip binaries
strip "${PKG_DIR}/bin/eden"
find "${PKG_DIR}/lib" -type f -name '*.so*' -exec strip {} \;

# Create a laucher for the pack
cat > "${PKG_NAME}/launch.sh" <<EOF
#!/bin/sh
# Eden Launcher for FreeBSD

DIR=\$(dirname "\$0")/usr/local

# Setup libs environment
export LD_LIBRARY_PATH="\$DIR/lib:\$DIR/lib/qt6:\$LD_LIBRARY_PATH"
export QT_PLUGIN_PATH="\$DIR/lib/qt6/plugins"
export QT_QPA_PLATFORM_PLUGIN_PATH="\$QT_PLUGIN_PATH/platforms"
export QT_TRANSLATIONS_PATH="\$DIR/share/translations"

exec "\$DIR/bin/eden" "\$@"
EOF

chmod +x "${PKG_NAME}/launch.sh"

# Pack for upload
XZ_OPT="-9e -T0" tar -cavf "${PKG_NAME}.tar.xz" "${PKG_NAME}"
mkdir -p artifacts
mv -v "${PKG_NAME}.tar.xz" artifacts

echo "Build completed successfully."
