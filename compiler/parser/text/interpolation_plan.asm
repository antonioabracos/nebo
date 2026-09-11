bits 64
default rel
%include "compiler/parser/text/interpolation_plan.inc"

extern neboc_interpolation_require_pure
section .text
global nebo_interpolation_plan
global neboc_interpolation_parse_literal
; rdi=expression count, rsi=max depth, rdx=pure flag, rcx=out[4].
; Publishes one FormatPlan fragment only after complete validation.
nebo_interpolation_plan:
    test rcx, rcx
    jz .invalid
    test rdi, rdi
    jz .invalid
    cmp rdi, 64
    ja .limit
    test rsi, rsi
    jz .invalid
    cmp rsi, 64
    ja .limit
    cmp rdx, 1
    jne .effect
    mov qword [rcx], 77
    mov [rcx+8], rdi
    mov [rcx+16], rsi
    mov qword [rcx+24], 1
    xor eax, eax
    ret
.invalid:
    mov eax, 1
    ret
.limit:
    mov eax, 2
    ret
.effect:
    mov eax, 3
    ret

; rdi=decoded/static literal bytes, rsi=length, rdx=summary.
; On success the summary is committed atomically.  On failure RDX is the
; precise byte offset and the caller's summary remains untouched.
neboc_interpolation_parse_literal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov r12, rdi
    mov r13, rsi
    mov [rsp+40], rdx
    test r12, r12
    jz .parse_invalid
    test rdx, rdx
    jz .parse_invalid
    test r13, r13
    jz .parse_syntax_zero
    cmp r13, INTERPOLATION_MAX_INPUT
    ja .parse_limit_zero
    mov qword [rsp], 0                 ; literal segments
    mov qword [rsp+8], 0               ; expression segments
    mov qword [rsp+16], 0              ; profile expressions
    mov qword [rsp+24], 1              ; maximum brace depth
    mov qword [rsp+32], INTERPOLATION_FLAG_PURE | INTERPOLATION_FLAG_LEFT_TO_RIGHT | INTERPOLATION_FLAG_EXACTLY_ONCE | INTERPOLATION_FLAG_STATIC_PLAN
    xor ebx, ebx                        ; cursor
    xor r14d, r14d                      ; current literal start
.parse_scan:
    cmp rbx, r13
    jae .parse_finish
    mov al, [r12+rbx]
    cmp al, 92
    jne .parse_dollar
    lea rax, [rbx+2]
    cmp rax, r13
    jae .parse_next
    cmp byte [r12+rbx+1], '$'
    jne .parse_next
    cmp byte [r12+rbx+2], '{'
    jne .parse_next
    ; Raw source can contain a run of slash escapes.  Odd parity escapes the
    ; interpolation start; even parity leaves `${` syntactic after decoding.
    mov rax, rbx
    xor edx, edx
.parse_escape_run:
    inc rdx
    test rax, rax
    jz .parse_escape_parity
    dec rax
    cmp byte [r12+rax], 92
    je .parse_escape_run
.parse_escape_parity:
    test dl, 1
    jz .parse_next
    or qword [rsp+32], INTERPOLATION_FLAG_ESCAPED_START
    add rbx, 3
    jmp .parse_scan
.parse_dollar:
    cmp al, '$'
    jne .parse_next
    lea rax, [rbx+1]
    cmp rax, r13
    jae .parse_next
    cmp byte [r12+rbx+1], '{'
    jne .parse_next
    cmp r14, rbx
    jae .parse_no_literal
    inc qword [rsp]
.parse_no_literal:
    inc qword [rsp+8]
    or qword [rsp+32], INTERPOLATION_FLAG_START_TOKEN | INTERPOLATION_FLAG_END_TOKEN
    mov r15, rbx
    add r15, 2                         ; expression start
    mov r10, r15                       ; inner cursor
    mov r11d, 1                        ; brace depth
    mov qword [rsp+56], -1             ; profile colon
.parse_inner:
    cmp r10, r13
    jae .parse_syntax_inner
    mov al, [r12+r10]
    cmp al, '{'
    jne .parse_inner_close
    inc r11
    cmp r11, INTERPOLATION_MAX_DEPTH
    ja .parse_limit_inner
    cmp r11, [rsp+24]
    jbe .parse_inner_next
    mov [rsp+24], r11
    jmp .parse_inner_next
.parse_inner_close:
    cmp al, '}'
    jne .parse_inner_colon
    dec r11
    jnz .parse_inner_next
    cmp r15, r10
    je .parse_syntax_inner
    mov [rsp+48], r10
    mov rax, [rsp+56]
    cmp rax, -1
    je .parse_pure_full
    cmp rax, r15
    je .parse_syntax_inner
    lea rcx, [rax+1]
    cmp rcx, r10
    jae .parse_syntax_inner
    mov rdi, r12
    add rdi, r15
    mov rsi, rax
    sub rsi, r15
    call neboc_interpolation_require_pure
    test eax, eax
    jnz .parse_effect_saved
    mov rax, [rsp+56]
    lea rcx, [rax+1]
.parse_profile_spaces:
    cmp rcx, [rsp+48]
    jae .parse_syntax_saved
    cmp byte [r12+rcx], ' '
    jne .parse_profile_name
    inc rcx
    jmp .parse_profile_spaces
.parse_profile_name:
    mov rax, [rsp+48]
    sub rax, rcx
    cmp rax, 6
    jb .parse_profile_hex
    cmp dword [r12+rcx], 'fixe'
    jne .parse_profile_align
    cmp word [r12+rcx+4], 'd('
    je .parse_profile_tail
.parse_profile_align:
    cmp dword [r12+rcx], 'alig'
    jne .parse_profile_hex
    cmp word [r12+rcx+4], 'n('
    je .parse_profile_tail
.parse_profile_hex:
    cmp rax, 4
    jb .parse_syntax_saved
    cmp dword [r12+rcx], 'hex('
    jne .parse_syntax_saved
.parse_profile_tail:
    mov rax, [rsp+48]
    cmp byte [r12+rax-1], ')'
    jne .parse_syntax_saved
    inc qword [rsp+16]
    jmp .parse_expression_done
.parse_pure_full:
    mov rdi, r12
    add rdi, r15
    mov rsi, r10
    sub rsi, r15
    call neboc_interpolation_require_pure
    test eax, eax
    jnz .parse_effect_saved
.parse_expression_done:
    mov r10, [rsp+48]
    lea rbx, [r10+1]
    mov r14, rbx
    mov rax, [rsp]
    add rax, [rsp+8]
    cmp rax, INTERPOLATION_MAX_SEGMENTS
    ja .parse_limit_saved
    jmp .parse_scan
.parse_inner_colon:
    cmp al, ':'
    jne .parse_inner_next
    cmp r11, 1
    jne .parse_inner_next
    cmp qword [rsp+56], -1
    jne .parse_inner_next             ; named profile arguments own later ':'
    mov [rsp+56], r10
.parse_inner_next:
    inc r10
    jmp .parse_inner
.parse_next:
    inc rbx
    jmp .parse_scan
.parse_finish:
    cmp qword [rsp+8], 0
    je .parse_syntax_zero
    cmp r14, r13
    jae .parse_count
    inc qword [rsp]
.parse_count:
    mov rax, [rsp]
    add rax, [rsp+8]
    cmp rax, INTERPOLATION_MAX_SEGMENTS
    ja .parse_limit_zero
    mov rdx, [rsp+40]
    mov qword [rdx+INTERPOLATION_SUMMARY_KIND], INTERPOLATED_TEXT_EXPR_KIND
    mov rax, [rsp]
    mov [rdx+INTERPOLATION_SUMMARY_LITERAL_COUNT], rax
    mov rax, [rsp+8]
    mov [rdx+INTERPOLATION_SUMMARY_EXPRESSION_COUNT], rax
    mov rax, [rsp+16]
    mov [rdx+INTERPOLATION_SUMMARY_PROFILE_COUNT], rax
    mov rax, [rsp+24]
    mov [rdx+INTERPOLATION_SUMMARY_MAX_DEPTH], rax
    mov rax, [rsp+32]
    mov [rdx+INTERPOLATION_SUMMARY_FLAGS], rax
    mov rax, [rsp]
    add rax, [rsp+8]
    mov [rdx+INTERPOLATION_SUMMARY_SEGMENT_COUNT], rax
    xor edx, edx
    xor eax, eax
    jmp .parse_done
.parse_invalid:
    xor edx, edx
    mov eax, INTERPOLATION_E_INVALID
    jmp .parse_done
.parse_syntax_inner:
    mov rdx, r10
    mov eax, INTERPOLATION_E_SYNTAX
    jmp .parse_done
.parse_syntax_saved:
    mov rdx, [rsp+48]
    mov eax, INTERPOLATION_E_SYNTAX
    jmp .parse_done
.parse_syntax_zero:
    xor edx, edx
    mov eax, INTERPOLATION_E_SYNTAX
    jmp .parse_done
.parse_limit_inner:
    mov rdx, r10
    mov eax, INTERPOLATION_E_LIMIT
    jmp .parse_done
.parse_limit_saved:
    mov rdx, [rsp+48]
    mov eax, INTERPOLATION_E_LIMIT
    jmp .parse_done
.parse_limit_zero:
    xor edx, edx
    mov eax, INTERPOLATION_E_LIMIT
    jmp .parse_done
.parse_effect_saved:
    mov rdx, [rsp+48]
    mov eax, INTERPOLATION_E_EFFECT
.parse_done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
