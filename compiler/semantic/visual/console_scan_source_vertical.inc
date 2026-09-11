; G105 token-owned ScanPlan Console profile. G075-G078 remain the owners of
; typed parsing, validation, retry, privacy, multiline, and form semantics;
; this vertical validates their bounded composition with `.scan(.console())`.
%define G105_FAMILY_KEY 0x4731303553524331
%define G105_MIN_SEED 2500
%define G105_MAX_SEED 0xffffffff
%define G105_MAX_LINES 256
%define G105_MAX_CHOICES 32
%define G105_MAX_STRENGTH 5

section .rodata
%macro G105_NAME 2
g105_n_%1: db %2
g105_n_%1_len equ $-g105_n_%1
%endmacro
G105_NAME root,'ScanPlan'
G105_NAME scan,'scan'
G105_NAME console,'console'
G105_NAME form,'form'
G105_NAME field,'field'
G105_NAME view,'view'
G105_NAME panel,'panel'
G105_NAME feedback,'feedback'
G105_NAME style,'style'
G105_NAME multiline,'multiline'
G105_NAME until,'until'
G105_NAME max_lines,'maxLines'
G105_NAME paragraph,'paragraph'
G105_NAME block,'block'
G105_NAME markdown,'markdown'
G105_NAME code,'code'
G105_NAME json_block,'jsonBlock'
G105_NAME raw_block,'rawBlock'
G105_NAME choice,'choice'
G105_NAME one_of,'oneOf'
G105_NAME menu,'menu'
G105_NAME select,'select'
G105_NAME multi_select,'multiSelect'
G105_NAME index_choice,'indexChoice'
G105_NAME yes_no,'yesNo'
G105_NAME confirm,'confirm'
G105_NAME enum,'enum'
G105_NAME autocomplete,'autocomplete'
G105_NAME secret,'secret'
G105_NAME password,'password'
G105_NAME mask,'mask'
G105_NAME redact,'redact'
G105_NAME no_history,'noHistory'
G105_NAME no_echo,'noEcho'
G105_NAME confirm_secret,'confirmSecret'
G105_NAME sensitive,'sensitive'
G105_NAME min_strength,'minStrength'
G105_NAME forget_after_use,'forgetAfterUse'
G105_NAME untrusted,'untrusted'
G105_NAME mock,'mock'
G105_NAME replay,'replay'
G105_NAME print,'print'
%undef G105_NAME

section .bss align=16
g105_mode: resq 1
g105_seed: resq 1
g105_seed_seen: resq 1

section .text
%macro G105_REQUIRE 2
 lea rsi,[rel g105_n_%1]
 mov edx,g105_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g105_is_program:
 G105_REQUIRE root,.no
 G105_REQUIRE scan,.no
 G105_REQUIRE console,.no
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

g105_known_call:
 push rbx
 mov rbx,rdi
%macro G105_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g105_n_%1]
 mov edx,g105_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G105_KNOWN scan
 G105_KNOWN console
 G105_KNOWN form
 G105_KNOWN field
 G105_KNOWN view
 G105_KNOWN panel
 G105_KNOWN feedback
 G105_KNOWN style
 G105_KNOWN multiline
 G105_KNOWN until
 G105_KNOWN max_lines
 G105_KNOWN paragraph
 G105_KNOWN block
 G105_KNOWN markdown
 G105_KNOWN code
 G105_KNOWN json_block
 G105_KNOWN raw_block
 G105_KNOWN choice
 G105_KNOWN one_of
 G105_KNOWN menu
 G105_KNOWN select
 G105_KNOWN multi_select
 G105_KNOWN index_choice
 G105_KNOWN yes_no
 G105_KNOWN confirm
 G105_KNOWN enum
 G105_KNOWN autocomplete
 G105_KNOWN secret
 G105_KNOWN password
 G105_KNOWN mask
 G105_KNOWN redact
 G105_KNOWN no_history
 G105_KNOWN no_echo
 G105_KNOWN confirm_secret
 G105_KNOWN sensitive
 G105_KNOWN min_strength
 G105_KNOWN forget_after_use
 G105_KNOWN untrusted
 G105_KNOWN mock
 G105_KNOWN replay
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G105_KNOWN

; RDI first array token -> nonempty literal Text array capped at 32.
g105_validate_text_array:
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
 cmp r12d,G105_MAX_CHOICES
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
.bad:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; RDI dot token -> exact literal arity for every admitted selector.
g105_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G105_ROUTE 2
 mov rdi,r12
 lea rsi,[rel g105_n_%1]
 mov edx,g105_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G105_ROUTE scan,.scan_console
 G105_ROUTE form,.one_text
 G105_ROUTE view,.one_text
 G105_ROUTE panel,.one_text
 G105_ROUTE feedback,.one_text
 G105_ROUTE style,.one_text
 G105_ROUTE until,.one_text
 G105_ROUTE block,.one_text
 G105_ROUTE code,.one_text
 G105_ROUTE mask,.one_text
 G105_ROUTE mock,.one_text
 G105_ROUTE replay,.one_text
 G105_ROUTE field,.two_text
 G105_ROUTE max_lines,.max_lines
 G105_ROUTE min_strength,.strength
 G105_ROUTE choice,.array
 G105_ROUTE one_of,.array
 G105_ROUTE menu,.array
 G105_ROUTE select,.array
 G105_ROUTE multi_select,.array
 G105_ROUTE index_choice,.array
 G105_ROUTE enum,.array
 G105_ROUTE autocomplete,.array
 ; Remaining methods are nullary.
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.scan_console:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .bad
 lea rdi,[rbx+4]
 lea rsi,[rel g105_n_console]
 mov edx,g105_n_console_len
 call ls_token_match
 test eax,eax
 jz .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
 lea rdi,[rbx+7]
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
 cmp rdx,G105_MAX_LINES
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.strength:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,G105_MAX_STRENGTH
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.array:
 lea rdi,[rbx+3]
 call g105_validate_text_array
 jmp .done
.bad:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G105_ROUTE

g105_validate_profile:
 mov rax,[rel g105_mode]
 cmp eax,1
 je .s1
 cmp eax,2
 je .s2
 cmp eax,3
 je .s3
 cmp eax,4
 je .s4
 cmp eax,5
 je .s5
 cmp eax,6
 je .s6
 cmp eax,7
 je .s7
 cmp eax,8
 je .s8
 cmp eax,9
 je .s9
 cmp eax,10
 je .s10
 jmp .bad
.s1:
 G105_REQUIRE scan,.bad
 G105_REQUIRE console,.bad
 jmp .ok
.s2:
 G105_REQUIRE form,.bad
 G105_REQUIRE field,.bad
 G105_REQUIRE view,.bad
 G105_REQUIRE panel,.bad
 jmp .ok
.s3:
 G105_REQUIRE feedback,.bad
 G105_REQUIRE style,.bad
 jmp .ok
.s4:
 G105_REQUIRE multiline,.bad
 G105_REQUIRE until,.bad
 G105_REQUIRE max_lines,.bad
 G105_REQUIRE paragraph,.bad
 G105_REQUIRE block,.bad
 G105_REQUIRE markdown,.bad
 G105_REQUIRE code,.bad
 G105_REQUIRE json_block,.bad
 G105_REQUIRE raw_block,.bad
 jmp .ok
.s5:
 G105_REQUIRE choice,.bad
 G105_REQUIRE one_of,.bad
 G105_REQUIRE menu,.bad
 G105_REQUIRE select,.bad
 G105_REQUIRE multi_select,.bad
 G105_REQUIRE index_choice,.bad
 G105_REQUIRE yes_no,.bad
 G105_REQUIRE confirm,.bad
 G105_REQUIRE enum,.bad
 G105_REQUIRE autocomplete,.bad
 jmp .ok
.s6:
 G105_REQUIRE secret,.bad
 G105_REQUIRE password,.bad
 G105_REQUIRE mask,.bad
 G105_REQUIRE redact,.bad
 G105_REQUIRE no_history,.bad
 G105_REQUIRE no_echo,.bad
 G105_REQUIRE confirm_secret,.bad
 G105_REQUIRE sensitive,.bad
 G105_REQUIRE min_strength,.bad
 G105_REQUIRE forget_after_use,.bad
 G105_REQUIRE untrusted,.bad
 jmp .ok
.s7:
 G105_REQUIRE mock,.bad
 G105_REQUIRE form,.bad
 jmp .ok
.s8:
 G105_REQUIRE choice,.bad
 G105_REQUIRE mock,.bad
 jmp .ok
.s9:
 G105_REQUIRE mock,.bad
 G105_REQUIRE replay,.bad
 jmp .ok
.s10:
 G105_REQUIRE form,.bad
 G105_REQUIRE feedback,.bad
 G105_REQUIRE multiline,.bad
 G105_REQUIRE choice,.bad
 G105_REQUIRE secret,.bad
 G105_REQUIRE mock,.bad
 G105_REQUIRE replay,.bad
.ok:
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

g105_scan_program:
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
 cmp rdx,G105_MIN_SEED
 jb .next
 mov rax,G105_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g105_seed_seen],0
 jne .unsupported
 mov qword [rel g105_seed_seen],1
 mov [rel g105_seed],rdx
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
 call g105_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g105_validate_call
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
 cmp qword [rel g105_seed_seen],1
 jne .unsupported
 mov rax,[rel g105_seed]
 xor edx,edx
 mov ecx,100
 div rcx
 cmp edx,1
 jb .range
 cmp edx,10
 ja .range
 mov [rel g105_mode],rdx
 call g105_validate_profile
 test eax,eax
 jz .unsupported
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
 jmp .return
.range:
 mov eax,22
.return:
 pop rbx
 ret

neboc_g105_source_parse:
 mov qword [rel g105_mode],0
 mov qword [rel g105_seed],0
 mov qword [rel g105_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 lea rsi,[rel g105_n_print]
 mov edx,g105_n_print_len
 call ls_contains_atom
 test eax,eax
 jnz .unsupported
 call g105_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g105_mode]
 shl rax,32
 mov edi,dword [rel g105_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G105_FAMILY_KEY
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

%undef G105_REQUIRE
