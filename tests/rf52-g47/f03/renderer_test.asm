bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
global _start
extern neboc_diagnostic_new
extern neboc_diagnostic_renderer_human
extern neboc_diagnostic_renderer_short
extern neboc_renderer_render
extern neboc_renderer_theme
extern neboc_renderer_color_policy
extern neboc_renderer_unicode_policy
extern neboc_renderer_max_width
extern neboc_renderer_context_lines
extern neboc_host_process_exit
section .rodata
code: db "NEBO-E0001"
code_len equ $-code
key: db "diagnostic.schema.invalid"
key_len equ $-key
expected_human: db "error[NEBO-E0001]: diagnostic.schema.invalid --> source:1:2",10
expected_human_len equ $-expected_human
expected_short: db "error[NEBO-E0001]: diagnostic.schema.invalid",10
expected_short_len equ $-expected_short
section .data
span: dq 1,2,4,8
request: dq code,code_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_CATEGORY_TOOLING,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN,key,key_len,span,0,0
options: dq 0,NEBOC_THEME_DARK,NEBOC_COLOR_NEVER,NEBOC_UNICODE_ASCII,80,1,1,0,1,1
section .bss align=16
diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
renderer: resb NEBOC_RENDERER_SIZE
writer: resb NEBOC_WRITER_SIZE
output: resb 256
dummy_source_map: resq 1
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
.different: mov eax,1
.done: ret
_start:
 sub rsp,8
 lea rdi,[rel diagnostic]
 lea rsi,[rel request]
 call neboc_diagnostic_new
 test eax,eax
 jne .fail1
 lea rdi,[rel renderer]
 lea rsi,[rel options]
 call neboc_diagnostic_renderer_human
 test eax,eax
 jne .fail2
 lea rax,[rel output]
 mov [rel writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],256
 lea rdi,[rel renderer]
 lea rsi,[rel diagnostic]
 lea rdx,[rel dummy_source_map]
 lea rcx,[rel writer]
 call neboc_renderer_render
 test eax,eax
 jne .fail3
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],expected_human_len
 jne .fail4
 lea rdi,[rel output]
 lea rsi,[rel expected_human]
 mov edx,expected_human_len
 call compare
 test eax,eax
 jne .fail5

 lea rdi,[rel renderer]
 lea rsi,[rel options]
 call neboc_diagnostic_renderer_short
 test eax,eax
 jne .fail6
 lea rdi,[rel renderer]
 lea rsi,[rel diagnostic]
 lea rdx,[rel dummy_source_map]
 lea rcx,[rel writer]
 call neboc_renderer_render
 test eax,eax
 jne .fail7
 cmp qword [rel writer+NEBOC_WRITER_LENGTH_OFFSET],expected_short_len
 jne .fail8
 lea rdi,[rel output]
 lea rsi,[rel expected_short]
 mov edx,expected_short_len
 call compare
 test eax,eax
 jne .fail9

 lea rdi,[rel renderer]
 mov esi,39
 call neboc_renderer_max_width
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail10
 lea rdi,[rel renderer]
 mov esi,9
 xor edx,edx
 call neboc_renderer_context_lines
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail11
 lea rdi,[rel renderer]
 mov esi,NEBOC_COLOR_ALWAYS
 call neboc_renderer_color_policy
 test eax,eax
 jne .fail12
 lea rdi,[rel renderer]
 mov esi,NEBOC_UNICODE_FULL
 call neboc_renderer_unicode_policy
 test eax,eax
 jne .fail13
 lea rdi,[rel renderer]
 mov esi,NEBOC_THEME_MONO
 call neboc_renderer_theme
 test eax,eax
 jne .fail14
 mov qword [rel writer+NEBOC_WRITER_CAPACITY_OFFSET],8
 lea rdi,[rel renderer]
 lea rsi,[rel diagnostic]
 lea rdx,[rel dummy_source_map]
 lea rcx,[rel writer]
 call neboc_renderer_render
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail15
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 15
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
