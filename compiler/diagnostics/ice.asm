; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F08 deterministic local-only ICE reports, redaction and bundles.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/ice.inc"

section .rodata
bundle_magic: db 'NEBO-ICE-BUNDLE-v1',10
bundle_magic_len equ $-bundle_magic
line_code: db 'code=NEBO-ICE-0001',10
line_code_len equ $-line_code
line_phase: db 'phase='
line_phase_len equ $-line_phase
line_invariant: db 'invariant='
line_invariant_len equ $-line_invariant
line_context: db 'context='
line_context_len equ $-line_context
line_node: db 'nodeIdentity='
line_node_len equ $-line_node
line_node_schema: db 'nodeSchema='
line_node_schema_len equ $-line_node_schema
line_trace: db 'phaseTrace='
line_trace_len equ $-line_trace
line_version: db 'compilerVersion='
line_version_len equ $-line_version
line_target: db 'target='
line_target_len equ $-line_target
line_options: db 'optionsDigest='
line_options_len equ $-line_options
line_features: db 'featureDigest='
line_features_len equ $-line_features
line_source: db 'source='
line_source_len equ $-line_source
line_minimized: db 'minimized=bounded',10
line_minimized_len equ $-line_minimized
line_checksum: db 'checksum='
line_checksum_len equ $-line_checksum
redacted: db '<redacted>'
redacted_len equ $-redacted
comma: db ','
newline: db 10
tmp_suffix: db '.tmp',0
hex_digits: db '0123456789abcdef'

section .text
ice_append:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .ok
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_WRITER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .limit
 cmp r9,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 ja .limit
 cmp r9,NEBOC_ICE_MAX_BUNDLE_BYTES
 ja .limit
 mov r10,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test r10,r10
 jz .invalid
 add r10,r8
 xor ecx,ecx
.copy:
 cmp rcx,rdx
 jae .store
 mov al,[rsi+rcx]
 mov [r10+rcx],al
 inc rcx
 jmp .copy
.store:
 mov [rdi+NEBOC_WRITER_LENGTH_OFFSET],r9
.ok:
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

ice_u64:
 push rbx
 sub rsp,32
 mov rbx,rdi
 mov rax,rsi
 lea rsi,[rsp+32]
 xor ecx,ecx
 test rax,rax
 jnz .digits
 dec rsi
 mov byte [rsi],'0'
 mov ecx,1
 jmp .emit
.digits:
 mov r8d,10
.loop:
 xor edx,edx
 div r8
 add dl,'0'
 dec rsi
 mov [rsi],dl
 inc ecx
 test rax,rax
 jnz .loop
.emit:
 mov rdi,rbx
 mov edx,ecx
 call ice_append
 add rsp,32
 pop rbx
 ret

ice_hex64:
 sub rsp,24
 mov rax,rsi
 lea r8,[rel hex_digits]
 xor ecx,ecx
.loop:
 mov rdx,rax
 shr rdx,60
 mov dl,[r8+rdx]
 mov [rsp+rcx],dl
 shl rax,4
 inc rcx
 cmp rcx,16
 jb .loop
 lea rsi,[rsp]
 mov edx,16
 call ice_append
 add rsp,24
 ret

validate_writer:
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_ICE_MAX_BUNDLE_BYTES
 ja .invalid
 cmp qword [rdi+NEBOC_WRITER_LENGTH_OFFSET],rax
 ja .invalid
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; FNV-1a over a canonical byte slice.
ice_digest:
 mov rax,0xcbf29ce484222325
 mov r8,0x100000001b3
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .done
 movzx rdx,byte [rdi+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .loop
.done:
 ret

%macro APPEND_LITERAL 2
 mov rdi,r14
 lea rsi,[rel %1]
 mov edx,%2
 call ice_append
 test eax,eax
 jnz .bundle_rollback
%endmacro

; IceReport.new(out*, request*).
NEBOC_ABI_FUNCTION neboc_ice_report_new
 test rdi,rdi
 jz .new_invalid
 test rsi,rsi
 jz .new_invalid
 mov rax,[rsi+NEBOC_ICE_REQUEST_PHASE_OFFSET]
 test rax,rax
 jz .new_invalid
 mov rdx,[rsi+NEBOC_ICE_REQUEST_INVARIANT_LENGTH_OFFSET]
 test rdx,rdx
 jz .new_invalid
 cmp rdx,NEBOC_ICE_MAX_INVARIANT_BYTES
 ja .new_limit
 cmp qword [rsi+NEBOC_ICE_REQUEST_INVARIANT_OFFSET],0
 je .new_invalid
 mov rcx,[rsi+NEBOC_ICE_REQUEST_CONTEXT_LENGTH_OFFSET]
 cmp rcx,NEBOC_ICE_MAX_CONTEXT_BYTES
 ja .new_limit
 test rcx,rcx
 jz .context_ok
 cmp qword [rsi+NEBOC_ICE_REQUEST_CONTEXT_OFFSET],0
 je .new_invalid
.context_ok:
 mov [rdi+NEBOC_ICE_REPORT_PHASE_OFFSET],rax
 mov rax,[rsi+NEBOC_ICE_REQUEST_INVARIANT_OFFSET]
 mov [rdi+NEBOC_ICE_REPORT_INVARIANT_OFFSET],rax
 mov [rdi+NEBOC_ICE_REPORT_INVARIANT_LENGTH_OFFSET],rdx
 mov rax,[rsi+NEBOC_ICE_REQUEST_CONTEXT_OFFSET]
 mov [rdi+NEBOC_ICE_REPORT_CONTEXT_OFFSET],rax
 mov [rdi+NEBOC_ICE_REPORT_CONTEXT_LENGTH_OFFSET],rcx
 mov qword [rdi+NEBOC_ICE_REPORT_NODE_ID_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_NODE_SCHEMA_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_TRACE_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_TRACE_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_VERSION_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_VERSION_LENGTH_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_TARGET_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_TARGET_LENGTH_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_OPTIONS_DIGEST_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_FEATURE_DIGEST_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_REDACTION_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_BUNDLE_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_BUNDLE_LENGTH_OFFSET],0
 mov qword [rdi+NEBOC_ICE_REPORT_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.new_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.new_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Record a structural, versioned node identity (never a raw pointer).
NEBOC_ABI_FUNCTION neboc_ice_report_node_identity
 test rdi,rdi
 jz .node_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_ACTIVE_OFFSET],1
 jne .node_invalid
 test rsi,rsi
 jz .node_invalid
 test rdx,rdx
 jz .node_invalid
 mov [rdi+NEBOC_ICE_REPORT_NODE_ID_OFFSET],rsi
 mov [rdi+NEBOC_ICE_REPORT_NODE_SCHEMA_OFFSET],rdx
 xor eax,eax
 ret
.node_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Store a borrowed bounded list of completed phase identifiers.
NEBOC_ABI_FUNCTION neboc_ice_report_phase_trace
 test rdi,rdi
 jz .trace_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_ACTIVE_OFFSET],1
 jne .trace_invalid
 test rsi,rsi
 jz .trace_invalid
 test rdx,rdx
 jz .trace_invalid
 cmp rdx,NEBOC_ICE_MAX_TRACE_PHASES
 ja .trace_limit
 xor ecx,ecx
.trace_scan:
 cmp rcx,rdx
 jae .trace_ok
 cmp qword [rsi+rcx*8],0
 je .trace_invalid
 inc rcx
 jmp .trace_scan
.trace_ok:
 mov [rdi+NEBOC_ICE_REPORT_TRACE_OFFSET],rsi
 mov [rdi+NEBOC_ICE_REPORT_TRACE_COUNT_OFFSET],rdx
 xor eax,eax
 ret
.trace_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.trace_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ice_report_compiler_manifest
 test rdi,rdi
 jz .manifest_invalid
 test rsi,rsi
 jz .manifest_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_ACTIVE_OFFSET],1
 jne .manifest_invalid
 mov rax,[rsi+NEBOC_ICE_MANIFEST_VERSION_LENGTH_OFFSET]
 test rax,rax
 jz .manifest_invalid
 cmp rax,128
 ja .manifest_limit
 cmp qword [rsi+NEBOC_ICE_MANIFEST_VERSION_OFFSET],0
 je .manifest_invalid
 mov rdx,[rsi+NEBOC_ICE_MANIFEST_TARGET_LENGTH_OFFSET]
 test rdx,rdx
 jz .manifest_invalid
 cmp rdx,128
 ja .manifest_limit
 cmp qword [rsi+NEBOC_ICE_MANIFEST_TARGET_OFFSET],0
 je .manifest_invalid
 mov rcx,[rsi+NEBOC_ICE_MANIFEST_VERSION_OFFSET]
 mov [rdi+NEBOC_ICE_REPORT_VERSION_OFFSET],rcx
 mov [rdi+NEBOC_ICE_REPORT_VERSION_LENGTH_OFFSET],rax
 mov rcx,[rsi+NEBOC_ICE_MANIFEST_TARGET_OFFSET]
 mov [rdi+NEBOC_ICE_REPORT_TARGET_OFFSET],rcx
 mov [rdi+NEBOC_ICE_REPORT_TARGET_LENGTH_OFFSET],rdx
 mov rcx,[rsi+NEBOC_ICE_MANIFEST_OPTIONS_DIGEST_OFFSET]
 mov [rdi+NEBOC_ICE_REPORT_OPTIONS_DIGEST_OFFSET],rcx
 mov rcx,[rsi+NEBOC_ICE_MANIFEST_FEATURE_DIGEST_OFFSET]
 mov [rdi+NEBOC_ICE_REPORT_FEATURE_DIGEST_OFFSET],rcx
 xor eax,eax
 ret
.manifest_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.manifest_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_ice_report_redact
 test rdi,rdi
 jz .redact_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_ACTIVE_OFFSET],1
 jne .redact_invalid
 cmp rsi,NEBOC_ICE_REDACT_STRICT
 jb .redact_invalid
 cmp rsi,NEBOC_ICE_REDACT_METADATA
 ja .redact_invalid
 mov [rdi+NEBOC_ICE_REPORT_REDACTION_OFFSET],rsi
 lea rax,[rel redacted]
 mov [rdi+NEBOC_ICE_REPORT_CONTEXT_OFFSET],rax
 mov qword [rdi+NEBOC_ICE_REPORT_CONTEXT_LENGTH_OFFSET],redacted_len
 xor eax,eax
 ret
.redact_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; CompilerInvariant.assert(condition, request, out_report).
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_compiler_invariant_assert
 test rdi,rdi
 jz .assert_fail
 xor eax,eax
 ret
.assert_fail:
 mov rdi,rdx
 call neboc_ice_report_new
 test eax,eax
 jnz .assert_done
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.assert_done:
 ret

; Reproducer is deterministic and never reads environment or filesystem.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_ice_report_reproducer
 test rdi,rdi
 jz .bundle_invalid
 test rsi,rsi
 jz .bundle_invalid
 test rdx,rdx
 jz .bundle_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_ACTIVE_OFFSET],1
 jne .bundle_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_REDACTION_OFFSET],NEBOC_ICE_REDACT_STRICT
 jb .bundle_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_VERSION_LENGTH_OFFSET],0
 je .bundle_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_TARGET_LENGTH_OFFSET],0
 je .bundle_invalid
 mov rax,[rsi+NEBOC_ICE_REPRO_SOURCE_LENGTH_OFFSET]
 cmp rax,NEBOC_ICE_MAX_SOURCE_BYTES
 ja .bundle_limit
 mov rcx,[rsi+NEBOC_ICE_REPRO_MAX_SOURCE_OFFSET]
 cmp rcx,NEBOC_ICE_MAX_SOURCE_BYTES
 ja .bundle_limit
 cmp rax,rcx
 ja .bundle_limit
 test rax,rax
 jz .bundle_source_ok
 cmp qword [rsi+NEBOC_ICE_REPRO_SOURCE_OFFSET],0
 je .bundle_invalid
.bundle_source_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r14
 call validate_writer
 test eax,eax
 jnz .bundle_done
 mov rax,[r14+NEBOC_WRITER_LENGTH_OFFSET]
 mov [rsp],rax
 APPEND_LITERAL bundle_magic,bundle_magic_len
 APPEND_LITERAL line_code,line_code_len
 APPEND_LITERAL line_phase,line_phase_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_PHASE_OFFSET]
 call ice_u64
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_invariant,line_invariant_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_INVARIANT_OFFSET]
 mov rdx,[r12+NEBOC_ICE_REPORT_INVARIANT_LENGTH_OFFSET]
 call ice_append
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_context,line_context_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_CONTEXT_OFFSET]
 mov rdx,[r12+NEBOC_ICE_REPORT_CONTEXT_LENGTH_OFFSET]
 call ice_append
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_node,line_node_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_NODE_ID_OFFSET]
 call ice_hex64
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_node_schema,line_node_schema_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_NODE_SCHEMA_OFFSET]
 call ice_u64
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_trace,line_trace_len
 xor ebx,ebx
.bundle_trace:
 cmp rbx,[r12+NEBOC_ICE_REPORT_TRACE_COUNT_OFFSET]
 jae .bundle_trace_done
 test rbx,rbx
 jz .bundle_trace_item
 APPEND_LITERAL comma,1
.bundle_trace_item:
 mov rax,[r12+NEBOC_ICE_REPORT_TRACE_OFFSET]
 mov rdi,r14
 mov rsi,[rax+rbx*8]
 call ice_u64
 test eax,eax
 jnz .bundle_rollback
 inc rbx
 jmp .bundle_trace
.bundle_trace_done:
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_version,line_version_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_VERSION_OFFSET]
 mov rdx,[r12+NEBOC_ICE_REPORT_VERSION_LENGTH_OFFSET]
 call ice_append
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_target,line_target_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_TARGET_OFFSET]
 mov rdx,[r12+NEBOC_ICE_REPORT_TARGET_LENGTH_OFFSET]
 call ice_append
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_options,line_options_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_OPTIONS_DIGEST_OFFSET]
 call ice_hex64
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_features,line_features_len
 mov rdi,r14
 mov rsi,[r12+NEBOC_ICE_REPORT_FEATURE_DIGEST_OFFSET]
 call ice_hex64
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 APPEND_LITERAL line_source,line_source_len
 cmp qword [r12+NEBOC_ICE_REPORT_REDACTION_OFFSET],NEBOC_ICE_REDACT_METADATA
 jne .bundle_source_redacted
 cmp qword [r13+NEBOC_ICE_REPRO_INCLUDE_SOURCE_OFFSET],1
 jne .bundle_source_redacted
 mov rdi,r14
 mov rsi,[r13+NEBOC_ICE_REPRO_SOURCE_OFFSET]
 mov rdx,[r13+NEBOC_ICE_REPRO_SOURCE_LENGTH_OFFSET]
 call ice_append
 test eax,eax
 jnz .bundle_rollback
 jmp .bundle_source_done
.bundle_source_redacted:
 mov rdi,r14
 lea rsi,[rel redacted]
 mov edx,redacted_len
 call ice_append
 test eax,eax
 jnz .bundle_rollback
.bundle_source_done:
 APPEND_LITERAL newline,1
 mov rdi,[r14+NEBOC_WRITER_BYTES_OFFSET]
 mov rsi,[r14+NEBOC_WRITER_LENGTH_OFFSET]
 sub rsi,[rsp]
 add rdi,[rsp]
 call ice_digest
 mov r15,rax
 APPEND_LITERAL line_checksum,line_checksum_len
 mov rdi,r14
 mov rsi,r15
 call ice_hex64
 test eax,eax
 jnz .bundle_rollback
 APPEND_LITERAL newline,1
 mov rax,[r14+NEBOC_WRITER_BYTES_OFFSET]
 add rax,[rsp]
 mov [r12+NEBOC_ICE_REPORT_BUNDLE_OFFSET],rax
 mov rax,[r14+NEBOC_WRITER_LENGTH_OFFSET]
 sub rax,[rsp]
 mov [r12+NEBOC_ICE_REPORT_BUNDLE_LENGTH_OFFSET],rax
 xor eax,eax
 jmp .bundle_done
.bundle_rollback:
 mov rcx,[rsp]
 mov [r14+NEBOC_WRITER_LENGTH_OFFSET],rcx
.bundle_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.bundle_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.bundle_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Validate a path against an explicit local capability.
%undef call
validate_path:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp rsi,NEBOC_ICE_MAX_PATH_BYTES-4
 ja .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdx+NEBOC_ICE_CAP_ALLOW_WRITE_OFFSET],1
 jne .invalid
 mov r8,[rdx+NEBOC_ICE_CAP_PREFIX_LENGTH_OFFSET]
 cmp r8,rsi
 ja .invalid
 test r8,r8
 jz .scan
 mov r9,[rdx+NEBOC_ICE_CAP_PREFIX_OFFSET]
 test r9,r9
 jz .invalid
 xor ecx,ecx
.prefix:
 cmp rcx,r8
 jae .scan
 mov al,[rdi+rcx]
 cmp al,[r9+rcx]
 jne .invalid
 inc rcx
 jmp .prefix
.scan:
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .ok
 cmp byte [rdi+rcx],0
 je .invalid
 cmp byte [rdi+rcx],92
 je .invalid
 cmp byte [rdi+rcx],'.'
 jne .next
 cmp rcx,0
 je .dot_start
 cmp byte [rdi+rcx-1],'/'; component boundary
 jne .next
.dot_start:
 lea rax,[rcx+2]
 cmp rax,rsi
 ja .next
 cmp byte [rdi+rcx+1],'.'
 jne .next
 cmp rax,rsi
 je .invalid
 cmp byte [rdi+rax],'/'; complete .. component
 je .invalid
.next:
 inc rcx
 jmp .loop
.ok:
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Atomic local write: temp file, complete write, fsync, close, rename.
; iceReport.write(path, capability) as (report*, path*, path_len, cap*).
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_ice_report_write
 test rdi,rdi
 jz .write_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_ACTIVE_OFFSET],1
 jne .write_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_BUNDLE_LENGTH_OFFSET],0
 je .write_invalid
 cmp qword [rdi+NEBOC_ICE_REPORT_BUNDLE_OFFSET],0
 je .write_invalid
 test rcx,rcx
 jz .write_invalid
 mov rax,[rdi+NEBOC_ICE_REPORT_BUNDLE_LENGTH_OFFSET]
 cmp rax,[rcx+NEBOC_ICE_CAP_MAX_BYTES_OFFSET]
 ja .write_limit
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,4104
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r13
 mov rsi,r14
 mov rdx,r15
 call validate_path
 test eax,eax
 jnz .write_done
 lea rbx,[rsp]
 xor ecx,ecx
.path_copy:
 cmp rcx,r14
 jae .suffix
 mov al,[r13+rcx]
 mov [rbx+rcx],al
 inc rcx
 jmp .path_copy
.suffix:
 lea rsi,[rel tmp_suffix]
 xor edx,edx
.suffix_copy:
 mov al,[rsi+rdx]
 mov [rbx+rcx],al
 inc rcx
 inc rdx
 test al,al
 jnz .suffix_copy
 mov eax,2
 mov rdi,rbx
 mov esi,577
 mov edx,0600o
 syscall
 test rax,rax
 js .write_io
 mov r15,rax
 mov r14,[r12+NEBOC_ICE_REPORT_BUNDLE_LENGTH_OFFSET]
 mov r12,[r12+NEBOC_ICE_REPORT_BUNDLE_OFFSET]
 xor ebx,ebx
.write_loop:
 cmp rbx,r14
 jae .write_sync
 mov eax,1
 mov rdi,r15
 lea rsi,[r12+rbx]
 mov rdx,r14
 sub rdx,rbx
 syscall
 test rax,rax
 jle .write_cleanup
 add rbx,rax
 jmp .write_loop
.write_sync:
 mov eax,74
 mov rdi,r15
 syscall
 test rax,rax
 js .write_cleanup
 mov eax,3
 mov rdi,r15
 syscall
 mov r15,-1
 mov eax,82
 lea rdi,[rsp]
 mov rsi,r13
 syscall
 test rax,rax
 js .write_unlink
 xor eax,eax
 jmp .write_done
.write_cleanup:
 mov eax,3
 mov rdi,r15
 syscall
 mov r15,-1
.write_unlink:
 mov eax,87
 lea rdi,[rsp]
 syscall
.write_io:
 mov eax,NEBOC_STATUS_IO_ERROR
.write_done:
 add rsp,4104
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.write_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.write_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Copy a validated local bundle for explicit inspection.
%undef call
NEBOC_ABI_FUNCTION neboc_ice_bundle_inspect
 test rdi,rdi
 jz .inspect_invalid
 cmp rsi,bundle_magic_len
 jb .inspect_invalid
 cmp rsi,NEBOC_ICE_MAX_BUNDLE_BYTES
 ja .inspect_limit
 test rdx,rdx
 jz .inspect_invalid
 lea r8,[rel bundle_magic]
 xor ecx,ecx
.inspect_magic:
 cmp rcx,bundle_magic_len
 jae .inspect_copy
 mov al,[rdi+rcx]
 cmp al,[r8+rcx]
 jne .inspect_invalid
 inc rcx
 jmp .inspect_magic
.inspect_copy:
 mov rcx,[rdx+NEBOC_WRITER_LENGTH_OFFSET]
 push rcx
 mov r8,rdi
 mov r9,rsi
 mov rdi,rdx
 mov rsi,r8
 mov rdx,r9
 call ice_append
 test eax,eax
 jz .inspect_done
 pop rcx
 mov [rdi+NEBOC_WRITER_LENGTH_OFFSET],rcx
 ret
.inspect_done:
 add rsp,8
 ret
.inspect_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.inspect_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Produce a bounded deterministic reproducer summary preserving the ICE code.
NEBOC_ABI_FUNCTION neboc_ice_bundle_minimize
 test rdi,rdi
 jz .min_invalid
 cmp rsi,bundle_magic_len+line_code_len
 jb .min_invalid
 cmp rsi,NEBOC_ICE_MAX_BUNDLE_BYTES
 ja .min_limit
 test rdx,rdx
 jz .min_invalid
 lea r8,[rel bundle_magic]
 xor ecx,ecx
.min_magic:
 cmp rcx,bundle_magic_len
 jae .min_code
 mov al,[rdi+rcx]
 cmp al,[r8+rcx]
 jne .min_invalid
 inc rcx
 jmp .min_magic
.min_code:
 lea r8,[rel line_code]
 xor ecx,ecx
.min_code_loop:
 cmp rcx,line_code_len
 jae .min_emit
 mov al,[rdi+bundle_magic_len+rcx]
 cmp al,[r8+rcx]
 jne .min_invalid
 inc rcx
 jmp .min_code_loop
.min_emit:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdx
 mov rbx,[r12+NEBOC_WRITER_LENGTH_OFFSET]
 mov rdi,r12
 lea rsi,[rel bundle_magic]
 mov edx,bundle_magic_len
 call ice_append
 test eax,eax
 jnz .min_rollback
 mov rdi,r12
 lea rsi,[rel line_code]
 mov edx,line_code_len
 call ice_append
 test eax,eax
 jnz .min_rollback
 mov rdi,r12
 lea rsi,[rel line_minimized]
 mov edx,line_minimized_len
 call ice_append
 test eax,eax
 jnz .min_rollback
 mov rdi,[r12+NEBOC_WRITER_BYTES_OFFSET]
 add rdi,rbx
 mov rsi,[r12+NEBOC_WRITER_LENGTH_OFFSET]
 sub rsi,rbx
 call ice_digest
 mov [rsp],rax
 mov rdi,r12
 lea rsi,[rel line_checksum]
 mov edx,line_checksum_len
 call ice_append
 test eax,eax
 jnz .min_rollback
 mov rdi,r12
 mov rsi,[rsp]
 call ice_hex64
 test eax,eax
 jnz .min_rollback
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,1
 call ice_append
 test eax,eax
 jnz .min_rollback
 xor eax,eax
 jmp .min_done
.min_rollback:
 mov [r12+NEBOC_WRITER_LENGTH_OFFSET],rbx
.min_done:
 add rsp,8
 pop r12
 pop rbx
 ret
.min_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.min_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
