# MercurOS Boot Process on QEMU

## Boot Sequence

On QEMU, booting can be done either directly with U-Boot, or with U-Boot on OpenSBI
(U-Boot SPL). Both options are described in the
[U-Boot documentation](https://u-boot.readthedocs.io/en/latest/board/emulation/qemu-riscv.html).

In order to run MercurOS on QEMU, a bootable disk image is created containing a
standard EFI System Partition, with the Maia bootloader UEFI image at
`EFI/BOOT/BOOTRISCV64.EFI`. The disk image is loaded as a QEMU virtual hard
disk drive.

The boot process is as follows:

1. QEMU loads U-Boot / U-Boot SPL at startup
2. In U-Boot shell we scan for SCSI devices, load the Maia UEFI image, and run it
  - `> scsi scan`
  - `> load scsi 0:3 ${kernel_addr_r} /EFI/BOOT/BOOTRISCV64.EFI`
  - `> bootefi ${kernel_addr_r}`
3. Maia loads the embedded kernel image into memory
  - Maia reads the kernel ELF image for loadable segments
  - Maia allocates memory using UEFI services and copies in the segment data
4. Maia hands over execution to the kernel
  - Maia loads the memory map via UEFI services
  - Maia calls UEFI ExitBootServices()
  - Maia jumps to the kernel entry point

## Image Creation

### Prerequisites

To build a bootable disk image, you will need an U-Boot binary, and the
MercurOS UEFI image (`BOOTRISCV64.efi`). Optionally, for U-Boot SPL, you will
also need an OpenSBI binary.
