bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/memory/arena.inc"
%include "compiler/source/line-map/line_map.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/catalog.inc"

global _start
extern neboc_diagnostic_catalog_lookup
extern neboc_diagnostic_init
extern neboc_diagnostic_set_args
extern neboc_diagnostic_set_note_suggestion
extern neboc_diagnostic_set_secondary
extern neboc_diagnostic_store_init
extern neboc_diagnostic_store_push
extern neboc_diagnostic_store_finalize
extern neboc_diagnostic_render_human
extern neboc_host_process_exit

%define OWNER 0x445941474e4f5354
section .rodata
source: db 'first',10,'value.console();',10,'last',10
source_len equ $-source
path: db 'src/main.no'
path_len equ $-path
arg_int: db 'Int'
arg_int_len equ $-arg_int
arg_text: db 'Text'
arg_text_len equ $-arg_text
secondary_label: db 'receiver declaration'
secondary_label_len equ $-secondary_label
note_text: db 'receiver has type Text'
note_text_len equ $-note_text
help_text: db 'use an Int receiver'
help_text_len equ $-help_text
expected: incbin "tests/diagnostics/goldens/type-mismatch-no-color.txt"
expected_len equ $-expected
line_starts: dq 0,6,23,28

section .bss align=16
fake_arena: resb NEBOC_ARENA_SIZE
line_map: resb NEBOC_LINE_MAP_SIZE
primary: resb NEBOC_SOURCE_SPAN_SIZE
secondary: resb NEBOC_SOURCE_SPAN_SIZE
diag_a: resb NEBOC_DIAGNOSTIC_SIZE
diag_b: resb NEBOC_DIAGNOSTIC_SIZE
diag_c: resb NEBOC_DIAGNOSTIC_SIZE
diag_d: resb NEBOC_DIAGNOSTIC_SIZE
store: resb NEBOC_DIAGNOSTIC_STORE_SIZE
entries: resb NEBOC_DIAGNOSTIC_SIZE*4
request_a: resb NEBOC_DIAGNOSTIC_RENDER_SIZE
request_b: resb NEBOC_DIAGNOSTIC_RENDER_SIZE
output_a: resb 1024
output_b: resb 1024
catalog_entry: resb NEBOC_DIAG_ENTRY_SIZE

section .text
_start:
 sub rsp,8
 ; Manual valid LineMap/Arena for deterministic borrowed source.
 mov qword [rel fake_arena+NEBOC_ARENA_ACTIVE_OFFSET],1
 mov rax,OWNER
 mov [rel fake_arena+NEBOC_ARENA_OWNER_OFFSET],rax
 mov qword [rel fake_arena+NEBOC_ARENA_GENERATION_OFFSET],1
 lea rax,[rel source]
 mov [rel line_map+NEBOC_LINE_MAP_SOURCE_OFFSET],rax
 mov qword [rel line_map+NEBOC_LINE_MAP_SOURCE_LENGTH_OFFSET],source_len
 lea rax,[rel line_starts]
 mov [rel line_map+NEBOC_LINE_MAP_STARTS_OFFSET],rax
 mov qword [rel line_map+NEBOC_LINE_MAP_LINE_COUNT_OFFSET],4
 lea rax,[rel fake_arena]
 mov [rel line_map+NEBOC_LINE_MAP_ARENA_OFFSET],rax
 mov rax,OWNER
 mov [rel line_map+NEBOC_LINE_MAP_OWNER_OFFSET],rax
 mov qword [rel line_map+NEBOC_LINE_MAP_SOURCE_ID_OFFSET],1
 mov qword [rel line_map+NEBOC_LINE_MAP_ARENA_GENERATION_OFFSET],1
 mov qword [rel line_map+NEBOC_LINE_MAP_ACTIVE_OFFSET],1
 ; primary span bytes 8..13 => line2 col3, five carets
 mov qword [rel primary],1
 mov qword [rel primary+8],8
 mov qword [rel primary+16],13
 mov qword [rel primary+24],source_len
 mov qword [rel secondary],1
 mov qword [rel secondary+8],6
 mov qword [rel secondary+16],11
 mov qword [rel secondary+24],source_len
 ; catalog present
 mov edi,NEBOC_DIAG_TYPE_MISMATCH
 lea rsi,[rel catalog_entry]
 call neboc_diagnostic_catalog_lookup
 test eax,eax
 jne .fail1
 cmp qword [rel catalog_entry+NEBOC_DIAG_ENTRY_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 jne .fail2
 ; structured diagnostic A
 lea rdi,[rel diag_a]
 mov esi,NEBOC_DIAG_TYPE_MISMATCH
 mov edx,NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 mov ecx,NEBOC_DIAGNOSTIC_PHASE_TYPE
 lea r8,[rel primary]
 call neboc_diagnostic_init
 test eax,eax
 jne .fail3
 lea rdi,[rel diag_a]
 lea rsi,[rel arg_int]
 mov edx,arg_int_len
 lea rcx,[rel arg_text]
 mov r8d,arg_text_len
 call neboc_diagnostic_set_args
 test eax,eax
 jne .fail4
 lea rdi,[rel diag_a]
 lea rsi,[rel note_text]
 mov edx,note_text_len
 lea rcx,[rel help_text]
 mov r8d,help_text_len
 call neboc_diagnostic_set_note_suggestion
 test eax,eax
 jne .fail5
 lea rdi,[rel diag_a]
 lea rsi,[rel secondary]
 lea rdx,[rel secondary_label]
 mov ecx,secondary_label_len
 call neboc_diagnostic_set_secondary
 test eax,eax
 jne .fail6
 ; B before A by source position
 lea rdi,[rel diag_b]
 mov esi,NEBOC_DIAG_CLI_USAGE
 mov edx,NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 mov ecx,NEBOC_DIAGNOSTIC_PHASE_DRIVER
 lea r8,[rel secondary]
 call neboc_diagnostic_init
 test eax,eax
 jne .fail7
 ; C is a valid later diagnostic used to reach the configured limit.
 lea rdi,[rel diag_c]
 mov esi,NEBOC_DIAG_INTERNAL_ERROR
 mov edx,NEBOC_DIAGNOSTIC_SEVERITY_ERROR
 mov ecx,NEBOC_DIAGNOSTIC_PHASE_INTERNAL
 lea r8,[rel primary]
 call neboc_diagnostic_init
 test eax,eax
 jne .fail8
 ; store A then B, finalize must sort B first
 lea rdi,[rel store]
 lea rsi,[rel entries]
 mov edx,4
 mov ecx,3
 call neboc_diagnostic_store_init
 test eax,eax
 jne .fail8
 lea rdi,[rel store]
 lea rsi,[rel diag_a]
 call neboc_diagnostic_store_push
 test eax,eax
 jne .fail9
 lea rdi,[rel store]
 lea rsi,[rel diag_b]
 call neboc_diagnostic_store_push
 test eax,eax
 jne .fail10
 lea rdi,[rel store]
 lea rsi,[rel diag_c]
 call neboc_diagnostic_store_push
 test eax,eax
 jne .fail11
 lea rdi,[rel store]
 lea rsi,[rel diag_d]
 call neboc_diagnostic_store_push
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail12
 cmp qword [rel store+NEBOC_DIAGNOSTIC_STORE_DROPPED_OFFSET],1
 jne .fail13
 lea rdi,[rel store]
 call neboc_diagnostic_store_finalize
 test eax,eax
 jne .fail14
 cmp qword [rel entries+NEBOC_DIAGNOSTIC_CODE_OFFSET],NEBOC_DIAG_CLI_USAGE
 jne .fail15
 ; render no-color
 lea rax,[rel diag_a]
 mov [rel request_a],rax
 lea rax,[rel line_map]
 mov [rel request_a+8],rax
 lea rax,[rel path]
 mov [rel request_a+16],rax
 mov qword [rel request_a+24],path_len
 lea rax,[rel output_a]
 mov [rel request_a+32],rax
 mov qword [rel request_a+40],1024
 mov qword [rel request_a+56],0
 lea rdi,[rel request_a]
 call neboc_diagnostic_render_human
 test eax,eax
 jne .fail16
 cmp qword [rel request_a+48],expected_len
 jne .fail17
 lea rsi,[rel output_a]
 lea rdi,[rel expected]
 mov ecx,expected_len
 repe cmpsb
 jne .fail18
 ; deterministic render from a second request/address
 lea rax,[rel diag_a]
 mov [rel request_b],rax
 lea rax,[rel line_map]
 mov [rel request_b+8],rax
 lea rax,[rel path]
 mov [rel request_b+16],rax
 mov qword [rel request_b+24],path_len
 lea rax,[rel output_b]
 mov [rel request_b+32],rax
 mov qword [rel request_b+40],1024
 mov qword [rel request_b+56],0
 lea rdi,[rel request_b]
 call neboc_diagnostic_render_human
 test eax,eax
 jne .fail19
 mov rcx,[rel request_a+48]
 cmp rcx,[rel request_b+48]
 jne .fail20
 lea rsi,[rel output_a]
 lea rdi,[rel output_b]
 repe cmpsb
 jne .fail21
 ; no ANSI ESC in no-color output
 lea rsi,[rel output_a]
 mov rcx,[rel request_a+48]
.scan_esc:
 test rcx,rcx
 jz .success
 cmp byte [rsi],27
 je .fail22
 inc rsi
 dec rcx
 jmp .scan_esc
.success:
 xor edi,edi
 jmp .exit
.fail1: mov edi,1
jmp .exit
.fail2: mov edi,2
jmp .exit
.fail3: mov edi,3
jmp .exit
.fail4: mov edi,4
jmp .exit
.fail5: mov edi,5
jmp .exit
.fail6: mov edi,6
jmp .exit
.fail7: mov edi,7
jmp .exit
.fail8: mov edi,8
jmp .exit
.fail9: mov edi,9
jmp .exit
.fail10: mov edi,10
jmp .exit
.fail11: mov edi,11
jmp .exit
.fail12: mov edi,12
jmp .exit
.fail13: mov edi,13
jmp .exit
.fail14: mov edi,14
jmp .exit
.fail15: mov edi,15
jmp .exit
.fail16: mov edi,16
jmp .exit
.fail17: mov edi,17
jmp .exit
.fail18: mov edi,18
jmp .exit
.fail19: mov edi,19
jmp .exit
.fail20: mov edi,20
jmp .exit
.fail21: mov edi,21
jmp .exit
.fail22: mov edi,22
.exit:
 add rsp,8
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
