; G013 canonical public-source owner.  Complete subgroup surface sets select
; one concurrency family; fixture paths and filenames are never inspected.
%define G13_FAMILY_KEY 0x5246323034473133

section .rodata
%macro G13_NAME 2
g13_n_%1: db %2
g13_n_%1_len equ $-g13_n_%1
%endmacro
G13_NAME thread,'Thread'
G13_NAME task,'Task'
G13_NAME task_group,'TaskGroup'
G13_NAME future,'Future'
G13_NAME cancellation_token,'CancellationToken'
G13_NAME deadline,'Deadline'
G13_NAME channel,'Channel'
G13_NAME mutex,'Mutex'
G13_NAME rwlock,'RwLock'
G13_NAME atomic_int,'AtomicInt'
G13_NAME scheduler,'Scheduler'
G13_NAME concurrency,'concurrency'
G13_NAME spawn,'spawn'
G13_NAME join,'join'
G13_NAME id,'id'
G13_NAME name,'name'
G13_NAME yield,'yield'
G13_NAME available_parallelism,'availableParallelism'
G13_NAME value,'value'
G13_NAME new,'new'
G13_NAME await,'await'
G13_NAME join_all,'joinAll'
G13_NAME cancel,'cancel'
G13_NAME poll,'poll'
G13_NAME map,'map'
G13_NAME timeout,'timeout'
G13_NAME select,'select'
G13_NAME is_cancelled,'isCancelled'
G13_NAME throw_if_cancelled,'throwIfCancelled'
G13_NAME after,'after'
G13_NAME with_deadline,'withDeadline'
G13_NAME bounded,'bounded'
G13_NAME unbuffered,'unbuffered'
G13_NAME send,'send'
G13_NAME try_send,'trySend'
G13_NAME receive,'receive'
G13_NAME try_receive,'tryReceive'
G13_NAME close,'close'
G13_NAME capacity,'capacity'
G13_NAME lock,'lock'
G13_NAME try_lock,'tryLock'
G13_NAME load,'load'
G13_NAME store,'store'
G13_NAME compare_exchange,'compareExchange'
G13_NAME run,'run'
G13_NAME spawn_blocking,'spawnBlocking'
G13_NAME queue_depth,'queueDepth'
G13_NAME state,'state'
G13_NAME trace,'trace'
%undef G13_NAME

section .bss align=16
g13_mode: resq 1
g13_seed: resq 1

section .text
%macro G13_REQUIRE 3
 lea rsi,[rel g13_n_%1]
 mov edx,g13_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %3
%endmacro

g13_known_call:
 push rbx
 mov rbx,rdi
%macro G13_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g13_n_%1]
 mov edx,g13_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G13_KNOWN spawn
 G13_KNOWN join
 G13_KNOWN id
 G13_KNOWN name
 G13_KNOWN yield
 G13_KNOWN available_parallelism
 G13_KNOWN value
 G13_KNOWN new
 G13_KNOWN await
 G13_KNOWN join_all
 G13_KNOWN cancel
 G13_KNOWN poll
 G13_KNOWN map
 G13_KNOWN timeout
 G13_KNOWN select
 G13_KNOWN is_cancelled
 G13_KNOWN throw_if_cancelled
 G13_KNOWN after
 G13_KNOWN with_deadline
 G13_KNOWN bounded
 G13_KNOWN unbuffered
 G13_KNOWN send
 G13_KNOWN try_send
 G13_KNOWN receive
 G13_KNOWN try_receive
 G13_KNOWN close
 G13_KNOWN capacity
 G13_KNOWN lock
 G13_KNOWN try_lock
 G13_KNOWN load
 G13_KNOWN store
 G13_KNOWN compare_exchange
 G13_KNOWN run
 G13_KNOWN spawn_blocking
 G13_KNOWN queue_depth
 G13_KNOWN state
 G13_KNOWN trace
 xor eax,eax
 jmp .done
.yes: mov eax,1
.done:
 pop rbx
 ret
%undef G13_KNOWN

g13_select_mode:
 G13_REQUIRE scheduler,scheduler_len,.not_s07
 G13_REQUIRE concurrency,concurrency_len,.not_s07
 G13_REQUIRE new,new_len,.not_s07
 G13_REQUIRE run,run_len,.not_s07
 G13_REQUIRE spawn_blocking,spawn_blocking_len,.not_s07
 G13_REQUIRE queue_depth,queue_depth_len,.not_s07
 G13_REQUIRE state,state_len,.not_s07
 G13_REQUIRE trace,trace_len,.not_s07
 mov eax,7
 ret
.not_s07:
 G13_REQUIRE mutex,mutex_len,.not_s06
 G13_REQUIRE rwlock,rwlock_len,.not_s06
 G13_REQUIRE atomic_int,atomic_int_len,.not_s06
 G13_REQUIRE new,new_len,.not_s06
 G13_REQUIRE lock,lock_len,.not_s06
 G13_REQUIRE try_lock,try_lock_len,.not_s06
 G13_REQUIRE load,load_len,.not_s06
 G13_REQUIRE store,store_len,.not_s06
 G13_REQUIRE compare_exchange,compare_exchange_len,.not_s06
 mov eax,6
 ret
.not_s06:
 G13_REQUIRE channel,channel_len,.not_s05
 G13_REQUIRE bounded,bounded_len,.not_s05
 G13_REQUIRE unbuffered,unbuffered_len,.not_s05
 G13_REQUIRE send,send_len,.not_s05
 G13_REQUIRE try_send,try_send_len,.not_s05
 G13_REQUIRE receive,receive_len,.not_s05
 G13_REQUIRE try_receive,try_receive_len,.not_s05
 G13_REQUIRE close,close_len,.not_s05
 G13_REQUIRE capacity,capacity_len,.not_s05
 mov eax,5
 ret
.not_s05:
 G13_REQUIRE cancellation_token,cancellation_token_len,.not_s04
 G13_REQUIRE deadline,deadline_len,.not_s04
 G13_REQUIRE new,new_len,.not_s04
 G13_REQUIRE cancel,cancel_len,.not_s04
 G13_REQUIRE is_cancelled,is_cancelled_len,.not_s04
 G13_REQUIRE throw_if_cancelled,throw_if_cancelled_len,.not_s04
 G13_REQUIRE after,after_len,.not_s04
 G13_REQUIRE with_deadline,with_deadline_len,.not_s04
 mov eax,4
 ret
.not_s04:
 G13_REQUIRE future,future_len,.not_s03
 G13_REQUIRE poll,poll_len,.not_s03
 G13_REQUIRE map,map_len,.not_s03
 G13_REQUIRE timeout,timeout_len,.not_s03
 G13_REQUIRE select,select_len,.not_s03
 G13_REQUIRE await,await_len,.not_s03
 mov eax,3
 ret
.not_s03:
 G13_REQUIRE task,task_len,.not_s02
 G13_REQUIRE task_group,task_group_len,.not_s02
 G13_REQUIRE value,value_len,.not_s02
 G13_REQUIRE spawn,spawn_len,.not_s02
 G13_REQUIRE await,await_len,.not_s02
 G13_REQUIRE new,new_len,.not_s02
 G13_REQUIRE join_all,join_all_len,.not_s02
 G13_REQUIRE cancel,cancel_len,.not_s02
 mov eax,2
 ret
.not_s02:
 G13_REQUIRE thread,thread_len,.not_s01
 G13_REQUIRE spawn,spawn_len,.not_s01
 G13_REQUIRE join,join_len,.not_s01
 G13_REQUIRE id,id_len,.not_s01
 G13_REQUIRE name,name_len,.not_s01
 G13_REQUIRE yield,yield_len,.not_s01
 G13_REQUIRE available_parallelism,available_parallelism_len,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g13_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .syntax
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g13_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g13_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .method
 cmp eax,NEBOC_TOKEN_KW_AWAIT
 jne .syntax
.method:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g13_known_call
 test eax,eax
 jz .unsupported
 lea rdi,[rbx+1]
 lea rsi,[rel g13_n_bounded]
 mov edx,g13_n_bounded_len
 call ls_token_match
 test eax,eax
 jz .next
 lea rdi,[rbx+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .type
 lea rdi,[rbx+3]
 call ls_token_ptr
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],64
 ja .limit
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
 cmp qword [rel g13_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax: mov eax,20
 jmp .return
.type: mov eax,21
 jmp .return
.limit: mov eax,23
 jmp .return
.unsupported: mov eax,24
.return:
 pop rbx
 ret

neboc_g013_source_parse:
 mov qword [rel g13_mode],0
 mov qword [rel g13_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g13_select_mode
 test eax,eax
 jz .syntax
 mov [rel g13_mode],rax
 call g13_scan_program
 test eax,eax
 jnz .diagnostic
 mov rdi,[rel g13_mode]
 shl rdi,32
 mov edi,dword [rel g13_seed]
 mov rax,[rel g13_mode]
 shl rax,32
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G13_FAMILY_KEY
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

%undef G13_REQUIRE
