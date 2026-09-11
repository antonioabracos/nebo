bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/vector_contract.inc"
extern neboc_vector_api_contract
extern neboc_host_process_exit
%macro CASE 8
 dq %1,%2,%3,%4,%5,%6,%7,%8
%endmacro
section .rodata
subject: db 'Vector<Int> [1, 2, 3, 4]'
subject_len equ $-subject
section .data align=8
cases:
 CASE 1,4,1,0,0,31,0,0
 CASE 2,4,1,0,0,31,0,0
 CASE 2,4,1,3,0,31,0,0
 CASE 3,4,1,0,0,31,0,0
 CASE 4,4,1,0,0,31,0,0
 CASE 5,4,1,0,4,31,0,0
 CASE 1,0,1,0,0,31,4,1
 CASE 1,3,1,0,0,31,4,1
 CASE 1,4,2,0,0,31,4,2
 CASE 2,4,1,-1,0,31,4,3
 CASE 2,4,1,4,0,31,4,3
 CASE 2,4,1,1,0,30,4,4
 CASE 10,4,1,0,0,31,4,10
 CASE 6,4,1,0,0,31,4,6
 CASE 7,4,1,0,0,31,4,7
 CASE 8,4,1,0,0,31,4,8
 CASE 9,4,1,0,0,31,4,9
 CASE 0,4,1,0,0,31,4,5
 CASE 1,4,1,0,0,27,4,5
 CASE 1,4,1,0,0,29,4,5
 CASE 1,4,1,0,0,23,4,5
 CASE 1,4,1,0,0,15,4,5
 CASE 5,4,1,0,3,31,4,1
 CASE 5,4,1,0,4,31,0,0
case_count equ ($-cases)/(8*8)
section .bss align=16
request: resb NEBOC_VECTOR_CONTRACT_REQUEST_SIZE
first_hash: resq 1
section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel request]
 mov ecx,NEBOC_VECTOR_CONTRACT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel request+NEBOC_VECTOR_CONTRACT_OPERATION_OFFSET],rax
 mov rax,[r14+8]
 mov [rel request+NEBOC_VECTOR_CONTRACT_ELEMENT_COUNT_OFFSET],rax
 mov rax,[r14+16]
 mov [rel request+NEBOC_VECTOR_CONTRACT_ELEMENT_TYPE_OFFSET],rax
 mov rax,[r14+24]
 mov [rel request+NEBOC_VECTOR_CONTRACT_INDEX_OFFSET],rax
 mov rax,[r14+32]
 mov [rel request+NEBOC_VECTOR_CONTRACT_OTHER_COUNT_OFFSET],rax
 mov rax,[r14+40]
 mov [rel request+NEBOC_VECTOR_CONTRACT_FLAGS_OFFSET],rax
 lea rax,[rel subject]
 mov [rel request+NEBOC_VECTOR_CONTRACT_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_SUBJECT_LENGTH_OFFSET],subject_len
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_ABSOLUTE_START_OFFSET],1100
 lea rdi,[rel request]
 call neboc_vector_api_contract
 cmp rax,[r14+48]
 jne .fail
 mov rax,[rel request+NEBOC_VECTOR_CONTRACT_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+56]
 jne .fail
 add r14,8*8
 inc r13d
 dec r15d
 jnz .loop
 lea rdi,[rel request]
 mov ecx,NEBOC_VECTOR_CONTRACT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_OPERATION_OFFSET],5
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_ELEMENT_COUNT_OFFSET],4
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_ELEMENT_TYPE_OFFSET],1
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_OTHER_COUNT_OFFSET],4
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_FLAGS_OFFSET],31
 lea rax,[rel subject]
 mov [rel request+NEBOC_VECTOR_CONTRACT_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+NEBOC_VECTOR_CONTRACT_SUBJECT_LENGTH_OFFSET],subject_len
 lea rdi,[rel request]
 call neboc_vector_api_contract
 mov rax,[rel request+NEBOC_VECTOR_CONTRACT_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_vector_api_contract
 mov rax,[rel first_hash]
 cmp rax,[rel request+NEBOC_VECTOR_CONTRACT_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_vector_api_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
