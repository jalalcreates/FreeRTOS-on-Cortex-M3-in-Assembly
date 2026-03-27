.include "mutex.inc"
.include "tcb.inc"

.section .bss
.align 4
.global UART_MUTEX
.global ANY_MUTEX

UART_MUTEX:
    .space MUTEX_SIZE
ANY_MUTEX:
    .space MUTEX_SIZE

.section .text
.align 4
.type mutex_lock, %function
.thumb
.syntax unified
.global mutex_lock

mutex_lock:
@r0 = address of mutex
@r1  = address of tcb 
@r2 = address of mutex linked list head
cpsid i
    ldr r3, [r0]
    mov r4, #0
    cmp r3, r4
    bne check_next
    str r1, [r0]
    cpsie i
    bx lr

    check_next:
        ldr r3, [r0, #MUTEX_WAIT_LIST]
        cmp r3, r4
        bne find_list_end
        str r1, [r0, #MUTEX_WAIT_LIST]
        ldr r3, [r0]
        str r1, [r3, #MUTEX_NEXT]
        str r0, [r1, #MUTEX_WAIT]
        mov r4, #TASK_BLOCKED
        str r4, [r1, #TCB_STATE]
        cpsie i
        bx lr

    find_list_end:
        mov r5, r3 @ save previous value to avoid 0
        ldr r3, [r3, #MUTEX_NEXT]
        cmp r3, r4
        beq add_to_list
        b find_list_end

    add_to_list:
        str r1, [r5, #MUTEX_NEXT]
        mov r4, #TASK_BLOCKED
        str r4, [r1, #MUTEX_WAIT]
        str r4, [r1, #TCB_STATE]
        cpsie i
        bx lr

.section .text
.align 4
.type mutex_unlock, %function
.thumb
.syntax unified
.global mutex_unlock
mutex_unlock:
    @r0 = address of mutex
@r1  = address of tcb 
@r2 = address of mutex linked list head
cpsid i
    ldr r3, [r0, #MUTEX_WAIT_LIST]
    mov r4, #0
    cmp r3, r4
    bne update_mutex
    ldr r5, [r0]
    str r4, [r5, #MUTEX_NEXT]
    str r4, [r0]
    cpsie i
    b fire_PendSV

    update_mutex:
        str r3, [r0]
        str r4, [r1, #MUTEX_NEXT]
        ldr r5, [r0]
        str r4, [r5, #MUTEX_WAIT]
        mov r4, #TASK_READY
        str r4, [r5, #TCB_STATE]
        ldr r4, [r5, #MUTEX_NEXT]
        str r4, [r0, #MUTEX_WAIT_LIST] @can be 0 or an address
        cpsie i
        b fire_PendSV
    