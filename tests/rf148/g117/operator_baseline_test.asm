; RF148-G117 independent native test for snapshot, matrix, parity and freeze.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/operators/operator_protocol.inc"
%include "compiler/semantic/operators/operator_baseline.inc"

extern neboc_capture_current_operator_state
extern neboc_run_operator_context_matrix
extern neboc_compare_operator_mode_parity
extern neboc_freeze_operator_baseline

%define DIAG_TYPE_MISMATCH 0x117001
%define DIAG_QUESTION_FAMILY 0x117002
%define SENTINEL 0x5a5a5a5a5a5a5a5a

%macro CASE 12
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10,%11,%12
%endmacro

%macro PARITY 10
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10
%endmacro

section .rodata align=8
context_cases:
 CASE 1,NEBOC_TOKEN_PLUS,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,NEBOC_OPERATOR_CONTEXT_EXPRESSION,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,0,0,NEBOC_OPERATOR_MODE_ALL,NEBOC_OPERATOR_MODE_ALL,NEBOC_OPERATOR_CASE_FLAG_POSITIVE
 CASE 2,NEBOC_TOKEN_EQUAL_EQUAL,NEBOC_TYPE_ID_TEXT,NEBOC_TYPE_ID_TEXT,NEBOC_OPERATOR_CONTEXT_EXPRESSION,NEBOC_TYPE_ID_BOOL,NEBOC_TYPE_ID_BOOL,0,0,NEBOC_OPERATOR_MODE_ALL,NEBOC_OPERATOR_MODE_ALL,NEBOC_OPERATOR_CASE_FLAG_POSITIVE|NEBOC_OPERATOR_CASE_FLAG_EQUALITY
 CASE 3,NEBOC_TOKEN_PLUS,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_BOOL,NEBOC_OPERATOR_CONTEXT_STATEMENT,0,0,DIAG_TYPE_MISMATCH,DIAG_TYPE_MISMATCH,NEBOC_OPERATOR_MODE_TRI,NEBOC_OPERATOR_MODE_TRI,NEBOC_OPERATOR_CASE_FLAG_NEGATIVE|NEBOC_OPERATOR_CASE_FLAG_DISCARDED
 CASE 4,NEBOC_TOKEN_QUESTION,NEBOC_TYPE_ID_BOOL,NEBOC_TYPE_ID_INT,NEBOC_OPERATOR_CONTEXT_EXPRESSION,0,0,DIAG_QUESTION_FAMILY,DIAG_QUESTION_FAMILY,NEBOC_OPERATOR_MODE_TRI,NEBOC_OPERATOR_MODE_TRI,NEBOC_OPERATOR_CASE_FLAG_NEGATIVE|NEBOC_OPERATOR_CASE_FLAG_QUESTION_FAMILY
context_case_count equ ($-context_cases)/NEBOC_OPERATOR_CASE_SIZE

invalid_case:
 CASE 9,NEBOC_TOKEN_LESS,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_BOOL,NEBOC_OPERATOR_CONTEXT_EXPRESSION,NEBOC_TYPE_ID_BOOL,NEBOC_TYPE_ID_INT,0,0,NEBOC_OPERATOR_MODE_TRI,NEBOC_OPERATOR_MODE_TRI,NEBOC_OPERATOR_CASE_FLAG_POSITIVE|NEBOC_OPERATOR_CASE_FLAG_ORDERING

parity_cases:
 PARITY 1,NEBOC_OPERATOR_MODE_ALL,0x13f00d,0x13f00d,0x13f00d,0x13f00d,0,0,0,NEBOC_OPERATOR_PARITY_FLAG_POSITIVE|NEBOC_OPERATOR_PARITY_FLAG_NATIVE_REQUIRED
 PARITY 2,NEBOC_OPERATOR_MODE_TRI,0,0,0,0,DIAG_TYPE_MISMATCH,DIAG_TYPE_MISMATCH,DIAG_TYPE_MISMATCH,NEBOC_OPERATOR_PARITY_FLAG_NEGATIVE
parity_case_count equ ($-parity_cases)/NEBOC_OPERATOR_PARITY_SIZE

section .bss align=16
snapshot: resb NEBOC_OPERATOR_SNAPSHOT_SIZE
matrix: resb NEBOC_OPERATOR_MATRIX_SIZE
parity: resb NEBOC_OPERATOR_PARITY_SUMMARY_SIZE
freeze: resb NEBOC_OPERATOR_FREEZE_SIZE
atomic_summary: resb NEBOC_OPERATOR_MATRIX_SIZE
empty_matrix: resb NEBOC_OPERATOR_MATRIX_SIZE
atomic_freeze: resb NEBOC_OPERATOR_FREEZE_SIZE

section .text
global _start
_start:
 lea rdi,[rel snapshot]
 call neboc_capture_current_operator_state
 test eax,eax
 jnz .fail
 cmp qword [rel snapshot+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_ENTRIES_OFFSET],11
 jne .fail
 cmp qword [rel snapshot+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_LEXEMES_OFFSET],15
 jne .fail
 cmp qword [rel snapshot+NEBOC_OPERATOR_SNAPSHOT_PROTOCOLS_OFFSET],15
 jne .fail
 cmp qword [rel snapshot+NEBOC_OPERATOR_SNAPSHOT_PRECEDENCE_ROWS_OFFSET],NEBOC_OPERATOR_BASELINE_PRECEDENCE_ROWS
 jne .fail
 cmp qword [rel snapshot+NEBOC_OPERATOR_SNAPSHOT_IMPLEMENTATIONS_OFFSET],17
 jne .fail
 cmp qword [rel snapshot+NEBOC_OPERATOR_SNAPSHOT_NEW_PUBLIC_ENTRIES_OFFSET],0
 jne .fail

 lea rdi,[rel context_cases]
 mov esi,context_case_count
 lea rdx,[rel matrix]
 call neboc_run_operator_context_matrix
 test eax,eax
 jnz .fail
 cmp qword [rel matrix+NEBOC_OPERATOR_MATRIX_CASES_OFFSET],context_case_count
 jne .fail
 cmp qword [rel matrix+NEBOC_OPERATOR_MATRIX_POSITIVE_OFFSET],2
 jne .fail
 cmp qword [rel matrix+NEBOC_OPERATOR_MATRIX_NEGATIVE_OFFSET],2
 jne .fail

 lea rdi,[rel parity_cases]
 mov esi,parity_case_count
 lea rdx,[rel parity]
 call neboc_compare_operator_mode_parity
 test eax,eax
 jnz .fail

 lea rdi,[rel snapshot]
 lea rsi,[rel matrix]
 lea rdx,[rel parity]
 lea rcx,[rel freeze]
 call neboc_freeze_operator_baseline
 test eax,eax
 jnz .fail
 cmp qword [rel freeze+NEBOC_OPERATOR_FREEZE_FLAGS_OFFSET],NEBOC_OPERATOR_FREEZE_REQUIRED_FLAGS
 jne .fail

 lea rdi,[rel atomic_freeze]
 mov rax,SENTINEL
 mov ecx,NEBOC_OPERATOR_FREEZE_SIZE/8
 rep stosq
 lea rdi,[rel snapshot]
 lea rsi,[rel empty_matrix]
 lea rdx,[rel parity]
 lea rcx,[rel atomic_freeze]
 call neboc_freeze_operator_baseline
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 lea rdi,[rel atomic_freeze]
 mov rax,SENTINEL
 mov ecx,NEBOC_OPERATOR_FREEZE_SIZE/8
.freeze_atomic_loop:
 cmp [rdi],rax
 jne .fail
 add rdi,8
 dec ecx
 jnz .freeze_atomic_loop

 lea rdi,[rel atomic_summary]
 mov rax,SENTINEL
 mov ecx,NEBOC_OPERATOR_MATRIX_SIZE/8
 rep stosq
 lea rdi,[rel invalid_case]
 mov esi,1
 lea rdx,[rel atomic_summary]
 call neboc_run_operator_context_matrix
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 lea rdi,[rel atomic_summary]
 mov rax,SENTINEL
 mov ecx,NEBOC_OPERATOR_MATRIX_SIZE/8
.atomic_loop:
 cmp [rdi],rax
 jne .fail
 add rdi,8
 dec ecx
 jnz .atomic_loop

 xor edi,edi
 jmp .exit
.fail:
 mov edi,1
.exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
