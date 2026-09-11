; Nebo Assembly — deterministic keyword classification v0
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/tokens/token_kind.inc"
section .rodata
%include "compiler/tokens/keyword_table.inc"
section .text
; keyword_kind(bytes*, length) -> EAX kind or 0
NEBOC_ABI_FUNCTION neboc_token_keyword_kind
 mov r8,rdi
 mov r9,rsi
 lea r10,[rel keyword_table]
 mov edx,KEYWORD_COUNT
.loop:
 test edx,edx
 jz .none
 cmp [r10+8],r9
 jne .next
 mov rdi,r8
 mov rsi,[r10]
 mov rcx,r9
 repe cmpsb
 je .found
.next:
 add r10,24
 dec edx
 jmp .loop
.found:
 mov eax,[r10+16]
 cld
 ret
.none:
 xor eax,eax
 cld
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
