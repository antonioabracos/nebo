; G078 token-owned ScanPlan multiline, editor, explicit-source, headless-form,
; and metadata vertical. Deferred future-owner spellings are deliberately not
; admitted here. Every accepted shape is finite and literal-bounded.
%define G78_FAMILY_KEY 0x5246323034473738
%define G78_MIN_SEED 1900
%define G78_MAX_SEED 0xffffffff
%define G78_MAX_LINES 256
%define G78_MAX_CHOICES 32

section .rodata
%macro G78_NAME 2
g78_n_%1: db %2
g78_n_%1_len equ $-g78_n_%1
%endmacro
G78_NAME root,'ScanPlan'
G78_NAME blocks,'blocks'
G78_NAME editor,'editor'
G78_NAME sources,'sources'
G78_NAME forms,'forms'
G78_NAME meta,'meta78'
G78_NAME closeout,'closeout78'
G78_NAME multiline,'multiline'
G78_NAME until,'until'
G78_NAME max_lines,'maxLines'
G78_NAME indent_aware,'indentAware'
G78_NAME paragraph,'paragraph'
G78_NAME block,'block'
G78_NAME code,'code'
G78_NAME raw_block,'rawBlock'
G78_NAME history,'history'
G78_NAME no_history,'noHistory'
G78_NAME autocomplete,'autocomplete'
G78_NAME edit,'edit'
G78_NAME raw_keys,'rawKeys'
G78_NAME key,'key'
G78_NAME confirm_key,'confirmKey'
G78_NAME clear_submit,'clearOnSubmit'
G78_NAME stdin,'stdin'
G78_NAME file,'file'
G78_NAME env,'env'
G78_NAME args,'args'
G78_NAME pipe,'pipe'
G78_NAME mock,'mock'
G78_NAME source,'source'
G78_NAME replay,'replay'
G78_NAME record,'record'
G78_NAME device,'device'
G78_NAME console,'console'
G78_NAME form,'form'
G78_NAME field,'field'
G78_NAME view,'view'
G78_NAME panel,'panel'
G78_NAME feedback,'feedback'
G78_NAME style,'style'
G78_NAME schema,'schema'
G78_NAME doc,'doc'
G78_NAME quality,'quality'
G78_NAME provenance,'provenance'
G78_NAME event,'event'
G78_NAME stream,'stream'
G78_NAME print,'print'
%undef G78_NAME

section .bss align=16
g78_mode: resq 1
g78_seed: resq 1
g78_seed_seen: resq 1

section .text
%macro G78_REQUIRE 2
 lea rsi,[rel g78_n_%1]
 mov edx,g78_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g78_is_program:
 lea rsi,[rel g78_n_root]
 mov edx,g78_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G78_MARKER 1
 lea rsi,[rel g78_n_%1]
 mov edx,g78_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G78_MARKER blocks
 G78_MARKER editor
 G78_MARKER sources
 G78_MARKER forms
 G78_MARKER meta
 G78_MARKER closeout
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G78_MARKER

g78_known_call:
 push rbx
 mov rbx,rdi
%macro G78_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g78_n_%1]
 mov edx,g78_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G78_KNOWN multiline
 G78_KNOWN until
 G78_KNOWN max_lines
 G78_KNOWN indent_aware
 G78_KNOWN paragraph
 G78_KNOWN block
 G78_KNOWN code
 G78_KNOWN raw_block
 G78_KNOWN history
 G78_KNOWN no_history
 G78_KNOWN autocomplete
 G78_KNOWN edit
 G78_KNOWN raw_keys
 G78_KNOWN key
 G78_KNOWN confirm_key
 G78_KNOWN clear_submit
 G78_KNOWN stdin
 G78_KNOWN file
 G78_KNOWN env
 G78_KNOWN args
 G78_KNOWN pipe
 G78_KNOWN mock
 G78_KNOWN source
 G78_KNOWN replay
 G78_KNOWN record
 G78_KNOWN device
 G78_KNOWN console
 G78_KNOWN form
 G78_KNOWN field
 G78_KNOWN view
 G78_KNOWN panel
 G78_KNOWN feedback
 G78_KNOWN style
 G78_KNOWN schema
 G78_KNOWN doc
 G78_KNOWN quality
 G78_KNOWN provenance
 G78_KNOWN event
 G78_KNOWN stream
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G78_KNOWN

; RDI first array token -> nonempty literal Text array capped at 32.
g78_validate_text_array:
 push rbx
 push r12
 mov rbx,rdi
 xor r12d,r12d
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_LBRACKET
 jne .bad
 inc rbx
.item:
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,2
 jbe .bad
 inc r12d
 cmp r12d,G78_MAX_CHOICES
 ja .bad
 inc rbx
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .close
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 inc rbx
 jmp .item
.close:
 inc rbx
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bad: xor eax,eax
.done: pop r12
 pop rbx
 ret

; RDI dot token -> exact literal arity for every admitted selector.
g78_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G78_ROUTE 2
 mov rdi,r12
 lea rsi,[rel g78_n_%1]
 mov edx,g78_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G78_ROUTE until,.one_text
 G78_ROUTE block,.one_text
 G78_ROUTE code,.one_text
 G78_ROUTE file,.one_text
 G78_ROUTE env,.one_text
 G78_ROUTE source,.one_text
 G78_ROUTE replay,.one_text
 G78_ROUTE record,.one_text
 G78_ROUTE device,.one_text
 G78_ROUTE form,.one_text
 G78_ROUTE view,.one_text
 G78_ROUTE panel,.one_text
 G78_ROUTE style,.one_text
 G78_ROUTE schema,.one_text
 G78_ROUTE doc,.one_text
 G78_ROUTE quality,.one_text
 G78_ROUTE event,.one_text
 G78_ROUTE mock,.one_text
 G78_ROUTE field,.two_text
 G78_ROUTE max_lines,.max_lines
 G78_ROUTE autocomplete,.array
 ; Remaining public selectors are nullary.
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
 lea rdi,[rbx+4]
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
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.max_lines:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,G78_MAX_LINES
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.array:
 lea rdi,[rbx+3]
 call g78_validate_text_array
 jmp .done
.bad: xor eax,eax
.done: pop r12
 pop rbx
 ret
%undef G78_ROUTE

g78_select_mode:
 G78_REQUIRE blocks,.not_s1
 G78_REQUIRE multiline,.not_s1
 G78_REQUIRE until,.not_s1
 G78_REQUIRE max_lines,.not_s1
 G78_REQUIRE indent_aware,.not_s1
 G78_REQUIRE paragraph,.not_s1
 G78_REQUIRE block,.not_s1
 G78_REQUIRE code,.not_s1
 G78_REQUIRE raw_block,.not_s1
 mov eax,1
 ret
.not_s1:
 G78_REQUIRE editor,.not_s2
 G78_REQUIRE history,.not_s2
 G78_REQUIRE no_history,.not_s2
 G78_REQUIRE autocomplete,.not_s2
 G78_REQUIRE edit,.not_s2
 G78_REQUIRE raw_keys,.not_s2
 G78_REQUIRE key,.not_s2
 G78_REQUIRE confirm_key,.not_s2
 G78_REQUIRE clear_submit,.not_s2
 mov eax,2
 ret
.not_s2:
 G78_REQUIRE sources,.not_s3
 G78_REQUIRE stdin,.not_s3
 G78_REQUIRE file,.not_s3
 G78_REQUIRE env,.not_s3
 G78_REQUIRE args,.not_s3
 G78_REQUIRE pipe,.not_s3
 G78_REQUIRE mock,.not_s3
 G78_REQUIRE source,.not_s3
 G78_REQUIRE replay,.not_s3
 G78_REQUIRE record,.not_s3
 G78_REQUIRE device,.not_s3
 mov eax,3
 ret
.not_s3:
 G78_REQUIRE forms,.not_s4
 G78_REQUIRE console,.not_s4
 G78_REQUIRE form,.not_s4
 G78_REQUIRE field,.not_s4
 G78_REQUIRE view,.not_s4
 G78_REQUIRE panel,.not_s4
 G78_REQUIRE feedback,.not_s4
 G78_REQUIRE style,.not_s4
 mov eax,4
 ret
.not_s4:
 G78_REQUIRE meta,.not_s5
 G78_REQUIRE schema,.not_s5
 G78_REQUIRE doc,.not_s5
 G78_REQUIRE quality,.not_s5
 G78_REQUIRE provenance,.not_s5
 G78_REQUIRE event,.not_s5
 G78_REQUIRE stream,.not_s5
 mov eax,5
 ret
.not_s5:
 G78_REQUIRE closeout,.not_s6
 G78_REQUIRE multiline,.not_s6
 G78_REQUIRE autocomplete,.not_s6
 G78_REQUIRE mock,.not_s6
 G78_REQUIRE form,.not_s6
 G78_REQUIRE schema,.not_s6
 G78_REQUIRE provenance,.not_s6
 G78_REQUIRE stream,.not_s6
 mov eax,6
 ret
.not_s6: xor eax,eax
 ret

g78_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .done
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 test rbx,rbx
 jz .seed_candidate
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 je .next
 cmp eax,NEBOC_TOKEN_COMMA
 je .next
.seed_candidate:
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G78_MIN_SEED
 jb .next
 mov rax,G78_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g78_seed_seen],0
 jne .unsupported
 mov qword [rel g78_seed_seen],1
 mov [rel g78_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_RESERVED_LBRACKET
 je .next
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .next
 cmp eax,NEBOC_TOKEN_PLUS
 jb .dot_test
 cmp eax,NEBOC_TOKEN_LATERAL_FLOW
 jbe .unsupported
.dot_test:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .unsupported
 lea rdi,[rbx+1]
 call g78_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g78_validate_call
 test eax,eax
 jz .unsupported
.next: inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g78_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g078_source_parse:
 mov qword [rel g78_mode],0
 mov qword [rel g78_seed],0
 mov qword [rel g78_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g78_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g78_mode],rax
 lea rsi,[rel g78_n_print]
 mov edx,g78_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g78_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g78_mode]
 shl rax,32
 mov edi,dword [rel g78_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G78_FAMILY_KEY
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

%undef G78_REQUIRE
