; FILESYSTEM-PATHS-E-FORMATOS-F03 bounded compile-time type reflection descriptors.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/reflection/reflection.inc"
section .text
NEBOC_ABI_FUNCTION nebo_reflect_validate_type
 test rdi,rdi
 jz .invalid
 mov rax,NEBO_REFLECT_MAGIC
 cmp [rdi+NEBO_REFLECT_TYPE_MAGIC],rax
 jne .invalid
 cmp qword [rdi+NEBO_REFLECT_TYPE_VERSION],NEBO_REFLECT_VERSION
 jne .version
 mov r8,[rdi+NEBO_REFLECT_TYPE_ALIGN]
 test r8,r8
 jz .layout
 mov rax,r8
 dec rax
 test r8,rax
 jnz .layout
 cmp r8,64
 ja .layout
 mov rcx,[rdi+NEBO_REFLECT_TYPE_FIELD_COUNT]
 cmp rcx,NEBO_REFLECT_MAX_FIELDS
 ja .limit
 test rcx,rcx
 jz .ok
 mov rsi,[rdi+NEBO_REFLECT_TYPE_FIELDS]
 test rsi,rsi
 jz .invalid
 xor edx,edx
.loop:
 cmp qword [rsi+NEBO_REFLECT_FIELD_NAME_ID],0
 je .invalid
 mov rax,[rsi+NEBO_REFLECT_FIELD_OFFSET]
 mov r8,[rsi+NEBO_REFLECT_FIELD_SIZE]
 add rax,r8
 jc .layout
 cmp rax,[rdi+NEBO_REFLECT_TYPE_SIZE]
 ja .layout
 mov rax,[rsi+NEBO_REFLECT_FIELD_VISIBILITY]
 test rax,rax
 jz .visibility
 mov r8,[rdi+NEBO_REFLECT_TYPE_VISIBILITY]
 not r8
 test rax,r8
 jnz .visibility
 add rsi,NEBO_REFLECT_FIELD_DESC_SIZE
 inc rdx
 cmp rdx,rcx
 jb .loop
.ok: xor eax,eax
 ret
.invalid: mov eax,NEBO_REFLECT_STATUS_INVALID
 ret
.version: mov eax,NEBO_REFLECT_STATUS_VERSION
 ret
.limit: mov eax,NEBO_REFLECT_STATUS_LIMIT
 ret
.layout: mov eax,NEBO_REFLECT_STATUS_LAYOUT
 ret
.visibility: mov eax,NEBO_REFLECT_STATUS_VISIBILITY
 ret

NEBOC_ABI_FUNCTION nebo_reflect_field_at
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rsi,[rdi+NEBO_REFLECT_TYPE_FIELD_COUNT]
 jae .missing
 imul rax,rsi,NEBO_REFLECT_FIELD_DESC_SIZE
 add rax,[rdi+NEBO_REFLECT_TYPE_FIELDS]
 mov r8,[rax+NEBO_REFLECT_FIELD_VISIBILITY]
 test r8,rdx
 jz .visibility
 mov rsi,rax
 mov rdi,rcx
 mov ecx,NEBO_REFLECT_FIELD_DESC_SIZE/8
 rep movsq
 xor eax,eax
 ret
.invalid: mov eax,NEBO_REFLECT_STATUS_INVALID
 ret
.missing: mov eax,NEBO_REFLECT_STATUS_NOT_FOUND
 ret
.visibility: mov eax,NEBO_REFLECT_STATUS_VISIBILITY
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
