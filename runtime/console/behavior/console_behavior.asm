; Nebo Console ForegroundColor BehaviorSet runtime — MF045
bits 64
default rel

%include "runtime/console/behavior/console_behavior.inc"

global nebo_console_palette_color
global nebo_console_behavior_set_build
global nebo_console_behavior_set_validate
global nebo_console_behavior_set_state_hash
global nebo_console_behavior_store_init
global nebo_console_behavior_store_validate
global nebo_console_behavior_store_register
global nebo_console_behavior_store_lookup
global nebo_console_behavior_store_state_hash

section .text

; palette_color(ColorId, out_bgra*) -> status
nebo_console_palette_color:
    test rsi, rsi
    jz .palette_invalid
    cmp edi, NEBO_COLOR_ID_BLACK
    jb .palette_invalid
    cmp edi, NEBO_COLOR_ID_MAGENTA
    ja .palette_invalid
    cmp edi, NEBO_COLOR_ID_BLACK
    je .palette_black
    cmp edi, NEBO_COLOR_ID_WHITE
    je .palette_white
    cmp edi, NEBO_COLOR_ID_GREY
    je .palette_grey
    cmp edi, NEBO_COLOR_ID_RED
    je .palette_red
    cmp edi, NEBO_COLOR_ID_GREEN
    je .palette_green
    cmp edi, NEBO_COLOR_ID_BLUE
    je .palette_blue
    cmp edi, NEBO_COLOR_ID_YELLOW
    je .palette_yellow
    cmp edi, NEBO_COLOR_ID_CYAN
    je .palette_cyan
    mov eax, NEBO_COLOR_BGRA_MAGENTA
    jmp .palette_store
.palette_black:
    mov eax, NEBO_COLOR_BGRA_BLACK
    jmp .palette_store
.palette_white:
    mov eax, NEBO_COLOR_BGRA_WHITE
    jmp .palette_store
.palette_grey:
    mov eax, NEBO_COLOR_BGRA_GREY
    jmp .palette_store
.palette_red:
    mov eax, NEBO_COLOR_BGRA_RED
    jmp .palette_store
.palette_green:
    mov eax, NEBO_COLOR_BGRA_GREEN
    jmp .palette_store
.palette_blue:
    mov eax, NEBO_COLOR_BGRA_BLUE
    jmp .palette_store
.palette_yellow:
    mov eax, NEBO_COLOR_BGRA_YELLOW
    jmp .palette_store
.palette_cyan:
    mov eax, NEBO_COLOR_BGRA_CYAN
.palette_store:
    mov [rsi], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.palette_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; behavior_set_state_hash(set*, out*) -> status
nebo_console_behavior_set_state_hash:
    push rbx
    test rdi, rdi
    jz .set_hash_invalid
    test rsi, rsi
    jz .set_hash_invalid
    mov eax, NEBO_BEHAVIOR_HASH_FNV1A32_OFFSET_BASIS
    xor edx, edx
.set_hash_field:
    cmp edx, NEBO_BEHAVIOR_SET_STATE_HASH_OFFSET
    jae .set_hash_done
    mov rbx, [rdi+rdx]
    mov ecx, 8
.set_hash_bytes:
    xor al, bl
    imul rax, rax, NEBO_BEHAVIOR_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .set_hash_bytes
    add edx, 8
    jmp .set_hash_field
.set_hash_done:
    mov [rdi+NEBO_BEHAVIOR_SET_STATE_HASH_OFFSET], rax
    mov [rsi], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    pop rbx
    ret
.set_hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    pop rbx
    ret

; behavior_set_validate(set*) -> status
nebo_console_behavior_set_validate:
    test rdi, rdi
    jz .set_validate_invalid
    cmp qword [rdi+NEBO_BEHAVIOR_SET_ID_OFFSET], 0
    je .set_validate_state
    cmp qword [rdi+NEBO_BEHAVIOR_SET_VERSION_OFFSET], NEBO_BEHAVIOR_VERSION_V0
    jne .set_validate_state
    mov rax, [rdi+NEBO_BEHAVIOR_SET_ENTRY_COUNT_OFFSET]
    cmp rax, 1
    ja .set_validate_state
    mov rcx, [rdi+NEBO_BEHAVIOR_SET_FLAGS_OFFSET]
    and ecx, NEBO_BEHAVIOR_SET_REQUIRED_FLAGS
    cmp ecx, NEBO_BEHAVIOR_SET_REQUIRED_FLAGS
    jne .set_validate_state
    test rax, rax
    jz .set_validate_empty
    test qword [rdi+NEBO_BEHAVIOR_SET_FLAGS_OFFSET], NEBO_BEHAVIOR_SET_FLAG_HAS_FOREGROUND
    jz .set_validate_state
    cmp qword [rdi+NEBO_BEHAVIOR_SET_CONFLICT_MASK_OFFSET], NEBO_BEHAVIOR_CONFLICT_FOREGROUND_COLOR
    jne .set_validate_state
    cmp qword [rdi+NEBO_BEHAVIOR_SET_FOREGROUND_COLOR_OFFSET], 0
    je .set_validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.set_validate_empty:
    test qword [rdi+NEBO_BEHAVIOR_SET_FLAGS_OFFSET], NEBO_BEHAVIOR_SET_FLAG_HAS_FOREGROUND
    jnz .set_validate_state
    cmp qword [rdi+NEBO_BEHAVIOR_SET_CONFLICT_MASK_OFFSET], 0
    jne .set_validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.set_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.set_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; behavior_set_build(set*, set_id, descriptors*, count) -> status
nebo_console_behavior_set_build:
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
    test r12, r12
    jz .set_build_invalid_no_set
    push r12
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_BEHAVIOR_SET_QWORDS
    cld
    rep stosq
    pop r12
    test r13, r13
    jz .set_build_invalid
    cmp r15, NEBO_BEHAVIOR_MAX_ENTRIES_V0
    ja .set_build_limit
    test r15, r15
    jz .set_build_empty
    test r14, r14
    jz .set_build_invalid
    xor ebx, ebx
    xor r10d, r10d
.set_build_loop:
    cmp rbx, r15
    jae .set_build_finish
    mov rax, rbx
    imul rax, NEBO_BEHAVIOR_DESCRIPTOR_SIZE
    add rax, r14
    cmp dword [rax+NEBO_BEHAVIOR_DESCRIPTOR_VERSION_OFFSET], NEBO_BEHAVIOR_VERSION_V0
    jne .set_build_version
    cmp dword [rax+NEBO_BEHAVIOR_DESCRIPTOR_KIND_OFFSET], NEBO_BEHAVIOR_KIND_FOREGROUND_COLOR
    jne .set_build_kind
    test r10d, r10d
    jnz .set_build_conflict
    mov edi, [rax+NEBO_BEHAVIOR_DESCRIPTOR_PAYLOAD_OFFSET]
    lea rsi, [rsp]
    call nebo_console_palette_color
    test eax, eax
    jnz .set_build_color
    mov r10d, 1
    inc rbx
    jmp .set_build_loop
.set_build_finish:
    mov [r12+NEBO_BEHAVIOR_SET_ID_OFFSET], r13
    mov qword [r12+NEBO_BEHAVIOR_SET_VERSION_OFFSET], NEBO_BEHAVIOR_VERSION_V0
    mov [r12+NEBO_BEHAVIOR_SET_ENTRY_COUNT_OFFSET], r15
    test r10d, r10d
    jz .set_build_empty_fields
    mov qword [r12+NEBO_BEHAVIOR_SET_CONFLICT_MASK_OFFSET], NEBO_BEHAVIOR_CONFLICT_FOREGROUND_COLOR
    mov rax, [rsp]
    mov [r12+NEBO_BEHAVIOR_SET_FOREGROUND_COLOR_OFFSET], rax
    mov qword [r12+NEBO_BEHAVIOR_SET_APPLIED_ORDER_OFFSET], 0
    mov qword [r12+NEBO_BEHAVIOR_SET_FLAGS_OFFSET], NEBO_BEHAVIOR_SET_REQUIRED_FLAGS | NEBO_BEHAVIOR_SET_FLAG_HAS_FOREGROUND
    jmp .set_build_hash
.set_build_empty:
    mov [r12+NEBO_BEHAVIOR_SET_ID_OFFSET], r13
    mov qword [r12+NEBO_BEHAVIOR_SET_VERSION_OFFSET], NEBO_BEHAVIOR_VERSION_V0
    mov qword [r12+NEBO_BEHAVIOR_SET_ENTRY_COUNT_OFFSET], 0
.set_build_empty_fields:
    mov qword [r12+NEBO_BEHAVIOR_SET_CONFLICT_MASK_OFFSET], 0
    mov qword [r12+NEBO_BEHAVIOR_SET_FOREGROUND_COLOR_OFFSET], 0
    mov qword [r12+NEBO_BEHAVIOR_SET_APPLIED_ORDER_OFFSET], 0
    mov qword [r12+NEBO_BEHAVIOR_SET_FLAGS_OFFSET], NEBO_BEHAVIOR_SET_REQUIRED_FLAGS
.set_build_hash:
    mov rdi, r12
    lea rsi, [r12+NEBO_BEHAVIOR_SET_STATE_HASH_OFFSET]
    call nebo_console_behavior_set_state_hash
    jmp .set_build_done
.set_build_version:
    mov eax, NEBO_CONSOLE_STATUS_ABI_MISMATCH
    jmp .set_build_done
.set_build_kind:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .set_build_done
.set_build_conflict:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .set_build_done
.set_build_color:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .set_build_done
.set_build_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .set_build_done
.set_build_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .set_build_done
.set_build_invalid_no_set:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.set_build_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; store_state_hash(store*, out*) -> status
nebo_console_behavior_store_state_hash:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .store_hash_invalid
    test r13, r13
    jz .store_hash_invalid
    mov eax, NEBO_BEHAVIOR_HASH_FNV1A32_OFFSET_BASIS
    mov rbx, [r12+NEBO_BEHAVIOR_STORE_COUNT_OFFSET]
    mov ecx, 8
.store_hash_count:
    xor al, bl
    imul rax, rax, NEBO_BEHAVIOR_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .store_hash_count
    xor r8d, r8d
.store_hash_sets:
    cmp r8, [r12+NEBO_BEHAVIOR_STORE_COUNT_OFFSET]
    jae .store_hash_done
    mov r9, r8
    imul r9, NEBO_BEHAVIOR_SET_SIZE
    add r9, [r12+NEBO_BEHAVIOR_STORE_SETS_PTR_OFFSET]
    xor r10d, r10d
.store_hash_qword:
    cmp r10d, NEBO_BEHAVIOR_SET_QWORDS
    jae .store_hash_next
    mov rbx, [r9+r10*8]
    mov ecx, 8
.store_hash_bytes:
    xor al, bl
    imul rax, rax, NEBO_BEHAVIOR_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .store_hash_bytes
    inc r10d
    jmp .store_hash_qword
.store_hash_next:
    inc r8
    jmp .store_hash_sets
.store_hash_done:
    mov [r12+NEBO_BEHAVIOR_STORE_STATE_HASH_OFFSET], rax
    mov [r13], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .store_hash_return
.store_hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.store_hash_return:
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_behavior_store_init:
    test rdi, rdi
    jz .store_init_invalid_no_store
    push rdi
    mov r8, rsi
    mov r9, rdx
    xor eax, eax
    mov ecx, NEBO_BEHAVIOR_STORE_QWORDS
    cld
    rep stosq
    pop rdi
    test r8, r8
    jz .store_init_invalid
    test r9, r9
    jz .store_init_limit
    mov [rdi+NEBO_BEHAVIOR_STORE_SETS_PTR_OFFSET], r8
    mov [rdi+NEBO_BEHAVIOR_STORE_CAPACITY_OFFSET], r9
    mov qword [rdi+NEBO_BEHAVIOR_STORE_COUNT_OFFSET], 0
    mov qword [rdi+NEBO_BEHAVIOR_STORE_FLAGS_OFFSET], NEBO_BEHAVIOR_STORE_REQUIRED_FLAGS
    mov qword [rdi+NEBO_BEHAVIOR_STORE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [rdi+NEBO_BEHAVIOR_STORE_LAST_ERROR_OFFSET], NEBO_BEHAVIOR_ERROR_NONE
    mov eax, NEBO_BEHAVIOR_HASH_FNV1A32_OFFSET_BASIS
    mov [rdi+NEBO_BEHAVIOR_STORE_STATE_HASH_OFFSET], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.store_init_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    ret
.store_init_invalid:
.store_init_invalid_no_store:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

nebo_console_behavior_store_validate:
    test rdi, rdi
    jz .store_validate_invalid
    cmp qword [rdi+NEBO_BEHAVIOR_STORE_SETS_PTR_OFFSET], 0
    je .store_validate_state
    cmp qword [rdi+NEBO_BEHAVIOR_STORE_CAPACITY_OFFSET], 0
    je .store_validate_state
    mov rax, [rdi+NEBO_BEHAVIOR_STORE_COUNT_OFFSET]
    cmp rax, [rdi+NEBO_BEHAVIOR_STORE_CAPACITY_OFFSET]
    ja .store_validate_state
    mov rcx, [rdi+NEBO_BEHAVIOR_STORE_FLAGS_OFFSET]
    and ecx, NEBO_BEHAVIOR_STORE_REQUIRED_FLAGS
    cmp ecx, NEBO_BEHAVIOR_STORE_REQUIRED_FLAGS
    jne .store_validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.store_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.store_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; store_register(store*, set*) -> status. Copies one validated record.
nebo_console_behavior_store_register:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_console_behavior_store_validate
    test eax, eax
    jnz .store_register_done
    mov rdi, r13
    call nebo_console_behavior_set_validate
    test eax, eax
    jnz .store_register_state
    xor ebx, ebx
.store_register_duplicate_loop:
    cmp rbx, [r12+NEBO_BEHAVIOR_STORE_COUNT_OFFSET]
    jae .store_register_capacity
    mov rax, rbx
    imul rax, NEBO_BEHAVIOR_SET_SIZE
    add rax, [r12+NEBO_BEHAVIOR_STORE_SETS_PTR_OFFSET]
    mov rcx, [r13+NEBO_BEHAVIOR_SET_ID_OFFSET]
    cmp [rax+NEBO_BEHAVIOR_SET_ID_OFFSET], rcx
    je .store_register_duplicate
    inc rbx
    jmp .store_register_duplicate_loop
.store_register_capacity:
    mov rax, [r12+NEBO_BEHAVIOR_STORE_COUNT_OFFSET]
    cmp rax, [r12+NEBO_BEHAVIOR_STORE_CAPACITY_OFFSET]
    jae .store_register_full
    mov rdx, rax
    imul rdx, NEBO_BEHAVIOR_SET_SIZE
    add rdx, [r12+NEBO_BEHAVIOR_STORE_SETS_PTR_OFFSET]
    mov rdi, rdx
    mov rsi, r13
    mov ecx, NEBO_BEHAVIOR_SET_QWORDS
    cld
    rep movsq
    inc qword [r12+NEBO_BEHAVIOR_STORE_COUNT_OFFSET]
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_ERROR_OFFSET], NEBO_BEHAVIOR_ERROR_NONE
    mov rdi, r12
    lea rsi, [r12+NEBO_BEHAVIOR_STORE_STATE_HASH_OFFSET]
    call nebo_console_behavior_store_state_hash
    jmp .store_register_done
.store_register_duplicate:
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_ERROR_OFFSET], NEBO_BEHAVIOR_ERROR_DUPLICATE_ID
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .store_register_done
.store_register_full:
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_ERROR_OFFSET], NEBO_BEHAVIOR_ERROR_STORE_FULL
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .store_register_done
.store_register_state:
    test r12, r12
    jz .store_register_done
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_ERROR_OFFSET], NEBO_BEHAVIOR_ERROR_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.store_register_done:
    pop r13
    pop r12
    pop rbx
    ret

; store_lookup(store*, set_id, out_set**) -> status
nebo_console_behavior_store_lookup:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rdx
    test r13, r13
    jz .store_lookup_invalid
    mov qword [r13], 0
    test rsi, rsi
    jz .store_lookup_invalid
    mov rdi, r12
    call nebo_console_behavior_store_validate
    test eax, eax
    jnz .store_lookup_done
    xor ebx, ebx
.store_lookup_loop:
    cmp rbx, [r12+NEBO_BEHAVIOR_STORE_COUNT_OFFSET]
    jae .store_lookup_missing
    mov rax, rbx
    imul rax, NEBO_BEHAVIOR_SET_SIZE
    add rax, [r12+NEBO_BEHAVIOR_STORE_SETS_PTR_OFFSET]
    cmp [rax+NEBO_BEHAVIOR_SET_ID_OFFSET], rsi
    je .store_lookup_found
    inc rbx
    jmp .store_lookup_loop
.store_lookup_found:
    mov [r13], rax
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_ERROR_OFFSET], NEBO_BEHAVIOR_ERROR_NONE
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .store_lookup_done
.store_lookup_missing:
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov qword [r12+NEBO_BEHAVIOR_STORE_LAST_ERROR_OFFSET], NEBO_BEHAVIOR_ERROR_MISSING_SET
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .store_lookup_done
.store_lookup_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.store_lookup_done:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
