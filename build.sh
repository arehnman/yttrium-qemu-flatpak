#!/bin/sh
set -eu

MANIFEST=${MANIFEST:-org.qemu.yttrium.yml}
BUILD_DIR=${BUILD_DIR:-build-dir}
REPO_DIR=${REPO_DIR:-repo}
#REMOTE_NAME=${REMOTE_NAME:-qemu-yttrium}
BUNDLE=${BUNDLE:-org.qemu.yttrium.flatpak}
DEBUG_BUNDLE=${DEBUG_BUNDLE:-org.qemu.yttrium.Debug.flatpak}

rm -rf "$REPO_DIR"

if command -v flatpak-builder >/dev/null 2>&1; then
    flatpak-builder \
        --force-clean \
        --repo="$REPO_DIR" \
        "$BUILD_DIR" \
        "$MANIFEST"
else
    flatpak run org.flatpak.Builder \
        --force-clean \
        --disable-rofiles-fuse \
        --repo="$REPO_DIR" \
        "$BUILD_DIR" \
        "$MANIFEST"
fi

flatpak build-bundle \
    "$REPO_DIR" \
    "$BUNDLE" \
    org.qemu.yttrium \
    --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak build-bundle \
    "$REPO_DIR" \
    "$DEBUG_BUNDLE" \
    org.qemu.yttrium.Debug \
    --runtime \
    --runtime-repo=https://dl.flathub.org/repo/flathub.flatpakrepo

echo "Created: $BUNDLE"
echo "Created: $DEBUG_BUNDLE"

