bits 64
default rel

%include "runtime/textual/format_language.inc"

extern neboc_format_parse_balanced

section .text

global neboc_format_plan_validate
global neboc_format_plan_measure
global neboc_format_plan_write
global neboc_format_plan_byte_size_checked
global neboc_format_plan_render_to
global neboc_format_plan_clone
global neboc_format_plan_drop
global neboc_format_string_parse_checked
global neboc_format_string_validate
global neboc_text_format
global neboc_text_format_named
global neboc_text_format_with
global neboc_text_console
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
    cmp rax, FORMAT_NODE_POSITION
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
    cmp rax, FORMAT_NODE_POSITION
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
    ; Aliasing an output with the descriptor or any source slice would make a
    ; forward copy observably order-dependent. Reject every overlap before the
    ; first byte is committed, preserving the failure-atomic contract.
    mov rax, r13
    shl rax, 5
    lea rcx, [r12 + rax]
    lea rdx, [r14 + rbx]
    cmp rdx, r14
    jb .invalid
    cmp r14, rcx
    jae .check_data_overlap
    cmp rdx, r12
    ja .invalid
.check_data_overlap:
    mov r8, r12
    mov r9, r13
.overlap_node:
    test r9, r9
    jz .copy_begin
    mov rsi, [r8 + FORMAT_NODE_DATA]
    mov rcx, [r8 + FORMAT_NODE_LENGTH]
    test rcx, rcx
    jz .overlap_next
    lea rdi, [rsi + rcx]
    cmp rdi, rsi
    jb .invalid
    cmp r14, rdi
    jae .overlap_next
    cmp rdx, rsi
    ja .invalid
.overlap_next:
    add r8, FORMAT_NODE_SIZE
    dec r9
    jmp .overlap_node
.copy_begin:
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

; Public spelling bridges. The shared implementation is the single semantic
; owner, so aliases cannot drift from measure/write or atomicity.
neboc_format_plan_byte_size_checked:
    jmp neboc_format_plan_measure

neboc_format_plan_render_to:
    jmp neboc_format_plan_write

; rdi=live plan, rsi=destination descriptor -> typed status.
neboc_format_plan_clone:
    test rdi, rdi
    jz .clone_invalid
    test rsi, rsi
    jz .clone_invalid
    cmp rdi, rsi
    je .clone_invalid
    cmp qword [rdi + FORMAT_PLAN_STATE], FORMAT_PLAN_LIVE
    jne .clone_invalid
    mov rax, [rdi + FORMAT_PLAN_COUNT]
    cmp rax, FORMAT_MAX_NODES
    ja .clone_invalid
    test rax, rax
    jz .clone_copy
    cmp qword [rdi + FORMAT_PLAN_NODES], 0
    je .clone_invalid
.clone_copy:
    mov rax, [rdi + FORMAT_PLAN_NODES]
    mov [rsi + FORMAT_PLAN_NODES], rax
    mov rax, [rdi + FORMAT_PLAN_COUNT]
    mov [rsi + FORMAT_PLAN_COUNT], rax
    mov rax, [rdi + FORMAT_PLAN_GENERATION]
    mov [rsi + FORMAT_PLAN_GENERATION], rax
    mov qword [rsi + FORMAT_PLAN_STATE], FORMAT_PLAN_LIVE
    xor eax, eax
    ret
.clone_invalid:
    mov eax, FORMAT_E_INVALID
    ret

; rdi=plan. Drop is idempotent and invalidates no sibling clone.
neboc_format_plan_drop:
    test rdi, rdi
    jz .drop_invalid
    mov qword [rdi + FORMAT_PLAN_NODES], 0
    mov qword [rdi + FORMAT_PLAN_COUNT], 0
    mov qword [rdi + FORMAT_PLAN_GENERATION], 0
    mov qword [rdi + FORMAT_PLAN_STATE], FORMAT_PLAN_DROPPED
    xor eax, eax
    ret
.drop_invalid:
    mov eax, FORMAT_E_INVALID
    ret

; rdi=decoded immutable template bytes, rsi=len, rdx=node output,
; rcx=node capacity, r8=out count. Placeholder grammar begins in G060; G059
; therefore materializes the whole decoded template as one literal node.
neboc_format_string_parse_checked:
    test r8, r8
    jz .parse_invalid
    mov qword [r8], 0
    test rsi, rsi
    jz .parse_empty
    test rdi, rdi
    jz .parse_invalid
    cmp rsi, FORMAT_MAX_INPUT
    ja .parse_limit
    test rdx, rdx
    jz .parse_invalid
    test rcx, rcx
    jz .parse_capacity
    push rdx
    push rcx
    push r8
    call neboc_format_parse_balanced
    pop r8
    pop rcx
    pop rdx
    test eax, eax
    jnz .parse_invalid
    mov qword [rdx + FORMAT_NODE_KIND], FORMAT_NODE_LITERAL
    mov [rdx + FORMAT_NODE_DATA], rdi
    mov [rdx + FORMAT_NODE_LENGTH], rsi
    mov qword [rdx + FORMAT_NODE_PROFILE], 0
    mov qword [r8], 1
.parse_empty:
    xor eax, eax
    ret
.parse_invalid:
    mov eax, FORMAT_E_SYNTAX
    ret
.parse_limit:
    mov eax, FORMAT_E_LIMIT
    ret
.parse_capacity:
    mov eax, FORMAT_E_ALLOCATION
    ret

; rdi=nodes, rsi=count, rdx=declared typed argument count. Validation is
; structural and never evaluates an argument.
neboc_format_string_validate:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    call neboc_format_plan_validate
    test eax, eax
    jnz .validate_done
    xor ebx, ebx
.validate_node:
    test r13, r13
    jz .validate_count
    cmp qword [r12 + FORMAT_NODE_KIND], FORMAT_NODE_LITERAL
    je .validate_next
    inc rbx
.validate_next:
    add r12, FORMAT_NODE_SIZE
    dec r13
    jmp .validate_node
.validate_count:
    xor eax, eax
    cmp rbx, r14
    je .validate_done
    mov eax, FORMAT_E_INVALID
.validate_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

neboc_text_format:
neboc_text_format_named:
    jmp neboc_format_plan_write

; Same ABI as text_format plus r8=FormatEffectPolicy. G059 freezes policy 0
; (pure, left-to-right, exactly-once); unknown policies fail before output.
neboc_text_format_with:
    test r8, r8
    jnz .format_policy
    jmp neboc_format_plan_write
.format_policy:
    mov rax, -FORMAT_E_EFFECT
    ret

; rdi=formatted Text bytes, rsi=len, rdx=ConsoleOptions or null.
; This is the sole G059 output effect; format/measure/write remain silent.
neboc_text_console:
    test rsi, rsi
    jz .console_ok
    test rdi, rdi
    jz .console_invalid
    mov r8d, 1
    test rdx, rdx
    jz .console_write
    cmp qword [rdx + FORMAT_CONSOLE_FLAGS], 0
    jne .console_invalid
    mov r8, [rdx + FORMAT_CONSOLE_FD]
    cmp r8, 1
    je .console_write
    cmp r8, 2
    jne .console_invalid
.console_write:
    mov r9, rsi
    mov r10, rsi
    mov rsi, rdi
    mov rdi, r8
.console_write_loop:
    mov rdx, r10
    mov eax, 1
    syscall
    test rax, rax
    jns .console_progress
    cmp eax, -4                 ; Linux EINTR
    je .console_write_loop
    jmp .console_allocation
.console_progress:
    test rax, rax
    jz .console_allocation
    add rsi, rax
    sub r10, rax
    jnz .console_write_loop
    mov rax, r9
    ret
.console_ok:
    xor eax, eax
    ret
.console_invalid:
    mov rax, -FORMAT_E_INVALID
    ret
.console_allocation:
    mov rax, -FORMAT_E_ALLOCATION
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
