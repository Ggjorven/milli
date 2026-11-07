.code16
.global stage1_start	; Export symbol

.section .text

stage1_start: 			; Must be first in the file
	cli					; Clear interrupt flag
1:
    hlt					; Halt
    jmp 1b				; Jump to nearest 1 (backwards)
