bits 64
default rel

%include "runtime/textual/render_console.inc"

section .text

global neboc_render_plan_validate
global neboc_render_plan_measure
global neboc_render_plan_write
global neboc_render_feature_available
global neboc_render_feature_validate
global neboc_render_style_token_validate
global neboc_render_structure_token_validate
global neboc_render_developer_token_validate
global neboc_render_operation_token_validate
global neboc_render_policy_token_validate
global neboc_render_target_token_validate

; RAX target token, RDX bounded routing metadata, RCX policy flags.
; EAX is zero or -RENDER_E_INVALID.
render_target_validate:
    cmp rax,RENDER_TARGET_TOKEN_OUTPUT
    jb .invalid
    cmp rax,RENDER_TARGET_TOKEN_MAX
    ja .invalid
    mov rdi,rcx
    and rdi,~(RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE|RENDER_FLAG_REDACT)
    jnz .invalid
    test rcx,RENDER_FLAG_FALLBACK
    jz .invalid
    cmp rax,RENDER_TARGET_TOKEN_OUTPUT
    je .output
    cmp rax,RENDER_TARGET_TOKEN_VISUAL
    je .visual
    cmp rax,RENDER_TARGET_TOKEN_FILE
    je .file
    cmp rax,RENDER_TARGET_TOKEN_EVENT
    je .event
    cmp rax,RENDER_TARGET_TOKEN_ROUTER
    je .router
    cmp rax,RENDER_TARGET_TOKEN_LIFECYCLE
    je .lifecycle
    test rdx,rdx
    jnz .invalid
    xor eax,eax
    ret
.output:
    cmp rdx,RENDER_TARGET_PLAIN
    jb .invalid
    cmp rdx,RENDER_TARGET_HEADLESS
    ja .invalid
    xor eax,eax
    ret
.visual:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_VISUAL_MAX
    ja .invalid
    xor eax,eax
    ret
.file:
    cmp rdx,RENDER_FILE_OVERWRITE
    jb .invalid
    cmp rdx,RENDER_FILE_MAX
    ja .invalid
    xor eax,eax
    ret
.event:
    cmp rdx,RENDER_EVENT_JSONL
    jb .invalid
    cmp rdx,RENDER_EVENT_MAX
    ja .invalid
    xor eax,eax
    ret
.router:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_ROUTER_MAX_MASK
    ja .invalid
    xor eax,eax
    ret
.lifecycle:
    cmp rdx,RENDER_LIFECYCLE_OPEN
    jb .invalid
    cmp rdx,RENDER_LIFECYCLE_MAX
    ja .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,-RENDER_E_INVALID
    ret

; RDI token, RSI routing metadata, RDX flags -> EAX typed status.
neboc_render_target_token_validate:
    mov rax,rdi
    mov rcx,rdx
    mov rdx,rsi
    call render_target_validate
    test eax,eax
    js .error
    xor eax,eax
    ret
.error:
    neg eax
    ret

; RAX policy token, RDX explicit metadata, RCX policy flags.
; EAX is zero or -RENDER_E_INVALID.
render_policy_validate:
    cmp rax,RENDER_POLICY_SECURITY
    jb .invalid
    cmp rax,RENDER_POLICY_MAX
    ja .invalid
    mov rdi,rcx
    and rdi,~(RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE|RENDER_FLAG_REDACT)
    jnz .invalid
    test rcx,RENDER_FLAG_FALLBACK
    jz .invalid
    cmp rax,RENDER_POLICY_SECURITY
    je .security
    cmp rax,RENDER_POLICY_ESCAPE
    je .escape
    cmp rax,RENDER_POLICY_LOCALE
    je .locale
    cmp rax,RENDER_POLICY_ACCESSIBILITY
    je .access
    cmp rax,RENDER_POLICY_FALLBACK
    je .fallback
    cmp rax,RENDER_POLICY_TERMINAL
    je .terminal
    cmp rax,RENDER_POLICY_PRIVACY
    je .privacy
    test rdx,rdx
    jnz .invalid
    xor eax,eax
    ret
.security:
    test rdx,rdx
    jz .invalid
    cmp rdx,64
    ja .invalid
    xor eax,eax
    ret
.escape:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_SINK_MAX
    ja .invalid
    xor eax,eax
    ret
.locale:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_LOCALE_MAX
    ja .invalid
    xor eax,eax
    ret
.access:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_ACCESS_MAX
    ja .invalid
    xor eax,eax
    ret
.fallback:
    cmp rdx,RENDER_TARGET_PLAIN
    jb .invalid
    cmp rdx,RENDER_TARGET_HEADLESS
    ja .invalid
    xor eax,eax
    ret
.terminal:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_TERMINAL_MAX
    ja .invalid
    xor eax,eax
    ret
.privacy:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_PRIVACY_MAX
    ja .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,-RENDER_E_INVALID
    ret

; RDI token, RSI metadata, RDX flags -> EAX typed status.
neboc_render_policy_token_validate:
    mov rax,rdi
    mov rcx,rdx
    mov rdx,rsi
    call render_policy_validate
    test eax,eax
    js .error
    xor eax,eax
    ret
.error:
    neg eax
    ret

; RAX operation token, RDX bounded token metadata, RCX policy flags.
; EAX is zero or -RENDER_E_INVALID.
render_operation_validate:
    cmp rax,RENDER_OPERATION_LOG
    jb .invalid
    cmp rax,RENDER_OPERATION_MAX
    ja .invalid
    mov rdi,rcx
    and rdi,~(RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE|RENDER_FLAG_REDACT)
    jnz .invalid
    cmp rax,RENDER_OPERATION_LOG
    je .log
    cmp rax,RENDER_OPERATION_BUFFER
    je .buffer
    cmp rax,RENDER_OPERATION_PROGRESS
    je .progress
    cmp rax,RENDER_OPERATION_TIME
    je .time
    cmp rax,RENDER_OPERATION_RATE
    je .rate
    test rdx,rdx
    jnz .invalid
    xor eax,eax
    ret
.log:
    cmp rdx,1
    jne .invalid
    xor eax,eax
    ret
.buffer:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_OPERATION_MAX_CAPACITY
    ja .invalid
    xor eax,eax
    ret
.progress:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_OPERATION_MAX_PROGRESS
    ja .invalid
    xor eax,eax
    ret
.time:
    cmp rdx,RENDER_OPERATION_MAX_FAKE_MS
    ja .invalid
    xor eax,eax
    ret
.rate:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_OPERATION_MAX_INTERVAL
    ja .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,-RENDER_E_INVALID
    ret

; RDI token, RSI metadata, RDX flags -> EAX typed status.
neboc_render_operation_token_validate:
    mov rax,rdi
    mov rcx,rdx
    mov rdx,rsi
    call render_operation_validate
    test eax,eax
    js .error
    xor eax,eax
    ret
.error:
    neg eax
    ret

; RAX developer token, RDX structural depth, RCX policy flags.
; EAX is zero or -RENDER_E_INVALID.
render_developer_validate:
    cmp rax,RENDER_DEVELOPER_CODE
    jb .invalid
    cmp rax,RENDER_DEVELOPER_MAX
    ja .invalid
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_DEVELOPER_MAX_DEPTH
    ja .invalid
    mov rdi,rcx
    and rdi,~(RENDER_FLAG_FALLBACK|RENDER_FLAG_PRIVATE|RENDER_FLAG_REDACT|RENDER_FLAG_DEBUG)
    jnz .invalid
    cmp rax,RENDER_DEVELOPER_INSPECTION
    je .inspection
    test rcx,RENDER_FLAG_DEBUG
    jnz .invalid
    xor eax,eax
    ret
.inspection:
    test rcx,RENDER_FLAG_DEBUG
    jz .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,-RENDER_E_INVALID
    ret

; RDI token, RSI depth, RDX flags -> EAX typed status.
neboc_render_developer_token_validate:
    mov rax,rdi
    mov rcx,rdx
    mov rdx,rsi
    call render_developer_validate
    test eax,eax
    js .error
    xor eax,eax
    ret
.error:
    neg eax
    ret

; RAX structure token, RDX optional display-cell width.
; EAX is zero or -RENDER_E_INVALID.
render_structure_validate:
    cmp rax,RENDER_STRUCTURE_TITLE
    jb .invalid
    cmp rax,RENDER_STRUCTURE_MAX
    ja .invalid
    cmp rax,RENDER_STRUCTURE_WIDTH
    je .width
    test rdx,rdx
    jnz .invalid
    xor eax,eax
    ret
.width:
    test rdx,rdx
    jz .invalid
    cmp rdx,RENDER_MAX_DISPLAY_CELLS
    ja .invalid
    xor eax,eax
    ret
.invalid:
    mov eax,-RENDER_E_INVALID
    ret

; RDI token, RSI auxiliary width -> EAX typed status.
neboc_render_structure_token_validate:
    mov rax,rdi
    mov rdx,rsi
    call render_structure_validate
    test eax,eax
    js .error
    xor eax,eax
    ret
.error:
    neg eax
    ret

; RAX style token, RDX packed 0xRRGGBB auxiliary value.
; EAX is ANSI byte length or -RENDER_E_INVALID. Other targets strip the token.
render_style_length:
    cmp rax, RENDER_STYLE_RESET
    jb .invalid
    cmp rax, RENDER_STYLE_BLINK
    jbe .four
    cmp rax, RENDER_STYLE_FG_RED
    jb .invalid
    cmp rax, RENDER_STYLE_FG_GRAY
    jbe .five
    cmp rax, RENDER_STYLE_FG_RGB
    je .rgb
    cmp rax, RENDER_STYLE_BG_BLUE
    je .five
    cmp rax, RENDER_STYLE_GENERIC
    je .four
    cmp rax, RENDER_STYLE_THEME
    je .five
.invalid:
    mov eax,-RENDER_E_INVALID
    ret
.four:
    test rdx,rdx
    jnz .invalid
    mov eax,4
    ret
.five:
    test rdx,rdx
    jnz .invalid
    mov eax,5
    ret
.rgb:
    cmp rdx,0xffffff
    ja .invalid
    mov eax,19
    ret

; RDI token, RSI aux -> EAX typed status.
neboc_render_style_token_validate:
    mov rax,rdi
    mov rdx,rsi
    call render_style_length
    test eax,eax
    js .error
    xor eax,eax
    ret
.error:
    neg eax
    ret

; EAX style token, EDX packed RGB, RDI destination -> EAX bytes written.
render_style_write:
    cmp eax,RENDER_STYLE_FG_RGB
    je .rgb
    mov byte [rdi],27
    mov byte [rdi+1],'['
    cmp eax,RENDER_STYLE_RESET
    je .code0
    cmp eax,RENDER_STYLE_BOLD
    je .code1
    cmp eax,RENDER_STYLE_ITALIC
    je .code3
    cmp eax,RENDER_STYLE_UNDERLINE
    je .code4
    cmp eax,RENDER_STYLE_DIM
    je .code2
    cmp eax,RENDER_STYLE_INVERSE
    je .code7
    cmp eax,RENDER_STYLE_BLINK
    je .code5
    cmp eax,RENDER_STYLE_GENERIC
    je .code1
    mov byte [rdi+2],'3'
    cmp eax,RENDER_STYLE_FG_RED
    je .second1
    cmp eax,RENDER_STYLE_FG_GREEN
    je .second2
    cmp eax,RENDER_STYLE_FG_BLUE
    je .second4
    cmp eax,RENDER_STYLE_FG_YELLOW
    je .second3
    cmp eax,RENDER_STYLE_FG_CYAN
    je .second6
    cmp eax,RENDER_STYLE_FG_MAGENTA
    je .second5
    cmp eax,RENDER_STYLE_FG_GRAY
    je .gray
    cmp eax,RENDER_STYLE_BG_BLUE
    je .bg_blue
    ; Bounded theme maps to cyan while retaining semantic token identity.
    mov byte [rdi+3],'6'
    jmp .five_done
.second1: mov byte [rdi+3],'1'
    jmp .five_done
.second2: mov byte [rdi+3],'2'
    jmp .five_done
.second3: mov byte [rdi+3],'3'
    jmp .five_done
.second4: mov byte [rdi+3],'4'
    jmp .five_done
.second5: mov byte [rdi+3],'5'
    jmp .five_done
.second6: mov byte [rdi+3],'6'
    jmp .five_done
.gray:
    mov byte [rdi+2],'9'
    mov byte [rdi+3],'0'
    jmp .five_done
.bg_blue:
    mov byte [rdi+2],'4'
    mov byte [rdi+3],'4'
.five_done:
    mov byte [rdi+4],'m'
    mov eax,5
    ret
.code0: mov byte [rdi+2],'0'
    jmp .four_done
.code1: mov byte [rdi+2],'1'
    jmp .four_done
.code2: mov byte [rdi+2],'2'
    jmp .four_done
.code3: mov byte [rdi+2],'3'
    jmp .four_done
.code4: mov byte [rdi+2],'4'
    jmp .four_done
.code5: mov byte [rdi+2],'5'
    jmp .four_done
.code7: mov byte [rdi+2],'7'
.four_done:
    mov byte [rdi+3],'m'
    mov eax,4
    ret
.rgb:
    mov byte [rdi],27
    mov byte [rdi+1],'['
    mov byte [rdi+2],'3'
    mov byte [rdi+3],'8'
    mov byte [rdi+4],';'
    mov byte [rdi+5],'2'
    mov byte [rdi+6],';'
%macro RENDER_RGB_DECIMAL 2
    mov eax,edx
    shr eax,%1
    and eax,0xff
    xor edx,edx
    mov ecx,100
    div ecx
    add al,'0'
    mov [rdi+%2],al
    mov eax,edx
    xor edx,edx
    mov ecx,10
    div ecx
    add al,'0'
    mov [rdi+%2+1],al
    add dl,'0'
    mov [rdi+%2+2],dl
%endmacro
    mov r8d,edx
    mov edx,r8d
    RENDER_RGB_DECIMAL 16,7
    mov byte [rdi+10],';'
    mov edx,r8d
    RENDER_RGB_DECIMAL 8,11
    mov byte [rdi+14],';'
    mov edx,r8d
    RENDER_RGB_DECIMAL 0,15
    mov byte [rdi+18],'m'
    mov eax,19
    ret
%undef RENDER_RGB_DECIMAL

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
    cmp rax, RENDER_NODE_TARGET
    ja .invalid
    test qword [r8 + RENDER_NODE_FLAGS], RENDER_FLAG_FALLBACK
    jz .invalid
    cmp rax, RENDER_NODE_STYLE
    je .style
    cmp rax, RENDER_NODE_STRUCTURE
    je .structure
    cmp rax, RENDER_NODE_DEVELOPER
    je .developer
    cmp rax, RENDER_NODE_OPERATION
    je .operation
    cmp rax, RENDER_NODE_POLICY
    je .policy
    cmp rax, RENDER_NODE_TARGET
    je .target_token
    cmp rax, RENDER_NODE_BREAK
    je .break
.content:
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
.style:
    mov rax,[r8+RENDER_NODE_META]
    mov rdx,[r8+RENDER_NODE_AUX]
    call render_style_length
    test eax,eax
    js .invalid
    cmp r10d,RENDER_TARGET_ANSI
    jne .next
    add r11,rax
    jc .limit
    jmp .bounded
.structure:
    mov rax,[r8+RENDER_NODE_META]
    mov rdx,[r8+RENDER_NODE_AUX]
    call render_structure_validate
    test eax,eax
    js .invalid
    jmp .content
.developer:
    mov rax,[r8+RENDER_NODE_META]
    mov rdx,[r8+RENDER_NODE_AUX]
    mov rcx,[r8+RENDER_NODE_FLAGS]
    call render_developer_validate
    test eax,eax
    js .invalid
    jmp .content
.operation:
    mov rax,[r8+RENDER_NODE_META]
    mov rdx,[r8+RENDER_NODE_AUX]
    mov rcx,[r8+RENDER_NODE_FLAGS]
    call render_operation_validate
    test eax,eax
    js .invalid
    jmp .content
.policy:
    mov rax,[r8+RENDER_NODE_META]
    mov rdx,[r8+RENDER_NODE_AUX]
    mov rcx,[r8+RENDER_NODE_FLAGS]
    call render_policy_validate
    test eax,eax
    js .invalid
    jmp .content
.target_token:
    mov rax,[r8+RENDER_NODE_META]
    mov rdx,[r8+RENDER_NODE_AUX]
    mov rcx,[r8+RENDER_NODE_FLAGS]
    call render_target_validate
    test eax,eax
    js .invalid
    jmp .content
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
    je .style
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
.style:
    mov eax,[r9+RENDER_NODE_META]
    mov edx,[r9+RENDER_NODE_AUX]
    cmp r14d,RENDER_TARGET_ANSI
    jne .next
    mov rdi,r11
    call render_style_write
    add r11,rax
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
