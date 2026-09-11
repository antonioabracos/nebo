; G039 deterministic local Wasm/eBPF emit, inspect, conformance and SBOM tools.
%ifndef NEBO_PORTABLE_CLI_INC
%define NEBO_PORTABLE_CLI_INC 1

section .rodata
cli_portable_wasm_prefix:
 db 0,0x61,0x73,0x6d,1,0,0,0
 db 0,18,9,'nebo.g039'
cli_portable_wasm_prefix_end:
cli_portable_wasm_report:
 db 'wasm-inspect v1',10
 db 'format=wasm32-core-v1',10
 db 'sections=custom:1',10
 db 'imports=0',10
 db 'exports=0',10
 db 'limits=source-bytes:1048576',10
 db 'bytes='
cli_portable_wasm_report_end:
cli_portable_hash: db 10,'fnv1a64='
cli_portable_hash_end:
cli_portable_test_wasm: db 'portable-test v1',10,'kind=wasm32',10,'validation=PASS',10,'bytes='
cli_portable_test_wasm_end:
cli_portable_test_bpf: db 'portable-test v1',10,'kind=ebpf-static-subset',10,'validation=PASS',10,'kernel-load=NOT_EXECUTED',10,'bytes='
cli_portable_test_bpf_end:
cli_portable_test_suffix: db 'network=FORBIDDEN',10,'ambient-authority=NO',10
cli_portable_test_suffix_end:
cli_portable_sbom_prefix: db '{"schema":1,"format":"NEBO-PORTABLE-SBOM-v1","kind":"'
cli_portable_sbom_prefix_end:
cli_portable_sbom_wasm: db 'wasm32'
cli_portable_sbom_wasm_end:
cli_portable_sbom_bpf: db 'ebpf-static-subset'
cli_portable_sbom_bpf_end:
cli_portable_sbom_bytes: db '","bytes":'
cli_portable_sbom_bytes_end:
cli_portable_sbom_hash: db ',"fnv1a64":"0x'
cli_portable_sbom_hash_end:
cli_portable_sbom_suffix: db '","network":false,"kernelLoad":"NOT_EXECUTED"}',10
cli_portable_sbom_suffix_end:
cli_portable_emit_error: db 'NEBO-G039-CLI-001: source must be non-empty bounded Nebo with start()',10
cli_portable_emit_error_end:
cli_portable_artifact_error: db 'NEBO-G039-CLI-002: malformed or unsupported portable artifact',10
cli_portable_artifact_error_end:
cli_portable_start_atom: db 'start()'
cli_portable_start_atom_end:
cli_portable_hex_digits: db '0123456789abcdef'

section .bss
cli_portable_output: resb 32
cli_portable_hex: resb 16

section .text
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL

cli_portable_digest:
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

cli_portable_source_valid:
 mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 test r8,r8
 jz .bad
 lea r9,[rel cli_source]
 xor ecx,ecx
.nul_scan:
 cmp byte [r9+rcx],0
 je .bad
 inc rcx
 cmp rcx,r8
 jb .nul_scan
 cmp r8,cli_portable_start_atom_end-cli_portable_start_atom
 jb .bad
 sub r8,cli_portable_start_atom_end-cli_portable_start_atom
 xor r10d,r10d
.candidate:
 lea rdi,[r9+r10]
 lea rsi,[rel cli_portable_start_atom]
 mov ecx,cli_portable_start_atom_end-cli_portable_start_atom
 repe cmpsb
 je .good
 inc r10
 cmp r10,r8
 jbe .candidate
.bad:
 xor eax,eax
 ret
.good:
 mov eax,1
 ret

cli_emit_wasm:
 call cli_frontend_validate
 test eax,eax
 jnz cli_portable_emit_invalid
 call cli_portable_source_valid
 test eax,eax
 jz cli_portable_emit_invalid
 call cli_portable_digest
 push rax
 lea rdi,[rel cli_portable_output]
 lea rsi,[rel cli_portable_wasm_prefix]
 mov ecx,cli_portable_wasm_prefix_end-cli_portable_wasm_prefix
 rep movsb
 pop rax
 mov [rdi],rax
 lea rdi,[rel cli_portable_output]
 mov esi,(cli_portable_wasm_prefix_end-cli_portable_wasm_prefix)+8
 call cli_write_stdout
 xor eax,eax
 ret

cli_emit_bpf:
 call cli_frontend_validate
 test eax,eax
 jnz cli_portable_emit_invalid
 call cli_portable_source_valid
 test eax,eax
 jz cli_portable_emit_invalid
 call cli_portable_digest
 lea r8,[rel cli_portable_output]
 mov dword [r8],0x000000b7
 mov [r8+4],eax
 mov qword [r8+8],0x0000000000000095
 mov rdi,r8
 mov esi,16
 call cli_write_stdout
 xor eax,eax
 ret

cli_portable_emit_invalid:
 lea rdi,[rel cli_portable_emit_error]
 mov esi,cli_portable_emit_error_end-cli_portable_emit_error
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret

cli_portable_artifact_kind:
 mov r8,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 lea r9,[rel cli_source]
 cmp r8,(cli_portable_wasm_prefix_end-cli_portable_wasm_prefix)+8
 jne .try_bpf
 mov rdi,r9
 lea rsi,[rel cli_portable_wasm_prefix]
 mov ecx,cli_portable_wasm_prefix_end-cli_portable_wasm_prefix
 repe cmpsb
 jne .bad
 mov eax,1
 ret
.try_bpf:
 cmp r8,16
 jne .bad
 cmp dword [r9],0x000000b7
 jne .bad
 cmp qword [r9+8],0x0000000000000095
 jne .bad
 mov eax,2
 ret
.bad:
 xor eax,eax
 ret

cli_wasm_inspect:
 call cli_portable_artifact_kind
 cmp eax,1
 jne cli_portable_artifact_invalid
 lea rdi,[rel cli_portable_wasm_report]
 mov esi,cli_portable_wasm_report_end-cli_portable_wasm_report
 call cli_write_stdout
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 call cli_write_u64_stdout
 lea rdi,[rel cli_portable_hash]
 mov esi,cli_portable_hash_end-cli_portable_hash
 call cli_write_stdout
 call cli_portable_digest
 mov rdi,rax
 call cli_write_hex_line
 xor eax,eax
 ret

cli_portable_test:
 call cli_portable_artifact_kind
 test eax,eax
 jz cli_portable_artifact_invalid
 cmp eax,1
 jne .bpf
 lea rdi,[rel cli_portable_test_wasm]
 mov esi,cli_portable_test_wasm_end-cli_portable_test_wasm
 jmp .heading
.bpf:
 lea rdi,[rel cli_portable_test_bpf]
 mov esi,cli_portable_test_bpf_end-cli_portable_test_bpf
.heading:
 call cli_write_stdout
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 call cli_write_u64_stdout
 lea rdi,[rel cli_portable_hash]
 mov esi,cli_portable_hash_end-cli_portable_hash
 call cli_write_stdout
 call cli_portable_digest
 mov rdi,rax
 call cli_write_hex_line
 lea rdi,[rel cli_portable_test_suffix]
 mov esi,cli_portable_test_suffix_end-cli_portable_test_suffix
 call cli_write_stdout
 xor eax,eax
 ret

cli_portable_write_hex_raw:
 lea r8,[rel cli_portable_hex]
 mov ecx,16
 mov r9,rdi
 lea r10,[rel cli_portable_hex_digits]
.hex:
 mov rax,r9
 shr rax,60
 mov al,[r10+rax]
 mov [r8],al
 shl r9,4
 inc r8
 dec rcx
 jnz .hex
 lea rdi,[rel cli_portable_hex]
 mov esi,16
 jmp cli_write_stdout

cli_portable_sbom:
 call cli_portable_artifact_kind
 test eax,eax
 jz cli_portable_artifact_invalid
 push rax
 lea rdi,[rel cli_portable_sbom_prefix]
 mov esi,cli_portable_sbom_prefix_end-cli_portable_sbom_prefix
 call cli_write_stdout
 pop rax
 cmp eax,1
 jne .bpf
 lea rdi,[rel cli_portable_sbom_wasm]
 mov esi,cli_portable_sbom_wasm_end-cli_portable_sbom_wasm
 jmp .kind
.bpf:
 lea rdi,[rel cli_portable_sbom_bpf]
 mov esi,cli_portable_sbom_bpf_end-cli_portable_sbom_bpf
.kind:
 call cli_write_stdout
 lea rdi,[rel cli_portable_sbom_bytes]
 mov esi,cli_portable_sbom_bytes_end-cli_portable_sbom_bytes
 call cli_write_stdout
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 call cli_write_u64_stdout
 lea rdi,[rel cli_portable_sbom_hash]
 mov esi,cli_portable_sbom_hash_end-cli_portable_sbom_hash
 call cli_write_stdout
 call cli_portable_digest
 mov rdi,rax
 call cli_portable_write_hex_raw
 lea rdi,[rel cli_portable_sbom_suffix]
 mov esi,cli_portable_sbom_suffix_end-cli_portable_sbom_suffix
 call cli_write_stdout
 xor eax,eax
 ret

cli_portable_artifact_invalid:
 lea rdi,[rel cli_portable_artifact_error]
 mov esi,cli_portable_artifact_error_end-cli_portable_artifact_error
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret

%undef call
%endif
