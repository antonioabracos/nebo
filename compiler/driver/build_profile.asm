; BUILD-PROFILE-F07 bounded versioned build profiles.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/driver/build_profile.inc"
section .text
profile_clear:
 mov r8,rdi
 xor eax,eax
 mov ecx,NEBOC_PROFILE_SIZE/8
 rep stosq
 mov rdi,r8
 ret
profile_set_common:
 mov [rdi+NEBOC_PROFILE_NAME_OFFSET],rsi
 mov qword [rdi+NEBOC_PROFILE_VERSION_OFFSET],1
 mov qword [rdi+NEBOC_PROFILE_SECURITY_OFFSET],NEBOC_PROFILE_SECURITY_CHECKS
 mov qword [rdi+NEBOC_PROFILE_REPRO_OFFSET],1
 xor eax,eax
 ret
NEBOC_ABI_FUNCTION neboc_build_profile_debug
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdi
 call profile_clear
 mov rdi,rbx
 mov esi,NEBOC_PROFILE_DEBUG
 call profile_set_common
 mov qword [rbx+NEBOC_PROFILE_OPT_OFFSET],0
 mov qword [rbx+NEBOC_PROFILE_DEBUG_OFFSET],3
 mov qword [rbx+NEBOC_PROFILE_DIAGNOSTIC_OFFSET],3
 mov qword [rbx+NEBOC_PROFILE_RUNTIME_OFFSET],2
 pop rbx
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_build_profile_release
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdi
 call profile_clear
 mov rdi,rbx
 mov esi,NEBOC_PROFILE_RELEASE
 call profile_set_common
 mov qword [rbx+NEBOC_PROFILE_OPT_OFFSET],2
 mov qword [rbx+NEBOC_PROFILE_DEBUG_OFFSET],1
 mov qword [rbx+NEBOC_PROFILE_DIAGNOSTIC_OFFSET],2
 mov qword [rbx+NEBOC_PROFILE_RUNTIME_OFFSET],1
 pop rbx
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_build_profile_min_size
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdi
 call profile_clear
 mov rdi,rbx
 mov esi,NEBOC_PROFILE_MIN_SIZE
 call profile_set_common
 mov qword [rbx+NEBOC_PROFILE_OPT_OFFSET],3
 mov qword [rbx+NEBOC_PROFILE_DEBUG_OFFSET],0
 mov qword [rbx+NEBOC_PROFILE_DIAGNOSTIC_OFFSET],1
 mov qword [rbx+NEBOC_PROFILE_RUNTIME_OFFSET],1
 pop rbx
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_build_profile_custom
 ; rdi=profile rsi=10-qword literal options. Version and security proof required.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_PROFILE_VERSION_OFFSET],0
 je .source
 test qword [rsi+NEBOC_PROFILE_SECURITY_OFFSET],NEBOC_PROFILE_SECURITY_CHECKS
 jz .source
 mov rdx,rdi
 mov ecx,NEBOC_PROFILE_SIZE/8
.copy:
 mov rax,[rsi]
 mov [rdx],rax
 add rsi,8
 add rdx,8
 loop .copy
 mov qword [rdi+NEBOC_PROFILE_NAME_OFFSET],NEBOC_PROFILE_CUSTOM
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro PROFILE_GETTER 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 mov rax,[rdi+%2]
 mov [rsi],rax
 xor eax,eax
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
PROFILE_GETTER neboc_profile_optimization_level,NEBOC_PROFILE_OPT_OFFSET
PROFILE_GETTER neboc_profile_debug_info_policy,NEBOC_PROFILE_DEBUG_OFFSET
PROFILE_GETTER neboc_profile_diagnostic_table_policy,NEBOC_PROFILE_DIAGNOSTIC_OFFSET
PROFILE_GETTER neboc_profile_runtime_policy,NEBOC_PROFILE_RUNTIME_OFFSET
NEBOC_ABI_FUNCTION neboc_profile_reproducible
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 ja .invalid
 mov [rdi+NEBOC_PROFILE_REPRO_OFFSET],rsi
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_profile_manifest
 ; rdi=profile rsi=10-qword output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rdx,rsi
 mov rsi,rdi
 mov ecx,NEBOC_PROFILE_SIZE/8
.copy:
 mov rax,[rsi]
 mov [rdx],rax
 add rsi,8
 add rdx,8
 loop .copy
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_build_profile
 cmp rsi,NEBOC_PROFILE_DEBUG
 je neboc_build_profile_debug
 cmp rsi,NEBOC_PROFILE_RELEASE
 je neboc_build_profile_release
 cmp rsi,NEBOC_PROFILE_MIN_SIZE
 je neboc_build_profile_min_size
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_build_debug_control
 ; rdi=profile rsi=strip mask rdx=split-debug local token.
 test rdi,rdi
 jz .invalid
 mov [rdi+NEBOC_PROFILE_STRIP_OFFSET],rsi
 mov [rdi+NEBOC_PROFILE_SPLIT_TOKEN_OFFSET],rdx
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_profile_explain
 jmp neboc_profile_manifest
section .note.GNU-stack noalloc noexec nowrite progbits
