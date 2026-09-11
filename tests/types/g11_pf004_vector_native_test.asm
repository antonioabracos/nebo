bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/vector_layout.inc"
extern neboc_vector_layout
extern neboc_vector_int4_copy
extern neboc_vector_int4_read
extern neboc_vector_int4_len
extern neboc_vector_int4_sum
extern neboc_vector_int4_dot
extern neboc_host_process_exit
section .data align=16
source: dq -2,0,7,9
other: dq 1,2,3,4
overflow_sum: dq 0x7fffffffffffffff,1,0,0
overflow_dot_left: dq 0x7fffffffffffffff,0,0,0
overflow_dot_right: dq 2,0,0,0
section .bss align=16
target: resq 4
value: resq 1
layout: resb NEBOC_VECTOR_LAYOUT_REQUEST_SIZE
section .text
global _start
_start:
 lea rdi,[rel layout]
 mov ecx,NEBOC_VECTOR_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel layout+NEBOC_VECTOR_LAYOUT_ELEMENT_SIZE_OFFSET],8
 mov qword [rel layout+NEBOC_VECTOR_LAYOUT_ELEMENT_COUNT_OFFSET],4
 lea rdi,[rel layout]
 call neboc_vector_layout
 test eax,eax
 jnz .fail1
 cmp qword [rel layout+NEBOC_VECTOR_LAYOUT_SIZE_OFFSET],32
 jne .fail2
 cmp qword [rel layout+NEBOC_VECTOR_LAYOUT_ALIGNMENT_OFFSET],8
 jne .fail3
 cmp qword [rel layout+NEBOC_VECTOR_LAYOUT_STRIDE_OFFSET],8
 jne .fail4
 cmp qword [rel layout+NEBOC_VECTOR_LAYOUT_METADATA_SIZE_OFFSET],0
 jne .fail5
 cmp qword [rel layout+NEBOC_VECTOR_LAYOUT_ALLOCATION_COUNT_OFFSET],0
 jne .fail6
 lea rdi,[rel target]
 lea rsi,[rel source]
 call neboc_vector_int4_copy
 test eax,eax
 jnz .fail7
 xor r12d,r12d
 lea rbx,[rel source]
.reads:
 lea rdi,[rel target]
 mov rsi,r12
 lea rdx,[rel value]
 call neboc_vector_int4_read
 test eax,eax
 jnz .fail8
 mov rax,[rbx+r12*8]
 cmp rax,[rel value]
 jne .fail9
 inc r12
 cmp r12,4
 jb .reads
 lea rdi,[rel target]
 lea rsi,[rel value]
 call neboc_vector_int4_sum
 test eax,eax
 jnz .fail10
 cmp qword [rel value],14
 jne .fail11
 lea rdi,[rel target]
 lea rsi,[rel other]
 lea rdx,[rel value]
 call neboc_vector_int4_dot
 test eax,eax
 jnz .fail12
 cmp qword [rel value],55
 jne .fail13
 lea rdi,[rel overflow_sum]
 lea rsi,[rel value]
 call neboc_vector_int4_sum
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail14
 lea rdi,[rel overflow_dot_left]
 lea rsi,[rel overflow_dot_right]
 lea rdx,[rel value]
 call neboc_vector_int4_dot
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail15
 lea rdi,[rel target]
 mov esi,4
 lea rdx,[rel value]
 call neboc_vector_int4_read
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail16
 xor edi,edi
 call neboc_vector_layout
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail17
 call neboc_vector_int4_len
 cmp eax,4
 jne .fail18
 xor edi,edi
 jmp neboc_host_process_exit
%assign n 1
%rep 18
.fail %+ n: mov edi,n
 jmp neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
