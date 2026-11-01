.code16
.global stage1_start

.section .text
stage1_start:
    cli
1:
    hlt
    jmp 1b
