bits 64
default rel
%include "compiler/semantic/cpu/cpu_contract.inc"
%include "compiler/semantic/numeric/numeric_contract.inc"
section .bss
align 8
features resb NEBO_CPU_SIZE
section .text
global _start
_start:
 lea rdi,[features]
 call nebo_cpu_detect
 test eax,eax
 jnz .fail1
 lea rdi,[features]
 call nebo_cpu_validate
 test eax,eax
 jnz .fail2
 cmp qword [features+NEBO_CPU_MAX_LEAF],1
 jb .fail3
 cmp qword [features+NEBO_CPU_CACHE_LINE],0
 je .fail4
 test qword [features+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_SSE2
 jz .fail5
 mov edi,NEBO_CPU_FEATURE_AVX2
 call nebo_cpu_sanitize_features
 test rax,NEBO_CPU_FEATURE_AVX2
 jnz .fail6
 mov edi,NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE
 call nebo_cpu_sanitize_features
 test rax,NEBO_CPU_FEATURE_AVX
 jnz .fail7
 mov edi,NEBO_CPU_FEATURE_AVX|NEBO_CPU_FEATURE_AVX2|NEBO_CPU_FEATURE_OSXSAVE|NEBO_CPU_FEATURE_XCR0_YMM
 call nebo_cpu_sanitize_features
 test rax,NEBO_CPU_FEATURE_AVX2
 jz .fail8
 mov qword [features+NEBO_CPU_FEATURES],NEBO_CPU_FEATURE_AVX2
 lea rdi,[features]
 call nebo_cpu_validate
 cmp eax,NEBO_NUMERIC_ERROR_CONTRACT
 jne .fail9
 xor edi,edi
 call nebo_cpu_detect
 cmp eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jne .fail10
 cmp dword [features+NEBO_CPU_VENDOR_EBX],0
 je .fail11
 cmp qword [features+NEBO_CPU_CACHE_LINE],1024
 ja .fail12
 xor edi,edi
 jmp .exit
%assign i 1
%rep 12
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
