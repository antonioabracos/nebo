; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-F01 bounded symbolic variables and finite domains.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/solver/domain.inc"
section .text
NEBOC_ABI_FUNCTION nebo_solver_init
 ; state, variable storage, capacity, seed, step budget
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBO_SOLVER_STATE_VARIABLES],0
 mov qword [rdi+NEBO_SOLVER_STATE_CAPACITY],0
 mov qword [rdi+NEBO_SOLVER_STATE_COUNT],0
 mov [rdi+NEBO_SOLVER_STATE_SEED],rcx
 mov [rdi+NEBO_SOLVER_STATE_STEP_BUDGET],r8
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBO_SOLVER_MAX_VARIABLES
 ja .limit
 test r8,r8
 jz .limit
 mov [rdi+NEBO_SOLVER_STATE_VARIABLES],rsi
 mov [rdi+NEBO_SOLVER_STATE_CAPACITY],rdx
 xor eax,eax
 ret
.invalid: mov eax,NEBO_SOLVER_STATUS_INVALID
 ret
.limit: mov eax,NEBO_SOLVER_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_solver_add_domain
 ; state, id, kind, min, max, domain count
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rdx,NEBO_SOLVER_KIND_INT
 jb .domain
 cmp rdx,NEBO_SOLVER_KIND_SET
 ja .domain
 cmp rcx,r8
 jg .domain
 test r9,r9
 jz .domain
 cmp r9,NEBO_SOLVER_MAX_DOMAIN_VALUES
 ja .limit
 cmp rdx,NEBO_SOLVER_KIND_BOOL
 jne .scan
 cmp rcx,0
 jne .domain
 cmp r8,1
 jne .domain
 cmp r9,2
 jne .domain
.scan:
 mov r10,[rdi+NEBO_SOLVER_STATE_COUNT]
 cmp r10,[rdi+NEBO_SOLVER_STATE_CAPACITY]
 jae .limit
 mov r11,[rdi+NEBO_SOLVER_STATE_VARIABLES]
 xor eax,eax
.scan_loop:
 cmp rax,r10
 jae .store
 cmp [r11+NEBO_SOLVER_VAR_ID],rsi
 je .duplicate
 add r11,NEBO_SOLVER_VAR_SIZE
 inc rax
 jmp .scan_loop
.store:
 mov [r11+NEBO_SOLVER_VAR_ID],rsi
 mov [r11+NEBO_SOLVER_VAR_KIND],rdx
 mov [r11+NEBO_SOLVER_VAR_MIN],rcx
 mov [r11+NEBO_SOLVER_VAR_MAX],r8
 mov [r11+NEBO_SOLVER_VAR_DOMAIN_COUNT],r9
 inc r10
 mov [rdi+NEBO_SOLVER_STATE_COUNT],r10
 xor eax,eax
 ret
.invalid: mov eax,NEBO_SOLVER_STATUS_INVALID
 ret
.limit: mov eax,NEBO_SOLVER_STATUS_LIMIT
 ret
.domain: mov eax,NEBO_SOLVER_STATUS_DOMAIN
 ret
.duplicate: mov eax,NEBO_SOLVER_STATUS_DUPLICATE
 ret

NEBOC_ABI_FUNCTION nebo_symbolic_is_bound
 test rdi,rdi
 jz .false
 cmp qword [rdi+NEBO_SOLVER_VAR_DOMAIN_COUNT],1
 sete al
 movzx eax,al
 ret
.false: xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
