; Nebo Assembly — deterministic human diagnostic renderer v0
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/source/snippet/snippet.inc"

extern neboc_diagnostic_catalog_lookup
extern neboc_snippet_extract

section .rodata
s_colon: db ':'
s_colon_space: db ': '
s_space: db ' '
s_nl: db 10
s_error: db 'error'
s_error_len equ $-s_error
s_warning: db 'warning'
s_warning_len equ $-s_warning
s_note_sev: db 'note'
s_note_sev_len equ $-s_note_sev
s_note: db 'note: '
s_note_len equ $-s_note
s_help: db 'help: '
s_help_len equ $-s_help
s_related: db 'note: related location: '
s_related_len equ $-s_related
s_red: db 27,'[31m'
s_red_len equ $-s_red
s_reset: db 27,'[0m'
s_reset_len equ $-s_reset
s_open0: db '{0}'
s_open1: db '{1}'

section .text
; append(request*, bytes*, length)
append_bytes:
 test rdx,rdx
 jz .ok
 mov r8,[rdi+NEBOC_DIAGNOSTIC_RENDER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .limit
 cmp r9,[rdi+NEBOC_DIAGNOSTIC_RENDER_CAPACITY_OFFSET]
 ja .limit
 mov r10,[rdi+NEBOC_DIAGNOSTIC_RENDER_OUTPUT_OFFSET]
 add r10,r8
 xor r11d,r11d
.copy:
 cmp r11,rdx
 jae .stored
 mov al,[rsi+r11]
 mov [r10+r11],al
 inc r11
 jmp .copy
.stored:
 mov [rdi+NEBOC_DIAGNOSTIC_RENDER_LENGTH_OFFSET],r9
.ok: mov eax,NEBOC_STATUS_OK
ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
ret

append_char:
 sub rsp,24
 mov [rsp],sil
 mov rsi,rsp
 mov edx,1
 call append_bytes
 add rsp,24
 ret

append_u64:
 push rbx
 push r12
 sub rsp,40
 mov rbx,rdi
 mov rax,rsi
 lea r12,[rsp+31]
 xor ecx,ecx
 test rax,rax
 jnz .digits
 dec r12
 mov byte [r12],'0'
 mov ecx,1
 jmp .emit
.digits:
 mov r8d,10
.loop:
 xor edx,edx
 div r8
 add dl,'0'
 dec r12
 mov [r12],dl
 inc ecx
 test rax,rax
 jnz .loop
.emit:
 mov rdi,rbx
 mov rsi,r12
 mov edx,ecx
 call append_bytes
 add rsp,40
 pop r12
 pop rbx
 ret

append_message:
 ; rdi=request, rsi=message, rdx=len, rcx=diagnostic
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 xor r15d,r15d
.scan:
 cmp r15,r13
 jae .done
 mov al,[r12+r15]
 cmp al,'{'
 jne .literal
 lea rax,[r15+2]
 cmp rax,r13
 jae .literal
 cmp byte [r12+r15+2],'}'
 jne .literal
 mov al,[r12+r15+1]
 cmp al,'0'
 je .arg0
 cmp al,'1'
 je .arg1
 jmp .literal
.arg0:
 mov rdi,rbx
 mov rsi,[r14+112]
 mov rdx,[r14+120]
 call append_bytes
 test eax,eax
 jne .finish
 add r15,3
 jmp .scan
.arg1:
 mov rdi,rbx
 mov rsi,[r14+128]
 mov rdx,[r14+136]
 call append_bytes
 test eax,eax
 jne .finish
 add r15,3
 jmp .scan
.literal:
 mov rdi,rbx
 movzx esi,byte [r12+r15]
 call append_char
 test eax,eax
 jne .finish
 inc r15
 jmp .scan
.done: xor eax,eax
.finish:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; diagnostic_render_human(RenderRequest*)
NEBOC_ABI_FUNCTION neboc_diagnostic_render_human
 test rdi,rdi
 jz .invalid_fast
 mov qword [rdi+NEBOC_DIAGNOSTIC_RENDER_LENGTH_OFFSET],0
 mov rax,[rdi+NEBOC_DIAGNOSTIC_RENDER_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_DIAGNOSTIC_RENDER_LINE_MAP_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_DIAGNOSTIC_RENDER_PATH_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_DIAGNOSTIC_RENDER_OUTPUT_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_DIAGNOSTIC_RENDER_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid_fast
 cmp rax,NEBOC_DIAGNOSTIC_RENDER_HARD_MAX
 ja .invalid_fast
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,176
 mov rbx,rdi
 mov r12,[rbx]
 lea rsi,[rsp]
 mov rdi,[r12+8]
 call neboc_diagnostic_catalog_lookup
 test eax,eax
 jne .finish
 ; snippet into rsp+48
 mov rdi,[rbx+8]
 lea rsi,[r12+32]
 mov rdx,[rbx+16]
 mov rcx,[rbx+24]
 mov r8d,160
 lea r9,[rsp+48]
 call neboc_snippet_extract
 test eax,eax
 jne .finish
 ; path
 mov rdi,rbx
 mov rsi,[rbx+16]
 mov rdx,[rbx+24]
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov esi,':'
 call append_char
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov rsi,[rsp+48+40]
 call append_u64
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov esi,':'
 call append_char
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov rsi,[rsp+48+48]
 call append_u64
 test eax,eax
 jne .finish
 lea rsi,[rel s_colon_space]
 mov rdi,rbx
 mov edx,2
 call append_bytes
 test eax,eax
 jne .finish
 ; optional color
 test qword [rbx+56],NEBOC_DIAGNOSTIC_RENDER_FLAG_COLOR
 jz .severity
 lea rsi,[rel s_red]
 mov rdi,rbx
 mov edx,s_red_len
 call append_bytes
 test eax,eax
 jne .finish
.severity:
 mov rax,[r12+16]
 cmp rax,NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 je .warning
 cmp rax,NEBOC_DIAGNOSTIC_SEVERITY_NOTE
 je .note_severity
 lea rsi,[rel s_error]
 mov edx,s_error_len
 jmp .sev_emit
.warning: lea rsi,[rel s_warning]
mov edx,s_warning_len
jmp .sev_emit
.note_severity: lea rsi,[rel s_note_sev]
mov edx,s_note_sev_len
.sev_emit:
 mov rdi,rbx
 call append_bytes
 test eax,eax
 jne .finish
 test qword [rbx+56],NEBOC_DIAGNOSTIC_RENDER_FLAG_COLOR
 jz .after_color
 lea rsi,[rel s_reset]
 mov rdi,rbx
 mov edx,s_reset_len
 call append_bytes
 test eax,eax
 jne .finish
.after_color:
 mov rdi,rbx
 mov esi,' '
 call append_char
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,[rsp+8]
 call append_bytes
 test eax,eax
 jne .finish
 lea rsi,[rel s_colon_space]
 mov rdi,rbx
 mov edx,2
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov rdx,[rsp+24]
 mov rcx,r12
 call append_message
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov esi,10
 call append_char
 test eax,eax
 jne .finish
 ; source line
 mov rdi,rbx
 mov rsi,[rsp+48+24]
 mov rdx,[rsp+48+32]
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov esi,10
 call append_char
 test eax,eax
 jne .finish
 ; underline by byte-safe ASCII spaces/carets from snippet offsets
 xor r13d,r13d
.spaces:
 cmp r13,[rsp+48+72]
 jae .carets_begin
 mov rdi,rbx
 mov esi,' '
 call append_char
 test eax,eax
 jne .finish
 inc r13
 jmp .spaces
.carets_begin:
 mov r14,[rsp+48+80]
 sub r14,[rsp+48+72]
 jnz .carets
 mov r14d,1
.carets:
 test r14,r14
 jz .after_carets
 mov rdi,rbx
 mov esi,'^'
 call append_char
 test eax,eax
 jne .finish
 dec r14
 jmp .carets
.after_carets:
 mov rdi,rbx
 mov esi,10
 call append_char
 test eax,eax
 jne .finish
 ; secondary label
 test qword [r12+184],NEBOC_DIAGNOSTIC_FLAG_HAS_SECONDARY
 jz .note_text
 lea rsi,[rel s_related]
 mov rdi,rbx
 mov edx,s_related_len
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov rsi,[r12+96]
 mov rdx,[r12+104]
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov esi,10
 call append_char
 test eax,eax
 jne .finish
.note_text:
 test qword [r12+184],NEBOC_DIAGNOSTIC_FLAG_HAS_NOTE
 jz .help_text
 lea rsi,[rel s_note]
 mov rdi,rbx
 mov edx,s_note_len
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov rsi,[r12+144]
 mov rdx,[r12+152]
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov esi,10
 call append_char
 test eax,eax
 jne .finish
.help_text:
 test qword [r12+184],NEBOC_DIAGNOSTIC_FLAG_HAS_SUGGESTION
 jz .ok
 lea rsi,[rel s_help]
 mov rdi,rbx
 mov edx,s_help_len
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov rsi,[r12+160]
 mov rdx,[r12+168]
 call append_bytes
 test eax,eax
 jne .finish
 mov rdi,rbx
 mov esi,10
 call append_char
 test eax,eax
 jne .finish
.ok: xor eax,eax
.finish:
 add rsp,176
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
.invalid_fast: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
section .note.GNU-stack noalloc noexec nowrite progbits
