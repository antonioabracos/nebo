bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"
section .text
; caller-owned state publishes all-or-zero after a complete bounded preflight.
NEBOC_ABI_FUNCTION neboc_module_startup
 test rdi,rdi
 jz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_INIT_MAX
 ja .limit
 cmp rdx,rsi
 jb .rollback
 xor ecx,ecx
.commit: cmp rcx,rsi
 jae .ok
 mov qword [rdi+rcx*8],NEBOC_INIT_COMMITTED
 inc rcx
 jmp .commit
.rollback: xor ecx,ecx
.zero: cmp rcx,rsi
 jae .source
 mov qword [rdi+rcx*8],NEBOC_INIT_PENDING
 inc rcx
 jmp .zero
.ok: xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
