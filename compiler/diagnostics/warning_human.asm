; C04-F05 canonical, bounded and color-independent human warning renderer.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/explain.inc"
%include "compiler/diagnostics/warning_registry.inc"
%include "compiler/diagnostics/warning_human.inc"
%include "compiler/source/span/source_span.inc"
%include "compiler/source/source_map.inc"

extern neboc_warning_registry_lookup
extern neboc_diagnostic_explanation_load
extern neboc_source_map_line_column
extern neboc_source_map_display_path
extern neboc_fix_it_preview

section .rodata
t_warning: db "warning"
t_warning_len equ $-t_warning
t_open: db "["
t_close: db "]: "
t_location: db " --> "
t_colon: db ":"
t_newline: db 10
t_note: db "note: "
t_note_len equ $-t_note
t_help: db "help: "
t_help_len equ $-t_help
t_fix: db "fix: "
t_fix_len equ $-t_fix
t_yellow: db 27,"[33m"
t_yellow_len equ $-t_yellow
t_reset: db 27,"[0m"
t_reset_len equ $-t_reset

section .text
; append(writer*, bytes*, length)
warning_append:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .ok
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_WRITER_LENGTH_OFFSET]
 mov r9,r8
 add r9,rdx
 jc .limit
 cmp r9,[rdi+NEBOC_WRITER_CAPACITY_OFFSET]
 ja .limit
 mov r10,[rdi+NEBOC_WRITER_BYTES_OFFSET]
 test r10,r10
 jz .invalid
 add r10,r8
 xor ecx,ecx
.copy:
 cmp rcx,rdx
 jae .store
 mov al,[rsi+rcx]
 mov [r10+rcx],al
 inc rcx
 jmp .copy
.store:
 mov [rdi+NEBOC_WRITER_LENGTH_OFFSET],r9
.ok:
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

warning_append_u64:
 push rbx
 sub rsp,32
 mov rbx,rdi
 mov rax,rsi
 lea rsi,[rsp+32]
 xor ecx,ecx
 test rax,rax
 jnz .digits
 dec rsi
 mov byte [rsi],'0'
 mov ecx,1
 jmp .emit
.digits:
 mov r8d,10
.loop:
 xor edx,edx
 div r8
 add dl,'0'
 dec rsi
 mov [rsi],dl
 inc ecx
 test rax,rax
 jnz .loop
.emit:
 mov rdi,rbx
 mov edx,ecx
 call warning_append
 add rsp,32
 pop rbx
 ret

%macro WARNING_APPEND 2
 mov rdi,r13
 lea rsi,[rel %1]
 mov edx,%2
 call warning_append
 test eax,eax
 jnz .rollback
%endmacro

; warning_render_human(request*)
; Human text contains the same semantic tokens with or without ANSI color.
; Fixes are previews only; this function never mutates source storage.
NEBOC_ABI_FUNCTION neboc_warning_render_human
 test rdi,rdi
 jz .invalid_fast
 mov rax,[rdi+NEBOC_WARNING_HUMAN_RENDERER_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_WARNING_HUMAN_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_WARNING_HUMAN_SOURCE_MAP_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_WARNING_HUMAN_WRITER_OFFSET]
 test rax,rax
 jz .invalid_fast
 mov rax,[rdi+NEBOC_WARNING_HUMAN_FLAGS_OFFSET]
 test rax,~NEBOC_WARNING_HUMAN_KNOWN_FLAGS
 jnz .invalid_fast
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,240
 mov rbx,rdi
 mov r14,[rbx+NEBOC_WARNING_HUMAN_RENDERER_OFFSET]
 mov r12,[rbx+NEBOC_WARNING_HUMAN_DIAGNOSTIC_OFFSET]
 mov r15,[rbx+NEBOC_WARNING_HUMAN_SOURCE_MAP_OFFSET]
 mov r13,[rbx+NEBOC_WARNING_HUMAN_WRITER_OFFSET]
 cmp qword [r14+NEBOC_RENDERER_MODE_OFFSET],NEBOC_RENDERER_HUMAN
 jne .invalid_local
 cmp qword [r14+NEBOC_RENDERER_COLOR_OFFSET],NEBOC_COLOR_AUTO
 jb .invalid_local
 cmp qword [r14+NEBOC_RENDERER_COLOR_OFFSET],NEBOC_COLOR_NEVER
 ja .invalid_local
 cmp qword [r14+NEBOC_RENDERER_PATH_STYLE_OFFSET],NEBOC_PATH_STYLE_RELATIVE
 jb .invalid_local
 cmp qword [r14+NEBOC_RENDERER_PATH_STYLE_OFFSET],NEBOC_PATH_STYLE_REDACTED
 ja .invalid_local
 cmp qword [r12+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 jne .invalid_local
 cmp qword [r12+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],NEBOC_DIAGNOSTIC_SEVERITY_WARNING
 jne .invalid_local
 cmp qword [r12+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 jne .invalid_local
 cmp qword [r15+NEBOC_SOURCE_MAP_ACTIVE_OFFSET],1
 jne .invalid_local
 mov rax,[r13+NEBOC_WRITER_BYTES_OFFSET]
 test rax,rax
 jz .invalid_local
 mov rax,[r13+NEBOC_WRITER_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid_local
 cmp rax,NEBOC_EXPLANATION_MAX_OUTPUT_BYTES
 ja .invalid_local
 cmp qword [r13+NEBOC_WRITER_LENGTH_OFFSET],rax
 ja .invalid_local
 mov rax,[r13+NEBOC_WRITER_LENGTH_OFFSET]
 mov [rsp+232],rax
 mov qword [r13+NEBOC_WRITER_LENGTH_OFFSET],0

 mov rdi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .rollback
 mov rdi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 lea rdx,[rsp]
 call neboc_diagnostic_explanation_load
 test eax,eax
 jnz .rollback

 mov rdi,r15
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 mov rdx,[r12+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 lea rcx,[rsp+120]
 call neboc_source_map_line_column
 test eax,eax
 jnz .rollback
 mov rdi,r15
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET]
 mov rdx,[r14+NEBOC_RENDERER_PATH_STYLE_OFFSET]
 lea rcx,[rsp+216]
 call neboc_source_map_display_path
 test eax,eax
 jnz .rollback

 mov rax,[r14+NEBOC_RENDERER_COLOR_OFFSET]
 cmp rax,NEBOC_COLOR_ALWAYS
 je .color
 cmp rax,NEBOC_COLOR_AUTO
 jne .severity
 cmp qword [r14+NEBOC_RENDERER_TTY_OFFSET],1
 jne .severity
 cmp qword [r14+NEBOC_RENDERER_NO_COLOR_OFFSET],0
 jne .severity
.color:
 WARNING_APPEND t_yellow,t_yellow_len
.severity:
 WARNING_APPEND t_warning,t_warning_len
 mov rax,[r14+NEBOC_RENDERER_COLOR_OFFSET]
 cmp rax,NEBOC_COLOR_ALWAYS
 je .reset
 cmp rax,NEBOC_COLOR_AUTO
 jne .after_reset
 cmp qword [r14+NEBOC_RENDERER_TTY_OFFSET],1
 jne .after_reset
 cmp qword [r14+NEBOC_RENDERER_NO_COLOR_OFFSET],0
 jne .after_reset
.reset:
 WARNING_APPEND t_reset,t_reset_len
.after_reset:
 WARNING_APPEND t_open,1
 mov rdi,r13
 mov rsi,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rdx,[r12+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call warning_append
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_close,3
 mov rdi,r13
 mov rsi,[rsp+NEBOC_EXPLANATION_TITLE_OFFSET]
 mov rdx,[rsp+NEBOC_EXPLANATION_TITLE_LENGTH_OFFSET]
 call warning_append
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_location,5
 mov rdi,r13
 mov rsi,[rsp+216+NEBOC_SOURCE_MAP_SLICE_POINTER_OFFSET]
 mov rdx,[rsp+216+neboc_recovery_SLICE_LENGTH_OFFSET]
 call warning_append
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_colon,1
 mov rdi,r13
 mov rsi,[rsp+120+NEBOC_MACHINE_SOURCE_LOCATION_LINE_OFFSET]
 call warning_append_u64
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_colon,1
 mov rdi,r13
 mov rsi,[rsp+120+NEBOC_SOURCE_LOCATION_DISPLAY_COLUMN_OFFSET]
 call warning_append_u64
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_newline,1

 mov rax,[r12+NEBOC_DIAGNOSTIC_NOTE_COUNT_OFFSET]
 cmp rax,NEBOC_DIAGNOSTIC_MAX_NOTES
 ja .invalid_rollback
 mov [rsp+168],rax
 mov qword [rsp+176],0
.note_loop:
 mov rax,[rsp+176]
 cmp rax,[rsp+168]
 jae .help_setup
 imul rax,NEBOC_DIAGNOSTIC_TEXT_ITEM_SIZE
 lea r10,[r12+NEBOC_DIAGNOSTIC_NOTES_OFFSET]
 add r10,rax
 mov [rsp+184],r10
 mov r11,[r10+NEBOC_DIAGNOSTIC_TEXT_LENGTH_OFFSET]
 test r11,r11
 jz .invalid_rollback
 cmp r11,NEBOC_DIAGNOSTIC_MAX_TEXT_BYTES
 ja .invalid_rollback
 cmp qword [r10+NEBOC_DIAGNOSTIC_TEXT_POINTER_OFFSET],0
 je .invalid_rollback
 WARNING_APPEND t_note,t_note_len
 mov r10,[rsp+184]
 mov rdi,r13
 mov rsi,[r10+NEBOC_DIAGNOSTIC_TEXT_POINTER_OFFSET]
 mov rdx,[r10+NEBOC_DIAGNOSTIC_TEXT_LENGTH_OFFSET]
 call warning_append
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_newline,1
 inc qword [rsp+176]
 jmp .note_loop
.help_setup:
 mov rax,[r12+NEBOC_DIAGNOSTIC_HELP_COUNT_OFFSET]
 cmp rax,NEBOC_DIAGNOSTIC_MAX_HELPS
 ja .invalid_rollback
 mov [rsp+168],rax
 mov qword [rsp+176],0
.help_loop:
 mov rax,[rsp+176]
 cmp rax,[rsp+168]
 jae .fix
 imul rax,NEBOC_DIAGNOSTIC_TEXT_ITEM_SIZE
 lea r10,[r12+NEBOC_DIAGNOSTIC_HELPS_OFFSET]
 add r10,rax
 mov [rsp+184],r10
 mov r11,[r10+NEBOC_DIAGNOSTIC_TEXT_LENGTH_OFFSET]
 test r11,r11
 jz .invalid_rollback
 cmp r11,NEBOC_DIAGNOSTIC_MAX_TEXT_BYTES
 ja .invalid_rollback
 cmp qword [r10+NEBOC_DIAGNOSTIC_TEXT_POINTER_OFFSET],0
 je .invalid_rollback
 WARNING_APPEND t_help,t_help_len
 mov r10,[rsp+184]
 mov rdi,r13
 mov rsi,[r10+NEBOC_DIAGNOSTIC_TEXT_POINTER_OFFSET]
 mov rdx,[r10+NEBOC_DIAGNOSTIC_TEXT_LENGTH_OFFSET]
 call warning_append
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_newline,1
 inc qword [rsp+176]
 jmp .help_loop
.fix:
 test qword [rbx+NEBOC_WARNING_HUMAN_FLAGS_OFFSET],NEBOC_WARNING_HUMAN_SHOW_FIX
 jz .ok
 mov rax,[rbx+NEBOC_WARNING_HUMAN_FIXIT_OFFSET]
 test rax,rax
 jz .invalid_rollback
 cmp qword [rax+NEBOC_FIXIT_ACTIVE_OFFSET],1
 jne .invalid_rollback
 mov rdx,[rax+NEBOC_FIXIT_DESCRIPTION_LENGTH_OFFSET]
 test rdx,rdx
 jz .invalid_rollback
 cmp rdx,NEBOC_FIXIT_MAX_DESCRIPTION_BYTES
 ja .invalid_rollback
 cmp qword [rax+NEBOC_FIXIT_DESCRIPTION_OFFSET],0
 je .invalid_rollback
 WARNING_APPEND t_fix,t_fix_len
 mov rax,[rbx+NEBOC_WARNING_HUMAN_FIXIT_OFFSET]
 mov rdi,r13
 mov rsi,[rax+NEBOC_FIXIT_DESCRIPTION_OFFSET]
 mov rdx,[rax+NEBOC_FIXIT_DESCRIPTION_LENGTH_OFFSET]
 call warning_append
 test eax,eax
 jnz .rollback
 WARNING_APPEND t_newline,1
 mov rdi,[rbx+NEBOC_WARNING_HUMAN_FIXIT_OFFSET]
 mov rsi,r15
 mov rdx,r13
 call neboc_fix_it_preview
 test eax,eax
 jnz .rollback
.ok:
 xor eax,eax
 jmp .finish
.invalid_rollback:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.rollback:
 mov rcx,[rsp+232]
 mov [r13+NEBOC_WRITER_LENGTH_OFFSET],rcx
 jmp .finish
.invalid_local:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.finish:
 add rsp,240
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_fast:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
