bits 64
default rel

%include "compiler/codegen/functions/x86_64/function_codegen.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/semantic/collections/array_range.inc"

%if NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS != 256
    %error "A3 public owner bound drift"
%endif
%if NEBOC_FUNCTION_CODEGEN_MAX_INTERNAL_FUNCTIONS != 513
    %error "A3 private symbol bound drift"
%endif
%if NEBOC_ABI_MAX_LOCAL_SLOTS != 256
    %error "A3 start frame slot bound drift"
%endif
%if NEBOC_ABI_MAX_RUNTIME_CALLS != 256
    %error "A3 start call bound drift"
%endif
%if NEBOC_AR_MAX_BINDINGS != 256
    %error "A3 collection owner bound drift"
%endif

section .text
global _start
_start:
    mov eax,60
    xor edi,edi
    syscall
