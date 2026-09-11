bits 64
default rel
%include "compiler/bootstrap/ddc.inc"
global _start
extern neboc_ddc_plan_new,neboc_ddc_build_path_a,neboc_ddc_build_path_b,neboc_ddc_normalize_artifacts
extern neboc_ddc_compare,neboc_ddc_anomaly_report,neboc_ddc_assumptions,neboc_ddc_replay
extern neboc_independent_verifier_verify_compiler_artifact,neboc_cli_diverse_build_plan
extern neboc_cli_diverse_build_report,neboc_host_process_exit
section .bss align=16
plan: resb NEBOC_DDC_SIZE
artifact: resb 64
out: resq 4
section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 mov esi,1
 mov edx,2
 mov ecx,3
 call neboc_ddc_plan_new
 cmp eax,6
 jne .f1
 lea rdi,[rel plan]
 call neboc_ddc_build_path_a
 cmp eax,6
 jne .f2
 lea rdi,[rel plan]
 call neboc_ddc_build_path_b
 cmp eax,6
 jne .f3
 lea rdi,[rel plan]
 call neboc_ddc_normalize_artifacts
 cmp eax,6
 jne .f4
 lea rdi,[rel plan]
 call neboc_ddc_compare
 cmp eax,6
 jne .f5
 lea rdi,[rel plan]
 lea rsi,[rel out]
 call neboc_ddc_anomaly_report
 cmp qword [rel out],5
 jne .f6
 lea rdi,[rel plan]
 lea rsi,[rel out]
 call neboc_ddc_assumptions
 cmp qword [rel out],7
 jne .f7
 lea rdi,[rel plan]
 call neboc_ddc_replay
 cmp eax,6
 jne .f8
 mov dword [rel artifact],0x464c457f
 mov byte [rel artifact+4],2
 mov word [rel artifact+16],2
 mov word [rel artifact+18],62
 lea rdi,[rel artifact]
 mov esi,64
 lea rdx,[rel out]
 call neboc_independent_verifier_verify_compiler_artifact
 test eax,eax
 jne .f9
 cmp qword [rel out],1
 jne .f10
 lea rdi,[rel plan]
 call neboc_cli_diverse_build_plan
 cmp eax,6
 jne .f11
 lea rdi,[rel plan]
 lea rsi,[rel out]
 call neboc_cli_diverse_build_report
 cmp qword [rel out],5
 jne .f12
 mov byte [rel artifact],0
 lea rdi,[rel artifact]
 mov esi,64
 lea rdx,[rel out]
 call neboc_independent_verifier_verify_compiler_artifact
 cmp eax,4
 jne .f13
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 13
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
