; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-F03 deterministic finite search and independent solution verification.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/solver/search.inc"
section .text
NEBOC_ABI_FUNCTION nebo_solver_solve
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov qword [rsi],NEBO_SEARCH_STATE_UNKNOWN
 mov qword [rsi+8],0
 mov qword [rsi+16],0
 mov qword [rsi+24],0
 mov rcx,[rdi+NEBO_SEARCH_MODEL_VARIABLES]
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBO_SEARCH_MAX_VARIABLES
 ja .limit
 mov r8,[rdi+NEBO_SEARCH_MODEL_REQUIRED_MASK]
 mov r9,[rdi+NEBO_SEARCH_MODEL_FORBIDDEN_MASK]
 mov rax,r8
 and rax,r9
 jnz .unsat
 mov r10,1
 shl r10,cl
 xor eax,eax
 xor edx,edx
.loop:
 cmp rax,r10
 jae .unsat_steps
 cmp rdx,[rdi+NEBO_SEARCH_MODEL_STEP_BUDGET]
 jae .timeout
 inc rdx
 mov rcx,rax
 and rcx,r8
 cmp rcx,r8
 jne .next
 mov rcx,rax
 and rcx,r9
 jnz .next
 mov qword [rsi+NEBO_SEARCH_RESULT_STATE],NEBO_SEARCH_STATE_SAT
 mov [rsi+NEBO_SEARCH_RESULT_ASSIGNMENT],rax
 mov [rsi+NEBO_SEARCH_RESULT_STEPS],rdx
 mov qword [rsi+NEBO_SEARCH_RESULT_VERIFIED],1
 xor eax,eax
 ret
.next: inc rax
 jmp .loop
.unsat_steps: mov [rsi+NEBO_SEARCH_RESULT_STEPS],rdx
.unsat: mov qword [rsi+NEBO_SEARCH_RESULT_STATE],NEBO_SEARCH_STATE_UNSAT
 xor eax,eax
 ret
.timeout:
 mov qword [rsi+NEBO_SEARCH_RESULT_STATE],NEBO_SEARCH_STATE_TIMEOUT
 mov [rsi+NEBO_SEARCH_RESULT_STEPS],rdx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_SEARCH_STATUS_INVALID
 ret
.limit: mov eax,NEBO_SEARCH_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_solver_verify_assignment
 ; model, assignment
 test rdi,rdi
 jz .invalid_verify
 mov rcx,[rdi+NEBO_SEARCH_MODEL_VARIABLES]
 test rcx,rcx
 jz .invalid_verify
 cmp rcx,NEBO_SEARCH_MAX_VARIABLES
 ja .invalid_verify
 mov rax,1
 shl rax,cl
 cmp rsi,rax
 jae .rejected
 mov rax,rsi
 and rax,[rdi+NEBO_SEARCH_MODEL_REQUIRED_MASK]
 cmp rax,[rdi+NEBO_SEARCH_MODEL_REQUIRED_MASK]
 jne .rejected
 mov rax,rsi
 and rax,[rdi+NEBO_SEARCH_MODEL_FORBIDDEN_MASK]
 jnz .rejected
 xor eax,eax
 ret
.invalid_verify: mov eax,NEBO_SEARCH_STATUS_INVALID
 ret
.rejected: mov eax,NEBO_SEARCH_STATUS_REJECTED
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
