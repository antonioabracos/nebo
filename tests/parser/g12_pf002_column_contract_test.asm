; COLUMN-ROW-TABLE-E-DATASET-PF002 21 table-driven native contract cases
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/column_contract.inc"
extern neboc_column_contract_validate
extern neboc_host_process_exit
section .rodata align=8
; op argc flags index hint expected_status expected_diag
cases:
 dq 0,4,7,0,0,0,0
 dq 1,1,7,0,0,0,0
 dq 1,1,7,3,0,0,0
 dq 2,0,7,0,0,0,0
 dq 3,0,7,0,0,0,0
 dq 4,0,7,0,0,0,0
 dq 5,0,7,0,0,0,0
 dq 6,0,7,0,0,0,0
 dq 0,3,7,0,0,4,1
 dq 1,0,7,0,0,4,1
 dq 1,1,7,4,0,4,3
 dq 3,0,0,0,0,4,5
 dq 9,0,7,0,0,4,9
 dq 0,4,7,0,1,4,1
 dq 0,4,7,0,2,4,2
 dq 0,4,7,0,3,4,3
 dq 0,4,7,0,4,4,4
 dq 0,4,7,0,6,4,6
 dq 0,4,7,0,7,4,7
 dq 0,4,7,0,8,4,8
 dq 0,4,7,0,10,4,10
case_count equ ($-cases)/(7*8)
section .bss
request: resb NEBOC_COLUMN_REQUEST_SIZE
section .text
global _start
_start:
 lea r12,[rel cases]
 mov r13d,case_count
.loop:
 lea rdi,[rel request]
 mov rcx,NEBOC_COLUMN_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r12]
 mov [rel request+0],rax
 mov rax,[r12+8]
 mov [rel request+8],rax
 mov rax,[r12+16]
 mov [rel request+16],rax
 mov rax,[r12+24]
 mov [rel request+24],rax
 mov rax,[r12+32]
 mov [rel request+32],rax
 lea rdi,[rel request]
 call neboc_column_contract_validate
 cmp rax,[r12+40]
 jne .fail
 mov rax,[rel request+40]
 cmp rax,[r12+48]
 jne .fail
 add r12,56
 dec r13d
 jnz .loop
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
