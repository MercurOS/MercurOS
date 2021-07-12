#!/bin/sh

QEMU="qemu-system-riscv64"
QEMU_MACHINE="virt"

IMAGE="images/mercuros_rv64_qemu.img"

QEMU_OPTIONS=( -machine $QEMU_MACHINE -display none -serial stdio )

function qemu_direct() {
    QEMU_OPTIONS+=(-bios third-party/qemu/u-boot/u-boot)
}

function qemu_opensbi() {
    QEMU_OPTIONS+=(-bios third-party/qemu/u-boot/spl/u-boot-spl)
    QEMU_OPTIONS+=(-device loader,file=third-party/qemu/u-boot/u-boot.itb,addr=0x80200000)
}

function qemu_hdd() {
    local image="$1"

    QEMU_OPTIONS+=(-device ich9-ahci,id=ahci)
    QEMU_OPTIONS+=(-drive if=none,file=$image,format=raw,id=osimage)
    QEMU_OPTIONS+=(-device ide-hd,drive=osimage,bus=ahci.0)
}

function qemu_gdb() {
    QEMU_OPTIONS+=(-gdb tcp::1234)

    # halt on startup
    #QEMU_OPTIONS+=(-S)
}

#qemu_direct
qemu_opensbi

qemu_hdd $IMAGE
qemu_gdb

$QEMU ${QEMU_OPTIONS[@]}
