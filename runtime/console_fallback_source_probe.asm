; Source-to-effect bridge for the G107 `fallback:` schema.
bits 64
default rel
%define NEBO_G107_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_fallback_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g107_plan: resb NEBO_G107_PLAN_SIZE
g107_result: resb NEBO_G107_RESULT_SIZE
g107_payload: resb 16
g107_last_mode: resq 1
g107_last_variant: resq 1

section .text
global nebo_g107_source_probe
global nebo_g107_surface_probe
global nebo_g107_negative_probe

g107_clear_state:
    lea rdi,[rel g107_plan]
    mov ecx,(NEBO_G107_PLAN_SIZE+NEBO_G107_RESULT_SIZE+16)/8
    xor eax,eax
    rep stosq
    ret

; EDI mode 1..9, ESI seed, EDX variant. Success returns the source seed.
nebo_g107_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov ebx,edi
    mov ebp,esi
    mov r12d,edx
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G107_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G107_SOURCE_MIN_SEED
    jb .invalid
    cmp r12d,NEBO_G107_SOURCE_MAX_VARIANT
    ja .invalid
    call g107_clear_state
    mov [rel g107_last_mode],rbx
    mov [rel g107_last_variant],r12
    mov [rel g107_payload],rbp
    mov [rel g107_payload+4],ebx
    mov [rel g107_payload+8],r12
    mov rax,0x726f7574652d3137
    xor rax,rbp
    mov [rel g107_payload+8],rax

    mov r13,NEBO_G107_SINK_STDOUT
    mov r14,r13
    mov r15,NEBO_G107_CAP_PLAIN
    xor r8d,r8d
    xor r9d,r9d
    cmp ebx,1
    jne .mode2
    cmp r12d,1
    jne .mode1_ansi
    mov r13,NEBO_G107_SINK_STDERR
    mov r14,r13
    jmp .init
.mode1_ansi:
    cmp r12d,2
    jne .init
    mov r13,NEBO_G107_SINK_ANSI
    mov r14,r13
    mov r15,NEBO_G107_CAP_ANSI
    jmp .init
.mode2:
    cmp ebx,2
    jne .mode3
    cmp r12d,NEBO_G107_FILE_MODE_MAX
    ja .invalid
    mov r13,NEBO_G107_SINK_FILE
    mov r14,r13
    mov r15,NEBO_G107_CAP_FILE
    mov r9,r12
    cmp r9d,NEBO_G107_FILE_ATOMIC
    jne .init
    or r15,NEBO_G107_CAP_ATOMIC
    jmp .init
.mode3:
    cmp ebx,3
    jne .mode4
    mov r13,NEBO_G107_SINK_STDOUT|NEBO_G107_SINK_STDERR
    mov r14,r13
    mov r15,NEBO_G107_CAP_PLAIN
    jmp .init
.mode4:
    cmp ebx,4
    jne .mode5
    mov r13,NEBO_G107_SINK_STDOUT|NEBO_G107_SINK_VISUAL
    mov r14,r13
    mov r15,NEBO_G107_CAP_PLAIN|NEBO_G107_CAP_VISUAL
    test r12d,r12d
    jz .init
    mov r13,NEBO_G107_SINK_STDOUT|NEBO_G107_SINK_PANEL
    mov r14,r13
    mov r15,NEBO_G107_CAP_PLAIN|NEBO_G107_CAP_PANEL
    jmp .init
.mode5:
    cmp ebx,5
    jne .mode6
    cmp r12d,3
    je .detect_supported
    mov r13,NEBO_G107_SINK_VISUAL
    mov r14,NEBO_G107_SINK_STDOUT
    mov r15,NEBO_G107_CAP_PLAIN
    lea r8d,[r12+NEBO_G107_FALLBACK_TEXT]
    jmp .init
.detect_supported:
    mov r8d,NEBO_G107_FALLBACK_DETECT_TARGET
    jmp .init
.mode6:
    cmp ebx,6
    jne .mode7
    mov r13,NEBO_G107_SINK_FILE
    mov r14,r13
    mov r15,NEBO_G107_CAP_FILE|NEBO_G107_CAP_ATOMIC
    mov r9d,NEBO_G107_FILE_ATOMIC
    jmp .init
.mode7:
    cmp ebx,7
    jne .mode8
    mov r13,NEBO_G107_SINK_STDOUT|NEBO_G107_SINK_STDERR|NEBO_G107_SINK_VISUAL
    mov r14,r13
    mov r15,NEBO_G107_CAP_PLAIN|NEBO_G107_CAP_VISUAL
    jmp .init
.mode8:
    cmp ebx,8
    jne .mode9
    mov r13,NEBO_G107_SINK_PANEL
    mov r14,r13
    mov r15,NEBO_G107_CAP_PANEL
    jmp .init
.mode9:
    mov r13,NEBO_G107_SINK_ALL
    mov r14,r13
    mov r15,NEBO_G107_CAP_ALL
    mov r8d,NEBO_G107_FALLBACK_SUMMARY
    mov r9d,NEBO_G107_FILE_ATOMIC
.init:
    lea rdi,[rel g107_plan]
    mov rsi,r13
    mov rdx,r14
    mov rcx,r15
    call nebo_g107_route_plan_init
    test eax,eax
    jnz .done
    lea rdi,[rel g107_plan]
    lea rsi,[rel g107_payload]
    mov edx,16
    lea rcx,[rel g107_result]
    call nebo_g107_route_execute
    test eax,eax
    jnz .done
    cmp ebx,8
    jne .success
    lea rdi,[rel g107_result]
    call nebo_g107_route_close
    test eax,eax
    jnz .done
.success:
    mov eax,ebp
    jmp .done
.invalid:
    mov eax,-NEBO_G107_ERROR_INVALID
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI selector 1..10 -> current observable or negative typed error.
nebo_g107_surface_probe:
    cmp edi,1
    jb .invalid
    cmp edi,10
    ja .invalid
    lea rdx,[rel .table]
    movsxd rax,dword [rdx+rdi*4-4]
    add rax,rdx
    jmp rax
.mode: mov rax,[rel g107_last_mode]
    ret
.mask: mov rax,[rel g107_result+NEBO_G107_RESULT_COMMITTED]
    ret
.total: mov rax,[rel g107_result+NEBO_G107_RESULT_TOTAL_BYTES]
    ret
.digest: mov rax,[rel g107_result+NEBO_G107_RESULT_PAYLOAD_DIGEST]
    ret
.file_mode: mov rax,[rel g107_plan+NEBO_G107_PLAN_FILE_MODE]
    ret
.fallback: mov rax,[rel g107_result+NEBO_G107_RESULT_FALLBACK_USED]
    ret
.evals: mov rax,[rel g107_result+NEBO_G107_RESULT_RECEIVER_EVALS]
    ret
.closed: mov rax,[rel g107_result+NEBO_G107_RESULT_CLOSED]
    ret
.caps: mov rax,[rel g107_plan+NEBO_G107_PLAN_REQUIRED_CAPS]
    ret
.maturity: mov eax,NEBO_G107_MATURITY_PUBLIC_CONSOLE_ROUTING_GREEN
    ret
.invalid:
    mov rax,-NEBO_G107_ERROR_INVALID
    ret
align 4
.table:
    dd .mode-.table,.mask-.table,.total-.table,.digest-.table
    dd .file_mode-.table,.fallback-.table,.evals-.table,.closed-.table
    dd .caps-.table,.maturity-.table

; EDI case 1..8. Each known-invalid operation must fail closed and preserve
; the caller-provided sentinel when publication has not committed.
nebo_g107_negative_probe:
    push rbx
    push r12
    sub rsp,16
    mov ebx,edi
    cmp ebx,1
    jb .invalid
    cmp ebx,8
    ja .invalid
    call g107_clear_state
    mov qword [rel g107_plan],0x51515151
    mov qword [rel g107_result],0x61616161
    cmp ebx,1
    je .missing_cap
    cmp ebx,2
    je .missing_target
    cmp ebx,3
    je .detect_target
    cmp ebx,4
    je .bad_mode
    ; Cases 5..8 first need a valid stdout plan.
    lea rdi,[rel g107_plan]
    mov esi,NEBO_G107_SINK_STDOUT
    mov edx,NEBO_G107_SINK_STDOUT
    mov ecx,NEBO_G107_CAP_PLAIN
    xor r8d,r8d
    xor r9d,r9d
    call nebo_g107_route_plan_init
    test eax,eax
    jnz .failed
    mov qword [rel g107_result],0x61616161
    cmp ebx,5
    je .zero_payload
    cmp ebx,6
    je .tamper
    cmp ebx,7
    je .double_close
    lea rdi,[rel g107_plan]
    lea rsi,[rel g107_payload]
    mov edx,NEBO_G107_MAX_PAYLOAD+1
    lea rcx,[rel g107_result]
    call nebo_g107_route_execute
    cmp eax,-NEBO_G107_ERROR_LIMIT
    jne .failed
    jmp .result_sentinel
.zero_payload:
    lea rdi,[rel g107_plan]
    lea rsi,[rel g107_payload]
    xor edx,edx
    lea rcx,[rel g107_result]
    call nebo_g107_route_execute
    cmp eax,-NEBO_G107_ERROR_INVALID
    jne .failed
    jmp .result_sentinel
.tamper:
    xor qword [rel g107_plan+NEBO_G107_PLAN_DIGEST],1
    lea rdi,[rel g107_plan]
    lea rsi,[rel g107_payload]
    mov edx,8
    lea rcx,[rel g107_result]
    call nebo_g107_route_execute
    cmp eax,-NEBO_G107_ERROR_INVALID
    jne .failed
    jmp .result_sentinel
.double_close:
    lea rdi,[rel g107_plan]
    lea rsi,[rel g107_payload]
    mov edx,8
    lea rcx,[rel g107_result]
    call nebo_g107_route_execute
    test eax,eax
    jnz .failed
    lea rdi,[rel g107_result]
    call nebo_g107_route_close
    test eax,eax
    jnz .failed
    lea rdi,[rel g107_result]
    call nebo_g107_route_close
    cmp eax,-NEBO_G107_ERROR_STATE
    jne .failed
    xor eax,eax
    jmp .done
.missing_cap:
    lea rdi,[rel g107_plan]
    mov esi,NEBO_G107_SINK_FILE
    mov edx,NEBO_G107_SINK_FILE
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    call nebo_g107_route_plan_init
    cmp eax,-NEBO_G107_ERROR_CAPABILITY
    jne .failed
    jmp .plan_sentinel
.missing_target:
    lea rdi,[rel g107_plan]
    mov esi,NEBO_G107_SINK_VISUAL
    mov edx,NEBO_G107_SINK_STDOUT
    mov ecx,NEBO_G107_CAP_PLAIN
    xor r8d,r8d
    xor r9d,r9d
    call nebo_g107_route_plan_init
    cmp eax,-NEBO_G107_ERROR_TARGET
    jne .failed
    jmp .plan_sentinel
.detect_target:
    lea rdi,[rel g107_plan]
    mov esi,NEBO_G107_SINK_VISUAL
    mov edx,NEBO_G107_SINK_STDOUT
    mov ecx,NEBO_G107_CAP_PLAIN
    mov r8d,NEBO_G107_FALLBACK_DETECT_TARGET
    xor r9d,r9d
    call nebo_g107_route_plan_init
    cmp eax,-NEBO_G107_ERROR_TARGET
    jne .failed
    jmp .plan_sentinel
.bad_mode:
    lea rdi,[rel g107_plan]
    mov esi,NEBO_G107_SINK_FILE
    mov edx,NEBO_G107_SINK_FILE
    mov ecx,NEBO_G107_CAP_FILE
    xor r8d,r8d
    mov r9d,NEBO_G107_FILE_MODE_MAX+1
    call nebo_g107_route_plan_init
    cmp eax,-NEBO_G107_ERROR_INVALID
    jne .failed
.plan_sentinel:
    cmp qword [rel g107_plan],0x51515151
    jne .failed
    xor eax,eax
    jmp .done
.result_sentinel:
    cmp qword [rel g107_result],0x61616161
    jne .failed
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G107_ERROR_INVALID
    jmp .done
.failed:
    mov eax,-NEBO_G107_ERROR_STATE
.done:
    add rsp,16
    pop r12
    pop rbx
    ret
