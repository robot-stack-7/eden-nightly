#!/bin/bash -ex

echo "Making Eden for Windows (MSVC)"

cd ./eden

if [[ "${ARCH}" == "ARM64" ]]; then
    export EXTRA_CMAKE_FLAGS=(
        -DYUZU_USE_BUNDLED_SDL2=OFF
        -DYUZU_USE_EXTERNAL_SDL2=ON
	-DCMAKE_SYSTEM_NAME=Windows
    )

# workaround for ffmpeg
# use prebuilt arm64 ffmpeg from https://github.com/tordona/ffmpeg-win-arm64/releases
# trimmed unused files according to the ffmpeg x64 build from eden repo
sed -i 's|set(package_base_url "https://github.com/eden-emulator/")|set(package_base_url "https://github.com/pflyly/eden-nightly/")|' CMakeModules/DownloadExternals.cmake
sed -i 's|set(package_repo "ext-windows-bin/raw/master/")|set(package_repo "raw/refs/heads/main/")|' CMakeModules/DownloadExternals.cmake
sed -i 's|set(package_extension ".7z")|set(package_extension ".zip")|' CMakeModules/DownloadExternals.cmake

# Adapt upstream WIP changes
sed -i '
/#elif defined(ARCHITECTURE_x86_64)/{
    N
    /asm volatile("mfence\\n\\tlfence\\n\\t" : : : "memory");/a\
#elif defined(_MSC_VER) && defined(ARCHITECTURE_arm64)\
                    _Memory_barrier();
}
/#elif defined(ARCHITECTURE_x86_64)/{
    N
    /asm volatile("mfence\\n\\t" : : : "memory");/a\
#elif defined(_MSC_VER) && defined(ARCHITECTURE_arm64)\
                    _Memory_barrier();
}
' src/core/arm/dynarmic/dynarmic_cp15.cpp

sed -i 's/list(APPEND CMAKE_PREFIX_PATH "${Qt6_DIR}")/list(PREPEND CMAKE_PREFIX_PATH "${Qt6_DIR}")/' CMakeLists.txt
sed -i '/#include <boost\/asio.hpp>/a #include <boost/version.hpp>' src/core/debugger/debugger.cpp
fi

# disable debug info and silence warnings. turns out this can reduce build time, so we keep it.
find . -name CMakeLists.txt -exec sed -i 's|/W4||g; s|/Zi||g; s|/Zo||g; s|  *| |g' {} +

COUNT="$(git rev-list --count HEAD)"
EXE_NAME="Eden-${COUNT}-Windows-${ARCH}"

mkdir -p build
cd build
cmake .. -G Ninja \
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

# Use windeployqt to gather dependencies
EXE_PATH=./bin/eden.exe

if [[ "${ARCH}" == "ARM64" ]]; then
	# Accoding to #89, we may need every dll for the prebuilt ffmpeg
 	wget -q https://github.com/tordona/ffmpeg-win-arm64/releases/download/7.1.1/ffmpeg-7.1.1-essentials-shared-win-arm64.7z -O ffmpeg-full.7z
  	mkdir -p ffmpeg
   	7z x ffmpeg-full.7z -offmpeg > /dev/null
    	find ffmpeg -type f -iname "*.dll" -exec cp -v {} ./bin/ \;
     	rm -rf ffmpeg ffmpeg-full.7z
     	
  	# Use ARM64-specific Qt paths with windeployqt
 	"D:/a/eden-nightly/Qt/6.9.1/msvc2022_64/bin/windeployqt6.exe" --qtpaths "D:/a/eden-nightly/Qt/6.9.1/msvc2022_arm64/bin/qtpaths6.bat" --release --no-compiler-runtime --no-opengl-sw --no-system-d3d-compiler --no-system-dxc-compiler --dir bin "$EXE_PATH"
else
	windeployqt6 --release --no-compiler-runtime --no-opengl-sw --no-system-dxc-compiler --no-system-d3d-compiler --dir bin "$EXE_PATH"
fi

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
