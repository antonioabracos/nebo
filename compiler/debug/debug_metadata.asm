; MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-F07 deterministic pointer-free debug metadata.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/debug/debug_metadata.inc"

section .text

NEBOC_ABI_FUNCTION nebo_debug_metadata_init
    test rdi,rdi
    jz .init_invalid
    push r12
    push r13
    mov r12,rdi
    mov r13,[r12+NEBO_DEBUG_INIT_STATE]
    test r13,r13
    jz .init_invalid_saved
    cmp qword [r12+NEBO_DEBUG_INIT_SOURCES],0
    je .init_invalid_saved
    cmp qword [r12+NEBO_DEBUG_INIT_FRAMES],0
    je .init_invalid_saved
    cmp qword [r12+NEBO_DEBUG_INIT_BINDINGS],0
    je .init_invalid_saved
    mov rax,[r12+NEBO_DEBUG_INIT_SOURCE_CAP]
    test rax,rax
    jz .init_invalid_saved
    cmp rax,NEBO_DEBUG_MAX_SOURCES
    ja .init_limit
    mov rax,[r12+NEBO_DEBUG_INIT_FRAME_CAP]
    test rax,rax
    jz .init_invalid_saved
    cmp rax,NEBO_DEBUG_MAX_FRAMES
    ja .init_limit
    mov rax,[r12+NEBO_DEBUG_INIT_BINDING_CAP]
    test rax,rax
    jz .init_invalid_saved
    cmp rax,NEBO_DEBUG_MAX_BINDINGS
    ja .init_limit
    mov rdi,r13
    mov ecx,NEBO_DEBUG_STATE_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,NEBO_DEBUG_MAGIC
    mov [r13+NEBO_DEBUG_STATE_MAGIC],rax
    mov qword [r13+NEBO_DEBUG_STATE_VERSION],NEBO_DEBUG_VERSION
    mov rax,[r12+NEBO_DEBUG_INIT_SOURCES]
    mov [r13+NEBO_DEBUG_STATE_SOURCES],rax
    mov rax,[r12+NEBO_DEBUG_INIT_SOURCE_CAP]
    mov [r13+NEBO_DEBUG_STATE_SOURCE_CAP],rax
    mov rax,[r12+NEBO_DEBUG_INIT_FRAMES]
    mov [r13+NEBO_DEBUG_STATE_FRAMES],rax
    mov rax,[r12+NEBO_DEBUG_INIT_FRAME_CAP]
    mov [r13+NEBO_DEBUG_STATE_FRAME_CAP],rax
    mov rax,[r12+NEBO_DEBUG_INIT_BINDINGS]
    mov [r13+NEBO_DEBUG_STATE_BINDINGS],rax
    mov rax,[r12+NEBO_DEBUG_INIT_BINDING_CAP]
    mov [r13+NEBO_DEBUG_STATE_BINDING_CAP],rax
    xor eax,eax
    jmp .init_done
.init_limit:
    mov eax,NEBO_DEBUG_STATUS_LIMIT
    jmp .init_done
.init_invalid_saved:
    mov eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
.init_done:
    pop r13
    pop r12
    ret
.init_invalid:
    mov eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_debug_source_add
    test rdi,rdi
    jz .source_invalid
    mov qword [rdi+NEBO_DEBUG_SOURCE_REQUEST_INDEX],0
    mov rsi,[rdi+NEBO_DEBUG_SOURCE_REQUEST_STATE]
    test rsi,rsi
    jz .source_invalid
    mov rax,NEBO_DEBUG_MAGIC
    cmp [rsi+NEBO_DEBUG_STATE_MAGIC],rax
    jne .source_invalid
    mov rax,[rdi+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_START]
    cmp rax,[rdi+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_END]
    jae .source_invalid
    cmp qword [rdi+NEBO_DEBUG_SOURCE_REQUEST_ID],0
    je .source_invalid
    mov rdx,[rdi+NEBO_DEBUG_SOURCE_REQUEST_SPAN_START]
    cmp rdx,[rdi+NEBO_DEBUG_SOURCE_REQUEST_SPAN_END]
    ja .source_invalid
    mov rcx,[rsi+NEBO_DEBUG_STATE_SOURCE_COUNT]
    cmp rcx,[rsi+NEBO_DEBUG_STATE_SOURCE_CAP]
    jae .source_limit
    test rcx,rcx
    jz .source_store
    mov r8,rcx
    dec r8
    imul r8,NEBO_DEBUG_SOURCE_SIZE
    add r8,[rsi+NEBO_DEBUG_STATE_SOURCES]
    cmp rax,[r8+NEBO_DEBUG_SOURCE_ADDRESS_END]
    jb .source_overlap
.source_store:
    mov r8,rcx
    imul r8,NEBO_DEBUG_SOURCE_SIZE
    add r8,[rsi+NEBO_DEBUG_STATE_SOURCES]
    mov [r8+NEBO_DEBUG_SOURCE_ADDRESS_START],rax
    mov rax,[rdi+NEBO_DEBUG_SOURCE_REQUEST_ADDRESS_END]
    mov [r8+NEBO_DEBUG_SOURCE_ADDRESS_END],rax
    mov rax,[rdi+NEBO_DEBUG_SOURCE_REQUEST_ID]
    mov [r8+NEBO_DEBUG_SOURCE_ID],rax
    mov [r8+NEBO_DEBUG_SOURCE_SPAN_START],rdx
    mov rax,[rdi+NEBO_DEBUG_SOURCE_REQUEST_SPAN_END]
    mov [r8+NEBO_DEBUG_SOURCE_SPAN_END],rax
    mov [rdi+NEBO_DEBUG_SOURCE_REQUEST_INDEX],rcx
    inc qword [rsi+NEBO_DEBUG_STATE_SOURCE_COUNT]
    xor eax,eax
    ret
.source_overlap:
    mov eax,NEBO_DEBUG_STATUS_OVERLAP
    ret
.source_limit:
    mov eax,NEBO_DEBUG_STATUS_LIMIT
    ret
.source_invalid:
    mov eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_debug_frame_add
    test rdi,rdi
    jz .frame_invalid
    mov qword [rdi+NEBO_DEBUG_FRAME_REQUEST_INDEX],0
    mov rsi,[rdi+NEBO_DEBUG_FRAME_REQUEST_STATE]
    test rsi,rsi
    jz .frame_invalid
    mov rax,NEBO_DEBUG_MAGIC
    cmp [rsi+NEBO_DEBUG_STATE_MAGIC],rax
    jne .frame_invalid
    cmp qword [rdi+NEBO_DEBUG_FRAME_REQUEST_ID],0
    je .frame_invalid
    mov rax,[rdi+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_START]
    cmp rax,[rdi+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_END]
    jae .frame_invalid
    mov rcx,[rsi+NEBO_DEBUG_STATE_FRAME_COUNT]
    cmp rcx,[rsi+NEBO_DEBUG_STATE_FRAME_CAP]
    jae .frame_limit
    test rcx,rcx
    jz .frame_store
    mov r8,rcx
    dec r8
    imul r8,NEBO_DEBUG_FRAME_SIZE
    add r8,[rsi+NEBO_DEBUG_STATE_FRAMES]
    cmp rax,[r8+NEBO_DEBUG_FRAME_ADDRESS_END]
    jb .frame_overlap
.frame_store:
    mov r8,rcx
    imul r8,NEBO_DEBUG_FRAME_SIZE
    add r8,[rsi+NEBO_DEBUG_STATE_FRAMES]
    mov rdx,[rdi+NEBO_DEBUG_FRAME_REQUEST_ID]
    mov [r8+NEBO_DEBUG_FRAME_ID],rdx
    mov [r8+NEBO_DEBUG_FRAME_ADDRESS_START],rax
    mov rdx,[rdi+NEBO_DEBUG_FRAME_REQUEST_ADDRESS_END]
    mov [r8+NEBO_DEBUG_FRAME_ADDRESS_END],rdx
    mov rdx,[rsi+NEBO_DEBUG_STATE_BINDING_COUNT]
    mov [r8+NEBO_DEBUG_FRAME_BINDING_START],rdx
    mov qword [r8+NEBO_DEBUG_FRAME_BINDING_COUNT],0
    mov qword [r8+NEBO_DEBUG_FRAME_STATE],1
    mov [rdi+NEBO_DEBUG_FRAME_REQUEST_INDEX],rcx
    inc qword [rsi+NEBO_DEBUG_STATE_FRAME_COUNT]
    xor eax,eax
    ret
.frame_overlap:
    mov eax,NEBO_DEBUG_STATUS_OVERLAP
    ret
.frame_limit:
    mov eax,NEBO_DEBUG_STATUS_LIMIT
    ret
.frame_invalid:
    mov eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
    ret

NEBOC_ABI_FUNCTION nebo_debug_binding_add
    test rdi,rdi
    jz .binding_invalid
    mov qword [rdi+NEBO_DEBUG_BINDING_REQUEST_INDEX],0
    mov rsi,[rdi+NEBO_DEBUG_BINDING_REQUEST_STATE]
    test rsi,rsi
    jz .binding_invalid
    mov rax,NEBO_DEBUG_MAGIC
    cmp [rsi+NEBO_DEBUG_STATE_MAGIC],rax
    jne .binding_invalid
    cmp qword [rdi+NEBO_DEBUG_BINDING_REQUEST_NAME],0
    je .binding_invalid
    mov rdx,[rdi+NEBO_DEBUG_BINDING_REQUEST_FRAME]
    cmp rdx,[rsi+NEBO_DEBUG_STATE_FRAME_COUNT]
    jae .binding_frame
    mov rax,[rdi+NEBO_DEBUG_BINDING_REQUEST_KIND]
    cmp rax,NEBO_DEBUG_BINDING_REGISTER
    je .binding_kind_ok
    cmp rax,NEBO_DEBUG_BINDING_STACK
    jne .binding_invalid
.binding_kind_ok:
    mov r8,[rdi+NEBO_DEBUG_BINDING_REQUEST_CLASS]
    test r8,~NEBO_PRIVACY_CLASS_MASK
    jnz .binding_invalid
    cmp qword [rdi+NEBO_DEBUG_BINDING_REQUEST_REDACTED],1
    ja .binding_invalid
    test r8,r8
    jz .binding_privacy_ok
    cmp qword [rdi+NEBO_DEBUG_BINDING_REQUEST_REDACTED],1
    jne .binding_privacy
.binding_privacy_ok:
    mov rcx,[rsi+NEBO_DEBUG_STATE_BINDING_COUNT]
    cmp rcx,[rsi+NEBO_DEBUG_STATE_BINDING_CAP]
    jae .binding_limit
    mov r9,rcx
    imul r9,NEBO_DEBUG_BINDING_SIZE
    add r9,[rsi+NEBO_DEBUG_STATE_BINDINGS]
    mov rax,[rdi+NEBO_DEBUG_BINDING_REQUEST_NAME]
    mov [r9+NEBO_DEBUG_BINDING_NAME],rax
    mov [r9+NEBO_DEBUG_BINDING_FRAME],rdx
    mov rax,[rdi+NEBO_DEBUG_BINDING_REQUEST_KIND]
    mov [r9+NEBO_DEBUG_BINDING_KIND],rax
    mov rax,[rdi+NEBO_DEBUG_BINDING_REQUEST_LOCATION]
    mov [r9+NEBO_DEBUG_BINDING_LOCATION],rax
    mov [r9+NEBO_DEBUG_BINDING_CLASS],r8
    mov rax,[rdi+NEBO_DEBUG_BINDING_REQUEST_REDACTED]
    mov [r9+NEBO_DEBUG_BINDING_REDACTED],rax
    mov [rdi+NEBO_DEBUG_BINDING_REQUEST_INDEX],rcx
    inc qword [rsi+NEBO_DEBUG_STATE_BINDING_COUNT]
    mov r9,rdx
    imul r9,NEBO_DEBUG_FRAME_SIZE
    add r9,[rsi+NEBO_DEBUG_STATE_FRAMES]
    inc qword [r9+NEBO_DEBUG_FRAME_BINDING_COUNT]
    xor eax,eax
    ret
.binding_privacy:
    mov eax,NEBO_DEBUG_STATUS_PRIVACY
    ret
.binding_frame:
    mov eax,NEBO_DEBUG_STATUS_FRAME
    ret
.binding_limit:
    mov eax,NEBO_DEBUG_STATUS_LIMIT
    ret
.binding_invalid:
    mov eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
    ret

; rdi=40-byte request. Encodes a pointer-free, versioned local blob.
NEBOC_ABI_FUNCTION nebo_debug_metadata_encode
    test rdi,rdi
    jz .encode_invalid
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov qword [r12+NEBO_DEBUG_ENCODE_LENGTH],0
    mov qword [r12+NEBO_DEBUG_ENCODE_HASH],0
    mov r13,[r12+NEBO_DEBUG_ENCODE_STATE]
    test r13,r13
    jz .encode_invalid_saved
    mov rax,NEBO_DEBUG_MAGIC
    cmp [r13+NEBO_DEBUG_STATE_MAGIC],rax
    jne .encode_invalid_saved
    mov rbx,NEBO_DEBUG_HEADER_SIZE
    mov rax,[r13+NEBO_DEBUG_STATE_SOURCE_COUNT]
    imul rax,NEBO_DEBUG_SOURCE_SIZE
    add rbx,rax
    mov rax,[r13+NEBO_DEBUG_STATE_FRAME_COUNT]
    imul rax,NEBO_DEBUG_FRAME_SIZE
    add rbx,rax
    mov rax,[r13+NEBO_DEBUG_STATE_BINDING_COUNT]
    imul rax,NEBO_DEBUG_BINDING_SIZE
    add rbx,rax
    cmp rbx,[r12+NEBO_DEBUG_ENCODE_CAPACITY]
    ja .encode_limit
    mov rdi,[r12+NEBO_DEBUG_ENCODE_OUTPUT]
    test rdi,rdi
    jz .encode_invalid_saved
    mov rax,NEBO_DEBUG_MAGIC
    stosq
    mov rax,NEBO_DEBUG_VERSION
    stosq
    mov rax,[r13+NEBO_DEBUG_STATE_SOURCE_COUNT]
    stosq
    mov rax,[r13+NEBO_DEBUG_STATE_FRAME_COUNT]
    stosq
    mov rax,[r13+NEBO_DEBUG_STATE_BINDING_COUNT]
    stosq
    mov rsi,[r13+NEBO_DEBUG_STATE_SOURCES]
    mov rcx,[r13+NEBO_DEBUG_STATE_SOURCE_COUNT]
    imul rcx,NEBO_DEBUG_SOURCE_SIZE/8
    rep movsq
    mov rsi,[r13+NEBO_DEBUG_STATE_FRAMES]
    mov rcx,[r13+NEBO_DEBUG_STATE_FRAME_COUNT]
    imul rcx,NEBO_DEBUG_FRAME_SIZE/8
    rep movsq
    mov rsi,[r13+NEBO_DEBUG_STATE_BINDINGS]
    mov rcx,[r13+NEBO_DEBUG_STATE_BINDING_COUNT]
    imul rcx,NEBO_DEBUG_BINDING_SIZE/8
    rep movsq
    mov [r12+NEBO_DEBUG_ENCODE_LENGTH],rbx
    mov rdi,[r12+NEBO_DEBUG_ENCODE_OUTPUT]
    mov rcx,rbx
    mov rax,NEBO_DEBUG_FNV_OFFSET
    mov rdx,NEBO_DEBUG_FNV_PRIME
.encode_hash:
    xor al,[rdi]
    imul rax,rdx
    inc rdi
    loop .encode_hash
    mov [r12+NEBO_DEBUG_ENCODE_HASH],rax
    mov [r13+NEBO_DEBUG_STATE_HASH],rax
    xor eax,eax
    jmp .encode_done
.encode_limit:
    mov eax,NEBO_DEBUG_STATUS_LIMIT
    jmp .encode_done
.encode_invalid_saved:
    mov eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
.encode_done:
    pop r13
    pop r12
    pop rbx
    ret
.encode_invalid:
    mov eax,NEBO_DEBUG_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
