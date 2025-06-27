#!/bin/sh

set -ex

export ARCH="$(uname -m)"

cd ./eden
git config --global --add safe.directory .
COUNT="$(git rev-list --count HEAD)"

# workaound for libusb
sed -i '' 's/find_package(libusb 1\.0\.24 MODULE)/find_package(libusb 1.0.16 REQUIRED)/' CMakeLists.txt

# workaound for renderdoc
sed -i '' '/#elif defined(__APPLE__)/i\
#elif defined(__FreeBSD__)\
#define RENDERDOC_CC\
' externals/renderdoc/renderdoc_app.h

# workaound for ffmpeg
sed -i '' 's/make -j\${SYSTEM_THREADS}/gmake -j\${SYSTEM_THREADS}/' externals/ffmpeg/CMakeLists.txt

# workaround for airplane mode commit: resolve non existed libiw linking
sed -i '' 's/^if *(UNIX AND NOT APPLE AND NOT ANDROID)/if(CMAKE_SYSTEM_NAME STREQUAL "Linux")/' src/core/CMakeLists.txt

mkdir build
cd build
cmake .. -GNinja \
    -DYUZU_TESTS=OFF \
    -DYUZU_CHECK_SUBMODULES=OFF \
    -DYUZU_USE_FASTER_LD=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-w" \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DYUZU_USE_PRECOMPILED_HEADERS=OFF \
    -DQt6_DIR=/usr/local/lib/cmake/Qt6
ninja
ccache -s-v

PKG_NAME="Eden-${COUNT}-FreeBSD-${ARCH}"
PKG_DIR="${PKG_NAME}/usr/local"
EDEN_PATH="${PKG_DIR}/bin/eden"

mkdir -p "${PKG_NAME}"
DESTDIR="${PKG_NAME}" ninja install

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
