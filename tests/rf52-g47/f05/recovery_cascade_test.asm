bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/recovery.inc"
%include "compiler/parser/source_span_recovery.inc"

global _start
extern neboc_diagnostic_bag_new
extern neboc_diagnostic_bag_add
extern neboc_diagnostic_bag_deduplicate
extern neboc_diagnostic_bag_suppress_cascade
extern neboc_diagnostic_bag_sort_canonical
extern neboc_parser_recover
extern neboc_recovery_result_inserted_tokens
extern neboc_recovery_result_skipped_span
extern neboc_analysis_continue_after_error
extern neboc_host_process_exit

section .rodata
code_a: db "NEBO-E0001"
code_a_len equ $-code_a
code_b: db "NEBO-E0002"
code_b_len equ $-code_b

section .data
tokens: dq 10,20,99,30,0
sync_set: dq 99
derived_ids: dq 3
invalid_derived_ids: dq 1

section .bss align=16
diag_a: resb NEBOC_DIAGNOSTIC_SIZE
diag_b: resb NEBOC_DIAGNOSTIC_SIZE
diag_c: resb NEBOC_DIAGNOSTIC_SIZE
diag_d: resb NEBOC_DIAGNOSTIC_SIZE
bag: resb NEBOC_DIAG_BAG_SIZE
entries: resb NEBOC_RECOVERY_DIAG_ENTRY_SIZE*4
scalar: resq 1
recover_request: resb NEBOC_RECOVER_REQUEST_SIZE
recover_result: resb NEBOC_RECOVERY_RESULT_SIZE
slice: resb neboc_recovery_SLICE_SIZE
span: resb NEBOC_SOURCE_SPAN_SIZE

section .text
; init_diag(diag*, code*, code_len, severity, source_id, start)
init_diag:
 mov [rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],rsi
 mov [rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],rdx
 mov [rdi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],rcx
 mov qword [rdi+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_SYNTAX
 mov qword [rdi+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_PARSE
 mov qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 mov qword [rdi+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 mov [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],r8
 mov [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],r9
 lea rax,[r9+1]
 mov [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET],rax
 mov qword [rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],100
 ret

_start:
 sub rsp,8
 lea rdi,[rel diag_a]
 lea rsi,[rel code_a]
 mov edx,code_a_len
 mov ecx,NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 mov r8d,1
 mov r9d,10
 call init_diag
 lea rdi,[rel diag_b]
 lea rsi,[rel code_a]
 mov edx,code_a_len
 mov ecx,NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 mov r8d,1
 mov r9d,10
 call init_diag
 lea rdi,[rel diag_c]
 lea rsi,[rel code_b]
 mov edx,code_b_len
 mov ecx,NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 mov r8d,1
 mov r9d,2
 call init_diag
 lea rdi,[rel diag_d]
 lea rsi,[rel code_b]
 mov edx,code_b_len
 mov ecx,NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 mov r8d,2
 mov r9d,1
 call init_diag

 lea rdi,[rel bag]
 lea rsi,[rel entries]
 mov edx,4
 mov ecx,3
 mov r8d,120
 call neboc_diagnostic_bag_new
 test eax,eax
 jne .fail1
 lea rdi,[rel bag]
 lea rsi,[rel diag_a]
 mov edx,30
 lea rcx,[rel scalar]
 call neboc_diagnostic_bag_add
 test eax,eax
 jne .fail2
 cmp qword [rel scalar],1
 jne .fail3
 lea rdi,[rel bag]
 lea rsi,[rel diag_b]
 mov edx,30
 lea rcx,[rel scalar]
 call neboc_diagnostic_bag_add
 test eax,eax
 jne .fail4
 lea rdi,[rel bag]
 lea rsi,[rel diag_c]
 mov edx,30
 lea rcx,[rel scalar]
 call neboc_diagnostic_bag_add
 test eax,eax
 jne .fail5
 lea rdi,[rel bag]
 lea rsi,[rel diag_d]
 mov edx,30
 lea rcx,[rel scalar]
 call neboc_diagnostic_bag_add
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail6
 cmp qword [rel bag+NEBOC_DIAG_BAG_COUNT_OFFSET],3
 jne .fail7
 cmp qword [rel bag+NEBOC_DIAG_BAG_USED_BYTES_OFFSET],90
 jne .fail8

 lea rdi,[rel bag]
 mov esi,NEBOC_DIAG_DEDUP_STRUCTURAL
 lea rdx,[rel scalar]
 call neboc_diagnostic_bag_deduplicate
 test eax,eax
 jne .fail9
 cmp qword [rel scalar],1
 jne .fail10
 cmp qword [rel bag+NEBOC_DIAG_BAG_VISIBLE_COUNT_OFFSET],2
 jne .fail11
 test qword [rel entries+NEBOC_RECOVERY_DIAG_ENTRY_SIZE+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_DUPLICATE
 jz .fail12

 lea rdi,[rel bag]
 mov esi,1
 lea rdx,[rel invalid_derived_ids]
 mov ecx,1
 call neboc_diagnostic_bag_suppress_cascade
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail13
 cmp qword [rel bag+NEBOC_DIAG_BAG_VISIBLE_COUNT_OFFSET],2
 jne .fail14
 lea rdi,[rel bag]
 mov esi,1
 lea rdx,[rel derived_ids]
 mov ecx,1
 call neboc_diagnostic_bag_suppress_cascade
 test eax,eax
 jne .fail15
 cmp qword [rel bag+NEBOC_DIAG_BAG_VISIBLE_COUNT_OFFSET],1
 jne .fail16
 test qword [rel entries+NEBOC_DIAG_ENTRY_FLAGS_OFFSET],NEBOC_DIAG_ENTRY_DUPLICATE|NEBOC_DIAG_ENTRY_CASCADE
 jnz .fail17
 lea rdi,[rel bag]
 call neboc_diagnostic_bag_sort_canonical
 test eax,eax
 jne .fail18
 lea rax,[rel diag_c]
 cmp [rel entries+NEBOC_DIAG_ENTRY_DIAGNOSTIC_OFFSET],rax
 jne .fail19

 lea rdi,[rel recover_request]
 mov ecx,NEBOC_RECOVER_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel tokens]
 mov [rel recover_request+NEBOC_RECOVER_TOKENS_OFFSET],rax
 mov qword [rel recover_request+NEBOC_RECOVER_TOKEN_COUNT_OFFSET],5
 mov qword [rel recover_request+NEBOC_RECOVER_STRATEGY_OFFSET],NEBOC_RECOVER_SKIP_TO_SYNC
 lea rax,[rel sync_set]
 mov [rel recover_request+NEBOC_RECOVER_SYNC_SET_OFFSET],rax
 mov qword [rel recover_request+NEBOC_RECOVER_SYNC_COUNT_OFFSET],1
 mov qword [rel recover_request+NEBOC_RECOVER_SOURCE_ID_OFFSET],7
 mov qword [rel recover_request+NEBOC_RECOVER_MAX_STEPS_OFFSET],4
 lea rdi,[rel recover_request]
 lea rsi,[rel recover_result]
 call neboc_parser_recover
 test eax,eax
 jne .fail20
 cmp qword [rel recover_result+NEBOC_RECOVERY_RESULT_NEXT_CURSOR_OFFSET],2
 jne .fail21
 cmp qword [rel recover_result+NEBOC_RECOVERY_RESULT_CODEGEN_VALID_OFFSET],0
 jne .fail22
 lea rdi,[rel recover_result]
 lea rsi,[rel span]
 call neboc_recovery_result_skipped_span
 test eax,eax
 jne .fail23
 cmp qword [rel span+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],7
 jne .fail24
 cmp qword [rel span+NEBOC_SOURCE_SPAN_START_OFFSET],0
 jne .fail25
 cmp qword [rel span+NEBOC_SOURCE_SPAN_END_OFFSET],2
 jne .fail26

 mov qword [rel recover_request+NEBOC_RECOVER_CURSOR_OFFSET],2
 mov qword [rel recover_request+NEBOC_RECOVER_STRATEGY_OFFSET],NEBOC_RECOVER_INSERT_TOKEN
 mov qword [rel recover_request+NEBOC_RECOVER_EXPECTED_TOKEN_OFFSET],55
 lea rdi,[rel recover_request]
 lea rsi,[rel recover_result]
 call neboc_parser_recover
 test eax,eax
 jne .fail27
 lea rdi,[rel recover_result]
 lea rsi,[rel slice]
 call neboc_recovery_result_inserted_tokens
 test eax,eax
 jne .fail28
 cmp qword [rel slice+neboc_recovery_SLICE_LENGTH_OFFSET],1
 jne .fail29
 mov rax,[rel slice+NEBOC_SOURCE_MAP_SLICE_POINTER_OFFSET]
 cmp qword [rax],55
 jne .fail30

 mov qword [rel recover_result],0x44556677
 mov qword [rel recover_request+NEBOC_RECOVER_EXPECTED_TOKEN_OFFSET],0
 lea rdi,[rel recover_request]
 lea rsi,[rel recover_result]
 call neboc_parser_recover
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail31
 cmp qword [rel recover_result],0x44556677
 jne .fail32

 mov edi,NEBOC_CONTINUE_KEEP_GOING
 mov esi,NEBOC_ANALYSIS_NODE_VALID|NEBOC_ANALYSIS_NODE_RECOVERED
 lea rdx,[rel scalar]
 call neboc_analysis_continue_after_error
 test eax,eax
 jne .fail33
 cmp qword [rel scalar],0
 jne .fail34
 mov edi,NEBOC_CONTINUE_INDEPENDENT
 mov esi,NEBOC_ANALYSIS_NODE_VALID
 lea rdx,[rel scalar]
 call neboc_analysis_continue_after_error
 test eax,eax
 jne .fail35
 cmp qword [rel scalar],1
 jne .fail36
 mov edi,NEBOC_CONTINUE_STRICT
 mov esi,NEBOC_ANALYSIS_NODE_VALID
 lea rdx,[rel scalar]
 call neboc_analysis_continue_after_error
 test eax,eax
 jne .fail37
 cmp qword [rel scalar],0
 jne .fail38

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 38
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
