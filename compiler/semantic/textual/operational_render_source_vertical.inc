; G070 token-owned public source vertical for bounded operational rendering.
%define G70_FAMILY_KEY 0x5246323034473730
%define G70_MAX_PAYLOAD 4096
%define G70_MIN_SEED 800
%define G70_MAX_SEED 0xffffffff
%define G70_MAX_CAPACITY 8
%define G70_MAX_RATE 1000
%define G70_MAX_INTERVAL 60000

section .rodata
%macro G70_NAME 2
g70_n_%1: db %2
g70_n_%1_len equ $-g70_n_%1
%endmacro
G70_NAME root,'RenderPlan'
G70_NAME log,'log'
G70_NAME timestamp,'timestamp'
G70_NAME scope,'scope'
G70_NAME event,'event'
G70_NAME trace_id,'traceId'
G70_NAME level,'level'
G70_NAME span,'span'
G70_NAME context,'context'
G70_NAME tag,'tag'
G70_NAME flush,'flush'
G70_NAME buffered,'buffered'
G70_NAME unbuffered,'unbuffered'
G70_NAME batch,'batch'
G70_NAME rate_limit,'rateLimit'
G70_NAME debounce,'debounce'
G70_NAME throttle,'throttle'
G70_NAME overwrite_line,'overwriteLine'
G70_NAME progress_line,'progressLine'
G70_NAME lazy,'lazy'
G70_NAME eager,'eager'
G70_NAME progress,'progress'
G70_NAME progress_bar,'progressBar'
G70_NAME percent,'percent'
G70_NAME metric,'metric'
G70_NAME badge,'badge'
G70_NAME counter,'counter'
G70_NAME spinner,'spinner'
G70_NAME duration,'duration'
G70_NAME bytes,'bytes'
G70_NAME speed,'speed'
G70_NAME label,'label'
G70_NAME elapsed,'elapsed'
G70_NAME since,'since'
G70_NAME timezone,'timezone'
G70_NAME iso_time,'isoTime'
G70_NAME date,'date'
G70_NAME time,'time'
G70_NAME backpressure,'backpressure'
G70_NAME capacity,'capacity'
G70_NAME reject_newest,'rejectNewest'
G70_NAME advance_clock,'advanceClock'
G70_NAME drain,'drain'
G70_NAME operations_conformance,'operationsConformance'
G70_NAME snapshot,'snapshot'
G70_NAME validate,'validate'
G70_NAME console,'console'
G70_NAME deterministic,'deterministic'
%undef G70_NAME

section .bss align=16
g70_mode: resq 1
g70_seed: resq 1
g70_seed_seen: resq 1

section .text
%macro G70_REQUIRE 2
 lea rsi,[rel g70_n_%1]
 mov edx,g70_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

g70_is_program:
 lea rsi,[rel g70_n_root]
 mov edx,g70_n_root_len
 call ls_contains_atom
 test eax,eax
 jz .no
%macro G70_MARKER 1
 lea rsi,[rel g70_n_%1]
 mov edx,g70_n_%1_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
%endmacro
 G70_MARKER log
 G70_MARKER buffered
 G70_MARKER progress_bar
 G70_MARKER elapsed
 G70_MARKER backpressure
 G70_MARKER operations_conformance
.no: xor eax,eax
 ret
.yes: mov eax,1
 ret
%undef G70_MARKER

g70_known_call:
 push rbx
 mov rbx,rdi
%macro G70_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g70_n_%1]
 mov edx,g70_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G70_KNOWN log
 G70_KNOWN timestamp
 G70_KNOWN scope
 G70_KNOWN event
 G70_KNOWN trace_id
 G70_KNOWN level
 G70_KNOWN span
 G70_KNOWN context
 G70_KNOWN tag
 G70_KNOWN flush
 G70_KNOWN buffered
 G70_KNOWN unbuffered
 G70_KNOWN batch
 G70_KNOWN rate_limit
 G70_KNOWN debounce
 G70_KNOWN throttle
 G70_KNOWN overwrite_line
 G70_KNOWN progress_line
 G70_KNOWN lazy
 G70_KNOWN eager
 G70_KNOWN progress
 G70_KNOWN progress_bar
 G70_KNOWN percent
 G70_KNOWN metric
 G70_KNOWN badge
 G70_KNOWN counter
 G70_KNOWN spinner
 G70_KNOWN duration
 G70_KNOWN bytes
 G70_KNOWN speed
 G70_KNOWN label
 G70_KNOWN elapsed
 G70_KNOWN since
 G70_KNOWN timezone
 G70_KNOWN iso_time
 G70_KNOWN date
 G70_KNOWN time
 G70_KNOWN backpressure
 G70_KNOWN capacity
 G70_KNOWN reject_newest
 G70_KNOWN advance_clock
 G70_KNOWN drain
 G70_KNOWN operations_conformance
 G70_KNOWN snapshot
 G70_KNOWN validate
 G70_KNOWN console
 G70_KNOWN deterministic
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done: pop rbx
 ret
%undef G70_KNOWN

; RDI dot-token index -> EAX boolean for exact bounded arity and values.
g70_validate_call:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 lea r12,[rbx+1]
%macro G70_ARG_MATCH 2
 mov rdi,r12
 lea rsi,[rel g70_n_%1]
 mov edx,g70_n_%1_len
 call ls_token_match
 test eax,eax
 jnz %2
%endmacro
 G70_ARG_MATCH log,.optional_text
 G70_ARG_MATCH duration,.optional_integer
 G70_ARG_MATCH scope,.text
 G70_ARG_MATCH event,.text
 G70_ARG_MATCH trace_id,.text
 G70_ARG_MATCH level,.text
 G70_ARG_MATCH span,.text
 G70_ARG_MATCH context,.text
 G70_ARG_MATCH tag,.text
 G70_ARG_MATCH metric,.text
 G70_ARG_MATCH label,.text
 G70_ARG_MATCH timezone,.text
 G70_ARG_MATCH capacity,.capacity
 G70_ARG_MATCH rate_limit,.rate
 G70_ARG_MATCH debounce,.interval
 G70_ARG_MATCH throttle,.interval
 G70_ARG_MATCH since,.interval
 G70_ARG_MATCH advance_clock,.interval
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 sete al
 movzx eax,al
 jmp .done
.optional_text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
 jmp .bounded_text
.text:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_TEXT
 jne .bad
.bounded_text:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G70_MAX_PAYLOAD+2
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 jmp .bad
.optional_integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 mov r13d,G70_MAX_INTERVAL
 jmp .bounded_integer
.capacity:
 mov r13d,G70_MAX_CAPACITY
 jmp .integer
.rate:
 mov r13d,G70_MAX_RATE
 jmp .integer
.interval:
 mov r13d,G70_MAX_INTERVAL
.integer:
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
.bounded_integer:
 lea rdi,[rbx+3]
 call ls_token_ptr
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rdx,rdx
 jz .bad
 cmp rdx,r13
 ja .bad
 lea rdi,[rbx+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .good
.bad: xor eax,eax
 jmp .done
.good: mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret
%undef G70_ARG_MATCH

g70_select_mode:
 G70_REQUIRE operations_conformance,.not_s06
 G70_REQUIRE snapshot,.not_s06
 G70_REQUIRE validate,.not_s06
 G70_REQUIRE console,.not_s06
 G70_REQUIRE deterministic,.not_s06
 mov eax,6
 ret
.not_s06:
 G70_REQUIRE backpressure,.not_s05
 G70_REQUIRE capacity,.not_s05
 G70_REQUIRE reject_newest,.not_s05
 G70_REQUIRE advance_clock,.not_s05
 G70_REQUIRE drain,.not_s05
 mov eax,5
 ret
.not_s05:
 G70_REQUIRE timestamp,.not_s04
 G70_REQUIRE elapsed,.not_s04
 G70_REQUIRE duration,.not_s04
 G70_REQUIRE since,.not_s04
 G70_REQUIRE timezone,.not_s04
 G70_REQUIRE iso_time,.not_s04
 G70_REQUIRE date,.not_s04
 G70_REQUIRE time,.not_s04
 mov eax,4
 ret
.not_s04:
 G70_REQUIRE progress,.not_s03
 G70_REQUIRE progress_bar,.not_s03
 G70_REQUIRE percent,.not_s03
 G70_REQUIRE metric,.not_s03
 G70_REQUIRE badge,.not_s03
 G70_REQUIRE counter,.not_s03
 G70_REQUIRE spinner,.not_s03
 G70_REQUIRE duration,.not_s03
 G70_REQUIRE bytes,.not_s03
 G70_REQUIRE speed,.not_s03
 G70_REQUIRE label,.not_s03
 mov eax,3
 ret
.not_s03:
 G70_REQUIRE flush,.not_s02
 G70_REQUIRE buffered,.not_s02
 G70_REQUIRE unbuffered,.not_s02
 G70_REQUIRE batch,.not_s02
 G70_REQUIRE rate_limit,.not_s02
 G70_REQUIRE debounce,.not_s02
 G70_REQUIRE throttle,.not_s02
 G70_REQUIRE overwrite_line,.not_s02
 G70_REQUIRE progress_line,.not_s02
 G70_REQUIRE lazy,.not_s02
 G70_REQUIRE eager,.not_s02
 mov eax,2
 ret
.not_s02:
 G70_REQUIRE log,.not_s01
 G70_REQUIRE timestamp,.not_s01
 G70_REQUIRE scope,.not_s01
 G70_REQUIRE event,.not_s01
 G70_REQUIRE trace_id,.not_s01
 G70_REQUIRE level,.not_s01
 G70_REQUIRE span,.not_s01
 G70_REQUIRE context,.not_s01
 G70_REQUIRE tag,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g70_scan_program:
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
.seed_candidate:
 mov rdi,rbx
 call ls_token_ptr
 test rax,rax
 jz .syntax
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,G70_MIN_SEED
 jb .next
 mov rax,G70_MAX_SEED
 cmp rdx,rax
 ja .unsupported
 cmp qword [rel g70_seed_seen],0
 jne .unsupported
 mov qword [rel g70_seed_seen],1
 mov [rel g70_seed],rdx
 jmp .next
.text:
 cmp eax,NEBOC_TOKEN_TEXT
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,G70_MAX_PAYLOAD+2
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
 call g70_known_call
 test eax,eax
 jz .unsupported
 mov rdi,rbx
 call g70_validate_call
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
 cmp qword [rel g70_seed_seen],1
 jne .unsupported
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.unsupported: mov eax,24
.return: pop rbx
 ret

neboc_g070_source_parse:
 mov qword [rel g70_mode],0
 mov qword [rel g70_seed],0
 mov qword [rel g70_seed_seen],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g70_select_mode
 test eax,eax
 jz .unsupported
 mov [rel g70_mode],rax
 call g70_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g70_mode]
 shl rax,32
 mov edi,dword [rel g70_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G70_FAMILY_KEY
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

%undef G70_REQUIRE
