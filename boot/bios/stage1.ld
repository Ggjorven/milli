OUTPUT_FORMAT(elf32-i386)
OUTPUT_ARCH(i386)
ENTRY(stage1_start)

SECTIONS
{
    . = 0x7c00;

    .text : { *(.text .text.*) }
    .rodata : { *(.rodata .rodata.*) }
    .data : { *(.data .data.*) }
    .bss : { *(.bss .bss.*) *(COMMON) }

    . = 0x7dfe; /* offset 510 */
    .signature : { SHORT(0xaa55) } /* The 2 bytes: 0x55 and 0xaa */

    /DISCARD/ : { *(.comment) *(.note .note.*) }
}
