; HERMETIC-BUILD-F06 logical/local hermetic context with explicit inputs only.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/toolchain/hermetic_build.inc"
section .text
NEBOC_ABI_FUNCTION neboc_hermetic_build_context_new
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
 mov ecx,8
 lea rdi,[rdi+24]
 xor eax,eax
 rep stosq
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_allow_environment
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,8
 ja .limit
 mov [rdi+24],rsi
 xor [rdi+80],rdx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_allow_files
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,64
 ja .limit
 test rdx,rdx
 jz .source
 mov [rdi+32],rsi
 xor [rdi+80],rdx
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_deny_network
 test rdi,rdi
 jz .invalid
 mov qword [rdi+40],1
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_fixed_epoch
 test rdi,rdi
 jz .invalid
 mov [rdi+48],rsi
 xor [rdi+80],rsi
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_path_remap
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .source
 mov rax,rsi
 rol rax,13
 xor rax,rdx
 mov [rdi+56],rax
 xor [rdi+80],rax
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_fixed_locale
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jne .source
 mov [rdi+64],rsi
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_fixed_random_seed
 test rdi,rdi
 jz .invalid
 mov [rdi+72],rsi
 xor [rdi+80],rsi
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_hermetic_record_inputs
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi]
 xor rax,[rdi+8]
 xor rax,[rdi+16]
 xor rax,[rdi+24]
 xor rax,[rdi+32]
 xor rax,[rdi+40]
 xor rax,[rdi+48]
 xor rax,[rdi+56]
 xor rax,[rdi+64]
 xor rax,[rdi+72]
 xor rax,[rdi+80]
 mov [rdi+80],rax
 mov [rsi],rax
 mov rax,[rdi+24]
 add rax,[rdi+32]
 add rax,8
 mov [rsi+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_reproducibility_compare
 ; rdi=digest A, rsi=digest B, rdx=policy, rcx=report{class,firstDifference}.
 test rcx,rcx
 jz .invalid
 cmp rdx,1
 jne .source
 cmp rdi,rsi
 jne .diverged
 mov qword [rcx],NEBOC_REPRO_BYTE_IDENTICAL
 mov qword [rcx+8],-1
 xor eax,eax
 ret
.diverged:
 mov qword [rcx],NEBOC_REPRO_DIVERGED
 mov qword [rcx+8],0
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_reproducibility_first_difference
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+8]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_build_hermetic
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+40],1
 jne .source
 cmp qword [rdi+64],1
 jne .source
 cmp qword [rdi+56],0
 je .source
 jmp neboc_hermetic_record_inputs
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_reproducibility_report
 jmp neboc_reproducibility_compare
section .note.GNU-stack noalloc noexec nowrite progbits
