; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF002 isolated domain-refinement API contract tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/domain_refinement_api_contract.inc"
extern neboc_domain_refinement_api_contract
extern neboc_host_process_exit

%macro CASE 14
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12,%13,%14
%endmacro

section .rodata
subject: db "7.toPositiveInt().unwrapOr(1)"
subject_len equ $-subject

section .data align=8
cases:
 ; op,recv,argc,recvLit,recvVal,fallLit,fallVal,flags,status,diag,resultType,tag,payload,reserved
 CASE 1,3,0,1,7,0,0,7,0,0,268435468,0,7,0
 CASE 1,3,0,1,0,0,0,7,0,0,268435468,1,1,0
 CASE 1,3,0,1,-1,0,0,7,0,0,268435468,1,1,0
 CASE 2,268435468,0,0,0,0,0,0,0,0,2,0,1,0
 CASE 3,268435468,0,0,0,0,0,0,0,0,2,0,1,0
 CASE 4,268435468,1,0,0,1,9,0,0,0,12,0,9,0
 CASE 99,3,0,1,7,0,0,7,4,1,0,0,0,0
 CASE 5,3,0,1,7,0,0,7,4,2,0,0,0,0
 CASE 1,9,0,1,7,0,0,7,4,3,0,0,0,0
 CASE 1,3,1,1,7,0,0,7,4,4,0,0,0,0
 CASE 1,3,0,0,7,0,0,7,4,5,0,0,0,0
 CASE 4,268435468,0,0,0,0,0,0,4,6,0,0,0,0
 CASE 4,268435468,1,0,0,0,9,0,4,7,0,0,0,0
 CASE 4,268435468,1,0,0,1,0,0,4,7,0,0,0,0
 CASE 6,3,1,1,7,0,0,0,4,8,0,0,0,0
 CASE 7,3,0,1,7,0,0,0,4,9,0,0,0,0
 CASE 8,3,0,0,0,0,0,0,4,10,0,0,0,0
 CASE 2,3,0,0,0,0,0,0,4,11,0,0,0,0
case_count equ ($-cases)/(14*8)

section .bss align=16
request: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_REQUEST_SIZE
first_hash: resq 1

section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel request]
 mov ecx,NEBOC_API_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 %assign i 0
 %rep 8
 mov rax,[r14+i*8]
 mov [rel request+i*8],rax
 %assign i i+1
 %endrep
 lea rax,[rel subject]
 mov [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_LENGTH_OFFSET],subject_len
 mov qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ABSOLUTE_START_OFFSET],800
 lea rdi,[rel request]
 call neboc_domain_refinement_api_contract
 cmp rax,[r14+8*8]
 jne .fail
 mov rax,[rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+9*8]
 jne .fail
 mov rax,[rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RESULT_TYPE_OFFSET]
 cmp rax,[r14+10*8]
 jne .fail
 mov rax,[rel request+NEBOC_API_RESULT_TAG_OFFSET]
 cmp rax,[r14+11*8]
 jne .fail
 mov rax,[rel request+NEBOC_API_RESULT_PAYLOAD_OFFSET]
 cmp rax,[r14+12*8]
 jne .fail
 cmp qword [r14+8*8],NEBOC_STATUS_OK
 je .next
 cmp qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ERROR_START_OFFSET],800
 jne .fail
 cmp qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ERROR_END_OFFSET],800+subject_len
 jne .fail
.next:
 add r14,14*8
 inc r13d
 dec r15d
 jnz .loop
 ; deterministic hash and null guard
 lea rdi,[rel request]
 mov ecx,NEBOC_API_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_OPERATION_OFFSET],NEBOC_OP_TO_POSITIVE_INT
 mov qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RECEIVER_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 mov qword [rel request+NEBOC_API_RECEIVER_LITERAL_OFFSET],1
 mov qword [rel request+NEBOC_API_RECEIVER_VALUE_OFFSET],7
 mov qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_INPUT_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_INPUT_REQUIRED_FLAGS
 lea rax,[rel subject]
 mov [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_PTR_OFFSET],rax
 mov qword [rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_LENGTH_OFFSET],subject_len
 lea rdi,[rel request]
 call neboc_domain_refinement_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_domain_refinement_api_contract
 test eax,eax
 jnz .fail
 mov rax,[rel first_hash]
 cmp rax,[rel request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_domain_refinement_api_contract
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
