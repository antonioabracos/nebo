bits 64
default rel

%include "runtime/textual/format_language.inc"

section .text

global neboc_format_plan_validate
global neboc_format_plan_measure
global neboc_format_plan_write
global neboc_format_feature_available
global neboc_format_feature_validate

; rdi = node pointer, rsi = node count
; rax = typed status
neboc_format_plan_validate:
    cmp rsi, FORMAT_MAX_NODES
    ja .limit
    test rsi, rsi
    jz .ok
    test rdi, rdi
    jz .invalid
    xor r8, r8
.node:
    mov rax, [rdi + FORMAT_NODE_KIND]
    cmp rax, FORMAT_NODE_LITERAL
    jb .invalid
    cmp rax, FORMAT_NODE_STYLE_CLOSE
    ja .invalid
    mov rax, [rdi + FORMAT_NODE_LENGTH]
    test rax, rax
    jz .add
    cmp qword [rdi + FORMAT_NODE_DATA], 0
    je .invalid
.add:
    add r8, rax
    jc .limit
    cmp r8, FORMAT_MAX_OUTPUT
    ja .limit
    add rdi, FORMAT_NODE_SIZE
    dec rsi
    jnz .node
.ok:
    xor eax, eax
    ret
.invalid:
    mov eax, FORMAT_E_INVALID
    ret
.limit:
    mov eax, FORMAT_E_LIMIT
    ret

; rdi = node pointer, rsi = node count
; rax = byte count, or negative typed status
neboc_format_plan_measure:
    cmp rsi, FORMAT_MAX_NODES
    ja .limit
    test rsi, rsi
    jz .zero
    test rdi, rdi
    jz .invalid
    xor r8, r8
.node:
    mov rax, [rdi + FORMAT_NODE_KIND]
    cmp rax, FORMAT_NODE_LITERAL
    jb .invalid
    cmp rax, FORMAT_NODE_STYLE_CLOSE
    ja .invalid
    mov rax, [rdi + FORMAT_NODE_LENGTH]
    test rax, rax
    jz .add
    cmp qword [rdi + FORMAT_NODE_DATA], 0
    je .invalid
.add:
    add r8, rax
    jc .limit
    cmp r8, FORMAT_MAX_OUTPUT
    ja .limit
    add rdi, FORMAT_NODE_SIZE
    dec rsi
    jnz .node
    mov rax, r8
    ret
.zero:
    xor eax, eax
    ret
.invalid:
    mov rax, -FORMAT_E_INVALID
    ret
.limit:
    mov rax, -FORMAT_E_LIMIT
    ret

; rdi = node pointer, rsi = node count, rdx = output, rcx = capacity
; rax = bytes committed, or negative typed status. Output is untouched on error.
neboc_format_plan_write:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    call neboc_format_plan_measure
    test rax, rax
    js .done
    mov rbx, rax
    cmp rax, r15
    ja .capacity
    test rax, rax
    jz .success
    test r14, r14
    jz .invalid
    mov r8, r12
    mov r9, r13
    mov r10, r14
.copy_node:
    test r9, r9
    jz .success
    mov rsi, [r8 + FORMAT_NODE_DATA]
    mov rcx, [r8 + FORMAT_NODE_LENGTH]
    mov rdi, r10
    rep movsb
    mov r10, rdi
    add r8, FORMAT_NODE_SIZE
    dec r9
    jmp .copy_node
.success:
    mov rax, rbx
    jmp .done
.capacity:
    mov rax, -FORMAT_E_CAPACITY
    jmp .done
.invalid:
    mov rax, -FORMAT_E_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi = stable typed feature id (group * 100 + front)
; rax = 1 when activated by the current DAG prefix, else 0
neboc_format_feature_available:
    cmp rdi, FORMAT_MAX_FEATURE_ID
    ja .no
    mov rax, rdi
    xor edx, edx
    mov ecx, 100
    div rcx
    test rdx, rdx
    jz .no
    cmp rax, 59
    jb .no
    cmp rax, 65
    ja .no
    cmp rax, 59
    jne .format_language
    cmp rdx, 8
    jbe .yes
    jmp .no
.format_language:
    cmp rax, 62
    je .ten
    cmp rax, 63
    je .eight
    cmp rdx, 9
    jbe .yes
    jmp .no
.ten:
    cmp rdx, 10
    jbe .yes
    jmp .no
.eight:
    cmp rdx, 8
    jbe .yes
    jmp .no
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

; rdi = feature id, rsi = source bytes, rdx = byte length
; This is semantic-family dispatch, never fixture/path/source dispatch.
neboc_format_feature_validate:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    call neboc_format_feature_available
    test rax, rax
    jz .unavailable
    test r13, r13
    jz .invalid
    test r14, r14
    jz .syntax
    cmp r14, FORMAT_MAX_INPUT
    ja .limit
    mov rax, r12
    xor edx, edx
    mov ecx, 100
    div rcx
    cmp eax, 59
    je .identifier
    cmp eax, 60
    je .placeholder
    cmp eax, 61
    je .interpolation
    cmp eax, 62
    je .profile
    cmp eax, 63
    je .literal
    jmp .slash

.identifier:
    xor ecx, ecx
.identifier_loop:
    cmp rcx, r14
    je .ok
    mov al, [r13 + rcx]
    cmp al, 'a'
    jb .identifier_extra
    cmp al, 'z'
    jbe .identifier_next
.identifier_extra:
    cmp al, '0'
    jb .identifier_dash
    cmp al, '9'
    jbe .identifier_next
.identifier_dash:
    cmp al, '-'
    je .identifier_next
    cmp al, '_'
    jne .syntax
.identifier_next:
    inc rcx
    jmp .identifier_loop

.placeholder:
    cmp byte [r13], '%'
    jne .syntax
    cmp r14, 2
    jb .syntax
    cmp byte [r13 + 1], '{'
    je .placeholder_named
    mov rcx, 1
    xor ebx, ebx
    jmp .placeholder_loop
.placeholder_named:
    cmp r14, 6
    jb .syntax
    mov rcx, 2
.placeholder_named_scan:
    lea rax, [r14 - 3]
    cmp rcx, rax
    ja .syntax
    mov al, [r13 + rcx]
    cmp al, ':'
    je .placeholder_named_type
    cmp al, '_'
    je .placeholder_named_next
    cmp al, '0'
    jb .placeholder_named_alpha
    cmp al, '9'
    jbe .placeholder_named_next
.placeholder_named_alpha:
    call .is_alpha
    test eax, eax
    jz .syntax
.placeholder_named_next:
    inc rcx
    jmp .placeholder_named_scan
.placeholder_named_type:
    inc rcx
    xor ebx, ebx
.placeholder_loop:
    cmp rcx, r14
    je .placeholder_done
    mov al, [r13 + rcx]
    cmp al, 's'
    je .placeholder_type
    cmp al, 'q'
    je .placeholder_type
    cmp al, 'd'
    je .placeholder_type
    cmp al, 'x'
    je .placeholder_type
    cmp al, 'X'
    je .placeholder_type
    cmp al, 'b'
    je .placeholder_type
    cmp al, 'o'
    je .placeholder_type
    cmp al, 'f'
    je .placeholder_type
    cmp al, 'e'
    je .placeholder_type
    cmp al, 'E'
    je .placeholder_type
    cmp al, 'g'
    je .placeholder_type
    cmp al, 'G'
    je .placeholder_type
    cmp al, '?'
    je .placeholder_type
    cmp al, '0'
    jb .placeholder_punct
    cmp al, '9'
    jbe .placeholder_next
    cmp al, 'a'
    jb .placeholder_punct
    cmp al, 'z'
    jbe .placeholder_next
.placeholder_punct:
    cmp al, '-'
    je .placeholder_next
    cmp al, '+'
    je .placeholder_next
    cmp al, '#'
    je .placeholder_next
    cmp al, '.'
    je .placeholder_next
    cmp al, '{'
    je .placeholder_next
    cmp al, '}'
    je .placeholder_next
    cmp al, '$'
    je .placeholder_next
    cmp al, ':'
    jne .syntax
.placeholder_next:
    inc rcx
    jmp .placeholder_loop
.placeholder_type:
    mov ebx, 1
    inc rcx
    cmp rcx, r14
    je .placeholder_done
    lea rax, [r14 - 1]
    cmp rcx, rax
    jne .syntax
    cmp byte [r13 + rcx], '}'
    jne .syntax
    inc rcx
.placeholder_done:
    test ebx, ebx
    jz .syntax
    jmp .ok

.interpolation:
    cmp r14, 4
    jb .syntax
    cmp byte [r13], '$'
    jne .syntax
    cmp byte [r13 + 1], '{'
    jne .syntax
    cmp byte [r13 + r14 - 1], '}'
    jne .syntax
    mov rcx, 2
    mov ebx, 1
.interp_loop:
    lea rax, [r14 - 1]
    cmp rcx, rax
    jae .interp_done
    mov al, [r13 + rcx]
    cmp al, '!'
    je .effect
    cmp al, '='
    je .effect
    cmp al, ';'
    je .effect
    cmp al, '{'
    jne .interp_close
    inc ebx
    cmp ebx, FORMAT_MAX_SLASH_DEPTH
    ja .limit
    jmp .interp_next
.interp_close:
    cmp al, '}'
    jne .interp_next
    dec ebx
    jz .syntax
.interp_next:
    inc rcx
    jmp .interp_loop
.interp_done:
    cmp ebx, 1
    jne .syntax
    jmp .ok

.profile:
    mov al, [r13]
    call .is_alpha
    test eax, eax
    jz .syntax
    xor ecx, ecx
    xor ebx, ebx
.profile_loop:
    cmp rcx, r14
    je .profile_done
    mov al, [r13 + rcx]
    cmp al, '!'
    je .effect
    cmp al, ';'
    je .effect
    cmp al, '('
    jne .profile_close
    inc ebx
    cmp ebx, 1
    ja .syntax
    jmp .profile_next
.profile_close:
    cmp al, ')'
    jne .profile_next
    dec ebx
    js .syntax
.profile_next:
    inc rcx
    jmp .profile_loop
.profile_done:
    test ebx, ebx
    jnz .syntax
    jmp .ok

.literal:
    cmp r14, 2
    jb .syntax
    xor ecx, ecx
    xor ebx, ebx
.literal_loop:
    cmp rcx, r14
    je .literal_done
    cmp byte [r13 + rcx], '"'
    jne .literal_next
    inc ebx
.literal_next:
    inc rcx
    jmp .literal_loop
.literal_done:
    cmp ebx, 2
    jb .syntax
    test bl, 1
    jnz .syntax
    jmp .ok

.slash:
    cmp r14, 2
    jb .syntax
    cmp byte [r13], '/'
    jne .syntax
    mov al, [r13 + 1]
    call .is_alpha
    test eax, eax
    jz .syntax
    ; Explicit anti-Turing policy: loop directives are not grammar members.
    cmp r14, 4
    jb .slash_scan
    cmp dword [r13], 0x726f662f       ; /for
    je .effect
    cmp r14, 6
    jb .slash_scan
    cmp dword [r13], 0x6968772f       ; /whi...
    jne .slash_scan
    cmp word [r13 + 4], 0x656c        ; ...le
    je .effect
.slash_scan:
    xor ecx, ecx
    xor ebx, ebx
.slash_loop:
    cmp rcx, r14
    je .slash_done
    mov al, [r13 + rcx]
    cmp al, '{'
    jne .slash_close
    inc ebx
    cmp ebx, FORMAT_MAX_SLASH_DEPTH
    ja .limit
    jmp .slash_next
.slash_close:
    cmp al, '}'
    jne .slash_next
    dec ebx
    js .syntax
.slash_next:
    inc rcx
    jmp .slash_loop
.slash_done:
    test ebx, ebx
    jnz .syntax
    jmp .ok

.is_alpha:
    cmp al, 'A'
    jb .not_alpha
    cmp al, 'Z'
    jbe .alpha
    cmp al, 'a'
    jb .not_alpha
    cmp al, 'z'
    ja .not_alpha
.alpha:
    mov eax, 1
    ret
.not_alpha:
    xor eax, eax
    ret

.ok:
    xor eax, eax
    jmp .return
.invalid:
    mov eax, FORMAT_E_INVALID
    jmp .return
.limit:
    mov eax, FORMAT_E_LIMIT
    jmp .return
.syntax:
    mov eax, FORMAT_E_SYNTAX
    jmp .return
.effect:
    mov eax, FORMAT_E_EFFECT
    jmp .return
.unavailable:
    mov eax, FORMAT_E_UNAVAILABLE
.return:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
