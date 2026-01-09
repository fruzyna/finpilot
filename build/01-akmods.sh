#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

# If main kernel branch is used, kernel does not need to be rebuilt to make akmods
if [[ "$LIAMOS_KERNEL_BRANCH" != "main" ]]; then
    echo "::group:: Replace kernel"

    # Remove existing kernel
    for pkg in kernel kernel-core kernel-modules kernel-modules-core kernel-modules-extra; do
        rpm --erase $pkg --nodeps
    done

    # Install new kernel
    dnf5 -y install \
        /ctx/akmods/common/kernel-rpms/kernel-[0-9]*.rpm \
        /ctx/akmods/common/kernel-rpms/kernel-core-*.rpm \
        /ctx/akmods/common/kernel-rpms/kernel-modules-*.rpm \
        /ctx/akmods/common/kernel-rpms/kernel-devel-*.rpm

    echo "::endgroup::"
fi

dnf5 versionlock add kernel kernel-devel kernel-devel-matched kernel-core kernel-modules kernel-modules-core kernel-modules-extra

echo "::group:: Install kernel modules"

# Install common akmods
dnf5 -y install \
    /ctx/akmods/common/rpms/ublue-os/ublue-os-akmods*.rpm \
    /ctx/akmods/common/rpms/kmods/kmod-framework-laptop*.rpm \
    /ctx/akmods/common/rpms/kmods/kmod-xone*.rpm

# Install v4l2loopback akmod
dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm
dnf5 -y install v4l2loopback /ctx/akmods/common/rpms/kmods/kmod-v4l2loopback*.rpm
dnf5 -y remove rpmfusion-free-release rpmfusion-nonfree-release

if [[ "$LIAMOS_IMAGE_NAME" =~ "nvidia" ]]; then
    echo "::group:: Install Nvidia kernel modules"

    cp -r /ctx/akmods/nvidia/rpms /tmp/akmods-rpms/

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
