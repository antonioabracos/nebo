; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F06 stable module graph diagnostic classification.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"
section .rodata
align 4
module_codes: dd NEBOC_MODULE_DIAG_INVALID_PATH
 dd NEBOC_MODULE_DIAG_ROOT_ESCAPE
 dd NEBOC_MODULE_DIAG_DUPLICATE_ID
 dd neboc_module_diagnostics_MODULE_DIAG_MISSING_UNIT
 dd NEBOC_MODULE_DIAG_CYCLE
 dd NEBOC_MODULE_DIAG_STALE_REVISION
 dd neboc_module_diagnostics_MODULE_DIAG_CAPACITY
section .text
; diagnostic(reason, out_code*) -> status
NEBOC_ABI_FUNCTION neboc_module_diagnostic
 test rsi,rsi
 jz .arg
 test rsi,3
 jnz .arg
 cmp rdi,NEBOC_MODULE_REASON_INVALID_PATH
 jb .source
 cmp rdi,NEBOC_MODULE_REASON_CAPACITY
 ja .source
 lea rax,[rel module_codes]
 mov eax,[rax+rdi*4-4]
 mov [rsi],eax
 xor eax,eax
 ret
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
