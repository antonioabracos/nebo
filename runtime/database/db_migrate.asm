; MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-F06 bounded compatible schema migration and streaming transfer core.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/database/db_migrate.inc"
section .text
NEBOC_ABI_FUNCTION nebo_db_migrate_v1_v2
 ; src,dst,old_count,dst_capacity,default_value
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBO_DB_MAX_COLUMNS-1
 ja .limit
 mov rax,rdx
 inc rax
 cmp rcx,rax
 jb .destination
 xor r9d,r9d
.copy:
 cmp r9,rdx
 jae .append
 mov r10,[rdi+r9*8]
 mov [rsi+r9*8],r10
 inc r9
 jmp .copy
.append:
 mov [rsi+rdx*8],r8
 mov rax,rdx
 inc rax
 ret
.invalid: mov rax,-1
 ret
.limit: mov rax,-2
 ret
.destination: mov rax,-4
 ret

NEBOC_ABI_FUNCTION nebo_db_transfer_chunk
 ; src,dst,offset,total,max_chunk,out_count
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test r9,r9
 jz .invalid
 cmp rdx,rcx
 ja .invalid
 test r8,r8
 jz .limit
 cmp r8,65536
 ja .limit
 mov rax,rcx
 sub rax,rdx
 cmp rax,r8
 jbe .size
 mov rax,r8
.size:
 mov [r9],rax
 xor r10d,r10d
.copy:
 cmp r10,rax
 jae .ok
 mov r11b,[rdi+rdx]
 mov [rsi+r10],r11b
 inc rdx
 inc r10
 jmp .copy
.ok:
 xor eax,eax
 ret
.invalid: mov eax,NEBO_DB_MIGRATE_INVALID
 ret
.limit: mov eax,NEBO_DB_MIGRATE_LIMIT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
