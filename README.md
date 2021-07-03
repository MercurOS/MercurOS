# MercurOS

MercurOS is an experimental operating system written primarily in Rust,
targeting the RISC-V processor architecture.

The MercurOS project consists of several components:

 - The bootloader -- [Maia](https://github.com/MercurOS/maia)
 - The OS kernel -- [Mercurius](https://github.com/MercurOS/mercurius)
 - Build tools -- [tools](https://github.com/MercurOS/tools)

## Build Requirements

Currently, only Linux on x86-64 is supported as a build platform.

Rust with Cargo and rustup is required,
see [rust-lang.org](https://www.rust-lang.org/tools/install) for installation instructions.

Install the nightly toolchain by running:
```
$ rustup toolchain install nightly
```

Install the `riscv64gc-unknown-none-elf` cross-compilation target by running:
```
$ rustup target add riscv64gc-unknown-none-elf
```

MercurOS is using the Cargo `build-std` feature, so Rust standard library sources need
to be available as well:
```
$ rustup component add rust-src --toolchain nightly
```

Finally, the MercurOS build tools need access to the Rust llvm cross compilation toolchain,
so `cargo-binutils` and `llvm-tools` are needed as well:
```
$ cargo install cargo-binutils
$ rustup component add llvm-tools-preview
```

## Preparation

Clone the MercurOS project and submodules:
```
$ git clone https://github.com/MercurOS/MercurOS.git --recurse-submodules
```

## Building

MercurOS can currently be built for two hardware targets:

 - `qemu` for QEMU (qemu-system-riscv64)
 - `fu740` for HiFive Freedom Unmatched (SiFive fu740-c000)

The `build.sh` script will run through all the steps needed to build both Mercurius and Maia
for either target, and to create a bootable UEFI image.

To build, run one of the following:
```
$ ./build.sh qemu # for QEMU
$ ./build.sh fu740 # for HiFive Unmatched
```
