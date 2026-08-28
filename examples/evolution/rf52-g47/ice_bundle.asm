; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F08 native composition: create a strict redacted in-memory bundle.
bits 64
default rel
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/ice.inc"
global _start
extern neboc_ice_report_new
extern neboc_ice_report_node_identity
extern neboc_ice_report_phase_trace
extern neboc_ice_report_compiler_manifest
extern neboc_ice_report_redact
extern neboc_ice_report_reproducer
extern neboc_host_process_exit
section .rodata
invariant: db 'example.invariant'
invariant_len equ $-invariant
context: db 'example context'
context_len equ $-context
version: db 'neboc-example-v1'
version_len equ $-version
target: db 'x86_64-systemv-elf-linux'
target_len equ $-target
section .data
request: dq 13,invariant,invariant_len,context,context_len
manifest: dq version,version_len,target,target_len,1,1
reproducer: dq 0,0,0,NEBOC_ICE_MAX_SOURCE_BYTES
trace: dq 1,13
section .bss align=16
report: resb NEBOC_ICE_REPORT_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 2048
section .text
_start:
 sub rsp,8
 lea rdi,[rel report]
 lea rsi,[rel request]
 call neboc_ice_report_new
 test eax,eax
 jne .fail
 lea rdi,[rel report]
 mov esi,1
 mov edx,1
 call neboc_ice_report_node_identity
 test eax,eax
 jne .fail
 lea rdi,[rel report]
 lea rsi,[rel trace]
 mov edx,2
 call neboc_ice_report_phase_trace
 test eax,eax
 jne .fail
 lea rdi,[rel report]
 lea rsi,[rel manifest]
 call neboc_ice_report_compiler_manifest
 test eax,eax
 jne .fail
 lea rdi,[rel report]
 mov esi,NEBOC_ICE_REDACT_STRICT
 call neboc_ice_report_redact
 test eax,eax
 jne .fail
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],2048
 lea rdi,[rel report]
 lea rsi,[rel reproducer]
 lea rdx,[rel writer]
 call neboc_ice_report_reproducer
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
