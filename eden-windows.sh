#!/bin/bash -ex

echo "Making Eden for Windows ${TOOLCHAIN}-${ARCH}"

cd ./eden

declare -a EXTRA_CMAKE_FLAGS=()

# hook the updater to check my repo
patch -p1 < ../patches/update.patch

#tempfix, remove when upstream fixed
# patch -p1 < ../patches/tempfix.patch

if [[ "${TOOLCHAIN}" == "clang" ]]; then
    if [[ "${TARGET}" == "PGO" ]]; then
        EXTRA_CMAKE_FLAGS+=(
            "-DCMAKE_C_COMPILER=clang-cl"
            "-DCMAKE_CXX_COMPILER=clang-cl"
            "-DCMAKE_CXX_FLAGS=-O3 -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
            "-DCMAKE_C_FLAGS=-O3 -fprofile-use=${GITHUB_WORKSPACE}/pgo/eden.profdata -Wno-backend-plugin -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
        )
    else
        EXTRA_CMAKE_FLAGS+=(
            "-DCMAKE_C_COMPILER=clang-cl"
            "-DCMAKE_CXX_COMPILER=clang-cl"
            "-DCMAKE_CXX_FLAGS=-O3"
            "-DCMAKE_C_FLAGS=-O3"
        )
    fi
else
    EXTRA_CMAKE_FLAGS+=(
    "-DYUZU_ENABLE_LTO=ON"
    "-DDYNARMIC_ENABLE_LTO=ON"
    )
fi

COUNT="$(git rev-list --count HEAD)"

if [[ "${TARGET}" == "PGO" ]]; then
    EXE_NAME="Eden-${COUNT}-Windows-PGO-${TOOLCHAIN}-${ARCH}"
else
    EXE_NAME="Eden-${COUNT}-Windows-${TOOLCHAIN}-${ARCH}"
fi

mkdir -p build
cd build

cmake .. -G Ninja \
    -DBUILD_TESTING=OFF \
    -DDYNARMIC_TESTS=OFF \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DYUZU_USE_BUNDLED_FFMPEG=ON \
    -DYUZU_USE_CPM=ON \
    -DENABLE_QT_TRANSLATION=ON \
    -DENABLE_QT_UPDATE_CHECKER=ON \
    -DUSE_DISCORD_PRESENCE=OFF \
    -DYUZU_CMD=OFF \
    -DYUZU_ROOM=ON \
    -DYUZU_ROOM_STANDALONE=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    "${EXTRA_CMAKE_FLAGS[@]}"
ninja

# Gather dependencies
windeployqt --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --dir bin ./bin/eden.exe

# Delete un-needed debug files 
find bin -type f -name "*.pdb" -exec rm -fv {} +

# Pack for upload
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r bin/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
