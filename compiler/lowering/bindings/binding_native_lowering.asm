; Nebo Assembly — BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF004 isolated binding native lowering
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_semantic.inc"
%include "compiler/lowering/bindings/binding_ir_contract.inc"
%include "compiler/lowering/bindings/binding_native_lowering.inc"

section .text
NEBOC_ABI_FUNCTION neboc_binding_native_lower
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov r13,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SEMANTIC_REQUEST_OFFSET]
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_IR_REQUEST_OFFSET]
 test r13,r13
 jz .invalid_argument
 test r14,r14
 jz .invalid_argument
 lea rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_OPERATION_OFFSET]
 mov ecx,(neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REQUEST_SIZE-neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_OPERATION_OFFSET)/8
 xor eax,eax
 rep stosq
 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_TARGET_ID_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 jne .target_error
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_NONE
 jne .semantic_error
 cmp qword [r14+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_ERROR_NONE
 jne .ir_error
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RUNTIME_METADATA_OFFSET],0
 jne .metadata_error
 cmp qword [r14+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_RUNTIME_METADATA_OFFSET],0
 jne .metadata_error
 mov r15,[r13+NEBOC_SEM_RESULT_OPERATION_OFFSET]
 cmp r15,[r14+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_OPERATION_OFFSET]
 jne .contract_error
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SEMANTIC_HASH_OFFSET],0
 je .contract_error
 cmp qword [r14+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_HASH_OFFSET],0
 je .contract_error
 mov rax,[r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET]
 cmp rax,[r14+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_LIR_KIND_OFFSET]
 jne .contract_error
 mov rbx,[r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RESULT_TYPE_OFFSET]
 cmp rbx,[r12+NEBOC_NATIVE_VALUE_TYPE_OFFSET]
 jne .type_error
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_OPERATION_OFFSET],r15
 mov qword [r12+NEBOC_NATIVE_RUNTIME_OBJECT_OFFSET],NEBOC_NATIVE_RUNTIME_OBJECT_NONE
 mov qword [r12+NEBOC_NATIVE_ALLOCATION_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ALLOCATION_NONE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_RUNTIME_METADATA_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_METADATA_NONE
 cmp r15,NEBOC_SEM_OPERATION_FLOW_MERGE
 je .flow_merge
 mov rdi,r12
 mov rsi,rbx
 call g05n_layout
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_NATIVE_STACK_SLOT_OFFSET_OFFSET]
 test rax,rax
 jz .slot_error
 mov rcx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_ALIGNMENT_OFFSET]
 dec rcx
 test rax,rcx
 jnz .slot_error
 cmp r15,NEBOC_SEM_OPERATION_TYPED_DECLARATION
 je .typed
 cmp r15,NEBOC_SEM_OPERATION_DIRECT_BINDING
 je .direct
 cmp r15,NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION
 je .initialize
 cmp r15,NEBOC_SEM_OPERATION_READ
 je .read
 cmp r15,NEBOC_SEM_OPERATION_DEFINITE_READ
 je .definite_read
 jmp .contract_error
.typed:
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_DECLARE
 jne .contract_error
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_NONE
 mov qword [r12+NEBOC_NATIVE_RESERVE_SLOT_OFFSET],1
 mov qword [r12+NEBOC_NATIVE_STATE_ONLY_OFFSET],1
 jmp .hash
.direct:
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_BIND_VALUE
 jne .contract_error
 mov qword [r12+NEBOC_NATIVE_RESERVE_SLOT_OFFSET],1
 mov qword [r12+NEBOC_NATIVE_STORE_COUNT_OFFSET],1
 jmp .store_instruction
.initialize:
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_INITIALIZE_ONCE
 jne .contract_error
 mov qword [r12+NEBOC_NATIVE_STORE_COUNT_OFFSET],1
 jmp .store_instruction
.read:
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_READ
 jne .contract_error
 mov qword [r12+NEBOC_NATIVE_LOAD_COUNT_OFFSET],1
 jmp .load_instruction
.definite_read:
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_DEFINITE_READ
 jne .contract_error
 mov qword [r12+NEBOC_NATIVE_LOAD_COUNT_OFFSET],1
 jmp .load_instruction
.flow_merge:
 cmp qword [r13+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_FLOW_STATE_INTERSECTION
 jne .contract_error
 mov qword [r12+NEBOC_NATIVE_REPRESENTATION_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REPR_NONE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_ALIGNMENT_OFFSET],1
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_CLASS_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_NONE
 mov qword [r12+NEBOC_NATIVE_VALUE_REGISTER_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REGISTER_NONE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],NEBOC_NATIVE_INSTRUCTION_NONE
 mov qword [r12+NEBOC_NATIVE_STATE_ONLY_OFFSET],1
 jmp .hash
.store_instruction:
 mov rax,[r12+NEBOC_NATIVE_REPRESENTATION_OFFSET]
 cmp rax,neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REPR_BOOL_U8
 je .store_u8
 cmp rax,NEBOC_NATIVE_REPR_SIGNED_I64
 je .store_i64
 cmp rax,NEBOC_NATIVE_REPR_BINARY64
 je .store_f64
 cmp rax,NEBOC_NATIVE_REPR_DESCRIPTOR_PTR
 je .store_ptr
 cmp rax,NEBOC_NATIVE_REPR_UNICODE_U32
 je .store_u32
 jmp .type_error
.store_u8: mov eax,NEBOC_NATIVE_INSTRUCTION_STORE_U8
 jmp .set_instruction
.store_i64: mov eax,NEBOC_NATIVE_INSTRUCTION_STORE_I64
 jmp .set_instruction
.store_f64: mov eax,NEBOC_NATIVE_INSTRUCTION_STORE_F64
 jmp .set_instruction
.store_ptr: mov eax,NEBOC_NATIVE_INSTRUCTION_STORE_PTR
 jmp .set_instruction
.store_u32: mov eax,NEBOC_NATIVE_INSTRUCTION_STORE_U32
 jmp .set_instruction
.load_instruction:
 mov rax,[r12+NEBOC_NATIVE_REPRESENTATION_OFFSET]
 cmp rax,neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REPR_BOOL_U8
 je .load_u8
 cmp rax,NEBOC_NATIVE_REPR_SIGNED_I64
 je .load_i64
 cmp rax,NEBOC_NATIVE_REPR_BINARY64
 je .load_f64
 cmp rax,NEBOC_NATIVE_REPR_DESCRIPTOR_PTR
 je .load_ptr
 cmp rax,NEBOC_NATIVE_REPR_UNICODE_U32
 je .load_u32
 jmp .type_error
.load_u8: mov eax,NEBOC_NATIVE_INSTRUCTION_LOAD_U8_ZX
 jmp .set_instruction
.load_i64: mov eax,NEBOC_NATIVE_INSTRUCTION_LOAD_I64
 jmp .set_instruction
.load_f64: mov eax,NEBOC_NATIVE_INSTRUCTION_LOAD_F64
 jmp .set_instruction
.load_ptr: mov eax,NEBOC_NATIVE_INSTRUCTION_LOAD_PTR
 jmp .set_instruction
.load_u32: mov eax,NEBOC_NATIVE_INSTRUCTION_LOAD_U32_ZX
.set_instruction:
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_INSTRUCTION_OFFSET],rax
.hash:
 mov rax,NEBOC_NATIVE_HASH_OFFSET_BASIS
 lea rsi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_OPERATION_OFFSET]
 mov ecx,15
.hash_loop:
 xor rax,[rsi]
 mov rdx,NEBOC_NATIVE_HASH_PRIME
 imul rax,rdx
 add rsi,8
 loop .hash_loop
 test rax,rax
 jnz .hash_ok
 mov eax,1
.hash_ok:
 mov [r12+NEBOC_NATIVE_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.target_error:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_TARGET
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.semantic_error:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_SEMANTIC
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ir_error:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_IR
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.contract_error:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CONTRACT
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.type_error:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],NEBOC_NATIVE_ERROR_TYPE
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.slot_error:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],NEBOC_NATIVE_ERROR_SLOT
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.metadata_error:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_METADATA
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; rdi=request, rsi=TypeId
; caller-owned stack slot representation only; no binding object.
g05n_layout:
 cmp rsi,NEBOC_BIND_TYPE_BOOL
 je .bool
 cmp rsi,NEBOC_BIND_TYPE_INT
 je .int
 cmp rsi,NEBOC_BIND_TYPE_FLOAT
 je .float
 cmp rsi,NEBOC_BIND_TYPE_TEXT
 je .pointer
 cmp rsi,NEBOC_BIND_TYPE_CONSOLE
 je .int
 cmp rsi,NEBOC_BIND_TYPE_CHAR
 je .char
 cmp rsi,NEBOC_BIND_TYPE_BYTES
 je .pointer
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ERROR_CODE_OFFSET],NEBOC_NATIVE_ERROR_TYPE
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 ret
.bool:
 mov qword [rdi+NEBOC_NATIVE_REPRESENTATION_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REPR_BOOL_U8
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],1
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_ALIGNMENT_OFFSET],1
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_CLASS_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_INTEGER
 mov qword [rdi+NEBOC_NATIVE_VALUE_REGISTER_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REGISTER_RAX
 xor eax,eax
 ret
.int:
 mov qword [rdi+NEBOC_NATIVE_REPRESENTATION_OFFSET],NEBOC_NATIVE_REPR_SIGNED_I64
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],8
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_ALIGNMENT_OFFSET],8
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_CLASS_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_INTEGER
 mov qword [rdi+NEBOC_NATIVE_VALUE_REGISTER_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REGISTER_RAX
 xor eax,eax
 ret
.float:
 mov qword [rdi+NEBOC_NATIVE_REPRESENTATION_OFFSET],NEBOC_NATIVE_REPR_BINARY64
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],8
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_ALIGNMENT_OFFSET],8
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_CLASS_OFFSET],NEBOC_NATIVE_ABI_SSE
 mov qword [rdi+NEBOC_NATIVE_VALUE_REGISTER_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REGISTER_XMM0
 xor eax,eax
 ret
.pointer:
 mov qword [rdi+NEBOC_NATIVE_REPRESENTATION_OFFSET],NEBOC_NATIVE_REPR_DESCRIPTOR_PTR
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],8
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_ALIGNMENT_OFFSET],8
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_CLASS_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_INTEGER
 mov qword [rdi+NEBOC_NATIVE_VALUE_REGISTER_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REGISTER_RAX
 xor eax,eax
 ret
.char:
 mov qword [rdi+NEBOC_NATIVE_REPRESENTATION_OFFSET],NEBOC_NATIVE_REPR_UNICODE_U32
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_SIZE_OFFSET],4
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_SLOT_ALIGNMENT_OFFSET],4
 mov qword [rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_CLASS_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_ABI_INTEGER
 mov qword [rdi+NEBOC_NATIVE_VALUE_REGISTER_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_NATIVE_REGISTER_RAX
 xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
