#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "Systemd configuration..."

# Enable/disable systemd services
systemctl enable podman.socket
# Example: systemctl mask unwanted-service

echo "Systemd configuration complete!"
