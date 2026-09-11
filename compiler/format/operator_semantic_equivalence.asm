; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA canonical token/AST semantic equivalence proof.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/format/symbol_style_profile.inc"

section .text
; operator_semantic_equivalence(before_records*, after_records*, count, out*)
; Each record is {canonical token kind, semantic payload}.  Source spelling,
; byte offsets and provenance flags are intentionally excluded.
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
 mov rax,r9
 shl rax,4
 mov r10,[rdi+rax+NEBOC_FORMAT_SEMANTIC_TOKEN_KIND_OFFSET]
 cmp r10,[rsi+rax+NEBOC_FORMAT_SEMANTIC_TOKEN_KIND_OFFSET]
 jne .source
 xor r8,r10
 mov rax,0x100000001b3
 imul r8,rax
 mov rax,r9
 shl rax,4
 mov r10,[rdi+rax+NEBOC_FORMAT_SEMANTIC_TOKEN_PAYLOAD_OFFSET]
 cmp r10,[rsi+rax+NEBOC_FORMAT_SEMANTIC_TOKEN_PAYLOAD_OFFSET]
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
