; G040 bounded schema-format validator and deterministic generator receipt.
section .rodata
cli_protocol_magic: db 'NEBO-PROTOCOL-SCHEMA-V1'
cli_protocol_report:
 db 'protocol-generate v1',10
 db 'schema-format=NEBO-PROTOCOL-SCHEMA-V1',10
 db 'generator=scripts/rf46-g40/protocol_generate.py',10
 db 'artifacts=client.no,server.no,mock.no,documentation.md,conformance.tsv',10
 db 'compiler-pipeline=build/bin/neboc check',10
 db 'deterministic=YES',10
 db 'source-syntax=NO_NEW_SYNTAX',10
cli_protocol_report_end:
cli_protocol_fuzz_report:
 db 'protocol-fuzz v1',10
 db 'schema-format=NEBO-PROTOCOL-SCHEMA-V1',10
 db 'corpus=frames,state-machines,schema-mutations',10
 db 'limits=frame:65536;queue:64;seed:4007',10
 db 'network=FORBIDDEN',10
 db 'runner=scripts/rf46-g40/protocol_fuzz.py',10
cli_protocol_fuzz_report_end:
cli_protocol_error: db 'NG40_F0501: invalid or unsupported protocol schema',10
cli_protocol_error_end:
section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_protocol_generate:
    lea rsi,[rel cli_source]
    lea rdi,[rel cli_protocol_magic]
    mov ecx,23
    repe cmpsb
    jne .bad
    cmp byte [rsi],10
    jne .bad
    lea rdi,[rel cli_protocol_report]
    mov esi,cli_protocol_report_end-cli_protocol_report
    call cli_write_stdout
    xor eax,eax
    ret
.bad:
    lea rdi,[rel cli_protocol_error]
    mov esi,cli_protocol_error_end-cli_protocol_error
    call cli_write_stderr
    mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
    ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_protocol_fuzz:
    lea rsi,[rel cli_source]
    lea rdi,[rel cli_protocol_magic]
    mov ecx,23
    repe cmpsb
    jne .bad
    cmp byte [rsi],10
    jne .bad
    lea rdi,[rel cli_protocol_fuzz_report]
    mov esi,cli_protocol_fuzz_report_end-cli_protocol_fuzz_report
    call cli_write_stdout
    xor eax,eax
    ret
.bad:
    lea rdi,[rel cli_protocol_error]
    mov esi,cli_protocol_error_end-cli_protocol_error
    call cli_write_stderr
    mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
    ret
%undef call
