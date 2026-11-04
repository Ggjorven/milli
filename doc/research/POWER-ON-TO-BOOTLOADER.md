# Power on to bootloader

This is a very simple still high-level overview of how a computer starts

## Table of contents

- [Boot](#boot)
  - [Legacy boot (BIOS)](#Legacy-boot-BIOS)
  - [UEFI](#UEFI)
- [Glossary](#Glossary)
  - [Reset vector](#Reset-vector)
  - [Mapping memory](#Mapping-memory)
  - [16-bit real mode](#16-bit-real-mode)
  - [32-bit protected mode](#32-bit-protected-mode)
  - [64-bit long mode](#64-bit-long-mode)
  - [GDT](#GDT)
  - [Paging](#Paging)
  - [TSS](#TSS)
  - [IST](#IST)
  - [NVRAM](#NVRAM)
  - [GPT](#GPT)
- [References](#references)

## Boot

This will describe the most general steps of how a PC starts from power-on.

> [!NOTE]
> A PC can either have BIOS boot or UEFI, not both. But most UEFI boards still add a CSM module which can emulate BIOS booting.

### Legacy boot (BIOS)

1. The CPU starts executing at the [reset vector](#Reset-vector) (ex. `0xFFFFFFF0` on x86). The chipset [maps](#Mapping-memory) this to the firmware flash chip on the motherboard.

2. The BIOS initializes the RAM and may then copy itself into it (for speed).

3. Then the BIOS:
    - Initializes the remaining hardware
    - Runs some tests (POST = power-on self test)

4. The BIOS goes through the devices in the configured boot order (e.g. Disk A, Disk B, USB, CD/DVD, Network). For each device it:
    - Loads the first sector (512 bytes) to memory at `0x7C00`.
    - Checks for the boot signature `0x55 0xAA` at offsets 510 and 511.
    - If the signature is missing, tries the next device.

5. If the signature is found, the BIOS jumps to `0x7C00` and starts executing that sector (in [16-bit real mode](#16-bit-real-mode)).

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

1. The CPU starts executing at the [reset vector](#Reset-vector) (ex. `0xFFFFFFF0` on x86). The chipset [maps](#Mapping-memory) this to the firmware flash chip on the motherboard.

2. The firmware initializes the RAM and may then copy itself into it (for speed).

3. The firmware then does:
    - Switch from [16-bit real mode](#16-bit-real-mode) to [64-bit long mode](#64-bit-long-mode). It also enables [paging](#paging) and creates a flat [GDT](#gdt).
    - It initializes the remaning hardware and loads its drivers.

4. It reads the boot entries from [NVRAM](#NVRAM), each entry holds a path to an `.efi` file. For example:
    - **Windows**: `\EFI\Microsoft\Boot\bootmgfw.efi`
    - **Fedora**: `\EFI\fedora\shimx64.efi` (loads `grubx64.efi`)

5. These files live on the EFI System Partition (ESP) which is a small FAT (usually FAT32) partition on a [GPT](#GPT) disk. This partition is shared by all installed operating systems. The firmware contains a FAT driver, so it can read the file by path without any boot sector code.

6. The firmware loads the `.efi` file (a PE/COFF executable, the same format as Windows `.exe` files) into memory and calls its entry point. This is the bootloader.

7. If no boot entry works (or on removable media like a USB stick), the firmware falls back to a default path: `\EFI\BOOT\BOOTX64.EFI` (on x86-64).

8. With **Secure Boot** enabled, the firmware first verifies the signature of the `.efi` file against its trusted keys, and refuses to run it if the check fails.

## Glossary

### Reset vector

The reset vector is the address where a CPU starts fetching its first instruction from after power-on or reset.
It's hardwired into the CPU and differs per architecture. This is so the very first instruction has a known place to come from.
Whoever builds the board puts the firmware at that location.

### Mapping memory

Mapping memory means that when the CPU reads from the mapped address, the read doesn’t go to RAM.
A piece of hardware (the chipset) intercepts the read and answers with bytes from the mapped address instead (maybe flash memory instead of RAM).

### 16-bit real mode

This is what the CPU starts in for compatibility with [the original 8086](https://en.wikipedia.org/wiki/Intel_8086). It has:
- 16 bit registers.
- Addresses are segment:offset, giving access to only about 1 MB of RAM.
- No memory protection, no privilege levels and no virtual memory.
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

[Paging](#paging) uses virtual addresses and uses multiple levels of indices into tables.
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

> [!NOTE]
> This is the GDT for the bootloader, the OS/kernel usually creates its own.

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

The CPU reads the code segment descriptors (selected by `cs`) to learn whether to run 64-bit code and at which privilege level.

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

- **32-bit**: also holds a full copy of the CPU state, which is used for hardware task switching. (Modern OSes don't use that feature and only use the stack fields (`ss0:esp0`).)
- **64-bit**: hardware task switching was removed. It only holds the stack pointers for each ring (`rsp0`-`rsp2`) ([IST](#IST)) and an I/O permission bitmap.

### IST

The IST are separate stacks for specific interrupts, like double faults.

### NVRAM

NVRAM is a small persistent storage area. Most often a region on the firmware flash chip that keeps firmware settings and UEFI variables (boot entries, boot order, Secure Boot keys).
On older BIOS systems the equivalent was CMOS RAM kept alive by the motherboard's coin cell battery.

### GPT

[GPT](https://en.wikipedia.org/wiki/GUID_Partition_Table) is a type of partition table a disk can use. Other examples are [MBR](https://en.wikipedia.org/wiki/Master_boot_record).
A partition table is a table that describes all partitions on a disk. A high level overview:
```
Disk
 ├── Partition table (GPT or MBR)
 │    ├── Partition 1 -> filesystem: FAT32
 │    ├── Partition 2 -> filesystem: NTFS
 │    └── Partition 3 -> filesystem: ext4
 ```

## References

- **nanobyte** - [Building an OS - 1 - Hello world](https://www.youtube.com/watch?v=9t-SPC7Tczc) 3:46-4:24
- **nanobyte** - [Part 2-1: Boot Protocol & Bootloader Architecture](https://nanobyte.dev/building-an-os/2-1-boot-protocol/#for-x86-64)
