
.include "tcb.inc"
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
.syntax unified
.type reset_handler, %function 
reset_handler:

    ldr r0, =_task1_stack_top
    ldr r1, =tcb_task1
    str r0, [r1, #TCB_PSP]
    msr psp, r0

    @fake stack frame for task 2
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

    ldr r1, =tcb_task2
    str r0, [r1,#TCB_PSP]

    @systick registers configuration
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

    @linked list between task1 and task 2
    ldr r0, =tcb_task1
    ldr r1, =tcb_task2
    str r1, [r0, #TCB_NEXT]
    str r1, [r0, #TCB_PREV]
    str r0, [r1, #TCB_NEXT]
    str r0, [r1, #TCB_PREV]

    ldr r2, =tcb_linked_list_head
    str r0, [r2]

    ldr r2, =current_tcb
    str r0, [r2]
    
@blocking task1 for testing code
   @ ldr r0, =tcb_task1
   @ mov r1, #TASK_BLOCKED
   @ str r1, [r0, #TCB_STATE]
   @ mov r1, #1000
   @ str r1, [r0, #TCB_WAKE_TICK]

   @ ldr r0, =tcb_task2
   @ mov r1, #TASK_READY
   @ str r1, [r0, #TCB_STATE]

    @for priority of PendSV and systick
    ldr r0, =0xE000ED20
    ldr r1, =0xFFFF0000
    str r1, [r0]

    mov r1, #0x0
    cpsie i

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
    ldr r0, =tick_count
    ldr r1, [r0]
    add r1, r1, #1
    str r1, [r0]

    ldr r2, =tcb_linked_list_head
    ldr r0, [r2]
    mov r4, r0 @remember where started
    
    check_if_blocked: 
        ldr r2, [r0, #TCB_STATE]
        cmp r2, #TASK_BLOCKED
        beq compare_wake_tick
        ldr r0, [r0, #TCB_NEXT]
        cmp r4, r0
        beq fire_PendSV
        b check_if_blocked

    compare_wake_tick:
        ldr r3, [r0, #TCB_WAKE_TICK]
        cmp r1, r3
        bhs make_ready
        ldr r0, [r0, #TCB_NEXT]
        cmp r4, r0
        beq fire_PendSV
        b check_if_blocked
        
    make_ready:
        mov r1, #TASK_READY
        str r1, [r0, #TCB_STATE]
        ldr r0, [r0, #TCB_NEXT]
        cmp r4, r0
        beq fire_PendSV
        b check_if_blocked
    
    fire_PendSV:
    @firing PendSV handler through ICSR
        ldr r0, =0xE000ED04
        ldr r1, =0x10000000
        str r1, [r0]
        bx lr

.global delay
.section .text
.align 4
.thumb
.syntax unified
.type delay, %function
delay :
    cpsid i

    ldr r1, =tick_count
    ldr r2, [r1]

    ldr r3, =current_tcb
    ldr r4, [r3]
    add r2, r2, r0 @r2 = tick_count + delay
    str r2, [r4, #TCB_WAKE_TICK]
    
    mov r5, #TASK_BLOCKED
    str r5, [r4, #TCB_STATE]
    
@fire PendSV
    ldr r0, =0xE000ED04
    ldr r1, =0x10000000
    str r1, [r0]

    cpsie i
    bx lr

.section .text
.align 4
.thumb
.thumb_func
.syntax unified
.type pendsv_handler, %function

pendsv_handler:
    ldr r1, =current_tcb
    ldr r2, [r1]
    mrs r0, psp
    stmdb r0!, {r4-r11}

    str r0, [r2,#TCB_PSP] @for updating the current task's PSP

    ldr r3, [r2, #TCB_NEXT]
    mov r4, r3 @remember where started
    search_next_ready_task:
        ldr r0, [r3, #TCB_STATE]
        cmp r0, #TASK_READY
        beq restore_context
        ldr r3, [r3, #TCB_NEXT]
        cmp r3, r4
        beq no_ready_task_found
        b search_next_ready_task

    no_ready_task_found:
        mov r3, r2 @stay on current task

    restore_context:    
        str r3, [r1]
        ldr r0, [r3, #TCB_PSP]
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

.global tick_count
tick_count:
    .word 0

