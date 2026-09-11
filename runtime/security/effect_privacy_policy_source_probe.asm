; G025 source-to-effect adapter.  Each public subgroup reaches the bounded
; semantic/runtime owner and returns the caller's seed only after observing
; the expected value or effect.
bits 64
default rel
%include "compiler/semantic/effects/effect_inference.inc"
%include "runtime/effects/policy.inc"
%include "runtime/observability/observability.inc"
%include "runtime/provenance/provenance.inc"
%include "runtime/security/audit.inc"

extern nebo_effect_contract_evaluate
extern nebo_effect_infer
extern nebo_capability_authority_init
extern nebo_capability_grant
extern nebo_capability_attenuate
extern nebo_capability_precheck
extern nebo_policy_evaluate
extern nebo_sensitive_init
extern nebo_reveal_capability_grant
extern nebo_sensitive_reveal
extern nebo_sensitive_redact
extern nebo_privacy_flow_check
extern nebo_observability_init
extern nebo_observability_log
extern nebo_observability_counter_add
extern nebo_observability_histogram_observe
extern nebo_observability_span_start
extern nebo_observability_span_close
extern nebo_provenance_init
extern nebo_provenance_record_create
extern nebo_provenance_verify
extern nebo_audit_init
extern nebo_audit_append
extern nebo_audit_verify
extern nebo_audit_query_explain

section .rodata
g25_secret: times 32 db 0x25
g25_payload: db 'g025-private-value'
g25_payload_len equ $-g25_payload
g25_source_digest: times 32 db 0x11
g25_transform_digest: times 32 db 0x22
g25_artifact_digest: times 32 db 0x33
g25_subject_digest: times 32 db 0x44

section .bss align=16
g25_authority: resb NEBO_AUTHORITY_SIZE
g25_capability: resb NEBO_CAPABILITY_SIZE
g25_child: resb NEBO_CAPABILITY_SIZE
g25_grant_request: resb NEBO_CAPABILITY_GRANT_SIZE
g25_effect_request: resb NEBO_EFFECT_REQUEST_SIZE
g25_infer_request: resb NEBO_EFFECT_INFER_REQUEST_SIZE
g25_nodes: resb NEBO_EFFECT_NODE_SIZE*2
g25_edges: resq 1
g25_outputs: resb NEBO_EFFECT_OUTPUT_SIZE*2
g25_trace: resq 2
g25_policy: resb nebo_policy_POLICY_SIZE
g25_sensitive: resb NEBO_SENSITIVE_SIZE
g25_reveal_cap: resb NEBO_REVEAL_SIZE
g25_reveal_request: resb NEBO_REVEAL_REQUEST_SIZE
g25_redact_request: resb NEBO_REDACT_SIZE
g25_flow: resb NEBO_FLOW_SIZE
g25_redacted: resb 32
g25_obs_init: resb NEBO_OBS_INIT_SIZE
g25_obs_state: resb NEBO_OBS_STATE_SIZE
g25_obs_events: resb NEBO_OBS_EVENT_SIZE*8
g25_obs_spans: resb NEBO_OBS_SPAN_SIZE*4
g25_obs_request: resb NEBO_OBS_REQUEST_SIZE
g25_metric: resb NEBO_OBS_METRIC_SIZE
g25_span_request: resb NEBO_OBS_SPAN_REQUEST_SIZE
g25_prov_init: resb NEBO_PROVENANCE_INIT_SIZE
g25_prov_state: resb NEBO_PROVENANCE_STATE_SIZE
g25_prov_records: resb NEBO_PROVENANCE_RECORD_SIZE*4
g25_prov_create: resb NEBO_PROVENANCE_CREATE_SIZE
g25_prov_verify: resb NEBO_PROVENANCE_VERIFY_SIZE
g25_prov_digest: resb 32
g25_prov_verify_digest: resb 32
g25_audit_init_request: resb NEBO_AUDIT_INIT_SIZE
g25_audit_state: resb NEBO_AUDIT_STATE_SIZE
g25_audit_records: resb NEBO_AUDIT_RECORD_SIZE*4
g25_audit_append: resb NEBO_AUDIT_APPEND_SIZE
g25_audit_verify: resb NEBO_AUDIT_VERIFY_SIZE
g25_audit_query: resb NEBO_AUDIT_QUERY_SIZE
g25_audit_explain: resb NEBO_AUDIT_EXPLAIN_SIZE
g25_audit_digest: resb 32
g25_audit_verify_digest: resb 32

section .text
g25_clear:
 ; rdi=address, ecx=qwords
 xor eax,eax
 rep stosq
 ret

g25_authority_init:
 lea rdi,[rel g25_authority]
 mov esi,0x250025
 lea rdx,[rel g25_secret]
 jmp nebo_capability_authority_init

; edi=kind, esi=effects, edx=constraint, ecx=budget, r8d=scope
g25_grant:
 push rbx
 mov ebx,edi
 mov r10d,esi
 mov r11d,edx
 mov r9d,ecx
 mov edx,r8d
 lea rdi,[rel g25_grant_request]
 mov ecx,NEBO_CAPABILITY_GRANT_SIZE/8
 call g25_clear
 lea rax,[rel g25_authority]
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET],rax
 lea rax,[rel g25_capability]
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],rbx
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],r10
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],r11
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],r9
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],rdx
 lea rdi,[rel g25_grant_request]
 call nebo_capability_grant
 pop rbx
 ret

g25_infer_effects:
 lea rdi,[rel g25_infer_request]
 mov ecx,NEBO_EFFECT_INFER_REQUEST_SIZE/8
 call g25_clear
 lea rdi,[rel g25_nodes]
 mov ecx,(NEBO_EFFECT_NODE_SIZE*2)/8
 call g25_clear
 lea rdi,[rel g25_outputs]
 mov ecx,(NEBO_EFFECT_OUTPUT_SIZE*2)/8
 call g25_clear
 lea rdi,[rel g25_trace]
 mov ecx,2
 call g25_clear
 lea rax,[rel g25_nodes]
 mov [rel g25_infer_request+NEBO_EFFECT_INFER_NODES_OFFSET],rax
 mov qword [rel g25_infer_request+NEBO_EFFECT_INFER_NODE_COUNT_OFFSET],2
 lea rax,[rel g25_edges]
 mov [rel g25_infer_request+NEBO_EFFECT_INFER_EDGES_OFFSET],rax
 mov qword [rel g25_infer_request+NEBO_EFFECT_INFER_EDGE_COUNT_OFFSET],1
 lea rax,[rel g25_outputs]
 mov [rel g25_infer_request+NEBO_EFFECT_INFER_OUTPUTS_OFFSET],rax
 mov qword [rel g25_infer_request+NEBO_EFFECT_INFER_OUTPUT_CAPACITY_OFFSET],2
 lea rax,[rel g25_trace]
 mov [rel g25_infer_request+NEBO_EFFECT_INFER_TRACE_OFFSET],rax
 mov qword [rel g25_infer_request+NEBO_EFFECT_INFER_TRACE_CAPACITY_OFFSET],2
 mov qword [rel g25_infer_request+NEBO_EFFECT_INFER_EXPLAIN_NODE_OFFSET],0
 mov qword [rel g25_infer_request+NEBO_EFFECT_INFER_EXPLAIN_EFFECT_OFFSET],NEBO_EFFECT_NETWORK
 mov qword [rel g25_nodes+NEBO_EFFECT_NODE_DIRECT_OFFSET],NEBO_EFFECT_CONSOLE_WRITE
 mov qword [rel g25_nodes+NEBO_EFFECT_NODE_DECLARED_OFFSET],NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_NETWORK
 mov qword [rel g25_nodes+NEBO_EFFECT_NODE_EDGE_COUNT_OFFSET],1
 mov qword [rel g25_nodes+NEBO_EFFECT_NODE_KIND_OFFSET],NEBO_EFFECT_NODE_FUNCTION
 mov qword [rel g25_nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_DIRECT_OFFSET],NEBO_EFFECT_NETWORK
 mov qword [rel g25_nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_DECLARED_OFFSET],NEBO_EFFECT_NETWORK
 mov qword [rel g25_nodes+NEBO_EFFECT_NODE_SIZE+NEBO_EFFECT_NODE_KIND_OFFSET],NEBO_EFFECT_NODE_MODULE
 mov qword [rel g25_edges],1
 lea rdi,[rel g25_infer_request]
 call nebo_effect_infer
 test eax,eax
 jnz .done
 cmp qword [rel g25_outputs+NEBO_EFFECT_OUTPUT_INFERRED_OFFSET],NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_NETWORK
 jne .bad
 cmp qword [rel g25_infer_request+NEBO_EFFECT_INFER_TRACE_COUNT_OFFSET],2
 jne .bad
 xor eax,eax
.done:
 ret
.bad:
 mov eax,1
 ret

g25_mode_effects:
 lea rdi,[rel g25_effect_request]
 mov ecx,NEBO_EFFECT_REQUEST_SIZE/8
 call g25_clear
 mov qword [rel g25_effect_request+NEBO_EFFECT_REQUEST_OPERATION_OFFSET],NEBO_EFFECT_OP_UNION
 mov qword [rel g25_effect_request+NEBO_EFFECT_REQUEST_LEFT_OFFSET],NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE
 mov qword [rel g25_effect_request+NEBO_EFFECT_REQUEST_RIGHT_OFFSET],NEBO_EFFECT_NETWORK | NEBO_EFFECT_PROCESS | NEBO_EFFECT_RANDOM
 lea rdi,[rel g25_effect_request]
 call nebo_effect_contract_evaluate
 test eax,eax
 jnz .bad
 cmp qword [rel g25_effect_request+NEBO_EFFECT_REQUEST_RESULT_OFFSET],NEBO_EFFECT_CONSOLE_WRITE | NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE | NEBO_EFFECT_NETWORK | NEBO_EFFECT_PROCESS | NEBO_EFFECT_RANDOM
 jne .bad
 cmp qword [rel g25_effect_request+NEBO_EFFECT_REQUEST_CARDINALITY_OFFSET],6
 jne .bad
 call g25_infer_effects
 ret
.bad:
 mov eax,1
 ret

g25_mode_capability:
 call g25_authority_init
 test eax,eax
 jnz .bad
 mov edi,NEBO_CAPABILITY_FILE
 mov esi,NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE
 mov edx,0xf
 mov ecx,4
 mov r8d,25
 call g25_grant
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_grant_request]
 mov ecx,NEBO_CAPABILITY_GRANT_SIZE/8
 call g25_clear
 lea rax,[rel g25_authority]
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET],rax
 lea rax,[rel g25_child]
 mov [rel g25_grant_request+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
 mov qword [rel g25_grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],NEBO_CAPABILITY_FILE
 mov qword [rel g25_grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_FILE_READ
 mov qword [rel g25_grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],3
 mov qword [rel g25_grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],2
 mov qword [rel g25_grant_request+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],26
 lea rdi,[rel g25_grant_request]
 lea rsi,[rel g25_capability]
 call nebo_capability_attenuate
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_authority]
 lea rsi,[rel g25_child]
 mov edx,NEBO_EFFECT_FILE_READ
 mov ecx,1
 mov r8d,26
 mov r9d,1
 call nebo_capability_precheck
 test eax,eax
 jnz .bad
 cmp qword [rel g25_child+NEBO_CAPABILITY_BUDGET_OFFSET],1
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g25_mode_policy:
 call g25_authority_init
 test eax,eax
 jnz .bad
 mov edi,NEBO_CAPABILITY_FILE
 mov esi,NEBO_EFFECT_FILE_READ | NEBO_EFFECT_FILE_WRITE
 mov edx,0xf
 mov ecx,5
 mov r8d,25
 call g25_grant
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_policy]
 mov ecx,NEBO_POLICY_QWORDS
 call g25_clear
 lea rax,[rel g25_authority]
 mov [rel g25_policy+NEBO_POLICY_AUTHORITY_OFFSET],rax
 lea rax,[rel g25_capability]
 mov [rel g25_policy+NEBO_POLICY_CAPABILITY_OFFSET],rax
 mov qword [rel g25_policy+NEBO_POLICY_EFFECTS_OFFSET],NEBO_EFFECT_FILE_READ
 mov qword [rel g25_policy+NEBO_POLICY_CONSTRAINT_OFFSET],1
 mov qword [rel g25_policy+NEBO_POLICY_SCOPE_OFFSET],25
 mov qword [rel g25_policy+NEBO_POLICY_CAPABILITY_COST_OFFSET],1
 mov qword [rel g25_policy+NEBO_POLICY_ALLOW_OFFSET],NEBO_EFFECT_FILE_READ
 mov qword [rel g25_policy+NEBO_POLICY_TRUST_ACTUAL_OFFSET],NEBO_POLICY_TRUST_RESTRICTED
 mov qword [rel g25_policy+NEBO_POLICY_TRUST_REQUIRED_OFFSET],NEBO_POLICY_TRUST_INTERNAL
 mov qword [rel g25_policy+NEBO_POLICY_BUDGET_OFFSET],7
 mov qword [rel g25_policy+NEBO_POLICY_COST_OFFSET],2
 mov qword [rel g25_policy+NEBO_POLICY_DEADLINE_OFFSET],100
 mov qword [rel g25_policy+NEBO_POLICY_NOW_OFFSET],50
 lea rdi,[rel g25_policy]
 call nebo_policy_evaluate
 test eax,eax
 jnz .bad
 cmp qword [rel g25_policy+NEBO_POLICY_DECISION_OFFSET],NEBO_POLICY_DECISION_PERMIT
 jne .bad
 cmp qword [rel g25_policy+NEBO_POLICY_REMAINING_OFFSET],5
 jne .bad
 cmp qword [rel g25_policy+NEBO_POLICY_HASH_OFFSET],0
 je .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g25_mode_privacy:
 call g25_authority_init
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_sensitive]
 lea rsi,[rel g25_payload]
 mov edx,g25_payload_len
 mov ecx,nebo_privacy_PRIVACY_SECRET
 mov r8d,25
 call nebo_sensitive_init
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_authority]
 lea rsi,[rel g25_reveal_cap]
 mov edx,25
 mov ecx,nebo_privacy_PRIVACY_SECRET
 mov r8d,25
 call nebo_reveal_capability_grant
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_reveal_request]
 mov ecx,NEBO_REVEAL_REQUEST_SIZE/8
 call g25_clear
 lea rax,[rel g25_authority]
 mov [rel g25_reveal_request+NEBO_REVEAL_REQUEST_AUTHORITY_OFFSET],rax
 lea rax,[rel g25_reveal_cap]
 mov [rel g25_reveal_request+NEBO_REVEAL_REQUEST_CAPABILITY_OFFSET],rax
 lea rax,[rel g25_sensitive]
 mov [rel g25_reveal_request+NEBO_REVEAL_REQUEST_SENSITIVE_OFFSET],rax
 mov qword [rel g25_reveal_request+NEBO_REVEAL_REQUEST_SCOPE_OFFSET],25
 lea rdi,[rel g25_reveal_request]
 call nebo_sensitive_reveal
 test eax,eax
 jnz .bad
 cmp qword [rel g25_reveal_request+NEBO_REVEAL_REQUEST_LENGTH_OFFSET],g25_payload_len
 jne .bad
 lea rdi,[rel g25_redact_request]
 mov ecx,NEBO_REDACT_SIZE/8
 call g25_clear
 lea rax,[rel g25_sensitive]
 mov [rel g25_redact_request+NEBO_REDACT_SENSITIVE_OFFSET],rax
 lea rax,[rel g25_redacted]
 mov [rel g25_redact_request+NEBO_REDACT_OUTPUT_OFFSET],rax
 mov qword [rel g25_redact_request+NEBO_REDACT_CAPACITY_OFFSET],32
 lea rdi,[rel g25_redact_request]
 call nebo_sensitive_redact
 test eax,eax
 jnz .bad
 cmp qword [rel g25_redact_request+NEBO_REDACT_LENGTH_OFFSET],NEBO_REDACTED_BYTES
 jne .bad
 lea rdi,[rel g25_flow]
 mov ecx,NEBO_FLOW_SIZE/8
 call g25_clear
 mov qword [rel g25_flow+NEBO_FLOW_LABELS_OFFSET],nebo_privacy_PRIVACY_SECRET
 mov qword [rel g25_flow+NEBO_FLOW_CLEARANCE_OFFSET],nebo_privacy_PRIVACY_SECRET
 mov qword [rel g25_flow+NEBO_FLOW_VALUE_PURPOSE_OFFSET],25
 mov qword [rel g25_flow+NEBO_FLOW_SINK_PURPOSE_OFFSET],25
 lea rdi,[rel g25_flow]
 call nebo_privacy_flow_check
 test eax,eax
 jnz .bad
 cmp qword [rel g25_flow+NEBO_FLOW_DECISION_OFFSET],1
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g25_mode_observability:
 call g25_authority_init
 test eax,eax
 jnz .bad
 mov edi,NEBO_CAPABILITY_CONSOLE
 mov esi,NEBO_EFFECT_CONSOLE_WRITE
 mov edx,1
 mov ecx,20
 mov r8d,25
 call g25_grant
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_obs_init]
 mov ecx,NEBO_OBS_INIT_SIZE/8
 call g25_clear
 lea rax,[rel g25_obs_state]
 mov [rel g25_obs_init+NEBO_OBS_INIT_STATE],rax
 lea rax,[rel g25_obs_events]
 mov [rel g25_obs_init+NEBO_OBS_INIT_EVENTS],rax
 mov qword [rel g25_obs_init+NEBO_OBS_INIT_EVENT_CAPACITY],8
 lea rax,[rel g25_obs_spans]
 mov [rel g25_obs_init+NEBO_OBS_INIT_SPANS],rax
 mov qword [rel g25_obs_init+NEBO_OBS_INIT_SPAN_CAPACITY],4
 lea rax,[rel g25_authority]
 mov [rel g25_obs_init+NEBO_OBS_INIT_AUTHORITY],rax
 lea rax,[rel g25_capability]
 mov [rel g25_obs_init+NEBO_OBS_INIT_CAPABILITY],rax
 mov qword [rel g25_obs_init+NEBO_OBS_INIT_SCOPE],25
 lea rdi,[rel g25_obs_init]
 call nebo_observability_init
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_obs_request]
 mov ecx,NEBO_OBS_REQUEST_SIZE/8
 call g25_clear
 lea rax,[rel g25_obs_state]
 mov [rel g25_obs_request+NEBO_OBS_REQUEST_STATE],rax
 mov qword [rel g25_obs_request+NEBO_OBS_REQUEST_NAME],0x2501
 mov qword [rel g25_obs_request+NEBO_OBS_REQUEST_TIME],10
 mov qword [rel g25_obs_request+NEBO_OBS_REQUEST_VALUE],17
 mov qword [rel g25_obs_request+NEBO_OBS_REQUEST_FIELDS],2
 mov qword [rel g25_obs_request+NEBO_OBS_REQUEST_LABELS],1
 lea rdi,[rel g25_obs_request]
 call nebo_observability_log
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_metric]
 mov ecx,NEBO_OBS_METRIC_SIZE/8
 call g25_clear
 lea rax,[rel g25_obs_state]
 mov [rel g25_metric+NEBO_OBS_METRIC_STATE],rax
 mov qword [rel g25_metric+NEBO_OBS_METRIC_NAME],0x2502
 mov qword [rel g25_metric+NEBO_OBS_METRIC_VALUE],3
 mov qword [rel g25_metric+NEBO_OBS_METRIC_TIME],20
 mov qword [rel g25_metric+NEBO_OBS_METRIC_LABELS],1
 lea rdi,[rel g25_metric]
 call nebo_observability_counter_add
 test eax,eax
 jnz .bad
 cmp qword [rel g25_metric+NEBO_OBS_METRIC_RESULT],3
 jne .bad
 mov qword [rel g25_metric+NEBO_OBS_METRIC_VALUE],4
 lea rdi,[rel g25_metric]
 call nebo_observability_histogram_observe
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_span_request]
 mov ecx,NEBO_OBS_SPAN_REQUEST_SIZE/8
 call g25_clear
 lea rax,[rel g25_obs_state]
 mov [rel g25_span_request+NEBO_OBS_SPAN_REQUEST_STATE],rax
 mov qword [rel g25_span_request+NEBO_OBS_SPAN_REQUEST_NAME],0x2503
 mov qword [rel g25_span_request+NEBO_OBS_SPAN_REQUEST_TIME],30
 mov qword [rel g25_span_request+NEBO_OBS_SPAN_REQUEST_FIELDS],1
 mov qword [rel g25_span_request+NEBO_OBS_SPAN_REQUEST_LABELS],1
 lea rdi,[rel g25_span_request]
 call nebo_observability_span_start
 test eax,eax
 jnz .bad
 cmp qword [rel g25_span_request+NEBO_OBS_SPAN_REQUEST_ID],0
 je .bad
 mov qword [rel g25_span_request+NEBO_OBS_SPAN_REQUEST_TIME],40
 lea rdi,[rel g25_span_request]
 call nebo_observability_span_close
 test eax,eax
 jnz .bad
 cmp qword [rel g25_obs_state+NEBO_OBS_STATE_EVENT_COUNT],5
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g25_mode_provenance:
 call g25_authority_init
 test eax,eax
 jnz .bad
 mov edi,NEBO_CAPABILITY_FILE
 mov esi,NEBO_EFFECT_FILE_WRITE
 mov edx,1
 mov ecx,8
 mov r8d,25
 call g25_grant
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_prov_init]
 mov ecx,NEBO_PROVENANCE_INIT_SIZE/8
 call g25_clear
 lea rax,[rel g25_prov_state]
 mov [rel g25_prov_init+NEBO_PROVENANCE_INIT_STATE],rax
 lea rax,[rel g25_prov_records]
 mov [rel g25_prov_init+NEBO_PROVENANCE_INIT_RECORDS],rax
 mov qword [rel g25_prov_init+NEBO_PROVENANCE_INIT_CAPACITY],4
 lea rax,[rel g25_authority]
 mov [rel g25_prov_init+NEBO_PROVENANCE_INIT_AUTHORITY],rax
 lea rax,[rel g25_capability]
 mov [rel g25_prov_init+NEBO_PROVENANCE_INIT_CAPABILITY],rax
 mov qword [rel g25_prov_init+NEBO_PROVENANCE_INIT_SCOPE],25
 lea rdi,[rel g25_prov_init]
 call nebo_provenance_init
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_prov_create]
 mov ecx,NEBO_PROVENANCE_CREATE_SIZE/8
 call g25_clear
 lea rax,[rel g25_prov_state]
 mov [rel g25_prov_create+NEBO_PROVENANCE_CREATE_STATE],rax
 lea rax,[rel g25_source_digest]
 mov [rel g25_prov_create+NEBO_PROVENANCE_CREATE_SOURCE],rax
 lea rax,[rel g25_transform_digest]
 mov [rel g25_prov_create+NEBO_PROVENANCE_CREATE_TRANSFORM],rax
 lea rax,[rel g25_artifact_digest]
 mov [rel g25_prov_create+NEBO_PROVENANCE_CREATE_ARTIFACT],rax
 mov qword [rel g25_prov_create+NEBO_PROVENANCE_CREATE_POLICY],0x2506
 mov qword [rel g25_prov_create+NEBO_PROVENANCE_CREATE_QUALITY],950000
 lea rax,[rel g25_prov_digest]
 mov [rel g25_prov_create+NEBO_PROVENANCE_CREATE_DIGEST],rax
 lea rdi,[rel g25_prov_create]
 call nebo_provenance_record_create
 test eax,eax
 jnz .bad
 cmp qword [rel g25_prov_create+NEBO_PROVENANCE_CREATE_INDEX],1
 jne .bad
 lea rdi,[rel g25_prov_verify]
 mov ecx,NEBO_PROVENANCE_VERIFY_SIZE/8
 call g25_clear
 lea rax,[rel g25_prov_state]
 mov [rel g25_prov_verify+NEBO_PROVENANCE_VERIFY_STATE],rax
 mov qword [rel g25_prov_verify+NEBO_PROVENANCE_VERIFY_INDEX],1
 lea rax,[rel g25_prov_verify_digest]
 mov [rel g25_prov_verify+NEBO_PROVENANCE_VERIFY_DIGEST],rax
 lea rdi,[rel g25_prov_verify]
 call nebo_provenance_verify
 test eax,eax
 jnz .bad
 mov rax,[rel g25_prov_digest]
 cmp [rel g25_prov_verify_digest],rax
 jne .bad
 cmp qword [rel g25_prov_records+NEBO_PROVENANCE_RECORD_PARENT_COUNT],0
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

g25_mode_audit:
 lea rdi,[rel g25_audit_init_request]
 mov ecx,NEBO_AUDIT_INIT_SIZE/8
 call g25_clear
 lea rax,[rel g25_audit_state]
 mov [rel g25_audit_init_request+NEBO_AUDIT_INIT_STATE],rax
 lea rax,[rel g25_audit_records]
 mov [rel g25_audit_init_request+NEBO_AUDIT_INIT_RECORDS],rax
 mov qword [rel g25_audit_init_request+NEBO_AUDIT_INIT_CAPACITY],4
 mov qword [rel g25_audit_init_request+NEBO_AUDIT_INIT_AUTHORITY],0x2525
 mov qword [rel g25_audit_init_request+NEBO_AUDIT_INIT_SCOPE],25
 mov qword [rel g25_audit_init_request+NEBO_AUDIT_INIT_WRITE_BUDGET],4
 mov qword [rel g25_audit_init_request+NEBO_AUDIT_INIT_QUERY_BUDGET],4
 lea rdi,[rel g25_audit_init_request]
 call nebo_audit_init
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_audit_append]
 mov ecx,NEBO_AUDIT_APPEND_SIZE/8
 call g25_clear
 lea rax,[rel g25_audit_state]
 mov [rel g25_audit_append+NEBO_AUDIT_APPEND_STATE],rax
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_AUTHORITY],0x2525
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_SCOPE],25
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_EVENT_KIND],7
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_EFFECT_MASK],NEBO_EFFECT_NETWORK
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_CAPABILITY_KIND],NEBO_CAPABILITY_NETWORK
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_DECISION],NEBO_AUDIT_DECISION_DENY
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_ERROR_CLASS],4
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_POLICY_ID],0x2507
 mov qword [rel g25_audit_append+NEBO_AUDIT_APPEND_PURPOSE_ID],25
 lea rax,[rel g25_subject_digest]
 mov [rel g25_audit_append+NEBO_AUDIT_APPEND_SUBJECT_DIGEST],rax
 lea rax,[rel g25_audit_digest]
 mov [rel g25_audit_append+NEBO_AUDIT_APPEND_DIGEST],rax
 lea rdi,[rel g25_audit_append]
 call nebo_audit_append
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_audit_verify]
 mov ecx,NEBO_AUDIT_VERIFY_SIZE/8
 call g25_clear
 lea rax,[rel g25_audit_state]
 mov [rel g25_audit_verify+NEBO_AUDIT_VERIFY_STATE],rax
 mov qword [rel g25_audit_verify+NEBO_AUDIT_VERIFY_INDEX],1
 lea rax,[rel g25_audit_verify_digest]
 mov [rel g25_audit_verify+NEBO_AUDIT_VERIFY_DIGEST],rax
 lea rdi,[rel g25_audit_verify]
 call nebo_audit_verify
 test eax,eax
 jnz .bad
 lea rdi,[rel g25_audit_query]
 mov ecx,NEBO_AUDIT_QUERY_SIZE/8
 call g25_clear
 lea rax,[rel g25_audit_state]
 mov [rel g25_audit_query+NEBO_AUDIT_QUERY_STATE],rax
 mov qword [rel g25_audit_query+NEBO_AUDIT_QUERY_AUTHORITY],0x2525
 mov qword [rel g25_audit_query+NEBO_AUDIT_QUERY_SCOPE],25
 mov qword [rel g25_audit_query+NEBO_AUDIT_QUERY_INDEX],1
 lea rax,[rel g25_audit_explain]
 mov [rel g25_audit_query+NEBO_AUDIT_QUERY_OUTPUT],rax
 lea rdi,[rel g25_audit_query]
 call nebo_audit_query_explain
 test eax,eax
 jnz .bad
 cmp qword [rel g25_audit_explain+NEBO_AUDIT_EXPLAIN_DECISION],NEBO_AUDIT_DECISION_DENY
 jne .bad
 cmp qword [rel g25_audit_explain+NEBO_AUDIT_EXPLAIN_POLICY_ID],0x2507
 jne .bad
 call g25_infer_effects
 ret
.bad:
 mov eax,1
 ret

global nebo_g025_source_probe
nebo_g025_source_probe:
 push rbp
 mov rbp,rsp
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 cmp r12d,1
 je .s01
 cmp r12d,2
 je .s02
 cmp r12d,3
 je .s03
 cmp r12d,4
 je .s04
 cmp r12d,5
 je .s05
 cmp r12d,6
 je .s06
 cmp r12d,7
 je .s07
 jmp .failed
.s01: call g25_mode_effects
 jmp .check
.s02: call g25_mode_capability
 jmp .check
.s03: call g25_mode_policy
 jmp .check
.s04: call g25_mode_privacy
 jmp .check
.s05: call g25_mode_observability
 jmp .check
.s06: call g25_mode_provenance
 jmp .check
.s07: call g25_mode_audit
.check:
 test eax,eax
 jnz .failed
 mov eax,r13d
 jmp .done
.failed:
 mov eax,111
.done:
 pop r13
 pop r12
 leave
 ret
