; C07-F07 all-path Tuple merge and internal sret conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/functions/tuple_function_abi.inc"

extern neboc_tuple_function_merge
extern neboc_tuple_function_sret
extern neboc_host_process_exit

section .data align=16
paths:
path0: dq 2,16,8,1,1,4,0,0,0,0,0,0
path1: dq 2,16,8,1,1,4,0,0,0,0,0,0
source: dq 11,22

section .bss align=16
request: resb NEBOC_TFA_REQUEST_SIZE
target: resq 2

section .text
global _start

reset:
 lea rdi,[rel request]
 mov ecx,NEBOC_TFA_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel paths]
 mov [rel request+NEBOC_TFA_PATHS_OFFSET],rax
 mov qword [rel request+NEBOC_TFA_PATH_COUNT_OFFSET],2
 lea rax,[rel source]
 mov [rel request+NEBOC_TFA_SOURCE_OFFSET],rax
 lea rax,[rel target]
 mov [rel request+NEBOC_TFA_DESTINATION_OFFSET],rax
 ret

_start:
 call reset
 lea rdi,[rel request]
 call neboc_tuple_function_merge
 test eax,eax
 jnz .fail1
 cmp qword [rel request+NEBOC_TFA_MERGED_ARITY_OFFSET],2
 jne .fail1
 cmp qword [rel request+NEBOC_TFA_MERGED_SIZE_OFFSET],16
 jne .fail1
 cmp qword [rel request+NEBOC_TFA_MERGED_DROP_COUNT_OFFSET],1
 jne .fail1
 cmp qword [rel request+NEBOC_TFA_MERGED_TYPE_HASH_OFFSET],0
 je .fail1

 call reset
 lea rdi,[rel request]
 call neboc_tuple_function_sret
 test eax,eax
 jnz .fail2
 cmp qword [rel request+NEBOC_TFA_SRET_BYTES_OFFSET],16
 jne .fail2
 cmp qword [rel target],11
 jne .fail2
 cmp qword [rel target+8],22
 jne .fail2

 ; A single divergent type makes the all-path merge fail closed.
 mov qword [rel path1+NEBOC_TFA_PATH_TYPES_OFFSET+8],3
 call reset
 lea rdi,[rel request]
 call neboc_tuple_function_merge
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail3
 cmp qword [rel request+NEBOC_TFA_DIAGNOSTIC_OFFSET],NEBOC_TFA_DIAG_PATH_MISMATCH
 jne .fail3
 mov qword [rel path1+NEBOC_TFA_PATH_TYPES_OFFSET+8],4

 ; Source/destination overlap is never silently assigned move semantics.
 call reset
 lea rax,[rel source]
 mov [rel request+NEBOC_TFA_DESTINATION_OFFSET],rax
 lea rdi,[rel request]
 call neboc_tuple_function_sret
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail4
 cmp qword [rel request+NEBOC_TFA_DIAGNOSTIC_OFFSET],NEBOC_TFA_DIAG_STORAGE_OVERLAP
 jne .fail4

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

section .note.GNU-stack noalloc noexec nowrite progbits
