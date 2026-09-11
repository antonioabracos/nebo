; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF003 isolated SymbolTable, definite-assignment and abstract IR invariants
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_semantic.inc"
%include "compiler/lowering/bindings/binding_ir_contract.inc"
extern neboc_binding_contract
extern neboc_binding_semantic_analyze
extern neboc_binding_ir_lower
extern neboc_host_process_exit

section .rodata
name_counter: db "counter"
name_value: db "value"

section .bss align=16
syn: resb NEBOC_BIND_REQUEST_SIZE
sem: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_REQUEST_SIZE
ir: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_REQUEST_SIZE
ctx_syn_op: resq 1
ctx_sem_op: resq 1
ctx_decl_type: resq 1
ctx_value_type: resq 1
ctx_state: resq 1
ctx_syn_flags: resq 1
ctx_sem_flags: resq 1
ctx_true_state: resq 1
ctx_false_state: resq 1
ctx_source_id: resq 1
ctx_node_start: resq 1
ctx_subject_start: resq 1
saved_sem_hash: resq 1
saved_prov_hash: resq 1
saved_ir_hash: resq 1

section .text
%macro SETCTX 10
 mov qword [rel ctx_syn_op],%1
 mov qword [rel ctx_sem_op],%2
 mov qword [rel ctx_decl_type],%3
 mov qword [rel ctx_value_type],%4
 mov qword [rel ctx_state],%5
 mov qword [rel ctx_syn_flags],%6
 mov qword [rel ctx_sem_flags],%7
 mov qword [rel ctx_true_state],%8
 mov qword [rel ctx_false_state],%9
 mov qword [rel ctx_source_id],%10
%endmacro

clear_all:
 lea rdi,[rel syn]
 mov ecx,NEBOC_BIND_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel sem]
 mov ecx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel ir]
 mov ecx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 ret

prepare:
 call clear_all
 mov rax,[rel ctx_syn_op]
 mov [rel syn+NEBOC_BIND_OPERATION_OFFSET],rax
 mov rax,[rel ctx_decl_type]
 mov [rel syn+NEBOC_BIND_DECLARED_TYPE_OFFSET],rax
 mov rax,[rel ctx_value_type]
 mov [rel syn+NEBOC_BIND_VALUE_TYPE_OFFSET],rax
 mov rax,[rel ctx_state]
 mov [rel syn+NEBOC_BIND_SYMBOL_STATE_OFFSET],rax
 mov qword [rel syn+NEBOC_BIND_SCOPE_RELATION_OFFSET],NEBOC_BIND_SCOPE_SAME
 mov rax,[rel ctx_syn_flags]
 mov [rel syn+NEBOC_BIND_INPUT_FLAGS_OFFSET],rax
 lea rax,[rel name_counter]
 mov [rel syn+NEBOC_BIND_NAME_PTR_OFFSET],rax
 mov qword [rel syn+NEBOC_BIND_NAME_LENGTH_OFFSET],7
 mov qword [rel syn+NEBOC_BIND_ABSOLUTE_START_OFFSET],101
 lea rdi,[rel syn]
 call neboc_binding_contract
 ; The semantic stage must observe both successful and diagnostic syntax requests.
 lea rax,[rel syn]
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SYNTAX_REQUEST_OFFSET],rax
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SYMBOL_ID_OFFSET],77
 mov rax,[rel ctx_decl_type]
 test rax,rax
 jnz .have_type
 mov rax,[rel ctx_value_type]
.have_type:
 mov [rel sem+NEBOC_SEM_SYMBOL_TYPE_OFFSET],rax
 mov rax,[rel ctx_state]
 mov [rel sem+NEBOC_SEM_CURRENT_STATE_OFFSET],rax
 mov rax,[rel ctx_sem_op]
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_OPERATION_OFFSET],rax
 mov qword [rel sem+NEBOC_SEM_SCOPE_ID_OFFSET],3
 mov qword [rel sem+NEBOC_SEM_DECL_SCOPE_ID_OFFSET],3
 mov rax,[rel ctx_sem_flags]
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_INPUT_FLAGS_OFFSET],rax
 mov qword [rel sem+NEBOC_SEM_DECL_START_OFFSET],100
 mov qword [rel sem+NEBOC_SEM_DECL_END_OFFSET],109
 mov qword [rel sem+NEBOC_SEM_INIT_START_OFFSET],120
 mov qword [rel sem+NEBOC_SEM_INIT_END_OFFSET],129
 mov rax,[rel ctx_true_state]
 mov [rel sem+NEBOC_SEM_TRUE_STATE_OFFSET],rax
 mov rax,[rel ctx_false_state]
 mov [rel sem+NEBOC_SEM_FALSE_STATE_OFFSET],rax
 mov rax,[rel ctx_source_id]
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SOURCE_ID_OFFSET],rax
 mov rax,1000
 add rax,[rel ctx_source_id]
 mov [rel ctx_node_start],rax
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_NODE_START_OFFSET],rax
 add rax,20
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_NODE_END_OFFSET],rax
 mov rax,[rel ctx_node_start]
 add rax,2
 mov [rel ctx_subject_start],rax
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_START_OFFSET],rax
 add rax,7
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SUBJECT_END_OFFSET],rax
 lea rdi,[rel sem]
 jmp neboc_binding_semantic_analyze

lower_ir:
 lea rdi,[rel ir]
 mov ecx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel sem]
 mov [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_SEMANTIC_REQUEST_OFFSET],rax
 lea rdi,[rel ir]
 jmp neboc_binding_ir_lower

assert_success:
 test eax,eax
 jnz fail
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_RUNTIME_METADATA_OFFSET],0
 jne fail
 cmp qword [rel sem+NEBOC_SEM_SOURCE_DIAGNOSTIC_OFFSET],0
 jne fail
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CODE_OFFSET],0
 jne fail
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SEMANTIC_HASH_OFFSET],0
 je fail
 call lower_ir
 test eax,eax
 jnz fail
 cmp qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_HASH_OFFSET],0
 je fail
 ret

assert_invalid_source:
 ; edi expected diagnostic, eax status
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp [rel sem+NEBOC_SEM_SOURCE_DIAGNOSTIC_OFFSET],rdi
 jne fail
 mov rax,[rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_END_OFFSET]
 cmp rax,[rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_START_OFFSET]
 jbe fail
 ret

assert_internal:
 ; edi expected internal code, eax status
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CODE_OFFSET],rdi
 jne fail
 ret

global _start
_start:
 mov r13d,1
 ; 1 direct Int binding
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,501
 call prepare
 call assert_success
 cmp qword [rel sem+NEBOC_SEM_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 jne fail
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_DIRECT_BINDING
 jne fail
 mov rax,[rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SEMANTIC_HASH_OFFSET]
 mov [rel saved_sem_hash],rax
 mov rax,[rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_PROVENANCE_HASH_OFFSET]
 mov [rel saved_prov_hash],rax
 mov rax,[rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_HASH_OFFSET]
 mov [rel saved_ir_hash],rax

 inc r13d
 ; 2 explicit direct Int is semantically equivalent, provenance differs
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME|NEBOC_BIND_INPUT_EXPLICIT_FORM,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE|NEBOC_SEM_INPUT_EXPLICIT_FORM,0,0,502
 call prepare
 call assert_success
 mov rax,[rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SEMANTIC_HASH_OFFSET]
 cmp rax,[rel saved_sem_hash]
 jne fail
 mov rax,[rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_HASH_OFFSET]
 cmp rax,[rel saved_ir_hash]
 jne fail
 mov rax,[rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_PROVENANCE_HASH_OFFSET]
 cmp rax,[rel saved_prov_hash]
 je fail

 inc r13d
 ; 3 typed declaration
 SETCTX NEBOC_BIND_OP_TYPED_DECLARATION,NEBOC_SEM_OPERATION_TYPED_DECLARATION,NEBOC_BIND_TYPE_INT,0,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE,0,0,503
 call prepare
 call assert_success
 cmp qword [rel sem+NEBOC_SEM_RESULT_STATE_OFFSET],NEBOC_BIND_STATE_DECLARED_UNINITIALIZED
 jne fail
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_DECLARE
 jne fail

 inc r13d
 ; 4 one-shot initialization
 SETCTX NEBOC_BIND_OP_ONE_SHOT_INITIALIZATION,NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION,NEBOC_BIND_TYPE_INT,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_DECLARED_UNINITIALIZED,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,504
 call prepare
 call assert_success
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_LIR_KIND_OFFSET],NEBOC_SEM_LIR_SYMBOL_INITIALIZE_ONCE
 jne fail

 inc r13d
 ; 5 initialized read
 SETCTX NEBOC_BIND_OP_READ,NEBOC_SEM_OPERATION_READ,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE,0,0,505
 call prepare
 call assert_success
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_IDENTIFIER_READ
 jne fail

 inc r13d
 ; 6 definite read after all paths
 SETCTX NEBOC_BIND_OP_DEFINITE_READ,NEBOC_SEM_OPERATION_DEFINITE_READ,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_INPUT_VALID_NAME|NEBOC_BIND_INPUT_ALL_PATHS_INITIALIZED,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_ALL_PATHS_INITIALIZED,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_STATE_INITIALIZED,506
 call prepare
 call assert_success
 cmp qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_DEFINITE_READ
 jne fail

 inc r13d
 ; 7 if/else intersection where both branches initialize
 SETCTX NEBOC_BIND_OP_DEFINITE_READ,NEBOC_SEM_OPERATION_FLOW_MERGE,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_INPUT_VALID_NAME|NEBOC_BIND_INPUT_ALL_PATHS_INITIALIZED,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_ALL_PATHS_INITIALIZED,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_STATE_INITIALIZED,507
 call prepare
 call assert_success
 cmp qword [rel sem+NEBOC_SEM_MERGE_MASK_OFFSET],NEBOC_SEM_MERGE_ALL_INITIALIZED
 jne fail

 inc r13d
 ; 8 Text direct binding
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_TEXT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,508
 call prepare
 call assert_success

 inc r13d
 ; 9 Char typed declaration
 SETCTX NEBOC_BIND_OP_TYPED_DECLARATION,NEBOC_SEM_OPERATION_TYPED_DECLARATION,NEBOC_BIND_TYPE_CHAR,0,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE,0,0,509
 call prepare
 call assert_success

 inc r13d
 ; 10 Char initialization
 SETCTX NEBOC_BIND_OP_ONE_SHOT_INITIALIZATION,NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION,NEBOC_BIND_TYPE_CHAR,NEBOC_BIND_TYPE_CHAR,NEBOC_BIND_STATE_DECLARED_UNINITIALIZED,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,510
 call prepare
 call assert_success

 inc r13d
 ; 11 Bytes direct binding
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_BYTES,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,511
 call prepare
 call assert_success

 inc r13d
 ; 12 Float typed declaration
 SETCTX NEBOC_BIND_OP_TYPED_DECLARATION,NEBOC_SEM_OPERATION_TYPED_DECLARATION,NEBOC_BIND_TYPE_FLOAT,0,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE,0,0,512
 call prepare
 call assert_success

 inc r13d
 ; 13 undefined read diagnostic propagation
 SETCTX NEBOC_BIND_OP_READ,NEBOC_SEM_OPERATION_READ,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE,0,0,513
 call prepare
 mov edi,NEBOC_BIND_DIAG_UNDEFINED_NAME
 call assert_invalid_source

 inc r13d
 ; 14 second initialization diagnostic propagation
 SETCTX NEBOC_BIND_OP_ONE_SHOT_INITIALIZATION,NEBOC_SEM_OPERATION_ONE_SHOT_INITIALIZATION,NEBOC_BIND_TYPE_INT,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,514
 call prepare
 mov edi,NEBOC_BIND_DIAG_ALREADY_INITIALIZED
 call assert_invalid_source

 inc r13d
 ; 15 zero SymbolId
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,515
 call prepare
 ; prepare already analyzed; repeat with corrupted symbol id
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_SYMBOL_ID_OFFSET],0
 lea rdi,[rel sem]
 call neboc_binding_semantic_analyze
 mov edi,NEBOC_SEM_ERROR_SYMBOL_INVARIANT
 call assert_internal

 inc r13d
 ; 16 scope mismatch
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,516
 call prepare
 mov qword [rel sem+NEBOC_SEM_DECL_SCOPE_ID_OFFSET],4
 lea rdi,[rel sem]
 call neboc_binding_semantic_analyze
 mov edi,NEBOC_SEM_ERROR_SCOPE_INVARIANT
 call assert_internal

 inc r13d
 ; 17 invalid node span
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,517
 call prepare
 mov rax,[rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_NODE_START_OFFSET]
 mov [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_NODE_END_OFFSET],rax
 lea rdi,[rel sem]
 call neboc_binding_semantic_analyze
 mov edi,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_SPAN_INVARIANT
 call assert_internal

 inc r13d
 ; 18 semantic operation disagrees with syntax operation
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,518
 call prepare
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_TYPED_DECLARATION
 lea rdi,[rel sem]
 call neboc_binding_semantic_analyze
 mov edi,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_CONTRACT_INVALID
 call assert_internal

 inc r13d
 ; 19 semantic symbol type disagrees with syntax value type
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,519
 call prepare
 mov qword [rel sem+NEBOC_SEM_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_TEXT
 lea rdi,[rel sem]
 call neboc_binding_semantic_analyze
 mov edi,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_TYPE_INVARIANT
 call assert_internal

 inc r13d
 ; 20 one branch remains uninitialized
 SETCTX NEBOC_BIND_OP_DEFINITE_READ,NEBOC_SEM_OPERATION_FLOW_MERGE,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_INPUT_VALID_NAME|NEBOC_BIND_INPUT_ALL_PATHS_INITIALIZED,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_ALL_PATHS_INITIALIZED,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_STATE_DECLARED_UNINITIALIZED,520
 call prepare
 mov edi,NEBOC_BIND_DIAG_NOT_DEFINITELY_INITIALIZED
 call assert_invalid_source

 inc r13d
 ; 21 mutable flag is forbidden
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,521
 call prepare
 mov edi,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_FLAG_INVARIANT
 call assert_internal

 inc r13d
 ; 22 typed declaration may not carry a value type
 SETCTX NEBOC_BIND_OP_TYPED_DECLARATION,NEBOC_SEM_OPERATION_TYPED_DECLARATION,NEBOC_BIND_TYPE_INT,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE,0,0,522
 call prepare
 mov edi,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_TYPE_INVARIANT
 call assert_internal

 inc r13d
 ; 23 initialized read cannot have Void type
 SETCTX NEBOC_BIND_OP_READ,NEBOC_SEM_OPERATION_READ,0,NEBOC_BIND_TYPE_VOID,NEBOC_BIND_STATE_INITIALIZED,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE,0,0,523
 call prepare
 mov edi,neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_ERROR_TYPE_INVARIANT
 call assert_internal

 inc r13d
 ; 24 IR rejects corrupted HIR/LIR relationship
 SETCTX NEBOC_BIND_OP_DIRECT_BINDING,NEBOC_SEM_OPERATION_DIRECT_BINDING,0,NEBOC_BIND_TYPE_INT,NEBOC_BIND_STATE_ABSENT,NEBOC_BIND_INPUT_VALID_NAME,NEBOC_SEM_INPUT_VALID_SYMBOL|NEBOC_SEM_INPUT_IMMUTABLE|NEBOC_SEM_INPUT_SAME_SCOPE|NEBOC_SEM_INPUT_TYPE_COMPATIBLE,0,0,524
 call prepare
 call assert_success
 mov qword [rel sem+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_FLOW_STATE_MERGE
 call lower_ir
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne fail
 cmp qword [rel ir+neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_IR_ERROR_SEMANTIC_INVARIANT
 jne fail

 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
