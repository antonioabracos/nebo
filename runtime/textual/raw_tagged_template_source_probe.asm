; G063 source-to-effect owner. Generated programs receive only a validated mode
; and source digest; no lexer or template parser is linked into the executable.
bits 64
default rel
%define NEBO_G063_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/raw_tagged_template_source_probe.inc"
%include "runtime/textual/tagged_templates.inc"

section .rodata
g63_multiline: db '    alpha',13,10,'      beta',13,10
g63_multiline_len equ $-g63_multiline
g63_normalized: db 'alpha',10,'  beta',10
g63_normalized_len equ $-g63_normalized
g63_html: db '<&>'
g63_html_len equ $-g63_html
g63_html_expected: db '&lt;&amp;&gt;'
g63_html_expected_len equ $-g63_html_expected
g63_markdown: db '# [x]'
g63_markdown_len equ $-g63_markdown
g63_markdown_expected: db 92,'# ',92,'[x',92,']'
g63_markdown_expected_len equ $-g63_markdown_expected
g63_json: db '"x"',10
g63_json_len equ $-g63_json
g63_json_expected: db '"',92,'"x',92,'"',92,'n','"'
g63_json_expected_len equ $-g63_json_expected
g63_log: db 'event'
g63_log_len equ $-g63_log
g63_log_expected: db 'message="event"'
g63_log_expected_len equ $-g63_log_expected
g63_attack: db '<script>'
g63_attack_len equ $-g63_attack
g63_attack_expected: db '&lt;script&gt;'
g63_attack_expected_len equ $-g63_attack_expected
g63_control: db 1

section .bss align=16
g63_output: resb 128

section .text
global nebo_g063_source_probe
global nebo_g063_negative_probe

g63_fill:
 lea rdi,[rel g63_output]
 mov ecx,32
 mov eax,0xa5a5a5a5
 rep stosd
 ret

; edi=mode 1..8, esi=nonzero source digest. Return digest only after a real
; mode-specific normalization/render effect matches an independent byte oracle.
nebo_g063_source_probe:
 push rbx
 push r12
 push r13
 mov ebx,esi
 test ebx,ebx
 jz .fail
 cmp edi,1
 jb .fail
 cmp edi,8
 ja .fail
 mov r12d,edi
 call g63_fill
 cmp r12d,3
 ja .tagged
 lea rdi,[rel g63_multiline]
 mov esi,g63_multiline_len
 mov edx,TAGGED_TEXT_DEDENT_COMMON
 mov ecx,TAGGED_TEXT_NEWLINE_LF
 lea r8,[rel g63_output]
 mov r9d,128
 call neboc_multiline_normalize
 cmp rax,g63_normalized_len
 jne .fail
 lea rsi,[rel g63_normalized]
 mov r13,g63_normalized_len
 jmp .compare
.tagged:
 cmp r12d,4
 je .html
 cmp r12d,5
 je .markdown
 cmp r12d,6
 je .json
 cmp r12d,7
 je .log
 lea rsi,[rel g63_attack]
 mov edx,g63_attack_len
 mov edi,TEMPLATE_TAG_HTML
 lea rcx,[rel g63_output]
 mov r8d,128
 call neboc_tagged_template_render
 cmp rax,g63_attack_expected_len
 jne .fail
 lea rsi,[rel g63_attack_expected]
 mov r13,g63_attack_expected_len
 jmp .compare
.html:
 lea rsi,[rel g63_html]
 mov edx,g63_html_len
 mov edi,TEMPLATE_TAG_HTML
 lea rcx,[rel g63_output]
 mov r8d,128
 call neboc_tagged_template_render
 cmp rax,g63_html_expected_len
 jne .fail
 lea rsi,[rel g63_html_expected]
 mov r13,g63_html_expected_len
 jmp .compare
.markdown:
 lea rsi,[rel g63_markdown]
 mov edx,g63_markdown_len
 mov edi,TEMPLATE_TAG_MARKDOWN
 lea rcx,[rel g63_output]
 mov r8d,128
 call neboc_tagged_template_render
 cmp rax,g63_markdown_expected_len
 jne .fail
 lea rsi,[rel g63_markdown_expected]
 mov r13,g63_markdown_expected_len
 jmp .compare
.json:
 lea rsi,[rel g63_json]
 mov edx,g63_json_len
 mov edi,TEMPLATE_TAG_JSON
 lea rcx,[rel g63_output]
 mov r8d,128
 call neboc_tagged_template_render
 cmp rax,g63_json_expected_len
 jne .fail
 lea rsi,[rel g63_json_expected]
 mov r13,g63_json_expected_len
 jmp .compare
.log:
 lea rsi,[rel g63_log]
 mov edx,g63_log_len
 mov edi,TEMPLATE_TAG_LOG
 lea rcx,[rel g63_output]
 mov r8d,128
 call neboc_tagged_template_render
 cmp rax,g63_log_expected_len
 jne .fail
 lea rsi,[rel g63_log_expected]
 mov r13,g63_log_expected_len
.compare:
 lea rdi,[rel g63_output]
 mov rcx,r13
 repe cmpsb
 jne .fail
 mov eax,ebx
 jmp .done
.fail:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; Independently exercises capacity, external maturity and security failure
; atomicity. Returns zero only when every output byte remains untouched.
nebo_g063_negative_probe:
 push rbx
 call g63_fill
 lea rsi,[rel g63_attack]
 mov edx,g63_attack_len
 mov edi,TEMPLATE_TAG_HTML
 lea rcx,[rel g63_output]
 mov r8d,2
 call neboc_tagged_template_render
 cmp rax,-TAGGED_TEXT_E_CAPACITY
 jne .negative_fail
 cmp byte [rel g63_output],0xa5
 jne .negative_fail
 lea rsi,[rel g63_attack]
 mov edx,g63_attack_len
 mov edi,TEMPLATE_TAG_SQL
 lea rcx,[rel g63_output]
 mov r8d,128
 call neboc_tagged_template_render
 cmp rax,-TAGGED_TEXT_E_EXTERNAL
 jne .negative_fail
 cmp byte [rel g63_output],0xa5
 jne .negative_fail
 lea rsi,[rel g63_control]
 mov edx,1
 mov edi,TEMPLATE_TAG_JSON
 lea rcx,[rel g63_output]
 mov r8d,128
 call neboc_tagged_template_render
 cmp rax,-TAGGED_TEXT_E_SECURITY
 jne .negative_fail
 cmp byte [rel g63_output],0xa5
 jne .negative_fail
 xor eax,eax
 jmp .negative_done
.negative_fail:
 mov eax,1
.negative_done:
 pop rbx
 ret
