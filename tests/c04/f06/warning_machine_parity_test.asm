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
extern neboc_diagnostic_set_note_suggestion
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_diagnostic_encoder_json
extern neboc_diagnostic_encoder_json_lines
extern neboc_diagnostic_encoder_sarif
extern neboc_diagnostic_encoder_lsp
extern neboc_host_process_exit

section .rodata
code: db "NEBO-W0001"
code_len equ $-code
key: db "diagnostic.compatibility.warning"
key_len equ $-key
path: db "src/main.no"
path_len equ $-path
source: db "abc",10
source_len equ $-source
note: db "compatibility note"
note_len equ $-note
replacement: db "_"
replacement_len equ $-replacement

marker_code: db '"NEBO-W0001"'
marker_code_len equ $-marker_code
marker_severity: db '"severity":2'
marker_severity_len equ $-marker_severity
marker_category: db '"category":7'
marker_category_len equ $-marker_category
marker_phase: db '"phase":12'
marker_phase_len equ $-marker_phase
marker_source: db '"sourceId":1'
marker_source_len equ $-marker_source
marker_message: db '"messageKey":"diagnostic.compatibility.warning"'
marker_message_len equ $-marker_message
marker_note: db '"note":"compatibility note"'
marker_note_len equ $-marker_note
json_span: db '"primary":{"sourceId":1,"start":1,"end":2}'
json_span_len equ $-json_span
portable_span: db '"sourceId":1,"spanStart":1,"spanEnd":2'
portable_span_len equ $-portable_span
json_fix: db '"fixIts":[{"start":1,"end":1,"replacement":"_"}]'
json_fix_len equ $-json_fix
sarif_fix: db '"fixes":['
sarif_fix_len equ $-sarif_fix
sarif_schema: db '"neboSchema":1'
sarif_schema_len equ $-sarif_schema
lsp_schema: db '"schema":1'
lsp_schema_len equ $-lsp_schema

section .data
span: dq 1,1,2,source_len
diagnostic_request:
 dq code,code_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq key,key_len
 dq span,0,0
source_request: dq path,path_len,source,source_len,0xc04f0601

section .bss align=16
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
source_map: resb NEBOC_SOURCE_MAP_SIZE
source_entries: resb NEBOC_SOURCE_ENTRY_SIZE
file_id: resq 1
writer: resb NEBOC_WRITER_SIZE
json_output: resb 4096
jsonl_output: resb 4096
sarif_output: resb 4096
lsp_output: resb 4096
json_length: resq 1

section .text
set_writer:
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rdi
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],4096
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 ret

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
 mov rdx,[rel writer+NEBOC_WRITER_BYTES_OFFSET]
 mov al,[rdx+r9]
 add r9,rcx
 mov al,[rdx+r9]
 sub r9,rcx
 cmp al,[rdi+rcx]
 jne .next
 inc rcx
 jmp .inner
.next:
 inc r9
 jmp .outer
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

assert_common:
 push rbx
 lea rdi,[rel marker_code]
 mov esi,marker_code_len
 call contains_output
 test eax,eax
 jz .no
 lea rdi,[rel marker_severity]
 mov esi,marker_severity_len
 call contains_output
 test eax,eax
 jz .no
 lea rdi,[rel marker_category]
 mov esi,marker_category_len
 call contains_output
 test eax,eax
 jz .no
 lea rdi,[rel marker_phase]
 mov esi,marker_phase_len
 call contains_output
 test eax,eax
 jz .no
 lea rdi,[rel marker_source]
 mov esi,marker_source_len
 call contains_output
 test eax,eax
 jz .no
 lea rdi,[rel marker_message]
 mov esi,marker_message_len
 call contains_output
 test eax,eax
 jz .no
 lea rdi,[rel marker_note]
 mov esi,marker_note_len
 call contains_output
 test eax,eax
 jz .no
 mov eax,1
 pop rbx
 ret
.no:
 xor eax,eax
 pop rbx
 ret

compare_buffers:
 xor eax,eax
.loop:
 test rdx,rdx
 jz .yes
 mov cl,[rdi]
 cmp cl,[rsi]
 jne .no
 inc rdi
 inc rsi
 dec rdx
 jmp .loop
.yes:
 mov eax,1
.no:
 ret

_start:
 lea rdi,[rel diagnostic]
 lea rsi,[rel diagnostic_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail1
 lea rdi,[rel diagnostic]
 lea rsi,[rel note]
 mov edx,note_len
 xor ecx,ecx
 xor r8d,r8d
 call neboc_diagnostic_set_note_suggestion
 test eax,eax
 jne .fail2
 or qword [rel diagnostic+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_FIXITS
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_ARGUMENT_COUNT_OFFSET],1
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET+NEBOC_DIAGNOSTIC_ARGUMENT_TYPE_OFFSET],NEBOC_DIAGNOSTIC_ARGUMENT_TEXT
 lea rax,[rel replacement]
 mov [rel diagnostic+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET+NEBOC_DIAGNOSTIC_ARGUMENT_DATA_OFFSET],rax
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET+NEBOC_DIAGNOSTIC_ARGUMENT_LENGTH_OFFSET],replacement_len
 mov qword [rel diagnostic+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET+NEBOC_DIAGNOSTIC_ARGUMENT_VALUE_OFFSET],1

 lea rdi,[rel source_map]
 lea rsi,[rel source_entries]
 mov edx,1
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail3
 lea rdi,[rel source_map]
 lea rsi,[rel source_request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jne .fail4

 lea rdi,[rel json_output]
 call set_writer
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json
 test eax,eax
 jne .fail5
 call assert_common
 test eax,eax
 jz .fail6
 lea rdi,[rel json_span]
 mov esi,json_span_len
 call contains_output
 test eax,eax
 jz .fail7
 lea rdi,[rel json_fix]
 mov esi,json_fix_len
 call contains_output
 test eax,eax
 jz .fail8
 mov rax,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 mov [rel json_length],rax

 lea rdi,[rel jsonl_output]
 call set_writer
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_json_lines
 test eax,eax
 jne .fail9
 mov rax,[rel json_length]
 inc rax
 cmp [rel writer+NEBOC_WRITER_LENGTH_OFFSET],rax
 jne .fail10
 mov rdx,[rel json_length]
 lea rdi,[rel json_output]
 lea rsi,[rel jsonl_output]
 call compare_buffers
 test eax,eax
 jz .fail11
 mov rax,[rel json_length]
 lea rdx,[rel jsonl_output]
 cmp byte [rdx+rax],10
 jne .fail12

 lea rdi,[rel sarif_output]
 call set_writer
 lea rdi,[rel diagnostic]
 mov esi,NEBOC_SARIF_PROFILE_V1
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_sarif
 test eax,eax
 jne .fail13
 call assert_common
 test eax,eax
 jz .fail14
 lea rdi,[rel portable_span]
 mov esi,portable_span_len
 call contains_output
 test eax,eax
 jz .fail15
 lea rdi,[rel sarif_fix]
 mov esi,sarif_fix_len
 call contains_output
 test eax,eax
 jz .fail16
 lea rdi,[rel sarif_schema]
 mov esi,sarif_schema_len
 call contains_output
 test eax,eax
 jz .fail17

 lea rdi,[rel lsp_output]
 call set_writer
 lea rdi,[rel diagnostic]
 lea rsi,[rel source_map]
 lea rdx,[rel writer]
 call neboc_diagnostic_encoder_lsp
 test eax,eax
 jne .fail18
 call assert_common
 test eax,eax
 jz .fail19
 lea rdi,[rel portable_span]
 mov esi,portable_span_len
 call contains_output
 test eax,eax
 jz .fail20
 lea rdi,[rel json_fix]
 mov esi,json_fix_len
 call contains_output
 test eax,eax
 jz .fail21
 lea rdi,[rel lsp_schema]
 mov esi,lsp_schema_len
 call contains_output
 test eax,eax
 jz .fail22

 xor edi,edi
 call neboc_host_process_exit

%assign n 1
%rep 22
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
