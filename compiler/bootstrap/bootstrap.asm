; BOOTSTRAP-F07 factual bootstrap inventory: Assembly stage0 only.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/bootstrap/bootstrap.inc"
section .text
NEBOC_ABI_FUNCTION neboc_bootstrap_stage0
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 test rcx,rcx
 jz .source
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 mov qword [rdi+24],NEBOC_BOOT_AVAILABLE
 mov qword [rdi+32],NEBOC_BOOT_SOURCE_COMPILER_NOT_AVAILABLE
 mov qword [rdi+40],0
 mov qword [rdi+48],0
 mov qword [rdi+56],0
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_source_compiler
 test rdi,rdi
 jz .invalid
 mov qword [rdi+32],NEBOC_BOOT_SOURCE_COMPILER_NOT_AVAILABLE
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_stage1
 test rdi,rdi
 jz .invalid
 mov qword [rdi+40],0
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_stage2
 test rdi,rdi
 jz .invalid
 mov qword [rdi+48],0
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_compare_stages
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov qword [rsi],NEBOC_BOOT_SOURCE_COMPILER_NOT_AVAILABLE
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_divergence_report
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov qword [rsi],NEBOC_BOOT_SOURCE_COMPILER_NOT_AVAILABLE
 mov qword [rsi+8],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_preserve_stage0
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+24],NEBOC_BOOT_AVAILABLE
 jne .source
 mov rax,[rdi]
 test rax,rax
 jz .source
 mov rax,[rdi+8]
 test rax,rax
 jz .source
 mov qword [rsi],1
 xor eax,eax
 ret
.source: mov qword [rsi],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_promote_component
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_rollback_promotion
 test rdi,rdi
 jz .invalid
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_bootstrap_stage_manifest
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_BOOT_STAGE0
 jne .unavailable
 mov rax,[rdi]
 mov [rdx],rax
 mov rax,[rdi+8]
 mov [rdx+8],rax
 mov rax,[rdi+16]
 mov [rdx+16],rax
 mov qword [rdx+24],NEBOC_BOOT_AVAILABLE
 xor eax,eax
 ret
.unavailable:
 cmp rsi,NEBOC_BOOT_STAGE2
 ja .source
 mov qword [rdx+24],NEBOC_BOOT_SOURCE_COMPILER_NOT_AVAILABLE
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_bootstrap_stage
 ; rdi=state rsi=stage rdx=report.
 cmp rsi,NEBOC_BOOT_STAGE0
 jne .unavailable
 jmp neboc_bootstrap_preserve_stage0
.unavailable:
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBOC_BOOT_STAGE2
 ja .source
 test rdx,rdx
 jz .invalid
 mov qword [rdx],NEBOC_BOOT_SOURCE_COMPILER_NOT_AVAILABLE
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_bootstrap_verify
 jmp neboc_bootstrap_preserve_stage0
section .note.GNU-stack noalloc noexec nowrite progbits
