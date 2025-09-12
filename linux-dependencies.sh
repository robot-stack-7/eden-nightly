#!/bin/sh

set -eux
ARCH="$(uname -m)"
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel \
	catch2 \
	cmake \
 	clang \
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
 	lld \
 	llvm \
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
	wget \
 	wireless_tools \
  	xcb-util-cursor \
	xcb-util-image \
	xcb-util-renderutil \
	xcb-util-wm \
	xorg-server-xvfb \
	zip \
	zsync

wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-opengl --add-vulkan qt6-base-mini opus-mini libxml2-mini llvm-libs-mini intel-media-driver-mini

echo "All done!"
echo "---------------------------------------------------------------"
