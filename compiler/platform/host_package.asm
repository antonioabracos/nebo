; HOST-PACKAGE-F08 bounded current-host compiler plan and offline package manifest.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/platform/host_package.inc"
section .text
NEBOC_ABI_FUNCTION neboc_host_compiler_plan_for_triple
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 jne .unsupported
 mov [rdi],rsi
 mov qword [rdi+8],1
 mov qword [rdi+16],1
 mov qword [rdi+24],0x1f
 mov qword [rdi+32],0x1f
 xor eax,eax
 ret
.unsupported: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro PLAN_FACT 3
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 mov rax,[rdi+%2]
 mov [rsi],rax
%if %2 = NEBOC_HOST_PLAN_STARTUP_OFFSET
 mov qword [rsi+8],0
 mov qword [rsi+16],3
%endif
 xor eax,eax
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
PLAN_FACT neboc_host_compiler_plan_bootstrap_source,NEBOC_HOST_PLAN_STARTUP_OFFSET,0
PLAN_FACT neboc_host_compiler_plan_platform_backend,NEBOC_HOST_PLAN_PLATFORM_OFFSET,0
PLAN_FACT neboc_host_compiler_plan_package_layout,NEBOC_HOST_PLAN_LAYOUT_OFFSET,0
PLAN_FACT neboc_host_compiler_plan_self_test_suite,NEBOC_HOST_PLAN_SUITE_OFFSET,0
NEBOC_ABI_FUNCTION neboc_host_compiler_package_verify
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_HOST_PACKAGE_VERSION_OFFSET],1
 jne .source
 cmp qword [rdi+NEBOC_HOST_PACKAGE_HOST_OFFSET],1
 jne .unsupported
 cmp qword [rdi+NEBOC_HOST_PACKAGE_HASH_OFFSET],0
 je .source
 cmp qword [rdi+NEBOC_HOST_PACKAGE_FORMAT_OFFSET],1
 jne .source
 cmp qword [rdi+NEBOC_HOST_PACKAGE_LIBS_OFFSET],0
 jne .source
 cmp qword [rdi+NEBOC_HOST_PACKAGE_FILES_OFFSET],256
 ja .limit
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.unsupported: mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_host_compiler_package_restore_test
 ; Manifest-level offline restore smoke; G52 performs full SDK filesystem restore.
 test rsi,rsi
 jz .invalid
 push rsi
 call neboc_host_compiler_package_verify
 pop rsi
 test eax,eax
 jne .return
 mov qword [rsi],1
 mov qword [rsi+8],0
 mov qword [rsi+16],1
.return: ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_host_compiler_compatibility_report
 ; rdi=left package rsi=right package rdx=out{same_host,same_format,same_dependencies}.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rdi+8]
 cmp rax,[rsi+8]
 sete al
 movzx rax,al
 mov [rdx],rax
 mov rax,[rdi+24]
 cmp rax,[rsi+24]
 sete al
 movzx rax,al
 mov [rdx+8],rax
 mov rax,[rdi+32]
 cmp rax,[rsi+32]
 sete al
 movzx rax,al
 mov [rdx+16],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_host_compiler_external_dependencies
 ; out={shared_libraries,external_tools}; current build truthfully uses NASM and ld.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_HOST_PACKAGE_LIBS_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_HOST_PACKAGE_TOOLS_OFFSET]
 mov [rsi+8],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_self_test_host
 call neboc_host_compiler_package_restore_test
 ret
NEBOC_ABI_FUNCTION neboc_cli_host_package_verify
 call neboc_host_compiler_package_verify
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
