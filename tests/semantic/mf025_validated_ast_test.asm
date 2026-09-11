; Nebo Assembly — MF025 Validated AST and complete side-table contracts
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/effect/effect_classifier.inc"
%include "compiler/semantic/database/control_flow_table.inc"
%include "compiler/semantic/database/constant_value_table.inc"
%include "compiler/semantic/database/semantic_database.inc"
%include "compiler/semantic/dump/semantic_dump.inc"

extern neboc_control_flow_table_init
extern neboc_control_flow_table_set
extern neboc_control_flow_table_freeze
extern neboc_constant_value_table_init
extern neboc_constant_value_table_set
extern neboc_constant_value_table_freeze
extern neboc_semantic_database_validate
extern neboc_semantic_dump
extern neboc_host_process_exit

section .rodata align=16
nodes_template:
 dq NEBOC_AST_PROGRAM,0,1,0,1,0,0,0,0,0
 dq NEBOC_AST_INTEGER_LITERAL,0,1,0,1,0,0,0,42,0
 dq NEBOC_AST_CALL_EXPR,0,1,0,1,0,0,0,0,0
 dq NEBOC_AST_IF_STMT,0,1,0,1,0,0,0,0,0
required_template: dq 0,35,463,17
types_template: dq 0,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_TEXT,NEBOC_TYPE_ID_BOOL
symbols_template: dq 0,1,2,0
effects_template: dq 0,0,NEBOC_EFFECT_ID_CONSOLE,0
calls_template: dq 0,0,1,0
behaviors_template: dq 0,0,1,0
routes_template: dq 0,0,1,0
dependencies_template: dq 0,0,1,0

error_node_template:
 dq NEBOC_AST_ERROR_NODE,NEBOC_AST_FLAG_RECOVERED,1,0,1,0,0,0,0,0
error_required_template: dq 0

golden_start:
 incbin "tests/semantic/goldens/009-validated-ast-dump.txt"
golden_end:
golden_size equ golden_end-golden_start

section .bss align=16
%macro INSTANCE_BSS 1
nodes_%{1}: resq 40
required_%{1}: resq 4
types_%{1}: resq 4
symbols_%{1}: resq 4
effects_%{1}: resq 4
calls_%{1}: resq 4
behaviors_%{1}: resq 4
routes_%{1}: resq 4
dependencies_%{1}: resq 4
control_data_%{1}: resq 4
constant_values_%{1}: resq 4
constant_flags_%{1}: resq 4
ast_%{1}: resb NEBOC_AST_STORE_SIZE
control_%{1}: resb NEBOC_CONTROL_FLOW_TABLE_SIZE
constant_%{1}: resb NEBOC_CONSTANT_VALUE_TABLE_SIZE
database_%{1}: resb NEBOC_SEMANTIC_DATABASE_SIZE
dump_%1: resb 1024
dump_len_%1: resq 1
%endmacro
INSTANCE_BSS a
INSTANCE_BSS b
error_node: resq 10
error_required: resq 1
error_ast: resb NEBOC_AST_STORE_SIZE
error_database: resb NEBOC_SEMANTIC_DATABASE_SIZE
saved_hash: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 cmp byte [rdx+1],0
 jne test_usage
 movzx eax,byte [rdx]
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,5
 ja test_usage
 cmp eax,1
 je case1
 cmp eax,2
 je case2
 cmp eax,3
 je case3
 cmp eax,4
 je case4
 jmp case5

case1:
 call setup_a
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 test eax,eax
 jnz test_fail
 mov qword [rel types_a+16],0
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],NEBOC_SEMANTIC_ERROR_MISSING_TYPE
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_NODE_ID_OFFSET],3
 jne test_fail
 jmp test_pass

case2:
 call setup_a
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 test eax,eax
 jnz test_fail
 mov qword [rel effects_a+16],0
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],NEBOC_SEMANTIC_ERROR_MISSING_EFFECT
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_NODE_ID_OFFSET],3
 jne test_fail
 jmp test_pass

case3:
 call setup_a
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 test eax,eax
 jnz test_fail
 mov qword [rel routes_a+16],0
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],NEBOC_SEMANTIC_ERROR_MISSING_ROUTE
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_NODE_ID_OFFSET],3
 jne test_fail
 jmp test_pass

case4:
 call setup_a
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 test eax,eax
 jnz test_fail
 mov qword [rel dependencies_a+16],0
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],NEBOC_SEMANTIC_ERROR_MISSING_DEPENDENCY
 jne test_fail
 cmp qword [rel database_a+NEBOC_SEMANTIC_DATABASE_ERROR_NODE_ID_OFFSET],3
 jne test_fail
 jmp test_pass

case5:
 call setup_a
 call setup_b
 lea rdi,[rel database_a]
 call neboc_semantic_database_validate
 test eax,eax
 jnz test_fail
 lea rdi,[rel database_b]
 call neboc_semantic_database_validate
 test eax,eax
 jnz test_fail
 mov rax,[rel database_a+NEBOC_SEMANTIC_DATABASE_HASH_OFFSET]
 test rax,rax
 jz test_fail
 mov [rel saved_hash],rax
 cmp rax,[rel database_b+NEBOC_SEMANTIC_DATABASE_HASH_OFFSET]
 jne test_fail
 lea rdi,[rel database_a]
 lea rsi,[rel dump_a]
 mov edx,1024
 lea rcx,[rel dump_len_a]
 call neboc_semantic_dump
 test eax,eax
 jnz test_fail
 lea rdi,[rel database_b]
 lea rsi,[rel dump_b]
 mov edx,1024
 lea rcx,[rel dump_len_b]
 call neboc_semantic_dump
 test eax,eax
 jnz test_fail
 cmp qword [rel dump_len_a],golden_size
 jne test_fail
 cmp qword [rel dump_len_b],golden_size
 jne test_fail
 lea rdi,[rel dump_a]
 lea rsi,[rel dump_b]
 mov edx,golden_size
 call bytes_equal
 test eax,eax
 jz test_fail
 lea rdi,[rel dump_a]
 lea rsi,[rel golden_start]
 mov edx,golden_size
 call bytes_equal
 test eax,eax
 jz test_fail
 call setup_error
 lea rdi,[rel error_database]
 call neboc_semantic_database_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel error_database+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],NEBOC_SEMANTIC_ERROR_ERROR_NODE
 jne test_fail
 cmp qword [rel error_database+NEBOC_SEMANTIC_DATABASE_STATE_OFFSET],NEBOC_SEMANTIC_DATABASE_STATE_INVALID
 jne test_fail
 jmp test_pass

%macro COPY_QWORDS 3
 lea rdi,[rel %1]
 lea rsi,[rel %2]
 mov ecx,%3
 rep movsq
%endmacro

%macro CLEAR_QWORDS 2
 lea rdi,[rel %1]
 xor eax,eax
 mov ecx,%2
 rep stosq
%endmacro

%macro DEFINE_SETUP 1
setup_%{1}:
 COPY_QWORDS nodes_%{1},nodes_template,40
 COPY_QWORDS required_%{1},required_template,4
 COPY_QWORDS types_%{1},types_template,4
 COPY_QWORDS symbols_%{1},symbols_template,4
 COPY_QWORDS effects_%{1},effects_template,4
 COPY_QWORDS calls_%{1},calls_template,4
 COPY_QWORDS behaviors_%{1},behaviors_template,4
 COPY_QWORDS routes_%{1},routes_template,4
 COPY_QWORDS dependencies_%{1},dependencies_template,4
 CLEAR_QWORDS ast_%{1},NEBOC_AST_STORE_QWORDS
 CLEAR_QWORDS database_%{1},NEBOC_SEMANTIC_DATABASE_QWORDS
 lea rax,[rel nodes_%{1}]
 mov [rel ast_%{1}+NEBOC_AST_STORE_DATA_OFFSET],rax
 mov qword [rel ast_%{1}+NEBOC_AST_STORE_COUNT_OFFSET],4
 mov qword [rel ast_%{1}+NEBOC_AST_STORE_ROOT_ID_OFFSET],1
 mov qword [rel ast_%{1}+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 mov qword [rel ast_%{1}+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_NONE
 mov qword [rel ast_%{1}+NEBOC_AST_STORE_HASH_OFFSET],0x12345678
 lea rdi,[rel control_%{1}]
 lea rsi,[rel control_data_%{1}]
 mov edx,4
 call neboc_control_flow_table_init
 test eax,eax
 jnz test_fail
 lea rdi,[rel control_%{1}]
 mov esi,4
 mov edx,NEBOC_CONTROL_FLOW_BRANCH
 call neboc_control_flow_table_set
 test eax,eax
 jnz test_fail
 lea rdi,[rel control_%{1}]
 call neboc_control_flow_table_freeze
 test eax,eax
 jnz test_fail
 lea rdi,[rel constant_%{1}]
 lea rsi,[rel constant_values_%{1}]
 lea rdx,[rel constant_flags_%{1}]
 mov ecx,4
 call neboc_constant_value_table_init
 test eax,eax
 jnz test_fail
 lea rdi,[rel constant_%{1}]
 mov esi,2
 mov edx,42
 call neboc_constant_value_table_set
 test eax,eax
 jnz test_fail
 lea rdi,[rel constant_%{1}]
 call neboc_constant_value_table_freeze
 test eax,eax
 jnz test_fail
 lea rax,[rel ast_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_AST_STORE_OFFSET],rax
 lea rax,[rel required_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_REQUIRED_MASKS_OFFSET],rax
 lea rax,[rel types_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_TYPES_OFFSET],rax
 lea rax,[rel symbols_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_SYMBOLS_OFFSET],rax
 lea rax,[rel effects_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_EFFECTS_OFFSET],rax
 lea rax,[rel calls_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_CALLS_OFFSET],rax
 lea rax,[rel behaviors_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_BEHAVIORS_OFFSET],rax
 lea rax,[rel routes_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_ROUTES_OFFSET],rax
 lea rax,[rel dependencies_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_DEPENDENCIES_OFFSET],rax
 lea rax,[rel control_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_CONTROL_TABLE_OFFSET],rax
 lea rax,[rel constant_%{1}]
 mov [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_CONSTANT_TABLE_OFFSET],rax
 mov qword [rel database_%{1}+NEBOC_SEMANTIC_DATABASE_NODE_COUNT_OFFSET],4
 ret
%endmacro

DEFINE_SETUP a
DEFINE_SETUP b

setup_error:
 COPY_QWORDS error_node,error_node_template,10
 COPY_QWORDS error_required,error_required_template,1
 CLEAR_QWORDS error_ast,NEBOC_AST_STORE_QWORDS
 CLEAR_QWORDS error_database,NEBOC_SEMANTIC_DATABASE_QWORDS
 lea rax,[rel error_node]
 mov [rel error_ast+NEBOC_AST_STORE_DATA_OFFSET],rax
 mov qword [rel error_ast+NEBOC_AST_STORE_COUNT_OFFSET],1
 mov qword [rel error_ast+NEBOC_AST_STORE_ROOT_ID_OFFSET],1
 mov qword [rel error_ast+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 mov qword [rel error_ast+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_HAS_ERROR
 mov qword [rel error_ast+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET],1
 mov qword [rel error_ast+NEBOC_AST_STORE_HASH_OFFSET],0x9999
 lea rax,[rel error_ast]
 mov [rel error_database+NEBOC_SEMANTIC_DATABASE_AST_STORE_OFFSET],rax
 lea rax,[rel error_required]
 mov [rel error_database+NEBOC_SEMANTIC_DATABASE_REQUIRED_MASKS_OFFSET],rax
 mov qword [rel error_database+NEBOC_SEMANTIC_DATABASE_NODE_COUNT_OFFSET],1
 ret

; bytes_equal(a,b,length) -> EAX=1 equal, 0 different
bytes_equal:
 test rdx,rdx
 jz .equal
.loop:
 mov al,[rdi]
 cmp al,[rsi]
 jne .different
 inc rdi
 inc rsi
 dec rdx
 jnz .loop
.equal:
 mov eax,1
 ret
.different:
 xor eax,eax
 ret

test_pass:
 xor edi,edi
 call neboc_host_process_exit
test_fail:
 mov edi,1
 call neboc_host_process_exit
test_usage:
 mov edi,64
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
