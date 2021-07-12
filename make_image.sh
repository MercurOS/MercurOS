#!/bin/sh

set -e

TARGET="${1:-qemu}"
IMAGE_FILE="mercuros_rv64_${TARGET}.img"
IMAGE_SIZE=128
IMAGE_PATH="images"

MAIA_IMAGE="$IMAGE_PATH/$TARGET/BOOTRISCV64.efi"
MAIA_FILE="BOOTRISCV64.EFI"

LINUX_ROOT="third-party/$TARGET/linux"
UBOOT_ROOT="third-party/$TARGET/u-boot"

function cleanup() {
    # Unmount image
    sudo umount /mnt
    sudo losetup -d "$LOOP_DEV"
}

echo "Preparing MercurOS Image for $TARGET"

# Create image
dd if=/dev/zero of="$IMAGE_FILE" bs=1M count=$IMAGE_SIZE

# Partition image
sudo sgdisk -g --clear --set-alignment=1 \
    --new=1:34:+1M:     --change-name=1:'u-boot-spl'    --typecode=1:5b193300-fc78-40cd-8002-e86c45580b47 \
    --new=2:2082:+4M:   --change-name=2:'opensbi-uboot' --typecode=2:2e54b353-1271-4842-806f-e436d6af6985 \
    --new=3:16384:+64M  --change-name=3:'efi'           --typecode=3:EF00 \
    --new=4:147456:-0   --change-name=4:'roofs'         --attributes=4:set:2 \
    "$IMAGE_FILE"

# Mount image in loop device
LOOP_DEV=$(sudo losetup --partscan --find --show "$IMAGE_FILE")
trap cleanup EXIT

# Write bootloader partitions
if [ "$TARGET" == "fu740" ]; then
    sudo dd \
        if="$UBOOT_ROOT/spl/u-boot-spl.bin" \
        of="$LOOP_DEV"p1 \
        bs=8k \
        iflag=fullblock oflag=direct \
        conv=fsync status=progress

    sudo dd \
        if="$UBOOT_ROOT/u-boot.itb" \
        of="$LOOP_DEV"p2 \
        bs=8k \
        iflag=fullblock oflag=direct \
        conv=fsync status=progress
fi

# Create and mount EFI system partition
sudo mkfs.fat "$LOOP_DEV"p3
sudo fatlabel "$LOOP_DEV"p3 EFIBOOT
sudo mount "$LOOP_DEV"p3 /mnt

# Prepare the EFI system partition
sudo mkdir -p /mnt/EFI/BOOT
sudo mkdir -p /mnt/EFI/MercurOS

# Copy Maia binary to the EFI partition
sudo cp "$MAIA_IMAGE" "/mnt/EFI/BOOT/$MAIA_FILE"

# Unmount the EFI system partition
sudo umount /mnt

# Create and mount root filesystem
sudo mkfs.ext4 "$LOOP_DEV"p4
sudo e2label "$LOOP_DEV"p4 rootfs
sudo mount "$LOOP_DEV"p4 /mnt

sudo mkdir -p /mnt/boot

# Copy DTBs
if [ "$TARGET" == "fu740" ]; then
    version=`cat "$LINUX_ROOT/include/config/kernel.release"`
    echo $version
    sudo mkdir -p /mnt/boot/dtbs/$version
    sudo cp -R "$LINUX_ROOT/arch/riscv/boot/dts/sifive/"*.dtb /mnt/boot/dtbs/$version
fi

echo "U-Boot Shell:"
if [ "$TARGET" == "fu740" ]; then
    echo "> load mmc 0:3 \${fdt_addr_r} /boot/dtbs/$version/sifive/hifive-unmatched-a00.dtb"
    echo "> load mmc 0:3 \${kernel_addr_r} /boot/${MAIA_FILE}"
    echo "> bootefi \${kernel_addr_r} \${fdt_addr_r}"
else
    echo "> scsi scan"
    echo "> load scsi 0:3 \${kernel_addr_r} /EFI/BOOT/${MAIA_FILE}"
    echo "> bootefi \${kernel_addr_r}"
fi

mv $IMAGE_FILE $IMAGE_PATH/$IMAGE_FILE
