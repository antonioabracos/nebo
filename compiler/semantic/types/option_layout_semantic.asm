; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F02 generic explicit-tag Option A0 layout validation.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/semantic/types/option_layout_semantic.inc"

section .text

NEBOC_ABI_FUNCTION neboc_option_layout
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 mov qword [rdi+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],0
 mov qword [rdi+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_ALIGN_OFFSET],0
 mov qword [rdi+NEBOC_OPTION_LAYOUT_REQUEST_DIAGNOSTIC_OFFSET],0
 mov qword [rdi+NEBOC_OPTION_LAYOUT_REQUEST_HASH_OFFSET],0
 mov rax,[rdi+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET]
 cmp rax,NEBOC_OPTION_MAX_PAYLOAD_SIZE
 ja .layout
 mov rcx,[rdi+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET]
 test rcx,rcx
 jz .layout
 mov rdx,rcx
 dec rdx
 test rcx,rdx
 jnz .layout
 cmp rcx,64
 ja .layout
 cmp rcx,8
 jae .align_ready
 mov ecx,8
.align_ready:
 add rax,8
 jc .layout
 mov rdx,rcx
 dec rdx
 add rax,rdx
 jc .layout
 not rdx
 and rax,rdx
 cmp rax,NEBOC_OPTION_MAX_PAYLOAD_SIZE
 ja .layout
 mov [rdi+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],rax
 mov [rdi+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_ALIGN_OFFSET],rcx
 mov r8,14695981039346656037
 mov r9,1099511628211
 xor r8,[rdi+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET]
 imul r8,r9
 xor r8,[rdi+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET]
 imul r8,r9
 xor r8,rax
 imul r8,r9
 xor r8,rcx
 imul r8,r9
 mov [rdi+NEBOC_OPTION_LAYOUT_REQUEST_HASH_OFFSET],r8
 xor eax,eax
 ret
.layout:
 mov qword [rdi+NEBOC_OPTION_LAYOUT_REQUEST_DIAGNOSTIC_OFFSET],NEBOC_OPTION_DIAG_LAYOUT
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

NEBOC_ABI_FUNCTION neboc_result_layout
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 mov qword [rdi+NEBOC_RESULT_LAYOUT_RESULT_SIZE_OFFSET],0
 mov qword [rdi+NEBOC_RESULT_LAYOUT_RESULT_ALIGN_OFFSET],0
 mov qword [rdi+NEBOC_RESULT_LAYOUT_DIAGNOSTIC_OFFSET],0
 mov qword [rdi+NEBOC_RESULT_LAYOUT_HASH_OFFSET],0
 mov rax,[rdi+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET]
 cmp rax,NEBOC_RESULT_MAX_PAYLOAD_SIZE
 ja .layout
 mov rdx,[rdi+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET]
 cmp rdx,NEBOC_RESULT_MAX_PAYLOAD_SIZE
 ja .layout
 cmp rax,rdx
 cmovb rax,rdx
 mov rcx,[rdi+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET]
 test rcx,rcx
 jz .layout
 mov r8,rcx
 dec r8
 test rcx,r8
 jnz .layout
 cmp rcx,64
 ja .layout
 mov rdx,[rdi+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET]
 test rdx,rdx
 jz .layout
 mov r8,rdx
 dec r8
 test rdx,r8
 jnz .layout
 cmp rdx,64
 ja .layout
 cmp rcx,rdx
 cmovb rcx,rdx
 cmp rcx,8
 jae .align_ready
 mov ecx,8
.align_ready:
 add rax,8
 jc .layout
 mov rdx,rcx
 dec rdx
 add rax,rdx
 jc .layout
 not rdx
 and rax,rdx
 cmp rax,NEBOC_RESULT_MAX_PAYLOAD_SIZE
 ja .layout
 mov [rdi+NEBOC_RESULT_LAYOUT_RESULT_SIZE_OFFSET],rax
 mov [rdi+NEBOC_RESULT_LAYOUT_RESULT_ALIGN_OFFSET],rcx
 mov r8,14695981039346656037
 mov r9,1099511628211
 xor r8,[rdi+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET]
 imul r8,r9
 xor r8,[rdi+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET]
 imul r8,r9
 xor r8,[rdi+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET]
 imul r8,r9
 xor r8,[rdi+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET]
 imul r8,r9
 xor r8,rax
 imul r8,r9
 xor r8,rcx
 imul r8,r9
 mov [rdi+NEBOC_RESULT_LAYOUT_HASH_OFFSET],r8
 xor eax,eax
 ret
.layout:
 mov qword [rdi+NEBOC_RESULT_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_RESULT_DIAG_LAYOUT
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
