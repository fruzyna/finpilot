#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "Installing kernel mods..."

dnf install /tmp/rpms/ublue-os/ublue-os-akmods*.rpm
dnf install /tmp/rpms/kmods/kmod-v4l2loopback*.rpm

echo "Kmod installation complete!"
