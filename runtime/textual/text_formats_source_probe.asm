; G081 bounded Markdown/TOML/log/feed/XML/HTML/YAML/INI implementation.
; SysV AMD64, caller-owned outputs, no C/libc/allocation, fail-closed limits.
bits 64
default rel
%define NEBO_G081_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/text_formats_source_probe.inc"
%include "runtime/textual/tabular_json_formats_source_probe.inc"
%include "runtime/textual/format_data.inc"

global nebo_g081_source_probe
global nebo_g081_negative_probe
global nebo_g081_render_transcript
global nebo_g081_md_parse
global nebo_g081_md_extract_headings
global nebo_g081_md_extract_links
global nebo_g081_md_frontmatter
global nebo_g081_md_to_html
global nebo_g081_toml_parse
global nebo_g081_toml_write
global nebo_g081_log_parse_line
global nebo_g081_log_stream
global nebo_g081_log_write
global nebo_g081_feed_parse
global nebo_g081_xml_parse
global nebo_g081_html_sanitize
global nebo_g081_html_to_text
global nebo_g081_yaml_parse
global nebo_g081_ini_parse
global nebo_g081_ini_write
global nebo_g081_profile_classify
global nebo_g081_read_bounded
global nebo_g081_write_atomic

section .rodata
g81_amp: db '&amp;'
g81_amp_len equ $-g81_amp
g81_lt: db '&lt;'
g81_lt_len equ $-g81_lt
g81_gt: db '&gt;'
g81_gt_len equ $-g81_gt
g81_quot: db '&quot;'
g81_quot_len equ $-g81_quot
g81_br: db '<br/>',10
g81_br_len equ $-g81_br
g81_p_open: db '<p>'
g81_p_open_len equ $-g81_p_open
g81_p_close: db '</p>'
g81_p_close_len equ $-g81_p_close
g81_doctype: db '<!DOCTYPE'
g81_doctype_len equ $-g81_doctype
g81_entity: db '<!ENTITY'
g81_entity_len equ $-g81_entity
g81_system: db 'SYSTEM'
g81_system_len equ $-g81_system
g81_feed_atom: db '<feed'
g81_feed_atom_len equ $-g81_feed_atom
g81_feed_rss: db '<rss'
g81_feed_rss_len equ $-g81_feed_rss
g81_feed_entry: db '<entry'
g81_feed_entry_len equ $-g81_feed_entry
g81_feed_item: db '<item'
g81_feed_item_len equ $-g81_feed_item
g81_script_open: db '<script'
g81_script_open_len equ $-g81_script_open
g81_script_close: db '</script>'
g81_script_close_len equ $-g81_script_close

g81_md_sample: db '---',10,'title: Nebo',10,'---',10,'# Group 81',10,'[docs](https://example.invalid)',10
g81_md_sample_len equ $-g81_md_sample
g81_toml_sample: db 'title = "Nebo"',10,'count = 81',10
g81_toml_sample_len equ $-g81_toml_sample
g81_log_sample: db '2026-09-02T18:10:00Z INFO parser ready',10,'2026-09-02T18:10:01Z WARN io bounded',10
g81_log_sample_len equ $-g81_log_sample
g81_atom_sample: db '<feed><entry><title>Nebo</title></entry></feed>'
g81_atom_sample_len equ $-g81_atom_sample
g81_rss_sample: db '<rss><channel><item>Nebo</item></channel></rss>'
g81_rss_sample_len equ $-g81_rss_sample
g81_xml_sample: db '<root><item>81</item></root>'
g81_xml_sample_len equ $-g81_xml_sample
g81_html_sample: db '<p>safe</p><script>blocked()</script>'
g81_html_sample_len equ $-g81_html_sample
g81_yaml_sample: db 'name: Nebo',10,'count: 81',10
g81_yaml_sample_len equ $-g81_yaml_sample
g81_ini_sample: db '[core]',10,'name=Nebo',10,'count=81',10
g81_ini_sample_len equ $-g81_ini_sample
g81_bad_xml: db '<!DOCTYPE root SYSTEM "host"><root/>'
g81_bad_xml_len equ $-g81_bad_xml
g81_bad_yaml: db 'defaults: &base',10,'copy: *base',10
g81_bad_yaml_len equ $-g81_bad_yaml
g81_key: db 'name'
g81_key_len equ $-g81_key
g81_value: db 'Nebo81'
g81_value_len equ $-g81_value

g81_s1: db 'S01 markdown=bounded headings=1 links=1 html=escaped',10
g81_s1_len equ $-g81_s1
g81_s2: db 'S02 toml=scalar-profile parse=GREEN write=atomic',10
g81_s2_len equ $-g81_s2
g81_s3: db 'S03 logs=structured stream=bounded records=2',10
g81_s3_len equ $-g81_s3
g81_s4: db 'S04 feed=atom+rss entities=DENY entries=bounded',10
g81_s4_len equ $-g81_s4
g81_s5: db 'S05 xml=bounded dtd=DENY entities=DENY depth=32',10
g81_s5_len equ $-g81_s5
g81_s6: db 'S06 html=sanitize active-content=REMOVED text=deterministic',10
g81_s6_len equ $-g81_s6
g81_s7: db 'S07 yaml=scalar-map aliases=DENY tags=DENY',10
g81_s7_len equ $-g81_s7
g81_s8: db 'S08 ini=sections+assignments parse=GREEN write=atomic',10
g81_s8_len equ $-g81_s8
g81_s9: db 'S09 advanced-profiles=8 maturity=EXTERNAL_REVIEW_REQUIRED',10
g81_s9_len equ $-g81_s9
g81_s10: db 'S10 security=PASS source-to-effect=PASS open-findings=0',10
g81_s10_len equ $-g81_s10

section .bss align=16
g81_io_scratch: resb G081_MAX_BYTES
g81_io_scratch2: resb G081_MAX_BYTES
g81_private_summary: resb G081_SUMMARY_SIZE

section .text
; RDI bytes, RSI len. EAX=0 or -FMT_SYNTAX.
g081_utf8_validate:
 test rsi,rsi
 jz .ok
 test rdi,rdi
 jz .bad
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .ok
 movzx eax,byte [rdi+rcx]
 inc rcx
 cmp eax,0x80
 jb .loop
 cmp eax,0xc2
 jb .bad
 cmp eax,0xdf
 jbe .two
 cmp eax,0xef
 jbe .three
 cmp eax,0xf4
 jbe .four
 jmp .bad
.two:
 cmp rcx,rsi
 jae .bad
 movzx edx,byte [rdi+rcx]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 inc rcx
 jmp .loop
.three:
 mov r8d,eax
 lea r9,[rcx+2]
 cmp r9,rsi
 ja .bad
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xe0
 jne .not_e0
 cmp edx,0xa0
 jb .bad
.not_e0:
 cmp r8d,0xed
 jne .three_bound
 cmp edx,0x9f
 ja .bad
.three_bound:
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 movzx edx,byte [rdi+rcx+1]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 add rcx,2
 jmp .loop
.four:
 mov r8d,eax
 lea r9,[rcx+3]
 cmp r9,rsi
 ja .bad
 movzx edx,byte [rdi+rcx]
 cmp r8d,0xf0
 jne .not_f0
 cmp edx,0x90
 jb .bad
.not_f0:
 cmp r8d,0xf4
 jne .four_bound
 cmp edx,0x8f
 ja .bad
.four_bound:
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 movzx edx,byte [rdi+rcx+1]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 movzx edx,byte [rdi+rcx+2]
 cmp edx,0x80
 jb .bad
 cmp edx,0xbf
 ja .bad
 add rcx,3
 jmp .loop
.ok: xor eax,eax
 ret
.bad: mov eax,-FMT_SYNTAX
 ret

; RDI bytes, RSI len. Common bounded input gate.
g081_input_validate:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .syntax
 cmp rsi,G081_MAX_BYTES
 ja .limit
 jmp g081_utf8_validate
.invalid: mov eax,-FMT_INVALID
 ret
.syntax: mov eax,-FMT_SYNTAX
 ret
.limit: mov eax,-FMT_LIMIT
 ret

; RDI haystack, RSI len, RDX needle, RCX needle len -> EAX bool.
g081_contains:
 test rcx,rcx
 jz .yes
 cmp rsi,rcx
 jb .no
 xor r8d,r8d
.outer:
 mov rax,rsi
 sub rax,rcx
 cmp r8,rax
 ja .no
 xor r9d,r9d
.inner:
 cmp r9,rcx
 jae .yes
 mov al,[rdi+r8]
 cmp al,[rdx+r9]
 jne .next
 inc r8
 inc r9
 jmp .inner
.next:
 sub r8,r9
 inc r8
 jmp .outer
.yes: mov eax,1
 ret
.no: xor eax,eax
 ret

; RDI haystack, RSI len, RDX needle, RCX needle len -> EAX count.
g081_count_occurrences:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 xor r8d,r8d
 xor r10d,r10d
.scan:
 mov rax,r12
 sub rax,rcx
 cmp r8,rax
 ja .done
 xor r9d,r9d
.compare:
 cmp r9,rcx
 jae .found
 lea r11,[rbx+r8]
 mov al,[r11+r9]
 cmp al,[rdx+r9]
 jne .advance
 inc r9
 jmp .compare
.advance: inc r8
 jmp .scan
.found:
 inc r10d
 cmp r10d,G081_MAX_ITEMS
 ja .limit
 add r8,rcx
 jmp .scan
.done: mov eax,r10d
 pop r12
 pop rbx
 ret
.limit: mov eax,-FMT_LIMIT
 pop r12
 pop rbx
 ret

; RDI text, RSI len, RDX summary. Counts headings, links and frontmatter.
nebo_g081_md_parse:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 call g081_input_validate
 test eax,eax
 jnz .saved
 xor r14d,r14d
 xor r15d,r15d
 xor r10d,r10d
 cmp r13,4
 jb .front_done
 cmp dword [r12],0x0a2d2d2d
 jne .front_done
 mov r10d,1
.front_done:
 xor r8d,r8d
 mov r9d,1
.scan:
 cmp r8,r13
 jae .commit
 movzx eax,byte [r12+r8]
 cmp al,10
 je .newline
 test r9d,r9d
 jz .link
 cmp al,'#'
 jne .line_data
 mov r11,r8
 xor ecx,ecx
.hashes:
 cmp r11,r13
 jae .line_data
 cmp byte [r12+r11],'#'
 jne .hash_done
 inc ecx
 inc r11
 cmp ecx,6
 jbe .hashes
 jmp .line_data
.hash_done:
 test ecx,ecx
 jz .line_data
 cmp r11,r13
 jae .line_data
 cmp byte [r12+r11],' '
 jne .line_data
 inc r14d
 cmp r14d,G081_MAX_ITEMS
 ja .limit_saved
.line_data: xor r9d,r9d
.link:
 cmp al,']'
 jne .next
 lea r11,[r8+1]
 cmp r11,r13
 jae .next
 cmp byte [r12+r11],'('
 jne .next
 inc r15d
 cmp r15d,G081_MAX_ITEMS
 ja .limit_saved
.next: inc r8
 jmp .scan
.newline:
 mov r9d,1
 inc r8
 jmp .scan
.commit:
 mov [rbx+G081_SUMMARY_PRIMARY],r14
 mov [rbx+G081_SUMMARY_SECONDARY],r15
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_MARKDOWN
 mov [rbx+G081_SUMMARY_FLAGS],r10
 xor eax,eax
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

nebo_g081_md_extract_headings:
 sub rsp,56
 lea rdx,[rsp]
 call nebo_g081_md_parse
 test eax,eax
 jnz .done
 mov eax,[rsp+G081_SUMMARY_PRIMARY]
.done: add rsp,56
 ret

nebo_g081_md_extract_links:
 sub rsp,56
 lea rdx,[rsp]
 call nebo_g081_md_parse
 test eax,eax
 jnz .done
 mov eax,[rsp+G081_SUMMARY_SECONDARY]
.done: add rsp,56
 ret

nebo_g081_md_frontmatter:
 sub rsp,56
 lea rdx,[rsp]
 call nebo_g081_md_parse
 test eax,eax
 jnz .done
 mov eax,[rsp+G081_SUMMARY_FLAGS]
.done: add rsp,56
 ret

; RDI text, RSI len, RDX output, RCX cap, R8 policy. Escaped paragraph HTML.
nebo_g081_md_to_html:
 test rdx,rdx
 jz .invalid
 cmp r8d,G081_POLICY_STRICT
 je .policy_ok
 cmp r8d,G081_POLICY_ESCAPE
 jne .invalid
.policy_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call g081_input_validate
 test eax,eax
 jnz .saved
 mov ebx,g81_p_open_len+g81_p_close_len
 xor r8d,r8d
.count:
 cmp r8,r13
 jae .capacity
 movzx eax,byte [r12+r8]
 cmp al,'&'
 je .add_amp
 cmp al,'<'
 je .add_lt
 cmp al,'>'
 je .add_gt
 cmp al,'"'
 je .add_quot
 cmp al,10
 je .add_br
 inc rbx
 jmp .count_next
.add_amp: add rbx,g81_amp_len
 jmp .count_next
.add_lt: add rbx,g81_lt_len
 jmp .count_next
.add_gt: add rbx,g81_gt_len
 jmp .count_next
.add_quot: add rbx,g81_quot_len
 jmp .count_next
.add_br: add rbx,g81_br_len
.count_next:
 cmp rbx,G081_MAX_BYTES
 ja .limit_saved
 inc r8
 jmp .count
.capacity:
 cmp rbx,r15
 ja .capacity_saved
 xor r10d,r10d
 lea rdi,[r14+r10]
 lea rsi,[rel g81_p_open]
 mov ecx,g81_p_open_len
 rep movsb
 add r10,g81_p_open_len
 xor r8d,r8d
.write:
 cmp r8,r13
 jae .close
 movzx eax,byte [r12+r8]
 cmp al,'&'
 je .emit_amp
 cmp al,'<'
 je .emit_lt
 cmp al,'>'
 je .emit_gt
 cmp al,'"'
 je .emit_quot
 cmp al,10
 je .emit_br
 mov [r14+r10],al
 inc r10
 jmp .write_next
.emit_amp:
 lea rsi,[rel g81_amp]
 mov ecx,g81_amp_len
 jmp .emit
.emit_lt:
 lea rsi,[rel g81_lt]
 mov ecx,g81_lt_len
 jmp .emit
.emit_gt:
 lea rsi,[rel g81_gt]
 mov ecx,g81_gt_len
 jmp .emit
.emit_quot:
 lea rsi,[rel g81_quot]
 mov ecx,g81_quot_len
 jmp .emit
.emit_br:
 lea rsi,[rel g81_br]
 mov ecx,g81_br_len
.emit:
 lea rdi,[r14+r10]
 mov r11d,ecx
 rep movsb
 add r10,r11
.write_next: inc r8
 jmp .write
.close:
 lea rdi,[r14+r10]
 lea rsi,[rel g81_p_close]
 mov ecx,g81_p_close_len
 rep movsb
 add r10,g81_p_close_len
 mov rax,r10
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI text, RSI len, RDX summary. Bounded scalar/table-header TOML profile.
nebo_g081_toml_parse:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 call g081_input_validate
 test eax,eax
 jnz .saved
 xor r14d,r14d
 xor r15d,r15d
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
.scan:
 cmp r8,r13
 jae .final_line
 movzx eax,byte [r12+r8]
 cmp al,13
 je .next
 cmp al,10
 je .line_end
 inc r10d
 cmp r10d,G081_MAX_LINE
 ja .limit_saved
 cmp al,9
 je .syntax_saved
 cmp al,0x20
 jb .syntax_saved
 test r9d,1
 jnz .line_active
 cmp al,' '
 je .next
 or r9d,1
 cmp al,'#'
 jne .section_start
 or r9d,8
 jmp .next
.section_start:
 cmp al,'['
 jne .line_active
 or r9d,4
.line_active:
 test r9d,8
 jnz .next
 cmp al,'='
 jne .toml_key
 test r9d,16
 jz .syntax_saved
 or r9d,2
 jmp .last
.toml_key:
 test r9d,2
 jnz .last
 cmp al,' '
 je .last
 cmp al,'['
 je .last
 cmp al,']'
 je .last
 or r9d,16
.last:
 cmp al,' '
 je .next
 mov r11d,eax
.next: inc r8
 jmp .scan
.line_end:
 call .finish_line
 test eax,eax
 jnz .saved
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
 inc r8
 jmp .scan
.final_line:
 call .finish_line
 test eax,eax
 jnz .saved
 test r14,r14
 jnz .commit
 test r15,r15
 jz .syntax_saved
.commit:
 mov [rbx+G081_SUMMARY_PRIMARY],r14
 mov [rbx+G081_SUMMARY_SECONDARY],r15
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_TOML
 mov qword [rbx+G081_SUMMARY_FLAGS],G081_POLICY_STRICT
 xor eax,eax
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.finish_line:
 test r9d,1
 jz .line_ok
 test r9d,8
 jnz .line_ok
 test r9d,4
 jz .assignment
 cmp r11b,']'
 jne .line_bad
 inc r15d
 cmp r15d,G081_MAX_ITEMS
 ja .line_limit
 jmp .line_ok
.assignment:
 test r9d,2
 jz .line_bad
 inc r14d
 cmp r14d,G081_MAX_ITEMS
 ja .line_limit
.line_ok: xor eax,eax
 ret
.line_bad: mov eax,-FMT_SYNTAX
 ret
.line_limit: mov eax,-FMT_LIMIT
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI key, RSI key len, RDX value, RCX value len, R8 output, R9 capacity.
nebo_g081_toml_write:
 test r8,r8
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov r11,r9
 mov rdi,rbx
 mov rsi,r12
 call g081_input_validate
 test eax,eax
 jnz .saved
 mov rdi,r13
 mov rsi,r14
 call g081_input_validate
 test eax,eax
 jnz .saved
 xor r8d,r8d
.key_check:
 cmp r8,r12
 jae .value_count
 movzx eax,byte [rbx+r8]
 cmp al,'a'
 jb .key_upper
 cmp al,'z'
 jbe .key_next
.key_upper:
 cmp al,'A'
 jb .key_digit
 cmp al,'Z'
 jbe .key_next
.key_digit:
 cmp al,'0'
 jb .key_punct
 cmp al,'9'
 jbe .key_next
.key_punct:
 cmp al,'_'
 je .key_next
 cmp al,'-'
 je .key_next
 jmp .syntax_saved
.key_next: inc r8
 jmp .key_check
.value_count:
 mov r10,r12
 add r10,6
 xor r8d,r8d
.count:
 cmp r8,r14
 jae .capacity
 movzx eax,byte [r13+r8]
 cmp al,10
 je .syntax_saved
 cmp al,13
 je .syntax_saved
 cmp al,'"'
 je .escaped
 cmp al,'\'
 je .escaped
 inc r10
 jmp .count_next
.escaped: add r10,2
.count_next: inc r8
 jmp .count
.capacity:
 cmp r10,r11
 ja .capacity_saved
 mov rdi,r15
 mov rsi,rbx
 mov rcx,r12
 rep movsb
 mov byte [rdi],' '
 mov byte [rdi+1],'='
 mov byte [rdi+2],' '
 mov byte [rdi+3],'"'
 add rdi,4
 xor r8d,r8d
.write:
 cmp r8,r14
 jae .tail
 mov al,[r13+r8]
 cmp al,'"'
 je .escape
 cmp al,'\'
 jne .copy
.escape: mov byte [rdi],'\'
 inc rdi
.copy: mov [rdi],al
 inc rdi
 inc r8
 jmp .write
.tail:
 mov byte [rdi],'"'
 mov byte [rdi+1],10
 mov rax,r10
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI line, RSI len, RDX summary. Requires timestamp, level, scope/message.
nebo_g081_log_parse_line:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 call g081_input_validate
 test eax,eax
 jnz .saved
 cmp r13,G081_MAX_LINE
 ja .limit_saved
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
.scan:
 cmp r8,r13
 jae .done
 movzx eax,byte [r12+r8]
 cmp al,10
 je .syntax_saved
 cmp al,13
 je .syntax_saved
 cmp al,' '
 jne .token
 test r10d,r10d
 jz .next
 inc r9d
 xor r10d,r10d
 jmp .next
.token: mov r10d,1
.next: inc r8
 jmp .scan
.done:
 test r10d,r10d
 jz .syntax_saved
 inc r9d
 cmp r9d,4
 jb .syntax_saved
 cmp r9d,G081_MAX_ITEMS
 ja .limit_saved
 mov qword [rbx+G081_SUMMARY_PRIMARY],1
 mov [rbx+G081_SUMMARY_SECONDARY],r9
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_LOG
 mov qword [rbx+G081_SUMMARY_FLAGS],G081_POLICY_STRICT
 xor eax,eax
.saved:
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI text, RSI len, RDX summary. Parses each non-empty line independently.
nebo_g081_log_stream:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 call g081_input_validate
 test eax,eax
 jnz .saved
 mov qword [rsp],0
 xor r14d,r14d
 xor r15d,r15d
.scan:
 cmp r14,r13
 jae .final
 cmp byte [r12+r14],10
 jne .next
 mov rsi,r14
 sub rsi,r15
 test rsi,rsi
 jz .advance
 lea rdi,[r12+r15]
 lea rdx,[rsp+8]
 call nebo_g081_log_parse_line
 test eax,eax
 jnz .saved
 inc qword [rsp]
 cmp qword [rsp],G081_MAX_ITEMS
 ja .limit_saved
.advance: lea r15,[r14+1]
.next: inc r14
 jmp .scan
.final:
 cmp r15,r13
 jae .commit
 lea rdi,[r12+r15]
 mov rsi,r13
 sub rsi,r15
 lea rdx,[rsp+8]
 call nebo_g081_log_parse_line
 test eax,eax
 jnz .saved
 inc qword [rsp]
.commit:
 cmp qword [rsp],0
 je .syntax_saved
 mov rax,[rsp]
 mov [rbx+G081_SUMMARY_PRIMARY],rax
 mov qword [rbx+G081_SUMMARY_SECONDARY],0
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_LOG
 mov qword [rbx+G081_SUMMARY_FLAGS],G081_POLICY_STRICT
 xor eax,eax
.saved:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI line, RSI len, RDX output, RCX cap.
nebo_g081_log_write:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 lea rdx,[rsp]
 call nebo_g081_log_parse_line
 test eax,eax
 jnz .saved
 lea rax,[r12+1]
 cmp rax,r14
 ja .capacity_saved
 mov rdi,r13
 mov rsi,rbx
 mov rcx,r12
 rep movsb
 mov byte [rdi],10
 lea rax,[r12+1]
.saved:
 add rsp,48
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI text, RSI len, RDX summary. Strict bounded XML subset: one root,
; matched tag names, quoted attributes, and no DTD/entity declarations.
nebo_g081_xml_parse:
 test rdx,rdx
 jz .invalid
 cmp ecx,G081_POLICY_STRICT
 je .policy_ok
 cmp ecx,G081_POLICY_ESCAPE
 jne .invalid
.policy_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,528                   ; 32 (offset,length) frames plus root count
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 call g081_input_validate
 test eax,eax
 jnz .saved
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel g81_doctype]
 mov ecx,g81_doctype_len
 call g081_contains
 test eax,eax
 jnz .conflict_saved
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel g81_entity]
 mov ecx,g81_entity_len
 call g081_contains
 test eax,eax
 jnz .conflict_saved
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel g81_system]
 mov ecx,g81_system_len
 call g081_contains
 test eax,eax
 jnz .conflict_saved
 xor r14d,r14d                ; open depth
 xor r15d,r15d                ; element count
 mov qword [rsp+512],0         ; top-level roots
 xor r8d,r8d
.scan:
 cmp r8,r13
 jae .done
 cmp byte [r12+r8],'<'
 je .tag_start
 test r14,r14
 jnz .next
 movzx eax,byte [r12+r8]
 cmp al,' '
 je .next
 cmp al,9
 je .next
 cmp al,10
 je .next
 cmp al,13
 jne .syntax_saved
 jmp .next
.tag_start:
 lea r9,[r8+1]
 cmp r9,r13
 jae .syntax_saved
 movzx eax,byte [r12+r9]
 cmp al,'!'
 je .conflict_saved
 cmp al,'?'
 je .processing_instruction
 xor r10d,r10d
 cmp al,'/'
 jne .name_start
 mov r10d,1
 inc r9
.name_start:
 mov rdx,r9
.name:
 cmp r9,r13
 jae .syntax_saved
 movzx eax,byte [r12+r9]
 cmp al,'>'
 je .name_done
 cmp al,'/'
 je .name_done
 cmp al,' '
 je .name_done
 cmp al,9
 je .name_done
 cmp al,10
 je .name_done
 cmp al,13
 je .name_done
 cmp al,'<'
 je .syntax_saved
 cmp al,'"'
 je .syntax_saved
 cmp al,39
 je .syntax_saved
 cmp al,0x20
 jb .syntax_saved
 inc r9
 jmp .name
.name_done:
 mov r11,r9
 sub r11,rdx
 test r11,r11
 jz .syntax_saved
 test r10d,r10d
 jnz .closing_tail
 inc r15
 cmp r15,G081_MAX_ITEMS
 ja .limit_saved
.find_end:
 xor ecx,ecx                  ; 0 boundary, 1 name, 2 after-name,
 xor edi,edi                  ; 3 before-quote, 4 quoted, 5 after-value
.attribute_scan:
 cmp r9,r13
 jae .syntax_saved
 movzx eax,byte [r12+r9]
 cmp ecx,1
 je .attribute_name
 cmp ecx,2
 je .attribute_after_name
 cmp ecx,3
 je .attribute_before_quote
 cmp ecx,4
 je .quoted_attribute
 cmp ecx,5
 je .attribute_after_value
 cmp al,'>'
 je .opening_end
 cmp al,'/'
 je .attribute_slash
 cmp al,' '
 je .attribute_advance
 cmp al,9
 je .attribute_advance
 cmp al,10
 je .attribute_advance
 cmp al,13
 je .attribute_advance
 cmp al,'<'
 je .syntax_saved
 cmp al,'='
 je .syntax_saved
 cmp al,'"'
 je .syntax_saved
 cmp al,39
 je .syntax_saved
 mov ecx,1
.attribute_advance:
 inc r9
 jmp .attribute_scan
.attribute_name:
 cmp al,'='
 je .attribute_equal
 cmp al,' '
 je .attribute_name_space
 cmp al,9
 je .attribute_name_space
 cmp al,10
 je .attribute_name_space
 cmp al,13
 je .attribute_name_space
 cmp al,'>'
 je .syntax_saved
 cmp al,'/'
 je .syntax_saved
 cmp al,'<'
 je .syntax_saved
 cmp al,'"'
 je .syntax_saved
 cmp al,39
 je .syntax_saved
 inc r9
 jmp .attribute_scan
.attribute_name_space:
 mov ecx,2
 inc r9
 jmp .attribute_scan
.attribute_after_name:
 cmp al,' '
 je .attribute_advance
 cmp al,9
 je .attribute_advance
 cmp al,10
 je .attribute_advance
 cmp al,13
 je .attribute_advance
 cmp al,'='
 jne .syntax_saved
.attribute_equal:
 mov ecx,3
 inc r9
 jmp .attribute_scan
.attribute_before_quote:
 cmp al,' '
 je .attribute_advance
 cmp al,9
 je .attribute_advance
 cmp al,10
 je .attribute_advance
 cmp al,13
 je .attribute_advance
 cmp al,'"'
 je .open_quote
 cmp al,39
 jne .syntax_saved
.open_quote:
 mov edi,eax
 mov ecx,4
 inc r9
 jmp .attribute_scan
.quoted_attribute:
 cmp al,'<'
 je .syntax_saved
 cmp eax,edi
 je .close_quote
 inc r9
 jmp .attribute_scan
.close_quote:
 mov ecx,5
 inc r9
 jmp .attribute_scan
.attribute_after_value:
 cmp al,' '
 je .attribute_value_space
 cmp al,9
 je .attribute_value_space
 cmp al,10
 je .attribute_value_space
 cmp al,13
 je .attribute_value_space
 cmp al,'>'
 je .opening_end
 cmp al,'/'
 je .attribute_slash
 jmp .syntax_saved
.attribute_value_space:
 xor ecx,ecx
 inc r9
 jmp .attribute_scan
.attribute_slash:
 lea rax,[r9+1]
 cmp rax,r13
 jae .syntax_saved
 cmp byte [r12+rax],'>'
 jne .syntax_saved
 inc r9
.opening_end:
 mov rax,r9
.trim_opening:
 cmp rax,rdx
 jbe .not_self_closing
 dec rax
 movzx ecx,byte [r12+rax]
 cmp cl,' '
 je .trim_opening
 cmp cl,9
 je .trim_opening
 cmp cl,10
 je .trim_opening
 cmp cl,13
 je .trim_opening
 cmp cl,'/'
 je .self_closing
.not_self_closing:
 cmp r14,G081_MAX_DEPTH
 jae .limit_saved
 mov rax,r14
 shl rax,4
 mov [rsp+rax],rdx
 mov [rsp+rax+8],r11
 inc r14
 cmp r14,1
 ja .after_tag
.root_account:
 cmp qword [rsp+512],0
 jne .syntax_saved
 mov qword [rsp+512],1
 jmp .after_tag
.self_closing:
 test r14,r14
 jnz .after_tag
 jmp .root_account
.closing_tail:
 cmp r14,0
 je .syntax_saved
.closing_space:
 cmp r9,r13
 jae .syntax_saved
 movzx eax,byte [r12+r9]
 cmp al,'>'
 je .closing_match
 cmp al,' '
 je .closing_advance
 cmp al,9
 je .closing_advance
 cmp al,10
 je .closing_advance
 cmp al,13
 jne .syntax_saved
.closing_advance:
 inc r9
 jmp .closing_space
.closing_match:
 mov rax,r14
 dec rax
 shl rax,4
 cmp [rsp+rax+8],r11
 jne .syntax_saved
 mov rdi,[rsp+rax]
 xor ecx,ecx
.compare_name:
 cmp rcx,r11
 jae .matched_name
 mov al,[r12+rdi]
 cmp al,[r12+rdx]
 jne .syntax_saved
 inc rdi
 inc rdx
 inc rcx
 jmp .compare_name
.matched_name:
 dec r14
 jmp .after_tag
.processing_instruction:
 inc r9
.pi_scan:
 cmp r9,r13
 jae .syntax_saved
 cmp byte [r12+r9],'>'
 jne .pi_next
 cmp r9,r8
 jbe .syntax_saved
 cmp byte [r12+r9-1],'?'
 je .after_tag
.pi_next:
 inc r9
 jmp .pi_scan
 cmp r9,r8
 jbe .syntax_saved
 cmp byte [r12+r9-1],'/'
 jne .after_tag
 cmp byte [r12+r8+1],'/'
 je .after_tag
 cmp byte [r12+r8+1],'?'
 je .after_tag
 test r14,r14
 jz .syntax_saved
 dec r14
.after_tag:
 mov r8,r9
.next: inc r8
 jmp .scan
.done:
 test r14,r14
 jnz .syntax_saved
 cmp qword [rsp+512],1
 jne .syntax_saved
 test r15,r15
 jz .syntax_saved
 mov [rbx+G081_SUMMARY_PRIMARY],r15
 mov qword [rbx+G081_SUMMARY_SECONDARY],0
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_XML
 mov qword [rbx+G081_SUMMARY_FLAGS],G081_POLICY_STRICT
 xor eax,eax
.saved:
 add rsp,528
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.conflict_saved: mov eax,-FMT_CONFLICT
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI text, RSI len, RDX summary. Atom/RSS roots and entry counts.
nebo_g081_feed_parse:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 sub rsp,48
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 mov rcx,G081_POLICY_STRICT
 lea rdx,[rsp]
 call nebo_g081_xml_parse
 test eax,eax
 jnz .saved
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel g81_feed_atom]
 mov ecx,g81_feed_atom_len
 call g081_contains
 test eax,eax
 jz .rss
 mov r14d,1
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel g81_feed_entry]
 mov ecx,g81_feed_entry_len
 call g081_count_occurrences
 jmp .counted
.rss:
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel g81_feed_rss]
 mov ecx,g81_feed_rss_len
 call g081_contains
 test eax,eax
 jz .syntax_saved
 mov r14d,2
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel g81_feed_item]
 mov ecx,g81_feed_item_len
 call g081_count_occurrences
.counted:
 test eax,eax
 js .saved
 test eax,eax
 jz .syntax_saved
 mov [rbx+G081_SUMMARY_PRIMARY],rax
 mov qword [rbx+G081_SUMMARY_SECONDARY],1
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_FEED
 mov [rbx+G081_SUMMARY_FLAGS],r14
 xor eax,eax
.saved:
 add rsp,48
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; Internal first pass for HTML: strips all tags and complete script blocks.
; RDI text, RSI len, RDX output-or-zero, RCX cap, R8 escape flag.
g081_html_transform:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov ebx,r8d
 call g081_input_validate
 test eax,eax
 jnz .saved
 xor r9d,r9d
 xor r10d,r10d
.scan:
 cmp r9,r13
 jae .done
 cmp byte [r12+r9],'<'
 jne .text
 mov rax,r13
 sub rax,r9
 cmp rax,g81_script_open_len
 jb .tag
 xor r8d,r8d
.script_prefix:
 cmp r8d,g81_script_open_len
 jae .find_script_end
 lea rdi,[r12+r9]
 mov al,[rdi+r8]
 cmp al,'A'
 jb .script_prefix_folded
 cmp al,'Z'
 ja .script_prefix_folded
 or al,0x20
.script_prefix_folded:
 cmp al,[g81_script_open+r8]
 jne .tag
 inc r8d
 jmp .script_prefix
.find_script_end:
 lea r11,[r9+g81_script_open_len]
.script_search:
 mov rax,r13
 sub rax,g81_script_close_len
 cmp r11,rax
 ja .syntax_saved
 xor r8d,r8d
.script_compare:
 cmp r8d,g81_script_close_len
 jae .script_skip
 lea rdi,[r12+r11]
 mov al,[rdi+r8]
 cmp al,'A'
 jb .script_close_folded
 cmp al,'Z'
 ja .script_close_folded
 or al,0x20
.script_close_folded:
 cmp al,[g81_script_close+r8]
 jne .script_next
 inc r8d
 jmp .script_compare
.script_next: inc r11
 jmp .script_search
.script_skip:
 lea r9,[r11+g81_script_close_len]
 jmp .scan
.tag:
 inc r9
.tag_scan:
 cmp r9,r13
 jae .syntax_saved
 cmp byte [r12+r9],'>'
 je .tag_done
 inc r9
 jmp .tag_scan
.tag_done: inc r9
 jmp .scan
.text:
 movzx eax,byte [r12+r9]
 test ebx,ebx
 jz .emit_one
 cmp al,'&'
 je .emit_amp
 cmp al,'<'
 je .emit_lt
 cmp al,'>'
 je .emit_gt
.emit_one:
 test r14,r14
 jz .one_count
 cmp r10,r15
 jae .capacity_saved
 mov [r14+r10],al
.one_count: inc r10
 jmp .text_next
.emit_amp:
 lea rdx,[rel g81_amp]
 mov ecx,g81_amp_len
 jmp .emit_literal
.emit_lt:
 lea rdx,[rel g81_lt]
 mov ecx,g81_lt_len
 jmp .emit_literal
.emit_gt:
 lea rdx,[rel g81_gt]
 mov ecx,g81_gt_len
.emit_literal:
 test r14,r14
 jz .literal_count
 mov rax,r10
 add rax,rcx
 cmp rax,r15
 ja .capacity_saved
 lea rdi,[r14+r10]
 mov rsi,rdx
 mov r11d,ecx
 rep movsb
 mov ecx,r11d
.literal_count: add r10,rcx
.text_next:
 cmp r10,G081_MAX_BYTES
 ja .limit_saved
 inc r9
 jmp .scan
.done: mov rax,r10
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved

; RDI text, RSI len, RDX output, RCX cap, R8 policy.
nebo_g081_html_sanitize:
 test rdx,rdx
 jz .invalid
 cmp r8d,G081_POLICY_STRICT
 je .go
 cmp r8d,G081_POLICY_ESCAPE
 jne .invalid
.go:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov ebx,r8d
 xor edx,edx
 xor ecx,ecx
 mov r8d,1
 call g081_html_transform
 test eax,eax
 js .saved
 cmp rax,r15
 ja .capacity_saved
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 mov r8d,1
 call g081_html_transform
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.capacity_saved:
 mov eax,-FMT_CAPACITY
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI text, RSI len, RDX output, RCX cap.
nebo_g081_html_to_text:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 call g081_html_transform
 test eax,eax
 js .saved
 cmp rax,r15
 ja .capacity_saved
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov rcx,r15
 xor r8d,r8d
 call g081_html_transform
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.capacity_saved:
 mov eax,-FMT_CAPACITY
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI text, RSI len, RDX summary, ECX policy. Scalar mapping YAML subset.
nebo_g081_yaml_parse:
 test rdx,rdx
 jz .invalid
 cmp ecx,G081_POLICY_STRICT
 je .policy_ok
 cmp ecx,G081_POLICY_ESCAPE
 jne .invalid
.policy_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 call g081_input_validate
 test eax,eax
 jnz .saved
 xor r14d,r14d
 xor r15d,r15d
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
.scan:
 cmp r8,r13
 jae .finish
 movzx eax,byte [r12+r8]
 cmp al,9
 je .conflict_saved
 cmp al,'&'
 je .conflict_saved
 cmp al,'*'
 je .conflict_saved
 cmp al,'!'
 je .conflict_saved
 cmp al,10
 je .line_end
 test r9d,1
 jnz .line
 cmp al,' '
 jne .content
 inc r10d
 cmp r10d,G081_MAX_DEPTH*2
 ja .limit_saved
 jmp .next
.content:
 cmp al,':'
 je .syntax_saved
 or r9d,1
 cmp al,'#'
 jne .line
 or r9d,4
.line:
 test r9d,4
 jnz .next
 cmp al,':'
 jne .next
 or r9d,2
.next: inc r8
 jmp .scan
.line_end:
 call .finish_line
 test eax,eax
 jnz .saved
 xor r9d,r9d
 xor r10d,r10d
 inc r8
 jmp .scan
.finish:
 call .finish_line
 test eax,eax
 jnz .saved
 test r14,r14
 jz .syntax_saved
 mov [rbx+G081_SUMMARY_PRIMARY],r14
 mov [rbx+G081_SUMMARY_SECONDARY],r15
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_YAML
 mov qword [rbx+G081_SUMMARY_FLAGS],G081_POLICY_STRICT
 xor eax,eax
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.finish_line:
 test r9d,1
 jz .line_ok
 test r9d,4
 jnz .line_ok
 test r9d,2
 jz .line_bad
 inc r14d
 mov eax,r10d
 shr eax,1
 cmp eax,r15d
 cmova r15d,eax
 cmp r14d,G081_MAX_ITEMS
 ja .line_limit
.line_ok: xor eax,eax
 ret
.line_bad: mov eax,-FMT_SYNTAX
 ret
.line_limit: mov eax,-FMT_LIMIT
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.conflict_saved: mov eax,-FMT_CONFLICT
 jmp .saved
.limit_saved: mov eax,-FMT_LIMIT
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI text, RSI len, RDX summary. Sections and key=value assignments.
nebo_g081_ini_parse:
 test rdx,rdx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdx
 mov r12,rdi
 mov r13,rsi
 call g081_input_validate
 test eax,eax
 jnz .saved
 xor r14d,r14d
 xor r15d,r15d
 xor r8d,r8d
 xor r9d,r9d
 xor r10d,r10d
.scan:
 cmp r8,r13
 jae .finish
 movzx eax,byte [r12+r8]
 cmp al,9
 je .syntax_saved
 cmp al,10
 je .line_end
 test r9d,1
 jnz .line
 cmp al,' '
 je .next
 or r9d,1
 cmp al,';'
 je .comment
 cmp al,'#'
 je .comment
 cmp al,'['
 jne .line
 or r9d,4
 jmp .line
.comment: or r9d,8
.line:
 test r9d,8
 jnz .next
 cmp al,'='
 jne .ini_key
 test r9d,16
 jz .syntax_saved
 or r9d,2
 jmp .last
.ini_key:
 test r9d,2
 jnz .last
 cmp al,' '
 je .last
 cmp al,'['
 je .last
 cmp al,']'
 je .last
 or r9d,16
.last:
 cmp al,' '
 je .next
 mov r10d,eax
.next: inc r8
 jmp .scan
.line_end:
 call .finish_line
 test eax,eax
 jnz .saved
 xor r9d,r9d
 xor r10d,r10d
 inc r8
 jmp .scan
.finish:
 call .finish_line
 test eax,eax
 jnz .saved
 test r14,r14
 jz .syntax_saved
 mov [rbx+G081_SUMMARY_PRIMARY],r14
 mov [rbx+G081_SUMMARY_SECONDARY],r15
 mov [rbx+G081_SUMMARY_BYTES],r13
 mov qword [rbx+G081_SUMMARY_KIND],G081_KIND_INI
 mov qword [rbx+G081_SUMMARY_FLAGS],G081_POLICY_STRICT
 xor eax,eax
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.finish_line:
 test r9d,1
 jz .line_ok
 test r9d,8
 jnz .line_ok
 test r9d,4
 jz .assignment
 cmp r10b,']'
 jne .line_bad
 inc r15d
 jmp .line_limit_check
.assignment:
 test r9d,2
 jz .line_bad
 inc r14d
.line_limit_check:
 cmp r14d,G081_MAX_ITEMS
 ja .line_limit
 cmp r15d,G081_MAX_ITEMS
 ja .line_limit
.line_ok: xor eax,eax
 ret
.line_bad: mov eax,-FMT_SYNTAX
 ret
.line_limit: mov eax,-FMT_LIMIT
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI key, RSI key len, RDX value, RCX value len, R8 output, R9 capacity.
nebo_g081_ini_write:
 test r8,r8
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov r11,r9
 mov rdi,rbx
 mov rsi,r12
 call g081_input_validate
 test eax,eax
 jnz .saved
 mov rdi,r13
 mov rsi,r14
 call g081_input_validate
 test eax,eax
 jnz .saved
 xor r8d,r8d
.key:
 cmp r8,r12
 jae .value
 mov al,[rbx+r8]
 cmp al,'='
 je .syntax_saved
 cmp al,10
 je .syntax_saved
 cmp al,13
 je .syntax_saved
 inc r8
 jmp .key
.value:
 xor r8d,r8d
.value_scan:
 cmp r8,r14
 jae .capacity
 mov al,[r13+r8]
 cmp al,10
 je .syntax_saved
 cmp al,13
 je .syntax_saved
 inc r8
 jmp .value_scan
.capacity:
 mov rax,r12
 add rax,r14
 add rax,2
 cmp rax,r11
 ja .capacity_saved
 mov rdi,r15
 mov rsi,rbx
 mov rcx,r12
 rep movsb
 mov byte [rdi],'='
 inc rdi
 mov rsi,r13
 mov rcx,r14
 rep movsb
 mov byte [rdi],10
 mov rax,r12
 add rax,r14
 add rax,2
.saved:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.syntax_saved: mov eax,-FMT_SYNTAX
 jmp .saved
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; RDI registry kind. Advanced profiles never masquerade as implemented.
nebo_g081_profile_classify:
 cmp edi,G081_EXTERNAL_FIRST
 jb .invalid
 cmp edi,G081_EXTERNAL_LAST
 ja .invalid
 mov eax,FMT_STATE_EXTERNAL
 ret
.invalid: mov eax,-FMT_INVALID
 ret

; RDI dirfd, RSI path, EDX path len, RCX destination, R8 capacity, R9 kind.
; Reads into private scratch, validates by format, then commits caller bytes.
nebo_g081_read_bounded:
 test rcx,rcx
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov ebx,edi
 mov r12,rsi
 mov r13d,edx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 mov edi,ebx
 mov rsi,r12
 mov edx,r13d
 lea rcx,[rel g81_io_scratch]
 mov r8d,G081_MAX_BYTES
 call nebo_g080_file_read
 test eax,eax
 js .saved
 mov r13d,eax
 mov r9,[rsp]
 cmp r9,G081_KIND_MARKDOWN
 je .markdown
 cmp r9,G081_KIND_TOML
 je .toml
 cmp r9,G081_KIND_LOG
 je .log
 cmp r9,G081_KIND_FEED
 je .feed
 cmp r9,G081_KIND_XML
 je .xml
 cmp r9,G081_KIND_HTML
 je .html
 cmp r9,G081_KIND_YAML
 je .yaml
 cmp r9,G081_KIND_INI
 je .ini
 jmp .invalid_saved
.markdown:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_private_summary]
 call nebo_g081_md_parse
 jmp .validated
.toml:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_private_summary]
 call nebo_g081_toml_parse
 jmp .validated
.log:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_private_summary]
 call nebo_g081_log_stream
 jmp .validated
.feed:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_private_summary]
 call nebo_g081_feed_parse
 jmp .validated
.xml:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_private_summary]
 mov ecx,G081_POLICY_STRICT
 call nebo_g081_xml_parse
 jmp .validated
.html:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_io_scratch2]
 mov ecx,G081_MAX_BYTES
 call nebo_g081_html_to_text
 jmp .validated
.yaml:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_private_summary]
 mov ecx,G081_POLICY_STRICT
 call nebo_g081_yaml_parse
 jmp .validated
.ini:
 lea rdi,[rel g81_io_scratch]
 mov rsi,r13
 lea rdx,[rel g81_private_summary]
 call nebo_g081_ini_parse
.validated:
 test eax,eax
 js .saved
 cmp r13,r15
 ja .capacity_saved
 mov rdi,r14
 lea rsi,[rel g81_io_scratch]
 mov rcx,r13
 rep movsb
 mov eax,r13d
.saved:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.capacity_saved: mov eax,-FMT_CAPACITY
 jmp .saved
.invalid_saved: mov eax,-FMT_INVALID
 jmp .saved
.invalid: mov eax,-FMT_INVALID
 ret

; Same explicit dirfd/basename atomic writer as G080.
nebo_g081_write_atomic:
 jmp nebo_g080_file_write_atomic

; EDI subgroup mode 1..10, ESI seed. Every mode executes its real owner.
nebo_g081_source_probe:
 cmp edi,1
 jb .fail
 cmp edi,10
 ja .fail
 cmp esi,G081_SEED_MIN
 jb .fail
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12d,edi
 mov r13d,esi
 lea r14,[rel g81_private_summary]
 cmp r12d,1
 je .s1
 cmp r12d,2
 je .s2
 cmp r12d,3
 je .s3
 cmp r12d,4
 je .s4
 cmp r12d,5
 je .s5
 cmp r12d,6
 je .s6
 cmp r12d,7
 je .s7
 cmp r12d,8
 je .s8
 cmp r12d,9
 je .s9
 jmp .s10
.s1:
 lea rdi,[rel g81_md_sample]
 mov esi,g81_md_sample_len
 mov rdx,r14
 call nebo_g081_md_parse
 test eax,eax
 jnz .fail_saved
 cmp qword [r14+G081_SUMMARY_PRIMARY],1
 jne .fail_saved
 cmp qword [r14+G081_SUMMARY_SECONDARY],1
 jne .fail_saved
 lea rdi,[rel g81_md_sample]
 mov esi,g81_md_sample_len
 lea rdx,[rel g81_io_scratch2]
 mov ecx,G081_MAX_BYTES
 mov r8d,G081_POLICY_ESCAPE
 call nebo_g081_md_to_html
 test eax,eax
 js .fail_saved
 jmp .success
.s2:
 lea rdi,[rel g81_toml_sample]
 mov esi,g81_toml_sample_len
 mov rdx,r14
 call nebo_g081_toml_parse
 test eax,eax
 jnz .fail_saved
 lea rdi,[rel g81_key]
 mov esi,g81_key_len
 lea rdx,[rel g81_value]
 mov ecx,g81_value_len
 lea r8,[rel g81_io_scratch2]
 mov r9d,G081_MAX_BYTES
 call nebo_g081_toml_write
 test eax,eax
 js .fail_saved
 jmp .success
.s3:
 lea rdi,[rel g81_log_sample]
 mov esi,g81_log_sample_len
 mov rdx,r14
 call nebo_g081_log_stream
 test eax,eax
 jnz .fail_saved
 cmp qword [r14+G081_SUMMARY_PRIMARY],2
 jne .fail_saved
 jmp .success
.s4:
 lea rdi,[rel g81_atom_sample]
 mov esi,g81_atom_sample_len
 mov rdx,r14
 call nebo_g081_feed_parse
 test eax,eax
 jnz .fail_saved
 lea rdi,[rel g81_rss_sample]
 mov esi,g81_rss_sample_len
 mov rdx,r14
 call nebo_g081_feed_parse
 test eax,eax
 jnz .fail_saved
 jmp .success
.s5:
 lea rdi,[rel g81_xml_sample]
 mov esi,g81_xml_sample_len
 mov rdx,r14
 mov ecx,G081_POLICY_STRICT
 call nebo_g081_xml_parse
 test eax,eax
 jnz .fail_saved
 jmp .success
.s6:
 lea rdi,[rel g81_html_sample]
 mov esi,g81_html_sample_len
 lea rdx,[rel g81_io_scratch2]
 mov ecx,G081_MAX_BYTES
 mov r8d,G081_POLICY_STRICT
 call nebo_g081_html_sanitize
 test eax,eax
 js .fail_saved
 jmp .success
.s7:
 lea rdi,[rel g81_yaml_sample]
 mov esi,g81_yaml_sample_len
 mov rdx,r14
 mov ecx,G081_POLICY_STRICT
 call nebo_g081_yaml_parse
 test eax,eax
 jnz .fail_saved
 jmp .success
.s8:
 lea rdi,[rel g81_ini_sample]
 mov esi,g81_ini_sample_len
 mov rdx,r14
 call nebo_g081_ini_parse
 test eax,eax
 jnz .fail_saved
 lea rdi,[rel g81_key]
 mov esi,g81_key_len
 lea rdx,[rel g81_value]
 mov ecx,g81_value_len
 lea r8,[rel g81_io_scratch2]
 mov r9d,G081_MAX_BYTES
 call nebo_g081_ini_write
 test eax,eax
 js .fail_saved
 jmp .success
.s9:
 mov ebx,G081_EXTERNAL_FIRST
.profile_loop:
 mov edi,ebx
 call nebo_g081_profile_classify
 cmp eax,FMT_STATE_EXTERNAL
 jne .fail_saved
 inc ebx
 cmp ebx,G081_EXTERNAL_LAST
 jbe .profile_loop
 jmp .success
.s10:
 call nebo_g081_negative_probe
 test eax,eax
 jnz .fail_saved
.success:
 mov eax,r12d
 imul eax,5
 add eax,r13d
 shl eax,4
 and eax,255
 test eax,eax
 jnz .done
 mov eax,r12d
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.fail_saved:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
.fail: mov eax,255
 ret

nebo_g081_negative_probe:
 lea rdi,[rel g81_bad_xml]
 mov esi,g81_bad_xml_len
 lea rdx,[rel g81_private_summary]
 mov ecx,G081_POLICY_STRICT
 call nebo_g081_xml_parse
 cmp eax,-FMT_CONFLICT
 jne .fail
 lea rdi,[rel g81_bad_yaml]
 mov esi,g81_bad_yaml_len
 lea rdx,[rel g81_private_summary]
 mov ecx,G081_POLICY_STRICT
 call nebo_g081_yaml_parse
 cmp eax,-FMT_CONFLICT
 jne .fail
 mov edi,G081_EXTERNAL_FIRST
 call nebo_g081_profile_classify
 cmp eax,FMT_STATE_EXTERNAL
 jne .fail
 xor eax,eax
 ret
.fail: mov eax,-FMT_CONFLICT
 ret

nebo_g081_render_transcript:
 push rbx
 push r12
 lea rbx,[rel g81_s1]
 mov r12d,g81_s1_len
 call .write
 lea rbx,[rel g81_s2]
 mov r12d,g81_s2_len
 call .write
 lea rbx,[rel g81_s3]
 mov r12d,g81_s3_len
 call .write
 lea rbx,[rel g81_s4]
 mov r12d,g81_s4_len
 call .write
 lea rbx,[rel g81_s5]
 mov r12d,g81_s5_len
 call .write
 lea rbx,[rel g81_s6]
 mov r12d,g81_s6_len
 call .write
 lea rbx,[rel g81_s7]
 mov r12d,g81_s7_len
 call .write
 lea rbx,[rel g81_s8]
 mov r12d,g81_s8_len
 call .write
 lea rbx,[rel g81_s9]
 mov r12d,g81_s9_len
 call .write
 lea rbx,[rel g81_s10]
 mov r12d,g81_s10_len
 call .write
 xor eax,eax
 pop r12
 pop rbx
 ret
.write:
 mov eax,1
 mov edi,1
 mov rsi,rbx
 mov rdx,r12
 syscall
 cmp rax,r12
 jne .write_fail
 ret
.write_fail:
 mov eax,-FMT_CONFLICT
 pop rax
 pop r12
 pop rbx
 ret
