; Nebo Console bounded ring queues — MF042 headless infrastructure
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/queues/console_queue.inc"

global nebo_console_queue_init
global nebo_console_queue_validate
global nebo_console_queue_enqueue
global nebo_console_queue_dequeue
global nebo_console_queue_peek
global nebo_console_queue_depth
global nebo_console_queue_state_hash

section .text

; queue_init(queue*, buffer*, capacity, item_size, flags)
nebo_console_queue_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    test r12, r12
    jz .init_invalid
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_CONSOLE_QUEUE_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .init_invalid
    test r14, r14
    jz .init_invalid
    cmp r14, NEBO_CONSOLE_MAX_QUEUED_COMMANDS
    ja .init_limit
    cmp r15, NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
    jne .init_invalid
    mov rax, r14
    shl rax, 6
    shr rax, 6
    cmp rax, r14
    jne .init_limit
    mov rdi, r13
    xor eax, eax
    mov rcx, r14
    shl rcx, 3
    rep stosq
    mov [r12+NEBO_CONSOLE_QUEUE_BUFFER_PTR_OFFSET], r13
    mov [r12+NEBO_CONSOLE_QUEUE_CAPACITY_OFFSET], r14
    mov [r12+NEBO_CONSOLE_QUEUE_ITEM_SIZE_OFFSET], r15
    mov qword [r12+NEBO_CONSOLE_QUEUE_HEAD_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_QUEUE_TAIL_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET], 0
    or rbx, NEBO_CONSOLE_QUEUE_FLAG_INITIALIZED
    mov [r12+NEBO_CONSOLE_QUEUE_FLAGS_OFFSET], rbx
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .init_done
.init_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .init_done
.init_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; queue_validate(queue*)
nebo_console_queue_validate:
    test rdi, rdi
    jz .validate_invalid
    mov rax, [rdi+NEBO_CONSOLE_QUEUE_FLAGS_OFFSET]
    test rax, NEBO_CONSOLE_QUEUE_FLAG_INITIALIZED
    jz .validate_state
    mov rax, [rdi+NEBO_CONSOLE_QUEUE_BUFFER_PTR_OFFSET]
    test rax, rax
    jz .validate_invalid
    mov rax, [rdi+NEBO_CONSOLE_QUEUE_CAPACITY_OFFSET]
    test rax, rax
    jz .validate_invalid
    cmp rax, NEBO_CONSOLE_MAX_QUEUED_COMMANDS
    ja .validate_invalid
    cmp qword [rdi+NEBO_CONSOLE_QUEUE_ITEM_SIZE_OFFSET], NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
    jne .validate_state
    mov rcx, [rdi+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    cmp rcx, rax
    ja .validate_state
    mov rcx, [rdi+NEBO_CONSOLE_QUEUE_HEAD_OFFSET]
    cmp rcx, rax
    jae .validate_state
    mov rcx, [rdi+NEBO_CONSOLE_QUEUE_TAIL_OFFSET]
    cmp rcx, rax
    jae .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; queue_enqueue(queue*, descriptor*)
nebo_console_queue_enqueue:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .enqueue_invalid
    mov rdi, r12
    call nebo_console_queue_validate
    test eax, eax
    jnz .enqueue_done
    mov r14, [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    mov r15, [r12+NEBO_CONSOLE_QUEUE_CAPACITY_OFFSET]
    cmp r14, r15
    jae .enqueue_full
    mov rbx, [r12+NEBO_CONSOLE_QUEUE_TAIL_OFFSET]
    mov rdi, [r12+NEBO_CONSOLE_QUEUE_BUFFER_PTR_OFFSET]
    mov rax, rbx
    shl rax, 6
    add rdi, rax
    mov rsi, r13
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep movsq
    inc rbx
    cmp rbx, r15
    jb .enqueue_tail_ready
    xor ebx, ebx
.enqueue_tail_ready:
    mov [r12+NEBO_CONSOLE_QUEUE_TAIL_OFFSET], rbx
    inc qword [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    inc qword [r12+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .enqueue_done
.enqueue_full:
    mov eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jmp .enqueue_done
.enqueue_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.enqueue_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; queue_dequeue(queue*, out_descriptor*)
nebo_console_queue_dequeue:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .dequeue_invalid
    mov rdi, r13
    xor eax, eax
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov rdi, r12
    call nebo_console_queue_validate
    test eax, eax
    jnz .dequeue_done
    cmp qword [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    je .dequeue_empty
    mov rbx, [r12+NEBO_CONSOLE_QUEUE_HEAD_OFFSET]
    mov r15, [r12+NEBO_CONSOLE_QUEUE_BUFFER_PTR_OFFSET]
    mov rax, rbx
    shl rax, 6
    add r15, rax
    mov rsi, r15
    mov rdi, r13
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep movsq
    mov rdi, r15
    xor eax, eax
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep stosq
    inc rbx
    mov r14, [r12+NEBO_CONSOLE_QUEUE_CAPACITY_OFFSET]
    cmp rbx, r14
    jb .dequeue_head_ready
    xor ebx, ebx
.dequeue_head_ready:
    mov [r12+NEBO_CONSOLE_QUEUE_HEAD_OFFSET], rbx
    dec qword [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .dequeue_done
.dequeue_empty:
    mov eax, NEBO_CONSOLE_STATUS_QUEUE_EMPTY
    jmp .dequeue_done
.dequeue_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.dequeue_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; queue_peek(queue*, out_descriptor*)
nebo_console_queue_peek:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .peek_invalid
    mov rdi, r13
    xor eax, eax
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov rdi, r12
    call nebo_console_queue_validate
    test eax, eax
    jnz .peek_done
    cmp qword [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    je .peek_empty
    mov rbx, [r12+NEBO_CONSOLE_QUEUE_HEAD_OFFSET]
    mov rsi, [r12+NEBO_CONSOLE_QUEUE_BUFFER_PTR_OFFSET]
    mov rax, rbx
    shl rax, 6
    add rsi, rax
    mov rdi, r13
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep movsq
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .peek_done
.peek_empty:
    mov eax, NEBO_CONSOLE_STATUS_QUEUE_EMPTY
    jmp .peek_done
.peek_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.peek_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; queue_depth(queue*) -> RAX, zero for invalid queue.
nebo_console_queue_depth:
    test rdi, rdi
    jz .depth_zero
    mov rax, [rdi+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    ret
.depth_zero:
    xor eax, eax
    ret

; Canonical pointer-free FNV-1a hash over queue metadata and FIFO contents.
nebo_console_queue_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov rdi, r12
    call nebo_console_queue_validate
    test eax, eax
    jnz .hash_invalid
    mov eax, NEBO_CONSOLE_QUEUE_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_CONSOLE_QUEUE_CAPACITY_OFFSET]
    call .hash_qword
    mov rdx, [r12+NEBO_CONSOLE_QUEUE_ITEM_SIZE_OFFSET]
    call .hash_qword
    mov rdx, [r12+NEBO_CONSOLE_QUEUE_HEAD_OFFSET]
    call .hash_qword
    mov rdx, [r12+NEBO_CONSOLE_QUEUE_TAIL_OFFSET]
    call .hash_qword
    mov rdx, [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    call .hash_qword
    mov rdx, [r12+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    call .hash_qword
    mov rdx, [r12+NEBO_CONSOLE_QUEUE_FLAGS_OFFSET]
    call .hash_qword
    mov r13, [r12+NEBO_CONSOLE_QUEUE_BUFFER_PTR_OFFSET]
    mov r14, [r12+NEBO_CONSOLE_QUEUE_HEAD_OFFSET]
    mov r15, [r12+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
.hash_item_loop:
    test r15, r15
    jz .hash_finish
    mov rbx, r14
    shl rbx, 6
    add rbx, r13
    xor ecx, ecx
.hash_item_qwords:
    mov rdx, [rbx+rcx*8]
    call .hash_qword
    inc ecx
    cmp ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    jb .hash_item_qwords
    inc r14
    cmp r14, [r12+NEBO_CONSOLE_QUEUE_CAPACITY_OFFSET]
    jb .hash_item_next
    xor r14d, r14d
.hash_item_next:
    dec r15
    jmp .hash_item_loop
.hash_finish:
    test eax, eax
    jnz .hash_done
    mov eax, 1
    jmp .hash_done
.hash_invalid:
    xor eax, eax
.hash_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.hash_qword:
    push rcx
    mov ecx, 8
.hash_byte:
    movzx esi, dl
    xor eax, esi
    imul eax, eax, NEBO_CONSOLE_QUEUE_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .hash_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
