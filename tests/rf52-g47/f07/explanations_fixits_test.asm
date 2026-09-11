bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/explain.inc"

global _start
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_fix_it_new
extern neboc_fix_it_add_edit
extern neboc_fix_it_preview
extern neboc_fix_it_conflicts
extern neboc_diagnostic_explanation_load
extern neboc_diagnostic_explanation_examples
extern neboc_diagnostic_explanation_related_codes
extern neboc_diagnostic_explanation_render
extern neboc_diagnostic_explanation_search
extern neboc_host_process_exit

section .rodata
description: db 'replace the literal'
description_len equ $-description
path: db 'src/main.no'
path_len equ $-path
source: db 'let value = 1',10
source_len equ $-source
replacement: db '2'
replacement_len equ $-replacement
code: db 'NEBO-E0001'
code_len equ $-code
query: db 'tooling'
query_len equ $-query
expected_preview:
 db '--- src/main.no',10
 db '+++ src/main.no',10
 db '@@ bytes 12..13 @@',10
 db '-1',10
 db '+2',10
expected_preview_len equ $-expected_preview
title_marker: db 'invalid diagnostic or source contract'
title_marker_len equ $-title_marker
search_marker: db 'NEBO-ICE-0001'
search_marker_len equ $-search_marker

section .data
source_request: dq path,path_len,source,source_len,0x52f70001
span_edit: dq 1,12,13,source_len,0x52f70001,1
span_overlap: dq 1,12,13,source_len,0x52f70001,1
span_separate: dq 1,4,9,source_len,0x52f70001,1

section .bss align=16
source_map: resb NEBOC_SOURCE_MAP_SIZE
source_entries: resb NEBOC_SOURCE_ENTRY_SIZE*2
file_id: resq 1
fix_a: resb NEBOC_FIXIT_SIZE
fix_b: resb NEBOC_FIXIT_SIZE
fix_c: resb NEBOC_FIXIT_SIZE
fix_one: resb NEBOC_FIXIT_SIZE
edits_a: resb NEBOC_FIXIT_EDIT_SIZE*2
edits_b: resb NEBOC_FIXIT_EDIT_SIZE
edits_c: resb NEBOC_FIXIT_EDIT_SIZE
edits_one: resb NEBOC_FIXIT_EDIT_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 4096
conflict: resq 1
explanation: resb NEBOC_EXPLANATION_SIZE
positive_slice: resq 2
negative_slice: resq 2
related_slice: resq 2

section .text
reset_writer:
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],4096
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 ret

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

_start:
 sub rsp,8
 lea rdi,[rel source_map]
 lea rsi,[rel source_entries]
 mov edx,2
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail1
 lea rdi,[rel source_map]
 lea rsi,[rel source_request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jne .fail2

 lea rdi,[rel fix_a]
 lea rsi,[rel description]
 mov edx,description_len
 mov ecx,NEBOC_FIXIT_MACHINE_APPLICABLE
 lea r8,[rel edits_a]
 mov r9d,2
 call neboc_fix_it_new
 test eax,eax
 jne .fail3
 lea rdi,[rel fix_a]
 mov esi,1
 lea rdx,[rel span_edit]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,0x52f70001
 call neboc_fix_it_add_edit
 test eax,eax
 jne .fail4

 call reset_writer
 lea rdi,[rel fix_a]
 lea rsi,[rel source_map]
 lea rdx,[rel writer]
 call neboc_fix_it_preview
 test eax,eax
 jne .fail5
 lea rdi,[rel expected_preview]
 mov esi,expected_preview_len
 call equals_output
 test eax,eax
 jz .fail6
 cmp byte [rel source+12],'1'
 jne .fail7

 lea rdi,[rel fix_b]
 lea rsi,[rel description]
 mov edx,description_len
 mov ecx,NEBOC_FIXIT_MAYBE_INCORRECT
 lea r8,[rel edits_b]
 mov r9d,1
 call neboc_fix_it_new
 test eax,eax
 jne .fail8
 lea rdi,[rel fix_b]
 mov esi,1
 lea rdx,[rel span_overlap]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,0x52f70001
 call neboc_fix_it_add_edit
 test eax,eax
 jne .fail9
 lea rdi,[rel fix_a]
 lea rsi,[rel fix_b]
 lea rdx,[rel conflict]
 call neboc_fix_it_conflicts
 test eax,eax
 jne .fail10
 cmp qword [rel conflict],1
 jne .fail11

 lea rdi,[rel fix_c]
 lea rsi,[rel description]
 mov edx,description_len
 mov ecx,NEBOC_FIXIT_HAS_PLACEHOLDERS
 lea r8,[rel edits_c]
 mov r9d,1
 call neboc_fix_it_new
 test eax,eax
 jne .fail12
 lea rdi,[rel fix_c]
 mov esi,1
 lea rdx,[rel span_separate]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,0x52f70001
 call neboc_fix_it_add_edit
 test eax,eax
 jne .fail13
 lea rdi,[rel fix_a]
 lea rsi,[rel fix_c]
 lea rdx,[rel conflict]
 call neboc_fix_it_conflicts
 test eax,eax
 jne .fail14
 cmp qword [rel conflict],0
 jne .fail15

 lea rdi,[rel fix_one]
 lea rsi,[rel description]
 mov edx,description_len
 mov ecx,NEBOC_FIXIT_MANUAL_ONLY
 lea r8,[rel edits_one]
 mov r9d,1
 call neboc_fix_it_new
 test eax,eax
 jne .fail16
 lea rdi,[rel fix_one]
 mov esi,1
 lea rdx,[rel span_edit]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,0x52f70001
 call neboc_fix_it_add_edit
 test eax,eax
 jne .fail17
 lea rdi,[rel fix_one]
 mov esi,1
 lea rdx,[rel span_edit]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,0x52f70001
 call neboc_fix_it_add_edit
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail18

 lea rdi,[rel fix_one]
 lea rsi,[rel description]
 mov edx,description_len
 xor ecx,ecx
 lea r8,[rel edits_one]
 mov r9d,1
 call neboc_fix_it_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail19

 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],8
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],2
 lea rdi,[rel fix_a]
 lea rsi,[rel source_map]
 lea rdx,[rel writer]
 call neboc_fix_it_preview
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail20
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],2
 jne .fail21

 mov eax,0xdeadbeef
 mov [rel edits_a+NEBOC_FIXIT_EDIT_SNAPSHOT_DIGEST_OFFSET],rax
 call reset_writer
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],3
 lea rdi,[rel fix_a]
 lea rsi,[rel source_map]
 lea rdx,[rel writer]
 call neboc_fix_it_preview
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail22
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],3
 jne .fail23
 mov qword [rel edits_a+NEBOC_FIXIT_EDIT_SNAPSHOT_DIGEST_OFFSET],0x52f70001

 lea rdi,[rel code]
 mov esi,code_len
 lea rdx,[rel explanation]
 call neboc_diagnostic_explanation_load
 test eax,eax
 jne .fail24
 cmp qword [rel explanation+NEBOC_EXPLANATION_VERSION_OFFSET],NEBOC_EXPLANATION_VERSION_V1
 jne .fail25
 lea rdi,[rel explanation]
 lea rsi,[rel positive_slice]
 lea rdx,[rel negative_slice]
 call neboc_diagnostic_explanation_examples
 test eax,eax
 jne .fail26
 cmp qword [rel positive_slice+8],0
 je .fail27
 cmp qword [rel negative_slice+8],0
 je .fail28
 lea rdi,[rel explanation]
 lea rsi,[rel related_slice]
 call neboc_diagnostic_explanation_related_codes
 test eax,eax
 jne .fail29
 cmp qword [rel related_slice+8],0
 je .fail30

 call reset_writer
 lea rdi,[rel explanation]
 lea rsi,[rel writer]
 call neboc_diagnostic_explanation_render
 test eax,eax
 jne .fail31
 lea rdi,[rel title_marker]
 mov esi,title_marker_len
 call contains_output
 test eax,eax
 jz .fail32

 call reset_writer
 lea rdi,[rel query]
 mov esi,query_len
 lea rdx,[rel writer]
 call neboc_diagnostic_explanation_search
 test eax,eax
 jne .fail33
 lea rdi,[rel search_marker]
 mov esi,search_marker_len
 call contains_output
 test eax,eax
 jz .fail34

 lea rdi,[rel code]
 xor esi,esi
 lea rdx,[rel explanation]
 call neboc_diagnostic_explanation_load
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail35

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 35
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
