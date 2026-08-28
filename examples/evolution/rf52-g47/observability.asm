; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F09 native composition: deterministic progress summary.
bits 64
default rel
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/observability.inc"
global _start
extern neboc_progress_phase_started
extern neboc_progress_unit_finished
extern neboc_progress_deterministic_summary
extern neboc_host_process_exit
section .bss align=16
progress: resb NEBOC_PROGRESS_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 256
section .text
_start:
 sub rsp,8
 lea rdi,[rel progress]
 mov esi,13
 mov edx,1
 call neboc_progress_phase_started
 test eax,eax
 jne .fail
 lea rdi,[rel progress]
 mov esi,1
 mov edx,NEBOC_PROGRESS_OUTCOME_SUCCESS
 call neboc_progress_unit_finished
 test eax,eax
 jne .fail
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],256
 lea rdi,[rel progress]
 lea rsi,[rel writer]
 call neboc_progress_deterministic_summary
 test eax,eax
 jne .fail
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 je .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
