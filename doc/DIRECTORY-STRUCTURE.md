# Directory structure

An operating system is very complex project with many moving parts, to be able to quickly see where all the components are located this Directory Structure file was created.

## Tree

```
milli/
├── CMakeLists.txt
├── CMakePresets.json
├── cmake/                     toolchain files and CMake helpers
│   └── toolchains/            x86_64-elf.cmake, later aarch64-elf.cmake
│
├── abi/                       headers shared across a boundary. types only, no code
│   ├── boot_info.hpp          loader <-> kernel
│   └── syscall.hpp            kernel <-> userspace
│
├── boot/                      everything that runs BEFORE kernel_main
│   ├── limine/                limine.conf, limine_boot.cpp
│   └── uefi/                  custom loader
│
├── kernel/                    the kernel
│   ├── CMakeLists.txt
│   ├── main.cpp               kernel_main(): portable startup sequence
│   ├── arch/
│   │   ├── arch.hpp           the arch:: interface the portable code uses
│   │   └── x86_64/            io, cpu, gdt, idt, apic, paging, context switch (.S),
│   │                          string.cpp (rep movsb), linker.ld
│   ├── lib/                   freestanding "libk": kprintf, string utils, containers
│   ├── bitmap/                physical memory manager
│   ├── debug/                 panic, logging, assert, stack traces
│   ├── mm/                    pmm, vmm, heap
│   ├── sched/                 threads, scheduler, locks
│   ├── fs/                    vfs, tarfs, fat32, ...
│   ├── drivers/
│   │   ├── serial/            uart16550
│   │   ├── display/           framebuffer, console, font
│   │   ├── input/             ps2 keyboard, later usb hid
│   │   ├── pci/
│   │   └── virtio/            blk, net, gpu
│   └── syscall/
│
├── userland/                  separate programs, separate build flags
│   ├── libc/                  custom libc/musl
│   ├── init/
│   └── shell/
│
├── tools/                     host-side scripts: make-initrd, run-qemu, gdb init file
├── tests/                     host-side unit tests of portable code
├── doc/                       design notes, and other instructions
└── .clang-format, .clangd, .gitignore, ...
```
