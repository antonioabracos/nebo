; PLUGINS-FFI-E-EXTENSIBILIDADE-F07 deterministic expected utility, tail risk and provenance digest.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/probabilistic/decision_risk.inc"
section .rodata
zero dq 0.0
one dq 1.0
sum_tolerance dq 0.000000000001
sign_mask dq 0x7fffffffffffffff
max_finite dq 0x7fefffffffffffff
section .text
; rdi=probabilities, rsi=outcomes, rdx=action-major utilities, rcx=actions,
; r8=report, r9=report capacity. The report appends one f64 per action.
NEBOC_ABI_FUNCTION nebo_prob_expected_utility_choose_f64
    test rdi,rdi
    jz .decision_invalid
    test rdx,rdx
    jz .decision_invalid
    test r8,r8
    jz .decision_invalid
    test rsi,rsi
    jz .decision_invalid
    test rcx,rcx
    jz .decision_invalid
    cmp rsi,NEBO_DECISION_MAX_OUTCOMES
    ja .decision_limit
    cmp rcx,NEBO_DECISION_MAX_ACTIONS
    ja .decision_limit
    mov rax,rcx
    shl rax,3
    add rax,NEBO_DECISION_REPORT_HEADER_SIZE
    jc .decision_limit
    cmp r9,rax
    jb .decision_limit
    mov rax,rsi
    imul rax,rcx
    jo .decision_limit
    mov r10,rax                   ; utility count
    pxor xmm0,xmm0
    pxor xmm5,xmm5
    xor eax,eax
.prob_validate:
    movsd xmm1,[rdi+rax*8]
    ucomisd xmm1,xmm1
    jp .decision_invalid
    ucomisd xmm1,[zero]
    jb .decision_invalid
    ucomisd xmm1,[one]
    ja .decision_invalid
    addsd xmm0,xmm1
    mulsd xmm1,xmm1
    addsd xmm5,xmm1
    inc rax
    cmp rax,rsi
    jb .prob_validate
    subsd xmm0,[one]
    movq xmm1,[sign_mask]
    andpd xmm0,xmm1
    ucomisd xmm0,[sum_tolerance]
    ja .decision_invalid
    movsd xmm6,[one]
    subsd xmm6,xmm5               ; Gini posterior uncertainty.
    maxsd xmm6,[zero]
    xor eax,eax
.utility_validate:
    movsd xmm0,[rdx+rax*8]
    movq xmm1,[sign_mask]
    andpd xmm0,xmm1
    ucomisd xmm0,[max_finite]
    ja .decision_invalid
    jp .decision_invalid
    inc rax
    cmp rax,r10
    jb .utility_validate
    xor r9d,r9d                   ; action
    pxor xmm4,xmm4
    mov r11,-1                    ; best action / first marker
.action:
    pxor xmm0,xmm0
    xor eax,eax
    mov r10,r9
    imul r10,rsi
.outcome:
    movsd xmm1,[rdi+rax*8]
    mulsd xmm1,[rdx+r10*8]
    addsd xmm0,xmm1
    inc r10
    inc rax
    cmp rax,rsi
    jb .outcome
    movapd xmm1,xmm0
    movq xmm2,[sign_mask]
    andpd xmm1,xmm2
    ucomisd xmm1,[max_finite]
    ja .decision_invalid
    jp .decision_invalid
    cmp r11,-1
    je .new_best
    ucomisd xmm0,xmm4
    jbe .next_action
.new_best:
    movsd xmm4,xmm0
    mov r11,r9
.next_action:
    inc r9
    cmp r9,rcx
    jb .action
    xor r9d,r9d
.expected_write:
    pxor xmm0,xmm0
    xor eax,eax
    mov r10,r9
    imul r10,rsi
.expected_outcome:
    movsd xmm1,[rdi+rax*8]
    mulsd xmm1,[rdx+r10*8]
    addsd xmm0,xmm1
    inc r10
    inc rax
    cmp rax,rsi
    jb .expected_outcome
    movsd [r8+NEBO_DECISION_REPORT_EXPECTED_UTILITIES+r9*8],xmm0
    inc r9
    cmp r9,rcx
    jb .expected_write
    mov [r8+NEBO_DECISION_REPORT_ACTION],r11
    movsd [r8+NEBO_DECISION_REPORT_UTILITY],xmm4
    mov [r8+NEBO_DECISION_REPORT_ACTIONS],rcx
    mov [r8+NEBO_DECISION_REPORT_OUTCOMES],rsi
    mov qword [r8+NEBO_DECISION_REPORT_STATUS],NEBO_DECISION_OK
    movsd [r8+NEBO_DECISION_REPORT_POSTERIOR_UNCERTAINTY],xmm6
    mov qword [r8+NEBO_DECISION_REPORT_UTILITY_ASSUMPTIONS],NEBO_DECISION_UTILITY_PURE_CALLER_PROVIDED
    mov qword [r8+NEBO_DECISION_REPORT_SENSITIVITY_STATUS],NEBO_DECISION_SENSITIVITY_UNSUPPORTED
    xor eax,eax
    ret
.decision_invalid: mov eax,NEBO_DECISION_INVALID
    ret
.decision_limit: mov eax,NEBO_DECISION_LIMIT
    ret

; rdi=ascending finite losses, rsi=count, rdx=tail index, rcx=report.
NEBOC_ABI_FUNCTION nebo_prob_var_cvar_sorted_f64
    test rdi,rdi
    jz .risk_invalid
    test rcx,rcx
    jz .risk_invalid
    test rsi,rsi
    jz .risk_invalid
    cmp rsi,NEBO_DECISION_MAX_OUTCOMES
    ja .risk_limit
    cmp rdx,rsi
    jae .risk_invalid
    xor eax,eax
.risk_validate:
    movsd xmm0,[rdi+rax*8]
    movq xmm1,[sign_mask]
    andpd xmm0,xmm1
    ucomisd xmm0,[max_finite]
    ja .risk_invalid
    jp .risk_invalid
    test rax,rax
    jz .risk_next
    ucomisd xmm0,[rdi+rax*8-8]
    jb .risk_invalid
.risk_next:
    inc rax
    cmp rax,rsi
    jb .risk_validate
    movsd xmm0,[rdi+rdx*8]
    pxor xmm1,xmm1
    mov rax,rdx
.tail:
    addsd xmm1,[rdi+rax*8]
    inc rax
    cmp rax,rsi
    jb .tail
    movapd xmm2,xmm1
    movq xmm3,[sign_mask]
    andpd xmm2,xmm3
    ucomisd xmm2,[max_finite]
    ja .risk_invalid
    jp .risk_invalid
    mov rax,rsi
    sub rax,rdx
    cvtsi2sd xmm2,rax
    divsd xmm1,xmm2
    movsd [rcx+NEBO_RISK_REPORT_VAR],xmm0
    movsd [rcx+NEBO_RISK_REPORT_CVAR],xmm1
    mov [rcx+NEBO_RISK_REPORT_TAIL_INDEX],rdx
    mov [rcx+NEBO_RISK_REPORT_COUNT],rsi
    xor eax,eax
    ret
.risk_invalid: mov eax,NEBO_DECISION_INVALID
    ret
.risk_limit: mov eax,NEBO_DECISION_LIMIT
    ret

; rdi=probabilities f64, rsi=binary observation bytes, rdx=count, rcx=report.
NEBOC_ABI_FUNCTION nebo_prob_brier_binary_f64
    test rdi,rdi
    jz .cal_invalid
    test rsi,rsi
    jz .cal_invalid
    test rcx,rcx
    jz .cal_invalid
    test rdx,rdx
    jz .cal_invalid
    cmp rdx,NEBO_DECISION_MAX_OUTCOMES
    ja .cal_limit
    xor eax,eax
.cal_validate:
    movsd xmm0,[rdi+rax*8]
    ucomisd xmm0,xmm0
    jp .cal_invalid
    ucomisd xmm0,[zero]
    jb .cal_invalid
    ucomisd xmm0,[one]
    ja .cal_invalid
    cmp byte [rsi+rax],1
    ja .cal_invalid
    inc rax
    cmp rax,rdx
    jb .cal_validate
    pxor xmm2,xmm2
    pxor xmm3,xmm3
    pxor xmm4,xmm4
    xor eax,eax
.cal_sum:
    movsd xmm0,[rdi+rax*8]
    addsd xmm3,xmm0
    movzx r8d,byte [rsi+rax]
    cvtsi2sd xmm1,r8
    addsd xmm4,xmm1
    subsd xmm0,xmm1
    mulsd xmm0,xmm0
    addsd xmm2,xmm0
    inc rax
    cmp rax,rdx
    jb .cal_sum
    cvtsi2sd xmm0,rdx
    divsd xmm2,xmm0
    divsd xmm3,xmm0
    divsd xmm4,xmm0
    movsd [rcx+NEBO_CALIBRATION_REPORT_BRIER],xmm2
    movsd [rcx+NEBO_CALIBRATION_REPORT_MEAN_PREDICTED],xmm3
    movsd [rcx+NEBO_CALIBRATION_REPORT_MEAN_OBSERVED],xmm4
    mov [rcx+NEBO_CALIBRATION_REPORT_COUNT],rdx
    xor eax,eax
    ret
.cal_invalid: mov eax,NEBO_DECISION_INVALID
    ret
.cal_limit: mov eax,NEBO_DECISION_LIMIT
    ret

; rdi=probabilities f64, rsi=binary observation bytes, rdx=count, rcx=out mean log score.
NEBOC_ABI_FUNCTION nebo_prob_log_score_binary_f64
    test rdi,rdi
    jz .log_invalid
    test rsi,rsi
    jz .log_invalid
    test rcx,rcx
    jz .log_invalid
    test rdx,rdx
    jz .log_invalid
    cmp rdx,NEBO_DECISION_MAX_OUTCOMES
    ja .log_limit
    xor eax,eax
.log_validate:
    movsd xmm0,[rdi+rax*8]
    ucomisd xmm0,xmm0
    jp .log_invalid
    ucomisd xmm0,[zero]
    jb .log_invalid
    ucomisd xmm0,[one]
    ja .log_invalid
    cmp byte [rsi+rax],1
    ja .log_invalid
    je .log_observed_one_validate
    ucomisd xmm0,[one]
    jae .log_invalid
    jmp .log_validate_next
.log_observed_one_validate:
    ucomisd xmm0,[zero]
    jbe .log_invalid
.log_validate_next:
    inc rax
    cmp rax,rdx
    jb .log_validate
    sub rsp,16
    pxor xmm2,xmm2
    xor eax,eax
.log_sum:
    movsd xmm0,[rdi+rax*8]
    cmp byte [rsi+rax],1
    je .log_probability_ready
    movsd xmm1,[one]
    subsd xmm1,xmm0
    movapd xmm0,xmm1
.log_probability_ready:
    movsd [rsp],xmm0
    fldln2
    fld qword [rsp]
    fyl2x
    fstp qword [rsp+8]
    addsd xmm2,[rsp+8]
    inc rax
    cmp rax,rdx
    jb .log_sum
    cvtsi2sd xmm0,rdx
    divsd xmm2,xmm0
    movsd [rcx],xmm2
    add rsp,16
    xor eax,eax
    ret
.log_invalid: mov eax,NEBO_DECISION_INVALID
    ret
.log_limit: mov eax,NEBO_DECISION_LIMIT
    ret

; rdi=aleatoric f64, rsi=epistemic f64, rdx=eligibility, rcx=report.
NEBOC_ABI_FUNCTION nebo_prob_uncertainty_decompose_f64
    test rdi,rdi
    jz .uncertainty_invalid
    test rsi,rsi
    jz .uncertainty_invalid
    test rcx,rcx
    jz .uncertainty_invalid
    cmp rdx,NEBO_UNCERTAINTY_COMPONENTS_SUPPORTED
    jne .uncertainty_unsupported
    movsd xmm0,[rdi]
    movsd xmm1,[rsi]
    movapd xmm2,xmm0
    movq xmm3,[sign_mask]
    andpd xmm2,xmm3
    ucomisd xmm2,[max_finite]
    ja .uncertainty_invalid
    jp .uncertainty_invalid
    movapd xmm2,xmm1
    andpd xmm2,xmm3
    ucomisd xmm2,[max_finite]
    ja .uncertainty_invalid
    jp .uncertainty_invalid
    ucomisd xmm0,[zero]
    jb .uncertainty_invalid
    ucomisd xmm1,[zero]
    jb .uncertainty_invalid
    movapd xmm2,xmm0
    addsd xmm2,xmm1
    movapd xmm3,xmm2
    movq xmm4,[sign_mask]
    andpd xmm3,xmm4
    ucomisd xmm3,[max_finite]
    ja .uncertainty_invalid
    movsd [rcx+NEBO_UNCERTAINTY_REPORT_ALEATORIC],xmm0
    movsd [rcx+NEBO_UNCERTAINTY_REPORT_EPISTEMIC],xmm1
    movsd [rcx+NEBO_UNCERTAINTY_REPORT_TOTAL],xmm2
    mov qword [rcx+NEBO_UNCERTAINTY_REPORT_STATUS],NEBO_DECISION_OK
    xor eax,eax
    ret
.uncertainty_invalid: mov eax,NEBO_DECISION_INVALID
    ret
.uncertainty_unsupported: mov eax,NEBO_DECISION_UNSUPPORTED
    ret

; rdi=redacted versioned report bytes, rsi=len, rdx=provenance digest.
NEBOC_ABI_FUNCTION nebo_prob_report_provenance_digest
    test rdi,rdi
    jz .digest_invalid
    test rdx,rdx
    jz .digest_invalid
    test rsi,rsi
    jz .digest_invalid
    cmp rsi,NEBO_DECISION_MAX_REPORT_BYTES
    ja .digest_limit
    mov rax,0xcbf29ce484222325
    mov r8,0x100000001b3
    xor ecx,ecx
.digest:
    movzx r9d,byte [rdi+rcx]
    xor rax,r9
    imul rax,r8
    inc rcx
    cmp rcx,rsi
    jb .digest
    mov [rdx],rax
    xor eax,eax
    ret
.digest_invalid: mov eax,NEBO_DECISION_INVALID
    ret
.digest_limit: mov eax,NEBO_DECISION_LIMIT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
