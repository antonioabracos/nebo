bits 64
default rel
%define NEBO_STRUCTURED_IMPLEMENTATION 1
%include "runtime/ai/structured.inc"
section .text
global nebo_prompt_validate
global nebo_structured_schema_validate
global nebo_structured_repair
global nebo_provenance_copy
; system_len,context_len,total*. No ambient context is consulted.
nebo_prompt_validate:
 test rdx,rdx
 jz .p_arg
 mov rax,rdi
 add rax,rsi
 jc .p_limit
 cmp rax,NEBO_STRUCT_MAX_PROMPT
 ja .p_limit
 mov [rdx],rax
 xor eax,eax
 ret
.p_limit: mov eax,NEBO_STRUCT_E_LIMIT
 ret
.p_arg: mov eax,NEBO_STRUCT_E_ARGUMENT
 ret
; values types*, value_count, schema types*, schema_count.
nebo_structured_schema_validate:
 cmp rsi,NEBO_STRUCT_MAX_FIELDS
 ja .s_limit
 cmp rcx,NEBO_STRUCT_MAX_FIELDS
 ja .s_limit
 cmp rsi,rcx
 jne .s_schema
 test rsi,rsi
 jz .s_ok
 test rdi,rdi
 jz .s_arg
 test rdx,rdx
 jz .s_arg
 xor r8d,r8d
.s_loop:
 mov rax,[rdi+r8*8]
 cmp rax,[rdx+r8*8]
 jne .s_schema
 inc r8
 cmp r8,rsi
 jb .s_loop
.s_ok: xor eax,eax
 ret
.s_limit: mov eax,NEBO_STRUCT_E_LIMIT
 ret
.s_schema: mov eax,NEBO_STRUCT_E_SCHEMA
 ret
.s_arg: mov eax,NEBO_STRUCT_E_ARGUMENT
 ret
; state={repairs}, valid flag, attempt*.
nebo_structured_repair:
 test rdi,rdi
 jz .r_arg
 test rdx,rdx
 jz .r_arg
 test rsi,rsi
 jnz .r_valid
 cmp qword [rdi],0
 jne .r_limit
 mov qword [rdx],1
 mov qword [rdi],1
 xor eax,eax
 ret
.r_valid: mov qword [rdx],0
 xor eax,eax
 ret
.r_limit: mov eax,NEBO_STRUCT_E_REPAIR
 ret
.r_arg: mov eax,NEBO_STRUCT_E_ARGUMENT
 ret
; two-u64 provenance copied exactly.
nebo_provenance_copy:
 test rdi,rdi
 jz .v_arg
 test rsi,rsi
 jz .v_arg
 mov rax,[rdi]
 mov rdx,[rdi+8]
 mov [rsi],rax
 mov [rsi+8],rdx
 xor eax,eax
 ret
.v_arg: mov eax,NEBO_STRUCT_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
