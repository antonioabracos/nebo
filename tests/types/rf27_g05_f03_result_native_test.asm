; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F03 explicit-tag Result A0 union and authenticated-plan vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/semantic/types/option_layout_semantic.inc"
%include "compiler/lowering/scalars/option_result_plan.inc"

extern neboc_result_layout
extern neboc_result_lower
extern neboc_host_process_exit

section .bss align=16
layout_request: resb NEBOC_RESULT_LAYOUT_REQUEST_SIZE
result_request: resb NEBOC_RESULT_REQUEST_SIZE
result_plan: resb NEBOC_RESULT_PLAN_SIZE

section .text
global _start

reset_layout:
 lea rdi,[rel layout_request]
 mov ecx,NEBOC_RESULT_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ret

reset_plan:
 lea rdi,[rel result_request]
 mov ecx,NEBOC_RESULT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel result_plan]
 mov ecx,NEBOC_RESULT_PLAN_QWORDS
 xor eax,eax
 rep stosq
 ret

_start:
 ; V01: scalar Int/Bool uses one tag slot plus max(union payload).
 call reset_layout
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],1
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],1
 lea rdi,[rel layout_request]
 call neboc_result_layout
 test eax,eax
 jnz .fail1
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_RESULT_SIZE_OFFSET],16
 jne .fail1
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_RESULT_ALIGN_OFFSET],8
 jne .fail1
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_HASH_OFFSET],0
 je .fail1

 ; V02-V04: union chooses the larger side and the stricter alignment.
 call reset_layout
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],1
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],1
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],4
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],4
 lea rdi,[rel layout_request]
 call neboc_result_layout
 test eax,eax
 jnz .fail2
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_RESULT_SIZE_OFFSET],16
 jne .fail2
 call reset_layout
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],64
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],8
 lea rdi,[rel layout_request]
 call neboc_result_layout
 test eax,eax
 jnz .fail2
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_RESULT_SIZE_OFFSET],72
 jne .fail2
 call reset_layout
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],32
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],16
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],64
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],8
 lea rdi,[rel layout_request]
 call neboc_result_layout
 test eax,eax
 jnz .fail2
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_RESULT_SIZE_OFFSET],80
 jne .fail2
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_RESULT_ALIGN_OFFSET],16
 jne .fail2

 ; V05-V07: each side is independently checked before publication.
 call reset_layout
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],3
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],8
 lea rdi,[rel layout_request]
 call neboc_result_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail3
 cmp qword [rel layout_request+NEBOC_RESULT_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_RESULT_DIAG_LAYOUT
 jne .fail3
 call reset_layout
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],128
 lea rdi,[rel layout_request]
 call neboc_result_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail3
 call reset_layout
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],1048577
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],8
 mov qword [rel layout_request+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],8
 lea rdi,[rel layout_request]
 call neboc_result_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail3

 ; V08-V09: both active tags publish the same pointerless plan shape.
 call reset_plan
 mov qword [rel result_request+NEBOC_RESULT_FOUND_OFFSET],1
 mov qword [rel result_request+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [rel result_request+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],42
 mov qword [rel result_request+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],16
 mov qword [rel result_request+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],8
 mov qword [rel result_request+NEBOC_RESULT_CALLBACK_COUNT_OFFSET],1
 mov qword [rel result_request+NEBOC_RESULT_DROP_COUNT_OFFSET],2
 mov qword [rel result_request+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],0x12345678
 mov qword [rel result_request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 lea rdi,[rel result_request]
 lea rsi,[rel result_plan]
 call neboc_result_lower
 test eax,eax
 jnz .fail4
 mov rax,NEBOC_RESULT_PLAN_MAGIC
 cmp [rel result_plan+NEBOC_RESULT_PLAN_MAGIC_OFFSET],rax
 jne .fail4
 mov rax,NEBOC_RESULT_LAYOUT_ID
 cmp [rel result_plan+NEBOC_RESULT_PLAN_LAYOUT_ID_OFFSET],rax
 jne .fail4
 cmp qword [rel result_plan+NEBOC_RESULT_PLAN_OUTPUT_VALUE_OFFSET],42
 jne .fail4
 cmp qword [rel result_plan+NEBOC_RESULT_PLAN_HASH_OFFSET],0
 je .fail4
 mov qword [rel result_request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 lea rdi,[rel result_request]
 lea rsi,[rel result_plan]
 call neboc_result_lower
 test eax,eax
 jnz .fail4
 cmp qword [rel result_plan+NEBOC_RESULT_PLAN_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 jne .fail4

 ; V10-V11: invalid active tag and non-scalar public output never lower.
 mov qword [rel result_request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],2
 lea rdi,[rel result_request]
 lea rsi,[rel result_plan]
 call neboc_result_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail5
 mov qword [rel result_request+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov qword [rel result_request+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_ARRAY_INT
 lea rdi,[rel result_request]
 lea rsi,[rel result_plan]
 call neboc_result_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
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
