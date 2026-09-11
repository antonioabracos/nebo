; G029 public formal-method witnesses. Real Nebo sources reach these bounded,
; deterministic operations through the ordinary parser, lowering, and linker.
bits 64
default rel
%define NEBO_G029_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/verification/formal_verification_source_probe.inc"
%include "compiler/contracts/contracts.inc"
%include "compiler/contracts/refinement.inc"
%include "compiler/verification/obligations.inc"
%include "compiler/verification/model_check.inc"
%include "compiler/verification/proof.inc"
%include "compiler/verification/report.inc"
%include "runtime/solver/search.inc"

extern nebo_contracts_contract_validate,nebo_contract_decide
extern nebo_refinement_validate,nebo_refinement_refine,nebo_refinement_is
extern nebo_refinement_assume
extern nebo_obligation_evaluate,nebo_obligations_validate_count
extern nebo_model_check
extern nebo_proof_verify,nebo_proof_compose
extern nebo_verification_report_init,nebo_verification_report_add
extern nebo_counterexample_minimize,nebo_counterexample_replay
extern nebo_solver_solve

global nebo_g029_source_probe
global nebo_g029_refinement_explain
global nebo_g029_model_deadlocks
global nebo_g029_manifest_export
global nebo_g029_report_verdict

section .data align=16
g29_requires_contract:
 dq NEBO_CONTRACT_KIND_REQUIRES,2,0,NEBO_CONTRACT_POLICY_RUNTIME,2901
g29_invariant_contract:
 dq NEBO_CONTRACT_KIND_INVARIANT,1,6,NEBO_CONTRACT_POLICY_REJECT_UNKNOWN,2902
g29_refinement_desc:
 dq -10,10,29,2902
g29_solver_model:
 dq 3,1,4,8
g29_transitions:
 dq 2,4,0
g29_unsafe_model:
 dq g29_transitions,3,1,4,4,NEBO_MODEL_PROPERTY_ALWAYS_SAFE,16
g29_eventually_model:
 dq g29_transitions,3,1,0,4,NEBO_MODEL_PROPERTY_EVENTUALLY,16
g29_left_proof:
 dq 101,0x2905,0x460029,0xabc1,1,1,NEBO_PROOF_VERSION
g29_right_proof:
 dq 102,0x2905,0x460029,0xabc2,2,1,NEBO_PROOF_VERSION
g29_trace:
 dq 0,0,1,1,2

section .bss align=16
g29_explain: resb NEBO_CONTRACT_EXPLAIN_SIZE
g29_certificate: resb NEBO_REFINEMENT_CERT_SIZE
g29_refinement_failure: resb G029_REFINEMENT_FAILURE_SIZE
g29_obligation_result: resb NEBO_OBLIGATION_RESULT_SIZE
g29_solver_result: resb NEBO_SEARCH_RESULT_SIZE
g29_model_result: resb NEBO_MODEL_RESULT_SIZE
g29_combined_proof: resb NEBO_PROOF_SIZE
g29_manifest: resb G029_MANIFEST_SIZE
g29_report: resb NEBO_REPORT_SIZE
g29_minimal_trace: resq 5
g29_written: resq 1
g29_deadlock_mask: resq 1

section .text
; descriptor, signed value, failure output -> refinement status. The output is
; cleared before validation and identifies the exact failed bound and span.
nebo_g029_refinement_explain:
 test rdx,rdx
 jz .invalid
 mov qword [rdx+G029_REFINEMENT_FAILURE_PREDICATE],0
 mov qword [rdx+G029_REFINEMENT_FAILURE_SPAN],0
 mov qword [rdx+G029_REFINEMENT_FAILURE_CLAUSE],0
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBO_REFINEMENT_DESC_PREDICATE_ID]
 mov [rdx+G029_REFINEMENT_FAILURE_PREDICATE],rax
 mov rax,[rdi+NEBO_REFINEMENT_DESC_SPAN]
 mov [rdx+G029_REFINEMENT_FAILURE_SPAN],rax
 cmp rsi,[rdi+NEBO_REFINEMENT_DESC_MIN]
 jl .below
 cmp rsi,[rdi+NEBO_REFINEMENT_DESC_MAX]
 jg .above
 xor eax,eax
 ret
.below:
 mov qword [rdx+G029_REFINEMENT_FAILURE_CLAUSE],G029_REFINEMENT_CLAUSE_BELOW
 mov eax,G029_STATUS_RANGE
 ret
.above:
 mov qword [rdx+G029_REFINEMENT_FAILURE_CLAUSE],G029_REFINEMENT_CLAUSE_ABOVE
 mov eax,G029_STATUS_RANGE
 ret
.invalid:
 mov eax,G029_STATUS_INVALID
 ret

; transitions, state count, undesired-state mask, output -> status.
nebo_g029_model_deadlocks:
 test rcx,rcx
 jz .invalid
 mov qword [rcx],0
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBO_MODEL_MAX_STATES
 ja .limit
 xor r8d,r8d
 xor r9d,r9d
.scan:
 cmp r8,rsi
 jae .done
 cmp qword [rdi+r8*8],0
 jne .next
 bt rdx,r8
 jnc .next
 bts r9,r8
.next:
 inc r8
 jmp .scan
.done:
 mov [rcx],r9
 xor eax,eax
 ret
.invalid:
 mov eax,G029_STATUS_INVALID
 ret
.limit:
 mov eax,G029_STATUS_LIMIT
 ret

; proof, caller-owned manifest -> status. The proof is independently verified
; against its own versioned subject/spec identities before anything is copied.
nebo_g029_manifest_export:
 test rsi,rsi
 jz .invalid_plain
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,r12
 mov ecx,G029_MANIFEST_SIZE/8
 xor eax,eax
 rep stosq
 test rbx,rbx
 jz .invalid
 mov rdi,rbx
 mov rsi,[rbx+NEBO_PROOF_SUBJECT_HASH]
 mov rdx,[rbx+NEBO_PROOF_SPEC_HASH]
 call nebo_proof_verify
 test eax,eax
 jnz .done
 mov rax,[rbx+NEBO_PROOF_PROPERTY]
 mov [r12+G029_MANIFEST_PROPERTY],rax
 mov rax,[rbx+NEBO_PROOF_SUBJECT_HASH]
 mov [r12+G029_MANIFEST_SUBJECT_HASH],rax
 mov rax,[rbx+NEBO_PROOF_SPEC_HASH]
 mov [r12+G029_MANIFEST_SPEC_HASH],rax
 mov rax,[rbx+NEBO_PROOF_EVIDENCE_HASH]
 mov [r12+G029_MANIFEST_EVIDENCE_HASH],rax
 mov rax,[rbx+NEBO_PROOF_ASSUMPTION_MASK]
 mov [r12+G029_MANIFEST_ASSUMPTION_MASK],rax
 mov rax,[rbx+NEBO_PROOF_ASSUMPTION_COUNT]
 mov [r12+G029_MANIFEST_ASSUMPTION_COUNT],rax
 mov rax,[rbx+NEBO_PROOF_FORMAT_VERSION]
 mov [r12+G029_MANIFEST_VERSION],rax
 xor eax,eax
 jmp .done
.invalid:
 mov eax,G029_STATUS_INVALID
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
.invalid_plain:
 mov eax,G029_STATUS_INVALID
 ret

; A report never upgrades UNKNOWN, TIMEOUT, or FAILED to proof success.
nebo_g029_report_verdict:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_REPORT_FAILED],0
 jne .failed
 cmp qword [rdi+NEBO_REPORT_TIMEOUT],0
 jne .timeout
 cmp qword [rdi+NEBO_REPORT_UNKNOWN],0
 jne .unknown
 mov eax,G029_REPORT_VERDICT_PROVED_OR_RUNTIME
 ret
.unknown:
 mov eax,G029_REPORT_VERDICT_UNKNOWN
 ret
.timeout:
 mov eax,G029_REPORT_VERDICT_TIMEOUT
 ret
.failed:
 mov eax,G029_REPORT_VERDICT_FAILED
 ret
.invalid:
 xor eax,eax
 ret

; mode, seed -> bounded observed process result. The high dword is nonzero on
; internal failure; the low byte is the independently reproducible effect.
nebo_g029_source_probe:
 push rbx
 push r12
 sub rsp,8
 mov ebx,edi
 mov r12d,esi
 cmp ebx,1
 jb .fail
 cmp ebx,6
 ja .fail
 cmp r12d,2901
 jb .fail
 cmp r12d,999999
 ja .fail
 cmp ebx,1
 je .s1
 cmp ebx,2
 je .s2
 cmp ebx,3
 je .s3
 cmp ebx,4
 je .s4
 cmp ebx,5
 je .s5
 jmp .s6
.s1:
 lea rdi,[rel g29_requires_contract]
 call nebo_contracts_contract_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_invariant_contract]
 call nebo_contracts_contract_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_requires_contract]
 mov esi,NEBO_CONTRACT_PROOF_UNKNOWN
 mov edx,1
 lea rcx,[rel g29_explain]
 call nebo_contract_decide
 test eax,eax
 jnz .fail
 cmp qword [rel g29_explain+NEBO_CONTRACT_EXPLAIN_ACTION],NEBO_CONTRACT_ACTION_RUNTIME_CHECK
 jne .fail
 lea rdi,[rel g29_invariant_contract]
 mov esi,NEBO_CONTRACT_PROOF_PROVED
 xor edx,edx
 lea rcx,[rel g29_explain]
 call nebo_contract_decide
 test eax,eax
 jnz .fail
 cmp qword [rel g29_explain+NEBO_CONTRACT_EXPLAIN_ACTION],NEBO_CONTRACT_ACTION_PROVED
 jne .fail
 jmp .effect
.s2:
 lea rdi,[rel g29_refinement_desc]
 call nebo_refinement_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_refinement_desc]
 mov esi,5
 mov edx,r12d
 lea rcx,[rel g29_certificate]
 call nebo_refinement_refine
 test eax,eax
 jnz .fail
 cmp qword [rel g29_certificate+NEBO_REFINEMENT_CERT_VALUE],5
 jne .fail
 cmp qword [rel g29_certificate+NEBO_REFINEMENT_CERT_PREDICATE_ID],29
 jne .fail
 lea rdi,[rel g29_refinement_desc]
 mov esi,5
 call nebo_refinement_is
 cmp eax,1
 jne .fail
 mov edi,NEBO_REFINEMENT_CAP_ASSUME_UNSAFE
 mov esi,29
 call nebo_refinement_assume
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_refinement_desc]
 mov esi,11
 lea rdx,[rel g29_refinement_failure]
 call nebo_g029_refinement_explain
 cmp eax,G029_STATUS_RANGE
 jne .fail
 cmp qword [rel g29_refinement_failure+G029_REFINEMENT_FAILURE_CLAUSE],G029_REFINEMENT_CLAUSE_ABOVE
 jne .fail
 jmp .effect
.s3:
 mov edi,7
 call nebo_obligations_validate_count
 test eax,eax
 jnz .fail
 mov edi,NEBO_OBLIGATION_OVERFLOW_ADD
 mov esi,40
 mov edx,2
 lea rcx,[rel g29_obligation_result]
 call nebo_obligation_evaluate
 test eax,eax
 jnz .fail
 cmp qword [rel g29_obligation_result+NEBO_OBLIGATION_RESULT_STATE],NEBO_OBLIGATION_STATE_PROVED
 jne .fail
 mov edi,NEBO_OBLIGATION_BOUNDS
 mov esi,2
 mov edx,4
 lea rcx,[rel g29_obligation_result]
 call nebo_obligation_evaluate
 test eax,eax
 jnz .fail
 cmp qword [rel g29_obligation_result+NEBO_OBLIGATION_RESULT_STATE],NEBO_OBLIGATION_STATE_PROVED
 jne .fail
 mov edi,NEBO_OBLIGATION_CLEANUP
 mov esi,3
 mov edx,3
 lea rcx,[rel g29_obligation_result]
 call nebo_obligation_evaluate
 test eax,eax
 jnz .fail
 mov edi,NEBO_OBLIGATION_EFFECTS
 mov esi,1
 mov edx,3
 lea rcx,[rel g29_obligation_result]
 call nebo_obligation_evaluate
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_solver_model]
 lea rsi,[rel g29_solver_result]
 call nebo_solver_solve
 test eax,eax
 jnz .fail
 cmp qword [rel g29_solver_result+NEBO_SEARCH_RESULT_STATE],NEBO_SEARCH_STATE_SAT
 jne .fail
 cmp qword [rel g29_solver_result+NEBO_SEARCH_RESULT_VERIFIED],1
 jne .fail
 jmp .effect
.s4:
 lea rdi,[rel g29_unsafe_model]
 lea rsi,[rel g29_model_result]
 call nebo_model_check
 test eax,eax
 jnz .fail
 cmp qword [rel g29_model_result+NEBO_MODEL_RESULT_STATE],NEBO_MODEL_STATE_VIOLATED
 jne .fail
 cmp qword [rel g29_model_result+NEBO_MODEL_RESULT_WITNESS],2
 jne .fail
 lea rdi,[rel g29_eventually_model]
 lea rsi,[rel g29_model_result]
 call nebo_model_check
 test eax,eax
 jnz .fail
 cmp qword [rel g29_model_result+NEBO_MODEL_RESULT_STATE],NEBO_MODEL_STATE_VERIFIED
 jne .fail
 lea rdi,[rel g29_transitions]
 mov esi,3
 mov edx,4
 lea rcx,[rel g29_deadlock_mask]
 call nebo_g029_model_deadlocks
 test eax,eax
 jnz .fail
 cmp qword [rel g29_deadlock_mask],4
 jne .fail
 jmp .effect
.s5:
 lea rdi,[rel g29_left_proof]
 mov esi,0x2905
 mov edx,0x460029
 call nebo_proof_verify
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_left_proof]
 lea rsi,[rel g29_right_proof]
 lea rdx,[rel g29_combined_proof]
 call nebo_proof_compose
 test eax,eax
 jnz .fail
 cmp qword [rel g29_combined_proof+NEBO_PROOF_ASSUMPTION_MASK],3
 jne .fail
 lea rdi,[rel g29_combined_proof]
 lea rsi,[rel g29_manifest]
 call nebo_g029_manifest_export
 test eax,eax
 jnz .fail
 cmp qword [rel g29_manifest+G029_MANIFEST_VERSION],NEBO_PROOF_VERSION
 jne .fail
 jmp .effect
.s6:
 lea rdi,[rel g29_report]
 call nebo_verification_report_init
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_report]
 mov esi,NEBO_REPORT_STATE_PROVED
 call nebo_verification_report_add
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_report]
 mov esi,NEBO_REPORT_STATE_PROVED
 call nebo_verification_report_add
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_report]
 mov esi,NEBO_REPORT_STATE_PROVED
 call nebo_verification_report_add
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_report]
 mov esi,NEBO_REPORT_STATE_PROVED
 call nebo_verification_report_add
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_report]
 mov esi,NEBO_REPORT_STATE_RUNTIME
 call nebo_verification_report_add
 test eax,eax
 jnz .fail
 cmp qword [rel g29_report+NEBO_REPORT_PROVED],4
 jne .fail
 cmp qword [rel g29_report+NEBO_REPORT_RUNTIME],1
 jne .fail
 cmp qword [rel g29_report+NEBO_REPORT_UNKNOWN],0
 jne .fail
 cmp qword [rel g29_report+NEBO_REPORT_TIMEOUT],0
 jne .fail
 cmp qword [rel g29_report+NEBO_REPORT_FAILED],0
 jne .fail
 lea rdi,[rel g29_report]
 call nebo_g029_report_verdict
 cmp eax,G029_REPORT_VERDICT_PROVED_OR_RUNTIME
 jne .fail
 lea rdi,[rel g29_trace]
 mov esi,5
 lea rdx,[rel g29_minimal_trace]
 mov ecx,5
 lea r8,[rel g29_written]
 call nebo_counterexample_minimize
 test eax,eax
 jnz .fail
 cmp qword [rel g29_written],3
 jne .fail
 lea rdi,[rel g29_transitions]
 mov esi,3
 lea rdx,[rel g29_minimal_trace]
 mov rcx,[rel g29_written]
 call nebo_counterexample_replay
 test eax,eax
 jnz .fail
 lea rdi,[rel g29_left_proof]
 lea rsi,[rel g29_manifest]
 call nebo_g029_manifest_export
 test eax,eax
 jnz .fail
.effect:
 mov eax,r12d
 imul ecx,ebx,17
 add eax,ecx
 and eax,255
 test eax,eax
 jnz .done
 mov eax,1
 jmp .done
.fail:
 mov rax,0x0000000100000046
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
