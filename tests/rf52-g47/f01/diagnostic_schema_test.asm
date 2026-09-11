bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/registry.inc"

global _start
extern neboc_diagnostic_code_registry_lookup
extern neboc_diagnostic_code_registry_count
extern neboc_diagnostic_new
extern neboc_diagnostic_code
extern neboc_diagnostic_severity
extern neboc_diagnostic_category
extern neboc_diagnostic_phase
extern neboc_diagnostic_schema_version
extern neboc_diagnostic_exit_code
extern neboc_diagnostic_primary_span
extern neboc_diagnostic_arguments
extern neboc_diagnostic_add_label
extern neboc_diagnostic_add_note
extern neboc_diagnostic_add_help
extern neboc_diagnostic_add_cause
extern neboc_host_process_exit

section .rodata
code_error: db "NEBO-E0001"
code_error_len equ $-code_error
key_error: db "diagnostic.schema.invalid"
key_error_len equ $-key_error
code_warning: db "NEBO-W0001"
code_warning_len equ $-code_warning
key_warning: db "diagnostic.compatibility.warning"
key_warning_len equ $-key_warning
unknown_code: db "NEBO-E9999"
label_text: db "invalid schema"
label_text_len equ $-label_text
note_text: db "schema v1 is required"
note_text_len equ $-note_text
help_text: db "use a registered diagnostic descriptor"
help_text_len equ $-help_text
argument_text: db "schema"
argument_text_len equ $-argument_text

section .data
primary_span: dq 7,3,8,16
arguments:
 dq NEBOC_DIAGNOSTIC_ARGUMENT_TEXT,argument_text,argument_text_len,0
 dq NEBOC_DIAGNOSTIC_ARGUMENT_UNSIGNED,0,0,1
request:
 dq code_error,code_error_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq key_error,key_error_len
 dq primary_span
 dq arguments,2
warning_request:
 dq code_warning,code_warning_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq key_warning,key_warning_len
 dq 0
 dq 0,0

section .bss align=16
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
cause: resb NEBOC_DIAGNOSTIC_SIZE
atomic_destination: resb NEBOC_DIAGNOSTIC_SIZE
registry_entry: resb NEBOC_DIAGNOSTIC_CODE_ENTRY_SIZE
slice: resb NEBOC_DIAGNOSTIC_SLICE_SIZE
scalar: resq 1
span_copy: resb NEBOC_SOURCE_SPAN_SIZE

section .text
_start:
 sub rsp,8
 call neboc_diagnostic_code_registry_count
 cmp eax,NEBOC_DIAGNOSTIC_CODE_COUNT
 jne .fail1

 lea rdi,[rel code_error]
 mov esi,code_error_len
 lea rdx,[rel registry_entry]
 call neboc_diagnostic_code_registry_lookup
 test eax,eax
 jne .fail2
 cmp qword [rel registry_entry+NEBOC_DIAGNOSTIC_CODE_ENTRY_SCHEMA_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .fail3
 lea rdi,[rel unknown_code]
 mov esi,10
 lea rdx,[rel registry_entry]
 call neboc_diagnostic_code_registry_lookup
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail4

 lea rdi,[rel diagnostic]
 lea rsi,[rel request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail5
 lea rdi,[rel diagnostic]
 lea rsi,[rel slice]
 call neboc_diagnostic_code
 test eax,eax
 jne .fail6
 cmp qword [rel slice+NEBOC_DIAGNOSTIC_SLICE_LENGTH_OFFSET],code_error_len
 jne .fail7
 lea rdi,[rel diagnostic]
 lea rsi,[rel scalar]
 call neboc_diagnostic_schema_version
 test eax,eax
 jne .fail8
 cmp qword [rel scalar],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .fail9
 lea rdi,[rel diagnostic]
 lea rsi,[rel scalar]
 call neboc_diagnostic_exit_code
 test eax,eax
 jne .fail10
 cmp qword [rel scalar],NEBOC_DIAGNOSTIC_EXIT_USER_ERROR
 jne .fail11
 lea rdi,[rel diagnostic]
 lea rsi,[rel span_copy]
 call neboc_diagnostic_primary_span
 test eax,eax
 jne .fail12
 cmp qword [rel span_copy+NEBOC_SOURCE_SPAN_START_OFFSET],3
 jne .fail13
 lea rdi,[rel diagnostic]
 lea rsi,[rel slice]
 call neboc_diagnostic_arguments
 test eax,eax
 jne .fail14
 cmp qword [rel slice+NEBOC_DIAGNOSTIC_SLICE_LENGTH_OFFSET],2
 jne .fail15

 xor r12d,r12d
.labels:
 lea rdi,[rel diagnostic]
 lea rsi,[rel primary_span]
 lea rdx,[rel label_text]
 mov ecx,label_text_len
 mov r8d,NEBOC_DIAGNOSTIC_LABEL_ROLE_SECONDARY
 call neboc_diagnostic_add_label
 test eax,eax
 jne .fail16
 inc r12d
 cmp r12d,NEBOC_DIAGNOSTIC_MAX_LABELS
 jb .labels
 lea rdi,[rel diagnostic]
 lea rsi,[rel primary_span]
 lea rdx,[rel label_text]
 mov ecx,label_text_len
 mov r8d,NEBOC_DIAGNOSTIC_LABEL_ROLE_SECONDARY
 call neboc_diagnostic_add_label
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail17

 xor r12d,r12d
.notes:
 lea rdi,[rel diagnostic]
 lea rsi,[rel note_text]
 mov edx,note_text_len
 call neboc_diagnostic_add_note
 test eax,eax
 jne .fail18
 inc r12d
 cmp r12d,NEBOC_DIAGNOSTIC_MAX_NOTES
 jb .notes
 lea rdi,[rel diagnostic]
 lea rsi,[rel note_text]
 mov edx,note_text_len
 call neboc_diagnostic_add_note
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail19

 xor r12d,r12d
.helps:
 lea rdi,[rel diagnostic]
 lea rsi,[rel help_text]
 mov edx,help_text_len
 call neboc_diagnostic_add_help
 test eax,eax
 jne .fail20
 inc r12d
 cmp r12d,NEBOC_DIAGNOSTIC_MAX_HELPS
 jb .helps
 lea rdi,[rel diagnostic]
 lea rsi,[rel help_text]
 mov edx,help_text_len
 call neboc_diagnostic_add_help
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail21

 lea rdi,[rel cause]
 lea rsi,[rel warning_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail22
 lea rdi,[rel diagnostic]
 lea rsi,[rel cause]
 call neboc_diagnostic_add_cause
 test eax,eax
 jne .fail23
 lea rdi,[rel diagnostic]
 lea rsi,[rel diagnostic]
 call neboc_diagnostic_add_cause
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail24

 mov rax,0x1122334455667788
 mov [rel atomic_destination],rax
 mov qword [rel request+NEBOC_DIAGNOSTIC_NEW_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 lea rdi,[rel atomic_destination]
 lea rsi,[rel request]
 call neboc_diagnostic_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail25
 mov rax,0x1122334455667788
 cmp [rel atomic_destination],rax
 jne .fail26
 mov qword [rel request+NEBOC_DIAGNOSTIC_NEW_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_ERROR

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 26
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
