bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/lowering/collections/list_plan.inc"
section .text
; Emit a relocatable descriptor image: data and allocator are owner fixups.
NEBOC_ABI_FUNCTION neboc_list_codegen_descriptor
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rax,NEBOC_LIST_PLAN_MAGIC
 cmp [r12+NEBOC_LIST_PLAN_MAGIC_OFFSET],rax
 jne .source
 mov rdi,r12
 mov ecx,NEBOC_LIST_PLAN_HASHED_BYTES
 call hash_bytes
 cmp rax,[r12+NEBOC_LIST_PLAN_HASH_OFFSET]
 jne .source
 mov rdi,r13
 mov ecx,NEBOC_LIST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r12+NEBOC_LIST_PLAN_LENGTH_OFFSET]
 mov [r13+NEBOC_LIST_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_LIST_PLAN_CAPACITY_OFFSET]
 mov [r13+NEBOC_LIST_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBOC_LIST_PLAN_ELEMENT_SIZE_OFFSET]
 mov [r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_LIST_PLAN_ELEMENT_ALIGN_OFFSET]
 mov [r13+NEBOC_LIST_ELEMENT_ALIGN_OFFSET],rax
 mov rax,[r12+NEBOC_LIST_PLAN_GENERATION_OFFSET]
 mov [r13+NEBOC_LIST_GENERATION_OFFSET],rax
 mov rax,[r12+NEBOC_LIST_PLAN_FLAGS_OFFSET]
 mov [r13+NEBOC_LIST_FLAGS_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r13
 pop r12
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
hash_bytes:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.hash_loop:
 cmp edx,ecx
 jae .hash_done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .hash_loop
.hash_done:
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
