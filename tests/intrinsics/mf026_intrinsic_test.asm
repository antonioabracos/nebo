; Nebo Assembly — MF026 intrinsic infrastructure native scenarios
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/effect/effect_classifier.inc"
%include "compiler/semantic/behavior/behavior_table.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/database/semantic_database.inc"

extern neboc_type_table_init
extern neboc_type_table_declare_builtins
extern neboc_type_table_declare_intrinsic_types
extern neboc_type_table_get
extern neboc_type_table_freeze
extern neboc_intrinsic_table_init
extern neboc_intrinsic_table_declare_v0_1
extern neboc_intrinsic_table_get
extern neboc_intrinsic_table_freeze
extern neboc_intrinsic_table_validate_runtime_contracts
extern neboc_intrinsic_resolve
extern neboc_semantic_database_attach_intrinsics
extern neboc_host_process_exit

global _start

section .bss align=16
type_entries_a: resb NEBOC_TYPE_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
type_entries_b: resb NEBOC_TYPE_MAX_COUNT * NEBOC_TYPE_ENTRY_SIZE
type_table_a: resb NEBOC_TYPE_TABLE_SIZE
type_table_b: resb NEBOC_TYPE_TABLE_SIZE
intrinsic_entries_a: resb NEBOC_INTRINSIC_COUNT * NEBOC_INTRINSIC_ENTRY_SIZE
intrinsic_entries_b: resb NEBOC_INTRINSIC_COUNT * NEBOC_INTRINSIC_ENTRY_SIZE
intrinsic_table_a: resb NEBOC_INTRINSIC_TABLE_SIZE
intrinsic_table_b: resb NEBOC_INTRINSIC_TABLE_SIZE
request: resb NEBOC_INTRINSIC_REQUEST_SIZE
database: resb NEBOC_SEMANTIC_DATABASE_SIZE
out_ptr: resq 1

section .text
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rax,[rsp+16]
 cmp byte [rax+1],0
 jne test_usage
 movzx eax,byte [rax]
 sub eax,'0'
 cmp eax,1
 jb test_usage
 cmp eax,9
 ja test_usage
 mov r12d,eax
 call setup_all
 test eax,eax
 jnz test_fail
 cmp r12d,1
 je scenario_1
 cmp r12d,2
 je scenario_2
 cmp r12d,3
 je scenario_3
 cmp r12d,4
 je scenario_4
 cmp r12d,5
 je scenario_5
 cmp r12d,6
 je scenario_6
 cmp r12d,7
 je scenario_7
 cmp r12d,8
 je scenario_8
 jmp scenario_9

scenario_1:
 cmp qword [rel type_table_a+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_MAX_COUNT
 jne test_fail
 lea rdi,[rel type_table_a]
 mov esi,NEBOC_TYPE_ID_COLOR
 lea rdx,[rel out_ptr]
 call neboc_type_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_COLOR
 jne test_fail
 lea rdi,[rel type_table_a]
 mov esi,NEBOC_TYPE_ID_BEHAVIOR_FOREGROUND_COLOR
 lea rdx,[rel out_ptr]
 call neboc_type_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_BEHAVIOR
 jne test_fail
 cmp qword [rbx+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_COLOR
 jne test_fail
 jmp test_pass

scenario_2:
 cmp qword [rel intrinsic_table_a+NEBOC_INTRINSIC_TABLE_COUNT_OFFSET],NEBOC_INTRINSIC_COUNT
 jne test_fail
 lea rdi,[rel intrinsic_table_a]
 call neboc_intrinsic_table_validate_runtime_contracts
 test eax,eax
 jnz test_fail
 lea rdi,[rel intrinsic_table_a]
 mov esi,NEBOC_INTRINSIC_ID_COLOR_BEHAVIOR
 lea rdx,[rel out_ptr]
 call neboc_intrinsic_table_get
 test eax,eax
 jnz test_fail
 mov rbx,[rel out_ptr]
 cmp qword [rbx+NEBOC_INTRINSIC_ENTRY_RUNTIME_CONTRACT_ID_OFFSET],NEBOC_RUNTIME_CONTRACT_COLOR_FOREGROUND_DESCRIPTOR
 jne test_fail
 jmp test_pass

scenario_3:
 mov edi,NEBOC_INTRINSIC_NAME_CONSOLE
 mov esi,NEBOC_TYPE_ID_TEXT
 mov edx,NEBOC_BEHAVIOR_MASK_COLOR
 call resolve_signature
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_CONSOLE
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_CONSOLE
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_EFFECT_ID_OFFSET],NEBOC_EFFECT_ID_CONSOLE
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_RUNTIME_CONTRACT_OFFSET],NEBOC_RUNTIME_CONTRACT_TEXT_CONSOLE
 jne test_fail
 jmp test_pass

scenario_4:
 mov edi,NEBOC_INTRINSIC_NAME_CONSOLE
 mov esi,NEBOC_TYPE_ID_INT
 xor edx,edx
 call resolve_signature
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_INT_CONSOLE
 jne test_fail
 mov edi,NEBOC_INTRINSIC_NAME_CONSOLE
 mov esi,NEBOC_TYPE_ID_BOOL
 xor edx,edx
 call resolve_signature
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_BOOL_CONSOLE
 jne test_fail
 jmp test_pass

scenario_5:
 mov edi,NEBOC_INTRINSIC_NAME_SCAN
 mov esi,NEBOC_TYPE_ID_TEXT
 xor edx,edx
 call resolve_signature
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_TEXT_SCAN
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_PENDING_TEXT
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_EFFECT_ID_OFFSET],NEBOC_EFFECT_ID_SCAN
 jne test_fail
 mov rax,[rel request+NEBOC_INTRINSIC_REQUEST_OUT_CONCURRENCY_OFFSET]
 and eax,NEBOC_INTRINSIC_CONCURRENCY_THREAD_CAPABLE | NEBOC_INTRINSIC_CONCURRENCY_PENDING_RESULT
 cmp eax,NEBOC_INTRINSIC_CONCURRENCY_THREAD_CAPABLE | NEBOC_INTRINSIC_CONCURRENCY_PENDING_RESULT
 jne test_fail
 jmp test_pass

scenario_6:
 mov edi,NEBOC_INTRINSIC_NAME_SCAN
 mov esi,NEBOC_TYPE_ID_CONSOLE
 xor edx,edx
 call resolve_signature
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_CONSOLE_SCAN
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_RUNTIME_CONTRACT_OFFSET],NEBOC_RUNTIME_CONTRACT_CONSOLE_SCAN_INLINE
 jne test_fail
 jmp test_pass

scenario_7:
 mov edi,NEBOC_INTRINSIC_NAME_COLOR
 mov esi,NEBOC_TYPE_ID_COLOR
 xor edx,edx
 call resolve_signature
 test eax,eax
 jnz test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_INTRINSIC_ID_OFFSET],NEBOC_INTRINSIC_ID_COLOR_BEHAVIOR
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_BEHAVIOR_FOREGROUND_COLOR
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_OUT_EFFECT_ID_OFFSET],NEBOC_EFFECT_ID_PURE
 jne test_fail
 mov rax,[rel request+NEBOC_INTRINSIC_REQUEST_OUT_FLAGS_OFFSET]
 test rax,NEBOC_INTRINSIC_FLAG_DESCRIPTOR
 jz test_fail
 jmp test_pass

scenario_8:
 mov edi,NEBOC_INTRINSIC_NAME_SCAN
 mov esi,NEBOC_TYPE_ID_TEXT
 mov edx,NEBOC_BEHAVIOR_MASK_COLOR
 call resolve_signature
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_ERROR_CODE_OFFSET],NEBOC_INTRINSIC_ERROR_UNSUPPORTED_BEHAVIOR
 jne test_fail
 mov edi,NEBOC_INTRINSIC_NAME_CONSOLE
 mov esi,NEBOC_TYPE_ID_CONSOLE
 xor edx,edx
 call resolve_signature
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_INTRINSIC_REQUEST_ERROR_CODE_OFFSET],NEBOC_INTRINSIC_ERROR_NO_MATCH
 jne test_fail
 jmp test_pass

scenario_9:
 lea rdi,[rel database]
 lea rsi,[rel intrinsic_table_a]
 lea rdx,[rel type_table_a]
 call neboc_semantic_database_attach_intrinsics
 test eax,eax
 jnz test_fail
 lea rax,[rel intrinsic_table_a]
 cmp [rel database+NEBOC_SEMANTIC_DATABASE_INTRINSIC_TABLE_OFFSET],rax
 jne test_fail
 lea rax,[rel type_table_a]
 cmp [rel database+NEBOC_SEMANTIC_DATABASE_TYPE_TABLE_OFFSET],rax
 jne test_fail
 mov rax,[rel intrinsic_table_a+NEBOC_INTRINSIC_TABLE_HASH_OFFSET]
 cmp rax,[rel intrinsic_table_b+NEBOC_INTRINSIC_TABLE_HASH_OFFSET]
 jne test_fail
 mov rax,[rel type_table_a+NEBOC_TYPE_TABLE_HASH_OFFSET]
 cmp rax,[rel type_table_b+NEBOC_TYPE_TABLE_HASH_OFFSET]
 jne test_fail
 jmp test_pass

; resolve_signature(name_id, receiver_type, behavior_mask)
resolve_signature:
 mov r8,rdi
 mov r9,rsi
 mov r10,rdx
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,NEBOC_INTRINSIC_REQUEST_QWORDS
.clear_request:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .clear_request
 mov [rel request+NEBOC_INTRINSIC_REQUEST_NAME_ID_OFFSET],r8
 mov [rel request+NEBOC_INTRINSIC_REQUEST_RECEIVER_TYPE_OFFSET],r9
 mov qword [rel request+NEBOC_INTRINSIC_REQUEST_POSITIONAL_COUNT_OFFSET],0
 mov [rel request+NEBOC_INTRINSIC_REQUEST_BEHAVIOR_MASK_OFFSET],r10
 lea rdi,[rel intrinsic_table_a]
 lea rsi,[rel request]
 call neboc_intrinsic_resolve
 ret

setup_all:
 lea rdi,[rel type_table_a]
 lea rsi,[rel type_entries_a]
 mov edx,NEBOC_TYPE_MAX_COUNT
 call neboc_type_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel type_table_a]
 call neboc_type_table_declare_builtins
 test eax,eax
 jnz .done
 lea rdi,[rel type_table_a]
 call neboc_type_table_declare_intrinsic_types
 test eax,eax
 jnz .done
 lea rdi,[rel type_table_a]
 call neboc_type_table_freeze
 test eax,eax
 jnz .done
 lea rdi,[rel type_table_b]
 lea rsi,[rel type_entries_b]
 mov edx,NEBOC_TYPE_MAX_COUNT
 call neboc_type_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel type_table_b]
 call neboc_type_table_declare_builtins
 test eax,eax
 jnz .done
 lea rdi,[rel type_table_b]
 call neboc_type_table_declare_intrinsic_types
 test eax,eax
 jnz .done
 lea rdi,[rel type_table_b]
 call neboc_type_table_freeze
 test eax,eax
 jnz .done
 lea rdi,[rel intrinsic_table_a]
 lea rsi,[rel intrinsic_entries_a]
 mov edx,NEBOC_INTRINSIC_COUNT
 call neboc_intrinsic_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel intrinsic_table_a]
 call neboc_intrinsic_table_declare_v0_1
 test eax,eax
 jnz .done
 lea rdi,[rel intrinsic_table_a]
 call neboc_intrinsic_table_freeze
 test eax,eax
 jnz .done
 lea rdi,[rel intrinsic_table_b]
 lea rsi,[rel intrinsic_entries_b]
 mov edx,NEBOC_INTRINSIC_COUNT
 call neboc_intrinsic_table_init
 test eax,eax
 jnz .done
 lea rdi,[rel intrinsic_table_b]
 call neboc_intrinsic_table_declare_v0_1
 test eax,eax
 jnz .done
 lea rdi,[rel intrinsic_table_b]
 call neboc_intrinsic_table_freeze
.done:
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
