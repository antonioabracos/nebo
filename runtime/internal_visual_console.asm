; G110 target-neutral internal visual.console and visual.panel host services.
bits 64
default rel
%define NEBO_G110_INTERNAL_VISUAL_CONSOLE_IMPLEMENTATION 1
%include "runtime/internal_visual_console.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .text
global nebo_g110_console_open
global nebo_g110_console_close
global nebo_g110_console_status
global nebo_g110_console_configure
global nebo_g110_console_configure_headless
global nebo_g110_console_set_mode
global nebo_g110_console_set_theme
global nebo_g110_console_set_limits
global nebo_g110_console_show
global nebo_g110_console_inspect
global nebo_g110_console_fallback_text
global nebo_g110_panel_create
global nebo_g110_panel_get
global nebo_g110_panel_remove
global nebo_g110_panel_clear
global nebo_g110_panel_title
global nebo_g110_panel_type
global nebo_g110_panel_send
global nebo_g110_panel_replace
global nebo_g110_panel_append
global nebo_g110_panel_snapshot

; RDI=limits. Validate bounded resource policy without publishing state.
g110_limits_validate:
    test rdi,rdi
    jz .invalid
    mov rax,[rdi+NEBO_G110_LIMIT_LINES]
    test rax,rax
    jz .range
    cmp rax,4096
    ja .range
    mov rax,[rdi+NEBO_G110_LIMIT_BYTES]
    test rax,rax
    jz .range
    cmp rax,65536
    ja .range
    mov rax,[rdi+NEBO_G110_LIMIT_PANELS]
    test rax,rax
    jz .range
    cmp rax,64
    ja .range
    xor eax,eax
    ret
.range:
    mov eax,-NEBO_G110_ERROR_LIMIT
    ret
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
    ret

; RDI=console. Require a live, initialized service.
g110_require_open:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G110_CONSOLE_MAGIC
    cmp [rdi+NEBO_G110_CONSOLE_MAGIC_OFS],rax
    jne .invalid
    cmp qword [rdi+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_OPEN
    jne .state
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G110_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
    ret

; RDI=panel. Require an active caller-owned panel.
g110_require_panel:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G110_PANEL_MAGIC
    cmp [rdi+NEBO_G110_PANEL_MAGIC_OFS],rax
    jne .invalid
    cmp qword [rdi+NEBO_G110_PANEL_STATE],NEBO_G110_PANEL_ACTIVE
    jne .state
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G110_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
    ret

; console.open(console*, mode, theme, limits*, capabilities) -> status.
nebo_g110_console_open:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx,rdi
    mov r12d,esi
    mov r13d,edx
    mov r14,rcx
    mov r15,r8
    test rbx,rbx
    jz .invalid
    mov rax,NEBO_G110_CONSOLE_MAGIC
    cmp [rbx+NEBO_G110_CONSOLE_MAGIC_OFS],rax
    jne .mode
    cmp qword [rbx+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_OPEN
    je .busy
.mode:
    cmp r12d,NEBO_G110_MODE_PLAIN
    jb .range
    cmp r12d,NEBO_G110_MODE_MAX
    ja .range
    cmp r13d,NEBO_G110_THEME_DEFAULT
    jb .range
    cmp r13d,NEBO_G110_THEME_MAX
    ja .range
    mov rdi,r14
    call g110_limits_validate
    test eax,eax
    jnz .done
    mov rax,r15
    and rax,~NEBO_G110_CAP_ALL
    jnz .capability
    mov rax,r15
    and eax,NEBO_G110_CAP_ALL
    cmp eax,NEBO_G110_CAP_ALL
    jne .capability
    mov rdi,rbx
    mov ecx,NEBO_G110_CONSOLE_QWORDS
    xor eax,eax
    cld
    rep stosq
    mov rax,NEBO_G110_CONSOLE_MAGIC
    mov [rbx+NEBO_G110_CONSOLE_MAGIC_OFS],rax
    mov qword [rbx+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_OPEN
    mov [rbx+NEBO_G110_CONSOLE_MODE],r12
    mov [rbx+NEBO_G110_CONSOLE_THEME],r13
    mov rax,[r14+NEBO_G110_LIMIT_LINES]
    mov [rbx+NEBO_G110_CONSOLE_MAX_LINES],rax
    mov rax,[r14+NEBO_G110_LIMIT_BYTES]
    mov [rbx+NEBO_G110_CONSOLE_MAX_BYTES],rax
    mov rax,[r14+NEBO_G110_LIMIT_PANELS]
    mov [rbx+NEBO_G110_CONSOLE_MAX_PANELS],rax
    mov qword [rbx+NEBO_G110_CONSOLE_GENERATION],1
    mov [rbx+NEBO_G110_CONSOLE_CAPS],r15
    mov rax,r12
    shl rax,48
    mov rdx,r13
    shl rdx,40
    xor rax,rdx
    xor rax,[r14+NEBO_G110_LIMIT_LINES]
    rol rax,9
    xor rax,[r14+NEBO_G110_LIMIT_BYTES]
    rol rax,9
    xor rax,[r14+NEBO_G110_LIMIT_PANELS]
    mov [rbx+NEBO_G110_CONSOLE_DIGEST],rax
    xor eax,eax
    jmp .done
.capability:
    mov eax,-NEBO_G110_ERROR_CAPABILITY
    jmp .done
.busy:
    mov eax,-NEBO_G110_ERROR_BUSY
    jmp .done
.range:
    mov eax,-NEBO_G110_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; console.close(console*) is idempotent after exactly one cleanup.
nebo_g110_console_close:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G110_CONSOLE_MAGIC
    cmp [rdi+NEBO_G110_CONSOLE_MAGIC_OFS],rax
    jne .invalid
    cmp qword [rdi+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_CLOSED
    je .ok
    cmp qword [rdi+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_OPEN
    jne .state
    cmp qword [rdi+NEBO_G110_CONSOLE_PANELS],0
    jne .busy
    mov qword [rdi+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_CLOSED
    inc qword [rdi+NEBO_G110_CONSOLE_GENERATION]
    inc qword [rdi+NEBO_G110_CONSOLE_CLEANUPS]
    mov qword [rdi+NEBO_G110_CONSOLE_DIGEST],0
.ok:
    xor eax,eax
    ret
.busy:
    mov eax,-NEBO_G110_ERROR_BUSY
    ret
.state:
    mov eax,-NEBO_G110_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
    ret

; console.status(console*, receipt*) publishes a pointer-free factual snapshot.
nebo_g110_console_status:
    push rbx
    push r12
    mov rbx,rdi
    mov r12,rsi
    test rbx,rbx
    jz .invalid
    test r12,r12
    jz .invalid
    mov rax,NEBO_G110_CONSOLE_MAGIC
    cmp [rbx+NEBO_G110_CONSOLE_MAGIC_OFS],rax
    jne .invalid
%macro G110_STATUS_COPY 2
    mov rax,[rbx+%1]
    mov [r12+%2],rax
%endmacro
    G110_STATUS_COPY NEBO_G110_CONSOLE_STATE,NEBO_G110_STATUS_STATE
    G110_STATUS_COPY NEBO_G110_CONSOLE_MODE,NEBO_G110_STATUS_MODE
    G110_STATUS_COPY NEBO_G110_CONSOLE_THEME,NEBO_G110_STATUS_THEME
    G110_STATUS_COPY NEBO_G110_CONSOLE_MAX_LINES,NEBO_G110_STATUS_MAX_LINES
    G110_STATUS_COPY NEBO_G110_CONSOLE_MAX_BYTES,NEBO_G110_STATUS_MAX_BYTES
    G110_STATUS_COPY NEBO_G110_CONSOLE_MAX_PANELS,NEBO_G110_STATUS_MAX_PANELS
    G110_STATUS_COPY NEBO_G110_CONSOLE_LINES,NEBO_G110_STATUS_LINES
    G110_STATUS_COPY NEBO_G110_CONSOLE_BYTES,NEBO_G110_STATUS_BYTES
    G110_STATUS_COPY NEBO_G110_CONSOLE_PANELS,NEBO_G110_STATUS_PANELS
    G110_STATUS_COPY NEBO_G110_CONSOLE_GENERATION,NEBO_G110_STATUS_GENERATION
    G110_STATUS_COPY NEBO_G110_CONSOLE_DIGEST,NEBO_G110_STATUS_DIGEST
    G110_STATUS_COPY NEBO_G110_CONSOLE_CLEANUPS,NEBO_G110_STATUS_CLEANUPS
%undef G110_STATUS_COPY
    mov qword [r12+NEBO_G110_STATUS_MATURITY],NEBO_G110_MATURITY_INTERNAL_PANEL_SERVICE_GREEN
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop r12
    pop rbx
    ret

; Atomic full configuration update: mode, theme and all resource limits.
; RDI=console, ESI=mode, EDX=theme, RCX=limits.
nebo_g110_console_configure:
    push rbx
    push r12
    push r13
    push r14
    mov rbx,rdi
    mov r12d,esi
    mov r13d,edx
    mov r14,rcx
    call g110_require_open
    test eax,eax
    jnz .done
    cmp r12d,NEBO_G110_MODE_PLAIN
    jb .range
    cmp r12d,NEBO_G110_MODE_MAX
    ja .range
    cmp r13d,NEBO_G110_THEME_DEFAULT
    jb .range
    cmp r13d,NEBO_G110_THEME_MAX
    ja .range
    mov rdi,r14
    call g110_limits_validate
    test eax,eax
    jnz .done
    mov rax,[r14+NEBO_G110_LIMIT_LINES]
    cmp rax,[rbx+NEBO_G110_CONSOLE_LINES]
    jb .limit
    mov rax,[r14+NEBO_G110_LIMIT_BYTES]
    cmp rax,[rbx+NEBO_G110_CONSOLE_BYTES]
    jb .limit
    mov rax,[r14+NEBO_G110_LIMIT_PANELS]
    cmp rax,[rbx+NEBO_G110_CONSOLE_PANELS]
    jb .limit
    mov [rbx+NEBO_G110_CONSOLE_MODE],r12
    mov [rbx+NEBO_G110_CONSOLE_THEME],r13
    mov rax,[r14+NEBO_G110_LIMIT_LINES]
    mov [rbx+NEBO_G110_CONSOLE_MAX_LINES],rax
    mov rax,[r14+NEBO_G110_LIMIT_BYTES]
    mov [rbx+NEBO_G110_CONSOLE_MAX_BYTES],rax
    mov rax,[r14+NEBO_G110_LIMIT_PANELS]
    mov [rbx+NEBO_G110_CONSOLE_MAX_PANELS],rax
    inc qword [rbx+NEBO_G110_CONSOLE_GENERATION]
    xor eax,eax
    jmp .done
.limit:
    mov eax,-NEBO_G110_ERROR_LIMIT
    jmp .done
.range:
    mov eax,-NEBO_G110_ERROR_RANGE
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_g110_console_configure_headless:
    call g110_require_open
    test eax,eax
    jnz .done
    mov qword [rdi+NEBO_G110_CONSOLE_MODE],NEBO_G110_MODE_HEADLESS
    inc qword [rdi+NEBO_G110_CONSOLE_GENERATION]
    xor eax,eax
.done:
    ret

nebo_g110_console_set_mode:
    push rbx
    mov rbx,rdi
    call g110_require_open
    test eax,eax
    jnz .done
    cmp esi,NEBO_G110_MODE_PLAIN
    jb .range
    cmp esi,NEBO_G110_MODE_MAX
    ja .range
    mov [rbx+NEBO_G110_CONSOLE_MODE],rsi
    inc qword [rbx+NEBO_G110_CONSOLE_GENERATION]
    xor eax,eax
    jmp .done
.range:
    mov eax,-NEBO_G110_ERROR_RANGE
.done:
    pop rbx
    ret

nebo_g110_console_set_theme:
    push rbx
    mov rbx,rdi
    call g110_require_open
    test eax,eax
    jnz .done
    cmp esi,NEBO_G110_THEME_DEFAULT
    jb .range
    cmp esi,NEBO_G110_THEME_MAX
    ja .range
    mov [rbx+NEBO_G110_CONSOLE_THEME],rsi
    inc qword [rbx+NEBO_G110_CONSOLE_GENERATION]
    xor eax,eax
    jmp .done
.range:
    mov eax,-NEBO_G110_ERROR_RANGE
.done:
    pop rbx
    ret

nebo_g110_console_set_limits:
    push rbx
    mov rbx,rdi
    call g110_require_open
    test eax,eax
    jnz .done
    mov rdi,rsi
    call g110_limits_validate
    test eax,eax
    jnz .done
    mov rax,[rsi+NEBO_G110_LIMIT_LINES]
    cmp rax,[rbx+NEBO_G110_CONSOLE_LINES]
    jb .limit
    mov rax,[rsi+NEBO_G110_LIMIT_BYTES]
    cmp rax,[rbx+NEBO_G110_CONSOLE_BYTES]
    jb .limit
    mov rax,[rsi+NEBO_G110_LIMIT_PANELS]
    cmp rax,[rbx+NEBO_G110_CONSOLE_PANELS]
    jb .limit
    mov rax,[rsi+NEBO_G110_LIMIT_LINES]
    mov [rbx+NEBO_G110_CONSOLE_MAX_LINES],rax
    mov rax,[rsi+NEBO_G110_LIMIT_BYTES]
    mov [rbx+NEBO_G110_CONSOLE_MAX_BYTES],rax
    mov rax,[rsi+NEBO_G110_LIMIT_PANELS]
    mov [rbx+NEBO_G110_CONSOLE_MAX_PANELS],rax
    inc qword [rbx+NEBO_G110_CONSOLE_GENERATION]
    xor eax,eax
    jmp .done
.limit:
    mov eax,-NEBO_G110_ERROR_LIMIT
.done:
    pop rbx
    ret

; Shared bounded effect. RDI=console, RSI=value, RDX=digest out;
; R8=byte cost, R9=kind, R10=required capability.
g110_console_emit:
    push rbx
    push r12
    push r13
    mov rbx,rdi
    mov r12,rdx
    mov r13,rsi
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    call g110_require_open
    test eax,eax
    jnz .done
    mov rax,[rbx+NEBO_G110_CONSOLE_CAPS]
    and rax,r10
    cmp rax,r10
    jne .capability
    mov r11,[rbx+NEBO_G110_CONSOLE_LINES]
    inc r11
    cmp r11,[rbx+NEBO_G110_CONSOLE_MAX_LINES]
    ja .limit
    mov rcx,[rbx+NEBO_G110_CONSOLE_BYTES]
    add rcx,r8
    cmp rcx,[rbx+NEBO_G110_CONSOLE_MAX_BYTES]
    ja .limit
    mov rdx,[rbx+NEBO_G110_CONSOLE_DIGEST]
    rol rdx,11
    xor rdx,r13
    mov rax,r9
    shl rax,56
    xor rdx,rax
    mov [rbx+NEBO_G110_CONSOLE_LINES],r11
    mov [rbx+NEBO_G110_CONSOLE_BYTES],rcx
    inc qword [rbx+NEBO_G110_CONSOLE_GENERATION]
    mov [rbx+NEBO_G110_CONSOLE_DIGEST],rdx
    mov [r12],rdx
    xor eax,eax
    jmp .done
.capability:
    mov eax,-NEBO_G110_ERROR_CAPABILITY
    jmp .done
.limit:
    mov eax,-NEBO_G110_ERROR_LIMIT
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop r13
    pop r12
    pop rbx
    ret

nebo_g110_console_show:
    mov r8d,8
    mov r9d,1
    mov r10d,NEBO_G110_CAP_SHOW
    jmp g110_console_emit

nebo_g110_console_inspect:
    mov r8d,16
    mov r9d,2
    mov r10d,NEBO_G110_CAP_INSPECT
    jmp g110_console_emit

nebo_g110_console_fallback_text:
    mov r8d,4
    mov r9d,3
    mov r10d,NEBO_G110_CAP_SHOW
    jmp g110_console_emit

; panel.create(console*, panel*, id, type, title_hash).
nebo_g110_panel_create:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    call g110_require_open
    test eax,eax
    jnz .done
    test r12,r12
    jz .invalid
    mov rax,NEBO_G110_PANEL_MAGIC
    cmp [r12+NEBO_G110_PANEL_MAGIC_OFS],rax
    jne .id
    cmp qword [r12+NEBO_G110_PANEL_STATE],NEBO_G110_PANEL_ACTIVE
    je .busy
.id:
    test r13,r13
    jz .range
    cmp r14,NEBO_G110_PANEL_TEXT
    jb .range
    cmp r14,NEBO_G110_PANEL_TYPE_MAX
    ja .range
    test r15,r15
    jz .range
    test qword [rbx+NEBO_G110_CONSOLE_CAPS],NEBO_G110_CAP_PANEL
    jz .capability
    mov rax,[rbx+NEBO_G110_CONSOLE_PANELS]
    cmp rax,[rbx+NEBO_G110_CONSOLE_MAX_PANELS]
    jae .limit
    mov rdi,r12
    mov ecx,NEBO_G110_PANEL_QWORDS
    xor eax,eax
    cld
    rep stosq
    mov rax,NEBO_G110_PANEL_MAGIC
    mov [r12+NEBO_G110_PANEL_MAGIC_OFS],rax
    mov [r12+NEBO_G110_PANEL_ID],r13
    mov qword [r12+NEBO_G110_PANEL_STATE],NEBO_G110_PANEL_ACTIVE
    mov [r12+NEBO_G110_PANEL_TYPE],r14
    mov [r12+NEBO_G110_PANEL_TITLE],r15
    mov qword [r12+NEBO_G110_PANEL_GENERATION],1
    mov rax,[rbx+NEBO_G110_CONSOLE_GENERATION]
    mov [r12+NEBO_G110_PANEL_OWNER],rax
    inc qword [rbx+NEBO_G110_CONSOLE_PANELS]
    inc qword [rbx+NEBO_G110_CONSOLE_GENERATION]
    xor eax,eax
    jmp .done
.capability:
    mov eax,-NEBO_G110_ERROR_CAPABILITY
    jmp .done
.busy:
    mov eax,-NEBO_G110_ERROR_BUSY
    jmp .done
.limit:
    mov eax,-NEBO_G110_ERROR_LIMIT
    jmp .done
.range:
    mov eax,-NEBO_G110_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; panel.get(console*, panel*, id, snapshot*) does not publish a pointer handle.
nebo_g110_panel_get:
    push rbx
    push r12
    push r13
    mov rbx,rsi
    mov r12,rdx
    mov r13,rcx
    call g110_require_open
    test eax,eax
    jnz .done
    mov rdi,rbx
    call g110_require_panel
    test eax,eax
    jnz .done
    cmp [rbx+NEBO_G110_PANEL_ID],r12
    jne .not_found
    mov rdi,rbx
    mov rsi,r13
    call nebo_g110_panel_snapshot
    jmp .done
.not_found:
    mov eax,-NEBO_G110_ERROR_NOT_FOUND
.done:
    pop r13
    pop r12
    pop rbx
    ret

nebo_g110_panel_remove:
    push rbx
    push r12
    mov rbx,rdi
    mov r12,rsi
    call g110_require_open
    test eax,eax
    jnz .done
    mov rdi,r12
    call g110_require_panel
    test eax,eax
    jnz .done
    cmp qword [rbx+NEBO_G110_CONSOLE_PANELS],0
    je .state
    mov qword [r12+NEBO_G110_PANEL_STATE],NEBO_G110_PANEL_REMOVED
    mov qword [r12+NEBO_G110_PANEL_DIGEST],0
    mov qword [r12+NEBO_G110_PANEL_ITEMS],0
    mov qword [r12+NEBO_G110_PANEL_BYTES],0
    inc qword [r12+NEBO_G110_PANEL_GENERATION]
    inc qword [r12+NEBO_G110_PANEL_CLEANUPS]
    dec qword [rbx+NEBO_G110_CONSOLE_PANELS]
    inc qword [rbx+NEBO_G110_CONSOLE_GENERATION]
    xor eax,eax
    jmp .done
.state:
    mov eax,-NEBO_G110_ERROR_STATE
.done:
    pop r12
    pop rbx
    ret

nebo_g110_panel_clear:
    push rbx
    mov rbx,rdi
    call g110_require_panel
    test eax,eax
    jnz .done
    mov qword [rbx+NEBO_G110_PANEL_DIGEST],0
    mov qword [rbx+NEBO_G110_PANEL_ITEMS],0
    mov qword [rbx+NEBO_G110_PANEL_BYTES],0
    inc qword [rbx+NEBO_G110_PANEL_GENERATION]
    xor eax,eax
.done:
    pop rbx
    ret

; title(panel*, new_or_zero, result*) and type(...) support query or set.
nebo_g110_panel_title:
    push rbx
    mov rbx,rdi
    test rdx,rdx
    jz .invalid
    call g110_require_panel
    test eax,eax
    jnz .done
    test rsi,rsi
    jz .publish
    mov [rbx+NEBO_G110_PANEL_TITLE],rsi
    inc qword [rbx+NEBO_G110_PANEL_GENERATION]
.publish:
    mov rax,[rbx+NEBO_G110_PANEL_TITLE]
    mov [rdx],rax
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop rbx
    ret

nebo_g110_panel_type:
    push rbx
    mov rbx,rdi
    test rdx,rdx
    jz .invalid
    call g110_require_panel
    test eax,eax
    jnz .done
    test rsi,rsi
    jz .publish
    cmp rsi,NEBO_G110_PANEL_TEXT
    jb .range
    cmp rsi,NEBO_G110_PANEL_TYPE_MAX
    ja .range
    mov [rbx+NEBO_G110_PANEL_TYPE],rsi
    inc qword [rbx+NEBO_G110_PANEL_GENERATION]
.publish:
    mov rax,[rbx+NEBO_G110_PANEL_TYPE]
    mov [rdx],rax
    xor eax,eax
    jmp .done
.range:
    mov eax,-NEBO_G110_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop rbx
    ret

; RDI=panel, RSI=value, RDX=bytes, RCX=digest out, R8=operation.
g110_panel_mutate:
    push rbx
    push r12
    push r13
    push r14
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    test r14,r14
    jz .invalid
    test r12,r12
    jz .range
    test r13,r13
    jz .range
    cmp r13,64
    ja .limit
    call g110_require_panel
    test eax,eax
    jnz .done
    cmp r8,2
    je .replace
    mov rax,[rbx+NEBO_G110_PANEL_ITEMS]
    inc rax
    cmp rax,64
    ja .limit
    mov rdx,[rbx+NEBO_G110_PANEL_BYTES]
    add rdx,r13
    cmp rdx,256
    ja .limit
    jmp .digest
.replace:
    mov eax,1
    mov rdx,r13
.digest:
    mov rcx,[rbx+NEBO_G110_PANEL_DIGEST]
    rol rcx,13
    xor rcx,r12
    mov rsi,r8
    shl rsi,60
    xor rcx,rsi
    mov [rbx+NEBO_G110_PANEL_ITEMS],rax
    mov [rbx+NEBO_G110_PANEL_BYTES],rdx
    mov [rbx+NEBO_G110_PANEL_DIGEST],rcx
    inc qword [rbx+NEBO_G110_PANEL_GENERATION]
    mov [r14],rcx
    xor eax,eax
    jmp .done
.limit:
    mov eax,-NEBO_G110_ERROR_LIMIT
    jmp .done
.range:
    mov eax,-NEBO_G110_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_g110_panel_send:
    mov r8d,1
    jmp g110_panel_mutate

nebo_g110_panel_replace:
    mov r8d,2
    jmp g110_panel_mutate

nebo_g110_panel_append:
    mov r8d,3
    jmp g110_panel_mutate

; panel.snapshot(panel*, receipt*) computes a pointer-free stable identity.
nebo_g110_panel_snapshot:
    push rbx
    push r12
    mov rbx,rdi
    mov r12,rsi
    test r12,r12
    jz .invalid
    call g110_require_panel
    test eax,eax
    jnz .done
    mov rax,[rbx+NEBO_G110_PANEL_ID]
    mov [r12+NEBO_G110_SNAPSHOT_ID],rax
    mov rax,[rbx+NEBO_G110_PANEL_STATE]
    mov [r12+NEBO_G110_SNAPSHOT_STATE],rax
    mov rax,[rbx+NEBO_G110_PANEL_TYPE]
    mov [r12+NEBO_G110_SNAPSHOT_TYPE],rax
    mov rax,[rbx+NEBO_G110_PANEL_TITLE]
    mov [r12+NEBO_G110_SNAPSHOT_TITLE],rax
    mov rax,[rbx+NEBO_G110_PANEL_DIGEST]
    mov [r12+NEBO_G110_SNAPSHOT_DIGEST],rax
    mov rax,[rbx+NEBO_G110_PANEL_ITEMS]
    mov [r12+NEBO_G110_SNAPSHOT_ITEMS],rax
    mov rax,[rbx+NEBO_G110_PANEL_BYTES]
    mov [r12+NEBO_G110_SNAPSHOT_BYTES],rax
    mov rax,[rbx+NEBO_G110_PANEL_GENERATION]
    mov [r12+NEBO_G110_SNAPSHOT_GENERATION],rax
    mov rcx,[rbx+NEBO_G110_PANEL_ID]
    rol rcx,7
    xor rcx,[rbx+NEBO_G110_PANEL_TITLE]
    rol rcx,7
    xor rcx,[rbx+NEBO_G110_PANEL_DIGEST]
    rol rcx,7
    xor rcx,rax
    mov [r12+NEBO_G110_SNAPSHOT_IDENTITY],rcx
    mov [rbx+NEBO_G110_PANEL_SNAPSHOT],rcx
    mov rax,[rbx+NEBO_G110_PANEL_CLEANUPS]
    mov [r12+NEBO_G110_SNAPSHOT_CLEANUPS],rax
    mov qword [r12+NEBO_G110_SNAPSHOT_MATURITY],NEBO_G110_MATURITY_INTERNAL_PANEL_SERVICE_GREEN
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop r12
    pop rbx
    ret

; Historical generated-front compatibility: the old three-scalar scaffold is
; retained only so baseline tests remain linkable. It is not used by G110 proof.
%macro G110_LEGACY_EXPORT 1
global %1
%1:
    jmp g110_legacy_contract_validate
%endmacro
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_facade_historica_visual_e_migration_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_visual_console_open_close_status_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_configure_headless_mode_theme_limits_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_show_inspect_fallbacktext_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_visual_panel_create_get_remove_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_clear_title_type_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_send_replace_append_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_snapshot_lifecycle_contract_validate
G110_LEGACY_EXPORT nebo_servicos_internos_visual_console_e_visual_panel_closeout_contract_validate
%undef G110_LEGACY_EXPORT

g110_legacy_contract_validate:
    test rdx,rdx
    jz .invalid
    cmp rdi,1
    jl .invalid
    cmp rdi,64
    jg .bounds
    test rsi,rsi
    js .invalid
    cmp rsi,64
    jg .bounds
    lea rax,[rdi+rsi]
    mov [rdx],rax
    xor eax,eax
    ret
.bounds:
    mov eax,NEBO_INTERNAL_ERR_BOUNDS
    ret
.invalid:
    mov eax,NEBO_INTERNAL_ERR_INVALID
    ret
