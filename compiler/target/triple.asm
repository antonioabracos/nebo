; TRIPLE-F01 bounded build/host/target triple contract.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/triple.inc"
section .text
triple_linux_x86:
 mov qword [rdi+NEBOC_TRIPLE_ARCH_OFFSET],NEBOC_ARCH_X86_64
 mov qword [rdi+NEBOC_TRIPLE_VENDOR_OFFSET],0
 mov qword [rdi+NEBOC_TRIPLE_OS_OFFSET],NEBOC_OS_LINUX
 mov qword [rdi+NEBOC_TRIPLE_ENV_OFFSET],NEBOC_ENV_SYSTEMV
 mov qword [rdi+NEBOC_TRIPLE_WORD_OFFSET],64
 mov qword [rdi+NEBOC_TRIPLE_CANONICAL_OFFSET],1
 xor eax,eax
 ret
NEBOC_ABI_FUNCTION neboc_build_triple_current
 test rdi,rdi
 jz .invalid
 jmp triple_linux_x86
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_host_triple_current
 test rdi,rdi
 jz .invalid
 jmp triple_linux_x86
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_target_triple_parse
 ; Bounded parser tokens: 1 x86_64-linux-systemv, 2 aarch64-linux-systemv, 3 wasm32-wasi.
 test rdi,rdi
 jz .invalid
 cmp rsi,1
 je triple_linux_x86
 cmp rsi,2
 je .aarch64
 cmp rsi,3
 je .wasm
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.aarch64:
 mov qword [rdi],NEBOC_ARCH_AARCH64
 mov qword [rdi+8],0
 mov qword [rdi+16],NEBOC_OS_LINUX
 mov qword [rdi+24],NEBOC_ENV_SYSTEMV
 mov qword [rdi+32],64
 mov qword [rdi+40],2
 xor eax,eax
 ret
.wasm:
 mov qword [rdi],NEBOC_ARCH_WASM32
 mov qword [rdi+8],0
 mov qword [rdi+16],NEBOC_OS_WASI
 mov qword [rdi+24],NEBOC_ENV_WASM
 mov qword [rdi+32],32
 mov qword [rdi+40],3
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_triple_normalize
 ; rdi=triple rsi=canonical token output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_TRIPLE_CANONICAL_OFFSET]
 test rax,rax
 jz .source
 mov [rsi],rax
 xor eax,eax
 ret
.source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro TRIPLE_GETTER 2
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 mov rax,[rdi+%2]
 mov [rsi],rax
%if %2 = NEBOC_TRIPLE_ARCH_OFFSET
 mov rax,[rdi+NEBOC_TRIPLE_WORD_OFFSET]
 mov [rsi+8],rax
%endif
 xor eax,eax
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
TRIPLE_GETTER neboc_triple_architecture,NEBOC_TRIPLE_ARCH_OFFSET
TRIPLE_GETTER neboc_triple_operating_system,NEBOC_TRIPLE_OS_OFFSET
TRIPLE_GETTER neboc_triple_environment,NEBOC_TRIPLE_ENV_OFFSET
NEBOC_ABI_FUNCTION neboc_triple_compatibility
 ; rdi=left rsi=right rdx=result.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rdi]
 cmp rax,[rsi]
 jne .source
 mov rax,[rdi+16]
 cmp rax,[rsi+16]
 jne .object
 mov rax,[rdi+24]
 cmp rax,[rsi+24]
 jne .abi
 mov rax,[rdi+40]
 cmp rax,[rsi+40]
 jne .abi
 mov qword [rdx],NEBOC_COMPAT_EXACT
 xor eax,eax
 ret
.abi: mov qword [rdx],NEBOC_COMPAT_ABI
 xor eax,eax
 ret
.object: mov qword [rdx],NEBOC_COMPAT_OBJECT
 xor eax,eax
 ret
.source: mov qword [rdx],NEBOC_COMPAT_SOURCE
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_compilation_context_new
 ; rdi=context rsi=build rdx=host rcx=target r8=compiler r9=options; pack via stack unavailable -> set later manifest field zero.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov [rdi],rsi
 mov [rdi+8],rdx
 mov [rdi+16],rcx
 mov [rdi+24],r8
 mov [rdi+32],r9
 mov qword [rdi+40],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_compilation_context_manifest
 ; rdi=context rsi=6-qword output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rdx,rsi
 mov rsi,rdi
 mov ecx,NEBOC_CONTEXT_SIZE/8
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
NEBOC_ABI_FUNCTION neboc_cli_host
 ; rdi=build output rsi=host output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rbx
 mov rbx,rsi
 call neboc_build_triple_current
 test eax,eax
 jne .return
 mov rdi,rbx
 call neboc_host_triple_current
.return: pop rbx
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_triple_normalize
 ; rdi=triple output rsi=input token rdx=canonical token output.
 test rdi,rdi
 jz .invalid
 push rbx
 mov rbx,rdx
 call neboc_target_triple_parse
 test eax,eax
 jne .return
 mov rsi,rbx
 call neboc_triple_normalize
.return: pop rbx
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
