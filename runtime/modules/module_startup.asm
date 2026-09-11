bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/module_init.inc"

extern neboc_init_execute_once

section .text
; Runtime startup has one authority: the authenticated ModuleInitPlan. It
; never discovers constructors from object/linker order.
NEBOC_ABI_FUNCTION neboc_module_startup
 test rdi,rdi
 jz .arg
 test rsi,rsi
 jz .arg
 jmp neboc_init_execute_once
.arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
