#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "::group:: Install kernel modules"

# install common akmods
dnf5 -y install \
    /ctx/akmods-common/rpms/ublue-os/ublue-os-akmods*.rpm \
    /ctx/akmods-common/rpms/kmods/kmod-framework-laptop*.rpm \
    /ctx/akmods-common/rpms/kmods/kmod-xone*.rpm

# install v4l2loopback akmod
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
dnf5 -y install v4l2loopback /ctx/akmods-common/rpms/kmods/kmod-v4l2loopback*.rpm
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

if [[ "$LIAMOS_IMAGE_NAME" =~ "nvidia" ]]; then
    echo "::group:: Install Nvidia kernel modules"

    dnf5 -y install \
        /ctx/akmods-nvidia/rpms/ublue-os/ublue-os-nvidia*.rpm \
        /ctx/akmods-nvidia/rpms/kmods/kmod-nvidia*.rpm

    echo "::endgroup::"
fi

echo "::endgroup::"
