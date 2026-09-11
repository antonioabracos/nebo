; RF148-G117 factual operator audit and semantic baseline owner.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/semantic/operators/operator_protocol.inc"
%include "compiler/semantic/operators/operator_baseline.inc"

extern neboc_operator_registry_entry_table
extern neboc_operator_registry_lexeme_table
extern neboc_operator_precedence_table
extern neboc_operator_known_implementations

section .text
; captureCurrentOperatorState(snapshot*) -> StatusCode
; The Git branch/HEAD/tree envelope is captured by the caller. This function
; freezes only facts owned by the live compiler and performs no mutation.
NEBOC_ABI_FUNCTION neboc_capture_current_operator_state
 push r12
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .invalid
 call neboc_operator_registry_entry_table
 mov [rsp],rdx
 mov [rsp+8],rcx
 call neboc_operator_registry_lexeme_table
 mov [rsp+16],rdx
 cmp rcx,[rsp+8]
 jne .internal
 call neboc_operator_precedence_table
 mov [rsp+24],rdx
 call neboc_operator_known_implementations
 test rax,rax
 jz .internal
 test rdx,rdx
 jz .internal
 mov r11,rdx
 cmp qword [rsp],NEBOC_OPERATOR_REGISTRY_ENTRY_COUNT
 jne .internal
 cmp qword [rsp+16],NEBOC_OPERATOR_REGISTRY_LEXEME_COUNT
 jne .internal
 cmp qword [rsp+8],NEBOC_OPERATOR_REGISTRY_SCHEMA_VERSION
 jne .internal

 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_SCHEMA_OFFSET],NEBOC_OPERATOR_BASELINE_SCHEMA_VERSION
 mov rax,[rsp]
 mov [r12+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_ENTRIES_OFFSET],rax
 mov rax,[rsp+16]
 mov [r12+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_LEXEMES_OFFSET],rax
 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_PROTOCOLS_OFFSET],NEBOC_OPERATOR_PROTOCOL_COUNT
 mov rax,[rsp+24]
 mov [r12+NEBOC_OPERATOR_SNAPSHOT_PRECEDENCE_ROWS_OFFSET],rax
 mov [r12+NEBOC_OPERATOR_SNAPSHOT_IMPLEMENTATIONS_OFFSET],r11
 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_MODES_OFFSET],NEBOC_OPERATOR_MODE_ALL
 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_NEW_PUBLIC_ENTRIES_OFFSET],0
 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_OPEN_P0_OFFSET],0
 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_OPEN_P1_OFFSET],0
 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_OPEN_P2_OFFSET],0
 mov qword [r12+NEBOC_OPERATOR_SNAPSHOT_FLAGS_OFFSET],NEBOC_OPERATOR_SNAPSHOT_REQUIRED_FLAGS
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[rsp]
 imul rax,rcx
 xor rax,[rsp+16]
 imul rax,rcx
 xor rax,NEBOC_OPERATOR_PROTOCOL_COUNT
 imul rax,rcx
 xor rax,[rsp+24]
 imul rax,rcx
 xor rax,r11
 imul rax,rcx
 xor rax,NEBOC_OPERATOR_SNAPSHOT_REQUIRED_FLAGS
 imul rax,rcx
 mov [r12+NEBOC_OPERATOR_SNAPSHOT_DIGEST_OFFSET],rax
 xor eax,eax
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r12
 ret

; runOperatorContextMatrix(cases*, count, summary*) -> StatusCode
; SUMMARY is failure-atomic: no byte is written unless every case agrees.
NEBOC_ABI_FUNCTION neboc_run_operator_context_matrix
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .matrix_invalid
 test r13,r13
 jz .matrix_invalid
 test r12,r12
 jz .matrix_invalid
 cmp r12,NEBOC_OPERATOR_BASELINE_MAX_CASES
 ja .matrix_limit
 xor r14d,r14d
 xor r15d,r15d
 mov r10,1469598103934665603
 mov r8,1099511628211
 xor r9d,r9d
.matrix_loop:
 cmp r9,r12
 jae .matrix_commit
 cmp qword [rbx+NEBOC_OPERATOR_CASE_ID_OFFSET],0
 je .matrix_mismatch
 cmp qword [rbx+NEBOC_OPERATOR_CASE_LEFT_TYPE_OFFSET],0
 je .matrix_mismatch
 mov rax,[rbx+NEBOC_OPERATOR_CASE_CONTEXT_OFFSET]
 test rax,rax
 jz .matrix_mismatch
 test rax,~255
 jnz .matrix_mismatch
 mov rax,[rbx+NEBOC_OPERATOR_CASE_EXPECTED_MODES_OFFSET]
 test rax,rax
 jz .matrix_mismatch
 test rax,~NEBOC_OPERATOR_MODE_ALL
 jnz .matrix_mismatch
 cmp rax,[rbx+NEBOC_OPERATOR_CASE_OBSERVED_MODES_OFFSET]
 jne .matrix_mismatch
 mov rax,[rbx+NEBOC_OPERATOR_CASE_EXPECTED_TYPE_OFFSET]
 cmp rax,[rbx+NEBOC_OPERATOR_CASE_OBSERVED_TYPE_OFFSET]
 jne .matrix_mismatch
 mov rax,[rbx+NEBOC_OPERATOR_CASE_EXPECTED_DIAGNOSTIC_OFFSET]
 cmp rax,[rbx+NEBOC_OPERATOR_CASE_OBSERVED_DIAGNOSTIC_OFFSET]
 jne .matrix_mismatch
 mov rcx,[rbx+NEBOC_OPERATOR_CASE_FLAGS_OFFSET]
 test rcx,~NEBOC_OPERATOR_CASE_KNOWN_FLAGS
 jnz .matrix_mismatch
 test rcx,NEBOC_OPERATOR_CASE_FLAG_POSITIVE
 jz .matrix_negative
 test rcx,NEBOC_OPERATOR_CASE_FLAG_NEGATIVE
 jnz .matrix_mismatch
 test rax,rax
 jnz .matrix_mismatch
 cmp qword [rbx+NEBOC_OPERATOR_CASE_EXPECTED_TYPE_OFFSET],0
 je .matrix_mismatch
 inc r14
 jmp .matrix_hash
.matrix_negative:
 test rcx,NEBOC_OPERATOR_CASE_FLAG_NEGATIVE
 jz .matrix_mismatch
 test rax,rax
 jz .matrix_mismatch
 inc r15
.matrix_hash:
 mov rax,[rbx+NEBOC_OPERATOR_CASE_ID_OFFSET]
 xor r10,rax
 imul r10,r8
 mov rax,[rbx+NEBOC_OPERATOR_CASE_TOKEN_OFFSET]
 xor r10,rax
 imul r10,r8
 mov rax,[rbx+NEBOC_OPERATOR_CASE_EXPECTED_TYPE_OFFSET]
 xor r10,rax
 imul r10,r8
 mov rax,[rbx+NEBOC_OPERATOR_CASE_EXPECTED_DIAGNOSTIC_OFFSET]
 xor r10,rax
 imul r10,r8
 mov rax,[rbx+NEBOC_OPERATOR_CASE_EXPECTED_MODES_OFFSET]
 xor r10,rax
 imul r10,r8
 add rbx,NEBOC_OPERATOR_CASE_SIZE
 inc r9
 jmp .matrix_loop
.matrix_commit:
 mov [r13+NEBOC_OPERATOR_MATRIX_CASES_OFFSET],r12
 mov [r13+NEBOC_OPERATOR_MATRIX_PASSED_OFFSET],r12
 mov qword [r13+NEBOC_OPERATOR_MATRIX_FAILURES_OFFSET],0
 mov [r13+NEBOC_OPERATOR_MATRIX_POSITIVE_OFFSET],r14
 mov [r13+NEBOC_OPERATOR_MATRIX_NEGATIVE_OFFSET],r15
 mov [r13+NEBOC_OPERATOR_MATRIX_DIGEST_OFFSET],r10
 xor eax,eax
 jmp .matrix_done
.matrix_mismatch:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .matrix_done
.matrix_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .matrix_done
.matrix_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.matrix_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; compareModeParity(observations*, count, summary*) -> StatusCode
NEBOC_ABI_FUNCTION neboc_compare_operator_mode_parity
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .parity_invalid
 test r13,r13
 jz .parity_invalid
 test r12,r12
 jz .parity_invalid
 cmp r12,NEBOC_OPERATOR_BASELINE_MAX_CASES
 ja .parity_limit
 mov r14,1469598103934665603
 mov r8,1099511628211
 xor r11d,r11d
.parity_loop:
 cmp r11,r12
 jae .parity_commit
 cmp qword [rbx+NEBOC_OPERATOR_PARITY_ID_OFFSET],0
 je .parity_mismatch
 mov rax,[rbx+NEBOC_OPERATOR_PARITY_MODES_OFFSET]
 mov rcx,rax
 and rcx,NEBOC_OPERATOR_MODE_TRI
 cmp rcx,NEBOC_OPERATOR_MODE_TRI
 jne .parity_mismatch
 test rax,~NEBOC_OPERATOR_MODE_ALL
 jnz .parity_mismatch
 mov rcx,[rbx+NEBOC_OPERATOR_PARITY_FLAGS_OFFSET]
 test rcx,~NEBOC_OPERATOR_PARITY_KNOWN_FLAGS
 jnz .parity_mismatch
 test rcx,NEBOC_OPERATOR_PARITY_FLAG_POSITIVE
 jz .parity_negative
 test rcx,NEBOC_OPERATOR_PARITY_FLAG_NEGATIVE
 jnz .parity_mismatch
 mov rdx,[rbx+NEBOC_OPERATOR_PARITY_CHECK_HASH_OFFSET]
 test rdx,rdx
 jz .parity_mismatch
 cmp rdx,[rbx+NEBOC_OPERATOR_PARITY_ASM_HASH_OFFSET]
 jne .parity_mismatch
 cmp rdx,[rbx+NEBOC_OPERATOR_PARITY_BUILD_HASH_OFFSET]
 jne .parity_mismatch
 cmp qword [rbx+NEBOC_OPERATOR_PARITY_CHECK_DIAGNOSTIC_OFFSET],0
 jne .parity_mismatch
 cmp qword [rbx+NEBOC_OPERATOR_PARITY_ASM_DIAGNOSTIC_OFFSET],0
 jne .parity_mismatch
 cmp qword [rbx+NEBOC_OPERATOR_PARITY_BUILD_DIAGNOSTIC_OFFSET],0
 jne .parity_mismatch
 test rcx,NEBOC_OPERATOR_PARITY_FLAG_NATIVE_REQUIRED
 jz .parity_hash
 test rax,NEBOC_OPERATOR_MODE_NATIVE
 jz .parity_mismatch
 cmp rdx,[rbx+NEBOC_OPERATOR_PARITY_NATIVE_HASH_OFFSET]
 jne .parity_mismatch
 jmp .parity_hash
.parity_negative:
 test rcx,NEBOC_OPERATOR_PARITY_FLAG_NEGATIVE
 jz .parity_mismatch
 mov rdx,[rbx+NEBOC_OPERATOR_PARITY_CHECK_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jz .parity_mismatch
 cmp rdx,[rbx+NEBOC_OPERATOR_PARITY_ASM_DIAGNOSTIC_OFFSET]
 jne .parity_mismatch
 cmp rdx,[rbx+NEBOC_OPERATOR_PARITY_BUILD_DIAGNOSTIC_OFFSET]
 jne .parity_mismatch
.parity_hash:
 mov rax,[rbx+NEBOC_OPERATOR_PARITY_ID_OFFSET]
 xor r14,rax
 imul r14,r8
 xor r14,rdx
 imul r14,r8
 add rbx,NEBOC_OPERATOR_PARITY_SIZE
 inc r11
 jmp .parity_loop
.parity_commit:
 mov [r13+NEBOC_OPERATOR_PARITY_SUMMARY_CASES_OFFSET],r12
 mov [r13+NEBOC_OPERATOR_PARITY_SUMMARY_PASSED_OFFSET],r12
 mov qword [r13+NEBOC_OPERATOR_PARITY_SUMMARY_FAILURES_OFFSET],0
 mov [r13+NEBOC_OPERATOR_PARITY_SUMMARY_DIGEST_OFFSET],r14
 xor eax,eax
 jmp .parity_done
.parity_mismatch:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .parity_done
.parity_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .parity_done
.parity_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.parity_done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; freezeOperatorBaseline(snapshot*, matrix*, parity*, freeze*) -> StatusCode
; FREEZE is written only after every factual gate has been authenticated.
NEBOC_ABI_FUNCTION neboc_freeze_operator_baseline
 test rdi,rdi
 jz .freeze_invalid
 test rsi,rsi
 jz .freeze_invalid
 test rdx,rdx
 jz .freeze_invalid
 test rcx,rcx
 jz .freeze_invalid
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_SCHEMA_OFFSET],NEBOC_OPERATOR_BASELINE_SCHEMA_VERSION
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_ENTRIES_OFFSET],NEBOC_OPERATOR_REGISTRY_ENTRY_COUNT
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_LEXEMES_OFFSET],NEBOC_OPERATOR_REGISTRY_LEXEME_COUNT
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_PROTOCOLS_OFFSET],NEBOC_OPERATOR_PROTOCOL_COUNT
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_PRECEDENCE_ROWS_OFFSET],NEBOC_OPERATOR_BASELINE_PRECEDENCE_ROWS
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_IMPLEMENTATIONS_OFFSET],NEBOC_OPERATOR_BASELINE_IMPLEMENTATIONS
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_MODES_OFFSET],NEBOC_OPERATOR_MODE_ALL
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_NEW_PUBLIC_ENTRIES_OFFSET],0
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_OPEN_P0_OFFSET],0
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_OPEN_P1_OFFSET],0
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_OPEN_P2_OFFSET],0
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_FLAGS_OFFSET],NEBOC_OPERATOR_SNAPSHOT_REQUIRED_FLAGS
 jne .freeze_reject
 cmp qword [rdi+NEBOC_OPERATOR_SNAPSHOT_DIGEST_OFFSET],0
 je .freeze_reject
 mov rax,[rsi+NEBOC_OPERATOR_MATRIX_CASES_OFFSET]
 test rax,rax
 jz .freeze_reject
 cmp [rsi+NEBOC_OPERATOR_MATRIX_PASSED_OFFSET],rax
 jne .freeze_reject
 cmp qword [rsi+NEBOC_OPERATOR_MATRIX_FAILURES_OFFSET],0
 jne .freeze_reject
 mov r8,[rsi+NEBOC_OPERATOR_MATRIX_POSITIVE_OFFSET]
 add r8,[rsi+NEBOC_OPERATOR_MATRIX_NEGATIVE_OFFSET]
 cmp r8,rax
 jne .freeze_reject
 cmp qword [rsi+NEBOC_OPERATOR_MATRIX_DIGEST_OFFSET],0
 je .freeze_reject
 mov rax,[rdx+NEBOC_OPERATOR_PARITY_SUMMARY_CASES_OFFSET]
 test rax,rax
 jz .freeze_reject
 cmp [rdx+NEBOC_OPERATOR_PARITY_SUMMARY_PASSED_OFFSET],rax
 jne .freeze_reject
 cmp qword [rdx+NEBOC_OPERATOR_PARITY_SUMMARY_FAILURES_OFFSET],0
 jne .freeze_reject
 cmp qword [rdx+NEBOC_OPERATOR_PARITY_SUMMARY_DIGEST_OFFSET],0
 je .freeze_reject
 mov qword [rcx+NEBOC_OPERATOR_FREEZE_SCHEMA_OFFSET],NEBOC_OPERATOR_BASELINE_SCHEMA_VERSION
 mov rax,[rdi+NEBOC_OPERATOR_SNAPSHOT_DIGEST_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_SNAPSHOT_DIGEST_OFFSET],rax
 mov rax,[rsi+NEBOC_OPERATOR_MATRIX_DIGEST_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_MATRIX_DIGEST_OFFSET],rax
 mov rax,[rdx+NEBOC_OPERATOR_PARITY_SUMMARY_DIGEST_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_PARITY_DIGEST_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_ENTRIES_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_REGISTRY_ENTRIES_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_SNAPSHOT_REGISTRY_LEXEMES_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_REGISTRY_LEXEMES_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_SNAPSHOT_PROTOCOLS_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_PROTOCOLS_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_SNAPSHOT_PRECEDENCE_ROWS_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_PRECEDENCE_ROWS_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_SNAPSHOT_IMPLEMENTATIONS_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_IMPLEMENTATIONS_OFFSET],rax
 mov rax,[rdi+NEBOC_OPERATOR_SNAPSHOT_MODES_OFFSET]
 mov [rcx+NEBOC_OPERATOR_FREEZE_MODES_OFFSET],rax
 mov qword [rcx+NEBOC_OPERATOR_FREEZE_FLAGS_OFFSET],NEBOC_OPERATOR_FREEZE_REQUIRED_FLAGS
 xor eax,eax
 ret
.freeze_reject:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.freeze_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
