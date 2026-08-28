; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F05 native composition: one bounded diagnostic bag insertion.
bits 64
default rel
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/recovery.inc"
global _start
extern neboc_diagnostic_bag_new
extern neboc_diagnostic_bag_add
extern neboc_host_process_exit
section .rodata
code: db "NEBO-E0001"
code_len equ $-code
section .bss align=16
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
bag: resb NEBOC_DIAG_BAG_SIZE
entries: resb NEBOC_RECOVERY_DIAG_ENTRY_SIZE*2
id: resq 1
section .text
_start:
 sub rsp,8
 lea rax,[rel code]
 mov [rel diagnostic+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],rax
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],code_len
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_SYNTAX
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_PARSE
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET],1
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+8],4
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+16],5
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+24],8
 lea rdi,[rel bag]
 lea rsi,[rel entries]
 mov edx,2
 mov ecx,2
 mov r8d,256
 call neboc_diagnostic_bag_new
 test eax,eax
 jne .fail
 lea rdi,[rel bag]
 lea rsi,[rel diagnostic]
 mov edx,64
 lea rcx,[rel id]
 call neboc_diagnostic_bag_add
 test eax,eax
 jne .fail
 cmp qword [rel id],1
 jne .fail
 xor edi,edi
 call neboc_host_process_exit
.fail:
 mov edi,1
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
