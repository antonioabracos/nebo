bits 64
default rel
%include "compiler/assembler/x86_64_encoder.inc"
global _start
extern neboc_instruction_encoder_for_target,neboc_encoder_coverage_report,neboc_host_process_exit
section .bss align=16
encoder: resb NEBOC_ENCODER_SIZE
report: resq 4
section .text
_start:
 sub rsp,8
 lea rdi,[rel encoder]
 mov esi,1
 xor edx,edx
 call neboc_instruction_encoder_for_target
 lea rdi,[rel encoder]
 lea rsi,[rel report]
 call neboc_encoder_coverage_report
 cmp qword [rel report],4
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail: mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
