; G072 token-owned source vertical for explicit RenderPlan targets and sinks.
%define G72_FAMILY_KEY 0x5246323034473732
%define G72_MAX_PAYLOAD 4096
%define G72_MIN_SEED 1000
%define G72_MAX_SEED 0xffffffff

section .rodata
%macro G72_NAME 2
g72_n_%1: db %2
g72_n_%1_len equ $-g72_n_%1
%endmacro
G72_NAME root,'RenderPlan'
G72_NAME stdout,'stdout'
G72_NAME stderr,'stderr'
G72_NAME target,'target'
G72_NAME file,'file'
G72_NAME overwrite,'overwrite'
G72_NAME buffer,'buffer'
G72_NAME console,'console'
G72_NAME markdown,'markdown'
G72_NAME html,'html'
G72_NAME json,'json'
G72_NAME ansi,'ansi'
G72_NAME plain,'plain'
G72_NAME event,'event'
G72_NAME log,'log'
G72_NAME sink,'sink'
G72_NAME line,'line'
G72_NAME column,'column'
G72_NAME at,'at'
G72_NAME foreground,'foreground'
G72_NAME background,'background'
G72_NAME fg,'fg'
G72_NAME bg,'bg'
G72_NAME bold,'bold'
G72_NAME italic,'italic'
G72_NAME underline,'underline'
G72_NAME close_policy,'closePolicy'
G72_NAME accessibility,'accessibility'
G72_NAME mirror,'mirror'
G72_NAME to_console,'toConsole'
G72_NAME to_panel,'toPanel'
G72_NAME console_style,'consoleStyle'
G72_NAME visual,'visual'
G72_NAME headless_event,'headlessEvent'
G72_NAME card,'card'
G72_NAME encoding,'encoding'
G72_NAME atomic,'atomic'
G72_NAME payload,'payload'
G72_NAME headless,'headless'
G72_NAME jsonl,'jsonl'
G72_NAME trace,'trace'
G72_NAME span,'span'
G72_NAME metric,'metric'
G72_NAME diagnostic_event,'diagnosticEvent'
G72_NAME target_conformance,'targetConformance'
G72_NAME validate,'validate'
G72_NAME deterministic,'deterministic'
G72_NAME failure_atomic,'failureAtomic'
G72_NAME bounded,'bounded'
%undef G72_NAME

section .bss align=16
g72_mode: resq 1
g72_seed: resq 1
g72_seed_seen: resq 1

section .text
%macro G72_REQUIRE 2
 lea rsi,[rel g72_n_%1]
 mov edx,g72_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g72_select_mode:
 G72_REQUIRE target_conformance,.not_s07
 G72_REQUIRE validate,.not_s07
 G72_REQUIRE deterministic,.not_s07
 G72_REQUIRE failure_atomic,.not_s07
 G72_REQUIRE bounded,.not_s07
 mov eax,7
 ret
.not_s07:
 G72_REQUIRE close_policy,.not_s06
 mov eax,6
 ret
.not_s06:
 G72_REQUIRE console,.not_s05
 G72_REQUIRE log,.not_s05
 G72_REQUIRE sink,.not_s05
 G72_REQUIRE mirror,.not_s05
 mov eax,5
 ret
.not_s05:
 G72_REQUIRE event,.not_s04
 G72_REQUIRE payload,.not_s04
 G72_REQUIRE headless,.not_s04
 G72_REQUIRE jsonl,.not_s04
 mov eax,4
 ret
.not_s04:
 G72_REQUIRE file,.not_s03
 G72_REQUIRE overwrite,.not_s03
 G72_REQUIRE encoding,.not_s03
 G72_REQUIRE atomic,.not_s03
 mov eax,3
 ret
.not_s03:
 G72_REQUIRE line,.not_s02
 G72_REQUIRE column,.not_s02
 G72_REQUIRE foreground,.not_s02
 G72_REQUIRE accessibility,.not_s02
 mov eax,2
 ret
.not_s02:
 G72_REQUIRE stdout,.not_s01
 G72_REQUIRE stderr,.not_s01
 G72_REQUIRE target,.not_s01
 G72_REQUIRE plain,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g72_is_program:
 lea rsi,[rel g72_n_root]
 mov edx,g72_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
 call g72_select_mode
 test eax,eax
 setnz al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

g72_known_call:
 push rbx
 mov rbx,rdi
%macro G72_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g72_n_%1]
 mov edx,g72_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G72_KNOWN stdout
 G72_KNOWN stderr
 G72_KNOWN target
 G72_KNOWN file
 G72_KNOWN overwrite
 G72_KNOWN buffer
 G72_KNOWN console
 G72_KNOWN markdown
 G72_KNOWN html
 G72_KNOWN json
 G72_KNOWN ansi
 G72_KNOWN plain
 G72_KNOWN event
 G72_KNOWN log
 G72_KNOWN sink
 G72_KNOWN line
 G72_KNOWN column
 G72_KNOWN at
 G72_KNOWN foreground
 G72_KNOWN background
 G72_KNOWN fg
 G72_KNOWN bg
 G72_KNOWN bold
 G72_KNOWN italic
 G72_KNOWN underline
 G72_KNOWN close_policy
 G72_KNOWN accessibility
 G72_KNOWN mirror
 G72_KNOWN to_console
 G72_KNOWN to_panel
 G72_KNOWN console_style
 G72_KNOWN visual
 G72_KNOWN headless_event
 G72_KNOWN card
 G72_KNOWN encoding
 G72_KNOWN atomic
 G72_KNOWN payload
 G72_KNOWN headless
 G72_KNOWN jsonl
 G72_KNOWN trace
 G72_KNOWN span
 G72_KNOWN metric
 G72_KNOWN diagnostic_event
 G72_KNOWN target_conformance
 G72_KNOWN validate
 G72_KNOWN deterministic
 G72_KNOWN failure_atomic
 G72_KNOWN bounded
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G72_KNOWN

; RDI dot-token index -> EAX boolean for exact bounded arity/kinds.
g72_validate_call:
 push rbx
 push r12
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G72_ARG_MATCH 2
 mov rdi,r12
 lea rsi,[rel g72_n_%1]
 mov edx,g72_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G72_ARG_MATCH line,.integer
 G72_ARG_MATCH column,.integer
 G72_ARG_MATCH at,.two_integer
 G72_ARG_MATCH fg,.three_integer
 G72_ARG_MATCH bg,.three_integer
 G72_ARG_MATCH target,.text
 G72_ARG_MATCH file,.text
 G72_ARG_MATCH overwrite,.text
 G72_ARG_MATCH buffer,.text
 G72_ARG_MATCH sink,.text
 G72_ARG_MATCH foreground,.text
 G72_ARG_MATCH background,.text
 G72_ARG_MATCH close_policy,.text
 G72_ARG_MATCH accessibility,.text
 G72_ARG_MATCH mirror,.text
 G72_ARG_MATCH to_panel,.text
 G72_ARG_MATCH console_style,.text
 G72_ARG_MATCH encoding,.text
 G72_ARG_MATCH event,.text
 G72_ARG_MATCH payload,.text
 G72_ARG_MATCH span,.text
 G72_ARG_MATCH metric,.text
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G72_MAX_PAYLOAD+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],1
 jb .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],4096
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.two_integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],1
 jb .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],4096
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],1
 jb .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],4096
 ja .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.three_integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],255
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+5]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],255
 ja .bad
 lea rdi,[rbx+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .bad
 lea rdi,[rbx+7]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 lea rdi,[rbx+7]
 call ls_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],255
 ja .bad
 lea rdi,[rbx+8]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .bad
.good:
 mov eax,1
 jmp .done
.bad:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret
%undef G72_ARG_MATCH

g72_scan_program:
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
 cmp rdx,G72_MIN_SEED
 jb .next
 mov rax,G72_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g72_seed_seen],0
 jne .unsupported
 mov qword [rel g72_seed_seen],1
 mov [rel g72_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G72_MAX_PAYLOAD+2
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
 call g72_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g72_validate_call
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
 cmp qword [rel g72_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_g072_source_parse:
 mov qword [rel g72_mode],0
 mov qword [rel g72_seed],0
 mov qword [rel g72_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g72_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g72_mode],rax
 call g72_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g72_mode]
 shl rax,32
 mov edi,dword [rel g72_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G72_FAMILY_KEY
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

%undef G72_REQUIRE
