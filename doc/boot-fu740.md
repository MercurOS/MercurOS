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

### Prerequisites

To build a bootable disk image, you will need to build an OpenSBI binary with
HiFive patches applied, and U-Boot with the previously built OpenSBI
embedded and additional HiFive patches applied. You will also need to build a
Device Tree Binary (DTB) blob with HiFive patches applied. You will also need
to build the MercurOS UEFI image (`BOOTRISCV64.efi`).
