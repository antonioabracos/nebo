bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
section .text
extern neboc_import_decl_parse
NEBOC_ABI_FUNCTION neboc_import_format
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test r8,r8
 jz .arg
 cmp rsi,NEBOC_IMPORT_MAX_BYTES
 ja .limit
 cmp rcx,rsi
 jb .limit
 ; Formatting is parser-owned: malformed, wildcard, dynamic and reserved
 ; qualifier forms can never be copied into an apparently canonical source.
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,r8
 sub rsp,NEBOC_IMPORT_AST_SIZE
 mov rdi,rbx
 mov rsi,r12
 mov rdx,rsp
 call neboc_import_decl_parse
 test eax,eax
 jnz .parsed_done
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 mov r8,r14
 xor r9d,r9d
.loop: cmp r9,rsi
 jae .put
 mov al,[rdi+r9]
 mov [rdx+r9],al
 inc r9
 jmp .loop
.put:
 mov [r8],rsi
 xor eax,eax
.parsed_done:
 add rsp,NEBOC_IMPORT_AST_SIZE
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
