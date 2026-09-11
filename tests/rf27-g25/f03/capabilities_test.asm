; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F03 authenticated capability lifecycle and attack tests.
bits 64
default rel
%include "runtime/capabilities/capabilities.inc"

extern nebo_capability_authority_init
extern nebo_capability_authority_revoke_all
extern nebo_capability_grant
extern nebo_capability_attenuate
extern nebo_capability_revoke
extern nebo_capability_precheck

section .rodata
secret: times 32 db 0x5a
zero_secret: times 32 db 0
kind_effects:
    dq NEBO_EFFECT_FILE_READ
    dq NEBO_EFFECT_NETWORK
    dq NEBO_EFFECT_PROCESS
    dq NEBO_EFFECT_RANDOM
    dq NEBO_EFFECT_CLOCK
    dq NEBO_EFFECT_CONSOLE_WRITE

section .bss
align 16
authority resb NEBO_AUTHORITY_SIZE
authority2 resb NEBO_AUTHORITY_SIZE
capability resb NEBO_CAPABILITY_SIZE
child resb NEBO_CAPABILITY_SIZE
copied resb NEBO_CAPABILITY_SIZE
grant_request resb NEBO_CAPABILITY_GRANT_SIZE

section .text
prepare_file_grant:
    lea rdi,[grant_request]
    mov ecx,NEBO_CAPABILITY_GRANT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[authority]
    mov [grant_request+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET],rax
    lea rax,[capability]
    mov [grant_request+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],NEBO_CAPABILITY_FILE
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],0xf
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],3
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],10
    ret

grant_file:
    sub rsp,8
    call prepare_file_grant
    add rsp,8
    lea rdi,[grant_request]
    jmp nebo_capability_grant

global _start
_start:
    ; 1-3. Only a nonzero host authority seed creates an authority.
    lea rdi,[authority]
    mov esi,0x2525
    lea rdx,[secret]
    call nebo_capability_authority_init
    test eax,eax
    jnz .fail1
    mov rax,NEBO_AUTHORITY_MAGIC
    cmp [authority+NEBO_AUTHORITY_MAGIC_OFFSET],rax
    jne .fail2
    lea rdi,[authority2]
    mov esi,2
    lea rdx,[zero_secret]
    call nebo_capability_authority_init
    cmp eax,NEBO_CAPABILITY_STATUS_INVALID_ARGUMENT
    jne .fail3

    ; 4-6. Grant is HMAC tagged and address-bound.
    call grant_file
    test eax,eax
    jnz .fail4
    cmp qword [capability+NEBO_CAPABILITY_TAG_OFFSET],0
    je .fail5
    lea rax,[capability]
    cmp [capability+NEBO_CAPABILITY_ADDRESS_OFFSET],rax
    jne .fail6

    ; 7-8. Immediate precheck consumes budget before the effect.
    lea rdi,[authority]
    lea rsi,[capability]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,10
    mov r9d,1
    call nebo_capability_precheck
    test eax,eax
    jnz .fail7
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],2
    jne .fail8

    ; 9-11. Effect, scope and resource denial do not consume budget.
    lea rdi,[authority]
    lea rsi,[capability]
    mov edx,NEBO_EFFECT_NETWORK
    mov ecx,1
    mov r8d,10
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_DENIED
    jne .fail9
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],2
    jne .fail9
    lea rdi,[authority]
    lea rsi,[capability]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,11
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_SCOPE
    jne .fail10
    lea rdi,[authority]
    lea rsi,[capability]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,0x10
    mov r8d,10
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_DENIED
    jne .fail11

    ; 12-17. Attenuation narrows effects/resource/budget and enters child scope.
    call prepare_file_grant
    lea rax,[child]
    mov [grant_request+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_FILE_READ
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],3
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],1
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],11
    lea rdi,[grant_request]
    lea rsi,[capability]
    call nebo_capability_attenuate
    test eax,eax
    jnz .fail12
    cmp qword [child+NEBO_CAPABILITY_EFFECTS_OFFSET],NEBO_EFFECT_FILE_READ
    jne .fail13
    cmp qword [child+NEBO_CAPABILITY_SCOPE_OFFSET],11
    jne .fail14
    lea rdi,[authority]
    lea rsi,[child]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,11
    mov r9d,1
    call nebo_capability_precheck
    test eax,eax
    jnz .fail15
    cmp qword [child+NEBO_CAPABILITY_BUDGET_OFFSET],0
    jne .fail16
    lea rdi,[authority]
    lea rsi,[child]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,11
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_BUDGET
    jne .fail17

    ; 18-21. No attenuation dimension can amplify authority.
    call prepare_file_grant
    lea rax,[child]
    mov [grant_request+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_NETWORK
    lea rdi,[grant_request]
    lea rsi,[capability]
    call nebo_capability_attenuate
    cmp eax,NEBO_CAPABILITY_STATUS_ESCALATION
    jne .fail18
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_FILE_READ
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],0x10
    lea rdi,[grant_request]
    lea rsi,[capability]
    call nebo_capability_attenuate
    cmp eax,NEBO_CAPABILITY_STATUS_ESCALATION
    jne .fail19
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],1
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],4
    lea rdi,[grant_request]
    lea rsi,[capability]
    call nebo_capability_attenuate
    cmp eax,NEBO_CAPABILITY_STATUS_ESCALATION
    jne .fail20
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],1
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],12
    lea rdi,[grant_request]
    lea rsi,[capability]
    call nebo_capability_attenuate
    cmp eax,NEBO_CAPABILITY_STATUS_SCOPE
    jne .fail21

    ; 22-23. Byte serialization and tag tampering are rejected.
    lea rsi,[capability]
    lea rdi,[copied]
    mov ecx,NEBO_CAPABILITY_SIZE/8
    rep movsq
    lea rdi,[authority]
    lea rsi,[copied]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,10
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_SERIALIZED
    jne .fail22
    xor byte [capability+NEBO_CAPABILITY_TAG_OFFSET],1
    lea rdi,[authority]
    lea rsi,[capability]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,10
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_FORGED
    jne .fail23

    ; 24-27. Individual and authority-wide revocation block future use.
    call grant_file
    test eax,eax
    jnz .fail24
    lea rdi,[authority]
    lea rsi,[capability]
    call nebo_capability_revoke
    test eax,eax
    jnz .fail24
    lea rdi,[authority]
    lea rsi,[capability]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,10
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_REVOKED
    jne .fail25
    call grant_file
    test eax,eax
    jnz .fail26
    lea rdi,[authority]
    call nebo_capability_authority_revoke_all
    test eax,eax
    jnz .fail26
    lea rdi,[authority]
    lea rsi,[capability]
    mov edx,NEBO_EFFECT_FILE_READ
    mov ecx,1
    mov r8d,10
    mov r9d,1
    call nebo_capability_precheck
    cmp eax,NEBO_CAPABILITY_STATUS_REVOKED
    jne .fail27

    ; Restore an authority, then prove all six public capability kinds.
    lea rdi,[authority]
    mov esi,0x2525
    lea rdx,[secret]
    call nebo_capability_authority_init
    test eax,eax
    jnz .fail28
    mov ebx,1
.kind_loop:
    call prepare_file_grant
    mov [grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],rbx
    mov rax,[kind_effects+rbx*8-8]
    mov [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],rax
    lea rdi,[grant_request]
    call nebo_capability_grant
    test eax,eax
    jnz .fail28
    inc rbx
    cmp rbx,7
    jb .kind_loop

    ; 29-30. Unknown kinds and kind/effect mismatch are denied.
    call prepare_file_grant
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],7
    lea rdi,[grant_request]
    call nebo_capability_grant
    cmp eax,NEBO_CAPABILITY_STATUS_DENIED
    jne .fail29
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],NEBO_CAPABILITY_FILE
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_NETWORK
    lea rdi,[grant_request]
    call nebo_capability_grant
    cmp eax,NEBO_CAPABILITY_STATUS_DENIED
    jne .fail30

    xor edi,edi
    jmp .exit
%assign i 1
%rep 30
.fail%+i:
    mov edi,i
    jmp .exit
%assign i i+1
%endrep
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
