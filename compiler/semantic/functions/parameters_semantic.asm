; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F02 semantic authentication and bounded System V register profile.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/parameters_parser.inc"

section .text

; RAX current hash, RDX qword -> RAX next FNV-1a state.
hash_qword:
 mov r8,1099511628211
 xor ecx,ecx
.loop:
 cmp ecx,8
 jae .done
 mov r9,rdx
 and r9,0xff
 xor rax,r9
 imul rax,r8
 shr rdx,8
 inc ecx
 jmp .loop
.done:
 ret

NEBOC_ABI_FUNCTION neboc_parameters_analyze
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov qword [r12+NEBOC_PARAM_SEMANTIC_HASH_OFFSET],0
 mov qword [r12+NEBOC_PARAM_ABI_HASH_OFFSET],0
 cmp qword [r12+NEBOC_PARAM_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 jne .source
 mov rbx,[r12+NEBOC_PARAM_COUNT_OFFSET]
 cmp rbx,NEBOC_PARAM_MAX
 ja .abi
 mov rax,[r12+NEBOC_PARAM_REQUIRED_COUNT_OFFSET]
 cmp rax,rbx
 ja .source
 mov rax,[r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET]
 mov rdx,[r12+NEBOC_PARAM_DEFAULT_COUNT_OFFSET]
 add rax,rdx
 jc .source
 cmp rax,rbx
 jne .source
 mov rax,[r12+NEBOC_PARAM_NAMED_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET]
 ja .source
 mov rax,[r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ja .source
 mov rax,[r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ja .source
 mov rax,[r12+NEBOC_PARAM_RETURN_ARITY_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_PARAM_MAX
 ja .source
 mov r13,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 test r13,r13
 jz .invalid
 test r13,7
 jnz .invalid
 xor r14d,r14d
 xor r15d,r15d
.params:
 cmp r14,rbx
 jae .hashes
 mov rax,r14
 imul rax,NEBOC_PARAM_RECORD_SIZE
 add rax,r13
 mov rcx,[rax+NEBOC_PARAM_TYPE_OFFSET]
 test rcx,rcx
 jz .source
 cmp rcx,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ja .source
 cmp qword [rax+NEBOC_PARAM_BOUND_OFFSET],1
 jne .source
 mov rdx,[rax+NEBOC_PARAM_HAS_DEFAULT_OFFSET]
 cmp rdx,1
 ja .source
 test rdx,rdx
 jz .required
 mov r15d,1
 jmp .next
.required:
 test r15d,r15d
 jnz .source
.next:
 inc r14
 jmp .params
.hashes:
 mov rax,[r12+NEBOC_OVERLOAD_COUNT_OFFSET]
 test rax,rax
 jz .overload_ready
 cmp rax,2
 jb .source
 cmp rax,NEBOC_OVERLOAD_MAX
 ja .source
 mov rdx,[r12+NEBOC_OVERLOAD_CANDIDATE_MASK_OFFSET]
 test rdx,rdx
 jz .source
 mov rcx,[r12+NEBOC_OVERLOAD_SELECTED_INDEX_OFFSET]
 cmp rcx,rax
 jae .source
 mov rcx,[r12+NEBOC_OVERLOAD_SELECTED_SCORE_OFFSET]
 test rcx,rcx
 jz .source
 cmp rcx,4
 ja .source
 cmp qword [r12+NEBOC_OVERLOAD_CONSTRAINT_MASK_OFFSET],0
 je .source
 cmp qword [r12+NEBOC_OVERLOAD_DISPATCH_HASH_OFFSET],0
 je .source
 cmp qword [r12+NEBOC_OVERLOAD_MANGLE_HASH_OFFSET],0
 je .source
 cmp qword [r12+NEBOC_OVERLOAD_COLLISION_COUNT_OFFSET],0
 jne .source
.overload_ready:
 mov rax,[r12+NEBOC_CALLABLE_COUNT_OFFSET]
 test rax,rax
 jz .callable_ready
 cmp rax,NEBOC_CALLABLE_MAX
 ja .source
 mov rcx,[r12+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET]
 cmp rcx,rax
 jae .source
 mov rcx,[r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET]
 cmp rcx,NEBOC_CAPTURE_BORROW
 ja .source
 cmp qword [r12+NEBOC_CALLABLE_CALL_COUNT_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET],1
 ja .source
 cmp rcx,NEBOC_CAPTURE_NONE
 je .no_environment
 cmp qword [r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET],NEBOC_CALLABLE_ENV_SIZE
 jne .source
 cmp rcx,NEBOC_CAPTURE_BORROW
 jne .callable_hash
 cmp qword [r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET],1
 jne .source
 jmp .callable_hash
.no_environment:
 cmp qword [r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET],0
 jne .source
.callable_hash:
 cmp qword [r12+NEBOC_CALLABLE_HASH_OFFSET],0
 je .source
.callable_ready:
 ; ABI identity authenticates the logical receiver, each ordinal and type.
 mov rax,14695981039346656037
 mov rdx,NEBOC_ABI_PROFILE_ID
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET]
 call hash_qword
 xor r14d,r14d
.abi_loop:
 cmp r14,rbx
 jae .abi_done
 mov rdx,r14
 inc rdx
 shl rdx,32
 mov rcx,r14
 imul rcx,NEBOC_PARAM_RECORD_SIZE
 add rcx,r13
 or rdx,[rcx+NEBOC_PARAM_TYPE_OFFSET]
 call hash_qword
 inc r14
 jmp .abi_loop
.abi_done:
 mov [r12+NEBOC_PARAM_ABI_HASH_OFFSET],rax
 ; Semantic hash covers the pointerless public facts plus each canonical record.
 mov rax,14695981039346656037
 mov rdx,[r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_FUNCTION_NAME_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_REQUIRED_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_DEFAULT_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_NAMED_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_RETURN_ARITY_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_OUTPUT_VALUE_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_PARAM_ABI_HASH_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_OVERLOAD_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_OVERLOAD_CANDIDATE_MASK_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_OVERLOAD_SELECTED_INDEX_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_OVERLOAD_SELECTED_SCORE_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_OVERLOAD_CONSTRAINT_MASK_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_OVERLOAD_DISPATCH_HASH_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_OVERLOAD_MANGLE_HASH_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_CAPTURE_VALUE_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_CALL_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET]
 call hash_qword
 mov rdx,[r12+NEBOC_CALLABLE_HASH_OFFSET]
 call hash_qword
 xor r14d,r14d
.record_hash:
 cmp r14,rbx
 jae .hash_done
 mov r10,r14
 imul r10,NEBOC_PARAM_RECORD_SIZE
 add r10,r13
 mov rdx,[r10+NEBOC_PARAM_NAME_OFFSET]
 call hash_qword
 mov rdx,[r10+NEBOC_PARAM_TYPE_OFFSET]
 call hash_qword
 mov rdx,[r10+NEBOC_PARAM_HAS_DEFAULT_OFFSET]
 call hash_qword
 mov rdx,[r10+NEBOC_PARAM_DEFAULT_VALUE_OFFSET]
 call hash_qword
 mov rdx,[r10+NEBOC_PARAM_BOUND_VALUE_OFFSET]
 call hash_qword
 inc r14
 jmp .record_hash
.hash_done:
 test rax,rax
 jz .source
 mov [r12+NEBOC_PARAM_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.abi:
 mov qword [r12+NEBOC_PARAM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_ABI_BOUND
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
