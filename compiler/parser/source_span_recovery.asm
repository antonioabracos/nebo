; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F05 bounded token recovery trace and post-error phase guard.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/parser/source_span_recovery.inc"

section .text

; Parser.recover(request*, result*)
; Token and synchronization arrays contain qword token-kind identifiers.
NEBOC_ABI_FUNCTION neboc_parser_recover
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_RECOVER_TOKENS_OFFSET]
 test r8,r8
 jz .invalid
 mov r9,[rdi+NEBOC_RECOVER_TOKEN_COUNT_OFFSET]
 test r9,r9
 jz .invalid
 cmp r9,NEBOC_RECOVER_MAX_TOKENS
 ja .limit
 mov r10,[rdi+NEBOC_RECOVER_CURSOR_OFFSET]
 cmp r10,r9
 jae .invalid
 mov r11,[rdi+NEBOC_RECOVER_MAX_STEPS_OFFSET]
 test r11,r11
 jz .invalid
 cmp r11,r9
 ja .limit
 mov rax,[rdi+NEBOC_RECOVER_STRATEGY_OFFSET]
 cmp rax,NEBOC_RECOVER_INSERT_TOKEN
 je .validate_insert
 cmp rax,NEBOC_RECOVER_SKIP_TO_SYNC
 jne .invalid
 mov rdx,[rdi+NEBOC_RECOVER_SYNC_SET_OFFSET]
 test rdx,rdx
 jz .invalid
 mov rcx,[rdi+NEBOC_RECOVER_SYNC_COUNT_OFFSET]
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBOC_RECOVER_MAX_SYNC
 ja .limit
 jmp .validated
.validate_insert:
 cmp qword [rdi+NEBOC_RECOVER_EXPECTED_TOKEN_OFFSET],0
 je .invalid
.validated:
 push rdi
 push rsi
 mov rdi,rsi
 xor eax,eax
 mov ecx,NEBOC_RECOVERY_RESULT_SIZE/8
 rep stosq
 pop rsi
 pop rdi
 mov qword [rsi+NEBOC_RECOVERY_RESULT_FLAGS_OFFSET],NEBOC_RECOVERY_RESULT_RECOVERED
 mov qword [rsi+NEBOC_RECOVERY_RESULT_CODEGEN_VALID_OFFSET],0
 mov rax,[rdi+NEBOC_RECOVER_STRATEGY_OFFSET]
 cmp rax,NEBOC_RECOVER_INSERT_TOKEN
 je .insert
 mov rdx,[rdi+NEBOC_RECOVER_SYNC_SET_OFFSET]
 mov rcx,[rdi+NEBOC_RECOVER_SYNC_COUNT_OFFSET]
 mov rax,[rdi+NEBOC_RECOVER_SOURCE_ID_OFFSET]
 mov [rsi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],rax
 mov [rsi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],r10
 push r12
 push r13
 xor r12d,r12d
.scan:
 cmp r10,r9
 jae .scan_done
 cmp r12,r11
 jae .scan_limit
 mov rax,[r8+r10*8]
 xor r13d,r13d
.sync:
 cmp r13,rcx
 jae .advance
 cmp rax,[rdx+r13*8]
 je .scan_done
 inc r13
 jmp .sync
.advance:
 inc r10
 inc r12
 jmp .scan
.scan_done:
 mov [rsi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET],r10
 mov [rsi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],r9
 mov [rsi+NEBOC_RECOVERY_RESULT_NEXT_CURSOR_OFFSET],r10
 pop r13
 pop r12
 xor eax,eax
 ret
.scan_limit:
 pop r13
 pop r12
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.insert:
 lea rax,[rdi+NEBOC_RECOVER_EXPECTED_TOKEN_OFFSET]
 mov [rsi+NEBOC_RECOVERY_RESULT_INSERTED_OFFSET],rax
 mov qword [rsi+NEBOC_RECOVERY_RESULT_INSERTED_COUNT_OFFSET],1
 mov [rsi+NEBOC_RECOVERY_RESULT_NEXT_CURSOR_OFFSET],r10
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; RecoveryResult.insertedTokens(result*, out_slice*)
NEBOC_ABI_FUNCTION neboc_recovery_result_inserted_tokens
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_RECOVERY_RESULT_INSERTED_OFFSET]
 mov [rsi+NEBOC_SOURCE_MAP_SLICE_POINTER_OFFSET],rax
 mov rax,[rdi+NEBOC_RECOVERY_RESULT_INSERTED_COUNT_OFFSET]
 mov [rsi+neboc_recovery_SLICE_LENGTH_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; RecoveryResult.skippedSpan(result*, out_span*)
NEBOC_ABI_FUNCTION neboc_recovery_result_skipped_span
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET+8]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET+16]
 mov [rsi+16],rax
 mov rax,[rdi+NEBOC_RECOVERY_RESULT_SKIPPED_SPAN_OFFSET+24]
 mov [rsi+24],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; analysis.continueAfterError(policy, node_flags, out_continue*)
; A recovered/error node is never eligible for lowering or codegen.
NEBOC_ABI_FUNCTION neboc_analysis_continue_after_error
 cmp rdi,NEBOC_CONTINUE_STRICT
 jb .invalid
 cmp rdi,NEBOC_CONTINUE_KEEP_GOING
 ja .invalid
 test rdx,rdx
 jz .invalid
 mov qword [rdx],0
 test rsi,NEBOC_ANALYSIS_NODE_RECOVERED|NEBOC_ANALYSIS_NODE_ERROR
 jnz .ok
 cmp rdi,NEBOC_CONTINUE_STRICT
 je .ok
 test rsi,NEBOC_ANALYSIS_NODE_VALID
 jz .ok
 mov qword [rdx],1
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
