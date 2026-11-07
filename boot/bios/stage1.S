.code16
.global stage1_start 		# Export symbol

.equ BIOS_VIDEO_INT, 0x10	# Location of the BIOS video interrupt handler, which is the video services routine
.equ TTY_OUTPUT,     0x0e	# Value to signify to output tty characters to the BIOS video interrupt handler, stored in `ah`

.macro putc ch
    movb \ch, %al			# Move the character to the lower half of ax (\ch tells the assembler it's not a symbol, but an argument from the macro)
    int  $BIOS_VIDEO_INT	# Call the interrupt handler at BIOS_VIDEO_INT, which reads `ah` on what to do in this case TTY_OUTPUT and `al` on what to output
.endm

.section .text
stage1_start:
    movb $TTY_OUTPUT, %ah	# Set `ah` to TTY_OUTPUT mode for the intterupt handler

    putc $'H'
    putc $'e'
    putc $'l'
    putc $'l'
    putc $'o'

1:  hlt						# Halt
    jmp 1b					# Jump to nearest 1 (backwards), because the CPU can sometimes come back from halt
