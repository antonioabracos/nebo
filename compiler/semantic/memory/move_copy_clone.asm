; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-F02/F03 bounded ownership and borrow vertical
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/memory/move_copy_clone.inc"

section .rodata
n_move: db "move"
n_move_len equ $-n_move
n_copy: db "copy"
n_copy_len equ $-n_copy
n_clone: db "clone"
n_clone_len equ $-n_clone
n_borrow_shared: db "borrowShared"
n_borrow_shared_len equ $-n_borrow_shared
n_borrow_unique: db "borrowUnique"
n_borrow_unique_len equ $-n_borrow_unique
n_read: db "read"
n_read_len equ $-n_read
n_write: db "write"
n_write_len equ $-n_write
n_release: db "release"
n_release_len equ $-n_release
n_drop: db "drop"
n_drop_len equ $-n_drop
n_defer_drop: db "deferDrop"
n_defer_drop_len equ $-n_defer_drop
n_close: db "close"
n_close_len equ $-n_close
n_is_closed: db "isClosed"
n_is_closed_len equ $-n_is_closed
n_forget: db "forget"
n_forget_len equ $-n_forget
n_bytes: db "Bytes"
n_bytes_len equ $-n_bytes
n_empty: db "empty"
n_empty_len equ $-n_empty
n_from_byte: db "fromByte"
n_from_byte_len equ $-n_from_byte
n_from_values: db "fromValues"
n_from_values_len equ $-n_from_values
n_byte_length: db "byteLength"
n_byte_length_len equ $-n_byte_length

section .text

; recognize(request*) -> Status.  The general Pratt parser owns syntax; this
; pass claims start bodies containing canonical ownership or borrow calls.
NEBOC_ABI_FUNCTION neboc_move_copy_clone_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_SEM_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 cmp qword [r12+NEBOC_SEM_SYMBOL_CAPACITY_OFFSET],NEBOC_SEM_MAX_SYMBOLS
 jb .invalid
 mov rax,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 test rax,rax
 jz .invalid
 lea rdi,[r12+NEBOC_SEM_FOUND_OFFSET]
 mov ecx,22
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 mov ecx,(NEBOC_SEM_MAX_SYMBOLS*NEBOC_SYMBOL_SIZE)/8
 xor eax,eax
 rep stosq

 ; Bounded ownership calls are identified structurally, never by substring.
 mov ebx,1
.scan:
 cmp rbx,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .not_found
 mov rdi,r12
 mov rsi,rbx
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 je .scan_call
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 je .scan_binding
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 je .claimed
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BREAK_STMT
 je .claimed
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CONTINUE_STMT
 je .claimed
 jmp .scan_next
.scan_call:
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .scan_next
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_move]
 mov ecx,n_move_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_copy]
 mov ecx,n_copy_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_clone]
 mov ecx,n_clone_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_borrow_shared]
 mov ecx,n_borrow_shared_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_borrow_unique]
 mov ecx,n_borrow_unique_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_read]
 mov ecx,n_read_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_write]
 mov ecx,n_write_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_release]
 mov ecx,n_release_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_drop]
 mov ecx,n_drop_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_defer_drop]
 mov ecx,n_defer_drop_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_close]
 mov ecx,n_close_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_is_closed]
 mov ecx,n_is_closed_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 mov rdi,r12
 mov rsi,r14
 lea rdx,[rel n_forget]
 mov ecx,n_forget_len
 call rf27g04_token_match
 test eax,eax
 jnz .claimed
 jmp .scan_next
.scan_binding:
 mov r14,rax
 mov rdi,r12
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .scan_text_owner
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .scan_next
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call rf27g04_find_symbol
 test rax,rax
 jz .scan_next
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_TEXT
 je .claimed
 jmp .scan_next
.scan_text_owner:
 mov rax,[r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_SEM_SYMBOL_CAPACITY_OFFSET]
 jae .internal
 imul rax,NEBOC_SYMBOL_SIZE
 add rax,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 mov rcx,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rax+neboc_text_char_unicode_e_bytes_SYMBOL_NAME_TOKEN_OFFSET],rcx
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_TEXT
 mov qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 inc qword [r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
.scan_next:
 inc rbx
 jmp .scan
.claimed:
 mov [rsp],rbx
 mov rdi,r12
 mov rsi,[r12+NEBOC_SEM_ROOT_ID_OFFSET]
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .internal
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_start:
 test r14,r14
 jz .internal
 mov rdi,r12
 mov rsi,r14
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .start
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_start
.start:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov [rsp+8],rsi
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov r14,rax
 mov rdi,r12
 mov rsi,[rsp]
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp rcx,[r14+NEBOC_AST_NODE_START_OFFSET]
 jb .claimed_outside_start
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 cmp rcx,[r14+NEBOC_AST_NODE_END_OFFSET]
 ja .claimed_outside_start
 mov qword [r12+NEBOC_SEM_FOUND_OFFSET],1
 mov rax,neboc_text_char_unicode_e_bytes_LAYOUT_ID
 mov [r12+NEBOC_SEM_LAYOUT_ID_OFFSET],rax
 mov qword [r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET],0
 mov rax,14695981039346656037
 mov [r12+NEBOC_SEM_CLEANUP_ORDER_HASH_OFFSET],rax
 mov rdi,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 mov ecx,(NEBOC_SEM_MAX_SYMBOLS*NEBOC_SYMBOL_SIZE)/8
 xor eax,eax
 rep stosq
 mov rdi,r12
 mov rsi,[rsp+8]
 xor edx,edx
 call rf27g04_analyze_block
 test eax,eax
 jnz .done
 mov rdi,r12
 call neboc_ownership_safety_finalize
 test eax,eax
 jnz .done
 mov rdi,r12
 call rf27g04_semantic_hash
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.claimed_outside_start:
 mov rbx,[rsp]
 inc rbx
 jmp .scan
.not_found:
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; finalize(request*) -> Status.  This exported bounded verifier is also used by
; the F06 native proof corpus.  It proves that no live owner/borrow remains and
; that every DROPPED owner corresponds to exactly one cleanup-ledger entry.
NEBOC_ABI_FUNCTION neboc_ownership_safety_finalize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 test r13,r13
 jz .invalid
 mov r14,[r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 cmp r14,[r12+NEBOC_SEM_SYMBOL_CAPACITY_OFFSET]
 ja .invalid
 cmp r14,NEBOC_SEM_MAX_SYMBOLS
 ja .invalid
 mov qword [r12+NEBOC_SEM_LIVE_OWNER_COUNT_OFFSET],0
 mov qword [r12+NEBOC_SEM_SAFETY_PROOF_HASH_OFFSET],0
 mov r15,14695981039346656037
 xor ebx,ebx
.loop:
 cmp rbx,r14
 jae .counts
 mov rax,rbx
 imul rax,NEBOC_SYMBOL_SIZE
 add rax,r13
 mov [rsp],rax
 mov r8,1099511628211
 mov rcx,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_NAME_TOKEN_OFFSET]
 xor r15,rcx
 imul r15,r8
 mov rcx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 xor r15,rcx
 imul r15,r8
 mov rcx,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET]
 xor r15,rcx
 imul r15,r8
 mov rcx,[rax+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET]
 xor r15,rcx
 imul r15,r8
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 cmp rcx,NEBOC_CATEGORY_UNIQUE_OWNER
 je .owner
 cmp rcx,NEBOC_CATEGORY_SHARED_BORROW
 je .borrow
 cmp rcx,NEBOC_CATEGORY_UNIQUE_BORROW
 je .borrow
 jmp .next
.owner:
 mov rcx,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET]
 cmp rcx,neboc_text_char_unicode_e_bytes_STATE_DROPPED
 je .closed
 cmp rcx,neboc_text_char_unicode_e_bytes_STATE_MOVED
 je .next
 cmp rcx,NEBOC_STATE_LIVE
 je .leak
 cmp rcx,NEBOC_STATE_BORROWED_SHARED
 je .leak
 cmp rcx,NEBOC_STATE_BORROWED_UNIQUE
 je .leak
 jmp .internal
.closed:
 jmp .next
.borrow:
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_RELEASED
 je .next
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 jne .internal
.leak:
 inc qword [r12+NEBOC_SEM_LIVE_OWNER_COUNT_OFFSET]
 mov rdx,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_NAME_TOKEN_OFFSET]
 mov rdi,r12
 mov esi,NEBOC_DIAG_RESOURCE_LEAK_PATH
 call rf27g04_set_error
 jmp .done
.next:
 inc rbx
 jmp .loop
.counts:
 mov rax,[r12+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_SEM_CLEANUP_COUNT_OFFSET]
 jne .missing_cleanup
 mov r8,1099511628211
 xor r15,rax
 imul r15,r8
 mov rcx,[r12+NEBOC_SEM_CLEANUP_ORDER_HASH_OFFSET]
 xor r15,rcx
 imul r15,r8
 mov [r12+NEBOC_SEM_SAFETY_PROOF_HASH_OFFSET],r15
 xor eax,eax
 jmp .done
.missing_cleanup:
 mov rdi,r12
 mov esi,NEBOC_DIAG_RESOURCE_LEAK_PATH
 xor edx,edx
 call rf27g04_set_error
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request*, block node id, lexical depth -> Status
rf27g04_analyze_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r15,rdx
 mov [rsp],r15
 mov rax,[r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 mov [rsp+8],rax
 mov rax,[r12+NEBOC_SEM_SCOPE_DEPTH_OFFSET]
 mov [rsp+16],rax
 mov [r12+NEBOC_SEM_SCOPE_DEPTH_OFFSET],r15
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .internal
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test rbx,rbx
 jz .ok
 mov rdi,r12
 mov rsi,rbx
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 je .binding
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_EXPRESSION_STMT
 je .expression
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 je .if_statement
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 je .return_statement
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 je .loop_statement
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BREAK_STMT
 je .break_statement
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CONTINUE_STMT
 je .continue_statement
 mov rdi,r12
 mov esi,NEBOC_DIAG_CLONE_UNAVAILABLE
 xor edx,edx
 call rf27g04_set_error
 jmp .done
.binding:
 mov rdi,r12
 mov rsi,rbx
 call rf27g04_analyze_binding
 test eax,eax
 jnz .done
 jmp .next
.expression:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r12
 xor edx,edx
 call rf27g04_eval_expr
 cmp rax,-1
 je .source_error
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_memory_native_vertical],rax
 mov [r12+NEBOC_SEM_RESULT_VALUE_OFFSET],rcx
 inc qword [r12+NEBOC_SEM_OPERATION_COUNT_OFFSET]
 jmp .next
.if_statement:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r15
 call rf27g04_analyze_if
 test eax,eax
 jnz .done
 jmp .next
.return_statement:
 mov rdi,r12
 mov rsi,rbx
 call rf27g04_analyze_return
 test eax,eax
 jnz .done
 mov qword [r12+NEBOC_SEM_CONTROL_OFFSET],NEBOC_CONTROL_RETURN
 jmp .next
.loop_statement:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r15
 call rf27g04_analyze_loop
 test eax,eax
 jnz .done
 jmp .next
.break_statement:
 cmp qword [r12+NEBOC_SEM_LOOP_DEPTH_OFFSET],0
 je .invalid_control
 mov qword [r12+NEBOC_SEM_CONTROL_OFFSET],NEBOC_CONTROL_BREAK
 jmp .next
.continue_statement:
 cmp qword [r12+NEBOC_SEM_LOOP_DEPTH_OFFSET],0
 je .invalid_control
 mov qword [r12+NEBOC_SEM_CONTROL_OFFSET],NEBOC_CONTROL_CONTINUE
.next:
 cmp qword [r12+NEBOC_SEM_CONTROL_OFFSET],NEBOC_CONTROL_NONE
 jne .ok
 mov rbx,r14
 jmp .loop
.ok:
 mov rdi,r12
 mov rsi,r15
 mov rdx,[rsp+8]
 call rf27g04_end_scope
 jmp .done
.invalid_control:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CLONE_UNAVAILABLE
 xor edx,edx
 call rf27g04_set_error
 jmp .done
.source_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 mov rcx,[rsp+16]
 mov [r12+NEBOC_SEM_SCOPE_DEPTH_OFFSET],rcx
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, loop statement id, parent depth -> Status.  The bounded F04
; profile analyzes one body path.  break/continue are consumed only after the
; body scope has run its cleanup ledger; return remains visible to callers.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rf27g04_analyze_loop:
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 jne .internal
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 inc qword [r12+NEBOC_SEM_LOOP_DEPTH_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call rf27g04_analyze_block
 dec qword [r12+NEBOC_SEM_LOOP_DEPTH_OFFSET]
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_SEM_CONTROL_OFFSET]
 cmp rax,NEBOC_CONTROL_BREAK
 je .consume
 cmp rax,NEBOC_CONTROL_CONTINUE
 jne .ok
.consume:
 mov qword [r12+NEBOC_SEM_CONTROL_OFFSET],NEBOC_CONTROL_NONE
.ok:
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 ret

; request*, if node id, parent depth -> Status. The bounded profile accepts
; compile-time Bool conditions and releases all branch-local borrows on exit.
%undef call
rf27g04_analyze_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 xor r8d,r8d
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .internal
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r15
 xor edx,edx
 call rf27g04_eval_expr
 cmp rax,-1
 je .source
 cmp rax,NEBOC_BIND_TYPE_BOOL
 jne .unavailable
 mov [rsp],rcx
 mov rdi,r12
 mov rsi,r15
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .internal
 cmp qword [rsp],0
 je .else_branch
 mov rdi,r12
 mov rsi,r15
 lea rdx,[r14+1]
 call rf27g04_analyze_block
 jmp .done
.else_branch:
 mov rdi,r12
 mov rsi,r15
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .ok
 mov rdi,r12
 mov rsi,r15
 lea rdx,[r14+1]
 call rf27g04_analyze_block
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.unavailable:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CLONE_UNAVAILABLE
 xor edx,edx
 call rf27g04_set_error
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, return statement id -> Status. Borrow values cannot escape start.
rf27g04_analyze_return:
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .internal
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 xor edx,edx
 call rf27g04_eval_expr
 cmp rax,-1
 je .source
 cmp rdx,NEBOC_CATEGORY_SHARED_BORROW
 je .escape
 cmp rdx,NEBOC_CATEGORY_UNIQUE_BORROW
 je .escape
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_memory_native_vertical],rax
 mov [r12+NEBOC_SEM_RESULT_VALUE_OFFSET],rcx
 inc qword [r12+NEBOC_SEM_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.escape:
 mov rdi,r12
 mov esi,NEBOC_DIAG_BORROW_ESCAPE
 xor edx,edx
 call rf27g04_set_error
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,8
 pop r13
 pop r12
 ret

; request*, scope depth, symbol count at scope entry -> Status.
rf27g04_end_scope:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbx,[r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
.loop:
 cmp rbx,r14
 jbe .pop_scope
 dec rbx
 mov rax,rbx
 imul rax,NEBOC_SYMBOL_SIZE
 add rax,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 jne .loop
 mov rcx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 cmp rcx,NEBOC_CATEGORY_SHARED_BORROW
 je .release
 cmp rcx,NEBOC_CATEGORY_UNIQUE_BORROW
 je .release
 cmp rcx,NEBOC_CATEGORY_UNIQUE_OWNER
 jne .loop
 test qword [rax+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],NEBOC_CLEANUP_REQUIRED
 jz .loop
 mov rdi,r12
 mov rsi,rax
 call rf27g04_cleanup_symbol
 test eax,eax
 jnz .done
 jmp .loop
.release:
 mov rdi,r12
 mov rsi,rax
 call rf27g04_release_borrow_symbol
 test eax,eax
 jnz .done
 jmp .loop
.pop_scope:
 test r13,r13
 jz .ok
 mov [r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET],r14
.ok:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, binding statement -> Status
rf27g04_analyze_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r14
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .internal
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,r12
 mov rsi,r15
 call rf27g04_find_symbol
 test rax,rax
 jnz .duplicate
 mov rdi,r12
 mov rsi,[rsp]
 mov edx,1
 call rf27g04_eval_expr
 cmp rax,-1
 je .source_error
 mov [rsp+8],rax
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 mov [rsp+32],r8
 mov rax,[r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_SEM_SYMBOL_CAPACITY_OFFSET]
 jae .internal
 imul rax,NEBOC_SYMBOL_SIZE
 add rax,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 mov [rax+neboc_text_char_unicode_e_bytes_SYMBOL_NAME_TOKEN_OFFSET],r15
 mov rcx,[rsp+8]
 mov [rax+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET],rcx
 mov rcx,[rsp+16]
 mov [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],rcx
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 mov rcx,[rsp+24]
 mov [rax+NEBOC_SYMBOL_VALUE_OFFSET],rcx
 mov rcx,[r12+NEBOC_SEM_SCOPE_DEPTH_OFFSET]
 mov [rax+NEBOC_SYMBOL_SCOPE_DEPTH_OFFSET],rcx
 mov qword [rax+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],0
 mov rcx,[rsp+16]
 cmp rcx,NEBOC_CATEGORY_SHARED_BORROW
 je .borrow_origin
 cmp rcx,NEBOC_CATEGORY_UNIQUE_BORROW
 jne .owner_origin
.borrow_origin:
 mov rcx,[rsp+32]
 mov [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET],rcx
 jmp .origin_ready
.owner_origin:
 mov [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET],r13
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 jne .origin_ready
 or qword [rax+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],NEBOC_CLEANUP_REQUIRED
.origin_ready:
 inc qword [r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 inc qword [r12+NEBOC_SEM_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.duplicate:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CLONE_UNAVAILABLE
 mov rdx,r15
 call rf27g04_set_error
 jmp .done
.source_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, expression node, binding_context -> type/-1, category in RDX,
; bounded compile-time value in RCX.
rf27g04_eval_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .unavailable
.int:
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done
.bool:
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,NEBOC_BIND_TYPE_BOOL
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done
.char:
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,NEBOC_BIND_TYPE_CHAR
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done
.float:
 xor ecx,ecx
 mov eax,NEBOC_BIND_TYPE_FLOAT
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done
.text:
 ; Literal-backed Text owns a descriptor while sharing immutable static bytes.
 ; Clone duplicates the descriptor; no backing allocation or mutation exists.
 xor ecx,ecx
 mov eax,NEBOC_BIND_TYPE_TEXT
 mov edx,NEBOC_CATEGORY_UNIQUE_OWNER
 jmp .done
.identifier:
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call rf27g04_find_symbol
 test rax,rax
 jz .unavailable_token
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_MOVED
 je .use_after_move
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_RELEASED
 je .borrow_escape
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_DROPPED
 je .double_drop
 mov [rsp],rax
 mov rcx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 cmp rcx,NEBOC_CATEGORY_SHARED_BORROW
 je .identifier_borrow
 cmp rcx,NEBOC_CATEGORY_UNIQUE_BORROW
 je .identifier_borrow
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_UNIQUE
 je .borrow_conflict
 cmp r14,0
 je .identifier_ok
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 je .copy_unique
.identifier_ok:
 mov rcx,[rax+NEBOC_SYMBOL_VALUE_OFFSET]
 mov rdx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 mov rax,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET]
 jmp .done
.identifier_borrow:
 test r14,r14
 jnz .borrow_escape
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_SYMBOL_VALUE_OFFSET]
 mov rdx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 mov r8,[rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET]
 mov rax,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET]
 jmp .done
.call:
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .unavailable
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_move]
 mov ecx,n_move_len
 call rf27g04_token_match
 test eax,eax
 jnz .ownership_move
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_copy]
 mov ecx,n_copy_len
 call rf27g04_token_match
 test eax,eax
 jnz .ownership_copy
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_clone]
 mov ecx,n_clone_len
 call rf27g04_token_match
 test eax,eax
 jnz .ownership_clone
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_borrow_shared]
 mov ecx,n_borrow_shared_len
 call rf27g04_token_match
 test eax,eax
 jnz .borrow_shared
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_borrow_unique]
 mov ecx,n_borrow_unique_len
 call rf27g04_token_match
 test eax,eax
 jnz .borrow_unique
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_read]
 mov ecx,n_read_len
 call rf27g04_token_match
 test eax,eax
 jnz .borrow_read
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_write]
 mov ecx,n_write_len
 call rf27g04_token_match
 test eax,eax
 jnz .borrow_write
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_release]
 mov ecx,n_release_len
 call rf27g04_token_match
 test eax,eax
 jnz .borrow_release
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_drop]
 mov ecx,n_drop_len
 call rf27g04_token_match
 test eax,eax
 jnz .cleanup_drop
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_close]
 mov ecx,n_close_len
 call rf27g04_token_match
 test eax,eax
 jnz .cleanup_drop
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_defer_drop]
 mov ecx,n_defer_drop_len
 call rf27g04_token_match
 test eax,eax
 jnz .cleanup_defer
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_closed]
 mov ecx,n_is_closed_len
 call rf27g04_token_match
 test eax,eax
 jnz .cleanup_is_closed
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_forget]
 mov ecx,n_forget_len
 call rf27g04_token_match
 test eax,eax
 jnz .cleanup_forget
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call rf27g04_token_match
 test eax,eax
 jnz .bytes_empty
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call rf27g04_token_match
 test eax,eax
 jnz .bytes_one
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call rf27g04_token_match
 test eax,eax
 jnz .bytes_four
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_byte_length]
 mov ecx,n_byte_length_len
 call rf27g04_token_match
 test eax,eax
 jnz .byte_length
 jmp .unavailable_token

.ownership_move:
 mov r10d,1
 jmp .ownership
.ownership_copy:
 mov r10d,2
 jmp .ownership
.ownership_clone:
 mov r10d,3
.ownership:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unavailable_token
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .unavailable_token
 mov r11,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r11
 call rf27g04_find_symbol
 test rax,rax
 jz .unavailable_receiver
 mov [rsp],rax
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_MOVED
 je .use_after_move_receiver
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_SHARED
 je .ownership_shared_borrow
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_UNIQUE
 je .ownership_unique_borrow
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_SHARED_BORROW
 je .unavailable_receiver
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_BORROW
 je .unavailable_receiver
 jmp .ownership_state_ready
.ownership_shared_borrow:
 ; An immutable borrow permits a trivial copy read, but never move or clone.
 cmp r10,2
 jne .move_while_borrowed_receiver
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_COPY
 jne .move_while_borrowed_receiver
 jmp .ownership_state_ready
.ownership_unique_borrow:
 cmp r10,1
 je .move_while_borrowed_receiver
 jmp .borrow_conflict_receiver
.ownership_state_ready:
 cmp r10,2
 jne .ownership_not_copy
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 je .copy_unique_receiver
 inc qword [r12+NEBOC_SEM_COPY_COUNT_OFFSET]
 jmp .ownership_result
.ownership_not_copy:
 cmp r10,3
 jne .ownership_do_move
 inc qword [r12+NEBOC_SEM_CLONE_COUNT_OFFSET]
 jmp .ownership_result
.ownership_do_move:
 inc qword [r12+NEBOC_SEM_MOVE_COUNT_OFFSET]
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_COPY
 je .ownership_result
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_MOVED
.ownership_result:
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_SYMBOL_VALUE_OFFSET]
 mov rdx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 mov rax,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET]
 jmp .done

.borrow_shared:
 mov r10d,1
 jmp .borrow_owner
.borrow_unique:
 mov r10d,2
.borrow_owner:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unavailable_token
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .unavailable_token
 mov r11,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r11
 call rf27g04_find_symbol
 test rax,rax
 jz .unavailable_receiver
 mov [rsp],rax
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_MOVED
 je .use_after_move_receiver
 mov rcx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 cmp rcx,NEBOC_CATEGORY_SHARED_BORROW
 je .borrow_conflict_receiver
 cmp rcx,NEBOC_CATEGORY_UNIQUE_BORROW
 je .borrow_conflict_receiver
 cmp r10,1
 jne .borrow_owner_unique
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_UNIQUE
 je .borrow_conflict_receiver
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 je .borrow_first_shared
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_SHARED
 jne .borrow_conflict_receiver
 inc qword [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET]
 jmp .borrow_shared_result
.borrow_first_shared:
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_SHARED
 mov qword [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET],1
.borrow_shared_result:
 mov edx,NEBOC_CATEGORY_SHARED_BORROW
 jmp .borrow_result
.borrow_owner_unique:
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 jne .borrow_conflict_receiver
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_UNIQUE
 mov qword [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET],1
 mov edx,NEBOC_CATEGORY_UNIQUE_BORROW
.borrow_result:
 mov r8,[rsp]
 mov rcx,[r12+NEBOC_SEM_SCOPE_DEPTH_OFFSET]
 mov rax,[r8+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET]
 jmp .done

.borrow_read:
 mov r10d,1
 jmp .borrow_view
.borrow_write:
 mov r10d,2
 jmp .borrow_view
.borrow_release:
 mov r10d,3
.borrow_view:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .unavailable_token
 mov r11,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r11
 call rf27g04_find_symbol
 test rax,rax
 jz .unavailable_receiver
 mov [rsp],rax
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_RELEASED
 je .borrow_escape_receiver
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 jne .borrow_escape_receiver
 mov rcx,[rax+NEBOC_SYMBOL_CATEGORY_OFFSET]
 cmp rcx,NEBOC_CATEGORY_SHARED_BORROW
 je .borrow_view_category_ok
 cmp rcx,NEBOC_CATEGORY_UNIQUE_BORROW
 jne .unavailable_receiver
.borrow_view_category_ok:
 mov rax,[rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET]
 test rax,rax
 jz .internal
 mov [rsp+8],rax
 cmp r10,3
 je .borrow_view_release
 cmp r10,2
 je .borrow_view_write
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unavailable_token
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_COPY
 jne .unavailable_receiver
 mov rcx,[rax+NEBOC_SYMBOL_VALUE_OFFSET]
 mov rax,[rax+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET]
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done
.borrow_view_write:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .unavailable_token
 mov rax,[rsp]
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_BORROW
 jne .borrow_conflict_receiver
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .unavailable_token
 mov rdi,r12
 xor edx,edx
 call rf27g04_eval_expr
 cmp rax,-1
 je .done
 cmp rdx,NEBOC_CATEGORY_COPY
 jne .unavailable_token
 mov r9,[rsp+8]
 cmp rax,[r9+neboc_text_char_unicode_e_bytes_SYMBOL_TYPE_OFFSET]
 jne .unavailable_token
 mov [r9+NEBOC_SYMBOL_VALUE_OFFSET],rcx
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done
.borrow_view_release:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unavailable_token
 mov rdi,r12
 mov rsi,[rsp]
 call rf27g04_release_borrow_symbol
 test eax,eax
 jnz .internal
 xor ecx,ecx
 mov eax,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done

.cleanup_drop:
 mov r10d,1
 jmp .cleanup_owner
.cleanup_defer:
 mov r10d,2
 jmp .cleanup_owner
.cleanup_is_closed:
 mov r10d,3
 jmp .cleanup_owner
.cleanup_forget:
 mov r10d,4
.cleanup_owner:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unavailable_token
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .unavailable_token
 mov r11,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r11
 call rf27g04_find_symbol
 test rax,rax
 jz .unavailable_receiver
 mov [rsp],rax
 cmp r10,4
 je .cleanup_leak_reject
 cmp r10,3
 je .cleanup_closed_result
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_MOVED
 je .use_after_move_receiver
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_DROPPED
 je .double_drop_receiver
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_SHARED
 je .move_while_borrowed_receiver
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_UNIQUE
 je .move_while_borrowed_receiver
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 jne .unavailable_receiver
 test qword [rax+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],NEBOC_CLEANUP_REQUIRED
 jz .unavailable_receiver
 cmp r10,2
 je .cleanup_schedule
 mov rdi,r12
 mov rsi,rax
 call rf27g04_cleanup_symbol
 test eax,eax
 jnz .internal
 xor ecx,ecx
 jmp .cleanup_result
.cleanup_schedule:
 test qword [rax+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],NEBOC_CLEANUP_DEFERRED
 jnz .unavailable_receiver
 or qword [rax+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],NEBOC_CLEANUP_DEFERRED
 mov ecx,1
 jmp .cleanup_result
.cleanup_closed_result:
 xor ecx,ecx
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_DROPPED
 sete cl
 jmp .cleanup_result
.cleanup_leak_reject:
 cmp qword [rax+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 jne .unavailable_receiver
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 jne .unavailable_receiver
 mov rdi,r12
 mov esi,NEBOC_DIAG_RESOURCE_LEAK_PATH
 mov rdx,r11
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.cleanup_result:
 mov eax,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done

.bytes_empty:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unavailable_token
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call rf27g04_receiver_is_bytes_type
 test eax,eax
 jz .unavailable_token
 xor ecx,ecx
 jmp .bytes_result
.bytes_one:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .unavailable_token
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call rf27g04_receiver_is_bytes_type
 test eax,eax
 jz .unavailable_token
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call rf27g04_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 call rf27g04_byte_literal
 test eax,eax
 jz .unavailable_token
 mov ecx,1
 jmp .bytes_result
.bytes_four:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],4
 jne .unavailable_token
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call rf27g04_receiver_is_bytes_type
 test eax,eax
 jz .unavailable_token
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call rf27g04_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov ebx,4
.byte_loop:
 test r13,r13
 jz .unavailable
 mov rdi,r12
 mov rsi,r13
 call rf27g04_byte_literal
 test eax,eax
 jz .unavailable
 mov rdi,r12
 mov rsi,r13
 call rf27g04_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec ebx
 jnz .byte_loop
 mov ecx,4
.bytes_result:
 mov eax,NEBOC_BIND_TYPE_BYTES
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done
.byte_length:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .unavailable_token
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor edx,edx
 call rf27g04_eval_expr
 cmp rax,NEBOC_BIND_TYPE_BYTES
 jne .unavailable_token
 mov eax,NEBOC_BIND_TYPE_INT
 mov edx,NEBOC_CATEGORY_COPY
 jmp .done

.use_after_move:
 mov rdi,r12
 mov esi,NEBOC_DIAG_USE_AFTER_MOVE
 mov rdx,rbx
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.use_after_move_receiver:
 mov rdi,r12
 mov esi,NEBOC_DIAG_USE_AFTER_MOVE
 mov rdx,r11
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.double_drop:
 mov rdi,r12
 mov esi,NEBOC_DIAG_DOUBLE_DROP
 mov rdx,rbx
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.double_drop_receiver:
 mov rdi,r12
 mov esi,NEBOC_DIAG_DOUBLE_DROP
 mov rdx,r11
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.borrow_conflict:
 mov rdi,r12
 mov esi,NEBOC_DIAG_BORROW_CONFLICT
 mov rdx,rbx
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.borrow_conflict_receiver:
 mov rdi,r12
 mov esi,NEBOC_DIAG_BORROW_CONFLICT
 mov rdx,r11
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.move_while_borrowed_receiver:
 mov rdi,r12
 mov esi,NEBOC_DIAG_MOVE_WHILE_BORROWED
 mov rdx,r11
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.borrow_escape:
 mov rdi,r12
 mov esi,NEBOC_DIAG_BORROW_ESCAPE
 mov rdx,rbx
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.borrow_escape_receiver:
 mov rdi,r12
 mov esi,NEBOC_DIAG_BORROW_ESCAPE
 mov rdx,r11
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.copy_unique:
 mov rdi,r12
 mov esi,NEBOC_DIAG_COPY_UNIQUE
 mov rdx,rbx
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.copy_unique_receiver:
 mov rdi,r12
 mov esi,NEBOC_DIAG_COPY_UNIQUE
 mov rdx,r11
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.unavailable_receiver:
 mov rbx,r11
.unavailable_token:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CLONE_UNAVAILABLE
 mov rdx,rbx
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.unavailable:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CLONE_UNAVAILABLE
 xor edx,edx
 call rf27g04_set_error
 mov rax,-1
 jmp .done
.internal:
 mov qword [r12+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov rax,-1
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, node id -> 1 iff identifier is canonical Bytes.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rf27g04_receiver_is_bytes_type:
 push r12
 sub rsp,8
 mov r12,rdi
 mov rdi,r12
 call rf27g04_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_bytes]
 mov ecx,n_bytes_len
 call rf27g04_token_match
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r12
 ret

; request*, node id -> 1 iff Int literal lies in 0..255.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rf27g04_byte_literal:
 mov rax,rsi
 call rf27g04_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .no
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],255
 ja .no
 mov eax,1
 ret
.no: xor eax,eax
 ret

; request*, live unique-owner symbol* -> Status.  The ledger records one
; exactly-once cleanup and hashes declaration tokens in actual cleanup order.
%undef call
rf27g04_cleanup_symbol:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 jne .internal
 cmp qword [rsi+NEBOC_SYMBOL_CATEGORY_OFFSET],NEBOC_CATEGORY_UNIQUE_OWNER
 jne .internal
 test qword [rsi+NEBOC_SYMBOL_CLEANUP_FLAGS_OFFSET],NEBOC_CLEANUP_REQUIRED
 jz .internal
 mov rax,[rdi+NEBOC_SEM_CLEANUP_ORDER_HASH_OFFSET]
 mov r8,1099511628211
 mov rcx,[rsi+neboc_text_char_unicode_e_bytes_SYMBOL_NAME_TOKEN_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLEANUP_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov [rdi+NEBOC_SEM_CLEANUP_ORDER_HASH_OFFSET],rax
 inc qword [rdi+NEBOC_SEM_CLEANUP_COUNT_OFFSET]
 inc qword [rdi+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET]
 mov qword [rsi+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],neboc_text_char_unicode_e_bytes_STATE_DROPPED
 xor eax,eax
 ret
.internal:
 mov qword [rdi+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; request*, live borrow symbol* -> Status. Owner state is restored only after
; the final shared token or the single unique token has ended.
rf27g04_release_borrow_symbol:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 jne .internal
 mov rax,[rsi+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET]
 test rax,rax
 jz .internal
 mov rcx,[rsi+NEBOC_SYMBOL_CATEGORY_OFFSET]
 cmp rcx,NEBOC_CATEGORY_SHARED_BORROW
 je .shared
 cmp rcx,NEBOC_CATEGORY_UNIQUE_BORROW
 jne .internal
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_UNIQUE
 jne .internal
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
 mov qword [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET],0
 jmp .released
.shared:
 cmp qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_BORROWED_SHARED
 jne .internal
 cmp qword [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET],0
 je .internal
 dec qword [rax+NEBOC_SYMBOL_ORIGIN_NODE_OFFSET]
 jnz .released
 mov qword [rax+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_LIVE
.released:
 mov qword [rsi+neboc_text_char_unicode_e_bytes_SYMBOL_STATE_OFFSET],NEBOC_STATE_RELEASED
 xor eax,eax
 ret
.internal:
 mov qword [rdi+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; request*, name token -> latest symbol or zero.
rf27g04_find_symbol:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 test r14,r14
 jz .none
 dec r14
.loop:
 mov rax,r14
 imul rax,NEBOC_SYMBOL_SIZE
 add rax,[r12+NEBOC_SEM_SYMBOLS_OFFSET]
 mov rbx,rax
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rbx+neboc_text_char_unicode_e_bytes_SYMBOL_NAME_TOKEN_OFFSET]
 call rf27g04_names_equal
 test eax,eax
 jnz .yes
 test r14,r14
 jz .none
 dec r14
 jmp .loop
.yes: mov rax,rbx
 jmp .done
.none: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, two token indexes -> 1 iff source spellings are equal.
rf27g04_names_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call rf27g04_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call rf27g04_token_ptr
 test rax,rax
 jz .no
 mov r15,rax
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[r15+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[r15+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 mov rsi,[r12+NEBOC_SEM_SOURCE_OFFSET]
 add rsi,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdi,[r12+NEBOC_SEM_SOURCE_OFFSET]
 add rdi,[r15+NEBOC_TOKEN_START_OFFSET]
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no: xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, token index, bytes, length -> 1/0.
rf27g04_token_match:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov ebx,ecx
 mov rdi,r12
 mov rsi,r13
 call rf27g04_token_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rbx
 jne .no
 mov rsi,[r12+NEBOC_SEM_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,r14
 mov rcx,rbx
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

rf27g04_node_ptr:
 test rsi,rsi
 jz .none
 ; Builder pointer is not a count; load it before the bounded ID check.
 mov rax,[rdi+NEBOC_SEM_BUILDER_OFFSET]
 cmp rsi,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .none
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 add rsi,[rax+NEBOC_AST_BUILDER_DATA_OFFSET]
 mov rax,rsi
 ret
.none: xor eax,eax
 ret

rf27g04_token_ptr:
 cmp rsi,[rdi+NEBOC_SEM_TOKEN_COUNT_OFFSET]
 jae .none
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_SEM_TOKENS_OFFSET]
 ret
.none: xor eax,eax
 ret

; request*, diagnostic, token -> INVALID_SOURCE.
rf27g04_set_error:
 push r12
 mov r12,rdi
 mov [rdi+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],rsi
 mov [rdi+NEBOC_SEM_ERROR_TOKEN_OFFSET],rdx
 mov rsi,rdx
 call rf27g04_token_ptr
 test rax,rax
 jz .no_span
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_START_OFFSET_semantic_memory_native_vertical],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_SEM_ERROR_END_OFFSET_semantic_memory_native_vertical],rcx
.no_span:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop r12
 ret

; Stable hash over semantic product fields (not transport pointers).
rf27g04_semantic_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 mov rcx,[rdi+NEBOC_SEM_FOUND_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_OPERATION_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_SYMBOL_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_memory_native_vertical]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_RESULT_VALUE_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_COPY_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_MOVE_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLONE_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLEANUP_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLEANUP_ORDER_HASH_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_CLOSED_OWNER_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_SAFETY_PROOF_HASH_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[rdi+NEBOC_SEM_LAYOUT_ID_OFFSET]
 xor rax,rcx
 imul rax,r8
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
