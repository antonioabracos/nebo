; G140 bounded source owner for graph, workflow and statechart arrows.  Every
; operand is parsed exactly once, all endpoints are typed by explicit port and
; schema identifiers, and construction remains allocation- and I/O-free.

%define G140_FAMILY_KEY 0x5246323047313430
%define G140_DIRECTED 0
%define G140_BIDIRECTIONAL 1
%define G140_ASYNC 2
%define G140_TRANSITION 3

section .rodata
g140_n_directedEdgeTo: db 'directedEdgeTo'
g140_n_directedEdgeTo_len equ $-g140_n_directedEdgeTo
g140_n_bidirectionalEdge: db 'bidirectionalEdge'
g140_n_bidirectionalEdge_len equ $-g140_n_bidirectionalEdge
g140_n_asyncEdgeTo: db 'asyncEdgeTo'
g140_n_asyncEdgeTo_len equ $-g140_n_asyncEdgeTo
g140_n_transitionTo: db 'transitionTo'
g140_n_transitionTo_len equ $-g140_n_transitionTo
g140_n_source: db 'source'
g140_n_source_len equ $-g140_n_source
g140_n_destination: db 'destination'
g140_n_destination_len equ $-g140_n_destination
g140_n_sourcePort: db 'sourcePort'
g140_n_sourcePort_len equ $-g140_n_sourcePort
g140_n_destinationPort: db 'destinationPort'
g140_n_destinationPort_len equ $-g140_n_destinationPort
g140_n_schema: db 'schema'
g140_n_schema_len equ $-g140_n_schema
g140_n_capacity: db 'capacity'
g140_n_capacity_len equ $-g140_n_capacity
g140_n_policy: db 'policy'
g140_n_policy_len equ $-g140_n_policy
g140_n_guard: db 'guard'
g140_n_guard_len equ $-g140_n_guard
g140_n_effect: db 'effect'
g140_n_effect_len equ $-g140_n_effect
g140_n_capability: db 'capability'
g140_n_capability_len equ $-g140_n_capability
g140_n_kind: db 'kind'
g140_n_kind_len equ $-g140_n_kind
g140_n_identity: db 'identity'
g140_n_identity_len equ $-g140_n_identity
g140_n_provenance: db 'provenance'
g140_n_provenance_len equ $-g140_n_provenance
g140_n_replay: db 'replay'
g140_n_replay_len equ $-g140_n_replay

section .bss align=16
g140_scratch_start:
g140_kind: resq 1
g140_source: resq 1
g140_destination: resq 1
g140_source_port: resq 1
g140_destination_port: resq 1
g140_source_schema: resq 1
g140_destination_schema: resq 1
g140_capacity: resq 1
g140_policy: resq 1
g140_guard: resq 1
g140_effect: resq 1
g140_capability: resq 1
g140_identity: resq 1
g140_provenance: resq 1
g140_replay: resq 1
g140_scratch_end:

section .text

g140_api_at:
 push rbx
 mov rbx,rdi
%macro G140_API_MATCH 1
 mov rdi,rbx
 lea rsi,[rel g140_n_%1]
 mov edx,g140_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G140_API_MATCH directedEdgeTo
 G140_API_MATCH bidirectionalEdge
 G140_API_MATCH asyncEdgeTo
 G140_API_MATCH transitionTo
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G140_API_MATCH

g140_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_GRAPH_DIRECTED
 jb .identifier
 cmp eax,NEBOC_TOKEN_STATE_TRANSITION
 jbe .yes
.identifier:
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 call g140_api_at
 test eax,eax
 jnz .yes
.next:
 inc rbx
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop rbx
 ret

g140_expect:
 sub rsp,8
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 ret

g140_expect_comma:
 mov edi,NEBOC_TOKEN_COMMA
 jmp g140_expect

g140_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call g140_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call g140_expect
.done:
 add rsp,8
 ret

g140_parse_positive:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 jle .domain
 cmp rdx,1000000
 ja .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g140_parse_nonnegative:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .domain
 cmp rdx,1000000
 ja .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g140_parse_bool:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 cmp rdx,1
 ja .domain
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret
.syntax:
 mov rax,-1
 ret

g140_next_positive:
 call g140_expect_comma
 test eax,eax
 jnz .done
 call g140_parse_positive
.done:
 ret

g140_next_nonnegative:
 call g140_expect_comma
 test eax,eax
 jnz .done
 call g140_parse_nonnegative
.done:
 ret

g140_next_bool:
 call g140_expect_comma
 test eax,eax
 jnz .done
 call g140_parse_bool
.done:
 ret

g140_parse_head:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G140_HEAD 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g140_n_%1]
 mov edx,g140_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G140_HEAD directedEdgeTo,directed
 G140_HEAD bidirectionalEdge,bidirectional
 G140_HEAD asyncEdgeTo,async
 G140_HEAD transitionTo,transition
 jmp .syntax
.directed:
 mov qword [rel g140_kind],G140_DIRECTED
 jmp .advance
.bidirectional:
 mov qword [rel g140_kind],G140_BIDIRECTIONAL
 jmp .advance
.async:
 mov qword [rel g140_kind],G140_ASYNC
 jmp .advance
.transition:
 mov qword [rel g140_kind],G140_TRANSITION
.advance:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call g140_expect
 ret
.syntax:
 mov rax,-1
 ret
%undef G140_HEAD

g140_arrow_token:
 cmp qword [rel g140_kind],G140_DIRECTED
 je .directed
 cmp qword [rel g140_kind],G140_BIDIRECTIONAL
 je .bidirectional
 cmp qword [rel g140_kind],G140_ASYNC
 je .async
 mov eax,NEBOC_TOKEN_STATE_TRANSITION
 ret
.directed:
 mov eax,NEBOC_TOKEN_GRAPH_DIRECTED
 ret
.bidirectional:
 mov eax,NEBOC_TOKEN_GRAPH_BIDIRECTIONAL
 ret
.async:
 mov eax,NEBOC_TOKEN_GRAPH_ASYNC
 ret

g140_parse_endpoints:
 call g140_parse_positive
 test eax,eax
 jnz .done
 mov [rel g140_source],rdx
 call g140_arrow_token
 mov r8d,eax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,r8d
 jne .named
 inc qword [rel ls_cursor]
 jmp .destination
.named:
 call g140_expect_comma
 test eax,eax
 jnz .done
.destination:
 call g140_parse_positive
 test eax,eax
 jnz .done
 mov [rel g140_destination],rdx
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_source_port],rdx
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_destination_port],rdx
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_source_schema],rdx
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_destination_schema],rdx
.done:
 ret

g140_parse_graph_tail:
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_capacity],rdx
 call g140_next_bool
 test eax,eax
 jnz .done
 mov [rel g140_policy],rdx
 mov qword [rel g140_capability],1
 jmp g140_close
.done:
 ret

g140_parse_async_tail:
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_capacity],rdx
 call g140_next_nonnegative
 test eax,eax
 jnz .done
 cmp rdx,2
 ja .domain
 mov [rel g140_policy],rdx
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_capability],rdx
 jmp g140_close
.domain:
 mov eax,28
.done:
 ret

g140_parse_transition_tail:
 mov qword [rel g140_capacity],1
 call g140_next_bool
 test eax,eax
 jnz .done
 mov [rel g140_guard],rdx
 call g140_next_nonnegative
 test eax,eax
 jnz .done
 mov [rel g140_effect],rdx
 call g140_next_positive
 test eax,eax
 jnz .done
 mov [rel g140_capability],rdx
 jmp g140_close
.done:
 ret

g140_close:
 mov edi,NEBOC_TOKEN_RPAREN
 jmp g140_expect

g140_parse_body:
 call g140_parse_endpoints
 test eax,eax
 jnz .done
 cmp qword [rel g140_kind],G140_BIDIRECTIONAL
 jbe .graph
 cmp qword [rel g140_kind],G140_ASYNC
 je .async
 call g140_parse_transition_tail
 ret
.graph:
 call g140_parse_graph_tail
 ret
.async:
 call g140_parse_async_tail
.done:
 ret

; The calculated identity is bounded for direct observation while retaining
; every public constructor field in the deterministic mix.
g140_calculate:
 mov rax,[rel g140_source_schema]
 cmp rax,[rel g140_destination_schema]
 jne .domain
 cmp qword [rel g140_kind],G140_BIDIRECTIONAL
 ja .not_graph
 cmp qword [rel g140_policy],0
 jne .not_graph
 mov rax,[rel g140_source]
 cmp rax,[rel g140_destination]
 je .domain
.not_graph:
 cmp qword [rel g140_kind],G140_ASYNC
 jne .not_async
 mov rax,[rel g140_source]
 cmp rax,[rel g140_destination]
 je .domain
.not_async:
 cmp qword [rel g140_kind],G140_TRANSITION
 jne .mix
 mov rax,[rel g140_capability]
 not rax
 and rax,[rel g140_effect]
 jnz .domain
.mix:
 mov rax,[rel g140_source]
 imul rax,131
 mov rcx,[rel g140_destination]
 imul rcx,137
 add rax,rcx
 mov rcx,[rel g140_source_port]
 imul rcx,139
 add rax,rcx
 mov rcx,[rel g140_destination_port]
 imul rcx,149
 add rax,rcx
 mov rcx,[rel g140_source_schema]
 imul rcx,151
 add rax,rcx
 mov rcx,[rel g140_kind]
 imul rcx,157
 add rax,rcx
 add rax,[rel g140_capacity]
 add rax,[rel g140_policy]
 add rax,[rel g140_guard]
 add rax,[rel g140_effect]
 add rax,[rel g140_capability]
 xor edx,edx
 mov ecx,251
 div rcx
 inc rdx
 mov [rel g140_identity],rdx
 mov rax,rdx
 xor rax,[rel g140_source]
 rol rax,7
 xor rax,[rel g140_destination]
 xor rdx,rdx
 mov ecx,251
 div rcx
 inc rdx
 mov [rel g140_provenance],rdx
 mov rax,[rel g140_destination]
 cmp qword [rel g140_kind],G140_TRANSITION
 jne .replay
 cmp qword [rel g140_guard],0
 jne .replay
 mov rax,[rel g140_source]
.replay:
 mov [rel g140_replay],rax
 xor eax,eax
 ret
.domain:
 mov eax,28
 ret

g140_parse_observer:
 mov edi,NEBOC_TOKEN_DOT
 call g140_expect
 test eax,eax
 jnz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
%macro G140_OBSERVER 2
 mov rdi,[rel ls_cursor]
 lea rsi,[rel g140_n_%1]
 mov edx,g140_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .%2
%endmacro
 G140_OBSERVER source,source
 G140_OBSERVER destination,destination
 G140_OBSERVER sourcePort,source_port
 G140_OBSERVER destinationPort,destination_port
 G140_OBSERVER schema,schema
 G140_OBSERVER capacity,capacity
 G140_OBSERVER policy,policy
 G140_OBSERVER guard,guard
 G140_OBSERVER effect,effect
 G140_OBSERVER capability,capability
 G140_OBSERVER kind,kind
 G140_OBSERVER identity,identity
 G140_OBSERVER provenance,provenance
 G140_OBSERVER replay,replay
 jmp .syntax
.source: mov rdx,[rel g140_source]
 jmp .empty
.destination: mov rdx,[rel g140_destination]
 jmp .empty
.source_port: mov rdx,[rel g140_source_port]
 jmp .empty
.destination_port: mov rdx,[rel g140_destination_port]
 jmp .empty
.schema: mov rdx,[rel g140_source_schema]
 jmp .empty
.capacity: mov rdx,[rel g140_capacity]
 jmp .empty
.policy: mov rdx,[rel g140_policy]
 jmp .empty
.guard: mov rdx,[rel g140_guard]
 jmp .empty
.effect: mov rdx,[rel g140_effect]
 jmp .empty
.capability: mov rdx,[rel g140_capability]
 jmp .empty
.kind: mov rdx,[rel g140_kind]
 jmp .empty
.identity: mov rdx,[rel g140_identity]
 jmp .empty
.provenance: mov rdx,[rel g140_provenance]
 jmp .empty
.replay: mov rdx,[rel g140_replay]
.empty:
 push rdx
 inc qword [rel ls_cursor]
 call g140_empty_call
 pop rdx
 ret
.syntax:
 mov rax,-1
 ret
%undef G140_OBSERVER

g140_parse_term:
 call g140_parse_head
 test eax,eax
 jnz .done
 call g140_parse_body
 test eax,eax
 jnz .done
 call g140_calculate
 test eax,eax
 jnz .done
 call g140_parse_observer
.done:
 ret

g140_parse_program:
 push rbx
 sub rsp,16
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call .clear_term
 call g140_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
.plus_loop:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 call .clear_term
 call g140_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 add [rsp],rdx
 jo .overflow
 jmp .plus_loop
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,G140_FAMILY_KEY
 call ls_success
 jmp .done
.semantic:
 call .record_error_token
 mov edi,eax
 call ls_error
 jmp .done
.overflow:
 call .record_error_token
 mov edi,10
 call ls_error
 jmp .done
.syntax:
 call .record_error_token
 mov edi,24
 call ls_error
 jmp .done
.clear_term:
 lea rdi,[rel g140_scratch_start]
 mov ecx,(g140_scratch_end-g140_scratch_start)/8
 xor eax,eax
 rep stosq
 ret
.record_error_token:
 mov r8,rax
 mov rcx,[rel ls_cursor]
 cmp rcx,[rel ls_token_count]
 jb .error_token_ready
 mov rcx,[rel ls_token_count]
 test rcx,rcx
 jz .error_token_ready
 dec rcx
.error_token_ready:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET],rcx
 mov rax,r8
 ret
.done:
 add rsp,16
 pop rbx
 ret
