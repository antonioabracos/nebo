; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F02 native A0 layout, nested drop and caller-storage ABI vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/struct_tuple.inc"
%include "compiler/lowering/aggregates/product_layout.inc"

extern neboc_product_layout
extern neboc_product_pass_return
extern neboc_host_process_exit

section .data align=16
sizes: dq 8,1,8,8,8,8,8,8
aligns: dq 8,1,8,8,8,8,8,8
drops: dq 0,0,0,0,0,0,0,0
source: dq 11,22,33

section .bss align=16
request: resb neboc_option_result_null_externo_e_erros_tipados_LAYOUT_REQUEST_SIZE
offsets: resq 8
target: resq 3

section .text
global _start

reset:
 lea rdi,[rel request]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel sizes]
 mov [rel request+NEBOC_LAYOUT_SIZES_OFFSET],rax
 lea rax,[rel aligns]
 mov [rel request+NEBOC_LAYOUT_ALIGNS_OFFSET],rax
 lea rax,[rel drops]
 mov [rel request+NEBOC_LAYOUT_DROP_COUNTS_OFFSET],rax
 lea rax,[rel offsets]
 mov [rel request+NEBOC_LAYOUT_OFFSETS_OFFSET],rax
 ret

layout:
 lea rdi,[rel request]
 jmp neboc_product_layout

_start:
 ; Empty Tuple has a stable non-zero representation.
 call reset
 call layout
 test eax,eax
 jnz .fail1
 cmp qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_SIZE_OFFSET],1
 jne .fail1
 cmp qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_ALIGN_OFFSET],1
 jne .fail1

 ; Int/Bool/Int offsets are 0/8/16 with tail size 24.
 call reset
 mov qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_MEMBER_COUNT_OFFSET],3
 call layout
 test eax,eax
 jnz .fail2
 cmp qword [rel offsets],0
 jne .fail2
 cmp qword [rel offsets+8],8
 jne .fail2
 cmp qword [rel offsets+16],16
 jne .fail2
 cmp qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_SIZE_OFFSET],24
 jne .fail2

 ; Nested ownership leaf counts and reverse-order cleanup proof are stable.
 mov qword [rel sizes],16
 mov qword [rel sizes+8],8
 mov qword [rel aligns],8
 mov qword [rel aligns+8],8
 mov qword [rel drops],2
 mov qword [rel drops+8],1
 call reset
 mov qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_MEMBER_COUNT_OFFSET],2
 call layout
 test eax,eax
 jnz .fail3
 cmp qword [rel request+NEBOC_LAYOUT_DROP_COUNT_OFFSET],3
 jne .fail3
 mov r13,[rel request+NEBOC_LAYOUT_CLEANUP_HASH_OFFSET]
 test r13,r13
 jz .fail3
 call layout
 test eax,eax
 jnz .fail3
 cmp r13,[rel request+NEBOC_LAYOUT_CLEANUP_HASH_OFFSET]
 jne .fail3

 ; Explicit caller storage passes and returns the 24-byte aggregate exactly.
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov edx,24
 call neboc_product_pass_return
 test eax,eax
 jnz .fail4
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov ecx,24
 repe cmpsb
 jne .fail4

 ; Invalid alignment, count and total size fail without layout success.
 mov qword [rel aligns],3
 call reset
 mov qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_MEMBER_COUNT_OFFSET],1
 call layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail5
 cmp qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_DIAG_INVALID_ALIGNMENT
 jne .fail5
 mov qword [rel aligns],8
 call reset
 mov qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_MEMBER_COUNT_OFFSET],9
 call layout
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail5
 mov qword [rel sizes],NEBOC_LAYOUT_MAX_SIZE
 mov qword [rel sizes+8],1
 call reset
 mov qword [rel request+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_MEMBER_COUNT_OFFSET],2
 call layout
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail5

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

section .note.GNU-stack noalloc noexec nowrite progbits
