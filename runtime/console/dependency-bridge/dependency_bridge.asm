; Nebo Console dependency bridge — MF048
bits 64
default rel
%include "runtime/console/dependency-bridge/dependency_bridge.inc"

global nebo_dependency_bridge_init
global nebo_dependency_bridge_validate
global nebo_dependency_bridge_register
global nebo_dependency_bridge_notify_resolved
global nebo_dependency_bridge_state_hash

section .text
nebo_dependency_bridge_init:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rbx, rcx
    test r12, r12
    jz .invalid_no_bridge
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_DEPENDENCY_BRIDGE_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .invalid
    test r14, r14
    jz .invalid
    cmp r14, 4096
    ja .limit
    test rbx, rbx
    jz .invalid
    mov rdi, r13
    xor eax, eax
    mov rcx, r14
    imul rcx, NEBO_DEPENDENCY_CONTINUATION_QWORDS
    cld
    rep stosq
    mov [r12+NEBO_DEPENDENCY_BRIDGE_RECORDS_PTR_OFFSET], r13
    mov [r12+NEBO_DEPENDENCY_BRIDGE_CAPACITY_OFFSET], r14
    mov [r12+NEBO_DEPENDENCY_BRIDGE_OWNER_CONSOLE_HANDLE_OFFSET], rbx
    mov qword [r12+NEBO_DEPENDENCY_BRIDGE_FLAGS_OFFSET], NEBO_DEPENDENCY_BRIDGE_REQUIRED_FLAGS
    xor eax, eax
    jmp .done
.limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .done
.invalid_no_bridge:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_dependency_bridge_validate:
    test rdi, rdi
    jz .invalid
    cmp qword [rdi+NEBO_DEPENDENCY_BRIDGE_RECORDS_PTR_OFFSET], 0
    je .state
    mov rax, [rdi+NEBO_DEPENDENCY_BRIDGE_CAPACITY_OFFSET]
    test rax, rax
    jz .state
    cmp [rdi+NEBO_DEPENDENCY_BRIDGE_COUNT_OFFSET], rax
    ja .state
    cmp qword [rdi+NEBO_DEPENDENCY_BRIDGE_OWNER_CONSOLE_HANDLE_OFFSET], 0
    je .state
    mov rax, [rdi+NEBO_DEPENDENCY_BRIDGE_FLAGS_OFFSET]
    and eax, NEBO_DEPENDENCY_BRIDGE_REQUIRED_FLAGS
    cmp eax, NEBO_DEPENDENCY_BRIDGE_REQUIRED_FLAGS
    jne .state
    xor eax, eax
    ret
.state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; register(bridge*, continuation_id, compiler_pending_id, binding_id, source_order, function_id)
nebo_dependency_bridge_register:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov [rsp], r8
    mov [rsp+8], r9
    mov rdi, r12
    call nebo_dependency_bridge_validate
    test eax, eax
    jnz .done
    test r13, r13
    jz .invalid
    test r14, r14
    jz .invalid
    test r15, r15
    jz .invalid
    cmp qword [rsp], 0
    je .invalid
    cmp qword [rsp+8], 0
    je .invalid
    mov rbx, [r12+NEBO_DEPENDENCY_BRIDGE_COUNT_OFFSET]
    xor rcx, rcx
    mov rdx, [r12+NEBO_DEPENDENCY_BRIDGE_RECORDS_PTR_OFFSET]
.dup_loop:
    cmp rcx, rbx
    jae .capacity
    imul rax, rcx, NEBO_DEPENDENCY_CONTINUATION_SIZE
    add rax, rdx
    cmp [rax+NEBO_DEPENDENCY_CONTINUATION_ID_OFFSET], r13
    je .duplicate
    inc rcx
    jmp .dup_loop
.capacity:
    cmp rbx, [r12+NEBO_DEPENDENCY_BRIDGE_CAPACITY_OFFSET]
    jae .limit
    imul rax, rbx, NEBO_DEPENDENCY_CONTINUATION_SIZE
    add rax, rdx
    mov rdi, rax
    xor eax, eax
    mov ecx, NEBO_DEPENDENCY_CONTINUATION_QWORDS
    cld
    rep stosq
    imul rax, rbx, NEBO_DEPENDENCY_CONTINUATION_SIZE
    add rax, rdx
    mov [rax+NEBO_DEPENDENCY_CONTINUATION_ID_OFFSET], r13
    mov [rax+NEBO_DEPENDENCY_COMPILER_PENDING_ID_OFFSET], r14
    mov [rax+NEBO_DEPENDENCY_BINDING_ID_OFFSET], r15
    mov rdx, [rsp+8]
    mov [rax+NEBO_DEPENDENCY_FUNCTION_ID_OFFSET], rdx
    mov rdx, [r12+NEBO_DEPENDENCY_BRIDGE_OWNER_CONSOLE_HANDLE_OFFSET]
    mov [rax+NEBO_DEPENDENCY_CONSOLE_HANDLE_OFFSET], rdx
    mov rdx, [rsp]
    mov [rax+NEBO_DEPENDENCY_SOURCE_ORDER_OFFSET], rdx
    mov dword [rax+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_WAITING
    mov dword [rax+NEBO_DEPENDENCY_FLAGS_OFFSET], NEBO_DEPENDENCY_REQUIRED_FLAGS
    inc qword [r12+NEBO_DEPENDENCY_BRIDGE_COUNT_OFFSET]
    xor eax, eax
    jmp .done
.duplicate:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .done
.limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; notify_resolved(bridge*, compiler_pending_id, binding_id, out_activation_count*)
nebo_dependency_bridge_notify_resolved:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jz .invalid
    mov qword [r15], 0
    mov rdi, r12
    call nebo_dependency_bridge_validate
    test eax, eax
    jnz .done
    test r13, r13
    jz .invalid
    test r14, r14
    jz .invalid
.outer:
    mov qword [rsp], 0
    mov qword [rsp+8], -1
    xor rbx, rbx
.scan:
    cmp rbx, [r12+NEBO_DEPENDENCY_BRIDGE_COUNT_OFFSET]
    jae .activate
    imul rax, rbx, NEBO_DEPENDENCY_CONTINUATION_SIZE
    add rax, [r12+NEBO_DEPENDENCY_BRIDGE_RECORDS_PTR_OFFSET]
    cmp dword [rax+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_WAITING
    jne .next
    cmp [rax+NEBO_DEPENDENCY_COMPILER_PENDING_ID_OFFSET], r13
    jne .next
    cmp [rax+NEBO_DEPENDENCY_BINDING_ID_OFFSET], r14
    jne .next
    mov rdx, [rax+NEBO_DEPENDENCY_SOURCE_ORDER_OFFSET]
    cmp rdx, [rsp+8]
    jae .next
    mov [rsp], rax
    mov [rsp+8], rdx
.next:
    inc rbx
    jmp .scan
.activate:
    mov rax, [rsp]
    test rax, rax
    jz .complete
    mov dword [rax+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_ACTIVATED
    inc qword [r12+NEBO_DEPENDENCY_BRIDGE_SEQUENCE_OFFSET]
    mov rdx, [r12+NEBO_DEPENDENCY_BRIDGE_SEQUENCE_OFFSET]
    mov [rax+NEBO_DEPENDENCY_ACTIVATION_SEQUENCE_OFFSET], rdx
    inc qword [r12+NEBO_DEPENDENCY_BRIDGE_ACTIVATED_COUNT_OFFSET]
    inc qword [r15]
    jmp .outer
.complete:
    lea rsi, [r12+NEBO_DEPENDENCY_BRIDGE_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_dependency_bridge_state_hash
    xor eax, eax
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_dependency_bridge_state_hash:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .invalid
    test r13, r13
    jz .invalid
    mov eax, NEBO_DEPENDENCY_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_DEPENDENCY_BRIDGE_COUNT_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_DEPENDENCY_BRIDGE_ACTIVATED_COUNT_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_DEPENDENCY_BRIDGE_SEQUENCE_OFFSET]
    call .mix
    xor rbx, rbx
    mov r14, [r12+NEBO_DEPENDENCY_BRIDGE_RECORDS_PTR_OFFSET]
.loop:
    cmp rbx, [r12+NEBO_DEPENDENCY_BRIDGE_COUNT_OFFSET]
    jae .commit
    imul rcx, rbx, NEBO_DEPENDENCY_CONTINUATION_SIZE
    add rcx, r14
    mov rdx, [rcx+NEBO_DEPENDENCY_CONTINUATION_ID_OFFSET]
    call .mix
    mov edx, [rcx+NEBO_DEPENDENCY_STATE_OFFSET]
    call .mix
    mov rdx, [rcx+NEBO_DEPENDENCY_ACTIVATION_SEQUENCE_OFFSET]
    call .mix
    inc rbx
    jmp .loop
.commit:
    mov [r13], rax
    mov [r12+NEBO_DEPENDENCY_BRIDGE_STATE_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.mix:
    push rcx
    mov ecx, 8
.mix_byte:
    xor al, dl
    imul eax, eax, NEBO_DEPENDENCY_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
