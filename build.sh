#!/bin/bash

set -e

TARGET="${1:-qemu}"

SCRIPT_ROOT="$(dirname "$(readlink -f "$0")")"

IMAGE_PATH="$SCRIPT_ROOT/images"
MAIA_PATH="$SCRIPT_ROOT/maia"
MERCURIUS_PATH="$SCRIPT_ROOT/mercurius"
TOOLS_PATH="$SCRIPT_ROOT/tools"

EFI_IMAGE="BOOTRISCV64.efi"
MAKE_EFI="make-efi"

MAIA_OUT_PATH="$MAIA_PATH/target/riscv64gc-unknown-none-elf/release/mercuros-maia"
MERCURIUS_OUT_PATH="$MERCURIUS_PATH/target/riscv64gc-unknown-none-elf/release/mercuros-mercurius"
MAKE_EFI_PATH="$TOOLS_PATH/target/release/$MAKE_EFI"
OUT_PATH="$IMAGE_PATH/$TARGET/$EFI_IMAGE"

CARGO_BUILD="cargo build"
CARGO_TARGET="--release"

E_INVALID_ARGS=64
E_BUILD_FAILED=65

function assert_target() {
    case "$TARGET" in
      "qemu")
          info "Building MercurOS for QEMU"
          ;;

      "fu740")
          info "Building MercurOS for HiFive Unmatched"
          ;;

      * )
          error "unknown target '$TARGET'"
          info "\nValid targets are: 'qemu' and 'fu740'"
          exit $E_INVALID_ARGS
          ;;
    esac
}

function info() {
    local message="$1"

    echo -e "$message"
}

function error() {
    local message="$1"
    local ecode="${2:-0}"

    echo -e "\nError: ${message}" 1>&2
    [ "$ecode" -ne 0 ] && exit $ecode
}

function run_build() {
    local build_path="$1"
    local build_cmd="$2"
    shift 2

    pushd "$build_path" &>/dev/null
    set +e
    $build_cmd $@
    local result=$?
    set -e
    popd &>/dev/null

    return $result
}

function build_mercurius() {
    info "\nBuilding Mercurius..."
    run_build \
        "$MERCURIUS_PATH" \
        $CARGO_BUILD $CARGO_TARGET --features $TARGET
}

function build_maia() {
    info "\nBuilding Maia..."
    export KERNEL="$MERCURIUS_OUT_PATH"
    run_build \
        "$MERCURIUS_PATH" \
        $CARGO_BUILD $CARGO_TARGET --features $TARGET
}

function build_tools() {
    info "\nBuilding MercurOS build tools..."
    run_build \
        "$TOOLS_PATH" \
        $CARGO_BUILD $CARGO_TARGET --bin $MAKE_EFI
}

function make_efi() {
    info "\nCreating UEFI image..."
    export MAIA="$MAIA_OUT_PATH"
    mkdir -p "$IMAGE_PATH/$TARGET"
    run_build \
        "$MAIA_PATH" \
        "$MAKE_EFI_PATH" "$OUT_PATH"
}

assert_target

build_tools || \
    error "failed to build MercurOS build tools!" $E_BUILD_FAILED

build_mercurius || \
    error "failed to build kernel!" $E_BUILD_FAILED

build_maia || \
    error "failed to build bootloader!" $E_BUILD_FAILED

make_efi || \
    error "failed to prepare UEFI image!" $E_BUILD_FAILED

info "\nSuccessfully built MercurOS UEFI image at $OUT_PATH"
