; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F03 checked Array A0 layout and Range arithmetic vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/lowering/collections/array_range_layout.inc"

extern neboc_option_result_null_externo_e_erros_tipados_array_layout
extern neboc_range_length
extern neboc_host_process_exit

section .bss align=16
array_request: resb NEBOC_ARRAY_LAYOUT_SIZE
range_request: resb NEBOC_RANGE_REQUEST_SIZE

section .text
global _start

reset_array:
 lea rdi,[rel array_request]
 mov ecx,NEBOC_ARRAY_LAYOUT_QWORDS
 xor eax,eax
 rep stosq
 ret

reset_range:
 lea rdi,[rel range_request]
 mov ecx,NEBOC_RANGE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ret

_start:
 ; Array<Int,6> is six inline 8-byte strides.
 call reset_array
 mov qword [rel array_request+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_ELEMENT_SIZE_OFFSET],8
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_ELEMENT_ALIGN_OFFSET],8
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_LENGTH_OFFSET],6
 lea rdi,[rel array_request]
 call neboc_option_result_null_externo_e_erros_tipados_array_layout
 test eax,eax
 jnz .fail1
 cmp qword [rel array_request+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_STRIDE_OFFSET],8
 jne .fail1
 cmp qword [rel array_request+NEBOC_ARRAY_LAYOUT_TOTAL_SIZE_OFFSET],48
 jne .fail1

 ; Empty arrays have the frozen zero-byte A0 size.
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_LENGTH_OFFSET],0
 lea rdi,[rel array_request]
 call neboc_option_result_null_externo_e_erros_tipados_array_layout
 test eax,eax
 jnz .fail2
 cmp qword [rel array_request+NEBOC_ARRAY_LAYOUT_TOTAL_SIZE_OFFSET],0
 jne .fail2

 ; Length, alignment and multiplication are checked before publication.
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_LENGTH_OFFSET],257
 lea rdi,[rel array_request]
 call neboc_option_result_null_externo_e_erros_tipados_array_layout
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail3
 cmp qword [rel array_request+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_CONST_LENGTH
 jne .fail3
 call reset_array
 mov qword [rel array_request+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_ELEMENT_SIZE_OFFSET],8
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_ELEMENT_ALIGN_OFFSET],3
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_LENGTH_OFFSET],1
 lea rdi,[rel array_request]
 call neboc_option_result_null_externo_e_erros_tipados_array_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail3
 call reset_array
 mov qword [rel array_request+neboc_option_result_null_externo_e_erros_tipados_ARRAY_LAYOUT_ELEMENT_SIZE_OFFSET],1048576
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_ELEMENT_ALIGN_OFFSET],8
 mov qword [rel array_request+NEBOC_ARRAY_LAYOUT_LENGTH_OFFSET],2
 lea rdi,[rel array_request]
 call neboc_option_result_null_externo_e_erros_tipados_array_layout
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail3

 ; Exclusive ascending length uses ceil(delta/step), without iteration.
 call reset_range
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_START_OFFSET],1
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_END_OFFSET],6
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_STEP_OFFSET],2
 lea rdi,[rel range_request]
 call neboc_range_length
 test eax,eax
 jnz .fail4
 cmp qword [rel range_request+NEBOC_RANGE_LENGTH_OFFSET],3
 jne .fail4

 ; Inclusive descending length includes the final aligned endpoint.
 call reset_range
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_START_OFFSET],5
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_END_OFFSET],1
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_STEP_OFFSET],-2
 mov qword [rel range_request+NEBOC_RANGE_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 lea rdi,[rel range_request]
 call neboc_range_length
 test eax,eax
 jnz .fail5
 cmp qword [rel range_request+NEBOC_RANGE_LENGTH_OFFSET],3
 jne .fail5

 ; Zero step, wrong direction and unrepresentable delta share stable 006.
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_STEP_OFFSET],0
 lea rdi,[rel range_request]
 call neboc_range_length
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail6
 cmp qword [rel range_request+NEBOC_RANGE_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_RANGE
 jne .fail6
 call reset_range
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_START_OFFSET],5
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_END_OFFSET],1
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_STEP_OFFSET],1
 lea rdi,[rel range_request]
 call neboc_range_length
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail6
 call reset_range
 mov rax,0x8000000000000000
 mov [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_START_OFFSET],rax
 mov rax,0x7fffffffffffffff
 mov [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_END_OFFSET],rax
 mov qword [rel range_request+NEBOC_ARRAY_RANGE_LAYOUT_RANGE_STEP_OFFSET],1
 lea rdi,[rel range_request]
 call neboc_range_length
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
