; Nebo Assembly — LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF004 native Int literal runtime prototype
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "runtime/scalars/int/numeric_literal_runtime.inc"

section .rodata align=8
int_runtime_layout:
 dq NEBOC_INT_RUNTIME_CONTRACT_VERSION
 dq NEBOC_INT_RUNTIME_TARGET_X86_64_SYSTEMV_ELF_LINUX
 dq NEBOC_INT_RUNTIME_FORMAT_SIGNED_TWOS_COMPLEMENT_I64
 dq 64
 dq 8
 dq 8
 dq NEBOC_INT_RUNTIME_REGISTER_CLASS_GPR
 dq NEBOC_INT_RUNTIME_PARAMETER_REGISTER_RDI
 dq NEBOC_INT_RUNTIME_RETURN_REGISTER_RAX
 dq 8
 dq 8
 dq 0
 dq NEBOC_INT_RUNTIME_REQUIRED_FLAGS
 dq NEBOC_INT_RUNTIME_ABI_VERSION
 dq NEBOC_INT_RUNTIME_STATE_PROTOTYPE
 dq 0

section .text
NEBOC_ABI_FUNCTION neboc_int_runtime_layout_get
 test rdi,rdi
 jz .invalid
 lea rax,[rel int_runtime_layout]
 mov [rdi],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Existing System V scalar Int path: RDI argument, RAX return.
align 16
global neboc_int_runtime_identity
neboc_int_runtime_identity:
 mov rax,rdi
 cld
 ret

; Prototype stack-slot path: RDI value, RSI points to an 8-byte aligned slot.
align 16
global neboc_int_runtime_stack_roundtrip
neboc_int_runtime_stack_roundtrip:
 mov [rsi],rdi
 mov rax,[rsi]
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
