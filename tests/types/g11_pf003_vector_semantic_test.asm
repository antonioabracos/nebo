bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/vector_semantic.inc"
%include "compiler/lowering/collections/vector_ir.inc"
extern neboc_vector_semantic_analyze
extern neboc_vector_ir_lower
extern neboc_host_process_exit
%macro SEM 13
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12,%13
%endmacro
%macro IR 10
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10
%endmacro
section .data align=8
sem_cases:
 SEM 1,1,4,0,0,31,0,64,0,0,0,11,0
 SEM 2,1,4,0,0,31,0,64,0,0,0,1,1
 SEM 2,1,4,3,0,31,0,64,0,0,0,1,4
 SEM 3,1,4,0,0,31,0,64,0,0,0,1,4
 SEM 4,1,4,0,0,31,0,64,0,0,0,1,10
 SEM 5,1,4,0,4,31,0,64,0,0,0,1,20
 SEM 1,1,3,0,0,31,0,64,0,4,1,0,0
 SEM 1,2,4,0,0,31,0,64,0,4,2,0,0
 SEM 2,1,4,-1,0,31,0,64,0,4,3,0,0
 SEM 2,1,4,4,0,31,0,64,0,4,3,0,0
 SEM 2,1,4,1,0,15,0,64,0,4,4,0,0
 SEM 1,1,4,0,0,13,0,64,0,4,5,0,0
 SEM 1,1,4,0,0,31,100,99,0,4,5,0,0
 SEM 5,1,4,0,3,31,0,64,0,4,1,0,0
 SEM 4,1,4,0,0,31,0,64,1,4,10,0,0
 SEM 5,1,4,0,4,31,0,64,2,4,10,0,0
sem_count equ ($-sem_cases)/(13*8)
ir_cases:
 IR 1,0,1,3,0,0,0,0,0,1
 IR 2,0,1,3,1,0,0,0,0,2
 IR 2,3,1,3,4,0,0,24,0,2
 IR 3,0,1,3,4,0,0,0,4,3
 IR 4,0,1,3,10,0,0,0,10,4
 IR 5,0,1,3,20,0,0,0,20,5
 IR 2,4,1,3,0,4,11,0,0,0
 IR 2,1,2,3,0,6,12,0,0,0
ir_count equ ($-ir_cases)/(10*8)
section .bss align=16
sem_request: resb NEBOC_VECTOR_SEM_REQUEST_SIZE
ir_request: resb NEBOC_VECTOR_IR_REQUEST_SIZE
section .text
global _start
_start:
 lea r14,[rel sem_cases]
 mov r15d,sem_count
 mov r13d,1
.sem_loop:
 lea rdi,[rel sem_request]
 mov ecx,NEBOC_VECTOR_SEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel sem_request+NEBOC_VECTOR_SEM_KIND_OFFSET],rax
 mov rax,[r14+8]
 mov [rel sem_request+NEBOC_VECTOR_SEM_ELEMENT_TYPE_OFFSET],rax
 mov rax,[r14+16]
 mov [rel sem_request+NEBOC_VECTOR_SEM_ELEMENT_COUNT_OFFSET],rax
 mov rax,[r14+24]
 mov [rel sem_request+NEBOC_VECTOR_SEM_INDEX_OFFSET],rax
 mov rax,[r14+32]
 mov [rel sem_request+NEBOC_VECTOR_SEM_OTHER_COUNT_OFFSET],rax
 mov rax,[r14+40]
 mov [rel sem_request+NEBOC_VECTOR_SEM_FLAGS_OFFSET],rax
 mov rax,[r14+48]
 mov [rel sem_request+NEBOC_VECTOR_SEM_SOURCE_START_OFFSET],rax
 mov rax,[r14+56]
 mov [rel sem_request+NEBOC_VECTOR_SEM_SOURCE_END_OFFSET],rax
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET],1
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET+8],2
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET+16],3
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET+24],4
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_OTHER_ELEMENTS_OFFSET],4
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_OTHER_ELEMENTS_OFFSET+8],3
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_OTHER_ELEMENTS_OFFSET+16],2
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_OTHER_ELEMENTS_OFFSET+24],1
 cmp qword [r14+64],1
 jne .variant_dot
 mov rax,0x7fffffffffffffff
 mov [rel sem_request+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET],rax
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET+8],1
 jmp .variant_done
.variant_dot:
 cmp qword [r14+64],2
 jne .variant_done
 mov rax,0x7fffffffffffffff
 mov [rel sem_request+NEBOC_VECTOR_SEM_ELEMENTS_OFFSET],rax
 mov qword [rel sem_request+NEBOC_VECTOR_SEM_OTHER_ELEMENTS_OFFSET],2
.variant_done:
 lea rdi,[rel sem_request]
 call neboc_vector_semantic_analyze
 cmp rax,[r14+72]
 jne .fail
 mov rax,[rel sem_request+NEBOC_VECTOR_SEM_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+80]
 jne .fail
 mov rax,[rel sem_request+NEBOC_VECTOR_SEM_OUTPUT_TYPE_OFFSET]
 cmp rax,[r14+88]
 jne .fail
 mov rax,[rel sem_request+NEBOC_VECTOR_SEM_RESULT_OFFSET]
 cmp rax,[r14+96]
 jne .fail
 add r14,13*8
 inc r13d
 dec r15d
 jnz .sem_loop
 lea r14,[rel ir_cases]
 mov r15d,ir_count
.ir_loop:
 lea rdi,[rel ir_request]
 mov ecx,NEBOC_VECTOR_IR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel ir_request+NEBOC_VECTOR_IR_OPERATION_OFFSET],rax
 mov qword [rel ir_request+NEBOC_VECTOR_IR_SEMANTIC_HASH_OFFSET],0x11a44b79
 mov rax,[r14+8]
 mov [rel ir_request+NEBOC_VECTOR_IR_INDEX_OFFSET],rax
 mov rax,[r14+16]
 mov [rel ir_request+NEBOC_VECTOR_IR_TARGET_OFFSET],rax
 mov rax,[r14+24]
 mov [rel ir_request+NEBOC_VECTOR_IR_FLAGS_OFFSET],rax
 mov rax,[r14+32]
 mov [rel ir_request+NEBOC_VECTOR_IR_SEMANTIC_RESULT_OFFSET],rax
 lea rdi,[rel ir_request]
 call neboc_vector_ir_lower
 cmp rax,[r14+40]
 jne .fail
 mov rax,[rel ir_request+NEBOC_VECTOR_IR_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+48]
 jne .fail
 mov rax,[rel ir_request+NEBOC_VECTOR_IR_BYTE_OFFSET_OFFSET]
 cmp rax,[r14+56]
 jne .fail
 mov rax,[rel ir_request+NEBOC_VECTOR_IR_CONSTANT_VALUE_OFFSET]
 cmp rax,[r14+64]
 jne .fail
 mov rax,[rel ir_request+NEBOC_VECTOR_IR_OUTPUT_KIND_OFFSET]
 cmp rax,[r14+72]
 jne .fail
 cmp qword [rel ir_request+NEBOC_VECTOR_IR_ALLOCATION_COUNT_OFFSET],0
 jne .fail
 add r14,10*8
 inc r13d
 dec r15d
 jnz .ir_loop
 xor edi,edi
 call neboc_vector_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 call neboc_vector_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
