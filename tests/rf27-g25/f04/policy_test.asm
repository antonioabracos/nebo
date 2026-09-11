; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F04 deny-first policy, budgets, trust, deadline and cancellation.
bits 64
default rel
%include "runtime/effects/policy.inc"

extern nebo_capability_authority_init
extern nebo_capability_grant
extern nebo_policy_evaluate

section .rodata
secret: times 32 db 0x6b

section .bss
align 16
authority resb NEBO_AUTHORITY_SIZE
capability resb NEBO_CAPABILITY_SIZE
grant_request resb NEBO_CAPABILITY_GRANT_SIZE
policy resb nebo_policy_POLICY_SIZE
policy_copy resb nebo_policy_POLICY_SIZE

section .text
grant_file:
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
    lea rdi,[grant_request]
    jmp nebo_capability_grant

prepare_policy:
    lea rdi,[policy]
    mov ecx,NEBO_POLICY_QWORDS
    xor eax,eax
    rep stosq
    lea rax,[authority]
    mov [policy+NEBO_POLICY_AUTHORITY_OFFSET],rax
    lea rax,[capability]
    mov [policy+NEBO_POLICY_CAPABILITY_OFFSET],rax
    mov qword [policy+NEBO_POLICY_EFFECTS_OFFSET],NEBO_EFFECT_FILE_READ
    mov qword [policy+NEBO_POLICY_CONSTRAINT_OFFSET],1
    mov qword [policy+NEBO_POLICY_SCOPE_OFFSET],10
    mov qword [policy+NEBO_POLICY_CAPABILITY_COST_OFFSET],1
    mov qword [policy+NEBO_POLICY_ALLOW_OFFSET],NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE
    mov qword [policy+NEBO_POLICY_TRUST_ACTUAL_OFFSET],NEBO_POLICY_TRUST_RESTRICTED
    mov qword [policy+NEBO_POLICY_TRUST_REQUIRED_OFFSET],NEBO_POLICY_TRUST_INTERNAL
    mov qword [policy+NEBO_POLICY_BUDGET_OFFSET],5
    mov qword [policy+NEBO_POLICY_COST_OFFSET],2
    mov qword [policy+NEBO_POLICY_DEADLINE_OFFSET],100
    mov qword [policy+NEBO_POLICY_NOW_OFFSET],50
    ret

evaluate:
    lea rdi,[policy]
    jmp nebo_policy_evaluate

global _start
_start:
    ; 1. Establish authenticated host authority.
    lea rdi,[authority]
    mov esi,0x252504
    lea rdx,[secret]
    call nebo_capability_authority_init
    test eax,eax
    jnz .fail1

    ; 2-6. A bounded request permits and consumes both budgets atomically.
    call grant_file
    test eax,eax
    jnz .fail2
    call prepare_policy
    call evaluate
    test eax,eax
    jnz .fail3
    cmp qword [policy+NEBO_POLICY_DECISION_OFFSET],NEBO_POLICY_DECISION_PERMIT
    jne .fail4
    cmp qword [policy+NEBO_POLICY_REMAINING_OFFSET],3
    jne .fail5
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],2
    jne .fail6

    ; 7-9. Explicit deny is first and capability budget remains untouched.
    call grant_file
    call prepare_policy
    mov qword [policy+NEBO_POLICY_DENY_OFFSET],NEBO_EFFECT_FILE_READ
    mov qword [policy+NEBO_POLICY_ALLOW_OFFSET],0
    mov qword [policy+NEBO_POLICY_CANCELED_OFFSET],1
    mov qword [policy+NEBO_POLICY_NOW_OFFSET],200
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail7
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_EXPLICIT_DENY
    jne .fail8
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],3
    jne .fail9

    ; 10-11. Missing allow is a missing grant before trust/deadline.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_ALLOW_OFFSET],0
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail10
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_MISSING_GRANT
    jne .fail11

    ; 12-13. Trust shortfall is stable.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_TRUST_ACTUAL_OFFSET],NEBO_POLICY_TRUST_PUBLIC
    mov qword [policy+NEBO_POLICY_TRUST_REQUIRED_OFFSET],NEBO_POLICY_TRUST_SECRET
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail12
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_TRUST
    jne .fail13

    ; 14-15. Cancellation precedes deadline and budget.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_CANCELED_OFFSET],1
    mov qword [policy+NEBO_POLICY_NOW_OFFSET],100
    mov qword [policy+NEBO_POLICY_BUDGET_OFFSET],0
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail14
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_CANCELED
    jne .fail15

    ; 16-17. Monotonic now equal to deadline is expired.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_NOW_OFFSET],100
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail16
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_DEADLINE
    jne .fail17

    ; 18-19. Policy budget rejects before capability consumption.
    call grant_file
    call prepare_policy
    mov qword [policy+NEBO_POLICY_BUDGET_OFFSET],1
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail18
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_BUDGET
    jne .fail19
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],3
    jne .fail19

    ; 20-22. An authenticated capability mismatch maps to missing grant.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_CONSTRAINT_OFFSET],0x10
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail20
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_MISSING_GRANT
    jne .fail21
    cmp qword [policy+NEBO_POLICY_CAPABILITY_STATUS_OFFSET],NEBO_CAPABILITY_STATUS_DENIED
    jne .fail22

    ; 23-24. Unknown atoms are rejected before every other rule.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_EFFECTS_OFFSET],0x4000
    mov qword [policy+NEBO_POLICY_ALLOW_OFFSET],0x4000
    call evaluate
    cmp eax,NEBO_POLICY_STATUS_DENIED
    jne .fail23
    cmp qword [policy+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_UNKNOWN
    jne .fail24

    ; 25-26. Pure work needs no capability but retains budget/deadline rules.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_AUTHORITY_OFFSET],0
    mov qword [policy+NEBO_POLICY_CAPABILITY_OFFSET],0
    mov qword [policy+NEBO_POLICY_EFFECTS_OFFSET],0
    call evaluate
    test eax,eax
    jnz .fail25
    cmp qword [policy+NEBO_POLICY_REMAINING_OFFSET],3
    jne .fail26

    ; 27. Null pointers do not publish outputs.
    xor edi,edi
    call nebo_policy_evaluate
    cmp eax,NEBO_POLICY_STATUS_INVALID_ARGUMENT
    jne .fail27

    ; 28-30. Identical pure requests produce identical records and hash.
    call prepare_policy
    mov qword [policy+NEBO_POLICY_AUTHORITY_OFFSET],0
    mov qword [policy+NEBO_POLICY_CAPABILITY_OFFSET],0
    mov qword [policy+NEBO_POLICY_EFFECTS_OFFSET],0
    call evaluate
    test eax,eax
    jnz .fail28
    lea rsi,[policy]
    lea rdi,[policy_copy]
    mov ecx,NEBO_POLICY_QWORDS
    rep movsq
    lea rdi,[policy_copy]
    call nebo_policy_evaluate
    test eax,eax
    jnz .fail29
    lea rsi,[policy]
    lea rdi,[policy_copy]
    mov ecx,NEBO_POLICY_QWORDS
    repe cmpsq
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
