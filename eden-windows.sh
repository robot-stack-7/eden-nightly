#!/bin/bash -ex

echo "Making Eden for Windows ${TOOLCHAIN}"

cd ./eden

declare -a EXTRA_CMAKE_FLAGS=()

if [[ "${TOOLCHAIN}" == "msvc" ]]; then

    # hook the updater to check my repo
    git apply ../patches/update.patch

    if [[ "${ARCH}" == "ARM64" ]]; then
        # Not working, leave it here for future test
        git apply ../patches/windows_arm64.patch
    elif [[ "${ARCH}" == "x86_64" ]]; then
        echo "Enabling AVX2 optimizations and C++ exception handling for native x86_64 performance."
        EXTRA_CMAKE_FLAGS+=("-DCMAKE_CXX_FLAGS=/arch:AVX2 /EHsc")
    fi

    # disable debug info and silence warnings.
    find . -name CMakeLists.txt -exec sed -i 's|/W4||g; s|/Zi||g; s|/Zo||g; s|  *| |g' {} +

elif [[ "${TOOLCHAIN}" == "msys2" ]]; then
        # temp fix
        sed -i 's|#include "common/logging/log.h"|#include "common/logging/log.h"\n#include "common/assert.h"|' src/common/heap_tracker.cpp
        
        EXTRA_CMAKE_FLAGS+=(
        "-DCMAKE_C_COMPILER=gcc"
        "-DCMAKE_CXX_COMPILER=g++"
        "-DCMAKE_C_FLAGS=-O3 -flto -fno-fat-lto-objects"
        "-DCMAKE_CXX_FLAGS=-O3 -flto -fno-fat-lto-objects"
        "-DCMAKE_EXE_LINKER_FLAGS=-flto"
        "-DCMAKE_SHARED_LINKER_FLAGS=-flto"
        )
fi

COUNT="$(git rev-list --count HEAD)"
EXE_NAME="Eden-${COUNT}-Windows-${TOOLCHAIN}-${ARCH}"

mkdir -p build
cd build

cmake .. -G Ninja \
    -DBUILD_TESTING=OFF \
    -DDYNARMIC_TESTS=OFF \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DENABLE_QT_TRANSLATION=ON \
    -DENABLE_QT_UPDATE_CHECKER=ON \
    -DYUZU_ENABLE_LTO=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER_LAUNCHER=ccache \
    -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
    -DYUZU_USE_PRECOMPILED_HEADERS=OFF \
    -DCMAKE_SYSTEM_PROCESSOR=${ARCH} \
    "${EXTRA_CMAKE_FLAGS[@]}"
ninja
ccache -s -v

# Gather dependencies
EXE_PATH=./bin/eden.exe

if [[ "${TOOLCHAIN}" == "msvc" ]]; then
    if [[ "${ARCH}" == "ARM64" ]]; then
        wget -q https://github.com/tordona/ffmpeg-win-arm64/releases/download/7.1.1/ffmpeg-7.1.1-essentials-shared-win-arm64.7z -O ffmpeg-full.7z
        mkdir -p ffmpeg
        7z x ffmpeg-full.7z -offmpeg > /dev/null
        find ffmpeg -type f -iname "*.dll" -exec cp -v {} ./bin/ \;
        rm -rf ffmpeg ffmpeg-full.7z
        
        "D:/a/eden-nightly/Qt/6.9.1/msvc2022_64/bin/windeployqt6.exe" --qtpaths "D:/a/eden-nightly/Qt/6.9.1/msvc2022_arm64/bin/qtpaths6.bat" --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --no-system-dxc-compiler --dir bin "$EXE_PATH"
    else
        windeployqt6 --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --dir bin "$EXE_PATH"
    fi

    # Delete un-needed debug files 
    find bin -type f -name "*.pdb" -exec rm -fv {} +

elif [[ "${TOOLCHAIN}" == "msys2" ]]; then
    
    windeployqt6 --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --no-system-dxc-compiler --dir ./bin "$EXE_PATH"
    echo -e "[Paths]\nPrefix = ." > ./bin/qt.conf    
    
    copy_deps() {
        local target="$1"
        objdump -p "$target" | awk '/DLL Name:/ {print $3}' | while read -r dll; do
            [[ -z "$dll" ]] && continue

            local dll_path
            dll_path=$(command -v "$dll" 2>/dev/null || true)
            [[ -z "$dll_path" ]] && continue

            case "$dll_path" in
                /c/Windows/System32/*|/c/Windows/SysWOW64/*) continue ;;
            esac

            local dest="./bin/$dll"
            if [[ ! -f "$dest" ]]; then
                cp -v "$dll_path" ./bin/
                copy_deps "$dll_path"
            fi
        done
    }

    copy_deps "$EXE_PATH"
    for qt_dll in ./bin/Qt6*.dll; do
        [[ -f "$qt_dll" ]] && copy_deps "$qt_dll"
    done

    find ./bin -type f \( -name "*.dll" -o -name "*.exe" \) -exec strip -s {} +
fi

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r bin/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
