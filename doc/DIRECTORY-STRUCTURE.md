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
├── boot/                      everything that runs before kernel_main
│   ├── CMakeLists.txt         shared boot build settings and aggregate target
│   ├── common/                firmware- and architecture-neutral loader logic
│   ├── bios/                  legacy BIOS loader (x86 only)
│   │   ├── CMakeLists.txt
│   ├── limine/                Limine protocol integration
│   │   ├── CMakeLists.txt
│   │   ├── limine.conf
│   │   ├── common/            Limine responses -> normalized boot info
│   │   └── arch/
│   │       └── x86-64/ Limine entry and final handoff
│   └── uefi/                  custom UEFI loader
│       ├── CMakeLists.txt
│       ├── common/            architecture-independent UEFI protocol code
│       └── arch/
│           └── x86-64/ x86-64 UEFI ABI entry and paging setup
│
├── kernel/                    the kernel
│   ├── CMakeLists.txt
│   ├── main.c                 kernel_main(): portable startup sequence
│   ├── arch/
│   │   ├── arch.h             the arch interface the portable code uses
│   │   └── x86_64/            io, cpu, gdt, idt, apic, paging, context switch (.S),
│   │                          string.c (rep movsb), linker.ld
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
