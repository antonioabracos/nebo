bits 64
default rel

%include "runtime/textual/render_console.inc"

section .text

global neboc_render_plan_validate
global neboc_render_plan_measure
global neboc_render_plan_write
global neboc_render_feature_available
global neboc_render_feature_validate

; rdi = nodes, rsi = count, edx = target
; rax = measured bytes or negative typed status.
neboc_render_plan_measure:
    cmp rsi, RENDER_MAX_NODES
    ja .limit
    cmp edx, RENDER_TARGET_PLAIN
    jb .target
    cmp edx, RENDER_TARGET_HEADLESS
    ja .target
    test rsi, rsi
    jz .zero
    test rdi, rdi
    jz .invalid
    mov r8, rdi
    mov r9, rsi
    mov r10d, edx
    xor r11d, r11d
.node:
    mov rax, [r8 + RENDER_NODE_KIND]
    cmp rax, RENDER_NODE_TEXT
    jb .invalid
    cmp rax, RENDER_NODE_STRUCTURE
    ja .invalid
    test qword [r8 + RENDER_NODE_FLAGS], RENDER_FLAG_FALLBACK
    jz .invalid
    cmp rax, RENDER_NODE_STYLE
    je .next
    cmp rax, RENDER_NODE_BREAK
    je .break
    mov rax, [r8 + RENDER_NODE_FLAGS]
    test rax, RENDER_FLAG_PRIVATE
    jz .payload
    test rax, RENDER_FLAG_REDACT
    jz .privacy
    add r11, 10
    jc .limit
    jmp .bounded
.break:
    inc r11
    jz .limit
    jmp .bounded
.payload:
    mov rcx, [r8 + RENDER_NODE_LENGTH]
    cmp rcx, RENDER_MAX_PAYLOAD
    ja .limit
    test rcx, rcx
    jz .next
    mov rdi, [r8 + RENDER_NODE_DATA]
    test rdi, rdi
    jz .invalid
    cmp r10d, RENDER_TARGET_HTML
    jne .plain_size
.html_size:
    movzx eax, byte [rdi]
    inc rdi
    cmp al, '&'
    je .html_amp
    cmp al, '<'
    je .html_four
    cmp al, '>'
    je .html_four
    cmp al, '"'
    je .html_quote
    inc r11
    jz .limit
    jmp .html_continue
.html_amp:
    add r11, 5
    jc .limit
    jmp .html_continue
.html_four:
    add r11, 4
    jc .limit
    jmp .html_continue
.html_quote:
    add r11, 6
    jc .limit
.html_continue:
    cmp r11, RENDER_MAX_OUTPUT
    ja .limit
    dec rcx
    jnz .html_size
    jmp .next
.plain_size:
    add r11, rcx
    jc .limit
.bounded:
    cmp r11, RENDER_MAX_OUTPUT
    ja .limit
.next:
    add r8, RENDER_NODE_SIZE
    dec r9
    jnz .node
    mov rax, r11
    ret
.zero:
    xor eax, eax
    ret
.invalid:
    mov rax, -RENDER_E_INVALID
    ret
.limit:
    mov rax, -RENDER_E_LIMIT
    ret
.target:
    mov rax, -RENDER_E_TARGET
    ret
.privacy:
    mov rax, -RENDER_E_PRIVACY
    ret

; rdi = nodes, rsi = count, edx = target
; eax = typed status.
neboc_render_plan_validate:
    sub rsp, 8
    call neboc_render_plan_measure
    add rsp, 8
    test rax, rax
    js .error
    xor eax, eax
    ret
.error:
    neg eax
    ret

; rdi = nodes, rsi = count, edx = target, rcx = output, r8 = capacity
; rax = bytes committed or negative typed status. Output is untouched on error.
neboc_render_plan_write:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    mov r15, rcx
    mov rbx, r8
    call neboc_render_plan_measure
    test rax, rax
    js .done
    cmp rax, rbx
    ja .capacity
    mov rbx, rax
    test rax, rax
    jz .success
    test r15, r15
    jz .invalid
    mov r9, r12
    mov r10, r13
    mov r11, r15
.node:
    mov rax, [r9 + RENDER_NODE_KIND]
    cmp rax, RENDER_NODE_STYLE
    je .next
    cmp rax, RENDER_NODE_BREAK
    je .break
    mov rax, [r9 + RENDER_NODE_FLAGS]
    test rax, RENDER_FLAG_PRIVATE
    jnz .redacted
    mov rsi, [r9 + RENDER_NODE_DATA]
    mov rcx, [r9 + RENDER_NODE_LENGTH]
    test rcx, rcx
    jz .next
    cmp r14d, RENDER_TARGET_HTML
    je .html
    mov rdi, r11
    rep movsb
    mov r11, rdi
    jmp .next
.html:
    lodsb
    cmp al, '&'
    je .emit_amp
    cmp al, '<'
    je .emit_lt
    cmp al, '>'
    je .emit_gt
    cmp al, '"'
    je .emit_quote
    mov [r11], al
    inc r11
    jmp .html_continue
.emit_amp:
    mov byte [r11], '&'
    mov byte [r11 + 1], 'a'
    mov byte [r11 + 2], 'm'
    mov byte [r11 + 3], 'p'
    mov byte [r11 + 4], ';'
    add r11, 5
    jmp .html_continue
.emit_lt:
    mov byte [r11], '&'
    mov byte [r11 + 1], 'l'
    mov byte [r11 + 2], 't'
    mov byte [r11 + 3], ';'
    add r11, 4
    jmp .html_continue
.emit_gt:
    mov byte [r11], '&'
    mov byte [r11 + 1], 'g'
    mov byte [r11 + 2], 't'
    mov byte [r11 + 3], ';'
    add r11, 4
    jmp .html_continue
.emit_quote:
    mov byte [r11], '&'
    mov byte [r11 + 1], 'q'
    mov byte [r11 + 2], 'u'
    mov byte [r11 + 3], 'o'
    mov byte [r11 + 4], 't'
    mov byte [r11 + 5], ';'
    add r11, 6
.html_continue:
    dec rcx
    jnz .html
    jmp .next
.break:
    mov byte [r11], 10
    inc r11
    jmp .next
.redacted:
    mov byte [r11], '['
    mov byte [r11 + 1], 'r'
    mov byte [r11 + 2], 'e'
    mov byte [r11 + 3], 'd'
    mov byte [r11 + 4], 'a'
    mov byte [r11 + 5], 'c'
    mov byte [r11 + 6], 't'
    mov byte [r11 + 7], 'e'
    mov byte [r11 + 8], 'd'
    mov byte [r11 + 9], ']'
    add r11, 10
.next:
    add r9, RENDER_NODE_SIZE
    dec r10
    jnz .node
.success:
    mov rax, rbx
    jmp .done
.capacity:
    mov rax, -RENDER_E_CAPACITY
    jmp .done
.invalid:
    mov rax, -RENDER_E_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi = feature id (group * 100 + front ordinal)
; eax = 1 only for the activated O3 DAG prefix.
neboc_render_feature_available:
    cmp rdi, RENDER_MAX_FEATURE_ID
    ja .no
    mov rax, rdi
    xor edx, edx
    mov ecx, 100
    div rcx
    test edx, edx
    jz .no
    cmp eax, 66
    jb .no
    cmp eax, 74
    ja .no
    cmp eax, 66
    je .five
    cmp eax, 67
    je .five
    cmp eax, 68
    je .seven
    cmp eax, 69
    je .seven
    cmp eax, 70
    je .six
    cmp eax, 71
    je .eight
    cmp eax, 72
    je .seven
    cmp eax, 73
    je .six
    cmp edx, 7
    jbe .yes
    jmp .no
.five:
    cmp edx, 5
    jbe .yes
    jmp .no
.six:
    cmp edx, 6
    jbe .yes
    jmp .no
.seven:
    cmp edx, 7
    jbe .yes
    jmp .no
.eight:
    cmp edx, 8
    jbe .yes
    jmp .no
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

; rdi = feature, rsi = policy flags, rdx = payload bytes,
; rcx = structural depth, r8d = target. This validates semantic policy,
; never a fixture, path, source hash or whole-source fingerprint.
neboc_render_feature_validate:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rbx, rcx
    call neboc_render_feature_available
    test eax, eax
    jz .unavailable
    cmp r14, RENDER_MAX_PAYLOAD
    ja .limit
    cmp rbx, RENDER_MAX_DEPTH
    ja .limit
    cmp r8d, RENDER_TARGET_PLAIN
    jb .target
    cmp r8d, RENDER_TARGET_HEADLESS
    ja .target
    mov rax, r12
    xor edx, edx
    mov ecx, 100
    div rcx
    cmp eax, 67
    jb .privacy_check
    test r13, RENDER_FLAG_FALLBACK
    jz .invalid
.privacy_check:
    test r13, RENDER_FLAG_PRIVATE
    jz .conditional
    test r13, RENDER_FLAG_REDACT
    jz .privacy
.conditional:
    cmp eax, 74
    jne .ok
    cmp rbx, 8
    ja .limit
.ok:
    xor eax, eax
    jmp .return
.invalid:
    mov eax, RENDER_E_INVALID
    jmp .return
.limit:
    mov eax, RENDER_E_LIMIT
    jmp .return
.target:
    mov eax, RENDER_E_TARGET
    jmp .return
.privacy:
    mov eax, RENDER_E_PRIVACY
    jmp .return
.unavailable:
    mov eax, RENDER_E_UNAVAILABLE
.return:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
