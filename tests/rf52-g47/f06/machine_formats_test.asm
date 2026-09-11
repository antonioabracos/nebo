bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/machine.inc"

global _start
extern neboc_diagnostic_new
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_diagnostic_encoder_json
extern neboc_diagnostic_encoder_json_lines
extern neboc_diagnostic_encoder_sarif
extern neboc_diagnostic_encoder_lsp
extern neboc_build_event_diagnostic
extern neboc_build_event_phase_started
extern neboc_build_event_phase_finished
extern neboc_diagnostic_payload_digest
extern neboc_host_process_exit

section .rodata
newline: db 10
code: db "NEBO-E0001"
code_len equ $-code
key: db "diagnostic.schema.invalid"
key_len equ $-key
key_other: db "diagnostic.schema.other"
key_other_len equ $-key_other
path: db "src/main.no"
path_len equ $-path
source: db "abc",10
source_len equ $-source
unit: db "main"
unit_len equ $-unit
expected_json: db '{"schema":1,"code":"NEBO-E0001","severity":1,"category":7,"phase":12,"messageKey":"diagnostic.schema.invalid","primary":{"sourceId":1,"start":1,"end":2}}'
expected_json_len equ $-expected_json
sarif_marker: db '"ruleId":"NEBO-E0001"'
sarif_marker_len equ $-sarif_marker
lsp_marker: db '"range":{"start":{"line":0,"character":1},"end":{"line":0,"character":2}}'
lsp_marker_len equ $-lsp_marker
event_diag_marker: db '"event":"diagnostic"'
event_diag_marker_len equ $-event_diag_marker
event_started_marker: db '"event":"phaseStarted"'
event_started_marker_len equ $-event_started_marker
event_finished_marker: db '"event":"phaseFinished"'
event_finished_marker_len equ $-event_finished_marker

section .data
primary_span: dq 1,1,2,source_len
diagnostic_request:
 dq code,code_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq key,key_len
 dq primary_span
 dq 0,0
source_request: dq path,path_len,source,source_len,0x12345678

section .bss align=16
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
source_map: resb NEBOC_SOURCE_MAP_SIZE
source_entries: resb NEBOC_SOURCE_ENTRY_SIZE*2
file_id: resq 1
writer: resb NEBOC_WRITER_SIZE
output: resb 4096
digest_a: resq 1
digest_b: resq 1

section .text
reset_writer:
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],4096
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 ret

write_output:
 mov rdx,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 lea rsi,[rel output]
 mov edi,1
 mov eax,1
 syscall
 cmp rax,rdx
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

write_newline:
 lea rsi,[rel newline]
 mov edx,1
 mov edi,1
 mov eax,1
 syscall
 cmp eax,1
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
 ret

; equals_output(expected*, length) -> 1/0
equals_output:
 cmp rsi,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 jne .no
 lea rdx,[rel output]
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .yes
 mov al,[rdi+rcx]
 cmp al,[rdx+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; contains_output(needle*, length) -> 1/0
contains_output:
 mov r8,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 cmp rsi,r8
 ja .no
 xor r9d,r9d
.outer:
 mov rax,r9
 add rax,rsi
 cmp rax,r8
 ja .no
 xor ecx,ecx
.inner:
 cmp rcx,rsi
 jae .yes
 lea rdx,[rel output]
 mov al,[rdx+r9]
 cmp al,[rdi+rcx]
 jne .next
 inc r9
 inc rcx
 jmp .inner
.next:
 sub r9,rcx
 inc r9
 jmp .outer
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

_start:
 sub rsp,8
 lea rdi,[rel diagnostic]
 lea rsi,[rel diagnostic_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail1
 lea rdi,[rel source_map]
 lea rsi,[rel source_entries]
 mov edx,2
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail2
 lea rdi,[rel source_map]
 lea rsi,[rel source_request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jne .fail3

 call reset_writer
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json
 test eax,eax
 jne .fail4
 lea rdi,[rel expected_json]
 mov esi,expected_json_len
 call equals_output
 test eax,eax
 jz .fail5
 call write_output
 test eax,eax
 jne .fail29
 call write_newline
 test eax,eax
 jne .fail30

 call reset_writer
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json_lines
 test eax,eax
 jne .fail6
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],expected_json_len+1
 jne .fail7
 mov rax,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 lea rdx,[rel output]
 cmp byte [rdx+rax-1],10
 jne .fail8

 call reset_writer
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_SARIF_PROFILE_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_sarif
 test eax,eax
 jne .fail9
 lea rdi,[rel sarif_marker]
 mov esi,sarif_marker_len
 call contains_output
 test eax,eax
 jz .fail10
 call write_output
 test eax,eax
 jne .fail31
 call write_newline
 test eax,eax
 jne .fail32

 call reset_writer
 lea rdi,[rel diagnostic]
 lea rsi,[rel source_map]
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_lsp
 test eax,eax
 jne .fail11
 lea rdi,[rel lsp_marker]
 mov esi,lsp_marker_len
 call contains_output
 test eax,eax
 jz .fail12
 call write_output
 test eax,eax
 jne .fail33
 call write_newline
 test eax,eax
 jne .fail34

 call reset_writer
 lea rdi,[rel diagnostic]
 lea rsi,[rel writer]
 call neboc_build_event_diagnostic
 test eax,eax
 jne .fail13
 lea rdi,[rel event_diag_marker]
 mov esi,event_diag_marker_len
 call contains_output
 test eax,eax
 jz .fail14
 call write_output
 test eax,eax
 jne .fail35

 call reset_writer
 mov edi,NEBOC_DIAGNOSTIC_PHASE_PARSE
 lea rsi,[rel unit]
 mov edx,unit_len
 lea rcx,[rel writer]
 call neboc_build_event_phase_started
 test eax,eax
 jne .fail15
 lea rdi,[rel event_started_marker]
 mov esi,event_started_marker_len
 call contains_output
 test eax,eax
 jz .fail16
 call write_output
 test eax,eax
 jne .fail36

 call reset_writer
 mov edi,NEBOC_DIAGNOSTIC_PHASE_PARSE
 mov esi,NEBOC_BUILD_OUTCOME_FAILURE
 mov edx,3
 lea rcx,[rel writer]
 call neboc_build_event_phase_finished
 test eax,eax
 jne .fail17
 lea rdi,[rel event_finished_marker]
 mov esi,event_finished_marker_len
 call contains_output
 test eax,eax
 jz .fail18
 call write_output
 test eax,eax
 jne .fail37

 lea rdi,[rel diagnostic]
 lea rsi,[rel digest_a]
 call neboc_diagnostic_payload_digest
 test eax,eax
 jne .fail19
 lea rdi,[rel diagnostic]
 lea rsi,[rel digest_b]
 call neboc_diagnostic_payload_digest
 test eax,eax
 jne .fail20
 mov rax,[rel digest_a]
 test rax,rax
 jz .fail21
 cmp rax,[rel digest_b]
 jne .fail22
 inc qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 lea rdi,[rel diagnostic]
 lea rsi,[rel digest_b]
 call neboc_diagnostic_payload_digest
 test eax,eax
 jne .fail23
 mov rax,[rel digest_a]
 cmp rax,[rel digest_b]
 je .fail24
 dec qword [rel diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET]
 lea rax,[rel key_other]
 mov [rel diagnostic+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],rax
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],key_other_len
 lea rdi,[rel diagnostic]
 lea rsi,[rel digest_b]
 call neboc_diagnostic_payload_digest
 test eax,eax
 jne .fail38
 mov rax,[rel digest_a]
 cmp rax,[rel digest_b]
 je .fail39
 lea rax,[rel key]
 mov [rel diagnostic+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],rax
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],key_len

 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],8
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],7
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail25
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],7
 jne .fail26
 lea rdi,[rel diagnostic]
 mov esi,2
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail27
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],7
 jne .fail28

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 39
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
