; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F06 deterministic JSON/JSONL/SARIF/LSP and build-event encoders.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/machine.inc"

extern neboc_source_map_line_column

section .rodata
json_prefix: db '{"schema":1,"code":'
json_prefix_len equ $-json_prefix
json_severity: db ',"severity":'
json_severity_len equ $-json_severity
json_category: db ',"category":'
json_category_len equ $-json_category
json_phase: db ',"phase":'
json_phase_len equ $-json_phase
json_message: db ',"messageKey":'
json_message_len equ $-json_message
json_primary: db ',"primary":{"sourceId":'
json_primary_len equ $-json_primary
json_start: db ',"start":'
json_start_len equ $-json_start
json_end: db ',"end":'
json_end_len equ $-json_end
json_close_primary: db '}}'
json_close_primary_len equ $-json_close_primary
json_newline: db 10
json_quote: db '"'
json_backslash_quote: db '\"'
json_backslash_quote_len equ $-json_backslash_quote
json_backslash_backslash: db '\\'
json_backslash_backslash_len equ $-json_backslash_backslash
json_unicode_prefix: db '\u00'
json_unicode_prefix_len equ $-json_unicode_prefix
hex_digits: db '0123456789abcdef'

sarif_prefix: db '{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"neboc"}},"results":[{"ruleId":'
sarif_prefix_len equ $-sarif_prefix
sarif_level: db ',"level":'
sarif_level_len equ $-sarif_level
sarif_message: db ',"message":{"id":'
sarif_message_len equ $-sarif_message
sarif_location: db '},"locations":[{"physicalLocation":{"region":{"byteOffset":'
sarif_location_len equ $-sarif_location
sarif_byte_length: db ',"byteLength":'
sarif_byte_length_len equ $-sarif_byte_length
sarif_close: db '}}}]}]}]}'
sarif_close_len equ $-sarif_close
t_error: db 'error'
t_error_len equ $-t_error
t_warning: db 'warning'
t_warning_len equ $-t_warning
t_note: db 'note'
t_note_len equ $-t_note

lsp_prefix: db '{"range":{"start":{"line":'
lsp_prefix_len equ $-lsp_prefix
lsp_character: db ',"character":'
lsp_character_len equ $-lsp_character
lsp_end: db '},"end":{"line":'
lsp_end_len equ $-lsp_end
lsp_after_range: db '}},"severity":'
lsp_after_range_len equ $-lsp_after_range
lsp_code: db ',"code":'
lsp_code_len equ $-lsp_code
lsp_source: db ',"source":"neboc","message":'
lsp_source_len equ $-lsp_source
lsp_related: db ',"relatedInformation":[],"data":{"neboCode":'
lsp_related_len equ $-lsp_related
lsp_close: db '}}'
lsp_close_len equ $-lsp_close

event_diagnostic_prefix: db '{"event":"diagnostic","diagnostic":'
event_diagnostic_prefix_len equ $-event_diagnostic_prefix
event_close: db '}',10
event_close_len equ $-event_close
event_started_prefix: db '{"event":"phaseStarted","phase":'
event_started_prefix_len equ $-event_started_prefix
event_unit: db ',"unit":'
event_unit_len equ $-event_unit
event_started_close: db '}',10
event_started_close_len equ $-event_started_close
event_finished_prefix: db '{"event":"phaseFinished","phase":'
event_finished_prefix_len equ $-event_finished_prefix
event_outcome: db ',"outcome":'
event_outcome_len equ $-event_outcome
event_count: db ',"diagnosticCount":'
event_count_len equ $-event_count
event_finished_close: db '}',10
event_finished_close_len equ $-event_finished_close

section .text

machine_writer_append:
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

machine_writer_u64:
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
 call machine_writer_append
 add rsp,32
 pop rbx
 ret

; JSON string encoding is byte-preserving for UTF-8 and escapes JSON controls.
machine_writer_json_string:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 lea rsi,[rel json_quote]
 mov edx,1
 call machine_writer_append
 test eax,eax
 jnz .done
 xor r14d,r14d
.loop:
 cmp r14,r13
 jae .close
 movzx eax,byte [r12+r14]
 cmp al,'"'
 je .quote
 cmp al,'\'
 je .backslash
 cmp al,32
 jb .control
 mov rdi,rbx
 lea rsi,[r12+r14]
 mov edx,1
 call machine_writer_append
 jmp .checked
.quote:
 mov rdi,rbx
 lea rsi,[rel json_backslash_quote]
 mov edx,json_backslash_quote_len
 call machine_writer_append
 jmp .checked
.backslash:
 mov rdi,rbx
 lea rsi,[rel json_backslash_backslash]
 mov edx,json_backslash_backslash_len
 call machine_writer_append
 jmp .checked
.control:
 mov [rsp],rax
 mov rdi,rbx
 lea rsi,[rel json_unicode_prefix]
 mov edx,json_unicode_prefix_len
 call machine_writer_append
 test eax,eax
 jnz .done
 mov rax,[rsp]
 shr rax,4
 and eax,15
 lea rcx,[rel hex_digits]
 mov al,[rcx+rax]
 mov [rsp],al
 movzx edx,byte [r12+r14]
 and edx,15
 mov dl,[rcx+rdx]
 mov [rsp+1],dl
 mov rdi,rbx
 lea rsi,[rsp]
 mov edx,2
 call machine_writer_append
.checked:
 test eax,eax
 jnz .done
 inc r14
 jmp .loop
.close:
 mov rdi,rbx
 lea rsi,[rel json_quote]
 mov edx,1
 call machine_writer_append
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%macro APPEND_LITERAL 2
 mov rdi,r12
 lea rsi,[rel %1]
 mov edx,%2
 call machine_writer_append
 test eax,eax
 jnz .finish
%endmacro

; emit_common_json(diagnostic*, writer*)
machine_emit_common_json:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 APPEND_LITERAL json_prefix,json_prefix_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call machine_writer_json_string
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_severity,json_severity_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 call machine_writer_u64
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_category,json_category_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET]
 call machine_writer_u64
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_phase,json_phase_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET]
 call machine_writer_u64
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_message,json_message_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET]
 call machine_writer_json_string
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_primary,json_primary_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 call machine_writer_u64
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_start,json_start_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 call machine_writer_u64
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_end,json_end_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 call machine_writer_u64
 test eax,eax
 jnz .finish
 APPEND_LITERAL json_close_primary,json_close_primary_len
 xor eax,eax
.finish:
 add rsp,8
 pop r12
 pop rbx
 ret

machine_validate_common:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_MACHINE_SCHEMA_V1
 jne .invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 jne .invalid
 mov rax,[rdx+NEBOC_WRITER_BYTES_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[rdx+NEBOC_WRITER_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_MACHINE_MAX_OUTPUT
 ja .invalid
 cmp qword [rdx+NEBOC_WRITER_LENGTH_OFFSET],rax
 ja .invalid
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

machine_validate_writer:
 test rdi,rdi
 jz .invalid
 mov rax,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_MACHINE_MAX_OUTPUT
 ja .invalid
 cmp qword [rdi+NEBOC_WRITER_LENGTH_OFFSET],rax
 ja .invalid
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; internal encode JSON, RCX is newline flag.
machine_encode_json:
 test rdx,rdx
 jz .invalid_fast
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rdx
 mov r13,rcx
 mov r14,[r12+NEBOC_WRITER_LENGTH_OFFSET]
 call machine_validate_common
 test eax,eax
 jnz .finish
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call machine_emit_common_json
 test eax,eax
 jnz .rollback
 test r13,r13
 jz .ok
 mov rdi,r12
 lea rsi,[rel json_newline]
 mov edx,1
 call machine_writer_append
 test eax,eax
 jnz .rollback
.ok:
 xor eax,eax
 jmp .finish
.rollback:
 mov [r12+NEBOC_WRITER_LENGTH_OFFSET],r14
.finish:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_fast:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; DiagnosticEncoder.json(diagnostic*, schema_version, writer*)
NEBOC_ABI_FUNCTION neboc_diagnostic_encoder_json
 xor ecx,ecx
 jmp machine_encode_json

; DiagnosticEncoder.jsonLines(diagnostic*, schema_version, writer*)
NEBOC_ABI_FUNCTION neboc_diagnostic_encoder_json_lines
 mov ecx,1
 jmp machine_encode_json

; DiagnosticEncoder.sarif(diagnostic*, profile, writer*)
NEBOC_ABI_FUNCTION neboc_diagnostic_encoder_sarif
 cmp rsi,NEBOC_SARIF_PROFILE_V1
 jne .invalid
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rdx
 mov r14,[r12+NEBOC_WRITER_LENGTH_OFFSET]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 call machine_validate_common
 test eax,eax
 jnz .finish
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
 APPEND_LITERAL sarif_prefix,sarif_prefix_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call machine_writer_json_string
 test eax,eax
 jnz .rollback
 APPEND_LITERAL sarif_level,sarif_level_len
 lea rsi,[rel t_error]
 mov edx,t_error_len
 cmp qword [rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .level_note
 lea rsi,[rel t_warning]
 mov edx,t_warning_len
.level_note:
 cmp qword [rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_NOTE
 jne .emit_level
 lea rsi,[rel t_note]
 mov edx,t_note_len
.emit_level:
 mov rdi,r12
 call machine_writer_json_string
 test eax,eax
 jnz .rollback
 APPEND_LITERAL sarif_message,sarif_message_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET]
 call machine_writer_json_string
 test eax,eax
 jnz .rollback
 APPEND_LITERAL sarif_location,sarif_location_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 call machine_writer_u64
 test eax,eax
 jnz .rollback
 APPEND_LITERAL sarif_byte_length,sarif_byte_length_len
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 sub rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 mov rdi,r12
 call machine_writer_u64
 test eax,eax
 jnz .rollback
 APPEND_LITERAL sarif_close,sarif_close_len
 xor eax,eax
 jmp .finish
.rollback:
 mov [r12+NEBOC_WRITER_LENGTH_OFFSET],r14
.finish:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; DiagnosticEncoder.lsp(diagnostic*, source_map*, writer*)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_diagnostic_encoder_lsp
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,104
 mov rbx,rdi
 mov r13,rsi
 mov r12,rdx
 mov r14,[r12+NEBOC_WRITER_LENGTH_OFFSET]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 call machine_validate_common
 test eax,eax
 jnz .finish
 mov rdi,r13
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 lea rcx,[rsp]
 call neboc_source_map_line_column
 test eax,eax
 jnz .finish
 mov rdi,r13
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 lea rcx,[rsp+48]
 call neboc_source_map_line_column
 test eax,eax
 jnz .finish
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
 APPEND_LITERAL lsp_prefix,lsp_prefix_len
 mov rsi,[rsp+NEBOC_MACHINE_SOURCE_LOCATION_LINE_OFFSET]
 dec rsi
 mov rdi,r12
 call machine_writer_u64
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_character,lsp_character_len
 mov rsi,[rsp+NEBOC_SOURCE_LOCATION_SCALAR_COLUMN_OFFSET]
 dec rsi
 mov rdi,r12
 call machine_writer_u64
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_end,lsp_end_len
 mov rsi,[rsp+48+NEBOC_MACHINE_SOURCE_LOCATION_LINE_OFFSET]
 dec rsi
 mov rdi,r12
 call machine_writer_u64
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_character,lsp_character_len
 mov rsi,[rsp+48+NEBOC_SOURCE_LOCATION_SCALAR_COLUMN_OFFSET]
 dec rsi
 mov rdi,r12
 call machine_writer_u64
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_after_range,lsp_after_range_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 cmp rsi,NEBOC_DIAGNOSTIC_SEVERITY_BUG
 jne .lsp_help
 mov esi,1
 jmp .lsp_severity_ready
.lsp_help:
 cmp rsi,NEBOC_DIAGNOSTIC_SEVERITY_HELP
 jne .lsp_severity_ready
 mov esi,4
.lsp_severity_ready:
 call machine_writer_u64
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_code,lsp_code_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call machine_writer_json_string
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_source,lsp_source_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET]
 call machine_writer_json_string
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_related,lsp_related_len
 mov rdi,r12
 mov rsi,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rdx,[rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call machine_writer_json_string
 test eax,eax
 jnz .rollback
 APPEND_LITERAL lsp_close,lsp_close_len
 xor eax,eax
 jmp .finish
.rollback:
 mov [r12+NEBOC_WRITER_LENGTH_OFFSET],r14
.finish:
 add rsp,104
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; BuildEvent.diagnostic(diagnostic*, writer*)
%undef call
NEBOC_ABI_FUNCTION neboc_build_event_diagnostic
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 mov rdx,r12
 call machine_validate_common
 test eax,eax
 jnz .finish
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
 APPEND_LITERAL event_diagnostic_prefix,event_diagnostic_prefix_len
 mov rdi,rbx
 mov rsi,r12
 call machine_emit_common_json
 test eax,eax
 jnz .rollback_zero
 APPEND_LITERAL event_close,event_close_len
 xor eax,eax
 jmp .finish
.rollback_zero:
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
.finish:
 add rsp,8
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; BuildEvent.phaseStarted(phase, unit*, unit_len, writer*)
NEBOC_ABI_FUNCTION neboc_build_event_phase_started
 test rdi,rdi
 jz .invalid
 cmp rdi,NEBOC_DIAGNOSTIC_PHASE_MAX
 ja .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_BUILD_EVENT_MAX_UNIT_BYTES
 ja .limit
 test rcx,rcx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r13,rsi
 mov r14,rdx
 mov r12,rcx
 mov rdi,r12
 call machine_validate_writer
 test eax,eax
 jnz .finish
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
 APPEND_LITERAL event_started_prefix,event_started_prefix_len
 mov rdi,r12
 mov rsi,rbx
 call machine_writer_u64
 test eax,eax
 jnz .zero
 APPEND_LITERAL event_unit,event_unit_len
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call machine_writer_json_string
 test eax,eax
 jnz .zero
 APPEND_LITERAL event_started_close,event_started_close_len
 xor eax,eax
 jmp .finish
.zero:
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
.finish:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; BuildEvent.phaseFinished(phase, outcome, diagnostic_count, writer*)
NEBOC_ABI_FUNCTION neboc_build_event_phase_finished
 test rdi,rdi
 jz .invalid
 cmp rdi,NEBOC_DIAGNOSTIC_PHASE_MAX
 ja .invalid
 cmp rsi,NEBOC_BUILD_OUTCOME_SUCCESS
 jb .invalid
 cmp rsi,NEBOC_BUILD_OUTCOME_FAILURE
 ja .invalid
 test rcx,rcx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r13,rsi
 mov r14,rdx
 mov r12,rcx
 mov rdi,r12
 call machine_validate_writer
 test eax,eax
 jnz .finish
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
 APPEND_LITERAL event_finished_prefix,event_finished_prefix_len
 mov rdi,r12
 mov rsi,rbx
 call machine_writer_u64
 test eax,eax
 jnz .zero
 APPEND_LITERAL event_outcome,event_outcome_len
 mov rdi,r12
 mov rsi,r13
 call machine_writer_u64
 test eax,eax
 jnz .zero
 APPEND_LITERAL event_count,event_count_len
 mov rdi,r12
 mov rsi,r14
 call machine_writer_u64
 test eax,eax
 jnz .zero
 APPEND_LITERAL event_finished_close,event_finished_close_len
 xor eax,eax
 jmp .finish
.zero:
 mov qword [r12+NEBOC_WRITER_LENGTH_OFFSET],0
.finish:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; diagnostic.payloadDigest(diagnostic*, out_u64*) -- observability only.
NEBOC_ABI_FUNCTION neboc_diagnostic_payload_digest
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .invalid
 mov r8,14695981039346656037
 mov r9,1099511628211
 mov r10,[rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov r11,[rdi+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 xor ecx,ecx
.code:
 cmp rcx,r11
 jae .scalars
 movzx eax,byte [r10+rcx]
 xor r8,rax
 imul r8,r9
 inc rcx
 jmp .code
.scalars:
 mov r10,[rdi+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET]
 mov r11,[rdi+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET]
 xor ecx,ecx
.message:
 cmp rcx,r11
 jae .scalar_values
 movzx eax,byte [r10+rcx]
 xor r8,rax
 imul r8,r9
 inc rcx
 jmp .message
.scalar_values:
 mov rax,[rdi+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 xor r8,rax
 imul r8,r9
 mov rax,[rdi+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET]
 xor r8,rax
 imul r8,r9
 mov rax,[rdi+NEBOC_DIAGNOSTIC_PHASE_OFFSET]
 xor r8,rax
 imul r8,r9
 %assign soff 0
 %rep 3
 mov rax,[rdi+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+soff]
 xor r8,rax
 imul r8,r9
 %assign soff soff+8
 %endrep
 mov [rsi],r8
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
