; Source-to-effect bridge for G109 structured diagnostics and profiler data.
bits 64
default rel
%define NEBO_G109_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_diagnostics_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g109_input: resb NEBO_G109_INPUT_SIZE
g109_receipt: resb NEBO_G109_RECEIPT_SIZE
g109_explanation: resb NEBO_G109_EXPLAIN_SIZE
g109_inspection: resb NEBO_G109_INSPECT_SIZE
g109_profile: resb NEBO_G109_PROFILE_SIZE
g109_tooling: resb NEBO_G109_TOOLING_SIZE
g109_registry: resb NEBO_G109_REGISTRY_SIZE
g109_bad_receipt: resb NEBO_G109_RECEIPT_SIZE
g109_last_config: resq 1

section .text
global nebo_g109_source_probe
global nebo_g109_surface_probe
global nebo_g109_negative_probe

g109_clear:
    lea rdi,[rel g109_input]
    mov ecx,(NEBO_G109_INPUT_SIZE+NEBO_G109_RECEIPT_SIZE+NEBO_G109_EXPLAIN_SIZE+NEBO_G109_INSPECT_SIZE+NEBO_G109_PROFILE_SIZE+NEBO_G109_TOOLING_SIZE+NEBO_G109_REGISTRY_SIZE+NEBO_G109_RECEIPT_SIZE+8)/8
    xor eax,eax
    rep stosq
    ret

; EDI mode, ESI seed, EDX packed depth:budget. Success returns source seed.
nebo_g109_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    mov ebx,edi
    mov ebp,esi
    mov r12d,edx
    mov r13d,edx
    shr r13d,8
    and r12d,0xff
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G109_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G109_SOURCE_MIN_SEED
    jb .invalid
    cmp r13d,1
    jb .invalid
    cmp r13d,NEBO_G109_SOURCE_MAX_DEPTH
    ja .invalid
    cmp r12d,r13d
    jb .invalid
    cmp r12d,NEBO_G109_SOURCE_MAX_BUDGET
    ja .invalid
    call g109_clear
    mov [rel g109_last_config],r12
    mov [rel g109_input+NEBO_G109_INPUT_MODE],rbx
    mov [rel g109_input+NEBO_G109_INPUT_SEED],rbp
    mov [rel g109_input+NEBO_G109_INPUT_DEPTH],r13
    mov [rel g109_input+NEBO_G109_INPUT_BUDGET],r12
    mov qword [rel g109_input+NEBO_G109_INPUT_FLAGS],NEBO_G109_FLAGS_REQUIRED
    mov qword [rel g109_input+NEBO_G109_INPUT_CAPS],NEBO_G109_CAP_REQUIRED
    lea r14,[rbp+rbx]
    mov [rel g109_input+NEBO_G109_INPUT_SPAN_START],r14
    add r14,r13
    mov [rel g109_input+NEBO_G109_INPUT_SPAN_END],r14
    lea rdi,[rel g109_input]
    lea rsi,[rel g109_receipt]
    call nebo_g109_diagnostic_build
    test eax,eax
    jnz .done
    mov rdi,[rel g109_receipt+NEBO_G109_RECEIPT_CODE]
    lea rsi,[rel g109_registry]
    call nebo_g109_registry_lookup
    test eax,eax
    jnz .done
    lea rdi,[rel g109_receipt]
    lea rsi,[rel g109_explanation]
    call nebo_g109_explain
    test eax,eax
    jnz .done
    lea rdi,[rel g109_receipt]
    lea rsi,[rel g109_inspection]
    call nebo_g109_inspect
    test eax,eax
    jnz .done
    lea rdi,[rel g109_receipt]
    lea rsi,[rel g109_profile]
    call nebo_g109_profiler
    test eax,eax
    jnz .done
    lea rdi,[rel g109_receipt]
    lea rsi,[rel g109_tooling]
    call nebo_g109_tooling_view
    test eax,eax
    jnz .done
    cmp ebx,9
    jne .success
    lea rdi,[rel g109_receipt]
    call nebo_g109_receipt_close
    test eax,eax
    jnz .done
.success:
    mov eax,ebp
    jmp .done
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
.done:
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI selector 1..15 returns the last source-derived structured observation.
nebo_g109_surface_probe:
    cmp edi,1
    jb .invalid
    cmp edi,15
    ja .invalid
    lea rdx,[rel .table]
    movsxd rax,dword [rdx+rdi*4-4]
    add rax,rdx
    jmp rax
.mode: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_MODE]
    ret
.code: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_CODE]
    ret
.severity: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_SEVERITY]
    ret
.phase: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_PHASE]
    ret
.depth: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_DEPTH]
    ret
.budget: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_BUDGET]
    ret
.fingerprint: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_FINGERPRINT]
    ret
.applicability: mov rax,[rel g109_explanation+NEBO_G109_EXPLAIN_APPLICABILITY]
    ret
.edits: mov rax,[rel g109_explanation+NEBO_G109_EXPLAIN_EDIT_COUNT]
    ret
.safe: mov rax,[rel g109_inspection+NEBO_G109_INSPECT_SAFE_FLAGS]
    ret
.work: mov rax,[rel g109_profile+NEBO_G109_PROFILE_WORK]
    ret
.peak: mov rax,[rel g109_profile+NEBO_G109_PROFILE_PEAK]
    ret
.tooling_code: mov rax,[rel g109_tooling+NEBO_G109_TOOLING_CODE]
    ret
.state: mov rax,[rel g109_receipt+NEBO_G109_RECEIPT_STATE]
    ret
.maturity: mov eax,NEBO_G109_MATURITY_RENDERER_PROFILER_GREEN
    ret
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
    ret
align 4
.table:
    dd .mode-.table,.code-.table,.severity-.table,.phase-.table
    dd .depth-.table,.budget-.table,.fingerprint-.table,.applicability-.table
    dd .edits-.table,.safe-.table,.work-.table,.peak-.table
    dd .tooling_code-.table,.state-.table,.maturity-.table

; EDI case 1..12. Each expected rejection preserves a sentinel receipt.
nebo_g109_negative_probe:
    push rbx
    push r12
    mov ebx,edi
    cmp ebx,1
    jb .invalid
    cmp ebx,12
    ja .invalid
    call g109_clear
    mov qword [rel g109_input+NEBO_G109_INPUT_MODE],1
    mov qword [rel g109_input+NEBO_G109_INPUT_SEED],3901
    mov qword [rel g109_input+NEBO_G109_INPUT_DEPTH],2
    mov qword [rel g109_input+NEBO_G109_INPUT_BUDGET],16
    mov qword [rel g109_input+NEBO_G109_INPUT_FLAGS],NEBO_G109_FLAGS_REQUIRED
    mov qword [rel g109_input+NEBO_G109_INPUT_CAPS],NEBO_G109_CAP_REQUIRED
    mov qword [rel g109_input+NEBO_G109_INPUT_SPAN_START],11
    mov qword [rel g109_input+NEBO_G109_INPUT_SPAN_END],13
    mov qword [rel g109_bad_receipt],0x51515151
    cmp ebx,1
    jne .c2
    mov qword [rel g109_input+NEBO_G109_INPUT_MODE],0
    mov r12d,-NEBO_G109_ERROR_RANGE
    jmp .build
.c2: cmp ebx,2
    jne .c3
    mov qword [rel g109_input+NEBO_G109_INPUT_SEED],2899
    mov r12d,-NEBO_G109_ERROR_RANGE
    jmp .build
.c3: cmp ebx,3
    jne .c4
    mov qword [rel g109_input+NEBO_G109_INPUT_DEPTH],0
    mov r12d,-NEBO_G109_ERROR_RANGE
    jmp .build
.c4: cmp ebx,4
    jne .c5
    mov qword [rel g109_input+NEBO_G109_INPUT_DEPTH],9
    mov r12d,-NEBO_G109_ERROR_RANGE
    jmp .build
.c5: cmp ebx,5
    jne .c6
    mov qword [rel g109_input+NEBO_G109_INPUT_BUDGET],0
    mov r12d,-NEBO_G109_ERROR_RANGE
    jmp .build
.c6: cmp ebx,6
    jne .c7
    mov qword [rel g109_input+NEBO_G109_INPUT_BUDGET],65
    mov r12d,-NEBO_G109_ERROR_RANGE
    jmp .build
.c7: cmp ebx,7
    jne .c8
    mov qword [rel g109_input+NEBO_G109_INPUT_CAPS],NEBO_G109_CAP_REQUIRED-NEBO_G109_CAP_DEBUG
    mov r12d,-NEBO_G109_ERROR_CAPABILITY
    jmp .build
.c8: cmp ebx,8
    jne .c9
    mov qword [rel g109_input+NEBO_G109_INPUT_FLAGS],NEBO_G109_FLAGS_REQUIRED-NEBO_G109_FLAG_CANONICAL
    mov r12d,-NEBO_G109_ERROR_PRIVACY
    jmp .build
.c9: cmp ebx,9
    jne .c10
    mov qword [rel g109_input+NEBO_G109_INPUT_SPAN_END],11
    mov r12d,-NEBO_G109_ERROR_INVALID
    jmp .build
.c10: cmp ebx,10
    jne .c11
    mov qword [rel g109_input+NEBO_G109_INPUT_SPAN_END],40
    mov r12d,-NEBO_G109_ERROR_LIMIT
.build:
    lea rdi,[rel g109_input]
    lea rsi,[rel g109_bad_receipt]
    call nebo_g109_diagnostic_build
    cmp eax,r12d
    jne .failed
    cmp qword [rel g109_bad_receipt],0x51515151
    jne .failed
    xor eax,eax
    jmp .done
.c11: cmp ebx,11
    jne .c12
    mov edi,107
    lea rsi,[rel g109_registry]
    call nebo_g109_registry_lookup
    cmp eax,-NEBO_G109_ERROR_REGISTRY
    jne .failed
    xor eax,eax
    jmp .done
.c12:
    mov edi,1
    mov esi,3902
    mov edx,0x0210
    call nebo_g109_source_probe
    test eax,eax
    js .failed
    lea rdi,[rel g109_receipt]
    call nebo_g109_receipt_close
    test eax,eax
    jnz .failed
    lea rdi,[rel g109_receipt]
    call nebo_g109_receipt_close
    cmp eax,-NEBO_G109_ERROR_STATE
    jne .failed
    xor eax,eax
    jmp .done
.failed:
    mov eax,-NEBO_G109_ERROR_INVALID
    jmp .done
.invalid:
    mov eax,-NEBO_G109_ERROR_INVALID
.done:
    pop r12
    pop rbx
    ret
