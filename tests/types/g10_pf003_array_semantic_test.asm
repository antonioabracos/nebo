bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_semantic.inc"
%include "compiler/lowering/collections/array_ir.inc"
extern neboc_array_semantic_analyze
extern neboc_array_ir_lower
extern neboc_host_process_exit
%macro SEM 10
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10
%endmacro
%macro IR 7
 dq %1,%2,%3,%4,%5,%6,%7
%endmacro
section .data align=8
sem_cases:
 SEM 1,1,4,0,7,0,64,0,0,10
 SEM 2,1,4,0,7,0,64,0,0,1
 SEM 2,1,4,3,7,0,64,0,0,1
 SEM 3,1,4,0,3,0,64,0,0,1
 SEM 1,1,3,0,7,0,64,4,1,0
 SEM 1,2,4,0,7,0,64,4,2,0
 SEM 2,1,4,-1,7,0,64,4,3,0
 SEM 2,1,4,4,7,0,64,4,3,0
 SEM 2,1,4,1,3,0,64,4,4,0
 SEM 1,1,4,0,6,0,64,4,5,0
 SEM 1,1,4,0,5,0,64,4,8,0
 SEM 1,1,4,0,7,100,99,4,8,0
sem_count equ ($-sem_cases)/(10*8)
ir_cases:
 IR 1,0,1,3,0,0,0
 IR 2,0,1,3,0,0,0
 IR 2,3,1,3,0,0,24
 IR 3,0,1,3,0,0,0
 IR 2,4,1,3,4,9,0
 IR 2,1,2,3,6,10,0
ir_count equ ($-ir_cases)/(7*8)
section .bss align=16
sem_request: resb NEBOC_ARRAY_SEM_REQUEST_SIZE
ir_request: resb NEBOC_ARRAY_IR_REQUEST_SIZE
section .text
global _start
_start:
 lea r14,[rel sem_cases]
 mov r15d,sem_count
 mov r13d,1
.sem_loop:
 lea rdi,[rel sem_request]
 mov ecx,NEBOC_ARRAY_SEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel sem_request+NEBOC_ARRAY_SEM_KIND_OFFSET],rax
 mov rax,[r14+8]
 mov [rel sem_request+NEBOC_ARRAY_SEM_ELEMENT_TYPE_OFFSET],rax
 mov rax,[r14+16]
 mov [rel sem_request+NEBOC_ARRAY_SEM_ELEMENT_COUNT_OFFSET],rax
 mov rax,[r14+24]
 mov [rel sem_request+NEBOC_ARRAY_SEM_INDEX_OFFSET],rax
 mov rax,[r14+32]
 mov [rel sem_request+NEBOC_ARRAY_SEM_FLAGS_OFFSET],rax
 mov rax,[r14+40]
 mov [rel sem_request+NEBOC_ARRAY_SEM_SOURCE_START_OFFSET],rax
 mov rax,[r14+48]
 mov [rel sem_request+NEBOC_ARRAY_SEM_SOURCE_END_OFFSET],rax
 lea rdi,[rel sem_request]
 call neboc_array_semantic_analyze
 cmp rax,[r14+56]
 jne .fail
 mov rax,[rel sem_request+NEBOC_ARRAY_SEM_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+64]
 jne .fail
 mov rax,[rel sem_request+NEBOC_ARRAY_SEM_OUTPUT_TYPE_OFFSET]
 cmp rax,[r14+72]
 jne .fail
 add r14,10*8
 inc r13d
 dec r15d
 jnz .sem_loop
 lea r14,[rel ir_cases]
 mov r15d,ir_count
.ir_loop:
 lea rdi,[rel ir_request]
 mov ecx,NEBOC_ARRAY_IR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel ir_request+NEBOC_ARRAY_IR_OPERATION_OFFSET],rax
 mov qword [rel ir_request+NEBOC_ARRAY_IR_SEMANTIC_HASH_OFFSET],0x10a44a79
 mov rax,[r14+8]
 mov [rel ir_request+NEBOC_ARRAY_IR_INDEX_OFFSET],rax
 mov rax,[r14+16]
 mov [rel ir_request+NEBOC_ARRAY_IR_TARGET_OFFSET],rax
 mov rax,[r14+24]
 mov [rel ir_request+NEBOC_ARRAY_IR_FLAGS_OFFSET],rax
 lea rdi,[rel ir_request]
 call neboc_array_ir_lower
 cmp rax,[r14+32]
 jne .fail
 mov rax,[rel ir_request+NEBOC_ARRAY_IR_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+40]
 jne .fail
 mov rax,[rel ir_request+NEBOC_ARRAY_IR_BYTE_OFFSET_OFFSET]
 cmp rax,[r14+48]
 jne .fail
 cmp qword [rel ir_request+NEBOC_ARRAY_IR_ALLOCATION_COUNT_OFFSET],0
 jne .fail
 add r14,7*8
 inc r13d
 dec r15d
 jnz .ir_loop
 xor edi,edi
 call neboc_array_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 call neboc_array_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
