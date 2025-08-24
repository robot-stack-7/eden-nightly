#!/bin/bash -ex

echo "Making Eden for Windows (MSVC)"

cd ./eden

# 为额外的CMake参数初始化一个数组
declare -a EXTRA_CMAKE_FLAGS=()

if [[ "${ARCH}" == "ARM64" ]]; then
    # Not working, leave it here for future test
    # git apply -p1 ../patches/windows_arm64.patch
elif [[ "${ARCH}" == "x86_64" ]]; then
    # 为 x86_64 架构开启针对性的CPU优化 (AVX2) 和 C++异常处理 (/EHsc)
    echo "Enabling AVX2 optimizations and C++ exception handling for native x86_64 performance."
    # <--- 本次核心修复：在编译参数中加入 /EHsc --->
    EXTRA_CMAKE_FLAGS+=("-DCMAKE_CXX_FLAGS=/arch:AVX2 /EHsc")
fi

# 禁用调试信息和部分警告
find . -name CMakeLists.txt -exec sed -i 's|/W4||g; s|/Zi||g; s|/Zo||g; s|  *| |g' {} +

COUNT="$(git rev-list --count HEAD)"
EXE_NAME="Eden-${COUNT}-Windows-${ARCH}"

mkdir -p build
cd build

cmake .. -G Ninja \
    -DBUILD_TESTING=OFF \
    -DDYNARMIC_TESTS=OFF \
    -DYUZU_TESTS=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF \
    -DENABLE_QT_TRANSLATION=ON \
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

# 使用 windeployqt 来收集依赖项
EXE_PATH=./bin/eden.exe

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

# 删除不需要的调试文件
find bin -type f -name "*.pdb" -exec rm -fv {} +

# 打包用于上传
mkdir -p artifacts
mkdir "$EXE_NAME"
cp -r bin/* "$EXE_NAME"
ZIP_NAME="$EXE_NAME.7z"
7z a -t7z -mx=9 "$ZIP_NAME" "$EXE_NAME"
mv "$ZIP_NAME" artifacts/

echo "Build completed successfully."
