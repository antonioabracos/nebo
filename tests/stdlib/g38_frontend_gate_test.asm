bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/final_program_gate.inc"
extern neboc_final_program_gate_validate
extern neboc_host_process_exit
section .bss align=16
p: resb FPG_SIZE
section .text
reset:
 lea rdi,[rel p]
 mov ecx,FPG_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel p+FPG_GROUP],38
 mov qword [rel p+FPG_PHASE_MASK],1
 mov qword [rel p+FPG_NEGATIVE_COUNT],12
 mov qword [rel p+FPG_RESOURCE_USED],64
 mov qword [rel p+FPG_RESOURCE_LIMIT],128
 mov qword [rel p+FPG_IDENTITY_HASH],0x38aa
 mov qword [rel p+FPG_LINEAGE_HASH],0x38bb
 mov qword [rel p+FPG_EXTERNAL_MUTATIONS],0
 mov qword [rel p+FPG_PRIVACY_FLAGS],1
 mov qword [rel p+FPG_DETERMINISM_RUNS],100
 call seal
 ret
seal:
 mov rax,FPG_SEAL_MAGIC
 lea rdi,[rel p]
 xor edx,edx
 mov ecx,10
.l: xor rax,[rdi+rdx*8]
 inc edx
 loop .l
 mov [rel p+FPG_SEAL],rax
 ret
bad:
 lea rdi,[rel p]
 call neboc_final_program_gate_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 ret
global _start
_start:
 mov r15d,1
 xor edi,edi
 call neboc_final_program_gate_validate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 call reset
 lea rdi,[rel p]
 call neboc_final_program_gate_validate
 test eax,eax
 jnz fail
 cmp qword [rel p+FPG_RESULT],38
 jne fail
 mov r15d,10
 call reset
 mov qword [rel p+FPG_PHASE_MASK],2
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+FPG_NEGATIVE_COUNT],0
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+FPG_RESOURCE_USED],129
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+FPG_EXTERNAL_MUTATIONS],1
 call seal
 call bad
 inc r15d
 call reset
 mov qword [rel p+FPG_DETERMINISM_RUNS],1
 call seal
 call bad
 inc r15d
 call reset
 inc qword [rel p+FPG_SEAL]
 call bad
 xor edi,edi
 jmp neboc_host_process_exit
fail: mov edi,r15d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
