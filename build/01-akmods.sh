#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "Installing kernel mods..."

# install akmods
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

echo "Kmod installation complete!"
