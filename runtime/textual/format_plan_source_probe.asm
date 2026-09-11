; G059 source-to-effect adapter. Each mode reaches the shared typed formatting
; owners and returns the source seed only after concrete observations.
bits 64
default rel
%define NEBO_G059_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/format_plan_source_probe.inc"
%include "runtime/textual/format_language.inc"

extern neboc_format_plan_validate
extern neboc_format_plan_measure
extern neboc_format_plan_write
extern neboc_format_plan_byte_size_checked
extern neboc_format_plan_render_to
extern neboc_format_plan_clone
extern neboc_format_plan_drop
extern neboc_format_string_parse_checked
extern neboc_format_string_validate
extern neboc_text_format
extern neboc_text_format_named
extern neboc_text_format_with
extern neboc_text_console
extern nebo_format_plan_evaluate_once

section .rodata
g59_plan_literal: db 'plan:'
g59_plan_value: db 'value'
g59_plan_named: db 'named'
g59_plan_position: db 'pos'
g59_static: db 'static-59'
g59_static_len equ $-g59_static
g59_bad_template: db '(]'
g59_bad_template_len equ $-g59_bad_template
g59_text_a: db 'Ol',0xc3,0xa1,' '
g59_text_a_len equ $-g59_text_a
g59_text_b: db 'Ada'
g59_text_b_len equ $-g59_text_b
g59_console_prefix: db 'console-options-'
g59_console_prefix_len equ $-g59_console_prefix
g59_conformance_prefix: db 'G059-conformance-'
g59_conformance_prefix_len equ $-g59_conformance_prefix

section .bss align=16
g59_nodes: resb FORMAT_NODE_SIZE*4
g59_plan_a: resb FORMAT_PLAN_SIZE
g59_plan_b: resb FORMAT_PLAN_SIZE
g59_output: resb 128
g59_count: resq 1
g59_visit: resq 2
g59_eval_nodes: resq 6
g59_options: resq 2
g59_current_seed: resd 1
g59_seed_bytes: resb 5

section .text
global nebo_g059_source_probe
global nebo_g059_negative_probe

g59_clear_output:
 lea rdi,[rel g59_output]
 mov ecx,16
 mov rax,0xa5a5a5a5a5a5a5a5
 rep stosq
 ret

; Materialize " ddd\n" from the first source integer. Public examples use
; three-digit distinct seeds, making the transcript source-dependent.
g59_render_seed:
 mov byte [rel g59_seed_bytes],' '
 mov eax,[rel g59_current_seed]
 xor edx,edx
 mov ecx,100
 div ecx
 add al,'0'
 mov [rel g59_seed_bytes+1],al
 mov eax,edx
 xor edx,edx
 mov ecx,10
 div ecx
 add al,'0'
 add dl,'0'
 mov [rel g59_seed_bytes+2],al
 mov [rel g59_seed_bytes+3],dl
 mov byte [rel g59_seed_bytes+4],10
 ret

g59_build_four_nodes:
 lea rdi,[rel g59_nodes]
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_LITERAL
 lea rax,[rel g59_plan_literal]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],5
 mov qword [rdi+FORMAT_NODE_PROFILE],0
 add rdi,FORMAT_NODE_SIZE
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_VALUE
 lea rax,[rel g59_plan_value]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],5
 mov qword [rdi+FORMAT_NODE_PROFILE],11
 add rdi,FORMAT_NODE_SIZE
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_NAMED
 lea rax,[rel g59_plan_named]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],5
 mov rax,0x1700000003
 mov [rdi+FORMAT_NODE_PROFILE],rax
 add rdi,FORMAT_NODE_SIZE
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_POSITION
 lea rax,[rel g59_plan_position]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],3
 mov rax,0x0200000005
 mov [rdi+FORMAT_NODE_PROFILE],rax
 ret

g59_build_text_nodes:
 call g59_render_seed
 lea rdi,[rel g59_nodes]
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_LITERAL
 lea rax,[rel g59_text_a]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],g59_text_a_len
 mov qword [rdi+FORMAT_NODE_PROFILE],0
 add rdi,FORMAT_NODE_SIZE
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_NAMED
 lea rax,[rel g59_text_b]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],g59_text_b_len
 mov rax,0x1900000000
 mov [rdi+FORMAT_NODE_PROFILE],rax
 add rdi,FORMAT_NODE_SIZE
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_POSITION
 lea rax,[rel g59_seed_bytes]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],5
 mov rax,0x0100000000
 mov [rdi+FORMAT_NODE_PROFILE],rax
 ret

g59_mode_1:
 sub rsp,8
 call g59_build_four_nodes
 lea rdi,[rel g59_nodes]
 mov esi,4
 call neboc_format_plan_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel g59_nodes]
 mov esi,4
 call neboc_format_plan_byte_size_checked
 cmp rax,18
 jne .fail
 call g59_clear_output
 lea rdi,[rel g59_nodes]
 mov esi,4
 lea rdx,[rel g59_output]
 mov ecx,128
 call neboc_format_plan_render_to
 cmp rax,18
 jne .fail
 cmp dword [rel g59_output],'plan'
 jne .fail
 cmp dword [rel g59_output+5],'valu'
 jne .fail
 cmp dword [rel g59_output+10],'name'
 jne .fail
 cmp word [rel g59_output+15],'po'
 jne .fail
 lea rax,[rel g59_nodes]
 mov [rel g59_plan_a+FORMAT_PLAN_NODES],rax
 mov qword [rel g59_plan_a+FORMAT_PLAN_COUNT],4
 mov qword [rel g59_plan_a+FORMAT_PLAN_GENERATION],59
 mov qword [rel g59_plan_a+FORMAT_PLAN_STATE],FORMAT_PLAN_LIVE
 lea rdi,[rel g59_plan_a]
 lea rsi,[rel g59_plan_b]
 call neboc_format_plan_clone
 test eax,eax
 jnz .fail
 cmp qword [rel g59_plan_b+FORMAT_PLAN_GENERATION],59
 jne .fail
 lea rdi,[rel g59_plan_a]
 call neboc_format_plan_drop
 test eax,eax
 jnz .fail
 cmp qword [rel g59_plan_b+FORMAT_PLAN_STATE],FORMAT_PLAN_LIVE
 jne .fail
 xor eax,eax
 add rsp,8
 ret
.fail:
 mov eax,1
 add rsp,8
 ret

g59_mode_2:
 sub rsp,8
 call g59_clear_output
 lea rdi,[rel g59_static]
 mov esi,g59_static_len
 lea rdx,[rel g59_nodes]
 mov ecx,1
 lea r8,[rel g59_count]
 call neboc_format_string_parse_checked
 test eax,eax
 jnz .fail
 cmp qword [rel g59_count],1
 jne .fail
 lea rdi,[rel g59_nodes]
 mov esi,1
 xor edx,edx
 call neboc_format_string_validate
 test eax,eax
 jnz .fail
 lea rdi,[rel g59_nodes]
 mov esi,1
 lea rdx,[rel g59_output]
 mov ecx,128
 call neboc_text_format
 cmp rax,g59_static_len
 jne .fail
 mov rax,'static-5'
 cmp [rel g59_output],rax
 jne .fail
 cmp byte [rel g59_output+8],'9'
 jne .fail
 xor eax,eax
 add rsp,8
 ret
.fail:
 mov eax,2
 add rsp,8
 ret

g59_mode_3:
 sub rsp,8
 call g59_build_text_nodes
 call g59_clear_output
 lea rdi,[rel g59_nodes]
 mov esi,3
 mov edx,2
 call neboc_format_string_validate
 test eax,eax
 jnz .fail_validate
 lea rdi,[rel g59_nodes]
 mov esi,3
 lea rdx,[rel g59_output]
 mov ecx,128
 call neboc_text_format_named
 cmp rax,13
 jne .fail_format
 cmp dword [rel g59_output],0xa1c36c4f
 jne .fail_utf8
 cmp dword [rel g59_output+5],'Ada '
 jne .fail_name
 movzx eax,byte [rel g59_seed_bytes+1]
 cmp byte [rel g59_output+9],al
 jne .fail_number
 movzx eax,byte [rel g59_seed_bytes+2]
 cmp byte [rel g59_output+10],al
 jne .fail_number
 movzx eax,byte [rel g59_seed_bytes+3]
 cmp byte [rel g59_output+11],al
 jne .fail_number
 lea rdi,[rel g59_output]
 mov esi,13
 xor edx,edx
 call neboc_text_console
 cmp rax,13
 jne .fail_console
 xor eax,eax
 add rsp,8
 ret
.fail_validate:
 mov eax,31
 jmp .fail
.fail_format:
 mov eax,32
 jmp .fail
.fail_utf8:
 mov eax,33
 jmp .fail
.fail_name:
 mov eax,34
 jmp .fail
.fail_number:
 mov eax,35
 jmp .fail
.fail_console:
 mov eax,36
.fail:
 add rsp,8
 ret

g59_mode_4:
 sub rsp,8
 mov qword [rel g59_eval_nodes],1
 mov qword [rel g59_eval_nodes+8],0
 mov qword [rel g59_eval_nodes+16],0
 mov qword [rel g59_eval_nodes+24],0
 mov qword [rel g59_eval_nodes+32],1
 mov qword [rel g59_eval_nodes+40],1
 lea rdi,[rel g59_eval_nodes]
 mov esi,3
 mov edx,2
 mov ecx,3
 lea r8,[rel g59_visit]
 call nebo_format_plan_evaluate_once
 test eax,eax
 jnz .fail
 cmp qword [rel g59_visit],3
 jne .fail
 cmp qword [rel g59_visit+8],3
 jne .fail
 call g59_build_text_nodes
 call g59_clear_output
 lea rdi,[rel g59_nodes]
 mov esi,3
 lea rdx,[rel g59_output]
 mov ecx,128
 xor r8d,r8d
 call neboc_text_format_with
 cmp rax,13
 jne .fail
 xor eax,eax
 add rsp,8
 ret
.fail:
 mov eax,4
 add rsp,8
 ret

g59_mode_5:
 sub rsp,8
 call g59_build_four_nodes
 call g59_clear_output
 lea rdi,[rel g59_nodes]
 mov esi,4
 lea rdx,[rel g59_output]
 mov ecx,17
 call neboc_format_plan_write
 cmp rax,-FORMAT_E_CAPACITY
 jne .fail
 mov rdx,0xa5a5a5a5a5a5a5a5
 cmp [rel g59_output],rdx
 jne .fail
 mov qword [rel g59_nodes+FORMAT_NODE_LENGTH],FORMAT_MAX_OUTPUT+1
 lea rdi,[rel g59_nodes]
 mov esi,1
 call neboc_format_plan_measure
 cmp rax,-FORMAT_E_LIMIT
 jne .fail
 lea r8,[rel g59_count]
 lea rdi,[rel g59_static]
 mov esi,g59_static_len
 lea rdx,[rel g59_nodes]
 xor ecx,ecx
 call neboc_format_string_parse_checked
 cmp eax,FORMAT_E_ALLOCATION
 jne .fail
 xor eax,eax
 add rsp,8
 ret
.fail:
 mov eax,5
 add rsp,8
 ret

g59_mode_6:
 sub rsp,8
 call g59_build_text_nodes
 call g59_clear_output
 lea rdi,[rel g59_nodes]
 mov esi,3
 lea rdx,[rel g59_output]
 mov ecx,128
 call neboc_text_format
 cmp rax,13
 jne .fail
 lea rax,[rel g59_nodes]
 mov [rel g59_plan_a+FORMAT_PLAN_NODES],rax
 mov qword [rel g59_plan_a+FORMAT_PLAN_COUNT],3
 mov qword [rel g59_plan_a+FORMAT_PLAN_GENERATION],606
 mov qword [rel g59_plan_a+FORMAT_PLAN_STATE],FORMAT_PLAN_LIVE
 lea rdi,[rel g59_plan_a]
 lea rsi,[rel g59_plan_b]
 call neboc_format_plan_clone
 test eax,eax
 jnz .fail
 lea rdi,[rel g59_plan_b]
 call neboc_format_plan_drop
 test eax,eax
 jnz .fail
 cmp qword [rel g59_plan_a+FORMAT_PLAN_STATE],FORMAT_PLAN_LIVE
 jne .fail
 xor eax,eax
 add rsp,8
 ret
.fail:
 mov eax,6
 add rsp,8
 ret

g59_mode_7:
 sub rsp,8
 call g59_render_seed
 lea rdi,[rel g59_nodes]
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_LITERAL
 lea rax,[rel g59_console_prefix]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],g59_console_prefix_len
 mov qword [rdi+FORMAT_NODE_PROFILE],0
 add rdi,FORMAT_NODE_SIZE
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_POSITION
 lea rax,[rel g59_seed_bytes+1]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],4
 mov qword [rdi+FORMAT_NODE_PROFILE],0
 call g59_clear_output
 lea rdi,[rel g59_nodes]
 mov esi,2
 lea rdx,[rel g59_output]
 mov ecx,128
 call neboc_text_format
 cmp rax,g59_console_prefix_len+4
 jne .fail
 mov qword [rel g59_options+FORMAT_CONSOLE_FD],1
 mov qword [rel g59_options+FORMAT_CONSOLE_FLAGS],0
 lea rdi,[rel g59_output]
 mov esi,g59_console_prefix_len+4
 lea rdx,[rel g59_options]
 call neboc_text_console
 cmp rax,g59_console_prefix_len+4
 jne .fail
 xor eax,eax
 add rsp,8
 ret
.fail:
 mov eax,7
 add rsp,8
 ret

g59_mode_8:
 sub rsp,8
 call g59_render_seed
 lea rdi,[rel g59_conformance_prefix]
 mov esi,g59_conformance_prefix_len
 lea rdx,[rel g59_nodes]
 mov ecx,1
 lea r8,[rel g59_count]
 call neboc_format_string_parse_checked
 test eax,eax
 jnz .fail
 lea rdi,[rel g59_nodes+FORMAT_NODE_SIZE]
 mov qword [rdi+FORMAT_NODE_KIND],FORMAT_NODE_POSITION
 lea rax,[rel g59_seed_bytes+1]
 mov [rdi+FORMAT_NODE_DATA],rax
 mov qword [rdi+FORMAT_NODE_LENGTH],4
 mov qword [rdi+FORMAT_NODE_PROFILE],0
 lea rdi,[rel g59_nodes]
 mov esi,2
 call neboc_format_plan_measure
 cmp rax,g59_conformance_prefix_len+4
 jne .fail
 call g59_clear_output
 lea rdi,[rel g59_nodes]
 mov esi,2
 lea rdx,[rel g59_output]
 mov ecx,128
 call neboc_text_format
 cmp rax,g59_conformance_prefix_len+4
 jne .fail
 lea rdi,[rel g59_output]
 mov esi,g59_conformance_prefix_len+4
 xor edx,edx
 call neboc_text_console
 cmp rax,g59_conformance_prefix_len+4
 jne .fail
 xor eax,eax
 add rsp,8
 ret
.fail:
 mov eax,8
 add rsp,8
 ret

; rdi=mode, rsi=source seed -> seed on success, bounded nonzero diagnostic.
nebo_g059_source_probe:
 push rbx
 mov ebx,esi
 mov [rel g59_current_seed],esi
 cmp edi,1
 je .m1
 cmp edi,2
 je .m2
 cmp edi,3
 je .m3
 cmp edi,4
 je .m4
 cmp edi,5
 je .m5
 cmp edi,6
 je .m6
 cmp edi,7
 je .m7
 cmp edi,8
 jne .invalid
 call g59_mode_8
 jmp .done
.m1: call g59_mode_1
 jmp .done
.m2: call g59_mode_2
 jmp .done
.m3: call g59_mode_3
 jmp .done
.m4: call g59_mode_4
 jmp .done
.m5: call g59_mode_5
 jmp .done
.m6: call g59_mode_6
 jmp .done
.m7: call g59_mode_7
.done:
 test eax,eax
 jnz .return
 mov eax,ebx
.return:
 pop rbx
 ret
.invalid:
 mov eax,FORMAT_E_INVALID
 pop rbx
 ret

; rdi=case -> zero only when the requested negative contract holds.
nebo_g059_negative_probe:
 sub rsp,8
 cmp edi,1
 je .overlap
 cmp edi,2
 je .policy
 cmp edi,3
 je .console
 cmp edi,4
 je .capacity
 cmp edi,5
 jne .bad
 lea r8,[rel g59_count]
 lea rdi,[rel g59_bad_template]
 mov esi,g59_bad_template_len
 lea rdx,[rel g59_nodes]
 mov ecx,1
 call neboc_format_string_parse_checked
 cmp eax,FORMAT_E_SYNTAX
 jne .bad
 jmp .ok
.capacity:
 lea r8,[rel g59_count]
 lea rdi,[rel g59_static]
 mov esi,g59_static_len
 lea rdx,[rel g59_nodes]
 xor ecx,ecx
 call neboc_format_string_parse_checked
 cmp eax,FORMAT_E_ALLOCATION
 jne .bad
 jmp .ok
.overlap:
 call g59_build_four_nodes
 lea rdi,[rel g59_nodes]
 mov esi,4
 lea rdx,[rel g59_plan_value]
 mov ecx,32
 call neboc_format_plan_write
 cmp rax,-FORMAT_E_INVALID
 jne .bad
 jmp .ok
.policy:
 call g59_build_text_nodes
 lea rdi,[rel g59_nodes]
 mov esi,3
 lea rdx,[rel g59_output]
 mov ecx,128
 mov r8d,1
 call neboc_text_format_with
 cmp rax,-FORMAT_E_EFFECT
 jne .bad
 jmp .ok
.console:
 mov qword [rel g59_options+FORMAT_CONSOLE_FD],1
 mov qword [rel g59_options+FORMAT_CONSOLE_FLAGS],1
 lea rdi,[rel g59_console_prefix]
 mov esi,g59_console_prefix_len
 lea rdx,[rel g59_options]
 call neboc_text_console
 cmp rax,-FORMAT_E_INVALID
 jne .bad
.ok:
 xor eax,eax
 add rsp,8
 ret
.bad:
 mov eax,1
 add rsp,8
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
