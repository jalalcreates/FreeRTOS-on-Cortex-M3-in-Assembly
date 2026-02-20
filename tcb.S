.include "tcb.inc"
.section .bss
.align 4

.global tcb_task1
.global tcb_task2
.global current_tcb


tcb_task1:
    .space TCB_SIZE

tcb_task2:
    .space TCB_SIZE

current_tcb:
    .word 0