; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F04 deterministic deny-first runtime policy evaluator.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/effects/policy.inc"

section .text
extern nebo_capability_precheck

; rdi=aligned 168-byte request/result. `now` is supplied by the caller's
; monotonic-clock boundary. No external effect occurs before all policy rules.
NEBOC_ABI_FUNCTION nebo_policy_evaluate
    test rdi,rdi
    jz .bare_argument
    test rdi,7
    jnz .bare_argument
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov qword [r12+NEBO_POLICY_DECISION_OFFSET],NEBO_POLICY_DECISION_DENY
    mov qword [r12+NEBO_POLICY_REASON_OFFSET],NEBO_POLICY_REASON_NONE
    mov qword [r12+NEBO_POLICY_REJECTED_OFFSET],0
    mov qword [r12+NEBO_POLICY_REMAINING_OFFSET],0
    mov qword [r12+NEBO_POLICY_CAPABILITY_STATUS_OFFSET],0
    mov qword [r12+NEBO_POLICY_HASH_OFFSET],0

    mov r13,[r12+NEBO_POLICY_EFFECTS_OFFSET]
    mov rax,r13
    or rax,[r12+NEBO_POLICY_ALLOW_OFFSET]
    or rax,[r12+NEBO_POLICY_DENY_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_EFFECT_MASK
    jnz .unknown
    cmp qword [r12+NEBO_POLICY_TRUST_ACTUAL_OFFSET],NEBO_POLICY_TRUST_SECRET
    ja .invalid
    cmp qword [r12+NEBO_POLICY_TRUST_REQUIRED_OFFSET],NEBO_POLICY_TRUST_SECRET
    ja .invalid
    cmp qword [r12+NEBO_POLICY_CANCELED_OFFSET],1
    ja .invalid
    cmp qword [r12+NEBO_POLICY_COST_OFFSET],0
    je .invalid
    cmp qword [r12+NEBO_POLICY_CAPABILITY_COST_OFFSET],0
    je .invalid

    mov rax,[r12+NEBO_POLICY_DENY_OFFSET]
    and rax,r13
    jnz .explicit_deny
    mov rax,[r12+NEBO_POLICY_ALLOW_OFFSET]
    not rax
    and rax,r13
    jnz .missing_allow
    mov rax,[r12+NEBO_POLICY_TRUST_ACTUAL_OFFSET]
    cmp rax,[r12+NEBO_POLICY_TRUST_REQUIRED_OFFSET]
    jb .trust
    cmp qword [r12+NEBO_POLICY_CANCELED_OFFSET],0
    jne .canceled
    mov rax,[r12+NEBO_POLICY_NOW_OFFSET]
    cmp rax,[r12+NEBO_POLICY_DEADLINE_OFFSET]
    jae .deadline
    mov rax,[r12+NEBO_POLICY_COST_OFFSET]
    cmp rax,[r12+NEBO_POLICY_BUDGET_OFFSET]
    ja .budget

    ; Pure requests need no authority. Every effectful request must pass the
    ; authenticated F03 gate after all policy-only denial paths are exhausted.
    test r13,r13
    jz .permit
    mov rdi,[r12+NEBO_POLICY_AUTHORITY_OFFSET]
    mov rsi,[r12+NEBO_POLICY_CAPABILITY_OFFSET]
    mov rdx,r13
    mov rcx,[r12+NEBO_POLICY_CONSTRAINT_OFFSET]
    mov r8,[r12+NEBO_POLICY_SCOPE_OFFSET]
    mov r9,[r12+NEBO_POLICY_CAPABILITY_COST_OFFSET]
    call nebo_capability_precheck
    mov [r12+NEBO_POLICY_CAPABILITY_STATUS_OFFSET],rax
    test eax,eax
    jnz .missing_capability

.permit:
    mov qword [r12+NEBO_POLICY_DECISION_OFFSET],NEBO_POLICY_DECISION_PERMIT
    mov rax,[r12+NEBO_POLICY_BUDGET_OFFSET]
    sub rax,[r12+NEBO_POLICY_COST_OFFSET]
    mov [r12+NEBO_POLICY_REMAINING_OFFSET],rax
    xor ebx,ebx
    jmp .hash
.unknown:
    mov [r12+NEBO_POLICY_REJECTED_OFFSET],rcx
    mov r14d,NEBO_POLICY_REASON_UNKNOWN
    jmp .deny
.explicit_deny:
    mov [r12+NEBO_POLICY_REJECTED_OFFSET],rax
    mov r14d,NEBO_POLICY_REASON_EXPLICIT_DENY
    jmp .deny
.missing_allow:
    mov [r12+NEBO_POLICY_REJECTED_OFFSET],rax
.missing_capability:
    mov r14d,NEBO_POLICY_REASON_MISSING_GRANT
    jmp .deny
.trust:
    mov r14d,NEBO_POLICY_REASON_TRUST
    jmp .deny
.canceled:
    mov r14d,NEBO_POLICY_REASON_CANCELED
    jmp .deny
.deadline:
    mov r14d,NEBO_POLICY_REASON_DEADLINE
    jmp .deny
.budget:
    mov r14d,NEBO_POLICY_REASON_BUDGET
    jmp .deny
.invalid:
    mov r14d,NEBO_POLICY_REASON_INVALID
.deny:
    mov [r12+NEBO_POLICY_REASON_OFFSET],r14
    mov ebx,NEBO_POLICY_STATUS_DENIED
.hash:
    mov rax,NEBO_POLICY_FNV1A64_OFFSET_BASIS
    mov r8,NEBO_POLICY_FNV1A64_PRIME
    xor ecx,ecx
.hash_loop:
    cmp rcx,NEBO_POLICY_HASH_BYTES
    jae .hash_done
    movzx edx,byte [r12+NEBO_POLICY_HASH_START+rcx]
    xor rax,rdx
    imul rax,r8
    inc rcx
    jmp .hash_loop
.hash_done:
    mov [r12+NEBO_POLICY_HASH_OFFSET],rax
    mov eax,ebx
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    cld
    ret
.bare_argument:
    mov eax,NEBO_POLICY_STATUS_INVALID_ARGUMENT
    cld
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
