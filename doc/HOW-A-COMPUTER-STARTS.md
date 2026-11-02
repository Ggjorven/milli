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
- Load the kernel ([nuance](#Kernel-loading-nuances)) (Read it from disk to memory)
- Switch CPU modes from [16-bit real](#16-bit-real-mode) to [32-bit protected mode](#32-bit-protected-mode) or [64-bit](#64-bit-long-mode)
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
- 64-bit registers (`rax`, `rbx`, etc.) + 8 extra general purpose registers (`r8` to `r15`). Also 64-bit addresses, so theoretically up to 16 EB of address space (16'777'216 TB) ([nuance](#Address-space-nuance)).
- [Paging](#Paging) is mandatory (4-level or 5-level page tables).
- Extra features:
    - RIP-relative addressing (makes position-independent code easy).
    - `syscall`/`sysret` instructions.
    - the `nx` (no-execute) bit for security.

#### Address space nuance

[Paging](#paging) uses virtual addresses and use multiple levels of indexes into tables.
Current CPUs implement 4-levels (48-bit) or 5-levels (57-bit) of virtual address space. This means that not the full 16 EB can be used.
The real number is more like 256 TB or 128 PB.

### GDT

The GDT is a table in memory that describes memory segments. Each entry is an 8-byte segment descriptor containing:
- **Base**, where the segment starts.
- **Limit**, how big it is.
- **Access flags**, is it code or data, readable/writable & which privilege ring (0 to 3) it belongs to.
- **Other flags**, 16/32-bit, whether the limit is counted in bytes or 4 KB units.

#### 32-bit systems

On a typical 32-bit system a GDT looks like:

| Entry | Purpose |
|---|---|
| 0 | Null descriptor (required, zeros) |
| 1 | Code (base 0, limit 4GB, 32-bit, ring 0) |
| 2 | Data (base 0, limit 4GB, ring 0) |

#### 64-bit systems

On a typical 64-bit system a GDT looks like:

| Entry | Purpose |
|---|---|
| 0 | Null descriptor (required, zeros) |
| 1 | Kernel code (64-bit, ring 0) |
| 2 | Kernel data (ring 0) |
| 3 | User code (64-bit, ring 3) |
| 4 | User data (ring 3) |
| 5 | (Often) 32-bit user code, for compatibility mode apps |
| 6-7 | [TSS](#TSS) descriptor (16 bytes, so it takes two slots) |

#### 32-bit vs 64-bit

| | 32-bit protected mode | 64-bit long mode |
|---|---|---|
| Base / Limit | Honored (but OSes set them flat) | Ignored for `cs`, `ds`, `es`, `ss` |
| Code mode | `D` bit selects 16/32-bit code | `L` bit selects 64-bit code vs 32-bit compatibility code |
| Privilege rings | Yes | Yes |
| [TSS](#TSS) | Yes (could do hardware task switching) | Yes (only holds stack pointers) |
| Thread-local data | GDT entry with a non-zero base, selected via `gs` (Linux) | `fs`/`gs` bases set through MSRs, not the GDT |
| Restricts memory access | Yes (but OSes set them flat) | No (ignored) |

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

### TSS

The Task State Segment is a structure in memory, referenced by a descriptor in the [GDT](#gdt).
Its most important job on modern systems is holding the kernel stack pointer the CPU switches to when moving from ring 3 to ring 0 (for example on an interrupt).

- **32-bit**: also holds a full copy of the CPU state, which was used for hardware task switching. Modern OSes don't use that feature and only use the stack fields (`ss0:esp0`).
- **64-bit**: hardware task switching was removed. It only holds the stack pointers for each ring (`rsp0`-`rsp2`) ([IST](#IST)) and an I/O permission bitmap.

### IST

The IST are separate stacks for specific interrupts, like double faults.

## References

- **nanobyte** - [Building an OS - 1 - Hello world](https://www.youtube.com/watch?v=9t-SPC7Tczc) 3:46-4:24
- **nanobyte** - [Part 2-1: Boot Protocol & Bootloader Architecture](https://nanobyte.dev/building-an-os/2-1-boot-protocol/#for-x86-64)
