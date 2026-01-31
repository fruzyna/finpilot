#!/usr/bin/env bash

# Tell build process to exit if there are any errors.
set -oue pipefail

echo "::group:: Install packages"

#
# Install packages from Fedora repos
#
echo "::group:: Install from Fedora repos"

FEDORA_PACKAGES=(
    android-tools
    ddcutil
    firefox
    fish
    git-lfs
    git-credential-libsecret
    gnome-boxes
    gnome-shell-extension-appindicator
    gnome-shell-extension-drive-menu
    gnome-shell-extension-launch-new-instance
    gnome-tweaks
    iwd
    keepassxc
    lm_sensors
    lsb_release
    podman-compose
    steam-devices
    waypipe
)

dnf -y install "${FEDORA_PACKAGES[@]}"

echo "::endgroup::"
echo "::group:: Install from copr repos"

# Source helper functions
# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

#
# Install fwupd with ublue ID fix
#

dnf -y copr enable ublue-os/staging
dnf -y copr disable ublue-os/staging
dnf -y swap --repo=copr:copr.fedorainfracloud.org:ublue-os:staging fwupd fwupd

#
# Install latest Flatpak to get preinstall command
#

dnf -y copr enable ublue-os/flatpak-test
dnf -y copr disable ublue-os/flatpak-test
dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak flatpak
dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-libs flatpak-libs
dnf -y --repo=copr:copr.fedorainfracloud.org:ublue-os:flatpak-test swap flatpak-session-helper flatpak-session-helper
# print information about flatpak package, it should say from our copr
rpm -q flatpak --qf "%{NAME} %{VENDOR}\n" | grep ublue-os

#
# Install UUPD updater
#

copr_install_isolated "ublue-os/packages" "uupd"

#
# Install VS Code from MS repo
#

echo "::endgroup::"
echo "::group:: Install VS Code"

tee /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
sed -i "s/enabled=.*/enabled=0/g" /etc/yum.repos.d/vscode.repo

dnf -y install --enablerepo=code code

rm -f /etc/yum.repos.d/vscode.repo

#
# Remove packages pre-installed from Fedora repos
#

echo "::endgroup::"
echo "::group:: Remove unwanted packages"

REMOVE_PACKAGES=(
    fedora-bookmarks
    fedora-chromium-config
    fedora-chromium-config-gnome
    gnome-extensions-app
    gnome-shell-extension-background-logo
    gnome-software
    gnome-software-rpm-ostree
    podman-docker
    yelp
)

dnf -y remove "${REMOVE_PACKAGES[@]}"

#
# Mutter experimental features
#

echo "::endgroup::"
echo "::group:: Configure Mutter"

MUTTER_EXP_FEATS="'scale-monitor-framebuffer', 'xwayland-native-scaling'"
if [[ "$LIAMOS_IMAGE_NAME" =~ "nvidia" ]]; then
    MUTTER_EXP_FEATS="'kms-modifiers', ${MUTTER_EXP_FEATS}"
fi
tee /usr/share/glib-2.0/schemas/zz1-bluefin-modifications-mutter-exp-feats.gschema.override << EOF
[org.gnome.mutter]
experimental-features=[${MUTTER_EXP_FEATS}]
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas &>/dev/null

echo "::endgroup::"
echo "::endgroup::"
