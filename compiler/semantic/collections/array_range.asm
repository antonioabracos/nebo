; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F03 structural bounded parser/typechecker for Array<T,N>/Range<Int>.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/semantic/collections/slice_view.inc"

extern neboc_slice_create
extern neboc_slice_subslice
extern neboc_slice_view_validate
extern neboc_slice_read
extern neboc_slice_sum
extern neboc_slice_release
extern neboc_slice_mutation_probe
extern neboc_slice_cleanup

section .rodata
n_array: db "Array"
n_array_len equ $-n_array
n_range: db "Range"
n_range_len equ $-n_range
n_int: db "Int"
n_int_len equ $-n_int
n_bool: db "Bool"
n_bool_len equ $-n_bool
n_char: db "Char"
n_char_len equ $-n_char
n_filled: db "filled"
n_filled_len equ $-n_filled
n_exclusive: db "exclusive"
n_exclusive_len equ $-n_exclusive
n_inclusive: db "inclusive"
n_inclusive_len equ $-n_inclusive
n_step_by: db "stepBy"
n_step_by_len equ $-n_step_by
n_at: db "at"
n_at_len equ $-n_at
n_length: db "length"
n_length_len equ $-n_length
n_contains: db "contains"
n_contains_len equ $-n_contains
n_as_slice: db "asSlice"
n_as_slice_len equ $-n_as_slice
n_subslice: db "subslice"
n_subslice_len equ $-n_subslice
n_sum: db "sum"
n_sum_len equ $-n_sum
n_release: db "release"
n_release_len equ $-n_release
n_mutate: db "mutate"
n_mutate_len equ $-n_mutate
n_in: db "in"
n_in_len equ $-n_in

section .text

NEBOC_ABI_FUNCTION neboc_array_range_recognize
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 lea rdi,[r12+NEBOC_AR_FOUND_OFFSET]
 mov ecx,15
 xor eax,eax
 rep stosq
 mov r13,[r12+NEBOC_AR_TOKENS_OFFSET]
 test r13,r13
 jz .invalid
 mov r14,[r12+NEBOC_AR_TOKEN_COUNT_OFFSET]
 test r14,r14
 jz .invalid
 mov rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_AR_BINDING_CAPACITY_OFFSET],NEBOC_AR_MAX_BINDINGS
 jb .invalid
 mov rax,[r12+NEBOC_AR_VALUES_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_AR_VALUE_CAPACITY_OFFSET],NEBOC_AR_MAX_VALUES
 jb .invalid
 mov rdi,[r12+NEBOC_AR_BINDINGS_OFFSET]
 mov ecx,(NEBOC_AR_MAX_BINDINGS*NEBOC_AR_BIND_SIZE)/8
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_AR_VALUES_OFFSET]
 mov ecx,NEBOC_AR_MAX_VALUES
 xor eax,eax
 rep stosq
 mov qword [r12+NEBOC_AR_LOOP_COUNT_OFFSET],0
 mov qword [r12+NEBOC_AR_ITERATION_COUNT_OFFSET],0
 mov qword [r12+NEBOC_AR_FOR_DEPTH_OFFSET],0
 mov qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],0
 mov rdi,[r12+NEBOC_AR_LOOPS_OFFSET]
 test rdi,rdi
 jz .invalid
 cmp qword [r12+NEBOC_AR_LOOP_CAPACITY_OFFSET],NEBOC_FOR_MAX_LOOPS
 jb .invalid
 mov ecx,(NEBOC_FOR_MAX_LOOPS*NEBOC_FOR_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 ; Claim only structural Array<...> or Range.<constructor> tokens. Historical
 ; colecoes_primitivas exact profiles run first in the driver and remain authoritative.
 xor ebx,ebx
.claim_scan:
 cmp rbx,r14
 jae .not_owned
 mov rax,rbx
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .claim_next
 mov rdi,rbx
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call ar_token_match
 test eax,eax
 jz .claim_range
 lea rax,[rbx+1]
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_LESS
 jne .claim_range
 lea rax,[rbx+2]
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .claim_range
 lea rax,[rbx+3]
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_COMMA
 jne .claim_range
 lea rax,[rbx+5]
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_GREATER
 jne .claim_range
 lea rax,[rbx+6]
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_RESERVED_LBRACKET
 je .claimed
 cmp rax,NEBOC_TOKEN_DOT
 jne .claim_range
 lea rdi,[rbx+7]
 lea rsi,[rel n_filled]
 mov edx,n_filled_len
 call ar_token_match
 test eax,eax
 jnz .claimed
.claim_range:
 mov rdi,rbx
 lea rsi,[rel n_range]
 mov edx,n_range_len
 call ar_token_match
 test eax,eax
 jz .claim_next
 lea rax,[rbx+1]
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 je .claimed
.claim_next:
 inc rbx
 jmp .claim_scan
.claimed:
 mov qword [r12+NEBOC_AR_FOUND_OFFSET],1
 mov qword [r12+NEBOC_AR_CURSOR_OFFSET],0
 mov edi,NEBOC_TOKEN_KW_START
 call ar_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call ar_expect
 test eax,eax
 jnz .done
.statement:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_RBRACE
 je .finish
 cmp rax,NEBOC_TOKEN_EOF
 je .syntax
 cmp rax,NEBOC_TOKEN_KW_FOR
 je .for_statement
 call ar_parse_statement
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ar_expect
 test eax,eax
 jnz .done
 jmp .statement
.for_statement:
 call ar_parse_for
 test eax,eax
 jnz .done
 jmp .statement
.finish:
 mov edi,NEBOC_TOKEN_RBRACE
 call ar_expect
 test eax,eax
 jnz .done
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 jne .syntax
 mov rdi,r12
 call neboc_slice_cleanup
 test eax,eax
 jnz .done
 call ar_semantic_hash
 mov [r12+NEBOC_AR_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.syntax:
 mov esi,NEBOC_AR_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Parse the F07 canonical `for item in collection { action }` form.  The
; bounded body surface is intentionally structural: empty, break, continue,
; iterator return, or one nested for.  It is sufficient to prove the CFG and
; native iterator mechanics without admitting general collection mutation.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
ar_parse_for:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,64
 mov qword [rsp+24],0
 mov rbx,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 cmp rbx,[r12+NEBOC_AR_LOOP_CAPACITY_OFFSET]
 jae .nesting
 cmp qword [r12+NEBOC_AR_FOR_DEPTH_OFFSET],NEBOC_FOR_MAX_LOOPS
 jae .nesting
 mov r13,rbx
 imul r13,NEBOC_FOR_RECORD_SIZE
 add r13,[r12+NEBOC_AR_LOOPS_OFFSET]
 mov rdi,r13
 mov ecx,NEBOC_FOR_RECORD_QWORDS
 xor eax,eax
 rep stosq
 mov [r13+NEBOC_FOR_ID_OFFSET],rbx
 mov rax,[r12+NEBOC_AR_FOR_DEPTH_OFFSET]
 mov [r13+NEBOC_FOR_DEPTH_OFFSET],rax
 mov qword [r13+NEBOC_FOR_CHILD_INDEX_OFFSET],-1
 inc qword [r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 mov edi,NEBOC_TOKEN_KW_FOR
 call ar_expect
 test eax,eax
 jnz .syntax_override
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov [rsp],rax
 mov [r13+NEBOC_FOR_ITEM_TOKEN_OFFSET],rax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_in]
 mov edx,n_in_len
 call ar_token_match
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .type
 mov r15,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rdi,r15
 call ar_find_binding
 test rax,rax
 jz .type
 mov r14,rax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov rax,r14
 sub rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 jc .internal
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .internal
 mov [r13+NEBOC_FOR_COLLECTION_INDEX_OFFSET],rax
 mov rax,[r14+NEBOC_AR_BIND_KIND_OFFSET]
 mov [r13+NEBOC_FOR_KIND_OFFSET],rax
 mov rax,[r14+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 mov [r13+NEBOC_FOR_DATA_INDEX_OFFSET],rax
 mov rax,[r14+NEBOC_AR_BIND_FLAGS_OFFSET]
 mov [r13+NEBOC_FOR_FLAGS_OFFSET],rax
 mov rax,[r14+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rax,NEBOC_AR_KIND_RANGE
 je .range
 cmp rax,NEBOC_AR_KIND_ARRAY
 je .array
 cmp rax,NEBOC_AR_KIND_SLICE
 je .slice
 jmp .type
.range:
 mov rax,[r14+NEBOC_AR_BIND_START_OFFSET]
 mov [r13+NEBOC_FOR_START_OFFSET],rax
 mov rax,[r14+NEBOC_AR_BIND_STEP_OFFSET]
 mov [r13+NEBOC_FOR_STEP_OFFSET],rax
 mov rdi,r14
 call ar_range_length
 test edx,edx
 jnz .fail
 jmp .count_ready
.array:
 mov qword [r13+NEBOC_FOR_START_OFFSET],0
 mov qword [r13+NEBOC_FOR_STEP_OFFSET],1
 mov rax,[r14+NEBOC_AR_BIND_COUNT_OFFSET]
 jmp .count_ready
.slice:
 mov rdi,r12
 mov rsi,r14
 call neboc_slice_view_validate
 test eax,eax
 jnz .fail
 mov qword [r13+NEBOC_FOR_START_OFFSET],0
 mov qword [r13+NEBOC_FOR_STEP_OFFSET],1
 mov rax,[r14+NEBOC_AR_BIND_COUNT_OFFSET]
.count_ready:
 cmp rax,NEBOC_FOR_MAX_ITERATIONS
 ja .overflow
 mov [r13+NEBOC_FOR_COUNT_OFFSET],rax
 mov rcx,[r12+NEBOC_AR_ITERATION_COUNT_OFFSET]
 add rcx,rax
 jc .overflow
 mov [r12+NEBOC_AR_ITERATION_COUNT_OFFSET],rcx
 mov edi,NEBOC_TOKEN_LBRACE
 call ar_expect
 test eax,eax
 jnz .syntax_override
 inc qword [r12+NEBOC_AR_FOR_DEPTH_OFFSET]
 mov qword [rsp+24],1
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_RBRACE
 je .body_done
 cmp rax,NEBOC_TOKEN_KW_BREAK
 je .break
 cmp rax,NEBOC_TOKEN_KW_CONTINUE
 je .continue
 cmp rax,NEBOC_TOKEN_KW_FOR
 je .nested
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .mutation_or_syntax
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rsi,[rsp]
 call ar_name_equal
 test eax,eax
 jz .mutation_or_syntax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call ar_expect
 test eax,eax
 jnz .syntax_override
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_KW_RETURN
 jne .syntax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ar_expect
 test eax,eax
 jnz .syntax_override
 mov qword [r13+NEBOC_FOR_ACTION_OFFSET],NEBOC_FOR_ACTION_RETURN_ITEM
 jmp .body_done
.break:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ar_expect
 test eax,eax
 jnz .syntax_override
 mov qword [r13+NEBOC_FOR_ACTION_OFFSET],NEBOC_FOR_ACTION_BREAK
 jmp .body_done
.continue:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ar_expect
 test eax,eax
 jnz .syntax_override
 mov qword [r13+NEBOC_FOR_ACTION_OFFSET],NEBOC_FOR_ACTION_CONTINUE
 jmp .body_done
.nested:
 mov rax,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 mov [r13+NEBOC_FOR_CHILD_INDEX_OFFSET],rax
 mov qword [r13+NEBOC_FOR_ACTION_OFFSET],NEBOC_FOR_ACTION_NESTED
 call ar_parse_for
 test eax,eax
 jnz .fail
 jmp .body_done
.mutation_or_syntax:
 ; A collection operation in the body is classified separately from malformed
 ; control syntax so the excluded mutation surface remains auditable.
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_find_binding
 test rax,rax
 jz .syntax
 mov rsi,NEBOC_AR_DIAG_FOR_MUTATION
 jmp .publish
.body_done:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .syntax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 dec qword [r12+NEBOC_AR_FOR_DEPTH_OFFSET]
 mov qword [rsp+24],0
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.type:
 mov esi,NEBOC_AR_DIAG_FOR_TYPE
 jmp .error
.overflow:
 mov esi,NEBOC_AR_DIAG_FOR_OVERFLOW
 jmp .error
.nesting:
 mov esi,NEBOC_AR_DIAG_FOR_NESTING
 jmp .error
.syntax_override:
.syntax:
 mov esi,NEBOC_AR_DIAG_FOR_SYNTAX
.error:
.publish:
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 jmp .fail
.internal:
 mov esi,NEBOC_AR_DIAG_INTERNAL
 jmp .error
.fail:
 cmp qword [rsp+24],0
 je .failed
 dec qword [r12+NEBOC_AR_FOR_DEPTH_OFFSET]
.failed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse one constructor/binding operation or one access expression.
%undef call
ar_parse_statement:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 xor r15d,r15d
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call ar_token_match
 test eax,eax
 jnz .array
 mov rdi,r14
 lea rsi,[rel n_range]
 mov edx,n_range_len
 call ar_token_match
 test eax,eax
 jnz .range
 mov rdi,r14
 call ar_find_binding
 test rax,rax
 jz .syntax
 mov r13,rax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .suffix
.array:
 call ar_parse_array
 test rax,rax
 jz .fail
 mov r13,rax
 jmp .suffix
.range:
 call ar_parse_range
 test rax,rax
 jz .fail
 mov r13,rax
.suffix:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_DOT
 jne .complete
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_KW_RETURN
 je .terminal_return
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_step_by]
 mov edx,n_step_by_len
 call ar_token_match
 test eax,eax
 jnz .step_by
 mov rdi,r14
 lea rsi,[rel n_at]
 mov edx,n_at_len
 call ar_token_match
 test eax,eax
 jnz .at
 mov rdi,r14
 lea rsi,[rel n_length]
 mov edx,n_length_len
 call ar_token_match
 test eax,eax
 jnz .length
 mov rdi,r14
 lea rsi,[rel n_contains]
 mov edx,n_contains_len
 call ar_token_match
 test eax,eax
 jnz .contains
 mov rdi,r14
 lea rsi,[rel n_as_slice]
 mov edx,n_as_slice_len
 call ar_token_match
 test eax,eax
 jnz .as_slice
 mov rdi,r14
 lea rsi,[rel n_subslice]
 mov edx,n_subslice_len
 call ar_token_match
 test eax,eax
 jnz .subslice
 mov rdi,r14
 lea rsi,[rel n_sum]
 mov edx,n_sum_len
 call ar_token_match
 test eax,eax
 jnz .sum
 mov rdi,r14
 lea rsi,[rel n_release]
 mov edx,n_release_len
 call ar_token_match
 test eax,eax
 jnz .release
 mov rdi,r14
 lea rsi,[rel n_mutate]
 mov edx,n_mutate_len
 call ar_token_match
 test eax,eax
 jnz .mutate
 ; Any other identifier is the language's one-shot `.name` binding terminal.
 cmp qword [r13+NEBOC_AR_BIND_NAME_OFFSET],NEBOC_AR_UNBOUND_NAME
 jne .syntax
 mov rdi,r14
 call ar_find_binding
 test rax,rax
 jnz .syntax
 mov [r13+NEBOC_AR_BIND_NAME_OFFSET],r14
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .suffix
.step_by:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 jne .type
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_parse_signed_int
 test edx,edx
 jnz .fail
 mov [r13+NEBOC_AR_BIND_STEP_OFFSET],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 jmp .suffix
.at:
 mov rax,[r13+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rax,NEBOC_AR_KIND_ARRAY
 je .at_parse
 cmp rax,NEBOC_AR_KIND_SLICE
 jne .type
.at_parse:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .dynamic
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 je .slice_at
 cmp rbx,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 jae .bounds
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,rbx
 cmp rax,[r12+NEBOC_AR_VALUE_COUNT_OFFSET]
 jae .internal
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 mov rax,[rdx+rax*8]
 mov [r12+NEBOC_AR_RESULT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_AR_RESULT_TYPE_OFFSET],rax
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 jmp .suffix
.slice_at:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 mov rcx,rsp
 call neboc_slice_read
 test eax,eax
 jnz .fail
 mov rax,[rsp]
 mov [r12+NEBOC_AR_RESULT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_AR_RESULT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.length:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_expect_empty_call
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .array_length
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 je .slice_length
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 jne .type
 mov rdi,r13
 call ar_range_length
 test edx,edx
 jnz .fail
 jmp .store_length
.array_length:
 mov rax,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 jmp .store_length
.slice_length:
 mov rdi,r12
 mov rsi,r13
 call neboc_slice_view_validate
 test eax,eax
 jnz .fail
 mov rax,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 mov r15d,1
.store_length:
 mov qword [r12+NEBOC_AR_RESULT_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 mov [r12+NEBOC_AR_RESULT_VALUE_OFFSET],rax
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 jmp .suffix
.contains:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 jne .type
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_parse_signed_int
 test edx,edx
 jnz .fail
 mov rbx,rax
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 mov rdi,r13
 call ar_range_length
 test edx,edx
 jnz .fail
 mov rdi,r13
 mov rsi,rbx
 call ar_range_contains
 mov qword [r12+NEBOC_AR_RESULT_TYPE_OFFSET],NEBOC_AR_TYPE_BOOL
 mov [r12+NEBOC_AR_RESULT_VALUE_OFFSET],rax
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 jmp .suffix
.as_slice:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .type
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_expect_empty_call
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 mov rdx,rsp
 call neboc_slice_create
 test eax,eax
 jnz .fail
 mov r13,[rsp]
 test r13,r13
 jz .internal
 jmp .suffix
.subslice:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .type
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .dynamic
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_COMMA
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .dynamic
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov r15,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 mov rcx,r15
 mov r8,rsp
 call neboc_slice_subslice
 test eax,eax
 jnz .fail
 mov r13,[rsp]
 test r13,r13
 jz .internal
 xor r15d,r15d
 jmp .suffix
.sum:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .type
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_expect_empty_call
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 mov rdx,rsp
 call neboc_slice_sum
 test eax,eax
 jnz .fail
 mov rax,[rsp]
 mov qword [r12+NEBOC_AR_RESULT_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 mov [r12+NEBOC_AR_RESULT_VALUE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.release:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .type
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_expect_empty_call
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 call neboc_slice_release
 test eax,eax
 jnz .fail
 mov qword [r12+NEBOC_AR_RESULT_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 mov qword [r12+NEBOC_AR_RESULT_VALUE_OFFSET],0
 jmp .suffix
.mutate:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .type
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 mov rdi,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 call ar_parse_scalar_value
 test edx,edx
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 call neboc_slice_mutation_probe
 jmp .fail
.terminal_return:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .return_ok
 test r15d,r15d
 jz .escape
.return_ok:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .suffix
.escape:
 mov esi,NEBOC_AR_DIAG_SLICE_ESCAPE
 jmp .error
.complete:
 ; A range is invalid even if only bound; validation cannot be deferred.
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 jne .record_layout
 mov rdi,r13
 call ar_range_length
 test edx,edx
 jnz .fail
.record_layout:
 mov rax,[r13+NEBOC_AR_BIND_SIZE_OFFSET]
 mov [r12+NEBOC_AR_LAYOUT_SIZE_OFFSET],rax
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 je .range_align
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 je .range_align
 mov rax,[r13+NEBOC_AR_BIND_FLAGS_OFFSET]
 mov [r12+NEBOC_AR_LAYOUT_ALIGN_OFFSET],rax
 jmp .layout_done
.range_align:
 mov qword [r12+NEBOC_AR_LAYOUT_ALIGN_OFFSET],8
.layout_done:
 xor eax,eax
 jmp .done
.dynamic:
 mov esi,NEBOC_AR_DIAG_DYNAMIC_INDEX
 jmp .error
.bounds:
 mov esi,NEBOC_AR_DIAG_BOUNDS
 jmp .error
.type:
 mov esi,NEBOC_AR_DIAG_TYPE
 jmp .error
.syntax:
 mov esi,NEBOC_AR_DIAG_SYNTAX
 jmp .error
.internal:
 mov esi,NEBOC_AR_DIAG_INTERNAL
.error:
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
.fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse Array<scalar,N> followed by a literal or `.filled(value)`.
ar_parse_array:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_parse_scalar_type
 test eax,eax
 jz .fail
 mov [rsp],rax
 mov [rsp+8],rdx
 mov edi,NEBOC_TOKEN_COMMA
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .const_length
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rbx,NEBOC_AR_MAX_LENGTH
 ja .const_length
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_alloc_binding
 test rax,rax
 jz .fail
 mov r13,rax
 mov qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 mov rax,[rsp]
 mov [r13+NEBOC_AR_BIND_TYPE_OFFSET],rax
 mov [r13+NEBOC_AR_BIND_COUNT_OFFSET],rbx
 mov rax,[rsp+8]
 mov [r13+NEBOC_AR_BIND_STRIDE_OFFSET],rax
 mov [r13+NEBOC_AR_BIND_FLAGS_OFFSET],rax
 mul rbx
 test rdx,rdx
 jnz .const_length
 cmp rax,NEBOC_AR_MAX_LAYOUT
 ja .const_length
 mov [r13+NEBOC_AR_BIND_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_AR_VALUE_COUNT_OFFSET]
 mov [r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET],rax
 mov rdx,rax
 add rdx,rbx
 jc .const_length
 cmp rdx,[r12+NEBOC_AR_VALUE_CAPACITY_OFFSET]
 ja .const_length
 mov [rsp+16],rdx
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_RESERVED_LBRACKET
 je .literal
 cmp rax,NEBOC_TOKEN_DOT
 jne .syntax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov r14,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_filled]
 mov edx,n_filled_len
 call ar_token_match
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 mov rdi,[rsp]
 call ar_parse_scalar_value
 test edx,edx
 jnz .fail
 mov r15,rax
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 xor r14d,r14d
.fill_loop:
 cmp r14,rbx
 jae .constructed
 mov rax,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rax,r14
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 mov [rdx+rax*8],r15
 inc r14
 jmp .fill_loop
.literal:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 xor r14d,r14d
.literal_item:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .literal_done
 cmp r14,rbx
 jae .arity
 mov rdi,[rsp]
 call ar_parse_scalar_value
 test edx,edx
 jnz .fail
 mov rcx,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 add rcx,r14
 mov rdx,[r12+NEBOC_AR_VALUES_OFFSET]
 mov [rdx+rcx*8],rax
 inc r14
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_COMMA
 jne .literal_item
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .literal_item
.literal_done:
 cmp r14,rbx
 jne .arity
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
.constructed:
 mov rax,[rsp+16]
 mov [r12+NEBOC_AR_VALUE_COUNT_OFFSET],rax
 inc qword [r12+NEBOC_AR_ARRAY_COUNT_OFFSET]
 inc qword [r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 mov rdi,r13
 call ar_hash_binding
 mov [r13+NEBOC_AR_BIND_HASH_OFFSET],rax
 mov rax,r13
 jmp .done
.const_length:
 mov esi,NEBOC_AR_DIAG_CONST_LENGTH
 jmp .error
.arity:
 mov esi,NEBOC_AR_DIAG_ARITY
 jmp .error
.syntax:
 mov esi,NEBOC_AR_DIAG_SYNTAX
.error:
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
.fail:
 xor eax,eax
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse Range.exclusive/inclusive(start,end), with stepBy handled as a suffix.
ar_parse_range:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call ar_expect
 test eax,eax
 jnz .fail
 mov r14,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_exclusive]
 mov edx,n_exclusive_len
 call ar_token_match
 test eax,eax
 jnz .exclusive
 mov rdi,r14
 lea rsi,[rel n_inclusive]
 mov edx,n_inclusive_len
 call ar_token_match
 test eax,eax
 jz .syntax
 mov qword [rsp+16],NEBOC_AR_RANGE_INCLUSIVE
 jmp .constructor
.exclusive:
 mov qword [rsp+16],0
.constructor:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_parse_signed_int
 test edx,edx
 jnz .fail
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_COMMA
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_parse_signed_int
 test edx,edx
 jnz .fail
 mov [rsp+8],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_alloc_binding
 test rax,rax
 jz .fail
 mov r13,rax
 mov qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_RANGE
 mov qword [r13+NEBOC_AR_BIND_TYPE_OFFSET],NEBOC_AR_TYPE_RANGE_INT
 mov qword [r13+NEBOC_AR_BIND_COUNT_OFFSET],4
 mov qword [r13+NEBOC_AR_BIND_STRIDE_OFFSET],8
 mov qword [r13+NEBOC_AR_BIND_SIZE_OFFSET],32
 mov rax,[rsp]
 mov [r13+NEBOC_AR_BIND_START_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_AR_BIND_END_OFFSET],rax
 mov qword [r13+NEBOC_AR_BIND_STEP_OFFSET],1
 mov rax,[rsp+16]
 mov [r13+NEBOC_AR_BIND_FLAGS_OFFSET],rax
 inc qword [r12+NEBOC_AR_RANGE_COUNT_OFFSET]
 inc qword [r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 mov rdi,r13
 call ar_hash_binding
 mov [r13+NEBOC_AR_BIND_HASH_OFFSET],rax
 mov rax,r13
 jmp .done
.syntax:
 mov esi,NEBOC_AR_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
.fail:
 xor eax,eax
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Return scalar type in RAX and stride in RDX.
ar_parse_scalar_type:
 push rbx
 sub rsp,16
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .type
 mov rbx,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rdi,rbx
 lea rsi,[rel n_int]
 mov edx,n_int_len
 call ar_token_match
 test eax,eax
 jnz .int
 mov rdi,rbx
 lea rsi,[rel n_bool]
 mov edx,n_bool_len
 call ar_token_match
 test eax,eax
 jnz .bool
 mov rdi,rbx
 lea rsi,[rel n_char]
 mov edx,n_char_len
 call ar_token_match
 test eax,eax
 jnz .char
.type:
 mov esi,NEBOC_AR_DIAG_TYPE
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 xor eax,eax
 xor edx,edx
 jmp .done
.int:
 mov eax,NEBOC_AR_TYPE_INT
 mov edx,8
 jmp .accept
.bool:
 mov eax,NEBOC_AR_TYPE_BOOL
 mov edx,1
 jmp .accept
.char:
 mov eax,NEBOC_AR_TYPE_CHAR
 mov edx,4
.accept:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
.done:
 add rsp,16
 pop rbx
 ret

; RDI expected scalar type; return value RAX, EDX=0 or publish type error.
ar_parse_scalar_value:
 push rbx
 push r13
 sub rsp,8
 mov r13,rdi
 call ar_peek_kind
 cmp r13,NEBOC_AR_TYPE_INT
 je .int
 cmp r13,NEBOC_AR_TYPE_BOOL
 je .bool
 cmp r13,NEBOC_AR_TYPE_CHAR
 je .char
 jmp .type
.int:
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .type
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 jmp .accept
.bool:
 cmp rax,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp rax,NEBOC_TOKEN_KW_FALSE
 jne .type
 xor eax,eax
 jmp .accept
.true:
 mov eax,1
 jmp .accept
.char:
 cmp rax,NEBOC_TOKEN_CHAR
 jne .type
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
.accept:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 xor edx,edx
 jmp .done
.type:
 mov esi,NEBOC_AR_DIAG_TYPE
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 mov edx,1
.done:
 add rsp,8
 pop r13
 pop rbx
 ret

; Return signed Int in RAX, EDX=0. The lexer already bounds positive payloads.
ar_parse_signed_int:
 push rbx
 sub rsp,16
 xor ebx,ebx
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_MINUS
 jne .magnitude
 mov ebx,1
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
.magnitude:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .type
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 test ebx,ebx
 jz .ok
 neg rax
 jo .range
.ok:
 xor edx,edx
 jmp .done
.range:
 mov esi,NEBOC_AR_DIAG_RANGE
 jmp .error
.type:
 mov esi,NEBOC_AR_DIAG_TYPE
.error:
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 mov edx,1
.done:
 add rsp,16
 pop rbx
 ret

; RDI range record -> RAX length, EDX=0. Checked without iteration.
ar_range_length:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rdi
 mov rbx,[r13+NEBOC_AR_BIND_START_OFFSET]
 mov r14,[r13+NEBOC_AR_BIND_END_OFFSET]
 mov r15,[r13+NEBOC_AR_BIND_STEP_OFFSET]
 test r15,r15
 jz .invalid
 cmp rbx,r14
 je .equal
 jl .ascending
 test r15,r15
 jns .invalid
 mov rax,rbx
 sub rax,r14
 jo .invalid
 mov rcx,r15
 neg rcx
 jo .invalid
 jmp .divide
.ascending:
 test r15,r15
 jle .invalid
 mov rax,r14
 sub rax,rbx
 jo .invalid
 mov rcx,r15
.divide:
 xor edx,edx
 div rcx
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jnz .inclusive
 test rdx,rdx
 jz .ok
 inc rax
 jo .invalid
 jmp .ok
.inclusive:
 inc rax
 jo .invalid
 jmp .ok
.equal:
 xor eax,eax
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jz .ok
 inc eax
.ok:
 xor edx,edx
 jmp .done
.invalid:
 mov esi,NEBOC_AR_DIAG_RANGE
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 xor eax,eax
 mov edx,1
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; RDI valid range, RSI candidate -> RAX Bool.
ar_range_contains:
 mov r8,[rdi+NEBOC_AR_BIND_START_OFFSET]
 mov r9,[rdi+NEBOC_AR_BIND_END_OFFSET]
 mov r10,[rdi+NEBOC_AR_BIND_STEP_OFFSET]
 test r10,r10
 js .descending
 cmp rsi,r8
 jl .no
 test qword [rdi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jnz .asc_inc
 cmp rsi,r9
 jge .no
 jmp .distance
.asc_inc:
 cmp rsi,r9
 jg .no
 jmp .distance
.descending:
 cmp rsi,r8
 jg .no
 test qword [rdi+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_RANGE_INCLUSIVE
 jnz .desc_inc
 cmp rsi,r9
 jle .no
 jmp .desc_distance
.desc_inc:
 cmp rsi,r9
 jl .no
.desc_distance:
 mov rax,r8
 sub rax,rsi
 neg r10
 jmp .mod
.distance:
 mov rax,rsi
 sub rax,r8
.mod:
 xor edx,edx
 div r10
 test rdx,rdx
 setz al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

ar_expect_empty_call:
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
.done:
 add rsp,8
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
ar_alloc_binding:
 mov rax,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_AR_BINDING_CAPACITY_OFFSET]
 jae .limit
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 mov qword [rax+NEBOC_AR_BIND_NAME_OFFSET],NEBOC_AR_UNBOUND_NAME
 inc qword [r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 ret
.limit:
 mov esi,NEBOC_AR_DIAG_CONST_LENGTH
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 xor eax,eax
 ret

%undef call
ar_find_binding:
 push rbx
 push r13
 sub rsp,8
 mov r13,rdi
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .no
 mov rax,rbx
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rax+NEBOC_AR_BIND_NAME_OFFSET],NEBOC_AR_UNBOUND_NAME
 je .next
 mov [rsp],rax
 mov rdi,r13
 mov rsi,[rax+NEBOC_AR_BIND_NAME_OFFSET]
 call ar_name_equal
 mov rdx,[rsp]
 test eax,eax
 jnz .yes
.next:
 inc rbx
 jmp .loop
.yes:
 mov rax,rdx
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop rbx
 ret

ar_hash_binding:
 mov rax,14695981039346656037
 mov r8,1099511628211
 mov ecx,1
.loop:
 cmp ecx,11
 jae .done
 xor rax,[rdi+rcx*8]
 imul rax,r8
 inc ecx
 jmp .loop
.done:
 ret

ar_semantic_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 mov rdx,NEBOC_ARRAY_RANGE_LAYOUT_ID
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_FOUND_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_RESULT_TYPE_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_RESULT_VALUE_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_LAYOUT_SIZE_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_LAYOUT_ALIGN_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_ARRAY_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_RANGE_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 mov rdx,[r12+NEBOC_AR_ITERATION_COUNT_OFFSET]
 xor rax,rdx
 imul rax,r8
 xor r9d,r9d
.loop_hash:
 cmp r9,[r12+NEBOC_AR_LOOP_COUNT_OFFSET]
 jae .done
 mov r10,r9
 imul r10,NEBOC_FOR_RECORD_SIZE
 add r10,[r12+NEBOC_AR_LOOPS_OFFSET]
 xor r11d,r11d
.record_hash:
 cmp r11,NEBOC_FOR_RECORD_QWORDS
 jae .next_loop_hash
 mov rdx,[r10+r11*8]
 xor rax,rdx
 imul rax,r8
 inc r11
 jmp .record_hash
.next_loop_hash:
 inc r9
 jmp .loop_hash
.done:
 ret

ar_name_equal:
 push rbx
 push r13
 push r14
 push rcx
 sub rsp,8
 mov r13,rdi
 mov r14,rsi
 mov rax,r13
 call ar_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rax,r14
 call ar_token_ptr
 test rax,rax
 jz .no
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov rsi,[r12+NEBOC_AR_SOURCE_OFFSET]
 add rsi,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdi,[r12+NEBOC_AR_SOURCE_OFFSET]
 add rdi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rcx,rdx
 repe cmpsb
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop rcx
 pop r14
 pop r13
 pop rbx
 ret

ar_token_match:
 push rbx
 mov rbx,rsi
 mov r9,rdx
 mov rax,rdi
 call ar_token_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r9
 jne .no
 mov rsi,[r12+NEBOC_AR_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,rbx
 mov rcx,r9
 repe cmpsb
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop rbx
 ret

ar_peek_kind:
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 jmp ar_kind_at

ar_expect:
 push rbx
 mov ebx,edi
 call ar_peek_kind
 cmp rax,rbx
 jne .bad
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 xor eax,eax
 pop rbx
 ret
.bad:
 mov esi,NEBOC_AR_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
ar_kind_at:
 call ar_token_ptr
 test rax,rax
 jz .invalid
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.invalid:
 xor eax,eax
 ret

%undef call
ar_token_ptr:
 cmp rax,[r12+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .invalid
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_AR_TOKENS_OFFSET]
 ret
.invalid:
 xor eax,eax
 ret

ar_error:
 mov [r12+NEBOC_AR_DIAGNOSTIC_OFFSET],rsi
 mov [r12+NEBOC_AR_ERROR_TOKEN_OFFSET],rdx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
