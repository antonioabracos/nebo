; CROSS-COMPILATION-F07 local verified target packs and explicit runner maturity.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/cross_compilation.inc"
section .text
NEBOC_ABI_FUNCTION neboc_cross_compilation_new
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp [rcx+NEBOC_PACK_TARGET_OFFSET],rdx
 jne .unsupported
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 xor eax,eax
 ret
.unsupported: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_target_pack_runtime_objects
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PACK_RUNTIME_COUNT_OFFSET]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_target_pack_system_contracts
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PACK_CONTRACTS_OFFSET]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_target_pack_verify
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_PACK_VERSION_OFFSET],1
 jne .source
 cmp qword [rdi+NEBOC_PACK_HASH_OFFSET],0
 je .source
 cmp qword [rdi+NEBOC_PACK_RUNTIME_COUNT_OFFSET],64
 ja .limit
 test qword [rdi+NEBOC_PACK_FLAGS_OFFSET],1
 jz .source
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cross_runner_new
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_RUNNER_NO_RUN
 ja .source
 test rcx,rcx
 jz .source
 cmp rcx,60000
 ja .limit
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 mov [rdi+24],r8
 mov qword [rdi+32],NEBOC_MATURITY_UNAVAILABLE
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_runner_execute
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .source
 test rdx,rdx
 jz .invalid
 cmp qword [rdi],NEBOC_RUNNER_LOCAL_NATIVE
 jne .unavailable
 mov qword [rdx],0
 mov qword [rdx+8],1
 mov qword [rdi+32],NEBOC_MATURITY_HARDWARE
 xor eax,eax
 ret
.unavailable:
 mov qword [rdi+32],NEBOC_MATURITY_UNAVAILABLE
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_runner_environment_manifest
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov ecx,5
.copy:
 mov rax,[rdi]
 mov [rsi],rax
 add rdi,8
 add rsi,8
 loop .copy
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_runner_copy_artifact
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jne .unsupported
 test rdx,rdx
 jz .invalid
 cmp rdx,0x10000000
 ja .limit
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.unsupported: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_runner_classify_result
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_RUNNER_RESULT_OFFSET]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_build_target
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rsi
 mov rdi,[rdi+16]
 call neboc_target_pack_verify
 pop rsi
 test eax,eax
 jne .return
 mov qword [rsi],NEBOC_MATURITY_COMPILE_ONLY
.return: ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_run_target
 call neboc_runner_execute
 ret
NEBOC_ABI_FUNCTION neboc_cli_target_pack_verify
 call neboc_target_pack_verify
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
