; FILESYSTEM-PATHS-E-FORMATOS-F05 pure bounded compile-time scalar evaluator and local resource descriptor.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/meta/compile_eval.inc"
section .text
NEBOC_ABI_FUNCTION nebo_compile_eval_binary
 ; op, lhs, rhs, output, step budget
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 test r8,r8
 jz .budget
 cmp r8,NEBO_EVAL_MAX_STEPS
 ja .budget
 cmp rdi,NEBO_EVAL_ADD
 je .add
 cmp rdi,NEBO_EVAL_SUB
 je .sub
 cmp rdi,NEBO_EVAL_MUL
 je .mul
 cmp rdi,NEBO_EVAL_EQUAL
 je .equal
 mov eax,NEBO_EVAL_STATUS_OPERATOR
 ret
.add: mov rax,rsi
 add rax,rdx
 jo .overflow
 jmp .store
.sub: mov rax,rsi
 sub rax,rdx
 jo .overflow
 jmp .store
.mul: mov rax,rsi
 imul rax,rdx
 jo .overflow
 jmp .store
.equal: xor eax,eax
 cmp rsi,rdx
 sete al
.store: mov [rcx],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBO_EVAL_STATUS_INVALID
 ret
.overflow: mov eax,NEBO_EVAL_STATUS_OVERFLOW
 ret
.budget: mov eax,NEBO_EVAL_STATUS_BUDGET
 ret

NEBOC_ABI_FUNCTION nebo_compile_resource_validate
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_RESOURCE_CAPABILITY],NEBO_RESOURCE_CAP_LOCAL_READ
 jne .capability
 mov rax,[rdi+NEBO_RESOURCE_SIZE]
 test rax,rax
 jz .resource
 cmp rax,NEBO_RESOURCE_MAX_BYTES
 ja .resource
 cmp qword [rdi+NEBO_RESOURCE_DATA],0
 je .resource
 mov rax,[rdi+NEBO_RESOURCE_HASH_LO]
 or rax,[rdi+NEBO_RESOURCE_HASH_HI]
 jz .resource
 cmp qword [rdi+NEBO_RESOURCE_MEDIA_TYPE],0
 je .resource
 xor eax,eax
 ret
.invalid: mov eax,NEBO_EVAL_STATUS_INVALID
 ret
.capability: mov eax,NEBO_EVAL_STATUS_CAPABILITY
 ret
.resource: mov eax,NEBO_EVAL_STATUS_RESOURCE
 ret

NEBOC_ABI_FUNCTION nebo_compile_cache_key
 ; explicit source digest, target digest, policy digest -> deterministic scalar key
 mov rax,rdi
 xor rax,rsi
 rol rax,13
 xor rax,rdx
 rol rax,29
 test rax,rax
 jnz .done
 mov eax,1
.done: ret
section .note.GNU-stack noalloc noexec nowrite progbits
