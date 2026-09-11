bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/programmer_type_contract.inc"
extern neboc_programmer_type_contract
extern neboc_host_process_exit

%macro CASE 5
 dq %1,%2,%3,%4,%5
%endmacro
section .rodata
subject: db 'struct Box { Int.value; }'
subject_len equ $-subject
section .data align=8
cases:
 CASE 1,255,1,0,0
 CASE 2,255,2,0,0
 CASE 3,255,2,0,0
 CASE 4,255,1,0,0
 CASE 5,255,2,0,0
 CASE 6,255,2,0,0
 CASE 7,255,1,0,0
 CASE 8,255,2,0,0
 CASE 0,255,1,4,1
 CASE 1,254,1,4,2
 CASE 1,253,1,4,4
 CASE 2,253,2,4,8
 CASE 3,251,2,4,5
 CASE 3,247,2,4,7
 CASE 6,247,2,4,9
 CASE 1,239,0,4,11
 CASE 1,223,1,4,10
 CASE 3,191,2,4,6
 CASE 1,127,1,4,12
 CASE 1,255,0,4,11
 CASE 1,255,9,4,12
 CASE 8,247,2,4,9
case_count equ ($-cases)/(5*8)
section .bss align=16
request: resb NEBOC_CONTRACT_REQUEST_SIZE
first_hash: resq 1
section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel request]
 mov ecx,NEBOC_CONTRACT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel request+NEBOC_CONTRACT_OPERATION_OFFSET],rax
 mov rax,[r14+8]
 mov [rel request+NEBOC_CONTRACT_FLAGS_OFFSET],rax
 mov rax,[r14+16]
 mov [rel request+NEBOC_CONTRACT_MEMBER_COUNT_OFFSET],rax
 lea rax,[rel subject]
 mov [rel request+NEBOC_CONTRACT_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+NEBOC_CONTRACT_SUBJECT_LENGTH_OFFSET],subject_len
 mov qword [rel request+NEBOC_CONTRACT_ABSOLUTE_START_OFFSET],900
 lea rdi,[rel request]
 call neboc_programmer_type_contract
 cmp rax,[r14+24]
 jne .fail
 mov rax,[rel request+NEBOC_CONTRACT_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+32]
 jne .fail
 add r14,5*8
 inc r13d
 dec r15d
 jnz .loop
 ; hash determinism
 lea rdi,[rel request]
 mov ecx,NEBOC_CONTRACT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel request+NEBOC_CONTRACT_OPERATION_OFFSET],1
 mov qword [rel request+NEBOC_CONTRACT_FLAGS_OFFSET],255
 mov qword [rel request+NEBOC_CONTRACT_MEMBER_COUNT_OFFSET],1
 lea rax,[rel subject]
 mov [rel request+NEBOC_CONTRACT_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+NEBOC_CONTRACT_SUBJECT_LENGTH_OFFSET],subject_len
 lea rdi,[rel request]
 call neboc_programmer_type_contract
 mov rax,[rel request+NEBOC_CONTRACT_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_programmer_type_contract
 mov rax,[rel first_hash]
 cmp rax,[rel request+NEBOC_CONTRACT_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_programmer_type_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
