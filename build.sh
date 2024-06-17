#!/bin/bash

# Exit on error
set -e

# User defined variables
TARGET=${1:-"all"}
PLATFORM=${2:-"linux"}
SCONS_VERSION=${3:-"4.4.0"}
FFMPEG_URL=${4:-"https://github.com/EIRTeam/FFmpeg-Builds/releases/download/\
latest/ffmpeg-master-latest-linux64-lgpl-godot.tar.xz"}
FFMPEG_RELATIVE_PATH=${5:-"ffmpeg-master-latest-linux64-lgpl-godot"}
SCONS_FLAGS=${6:-"debug_symbols=no"}

# Fixed variables
SCONS_CACHE_DIR="scons-cache"
SCONS_CACHE_LIMIT="7168"
BUILD_DIR="gdextension_build"
OUTPUT_DIR="${BUILD_DIR}/build"

setup() {
    echo "Setting up to build for ${TARGET} with SCons ${SCONS_VERSION}"

    echo "Setting up FFmpeg. Source: ${FFMPEG_URL}"
    # Download FFmpeg
    wget -q --show-progress -O ffmpeg.tar.xz ${FFMPEG_URL}
    # Extract FFmpeg
    tar -xf ffmpeg.tar.xz
    echo "FFmpeg downloaded and extracted."

    # Ensure submodules are up to date
    git submodule update --init --recursive

    echo "Setting up SCons"
    # Set up virtual environment
    python -m venv venv
    source venv/bin/activate
    # Upgrade pip
    pip install --upgrade pip
    # Install SCons
    pip install scons==${SCONS_VERSION}
    # Exit virtual environment, as it will be re-entered later,
    # potentially from a different instance of the script (if TARGET is "all")
    deactivate
    echo "SCons $(scons --version) installed."

    echo "Setup complete."
}

build() {
    TARGET=${1:-"editor"}
    echo "Building ${TARGET}..."
    # Setup environment variables
    export SCONS_FLAGS="${SCONS_FLAGS}"
    export SCONS_CACHE="${SCONS_CACHE_DIR}"
    export SCONS_CACHE_LIMIT="${SCONS_CACHE_LIMIT}"
    export FFMPEG_PATH="${PWD}/${FFMPEG_RELATIVE_PATH}"

    # Enter virtual environment
    source venv/bin/activate
    # Enter build directory
    pushd ${BUILD_DIR}
    # Build
    scons platform=linux target=${TARGET} ffmpeg_path=${FFMPEG_PATH} ${SCONS_FLAGS}
    # Show build results
    ls -R build/addons/ffmpeg

    # Exit build directory
    popd
    # Exit virtual environment
    deactivate
}

cleanup() {
    echo "Cleaning up..."
    # Remove the ffmpeg tarball
    rm -f ffmpeg.tar.xz
    echo "Cleanup complete."
    echo "The built addons folder is located at '${OUTPUT_DIR}'."
}

setup

if [ "${TARGET}" == "all" ]; then
    for target in "editor" "template_release" "template_debug"; do
        build ${target}
    done
    echo "Builds completed."
    cleanup
    exit 0
else
    build ${TARGET}
    echo "${TARGET} build completed."
    cleanup
fi

