###############################################################################
# PROJECT NAME CONFIGURATION
###############################################################################
# Name: liamos
#
# IMPORTANT: Change "finpilot" above to your desired project name.
# This name should be used consistently throughout the repository in:
#   - Justfile: export image_name := env("IMAGE_NAME", "your-name-here")
#   - README.md: # your-name-here (title)
#   - artifacthub-repo.yml: repositoryID: your-name-here
#   - custom/ujust/README.md: localhost/your-name-here:stable (in bootc switch example)
#
# The project name defined here is the single source of truth for your
# custom image's identity. When changing it, update all references above
# to maintain consistency.
###############################################################################

###############################################################################
# MULTI-STAGE BUILD ARCHITECTURE
###############################################################################
# This Containerfile follows the Bluefin architecture pattern as implemented in
# @projectbluefin/distroless. The architecture layers OCI containers together:
#
# 1. Context Stage (ctx) - Combines resources from:
#    - Local build scripts and custom files
#    - @projectbluefin/common - Desktop configuration shared with Aurora 
#    - @ublue-os/brew - Homebrew integration
#
# 2. Base Image Options:
#    - `ghcr.io/ublue-os/silverblue-main:latest` (Fedora and GNOME)
#    - `ghcr.io/ublue-os/base-main:latest` (Fedora and no desktop 
#    - `quay.io/centos-bootc/centos-bootc:stream10 (CentOS-based)` 
#
# See: https://docs.projectbluefin.io/contributing/ for architecture diagram
###############################################################################

# Context stage - combine local and imported OCI container resources
FROM scratch AS ctx

# ARG is limited to the current build stage which is defined by FROM
ARG FEDORA_VERSION="43"
ARG KERNEL_BRANCH="main"
ENV LIAMOS_KERNEL_BRANCH=${KERNEL_BRANCH}

COPY build /build
COPY custom /custom
# Copy from OCI containers to distinct subdirectories to avoid conflicts
# Note: Renovate can automatically update these :latest tags to SHA-256 digests for reproducibility
COPY --from=ghcr.io/projectbluefin/common:latest /system_files /oci/common
COPY --from=ghcr.io/ublue-os/akmods:${KERNEL_BRANCH}-${FEDORA_VERSION} / /akmods/common
COPY --from=ghcr.io/ublue-os/akmods-nvidia-open:${KERNEL_BRANCH}-${FEDORA_VERSION} / /akmods/nvidia

# Base Image - GNOME included
FROM ghcr.io/ublue-os/silverblue-main:latest

# KERNEL_BRANCH build-arg is accessible during build as LIAMOS_KERNEL_BRANCH
ARG KERNEL_BRANCH
ENV LIAMOS_KERNEL_BRANCH=${KERNEL_BRANCH}

# IMAGE_NAME build-arg is accessible during build as LIAMOS_IMAGE_NAME
ARG IMAGE_NAME="liamos-base"
ENV LIAMOS_IMAGE_NAME=${IMAGE_NAME}

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    /ctx/build/00-build.sh
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
