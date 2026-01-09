#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "::group:: Configure Systemd"

systemctl enable podman.socket

# replace Fedora update timers with UUPD
systemctl enable uupd.timer
systemctl disable rpm-ostreed-automatic.timer
systemctl disable flatpak-system-update.timer

echo "::endgroup::"
