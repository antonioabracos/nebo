; CONSOLE-VISUAL-DASHBOARD-E-PLOTS-F02 pure logical/global constraint checking over bounded vectors.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/solver/constraints.inc"
section .text
NEBOC_ABI_FUNCTION nebo_constraint_check
 ; operation, values, count, argument
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBO_CONSTRAINT_MAX_VALUES
 ja .limit
 cmp rdi,NEBO_CONSTRAINT_REQUIRE
 je .require
 cmp rdi,NEBO_CONSTRAINT_IMPLIES
 je .implies
 cmp rdi,NEBO_CONSTRAINT_EXACTLY_ONE
 je .exactly_one
 cmp rdi,NEBO_CONSTRAINT_ALL_DIFFERENT
 je .all_different
 cmp rdi,NEBO_CONSTRAINT_SUM_EQUALS
 je .sum_equals
 cmp rdi,NEBO_CONSTRAINT_ELEMENT
 je .element
 jmp .invalid
.require:
 cmp rdx,1
 jne .invalid
 cmp qword [rsi],0
 je .unsat
 jmp .ok
.implies:
 cmp rdx,2
 jne .invalid
 cmp qword [rsi],0
 je .ok
 cmp qword [rsi+8],0
 je .unsat
 jmp .ok
.exactly_one:
 xor eax,eax
 xor r8d,r8d
.one_loop:
 cmp rax,rdx
 jae .one_done
 cmp qword [rsi+rax*8],0
 je .one_next
 inc r8
.one_next: inc rax
 jmp .one_loop
.one_done:
 cmp r8,1
 jne .unsat
 jmp .ok
.all_different:
 xor eax,eax
.outer:
 cmp rax,rdx
 jae .ok
 mov r8,rax
 inc r8
.inner:
 cmp r8,rdx
 jae .outer_next
 mov r9,[rsi+rax*8]
 cmp r9,[rsi+r8*8]
 je .unsat
 inc r8
 jmp .inner
.outer_next: inc rax
 jmp .outer
.sum_equals:
 xor eax,eax
 xor r8d,r8d
.sum_loop:
 cmp rax,rdx
 jae .sum_done
 add r8,[rsi+rax*8]
 jo .overflow
 inc rax
 jmp .sum_loop
.sum_done:
 cmp r8,rcx
 jne .unsat
 jmp .ok
.element:
 cmp rcx,rdx
 jae .unsat
 ; the selected element must be nonzero for this bounded condition form
 cmp qword [rsi+rcx*8],0
 je .unsat
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_CONSTRAINT_STATUS_INVALID
 ret
.limit: mov eax,NEBO_CONSTRAINT_STATUS_LIMIT
 ret
.unsat: mov eax,NEBO_CONSTRAINT_STATUS_UNSAT
 ret
.overflow: mov eax,NEBO_CONSTRAINT_STATUS_OVERFLOW
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
