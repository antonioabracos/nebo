bits 64
default rel
%include "runtime/probabilistic/decision_risk.inc"
extern nebo_prob_expected_utility_choose_f64
extern nebo_prob_var_cvar_sorted_f64
extern nebo_prob_brier_binary_f64
extern nebo_prob_log_score_binary_f64
extern nebo_prob_uncertainty_decompose_f64
extern nebo_prob_report_provenance_digest
section .data
probabilities dq 0.25,0.75
bad_log_probabilities dq 0.0,0.75
utilities dq 4.0,0.0,0.0,2.0
expected_utility dq 1.5
losses dq 1.0,2.0,3.0,10.0
ten dq 10.0
bad_losses dq 1.0,3.0,2.0
infinite_losses dq 1.0,0x7ff0000000000000
infinite_utilities dq 0x7ff0000000000000,0.0,0.0,2.0
observations db 0,1
impossible_observations db 1,1
expected_brier dq 0.0625
expected_log_score dq -0.2876820724517809
abs_mask dq 0x7fffffffffffffff
log_tolerance dq 0.000000000000001
aleatoric dq 0.125
epistemic dq 0.25
uncertainty_total dq 0.375
report_bytes db "RF46-PROB-REPORT-v1;seed=42;raw_observations=redacted"
report_len equ $-report_bytes
section .bss
decision_report resb NEBO_DECISION_REPORT_MAX_SIZE
risk_report resb NEBO_RISK_REPORT_SIZE
calibration_report resb NEBO_CALIBRATION_REPORT_SIZE
log_score resq 1
uncertainty_report resb NEBO_UNCERTAINTY_REPORT_SIZE
digest resq 1
failure_code resd 1
section .text
global _start
_start:
    mov dword [failure_code],1
    lea rdi,[probabilities]
    mov esi,2
    lea rdx,[utilities]
    mov ecx,2
    lea r8,[decision_report]
    mov r9d,NEBO_DECISION_REPORT_MAX_SIZE
    call nebo_prob_expected_utility_choose_f64
    test eax,eax
    jnz fail
    cmp qword [decision_report+NEBO_DECISION_REPORT_ACTION],1
    jne fail
    mov rax,[expected_utility]
    cmp [decision_report+NEBO_DECISION_REPORT_UTILITY],rax
    jne fail
    mov rax,[expected_utility]
    cmp [decision_report+NEBO_DECISION_REPORT_EXPECTED_UTILITIES+8],rax
    jne fail
    mov rax,[uncertainty_total]
    cmp [decision_report+NEBO_DECISION_REPORT_POSTERIOR_UNCERTAINTY],rax
    jne fail
    mov dword [failure_code],2
    lea rdi,[losses]
    mov esi,4
    mov edx,3
    lea rcx,[risk_report]
    call nebo_prob_var_cvar_sorted_f64
    test eax,eax
    jnz fail
    mov rax,[ten]
    cmp [risk_report+NEBO_RISK_REPORT_VAR],rax
    jne fail
    cmp [risk_report+NEBO_RISK_REPORT_CVAR],rax
    jne fail
    mov dword [failure_code],3
    lea rdi,[probabilities]
    lea rsi,[observations]
    mov edx,2
    lea rcx,[calibration_report]
    call nebo_prob_brier_binary_f64
    test eax,eax
    jnz fail
    mov rax,[expected_brier]
    cmp [calibration_report+NEBO_CALIBRATION_REPORT_BRIER],rax
    jne fail
    mov dword [failure_code],4
    lea rdi,[probabilities]
    lea rsi,[observations]
    mov edx,2
    lea rcx,[log_score]
    call nebo_prob_log_score_binary_f64
    test eax,eax
    jnz fail
    movsd xmm0,[log_score]
    subsd xmm0,[expected_log_score]
    movq xmm1,[rel abs_mask]
    andpd xmm0,xmm1
    ucomisd xmm0,[rel log_tolerance]
    ja fail
    mov dword [failure_code],5
    lea rdi,[aleatoric]
    lea rsi,[epistemic]
    mov edx,NEBO_UNCERTAINTY_COMPONENTS_SUPPORTED
    lea rcx,[uncertainty_report]
    call nebo_prob_uncertainty_decompose_f64
    test eax,eax
    jnz fail
    mov rax,[uncertainty_total]
    cmp [uncertainty_report+NEBO_UNCERTAINTY_REPORT_TOTAL],rax
    jne fail
    mov dword [failure_code],6
    lea rdi,[report_bytes]
    mov esi,report_len
    lea rdx,[digest]
    call nebo_prob_report_provenance_digest
    test eax,eax
    jnz fail
    cmp qword [digest],0
    je fail
    mov dword [failure_code],7
    mov qword [risk_report],0x1234
    lea rdi,[bad_losses]
    mov esi,3
    mov edx,1
    lea rcx,[risk_report]
    call nebo_prob_var_cvar_sorted_f64
    cmp eax,NEBO_DECISION_INVALID
    jne fail
    cmp qword [risk_report],0x1234
    jne fail
    mov dword [failure_code],8
    mov qword [risk_report],0x5678
    lea rdi,[infinite_losses]
    mov esi,2
    mov edx,1
    lea rcx,[risk_report]
    call nebo_prob_var_cvar_sorted_f64
    cmp eax,NEBO_DECISION_INVALID
    jne fail
    cmp qword [risk_report],0x5678
    jne fail
    mov dword [failure_code],9
    mov qword [decision_report],0x9abc
    lea rdi,[probabilities]
    mov esi,2
    lea rdx,[infinite_utilities]
    mov ecx,2
    lea r8,[decision_report]
    mov r9d,NEBO_DECISION_REPORT_MAX_SIZE
    call nebo_prob_expected_utility_choose_f64
    cmp eax,NEBO_DECISION_INVALID
    jne fail
    cmp qword [decision_report],0x9abc
    jne fail
    mov dword [failure_code],10
    mov qword [decision_report],0xa5a5
    lea rdi,[probabilities]
    mov esi,2
    lea rdx,[utilities]
    mov ecx,2
    lea r8,[decision_report]
    mov r9d,NEBO_DECISION_REPORT_HEADER_SIZE-1
    call nebo_prob_expected_utility_choose_f64
    cmp eax,NEBO_DECISION_LIMIT
    jne fail
    cmp qword [decision_report],0xa5a5
    jne fail
    mov dword [failure_code],11
    mov qword [log_score],0xb6b6
    lea rdi,[bad_log_probabilities]
    lea rsi,[impossible_observations]
    mov edx,2
    lea rcx,[log_score]
    call nebo_prob_log_score_binary_f64
    cmp eax,NEBO_DECISION_INVALID
    jne fail
    cmp qword [log_score],0xb6b6
    jne fail
    mov dword [failure_code],12
    mov qword [uncertainty_report],0xdef0
    lea rdi,[aleatoric]
    lea rsi,[epistemic]
    xor edx,edx
    lea rcx,[uncertainty_report]
    call nebo_prob_uncertainty_decompose_f64
    cmp eax,NEBO_DECISION_UNSUPPORTED
    jne fail
    cmp qword [uncertainty_report],0xdef0
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,[failure_code]
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
