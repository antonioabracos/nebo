; OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-F01 local CPUID/OSXSAVE-safe feature contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%define NEBO_CPU_CONTRACT_IMPLEMENTATION 1
%include "compiler/semantic/cpu/cpu_contract.inc"
%include "compiler/semantic/numeric/numeric_contract.inc"
section .text
global nebo_cpu_detect
global nebo_cpu_sanitize_features
global nebo_cpu_validate
; desc rdi
nebo_cpu_detect:
 push rbx
 push r12
 push r13
 mov r12,rdi
 test rdi,rdi
 jz .arg
 xor eax,eax
 cpuid
 mov r13d,eax
 mov [r12+NEBO_CPU_MAX_LEAF],rax
 mov [r12+NEBO_CPU_VENDOR_EBX],ebx
 mov [r12+NEBO_CPU_VENDOR_EDX],edx
 mov [r12+NEBO_CPU_VENDOR_ECX],ecx
 mov qword [r12+NEBO_CPU_FEATURES],0
 mov qword [r12+NEBO_CPU_CACHE_LINE],0
 cmp r13d,1
 jb .finish
 mov eax,1
 cpuid
 mov eax,ebx
 shr eax,8
 and eax,0xff
 shl eax,3
 mov [r12+NEBO_CPU_CACHE_LINE],rax
 bt edx,26
 jnc .check_os
 or qword [r12+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_SSE2
.check_os:
 bt ecx,27
 jnc .leaf7
 or qword [r12+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_OSXSAVE
 bt ecx,28
 jnc .leaf7
 or qword [r12+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_AVX
 xor ecx,ecx
 xgetbv
 and eax,6
 cmp eax,6
 jne .leaf7
 or qword [r12+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_XCR0_YMM
.leaf7:
 cmp r13d,7
 jb .sanitize
 mov eax,7
 xor ecx,ecx
 cpuid
 bt ebx,5
 jnc .sanitize
 or qword [r12+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_AVX2
.sanitize:
 mov rdi,[r12+NEBO_CPU_FEATURES]
 call nebo_cpu_sanitize_features
 mov [r12+NEBO_CPU_FEATURES],rax
.finish:
 mov rax,NEBO_CPU_MAGIC
 mov [r12+NEBO_CPU_MAGIC_OFF],rax
 xor eax,eax
.ret: pop r13
 pop r12
 pop rbx
 ret
.arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .ret
; raw flags rdi -> safe flags rax
nebo_cpu_sanitize_features:
 mov rax,rdi
 test rax,NEBO_CPU_FEATURE_AVX
 jz .clear_avx2
 test rax,NEBO_CPU_FEATURE_OSXSAVE
 jz .clear_avx
 test rax,NEBO_CPU_FEATURE_XCR0_YMM
 jz .clear_avx
 ret
.clear_avx:
 and rax,~(NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_XCR0_YMM)
 ret
.clear_avx2:
 and rax,~NEBO_CPU_FEATURE_AVX2
 ret
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nebo_cpu_validate:
 test rdi,rdi
 jz .v_arg
 mov rax,NEBO_CPU_MAGIC
 cmp [rdi+NEBO_CPU_MAGIC_OFF],rax
 jne .v_contract
 mov rax,[rdi+NEBO_CPU_FEATURES]
 mov rdi,rax
 call nebo_cpu_sanitize_features
 cmp rax,rdi
 jne .v_contract
 xor eax,eax
 ret
.v_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 ret
.v_contract: mov eax,NEBO_NUMERIC_ERROR_CONTRACT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
