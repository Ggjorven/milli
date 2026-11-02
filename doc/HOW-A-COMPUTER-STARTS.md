# How a computer starts

This is a very simple still high-level overview of how a computer starts

## Boot

This will describe the most general steps of how a PC starts from boot.

1. BIOS is copied from a ROM chip into RAM

2. BIOS starts executing code:
    - Initializes hardware
    - Runs some tests (POST = power-on self test)

3. BIOS [searches for an operating system](#OS-search) to start.

## OS search

This will describe how an OS is found and started.

### Legacy boot (BIOS)

1. The BIOS loads the first sector (first 512 bytes) of each disk into memory (at location 0x7C00)

2. It looks for the boot signature (0x55 0xAA) at offsets 510 and 511.

3. If found it starts executing that sector.

That 512 byte sector often only does:
- (optional) Set up the segment registers and a stack.
- (optional, can be stage 2) Save the boot drive number in a variable (the BIOS sets it in the `dl` register).
- Load the next stage (either hardcoded how many sectors or found via filesystem like **FAT12**).

The second stage often does the rest:
- Set up the segment registers and a stack.
- Save the boot drive number (the BIOS sets it in the `dl` register).
- Read the filesystem to find files like the kernel (`kernel.bin`) or a config.
- Gather information about the **memory map**, **video mode**, **disk geometry** & **drive info**.
- Enable the **A20 line** (to be able to access more than 1MB of memory)
- Load the kernel [*1](#Kernel-loading-nuances) (Read it from disk to memory)
- Switch CPU modes from [16-bit real](#16-bit-real-mode) to [32-bit protected mode](#32-bit-protected-mode) or [64-bit](#64-bit-protected-mode)
- Jump to the kernel entry point and pass along memory map and boot drive

#### Kernel loading nuances

To load the kernel we need to read it from disk into memory.
[16-bit real mode](#16-bit-real-mode) (which is what the CPU starts in) can only address about 1 MB of RAM,
so loading a larger kernel often involves a trick: read into a low buffer, then switch modes and copy it up.

### UEFI

// TODO: Future

## Glossary

### 16-bit real mode

This is what the CPU starts in for compatibility with [the original 8086](https://en.wikipedia.org/wiki/Intel_8086). It has:
- 16 bit registers.
- Addresses are segment:offset, giving access to only about 1 MB of RAM.
- No memory protection, no privilige levels and no virtual memory.
- BIOS interrupts available.

### 32-bit protected mode

Made for [80386 / i386](https://en.wikipedia.org/wiki/I386) processors:
- 32-bit registers (`eax`, `ebx`, etc.) and 32-bit addresses, so up to 4 GB of address space.
- Privilege levels (rings). The kernel runs in ring 0, applications in ring 3.
- Memory protection through segmentation ([the GDT](#GDT)) and [paging](#Paging)
- Multitasking support (allow saving state for context switching like saving registers, instruction pointer, stack pointer, etc.).

### 64-bit long mode

Introduced by AMD (amd64/x86-64) and later adopted by Intel:
- 64-bit registers (`rax`, `rbx`, etc.) + 8 extra general purpose registers (`r8` to `r15`). Also 64-bit addresses, so theoretically up to 16 EB of address space (16'777'216 TB) ([*2](Address-space-nuance)).
- [Paging](#Paging) is mandatory (4-level or 5-level page tables).
- Extra features:
    - RIP-relative addressing (makes position-independent code easy).
    - `syscall`/`sysret` instructions.
    - the `nx` (no-execute) bit for security.

#### Address space nuance

Since [paging](#paging) is required it adds some overhead.
Current CPUs implement 48 (4-level) or 57 bits (5-level) of virtual address space, so the real number is more like 256 TB or 128 PB.

### GDT

The GDT is a table in memory that describes memory segments. Each entry is an 8-byte segment descriptor containing:
- **Base**, where the segment starts.
- **Limit**, how big it is.
- **Access flags**, is it code or data, readable/writable & which privilege ring (0 to 3) it belongs to.
- **Other flags**, 16/32-bit, whether the limit is counted in bytes or 4 KB units.

Modern OSes use a [flat memory model](#Flat-memory-model) where segments cover the entire address space and effectively do nothing.
The minimal GDT has three entries:
- **Null descriptor** (required, all zeros, entry 0)
- **Code segment**: base 0, limit 4 GB, executable
- **Data segment**: base 0, limit 4 GB, writable

This is because even in [64-bit long mode](#64-bit-long-mode) the CPU still supports running apps in 32-bit mode, which *requires* segmentation, so we **NEED** a GDT.

### Paging

Paging divides memory into fixed-size blocks and uses page tables to map virtual addresses to physical addresses.
A page is a block of virtual memory, normally 4 KB. A frame is the matching 4 KB block of physical RAM.

Page tables are in-memory structures the CPU walks to translate addresses. In long mode they have 4 levels (5 on newer CPUs).
The MMU (memory management unit) in the CPU does the translation on every access, with a cache called the TLB to keep it fast.

It helps with:
- **Process isolation**, every process gets its own page tables, so it sees its own private address space and can’t touch another process' memory.
- **Virtual memory**, pages can be marked "not present" and swapped to disk.
- **Flexible layout**, contiguous virtual memory can be backed by scattered physical frames, which avoids fragmentation.
- **Fine-grained permissions**, per-page read/write/execute and user/kernel.
- **Shared memory**, two processes can map the same physical frame (shared libraries, e.g.).

### Flat memory model

The flat memory model is where the program sees memory as a single contiguous range of addresses, from 0 up to the maximum (e.g. 0 to 4 GB-1 in 32-bit).
An address is just one number. There are no segments to think about.

## References

- **nanobyte** - [Building an OS - 1 - Hello world](https://www.youtube.com/watch?v=9t-SPC7Tczc) 3:46-4:24
- **nanobyte** - [Part 2-1: Boot Protocol & Bootloader Architecture](https://nanobyte.dev/building-an-os/2-1-boot-protocol/#for-x86-64)
