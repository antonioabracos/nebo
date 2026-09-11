bits 64
default rel
%define NEBO_TAGGED_TEMPLATES_IMPLEMENTATION 1
%include "runtime/textual/tagged_templates.inc"

section .rodata
tag_html: db 'html'
tag_markdown: db 'markdown'
tag_json: db 'json'
tag_log: db 'log'
tag_console: db 'console'
tag_sql: db 'sql'

section .text
global neboc_template_tag_lookup
global neboc_tagged_template_render
global neboc_multiline_normalize

; rdi=name, rsi=len, rdx=record. Registry is closed and versioned.
neboc_template_tag_lookup:
 test rdi,rdi
 jz .lookup_invalid
 test rdx,rdx
 jz .lookup_invalid
 mov r8,rdx
 cmp rsi,4
 jne .lookup_markdown
 cmp dword [rdi],'html'
 je .lookup_html
 cmp dword [rdi],'json'
 je .lookup_json
.lookup_markdown:
 cmp rsi,8
 jne .lookup_short
 cmp dword [rdi],'mark'
 jne .lookup_short
 cmp dword [rdi+4],'down'
 je .lookup_markdown_ok
.lookup_short:
 cmp rsi,3
 jne .lookup_console
 cmp word [rdi],'lo'
 jne .lookup_sql
 cmp byte [rdi+2],'g'
 je .lookup_log
.lookup_sql:
 cmp word [rdi],'sq'
 jne .lookup_invalid
 cmp byte [rdi+2],'l'
 je .lookup_sql_ok
.lookup_console:
 cmp rsi,7
 jne .lookup_invalid
 cmp dword [rdi],'cons'
 jne .lookup_invalid
 cmp word [rdi+4],'ol'
 jne .lookup_invalid
 cmp byte [rdi+6],'e'
 jne .lookup_invalid
 mov eax,TEMPLATE_TAG_CONSOLE
 jmp .lookup_public
.lookup_html: mov eax,TEMPLATE_TAG_HTML
 jmp .lookup_public
.lookup_markdown_ok: mov eax,TEMPLATE_TAG_MARKDOWN
 jmp .lookup_public
.lookup_json: mov eax,TEMPLATE_TAG_JSON
 jmp .lookup_public
.lookup_log: mov eax,TEMPLATE_TAG_LOG
 jmp .lookup_public
.lookup_sql_ok:
 mov qword [r8+TEMPLATE_TAG_RECORD_ID],TEMPLATE_TAG_SQL
 mov qword [r8+TEMPLATE_TAG_RECORD_VERSION],TEMPLATE_TAG_VERSION
 mov qword [r8+TEMPLATE_TAG_RECORD_FLAGS],0
 mov qword [r8+TEMPLATE_TAG_RECORD_MATURITY],TEMPLATE_TAG_MATURITY_EXTERNAL
 xor eax,eax
 ret
.lookup_public:
 mov [r8+TEMPLATE_TAG_RECORD_ID],rax
 mov qword [r8+TEMPLATE_TAG_RECORD_VERSION],TEMPLATE_TAG_VERSION
 mov qword [r8+TEMPLATE_TAG_RECORD_FLAGS],1
 mov qword [r8+TEMPLATE_TAG_RECORD_MATURITY],TEMPLATE_TAG_MATURITY_PUBLIC
 xor eax,eax
 ret
.lookup_invalid:
 mov eax,TAGGED_TEXT_E_INVALID
 ret

; rdi=tag id, rsi=input, rdx=len, rcx=output, r8=capacity.
; Returns committed bytes or a negative typed status. Measurement, security and
; overlap checks complete before the first output byte is touched.
neboc_tagged_template_render:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 cmp r12,TEMPLATE_TAG_SQL
 je .render_external
 cmp r12,TEMPLATE_TAG_HTML
 jb .render_invalid
 cmp r12,TEMPLATE_TAG_CONSOLE
 ja .render_invalid
 test r14,r14
 jz .measure_init
 test r13,r13
 jz .render_invalid
 cmp r14,TAGGED_TEXT_MAX_INPUT
 ja .render_limit
.measure_init:
 xor ebx,ebx
 cmp r12,TEMPLATE_TAG_JSON
 je .measure_json_open
 cmp r12,TEMPLATE_TAG_LOG
 je .measure_log_open
 jmp .measure_scan_start
.measure_json_open:
 mov ebx,2
 jmp .measure_scan_start
.measure_log_open:
 mov ebx,10                         ; message= plus JSON quotes
.measure_scan_start:
 xor r9d,r9d
.measure_scan:
 cmp r9,r14
 jae .measure_done
 movzx eax,byte [r13+r9]
 cmp r12,TEMPLATE_TAG_HTML
 je .measure_html
 cmp r12,TEMPLATE_TAG_MARKDOWN
 je .measure_markdown
 cmp r12,TEMPLATE_TAG_JSON
 je .measure_json
 cmp r12,TEMPLATE_TAG_LOG
 je .measure_json
 inc rbx
 jmp .measure_next
.measure_html:
 cmp al,'&'
 je .html_five
 cmp al,'<'
 je .html_four
 cmp al,'>'
 je .html_four
 cmp al,'"'
 je .html_six
 cmp al,39
 je .html_five
 inc rbx
 jmp .measure_next
.html_four: add rbx,4
 jmp .measure_next
.html_five: add rbx,5
 jmp .measure_next
.html_six: add rbx,6
 jmp .measure_next
.measure_markdown:
 cmp al,92
 je .markdown_two
 cmp al,'*'
 je .markdown_two
 cmp al,'_'
 je .markdown_two
 cmp al,'['
 je .markdown_two
 cmp al,']'
 je .markdown_two
 cmp al,96
 je .markdown_two
 cmp al,'#'
 je .markdown_two
 inc rbx
 jmp .measure_next
.markdown_two: add rbx,2
 jmp .measure_next
.measure_json:
 cmp al,0x20
 jb .json_control
 cmp al,'"'
 je .json_two
 cmp al,92
 je .json_two
 inc rbx
 jmp .measure_next
.json_control:
 cmp al,10
 je .json_two
 cmp al,13
 je .json_two
 cmp al,9
 je .json_two
 jmp .render_security
.json_two: add rbx,2
.measure_next:
 cmp rbx,TAGGED_TEXT_MAX_OUTPUT
 ja .render_limit
 inc r9
 jmp .measure_scan
.measure_done:
 cmp rbx,[rsp]
 ja .render_capacity
 test rbx,rbx
 jz .render_success
 test r15,r15
 jz .render_invalid
 lea rax,[r13+r14]
 lea rdx,[r15+rbx]
 cmp rax,r13
 jb .render_invalid
 cmp rdx,r15
 jb .render_invalid
 cmp r15,rax
 jae .write_begin
 cmp rdx,r13
 ja .render_invalid
.write_begin:
 mov rdi,r15
 cmp r12,TEMPLATE_TAG_JSON
 je .write_json_open
 cmp r12,TEMPLATE_TAG_LOG
 je .write_log_open
 jmp .write_scan_start
.write_json_open:
 mov byte [rdi],'"'
 inc rdi
 jmp .write_scan_start
.write_log_open:
 mov dword [rdi],'mess'
 mov dword [rdi+4],'age='
 add rdi,8
 mov byte [rdi],'"'
 inc rdi
.write_scan_start:
 xor r9d,r9d
.write_scan:
 cmp r9,r14
 jae .write_done
 mov al,[r13+r9]
 cmp r12,TEMPLATE_TAG_HTML
 je .write_html
 cmp r12,TEMPLATE_TAG_MARKDOWN
 je .write_markdown
 cmp r12,TEMPLATE_TAG_JSON
 je .write_json
 cmp r12,TEMPLATE_TAG_LOG
 je .write_json
 stosb
 jmp .write_next
.write_html:
 cmp al,'&'
 je .write_amp
 cmp al,'<'
 je .write_lt
 cmp al,'>'
 je .write_gt
 cmp al,'"'
 je .write_quot
 cmp al,39
 je .write_apos
 stosb
 jmp .write_next
.write_amp: mov dword [rdi],'&amp'
 mov byte [rdi+4],';'
 add rdi,5
 jmp .write_next
.write_lt: mov dword [rdi],'&lt;'
 add rdi,4
 jmp .write_next
.write_gt: mov dword [rdi],'&gt;'
 add rdi,4
 jmp .write_next
.write_quot:
 mov dword [rdi],'&quo'
 mov word [rdi+4],'t;'
 add rdi,6
 jmp .write_next
.write_apos:
 mov dword [rdi],'&#39'
 mov byte [rdi+4],';'
 add rdi,5
 jmp .write_next
.write_markdown:
 cmp al,92
 je .write_markdown_escape
 cmp al,'*'
 je .write_markdown_escape
 cmp al,'_'
 je .write_markdown_escape
 cmp al,'['
 je .write_markdown_escape
 cmp al,']'
 je .write_markdown_escape
 cmp al,96
 je .write_markdown_escape
 cmp al,'#'
 je .write_markdown_escape
 stosb
 jmp .write_next
.write_markdown_escape:
 mov byte [rdi],92
 inc rdi
 stosb
 jmp .write_next
.write_json:
 cmp al,'"'
 je .write_json_quote
 cmp al,92
 je .write_json_slash
 cmp al,10
 je .write_json_n
 cmp al,13
 je .write_json_r
 cmp al,9
 je .write_json_t
 stosb
 jmp .write_next
.write_json_quote: mov ah,'"'
 jmp .write_json_pair
.write_json_slash: mov ah,92
 jmp .write_json_pair
.write_json_n: mov ah,'n'
 jmp .write_json_pair
.write_json_r: mov ah,'r'
 jmp .write_json_pair
.write_json_t: mov ah,'t'
.write_json_pair:
 mov byte [rdi],92
 mov [rdi+1],ah
 add rdi,2
.write_next:
 inc r9
 jmp .write_scan
.write_done:
 cmp r12,TEMPLATE_TAG_JSON
 je .write_json_close
 cmp r12,TEMPLATE_TAG_LOG
 jne .render_success
.write_json_close:
 mov byte [rdi],'"'
.render_success:
 mov rax,rbx
 jmp .render_done
.render_invalid: mov rax,-TAGGED_TEXT_E_INVALID
 jmp .render_done
.render_limit: mov rax,-TAGGED_TEXT_E_LIMIT
 jmp .render_done
.render_capacity: mov rax,-TAGGED_TEXT_E_CAPACITY
 jmp .render_done
.render_security: mov rax,-TAGGED_TEXT_E_SECURITY
 jmp .render_done
.render_external: mov rax,-TAGGED_TEXT_E_EXTERNAL
.render_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=input, rsi=len, edx=dedent policy, ecx=newline policy, r8=output,
; r9=capacity. Common-dedent is bounded to 64 spaces and newline conversion
; normalizes CRLF/CR to LF. Output remains untouched on all errors.
neboc_multiline_normalize:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov r14,r8
 mov r15,r9
 test r13,r13
 jz .norm_empty
 test r12,r12
 jz .norm_invalid
 cmp r13,TAGGED_TEXT_MAX_INPUT
 ja .norm_limit
 cmp qword [rsp],TAGGED_TEXT_DEDENT_COMMON
 ja .norm_invalid
 cmp qword [rsp+8],TAGGED_TEXT_NEWLINE_LF
 ja .norm_invalid
 mov qword [rsp+16],0              ; common indent
 cmp qword [rsp],TAGGED_TEXT_DEDENT_COMMON
 jne .norm_measure
 mov qword [rsp+16],TAGGED_TEXT_MAX_INDENT
 xor r8d,r8d
 xor r9d,r9d
 mov r10d,1
.indent_scan:
 cmp r8,r13
 jae .indent_done
 mov al,[r12+r8]
 test r10d,r10d
 jz .indent_not_start
 cmp al,' '
 jne .indent_content
 inc r9
 cmp r9,TAGGED_TEXT_MAX_INDENT
 ja .norm_limit
 inc r8
 jmp .indent_scan
.indent_content:
 cmp al,10
 je .indent_newline
 cmp al,13
 je .indent_newline
 cmp r9,[rsp+16]
 jae .indent_mark_content
 mov [rsp+16],r9
.indent_mark_content:
 xor r10d,r10d
.indent_not_start:
 cmp al,10
 je .indent_newline
 cmp al,13
 jne .indent_next
.indent_newline:
 mov r10d,1
 xor r9d,r9d
.indent_next:
 inc r8
 jmp .indent_scan
.indent_done:
 cmp qword [rsp+16],TAGGED_TEXT_MAX_INDENT
 jne .norm_measure
 mov qword [rsp+16],0
.norm_measure:
 xor ebx,ebx                       ; measured output
 xor r8d,r8d                       ; cursor
 mov r10d,1                        ; line start
.norm_measure_loop:
 cmp r8,r13
 jae .norm_measured
 test r10d,r10d
 jz .norm_measure_byte
 mov rcx,[rsp+16]
.norm_skip_measure:
 test rcx,rcx
 jz .norm_measure_started
 cmp r8,r13
 jae .norm_measured
 cmp byte [r12+r8],' '
 jne .norm_measure_started
 inc r8
 dec rcx
 jmp .norm_skip_measure
.norm_measure_started:
 xor r10d,r10d
 cmp r8,r13
 jae .norm_measured
.norm_measure_byte:
 mov al,[r12+r8]
 cmp al,13
 jne .norm_measure_lf
 cmp qword [rsp+8],TAGGED_TEXT_NEWLINE_LF
 jne .norm_measure_plain
 inc r8
 cmp r8,r13
 jae .norm_measure_one_lf
 cmp byte [r12+r8],10
 jne .norm_measure_one_lf
 inc r8
.norm_measure_one_lf:
 inc rbx
 mov r10d,1
 jmp .norm_measure_loop
.norm_measure_lf:
 cmp al,10
 jne .norm_measure_plain
 inc rbx
 inc r8
 mov r10d,1
 jmp .norm_measure_loop
.norm_measure_plain:
 inc rbx
 inc r8
 jmp .norm_measure_loop
.norm_measured:
 cmp rbx,r15
 ja .norm_capacity
 test rbx,rbx
 jz .norm_empty
 test r14,r14
 jz .norm_invalid
 lea rax,[r12+r13]
 lea rcx,[r14+rbx]
 cmp r14,rax
 jae .norm_write
 cmp rcx,r12
 ja .norm_invalid
.norm_write:
 xor r8d,r8d
 mov rdi,r14
 mov r10d,1
.norm_write_loop:
 cmp r8,r13
 jae .norm_success
 test r10d,r10d
 jz .norm_write_byte
 mov rcx,[rsp+16]
.norm_skip_write:
 test rcx,rcx
 jz .norm_write_started
 cmp r8,r13
 jae .norm_success
 cmp byte [r12+r8],' '
 jne .norm_write_started
 inc r8
 dec rcx
 jmp .norm_skip_write
.norm_write_started:
 xor r10d,r10d
 cmp r8,r13
 jae .norm_success
.norm_write_byte:
 mov al,[r12+r8]
 cmp al,13
 jne .norm_write_regular
 cmp qword [rsp+8],TAGGED_TEXT_NEWLINE_LF
 jne .norm_write_regular
 inc r8
 cmp r8,r13
 jae .norm_write_lf
 cmp byte [r12+r8],10
 jne .norm_write_lf
 inc r8
.norm_write_lf:
 mov byte [rdi],10
 inc rdi
 mov r10d,1
 jmp .norm_write_loop
.norm_write_regular:
 mov [rdi],al
 inc rdi
 inc r8
 cmp al,10
 jne .norm_write_loop
 mov r10d,1
 jmp .norm_write_loop
.norm_success:
 mov rax,rbx
 jmp .norm_done
.norm_empty: xor eax,eax
 jmp .norm_done
.norm_invalid: mov rax,-TAGGED_TEXT_E_INVALID
 jmp .norm_done
.norm_limit: mov rax,-TAGGED_TEXT_E_LIMIT
 jmp .norm_done
.norm_capacity: mov rax,-TAGGED_TEXT_E_CAPACITY
.norm_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
