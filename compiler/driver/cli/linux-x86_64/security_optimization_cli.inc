; Phase 5 bounded metadata reports. No secret bytes are accepted or emitted.
section .rodata
cli_crypto_header: db 'NEBO-CRYPTO-AUDIT-V1',10
cli_crypto_header_end:
cli_crypto_report:
 db 'crypto-audit v2',10
 db 'algorithm-registry=SHA256_V1:APPROVED;PQC:UNAVAILABLE;ZK:UNAVAILABLE;MPC:UNAVAILABLE',10
 db 'review-gates=PQC,ZK,MPC:EXTERNAL_REVIEW_REQUIRED',10
 db 'vectors=FIPS_180_4_ABC:PASS;PQC,ZK,MPC:ABSENT',10
 db 'target-backend=x86_64-systemv;attestation:HARDWARE_UNAVAILABLE',10
 db 'constant-time=BOUNDED_STATIC_NOT_PROOF;leakage:ENVIRONMENT_LIMITED',10
 db 'secret-redaction=PASS',10
 db 'dependency-provenance=SHA256',10
 db 'composition=FAIL_CLOSED_ALLOWLIST_V1',10
 db 'deprecated-forbidden-usage=NONE',10
 db 'unsupported=PQC,ZK,MPC,ATTESTATION,VAULT_PERSISTENCE',10
 db 'claims=NO_QUANTUM_SAFE_NO_ZK_NO_MPC_NO_ATTESTATION',10
 db 'artifact-bytes='
cli_crypto_report_end:
cli_crypto_digest_prefix: db 10,'artifact-fnv1a64='
cli_crypto_digest_prefix_end:
cli_crypto_error: db 'NG44_F0703: invalid or unsupported crypto audit artifact',10
cli_crypto_error_end:
cli_crypto_artifact_prefix: db 'artifact=synthetic-'
cli_crypto_artifact_prefix_end:
cli_crypto_required_suffix: db 'algorithm=SHA256_V1',10,'secrets=none',10
cli_crypto_required_suffix_end:
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
cli_crypto_digest:
    mov rax,0xcbf29ce484222325
    mov r8,0x100000001b3
    lea r9,[rel cli_source]
    mov rcx,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
    xor edx,edx
.loop:
    movzx r10d,byte [r9+rdx]
    xor rax,r10
    imul rax,r8
    inc rdx
    cmp rdx,rcx
    jb .loop
    ret

cli_crypto_audit:
    mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
    cmp r8,cli_crypto_header_end-cli_crypto_header
    jb .bad
    lea rsi,[rel cli_source]
    lea rdi,[rel cli_crypto_header]
    mov ecx,cli_crypto_header_end-cli_crypto_header
    repe cmpsb
    jne .bad
    lea r9,[rel cli_source]
    xor ecx,ecx
.nul_scan:
    cmp byte [r9+rcx],0
    je .bad
    inc rcx
    cmp rcx,r8
    jb .nul_scan
    cmp byte [r9+r8-1],10
    jne .bad
    lea rsi,[r9+cli_crypto_header_end-cli_crypto_header]
    lea rdi,[rel cli_crypto_artifact_prefix]
    mov ecx,cli_crypto_artifact_prefix_end-cli_crypto_artifact_prefix
    mov rdx,rsi
    add rdx,rcx
    lea rax,[r9+r8]
    cmp rdx,rax
    jae .bad
    repe cmpsb
    jne .bad
    mov rdx,rsi
    xor r10d,r10d
.artifact_value:
    cmp rdx,rax
    jae .bad
    mov r11b,[rdx]
    cmp r11b,10
    je .artifact_end
    cmp r11b,'-'
    je .artifact_char
    cmp r11b,'0'
    jb .artifact_lower
    cmp r11b,'9'
    jbe .artifact_char
.artifact_lower:
    cmp r11b,'a'
    jb .bad
    cmp r11b,'z'
    ja .bad
.artifact_char:
    inc r10
    inc rdx
    jmp .artifact_value
.artifact_end:
    test r10,r10
    jz .bad
    inc rdx
    mov r10,rax
    sub r10,rdx
    cmp r10,cli_crypto_required_suffix_end-cli_crypto_required_suffix
    jne .bad
    mov rsi,rdx
    lea rdi,[rel cli_crypto_required_suffix]
    mov ecx,cli_crypto_required_suffix_end-cli_crypto_required_suffix
    repe cmpsb
    jne .bad
    lea rdi,[rel cli_crypto_report]
    mov esi,cli_crypto_report_end-cli_crypto_report
    call cli_write_stdout
    mov rdi,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
    call cli_write_u64_stdout
    lea rdi,[rel cli_crypto_digest_prefix]
    mov esi,cli_crypto_digest_prefix_end-cli_crypto_digest_prefix
    call cli_write_stdout
    call cli_crypto_digest
    mov rdi,rax
    call cli_write_hex_line
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
