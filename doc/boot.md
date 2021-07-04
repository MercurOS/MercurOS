# MercurOS Boot Process

MercurOS is UEFI bootable via the Maia bootloader. Maia works as an UEFI loader
application, capable of loading and executing an embedded ELF binary containing
the OS kernel.

As the HiFive Freedom Unmatched doesn't for the time being support native UEFI
booting, Maia is built to run on top of U-Boot. U-Boot is available both for
RISC-V QEMU and for the Freedom Unmatched, and provides a sufficient subset of
the UEFI interface to allow Maia to bring up MercurOS.

While MercurOS is intended to boot via U-Boot on both the QEMU and Freedom Unmatched,
the actual boot process differs somewhat. The Freedom Unmatched goes through
two standard boot stages (the Zeroth Stage Boot Loader from on-chip ROM, and the
First Stage Boot Loader that is embedded in a special partition on the boot SD-card)
prior to loading the final U-Boot stage where Maia will run. Additionally, the
Freedom Unmatched version of U-Boot needs to be built with OpenSBI, and both
OpenSBI and U-Boot need to be built with HiFive specific patches applied.
On QEMU it is possible to run U-Boot both standalone and with OpenSBI embedded,
but in either case, none of the HiFive patches should be applied.

More detailed target specific descriptions of both the boot sequence and
disk image creation:

 - [QEMU Boot Process](boot-qemu.md)
 - [Freedom Unmatched Boot Process](boot-fu740.md)
