; C03-F05 persistent entrypoint diagnostic identity/context conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/machine.inc"
%include "compiler/semantic/modules/entrypoint_resolver.inc"

global _start
extern neboc_entrypoint_diagnostic_prepare
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_diagnostic_encoder_json_lines
extern neboc_diagnostic_encoder_sarif
extern neboc_diagnostic_encoder_lsp

section .rodata
path: db 'entry.no'
path_len equ $-path
source: times 64 db 'x'
source_len equ $-source
newline: db 10

section .data
source_request: dq path,path_len,source,source_len,0x43523033463035

section .bss align=16
result: resb NEBOC_ENTRYPOINT_RESULT_SIZE
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb NEBOC_MACHINE_MAX_OUTPUT
source_map: resb NEBOC_SOURCE_MAP_SIZE
source_entries: resb NEBOC_SOURCE_ENTRY_SIZE
file_id: resq 1

section .text
reset_result:
 lea rdi,[rel result]
 xor eax,eax
 mov ecx,NEBOC_ENTRYPOINT_RESULT_SIZE/8
 rep stosq
 ret

prepare:
 ; RDI=outcome, RSI=expected stable catalog id.
 push rsi
 mov [rel result+NEBOC_ENTRYPOINT_RESULT_OUTCOME],rdi
 lea rdi,[rel result]
 mov esi,1
 mov edx,7
 mov ecx,7
 mov r8d,source_len
 lea r9,[rel diagnostic]
 call neboc_entrypoint_diagnostic_prepare
 pop rsi
 test eax,eax
 jnz fail_1
 cmp [rel diagnostic+NEBOC_DIAGNOSTIC_CODE_OFFSET],rsi
 jne fail_2
 cmp qword [rel diagnostic+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne fail_3
 test qword [rel diagnostic+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_NOTE
 jz fail_4
 ret

emit_json_line:
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],NEBOC_MACHINE_MAX_OUTPUT
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json_lines
 test eax,eax
 jnz fail_5
 jmp write_output

emit_sarif:
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],NEBOC_MACHINE_MAX_OUTPUT
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_SARIF_PROFILE_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_sarif
 test eax,eax
 jnz fail_6
 call write_output
 jmp write_newline

emit_lsp:
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],NEBOC_MACHINE_MAX_OUTPUT
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel diagnostic]
 lea rsi,[rel source_map]
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_lsp
 test eax,eax
 jnz fail_7
 call write_output
 jmp write_newline

write_output:
 mov rdx,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 lea rsi,[rel output]
 mov edi,1
 mov eax,1
 syscall
 cmp rax,rdx
 jne fail_8
 ret

write_newline:
 lea rsi,[rel newline]
 mov edx,1
 mov edi,1
 mov eax,1
 syscall
 cmp eax,1
 jne fail_9
 ret

_start:
 sub rsp,8
 lea rdi,[rel source_map]
 lea rsi,[rel source_entries]
 mov edx,1
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jnz fail_10
 lea rdi,[rel source_map]
 lea rsi,[rel source_request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jnz fail_11

 ; Missing owns the selected target/invocation fallback span.
 call reset_result
 mov edi,NEBOC_ENTRYPOINT_OUTCOME_MISSING
 mov esi,NEBOC_DIAG_ENTRYPOINT_MISSING
 call prepare
 cmp qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],7
 jne fail_12
 call emit_json_line

 ; Duplicate swaps the resolver minima: later primary, first related.
 call reset_result
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID],1
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START],10
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END],15
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_RELATED_SOURCE_UNIT_ID],1
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_START],30
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_END],35
 mov edi,NEBOC_ENTRYPOINT_OUTCOME_DUPLICATE
 mov esi,NEBOC_DIAG_ENTRYPOINT_DUPLICATE
 call prepare
 cmp qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],30
 jne fail_13
 cmp qword [rel diagnostic+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],10
 jne fail_14
 test qword [rel diagnostic+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_SECONDARY
 jz fail_15
 call emit_json_line
 call emit_sarif
 call emit_lsp

 ; Invalid signature owns the offending signature/status expression.
 call reset_result
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID],1
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START],20
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END],24
 mov edi,NEBOC_ENTRYPOINT_OUTCOME_INVALID_SIGNATURE
 mov esi,NEBOC_DIAG_ENTRYPOINT_INVALID_SIGNATURE
 call prepare
 cmp qword [rel diagnostic+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_TYPE
 jne fail_16
 call emit_json_line

 ; Ambiguity retains deterministic first primary and all bounded related data.
 call reset_result
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID],1
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START],8
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END],13
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_RELATED_SOURCE_UNIT_ID],1
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_START],40
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_RELATED_SPAN_END],45
 mov edi,NEBOC_ENTRYPOINT_OUTCOME_AMBIGUOUS
 mov esi,NEBOC_DIAG_ENTRYPOINT_AMBIGUOUS
 call prepare
 call emit_json_line

 ; Library/test declarations are diagnosed by the same stable catalog family.
 call reset_result
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SOURCE_UNIT_ID],1
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_START],50
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_PRIMARY_SPAN_END],55
 mov edi,NEBOC_ENTRYPOINT_OUTCOME_FORBIDDEN_FOR_TARGET
 mov esi,NEBOC_DIAG_ENTRYPOINT_FORBIDDEN_FOR_TARGET
 call prepare
 call emit_json_line

 ; Unknown outcome fails atomically and leaves no stale public identity.
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_CODE_OFFSET],-1
 call reset_result
 mov qword [rel result+NEBOC_ENTRYPOINT_RESULT_OUTCOME],99
 lea rdi,[rel result]
 mov esi,1
 xor edx,edx
 xor ecx,ecx
 mov r8d,source_len
 lea r9,[rel diagnostic]
 call neboc_entrypoint_diagnostic_prepare
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail_17
 cmp qword [rel diagnostic+NEBOC_DIAGNOSTIC_CODE_OFFSET],0
 jne fail_18

 xor edi,edi
 jmp exit
fail_1: mov edi,1
 jmp exit
fail_2: mov edi,2
 jmp exit
fail_3: mov edi,3
 jmp exit
fail_4: mov edi,4
 jmp exit
fail_5: mov edi,5
 jmp exit
fail_6: mov edi,6
 jmp exit
fail_7: mov edi,7
 jmp exit
fail_8: mov edi,8
 jmp exit
fail_9: mov edi,9
 jmp exit
fail_10: mov edi,10
 jmp exit
fail_11: mov edi,11
 jmp exit
fail_12: mov edi,12
 jmp exit
fail_13: mov edi,13
 jmp exit
fail_14: mov edi,14
 jmp exit
fail_15: mov edi,15
 jmp exit
fail_16: mov edi,16
 jmp exit
fail_17: mov edi,17
 jmp exit
fail_18: mov edi,18
exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
