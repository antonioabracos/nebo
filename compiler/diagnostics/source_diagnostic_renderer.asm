; RELEASE-GOVERNANCE-E-ENCERRAMENTO-DE-PROGRAMAS-F03 deterministic human and short diagnostic renderer.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/source/span/source_span.inc"

section .rodata
t_error: db "error"
t_error_len equ $-t_error
t_warning: db "warning"
t_warning_len equ $-t_warning
t_note: db "note"
t_note_len equ $-t_note
t_help: db "help"
t_help_len equ $-t_help
t_bug: db "bug"
t_bug_len equ $-t_bug
t_open: db "["
t_close: db "]: "
t_arrow_ascii: db " --> source:"
t_arrow_ascii_len equ $-t_arrow_ascii
t_arrow_unicode: db " ",0xe2,0x94,0x94,0xe2,0x94,0x80,"> source:"
t_arrow_unicode_len equ $-t_arrow_unicode
t_colon: db ":"
t_nl: db 10
t_red: db 27,"[31m"
t_red_len equ $-t_red
t_reset: db 27,"[0m"
t_reset_len equ $-t_reset

section .text
writer_append:
 test rdx,rdx
 jz .wa_ok
 test rdi,rdi
 jz .wa_invalid
 test rsi,rsi
 jz .wa_invalid
 mov r8,[rdi+NEBOC_WRITER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .wa_limit
 cmp r9,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 ja .wa_limit
 mov r10,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test r10,r10
 jz .wa_invalid
 add r10,r8
 xor ecx,ecx
.wa_copy:
 cmp rcx,rdx
 jae .wa_store
 mov al,[rsi+rcx]
 mov [r10+rcx],al
 inc rcx
 jmp .wa_copy
.wa_store:
 mov [rdi+NEBOC_WRITER_LENGTH_OFFSET],r9
.wa_ok: xor eax,eax
 ret
.wa_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.wa_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

writer_u64:
 push rbx
 sub rsp,32
 mov rbx,rdi
 mov rax,rsi
 lea rsi,[rsp+31]
 xor ecx,ecx
 test rax,rax
 jnz .wu_digits
 dec rsi
 mov byte [rsi],"0"
 mov ecx,1
 jmp .wu_emit
.wu_digits:
 mov r8d,10
.wu_loop:
 xor edx,edx
 div r8
 add dl,"0"
 dec rsi
 mov [rsi],dl
 inc ecx
 test rax,rax
 jnz .wu_loop
.wu_emit:
 mov rdi,rbx
 mov edx,ecx
 call writer_append
 add rsp,32
 pop rbx
 ret

renderer_new:
 test rdi,rdi
 jz .rn_invalid
 test rsi,rsi
 jz .rn_invalid
 mov rax,[rsi+NEBOC_RENDERER_THEME_OFFSET]
 cmp rax,NEBOC_THEME_DARK
 jb .rn_invalid
 cmp rax,NEBOC_THEME_MONO
 ja .rn_invalid
 mov rax,[rsi+NEBOC_RENDERER_COLOR_OFFSET]
 cmp rax,NEBOC_COLOR_AUTO
 jb .rn_invalid
 cmp rax,NEBOC_COLOR_NEVER
 ja .rn_invalid
 mov rax,[rsi+NEBOC_RENDERER_UNICODE_OFFSET]
 cmp rax,NEBOC_UNICODE_AUTO
 jb .rn_invalid
 cmp rax,NEBOC_UNICODE_FULL
 ja .rn_invalid
 mov rax,[rsi+NEBOC_RENDERER_WIDTH_OFFSET]
 cmp rax,NEBOC_RENDERER_MIN_WIDTH
 jb .rn_invalid
 cmp rax,NEBOC_RENDERER_MAX_WIDTH
 ja .rn_invalid
 mov rax,[rsi+NEBOC_RENDERER_CONTEXT_BEFORE_OFFSET]
 cmp rax,NEBOC_RENDERER_MAX_CONTEXT
 ja .rn_invalid
 mov rax,[rsi+NEBOC_RENDERER_CONTEXT_AFTER_OFFSET]
 cmp rax,NEBOC_RENDERER_MAX_CONTEXT
 ja .rn_invalid
 push rdi
 mov rcx,NEBOC_RENDERER_SIZE/8
 cld
 rep movsq
 pop rdi
 mov [rdi+NEBOC_RENDERER_MODE_OFFSET],rdx
 xor eax,eax
 ret
.rn_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; DiagnosticRenderer.human(renderer*, options*)
NEBOC_ABI_FUNCTION neboc_diagnostic_renderer_human
 mov edx,NEBOC_RENDERER_HUMAN
 jmp renderer_new

; DiagnosticRenderer.short(renderer*, options*)
NEBOC_ABI_FUNCTION neboc_diagnostic_renderer_short
 mov edx,NEBOC_RENDERER_SHORT
 jmp renderer_new

%macro RENDERER_SET_ENUM 4
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 cmp rsi,%3
 jb %%invalid
 cmp rsi,%4
 ja %%invalid
 mov [rdi+%2],rsi
 xor eax,eax
 ret
%%invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
RENDERER_SET_ENUM neboc_renderer_theme,NEBOC_RENDERER_THEME_OFFSET,NEBOC_THEME_DARK,NEBOC_THEME_MONO
RENDERER_SET_ENUM neboc_renderer_color_policy,NEBOC_RENDERER_COLOR_OFFSET,NEBOC_COLOR_AUTO,NEBOC_COLOR_NEVER
RENDERER_SET_ENUM neboc_renderer_unicode_policy,NEBOC_RENDERER_UNICODE_OFFSET,NEBOC_UNICODE_AUTO,NEBOC_UNICODE_FULL

NEBOC_ABI_FUNCTION neboc_renderer_max_width
 test rdi,rdi
 jz .width_invalid
 cmp rsi,NEBOC_RENDERER_MIN_WIDTH
 jb .width_invalid
 cmp rsi,NEBOC_RENDERER_MAX_WIDTH
 ja .width_invalid
 mov [rdi+NEBOC_RENDERER_WIDTH_OFFSET],rsi
 xor eax,eax
 ret
.width_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_renderer_context_lines
 test rdi,rdi
 jz .context_invalid
 cmp rsi,NEBOC_RENDERER_MAX_CONTEXT
 ja .context_invalid
 cmp rdx,NEBOC_RENDERER_MAX_CONTEXT
 ja .context_invalid
 mov [rdi+NEBOC_RENDERER_CONTEXT_BEFORE_OFFSET],rsi
 mov [rdi+NEBOC_RENDERER_CONTEXT_AFTER_OFFSET],rdx
 xor eax,eax
 ret
.context_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; renderer.render(renderer*, diagnostic*, source_map*, writer*)
; SourceMap is explicit even where this bounded renderer needs only the stable
; source id and offsets already captured in the diagnostic.
NEBOC_ABI_FUNCTION neboc_renderer_render
 test rdi,rdi
 jz .render_invalid
 test rsi,rsi
 jz .render_invalid
 test rdx,rdx
 jz .render_invalid
 test rcx,rcx
 jz .render_invalid
 cmp qword [rsi+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .render_invalid
 mov qword [rcx+NEBOC_WRITER_LENGTH_OFFSET],0
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rcx
 mov r14,[r12+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET]
 mov r15,[rbx+NEBOC_RENDERER_COLOR_OFFSET]
 cmp r15,NEBOC_COLOR_ALWAYS
 je .render_color
 cmp r15,NEBOC_COLOR_AUTO
 jne .render_severity
 cmp qword [rbx+NEBOC_RENDERER_TTY_OFFSET],1
 jne .render_severity
 cmp qword [rbx+NEBOC_RENDERER_NO_COLOR_OFFSET],0
 jne .render_severity
.render_color:
 mov rdi,r13
 lea rsi,[rel t_red]
 mov edx,t_red_len
 call writer_append
 test eax,eax
 jne .render_finish
.render_severity:
 lea rsi,[rel t_error]
 mov edx,t_error_len
 cmp r14,NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .sev_note
 lea rsi,[rel t_warning]
 mov edx,t_warning_len
.sev_note:
 cmp r14,NEBOC_DIAGNOSTIC_SEVERITY_NOTE
 jne .sev_help
 lea rsi,[rel t_note]
 mov edx,t_note_len
.sev_help:
 cmp r14,NEBOC_DIAGNOSTIC_SEVERITY_HELP
 jne .sev_bug
 lea rsi,[rel t_help]
 mov edx,t_help_len
.sev_bug:
 cmp r14,NEBOC_DIAGNOSTIC_SEVERITY_BUG
 jne .sev_emit
 lea rsi,[rel t_bug]
 mov edx,t_bug_len
.sev_emit:
 mov rdi,r13
 call writer_append
 test eax,eax
 jne .render_finish
 cmp r15,NEBOC_COLOR_ALWAYS
 je .reset
 cmp r15,NEBOC_COLOR_AUTO
 jne .after_reset
 cmp qword [rbx+NEBOC_RENDERER_TTY_OFFSET],1
 jne .after_reset
 cmp qword [rbx+NEBOC_RENDERER_NO_COLOR_OFFSET],0
 jne .after_reset
.reset:
 mov rdi,r13
 lea rsi,[rel t_reset]
 mov edx,t_reset_len
 call writer_append
 test eax,eax
 jne .render_finish
.after_reset:
 mov rdi,r13
 lea rsi,[rel t_open]
 mov edx,1
 call writer_append
 test eax,eax
 jne .render_finish
 mov rdi,r13
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rdx,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call writer_append
 test eax,eax
 jne .render_finish
 mov rdi,r13
 lea rsi,[rel t_close]
 mov edx,3
 call writer_append
 test eax,eax
 jne .render_finish
 mov rdi,r13
 mov rsi,[r12+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET]
 mov rdx,[r12+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET]
 call writer_append
 test eax,eax
 jne .render_finish
 cmp qword [rbx+NEBOC_RENDERER_MODE_OFFSET],NEBOC_RENDERER_SHORT
 je .newline
 cmp qword [r12+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 jne .newline
 mov rdi,r13
 lea rsi,[rel t_arrow_ascii]
 mov edx,t_arrow_ascii_len
 cmp qword [rbx+NEBOC_RENDERER_UNICODE_OFFSET],NEBOC_UNICODE_FULL
 jne .arrow_emit
 lea rsi,[rel t_arrow_unicode]
 mov edx,t_arrow_unicode_len
.arrow_emit:
 call writer_append
 test eax,eax
 jne .render_finish
 mov rdi,r13
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 call writer_u64
 test eax,eax
 jne .render_finish
 mov rdi,r13
 lea rsi,[rel t_colon]
 mov edx,1
 call writer_append
 test eax,eax
 jne .render_finish
 mov rdi,r13
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 call writer_u64
 test eax,eax
 jne .render_finish
.newline:
 mov rdi,r13
 lea rsi,[rel t_nl]
 mov edx,1
 call writer_append
.render_finish:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.render_invalid: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
