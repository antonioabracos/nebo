; Nebo Assembly — MF024 behaviors, effects and semantic control contracts
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/behavior/behavior_table.inc"
%include "compiler/semantic/effect/effect_classifier.inc"
%include "compiler/semantic/control/control_validator.inc"

extern neboc_behavior_classify
extern neboc_effect_classify
extern neboc_control_validate
extern neboc_host_process_exit

%macro ARG 6
 dq %1,%2,%3,%4,%5,%6
%endmacro
%macro CTRL 7
 dq %1,%2,%3,%4,%5,%6,%7
%endmacro
%macro EFF 5
 dq %1,%2,%3,%4,%5
%endmacro

section .rodata
align 8
behavior_middle:
 ARG NEBOC_ARGUMENT_KIND_POSITIONAL,NEBOC_TYPE_ID_INT,0,0,NEBOC_EFFECT_ID_PURE,11
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,NEBOC_BEHAVIOR_KIND_COLOR,NEBOC_COLOR_RED,NEBOC_EFFECT_ID_PURE,12
 ARG NEBOC_ARGUMENT_KIND_POSITIONAL,NEBOC_TYPE_ID_TEXT,0,0,NEBOC_EFFECT_ID_PURE,13
behavior_start:
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,NEBOC_BEHAVIOR_KIND_COLOR,NEBOC_COLOR_RED,NEBOC_EFFECT_ID_PURE,21
 ARG NEBOC_ARGUMENT_KIND_POSITIONAL,NEBOC_TYPE_ID_INT,0,0,NEBOC_EFFECT_ID_PURE,22
 ARG NEBOC_ARGUMENT_KIND_POSITIONAL,NEBOC_TYPE_ID_TEXT,0,0,NEBOC_EFFECT_ID_PURE,23
behavior_end:
 ARG NEBOC_ARGUMENT_KIND_POSITIONAL,NEBOC_TYPE_ID_INT,0,0,NEBOC_EFFECT_ID_PURE,22
 ARG NEBOC_ARGUMENT_KIND_POSITIONAL,NEBOC_TYPE_ID_TEXT,0,0,NEBOC_EFFECT_ID_PURE,23
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,NEBOC_BEHAVIOR_KIND_COLOR,NEBOC_COLOR_RED,NEBOC_EFFECT_ID_PURE,21
behavior_unsupported:
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,2,1,NEBOC_EFFECT_ID_PURE,31
behavior_conflict:
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,NEBOC_BEHAVIOR_KIND_COLOR,NEBOC_COLOR_RED,NEBOC_EFFECT_ID_PURE,41
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,NEBOC_BEHAVIOR_KIND_COLOR,NEBOC_COLOR_RED,NEBOC_EFFECT_ID_PURE,42
behavior_effectful:
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,NEBOC_BEHAVIOR_KIND_COLOR,NEBOC_COLOR_RED,NEBOC_EFFECT_ID_CONSOLE,51
behavior_red:
 ARG NEBOC_ARGUMENT_KIND_BEHAVIOR,0,NEBOC_BEHAVIOR_KIND_COLOR,NEBOC_COLOR_RED,NEBOC_EFFECT_ID_PURE,61

align 8
control_and:
 CTRL NEBOC_CONTROL_KIND_LOGICAL_AND,NEBOC_TYPE_ID_BOOL,NEBOC_CONTROL_BOOL_FALSE,0,0,0,71
control_or:
 CTRL NEBOC_CONTROL_KIND_LOGICAL_OR,NEBOC_TYPE_ID_BOOL,NEBOC_CONTROL_BOOL_TRUE,0,0,0,72
control_bad:
 CTRL NEBOC_CONTROL_KIND_IF,NEBOC_TYPE_ID_INT,NEBOC_CONTROL_BOOL_UNKNOWN,1,2,3,73
control_scope:
 CTRL NEBOC_CONTROL_KIND_IF,NEBOC_TYPE_ID_BOOL,NEBOC_CONTROL_BOOL_UNKNOWN,1,2,3,74

align 8
empty_effect_pool: dq 0
effect_console_pool: dq NEBOC_EFFECT_ID_CONSOLE
effect_scan_pool: dq NEBOC_EFFECT_ID_SCAN
effect_pure:
 EFF NEBOC_EFFECT_ID_PURE,0,0,NEBOC_EFFECT_FUNCTION_FLAG_NONE,81
effect_console:
 EFF NEBOC_EFFECT_ID_PURE,0,1,NEBOC_EFFECT_FUNCTION_FLAG_THREAD_CAPABLE,82
effect_scan:
 EFF NEBOC_EFFECT_ID_PURE,0,1,NEBOC_EFFECT_FUNCTION_FLAG_THREAD_CAPABLE,83
effect_bad_thread:
 EFF NEBOC_EFFECT_ID_PURE,0,0,NEBOC_EFFECT_FUNCTION_FLAG_THREAD_CAPABLE,84

section .bss align=16
behavior_request: resb NEBOC_BEHAVIOR_REQUEST_SIZE
behavior_positionals: resq 8
behavior_entries: resb NEBOC_BEHAVIOR_ENTRY_SIZE*8
control_request: resb NEBOC_CONTROL_REQUEST_SIZE
control_outputs: resb NEBOC_CONTROL_OUTPUT_SIZE*4
effect_request: resb NEBOC_EFFECT_REQUEST_SIZE
effect_outputs: resq 4
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
 cmp eax,9
 jbe .dispatch
 ; scenarios 10..16 encoded as A..G
 movzx eax,byte [rdx]
 cmp eax,'A'
 jb test_usage
 cmp eax,'G'
 ja test_usage
 sub eax,'A'-10
.dispatch:
 cmp eax,1
 je case1
 cmp eax,2
 je case2
 cmp eax,3
 je case3
 cmp eax,4
 je case4
 cmp eax,5
 je case5
 cmp eax,6
 je case6
 cmp eax,7
 je case7
 cmp eax,8
 je case8
 cmp eax,9
 je case9
 cmp eax,10
 je case10
 cmp eax,11
 je case11
 cmp eax,12
 je case12
 cmp eax,13
 je case13
 cmp eax,14
 je case14
 cmp eax,15
 je case15
 cmp eax,16
 je case16
 jmp test_usage

case1:
 lea rdi,[rel behavior_middle]
 mov esi,3
 call run_behavior
 test eax,eax
 jnz test_fail
 cmp qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel behavior_positionals],11
 jne test_fail
 cmp qword [rel behavior_positionals+8],13
 jne test_fail
 cmp qword [rel behavior_entries+NEBOC_BEHAVIOR_ENTRY_SOURCE_INDEX_OFFSET],1
 jne test_fail
 jmp test_pass
case2:
 lea rdi,[rel behavior_start]
 mov esi,3
 call run_behavior
 test eax,eax
 jnz test_fail
 cmp qword [rel behavior_positionals],22
 jne test_fail
 cmp qword [rel behavior_positionals+8],23
 jne test_fail
 lea rdi,[rel behavior_end]
 mov esi,3
 call run_behavior
 test eax,eax
 jnz test_fail
 cmp qword [rel behavior_positionals],22
 jne test_fail
 cmp qword [rel behavior_positionals+8],23
 jne test_fail
 jmp test_pass
case3:
 lea rdi,[rel behavior_middle]
 mov esi,3
 call run_behavior
 test eax,eax
 jnz test_fail
 cmp qword [rel behavior_entries+NEBOC_BEHAVIOR_ENTRY_APPLICATION_ORDER_OFFSET],0
 jne test_fail
 cmp qword [rel behavior_entries+NEBOC_BEHAVIOR_ENTRY_NODE_ID_OFFSET],12
 jne test_fail
 jmp test_pass
case4:
 lea rdi,[rel behavior_red]
 mov esi,1
 call run_behavior_without_support
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_BEHAVIOR_UNSUPPORTED
 jne test_fail
 jmp test_pass
case5:
 lea rdi,[rel behavior_conflict]
 mov esi,2
 call run_behavior
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_BEHAVIOR_CONFLICT
 jne test_fail
 cmp qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ERROR_INDEX_OFFSET],1
 jne test_fail
 jmp test_pass
case6:
 lea rdi,[rel behavior_effectful]
 mov esi,1
 call run_behavior
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_BEHAVIOR_EFFECTFUL
 jne test_fail
 jmp test_pass
case7:
 lea rdi,[rel behavior_red]
 mov esi,1
 call run_behavior
 test eax,eax
 jnz test_fail
 cmp qword [rel behavior_entries+NEBOC_BEHAVIOR_ENTRY_KIND_OFFSET],NEBOC_BEHAVIOR_KIND_COLOR
 jne test_fail
 cmp qword [rel behavior_entries+NEBOC_BEHAVIOR_ENTRY_VALUE_OFFSET],NEBOC_COLOR_RED
 jne test_fail
 jmp test_pass
case8:
 lea rdi,[rel behavior_middle]
 mov esi,3
 call run_behavior
 test eax,eax
 jnz test_fail
 mov rax,[rel behavior_request+NEBOC_BEHAVIOR_REQUEST_HASH_OFFSET]
 test rax,rax
 jz test_fail
 mov [rel saved_hash],rax
 lea rdi,[rel behavior_middle]
 mov esi,3
 call run_behavior
 test eax,eax
 jnz test_fail
 mov rax,[rel behavior_request+NEBOC_BEHAVIOR_REQUEST_HASH_OFFSET]
 cmp rax,[rel saved_hash]
 jne test_fail
 jmp test_pass
case9:
 lea rdi,[rel control_and]
 mov esi,1
 call run_control
 test eax,eax
 jnz test_fail
 cmp qword [rel control_outputs+NEBOC_CONTROL_OUTPUT_ANNOTATION_OFFSET],NEBOC_CONTROL_ANNOTATION_SKIP_RHS_WHEN_FALSE
 jne test_fail
 cmp qword [rel control_outputs+NEBOC_CONTROL_OUTPUT_EXECUTE_RHS_OFFSET],0
 jne test_fail
 jmp test_pass
case10:
 lea rdi,[rel control_or]
 mov esi,1
 call run_control
 test eax,eax
 jnz test_fail
 cmp qword [rel control_outputs+NEBOC_CONTROL_OUTPUT_ANNOTATION_OFFSET],NEBOC_CONTROL_ANNOTATION_SKIP_RHS_WHEN_TRUE
 jne test_fail
 cmp qword [rel control_outputs+NEBOC_CONTROL_OUTPUT_EXECUTE_RHS_OFFSET],0
 jne test_fail
 jmp test_pass
case11:
 lea rdi,[rel control_bad]
 mov esi,1
 call run_control
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel control_request+NEBOC_CONTROL_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_CONTROL_CONDITION_TYPE
 jne test_fail
 jmp test_pass
case12:
 lea rdi,[rel control_scope]
 mov esi,1
 call run_control
 test eax,eax
 jnz test_fail
 cmp qword [rel control_outputs+NEBOC_CONTROL_OUTPUT_THEN_SCOPE_OFFSET],2
 jne test_fail
 cmp qword [rel control_outputs+NEBOC_CONTROL_OUTPUT_ELSE_SCOPE_OFFSET],3
 jne test_fail
 jmp test_pass
case13:
 lea rdi,[rel effect_pure]
 mov esi,1
 lea rdx,[rel empty_effect_pool]
 xor ecx,ecx
 call run_effect
 test eax,eax
 jnz test_fail
 cmp qword [rel effect_outputs],NEBOC_EFFECT_ID_PURE
 jne test_fail
 jmp test_pass
case14:
 lea rdi,[rel effect_console]
 mov esi,1
 lea rdx,[rel effect_console_pool]
 mov ecx,1
 call run_effect
 test eax,eax
 jnz test_fail
 cmp qword [rel effect_outputs],NEBOC_EFFECT_ID_CONSOLE
 jne test_fail
 jmp test_pass
case15:
 lea rdi,[rel effect_scan]
 mov esi,1
 lea rdx,[rel effect_scan_pool]
 mov ecx,1
 call run_effect
 test eax,eax
 jnz test_fail
 cmp qword [rel effect_outputs],NEBOC_EFFECT_ID_SCAN
 jne test_fail
 jmp test_pass
case16:
 lea rdi,[rel effect_bad_thread]
 mov esi,1
 lea rdx,[rel empty_effect_pool]
 xor ecx,ecx
 call run_effect
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel effect_request+NEBOC_EFFECT_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_EFFECT_THREAD_CAPABILITY
 jne test_fail
 jmp test_pass

; run_behavior(arguments*, count)
run_behavior:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 lea rdi,[rel behavior_request]
 xor eax,eax
 mov ecx,NEBOC_BEHAVIOR_REQUEST_QWORDS
 rep stosq
 lea rdi,[rel behavior_positionals]
 mov ecx,8
 rep stosq
 lea rdi,[rel behavior_entries]
 mov ecx,NEBOC_BEHAVIOR_ENTRY_QWORDS*8
 rep stosq
 mov [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ARGUMENTS_OFFSET],r12
 mov [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ARGUMENT_COUNT_OFFSET],r13
 lea rax,[rel behavior_positionals]
 mov [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_NODES_OFFSET],rax
 mov qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_POSITIONAL_CAPACITY_OFFSET],8
 lea rax,[rel behavior_entries]
 mov [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ENTRIES_OFFSET],rax
 mov qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ENTRY_CAPACITY_OFFSET],8
 mov qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ACCEPTED_MASK_OFFSET],NEBOC_BEHAVIOR_MASK_COLOR
 lea rdi,[rel behavior_request]
 call neboc_behavior_classify
 pop r13
 pop r12
 ret

run_behavior_without_support:
 call run_behavior
 ; Re-run after overriding the outer function's accepted behavior contract.
 mov qword [rel behavior_request+NEBOC_BEHAVIOR_REQUEST_ACCEPTED_MASK_OFFSET],0
 lea rdi,[rel behavior_request]
 call neboc_behavior_classify
 ret

; run_control(inputs*, count)
run_control:
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 lea rdi,[rel control_request]
 xor eax,eax
 mov ecx,NEBOC_CONTROL_REQUEST_QWORDS
 rep stosq
 lea rdi,[rel control_outputs]
 mov ecx,NEBOC_CONTROL_OUTPUT_QWORDS*4
 rep stosq
 mov [rel control_request+NEBOC_CONTROL_REQUEST_INPUTS_OFFSET],r12
 mov [rel control_request+NEBOC_CONTROL_REQUEST_INPUT_COUNT_OFFSET],r13
 lea rax,[rel control_outputs]
 mov [rel control_request+NEBOC_CONTROL_REQUEST_OUTPUTS_OFFSET],rax
 mov qword [rel control_request+NEBOC_CONTROL_REQUEST_OUTPUT_CAPACITY_OFFSET],4
 lea rdi,[rel control_request]
 call neboc_control_validate
 pop r13
 pop r12
 ret

; run_effect(inputs*, count, pool*, pool_count)
run_effect:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 lea rdi,[rel effect_request]
 xor eax,eax
 mov ecx,NEBOC_EFFECT_REQUEST_QWORDS
 rep stosq
 lea rdi,[rel effect_outputs]
 mov ecx,4
 rep stosq
 mov [rel effect_request+NEBOC_EFFECT_REQUEST_INPUTS_OFFSET],r12
 mov [rel effect_request+NEBOC_EFFECT_REQUEST_INPUT_COUNT_OFFSET],r13
 mov [rel effect_request+NEBOC_EFFECT_REQUEST_CALLEE_EFFECTS_OFFSET],r14
 mov [rel effect_request+NEBOC_EFFECT_REQUEST_CALLEE_EFFECT_COUNT_OFFSET],r15
 lea rax,[rel effect_outputs]
 mov [rel effect_request+NEBOC_EFFECT_REQUEST_OUTPUTS_OFFSET],rax
 mov qword [rel effect_request+NEBOC_EFFECT_REQUEST_OUTPUT_CAPACITY_OFFSET],4
 lea rdi,[rel effect_request]
 call neboc_effect_classify
 pop r15
 pop r14
 pop r13
 pop r12
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
