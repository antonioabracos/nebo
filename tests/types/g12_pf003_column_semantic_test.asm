; COLUMN-ROW-TABLE-E-DATASET-PF003 semantic and IR native cases
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/column_contract.inc"
%include "compiler/semantic/collections/column_semantic.inc"
%include "compiler/lowering/collections/column_ir.inc"
extern neboc_column_semantic_evaluate
extern neboc_column_ir_lower
extern neboc_host_process_exit
section .rodata align=8
; op index a b c d status output diag
cases:
 dq 2,0,1,2,3,4,0,4,0
 dq 1,0,1,2,3,4,0,1,0
 dq 1,3,1,2,3,4,0,4,0
 dq 3,0,1,2,3,4,0,10,0
 dq 3,0,-2,0,7,9,0,14,0
 dq 4,0,-2,0,7,9,0,-2,0
 dq 5,0,-2,0,7,9,0,9,0
 dq 6,0,1,2,3,4,0,0,0
 dq 1,4,1,2,3,4,4,0,3
 dq 3,0,0x7fffffffffffffff,1,0,0,4,0,10
case_count equ ($-cases)/(9*8)
section .bss align=16
request: resb NEBOC_COLUMN_SEM_REQUEST_SIZE
cells: resq 4
ir: resb NEBOC_COLUMN_IR_REQUEST_SIZE
section .text
global _start
_start:
 lea r12,[rel cases]
 mov r13d,case_count
.loop:
 lea rdi,[rel request]
 mov rcx,NEBOC_COLUMN_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel cells]
 mov [rel request],rax
 mov rax,[r12]
 mov [rel request+8],rax
 mov rax,[r12+8]
 mov [rel request+16],rax
 mov rax,[r12+16]
 mov [rel cells],rax
 mov rax,[r12+24]
 mov [rel cells+8],rax
 mov rax,[r12+32]
 mov [rel cells+16],rax
 mov rax,[r12+40]
 mov [rel cells+24],rax
 lea rdi,[rel request]
 call neboc_column_semantic_evaluate
 cmp rax,[r12+48]
 jne .fail
 mov rax,[rel request+24]
 cmp rax,[r12+56]
 jne .fail
 mov rax,[rel request+32]
 cmp rax,[r12+64]
 jne .fail
 add r12,72
 dec r13d
 jnz .loop
 xor r12d,r12d
.irloop:
 lea rdi,[rel ir]
 mov ecx,NEBOC_COLUMN_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov [rel ir],r12
 lea rdi,[rel ir]
 call neboc_column_ir_lower
 test eax,eax
 jnz .fail
 mov rax,[rel ir+8]
 lea rdx,[r12+NEBOC_COLUMN_IR_BASE]
 cmp rax,rdx
 jne .fail
 cmp qword [rel ir+16],0
 jne .fail
 inc r12
 cmp r12,7
 jb .irloop
 xor edi,edi
 jmp neboc_host_process_exit
.fail: mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
