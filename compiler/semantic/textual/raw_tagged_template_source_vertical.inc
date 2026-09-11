; G063 public-source owner for raw, multiline and tagged template literals.
; Every source literal is parsed and lowered at compile time; only a mode and
; source-derived digest cross the generated executable ABI.
%define G63_FAMILY_KEY 0x5246323034473633
%include "compiler/parser/text/advanced_templates.inc"
%include "runtime/textual/tagged_templates.inc"

section .rodata
%macro G63_NAME 2
g63_n_%1: db %2
g63_n_%1_len equ $-g63_n_%1
%endmacro
G63_NAME root,'AdvancedTextLiteralExpr'
G63_NAME raw_single,'rawSingleString'
G63_NAME raw_escape,'rawEscapesDisabled'
G63_NAME raw_interp,'rawInterpolationDisabled'
G63_NAME raw_slash,'rawSlashDisabled'
G63_NAME multiline,'multilineString'
G63_NAME interpolable,'interpolable'
G63_NAME indentation,'explicitIndentation'
G63_NAME newlines,'explicitNewlines'
G63_NAME raw_multiline,'rawMultiline'
G63_NAME dedent,'textDedentPolicy'
G63_NAME newline_policy,'multilineNewlinePolicy'
G63_NAME registry,'templateTagRegistry'
G63_NAME tagged_expr,'taggedTemplateExpr'
G63_NAME handler,'taggedTemplateHandler'
G63_NAME html,'htmlTemplate'
G63_NAME markdown,'markdownTemplate'
G63_NAME json,'jsonTemplate'
G63_NAME sql_external,'sqlExternalReviewRequired'
G63_NAME log,'logTemplate'
G63_NAME console_plan,'consoleTemplate'
G63_NAME security,'templateSecurity'
G63_NAME diagnostics,'diagnostics'
G63_NAME determinism,'determinism'
G63_NAME closeout,'closeout'
G63_NAME console,'console'
%undef G63_NAME

section .bss align=16
g63_mode: resq 1
g63_seed: resq 1
g63_seed_seen: resq 1
g63_literal_seen: resq 1
g63_kind_mask: resq 1
g63_tag_mask: resq 1
g63_digest: resq 1
g63_ast: resb ADVANCED_TEXT_AST_SIZE
g63_plan: resb TAGGED_PLAN_SIZE

section .text
%macro G63_REQUIRE 2
 lea rsi,[rel g63_n_%1]
 mov edx,g63_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g63_is_program:
 lea rsi,[rel g63_n_root]
 mov edx,g63_n_root_len
 jmp ls_contains_atom

g63_known_call:
 push rbx
 mov rbx,rdi
%macro G63_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g63_n_%1]
 mov edx,g63_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G63_KNOWN raw_single
 G63_KNOWN raw_escape
 G63_KNOWN raw_interp
 G63_KNOWN raw_slash
 G63_KNOWN multiline
 G63_KNOWN interpolable
 G63_KNOWN indentation
 G63_KNOWN newlines
 G63_KNOWN raw_multiline
 G63_KNOWN dedent
 G63_KNOWN newline_policy
 G63_KNOWN registry
 G63_KNOWN tagged_expr
 G63_KNOWN handler
 G63_KNOWN html
 G63_KNOWN markdown
 G63_KNOWN json
 G63_KNOWN sql_external
 G63_KNOWN log
 G63_KNOWN console_plan
 G63_KNOWN security
 G63_KNOWN diagnostics
 G63_KNOWN determinism
 G63_KNOWN closeout
 G63_KNOWN console
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done:
 pop rbx
 ret
%undef G63_KNOWN

g63_select_mode:
 G63_REQUIRE security,.not_s08
 G63_REQUIRE diagnostics,.not_s08
 G63_REQUIRE determinism,.not_s08
 G63_REQUIRE closeout,.not_s08
 mov eax,8
 ret
.not_s08:
 G63_REQUIRE log,.not_s07
 G63_REQUIRE console_plan,.not_s07
 mov eax,7
 ret
.not_s07:
 G63_REQUIRE json,.not_s06
 G63_REQUIRE sql_external,.not_s06
 mov eax,6
 ret
.not_s06:
 G63_REQUIRE html,.not_s05
 G63_REQUIRE markdown,.not_s05
 mov eax,5
 ret
.not_s05:
 G63_REQUIRE registry,.not_s04
 G63_REQUIRE tagged_expr,.not_s04
 G63_REQUIRE handler,.not_s04
 mov eax,4
 ret
.not_s04:
 G63_REQUIRE raw_multiline,.not_s03
 G63_REQUIRE dedent,.not_s03
 G63_REQUIRE newline_policy,.not_s03
 mov eax,3
 ret
.not_s03:
 G63_REQUIRE multiline,.not_s02
 G63_REQUIRE interpolable,.not_s02
 G63_REQUIRE indentation,.not_s02
 G63_REQUIRE newlines,.not_s02
 mov eax,2
 ret
.not_s02:
 G63_REQUIRE raw_single,.not_s01
 G63_REQUIRE raw_escape,.not_s01
 G63_REQUIRE raw_interp,.not_s01
 G63_REQUIRE raw_slash,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g63_hash_ast:
 mov eax,dword [rel g63_digest]
 xor eax,dword [rel g63_ast+ADVANCED_TEXT_AST_KIND]
 imul eax,eax,16777619
 xor eax,dword [rel g63_ast+ADVANCED_TEXT_AST_TAG]
 imul eax,eax,16777619
 mov r8,[rel g63_ast+ADVANCED_TEXT_AST_CONTENT]
 mov rcx,[rel g63_ast+ADVANCED_TEXT_AST_LENGTH]
.hash_loop:
 test rcx,rcx
 jz .hash_done
 movzx edx,byte [r8]
 xor eax,edx
 imul eax,eax,16777619
 inc r8
 dec rcx
 jmp .hash_loop
.hash_done:
 mov dword [rel g63_digest],eax
 ret

g63_scan_program:
 push rbx
 push r12
 push r13
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .finish
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .finish
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .text
 mov rdi,rbx
 call ls_token_ptr
 cmp qword [rel g63_seed_seen],0
 jne .next
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rel g63_seed],rax
 mov qword [rel g63_seed_seen],1
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov r12,rax
 mov rax,[r12+NEBOC_TOKEN_FLAGS_OFFSET]
 test rax,NEBOC_TOKEN_FLAG_TEXT_RAW | NEBOC_TOKEN_FLAG_TEXT_MULTILINE
 jz .next
 mov r13,[r12+NEBOC_TOKEN_START_OFFSET]
 test rax,NEBOC_TOKEN_FLAG_TEXT_TAGGED
 jz .span_ready
 test rbx,rbx
 jz .unsupported
 lea rdi,[rbx-1]
 call ls_token_ptr
 mov r13,[rax+NEBOC_TOKEN_START_OFFSET]
.span_ready:
 mov rdi,[rel ls_source]
 add rdi,r13
 mov rsi,[r12+NEBOC_TOKEN_END_OFFSET]
 sub rsi,r13
 lea rdx,[rel g63_ast]
 call neboc_advanced_text_parse
 test eax,eax
 jz .parsed
 jmp .unsupported
.parsed:
 mov qword [rel g63_literal_seen],1
 mov rcx,[rel g63_ast+ADVANCED_TEXT_AST_KIND]
 mov rax,1
 shl rax,cl
 or [rel g63_kind_mask],rax
 mov rcx,[rel g63_ast+ADVANCED_TEXT_AST_TAG]
 test rcx,rcx
 jz .hash
 mov rax,1
 shl rax,cl
 or [rel g63_tag_mask],rax
 lea rdi,[rel g63_ast]
 lea rsi,[rel g63_plan]
 call neboc_tagged_template_lower
 test eax,eax
 jnz .unsupported
.hash:
 call g63_hash_ast
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g63_known_call
 test eax,eax
 jz .unsupported
.next:
 inc rbx
 jmp .scan
.finish:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .unsupported
 cmp qword [rel g63_seed_seen],1
 jne .unsupported
 cmp qword [rel g63_seed],0
 je .unsupported
 cmp qword [rel g63_literal_seen],1
 jne .unsupported
 mov rax,[rel g63_mode]
 cmp eax,1
 jne .need_s02
 test qword [rel g63_kind_mask],1 << ADVANCED_TEXT_RAW_SINGLE
 jz .unsupported
 jmp .ok
.need_s02:
 cmp eax,2
 jne .need_s03
 test qword [rel g63_kind_mask],1 << ADVANCED_TEXT_MULTILINE
 jz .unsupported
 jmp .ok
.need_s03:
 cmp eax,3
 jne .need_tagged
 test qword [rel g63_kind_mask],1 << ADVANCED_TEXT_RAW_MULTILINE
 jz .unsupported
 jmp .ok
.need_tagged:
 test qword [rel g63_kind_mask],1 << ADVANCED_TEXT_TAGGED
 jz .unsupported
 cmp eax,5
 jne .need_s06
 mov rax,(1 << TEMPLATE_TAG_HTML) | (1 << TEMPLATE_TAG_MARKDOWN)
 and rax,[rel g63_tag_mask]
 cmp rax,(1 << TEMPLATE_TAG_HTML) | (1 << TEMPLATE_TAG_MARKDOWN)
 jne .syntax
 jmp .ok
.need_s06:
 cmp eax,6
 jne .need_s07
 test qword [rel g63_tag_mask],1 << TEMPLATE_TAG_JSON
 jz .syntax
 jmp .ok
.need_s07:
 cmp eax,7
 jne .ok
 mov rax,(1 << TEMPLATE_TAG_LOG) | (1 << TEMPLATE_TAG_CONSOLE)
 and rax,[rel g63_tag_mask]
 cmp rax,(1 << TEMPLATE_TAG_LOG) | (1 << TEMPLATE_TAG_CONSOLE)
 jne .syntax
.ok:
 xor eax,eax
 jmp .done
.syntax: mov eax,24
 jmp .done
.unsupported: mov eax,24
.done:
 pop r13
 pop r12
 pop rbx
 ret

neboc_g063_source_parse:
 mov qword [rel g63_mode],0
 mov qword [rel g63_seed],0
 mov qword [rel g63_seed_seen],0
 mov qword [rel g63_literal_seen],0
 mov qword [rel g63_kind_mask],0
 mov qword [rel g63_tag_mask],0
 mov eax,2166136261
 mov [rel g63_digest],rax
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g63_select_mode
 test eax,eax
 jz .unsupported_entry
 mov [rel g63_mode],rax
 call g63_scan_program
 test eax,eax
 jnz .diagnostic
 mov eax,dword [rel g63_digest]
 xor eax,dword [rel g63_seed]
 mov edi,eax
 mov rax,[rel g63_mode]
 shl rax,32
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G63_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,24
 call ls_error
 ret
.unsupported_entry:
 mov edi,24
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G63_REQUIRE
