; G066 source owner for bounded base RenderPlan/Console output. Recognition,
; subgroup selection and diagnostics depend only on canonical lexer tokens.
%define G66_FAMILY_KEY 0x5246323034473636
%define G66_MAX_PAYLOAD 4096

section .rodata
%macro G66_NAME 2
g66_n_%1: db %2
g66_n_%1_len equ $-g66_n_%1
%endmacro
G66_NAME root,'RenderPlan'
G66_NAME newline,'newline'
G66_NAME no_newline,'noNewline'
G66_NAME end,'end'
G66_NAME prefix,'prefix'
G66_NAME suffix,'suffix'
G66_NAME repeat,'repeat'
G66_NAME once,'once'
G66_NAME empty_line,'emptyLine'
G66_NAME before,'before'
G66_NAME after,'after'
G66_NAME surround,'surround'
G66_NAME pad,'pad'
G66_NAME pad_left,'padLeft'
G66_NAME pad_right,'padRight'
G66_NAME sep,'sep'
G66_NAME join,'join'
G66_NAME wrap,'wrap'
G66_NAME between,'between'
G66_NAME columns,'columns'
G66_NAME rows,'rows'
G66_NAME inline,'inline'
G66_NAME multi_line,'multiLine'
G66_NAME compact,'compact'
G66_NAME pretty,'pretty'
G66_NAME limit,'limit'
G66_NAME ellipsis,'ellipsis'
G66_NAME compose,'compose'
G66_NAME ordered,'ordered'
G66_NAME exactly_once,'exactlyOnce'
G66_NAME borrowed,'borrowed'
G66_NAME newline_policy,'newlinePolicy'
G66_NAME whitespace_policy,'whitespacePolicy'
G66_NAME width_policy,'widthPolicy'
G66_NAME overflow_atomic,'overflowAtomic'
G66_NAME validate,'validate'
G66_NAME measure,'measure'
G66_NAME write,'write'
G66_NAME console,'console'
G66_NAME deterministic,'deterministic'
%undef G66_NAME

section .bss align=16
g66_mode: resq 1
g66_seed: resq 1
g66_seed_seen: resq 1

section .text
%macro G66_REQUIRE 2
 lea rsi,[rel g66_n_%1]
 mov edx,g66_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g66_is_program:
 lea rsi,[rel g66_n_root]
 mov edx,g66_n_root_len
 jmp ls_contains_atom

g66_known_call:
 push rbx
 mov rbx,rdi
%macro G66_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g66_n_%1]
 mov edx,g66_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G66_KNOWN newline
 G66_KNOWN no_newline
 G66_KNOWN end
 G66_KNOWN prefix
 G66_KNOWN suffix
 G66_KNOWN repeat
 G66_KNOWN once
 G66_KNOWN empty_line
 G66_KNOWN before
 G66_KNOWN after
 G66_KNOWN surround
 G66_KNOWN pad
 G66_KNOWN pad_left
 G66_KNOWN pad_right
 G66_KNOWN sep
 G66_KNOWN join
 G66_KNOWN wrap
 G66_KNOWN between
 G66_KNOWN columns
 G66_KNOWN rows
 G66_KNOWN inline
 G66_KNOWN multi_line
 G66_KNOWN compact
 G66_KNOWN pretty
 G66_KNOWN limit
 G66_KNOWN ellipsis
 G66_KNOWN compose
 G66_KNOWN ordered
 G66_KNOWN exactly_once
 G66_KNOWN borrowed
 G66_KNOWN newline_policy
 G66_KNOWN whitespace_policy
 G66_KNOWN width_policy
 G66_KNOWN overflow_atomic
 G66_KNOWN validate
 G66_KNOWN measure
 G66_KNOWN write
 G66_KNOWN console
 G66_KNOWN deterministic
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done:
 pop rbx
 ret
%undef G66_KNOWN

g66_select_mode:
 G66_REQUIRE validate,.not_s05
 G66_REQUIRE measure,.not_s05
 G66_REQUIRE write,.not_s05
 G66_REQUIRE console,.not_s05
 G66_REQUIRE deterministic,.not_s05
 mov eax,5
 ret
.not_s05:
 G66_REQUIRE newline_policy,.not_s04
 G66_REQUIRE whitespace_policy,.not_s04
 G66_REQUIRE width_policy,.not_s04
 G66_REQUIRE overflow_atomic,.not_s04
 mov eax,4
 ret
.not_s04:
 G66_REQUIRE compose,.not_s03
 G66_REQUIRE ordered,.not_s03
 G66_REQUIRE exactly_once,.not_s03
 G66_REQUIRE borrowed,.not_s03
 mov eax,3
 ret
.not_s03:
 G66_REQUIRE sep,.not_s02
 G66_REQUIRE join,.not_s02
 G66_REQUIRE wrap,.not_s02
 G66_REQUIRE between,.not_s02
 G66_REQUIRE columns,.not_s02
 G66_REQUIRE rows,.not_s02
 G66_REQUIRE inline,.not_s02
 G66_REQUIRE multi_line,.not_s02
 G66_REQUIRE compact,.not_s02
 G66_REQUIRE pretty,.not_s02
 G66_REQUIRE limit,.not_s02
 G66_REQUIRE ellipsis,.not_s02
 mov eax,2
 ret
.not_s02:
 G66_REQUIRE newline,.not_s01
 G66_REQUIRE no_newline,.not_s01
 G66_REQUIRE end,.not_s01
 G66_REQUIRE prefix,.not_s01
 G66_REQUIRE suffix,.not_s01
 G66_REQUIRE repeat,.not_s01
 G66_REQUIRE once,.not_s01
 G66_REQUIRE empty_line,.not_s01
 G66_REQUIRE before,.not_s01
 G66_REQUIRE after,.not_s01
 G66_REQUIRE surround,.not_s01
 G66_REQUIRE pad,.not_s01
 G66_REQUIRE pad_left,.not_s01
 G66_REQUIRE pad_right,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g66_scan_program:
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
 jne .text
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G66_MAX_PAYLOAD
 ja .unsupported
 cmp qword [rel g66_seed_seen],0
 jne .next
 mov qword [rel g66_seed_seen],1
 mov [rel g66_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G66_MAX_PAYLOAD+2
 ja .unsupported
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g66_known_call
 test eax,eax
 jz .unsupported
.next:
 inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g66_seed_seen],1
 jne .syntax
 cmp qword [rel g66_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return:
 pop rbx
 ret

neboc_g066_source_parse:
 mov qword [rel g66_mode],0
 mov qword [rel g66_seed],0
 mov qword [rel g66_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g66_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g66_mode],rax
 call g66_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g66_mode]
 shl rax,32
 mov edi,dword [rel g66_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G66_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.unsupported:
 mov edi,24
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G66_REQUIRE
