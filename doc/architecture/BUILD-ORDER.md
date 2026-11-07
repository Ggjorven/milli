# Build Order

milli produces a raw disk image (`.img`) for the selected boot path, this image is the complete virtual disk presented to QEMU.

## 1. Bootloader

First the bootloader is built, but this differs per boot platform.

### BIOS (Legacy boot)

> [!NOTE]
> BIOS / Legacy boot only supports x86 architectures.

The BIOS bootloader is built in 2 stages:
- Stage 1:
    - 16-bit real mode
    - Fully written in assembly
- Stage 2:
    - Transition to 64-bit
    - Load the kernel, initrd, etc...

Both are built as ELF binaries and then stripped of metadata down to a `.bin` file.

### UEFI

The UEFI bootloader is also first built as an ELF binary. It is then converted to EFI.

## 2. Initrd

Secondly CMake creates `initrd.cpio`, a [`newc` CPIO archive](https://man.archlinux.org/man/cpio.5.en#New_ASCII_Format) from the files under `initrd/root/`.
The archive is not interpreted by either bootloader it is copied into the disk image and loaded into memory for the kernel.

Both BIOS and UEFI use this same initrd archive. It is stored in the FAT32 filesystem under the name `/BOOT/INITRD.CPI`.

> [!NOTE]
> CPIO is used because it is a simple archive format which can combine multiple files and it can be easily parsed.

## 3. Kernel

Thirdly the kernel is built as a freestanding ELF executable.
It is not converted to a flat binary. This keeps the ELF program headers that tell each loader which segments to map, where to place them, and how much memory to reserve for [BSS](#bss).

## Combining

Finally all of the freestanding binaries and executables are combined into a disk image which can be used with QEMU.
This is again dependant on which boot platform is used.

### BIOS (Legacy boot)

The BIOS image uses a GPT partition table with a protective MBR. Stage 1 occupies the
protective MBR's boot-code area, while the FAT32 partition starts at sector 2048:

| Sector | Contents |
| -- | -- |
| `0` | Protective MBR: stage-1 code (446 bytes), GPT protective partition & 0x55AA signature |
| `1-2047` | Stage-2 code |
| `2048+` | FAT 32 partition: <br>├── /BOOT/KERNEL.ELF<br>└── /BOOT/INITRD.CPI |

The MBR layout fixes the stage-1 bootstrap area at 446 bytes even though a sector is 512 bytes.
The partition table contains four 16-byte entries (64 bytes), and the boot signature is 2 bytes
(`0x55AA`). The protective entry preserves the GPT partition table, so the available code space is
`512 - (4 * 16) - 2 = 446` bytes.

For the BIOS image, CMake currently does this order:

1. Create a zero-filled `.img` file (by default `64MiB`).
2. Create the GPT partition table and its protective MBR.
3. Format the partition at sector 2048 as FAT32.
4. Copy KERNEL.ELF and INITRD.CPI into that FAT32 filesystem.
5. Write stage 2 at sector 1.
6. Write the first 446 bytes of stage 1 into sector 0.

### UEFI

The UEFI image is a GPT-partitioned disk with one FAT32 EFI System Partition:

```text
GPT EFI System Partition
├── EFI/BOOT/BOOTX64.EFI
├── BOOT/KERNEL.ELF
└── BOOT/INITRD.CPI
```

> [!NOTE]
> The image renames the bootloader to `BOOTX64.EFI` since that is default fallback for UEFI.

> [!NOTE]
> For now the kernel and initrd are on the ESP partition just like the bootloader.
> In the future there may be a seperate ext4 partition (`/boot`) where the kernel and initrd live (just like linux).

For the UEFI image, CMake currently does this order:

1. Create a zero-filled `.img` file (by default `64MiB`).
2. Create a GPT partition table with one EFI System Partition starting at sector 2048.
3. Format that partition as FAT32.
4. Create the `EFI/BOOT` and `BOOT` directories.
5. Convert the UEFI loader ELF to `BOOTX64.EFI` and copy it to `EFI/BOOT/BOOTX64.EFI`.
6. Copy `KERNEL.ELF` and `INITRD.CPI` into the `/BOOT` directory.

## Glossary

### BSS

BSS is the part of a program containing global or static variables that start as zero.

For example:
```c
static unsigned char page_bitmap[1024 * 1024];
static int boot_count;
```

Those variables occupy memory when the kernel runs, but putting one megabyte of zero bytes into the kernel file would waste disk space.
So the ELF file describes them as:
- This segment needs N bytes in memory.
- Only M bytes exist in the file.
- Zero-fill the remaining N - M bytes.
