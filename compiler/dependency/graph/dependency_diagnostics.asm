; Nebo Assembly — MF029 dependency diagnostics
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/dependency/graph/dependency_graph.inc"
%include "compiler/dependency/graph/dependency_diagnostics.inc"

section .rodata
cycle_name: db 'pending-dependency-cycle'
orphan_name: db 'pending-orphan'

section .text

; dependency_graph_diagnostic_name(error_code, out_ptr*, out_length*)
NEBOC_ABI_FUNCTION neboc_dependency_graph_diagnostic_name
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rsi],0
 mov qword [rdx],0
 cmp edi,NEBOC_DEPENDENCY_ERROR_CYCLE
 je .cycle
 cmp edi,NEBOC_DEPENDENCY_ERROR_NONE
 je .orphan
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.cycle:
 lea rax,[rel cycle_name]
 mov [rsi],rax
 mov qword [rdx],NEBOC_DEPENDENCY_DIAGNOSTIC_CYCLE_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.orphan:
 lea rax,[rel orphan_name]
 mov [rsi],rax
 mov qword [rdx],NEBOC_DEPENDENCY_DIAGNOSTIC_ORPHAN_LENGTH
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
