OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(stage2_main)

SECTIONS
{
    . = 0x8000; /* Convential BIOS second stage address, because stage1 doesn't load it yet */

    .text ALIGN(16) : { *(.text .text.*) }
    .rodata ALIGN(16) : { *(.rodata .rodata.*) }
    .data ALIGN(16) : { *(.data .data.*) }
    .bss ALIGN(16) (NOLOAD) : { *(.bss .bss.*) *(COMMON) }

    /DISCARD/ : { *(.comment) *(.note .note.*) *(.eh_frame*) }
}
