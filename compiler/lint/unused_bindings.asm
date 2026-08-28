; C05 unused-binding warning owners over resolved identity and C05-F01 facts.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"
%include "compiler/lint/unused_bindings.inc"

extern neboc_warning_liveness_query

section .text

; unused_immutable_local(session*, function*, liveness_plan*, candidate*, out*)
NEBOC_ABI_FUNCTION neboc_unused_immutable_local
 mov r9d,NEBOC_UNUSED_KIND_IMMUTABLE_LOCAL
 mov r10d,NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL
 jmp unused_local_common

; unused_mutable_binding(session*, function*, liveness_plan*, candidate*, out*)
NEBOC_ABI_FUNCTION neboc_unused_mutable_binding
 mov r9d,NEBOC_UNUSED_KIND_MUTABLE_LOCAL
 mov r10d,NEBOC_UNUSED_WARNING_MUTABLE_BINDING
 jmp unused_local_common

; unused_callable_input accepts exactly parameter, receiver or capture kinds.
NEBOC_ABI_FUNCTION neboc_unused_callable_input
 test rcx,rcx
 jz .callable_invalid
 mov r9,[rcx+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET]
 cmp r9,NEBOC_UNUSED_KIND_PARAMETER
 jb .callable_invalid
 cmp r9,NEBOC_UNUSED_KIND_CAPTURE
 ja .callable_invalid
 mov r10d,NEBOC_UNUSED_WARNING_CALLABLE_INPUT
 jmp unused_local_common
.callable_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; unused_module_binding accepts import, alias and reexport identities.
NEBOC_ABI_FUNCTION neboc_unused_module_binding
 test rcx,rcx
 jz .module_invalid
 mov r9,[rcx+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET]
 cmp r9,NEBOC_UNUSED_KIND_IMPORT
 jb .module_invalid
 cmp r9,NEBOC_UNUSED_KIND_REEXPORT
 ja .module_invalid
 mov r10d,NEBOC_UNUSED_WARNING_MODULE_BINDING
 jmp unused_local_common
.module_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; unused_private_symbol accepts private function, constant and type identities.
NEBOC_ABI_FUNCTION neboc_unused_private_symbol
 test rcx,rcx
 jz .private_invalid
 mov r9,[rcx+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET]
 cmp r9,NEBOC_UNUSED_KIND_PRIVATE_FUNCTION
 jb .private_invalid
 cmp r9,NEBOC_UNUSED_KIND_PRIVATE_TYPE
 ja .private_invalid
 mov r10d,NEBOC_UNUSED_WARNING_PRIVATE_SYMBOL
 jmp unused_local_common
.private_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

unused_local_common:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,NEBOC_WARNING_LIVENESS_QUERY_SIZE+16
 mov [rsp+NEBOC_WARNING_LIVENESS_QUERY_SIZE],r9
 mov [rsp+NEBOC_WARNING_LIVENESS_QUERY_SIZE+8],r10
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 test rbx,rbx
 jz .invalid
 mov rax,[rsp+NEBOC_WARNING_LIVENESS_QUERY_SIZE]
 cmp [r15+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],rax
 jne .invalid
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET]
 mov rcx,[rsp+NEBOC_WARNING_LIVENESS_QUERY_SIZE]
 cmp rcx,NEBOC_UNUSED_KIND_IMPORT
 je .validate_import_flags
 cmp rcx,NEBOC_UNUSED_KIND_ALIAS
 je .validate_zero_flags
 cmp rcx,NEBOC_UNUSED_KIND_REEXPORT
 je .validate_reexport_flags
 cmp rcx,NEBOC_UNUSED_KIND_PRIVATE_FUNCTION
 jb .validate_zero_flags
 cmp rcx,NEBOC_UNUSED_KIND_PRIVATE_TYPE
 jbe .validate_private_flags
.validate_zero_flags:
 test rax,rax
 jnz .invalid
 jmp .flags_valid
.validate_import_flags:
 test rax,~NEBOC_UNUSED_FLAG_SIDE_EFFECT_IMPORT
 jnz .invalid
 jmp .flags_valid
.validate_reexport_flags:
 test rax,~NEBOC_UNUSED_FLAG_PUBLIC_REEXPORT
 jnz .invalid
 jmp .flags_valid
.validate_private_flags:
 test rax,~(NEBOC_UNUSED_FLAG_REACHABILITY_ROOT|NEBOC_UNUSED_FLAG_UNKNOWN_REACHABILITY)
 jnz .invalid
.flags_valid:
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_END_OFFSET]
 cmp rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_START_OFFSET]
 jb .invalid
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 cmp rax,[r13+NEBOC_ANALYSIS_FUNCTION_SNAPSHOT_OFFSET]
 jne .stale
 cmp rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_SNAPSHOT_OFFSET]
 jne .stale

 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_UNUSED_FINDING_SIZE/8
 rep stosq
 mov rdi,r12
 mov rsi,r14
 mov rdx,[r15+NEBOC_UNUSED_CANDIDATE_BLOCK_OFFSET]
 mov rcx,[r15+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 lea r8,[rsp]
 call neboc_warning_liveness_query
 test eax,eax
 jz .scan_setup
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .done
 mov qword [rbx+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jmp .done

.scan_setup:
 mov rax,[r13+NEBOC_ANALYSIS_FUNCTION_EVENT_COUNT_OFFSET]
 test rax,rax
 jz .invalid_after_clear
 cmp qword [r13+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET],0
 je .invalid_after_clear
 xor r9d,r9d                    ; definitions for this identity
 xor r10d,r10d                  ; reads for this identity
 xor r11d,r11d                  ; exact declaration node observed
 xor ecx,ecx
.scan:
 cmp rcx,[r13+NEBOC_ANALYSIS_FUNCTION_EVENT_COUNT_OFFSET]
 jae .classify
 mov rdi,[r13+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET]
 mov rax,rcx
 imul rax,NEBOC_ANALYSIS_EVENT_SIZE
 add rdi,rax
 mov rax,[rdi+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET]
 cmp rax,[r15+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 jne .next
 mov rax,[rdi+NEBOC_ANALYSIS_EVENT_FLAGS_OFFSET]
 test rax,NEBOC_ANALYSIS_EVENT_USE
 jz .definition
 inc r10
.definition:
 test rax,NEBOC_ANALYSIS_EVENT_DEFINE
 jz .next
 inc r9
 mov rax,[rdi+NEBOC_ANALYSIS_EVENT_NODE_OFFSET]
 cmp rax,[r15+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET]
 jne .next
 mov r11d,1
.next:
 inc rcx
 jmp .scan

.classify:
 cmp qword [rsp+NEBOC_WARNING_LIVENESS_QUERY_SIZE],NEBOC_UNUSED_KIND_MUTABLE_LOCAL
 je .mutable_definition_count
 cmp r9,1
 jne .invalid_after_clear
 jmp .definition_count_valid
.mutable_definition_count:
 test r9,r9
 jz .invalid_after_clear
.definition_count_valid:
 cmp r11,1
 jne .invalid_after_clear
 mov rax,[rsp+NEBOC_WARNING_LIVENESS_QUERY_SIZE]
 mov [rbx+NEBOC_UNUSED_FINDING_KIND_OFFSET],rax
 mov rax,[rsp+NEBOC_WARNING_LIVENESS_QUERY_SIZE+8]
 mov [rbx+NEBOC_UNUSED_FINDING_CODE_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SYMBOL_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_NODE_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_START_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SPAN_START_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_END_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SPAN_END_OFFSET],rax
 mov [rbx+NEBOC_UNUSED_FINDING_READS_OFFSET],r10
 mov [rbx+NEBOC_UNUSED_FINDING_DEFINITIONS_OFFSET],r9
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_INITIALIZER_EFFECTS_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SNAPSHOT_OFFSET],rax
 mov qword [rbx+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 test r10,r10
 jnz .clean
 cmp qword [r15+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],0
 jne .clean
 mov qword [rbx+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 mov qword [rbx+NEBOC_UNUSED_FINDING_REASON_OFFSET],NEBOC_UNUSED_REASON_NO_READS
.clean:
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_after_clear:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,NEBOC_WARNING_LIVENESS_QUERY_SIZE+16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; dead_store(session*, function*, liveness_plan*, store_candidate*, out*)
; A store is dead only when a same-block definition kills it before a read, or
; when no read follows and the symbol is not live-out of that block.
NEBOC_ABI_FUNCTION neboc_dead_store
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,NEBOC_WARNING_LIVENESS_QUERY_SIZE
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .dead_invalid
 test r13,r13
 jz .dead_invalid
 test r14,r14
 jz .dead_invalid
 test r15,r15
 jz .dead_invalid
 test rbx,rbx
 jz .dead_invalid
 cmp qword [r15+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET],NEBOC_UNUSED_KIND_MUTABLE_LOCAL
 jne .dead_invalid
 cmp qword [r15+NEBOC_UNUSED_CANDIDATE_FLAGS_OFFSET],0
 jne .dead_invalid
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_END_OFFSET]
 cmp rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_START_OFFSET]
 jb .dead_invalid
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 cmp rax,[r13+NEBOC_ANALYSIS_FUNCTION_SNAPSHOT_OFFSET]
 jne .dead_stale
 cmp rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_SNAPSHOT_OFFSET]
 jne .dead_stale
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_UNUSED_FINDING_SIZE/8
 rep stosq
 mov rdi,r12
 mov rsi,r14
 mov rdx,[r15+NEBOC_UNUSED_CANDIDATE_BLOCK_OFFSET]
 mov rcx,[r15+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 lea r8,[rsp]
 call neboc_warning_liveness_query
 test eax,eax
 jz .dead_block
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .dead_done
 mov qword [rbx+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 jmp .dead_done
.dead_block:
 mov rcx,[r15+NEBOC_UNUSED_CANDIDATE_BLOCK_OFFSET]
 cmp rcx,[r13+NEBOC_ANALYSIS_FUNCTION_BLOCK_COUNT_OFFSET]
 jae .dead_invalid_clear
 mov rdi,[r13+NEBOC_ANALYSIS_FUNCTION_BLOCKS_OFFSET]
 mov rax,rcx
 imul rax,NEBOC_ANALYSIS_BLOCK_SIZE
 add rdi,rax
 mov r9,[rdi+NEBOC_ANALYSIS_BLOCK_FIRST_EVENT_OFFSET]
 mov r10,r9
 add r10,[rdi+NEBOC_ANALYSIS_BLOCK_EVENT_COUNT_OFFSET]
 xor r11d,r11d
.dead_find:
 cmp r9,r10
 jae .dead_invalid_clear
 mov rdi,[r13+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET]
 mov rax,r9
 imul rax,NEBOC_ANALYSIS_EVENT_SIZE
 add rdi,rax
 mov rax,[rdi+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET]
 cmp rax,[r15+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 jne .dead_find_next
 mov rax,[rdi+NEBOC_ANALYSIS_EVENT_NODE_OFFSET]
 cmp rax,[r15+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET]
 jne .dead_find_next
 test qword [rdi+NEBOC_ANALYSIS_EVENT_FLAGS_OFFSET],NEBOC_ANALYSIS_EVENT_DEFINE
 jz .dead_invalid_clear
 mov r11d,1
 inc r9
 jmp .dead_after
.dead_find_next:
 inc r9
 jmp .dead_find
.dead_after:
 cmp r9,r10
 jae .dead_block_end
 mov rdi,[r13+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET]
 mov rax,r9
 imul rax,NEBOC_ANALYSIS_EVENT_SIZE
 add rdi,rax
 mov rax,[rdi+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET]
 cmp rax,[r15+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 jne .dead_after_next
 mov rax,[rdi+NEBOC_ANALYSIS_EVENT_FLAGS_OFFSET]
 test rax,NEBOC_ANALYSIS_EVENT_USE
 jnz .dead_clean_read
 test rax,NEBOC_ANALYSIS_EVENT_DEFINE
 jnz .dead_emit
.dead_after_next:
 inc r9
 jmp .dead_after
.dead_block_end:
 cmp qword [rsp+NEBOC_WARNING_LIVENESS_QUERY_LIVE_OUT_OFFSET],1
 je .dead_clean
 jmp .dead_emit
.dead_clean_read:
 mov qword [rbx+NEBOC_UNUSED_FINDING_READS_OFFSET],1
.dead_clean:
 mov qword [rbx+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .dead_done
.dead_emit:
 mov qword [rbx+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 mov qword [rbx+NEBOC_UNUSED_FINDING_KIND_OFFSET],NEBOC_UNUSED_KIND_MUTABLE_LOCAL
 mov qword [rbx+NEBOC_UNUSED_FINDING_CODE_OFFSET],NEBOC_UNUSED_WARNING_DEAD_STORE
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SYMBOL_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_NODE_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_START_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SPAN_START_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SPAN_END_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SPAN_END_OFFSET],rax
 mov qword [rbx+NEBOC_UNUSED_FINDING_DEFINITIONS_OFFSET],1
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_INITIALIZER_EFFECTS_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET],rax
 mov rax,[r15+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 mov [rbx+NEBOC_UNUSED_FINDING_SNAPSHOT_OFFSET],rax
 mov qword [rbx+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 mov qword [rbx+NEBOC_UNUSED_FINDING_REASON_OFFSET],NEBOC_UNUSED_REASON_DEAD_STORE
 xor eax,eax
 jmp .dead_done
.dead_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .dead_done
.dead_invalid_clear:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .dead_done
.dead_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.dead_done:
 add rsp,NEBOC_WARNING_LIVENESS_QUERY_SIZE
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; intentional_unused_policy(candidate*, policy*, out_record*)
NEBOC_ABI_FUNCTION neboc_unused_intentional_policy
 test rdi,rdi
 jz .policy_invalid
 test rsi,rsi
 jz .policy_invalid
 test rdx,rdx
 jz .policy_invalid
 mov rax,[rdi+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 test rax,rax
 jz .policy_invalid
 cmp rax,[rsi+NEBOC_UNUSED_POLICY_SNAPSHOT_OFFSET]
 jne .policy_stale
 mov rcx,[rdi+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 test rcx,rcx
 jz .policy_invalid
 cmp rcx,[rsi+NEBOC_UNUSED_POLICY_SYMBOL_OFFSET]
 jne .policy_invalid
 mov r8,[rsi+NEBOC_UNUSED_POLICY_CODE_OFFSET]
 cmp r8,NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL
 jb .policy_invalid
 cmp r8,NEBOC_UNUSED_WARNING_PRIVATE_SYMBOL
 ja .policy_invalid
 mov r9,[rsi+NEBOC_UNUSED_POLICY_MODE_OFFSET]
 cmp r9,NEBOC_UNUSED_POLICY_MODE_NAME
 je .policy_name
 cmp r9,NEBOC_UNUSED_POLICY_MODE_SCOPE
 je .policy_scope
 jmp .policy_invalid
.policy_name:
 cmp qword [rsi+NEBOC_UNUSED_POLICY_SCOPE_OFFSET],0
 jne .policy_invalid
 cmp qword [rsi+NEBOC_UNUSED_POLICY_REASON_LENGTH_OFFSET],0
 jne .policy_invalid
 mov r10,[rsi+NEBOC_UNUSED_POLICY_NAME_OFFSET]
 test r10,r10
 jz .policy_invalid
 mov r11,[rsi+NEBOC_UNUSED_POLICY_NAME_LENGTH_OFFSET]
 test r11,r11
 jz .policy_invalid
 cmp r11,NEBOC_UNUSED_POLICY_MAX_NAME_BYTES
 ja .policy_limit
 cmp byte [r10],'_'
 jne .policy_invalid
 mov rcx,1
.policy_name_loop:
 cmp rcx,r11
 jae .policy_name_ok
 mov al,[r10+rcx]
 cmp al,'_'
 je .policy_name_next
 cmp al,'0'
 jb .policy_name_alpha
 cmp al,'9'
 jbe .policy_name_next
.policy_name_alpha:
 cmp al,'A'
 jb .policy_invalid
 cmp al,'Z'
 jbe .policy_name_next
 cmp al,'a'
 jb .policy_invalid
 cmp al,'z'
 ja .policy_invalid
.policy_name_next:
 inc rcx
 jmp .policy_name_loop
.policy_name_ok:
 mov r9d,NEBOC_UNUSED_POLICY_FLAG_INTENTIONAL_NAME
 jmp .policy_store
.policy_scope:
 cmp qword [rsi+NEBOC_UNUSED_POLICY_SCOPE_OFFSET],0
 je .policy_invalid
 cmp qword [rsi+NEBOC_UNUSED_POLICY_NAME_LENGTH_OFFSET],0
 jne .policy_invalid
 mov r10,[rsi+NEBOC_UNUSED_POLICY_REASON_OFFSET]
 test r10,r10
 jz .policy_invalid
 mov r11,[rsi+NEBOC_UNUSED_POLICY_REASON_LENGTH_OFFSET]
 test r11,r11
 jz .policy_invalid
 cmp r11,NEBOC_UNUSED_POLICY_MAX_REASON_BYTES
 ja .policy_limit
 xor ecx,ecx
 xor r8d,r8d
.policy_reason_loop:
 cmp rcx,r11
 jae .policy_reason_done
 mov al,[r10+rcx]
 cmp al,0x20
 jb .policy_invalid
 cmp al,0x7f
 je .policy_invalid
 cmp al,0x20
 je .policy_reason_next
 mov r8d,1
.policy_reason_next:
 inc rcx
 jmp .policy_reason_loop
.policy_reason_done:
 test r8d,r8d
 jz .policy_invalid
 mov r9d,NEBOC_UNUSED_POLICY_FLAG_SCOPED_SUPPRESSION
.policy_store:
 mov qword [rdx+NEBOC_UNUSED_POLICY_RECORD_ACTIVE_OFFSET],1
 mov [rdx+NEBOC_UNUSED_POLICY_RECORD_FLAGS_OFFSET],r9
 mov rax,[rsi+NEBOC_UNUSED_POLICY_SYMBOL_OFFSET]
 mov [rdx+NEBOC_UNUSED_POLICY_RECORD_SYMBOL_OFFSET],rax
 mov rax,[rsi+NEBOC_UNUSED_POLICY_SCOPE_OFFSET]
 mov [rdx+NEBOC_UNUSED_POLICY_RECORD_SCOPE_OFFSET],rax
 mov rax,[rsi+NEBOC_UNUSED_POLICY_CODE_OFFSET]
 mov [rdx+NEBOC_UNUSED_POLICY_RECORD_CODE_OFFSET],rax
 mov rax,[rsi+NEBOC_UNUSED_POLICY_SNAPSHOT_OFFSET]
 mov [rdx+NEBOC_UNUSED_POLICY_RECORD_SNAPSHOT_OFFSET],rax
 xor eax,eax
 ret
.policy_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.policy_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.policy_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; apply_policy(finding*, policy_record*) suppresses only a completed matching
; unused warning; all semantic/effect fields remain available for audit.
NEBOC_ABI_FUNCTION neboc_unused_apply_policy
 test rdi,rdi
 jz .apply_invalid
 test rsi,rsi
 jz .apply_invalid
 cmp qword [rdi+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .apply_invalid
 cmp qword [rdi+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .apply_incomplete
 cmp qword [rsi+NEBOC_UNUSED_POLICY_RECORD_ACTIVE_OFFSET],1
 jne .apply_invalid
 mov rax,[rsi+NEBOC_UNUSED_POLICY_RECORD_FLAGS_OFFSET]
 cmp rax,NEBOC_UNUSED_POLICY_FLAG_INTENTIONAL_NAME
 je .apply_match
 cmp rax,NEBOC_UNUSED_POLICY_FLAG_SCOPED_SUPPRESSION
 jne .apply_invalid
.apply_match:
 mov rax,[rsi+NEBOC_UNUSED_POLICY_RECORD_SYMBOL_OFFSET]
 cmp rax,[rdi+NEBOC_UNUSED_FINDING_SYMBOL_OFFSET]
 jne .apply_invalid
 mov rax,[rsi+NEBOC_UNUSED_POLICY_RECORD_CODE_OFFSET]
 cmp rax,[rdi+NEBOC_UNUSED_FINDING_CODE_OFFSET]
 jne .apply_invalid
 mov rax,[rsi+NEBOC_UNUSED_POLICY_RECORD_SNAPSHOT_OFFSET]
 cmp rax,[rdi+NEBOC_UNUSED_FINDING_SNAPSHOT_OFFSET]
 jne .apply_stale
 mov qword [rdi+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],0
 xor eax,eax
 ret
.apply_incomplete:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.apply_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.apply_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; unused_fix_preview(finding*, candidate*, out_plan*) never writes source.
NEBOC_ABI_FUNCTION neboc_unused_fix_preview
 test rdi,rdi
 jz .fix_invalid
 test rsi,rsi
 jz .fix_invalid
 test rdx,rdx
 jz .fix_invalid
 cmp qword [rdi+NEBOC_UNUSED_FINDING_PRESENT_OFFSET],1
 jne .fix_invalid
 cmp qword [rdi+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .fix_incomplete
 mov rax,[rdi+NEBOC_UNUSED_FINDING_SNAPSHOT_OFFSET]
 cmp rax,[rsi+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 jne .fix_stale
 mov rax,[rdi+NEBOC_UNUSED_FINDING_SYMBOL_OFFSET]
 cmp rax,[rsi+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 jne .fix_invalid
 mov rax,[rdi+NEBOC_UNUSED_FINDING_NODE_OFFSET]
 cmp rax,[rsi+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET]
 jne .fix_invalid
 mov rax,[rdi+NEBOC_UNUSED_FINDING_SPAN_START_OFFSET]
 cmp rax,[rsi+NEBOC_UNUSED_CANDIDATE_SPAN_START_OFFSET]
 jne .fix_invalid
 mov rcx,[rdi+NEBOC_UNUSED_FINDING_SPAN_END_OFFSET]
 cmp rcx,[rsi+NEBOC_UNUSED_CANDIDATE_SPAN_END_OFFSET]
 jne .fix_invalid
 cmp rcx,rax
 jb .fix_invalid
 mov r8,[rdi+NEBOC_UNUSED_FINDING_CODE_OFFSET]
 cmp r8,NEBOC_UNUSED_WARNING_IMMUTABLE_LOCAL
 jb .fix_invalid
 cmp r8,NEBOC_UNUSED_WARNING_PRIVATE_SYMBOL
 ja .fix_invalid
 push rdi
 mov rdi,rdx
 xor eax,eax
 mov ecx,NEBOC_UNUSED_FIX_SIZE/8
 rep stosq
 pop rdi
 mov qword [rdx+NEBOC_UNUSED_FIX_ACTIVE_OFFSET],1
 mov rax,[rsi+NEBOC_UNUSED_CANDIDATE_SPAN_START_OFFSET]
 mov [rdx+NEBOC_UNUSED_FIX_START_OFFSET],rax
 mov rax,[rsi+NEBOC_UNUSED_CANDIDATE_SPAN_END_OFFSET]
 mov [rdx+NEBOC_UNUSED_FIX_END_OFFSET],rax
 mov rax,[rsi+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 mov [rdx+NEBOC_UNUSED_FIX_SNAPSHOT_OFFSET],rax
 mov rax,[rsi+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 mov [rdx+NEBOC_UNUSED_FIX_SYMBOL_OFFSET],rax
 mov rax,[rdi+NEBOC_UNUSED_FINDING_CODE_OFFSET]
 mov [rdx+NEBOC_UNUSED_FIX_CODE_OFFSET],rax
 mov rax,[rdi+NEBOC_UNUSED_FINDING_INITIALIZER_EFFECTS_OFFSET]
 mov [rdx+NEBOC_UNUSED_FIX_EFFECTS_OFFSET],rax
 test rax,rax
 jnz .fix_manual
 mov rax,[rsi+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET]
 cmp rax,NEBOC_UNUSED_KIND_PARAMETER
 jb .fix_machine
 cmp rax,NEBOC_UNUSED_KIND_CAPTURE
 jbe .fix_manual
 cmp rax,NEBOC_UNUSED_KIND_PRIVATE_FUNCTION
 jae .fix_manual
.fix_machine:
 mov qword [rdx+NEBOC_UNUSED_FIX_APPLICABILITY_OFFSET],NEBOC_UNUSED_FIX_MACHINE_APPLICABLE
 xor eax,eax
 ret
.fix_manual:
 mov qword [rdx+NEBOC_UNUSED_FIX_APPLICABILITY_OFFSET],NEBOC_UNUSED_FIX_MANUAL_ONLY
 xor eax,eax
 ret
.fix_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.fix_incomplete:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.fix_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Exact semantic parity for clean and incremental findings.
NEBOC_ABI_FUNCTION neboc_unused_finding_parity
 test rdi,rdi
 jz .parity_invalid
 test rsi,rsi
 jz .parity_invalid
 cmp qword [rdi+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .parity_incomplete
 cmp qword [rsi+NEBOC_UNUSED_FINDING_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .parity_incomplete
 mov ecx,NEBOC_UNUSED_FINDING_SIZE/8
 repe cmpsq
 jne .parity_mismatch
 xor eax,eax
 ret
.parity_mismatch:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.parity_incomplete:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.parity_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; incremental_key(function*, liveness_plan*, candidate*, out_key*)
NEBOC_ABI_FUNCTION neboc_unused_incremental_key
 test rdi,rdi
 jz .key_invalid
 test rsi,rsi
 jz .key_invalid
 test rdx,rdx
 jz .key_invalid
 test rcx,rcx
 jz .key_invalid
 mov r8,[rdi+NEBOC_ANALYSIS_FUNCTION_SNAPSHOT_OFFSET]
 cmp r8,[rsi+NEBOC_WARNING_LIVENESS_PLAN_SNAPSHOT_OFFSET]
 jne .key_stale
 cmp r8,[rdx+NEBOC_UNUSED_CANDIDATE_SNAPSHOT_OFFSET]
 jne .key_stale
 cmp qword [rsi+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .key_incomplete
 mov rax,14695981039346656037
 mov r9,1099511628211
 xor rax,r8
 imul rax,r9
 mov r10,[rdi+NEBOC_ANALYSIS_FUNCTION_ID_OFFSET]
 xor rax,r10
 imul rax,r9
 mov r11,[rdx+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 xor rax,r11
 imul rax,r9
 mov r11,[rdx+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET]
 xor rax,r11
 imul rax,r9
 mov r11,[rdx+NEBOC_UNUSED_CANDIDATE_KIND_OFFSET]
 xor rax,r11
 imul rax,r9
 mov r11,[rsi+NEBOC_WARNING_LIVENESS_PLAN_BLOCK_COUNT_OFFSET]
 xor rax,r11
 imul rax,r9
 mov [rcx+NEBOC_UNUSED_INCREMENTAL_DIGEST_OFFSET],rax
 mov [rcx+NEBOC_UNUSED_INCREMENTAL_SNAPSHOT_OFFSET],r8
 mov rax,[rdi+NEBOC_ANALYSIS_FUNCTION_ID_OFFSET]
 mov [rcx+NEBOC_UNUSED_INCREMENTAL_FUNCTION_OFFSET],rax
 mov rax,[rdx+NEBOC_UNUSED_CANDIDATE_SYMBOL_OFFSET]
 mov [rcx+NEBOC_UNUSED_INCREMENTAL_SYMBOL_OFFSET],rax
 mov rax,[rdx+NEBOC_UNUSED_CANDIDATE_NODE_OFFSET]
 mov [rcx+NEBOC_UNUSED_INCREMENTAL_NODE_OFFSET],rax
 mov qword [rcx+NEBOC_UNUSED_INCREMENTAL_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 ret
.key_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.key_incomplete:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.key_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
