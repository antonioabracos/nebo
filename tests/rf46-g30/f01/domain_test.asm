bits 64
default rel
%include "runtime/solver/domain.inc"
extern nebo_solver_init,nebo_solver_add_domain,nebo_symbolic_is_bound
section .bss
state resb NEBO_SOLVER_STATE_SIZE
vars resb NEBO_SOLVER_VAR_SIZE*4
section .text
global _start
_start:
 lea rdi,[state]
 lea rsi,[vars]
 mov edx,4
 mov ecx,123
 mov r8d,1000
 call nebo_solver_init
 test eax,eax
 jnz fail
 lea rdi,[state]
 mov esi,1
 mov edx,NEBO_SOLVER_KIND_BOOL
 xor ecx,ecx
 mov r8d,1
 mov r9d,2
 call nebo_solver_add_domain
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_SOLVER_STATE_COUNT],1
 jne fail
 lea rdi,[vars]
 call nebo_symbolic_is_bound
 test eax,eax
 jnz fail
 lea rdi,[state]
 mov esi,1
 mov edx,NEBO_SOLVER_KIND_BOOL
 xor ecx,ecx
 mov r8d,1
 mov r9d,2
 call nebo_solver_add_domain
 cmp eax,NEBO_SOLVER_STATUS_DUPLICATE
 jne fail
 cmp qword [state+NEBO_SOLVER_STATE_COUNT],1
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
