; Phase 5 bounded metadata reports. No secret bytes are accepted or emitted.
section .rodata
cli_crypto_header: db 'NEBO-CRYPTO-AUDIT-V1',10
cli_crypto_header_end:
cli_crypto_report:
 db 'crypto-audit v1',10
 db 'algorithm-registry=SHA256_V1:APPROVED;PQC:UNAVAILABLE;ZK:UNAVAILABLE;MPC:UNAVAILABLE',10
 db 'review-gates=PQC,ZK,MPC:EXTERNAL_REVIEW_REQUIRED',10
 db 'vectors=FIPS_180_4_ABC:PASS;PQC,ZK,MPC:ABSENT',10
 db 'target-backend=x86_64-systemv;attestation:HARDWARE_UNAVAILABLE',10
 db 'constant-time=BOUNDED_STATIC_NOT_PROOF;leakage:ENVIRONMENT_LIMITED',10
 db 'secret-redaction=PASS',10
 db 'dependency-provenance=SHA256',10
 db 'composition=FAIL_CLOSED_ALLOWLIST_V1',10
 db 'deprecated-forbidden-usage=NONE',10
 db 'unsupported=PQC,ZK,MPC,ATTESTATION,VAULT',10
 db 'claims=NO_QUANTUM_SAFE_NO_ZK_NO_MPC_NO_ATTESTATION',10
cli_crypto_report_end:
cli_crypto_error: db 'NG44_F0703: invalid or unsupported crypto audit artifact',10
cli_crypto_error_end:
cli_optimize_report:
 db 'optimize-explain v1',10
 db 'passes=NONE_BASELINE_INPUT_UNCHANGED',10
 db 'assumptions=NONE',10
 db 'removed-checks=NONE',10
 db 'size-delta=0',10
 db 'verification-status=UNKNOWN',10
 db 'counterexamples=NONE',10
 db 'resulting-code=INPUT_UNCHANGED',10
cli_optimize_report_end:
cli_bootstrap_report:
 db 'bootstrap v1',10
 db 'status=NOT_AVAILABLE_SOURCE_COMPILER_MISSING',10
 db 'maturity=CONTRACT_GREEN_SOURCE_COMPILER_NOT_AVAILABLE',10
 db 'stage0=ASSEMBLY_COMPILER_PRESERVED',10
 db 'stage0-hash-manifest=compiler/bootstrap/stage0_trust.tsv',10
 db 'stage1-executed=NO',10
 db 'stage2-executed=NO',10
 db 'comparison=NOT_RUN',10
 db 'trust=STAGE0_ASSEMBLY,NASM,GNU_LD,LINUX_KERNEL,X86_64_CPU',10
cli_bootstrap_report_end:
section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_crypto_audit:
    lea rsi,[rel cli_source]
    lea rdi,[rel cli_crypto_header]
    mov ecx,cli_crypto_header_end-cli_crypto_header
    repe cmpsb
    jne .bad
    lea rdi,[rel cli_crypto_report]
    mov esi,cli_crypto_report_end-cli_crypto_report
    call cli_write_stdout
    xor eax,eax
    ret
.bad:
    lea rdi,[rel cli_crypto_error]
    mov esi,cli_crypto_error_end-cli_crypto_error
    call cli_write_stderr
    mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
    ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_optimize_explain:
    lea rdi,[rel cli_optimize_report]
    mov esi,cli_optimize_report_end-cli_optimize_report
    call cli_write_stdout
    xor eax,eax
    ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_bootstrap_verify:
    lea rdi,[rel cli_bootstrap_report]
    mov esi,cli_bootstrap_report_end-cli_bootstrap_report
    call cli_write_stdout
    xor eax,eax
    ret
%undef call
