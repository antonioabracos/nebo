; Nebo static Text/Int/Bool RendererRegistry — MF045
bits 64
default rel

%include "runtime/console/renderer-registry/renderer_registry.inc"

global nebo_console_renderer_registry_init
global nebo_console_renderer_registry_validate
global nebo_console_renderer_registry_lookup
global nebo_console_renderer_registry_state_hash

section .text

nebo_console_renderer_registry_state_hash:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .registry_hash_invalid
    test r13, r13
    jz .registry_hash_invalid
    mov eax, NEBO_RENDERER_HASH_FNV1A32_OFFSET_BASIS
    mov rbx, [r12+NEBO_RENDERER_REGISTRY_COUNT_OFFSET]
    mov ecx, 8
.registry_hash_count:
    xor al, bl
    imul rax, rax, NEBO_RENDERER_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .registry_hash_count
    xor r8d, r8d
.registry_hash_entry:
    cmp r8, [r12+NEBO_RENDERER_REGISTRY_COUNT_OFFSET]
    jae .registry_hash_done
    mov r9, r8
    imul r9, NEBO_RENDERER_ENTRY_SIZE
    add r9, [r12+NEBO_RENDERER_REGISTRY_ENTRIES_PTR_OFFSET]
    xor r10d, r10d
.registry_hash_qword:
    cmp r10d, NEBO_RENDERER_ENTRY_QWORDS
    jae .registry_hash_next
    mov rbx, [r9+r10*8]
    mov ecx, 8
.registry_hash_bytes:
    xor al, bl
    imul rax, rax, NEBO_RENDERER_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .registry_hash_bytes
    inc r10d
    jmp .registry_hash_qword
.registry_hash_next:
    inc r8
    jmp .registry_hash_entry
.registry_hash_done:
    mov [r12+NEBO_RENDERER_REGISTRY_STATE_HASH_OFFSET], rax
    mov [r13], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .registry_hash_return
.registry_hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.registry_hash_return:
    pop r13
    pop r12
    pop rbx
    ret

; registry_init(registry*, entries*, capacity) -> status
nebo_console_renderer_registry_init:
    push r12
    mov r12, rdi
    test r12, r12
    jz .registry_init_invalid_no_registry
    push rsi
    push rdx
    push rdi
    xor eax, eax
    mov ecx, NEBO_RENDERER_REGISTRY_QWORDS
    cld
    rep stosq
    pop rdi
    pop rdx
    pop rsi
    test rsi, rsi
    jz .registry_init_invalid
    cmp rdx, NEBO_RENDERER_BUILTIN_COUNT
    jb .registry_init_capacity
    mov [r12+NEBO_RENDERER_REGISTRY_ENTRIES_PTR_OFFSET], rsi
    mov [r12+NEBO_RENDERER_REGISTRY_CAPACITY_OFFSET], rdx
    mov qword [r12+NEBO_RENDERER_REGISTRY_COUNT_OFFSET], NEBO_RENDERER_BUILTIN_COUNT
    mov qword [r12+NEBO_RENDERER_REGISTRY_VERSION_OFFSET], NEBO_RENDERER_REGISTRY_VERSION_V0
    mov qword [r12+NEBO_RENDERER_REGISTRY_FLAGS_OFFSET], NEBO_RENDERER_REGISTRY_REQUIRED_FLAGS
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_ERROR_OFFSET], NEBO_RENDERER_ERROR_NONE
    mov qword [r12+NEBO_RENDERER_REGISTRY_MISSING_TYPE_OFFSET], 0

    push rdi
    mov rdi, rsi
    xor eax, eax
    mov ecx, NEBO_RENDERER_BUILTIN_COUNT*NEBO_RENDERER_ENTRY_QWORDS
    cld
    rep stosq
    pop rdi

    mov dword [rsi+NEBO_RENDERER_ENTRY_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_TEXT
    mov dword [rsi+NEBO_RENDERER_ENTRY_RENDERER_KIND_OFFSET], NEBO_RENDERER_KIND_TEXT
    mov qword [rsi+NEBO_RENDERER_ENTRY_CAPABILITIES_OFFSET], NEBO_RENDERER_CAP_REQUIRED
    mov qword [rsi+NEBO_RENDERER_ENTRY_SEMANTIC_ROLE_OFFSET], NEBO_CONSOLE_SEMANTIC_ROLE_TEXT
    mov qword [rsi+NEBO_RENDERER_ENTRY_ORDER_OFFSET], 0

    add rsi, NEBO_RENDERER_ENTRY_SIZE
    mov dword [rsi+NEBO_RENDERER_ENTRY_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_INT
    mov dword [rsi+NEBO_RENDERER_ENTRY_RENDERER_KIND_OFFSET], NEBO_RENDERER_KIND_INT
    mov qword [rsi+NEBO_RENDERER_ENTRY_CAPABILITIES_OFFSET], NEBO_RENDERER_CAP_REQUIRED
    mov qword [rsi+NEBO_RENDERER_ENTRY_SEMANTIC_ROLE_OFFSET], NEBO_CONSOLE_SEMANTIC_ROLE_VALUE
    mov qword [rsi+NEBO_RENDERER_ENTRY_ORDER_OFFSET], 1

    add rsi, NEBO_RENDERER_ENTRY_SIZE
    mov dword [rsi+NEBO_RENDERER_ENTRY_NODE_KIND_OFFSET], NEBO_CONSOLE_NODE_KIND_BOOL
    mov dword [rsi+NEBO_RENDERER_ENTRY_RENDERER_KIND_OFFSET], NEBO_RENDERER_KIND_BOOL
    mov qword [rsi+NEBO_RENDERER_ENTRY_CAPABILITIES_OFFSET], NEBO_RENDERER_CAP_REQUIRED
    mov qword [rsi+NEBO_RENDERER_ENTRY_SEMANTIC_ROLE_OFFSET], NEBO_CONSOLE_SEMANTIC_ROLE_VALUE
    mov qword [rsi+NEBO_RENDERER_ENTRY_ORDER_OFFSET], 2

    mov rdi, r12
    lea rsi, [r12+NEBO_RENDERER_REGISTRY_STATE_HASH_OFFSET]
    call nebo_console_renderer_registry_state_hash
    jmp .registry_init_done
.registry_init_capacity:
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_ERROR_OFFSET], NEBO_RENDERER_ERROR_CAPACITY
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .registry_init_done
.registry_init_invalid:
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_ERROR_OFFSET], NEBO_RENDERER_ERROR_BAD_ARGUMENT
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .registry_init_done
.registry_init_invalid_no_registry:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.registry_init_done:
    pop r12
    ret

nebo_console_renderer_registry_validate:
    test rdi, rdi
    jz .registry_validate_invalid
    cmp qword [rdi+NEBO_RENDERER_REGISTRY_ENTRIES_PTR_OFFSET], 0
    je .registry_validate_state
    cmp qword [rdi+NEBO_RENDERER_REGISTRY_COUNT_OFFSET], NEBO_RENDERER_BUILTIN_COUNT
    jne .registry_validate_state
    mov rax, [rdi+NEBO_RENDERER_REGISTRY_CAPACITY_OFFSET]
    cmp rax, NEBO_RENDERER_BUILTIN_COUNT
    jb .registry_validate_state
    cmp qword [rdi+NEBO_RENDERER_REGISTRY_VERSION_OFFSET], NEBO_RENDERER_REGISTRY_VERSION_V0
    jne .registry_validate_state
    mov rax, [rdi+NEBO_RENDERER_REGISTRY_FLAGS_OFFSET]
    and eax, NEBO_RENDERER_REGISTRY_REQUIRED_FLAGS
    cmp eax, NEBO_RENDERER_REGISTRY_REQUIRED_FLAGS
    jne .registry_validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.registry_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.registry_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; registry_lookup(registry*, node_kind, out_renderer_kind*) -> status
nebo_console_renderer_registry_lookup:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rdx
    test r13, r13
    jz .registry_lookup_invalid
    mov qword [r13], 0
    mov rdi, r12
    call nebo_console_renderer_registry_validate
    test eax, eax
    jnz .registry_lookup_done
    xor ebx, ebx
.registry_lookup_loop:
    cmp rbx, [r12+NEBO_RENDERER_REGISTRY_COUNT_OFFSET]
    jae .registry_lookup_missing
    mov rax, rbx
    imul rax, NEBO_RENDERER_ENTRY_SIZE
    add rax, [r12+NEBO_RENDERER_REGISTRY_ENTRIES_PTR_OFFSET]
    cmp [rax+NEBO_RENDERER_ENTRY_NODE_KIND_OFFSET], esi
    je .registry_lookup_found
    inc rbx
    jmp .registry_lookup_loop
.registry_lookup_found:
    mov eax, [rax+NEBO_RENDERER_ENTRY_RENDERER_KIND_OFFSET]
    mov [r13], rax
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_ERROR_OFFSET], NEBO_RENDERER_ERROR_NONE
    mov qword [r12+NEBO_RENDERER_REGISTRY_MISSING_TYPE_OFFSET], 0
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .registry_lookup_done
.registry_lookup_missing:
    mov [r12+NEBO_RENDERER_REGISTRY_MISSING_TYPE_OFFSET], rsi
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov qword [r12+NEBO_RENDERER_REGISTRY_LAST_ERROR_OFFSET], NEBO_RENDERER_ERROR_MISSING
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .registry_lookup_done
.registry_lookup_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.registry_lookup_done:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
