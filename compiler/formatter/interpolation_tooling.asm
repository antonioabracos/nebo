bits 64
default rel
%include "compiler/formatter/interpolation_tooling.inc"
%include "compiler/parser/text/interpolation_plan.inc"

extern neboc_interpolation_parse_literal

section .text
global neboc_interpolation_rename_span
global neboc_interpolation_format_copy
global neboc_interpolation_highlight_counts

; rdi=template, rsi=len, rdx=out[text,delimiter,expression,profile].
; Semantic highlighting is derived from the same parsed AST summary.
neboc_interpolation_highlight_counts:
    push rbx
    sub rsp, 64
    mov rbx, rdx
    test rbx, rbx
    jz .highlight_invalid
    mov rdx, rsp
    call neboc_interpolation_parse_literal
    test eax, eax
    jnz .highlight_done
    mov rax, [rsp+INTERPOLATION_SUMMARY_LITERAL_COUNT]
    mov [rbx], rax
    mov rax, [rsp+INTERPOLATION_SUMMARY_EXPRESSION_COUNT]
    lea rcx, [rax*2]
    mov [rbx+8], rcx
    mov [rbx+16], rax
    mov rax, [rsp+INTERPOLATION_SUMMARY_PROFILE_COUNT]
    mov [rbx+24], rax
    xor eax, eax
    jmp .highlight_done
.highlight_invalid:
    mov eax, INTERPOLATION_TOOLING_E_INVALID
.highlight_done:
    add rsp, 64
    pop rbx
    ret

; rdi=template bytes, rsi=len, rdx=cursor, rcx=out[start,end].  A rename is
; bounded to one identifier identity inside an interpolation expression.
neboc_interpolation_rename_span:
    test rdi, rdi
    jz .rename_invalid
    test rcx, rcx
    jz .rename_invalid
    cmp rdx, rsi
    jae .rename_invalid
    mov al, [rdi+rdx]
    call g61_tool_is_identifier
    test eax, eax
    jz .rename_invalid
    mov r8, rdx
.rename_left:
    test r8, r8
    jz .rename_right_start
    mov al, [rdi+r8-1]
    call g61_tool_is_identifier
    test eax, eax
    jz .rename_right_start
    dec r8
    jmp .rename_left
.rename_right_start:
    mov r9, rdx
    inc r9
.rename_right:
    cmp r9, rsi
    jae .rename_bounds
    mov al, [rdi+r9]
    call g61_tool_is_identifier
    test eax, eax
    jz .rename_bounds
    inc r9
    jmp .rename_right
.rename_bounds:
    ; There must be a `${` before the identifier and a closing brace after it.
    mov r10, r8
.rename_find_start:
    test r10, r10
    jz .rename_invalid
    dec r10
    cmp byte [rdi+r10], '{'
    jne .rename_find_start
    test r10, r10
    jz .rename_invalid
    cmp byte [rdi+r10-1], '$'
    jne .rename_invalid
    mov r11, r9
.rename_find_end:
    cmp r11, rsi
    jae .rename_invalid
    cmp byte [rdi+r11], '}'
    je .rename_commit
    inc r11
    jmp .rename_find_end
.rename_commit:
    mov [rcx], r8
    mov [rcx+8], r9
    xor eax, eax
    ret
.rename_invalid:
    mov eax, INTERPOLATION_TOOLING_E_INVALID
    ret

; rdi=input, rsi=len, rdx=output, rcx=capacity. The current bounded formatter
; preserves literal bytes and escapes exactly while expression formatting is
; delegated to the normal language formatter.
neboc_interpolation_format_copy:
    test rdi, rdi
    jz .copy_invalid
    test rdx, rdx
    jz .copy_invalid
    cmp rsi, rcx
    ja .copy_capacity
    mov rax, rsi
    mov rcx, rsi
    mov rsi, rdi
    mov rdi, rdx
    rep movsb
    ret
.copy_invalid:
    mov rax, -INTERPOLATION_TOOLING_E_INVALID
    ret
.copy_capacity:
    mov rax, -INTERPOLATION_TOOLING_E_CAPACITY
    ret

g61_tool_is_identifier:
    cmp al, '_'
    je .identifier_yes
    cmp al, '0'
    jb .identifier_alpha
    cmp al, '9'
    jbe .identifier_yes
.identifier_alpha:
    and al, 0xdf
    cmp al, 'A'
    jb .identifier_no
    cmp al, 'Z'
    ja .identifier_no
.identifier_yes:
    mov eax, 1
    ret
.identifier_no:
    xor eax, eax
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
