# MercurOS Boot Process on the HiFive Freedom Unmatched

## Boot Sequence

On the HiFive Freedom Unmatched, MercurOS is booted from an SD-card via U-Boot.
To accomplish this, the MSEL switches on the board must be set to boot from the
SD-card (see the board documentation for details.)

The boot stages are as follows:

1. FU740 runs the Zeroth Stage Boot Loader (ZSBL) from ROM
2. Based on the MSEL switches, the ZSBL loads the First Stage Boot Loader (FSBL) from the SD-card
  - If the MSEL switches are set for booting from SD-card...
  - ...look for the FSBL by partition GUID on the SD-card
  - ZSBL loads FSBL from the SD-card partition and runs it
3. FSBL (U-Boot SPL) loads the Second Boot Loader (SBL) and runs it
  - FSBL looks for the SBL by partition GUID on the SD-card
  - FSBL loads SBL from the SD-card partition and runs it
4. SBL (U-Boot with OpenSBI) loads and runs Maia
  - U-Boot scans bootable devices and finds the SD-card EFI System Partition
  - U-Boot loads the `/EFI/BOOT/BOOTRISCV64.EFI` file (Maia) from the SD-card
  - U-Boot runs Maia as an UEFI Application
5. Maia loads the embedded kernel image into memory
  - Maia reads the kernel ELF image for loadable segments
  - Maia allocates memory using UEFI services and copies in the segment data
6. Maia hands over execution to the kernel
  - Maia loads the memory map via UEFI services
  - Maia calls UEFI ExitBootServices()
  - Maia jumps to the kernel entry point

## Image Creation

With all prerequisites in place, an automated script can be used to create
a bootable SD-card image for the FU740-C000. The resulting image will
be a GPT partitioned disk image with special partitions for U-Boot SPL and
U-Boot proper (SBL, U-Boot with OpenSBI), an EFI system partition with the
MercurOS UEFI image, and a currently unused root filesystem partition.

### Prerequisites

To build a bootable disk image, you will need to build an OpenSBI binary with
HiFive patches applied, and U-Boot with the previously built OpenSBI
embedded and additional HiFive patches applied. You will also need to build a
Device Tree Binary (DTB) blob with HiFive patches applied. You will also need
to build the MercurOS UEFI image (`BOOTRISCV64.efi`).

The image creation script expects the required third party binaries to be
present in target specific subdirectories under a directory named `third-party`.

To build the boot image for FU740-C000, the following files need to be present:
- `third-party/fu740/u-boot/spl/u-boot-spl.bin`
- `third-party/fu740/u-boot/u-boot.itb`
- `third-party/fu740/linux/arch/riscv/boot/dts/sifive/hifive-unmatched-a00.dtb`

### Running the Image Creation Script

To create the bootable image, run:
```
$ ./make_image.sh fu740
```

### Preparing the SD-Card

Insert the SD-card into your SD-card reader, and find the corresponding Linux
device (e.g. /dev/sdd). **Note! Make sure the device is correct, as any data on the
device will be overwritten!**

Flash the image onto the SD-card by running as root *(make sure to replace `/dev/sdd`
below with the correct device for your system!)*:
```
$ dd if=images/mercuros_rv64_fu740.img of=/dev/sdd bs=64k iflag=fullblock oflag=direct conv=fsync status=progress
```

The image creation script includes a root filesystem partition in the image.
If desired the root filesystem partition can be expanded to cover any unused
space on the SD-card, although MercurOS is as of yet unable to make use of any
filesystem.

To resize the partition, run the following as root *(Again, take care to replace `/dev/sdd`
with the correct device for your system! Keep the partition number the same, so for example
given the device `/dev/sdc`, `/dev/sdd4` below would become `/dev/sdc4` instead)*:
```
$ echo "- +" | sfdisk -N 4 /dev/sdd
$ e2fsck -f /dev/sdd4
$ resize2fs /dev/sdd4
```
