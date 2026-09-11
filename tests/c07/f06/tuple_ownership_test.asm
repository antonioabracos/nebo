; C07-F06 bounded caller-storage and reverse-cleanup ownership proof.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/struct_tuple.inc"
%include "compiler/lowering/aggregates/product_layout.inc"

extern neboc_product_layout
extern neboc_product_pass_return
extern neboc_host_process_exit

section .data align=16
sizes: dq 16,24,8,0,0,0,0,0
aligns: dq 8,8,8,0,0,0,0,0
drops: dq 1,2,3,0,0,0,0,0
source: dq 0x1111111111111111,0x2222222222222222,0x3333333333333333

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

layout3:
 lea rdi,[rel request]
 mov qword [rdi+neboc_option_result_null_externo_e_erros_tipados_LAYOUT_MEMBER_COUNT_OFFSET],3
 jmp neboc_product_layout

_start:
 call reset
 call layout3
 test eax,eax
 jnz .fail1
 cmp qword [rel request+NEBOC_LAYOUT_DROP_COUNT_OFFSET],6
 jne .fail1
 mov r12,[rel request+NEBOC_LAYOUT_CLEANUP_HASH_OFFSET]
 test r12,r12
 jz .fail1
 call layout3
 test eax,eax
 jnz .fail1
 cmp r12,[rel request+NEBOC_LAYOUT_CLEANUP_HASH_OFFSET]
 jne .fail1

 ; Cleanup identity is order-sensitive; no commutative/double-drop model leaks.
 mov rax,[rel drops]
 xchg rax,[rel drops+16]
 mov [rel drops],rax
 call reset
 call layout3
 test eax,eax
 jnz .fail2
 cmp qword [rel request+NEBOC_LAYOUT_DROP_COUNT_OFFSET],6
 jne .fail2
 cmp r12,[rel request+NEBOC_LAYOUT_CLEANUP_HASH_OFFSET]
 je .fail2

 ; Caller storage is explicit, exact-sized and independent after transport.
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov edx,24
 call neboc_product_pass_return
 test eax,eax
 jnz .fail3
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov ecx,24
 repe cmpsb
 jne .fail3
 mov qword [rel target],0
 mov rax,0x1111111111111111
 cmp [rel source],rax
 jne .fail3
 lea rdi,[rel target]
 lea rsi,[rel source]
 mov rdx,NEBOC_LAYOUT_MAX_SIZE+1
 call neboc_product_pass_return
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail3

 xor edi,edi
 jmp neboc_host_process_exit
.fail1: mov edi,1
 jmp neboc_host_process_exit
.fail2: mov edi,2
 jmp neboc_host_process_exit
.fail3: mov edi,3
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
