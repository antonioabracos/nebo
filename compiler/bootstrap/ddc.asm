; DDC-F08 honest DDC plan: unavailable build paths, bounded verifier active.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/bootstrap/ddc.inc"
section .text
NEBOC_ABI_FUNCTION neboc_ddc_plan_new
 test rdi,rdi
 jz .invalid
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 mov qword [rdi+24],NEBOC_DDC_SOURCE_COMPILER_NOT_AVAILABLE
 mov qword [rdi+32],NEBOC_DDC_SHARED_KERNEL_ASSEMBLER_LINKER
 mov qword [rdi+40],0
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_ddc_build_path_a
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_ddc_build_path_b
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_ddc_normalize_artifacts
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_ddc_compare
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_ddc_anomaly_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+24]
 mov [rsi],rax
 mov rax,[rdi+40]
 mov [rsi+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_ddc_assumptions
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+32]
 mov [rsi],rax
 mov qword [rsi+8],NEBOC_DDC_SOURCE_COMPILER_NOT_AVAILABLE
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_ddc_replay
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_independent_verifier_verify_compiler_artifact
 ; rdi=image rsi=size rdx=report. Header verifier is independent of compiler under test.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,64
 jb .source
 cmp dword [rdi],0x464c457f
 jne .source
 cmp byte [rdi+4],2
 jne .source
 cmp word [rdi+18],62
 jne .source
 mov qword [rdx],1
 movzx eax,word [rdi+16]
 mov [rdx+8],rax
 xor eax,eax
 ret
.source: mov qword [rdx],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_diverse_build_plan
 jmp neboc_ddc_build_path_a
NEBOC_ABI_FUNCTION neboc_cli_diverse_build_report
 jmp neboc_ddc_anomaly_report
section .note.GNU-stack noalloc noexec nowrite progbits
