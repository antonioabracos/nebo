; Nebo Assembly — deterministic bounded source snippet v0

bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/line-map/line_map.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/snippet/snippet.inc"

extern neboc_line_map_lookup

section .text

; snippet_extract(map*, span*, logical_path*, path_len, max_bytes, snippet*)
NEBOC_ABI_FUNCTION neboc_snippet_extract
    test r9, r9
    jz .invalid_fast
    test rdi, rdi
    jz .invalid_fast
    test rsi, rsi
    jz .invalid_fast
    test rdx, rdx
    jz .invalid_fast
    test rcx, rcx
    jz .invalid_fast
    cmp rcx, NEBOC_SNIPPET_LOGICAL_PATH_MAX_BYTES
    ja .invalid_fast
    test r8, r8
    jz .invalid_fast
    cmp r8, NEBOC_SNIPPET_HARD_MAX_BYTES
    ja .invalid_fast

    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 112

    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    mov [rsp], r9

    ; Stable relative path policy.
    mov al, [r13]
    cmp al, '/'
    je .invalid
    cmp al, 92
    je .invalid
    xor ecx, ecx
.path_loop:
    cmp rcx, r14
    jae .path_ok
    mov al, [r13 + rcx]
    test al, al
    jz .invalid
    cmp al, 92
    je .invalid
    cmp al, ':'
    je .invalid
    inc rcx
    jmp .path_loop
.path_ok:
    mov rax, [rbx + NEBOC_LINE_MAP_SOURCE_ID_OFFSET]
    test rax, rax
    jz .invalid
    cmp [r12 + NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET], rax
    jne .invalid
    mov rax, [rbx + NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET]
    cmp [r12 + NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET], rax
    jne .invalid
    mov rax, [r12 + NEBOC_SOURCE_SPAN_START_OFFSET]
    cmp rax, [r12 + NEBOC_SOURCE_SPAN_END_OFFSET]
    ja .invalid
    mov rax, [r12 + NEBOC_SOURCE_SPAN_END_OFFSET]
    cmp rax, [rbx + NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET]
    ja .invalid

    mov rdi, rbx
    mov rsi, [r12 + NEBOC_SOURCE_SPAN_START_OFFSET]
    mov rdx, [rbx + NEBOC_LINE_MAP_OWNER_OFFSET]
    lea rcx, [rsp + 16]
    call neboc_line_map_lookup
    test eax, eax
    jne .finish

    mov rdi, rbx
    mov rsi, [r12 + NEBOC_SOURCE_SPAN_END_OFFSET]
    mov rdx, [rbx + NEBOC_LINE_MAP_OWNER_OFFSET]
    lea rcx, [rsp + 64]
    call neboc_line_map_lookup
    test eax, eax
    jne .finish

    mov rax, [rsp + 16 + NEBOC_SOURCE_LOCATION_LINE_OFFSET]
    cmp rax, [rsp + 64 + NEBOC_SOURCE_LOCATION_LINE_OFFSET]
    jne .invalid

    mov r8, [rsp + 16 + NEBOC_SOURCE_LOCATION_LINE_START_OFFSET]
    mov r9, [rsp + 16 + NEBOC_SOURCE_LOCATION_LINE_END_OFFSET]
    mov r10, r8
    mov r11, r9
    mov rax, r11
    sub rax, r10
    cmp rax, r15
    jbe .window_ready

    mov rax, r15
    shr rax, 1
    mov rdx, [r12 + NEBOC_SOURCE_SPAN_START_OFFSET]
    mov rcx, r8
    add rcx, rax
    jc .invalid
    cmp rdx, rcx
    jbe .window_from_line
    sub rdx, rax
    mov r10, rdx
    jmp .window_adjust_start
.window_from_line:
    mov r10, r8
.window_adjust_start:
    mov rcx, [rbx + NEBOC_LINE_MAP_SOURCE_OFFSET]
.adjust_start_loop:
    cmp r10, [r12 + NEBOC_SOURCE_SPAN_START_OFFSET]
    jae .window_end_candidate
    movzx eax, byte [rcx + r10]
    and eax, 0xc0
    cmp eax, 0x80
    jne .window_end_candidate
    inc r10
    jmp .adjust_start_loop
.window_end_candidate:
    mov r11, r10
    add r11, r15
    jc .invalid
    cmp r11, r9
    jbe .adjust_end
    mov r11, r9
    jmp .window_ready
.adjust_end:
    cmp r11, r9
    jae .window_ready
.adjust_end_loop:
    cmp r11, r10
    jbe .invalid
    movzx eax, byte [rcx + r11]
    and eax, 0xc0
    cmp eax, 0x80
    jne .window_ready
    dec r11
    jmp .adjust_end_loop
.window_ready:
    mov rdx, [rsp]
    xor eax, eax
    mov ecx, NEBOC_SNIPPET_QWORDS
    mov rdi, rdx
    cld
    rep stosq

    mov rax, [rbx + NEBOC_LINE_MAP_SOURCE_ID_OFFSET]
    mov [rdx + NEBOC_SNIPPET_SOURCE_ID_OFFSET], rax
    mov [rdx + NEBOC_SNIPPET_LOGICAL_PATH_OFFSET], r13
    mov [rdx + NEBOC_SNIPPET_LOGICAL_PATH_LENGTH_OFFSET], r14
    mov rax, [rbx + NEBOC_LINE_MAP_SOURCE_OFFSET]
    add rax, r10
    jc .invalid_after_zero
    mov [rdx + NEBOC_SNIPPET_BYTES_OFFSET], rax
    mov rax, r11
    sub rax, r10
    mov [rdx + NEBOC_SNIPPET_BYTE_LENGTH_OFFSET], rax
    mov rax, [rsp + 16 + NEBOC_SOURCE_LOCATION_LINE_OFFSET]
    mov [rdx + NEBOC_SNIPPET_LINE_OFFSET], rax
    mov rax, [rsp + 16 + NEBOC_SOURCE_LOCATION_COLUMN_OFFSET]
    mov [rdx + NEBOC_SNIPPET_COLUMN_START_OFFSET], rax
    mov rax, [rsp + 64 + NEBOC_SOURCE_LOCATION_COLUMN_OFFSET]
    mov [rdx + NEBOC_SNIPPET_COLUMN_END_OFFSET], rax
    mov [rdx + NEBOC_SNIPPET_WINDOW_START_OFFSET], r10
    mov rax, [r12 + NEBOC_SOURCE_SPAN_START_OFFSET]
    sub rax, r10
    jc .invalid_after_zero
    mov [rdx + NEBOC_SNIPPET_HIGHLIGHT_START_OFFSET], rax
    mov rax, [r12 + NEBOC_SOURCE_SPAN_END_OFFSET]
    sub rax, r10
    jc .invalid_after_zero
    mov [rdx + NEBOC_SNIPPET_HIGHLIGHT_END_OFFSET], rax
    xor eax, eax
    cmp r10, r8
    je .flag_right
    or eax, NEBOC_SNIPPET_FLAG_TRUNCATED_LEFT
.flag_right:
    cmp r11, r9
    je .store_flags
    or eax, NEBOC_SNIPPET_FLAG_TRUNCATED_RIGHT
.store_flags:
    mov [rdx + NEBOC_SNIPPET_FLAGS_OFFSET], rax
    xor eax, eax
    jmp .finish
.invalid_after_zero:
    mov eax, NEBOC_STATUS_INTERNAL_ERROR
    jmp .finish
.invalid:
    mov eax, NEBOC_STATUS_INVALID_ARGUMENT
.finish:
    add rsp, 112
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.invalid_fast:
    NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
