; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-PF003 substitution/ranking/IR invariant tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/generic_api_contract.inc"
%include "compiler/semantic/generics/generic_semantic.inc"
%include "compiler/lowering/generics/generic_ir_contract.inc"
extern neboc_generic_semantic_analyze
extern neboc_generic_ir_lower
extern neboc_host_process_exit

%macro SEMCASE 11
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11
%endmacro

section .data align=8
sem_cases:
 ; kind,recv,ret,concrete,generic,flags,count,limit,status,selected,diag
 SEMCASE NEBOC_SEM_KIND_DECLARATION,NEBOC_TYPE_PARAMETER_T,NEBOC_TYPE_PARAMETER_T,0,0,0,0,32,NEBOC_STATUS_OK,NEBOC_SELECTED_GENERIC,0
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL,0,1,0,0,32,NEBOC_STATUS_OK,NEBOC_SELECTED_GENERIC,0
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,1,0,1,32,NEBOC_STATUS_OK,NEBOC_SELECTED_GENERIC,0
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT,0,1,0,2,32,NEBOC_STATUS_OK,NEBOC_SELECTED_GENERIC,0
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR,0,1,0,3,32,NEBOC_STATUS_OK,NEBOC_SELECTED_GENERIC,0
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,1,1,0,0,32,NEBOC_STATUS_OK,NEBOC_SELECTED_CONCRETE,0
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_TEXT,neboc_generics_constraints_overload_e_dispatch_TYPE_TEXT,0,1,0,0,32,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_BOUND_NOT_SATISFIED
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,0,0,0,32,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_OVERLOAD_NO_MATCH
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,2,0,0,32,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_OVERLOAD_AMBIGUOUS
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,2,0,0,0,32,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_OVERLOAD_AMBIGUOUS
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,1,NEBOC_SEM_FLAG_REQUIRES_CONVERSION,0,32,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_OVERLOAD_NO_MATCH
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,1,0,0,32,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_RETURN_TYPE_PARAMETER_REQUIRED
 SEMCASE NEBOC_SEM_KIND_CALL,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,neboc_generics_constraints_overload_e_dispatch_TYPE_INT,0,1,0,32,32,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_DIAG_INSTANTIATION_LIMIT
sem_count equ ($-sem_cases)/(11*8)

section .bss align=16
sem_request: resb neboc_generics_constraints_overload_e_dispatch_SEM_REQUEST_SIZE
ir_request: resb neboc_generics_constraints_overload_e_dispatch_IR_REQUEST_SIZE
keys: resq 4

section .text
global _start
_start:
 lea r14,[rel sem_cases]
 mov r15d,sem_count
 mov r13d,1
.sem_loop:
 lea rdi,[rel sem_request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_KIND_OFFSET],rax
 mov qword [rel sem_request+NEBOC_SEM_DECLARATION_ID_OFFSET],7
 mov rax,[r14+8]
 mov [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_RECEIVER_TYPE_OFFSET],rax
 mov rax,[r14+16]
 mov [rel sem_request+NEBOC_SEM_BODY_RETURN_TYPE_OFFSET],rax
 mov rax,[r14+24]
 mov [rel sem_request+NEBOC_SEM_CONCRETE_CANDIDATES_OFFSET],rax
 mov rax,[r14+32]
 mov [rel sem_request+NEBOC_SEM_GENERIC_CANDIDATES_OFFSET],rax
 mov rax,[r14+40]
 mov [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_FLAGS_OFFSET],rax
 mov rax,[r14+48]
 mov [rel sem_request+NEBOC_SEM_INSTANCE_COUNT_OFFSET],rax
 mov rax,[r14+56]
 mov [rel sem_request+NEBOC_SEM_INSTANCE_LIMIT_OFFSET],rax
 mov qword [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_START_OFFSET],10
 mov qword [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_END_OFFSET],20
 lea rdi,[rel sem_request]
 call neboc_generic_semantic_analyze
 cmp rax,[r14+64]
 jne .fail
 mov rax,[rel sem_request+NEBOC_SEM_SELECTED_KIND_OFFSET]
 cmp rax,[r14+72]
 jne .fail
 mov rax,[rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+80]
 jne .fail
 cmp qword [r14+64],NEBOC_STATUS_OK
 jne .sem_next
 cmp qword [rel sem_request+NEBOC_SEM_INSTANCE_KEY_OFFSET],0
 je .fail
.sem_next:
 add r14,11*8
 inc r13d
 dec r15d
 jnz .sem_loop

 ; Explicit span invariant.
 lea rdi,[rel sem_request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_KIND_OFFSET],NEBOC_SEM_KIND_CALL
 mov qword [rel sem_request+NEBOC_SEM_DECLARATION_ID_OFFSET],7
 mov qword [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_START_OFFSET],20
 mov qword [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_SOURCE_END_OFFSET],10
 lea rdi,[rel sem_request]
 call neboc_generic_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel sem_request+neboc_generics_constraints_overload_e_dispatch_SEM_DIAGNOSTIC_OFFSET],neboc_generics_constraints_overload_e_dispatch_DIAG_SEMANTIC_SPAN_INVARIANT
 jne .fail

 ; Four concrete IR records preserve type/ABI class and deterministic identity.
 mov r12d,neboc_generics_constraints_overload_e_dispatch_TYPE_BOOL
 xor ebx,ebx
.ir_loop:
 lea rdi,[rel ir_request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [rel ir_request+NEBOC_IR_DECLARATION_ID_OFFSET],7
 mov [rel ir_request+NEBOC_IR_TYPE_ID_OFFSET],r12
 mov rax,100
 add rax,r12
 mov [rel ir_request+NEBOC_IR_SEMANTIC_KEY_OFFSET],rax
 mov [rel ir_request+NEBOC_IR_RECEIVER_TYPE_OFFSET],r12
 mov [rel ir_request+NEBOC_IR_RETURN_TYPE_OFFSET],r12
 mov qword [rel ir_request+NEBOC_IR_TARGET_ID_OFFSET],NEBOC_TARGET_X86_64_SYSV
 lea rdi,[rel ir_request]
 call neboc_generic_ir_lower
 test eax,eax
 jnz .fail
 mov rax,100
 add rax,r12
 cmp [rel ir_request+NEBOC_IR_INSTANCE_ID_OFFSET],rax
 jne .fail
 cmp qword [rel ir_request+neboc_generics_constraints_overload_e_dispatch_IR_FLAGS_OFFSET],neboc_generics_constraints_overload_e_dispatch_IR_REQUIRED_FLAGS
 jne .fail
 mov eax,NEBOC_ABI_CLASS_INTEGER
 cmp r12,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 jne .abi_ready
 mov eax,NEBOC_ABI_CLASS_SSE
.abi_ready:
 cmp [rel ir_request+neboc_generics_constraints_overload_e_dispatch_IR_ABI_CLASS_OFFSET],rax
 jne .fail
 mov rax,[rel ir_request+NEBOC_IR_SYMBOL_HASH_OFFSET]
 test rax,rax
 jz .fail
 lea rdx,[rel keys]
 mov [rdx+rbx*8],rax
 inc ebx
 cmp ebx,1
 je .ir_int
 cmp ebx,2
 je .ir_float
 cmp ebx,3
 je .ir_char
 jmp .ir_done
.ir_int: mov r12d,neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 jmp .ir_loop
.ir_float: mov r12d,neboc_generics_constraints_overload_e_dispatch_TYPE_FLOAT
 jmp .ir_loop
.ir_char: mov r12d,neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 jmp .ir_loop
.ir_done:
 cmp qword [rel keys],0
 je .fail
 mov rax,[rel keys]
 cmp rax,[rel keys+8]
 je .fail
 cmp rax,[rel keys+16]
 je .fail
 cmp rax,[rel keys+24]
 je .fail

 ; Invalid IR never survives as a partially valid specialization.
 mov qword [rel ir_request+NEBOC_IR_RETURN_TYPE_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_INT
 lea rdi,[rel ir_request]
 call neboc_generic_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel ir_request+neboc_generics_constraints_overload_e_dispatch_IR_DIAGNOSTIC_OFFSET],NEBOC_DIAG_MONOMORPHIZATION_INVARIANT
 jne .fail
 mov qword [rel ir_request+NEBOC_IR_RETURN_TYPE_OFFSET],neboc_generics_constraints_overload_e_dispatch_TYPE_CHAR
 mov qword [rel ir_request+NEBOC_IR_TARGET_ID_OFFSET],2
 lea rdi,[rel ir_request]
 call neboc_generic_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 cmp qword [rel ir_request+neboc_generics_constraints_overload_e_dispatch_IR_DIAGNOSTIC_OFFSET],NEBOC_DIAG_UNSUPPORTED_TARGET
 jne .fail

 xor edi,edi
 call neboc_generic_semantic_analyze
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 call neboc_generic_ir_lower
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
