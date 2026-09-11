; Source-to-effect bridge for the G106 `privacy:` schema.  Dispatch is solely
; by the semantic mode/variant emitted by the compiler.
bits 64
default rel
%define NEBO_G106_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_privacy_source_probe.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g106_policy: resb NEBO_G106_POLICY_SIZE
g106_plan: resb NEBO_G106_PLAN_SIZE
g106_audit: resb NEBO_G106_AUDIT_SIZE

section .text
global nebo_g106_source_probe
global nebo_g106_surface_probe
global nebo_g106_negative_probe

g106_clear_outputs:
    lea rdi,[rel g106_plan]
    mov rcx,NEBO_G106_PLAN_QWORDS+NEBO_G106_AUDIT_QWORDS
    xor eax,eax
    rep stosq
    ret

; EDI mode 1..10, ESI seed, EDX variant. Success returns the source seed.
nebo_g106_source_probe:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,8
    mov ebx,edi
    mov r12d,esi
    mov r13d,edx
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G106_SOURCE_MAX_MODE
    ja .invalid
    cmp r12d,NEBO_G106_SOURCE_MIN_SEED
    jb .invalid
    cmp r13d,NEBO_G106_SOURCE_MAX_VARIANT
    ja .invalid
    call g106_clear_outputs

    xor esi,esi
    mov edx,NEBO_G106_ACTION_ALLOW
    xor ecx,ecx
    cmp ebx,2
    jne .mode3
    mov esi,nebo_text_privacy_PRIVACY_SENSITIVE
    mov edx,NEBO_G106_ACTION_REDACT
    mov ecx,NEBO_PRIVACY_REDACTED
    test r13d,r13d
    jz .init
    mov edx,NEBO_G106_ACTION_MASK
.mode3:
    cmp ebx,3
    jne .mode4
    test r13d,r13d
    jz .init
    mov edx,NEBO_G106_ACTION_DENY
.mode4:
    cmp ebx,4
    jne .mode6
    mov esi,NEBO_PRIVACY_ANONYMIZED
    mov ecx,NEBO_PRIVACY_ANONYMIZED
.mode6:
    cmp ebx,6
    jne .mode9
    mov esi,nebo_text_privacy_PRIVACY_SECRET
    mov edx,NEBO_G106_ACTION_REDACT
    mov ecx,NEBO_PRIVACY_REDACTED
.mode9:
    cmp ebx,9
    jne .mode10
    mov esi,NEBO_PRIVACY_PERSONAL_DATA
    mov edx,NEBO_G106_ACTION_REDACT
    mov ecx,NEBO_PRIVACY_REDACTED
.mode10:
    cmp ebx,10
    jne .init
    mov esi,nebo_text_privacy_PRIVACY_SECRET
    mov edx,NEBO_G106_ACTION_MASK
    mov ecx,NEBO_PRIVACY_REDACTED
.init:
    lea rdi,[rel g106_policy]
    call nebo_g106_policy_init
    test eax,eax
    jnz .effect

    mov eax,r12d
    xor edx,edx
    mov ecx,1701
    div ecx
    add edx,7000
    mov r14d,edx
    mov esi,r14d
    mov edx,r14d
    add edx,137
    cmp edx,NEBO_SCORE_MAX
    jbe .quality_ready
    sub edx,1001
.quality_ready:
    mov ecx,r12d
    shl rcx,8
    or ecx,ebx
    lea rdi,[rel g106_policy]
    call nebo_g106_policy_quality_lineage
    test eax,eax
    jnz .effect

    mov esi,NEBO_TRUST_VERIFIED
    cmp ebx,5
    jne .trust_ready
    mov esi,NEBO_TRUST_SYSTEM
.trust_ready:
    mov edx,NEBO_TRUST_VALIDATION_TOKEN_BASE
    or edx,esi
    lea rdi,[rel g106_policy]
    call nebo_g106_policy_trust
    test eax,eax
    jnz .effect

    mov esi,NEBO_G106_ACCESS_TEXT_FALLBACK
    cmp ebx,7
    jne .mode8_access
    or esi,NEBO_G106_ACCESS_HIGH_CONTRAST
.mode8_access:
    cmp ebx,8
    jne .mode9_access
    cmp r13d,1
    je .high_contrast
    cmp r13d,2
    je .screen_reader
    or esi,NEBO_G106_ACCESS_NO_COLOR
    jmp .mode9_access
.high_contrast:
    or esi,NEBO_G106_ACCESS_HIGH_CONTRAST
    jmp .mode9_access
.screen_reader:
    or esi,NEBO_G106_ACCESS_NO_COLOR|NEBO_G106_ACCESS_SCREEN_READER
.mode9_access:
    cmp ebx,9
    jne .access_ready
    mov esi,NEBO_G106_ACCESS_ALL
.access_ready:
    mov edx,NEBO_G106_STYLE_ALL
    lea ecx,[r13+4]
    lea rdi,[rel g106_policy]
    call nebo_g106_policy_accessibility
    test eax,eax
    jnz .effect
    lea rdi,[rel g106_policy]
    lea rsi,[rel g106_plan]
    lea rdx,[rel g106_audit]
    call nebo_g106_policy_evaluate
    test eax,eax
    jnz .effect
    mov eax,r12d
    jmp .done
.invalid:
    mov eax,-NEBO_G106_ERROR_INVALID
.effect:
.done:
    add rsp,8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI selector 1..10 -> last observed plan/audit field or typed error.
nebo_g106_surface_probe:
    cmp edi,1
    jb .invalid
    cmp edi,10
    ja .invalid
    lea rdx,[rel .table]
    movsxd rax,dword [rdx+rdi*4-4]
    add rax,rdx
    jmp rax
.class: mov rax,[rel g106_plan+NEBO_G106_PLAN_CLASS]
    ret
.action: mov rax,[rel g106_plan+NEBO_G106_PLAN_ACTION]
    ret
.visibility: mov rax,[rel g106_plan+NEBO_G106_PLAN_VISIBILITY]
    ret
.quality: mov rax,[rel g106_plan+NEBO_G106_PLAN_QUALITY]
    ret
.lineage: mov rax,[rel g106_plan+NEBO_G106_PLAN_LINEAGE]
    ret
.trust: mov rax,[rel g106_plan+NEBO_G106_PLAN_TRUST]
    ret
.sink: mov rax,[rel g106_plan+NEBO_G106_PLAN_SINK_MAX]
    ret
.access: mov rax,[rel g106_plan+NEBO_G106_PLAN_ACCESS]
    ret
.digest: mov rax,[rel g106_plan+NEBO_G106_PLAN_DIGEST]
    ret
.maturity: mov rax,[rel g106_audit+NEBO_G106_AUDIT_MATURITY]
    ret
.invalid:
    mov rax,-NEBO_G106_ERROR_INVALID
    ret
align 4
.table:
    dd .class-.table,.action-.table,.visibility-.table,.quality-.table
    dd .lineage-.table,.trust-.table,.sink-.table,.access-.table
    dd .digest-.table,.maturity-.table

; EDI case: 1 raw-secret sink, 2 missing fallback, 3 invalid trust,
; 4 invalid quality.  Failures must leave plan/audit sentinels untouched.
nebo_g106_negative_probe:
    push rbx
    mov ebx,edi
    cmp ebx,1
    jb .invalid
    cmp ebx,4
    ja .invalid
    lea rdi,[rel g106_policy]
    mov esi,nebo_text_privacy_PRIVACY_SECRET
    mov edx,NEBO_G106_ACTION_ALLOW
    xor ecx,ecx
    call nebo_g106_policy_init
    test eax,eax
    jnz .done
    cmp ebx,2
    je .bad_access
    cmp ebx,3
    je .bad_trust
    cmp ebx,4
    je .bad_quality
    call g106_clear_outputs
    mov qword [rel g106_plan],0x5151
    lea rdi,[rel g106_policy]
    lea rsi,[rel g106_plan]
    lea rdx,[rel g106_audit]
    call nebo_g106_policy_evaluate
    cmp eax,-NEBO_G106_ERROR_PRIVACY
    jne .failed
    cmp qword [rel g106_plan],0x5151
    jne .failed
    cmp qword [rel g106_audit],0
    jne .failed
    xor eax,eax
    jmp .done
.bad_access:
    lea rdi,[rel g106_policy]
    xor esi,esi
    mov edx,NEBO_G106_STYLE_ALL
    mov ecx,4
    call nebo_g106_policy_accessibility
    cmp eax,-NEBO_G106_ERROR_ACCESSIBILITY
    jne .failed
    xor eax,eax
    jmp .done
.bad_trust:
    lea rdi,[rel g106_policy]
    mov esi,NEBO_TRUST_VERIFIED
    xor edx,edx
    call nebo_g106_policy_trust
    cmp eax,-NEBO_G106_ERROR_TRUST
    jne .failed
    xor eax,eax
    jmp .done
.bad_quality:
    lea rdi,[rel g106_policy]
    mov esi,10001
    mov edx,9000
    mov ecx,1
    call nebo_g106_policy_quality_lineage
    cmp eax,-NEBO_G106_ERROR_QUALITY
    jne .failed
    xor eax,eax
    jmp .done
.invalid:
    mov eax,-NEBO_G106_ERROR_INVALID
    jmp .done
.failed:
    mov eax,-NEBO_G106_ERROR_STATE
.done:
    pop rbx
    ret
