; REDE-E-PROTOCOLOS-F04 deterministic bounded model exploration over up to 64 states.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/verification/model_check.inc"
section .text
NEBOC_ABI_FUNCTION nebo_model_check
 ; model, result
 test rdi,rdi
 jz .invalid_plain
 test rsi,rsi
 jz .invalid_plain
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov qword [r13],0
 mov qword [r13+8],0
 mov qword [r13+16],0
 mov qword [r13+24],0
 mov rcx,[r12+NEBO_MODEL_STATE_COUNT]
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBO_MODEL_MAX_STATES
 ja .limit
 cmp qword [r12+NEBO_MODEL_TRANSITIONS],0
 je .invalid
 mov r8,[r12+NEBO_MODEL_INITIAL_MASK]
 test r8,r8
 jz .invalid
 mov r9,r8
 xor r10d,r10d
 xor r11d,r11d
.level:
 mov rax,r9
 and rax,[r12+NEBO_MODEL_UNSAFE_MASK]
 jnz .violated
 cmp qword [r12+NEBO_MODEL_PROPERTY_KIND],NEBO_MODEL_PROPERTY_EVENTUALLY
 jne .expand
 mov rax,r9
 and rax,[r12+NEBO_MODEL_GOAL_MASK]
 jnz .verified
.expand:
 xor ebx,ebx
 mov rcx,r9
.state_loop:
 test rcx,rcx
 jz .next_level
 cmp r11,[r12+NEBO_MODEL_STEP_BUDGET]
 jae .timeout
 inc r11
 bsf rax,rcx
 btr rcx,rax
 mov rdx,[r12+NEBO_MODEL_TRANSITIONS]
 or rbx,[rdx+rax*8]
 jmp .state_loop
.next_level:
 mov rax,r8
 not rax
 and rbx,rax
 test rbx,rbx
 jz .exhausted
 or r8,rbx
 mov r9,rbx
 inc r10
 jmp .level
.exhausted:
 cmp qword [r12+NEBO_MODEL_PROPERTY_KIND],NEBO_MODEL_PROPERTY_ALWAYS_SAFE
 je .verified
 mov qword [r13+NEBO_MODEL_RESULT_STATE],NEBO_MODEL_STATE_DEADLOCK
 jmp .finish
.verified: mov qword [r13+NEBO_MODEL_RESULT_STATE],NEBO_MODEL_STATE_VERIFIED
 jmp .finish
.violated:
 bsf rax,rax
 mov qword [r13+NEBO_MODEL_RESULT_STATE],NEBO_MODEL_STATE_VIOLATED
 mov [r13+NEBO_MODEL_RESULT_WITNESS],rax
 jmp .finish
.timeout: mov qword [r13+NEBO_MODEL_RESULT_STATE],NEBO_MODEL_STATE_TIMEOUT
.finish:
 mov [r13+NEBO_MODEL_RESULT_DEPTH],r10
 mov [r13+NEBO_MODEL_RESULT_VISITED],r8
 xor eax,eax
 jmp .return
.invalid: mov eax,NEBO_MODEL_STATUS_INVALID
 jmp .return
.limit: mov eax,NEBO_MODEL_STATUS_LIMIT
.return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_plain: mov eax,NEBO_MODEL_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
