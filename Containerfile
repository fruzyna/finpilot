###############################################################################
# PROJECT NAME CONFIGURATION
###############################################################################
# Name: liamos
###############################################################################

# Context stage - combine local and imported OCI container resources
FROM scratch AS ctx

# ARG is limited to the current build stage which is defined by FROM
ARG FEDORA_VERSION="43"
ARG KERNEL_BRANCH="centos"
ENV LIAMOS_KERNEL_BRANCH=${KERNEL_BRANCH}

COPY build /build
COPY custom /custom

# Copy from OCI containers to distinct subdirectories to avoid conflicts
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

# Start build process
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    /ctx/build/00-build.sh

# Verify final image and contents are correct.
RUN bootc container lint
