; TIPOS-PRIMITIVOS-ESCALARES-F08 bounded inline Buffer construction recognizer.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/buffer_parser.inc"
%include "compiler/semantic/collections/public_slice.inc"

section .rodata
n_buffer: db 'Buffer'
n_buffer_len equ $-n_buffer
n_with_capacity: db 'withCapacity'
n_with_capacity_len equ $-n_with_capacity
n_zeroed: db 'zeroed'
n_zeroed_len equ $-n_zeroed
n_length: db 'length'
n_length_len equ $-n_length
n_capacity: db 'capacity'
n_capacity_len equ $-n_capacity
n_drop: db 'drop'
n_drop_len equ $-n_drop
n_copy: db 'copy'
n_copy_len equ $-n_copy
n_move: db 'move'
n_move_len equ $-n_move
n_clone: db 'clone'
n_clone_len equ $-n_clone
n_at: db 'at'
n_at_len equ $-n_at
n_get: db 'get'
n_get_len equ $-n_get
n_set: db 'set'
n_set_len equ $-n_set
n_push: db 'push'
n_push_len equ $-n_push
n_clear: db 'clear'
n_clear_len equ $-n_clear
n_borrow_shared: db 'borrowShared'
n_borrow_shared_len equ $-n_borrow_shared
n_reserve: db 'reserve'
n_reserve_len equ $-n_reserve
n_grow: db 'grow'
n_grow_len equ $-n_grow
n_extend: db 'extend'
n_extend_len equ $-n_extend
n_view: db 'view'
n_view_len equ $-n_view
n_subview: db 'subview'
n_subview_len equ $-n_subview
n_sum: db 'sum'
n_sum_len equ $-n_sum
n_release: db 'release'
n_release_len equ $-n_release

section .text

; RAX token index -> token pointer or zero. R12 is request.
buffer_token_ptr:
 cmp rax,[r12+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_BUFFER_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RAX token index -> token kind or INVALID.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_token_kind:
 call buffer_token_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad:
 mov eax,NEBOC_TOKEN_INVALID
 ret

; RAX token index, RSI bytes, EDX length -> EAX boolean.
%undef call
buffer_token_match:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 mov r14,rsi
 mov r15d,edx
 call buffer_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r15
 jne .no
 mov r8,[r12+NEBOC_BUFFER_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r15
 jae .yes
 mov al,[r8+rcx]
 cmp al,[r14+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; RAX first token index, RBX second token index -> EAX boolean byte equality.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_token_equal:
 push rbp
 push r13
 push r14
 push r15
 mov r13,rax
 mov r14,rbx
 call buffer_token_ptr
 test rax,rax
 jz .no
 mov r15,rax
 mov rax,r14
 call buffer_token_ptr
 test rax,rax
 jz .no
 mov rbp,rax
 cmp qword [r15+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 cmp qword [rbp+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[r15+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[r15+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[rbp+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rbp+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 mov r8,[r12+NEBOC_BUFFER_SOURCE_OFFSET]
 mov r9,r8
 add r8,[r15+NEBOC_TOKEN_START_OFFSET]
 add r9,[rbp+NEBOC_TOKEN_START_OFFSET]
 xor edx,edx
.loop:
 cmp rdx,rcx
 jae .yes
 mov al,[r8+rdx]
 cmp al,[r9+rdx]
 jne .no
 inc rdx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop rbp
 ret

; R14 token index, ESI diagnostic -> INVALID_SOURCE.
buffer_error:
 mov qword [r12+NEBOC_BUFFER_FOUND_OFFSET],1
 mov [r12+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],rsi
 mov [r12+NEBOC_BUFFER_ERROR_TOKEN_OFFSET],r14
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; R14 index, EDI kind -> EAX bool.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_kind_is:
 mov rax,r14
 call buffer_token_kind
 cmp eax,edi
 sete al
 movzx eax,al
 ret

; Constructor suffix starts at R14 == Buffer token.  Returns status.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_parse_constructor:
 ; Buffer . method ( literal ) . owner ;
 inc r14
 mov edi,NEBOC_TOKEN_DOT
 call buffer_kind_is
 test eax,eax
 jz .transport
 inc r14
 mov rax,r14
 lea rsi,[rel n_with_capacity]
 mov edx,n_with_capacity_len
 call buffer_token_match
 test eax,eax
 jnz .with_capacity
 mov rax,r14
 lea rsi,[rel n_zeroed]
 mov edx,n_zeroed_len
 call buffer_token_match
 test eax,eax
 jnz .zeroed
 jmp .transport
.with_capacity:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_WITH_CAPACITY
 mov r13d,NEBOC_BUFFER_DIAG_CAPACITY_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_CAPACITY_DYNAMIC
 jmp .argument
.zeroed:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_ZEROED
 mov r13d,NEBOC_BUFFER_DIAG_LENGTH_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_LENGTH_DYNAMIC
.argument:
 inc r14
 mov edi,NEBOC_TOKEN_LPAREN
 call buffer_kind_is
 test eax,eax
 jz .syntax
 inc r14
 mov rax,r14
 call buffer_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 je .literal
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .dynamic
 mov esi,r13d
 jmp buffer_error
.dynamic:
 mov esi,ebp
 jmp buffer_error
.literal:
 mov r15,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_WITH_CAPACITY
 jz .check_length
 cmp r15,4
 jne .capacity_range
 xor r15d,r15d
 jmp .literal_ready
.capacity_range:
 mov esi,NEBOC_BUFFER_DIAG_CAPACITY_UNSUPPORTED
 jmp buffer_error
.check_length:
 cmp r15,4
 ja .length_range
.literal_ready:
 inc r14
 mov edi,NEBOC_TOKEN_RPAREN
 call buffer_kind_is
 test eax,eax
 jz .syntax
 inc r14
 mov edi,NEBOC_TOKEN_DOT
 call buffer_kind_is
 test eax,eax
 jz .syntax
 inc r14
 mov edi,NEBOC_TOKEN_IDENTIFIER
 call buffer_kind_is
 test eax,eax
 jz .syntax
 mov [r12+NEBOC_BUFFER_NAME_TOKEN_OFFSET],r14
 inc r14
 mov edi,NEBOC_TOKEN_SEMICOLON
 call buffer_kind_is
 test eax,eax
 jz .syntax
 mov [r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET],r15
 mov qword [r12+NEBOC_BUFFER_PLAN_BUFFER_CAPACITY_OFFSET],4
 mov qword [r12+NEBOC_BUFFER_STORAGE_OFFSET],0
 mov qword [r12+NEBOC_BUFFER_RESERVED_OFFSET],0
 mov qword [r12+NEBOC_BUFFER_STATE_OFFSET],NEBOC_BUFFER_STATE_LIVE
 inc r14
 xor eax,eax
 ret
.length_range:
 mov esi,NEBOC_BUFFER_DIAG_LENGTH_RANGE
 jmp buffer_error
.transport:
 mov esi,NEBOC_BUFFER_DIAG_FUNCTION_TRANSPORT
 jmp buffer_error
.syntax:
 mov esi,NEBOC_BUFFER_DIAG_INTERNAL
 jmp buffer_error

; Parse an unsigned Int literal at R14. ESI is the wrong-type diagnostic and
; EBP the dynamic-literal diagnostic. The value is returned in R15.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_parse_unsigned_literal:
 mov rax,r14
 call buffer_token_ptr
 test rax,rax
 jz .type
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 je .literal
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .dynamic
.type:
 jmp buffer_error
.dynamic:
 mov esi,ebp
 jmp buffer_error
.literal:
 mov r15,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 xor eax,eax
 ret

; Parse and evaluate the capacity-4 F09 operation ladder in source order.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
buffer_parse_operations:
.scan:
 cmp r14,[r12+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .done
 mov rax,r14
 mov rbx,[r12+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 call buffer_token_equal
 test eax,eax
 jnz .buffer_owner
 cmp qword [r12+NEBOC_SLICE_VIEW_COUNT_OFFSET],0
 je .next
 mov rax,r14
 mov rbx,[r12+NEBOC_SLICE_NAME_TOKEN_OFFSET]
 call buffer_token_equal
 test eax,eax
 jnz .slice_owner
 jmp .next
.buffer_owner:
 cmp qword [r12+NEBOC_BUFFER_STATE_OFFSET],NEBOC_BUFFER_STATE_LIVE
 jne .copy_move
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 mov rax,r14
 add rax,2
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_KW_RETURN
 je .escape
 mov rax,r14
 add rax,2
 lea rsi,[rel n_length]
 mov edx,n_length_len
 call buffer_token_match
 test eax,eax
 jnz .length
 mov rax,r14
 add rax,2
 lea rsi,[rel n_capacity]
 mov edx,n_capacity_len
 call buffer_token_match
 test eax,eax
 jnz .capacity
 mov rax,r14
 add rax,2
 lea rsi,[rel n_drop]
 mov edx,n_drop_len
 call buffer_token_match
 test eax,eax
 jnz .drop
 mov rax,r14
 add rax,2
 lea rsi,[rel n_copy]
 mov edx,n_copy_len
 call buffer_token_match
 test eax,eax
 jnz .copy_move
 mov rax,r14
 add rax,2
 lea rsi,[rel n_move]
 mov edx,n_move_len
 call buffer_token_match
 test eax,eax
 jnz .copy_move
 mov rax,r14
 add rax,2
 lea rsi,[rel n_clone]
 mov edx,n_clone_len
 call buffer_token_match
 test eax,eax
 jnz .copy_move
 mov rax,r14
 add rax,2
 lea rsi,[rel n_at]
 mov edx,n_at_len
 call buffer_token_match
 test eax,eax
 jnz .at
 mov rax,r14
 add rax,2
 lea rsi,[rel n_get]
 mov edx,n_get_len
 call buffer_token_match
 test eax,eax
 jnz .get
 mov rax,r14
 add rax,2
 lea rsi,[rel n_set]
 mov edx,n_set_len
 call buffer_token_match
 test eax,eax
 jnz .set
 mov rax,r14
 add rax,2
 lea rsi,[rel n_push]
 mov edx,n_push_len
 call buffer_token_match
 test eax,eax
 jnz .push
 mov rax,r14
 add rax,2
 lea rsi,[rel n_clear]
 mov edx,n_clear_len
 call buffer_token_match
 test eax,eax
 jnz .clear
 mov rax,r14
 add rax,2
 lea rsi,[rel n_borrow_shared]
 mov edx,n_borrow_shared_len
 call buffer_token_match
 test eax,eax
 jnz .borrow_shared
 mov rax,r14
 add rax,2
 lea rsi,[rel n_reserve]
 mov edx,n_reserve_len
 call buffer_token_match
 test eax,eax
 jnz .reserve
 mov rax,r14
 add rax,2
 lea rsi,[rel n_grow]
 mov edx,n_grow_len
 call buffer_token_match
 test eax,eax
 jnz .growth
 mov rax,r14
 add rax,2
 lea rsi,[rel n_extend]
 mov edx,n_extend_len
 call buffer_token_match
 test eax,eax
 jnz .extend
 mov rax,r14
 add rax,2
 lea rsi,[rel n_view]
 mov edx,n_view_len
 call buffer_token_match
 test eax,eax
 jnz .view
 jmp .next
.slice_owner:
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 mov rax,r14
 add rax,2
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_KW_RETURN
 je .slice_escape
 cmp qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_LIVE
 jne .slice_stale
 mov rax,[r12+NEBOC_BUFFER_GENERATION_OFFSET]
 cmp rax,[r12+NEBOC_SLICE_VIEW_GENERATION_OFFSET]
 jne .slice_stale
 mov rax,r14
 add rax,2
 lea rsi,[rel n_length]
 mov edx,n_length_len
 call buffer_token_match
 test eax,eax
 jnz .slice_length
 mov rax,r14
 add rax,2
 lea rsi,[rel n_at]
 mov edx,n_at_len
 call buffer_token_match
 test eax,eax
 jnz .slice_at
 mov rax,r14
 add rax,2
 lea rsi,[rel n_subview]
 mov edx,n_subview_len
 call buffer_token_match
 test eax,eax
 jnz .slice_subview
 mov rax,r14
 add rax,2
 lea rsi,[rel n_sum]
 mov edx,n_sum_len
 call buffer_token_match
 test eax,eax
 jnz .slice_sum
 mov rax,r14
 add rax,2
 lea rsi,[rel n_release]
 mov edx,n_release_len
 call buffer_token_match
 test eax,eax
 jnz .slice_release
 jmp .next
.length:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_QUERY_LENGTH
 mov rax,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 jmp .next
.capacity:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_QUERY_CAPACITY
 mov qword [r12+NEBOC_BUFFER_RESULT_OFFSET],4
 jmp .next
.drop:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_EXPLICIT_DROP
 mov qword [r12+NEBOC_BUFFER_STATE_OFFSET],NEBOC_BUFFER_STATE_DROPPED
 mov qword [r12+NEBOC_BUFFER_DROP_COUNT_OFFSET],1
 jmp .next
.borrow_shared:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SHARED_ALIAS
 inc qword [r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 jmp .next
.view:
 cmp qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_LIVE
 je .slice_mutation_conflict
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .slice_arity
 add r14,4
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 mov r13,r15
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_COMMA
 jne .slice_arity
 add r14,2
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 cmp r13,r15
 ja .slice_bounds
 cmp r15,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 ja .slice_bounds
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .slice_arity
 mov rax,r14
 add rax,2
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .slice_arity
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .slice_arity
 lea rax,[r14+3]
 mov [r12+NEBOC_SLICE_NAME_TOKEN_OFFSET],rax
 sub r15,r13
 mov [r12+NEBOC_SLICE_START_OFFSET],r13
 mov [r12+neboc_buffer_parser_SLICE_LENGTH_OFFSET],r15
 mov rcx,r13
 shl rcx,3
 mov rax,[r12+NEBOC_BUFFER_STORAGE_OFFSET]
 shr rax,cl
 test r15,r15
 jz .view_zero
 cmp r15,4
 jae .view_storage
 mov rcx,r15
 shl rcx,3
 mov rdx,1
 shl rdx,cl
 dec rdx
 and rax,rdx
 jmp .view_storage
.view_zero:
 xor eax,eax
.view_storage:
 mov [r12+NEBOC_SLICE_STORAGE_OFFSET],rax
 mov rax,[r12+NEBOC_BUFFER_GENERATION_OFFSET]
 mov [r12+neboc_buffer_parser_SLICE_OWNER_GENERATION_OFFSET],rax
 mov [r12+NEBOC_SLICE_VIEW_GENERATION_OFFSET],rax
 mov qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_LIVE
 inc qword [r12+NEBOC_SLICE_VIEW_COUNT_OFFSET]
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUBLIC_SLICE
 add r14,3
 jmp .next
.at:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_AT
 inc qword [r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .arity
 add r14,4
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .arity
 cmp r15,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 jae .read_bounds
 call .load_byte
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 jmp .next
.get:
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_GET
 inc qword [r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .arity
 add r14,4
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .arity
 cmp r15,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 jae .get_none
 call .load_byte
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 mov qword [r12+NEBOC_BUFFER_OPTION_TAG_OFFSET],NEBOC_BUFFER_OPTION_SOME
 jmp .next
.get_none:
 mov qword [r12+NEBOC_BUFFER_RESULT_OFFSET],0
 mov qword [r12+NEBOC_BUFFER_OPTION_TAG_OFFSET],NEBOC_BUFFER_OPTION_NONE
 jmp .next
.set:
 cmp qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_LIVE
 je .slice_mutation_conflict
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SHARED_ALIAS
 jnz .alias
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SET | NEBOC_BUFFER_FLAG_MUTATION_F09
 inc qword [r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .arity
 add r14,4
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 mov r13,r15
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_COMMA
 jne .arity
 add r14,2
 mov rax,r14
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_MINUS
 je .byte_below
 mov esi,NEBOC_BUFFER_DIAG_BYTE_ABOVE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 cmp r15,255
 ja .byte_above
 mov rbx,r15
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .arity
 cmp r13,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 jae .write_bounds
 mov r15,r13
 call .load_byte
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 mov rcx,r13
 shl rcx,3
 mov rax,255
 shl rax,cl
 not rax
 and [r12+NEBOC_BUFFER_STORAGE_OFFSET],rax
 mov rax,rbx
 shl rax,cl
 or [r12+NEBOC_BUFFER_STORAGE_OFFSET],rax
 call .mutated
 jmp .next
.push:
 cmp qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_LIVE
 je .slice_mutation_conflict
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SHARED_ALIAS
 jnz .alias
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PUSH | NEBOC_BUFFER_FLAG_MUTATION_F09
 inc qword [r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .arity
 add r14,4
 mov rax,r14
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_MINUS
 je .byte_below
 mov esi,NEBOC_BUFFER_DIAG_BYTE_ABOVE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 cmp r15,255
 ja .byte_above
 mov rbx,r15
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .arity
 mov rcx,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 cmp rcx,4
 jae .push_full
 shl rcx,3
 mov rax,rbx
 shl rax,cl
 or [r12+NEBOC_BUFFER_STORAGE_OFFSET],rax
 inc qword [r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 mov rax,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 mov qword [r12+NEBOC_BUFFER_RESULT_TAG_OFFSET],NEBOC_BUFFER_RESULT_OK
 call .mutated
 jmp .next
.push_full:
 mov qword [r12+NEBOC_BUFFER_RESULT_OFFSET],1
 mov qword [r12+NEBOC_BUFFER_RESULT_TAG_OFFSET],NEBOC_BUFFER_RESULT_ERR
 jmp .next
.clear:
 cmp qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_LIVE
 je .slice_mutation_conflict
 test qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SHARED_ALIAS
 jnz .alias
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_CLEAR | NEBOC_BUFFER_FLAG_MUTATION_F09
 inc qword [r12+NEBOC_BUFFER_OPERATION_COUNT_OFFSET]
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .arity
 mov rax,r14
 add rax,4
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .arity
 mov rax,[r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET]
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 mov qword [r12+NEBOC_BUFFER_PLAN_BUFFER_LENGTH_OFFSET],0
 mov qword [r12+NEBOC_BUFFER_STORAGE_OFFSET],0
 call .mutated
 jmp .next
.slice_length:
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .slice_arity
 mov rax,r14
 add rax,4
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .slice_arity
 mov rax,[r12+neboc_buffer_parser_SLICE_LENGTH_OFFSET]
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 jmp .next
.slice_at:
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .slice_arity
 add r14,4
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .slice_arity
 cmp r15,[r12+neboc_buffer_parser_SLICE_LENGTH_OFFSET]
 jae .slice_bounds
 mov rcx,r15
 shl rcx,3
 mov rax,[r12+NEBOC_SLICE_STORAGE_OFFSET]
 shr rax,cl
 and eax,255
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SLICE_READ
 jmp .next
.slice_subview:
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .slice_arity
 add r14,4
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 mov r13,r15
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_COMMA
 jne .slice_arity
 add r14,2
 mov esi,NEBOC_BUFFER_DIAG_INDEX_TYPE
 mov ebp,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 call buffer_parse_unsigned_literal
 test eax,eax
 jnz .return_status
 cmp r13,r15
 ja .slice_bounds
 cmp r15,[r12+neboc_buffer_parser_SLICE_LENGTH_OFFSET]
 ja .slice_bounds
 mov rax,r14
 inc rax
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .slice_arity
 mov rax,r14
 add rax,2
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .slice_arity
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .slice_arity
 mov rcx,r13
 shl rcx,3
 mov rax,[r12+NEBOC_SLICE_STORAGE_OFFSET]
 shr rax,cl
 sub r15,r13
 test r15,r15
 jz .subview_zero
 cmp r15,4
 jae .subview_storage
 mov rcx,r15
 shl rcx,3
 mov rdx,1
 shl rdx,cl
 dec rdx
 and rax,rdx
 jmp .subview_storage
.subview_zero:
 xor eax,eax
.subview_storage:
 add [r12+NEBOC_SLICE_START_OFFSET],r13
 mov [r12+neboc_buffer_parser_SLICE_LENGTH_OFFSET],r15
 mov [r12+NEBOC_SLICE_STORAGE_OFFSET],rax
 lea rax,[r14+3]
 mov [r12+NEBOC_SLICE_NAME_TOKEN_OFFSET],rax
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],r15
 inc qword [r12+NEBOC_SLICE_VIEW_COUNT_OFFSET]
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SLICE_SUBVIEW
 add r14,3
 jmp .next
.slice_sum:
 xor eax,eax
 xor ecx,ecx
 mov rdx,[r12+NEBOC_SLICE_STORAGE_OFFSET]
.slice_sum_loop:
 cmp rcx,[r12+neboc_buffer_parser_SLICE_LENGTH_OFFSET]
 jae .slice_sum_done
 movzx r8d,dl
 add rax,r8
 shr rdx,8
 inc rcx
 jmp .slice_sum_loop
.slice_sum_done:
 mov [r12+NEBOC_BUFFER_RESULT_OFFSET],rax
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SLICE_ITERATE
 jmp .next
.slice_release:
 mov rax,r14
 add rax,3
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .slice_arity
 mov rax,r14
 add rax,4
 call buffer_token_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .slice_arity
 mov qword [r12+NEBOC_SLICE_STATE_OFFSET],NEBOC_SLICE_STATE_RELEASED
 inc qword [r12+NEBOC_SLICE_RELEASE_COUNT_OFFSET]
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_SLICE_RELEASE
 jmp .next
%undef call
.load_byte:
 mov rcx,r15
 shl rcx,3
 mov rax,[r12+NEBOC_BUFFER_STORAGE_OFFSET]
 shr rax,cl
 and eax,255
 ret
.mutated:
 inc qword [r12+NEBOC_BUFFER_GENERATION_OFFSET]
 inc qword [r12+NEBOC_BUFFER_MUTATION_COUNT_OFFSET]
 ret
.byte_below:
 mov esi,NEBOC_BUFFER_DIAG_BYTE_BELOW
 jmp buffer_error
.byte_above:
 mov esi,NEBOC_BUFFER_DIAG_BYTE_ABOVE
 jmp buffer_error
.read_bounds:
 mov esi,NEBOC_BUFFER_DIAG_READ_BOUNDS
 jmp buffer_error
.write_bounds:
 mov esi,NEBOC_BUFFER_DIAG_WRITE_BOUNDS
 jmp buffer_error
.arity:
 mov esi,NEBOC_BUFFER_DIAG_ARITY
 jmp buffer_error
.alias:
 mov esi,NEBOC_BUFFER_DIAG_ALIAS
 jmp buffer_error
.reserve:
 mov esi,NEBOC_BUFFER_DIAG_RESERVE
 jmp buffer_error
.growth:
 mov esi,NEBOC_BUFFER_DIAG_GROWTH
 jmp buffer_error
.extend:
 mov esi,NEBOC_BUFFER_DIAG_EXTEND
 jmp buffer_error
.slice_bounds:
 mov esi,NEBOC_BUFFER_DIAG_SLICE_BOUNDS
 jmp buffer_error
.slice_escape:
 mov esi,NEBOC_BUFFER_DIAG_SLICE_ESCAPE
 jmp buffer_error
.slice_mutation_conflict:
 mov esi,NEBOC_BUFFER_DIAG_SLICE_MUTATION_CONFLICT
 jmp buffer_error
.slice_stale:
 mov esi,NEBOC_BUFFER_DIAG_SLICE_STALE
 jmp buffer_error
.slice_arity:
 mov esi,NEBOC_BUFFER_DIAG_SLICE_ARITY
 jmp buffer_error
.return_status:
 ret
.escape:
 mov esi,NEBOC_BUFFER_DIAG_ESCAPE
 jmp buffer_error
.copy_move:
 mov esi,NEBOC_BUFFER_DIAG_COPY_MOVE
 jmp buffer_error
.next:
 inc r14
 jmp .scan
.done:
 xor eax,eax
 ret

NEBOC_ABI_FUNCTION neboc_buffer_parse
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov qword [r12+NEBOC_BUFFER_FOUND_OFFSET],0
 mov qword [r12+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],0
 xor r14d,r14d
.find:
 cmp r14,[r12+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .not_found
 mov rax,r14
 lea rsi,[rel n_buffer]
 mov edx,n_buffer_len
 call buffer_token_match
 test eax,eax
 jnz .found
 inc r14
 jmp .find
.found:
 mov qword [r12+NEBOC_BUFFER_FOUND_OFFSET],1
 call buffer_parse_constructor
 test eax,eax
 jnz .done
 call buffer_parse_operations
 test eax,eax
 jnz .done
 or qword [r12+NEBOC_BUFFER_FLAGS_OFFSET],NEBOC_BUFFER_FLAG_PARSED
 xor eax,eax
 jmp .done
.not_found:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
