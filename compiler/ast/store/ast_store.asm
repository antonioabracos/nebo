; Nebo Assembly — MF020 immutable AstStore, NodeIds and validation
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/support/hash/fnv1a.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"

extern neboc_ast_builder_finalize

section .text

; ast_store_freeze(store*, builder*, destination_nodes*, parent_ids*, capacity,
;                  root_id)
; Copies the provisional builder nodes into caller-owned immutable storage,
; finalizes the builder, validates the tree and records a deterministic hash.
NEBOC_ABI_FUNCTION neboc_ast_store_freeze
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r9
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 test r8,r8
 jz .invalid
 mov r10,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 test r10,r10
 jz .invalid
 cmp r10,r8
 ja .limit
 test rbx,rbx
 jz .invalid
 cmp rbx,r10
 ja .invalid
 mov r11,[r13+NEBOC_AST_BUILDER_DATA_OFFSET]
 test r11,r11
 jz .invalid

 ; Reject partially overlapping node regions; exact in-place freeze is allowed.
 mov rax,r10
 imul rax,NEBOC_AST_NODE_SIZE
 lea rdx,[r11+rax]                  ; source end
 lea rcx,[r14+rax]                  ; destination end
 cmp r14,r11
 je .node_regions_ready
 cmp r14,rdx
 jae .node_regions_ready
 cmp r11,rcx
 jae .node_regions_ready
 jmp .invalid
.node_regions_ready:
 ; The parent side table must not overlap either node region.
 mov rax,r10
 imul rax,8
 lea r9,[r15+rax]                   ; parent table end
 cmp r15,rdx
 jae .parent_vs_source_ready
 cmp r11,r9
 jae .parent_vs_source_ready
 jmp .invalid
.parent_vs_source_ready:
 cmp r15,rcx
 jae .regions_ready
 cmp r14,r9
 jae .regions_ready
 jmp .invalid
.regions_ready:

 ; Clear the store descriptor and parent side table before publishing it.
 mov rdi,r12
 xor eax,eax
 mov ecx,NEBOC_AST_STORE_QWORDS
 rep stosq
 mov rdi,r15
 mov rcx,r10
 rep stosq

 ; Freeze the producer API before copying/publishing the AST.
 mov rdi,r13
 call neboc_ast_builder_finalize
 test eax,eax
 jnz .done
 ; The finalize call may clobber caller-saved registers.
 mov r10,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov r11,[r13+NEBOC_AST_BUILDER_DATA_OFFSET]

 cmp r14,r11
 je .copy_done
 mov rdi,r14
 mov rsi,r11
 mov rcx,r10
 imul rcx,NEBOC_AST_NODE_QWORDS
 rep movsq
.copy_done:
 mov [r12+NEBOC_AST_STORE_DATA_OFFSET],r14
 mov [r12+NEBOC_AST_STORE_COUNT_OFFSET],r10
 mov [r12+NEBOC_AST_STORE_ROOT_ID_OFFSET],rbx
 mov [r12+NEBOC_AST_STORE_PARENTS_OFFSET],r15
 mov qword [r12+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_FROZEN
 mov qword [r12+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_NONE
 mov qword [r12+NEBOC_AST_STORE_HASH_OFFSET],0
 mov qword [r12+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET],0
 mov qword [r12+NEBOC_AST_STORE_VALIDATION_ERROR_OFFSET],NEBOC_AST_VALIDATION_NONE

 mov rdi,r12
 call neboc_ast_store_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[r12+NEBOC_AST_STORE_HASH_OFFSET]
 call neboc_ast_store_compute_hash
 test eax,eax
 jnz .done
 mov qword [r12+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
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

; ast_store_validate(store*)
; Validates kind/span/ID/child-order invariants and constructs the parent-ID
; side table. A valid ErrorNode is recorded but does not make the tree invalid.
NEBOC_ABI_FUNCTION neboc_ast_store_validate
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .bad_argument
 mov r13,[r12+NEBOC_AST_STORE_DATA_OFFSET]
 mov r14,[r12+NEBOC_AST_STORE_COUNT_OFFSET]
 mov r15,[r12+NEBOC_AST_STORE_PARENTS_OFFSET]
 test r13,r13
 jz .bad_store
 test r14,r14
 jz .bad_store
 test r15,r15
 jz .bad_store
 mov rax,[r12+NEBOC_AST_STORE_ROOT_ID_OFFSET]
 test rax,rax
 jz .bad_root
 cmp rax,r14
 ja .bad_root
 mov [rsp],rax                    ; root ID
 mov qword [rsp+8],0              ; total child edges
 mov qword [rsp+16],1             ; current parent ID
 mov qword [rsp+24],0             ; current node pointer
 mov qword [r12+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_NONE
 mov qword [r12+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET],0
 mov qword [r12+NEBOC_AST_STORE_VALIDATION_ERROR_OFFSET],NEBOC_AST_VALIDATION_NONE

 ; Parent table is output-only and deterministic.
 mov rdi,r15
 xor eax,eax
 mov rcx,r14
 rep stosq

.node_loop:
 mov rbx,[rsp+16]
 cmp rbx,r14
 ja .nodes_done
 mov rax,rbx
 dec rax
 imul rax,NEBOC_AST_NODE_SIZE
 lea r11,[r13+rax]
 mov [rsp+24],r11

 mov rax,[r11+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_PROGRAM
 jb .bad_kind
 cmp rax,NEBOC_AST_MAX_KIND
 ja .bad_kind
 cmp rax,NEBOC_AST_ERROR_NODE
 jne .not_error
 or qword [r12+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_HAS_ERROR
 cmp qword [r12+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET],0
 jne .not_error
 mov [r12+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET],rbx
.not_error:
 cmp qword [r11+NEBOC_AST_NODE_SOURCE_ID_OFFSET],0
 je .bad_id
 mov rax,[r11+NEBOC_AST_NODE_START_OFFSET]
 cmp rax,[r11+NEBOC_AST_NODE_END_OFFSET]
 ja .bad_span

 mov rax,[r11+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 cmp rax,r14
 ja .bad_id
 cmp rax,rbx
 je .bad_child
 mov rcx,[r11+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp rcx,r14
 ja .bad_id
 cmp rcx,rbx
 je .bad_child
 mov rdx,[r11+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp rdx,r14
 ja .bad_child
 test rdx,rdx
 jz .expect_no_first
 test rax,rax
 jz .bad_child
 jmp .walk_children
.expect_no_first:
 test rax,rax
 jnz .bad_child
 jmp .next_node

.walk_children:
 ; RAX=current child ID, RDX=remaining child count.
 test rax,rax
 jz .bad_child
 cmp rax,r14
 ja .bad_id
 cmp rax,rbx
 je .bad_child
 mov rcx,rax
 dec rcx
 lea r10,[r15+rcx*8]
 cmp qword [r10],0
 jne .duplicate_parent
 mov [r10],rbx
 inc qword [rsp+8]
 mov rcx,[rsp+8]
 cmp rcx,r14
 jae .bad_child
 mov rcx,rax
 dec rcx
 imul rcx,NEBOC_AST_NODE_SIZE
 lea r9,[r13+rcx]
 mov rax,[r9+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec rdx
 jnz .walk_children
 test rax,rax
 jnz .bad_child

.next_node:
 inc qword [rsp+16]
 jmp .node_loop

.nodes_done:
 mov rax,r14
 dec rax
 cmp [rsp+8],rax
 jne .disconnected
 mov rbx,[rsp]
 mov rax,rbx
 dec rax
 cmp qword [r15+rax*8],0
 jne .bad_root
 imul rax,NEBOC_AST_NODE_SIZE
 lea r11,[r13+rax]
 cmp qword [r11+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 jne .bad_root
 mov rax,1
.parent_check:
 cmp rax,r14
 ja .valid
 cmp rax,rbx
 je .parent_next
 mov rcx,rax
 dec rcx
 cmp qword [r15+rcx*8],0
 je .disconnected
.parent_next:
 inc rax
 jmp .parent_check
.valid:
 mov qword [r12+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_FROZEN
 xor eax,eax
 jmp .done

.bad_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_store:
 mov edi,NEBOC_AST_VALIDATION_BAD_STORE
 jmp .invalidate
.bad_root:
 mov edi,NEBOC_AST_VALIDATION_BAD_ROOT
 jmp .invalidate
.bad_kind:
 mov edi,NEBOC_AST_VALIDATION_BAD_KIND
 jmp .invalidate
.bad_span:
 mov edi,NEBOC_AST_VALIDATION_BAD_SPAN
 jmp .invalidate
.bad_id:
 mov edi,NEBOC_AST_VALIDATION_BAD_ID
 jmp .invalidate
.bad_child:
 mov edi,NEBOC_AST_VALIDATION_BAD_CHILD_CHAIN
 jmp .invalidate
.duplicate_parent:
 mov edi,NEBOC_AST_VALIDATION_DUPLICATE_PARENT
 jmp .invalidate
.disconnected:
 mov edi,NEBOC_AST_VALIDATION_DISCONNECTED
.invalidate:
 mov [r12+NEBOC_AST_STORE_VALIDATION_ERROR_OFFSET],rdi
 mov qword [r12+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_INVALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ast_store_compute_hash(store*, out_hash*)
; FNV-1a32 over count, root ID, canonical node bytes and parent-ID side table.
NEBOC_ABI_FUNCTION neboc_ast_store_compute_hash
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .hash_invalid
 test r13,r13
 jz .hash_invalid
 mov qword [r13],0
 mov r14,[r12+NEBOC_AST_STORE_DATA_OFFSET]
 mov r15,[r12+NEBOC_AST_STORE_COUNT_OFFSET]
 mov rbx,[r12+NEBOC_AST_STORE_PARENTS_OFFSET]
 test r14,r14
 jz .hash_invalid
 test r15,r15
 jz .hash_invalid
 test rbx,rbx
 jz .hash_invalid
 mov eax,NEBOC_FNV1A32_OFFSET_BASIS
 mov r8,r15
 mov ecx,8
.hash_count:
 movzx r9d,r8b
 xor eax,r9d
 imul eax,eax,NEBOC_FNV1A32_PRIME
 shr r8,8
 dec ecx
 jnz .hash_count
 mov r8,[r12+NEBOC_AST_STORE_ROOT_ID_OFFSET]
 mov ecx,8
.hash_root:
 movzx r9d,r8b
 xor eax,r9d
 imul eax,eax,NEBOC_FNV1A32_PRIME
 shr r8,8
 dec ecx
 jnz .hash_root
 mov r10,r15
 imul r10,NEBOC_AST_NODE_SIZE
 xor r11,r11
.hash_nodes:
 cmp r11,r10
 jae .hash_parents_start
 movzx r9d,byte [r14+r11]
 xor eax,r9d
 imul eax,eax,NEBOC_FNV1A32_PRIME
 inc r11
 jmp .hash_nodes
.hash_parents_start:
 mov r10,r15
 imul r10,8
 xor r11,r11
.hash_parents:
 cmp r11,r10
 jae .hash_store
 movzx r9d,byte [rbx+r11]
 xor eax,r9d
 imul eax,eax,NEBOC_FNV1A32_PRIME
 inc r11
 jmp .hash_parents
.hash_store:
 mov [r13],rax
 xor eax,eax
 jmp .hash_done
.hash_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.hash_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ast_store_verify_immutable(store*)
NEBOC_ABI_FUNCTION neboc_ast_store_verify_immutable
 push rbx
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .verify_invalid
 cmp qword [rbx+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 jne .verify_source
 mov qword [rsp],0
 mov rdi,rbx
 lea rsi,[rsp]
 call neboc_ast_store_compute_hash
 test eax,eax
 jnz .verify_done
 mov rax,[rsp]
 cmp rax,[rbx+NEBOC_AST_STORE_HASH_OFFSET]
 jne .verify_mismatch
 xor eax,eax
 jmp .verify_done
.verify_mismatch:
 mov qword [rbx+NEBOC_AST_STORE_VALIDATION_ERROR_OFFSET],NEBOC_AST_VALIDATION_HASH_MISMATCH
 mov qword [rbx+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_INVALID
.verify_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .verify_done
.verify_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.verify_done:
 add rsp,16
 pop rbx
 cld
 ret

; ast_store_node(store*, node_id, out_node_ptr*)
NEBOC_ABI_FUNCTION neboc_ast_store_node
 test rdi,rdi
 jz .node_invalid
 test rdx,rdx
 jz .node_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .node_invalid
 cmp rsi,[rdi+NEBOC_AST_STORE_COUNT_OFFSET]
 ja .node_invalid
 mov rax,[rdi+NEBOC_AST_STORE_STATE_OFFSET]
 cmp rax,NEBOC_AST_STORE_STATE_FROZEN
 je .node_state_ready
 cmp rax,NEBOC_AST_STORE_STATE_VALIDATED
 jne .node_invalid
.node_state_ready:
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 add rsi,[rdi+NEBOC_AST_STORE_DATA_OFFSET]
 mov [rdx],rsi
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.node_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; ast_store_require_clean(store*)
; Downstream consumers must call this gate before consuming the AST.
NEBOC_ABI_FUNCTION neboc_ast_store_require_clean
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .clean_invalid
 mov rdi,rbx
 call neboc_ast_store_verify_immutable
 test eax,eax
 jnz .clean_done
 test qword [rbx+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_HAS_ERROR
 jnz .clean_source
 cmp qword [rbx+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET],0
 jne .clean_source
 xor eax,eax
 jmp .clean_done
.clean_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .clean_done
.clean_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.clean_done:
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
