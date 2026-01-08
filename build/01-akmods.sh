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

    cp -r /ctx/akmods-nvidia/rpms /tmp/akmods-rpms/

    # Monkey patch right now...
    if ! grep -q negativo17 <(rpm -qi mesa-dri-drivers); then
        dnf5 -y swap --repo=updates-testing \
            mesa-dri-drivers mesa-dri-drivers
    fi

    # Install Nvidia RPMs
    curl "https://raw.githubusercontent.com/ublue-os/main/main/build_files/nvidia-install.sh" -o /tmp/nvidia-install.sh
    chmod +x /tmp/nvidia-install.sh
    /tmp/nvidia-install.sh
    rm -f /usr/share/vulkan/icd.d/nouveau_icd.*.json
    ln -sf libnvidia-ml.so.1 /usr/lib64/libnvidia-ml.so
    tee /usr/lib/bootc/kargs.d/00-nvidia.toml <<EOF
kargs = ["rd.driver.blacklist=nouveau", "modprobe.blacklist=nouveau", "nvidia-drm.modeset=1", "initcall_blacklist=simpledrm_platform_driver_init"]
EOF

    echo "::endgroup::"
fi

echo "::endgroup::"
