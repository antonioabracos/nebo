; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F03 structural bounded parser/typechecker for Array<T,N>/Range<Int>.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/statements/statements.inc"
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
extern neboc_statement_parse_for_header

section .rodata
n_array: db "Array"
n_array_len equ $-n_array
n_range: db "Range"
n_range_len equ $-n_range
n_slice: db "Slice"
n_slice_len equ $-n_slice
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
n_mutable: db "mutable"
n_mutable_len equ $-n_mutable
n_sum: db "sum"
n_sum_len equ $-n_sum
n_release: db "release"
n_release_len equ $-n_release
n_mutate: db "mutate"
n_mutate_len equ $-n_mutate
n_in: db "in"
n_in_len equ $-n_in
n_type: db "type"
n_type_len equ $-n_type
n_newtype: db "newtype"
n_newtype_len equ $-n_newtype

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
 lea rsi,[rel n_slice]
 mov edx,n_slice_len
 call ar_token_match
 test eax,eax
 jz .claim_range_only
 lea rax,[rbx+1]
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_LESS
 je .claimed
.claim_range_only:
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
 ; Collection semantics are declaration-body agnostic: the shared parser owns
 ; function/start headers.  Scan each top-level declaration to its opening
 ; brace, then authenticate only direct statements in that body.  Nested
 ; branch-local declarations stay visible to (and rejected by) the shared AST.
.top_level:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 je .finish_program
 cmp rax,NEBOC_TOKEN_RBRACE
 je .syntax
 cmp rax,NEBOC_TOKEN_KW_ENUM
 je .skip_top_level_enum
 cmp rax,NEBOC_TOKEN_LBRACE
 je .enter_body
 ; Collection-valued parameters/returns remain outside this front.  Do not
 ; let the body scanner erase the former fail-closed header behavior.
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .top_advance
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_type]
 mov edx,n_type_len
 call ar_token_match
 test eax,eax
 jnz .skip_top_level_linear_nominal
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_newtype]
 mov edx,n_newtype_len
 call ar_token_match
 test eax,eax
 jnz .skip_top_level_linear_nominal
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_slice]
 mov edx,n_slice_len
 call ar_token_match
 test eax,eax
 jz .top_array
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_LESS
 jne .top_array
 call ar_parse_slice_parameter_header
 test eax,eax
 jnz .done
 jmp .top_level
.top_array:
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call ar_token_match
 test eax,eax
 jz .top_range
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_LESS
 je .syntax
.top_range:
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_range]
 mov edx,n_range_len
 call ar_token_match
 test eax,eax
 jz .top_advance
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 je .syntax
.top_advance:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .top_level
.skip_top_level_linear_nominal:
 ; Alias/newtype declarations have already passed the nominal vertical.  They
 ; are semicolon-terminated and have no collection-owned body to reinterpret.
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 je .syntax
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .skip_top_level_linear_nominal
 jmp .top_level
.skip_top_level_enum:
 ; The driver reaches this owner only after the existing nominal vertical has
 ; authenticated every top-level enum.  Preserve the original token array and
 ; all collection record indices while declining to reinterpret variant braces
 ; as a function body.  Unbalanced declarations remain fail-closed here too.
 xor r15d,r15d
.skip_enum_token:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 je .syntax
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .skip_enum_close
 inc r15
 jmp .skip_enum_advance
.skip_enum_close:
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .skip_enum_advance
 test r15,r15
 jz .syntax
 dec r15
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 test r15,r15
 jnz .skip_enum_token
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .top_level
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .top_level
.skip_enum_advance:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .skip_enum_token
.enter_body:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov [r12+NEBOC_AR_BODY_START_OFFSET],rax
.statement:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_RBRACE
 je .finish_body
 cmp rax,NEBOC_TOKEN_EOF
 je .syntax
 cmp rax,NEBOC_TOKEN_KW_FOR
 je .for_statement
 ; Collection declarations and established collection operations stay under
 ; this semantic owner.  Other statements are authenticated by the shared AST
 ; and are skipped here so the general-body backend can own them.
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .general_statement
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call ar_token_match
 test eax,eax
 jnz .collection_statement
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_range]
 mov edx,n_range_len
 call ar_token_match
 test eax,eax
 jnz .collection_statement
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_find_binding
 test rax,rax
 jz .general_statement
.collection_statement:
 call ar_parse_statement
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ar_expect
 test eax,eax
 jnz .done
 jmp .statement
.general_statement:
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 call ar_skip_general_statement
 test eax,eax
 jnz .done
 jmp .statement
.for_statement:
 call ar_parse_for
 test eax,eax
 jnz .done
 cmp qword [r12+NEBOC_AR_FOUND_OFFSET],0
 je .not_owned
 jmp .statement
.finish_body:
 mov edi,NEBOC_TOKEN_RBRACE
 call ar_expect
 test eax,eax
 jnz .done
 jmp .top_level
.finish_program:
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

; Consume the canonical header through the shared statement parser, then
; authenticate the selected F07 iterable semantics without defining a second
; source grammar. The bounded body surface is intentionally structural: empty,
; break, continue,
; iterator return, or one nested for.  It is sufficient to prove the CFG and
; native iterator mechanics without admitting general collection mutation.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
ar_parse_for:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,224
 mov qword [rsp+24],0
 lea rdi,[rsp+64]
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r12+NEBOC_AR_TOKENS_OFFSET]
 mov [rsp+64+NEBOC_STMT_TOKENS_OFFSET],rax
 mov rax,[r12+NEBOC_AR_TOKEN_COUNT_OFFSET]
 mov [rsp+64+NEBOC_STMT_TOKEN_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_AR_SOURCE_OFFSET]
 mov [rsp+64+NEBOC_STMT_SOURCE_DATA_OFFSET],rax
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov [rsp+64+NEBOC_STMT_INDEX_OFFSET],rax
 lea rdi,[rsp+64]
 call neboc_statement_parse_for_header
 test eax,eax
 jnz .shared_header_reject_with_control_diagnostic
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
 mov rax,[rsp+64+NEBOC_STMT_SCRATCH1_OFFSET]
 mov [rsp],rax
 mov [r13+NEBOC_FOR_ITEM_TOKEN_OFFSET],rax
 mov r15,[rsp+64+NEBOC_STMT_SCRATCH2_OFFSET]
 mov rax,[rsp+64+NEBOC_STMT_INDEX_OFFSET]
 mov [r12+NEBOC_AR_CURSOR_OFFSET],rax
 mov rdi,r15
 call ar_find_binding
 test rax,rax
 jnz .collection_found
 ; The direct B01 result binding is introduced by the shared call/type owner
 ; after this semantic scan.  Retain the exact collection-use token in a
 ; deferred loop record only when this program already contains an
 ; authenticated owned-Array return; codegen must later resolve it to the
 ; exact caller-frame result record or reject the source.
 test qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],(NEBOC_AR_FOR_FLAG_ARRAY_RETURN | NEBOC_AR_FOR_FLAG_SLICE_RETURN)
 jz .type
.deferred_result:
 mov qword [r13+NEBOC_FOR_COLLECTION_INDEX_OFFSET],-1
 mov qword [r13+NEBOC_FOR_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 mov qword [r13+NEBOC_FOR_DATA_INDEX_OFFSET],0
 mov qword [r13+NEBOC_FOR_FLAGS_OFFSET],NEBOC_FOR_FLAG_DEFERRED_RESULT
 mov qword [r13+NEBOC_FOR_START_OFFSET],0
 mov qword [r13+NEBOC_FOR_STEP_OFFSET],1
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],(NEBOC_AR_FOR_FLAG_GENERAL_BODY | NEBOC_AR_FOR_FLAG_DYNAMIC_AT)
 xor eax,eax
 jmp .count_ready
.collection_found:
 mov r14,rax
 ; A same-spelled caller result can be found through a callee-local S04
 ; derivative because this legacy semantic catalog is source-global.  Such a
 ; record cannot own the caller loop: defer exact binding ownership to the
 ; shared AST/codegen resolver, as for owned Array results.
 test qword [r14+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jz .collection_found_exact
 test qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_SLICE_RETURN
 jz .type
 jmp .deferred_result
.collection_found_exact:
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
 cmp rax,NEBOC_AR_KIND_SLICE_PARAMETER
 je .slice_parameter
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
 jmp .count_ready
.slice_parameter:
 ; Runtime length is loaded from the borrowed descriptor by function codegen.
 ; The semantic loop remains bounded by the normal AST/control limits.
 mov qword [r13+NEBOC_FOR_START_OFFSET],0
 mov qword [r13+NEBOC_FOR_STEP_OFFSET],1
 xor eax,eax
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
 je .break_candidate
 cmp rax,NEBOC_TOKEN_KW_CONTINUE
 je .continue_candidate
 cmp rax,NEBOC_TOKEN_KW_FOR
 je .nested
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .general_body
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 mov rsi,[rsp]
 call ar_name_equal
 test eax,eax
 jz .general_body
 ; Preserve the legacy iterator.return action only when it is the complete
 ; body.  Any additional statement selects the general-body route.
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 jne .general_body
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 add rax,2
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_KW_RETURN
 jne .general_body
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 add rax,3
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .general_body
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 add rax,4
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .general_body
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
.break_candidate:
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .general_body
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 add rax,2
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .general_body
 jmp .break
.continue_candidate:
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .general_body
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 add rax,2
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .general_body
 jmp .continue
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
.general_body:
 ; A receiver that resolves to an authenticated collection binding remains an
 ; excluded collection operation.  Preserve the legacy mutation diagnostic
 ; and do not let the general statement route reinterpret that surface.
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .route_general_body
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_find_binding
 test rax,rax
 jz .route_general_body
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 jne .collection_forbidden
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 add rdi,2
 lea rsi,[rel n_at]
 mov edx,n_at_len
 call ar_token_match
 test eax,eax
 jnz .route_general_body
.collection_forbidden:
 mov rsi,NEBOC_AR_DIAG_FOR_MUTATION
 jmp .publish
.route_general_body:
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 ; Keep the lowered legacy action domain stable.  The request-level flag owns
 ; backend routing; an empty action is the neutral authenticated loop action.
 mov qword [r13+NEBOC_FOR_ACTION_OFFSET],NEBOC_FOR_ACTION_EMPTY
 call ar_skip_general_for_body
 test eax,eax
 jnz .fail
 jmp .body_done
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
 jmp .shared_header_reject
.shared_header_reject_with_control_diagnostic:
 mov rax,[rsp+64+NEBOC_STMT_ERROR_CODE_OFFSET]
 mov [r12+NEBOC_AR_DIAGNOSTIC_OFFSET],rax
 mov rax,[rsp+64+NEBOC_STMT_ERROR_TOKEN_OFFSET]
 mov [r12+NEBOC_AR_ERROR_TOKEN_OFFSET],rax
 mov rax,[rsp+64+NEBOC_STMT_FIXIT_COUNT_OFFSET]
 mov [r12+NEBOC_AR_CONTROL_FIXIT_COUNT_OFFSET],rax
 mov rax,[rsp+64+NEBOC_STMT_FIXIT0_START_OFFSET]
 mov [r12+NEBOC_AR_CONTROL_FIXIT0_START_OFFSET],rax
 mov rax,[rsp+64+NEBOC_STMT_FIXIT0_KIND_OFFSET]
 mov [r12+NEBOC_AR_CONTROL_FIXIT0_KIND_OFFSET],rax
 mov rax,[rsp+64+NEBOC_STMT_FIXIT1_START_OFFSET]
 mov [r12+NEBOC_AR_CONTROL_FIXIT1_START_OFFSET],rax
.shared_header_reject:
 ; Leave malformed/legacy control syntax to the shared parser so its stable
 ; diagnostics and fix-its remain authoritative. No collection facts escape.
 mov qword [r12+NEBOC_AR_FOUND_OFFSET],0
 xor eax,eax
.done:
 add rsp,224
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Skip one AST-authenticated general top-level statement.  Collection syntax
; is never handled here.  Semicolon statements and balanced control blocks are
; bounded by the lexer token count; an else/else-if tail remains attached.
ar_skip_general_statement:
 push rbx
 push r13
 xor ebx,ebx                    ; brace depth
 xor r13d,r13d                  ; saw a block
.scan:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 je .bad
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 je .maybe_collection
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .lbrace
 test rbx,rbx
 jnz .advance
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 xor eax,eax
 jmp .done
.lbrace:
 cmp rax,NEBOC_TOKEN_KW_FOR
 jne .not_nested_for
 call ar_parse_for
 test eax,eax
 jnz .done
 jmp .scan
.not_nested_for:
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .rbrace
 inc rbx
 mov r13d,1
 jmp .advance
.rbrace:
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .advance
 test rbx,rbx
 jz .bad
 dec rbx
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 test rbx,rbx
 jnz .scan
 test r13d,r13d
 jz .scan
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_KW_ELSE
 jne .ok
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .scan
.maybe_collection:
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call ar_token_match
 test eax,eax
 jnz .parse_collection
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_range]
 mov edx,n_range_len
 call ar_token_match
 test eax,eax
 jnz .parse_collection
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_find_binding
 test rax,rax
 jz .advance
.parse_collection:
 call ar_parse_statement
 test eax,eax
 jnz .done
 jmp .scan
.advance:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .scan
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov esi,NEBOC_AR_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
.done:
 pop r13
 pop rbx
 ret

; Cursor is at the first token inside a collection loop body.  Skip the full
; balanced body while recursively authenticating every nested collection loop.
; The matching outer RBRACE is deliberately left for ar_parse_for.
ar_skip_general_for_body:
 push rbx
 xor ebx,ebx
.scan:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 je .bad
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 je .maybe_collection
 cmp rax,NEBOC_TOKEN_KW_FOR
 je .nested_for
 cmp rax,NEBOC_TOKEN_LBRACE
 je .open
 cmp rax,NEBOC_TOKEN_RBRACE
 je .close
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .scan
.maybe_collection:
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call ar_token_match
 test eax,eax
 jnz .parse_collection
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 lea rsi,[rel n_range]
 mov edx,n_range_len
 call ar_token_match
 test eax,eax
 jnz .parse_collection
 mov rdi,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_find_binding
 test rax,rax
 jz .advance_general
.parse_collection:
 call ar_parse_statement
 test eax,eax
 jnz .done
 jmp .scan
.advance_general:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .scan
.nested_for:
 call ar_parse_for
 test eax,eax
 jnz .done
 jmp .scan
.open:
 inc rbx
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .scan
.close:
 test rbx,rbx
 jz .ok
 dec rbx
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .scan
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov esi,NEBOC_AR_DIAG_FOR_SYNTAX
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
.done:
 pop rbx
 ret

; Parse one constructor/binding operation or one access expression.
%undef call
ar_parse_statement:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 xor r15d,r15d
 mov qword [rsp+8],0
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
 cmp rax,NEBOC_TOKEN_RESERVED_EQUAL
 je .element_assignment_tail
 cmp rax,NEBOC_TOKEN_DOT
 jne .complete
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_KW_RETURN
 je .terminal_return
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov qword [rsp+8],1        ; distinguish a bare owned-Array return from access
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
 mov rdi,r14
 lea rsi,[rel n_mutable]
 mov edx,n_mutable_len
 call ar_token_match
 test eax,eax
 jnz .mutable
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
.mutable:
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .type
 cmp qword [r13+NEBOC_AR_BIND_NAME_OFFSET],NEBOC_AR_UNBOUND_NAME
 je .syntax
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 jnz .syntax
 or qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_MUTABLE
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY|NEBOC_AR_FOR_FLAG_DYNAMIC_AT|NEBOC_AR_FOR_FLAG_MUTABLE_ARRAY
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .suffix
.element_assignment_tail:
 ; The shared AST/type backend owns the RHS and the exact writable-target
 ; contract. This owner only advances through the already-tokenized suffix so
 ; collection declaration/access records remain available to codegen.
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 call ar_skip_dynamic_result_suffix
 test eax,eax
 jnz .fail
 jmp .complete
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
 je .at_parse
 cmp rax,NEBOC_AR_KIND_SLICE_PARAMETER
 jne .type
.at_parse:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .at_dynamic
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_RPAREN
 jne .at_dynamic
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call ar_expect
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .parameter_at
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
 jmp .material_scalar_suffix
.parameter_at:
 ; The callee observes this value dynamically through the borrowed descriptor.
 ; Semantic ownership authenticates only the exact constant-index/type shape.
 mov qword [r12+NEBOC_AR_RESULT_VALUE_OFFSET],0
 mov rax,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_AR_RESULT_TYPE_OFFSET],rax
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 jmp .material_scalar_suffix
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
 or r15d,1
 jmp .material_scalar_suffix
.at_dynamic:
 ; Preserve the established raw signed-literal rejection.  Computed negative
 ; values use material binary expressions and are checked by the runtime path.
 cmp rax,NEBOC_TOKEN_MINUS
 je .dynamic
 call ar_skip_dynamic_at_expression
 test eax,eax
 jnz .fail
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY|NEBOC_AR_FOR_FLAG_DYNAMIC_AT
 mov qword [r12+NEBOC_AR_RESULT_VALUE_OFFSET],0
 mov rax,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_AR_RESULT_TYPE_OFFSET],rax
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .dynamic_result_suffix
 or r15d,1
.dynamic_result_suffix:
 ; A material dynamic value may continue through an already-public scalar
 ; receiver operation such as Console.  The shared AST/type owners remain the
 ; authority for that suffix; this collection pass only advances to the
 ; statement terminator instead of reinterpreting the method as a binding.
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_DOT
 jne .suffix
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_KW_RETURN
 je .suffix
 call ar_skip_dynamic_result_suffix
 test eax,eax
 jnz .fail
 jmp .complete
.material_scalar_suffix:
 ; A scalar access result can continue through the shared postfix grammar
 ; (`.binding`, Console, arithmetic, ...).  The collection owner has already
 ; authenticated the receiver and result type/value; it must not reinterpret a
 ; following scalar binding as a second name for the collection record.
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jmp .dynamic_result_suffix
.length:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_expect_empty_call
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 je .array_length
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 je .slice_length
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .parameter_length
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
 or r15d,1
 jmp .store_length
.parameter_length:
 xor eax,eax
.store_length:
 mov qword [r12+NEBOC_AR_RESULT_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 mov [r12+NEBOC_AR_RESULT_VALUE_OFFSET],rax
 inc qword [r12+NEBOC_AR_ACCESS_COUNT_OFFSET]
 jmp .material_scalar_suffix
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
 jmp .material_scalar_suffix
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
 mov rax,[r13+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rax,NEBOC_AR_KIND_SLICE
 je .subslice_kind_ok
 cmp rax,NEBOC_AR_KIND_SLICE_PARAMETER
 jne .type
.subslice_kind_ok:
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
 mov rax,[r13+NEBOC_AR_BIND_KIND_OFFSET]
 cmp rax,NEBOC_AR_KIND_SLICE_PARAMETER
 je .subslice_s04
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jnz .subslice_s04
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 mov rcx,r15
 mov r8,rsp
 call neboc_slice_subslice
 jmp .subslice_created
.subslice_s04:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 mov rcx,r15
 mov r8,rsp
 call ar_create_s04_subslice
.subslice_created:
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
 or r15d,1
 jmp .material_scalar_suffix
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
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .slice_return_source
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .return_ok
 test r15d,1
 jnz .return_ok
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jz .escape
.slice_return_source:
 or qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RETURN_SOURCE
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],(NEBOC_AR_FOR_FLAG_GENERAL_BODY | NEBOC_AR_FOR_FLAG_SLICE_RETURN)
.return_ok:
 ; NPT-LANG-29 B01: an owned Array terminal return is lowered by the shared
 ; function CFG/sret backend.  Preserve the authenticated collection record,
 ; but route the statement through the declaration-filtered general AST.
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .return_advance
 cmp qword [rsp+8],0
 jne .return_advance
 or qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_RETURN_SOURCE
 or qword [r12+NEBOC_AR_FOR_FLAGS_OFFSET],(NEBOC_AR_FOR_FLAG_GENERAL_BODY | NEBOC_AR_FOR_FLAG_ARRAY_RETURN)
.return_advance:
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
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
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
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; request*, S04/derived parent*, constant start, constant end, out_record**.
; Retain one exact S04 root ordinal plus a checked accumulated element offset.
; The direct S04 upper bound is runtime descriptor state and is checked by the
; generated return path; a nested derived view has a known bounded length.
ar_create_s04_subslice:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 mov [rsp+8],rdx
 mov qword [r8],0
 cmp r14,r15
 ja .bounds
 cmp qword [r13+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 je .root_parameter
 test qword [r13+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_S04_DERIVED
 jz .type
 cmp r15,[r13+NEBOC_AR_BIND_COUNT_OFFSET]
 ja .bounds
 mov rbx,[r13+NEBOC_AR_BIND_START_OFFSET]
 add r14,[r13+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 jc .bounds
 jmp .allocate
.root_parameter:
 mov rax,r13
 sub rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 jc .internal_s04
 xor edx,edx
 mov ecx,NEBOC_AR_BIND_SIZE
 div rcx
 test rdx,rdx
 jnz .internal_s04
 mov rbx,rax
.allocate:
 call ar_alloc_binding
 test rax,rax
 jz .failed_s04
 mov qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 mov rdx,[r13+NEBOC_AR_BIND_TYPE_OFFSET]
 mov [rax+NEBOC_AR_BIND_TYPE_OFFSET],rdx
 mov rcx,r15
 sub rcx,[rsp+8]
 mov [rax+NEBOC_AR_BIND_COUNT_OFFSET],rcx
 mov qword [rax+NEBOC_AR_BIND_STRIDE_OFFSET],8
 mov qword [rax+NEBOC_AR_BIND_SIZE_OFFSET],40
 mov [rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET],r14
 mov [rax+NEBOC_AR_BIND_START_OFFSET],rbx
 mov qword [rax+NEBOC_AR_BIND_END_OFFSET],0
 mov rdx,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 mov [rax+NEBOC_AR_BIND_STEP_OFFSET],rdx
 mov qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],(NEBOC_AR_SLICE_LIVE | NEBOC_AR_SLICE_S04_DERIVED)
 mov rdx,[rsp]
 mov [rdx],rax
 inc qword [r12+NEBOC_AR_CONSTRUCT_COUNT_OFFSET]
 xor eax,eax
 jmp .done_s04
.bounds:
 mov esi,NEBOC_AR_DIAG_BOUNDS
 jmp .error_s04
.type:
 mov esi,NEBOC_AR_DIAG_TYPE
 jmp .error_s04
.internal_s04:
 mov esi,NEBOC_AR_DIAG_INTERNAL
.error_s04:
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
.failed_s04:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done_s04:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
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
 jc .value_capacity
 cmp rdx,[r12+NEBOC_AR_VALUE_CAPACITY_OFFSET]
 ja .value_capacity
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
.value_capacity:
 mov esi,NEBOC_AR_DIAG_VALUE_CAPACITY
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
 ; Collection elements keep the canonical qword-cell representation.  Scalar
 ; local Bool slot width is owned by the scalar backend and is intentionally
 ; unrelated to this collection stride.
 mov edx,8
 jmp .accept
.char:
 mov eax,NEBOC_AR_TYPE_CHAR
 ; Char collection cells are likewise qword-spaced even though a typed load
 ; may canonicalize only the low 32 bits.
 mov edx,8
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
 call ar_parse_signed_int
 jmp .done
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

; Consume one non-empty at() expression through its already-open outer
; parenthesis.  The shared Pratt parser remains the syntax/type authority; this
; semantic owner only preserves balanced token routing without inventing an
; expression grammar.  EAX is zero on success or invalid-source on failure.
ar_skip_dynamic_at_expression:
 push rbx
 push r13
 sub rsp,8
 mov r13,[r12+NEBOC_AR_CURSOR_OFFSET]
 xor ebx,ebx
.loop:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 je .bad
 cmp rax,NEBOC_TOKEN_SEMICOLON
 je .bad
 cmp rax,NEBOC_TOKEN_LBRACE
 je .bad
 cmp rax,NEBOC_TOKEN_RBRACE
 je .bad
 cmp rax,NEBOC_TOKEN_LPAREN
 je .open
 cmp rax,NEBOC_TOKEN_RPAREN
 je .close
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .loop
.open:
 inc rbx
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .loop
.close:
 test rbx,rbx
 jnz .nested_close
 cmp [r12+NEBOC_AR_CURSOR_OFFSET],r13
 je .bad
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 xor eax,eax
 jmp .done
.nested_close:
 dec rbx
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .loop
.bad:
 mov esi,NEBOC_AR_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r13
 pop rbx
 ret

; Cursor follows a complete dynamic at(...) expression and precedes an
; AST-owned scalar suffix.  Consume a bounded suffix up to (but not including)
; the statement semicolon.  Parentheses must balance; braces and EOF fail
; closed.  No suffix semantics are accepted here.
ar_skip_dynamic_result_suffix:
 push rbx
 xor ebx,ebx
.scan:
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 je .bad
 cmp rax,NEBOC_TOKEN_LBRACE
 je .bad
 cmp rax,NEBOC_TOKEN_RBRACE
 je .bad
 cmp rax,NEBOC_TOKEN_LPAREN
 je .open
 cmp rax,NEBOC_TOKEN_RPAREN
 je .close
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .advance
 test rbx,rbx
 jnz .bad
 xor eax,eax
 jmp .done
.open:
 inc rbx
 jmp .advance
.close:
 test rbx,rbx
 jz .bad
 dec rbx
.advance:
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 jmp .scan
.bad:
 mov esi,NEBOC_AR_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop rbx
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
 mov esi,NEBOC_AR_DIAG_RECORD_CAPACITY
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
 mov rbx,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
.loop:
 test rbx,rbx
 jz .no
 dec rbx
 mov rax,rbx
 imul rax,NEBOC_AR_BIND_SIZE
 add rax,[r12+NEBOC_AR_BINDINGS_OFFSET]
 cmp qword [rax+NEBOC_AR_BIND_NAME_OFFSET],NEBOC_AR_UNBOUND_NAME
 je .next
 mov rdx,[rax+NEBOC_AR_BIND_NAME_OFFSET]
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 jne .local_scope
 mov rcx,[rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET]
 cmp rcx,[r12+NEBOC_AR_BODY_START_OFFSET]
 jne .next
 jmp .name
.local_scope:
 cmp rdx,[r12+NEBOC_AR_BODY_START_OFFSET]
 jb .next
.name:
 mov [rsp],rax
 mov rdi,r13
 mov rsi,[rax+NEBOC_AR_BIND_NAME_OFFSET]
 call ar_name_equal
 mov rdx,[rsp]
 test eax,eax
 jnz .yes
.next:
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

; Cursor is at the exact `Slice<Element>.name` parameter spelling in a
; function header.  Only Int/Bool/Char elements and a parameter-list tail are
; admitted; Slice receivers and arbitrary generics remain closed.
ar_parse_slice_parameter_header:
 push rbx
 push r13
 push r14
 sub rsp,8
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_parse_scalar_type
 test eax,eax
 jz .fail
 mov r13,rax
 mov r14,rdx
 mov edi,NEBOC_TOKEN_GREATER
 call ar_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_DOT
 call ar_expect
 test eax,eax
 jnz .fail
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rbx,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc qword [r12+NEBOC_AR_CURSOR_OFFSET]
 ; A material parameter is followed by comma or by `) {`.  This explicitly
 ; rejects a Slice receiver, whose `)` is followed by the function name.
 call ar_peek_kind
 cmp rax,NEBOC_TOKEN_COMMA
 je .tail_ok
 cmp rax,NEBOC_TOKEN_RPAREN
 jne .syntax
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .syntax
.tail_ok:
 ; Persist the exact owning body token boundary so identically named Slice
 ; parameters in other functions cannot participate in this declaration.
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
.find_body:
 call ar_kind_at
 cmp rax,NEBOC_TOKEN_LBRACE
 je .body_found
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 cmp rax,[r12+NEBOC_AR_TOKEN_COUNT_OFFSET]
 jae .syntax
 mov [r12+NEBOC_AR_CURSOR_OFFSET],rax
 jmp .find_body
.body_found:
 mov rax,[r12+NEBOC_AR_CURSOR_OFFSET]
 inc rax
 mov [rsp],rax
 ; Restore the parameter-list cursor; the top-level scanner owns traversal.
 mov rax,rbx
 inc rax
 mov [r12+NEBOC_AR_CURSOR_OFFSET],rax
 call ar_alloc_binding
 test rax,rax
 jz .fail
 mov qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE_PARAMETER
 mov [rax+NEBOC_AR_BIND_TYPE_OFFSET],r13
 mov qword [rax+NEBOC_AR_BIND_COUNT_OFFSET],0
 ; The generated collection payload contract is one qword per scalar element;
 ; Bool/Char semantic identities remain exact, but transport stride is 8.
 mov qword [rax+NEBOC_AR_BIND_STRIDE_OFFSET],8
 mov qword [rax+NEBOC_AR_BIND_SIZE_OFFSET],40
 mov rdx,[rsp]
 mov [rax+NEBOC_AR_BIND_DATA_INDEX_OFFSET],rdx
 mov qword [rax+NEBOC_AR_BIND_START_OFFSET],0
 mov qword [rax+NEBOC_AR_BIND_END_OFFSET],1
 mov rdx,[r12+NEBOC_AR_BINDING_COUNT_OFFSET]
 mov [rax+NEBOC_AR_BIND_STEP_OFFSET],rdx
 mov qword [rax+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_LIVE
 mov [rax+NEBOC_AR_BIND_NAME_OFFSET],rbx
 mov rdi,rax
 call ar_hash_binding
 mov [rdi+NEBOC_AR_BIND_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.syntax:
 mov esi,NEBOC_AR_DIAG_TYPE
 mov rdx,[r12+NEBOC_AR_CURSOR_OFFSET]
 call ar_error
.fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r14
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
