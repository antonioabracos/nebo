; Nebo Assembly — checked SourceSpan v0

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"

section .text

; source_span_init(span*, source_id, start, end, source_length)
NEBOC_ABI_FUNCTION neboc_source_span_init
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp rdx, rcx
    ja .invalid
    cmp rcx, r8
    ja .invalid
    mov [rdi + NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET], rsi
    mov [rdi + NEBOC_SOURCE_SPAN_START_OFFSET], rdx
    mov [rdi + NEBOC_SOURCE_SPAN_END_OFFSET], rcx
    mov [rdi + NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET], r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_span_validate(span*, source_id, source_length)
NEBOC_ABI_FUNCTION neboc_source_span_validate
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    cmp [rdi + NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET], rsi
    jne .invalid
    cmp [rdi + NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET], rdx
    jne .invalid
    mov rax, [rdi + NEBOC_SOURCE_SPAN_START_OFFSET]
    cmp rax, [rdi + NEBOC_SOURCE_SPAN_END_OFFSET]
    ja .invalid
    mov rax, [rdi + NEBOC_SOURCE_SPAN_END_OFFSET]
    cmp rax, rdx
    ja .invalid
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; source_span_union(out*, left*, right*)
NEBOC_ABI_FUNCTION neboc_source_span_union
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    mov rax, [rsi + NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
    test rax, rax
    jz .invalid
    cmp [rdx + NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET], rax
    jne .invalid
    mov r8, [rsi + NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET]
    cmp [rdx + NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET], r8
    jne .invalid
    mov r9, [rsi + NEBOC_SOURCE_SPAN_START_OFFSET]
    mov r10, [rsi + NEBOC_SOURCE_SPAN_END_OFFSET]
    cmp r9, r10
    ja .invalid
    cmp r10, r8
    ja .invalid
    mov r11, [rdx + NEBOC_SOURCE_SPAN_START_OFFSET]
    mov rcx, [rdx + NEBOC_SOURCE_SPAN_END_OFFSET]
    cmp r11, rcx
    ja .invalid
    cmp rcx, r8
    ja .invalid
    cmp r11, r9
    cmovb r9, r11
    cmp rcx, r10
    cmova r10, rcx
    mov [rdi + NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET], rax
    mov [rdi + NEBOC_SOURCE_SPAN_START_OFFSET], r9
    mov [rdi + NEBOC_SOURCE_SPAN_END_OFFSET], r10
    mov [rdi + NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET], r8
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
