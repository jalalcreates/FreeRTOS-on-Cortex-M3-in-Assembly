
.equ systick_csr, 0xE000E010
.equ systick_rvr, 0xE000E014
.equ systick_cvr, 0xE000E018
.equ systick_calib, 0xE000E01c
.equ timeout, 100000

.section .vectors
vector_table:
    .word 0x20002000
    .word reset_handler
    .org 0x38
    .word pendsv_handler
    .org 0x3c
    .word systick_handler
    .zero 400


.section .text
.align 1
.thumb_func
.type reset_handler, %function 
reset_handler:

    ldr r0, =_task1_stack_top
    msr psp, r0
    
    ldr r0, =_task2_stack_top
    sub r0, r0, #32
    
    ldr r1, =task2_code
    str r1, [r0, #24]
    
    ldr r1, =0x01000000
    str r1, [r0, #28]
    
    sub r0, r0, #32
    mov r1, #0
    str r1, [r0, #0]        
    str r1, [r0, #4]        
    str r1, [r0, #8]        
    str r1, [r0, #12]       
    str r1, [r0, #16]       
    str r1, [r0, #20]       
    str r1, [r0, #24]       
    str r1, [r0, #28]       

    ldr r1, =task2_psp
    str r0, [r1]

    ldr r0, =systick_csr
    ldr r1, =systick_rvr
    ldr r2, =systick_cvr
    ldr r3, =timeout

    str r3, [r1]
    mov r3, #0x00
    str r3, [r2]
    mov r3, #0x7
    str r3, [r0]

    mov r0, #0x2
    msr CONTROL, r0
    isb
    cpsie i

    ldr r0, =0xE000ED20
    ldr r1, =0xFF000000
    str r1, [r0]

    ldr r1, =0x00FF0000
    str r1, [r0]

    mov r0, #0x00
    b task1_code

.section .text
task1_code:
    add r5, r5, #1
    b task1_code
.section .text
task2_code:
    sub r6, r6, #1
    b task2_code

.section .text
.align 1
.syntax unified
.thumb
.thumb_func
.type systick_handler, %function

systick_handler:
    ldr r0, =0xE000ED04
    ldr r1, =0x10000000
    str r1, [r0]
    bx lr
    

.section .text
.align 4
.thumb
.thumb_func
.syntax unified
.type pendsv_handler, %function

pendsv_handler:
    mrs r0, psp
    stmdb r0!, {r4-r11}
    ldr r1, =current_task
    ldr r2, [r1]
    cbz r2, save_task1
    b save_task2

    save_task2:
        ldr r3, =task2_psp
        str r0, [r3]
        mov r2, #0
        str r2, [r1]
        b switch_tasks

    save_task1:
        ldr r3, =task1_psp
        str r0, [r3]
        mov r2, #1
        str r2, [r1]
        b switch_tasks

    switch_tasks:
        cbz r2, load_task1
        b load_task2

    load_task2:
    ldr r3, =task2_psp
    ldr r0, [r3]
    b restore_context

load_task1:
    ldr r3, =task1_psp
    ldr r0, [r3]

restore_context:
    ldmia r0!, {r4-r11}
    msr psp, r0
    bx lr

.section .bss
.align 4

task1_stack:
.space 1024
_task1_stack_top:

task2_stack:
.space 1024
_task2_stack_top:

.align 4
current_task:
.word 0

task1_psp:
.word 0

task2_psp:
.word 0

