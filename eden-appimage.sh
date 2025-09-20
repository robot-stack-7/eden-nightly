#!/bin/bash

set -exu # -u: exit if referenced variables aren't assigned
         # -e: exit upon command error (NOTE: Builtin operator failures are handled differently depending the shell. POSIX behavior would be to quit, even if the condition was done with `test` )
         # -x: Print values of referenced variables, assignments, conditions and commands as they are executed/evaluated

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
PELF="https://github.com/xplshn/pelf/releases/latest/download/pelf_$ARCH"

case "$1" in
    steamdeck)
        echo "Making Eden Optimized Build for Steam Deck"
        CMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -flto=auto -fuse-ld=mold -w"
        CMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -flto=auto -fuse-ld=mold -w"
 		PROFILE="steamdeck"
   		EXTERNAL_SDL2="ON"
        TARGET="Steamdeck"
		CC="gcc"
		CXX="g++"
        ;;
    steamdeck-pgo)
        echo "Making Eden PGO_Optimized Build for Steam Deck"
        CMAKE_CXX_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
        CMAKE_C_FLAGS="-march=znver2 -mtune=znver2 -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
 		PROFILE="steamdeck"
   		EXTERNAL_SDL2="ON"
        TARGET="Steamdeck-PGO"
  		CC="clang"
		CXX="clang++"
        ;;
    rog)
        echo "Making Eden Optimized Build for ROG ALLY X"
        CMAKE_CXX_FLAGS="-march=znver4 -mtune=znver4 -O3 -pipe -flto=auto -fuse-ld=mold -w"
        CMAKE_C_FLAGS="-march=znver4 -mtune=znver4 -O3 -pipe -flto=auto -fuse-ld=mold -w"
 		PROFILE="steamdeck"
   		EXTERNAL_SDL2="ON"
        TARGET="ROG_ALLY"
		CC="gcc"
		CXX="g++"
        ;;
    rog-pgo)
        echo "Making Eden PGO Optimized Build for ROG ALLY X"
        CMAKE_CXX_FLAGS="-march=znver4 -mtune=znver4 -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
        CMAKE_C_FLAGS="-march=znver4 -mtune=znver4 -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
 		PROFILE="steamdeck"
   		EXTERNAL_SDL2="ON"
        TARGET="ROG_ALLY-PGO"
  		CC="clang"
		CXX="clang++"
        ;;
    common)
        echo "Making Eden Optimized Build for Modern CPUs"
        CMAKE_CXX_FLAGS="-march=x86-64-v3 -O3 -pipe -flto=auto -fuse-ld=mold -w"
        CMAKE_C_FLAGS="-march=x86-64-v3 -O3 -pipe -flto=auto -fuse-ld=mold -w"
        ARCH="${ARCH}_v3"
        TARGET="Common"
		CC="gcc"
		CXX="g++"
		BUNDLED_SDL2="ON"
  		EXTERNAL_SDL2="OFF"
        ;;
    common-pgo)
        echo "Making Eden PGO Optimized Build for Modern CPUs"
        CMAKE_CXX_FLAGS="-march=x86-64-v3 -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
        CMAKE_C_FLAGS="-march=x86-64-v3 -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
        ARCH="${ARCH}_v3"
        TARGET="Common-PGO"
  		CC="clang"
		CXX="clang++"
		BUNDLED_SDL2="ON"
  		EXTERNAL_SDL2="OFF"
        ;;
    legacy)
        echo "Making Eden Optimized Build for Legacy CPUs"
        CMAKE_CXX_FLAGS="-march=x86-64 -mtune=generic -O2 -pipe -flto=auto -fuse-ld=mold -w"
        CMAKE_C_FLAGS="-march=x86-64 -mtune=generic -O2 -pipe -flto=auto -fuse-ld=mold -w"
        TARGET="Legacy"
		CC="gcc"
		CXX="g++"
		BUNDLED_SDL2="ON"
  		EXTERNAL_SDL2="OFF"
        ;;
    legacy-pgo)
        echo "Making Eden Optimized Build for Legacy CPUs"
        CMAKE_CXX_FLAGS="-march=x86-64 -mtune=generic -O2 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
        CMAKE_C_FLAGS="-march=x86-64 -mtune=generic -O2 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
        TARGET="Legacy-PGO"
  		CC="clang"
		CXX="clang++"
		BUNDLED_SDL2="ON"
  		EXTERNAL_SDL2="OFF"
        ;;
    aarch64)
        echo "Making Eden Optimized Build for AArch64"
        CMAKE_CXX_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=auto -fuse-ld=mold -w"
        CMAKE_C_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=auto -fuse-ld=mold -w"
        TARGET="Linux"
		CC="gcc"
		CXX="g++"
		BUNDLED_SDL2="ON"
  		EXTERNAL_SDL2="OFF"
        ;;
    aarch64-pgo)
        echo "Making Eden PGO Optimized Build for AArch64"
        CMAKE_CXX_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
        CMAKE_C_FLAGS="-march=armv8-a -mtune=generic -O3 -pipe -flto=thin -fuse-ld=lld -fprofile-instr-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -fprofile-correction -w"
  		CC="clang"
		CXX="clang++"
        TARGET="Linux-PGO"
		BUNDLED_SDL2="ON"
  		EXTERNAL_SDL2="OFF"
        ;;
esac

cd ./eden
COUNT="$(git rev-list --count HEAD)"
DATE="$(date +"%d_%m_%Y")"

# hook the updater to check my repo
git apply ../patches/update.patch

mkdir build
cd build
cmake .. -GNinja \
    -DYUZU_USE_BUNDLED_QT=OFF \
	-DYUZU_USE_BUNDLED_FFMPEG=ON \
 	-DYUZU_USE_BUNDLED_OPENSSL=ON \
	-DYUZU_USE_CPM=ON \
	-DBUILD_TESTING=OFF \
    -DYUZU_TESTS=OFF \
	-DDYNARMIC_TESTS=OFF \
    -DYUZU_ENABLE_LTO=ON \
	-DDYNARMIC_ENABLE_LTO=ON \
    -DENABLE_QT_TRANSLATION=ON \
	-DENABLE_QT_UPDATE_CHECKER=ON \
    -DUSE_DISCORD_PRESENCE=ON \
    -DYUZU_CMD=OFF \
	-DYUZU_ROOM=ON \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_SYSTEM_PROCESSOR="$(uname -m)" \
    -DCMAKE_BUILD_TYPE=Release \
	-DCMAKE_C_COMPILER="${CC:-}" \
 	-DCMAKE_CXX_COMPILER="${CXX:-}" \
    -DCMAKE_EXE_LINKER_FLAGS="-Wl,--as-needed" \
    ${PROFILE:+-DYUZU_SYSTEM_PROFILE="$PROFILE"} \
	${BUNDLED_SDL2:+-DYUZU_USE_BUNDLED_SDL2="$BUNDLED_SDL2"} \
 	${EXTERNAL_SDL2:+-DYUZU_USE_EXTERNAL_SDL2="$EXTERNAL_SDL2"} \
    ${CMAKE_CXX_FLAGS:+-DCMAKE_CXX_FLAGS="$CMAKE_CXX_FLAGS"} \
    ${CMAKE_C_FLAGS:+-DCMAKE_C_FLAGS="$CMAKE_C_FLAGS"}
ninja

cd ../..
# Use sharun to generate AppDir
chmod +x ./sharun.sh
./sharun.sh ./eden/build

# Prepare uruntime and pelf
wget -q "$URUNTIME" -O ./uruntime
chmod +x ./uruntime
wget -q "$PELF" -O ./pelf
chmod +x ./pelf

# Turn AppDir into appimage and appbundle, upload seperately
echo "Generating AppImage"
APPIMAGE="Eden-${COUNT}-${TARGET}-${ARCH}.AppImage"
./uruntime --appimage-mkdwarfs -f --set-owner 0 --set-group 0 --no-history --no-create-timestamp --compression zstd:level=22 -S26 -B6 \
--header uruntime -i ./eden/build/AppDir -o "$APPIMAGE"

mkdir -p appimage
mv -v "${APPIMAGE}"* appimage/

echo "Generating AppBundle...(Go runtime)"
APPBUNDLE="Eden-${COUNT}-${TARGET}-${ARCH}.dwfs.AppBundle"
ln -sfv ./eden/build/AppDir/eden.svg ./eden/build/AppDir/.DirIcon.svg
./pelf --add-appdir ./eden/build/AppDir --appbundle-id="Eden-${DATE}-Escary" --compression "-C zstd:level=22 -S26 -B6" --output-to "$APPBUNDLE"

mkdir -p appbundle
mv -v "${APPBUNDLE}"* appbundle/

echo "All Done!"
