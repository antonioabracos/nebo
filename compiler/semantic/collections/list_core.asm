; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-F02 List descriptor invariant checker.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"

section .text

NEBOC_ABI_FUNCTION neboc_list_validate
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 mov rax,NEBOC_LIST_MAGIC
 cmp [rdi+NEBOC_LIST_FLAGS_OFFSET],rax
 jne .source
 mov rax,[rdi+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_LIST_MAX_ELEMENT_SIZE
 ja .source
 mov rcx,[rdi+NEBOC_LIST_ELEMENT_ALIGN_OFFSET]
 test rcx,rcx
 jz .source
 cmp rcx,NEBOC_LIST_MAX_ELEMENT_ALIGN
 ja .source
 lea rdx,[rcx-1]
 test rcx,rdx
 jnz .source
 mov rdx,[rdi+NEBOC_LIST_CAPACITY_OFFSET]
 cmp rdx,NEBOC_LIST_MAX_ELEMENTS
 ja .source
 cmp [rdi+NEBOC_LIST_LENGTH_OFFSET],rdx
 ja .source
 imul rax,rdx
 jo .source
 cmp rax,NEBOC_LIST_MAX_BYTES
 ja .source
 test rdx,rdx
 jz .zero_capacity
 cmp qword [rdi+NEBOC_LIST_DATA_OFFSET],0
 je .source
.zero_capacity:
 cmp qword [rdi+NEBOC_LIST_GENERATION_OFFSET],0
 je .source
 cmp qword [rdi+NEBOC_LIST_ALLOCATOR_OFFSET],0
 je .source
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
