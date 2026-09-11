; Source-to-effect bridge for internal visual console and panel services.
bits 64
default rel
%define NEBO_G110_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_scheduler_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g110_console: resb NEBO_G110_CONSOLE_SIZE
g110_panel: resb NEBO_G110_PANEL_SIZE
g110_limits: resb NEBO_G110_LIMIT_SIZE
g110_status: resb NEBO_G110_STATUS_SIZE
g110_snapshot: resb NEBO_G110_SNAPSHOT_SIZE
g110_bad_console: resb NEBO_G110_CONSOLE_SIZE
g110_bad_panel: resb NEBO_G110_PANEL_SIZE
g110_bad_snapshot: resb NEBO_G110_SNAPSHOT_SIZE
g110_observed_digest: resq 1
g110_observed_identity: resq 1
g110_observed_items: resq 1
g110_observed_bytes: resq 1
g110_last_mode: resq 1
g110_last_seed: resq 1

section .text
global nebo_g110_source_probe
global nebo_g110_surface_probe
global nebo_g110_negative_probe

g110_probe_clear:
    lea rdi,[rel g110_console]
    mov ecx,(NEBO_G110_CONSOLE_SIZE+NEBO_G110_PANEL_SIZE+NEBO_G110_LIMIT_SIZE+NEBO_G110_STATUS_SIZE+NEBO_G110_SNAPSHOT_SIZE+NEBO_G110_CONSOLE_SIZE+NEBO_G110_PANEL_SIZE+NEBO_G110_SNAPSHOT_SIZE+48)/8
    xor eax,eax
    cld
    rep stosq
    ret

; EDI=subgroup mode 1..9, ESI=source seed 3001..3009.
; All profiles traverse the same public receiver-first source surface and all
; internal services; distinct source values make every observation falsifiable.
nebo_g110_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov ebx,edi
    mov ebp,esi
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G110_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G110_SOURCE_MIN_SEED
    jb .invalid
    cmp ebp,NEBO_G110_SOURCE_MAX_SEED
    ja .invalid
    mov eax,ebp
    sub eax,3000
    cmp eax,ebx
    jne .invalid
    call g110_probe_clear
    mov [rel g110_last_mode],rbx
    mov [rel g110_last_seed],rbp

    mov eax,ebx
    add eax,32
    mov [rel g110_limits+NEBO_G110_LIMIT_LINES],rax
    mov eax,ebx
    imul eax,eax,8
    add eax,256
    mov [rel g110_limits+NEBO_G110_LIMIT_BYTES],rax
    mov qword [rel g110_limits+NEBO_G110_LIMIT_PANELS],4

    mov eax,ebx
    dec eax
    and eax,3
    inc eax
    mov r12d,eax
    lea rdi,[rel g110_console]
    mov esi,NEBO_G110_MODE_PLAIN
    mov edx,r12d
    lea rcx,[rel g110_limits]
    mov r8d,NEBO_G110_CAP_ALL
    call nebo_g110_console_open
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_status]
    call nebo_g110_console_status
    test eax,eax
    jnz .effect
    cmp qword [rel g110_status+NEBO_G110_STATUS_STATE],NEBO_G110_STATE_OPEN
    jne .effect

    lea rdi,[rel g110_console]
    mov esi,NEBO_G110_MODE_VISUAL
    mov edx,r12d
    lea rcx,[rel g110_limits]
    call nebo_g110_console_configure
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    mov esi,NEBO_G110_MODE_ANSI
    call nebo_g110_console_set_mode
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    mov esi,r12d
    call nebo_g110_console_set_theme
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_limits]
    call nebo_g110_console_set_limits
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    call nebo_g110_console_configure_headless
    test eax,eax
    jnz .effect

    lea rdi,[rel g110_console]
    lea esi,[rbp+11]
    lea rdx,[rel g110_observed_digest]
    call nebo_g110_console_show
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    lea esi,[rbp+22]
    lea rdx,[rel g110_observed_digest]
    call nebo_g110_console_inspect
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    lea esi,[rbp+33]
    lea rdx,[rel g110_observed_digest]
    call nebo_g110_console_fallback_text
    test eax,eax
    jnz .effect

    mov eax,ebx
    dec eax
    and eax,3
    inc eax
    mov r13d,eax
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    mov edx,ebp
    mov ecx,r13d
    lea r8d,[rbp+100]
    call nebo_g110_panel_create
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    mov edx,ebp
    lea rcx,[rel g110_snapshot]
    call nebo_g110_panel_get
    test eax,eax
    jnz .effect

    lea rdi,[rel g110_panel]
    lea esi,[rbp+200]
    lea rdx,[rel g110_observed_identity]
    call nebo_g110_panel_title
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_panel]
    xor esi,esi
    lea rdx,[rel g110_observed_identity]
    call nebo_g110_panel_title
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_panel]
    mov esi,r13d
    lea rdx,[rel g110_observed_items]
    call nebo_g110_panel_type
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_panel]
    xor esi,esi
    lea rdx,[rel g110_observed_items]
    call nebo_g110_panel_type
    test eax,eax
    jnz .effect

    lea rdi,[rel g110_panel]
    lea esi,[rbp+301]
    mov edx,8
    lea rcx,[rel g110_observed_digest]
    call nebo_g110_panel_send
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_panel]
    lea esi,[rbp+302]
    mov edx,12
    lea rcx,[rel g110_observed_digest]
    call nebo_g110_panel_replace
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_panel]
    lea esi,[rbp+303]
    mov edx,4
    lea rcx,[rel g110_observed_digest]
    call nebo_g110_panel_append
    test eax,eax
    jnz .effect

    lea rdi,[rel g110_panel]
    lea rsi,[rel g110_snapshot]
    call nebo_g110_panel_snapshot
    test eax,eax
    jnz .effect
    mov rax,[rel g110_snapshot+NEBO_G110_SNAPSHOT_DIGEST]
    mov [rel g110_observed_digest],rax
    mov rax,[rel g110_snapshot+NEBO_G110_SNAPSHOT_IDENTITY]
    mov [rel g110_observed_identity],rax
    mov rax,[rel g110_snapshot+NEBO_G110_SNAPSHOT_ITEMS]
    mov [rel g110_observed_items],rax
    mov rax,[rel g110_snapshot+NEBO_G110_SNAPSHOT_BYTES]
    mov [rel g110_observed_bytes],rax
    cmp qword [rel g110_observed_items],2
    jne .effect
    cmp qword [rel g110_observed_bytes],16
    jne .effect

    lea rdi,[rel g110_panel]
    call nebo_g110_panel_clear
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    call nebo_g110_panel_remove
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    call nebo_g110_console_close
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    call nebo_g110_console_close
    test eax,eax
    jnz .effect
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_status]
    call nebo_g110_console_status
    test eax,eax
    jnz .effect
    cmp qword [rel g110_status+NEBO_G110_STATUS_STATE],NEBO_G110_STATE_CLOSED
    jne .effect
    cmp qword [rel g110_status+NEBO_G110_STATUS_CLEANUPS],1
    jne .effect
    mov eax,ebp
    jmp .done
.effect:
    mov eax,-NEBO_G110_ERROR_STATE
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI selector 1..15 returns source-derived internal observations.
nebo_g110_surface_probe:
    cmp edi,1
    jb .invalid
    cmp edi,15
    ja .invalid
    lea rdx,[rel .table]
    movsxd rax,dword [rdx+rdi*4-4]
    add rax,rdx
    jmp rax
.mode: mov rax,[rel g110_last_mode]
    ret
.seed: mov rax,[rel g110_last_seed]
    ret
.state: mov rax,[rel g110_status+NEBO_G110_STATUS_STATE]
    ret
.console_mode: mov rax,[rel g110_status+NEBO_G110_STATUS_MODE]
    ret
.theme: mov rax,[rel g110_status+NEBO_G110_STATUS_THEME]
    ret
.lines: mov rax,[rel g110_status+NEBO_G110_STATUS_LINES]
    ret
.bytes: mov rax,[rel g110_status+NEBO_G110_STATUS_BYTES]
    ret
.console_cleanup: mov rax,[rel g110_status+NEBO_G110_STATUS_CLEANUPS]
    ret
.items: mov rax,[rel g110_observed_items]
    ret
.panel_bytes: mov rax,[rel g110_observed_bytes]
    ret
.panel_digest: mov rax,[rel g110_observed_digest]
    ret
.identity: mov rax,[rel g110_observed_identity]
    ret
.panel_cleanup: mov rax,[rel g110_panel+NEBO_G110_PANEL_CLEANUPS]
    ret
.generation: mov rax,[rel g110_status+NEBO_G110_STATUS_GENERATION]
    ret
.maturity: mov eax,NEBO_G110_MATURITY_INTERNAL_PANEL_SERVICE_GREEN
    ret
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
    ret
align 4
.table:
    dd .mode-.table,.seed-.table,.state-.table,.console_mode-.table
    dd .theme-.table,.lines-.table,.bytes-.table,.console_cleanup-.table
    dd .items-.table,.panel_bytes-.table,.panel_digest-.table,.identity-.table
    dd .panel_cleanup-.table,.generation-.table,.maturity-.table

; Prepare an open console and one panel for negative/failure-atomicity probes.
g110_negative_ready:
    call g110_probe_clear
    mov qword [rel g110_limits+NEBO_G110_LIMIT_LINES],8
    mov qword [rel g110_limits+NEBO_G110_LIMIT_BYTES],64
    mov qword [rel g110_limits+NEBO_G110_LIMIT_PANELS],2
    lea rdi,[rel g110_console]
    mov esi,NEBO_G110_MODE_HEADLESS
    mov edx,NEBO_G110_THEME_DEFAULT
    lea rcx,[rel g110_limits]
    mov r8d,NEBO_G110_CAP_ALL
    call nebo_g110_console_open
    test eax,eax
    jnz .done
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    mov edx,4010
    mov ecx,NEBO_G110_PANEL_TEXT
    mov r8d,5010
    call nebo_g110_panel_create
.done:
    ret

; EDI case 1..14. Zero means the exact rejection and sentinel preservation held.
nebo_g110_negative_probe:
    push rbx
    push r12
    sub rsp,8
    mov ebx,edi
    cmp ebx,1
    jb .invalid
    cmp ebx,14
    ja .invalid
    cmp ebx,1
    je .bad_mode
    cmp ebx,2
    je .bad_caps
    cmp ebx,3
    je .bad_limits
    call g110_negative_ready
    test eax,eax
    jnz .failed
    cmp ebx,4
    je .null_emit
    cmp ebx,5
    je .small_limits
    cmp ebx,6
    je .bad_panel_type
    cmp ebx,7
    je .not_found
    cmp ebx,8
    je .mutation_limit
    cmp ebx,9
    je .null_snapshot
    cmp ebx,10
    je .busy_close
    cmp ebx,11
    je .double_remove
    cmp ebx,12
    je .idempotent_close
    cmp ebx,13
    je .duplicate_open
    jmp .duplicate_panel
.bad_mode:
    call g110_probe_clear
    mov rax,0x5151515151515151
    mov [rel g110_bad_console],rax
    mov qword [rel g110_limits+NEBO_G110_LIMIT_LINES],8
    mov qword [rel g110_limits+NEBO_G110_LIMIT_BYTES],64
    mov qword [rel g110_limits+NEBO_G110_LIMIT_PANELS],2
    lea rdi,[rel g110_bad_console]
    xor esi,esi
    mov edx,NEBO_G110_THEME_DEFAULT
    lea rcx,[rel g110_limits]
    mov r8d,NEBO_G110_CAP_ALL
    call nebo_g110_console_open
    cmp eax,-NEBO_G110_ERROR_RANGE
    jne .failed
    mov rax,0x5151515151515151
    cmp [rel g110_bad_console],rax
    jne .failed
    jmp .ok
.bad_caps:
    call g110_probe_clear
    mov rax,0x5151515151515151
    mov [rel g110_bad_console],rax
    mov qword [rel g110_limits+NEBO_G110_LIMIT_LINES],8
    mov qword [rel g110_limits+NEBO_G110_LIMIT_BYTES],64
    mov qword [rel g110_limits+NEBO_G110_LIMIT_PANELS],2
    lea rdi,[rel g110_bad_console]
    mov esi,NEBO_G110_MODE_HEADLESS
    mov edx,NEBO_G110_THEME_DEFAULT
    lea rcx,[rel g110_limits]
    mov r8d,NEBO_G110_CAP_ALL-NEBO_G110_CAP_SNAPSHOT
    call nebo_g110_console_open
    cmp eax,-NEBO_G110_ERROR_CAPABILITY
    jne .failed
    mov rax,0x5151515151515151
    cmp [rel g110_bad_console],rax
    jne .failed
    jmp .ok
.bad_limits:
    call g110_probe_clear
    mov rax,0x5151515151515151
    mov [rel g110_bad_console],rax
    mov qword [rel g110_limits+NEBO_G110_LIMIT_LINES],0
    mov qword [rel g110_limits+NEBO_G110_LIMIT_BYTES],64
    mov qword [rel g110_limits+NEBO_G110_LIMIT_PANELS],2
    lea rdi,[rel g110_bad_console]
    mov esi,NEBO_G110_MODE_HEADLESS
    mov edx,NEBO_G110_THEME_DEFAULT
    lea rcx,[rel g110_limits]
    mov r8d,NEBO_G110_CAP_ALL
    call nebo_g110_console_open
    cmp eax,-NEBO_G110_ERROR_LIMIT
    jne .failed
    mov rax,0x5151515151515151
    cmp [rel g110_bad_console],rax
    jne .failed
    jmp .ok
.null_emit:
    lea rdi,[rel g110_console]
    mov esi,17
    xor edx,edx
    call nebo_g110_console_show
    cmp eax,-NEBO_G110_ERROR_INVALID
    jne .failed
    cmp qword [rel g110_console+NEBO_G110_CONSOLE_LINES],0
    jne .failed
    jmp .ok
.small_limits:
    mov qword [rel g110_limits+NEBO_G110_LIMIT_LINES],1
    mov qword [rel g110_limits+NEBO_G110_LIMIT_BYTES],1
    mov qword [rel g110_limits+NEBO_G110_LIMIT_PANELS],0
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_limits]
    call nebo_g110_console_set_limits
    cmp eax,-NEBO_G110_ERROR_LIMIT
    jne .failed
    cmp qword [rel g110_console+NEBO_G110_CONSOLE_MAX_LINES],8
    jne .failed
    jmp .ok
.bad_panel_type:
    mov rax,0x6161616161616161
    mov [rel g110_bad_panel],rax
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_bad_panel]
    mov edx,4011
    xor ecx,ecx
    mov r8d,5011
    call nebo_g110_panel_create
    cmp eax,-NEBO_G110_ERROR_RANGE
    jne .failed
    mov rax,0x6161616161616161
    cmp [rel g110_bad_panel],rax
    jne .failed
    jmp .ok
.not_found:
    mov rax,0x7171717171717171
    mov [rel g110_bad_snapshot],rax
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    mov edx,9999
    lea rcx,[rel g110_bad_snapshot]
    call nebo_g110_panel_get
    cmp eax,-NEBO_G110_ERROR_NOT_FOUND
    jne .failed
    mov rax,0x7171717171717171
    cmp [rel g110_bad_snapshot],rax
    jne .failed
    jmp .ok
.mutation_limit:
    mov rax,0x8181818181818181
    mov [rel g110_observed_digest],rax
    lea rdi,[rel g110_panel]
    mov esi,42
    mov edx,65
    lea rcx,[rel g110_observed_digest]
    call nebo_g110_panel_append
    cmp eax,-NEBO_G110_ERROR_LIMIT
    jne .failed
    mov rax,0x8181818181818181
    cmp [rel g110_observed_digest],rax
    jne .failed
    cmp qword [rel g110_panel+NEBO_G110_PANEL_ITEMS],0
    jne .failed
    jmp .ok
.null_snapshot:
    lea rdi,[rel g110_panel]
    xor esi,esi
    call nebo_g110_panel_snapshot
    cmp eax,-NEBO_G110_ERROR_INVALID
    jne .failed
    jmp .ok
.busy_close:
    lea rdi,[rel g110_console]
    call nebo_g110_console_close
    cmp eax,-NEBO_G110_ERROR_BUSY
    jne .failed
    cmp qword [rel g110_console+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_OPEN
    jne .failed
    jmp .ok
.double_remove:
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    call nebo_g110_panel_remove
    test eax,eax
    jnz .failed
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    call nebo_g110_panel_remove
    cmp eax,-NEBO_G110_ERROR_STATE
    jne .failed
    cmp qword [rel g110_panel+NEBO_G110_PANEL_CLEANUPS],1
    jne .failed
    jmp .ok
.idempotent_close:
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    call nebo_g110_panel_remove
    test eax,eax
    jnz .failed
    lea rdi,[rel g110_console]
    call nebo_g110_console_close
    test eax,eax
    jnz .failed
    lea rdi,[rel g110_console]
    call nebo_g110_console_close
    test eax,eax
    jnz .failed
    cmp qword [rel g110_console+NEBO_G110_CONSOLE_CLEANUPS],1
    jne .failed
    jmp .ok
.duplicate_open:
    lea rdi,[rel g110_console]
    mov esi,NEBO_G110_MODE_HEADLESS
    mov edx,NEBO_G110_THEME_DEFAULT
    lea rcx,[rel g110_limits]
    mov r8d,NEBO_G110_CAP_ALL
    call nebo_g110_console_open
    cmp eax,-NEBO_G110_ERROR_BUSY
    jne .failed
    cmp qword [rel g110_console+NEBO_G110_CONSOLE_PANELS],1
    jne .failed
    cmp qword [rel g110_console+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_OPEN
    jne .failed
    jmp .ok
.duplicate_panel:
    lea rdi,[rel g110_console]
    lea rsi,[rel g110_panel]
    mov edx,4011
    mov ecx,NEBO_G110_PANEL_TABLE
    mov r8d,5011
    call nebo_g110_panel_create
    cmp eax,-NEBO_G110_ERROR_BUSY
    jne .failed
    cmp qword [rel g110_console+NEBO_G110_CONSOLE_PANELS],1
    jne .failed
    cmp qword [rel g110_panel+NEBO_G110_PANEL_ID],4010
    jne .failed
.ok:
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G110_ERROR_INVALID
    jmp .done
.failed:
    mov eax,-NEBO_G110_ERROR_STATE
.done:
    add rsp,8
    pop r12
    pop rbx
    ret
