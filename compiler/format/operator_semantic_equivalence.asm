; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA canonical token/AST semantic equivalence proof.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/format/symbol_style_profile.inc"

section .text
; operator_semantic_equivalence(before_kinds*, after_kinds*, count, out*)
NEBOC_ABI_FUNCTION neboc_operator_semantic_equivalence
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rdx,NEBOC_FORMAT_EQUIVALENCE_MAX_TOKENS
 ja .limit
 mov r8,0xcbf29ce484222325
 xor r9d,r9d
.loop:
 cmp r9,rdx
 jae .store
 mov r10,[rdi+r9*8]
 cmp r10,[rsi+r9*8]
 jne .source
 xor r8,r10
 mov rax,0x100000001b3
 imul r8,rax
 inc r9
 jmp .loop
.store:
 mov [rcx+NEBOC_FORMAT_EQUIVALENCE_HASH_OFFSET],r8
 mov [rcx+NEBOC_FORMAT_EQUIVALENCE_TOKEN_COUNT_OFFSET],rdx
 mov qword [rcx+NEBOC_FORMAT_EQUIVALENCE_AST_IDENTITY_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
