bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/explain.inc"
%include "compiler/diagnostics/warning_human.inc"

global _start
extern neboc_source_map_new
extern neboc_source_map_add_file
extern neboc_diagnostic_new
extern neboc_diagnostic_add_note
extern neboc_diagnostic_add_help
extern neboc_diagnostic_renderer_human
extern neboc_fix_it_new
extern neboc_fix_it_add_edit
extern neboc_warning_render_human
extern neboc_host_process_exit

%define DIGEST 0x404f0501

section .rodata
code: db "NEBO-W0001"
code_len equ $-code
message_key: db "diagnostic.compatibility.warning"
message_key_len equ $-message_key
path: db "src/main.no"
path_len equ $-path
source: db "let x = 1",10
source_len equ $-source
note: db "compatibility concern is bounded"
note_len equ $-note
help: db "choose an explicit warning policy"
help_len equ $-help
fix_description: db "rename the compatibility marker"
fix_description_len equ $-fix_description
replacement: db "_"
replacement_len equ $-replacement
expected_plain:
 db "warning[NEBO-W0001]: compatibility warning --> src/main.no:1:5",10
 db "note: compatibility concern is bounded",10
 db "help: choose an explicit warning policy",10
 db "fix: rename the compatibility marker",10
 db "--- src/main.no",10
 db "+++ src/main.no",10
 db "@@ bytes 4..5 @@",10
 db "-x",10
 db "+_",10
expected_plain_len equ $-expected_plain

section .data
add_file_request: dq path,path_len,source,source_len,DIGEST
primary_span: dq 1,4,5,source_len
fix_span: dq 1,4,5,source_len,DIGEST,1
diagnostic_request:
 dq code,code_len
 dq NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 dq NEBOC_DIAGNOSTIC_CATEGORY_TOOLING
 dq NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq message_key,message_key_len
 dq primary_span,0,0
renderer_options:
 dq 0,NEBOC_THEME_DARK,NEBOC_COLOR_NEVER,NEBOC_UNICODE_ASCII
 dq 80,1,1,0,1,NEBOC_PATH_STYLE_RELATIVE
human_request: times NEBOC_WARNING_HUMAN_REQUEST_SIZE/8 dq 0

section .bss align=16
source_map: resb NEBOC_SOURCE_MAP_SIZE
source_entries: resb NEBOC_SOURCE_ENTRY_SIZE
file_id: resq 1
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
renderer: resb NEBOC_RENDERER_SIZE
fix: resb NEBOC_FIXIT_SIZE
fix_edits: resb NEBOC_FIXIT_EDIT_SIZE
writer: resb NEBOC_WRITER_SIZE
plain_output: resb 1024
color_output: resb 1024
plain_length: resq 1

section .text
compare:
 xor eax,eax
.loop:
 test rdx,rdx
 jz .done
 mov cl,[rdi]
 cmp cl,[rsi]
 jne .different
 inc rdi
 inc rsi
 dec rdx
 jmp .loop
.different:
 mov eax,1
.done:
 ret

; Compare color output after removing the exact yellow/reset sequences.
compare_color_semantics:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 xor r8d,r8d
 xor r9d,r9d
.scan:
 cmp r8,r13
 jae .yes
 cmp byte [rbx],27
 jne .byte
 mov rax,r13
 sub rax,r8
 cmp rax,5
 jb .no
 cmp byte [rbx+1],'['
 jne .no
 cmp byte [rbx+2],'3'
 jne .maybe_reset
 cmp byte [rbx+3],'3'
 jne .no
 cmp byte [rbx+4],'m'
 jne .no
 add rbx,5
 add r8,5
 jmp .scan
.maybe_reset:
 cmp byte [rbx+2],'0'
 jne .no
 cmp byte [rbx+3],'m'
 jne .no
 add rbx,4
 add r8,4
 jmp .scan
.byte:
 cmp r9,r14
 jae .no
 mov al,[rbx]
 cmp al,[r12]
 jne .no
 inc rbx
 inc r12
 inc r8
 inc r9
 jmp .scan
.yes:
 cmp r9,r14
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

_start:
 lea rdi,[rel source_map]
 lea rsi,[rel source_entries]
 mov edx,1
 mov ecx,NEBOC_PATH_POLICY_RELATIVE
 call neboc_source_map_new
 test eax,eax
 jne .fail1
 lea rdi,[rel source_map]
 lea rsi,[rel add_file_request]
 lea rdx,[rel file_id]
 call neboc_source_map_add_file
 test eax,eax
 jne .fail2
 lea rdi,[rel diagnostic]
 lea rsi,[rel diagnostic_request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail3
 lea rdi,[rel diagnostic]
 lea rsi,[rel note]
 mov edx,note_len
 call neboc_diagnostic_add_note
 test eax,eax
 jne .fail4
 lea rdi,[rel diagnostic]
 lea rsi,[rel help]
 mov edx,help_len
 call neboc_diagnostic_add_help
 test eax,eax
 jne .fail5
 lea rdi,[rel renderer]
 lea rsi,[rel renderer_options]
 call neboc_diagnostic_renderer_human
 test eax,eax
 jne .fail6
 lea rdi,[rel fix]
 lea rsi,[rel fix_description]
 mov edx,fix_description_len
 mov ecx,NEBOC_FIXIT_MACHINE_APPLICABLE
 lea r8,[rel fix_edits]
 mov r9d,1
 call neboc_fix_it_new
 test eax,eax
 jne .fail7
 lea rdi,[rel fix]
 mov esi,1
 lea rdx,[rel fix_span]
 lea rcx,[rel replacement]
 mov r8d,replacement_len
 mov r9d,DIGEST
 call neboc_fix_it_add_edit
 test eax,eax
 jne .fail8

 lea rax,[rel renderer]
 mov [rel human_request+NEBOC_WARNING_HUMAN_RENDERER_OFFSET],rax
 lea rax,[rel diagnostic]
 mov [rel human_request+NEBOC_WARNING_HUMAN_DIAGNOSTIC_OFFSET],rax
 lea rax,[rel source_map]
 mov [rel human_request+NEBOC_WARNING_HUMAN_SOURCE_MAP_OFFSET],rax
 lea rax,[rel writer]
 mov [rel human_request+NEBOC_WARNING_HUMAN_WRITER_OFFSET],rax
 lea rax,[rel fix]
 mov [rel human_request+NEBOC_WARNING_HUMAN_FIXIT_OFFSET],rax
 mov qword [rel human_request+NEBOC_WARNING_HUMAN_FLAGS_OFFSET],NEBOC_WARNING_HUMAN_SHOW_FIX
 lea rax,[rel plain_output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],1024
 lea rdi,[rel human_request]
 call neboc_warning_render_human
 test eax,eax
 jne .fail9
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],expected_plain_len
 jne .fail10
 lea rdi,[rel plain_output]
 lea rsi,[rel expected_plain]
 mov edx,expected_plain_len
 call compare
 test eax,eax
 jne .fail11
 mov rax,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 mov [rel plain_length],rax

 mov qword [rel renderer+NEBOC_RENDERER_COLOR_OFFSET],NEBOC_COLOR_ALWAYS
 lea rax,[rel color_output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel human_request]
 call neboc_warning_render_human
 test eax,eax
 jne .fail12
 mov rdx,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 lea rdi,[rel color_output]
 lea rsi,[rel plain_output]
 mov rcx,[rel plain_length]
 call compare_color_semantics
 test eax,eax
 jz .fail13

 ; AUTO without a TTY is the exact plain byte stream.
 mov qword [rel renderer+NEBOC_RENDERER_COLOR_OFFSET],NEBOC_COLOR_AUTO
 mov qword [rel renderer+NEBOC_RENDERER_TTY_OFFSET],0
 mov qword [rel renderer+NEBOC_RENDERER_NO_COLOR_OFFSET],0
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel human_request]
 call neboc_warning_render_human
 test eax,eax
 jne .fail14
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],expected_plain_len
 jne .fail15
 lea rdi,[rel color_output]
 lea rsi,[rel expected_plain]
 mov edx,expected_plain_len
 call compare
 test eax,eax
 jne .fail16

 ; NO_COLOR suppresses decoration even for an attached TTY.
 mov qword [rel renderer+NEBOC_RENDERER_TTY_OFFSET],1
 mov qword [rel renderer+NEBOC_RENDERER_NO_COLOR_OFFSET],1
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel human_request]
 call neboc_warning_render_human
 test eax,eax
 jne .fail17
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],expected_plain_len
 jne .fail18

 ; AUTO on a TTY decorates only severity and retains the semantic stream.
 mov qword [rel renderer+NEBOC_RENDERER_NO_COLOR_OFFSET],0
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel human_request]
 call neboc_warning_render_human
 test eax,eax
 jne .fail19
 mov rdx,[rel writer+NEBOC_WRITER_LENGTH_OFFSET]
 lea rdi,[rel color_output]
 lea rsi,[rel plain_output]
 mov rcx,[rel plain_length]
 call compare_color_semantics
 test eax,eax
 jz .fail20

 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],8
 mov qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],3
 lea rdi,[rel human_request]
 call neboc_warning_render_human
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail21
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],3
 jne .fail22

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
