; G152 semantic organize-imports plan. It orders selected SymbolIds while the
; original AST spans keep comments/trivia attached to their source records.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
%include "compiler/parser/selective_import_parser.inc"

section .text

; imports.organize(ast, policy, out_ordered_hashes, capacity, out_count)
NEBOC_ABI_FUNCTION neboc_organize_imports
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 test r8,r8
 jz .argument
 mov qword [r8],0
 cmp rsi,NEBOC_ORGANIZE_POLICY_CHECK
 je .policy_ok
 cmp rsi,NEBOC_ORGANIZE_POLICY_APPLY
 jne .source
.policy_ok:
 cmp qword [rdi+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .source
 mov r9,[rdi+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET]
 test r9,r9
 jz .source
 cmp r9,NEBOC_SELECTIVE_MAX
 ja .source
 cmp r9,rcx
 ja .limit
 xor r10d,r10d
.copy:
 cmp r10,r9
 jae .sort
 mov rax,[rdi+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+r10*8]
 mov [rdx+r10*8],rax
 inc r10
 jmp .copy
.sort:
 cmp r9,1
 jbe .done
 mov r10,r9
 dec r10
.outer:
 xor r11d,r11d
.inner:
 cmp r11,r10
 jae .next_outer
 mov rax,[rdx+r11*8]
 mov rcx,[rdx+r11*8+8]
 cmp rax,rcx
 jbe .next
 mov [rdx+r11*8],rcx
 mov [rdx+r11*8+8],rax
.next:
 inc r11
 jmp .inner
.next_outer:
 dec r10
 jnz .outer
.done:
 mov [r8],r9
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
