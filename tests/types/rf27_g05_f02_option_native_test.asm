; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F02 explicit-tag Option A0 and pointerless-plan vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/semantic/types/option_layout_semantic.inc"
%include "compiler/lowering/scalars/option_result_plan.inc"

extern neboc_option_layout
extern neboc_option_lower
extern neboc_host_process_exit

section .bss align=16
layout_request: resb NEBOC_OPTION_LAYOUT_REQUEST_SIZE
option_request: resb NEBOC_OPTION_REQUEST_SIZE
option_plan: resb NEBOC_OPTION_PLAN_SIZE

section .text
global _start

reset_layout:
 lea rdi,[rel layout_request]
 mov ecx,NEBOC_OPTION_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ret

reset_plan:
 lea rdi,[rel option_request]
 mov ecx,NEBOC_OPTION_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel option_plan]
 mov ecx,NEBOC_OPTION_PLAN_QWORDS
 xor eax,eax
 rep stosq
 ret

_start:
 ; Option<Int> is one explicit tag byte, seven zero padding bytes and payload.
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],8
 lea rdi,[rel layout_request]
 call neboc_option_layout
 test eax,eax
 jnz .fail1
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],16
 jne .fail1
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_ALIGN_OFFSET],8
 jne .fail1
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_HASH_OFFSET],0
 je .fail1

 ; Bool, Char and zero-sized payloads retain the A0 minimum alignment.
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],1
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],1
 lea rdi,[rel layout_request]
 call neboc_option_layout
 test eax,eax
 jnz .fail2
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],16
 jne .fail2
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],4
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],4
 lea rdi,[rel layout_request]
 call neboc_option_layout
 test eax,eax
 jnz .fail2
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],16
 jne .fail2
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],1
 lea rdi,[rel layout_request]
 call neboc_option_layout
 test eax,eax
 jnz .fail2
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],8
 jne .fail2

 ; Generic payload layout rounds the tag area plus payload to payload alignment.
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],17
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],16
 lea rdi,[rel layout_request]
 call neboc_option_layout
 test eax,eax
 jnz .fail3
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],32
 jne .fail3
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_ALIGN_OFFSET],16
 jne .fail3
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],128
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],8
 lea rdi,[rel layout_request]
 call neboc_option_layout
 test eax,eax
 jnz .fail3
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET],136
 jne .fail3

 ; Non-power-of-two, over-aligned and oversized payload layouts are rejected.
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],3
 lea rdi,[rel layout_request]
 call neboc_option_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail4
 cmp qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_DIAGNOSTIC_OFFSET],NEBOC_OPTION_DIAG_LAYOUT
 jne .fail4
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],128
 lea rdi,[rel layout_request]
 call neboc_option_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail4
 call reset_layout
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],1048577
 mov qword [rel layout_request+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],8
 lea rdi,[rel layout_request]
 call neboc_option_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail4

 ; Lowering authenticates a complete pointerless bounded plan.
 call reset_plan
 mov qword [rel option_request+NEBOC_OPTION_FOUND_OFFSET],1
 mov qword [rel option_request+NEBOC_OPTION_RESULT_TYPE_OFFSET],NEBOC_OPTION_TYPE_INT
 mov qword [rel option_request+NEBOC_OPTION_RESULT_VALUE_OFFSET],42
 mov qword [rel option_request+NEBOC_OPTION_LAYOUT_SIZE_OFFSET],16
 mov qword [rel option_request+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET],8
 mov qword [rel option_request+NEBOC_OPTION_CALLBACK_COUNT_OFFSET],1
 mov qword [rel option_request+NEBOC_OPTION_DROP_COUNT_OFFSET],2
 mov rax,0x123456789abcdef0
 mov [rel option_request+NEBOC_OPTION_SEMANTIC_HASH_OFFSET],rax
 lea rdi,[rel option_request]
 lea rsi,[rel option_plan]
 call neboc_option_lower
 test eax,eax
 jnz .fail5
 mov rax,NEBOC_OPTION_PLAN_MAGIC
 cmp [rel option_plan+NEBOC_OPTION_PLAN_MAGIC_OFFSET],rax
 jne .fail5
 mov rax,NEBOC_OPTION_LAYOUT_ID
 cmp [rel option_plan+NEBOC_OPTION_PLAN_LAYOUT_ID_OFFSET],rax
 jne .fail5
 cmp qword [rel option_plan+NEBOC_OPTION_PLAN_RESULT_VALUE_OFFSET],42
 jne .fail5
 cmp qword [rel option_plan+NEBOC_OPTION_PLAN_HASH_OFFSET],0
 je .fail5

 ; Invalid layout alignment and callback bounds never publish a plan.
 mov qword [rel option_request+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET],3
 lea rdi,[rel option_request]
 lea rsi,[rel option_plan]
 call neboc_option_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail6
 mov qword [rel option_request+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET],8
 mov qword [rel option_request+NEBOC_OPTION_CALLBACK_COUNT_OFFSET],17
 lea rdi,[rel option_request]
 lea rsi,[rel option_plan]
 call neboc_option_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail6

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

section .note.GNU-stack noalloc noexec nowrite progbits
