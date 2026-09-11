; G060 public-source owner for statically validated percent templates. The
; selector and every diagnostic depend only on canonical lexer tokens.
%define G60_FAMILY_KEY 0x5246323034473630

section .rodata
%macro G60_NAME 2
g60_n_%1: db %2
g60_n_%1_len equ $-g60_n_%1
%endmacro
G60_NAME root,'PercentFormat'
G60_NAME string,'string'
G60_NAME integer,'integer'
G60_NAME float,'float'
G60_NAME boolean,'boolean'
G60_NAME literal_percent,'literalPercent'
G60_NAME value,'value'
G60_NAME type,'type'
G60_NAME quote,'quote'
G60_NAME json,'json'
G60_NAME structural,'structural'
G60_NAME inspect,'inspect'
G60_NAME width,'width'
G60_NAME sign,'sign'
G60_NAME hex,'hex'
G60_NAME octal,'octal'
G60_NAME address_rejected,'addressRejected'
G60_NAME precision,'precision'
G60_NAME scientific,'scientific'
G60_NAME align,'align'
G60_NAME pad,'pad'
G60_NAME named,'named'
G60_NAME positional,'positional'
G60_NAME i18n,'i18n'
G60_NAME strict,'strict'
G60_NAME loose,'loose'
G60_NAME allow_coerce,'allowCoerce'
G60_NAME no_coerce,'noCoerce'
G60_NAME validate_only,'validateOnly'
G60_NAME format_only,'formatOnly'
G60_NAME placeholder_mode,'placeholderMode'
G60_NAME unknown_placeholder,'unknownPlaceholder'
G60_NAME missing_args,'missingArgs'
G60_NAME extra_args,'extraArgs'
G60_NAME diagnostics,'diagnostics'
G60_NAME closeout,'closeout'
G60_NAME compile,'compile'
G60_NAME validate,'validate'
G60_NAME format,'format'
G60_NAME console,'console'
%undef G60_NAME

section .bss align=16
g60_mode: resq 1
g60_seed: resq 1
g60_seed_seen: resq 1

section .text
%macro G60_REQUIRE 2
 lea rsi,[rel g60_n_%1]
 mov edx,g60_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g60_is_program:
 lea rsi,[rel g60_n_root]
 mov edx,g60_n_root_len
 jmp ls_contains_atom

g60_known_call:
 push rbx
 mov rbx,rdi
%macro G60_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g60_n_%1]
 mov edx,g60_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G60_KNOWN string
 G60_KNOWN integer
 G60_KNOWN float
 G60_KNOWN boolean
 G60_KNOWN literal_percent
 G60_KNOWN value
 G60_KNOWN type
 G60_KNOWN quote
 G60_KNOWN json
 G60_KNOWN structural
 G60_KNOWN inspect
 G60_KNOWN width
 G60_KNOWN sign
 G60_KNOWN hex
 G60_KNOWN octal
 G60_KNOWN address_rejected
 G60_KNOWN precision
 G60_KNOWN scientific
 G60_KNOWN align
 G60_KNOWN pad
 G60_KNOWN named
 G60_KNOWN positional
 G60_KNOWN i18n
 G60_KNOWN strict
 G60_KNOWN loose
 G60_KNOWN allow_coerce
 G60_KNOWN no_coerce
 G60_KNOWN validate_only
 G60_KNOWN format_only
 G60_KNOWN placeholder_mode
 G60_KNOWN unknown_placeholder
 G60_KNOWN missing_args
 G60_KNOWN extra_args
 G60_KNOWN diagnostics
 G60_KNOWN closeout
 G60_KNOWN compile
 G60_KNOWN validate
 G60_KNOWN format
 G60_KNOWN console
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done:
 pop rbx
 ret
%undef G60_KNOWN

g60_select_mode:
 G60_REQUIRE diagnostics,.not_s09
 G60_REQUIRE closeout,.not_s09
 mov eax,9
 ret
.not_s09:
 G60_REQUIRE strict,.not_s08
 G60_REQUIRE loose,.not_s08
 G60_REQUIRE allow_coerce,.not_s08
 G60_REQUIRE no_coerce,.not_s08
 G60_REQUIRE validate_only,.not_s08
 G60_REQUIRE format_only,.not_s08
 G60_REQUIRE placeholder_mode,.not_s08
 G60_REQUIRE unknown_placeholder,.not_s08
 G60_REQUIRE missing_args,.not_s08
 G60_REQUIRE extra_args,.not_s08
 mov eax,8
 ret
.not_s08:
 G60_REQUIRE positional,.not_s07
 G60_REQUIRE i18n,.not_s07
 mov eax,7
 ret
.not_s07:
 G60_REQUIRE named,.not_s06
 mov eax,6
 ret
.not_s06:
 G60_REQUIRE align,.not_s05
 G60_REQUIRE pad,.not_s05
 mov eax,5
 ret
.not_s05:
 G60_REQUIRE precision,.not_s04
 G60_REQUIRE scientific,.not_s04
 mov eax,4
 ret
.not_s04:
 G60_REQUIRE width,.not_s03
 G60_REQUIRE sign,.not_s03
 G60_REQUIRE hex,.not_s03
 G60_REQUIRE octal,.not_s03
 G60_REQUIRE address_rejected,.not_s03
 mov eax,3
 ret
.not_s03:
 G60_REQUIRE value,.not_s02
 G60_REQUIRE type,.not_s02
 G60_REQUIRE quote,.not_s02
 G60_REQUIRE json,.not_s02
 G60_REQUIRE structural,.not_s02
 G60_REQUIRE inspect,.not_s02
 mov eax,2
 ret
.not_s02:
 G60_REQUIRE string,.not_s01
 G60_REQUIRE integer,.not_s01
 G60_REQUIRE float,.not_s01
 G60_REQUIRE boolean,.not_s01
 G60_REQUIRE literal_percent,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

; AL -> EAX allowed public placeholder kind.
g60_placeholder_type:
 cmp al,'s'
 je .yes
 cmp al,'d'
 je .yes
 cmp al,'f'
 je .yes
 cmp al,'b'
 je .yes
 cmp al,'v'
 je .yes
 cmp al,'T'
 je .yes
 cmp al,'q'
 je .yes
 cmp al,'j'
 je .yes
 cmp al,'#'
 je .yes
 cmp al,'?'
 je .yes
 cmp al,'x'
 je .yes
 cmp al,'o'
 je .yes
 cmp al,'e'
 je .yes
 xor eax,eax
 ret
.yes: mov eax,1
 ret

; RDI TEXT token index -> EAX zero or semantic diagnostic 24. Every percent
; spelling in a literal is checked here, before lowering or runtime.
g60_validate_template_token:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov r12,[rel ls_source]
 add r12,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r13,[rax+NEBOC_TOKEN_END_OFFSET]
 sub r13,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp r13,2
 jb .bad
 inc r12
 sub r13,2                         ; bytes between quotes
 xor ebx,ebx
.scan:
 cmp rbx,r13
 jae .ok
 mov al,[r12+rbx]
 cmp al,'\'
 jne .percent
 add rbx,2
 jmp .scan
.percent:
 cmp al,'%'
 jne .next
 lea r14,[rbx+1]
 cmp r14,r13
 jae .bad
 cmp byte [r12+r14],'%'
 jne .placeholder
 add rbx,2
 jmp .scan
.placeholder:
 cmp byte [r12+r14],'{'
 je .named
 xor r15d,r15d                       ; numeric width/index
 xor ecx,ecx                         ; digit count
.flags:
 cmp r14,r13
 jae .bad
 mov al,[r12+r14]
 cmp al,'-'
 je .flag_next
 cmp al,'+'
 je .flag_next
 cmp al,'0'
 jne .digits
 lea rax,[r14+1]
 cmp rax,r13
 jae .flag_next
 cmp byte [r12+r14+1],'$'
 je .digits
.flag_next:
 inc r14
 jmp .flags
.digits:
 cmp r14,r13
 jae .bad
 movzx eax,byte [r12+r14]
 sub eax,'0'
 cmp eax,9
 ja .after_digits
 imul r15,r15,10
 add r15,rax
 cmp r15,256
 ja .bad
 inc r14
 inc ecx
 jmp .digits
.after_digits:
 test ecx,ecx
 jz .precision
 cmp r14,r13
 jae .bad
 cmp byte [r12+r14],'$'
 jne .precision
 test r15,r15
 jz .bad
 cmp r15,64
 ja .bad
 inc r14
.precision:
 cmp r14,r13
 jae .bad
 cmp byte [r12+r14],'.'
 jne .type
 inc r14
 xor r15d,r15d
 xor ecx,ecx
.precision_digits:
 cmp r14,r13
 jae .bad
 movzx eax,byte [r12+r14]
 sub eax,'0'
 cmp eax,9
 ja .precision_done
 imul r15,r15,10
 add r15,rax
 cmp r15,6
 ja .bad
 inc r14
 inc ecx
 jmp .precision_digits
.precision_done:
 test ecx,ecx
 jz .bad
.type:
 cmp r14,r13
 jae .bad
 mov al,[r12+r14]
 cmp al,'p'
 je .bad
 call g60_placeholder_type
 test eax,eax
 jz .bad
 lea rbx,[r14+1]
 jmp .scan
.named:
 add r14,1
 mov r15,r14
.name:
 cmp r14,r13
 jae .bad
 mov al,[r12+r14]
 cmp al,':'
 je .name_end
 cmp al,'_'
 je .name_next
 cmp al,'0'
 jb .name_alpha
 cmp al,'9'
 jbe .name_next
.name_alpha:
 cmp al,'A'
 jb .bad
 cmp al,'Z'
 jbe .name_next
 cmp al,'a'
 jb .bad
 cmp al,'z'
 ja .bad
.name_next:
 inc r14
 jmp .name
.name_end:
 cmp r14,r15
 je .bad
 inc r14
 cmp r14,r13
 jae .bad
 mov al,[r12+r14]
 cmp al,'p'
 je .bad
 call g60_placeholder_type
 test eax,eax
 jz .bad
 inc r14
 cmp r14,r13
 jae .bad
 cmp byte [r12+r14],'}'
 jne .bad
 lea rbx,[r14+1]
 jmp .scan
.next:
 inc rbx
 jmp .scan
.ok: xor eax,eax
 jmp .done
.bad: mov eax,24
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g60_scan_program:
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
 cmp qword [rel g60_seed_seen],0
 jne .next
 mov qword [rel g60_seed_seen],1
 mov [rel g60_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call g60_validate_template_token
 test eax,eax
 jnz .return
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
 call g60_known_call
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
 cmp qword [rel g60_seed_seen],1
 jne .syntax
 cmp qword [rel g60_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return:
 pop rbx
 ret

neboc_g060_source_parse:
 mov qword [rel g60_mode],0
 mov qword [rel g60_seed],0
 mov qword [rel g60_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g60_select_mode
 test eax,eax
 jz .syntax
 mov [rel g60_mode],rax
 call g60_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g60_mode]
 shl rax,32
 mov edi,dword [rel g60_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G60_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G60_REQUIRE
