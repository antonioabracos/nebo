; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F05 fail-closed logical module path security.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"
section .text

; validate_path(bytes*, length, out_ascii_fold_hash*) -> status
NEBOC_ABI_FUNCTION neboc_module_path_validate
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rdx,7
 jnz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_MODULE_MAX_TEXT
 ja .limit
 mov rax,0xcbf29ce484222325
 xor ecx,ecx
 mov r8d,1
.loop:
 cmp rcx,rsi
 jae .done_scan
 movzx r9d,byte [rdi+rcx]
 test r8d,r8d
 jz .body
 cmp r9b,'a'
 jb .source
 cmp r9b,'z'
 ja .source
 xor r8d,r8d
 jmp .hash
.body:
 cmp r9b,'.'
 je .separator
 cmp r9b,'a'
 jb .digit
 cmp r9b,'z'
 jbe .hash
.digit:
 cmp r9b,'0'
 jb .underscore
 cmp r9b,'9'
 jbe .hash
.underscore:
 cmp r9b,'_'
 jne .source
 jmp .hash
.separator:
 mov r8d,1
.hash:
 xor rax,r9
 mov r10,0x100000001b3
 imul rax,r10
 inc rcx
 jmp .loop
.done_scan:
 test r8d,r8d
 jnz .source
 test rax,rax
 jnz .publish
 mov eax,1
.publish:
 mov [rdx],rax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
