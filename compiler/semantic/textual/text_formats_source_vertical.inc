; G081 token-owned bounded textual-format contracts. Proposed source APIs are
; accepted only with finite literal plans; external-review profiles expose no
; callable route and remain classification-only.
%define G81_FAMILY_KEY 0x5246323034473831
%define G81_MIN_SEED 2900
%define G81_MAX_SEED 0xffffffff
%define G81_MAX_BYTES 4096

section .rodata
%macro G81_NAME 2
g81_n_%1: db %2
g81_n_%1_len equ $-g81_n_%1
%endmacro
G81_NAME root,'FormatAdvanced'
G81_NAME markdown,'markdown81'
G81_NAME toml,'toml81'
G81_NAME logs,'logs81'
G81_NAME atom,'atom81'
G81_NAME rss,'rss81'
G81_NAME feed,'feed81'
G81_NAME xml,'xml81'
G81_NAME html,'html81'
G81_NAME yaml,'yaml81'
G81_NAME ini,'ini81'
G81_NAME external_profiles,'externalProfiles81'
G81_NAME closeout,'closeout81'
G81_NAME parse,'parse'
G81_NAME read,'read'
G81_NAME extract_headings,'extractHeadings'
G81_NAME extract_links,'extractLinks'
G81_NAME read_frontmatter,'readFrontmatter'
G81_NAME to_html,'toHtml'
G81_NAME markdown_document,'MarkdownDocument'
G81_NAME markdown_heading,'MarkdownHeading'
G81_NAME markdown_link,'MarkdownLink'
G81_NAME html_policy,'HtmlPolicy'
G81_NAME write,'write'
G81_NAME toml_value,'TomlValue'
G81_NAME parse_line,'parseLine'
G81_NAME stream,'stream'
G81_NAME log_record,'LogRecord'
G81_NAME stream_entries,'streamEntries'
G81_NAME to_events,'toEvents'
G81_NAME xml_policy,'XmlPolicy'
G81_NAME sanitize,'sanitize'
G81_NAME to_text,'toText'
G81_NAME yaml_policy,'YamlPolicy'
G81_NAME compose,'compose'
G81_NAME security_audit,'securityAudit'
G81_NAME external_review,'externalReview'
G81_NAME print,'print'
%undef G81_NAME

section .bss align=16
g81_mode: resq 1
g81_seed: resq 1
g81_seed_seen: resq 1

section .text
%macro G81_REQUIRE 2
 lea rsi,[rel g81_n_%1]
 mov edx,g81_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g81_is_program:
 lea rsi,[rel g81_n_root]
 mov edx,g81_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G81_MARKER 1
 lea rsi,[rel g81_n_%1]
 mov edx,g81_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G81_MARKER markdown
 G81_MARKER toml
 G81_MARKER logs
 G81_MARKER atom
 G81_MARKER rss
 G81_MARKER feed
 G81_MARKER xml
 G81_MARKER html
 G81_MARKER yaml
 G81_MARKER ini
 G81_MARKER external_profiles
 G81_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G81_MARKER

g81_known_call:
 push rbx
 mov rbx,rdi
%macro G81_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g81_n_%1]
 mov edx,g81_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G81_KNOWN parse
 G81_KNOWN read
 G81_KNOWN extract_headings
 G81_KNOWN extract_links
 G81_KNOWN read_frontmatter
 G81_KNOWN to_html
 G81_KNOWN markdown_document
 G81_KNOWN markdown_heading
 G81_KNOWN markdown_link
 G81_KNOWN html_policy
 G81_KNOWN write
 G81_KNOWN toml_value
 G81_KNOWN parse_line
 G81_KNOWN stream
 G81_KNOWN log_record
 G81_KNOWN stream_entries
 G81_KNOWN to_events
 G81_KNOWN xml_policy
 G81_KNOWN sanitize
 G81_KNOWN to_text
 G81_KNOWN yaml_policy
 G81_KNOWN compose
 G81_KNOWN security_audit
 G81_KNOWN external_review
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G81_KNOWN

; RDI points at the dot token. Receiver and method must belong to the selected
; subgroup; a globally known method cannot be borrowed by a different format.
g81_call_allowed:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,[rel g81_mode]
%macro G81_RECEIVER 2
 lea rdi,[rbx-1]
 lea rsi,[rel g81_n_%1]
 mov edx,g81_n_%1_len
 call ls_token_match
 test eax,eax
 jz %2
%endmacro
%macro G81_METHOD 1
 lea rdi,[rbx+1]
 lea rsi,[rel g81_n_%1]
 mov edx,g81_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 cmp r12,1
 je .s1
 cmp r12,2
 je .s2
 cmp r12,3
 je .s3
 cmp r12,4
 je .s4
 cmp r12,5
 je .s5
 cmp r12,6
 je .s6
 cmp r12,7
 je .s7
 cmp r12,8
 je .s8
 cmp r12,10
 je .s10
 jmp .no
.s1:
 G81_RECEIVER markdown,.no
 G81_METHOD parse
 G81_METHOD read
 G81_METHOD extract_headings
 G81_METHOD extract_links
 G81_METHOD read_frontmatter
 G81_METHOD to_html
 G81_METHOD markdown_document
 G81_METHOD markdown_heading
 G81_METHOD markdown_link
 G81_METHOD html_policy
 jmp .no
.s2:
 G81_RECEIVER toml,.no
 G81_METHOD parse
 G81_METHOD read
 G81_METHOD write
 G81_METHOD toml_value
 jmp .no
.s3:
 G81_RECEIVER logs,.no
 G81_METHOD parse_line
 G81_METHOD stream
 G81_METHOD write
 G81_METHOD log_record
 jmp .no
.s4:
 lea rdi,[rbx-1]
 lea rsi,[rel g81_n_atom]
 mov edx,g81_n_atom_len
 call ls_token_match
 test eax,eax
 jnz .feed_read_only
 lea rdi,[rbx-1]
 lea rsi,[rel g81_n_rss]
 mov edx,g81_n_rss_len
 call ls_token_match
 test eax,eax
 jnz .feed_read_only
 G81_RECEIVER feed,.no
 G81_METHOD read
 G81_METHOD stream_entries
 G81_METHOD to_events
 jmp .no
.feed_read_only:
 G81_METHOD read
 jmp .no
.s5:
 G81_RECEIVER xml,.no
 G81_METHOD parse
 G81_METHOD read
 G81_METHOD xml_policy
 jmp .no
.s6:
 G81_RECEIVER html,.no
 G81_METHOD parse
 G81_METHOD sanitize
 G81_METHOD to_text
 jmp .no
.s7:
 G81_RECEIVER yaml,.no
 G81_METHOD parse
 G81_METHOD read
 G81_METHOD yaml_policy
 jmp .no
.s8:
 G81_RECEIVER ini,.no
 G81_METHOD parse
 G81_METHOD read
 G81_METHOD write
 jmp .no
.s10:
 G81_RECEIVER closeout,.no
 G81_METHOD compose
 G81_METHOD security_audit
 G81_METHOD external_review
 jmp .no
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G81_METHOD
%undef G81_RECEIVER

; RDI points at a dot token. Overloaded parse/read forms accept either a Text
; literal or Text plus one bounded policy literal.
g81_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G81_ROUTE 2
 mov rdi,r12
 lea rsi,[rel g81_n_%1]
 mov edx,g81_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G81_ROUTE extract_headings,.nullary
 G81_ROUTE extract_links,.nullary
 G81_ROUTE read_frontmatter,.nullary
 G81_ROUTE to_text,.nullary
 G81_ROUTE parse,.text_policy_overload
 G81_ROUTE read,.text_policy_overload
 G81_ROUTE parse_line,.one_text
 G81_ROUTE stream,.one_text
 G81_ROUTE stream_entries,.one_text
 G81_ROUTE to_events,.one_text
 G81_ROUTE write,.two_text
 G81_ROUTE to_html,.text_policy
 G81_ROUTE sanitize,.text_policy
 G81_ROUTE markdown_document,.one_kind
 G81_ROUTE markdown_heading,.one_kind
 G81_ROUTE markdown_link,.one_kind
 G81_ROUTE html_policy,.one_policy
 G81_ROUTE toml_value,.one_kind
 G81_ROUTE log_record,.one_kind
 G81_ROUTE xml_policy,.one_policy
 G81_ROUTE yaml_policy,.one_policy
 G81_ROUTE compose,.compose_count
 G81_ROUTE security_audit,.one_gate
 G81_ROUTE external_review,.external_count
 xor eax,eax
 jmp .done
.nullary:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_text:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 cmp rdx,G81_MAX_BYTES+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.text_policy_overload:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 cmp rdx,G81_MAX_BYTES+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .policy_comma
 cmp qword [rel g81_mode],5
 je .bad
 cmp qword [rel g81_mode],6
 je .bad
 cmp qword [rel g81_mode],7
 je .bad
 jmp .yes
.policy_comma:
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 jmp .policy_tail
.text_policy:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 cmp rdx,G81_MAX_BYTES+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
.policy_tail:
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,1
 jb .bad
 cmp rdx,2
 ja .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.two_text:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 cmp rdx,G81_MAX_BYTES+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 cmp rdx,G81_MAX_BYTES+2
 ja .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_policy:
 mov edx,2
 jmp .bounded_int
.one_kind:
 mov edx,8
.bounded_int:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rcx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rcx,rcx
 jz .bad
 cmp rcx,rdx
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.one_gate:
 mov edx,1
 jmp .exact_int
.external_count:
 mov edx,8
 jmp .exact_int
.compose_count:
 mov edx,10
.exact_int:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],rdx
 jne .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.yes: mov eax,1
 jmp .done
.bad: xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G81_ROUTE

g81_select_mode:
 G81_REQUIRE markdown,.not_s01
 G81_REQUIRE parse,.not_s01
 G81_REQUIRE read,.not_s01
 G81_REQUIRE extract_headings,.not_s01
 G81_REQUIRE extract_links,.not_s01
 G81_REQUIRE read_frontmatter,.not_s01
 G81_REQUIRE to_html,.not_s01
 G81_REQUIRE markdown_document,.not_s01
 G81_REQUIRE markdown_heading,.not_s01
 G81_REQUIRE markdown_link,.not_s01
 G81_REQUIRE html_policy,.not_s01
 mov eax,1
 ret
.not_s01:
 G81_REQUIRE toml,.not_s02
 G81_REQUIRE parse,.not_s02
 G81_REQUIRE read,.not_s02
 G81_REQUIRE write,.not_s02
 G81_REQUIRE toml_value,.not_s02
 mov eax,2
 ret
.not_s02:
 G81_REQUIRE logs,.not_s03
 G81_REQUIRE parse_line,.not_s03
 G81_REQUIRE stream,.not_s03
 G81_REQUIRE write,.not_s03
 G81_REQUIRE log_record,.not_s03
 mov eax,3
 ret
.not_s03:
 G81_REQUIRE atom,.not_s04
 G81_REQUIRE rss,.not_s04
 G81_REQUIRE feed,.not_s04
 G81_REQUIRE read,.not_s04
 G81_REQUIRE stream_entries,.not_s04
 G81_REQUIRE to_events,.not_s04
 mov eax,4
 ret
.not_s04:
 G81_REQUIRE xml,.not_s05
 G81_REQUIRE parse,.not_s05
 G81_REQUIRE read,.not_s05
 G81_REQUIRE xml_policy,.not_s05
 mov eax,5
 ret
.not_s05:
 G81_REQUIRE html,.not_s06
 G81_REQUIRE parse,.not_s06
 G81_REQUIRE sanitize,.not_s06
 G81_REQUIRE to_text,.not_s06
 mov eax,6
 ret
.not_s06:
 G81_REQUIRE yaml,.not_s07
 G81_REQUIRE parse,.not_s07
 G81_REQUIRE read,.not_s07
 G81_REQUIRE yaml_policy,.not_s07
 mov eax,7
 ret
.not_s07:
 G81_REQUIRE ini,.not_s08
 G81_REQUIRE parse,.not_s08
 G81_REQUIRE read,.not_s08
 G81_REQUIRE write,.not_s08
 mov eax,8
 ret
.not_s08:
 G81_REQUIRE external_profiles,.not_s09
 mov eax,9
 ret
.not_s09:
 G81_REQUIRE closeout,.none
 G81_REQUIRE compose,.none
 G81_REQUIRE security_audit,.none
 G81_REQUIRE external_review,.none
 mov eax,10
 ret
.none: xor eax,eax
 ret

g81_scan_program:
 push rbx
 mov rbx,[rel ls_cursor]
.scan:
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .syntax
 cmp eax,NEBOC_TOKEN_RBRACE
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 je .next
 cmp eax,NEBOC_TOKEN_COMMA
 je .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .next
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G81_MIN_SEED
 jb .next
 mov rax,G81_MAX_SEED
 cmp rdx,rax
 ja .next
 cmp qword [rel g81_seed_seen],0
 jne .unsupported
 mov qword [rel g81_seed_seen],1
 mov [rel g81_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 cmp qword [rel g81_mode],9
 je .unsupported
 mov rdi,rbx
 call g81_call_allowed
 test eax,eax
 jz .unsupported
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 lea rdi,[rbx+1]
 call g81_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g81_validate_call
 test eax,eax
 jz .unsupported
.next: inc rbx
 jmp .scan
.done:
 cmp qword [rel g81_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g081_source_parse:
 mov qword [rel g81_mode],0
 mov qword [rel g81_seed],0
 mov qword [rel g81_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g81_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g81_mode],rax
 lea rsi,[rel g81_n_print]
 mov edx,g81_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g81_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g81_mode]
 shl rax,32
 mov edi,dword [rel g81_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G81_FAMILY_KEY
 call ls_success
 ret
.syntax: mov edi,20
 call ls_error
 ret
.unsupported: mov edi,24
 call ls_error
 ret
.diagnostic: mov edi,eax
 call ls_error
 ret

%undef G81_REQUIRE
