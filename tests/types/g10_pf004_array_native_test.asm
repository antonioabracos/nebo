bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/collections/array_layout.inc"
extern neboc_colecoes_primitivas_array_layout
extern neboc_array_int4_copy
extern neboc_array_int4_read
extern neboc_array_int4_len
extern neboc_host_process_exit
section .data align=16
source: dq -2,0,7,9
section .bss align=16
target: resq 4
value: resq 1
layout: resb NEBOC_ARRAY_LAYOUT_REQUEST_SIZE
section .text
global _start
_start:
 lea rdi,[rel layout]
 mov ecx,NEBOC_ARRAY_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel layout+neboc_colecoes_primitivas_ARRAY_LAYOUT_ELEMENT_SIZE_OFFSET],8
 mov qword [rel layout+NEBOC_ARRAY_LAYOUT_ELEMENT_COUNT_OFFSET],4
 lea rdi,[rel layout]
 call neboc_colecoes_primitivas_array_layout
 test eax,eax
 jnz .fail1
 cmp qword [rel layout+NEBOC_ARRAY_LAYOUT_SIZE_OFFSET],32
 jne .fail2
 cmp qword [rel layout+NEBOC_ARRAY_LAYOUT_ALIGNMENT_OFFSET],8
 jne .fail3
 cmp qword [rel layout+neboc_colecoes_primitivas_ARRAY_LAYOUT_STRIDE_OFFSET],8
 jne .fail4
 cmp qword [rel layout+NEBOC_ARRAY_LAYOUT_ALLOCATION_COUNT_OFFSET],0
 jne .fail5
 lea rdi,[rel target]
 lea rsi,[rel source]
 call neboc_array_int4_copy
 test eax,eax
 jnz .fail6
 xor r12d,r12d
 lea rbx,[rel source]
.reads:
 lea rdi,[rel target]
 mov rsi,r12
 lea rdx,[rel value]
 call neboc_array_int4_read
 test eax,eax
 jnz .fail7
 mov rax,[rbx+r12*8]
 cmp rax,[rel value]
 jne .fail8
 inc r12
 cmp r12,4
 jb .reads
 lea rdi,[rel target]
 mov esi,4
 lea rdx,[rel value]
 call neboc_array_int4_read
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail9
 xor edi,edi
 call neboc_colecoes_primitivas_array_layout
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail10
 xor edi,edi
 lea rsi,[rel source]
 call neboc_array_int4_copy
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail11
 call neboc_array_int4_len
 cmp eax,4
 jne .fail12
 xor edi,edi
 jmp neboc_host_process_exit
.fail1: mov edi,1
 jmp neboc_host_process_exit
.fail2: mov edi,2
 jmp neboc_host_process_exit
.fail3: mov edi,3
 jmp neboc_host_process_exit
.fail4: mov edi,4
 jmp neboc_host_process_exit
.fail5: mov edi,5
 jmp neboc_host_process_exit
.fail6: mov edi,6
 jmp neboc_host_process_exit
.fail7: mov edi,7
 jmp neboc_host_process_exit
.fail8: mov edi,8
 jmp neboc_host_process_exit
.fail9: mov edi,9
 jmp neboc_host_process_exit
.fail10: mov edi,10
 jmp neboc_host_process_exit
.fail11: mov edi,11
 jmp neboc_host_process_exit
.fail12: mov edi,12
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
