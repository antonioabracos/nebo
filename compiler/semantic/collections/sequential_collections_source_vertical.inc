; G007 bounded source vertical for sequential collections.  This file is
; included by legacy_source_verticals.asm so it consumes the canonical lexer
; token stream and the shared structural request.  It never observes source
; paths or fixture names.

%define G7_MAX_RECORDS 8
%define G7_MAX_VALUES 16
%define G7_TYPE_LIST 1
%define G7_TYPE_STACK 2
%define G7_TYPE_QUEUE 3
%define G7_TYPE_DEQUE 4
%define G7_TYPE_ITERATOR 5
%define G7_RESULT_VOID 0
%define G7_RESULT_SCALAR 1
%define G7_RESULT_RECORD 2

section .rodata
g7_n_new: db 'new'
g7_n_new_len equ $-g7_n_new
g7_n_from: db 'from'
g7_n_from_len equ $-g7_n_from
g7_n_with_capacity: db 'withCapacity'
g7_n_with_capacity_len equ $-g7_n_with_capacity
g7_n_length: db 'length'
g7_n_length_len equ $-g7_n_length
g7_n_capacity: db 'capacity'
g7_n_capacity_len equ $-g7_n_capacity
g7_n_reserve: db 'reserve'
g7_n_reserve_len equ $-g7_n_reserve
g7_n_at: db 'at'
g7_n_at_len equ $-g7_n_at
g7_n_get: db 'get'
g7_n_get_len equ $-g7_n_get
g7_n_push: db 'push'
g7_n_push_len equ $-g7_n_push
g7_n_pop: db 'pop'
g7_n_pop_len equ $-g7_n_pop
g7_n_insert: db 'insert'
g7_n_insert_len equ $-g7_n_insert
g7_n_remove: db 'remove'
g7_n_remove_len equ $-g7_n_remove
g7_n_swap_remove: db 'swapRemove'
g7_n_swap_remove_len equ $-g7_n_swap_remove
g7_n_find: db 'find'
g7_n_find_len equ $-g7_n_find
g7_n_contains: db 'contains'
g7_n_contains_len equ $-g7_n_contains
g7_n_map: db 'map'
g7_n_map_len equ $-g7_n_map
g7_n_filter: db 'filter'
g7_n_filter_len equ $-g7_n_filter
g7_n_retain: db 'retain'
g7_n_retain_len equ $-g7_n_retain
g7_n_sort: db 'sort'
g7_n_sort_len equ $-g7_n_sort
g7_n_deduplicate: db 'deduplicate'
g7_n_deduplicate_len equ $-g7_n_deduplicate
g7_n_peek: db 'peek'
g7_n_peek_len equ $-g7_n_peek
g7_n_clear: db 'clear'
g7_n_clear_len equ $-g7_n_clear
g7_n_enqueue: db 'enqueue'
g7_n_enqueue_len equ $-g7_n_enqueue
g7_n_dequeue: db 'dequeue'
g7_n_dequeue_len equ $-g7_n_dequeue
g7_n_push_front: db 'pushFront'
g7_n_push_front_len equ $-g7_n_push_front
g7_n_push_back: db 'pushBack'
g7_n_push_back_len equ $-g7_n_push_back
g7_n_pop_front: db 'popFront'
g7_n_pop_front_len equ $-g7_n_pop_front
g7_n_pop_back: db 'popBack'
g7_n_pop_back_len equ $-g7_n_pop_back
g7_n_iterator: db 'iterator'
g7_n_iterator_len equ $-g7_n_iterator
g7_n_iterator_mutable: db 'iteratorMutable'
g7_n_iterator_mutable_len equ $-g7_n_iterator_mutable
g7_n_next: db 'next'
g7_n_next_len equ $-g7_n_next
g7_n_enumerate: db 'enumerate'
g7_n_enumerate_len equ $-g7_n_enumerate
g7_n_take: db 'take'
g7_n_take_len equ $-g7_n_take
g7_n_skip: db 'skip'
g7_n_skip_len equ $-g7_n_skip
g7_n_collect: db 'collect'
g7_n_collect_len equ $-g7_n_collect
g7_n_release: db 'release'
g7_n_release_len equ $-g7_n_release
g7_n_return: db 'return'
g7_n_return_len equ $-g7_n_return

section .bss align=16
g7_record_count: resq 1
g7_start_token: resq 1
g7_output: resq 1
g7_output_set: resq 1
g7_result_kind: resq 1
g7_result_value: resq 1
g7_result_record: resq 1
g7_active_record: resq 1
g7_callback_kind: resq 1
g7_names: resq G7_MAX_RECORDS
g7_types: resq G7_MAX_RECORDS
g7_lengths: resq G7_MAX_RECORDS
g7_capacities: resq G7_MAX_RECORDS
g7_generations: resq G7_MAX_RECORDS
g7_borrows: resq G7_MAX_RECORDS
g7_iter_owners: resq G7_MAX_RECORDS
g7_iter_generations: resq G7_MAX_RECORDS
g7_iter_indexes: resq G7_MAX_RECORDS
g7_iter_limits: resq G7_MAX_RECORDS
g7_iter_enumerated: resq G7_MAX_RECORDS
g7_values: resq G7_MAX_RECORDS*G7_MAX_VALUES
g7_scratch_end:

section .text

%macro G7_MATCH 3
 lea rsi,[rel %1]
 mov edx,%2
 call ls_current_atom
 test eax,eax
 jnz %3
%endmacro

; RDI record, RSI element -> RAX address.
g7_value_ptr:
 imul rax,rdi,G7_MAX_VALUES
 add rax,rsi
 lea rdx,[rel g7_values]
 lea rax,[rdx+rax*8]
 ret

; RDI binding token -> RAX record or -1.
g7_find_record:
 push rbx
 push r12
 mov rbx,rdi
 xor r12d,r12d
.loop:
 cmp r12,[rel g7_record_count]
 jae .none
 mov rdi,rbx
 mov rsi,[g7_names+r12*8]
 call ls_name_equal
 test eax,eax
 jnz .found
 inc r12
 jmp .loop
.found:
 mov rax,r12
 pop r12
 pop rbx
 ret
.none:
 mov rax,-1
 pop r12
 pop rbx
 ret

; EDI type, RSI capacity -> RAX fresh record or -1.
g7_alloc_record:
 mov rax,[rel g7_record_count]
 cmp rax,G7_MAX_RECORDS
 jae .none
 cmp rsi,G7_MAX_VALUES
 ja .none
 mov [g7_types+rax*8],rdi
 mov [g7_capacities+rax*8],rsi
 mov qword [g7_names+rax*8],LS_NO_TOKEN
 mov qword [g7_iter_owners+rax*8],-1
 inc qword [rel g7_record_count]
 ret
.none:
 mov rax,-1
 ret

; Parse .binding; and attach it to record RDI.
g7_bind_record:
 push rbx
 mov rbx,rdi
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rax,[rel ls_cursor]
 mov [g7_names+rbx*8],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov eax,1
 pop rbx
 ret
.bad:
 xor eax,eax
 pop rbx
 ret

; Require (), used by nullary constructors and operations.
g7_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov eax,1
 add rsp,8
 ret
.bad:
 xor eax,eax
 add rsp,8
 ret

; Parse [signed Int, ...] into record RDI. EAX boolean.
g7_parse_literal:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .bad
 xor ebx,ebx
.item:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .close
 cmp ebx,G7_MAX_VALUES
 jae .bad
 call ls_parse_signed_int
 test eax,eax
 jz .bad
 mov r13,rdx
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov [rax],r13
 inc rbx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .item
 inc qword [rel ls_cursor]
 jmp .item
.close:
 inc qword [rel ls_cursor]
 mov [g7_lengths+r12*8],rbx
 mov [g7_capacities+r12*8],rbx
 mov eax,1
 pop r13
 pop r12
 pop rbx
 ret
.bad:
 xor eax,eax
 pop r13
 pop r12
 pop rbx
 ret

; Grow a bounded record before append. EAX=1 on success.
g7_ensure_append:
 mov rax,[g7_lengths+rdi*8]
 cmp rax,G7_MAX_VALUES
 jae .bad
 cmp rax,[g7_capacities+rdi*8]
 jb .ok
 mov rcx,[g7_capacities+rdi*8]
 test rcx,rcx
 jnz .double
 mov ecx,4
 jmp .store
.double:
 shl rcx,1
.store:
 cmp rcx,G7_MAX_VALUES
 jbe .capacity_ok
 mov ecx,G7_MAX_VALUES
.capacity_ok:
 mov [g7_capacities+rdi*8],rcx
.ok:
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Parse List/Stack/Queue/Deque constructor at the current token.
; EAX=0 success, otherwise bounded diagnostic.
g7_parse_constructor:
 push rbx
 push r12
 xor ebx,ebx
 G7_MATCH ls_n_list,ls_n_list_len,.is_list
 G7_MATCH ls_n_stack,ls_n_stack_len,.is_stack
 G7_MATCH ls_n_queue,ls_n_queue_len,.is_queue
 G7_MATCH ls_n_deque,ls_n_deque_len,.is_deque
 mov eax,20
 jmp .done
.is_list: mov ebx,G7_TYPE_LIST
 jmp .type
.is_stack: mov ebx,G7_TYPE_STACK
 jmp .type
.is_queue: mov ebx,G7_TYPE_QUEUE
 jmp .type
.is_deque: mov ebx,G7_TYPE_DEQUE
.type:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .type_error
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 G7_MATCH g7_n_new,g7_n_new_len,.new
 cmp ebx,G7_TYPE_LIST
 jne .method
 G7_MATCH ls_n_with_capacity,ls_n_with_capacity_len,.with_capacity
 G7_MATCH g7_n_from,g7_n_from_len,.from
.method:
 mov eax,24
 jmp .done
.new:
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov edi,ebx
 xor esi,esi
 call g7_alloc_record
 cmp rax,-1
 je .limit
 mov r12,rax
 jmp .bind
.with_capacity:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .capacity
 cmp rdx,G7_MAX_VALUES
 ja .capacity
 mov r12,rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,G7_TYPE_LIST
 mov rsi,r12
 call g7_alloc_record
 cmp rax,-1
 je .limit
 mov r12,rax
 jmp .bind
.from:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,G7_TYPE_LIST
 mov esi,G7_MAX_VALUES
 call g7_alloc_record
 cmp rax,-1
 je .limit
 mov r12,rax
 mov rdi,r12
 call g7_parse_literal
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
.bind:
 mov rdi,r12
 call g7_bind_record
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.syntax: mov eax,20
 jmp .done
.type_error: mov eax,21
 jmp .done
.capacity: mov eax,23
 jmp .done
.limit: mov eax,26
.done:
 pop r12
 pop rbx
 ret

; RDI declaration-name token, ESI binary flag -> EAX boolean.  The bounded
; callback profile still authenticates receiver type and arity rather than
; treating an operator-shaped body as sufficient evidence.
g7_callback_signature:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13d,esi
 cmp r12,5
 jb .no
 lea rdi,[r12-5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .no
 lea rdi,[r12-4]
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_token_match
 test eax,eax
 jz .no
 lea rdi,[r12-3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .no
 lea rdi,[r12-2]
 lea rsi,[rel ls_n_self]
 mov edx,ls_n_self_len
 call ls_token_match
 test eax,eax
 jz .no
 lea rdi,[r12-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .no
 lea rdi,[r12+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .no
 test r13d,r13d
 jnz .binary
 lea rdi,[r12+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .no
 lea rdi,[r12+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LBRACE
 jne .no
 jmp .yes
.binary:
 lea rdi,[r12+2]
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_token_match
 test eax,eax
 jz .no
 lea rdi,[r12+3]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .no
 lea rdi,[r12+4]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 lea rdi,[r12+5]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .no
 lea rdi,[r12+6]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LBRACE
 jne .no
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; RDI callback-name token, ESI required operator kind -> EAX boolean and
; RDX signed literal immediately following the operator when present.
; Only declarations before start() are considered, so a call-site name cannot
; authenticate itself.
g7_callback_operator:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13d,esi
 xor ebx,ebx
.name_loop:
 cmp rbx,[rel g7_start_token]
 jae .no
 mov rdi,r12
 mov rsi,rbx
 call ls_name_equal
 test eax,eax
 jz .name_next
 mov rdi,rbx
 xor esi,esi
 cmp r13d,NEBOC_TOKEN_SPACESHIP
 sete sil
 call g7_callback_signature
 test eax,eax
 jz .name_next
 mov rcx,rbx
.brace_loop:
 inc rcx
 cmp rcx,[rel g7_start_token]
 jae .name_next
 mov rdi,rcx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LBRACE
 jne .brace_loop
.body_loop:
 inc rcx
 cmp rcx,[rel g7_start_token]
 jae .no
 mov rdi,rcx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 je .name_next
 cmp eax,r13d
 jne .body_loop
 mov rdi,rcx
 inc rdi
 call ls_token_ptr
 xor edx,edx
 test rax,rax
 jz .yes
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .yes
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
.yes:
 mov ecx,r13d
 mov eax,1
 pop r13
 pop r12
 pop rbx
 ret
.name_next:
 inc rbx
 jmp .name_loop
.no:
 xor eax,eax
 pop r13
 pop r12
 pop rbx
 ret

; Select one of the bounded, value-producing Int transform bodies.
; RDI callback token -> EAX boolean, ECX operator, RDX literal.
g7_select_transform:
 push r12
 mov r12,rdi
 mov esi,NEBOC_TOKEN_PLUS
 call g7_callback_operator
 test eax,eax
 jnz .done
 mov rdi,r12
 mov esi,NEBOC_TOKEN_MINUS
 call g7_callback_operator
 test eax,eax
 jnz .done
 mov rdi,r12
 mov esi,NEBOC_TOKEN_STAR
 call g7_callback_operator
.done:
 pop r12
 ret

; Select a bounded Int predicate and evaluate it with signed semantics.
g7_select_predicate:
 push r12
 mov r12,rdi
 mov esi,NEBOC_TOKEN_GREATER
 call g7_callback_operator
 test eax,eax
 jnz .selected
 mov rdi,r12
 mov esi,NEBOC_TOKEN_GREATER_EQUAL
 call g7_callback_operator
 test eax,eax
 jnz .selected
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LESS
 call g7_callback_operator
 test eax,eax
 jnz .selected
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LESS_EQUAL
 call g7_callback_operator
 test eax,eax
 jnz .selected
 mov rdi,r12
 mov esi,NEBOC_TOKEN_EQUAL_EQUAL
 call g7_callback_operator
 test eax,eax
 jnz .selected
 mov rdi,r12
 mov esi,NEBOC_TOKEN_BANG_EQUAL
 call g7_callback_operator
.selected:
 pop r12
 ret

; RDI lhs, RSI rhs, EDX token kind -> EAX predicate result.
g7_evaluate_predicate:
 cmp edx,NEBOC_TOKEN_GREATER
 je .greater
 cmp edx,NEBOC_TOKEN_GREATER_EQUAL
 je .greater_equal
 cmp edx,NEBOC_TOKEN_LESS
 je .less
 cmp edx,NEBOC_TOKEN_LESS_EQUAL
 je .less_equal
 cmp edx,NEBOC_TOKEN_EQUAL_EQUAL
 je .equal
 cmp edx,NEBOC_TOKEN_BANG_EQUAL
 je .not_equal
 xor eax,eax
 ret
.greater:
 cmp rdi,rsi
 setg al
 jmp .result
.greater_equal:
 cmp rdi,rsi
 setge al
 jmp .result
.less:
 cmp rdi,rsi
 setl al
 jmp .result
.less_equal:
 cmp rdi,rsi
 setle al
 jmp .result
.equal:
 cmp rdi,rsi
 sete al
 jmp .result
.not_equal:
 cmp rdi,rsi
 setne al
.result:
 movzx eax,al
 ret
; Parse (callbackIdentifier) and return its token index in RDX.
g7_parse_callback_arg:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rdx,[rel ls_cursor]
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov eax,1
 add rsp,8
 ret
.bad:
 xor eax,eax
 add rsp,8
 ret

; Parse one signed integer argument. EAX boolean, RDX value.
g7_parse_int_arg:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .bad
 call ls_parse_signed_int
 test eax,eax
 jz .bad
 push rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 pop rdx
 test eax,eax
 jz .bad
 mov eax,1
 add rsp,8
 ret
.bad:
 xor eax,eax
 add rsp,8
 ret

; Parse (first, second). EAX boolean, RDX first, RCX second.
g7_parse_two_int_args:
 push rbx
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .bad
 call ls_parse_signed_int
 test eax,eax
 jz .bad
 mov rbx,rdx
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .bad
 call ls_parse_signed_int
 test eax,eax
 jz .bad
 mov rcx,rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov rdx,rbx
 mov eax,1
 add rsp,8
 pop rbx
 ret
.bad:
 xor eax,eax
 add rsp,8
 pop rbx
 ret

g7_mark_mutation:
 inc qword [g7_generations+rdi*8]
 ret

; Reject mutation while an iterator owns the record.
g7_mutation_gate:
 cmp qword [g7_borrows+rdi*8],0
 jne .bad
 mov eax,1
 ret
.bad:
 xor eax,eax
 ret

; Consume a method result as ;, .binding;, or .return;.  A record result is
; bound by identity; scalar bindings are intentionally immutable sinks.
g7_consume_result:
 push rbx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 je .semicolon
 cmp eax,NEBOC_TOKEN_DOT
 jne .bad
 inc qword [rel ls_cursor]
 lea rsi,[rel g7_n_return]
 mov edx,g7_n_return_len
 call ls_current_atom
 test eax,eax
 jnz .return
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rbx,[rel ls_cursor]
 inc qword [rel ls_cursor]
 cmp qword [rel g7_result_kind],G7_RESULT_RECORD
 jne .binding_done
 mov rax,[rel g7_result_record]
 mov [g7_names+rax*8],rbx
.binding_done:
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov eax,1
 pop rbx
 ret
.return:
 inc qword [rel ls_cursor]
 cmp qword [rel g7_result_kind],G7_RESULT_SCALAR
 jne .bad
 mov rax,[rel g7_result_value]
 mov [rel g7_output],rax
 mov qword [rel g7_output_set],1
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .bad
 mov eax,1
 pop rbx
 ret
.semicolon:
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .ok
 cmp qword [rel g7_result_kind],G7_RESULT_SCALAR
 jne .ok
 mov rax,[rel g7_result_value]
 mov [rel g7_output],rax
 mov qword [rel g7_output_set],1
.ok:
 mov eax,1
 pop rbx
 ret
.bad:
 xor eax,eax
 pop rbx
 ret

; Dispatch a method for active record. The cursor points at its name.
; EAX=0 success or a stable G007 diagnostic.
g7_parse_method:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,[rel g7_active_record]
 mov qword [rel g7_result_kind],G7_RESULT_VOID
 G7_MATCH g7_n_length,g7_n_length_len,.length
 G7_MATCH g7_n_capacity,g7_n_capacity_len,.capacity
 G7_MATCH g7_n_reserve,g7_n_reserve_len,.reserve
 G7_MATCH g7_n_at,g7_n_at_len,.at
 G7_MATCH g7_n_get,g7_n_get_len,.at
 G7_MATCH g7_n_push,g7_n_push_len,.push
 G7_MATCH g7_n_pop,g7_n_pop_len,.pop
 G7_MATCH g7_n_insert,g7_n_insert_len,.insert
 G7_MATCH g7_n_remove,g7_n_remove_len,.remove
 G7_MATCH g7_n_swap_remove,g7_n_swap_remove_len,.swap_remove
 G7_MATCH g7_n_contains,g7_n_contains_len,.contains
 G7_MATCH g7_n_find,g7_n_find_len,.find
 G7_MATCH g7_n_map,g7_n_map_len,.map
 G7_MATCH g7_n_filter,g7_n_filter_len,.filter
 G7_MATCH g7_n_retain,g7_n_retain_len,.retain
 G7_MATCH g7_n_sort,g7_n_sort_len,.sort
 G7_MATCH g7_n_deduplicate,g7_n_deduplicate_len,.deduplicate
 G7_MATCH g7_n_peek,g7_n_peek_len,.peek
 G7_MATCH g7_n_clear,g7_n_clear_len,.clear
 G7_MATCH g7_n_enqueue,g7_n_enqueue_len,.enqueue
 G7_MATCH g7_n_dequeue,g7_n_dequeue_len,.dequeue
 G7_MATCH g7_n_push_front,g7_n_push_front_len,.push_front
 G7_MATCH g7_n_push_back,g7_n_push_back_len,.push_back
 G7_MATCH g7_n_pop_front,g7_n_pop_front_len,.pop_front
 G7_MATCH g7_n_pop_back,g7_n_pop_back_len,.pop_back
 G7_MATCH g7_n_iterator,g7_n_iterator_len,.iterator
 G7_MATCH g7_n_iterator_mutable,g7_n_iterator_mutable_len,.iterator
 G7_MATCH g7_n_next,g7_n_next_len,.next
 G7_MATCH g7_n_enumerate,g7_n_enumerate_len,.enumerate
 G7_MATCH g7_n_skip,g7_n_skip_len,.skip
 G7_MATCH g7_n_take,g7_n_take_len,.take
 G7_MATCH g7_n_collect,g7_n_collect_len,.collect
 G7_MATCH g7_n_release,g7_n_release_len,.release
 mov eax,24
 jmp .done

.length:
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov rax,[g7_lengths+r12*8]
 jmp .scalar_rax
.capacity:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov rax,[g7_capacities+r12*8]
.scalar_rax:
 mov [rel g7_result_value],rax
 mov qword [rel g7_result_kind],G7_RESULT_SCALAR
 xor eax,eax
 jmp .done
.reserve:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .capacity_error
 mov rax,[g7_lengths+r12*8]
 add rax,rdx
 jo .capacity_error
 cmp rax,G7_MAX_VALUES
 ja .capacity_error
 cmp rax,[g7_capacities+r12*8]
 jbe .reserve_ok
 mov [g7_capacities+r12*8],rax
 mov rdi,r12
 call g7_mark_mutation
.reserve_ok:
 xor eax,eax
 jmp .done
.at:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 je .method
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .bounds
 cmp rdx,[g7_lengths+r12*8]
 jae .bounds
 mov rdi,r12
 mov rsi,rdx
 call g7_value_ptr
 mov rax,[rax]
 jmp .scalar_rax
.push:
 mov rax,[g7_types+r12*8]
 cmp rax,G7_TYPE_LIST
 je .append
 cmp rax,G7_TYPE_STACK
 jne .method
.append:
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 mov r13,rdx
 mov rdi,r12
 call g7_ensure_append
 test eax,eax
 jz .limit
 mov rsi,[g7_lengths+r12*8]
 mov rdi,r12
 call g7_value_ptr
 mov [rax],r13
 inc qword [g7_lengths+r12*8]
 mov rdi,r12
 call g7_mark_mutation
 xor eax,eax
 jmp .done
.pop:
 mov rax,[g7_types+r12*8]
 cmp rax,G7_TYPE_LIST
 je .pop_last
 cmp rax,G7_TYPE_STACK
 jne .method
.pop_last:
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov rsi,[g7_lengths+r12*8]
 test rsi,rsi
 jz .bounds
 dec rsi
 mov [g7_lengths+r12*8],rsi
 mov rdi,r12
 call g7_value_ptr
 mov rax,[rax]
 push rax
 mov rdi,r12
 call g7_mark_mutation
 pop rax
 jmp .scalar_rax
.insert:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_two_int_args
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .bounds
 cmp rdx,[g7_lengths+r12*8]
 ja .bounds
 mov r13,rdx
 mov r14,rcx
 mov rdi,r12
 call g7_ensure_append
 test eax,eax
 jz .limit
 mov r15,[g7_lengths+r12*8]
.insert_shift:
 cmp r15,r13
 jbe .insert_store
 mov rdi,r12
 mov rsi,r15
 dec rsi
 call g7_value_ptr
 mov rbx,[rax]
 mov rdi,r12
 mov rsi,r15
 call g7_value_ptr
 mov [rax],rbx
 dec r15
 jmp .insert_shift
.insert_store:
 mov rdi,r12
 mov rsi,r13
 call g7_value_ptr
 mov [rax],r14
 inc qword [g7_lengths+r12*8]
 mov rdi,r12
 call g7_mark_mutation
 xor eax,eax
 jmp .done

.remove:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .bounds
 cmp rdx,[g7_lengths+r12*8]
 jae .bounds
 mov r13,rdx
 mov rdi,r12
 mov rsi,r13
 call g7_value_ptr
 mov r14,[rax]
 mov r15,r13
.remove_shift:
 mov rax,[g7_lengths+r12*8]
 dec rax
 cmp r15,rax
 jae .remove_commit
 mov rdi,r12
 mov rsi,r15
 inc rsi
 call g7_value_ptr
 mov rbx,[rax]
 mov rdi,r12
 mov rsi,r15
 call g7_value_ptr
 mov [rax],rbx
 inc r15
 jmp .remove_shift
.remove_commit:
 dec qword [g7_lengths+r12*8]
 mov rdi,r12
 call g7_mark_mutation
 mov rax,r14
 jmp .scalar_rax
.swap_remove:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .bounds
 cmp rdx,[g7_lengths+r12*8]
 jae .bounds
 mov r13,rdx
 mov rdi,r12
 mov rsi,r13
 call g7_value_ptr
 mov r14,[rax]
 mov r15,[g7_lengths+r12*8]
 dec r15
 cmp r13,r15
 je .swap_commit
 mov rdi,r12
 mov rsi,r15
 call g7_value_ptr
 mov rbx,[rax]
 mov rdi,r12
 mov rsi,r13
 call g7_value_ptr
 mov [rax],rbx
.swap_commit:
 mov [g7_lengths+r12*8],r15
 mov rdi,r12
 call g7_mark_mutation
 mov rax,r14
 jmp .scalar_rax
.contains:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 mov r14,rdx
 xor r13d,r13d
 xor ebx,ebx
.contains_loop:
 cmp rbx,[g7_lengths+r12*8]
 jae .contains_done
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 cmp [rax],r14
 jne .contains_next
 mov r13d,1
 jmp .contains_done
.contains_next:
 inc rbx
 jmp .contains_loop
.contains_done:
 mov rax,r13
 jmp .scalar_rax
.find:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 inc qword [rel ls_cursor]
 call g7_parse_callback_arg
 test eax,eax
 jz .syntax
 mov r13,rdx
 mov rdi,r13
 call g7_select_predicate
 test eax,eax
 jz .callback
 mov r14,rdx
 mov [rel g7_callback_kind],rcx
 xor ebx,ebx
.find_loop:
 cmp rbx,[g7_lengths+r12*8]
 jae .find_none
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov r13,[rax]
 mov rdi,r13
 mov rsi,r14
 mov edx,[rel g7_callback_kind]
 call g7_evaluate_predicate
 test eax,eax
 jz .find_next
 mov rax,r13
 jmp .scalar_rax
.find_next:
 inc rbx
 jmp .find_loop
.find_none:
 xor eax,eax
 jmp .scalar_rax
.map:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 inc qword [rel ls_cursor]
 call g7_parse_callback_arg
 test eax,eax
 jz .syntax
 mov r13,rdx
 mov rdi,r13
 call g7_select_transform
 test eax,eax
 jz .callback
 mov r14,rdx
 mov [rel g7_callback_kind],rcx
 mov edi,G7_TYPE_LIST
 mov rsi,[g7_lengths+r12*8]
 call g7_alloc_record
 cmp rax,-1
 je .limit
 mov r15,rax
 mov rax,[g7_lengths+r12*8]
 mov [g7_lengths+r15*8],rax
 xor ebx,ebx
.map_loop:
 cmp rbx,[g7_lengths+r12*8]
 jae .record_r15
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov r13,[rax]
 mov rcx,[rel g7_callback_kind]
 cmp ecx,NEBOC_TOKEN_PLUS
 je .map_add
 cmp ecx,NEBOC_TOKEN_MINUS
 je .map_subtract
 imul r13,r14
 jo .limit
 jmp .map_store
.map_add:
 add r13,r14
 jo .limit
 jmp .map_store
.map_subtract:
 sub r13,r14
 jo .limit
.map_store:
 mov rdi,r15
 mov rsi,rbx
 call g7_value_ptr
 mov [rax],r13
 inc rbx
 jmp .map_loop
.filter:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 inc qword [rel ls_cursor]
 call g7_parse_callback_arg
 test eax,eax
 jz .syntax
 mov r13,rdx
 mov rdi,r13
 call g7_select_predicate
 test eax,eax
 jz .callback
 mov r14,rdx
 mov [rel g7_callback_kind],rcx
 mov edi,G7_TYPE_LIST
 mov rsi,[g7_lengths+r12*8]
 call g7_alloc_record
 cmp rax,-1
 je .limit
 mov r15,rax
 xor ebx,ebx
 xor r13d,r13d
.filter_loop:
 cmp rbx,[g7_lengths+r12*8]
 jae .filter_commit
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov r13,[rax]
 mov rdi,r13
 mov rsi,r14
 mov edx,[rel g7_callback_kind]
 call g7_evaluate_predicate
 test eax,eax
 jz .filter_next
 mov rdi,r15
 mov rsi,r13
 mov rsi,[g7_lengths+r15*8]
 call g7_value_ptr
 mov [rax],r13
 inc qword [g7_lengths+r15*8]
.filter_next:
 inc rbx
 jmp .filter_loop
.filter_commit:
 mov rax,[g7_lengths+r15*8]
 mov [g7_capacities+r15*8],rax
.record_r15:
 mov [rel g7_result_record],r15
 mov qword [rel g7_result_kind],G7_RESULT_RECORD
 xor eax,eax
 jmp .done
.retain:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_callback_arg
 test eax,eax
 jz .syntax
 mov r13,rdx
 mov rdi,r13
 call g7_select_predicate
 test eax,eax
 jz .callback
 mov r14,rdx
 mov [rel g7_callback_kind],rcx
 xor ebx,ebx
 xor r15d,r15d
.retain_loop:
 cmp rbx,[g7_lengths+r12*8]
 jae .retain_commit
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov r13,[rax]
 mov rdi,r13
 mov rsi,r14
 mov edx,[rel g7_callback_kind]
 call g7_evaluate_predicate
 test eax,eax
 jz .retain_next
 mov rdi,r12
 mov rsi,r15
 call g7_value_ptr
 mov [rax],r13
 inc r15
.retain_next:
 inc rbx
 jmp .retain_loop
.retain_commit:
 cmp r15,[g7_lengths+r12*8]
 je .retain_ok
 mov [g7_lengths+r12*8],r15
 mov rdi,r12
 call g7_mark_mutation
.retain_ok:
 xor eax,eax
 jmp .done
.sort:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_callback_arg
 test eax,eax
 jz .syntax
 mov rdi,rdx
 mov esi,NEBOC_TOKEN_SPACESHIP
 call g7_callback_operator
 test eax,eax
 jz .callback
 mov ebx,1
.sort_outer:
 cmp rbx,[g7_lengths+r12*8]
 jae .sort_commit
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov r13,[rax]
 mov r14,rbx
.sort_inner:
 test r14,r14
 jz .sort_place
 mov rdi,r12
 lea rsi,[r14-1]
 call g7_value_ptr
 mov r15,[rax]
 cmp r15,r13
 jle .sort_place
 mov rdi,r12
 mov rsi,r14
 call g7_value_ptr
 mov [rax],r15
 dec r14
 jmp .sort_inner
.sort_place:
 mov rdi,r12
 mov rsi,r14
 call g7_value_ptr
 mov [rax],r13
 inc rbx
 jmp .sort_outer
.sort_commit:
 cmp qword [g7_lengths+r12*8],1
 jbe .sort_ok
 mov rdi,r12
 call g7_mark_mutation
.sort_ok:
 xor eax,eax
 jmp .done
.deduplicate:
 cmp qword [g7_types+r12*8],G7_TYPE_LIST
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov rax,[g7_lengths+r12*8]
 cmp rax,1
 jbe .dedup_ok
 mov ebx,1
 mov r15,1
.dedup_loop:
 cmp rbx,[g7_lengths+r12*8]
 jae .dedup_commit
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov r13,[rax]
 mov rdi,r12
 lea rsi,[r15-1]
 call g7_value_ptr
 cmp [rax],r13
 je .dedup_next
 mov rdi,r12
 mov rsi,r15
 call g7_value_ptr
 mov [rax],r13
 inc r15
.dedup_next:
 inc rbx
 jmp .dedup_loop
.dedup_commit:
 cmp r15,[g7_lengths+r12*8]
 je .dedup_ok
 mov [g7_lengths+r12*8],r15
 mov rdi,r12
 call g7_mark_mutation
.dedup_ok:
 xor eax,eax
 jmp .done
.peek:
 mov rax,[g7_types+r12*8]
 cmp rax,G7_TYPE_STACK
 je .peek_stack
 cmp rax,G7_TYPE_QUEUE
 jne .method
 xor r14d,r14d
 jmp .peek_call
.peek_stack:
 mov r14,[g7_lengths+r12*8]
 test r14,r14
 jz .bounds
 dec r14
.peek_call:
 cmp qword [g7_lengths+r12*8],0
 je .bounds
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov rsi,r14
 call g7_value_ptr
 mov rax,[rax]
 jmp .scalar_rax
.clear:
 cmp qword [g7_types+r12*8],G7_TYPE_STACK
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 cmp qword [g7_lengths+r12*8],0
 je .clear_ok
 mov qword [g7_lengths+r12*8],0
 mov rdi,r12
 call g7_mark_mutation
.clear_ok:
 xor eax,eax
 jmp .done
.enqueue:
 cmp qword [g7_types+r12*8],G7_TYPE_QUEUE
 jne .method
 jmp .queue_append
.push_back:
 cmp qword [g7_types+r12*8],G7_TYPE_DEQUE
 jne .method
.queue_append:
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 mov r13,rdx
 mov rdi,r12
 call g7_ensure_append
 test eax,eax
 jz .limit
 mov rsi,[g7_lengths+r12*8]
 mov rdi,r12
 call g7_value_ptr
 mov [rax],r13
 inc qword [g7_lengths+r12*8]
 mov rdi,r12
 call g7_mark_mutation
 xor eax,eax
 jmp .done
.dequeue:
 cmp qword [g7_types+r12*8],G7_TYPE_QUEUE
 jne .method
 jmp .front_pop
.pop_front:
 cmp qword [g7_types+r12*8],G7_TYPE_DEQUE
 jne .method
.front_pop:
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 cmp qword [g7_lengths+r12*8],0
 je .bounds
 mov rdi,r12
 xor esi,esi
 call g7_value_ptr
 mov r14,[rax]
 xor ebx,ebx
.front_shift:
 mov rax,[g7_lengths+r12*8]
 dec rax
 cmp rbx,rax
 jae .front_commit
 mov rdi,r12
 lea rsi,[rbx+1]
 call g7_value_ptr
 mov r13,[rax]
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov [rax],r13
 inc rbx
 jmp .front_shift
.front_commit:
 dec qword [g7_lengths+r12*8]
 mov rdi,r12
 call g7_mark_mutation
 mov rax,r14
 jmp .scalar_rax
.push_front:
 cmp qword [g7_types+r12*8],G7_TYPE_DEQUE
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 mov r14,rdx
 mov rdi,r12
 call g7_ensure_append
 test eax,eax
 jz .limit
 mov rbx,[g7_lengths+r12*8]
.front_insert_shift:
 test rbx,rbx
 jz .front_insert_store
 mov rdi,r12
 lea rsi,[rbx-1]
 call g7_value_ptr
 mov r13,[rax]
 mov rdi,r12
 mov rsi,rbx
 call g7_value_ptr
 mov [rax],r13
 dec rbx
 jmp .front_insert_shift
.front_insert_store:
 mov rdi,r12
 xor esi,esi
 call g7_value_ptr
 mov [rax],r14
 inc qword [g7_lengths+r12*8]
 mov rdi,r12
 call g7_mark_mutation
 xor eax,eax
 jmp .done
.pop_back:
 cmp qword [g7_types+r12*8],G7_TYPE_DEQUE
 jne .method
 mov rdi,r12
 call g7_mutation_gate
 test eax,eax
 jz .borrow
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov rsi,[g7_lengths+r12*8]
 test rsi,rsi
 jz .bounds
 dec rsi
 mov [g7_lengths+r12*8],rsi
 mov rdi,r12
 call g7_value_ptr
 mov r14,[rax]
 mov rdi,r12
 call g7_mark_mutation
 mov rax,r14
 jmp .scalar_rax
.iterator:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 je .method
 cmp qword [g7_borrows+r12*8],0
 jne .borrow
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov edi,G7_TYPE_ITERATOR
 xor esi,esi
 call g7_alloc_record
 cmp rax,-1
 je .limit
 mov r15,rax
 mov [g7_iter_owners+r15*8],r12
 mov rax,[g7_generations+r12*8]
 mov [g7_iter_generations+r15*8],rax
 mov qword [g7_iter_indexes+r15*8],0
 mov rax,[g7_lengths+r12*8]
 mov [g7_iter_limits+r15*8],rax
 mov qword [g7_borrows+r12*8],1
 jmp .record_r15
.next:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 jne .method
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov r13,[g7_iter_owners+r12*8]
 cmp r13,-1
 je .borrow
 mov rax,[g7_generations+r13*8]
 cmp rax,[g7_iter_generations+r12*8]
 jne .borrow
 mov rsi,[g7_iter_indexes+r12*8]
 cmp rsi,[g7_iter_limits+r12*8]
 jae .bounds
 mov rdi,r13
 call g7_value_ptr
 mov rax,[rax]
 inc qword [g7_iter_indexes+r12*8]
 jmp .scalar_rax
.enumerate:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 jne .method
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov qword [g7_iter_enumerated+r12*8],1
 xor eax,eax
 jmp .done
.skip:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 jne .method
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .bounds
 mov rax,[g7_iter_indexes+r12*8]
 add rax,rdx
 cmp rax,[g7_iter_limits+r12*8]
 jbe .skip_store
 mov rax,[g7_iter_limits+r12*8]
.skip_store:
 mov [g7_iter_indexes+r12*8],rax
 xor eax,eax
 jmp .done
.take:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 jne .method
 inc qword [rel ls_cursor]
 call g7_parse_int_arg
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .bounds
 mov rax,[g7_iter_indexes+r12*8]
 add rax,rdx
 cmp rax,[g7_iter_limits+r12*8]
 jae .take_ok
 mov [g7_iter_limits+r12*8],rax
.take_ok:
 xor eax,eax
 jmp .done
.collect:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 jne .method
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_list]
 mov edx,ls_n_list_len
 call ls_expect_atom
 test eax,eax
 jz .type_error
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .type_error
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov rax,[g7_iter_limits+r12*8]
 sub rax,[g7_iter_indexes+r12*8]
 mov r14,rax
 mov edi,G7_TYPE_LIST
 mov rsi,r14
 call g7_alloc_record
 cmp rax,-1
 je .limit
 mov r15,rax
 mov [g7_lengths+r15*8],r14
 xor ebx,ebx
.collect_loop:
 cmp rbx,r14
 jae .collect_commit
 mov r13,[g7_iter_owners+r12*8]
 mov rsi,[g7_iter_indexes+r12*8]
 add rsi,rbx
 mov rdi,r13
 call g7_value_ptr
 mov r13,[rax]
 mov rdi,r15
 mov rsi,rbx
 call g7_value_ptr
 mov [rax],r13
 inc rbx
 jmp .collect_loop
.collect_commit:
 mov rax,[g7_iter_limits+r12*8]
 mov [g7_iter_indexes+r12*8],rax
 jmp .record_r15
.release:
 cmp qword [g7_types+r12*8],G7_TYPE_ITERATOR
 jne .method
 inc qword [rel ls_cursor]
 call g7_empty_call
 test eax,eax
 jz .syntax
 mov r13,[g7_iter_owners+r12*8]
 cmp r13,-1
 je .borrow
 mov qword [g7_borrows+r13*8],0
 mov qword [g7_iter_owners+r12*8],-1
 xor eax,eax
 jmp .done

.method: mov eax,24
 jmp .done
.syntax: mov eax,20
 jmp .done
.bounds: mov eax,22
 jmp .done
.capacity_error: mov eax,23
 jmp .done
.callback: mov eax,25
 jmp .done
.type_error: mov eax,21
 jmp .done
.limit: mov eax,26
 jmp .done
.borrow: mov eax,27
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Public entry reached only after the owner recognizer found a sequential
; collection atom.  The source is interpreted from canonical tokens into one
; bounded semantic value, which the existing lowering/codegen path emits.
neboc_g007_source_parse:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 lea rdi,[rel g7_record_count]
 mov ecx,(g7_scratch_end-g7_record_count)/8
 xor eax,eax
 rep stosq
 xor ebx,ebx
.find_start:
 cmp rbx,[rel ls_token_count]
 jae .syntax
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_KW_START
 je .start
 inc rbx
 jmp .find_start
.start:
 mov [rel g7_start_token],rbx
 mov [rel ls_cursor],rbx
 call ls_start_header
 test eax,eax
 jz .syntax
.statement:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 je .finish
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 G7_MATCH ls_n_list,ls_n_list_len,.constructor
 G7_MATCH ls_n_stack,ls_n_stack_len,.constructor
 G7_MATCH ls_n_queue,ls_n_queue_len,.constructor
 G7_MATCH ls_n_deque,ls_n_deque_len,.constructor
 mov r13,[rel ls_cursor]
 mov rdi,r13
 call g7_find_record
 cmp rax,-1
 je .syntax
 mov [rel g7_active_record],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 call g7_parse_method
 test eax,eax
 jnz .diagnostic
 call g7_consume_result
 test eax,eax
 jz .syntax
 jmp .statement
.constructor:
 call g7_parse_constructor
 test eax,eax
 jnz .diagnostic
 jmp .statement
.finish:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_EOF
 call ls_expect_kind
 test eax,eax
 jz .syntax
 cmp qword [rel g7_output_set],1
 jne .syntax
 mov rdi,[rel g7_output]
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x5246323034473037
 call ls_success
 jmp .done
.syntax:
 mov edi,20
 call ls_error
 jmp .done
.diagnostic:
 mov edi,eax
 call ls_error
.done:
 pop r13
 pop r12
 pop rbx
 leave
 ret

%undef G7_MATCH
