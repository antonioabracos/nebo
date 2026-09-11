; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F05 constraint, instance, deduplication and plan vectors.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_parser.inc"
%include "compiler/lowering/generics/generic_plan.inc"

extern neboc_generic_analyze
extern neboc_generic_lower
extern neboc_host_process_exit

section .bss align=16
request: resb NEBOC_GEN_REQUEST_SIZE
records: resb NEBOC_GEN_MAX_INSTANCES*NEBOC_GEN_RECORD_SIZE
plan: resb NEBOC_GEN_PLAN_SIZE
saved_plan_hash: resq 1
saved_semantic_hash: resq 1
saved_instance_hash: resq 1
saved_symbol_hash: resq 1

section .text
global _start

reset_request:
 lea rdi,[rel request]
 mov ecx,NEBOC_GEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel records]
 mov ecx,NEBOC_GEN_MAX_INSTANCES*NEBOC_GEN_RECORD_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel plan]
 mov ecx,NEBOC_GEN_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel records]
 mov [rel request+NEBOC_GEN_RECORDS_OFFSET],rax
 mov qword [rel request+NEBOC_GEN_CAPACITY_OFFSET],NEBOC_GEN_MAX_INSTANCES
 mov qword [rel request+NEBOC_GEN_FOUND_OFFSET],1
 mov qword [rel request+NEBOC_GEN_DECLARATION_COUNT_OFFSET],1
 mov qword [rel request+NEBOC_GEN_RESULT_OFFSET],42
 mov qword [rel request+NEBOC_GEN_FLAGS_OFFSET],NEBOC_GEN_FLAG_PARSED
 ret

; RBX record offset, RAX type, RDX constraint, RCX declaration, R8 kind.
set_record:
 lea r10,[rel records]
 add r10,rbx
 mov [r10+NEBOC_GEN_RECORD_TYPE_ID_OFFSET],rax
 mov [r10+NEBOC_GEN_RECORD_CONSTRAINT_OFFSET],rdx
 mov [r10+NEBOC_GEN_RECORD_DECLARATION_HASH_OFFSET],rcx
 mov [r10+NEBOC_GEN_RECORD_KIND_OFFSET],r8
 ret

analyze:
 lea rdi,[rel request]
 jmp neboc_generic_analyze

lower:
 lea rdi,[rel request]
 lea rsi,[rel plan]
 jmp neboc_generic_lower

one_record:
 mov qword [rel request+NEBOC_GEN_USE_COUNT_OFFSET],1
 xor ebx,ebx
 mov ecx,0x11223344
 mov r8d,NEBOC_GEN_KIND_FUNCTION
 jmp set_record

_start:
 ; V01: Copy<Int> produces one authenticated pointerless instance.
 call reset_request
 mov eax,NEBOC_GEN_TYPE_INT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 call one_record
 call analyze
 test eax,eax
 jnz .fail1
 cmp qword [rel request+NEBOC_GEN_INSTANCE_COUNT_OFFSET],1
 jne .fail1
 call lower
 test eax,eax
 jnz .fail1
 cmp qword [rel plan+NEBOC_GEN_PLAN_INSTANCE_COUNT_OFFSET],1
 jne .fail1
 cmp qword [rel plan+NEBOC_GEN_PLAN_BUDGET_OFFSET],32
 jne .fail1

 ; V02: Eq admits Bool.
 call reset_request
 mov eax,NEBOC_GEN_TYPE_BOOL
 mov edx,NEBOC_GEN_CONSTRAINT_EQ
 call one_record
 call analyze
 test eax,eax
 jnz .fail2

 ; V03: Comparable admits Char.
 call reset_request
 mov eax,NEBOC_GEN_TYPE_CHAR
 mov edx,NEBOC_GEN_CONSTRAINT_COMPARABLE
 call one_record
 call analyze
 test eax,eax
 jnz .fail3

 ; V04: Hash admits Text while Copy deliberately does not.
 call reset_request
 mov eax,NEBOC_GEN_TYPE_TEXT
 mov edx,NEBOC_GEN_CONSTRAINT_HASH
 call one_record
 call analyze
 test eax,eax
 jnz .fail4

 ; V05: Copy admits the frozen scalar Float representation.
 call reset_request
 mov eax,NEBOC_GEN_TYPE_FLOAT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 call one_record
 call analyze
 test eax,eax
 jnz .fail5

 ; V06: repeated equal keys deduplicate to one emitted AOT instance.
 call reset_request
 mov qword [rel request+NEBOC_GEN_USE_COUNT_OFFSET],2
 xor ebx,ebx
 mov eax,NEBOC_GEN_TYPE_INT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 mov ecx,0x11223344
 mov r8d,NEBOC_GEN_KIND_FUNCTION
 call set_record
 mov ebx,NEBOC_GEN_RECORD_SIZE
 call set_record
 call analyze
 test eax,eax
 jnz .fail6
 cmp qword [rel request+NEBOC_GEN_INSTANCE_COUNT_OFFSET],1
 jne .fail6
 mov rax,[rel records+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 cmp rax,[rel records+NEBOC_GEN_RECORD_SIZE+NEBOC_GEN_RECORD_INSTANCE_KEY_OFFSET]
 jne .fail6

 ; V07: distinct concrete TypeKeys produce distinct instances.
 call reset_request
 mov qword [rel request+NEBOC_GEN_USE_COUNT_OFFSET],2
 xor ebx,ebx
 mov eax,NEBOC_GEN_TYPE_INT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 mov ecx,0x11223344
 mov r8d,NEBOC_GEN_KIND_FUNCTION
 call set_record
 mov ebx,NEBOC_GEN_RECORD_SIZE
 mov eax,NEBOC_GEN_TYPE_CHAR
 call set_record
 call analyze
 test eax,eax
 jnz .fail7
 cmp qword [rel request+NEBOC_GEN_INSTANCE_COUNT_OFFSET],2
 jne .fail7

 ; V08: constraint checking precedes lowering and rejects Text:Copy.
 call reset_request
 mov eax,NEBOC_GEN_TYPE_TEXT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 call one_record
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail8
 cmp qword [rel request+NEBOC_GEN_DIAGNOSTIC_OFFSET],NEBOC_GEN_DIAG_CONSTRAINT
 jne .fail8

 ; V09: the per-declaration budget is exactly 32.
 call reset_request
 mov qword [rel request+NEBOC_GEN_USE_COUNT_OFFSET],33
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail9
 cmp qword [rel request+NEBOC_GEN_DIAGNOSTIC_OFFSET],NEBOC_GEN_DIAG_BUDGET
 jne .fail9

 ; V10: distinct instance keys cannot share a declared symbol identity.
 call reset_request
 mov qword [rel request+NEBOC_GEN_USE_COUNT_OFFSET],2
 xor ebx,ebx
 mov eax,NEBOC_GEN_TYPE_INT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 mov ecx,0x11223344
 mov r8d,NEBOC_GEN_KIND_FUNCTION
 call set_record
 mov qword [rel records+NEBOC_GEN_RECORD_SYMBOL_HASH_OFFSET],777
 mov ebx,NEBOC_GEN_RECORD_SIZE
 mov eax,NEBOC_GEN_TYPE_CHAR
 call set_record
 mov qword [rel records+NEBOC_GEN_RECORD_SIZE+NEBOC_GEN_RECORD_SYMBOL_HASH_OFFSET],777
 call analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail10
 cmp qword [rel request+NEBOC_GEN_DIAGNOSTIC_OFFSET],NEBOC_GEN_DIAG_COLLISION
 jne .fail10

 ; V11: lowering rejects a tampered semantic publication.
 call reset_request
 mov eax,NEBOC_GEN_TYPE_INT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 call one_record
 call analyze
 test eax,eax
 jnz .fail11
 mov qword [rel request+NEBOC_GEN_FLAGS_OFFSET],NEBOC_GEN_FLAG_PARSED
 call lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail11
 cmp qword [rel plan+NEBOC_GEN_PLAN_DIAGNOSTIC_OFFSET],NEBOC_GEN_DIAG_INTERNAL
 jne .fail11

 ; V12: source use order cannot alter semantic or plan identity.
 call reset_request
 mov qword [rel request+NEBOC_GEN_USE_COUNT_OFFSET],2
 xor ebx,ebx
 mov eax,NEBOC_GEN_TYPE_INT
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 mov ecx,0x11223344
 mov r8d,NEBOC_GEN_KIND_FUNCTION
 call set_record
 mov ebx,NEBOC_GEN_RECORD_SIZE
 mov eax,NEBOC_GEN_TYPE_CHAR
 call set_record
 call analyze
 test eax,eax
 jnz .fail12
 call lower
 test eax,eax
 jnz .fail12
 mov rax,[rel request+NEBOC_GEN_SEMANTIC_HASH_OFFSET]
 mov [rel saved_semantic_hash],rax
 mov rax,[rel plan+NEBOC_GEN_PLAN_INSTANCE_SET_HASH_OFFSET]
 mov [rel saved_instance_hash],rax
 mov rax,[rel plan+NEBOC_GEN_PLAN_SYMBOL_SET_HASH_OFFSET]
 mov [rel saved_symbol_hash],rax
 mov rax,[rel plan+NEBOC_GEN_PLAN_HASH_OFFSET]
 mov [rel saved_plan_hash],rax
 call reset_request
 mov qword [rel request+NEBOC_GEN_USE_COUNT_OFFSET],2
 xor ebx,ebx
 mov eax,NEBOC_GEN_TYPE_CHAR
 mov edx,NEBOC_GEN_CONSTRAINT_COPY
 mov ecx,0x11223344
 mov r8d,NEBOC_GEN_KIND_FUNCTION
 call set_record
 mov ebx,NEBOC_GEN_RECORD_SIZE
 mov eax,NEBOC_GEN_TYPE_INT
 call set_record
 call analyze
 test eax,eax
 jnz .fail12
 call lower
 test eax,eax
 jnz .fail12
 mov rax,[rel saved_semantic_hash]
 cmp rax,[rel request+NEBOC_GEN_SEMANTIC_HASH_OFFSET]
 jne .fail12
 mov rax,[rel saved_instance_hash]
 cmp rax,[rel plan+NEBOC_GEN_PLAN_INSTANCE_SET_HASH_OFFSET]
 jne .fail12
 mov rax,[rel saved_symbol_hash]
 cmp rax,[rel plan+NEBOC_GEN_PLAN_SYMBOL_SET_HASH_OFFSET]
 jne .fail12
 mov rax,[rel saved_plan_hash]
 cmp rax,[rel plan+NEBOC_GEN_PLAN_HASH_OFFSET]
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
