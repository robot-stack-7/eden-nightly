#!/bin/sh

set -eux
ARCH="$(uname -m)"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel \
	catch2 \
	cmake \
 	ccache \
	ffnvcodec-headers \
	gamemode \
	git \
	glslang \
 	inetutils \
 	jq \
	libva \
 	libvdpau \
	libvpx \
	nasm \
	ninja \
	numactl \
	patchelf \
	pulseaudio \
	pulseaudio-alsa \
	python-pip \
	qt6ct \
	qt6-tools \
	qt6-wayland \
  	sccache \
 	sdl3 \
	strace \
	unzip \
	vulkan-headers \
 	vulkan-mesa-layers \
	vulkan-nouveau \
	vulkan-radeon \
	wget \
 	wireless_tools \
  	xcb-util-cursor \
	xcb-util-image \
	xcb-util-renderutil \
	xcb-util-wm \
	xorg-server-xvfb \
	zip \
	zsync

case "$ARCH" in
	'x86_64')  
		PKG_TYPE='x86_64.pkg.tar.zst'
		pacman -Syu --noconfirm vulkan-intel haskell-gnutls svt-av1
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
wget -q --retry-connrefused --tries=30 "$OPUS_URL" -O ./opus-nano.pkg.tar.zst

if [ "$ARCH" = 'x86_64' ]; then
	wget -q --retry-connrefused --tries=30 "$INTEL_MEDIA_URL" -O ./intel-media.pkg.tar.zst
fi

pacman -U --noconfirm ./*.pkg.tar.zst
rm -f ./*.pkg.tar.zst

echo "All done!"
echo "---------------------------------------------------------------"
