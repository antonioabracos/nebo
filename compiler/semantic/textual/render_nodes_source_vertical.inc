; G067 token-owned public source vertical for target-independent RenderPlan
; styles. Selection precedes G066 because both families intentionally share
; the RenderPlan root and Console closeout atoms.
%define G67_FAMILY_KEY 0x5246323034473637
%define G67_MAX_PAYLOAD 4096
%define G67_MAX_RGB 0xffffff

section .rodata
%macro G67_NAME 2
g67_n_%1: db %2
g67_n_%1_len equ $-g67_n_%1
%endmacro
G67_NAME root,'RenderPlan'
G67_NAME bold,'bold'
G67_NAME italic,'italic'
G67_NAME underline,'underline'
G67_NAME dim,'dim'
G67_NAME inverse,'inverse'
G67_NAME blink,'blink'
G67_NAME red,'red'
G67_NAME green,'green'
G67_NAME blue,'blue'
G67_NAME yellow,'yellow'
G67_NAME cyan,'cyan'
G67_NAME magenta,'magenta'
G67_NAME gray,'gray'
G67_NAME color,'color'
G67_NAME bg,'bg'
G67_NAME no_style,'noStyle'
G67_NAME style,'style'
G67_NAME theme,'theme'
G67_NAME ok,'ok'
G67_NAME success,'success'
G67_NAME warn,'warn'
G67_NAME warning,'warning'
G67_NAME error,'error'
G67_NAME fail,'fail'
G67_NAME info,'info'
G67_NAME debug,'debug'
G67_NAME trace,'trace'
G67_NAME blocked,'blocked'
G67_NAME todo,'todo'
G67_NAME done,'done'
G67_NAME skip,'skip'
G67_NAME pending,'pending'
G67_NAME critical,'critical'
G67_NAME neutral,'neutral'
G67_NAME style_token,'styleToken'
G67_NAME accessibility_label,'accessibilityLabel'
G67_NAME plain_fallback,'plainFallback'
G67_NAME ansi_fallback,'ansiFallback'
G67_NAME style_conformance,'styleConformance'
G67_NAME validate,'validate'
G67_NAME write,'write'
G67_NAME console,'console'
G67_NAME deterministic,'deterministic'
%undef G67_NAME
g67_l_red: db '"red"'
g67_l_red_len equ $-g67_l_red
g67_l_blue: db '"blue"'
g67_l_blue_len equ $-g67_l_blue
g67_l_emphasis: db '"emphasis"'
g67_l_emphasis_len equ $-g67_l_emphasis
g67_l_default: db '"default"'
g67_l_default_len equ $-g67_l_default
g67_l_important: db '"important"'
g67_l_important_len equ $-g67_l_important

section .bss align=16
g67_mode: resq 1
g67_seed: resq 1
g67_seed_seen: resq 1
g67_color_text_seen: resq 1
g67_color_rgb_seen: resq 1

section .text
%macro G67_REQUIRE 2
 lea rsi,[rel g67_n_%1]
 mov edx,g67_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g67_is_program:
 push rbx
 lea rsi,[rel g67_n_root]
 mov edx,g67_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
 lea rsi,[rel g67_n_bold]
 mov edx,g67_n_bold_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g67_n_red]
 mov edx,g67_n_red_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g67_n_ok]
 mov edx,g67_n_ok_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g67_n_style_token]
 mov edx,g67_n_style_token_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel g67_n_style_conformance]
 mov edx,g67_n_style_conformance_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
.no: xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret

g67_known_call:
 push rbx
 mov rbx,rdi
%macro G67_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g67_n_%1]
 mov edx,g67_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G67_KNOWN bold
 G67_KNOWN italic
 G67_KNOWN underline
 G67_KNOWN dim
 G67_KNOWN inverse
 G67_KNOWN blink
 G67_KNOWN red
 G67_KNOWN green
 G67_KNOWN blue
 G67_KNOWN yellow
 G67_KNOWN cyan
 G67_KNOWN magenta
 G67_KNOWN gray
 G67_KNOWN color
 G67_KNOWN bg
 G67_KNOWN no_style
 G67_KNOWN style
 G67_KNOWN theme
 G67_KNOWN ok
 G67_KNOWN success
 G67_KNOWN warn
 G67_KNOWN warning
 G67_KNOWN error
 G67_KNOWN fail
 G67_KNOWN info
 G67_KNOWN debug
 G67_KNOWN trace
 G67_KNOWN blocked
 G67_KNOWN todo
 G67_KNOWN done
 G67_KNOWN skip
 G67_KNOWN pending
 G67_KNOWN critical
 G67_KNOWN neutral
 G67_KNOWN style_token
 G67_KNOWN accessibility_label
 G67_KNOWN plain_fallback
 G67_KNOWN ansi_fallback
 G67_KNOWN style_conformance
 G67_KNOWN validate
 G67_KNOWN write
 G67_KNOWN console
 G67_KNOWN deterministic
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G67_KNOWN

; RDI dot-token index -> EAX boolean. Public methods have exact bounded arity;
; text-valued styles accept only the names materialized by the bounded probe.
g67_validate_call:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 lea r12,[rbx+1]
 mov rdi,r12
 lea rsi,[rel g67_n_color]
 mov edx,g67_n_color_len
 call ls_token_match
 test eax,eax
 jnz .color
 mov rdi,r12
 lea rsi,[rel g67_n_bg]
 mov edx,g67_n_bg_len
 call ls_token_match
 test eax,eax
 jnz .bg
 mov rdi,r12
 lea rsi,[rel g67_n_style]
 mov edx,g67_n_style_len
 call ls_token_match
 test eax,eax
 jnz .emphasis
 mov rdi,r12
 lea rsi,[rel g67_n_style_token]
 mov edx,g67_n_style_token_len
 call ls_token_match
 test eax,eax
 jnz .emphasis
 mov rdi,r12
 lea rsi,[rel g67_n_theme]
 mov edx,g67_n_theme_len
 call ls_token_match
 test eax,eax
 jnz .theme
 mov rdi,r12
 lea rsi,[rel g67_n_accessibility_label]
 mov edx,g67_n_accessibility_label_len
 call ls_token_match
 test eax,eax
 jnz .important
 ; Every remaining public surface is a nullary plan transform.
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.bg:
 lea r13,[rel g67_l_blue]
 mov r14d,g67_l_blue_len
 jmp .text
.emphasis:
 lea r13,[rel g67_l_emphasis]
 mov r14d,g67_l_emphasis_len
 jmp .text
.theme:
 lea r13,[rel g67_l_default]
 mov r14d,g67_l_default_len
 jmp .text
.important:
 lea r13,[rel g67_l_important]
 mov r14d,g67_l_important_len
.text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+3]
 mov rsi,r13
 mov rdx,r14
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.color:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 je .color_text
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],G67_MAX_RGB
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 mov qword [rel g67_color_rgb_seen],1
 jmp .yes
.color_text:
 lea rdi,[rbx+3]
 lea rsi,[rel g67_l_red]
 mov edx,g67_l_red_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 mov qword [rel g67_color_text_seen],1
.yes:
 mov eax,1
 jmp .done
.bad:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g67_select_mode:
 G67_REQUIRE style_conformance,.not_s05
 G67_REQUIRE validate,.not_s05
 G67_REQUIRE write,.not_s05
 G67_REQUIRE console,.not_s05
 G67_REQUIRE deterministic,.not_s05
 mov eax,5
 ret
.not_s05:
 G67_REQUIRE style_token,.not_s04
 G67_REQUIRE accessibility_label,.not_s04
 G67_REQUIRE plain_fallback,.not_s04
 G67_REQUIRE ansi_fallback,.not_s04
 mov eax,4
 ret
.not_s04:
 G67_REQUIRE ok,.not_s03
 G67_REQUIRE success,.not_s03
 G67_REQUIRE warn,.not_s03
 G67_REQUIRE warning,.not_s03
 G67_REQUIRE error,.not_s03
 G67_REQUIRE fail,.not_s03
 G67_REQUIRE info,.not_s03
 G67_REQUIRE debug,.not_s03
 G67_REQUIRE trace,.not_s03
 G67_REQUIRE blocked,.not_s03
 G67_REQUIRE todo,.not_s03
 G67_REQUIRE done,.not_s03
 G67_REQUIRE skip,.not_s03
 G67_REQUIRE pending,.not_s03
 G67_REQUIRE critical,.not_s03
 G67_REQUIRE neutral,.not_s03
 mov eax,3
 ret
.not_s03:
 G67_REQUIRE red,.not_s02
 G67_REQUIRE green,.not_s02
 G67_REQUIRE blue,.not_s02
 G67_REQUIRE yellow,.not_s02
 G67_REQUIRE cyan,.not_s02
 G67_REQUIRE magenta,.not_s02
 G67_REQUIRE gray,.not_s02
 G67_REQUIRE color,.not_s02
 G67_REQUIRE bg,.not_s02
 G67_REQUIRE no_style,.not_s02
 G67_REQUIRE style,.not_s02
 G67_REQUIRE theme,.not_s02
 mov eax,2
 ret
.not_s02:
 G67_REQUIRE bold,.not_s01
 G67_REQUIRE italic,.not_s01
 G67_REQUIRE underline,.not_s01
 G67_REQUIRE dim,.not_s01
 G67_REQUIRE inverse,.not_s01
 G67_REQUIRE blink,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g67_scan_program:
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
 cmp rdx,G67_MAX_RGB
 ja .unsupported
 cmp qword [rel g67_seed_seen],0
 jne .next
 mov qword [rel g67_seed_seen],1
 mov [rel g67_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G67_MAX_PAYLOAD+2
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
 call g67_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g67_validate_call
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
 cmp qword [rel g67_seed_seen],1
 jne .syntax
 cmp qword [rel g67_seed],0
 je .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g067_source_parse:
 mov qword [rel g67_mode],0
 mov qword [rel g67_seed],0
 mov qword [rel g67_seed_seen],0
 mov qword [rel g67_color_text_seen],0
 mov qword [rel g67_color_rgb_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g67_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g67_mode],rax
 call g67_scan_program
 test eax,eax
 jnz .diagnostic
 cmp qword [rel g67_mode],2
 jne .lower
 cmp qword [rel g67_color_text_seen],1
 jne .unsupported
 cmp qword [rel g67_color_rgb_seen],1
 jne .unsupported
.lower:
 mov rax,[rel g67_mode]
 shl rax,32
 mov edi,dword [rel g67_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G67_FAMILY_KEY
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

%undef G67_REQUIRE
