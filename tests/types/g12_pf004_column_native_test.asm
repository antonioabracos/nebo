; COLUMN-ROW-TABLE-E-DATASET-PF004 layout and runtime scenarios
bits 64
default rel
%include "compiler/lowering/collections/column_layout.inc"
%include "runtime/collections/column_int4_runtime.inc"
extern neboc_column_layout_property
extern neboc_column_copy
extern neboc_column_read
extern neboc_column_len
extern neboc_column_row_table_e_dataset_column_count_missing
extern neboc_host_process_exit
section .rodata align=8
expected: dq 32,8,8,0,8,16,24,0,0
source: dq -2,0,7,9
section .bss align=16
dest: resq 4
out: resq 1
section .text
global _start
_start:
 lea rbx,[rel expected]
 xor r12d,r12d
.layout:
 mov rdi,r12
 call neboc_column_layout_property
 cmp rax,[rbx+r12*8]
 jne .fail
 inc r12
 cmp r12,9
 jb .layout
 mov edi,9
 call neboc_column_layout_property
 cmp rax,-1
 jne .fail
 lea rdi,[rel dest]
 lea rsi,[rel source]
 call neboc_column_copy
 test eax,eax
 jnz .fail
 lea rbx,[rel source]
 xor r12d,r12d
.read:
 lea rdi,[rel dest]
 mov rsi,r12
 lea rdx,[rel out]
 call neboc_column_read
 test eax,eax
 jnz .fail
 mov rax,[rel out]
 cmp rax,[rbx+r12*8]
 jne .fail
 inc r12
 cmp r12,4
 jb .read
 lea rdi,[rel dest]
 mov esi,4
 lea rdx,[rel out]
 call neboc_column_read
 cmp eax,NEBOC_COLUMN_RUNTIME_BOUNDS
 jne .fail
 call neboc_column_len
 cmp eax,4
 jne .fail
 call neboc_column_row_table_e_dataset_column_count_missing
 test eax,eax
 jnz .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail: mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
