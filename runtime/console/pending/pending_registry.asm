; Nebo Console PendingRegistry producer base — MF046
bits 64
default rel

%include "runtime/console/pending/pending_registry.inc"

global nebo_pending_handle_pack
global nebo_pending_handle_unpack
global nebo_pending_handle_is_valid
global nebo_pending_registry_init
global nebo_pending_registry_validate
global nebo_pending_registry_get
global nebo_pending_registry_state_hash

extern nebo_console_handle_pack
extern nebo_console_handle_unpack
extern nebo_console_handle_is_valid

section .text
nebo_pending_handle_pack:
    jmp nebo_console_handle_pack
nebo_pending_handle_unpack:
    jmp nebo_console_handle_unpack
nebo_pending_handle_is_valid:
    jmp nebo_console_handle_is_valid

nebo_pending_registry_init:
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
    jz .init_invalid_no_registry
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_PENDING_REGISTRY_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .init_invalid
    test r14, r14
    jz .init_invalid
    cmp r14, NEBO_INPUT_MAX_PER_CONSOLE
    ja .init_limit
    test rbx, rbx
    jz .init_invalid
    mov rdi, r13
    xor eax, eax
    mov rcx, r14
    imul rcx, NEBO_PENDING_RECORD_QWORDS
    cld
    rep stosq
    xor edx, edx
.init_generation_loop:
    cmp rdx, r14
    jae .init_commit
    imul rax, rdx, NEBO_PENDING_RECORD_SIZE
    mov dword [r13+rax+NEBO_PENDING_RECORD_GENERATION_OFFSET], 1
    inc rdx
    jmp .init_generation_loop
.init_commit:
    mov [r12+NEBO_PENDING_REGISTRY_RECORDS_PTR_OFFSET], r13
    mov [r12+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET], r14
    mov [r12+NEBO_PENDING_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], rbx
    mov qword [r12+NEBO_PENDING_REGISTRY_FLAGS_OFFSET], NEBO_PENDING_REGISTRY_REQUIRED_FLAGS
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_ERROR_OFFSET], NEBO_PENDING_ERROR_NONE
    mov eax, NEBO_PENDING_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET], rax
    lea rsi, [r12+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_pending_registry_state_hash
    jmp .init_done
.init_limit:
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_ERROR_OFFSET], NEBO_PENDING_ERROR_LIMIT
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .init_done
.init_invalid:
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_ERROR_OFFSET], NEBO_PENDING_ERROR_BAD_ARGUMENT
.init_invalid_no_registry:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_pending_registry_validate:
    test rdi, rdi
    jz .validate_invalid
    cmp qword [rdi+NEBO_PENDING_REGISTRY_RECORDS_PTR_OFFSET], 0
    je .validate_invalid
    mov rax, [rdi+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    test rax, rax
    jz .validate_invalid
    cmp rax, NEBO_INPUT_MAX_PER_CONSOLE
    ja .validate_state
    cmp [rdi+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], rax
    ja .validate_state
    cmp qword [rdi+NEBO_PENDING_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], 0
    je .validate_state
    mov rax, [rdi+NEBO_PENDING_REGISTRY_FLAGS_OFFSET]
    and eax, NEBO_PENDING_REGISTRY_REQUIRED_FLAGS
    cmp eax, NEBO_PENDING_REGISTRY_REQUIRED_FLAGS
    jne .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

nebo_pending_registry_get:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx
    test rbx, rbx
    jz .get_invalid
    mov qword [rbx], 0
    mov rdi, r12
    call nebo_pending_registry_validate
    test eax, eax
    jnz .get_done
    test r13, r13
    jz .get_handle
    mov eax, r13d
    cmp rax, [r12+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jae .get_handle
    mov rdx, r13
    shr rdx, NEBO_PENDING_HANDLE_GENERATION_SHIFT
    test edx, edx
    jz .get_handle
    imul rax, rax, NEBO_PENDING_RECORD_SIZE
    add rax, [r12+NEBO_PENDING_REGISTRY_RECORDS_PTR_OFFSET]
    cmp dword [rax+NEBO_PENDING_RECORD_GENERATION_OFFSET], edx
    jne .get_handle
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    jne .get_handle
    cmp [rax+NEBO_PENDING_RECORD_HANDLE_OFFSET], r13
    jne .get_handle
    mov [rbx], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .get_done
.get_handle:
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov qword [r12+NEBO_PENDING_REGISTRY_LAST_ERROR_OFFSET], NEBO_PENDING_ERROR_HANDLE_INVALID
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    jmp .get_done
.get_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.get_done:
    pop r13
    pop r12
    pop rbx
    ret

nebo_pending_registry_state_hash:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .hash_invalid
    test r13, r13
    jz .hash_invalid
    mov eax, NEBO_PENDING_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    call .mix_qword
    mov rdx, [r12+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET]
    call .mix_qword
    mov rdx, [r12+NEBO_PENDING_REGISTRY_CREATED_COUNT_OFFSET]
    call .mix_qword
    mov rdx, [r12+NEBO_PENDING_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET]
    call .mix_qword
    xor ebx, ebx
    mov r14, [r12+NEBO_PENDING_REGISTRY_RECORDS_PTR_OFFSET]
.hash_loop:
    cmp rbx, [r12+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jae .hash_done
    imul rcx, rbx, NEBO_PENDING_RECORD_SIZE
    add rcx, r14
    cmp dword [rcx+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_FREE
    je .hash_next
    mov edx, [rcx+NEBO_PENDING_RECORD_STATE_OFFSET]
    call .mix_qword
    mov rdx, [rcx+NEBO_PENDING_RECORD_HANDLE_OFFSET]
    call .mix_qword
    mov rdx, [rcx+NEBO_PENDING_RECORD_INPUT_HANDLE_OFFSET]
    call .mix_qword
    mov rdx, [rcx+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET]
    call .mix_qword
    mov rdx, [rcx+NEBO_PENDING_RECORD_BINDING_ID_OFFSET]
    call .mix_qword
    mov rdx, [rcx+NEBO_PENDING_RECORD_RESOLUTION_SEQUENCE_OFFSET]
    call .mix_qword
    mov rdx, [rcx+NEBO_PENDING_RECORD_RESULT_LENGTH_OFFSET]
    call .mix_qword
.hash_next:
    inc rbx
    jmp .hash_loop
.hash_done:
    mov [r13], rax
    mov [r12+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .hash_return
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.hash_return:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.mix_qword:
    push rcx
    mov ecx, 8
.mix_byte:
    xor al, dl
    imul eax, eax, NEBO_PENDING_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
