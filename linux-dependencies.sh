#!/bin/sh

set -ex
ARCH="$(uname -m)"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	aom \
	base-devel \
	boost \
	boost-libs \
	catch2 \
	clang \
	cmake \
 	ccache \
	curl \
	dav1d \
	desktop-file-utils \
	doxygen \
	enet \
	ffmpeg \
	fuse2 \
	fmt \
	gamemode \
	git \
	glslang \
	glfw \
	glu \
	hidapi \
 	jq \
	libass \
	libdecor \
	libdisplay-info \
	libfdk-aac \
	libopusenc \
 	libtheora \
	libva \
	libvpx \
	libxi \
	libxkbcommon-x11 \
	libxss \
	libzip \
	mbedtls \
	mbedtls2 \
	mesa \
	meson \
	nasm \
	ninja \
	nlohmann-json \
	numactl \
	patchelf \
	pipewire-audio \
	pulseaudio \
	pulseaudio-alsa \
	python-pip \
	qt6-base \
	qt6ct \
	qt6-multimedia \
	qt6-tools \
	qt6-wayland \
 	rapidjson \
  	sccache \
	sdl2 \
 	sdl3 \
	strace \
	unzip \
	vulkan-headers \
	vulkan-nouveau \
	vulkan-radeon \
	wget \
 	wireless_tools \
	x264 \
	x265 \
	xcb-util-image \
	xcb-util-renderutil \
	xcb-util-wm \
	xorg-server-xvfb \
	zip \
	zsync

# build and installlsfg-vk
git clone https://github.com/PancakeTAS/lsfg-vk.git ./lsfg && (
	cd ./lsfg
	CC=clang CXX=clang++ cmake \
		-B build                    \
		-G Ninja                    \
		-DCMAKE_BUILD_TYPE=Release  \
		-DCMAKE_INSTALL_PREFIX=/usr
	cmake --build build
	cmake --install build
)


case "$ARCH" in
	'x86_64')  
		PKG_TYPE='x86_64.pkg.tar.zst'
		pacman -Syu --noconfirm vulkan-intel haskell-gnutls gcc svt-av1
		;;
	'aarch64') 
		PKG_TYPE='aarch64.pkg.tar.xz'
		pacman -Syu --noconfirm vulkan-freedreno vulkan-panfrost
		;;
	''|*)      
		echo "Unknown cpu arch: $ARCH" 
		exit 1
		;;
esac

LLVM_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/llvm-libs-nano-$PKG_TYPE"
FFMPEG_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/ffmpeg-mini-$PKG_TYPE"
QT6_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/qt6-base-iculess-$PKG_TYPE"
LIBXML_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/libxml2-iculess-$PKG_TYPE"
OPUS_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/opus-nano-$PKG_TYPE"
INTEL_MEDIA_URL="https://github.com/pkgforge-dev/llvm-libs-debloated/releases/download/continuous/intel-media-mini-$PKG_TYPE" 

echo "Installing debloated pckages..."
echo "---------------------------------------------------------------"
wget -q --retry-connrefused --tries=30 "$LLVM_URL" -O ./llvm-libs.pkg.tar.zst
wget -q --retry-connrefused --tries=30 "$QT6_URL" -O ./qt6-base-iculess.pkg.tar.zst
wget -q --retry-connrefused --tries=30 "$LIBXML_URL" -O ./libxml2-iculess.pkg.tar.zst
wget -q --retry-connrefused --tries=30 "$FFMPEG_URL" -O ./ffmpeg-mini.pkg.tar.zst
wget -q --retry-connrefused --tries=30 "$OPUS_URL" -O ./opus-nano.pkg.tar.zst

if [ "$ARCH" = 'x86_64' ]; then
	wget -q --retry-connrefused --tries=30 "$INTEL_MEDIA_URL" -O ./intel-media.pkg.tar.zst
fi

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"
