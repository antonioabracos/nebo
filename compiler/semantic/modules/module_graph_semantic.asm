; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F05 bounded module graph, visibility and cycle analysis.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/module_parser.inc"

extern neboc_module_resolve_export

section .text

NEBOC_ABI_FUNCTION neboc_module_analyze
 test rdi,rdi
 jz .invalid
 test rdi,NEBOC_MODULE_ALIGNMENT-1
 jnz .invalid
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 cmp qword [r12+NEBOC_MODULE_FOUND_OFFSET],1
 jne .invalid_state
 cmp qword [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],0
 jne .invalid_state
 cmp qword [r12+NEBOC_MODULE_UNIT_COUNT_OFFSET],NEBOC_MODULE_MAX_UNITS
 jne .capacity
 cmp qword [r12+NEBOC_MODULE_FLAGS_OFFSET],NEBOC_MODULE_FLAG_PARSED
 jne .invalid_state
 mov r13,[r12+NEBOC_MODULE_RECORDS_OFFSET]
 test r13,r13
 jz .invalid_state
 test r13,NEBOC_MODULE_ALIGNMENT-1
 jnz .invalid_state
 mov qword [rsp],0
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],0
 mov qword [r12+NEBOC_MODULE_ROOT_INDEX_OFFSET],-1
 mov qword [r12+NEBOC_MODULE_RESULT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_EDGE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_PUBLIC_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_PRIVATE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_START_REF_COUNT_OFFSET],0

 ; Module identity is the canonical namespace key.  A repeated key (including
 ; a theoretical hash collision) is rejected before graph construction.
 xor ebx,ebx
.identity_outer:
 cmp ebx,NEBOC_MODULE_MAX_UNITS
 jae .summarize
 mov rdx,rbx
 shl rdx,7
 mov rax,[r13+rdx+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 test rax,rax
 jz .invalid_state
 lea rbp,[rbx+1]
.identity_inner:
 cmp ebp,NEBOC_MODULE_MAX_UNITS
 jae .identity_next
 mov rcx,rbp
 shl rcx,7
 cmp rax,[r13+rcx+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 je .identity_collision
 inc rbp
 jmp .identity_inner
.identity_next:
 inc rbx
 jmp .identity_outer

.summarize:
 xor ebx,ebx
 xor r14d,r14d
 mov r15,0x9e3779b97f4a7c15
.summary_loop:
 cmp ebx,NEBOC_MODULE_MAX_UNITS
 jae .root_check
 mov rdx,rbx
 shl rdx,7
 lea rbp,[r13+rdx]
 mov rax,[rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET]
 test rax,NEBOC_MODULE_RECORD_EXPORT
 jz .summary_start
 mov rcx,[rbp+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET]
 cmp rcx,NEBOC_MODULE_VISIBILITY_PUBLIC
 je .count_public
 cmp rcx,NEBOC_MODULE_VISIBILITY_INTERNAL
 je .count_non_public
 cmp rcx,NEBOC_MODULE_VISIBILITY_PRIVATE
 jne .invalid_state
.count_non_public:
 inc qword [r12+NEBOC_MODULE_PRIVATE_COUNT_OFFSET]
 jmp .summary_start
.count_public:
 inc qword [r12+NEBOC_MODULE_PUBLIC_COUNT_OFFSET]
.summary_start:
 test rax,NEBOC_MODULE_RECORD_START
 jz .canonical_rank
 cmp qword [r12+NEBOC_MODULE_ROOT_INDEX_OFFSET],-1
 jne .identity_collision
 mov [r12+NEBOC_MODULE_ROOT_INDEX_OFFSET],rbx
 mov rcx,[rbp+NEBOC_MODULE_RECORD_START_COUNT_OFFSET]
 test rcx,rcx
 jz .invalid_state
 cmp rcx,NEBOC_MODULE_MAX_START_REFS
 ja .capacity
 mov [r12+NEBOC_MODULE_START_REF_COUNT_OFFSET],rcx
.canonical_rank:
 xor ecx,ecx
 xor edx,edx
 mov rax,[rbp+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
.rank_loop:
 cmp edx,NEBOC_MODULE_MAX_UNITS
 jae .rank_done
 mov r8,rdx
 shl r8,7
 cmp [r13+r8+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET],rax
 jae .rank_next
 inc rcx
.rank_next:
 inc rdx
 jmp .rank_loop
.rank_done:
 mov [rbp+NEBOC_MODULE_RECORD_CANONICAL_INDEX_OFFSET],rcx
 ; Commutative authenticated graph summary, stable under auxiliary argv order.
 mov rax,[rbp+NEBOC_MODULE_RECORD_SOURCE_HASH_OFFSET]
 xor rax,[rbp+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 rol rax,17
 xor r14,rax
 add r15,rax
 inc rbx
 jmp .summary_loop

.root_check:
 cmp qword [r12+NEBOC_MODULE_ROOT_INDEX_OFFSET],-1
 je .missing_export
 xor r14,r15
 test r14,r14
 jnz .graph_seed_ok
 mov r14,1
.graph_seed_ok:
 mov [r12+NEBOC_MODULE_GRAPH_HASH_OFFSET],r14

 ; Resolve every import to a bounded unit index and form three adjacency masks.
 xor ebx,ebx
.edge_unit:
 cmp ebx,NEBOC_MODULE_MAX_UNITS
 jae .closure
 mov rdx,rbx
 shl rdx,7
 lea rbp,[r13+rdx]
 xor r14d,r14d
.edge_import:
 cmp r14,[rbp+NEBOC_MODULE_RECORD_IMPORT_COUNT_OFFSET]
 jae .edge_next_unit
 mov rax,[rbp+r14*8+NEBOC_MODULE_RECORD_IMPORT0_HASH_OFFSET]
 xor ecx,ecx
.edge_find:
 cmp ecx,NEBOC_MODULE_MAX_UNITS
 jae .missing_unit
 mov rdx,rcx
 shl rdx,7
 cmp rax,[r13+rdx+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 je .edge_found
 inc rcx
 jmp .edge_find
.edge_found:
 bts qword [rsp+rbx*8],rcx
 inc qword [r12+NEBOC_MODULE_EDGE_COUNT_OFFSET]
 inc r14
 jmp .edge_import
.edge_next_unit:
 inc rbx
 jmp .edge_unit

 ; Three-node transitive closure; a diagonal bit proves an import cycle.
.closure:
 xor r14d,r14d
.closure_k:
 cmp r14d,NEBOC_MODULE_MAX_UNITS
 jae .cycle_check
 xor ebx,ebx
.closure_i:
 cmp ebx,NEBOC_MODULE_MAX_UNITS
 jae .closure_next_k
 bt qword [rsp+rbx*8],r14
 jnc .closure_next_i
 mov rax,[rsp+r14*8]
 or [rsp+rbx*8],rax
.closure_next_i:
 inc rbx
 jmp .closure_i
.closure_next_k:
 inc r14
 jmp .closure_k
.cycle_check:
 xor ebx,ebx
.cycle_loop:
 cmp ebx,NEBOC_MODULE_MAX_UNITS
 jae .resolve_start
 bt qword [rsp+rbx*8],rbx
 jc .cycle
 inc rbx
 jmp .cycle_loop

.resolve_start:
 mov rbx,[r12+NEBOC_MODULE_ROOT_INDEX_OFFSET]
 mov rdx,rbx
 shl rdx,7
 lea rbp,[r13+rdx]
 xor r14d,r14d
 xor r15d,r15d
.reference_loop:
 cmp r14,[rbp+NEBOC_MODULE_RECORD_START_COUNT_OFFSET]
 jae .semantic_done
 mov rdx,r14
 shl rdx,4
 mov rax,[rbp+rdx+NEBOC_MODULE_RECORD_START0_MODULE_OFFSET]
 mov r11,[rbp+rdx+NEBOC_MODULE_RECORD_START0_SYMBOL_OFFSET]
 test qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_MODERN_IMPORTS
 jz .reference_namespace_ready
 sub rsp,8
 call module_import_resolve_namespace
 jnc .reference_namespace_call_ok
 add rsp,8
 jmp .import_resolution_failed
.reference_namespace_call_ok:
 add rsp,8
.reference_namespace_ready:
 xor ecx,ecx
.reference_find_module:
 cmp ecx,NEBOC_MODULE_MAX_UNITS
 jae .missing_unit
 mov rdx,rcx
 shl rdx,7
 cmp rax,[r13+rdx+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 je .reference_module_found
 inc rcx
 jmp .reference_find_module
.reference_module_found:
 cmp rcx,rbx
 je .reference_imported
 ; Visibility resolution is intentionally direct-import only.
 xor r8d,r8d
.reference_import_loop:
 cmp r8,[rbp+NEBOC_MODULE_RECORD_IMPORT_COUNT_OFFSET]
 jae .missing_unit
 cmp rax,[rbp+r8*8+NEBOC_MODULE_RECORD_IMPORT0_HASH_OFFSET]
 je .reference_imported
 inc r8
 jmp .reference_import_loop
.reference_imported:
 mov rdi,r12
 mov rsi,rcx
 mov rdx,r11
 sub rsp,8
 call neboc_module_resolve_export
 add rsp,8
 test eax,eax
 jnz .export_resolution_failed
 mov r9,rdx
 cmp qword [r9+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PRIVATE
 jne .reference_value
 cmp rcx,rbx
 jne .private_access
.reference_value:
 add r15,[r9+NEBOC_MODULE_RECORD_EXPORT_VALUE_OFFSET]
 cmp r15,255
 ja .capacity
 inc r14
 jmp .reference_loop

.semantic_done:
 mov [r12+NEBOC_MODULE_RESULT_OFFSET],r15
 mov r10,1099511628211
 mov rax,[r12+NEBOC_MODULE_GRAPH_HASH_OFFSET]
 xor rax,r15
 imul rax,r10
 xor rax,[r12+NEBOC_MODULE_EDGE_COUNT_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_MODULE_PUBLIC_COUNT_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_MODULE_PRIVATE_COUNT_OFFSET]
 imul rax,r10
 xor rax,[r12+NEBOC_MODULE_START_REF_COUNT_OFFSET]
 test rax,rax
 jnz .semantic_hash_ok
 mov rax,1
.semantic_hash_ok:
 mov [r12+NEBOC_MODULE_SEMANTIC_HASH_OFFSET],rax
 mov qword [r12+NEBOC_MODULE_FLAGS_OFFSET],NEBOC_MODULE_FLAG_PARSED|NEBOC_MODULE_FLAG_ANALYZED
 xor eax,eax
 jmp .done

.missing_unit:
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_MISSING_UNIT
 jmp .failure
.export_resolution_failed:
 mov eax,edx
 jmp .failure
.import_resolution_failed:
 mov rax,[r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .failure
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_MISSING_UNIT
 jmp .failure
.private_access:
 mov eax,NEBOC_MODULE_DIAG_PRIVATE_ACCESS
 jmp .failure
.cycle:
 mov eax,NEBOC_MODULE_DIAG_IMPORT_CYCLE
 jmp .failure
.identity_collision:
 mov eax,NEBOC_MODULE_DIAG_IDENTITY_COLLISION
 jmp .failure
.missing_export:
 mov eax,NEBOC_MODULE_DIAG_MISSING_EXPORT
 jmp .failure
.capacity:
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_CAPACITY
 jmp .failure
.invalid_state:
 mov eax,NEBOC_MODULE_DIAG_INTERNAL
.failure:
 mov [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],rax
 mov qword [r12+NEBOC_MODULE_RESULT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_SEMANTIC_HASH_OFFSET],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 cld
 ret
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Resolve the source namespace in RAX through the root's canonical G151 AST.
; R11 is the referenced symbol. Named capsules select the unique entry that
; publicly exports that symbol; anonymous/simple forms expose entry aliases.
module_import_resolve_namespace:
 mov r8,[r12+NEBOC_MODULE_IMPORT_ASTS_OFFSET]
 test r8,r8
 jz .bad
 mov rdx,rbx
 imul rdx,NEBOC_IMPORT_AST_SIZE
 add r8,rdx
 mov rdx,[r8+NEBOC_IMPORT_AST_FORM_OFFSET]
 cmp rdx,NEBOC_IMPORT_FORM_NAMED_CAPSULE
 je .named
 cmp rax,[r8+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 je .alias0
 cmp qword [r8+NEBOC_IMPORT_AST_COUNT_OFFSET],2
 jb .bad
 cmp rax,[r8+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET]
 jne .bad
 mov rax,[r8+NEBOC_IMPORT_AST_TARGET1_HASH_OFFSET]
 clc
 ret
.alias0:
 cmp qword [r8+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .alias0_ready
 xor r9d,r9d
.selective_symbol:
 cmp r9,[r8+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET]
 jae .selective_missing
 cmp r11,[r8+r9*8+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET]
 je .alias0_ready
 inc r9
 jmp .selective_symbol
.selective_missing:
 mov qword [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_SELECTIVE_MISSING
 stc
 ret
.alias0_ready:
 mov rax,[r8+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 clc
 ret
.named:
 cmp rax,[r8+NEBOC_IMPORT_AST_CAPSULE_HASH_OFFSET]
 jne .bad
 xor r9d,r9d                  ; entry index
 xor r10d,r10d                ; selected module hash
.named_entry:
 cmp r9,[r8+NEBOC_IMPORT_AST_COUNT_OFFSET]
 jae .named_done
 mov rdx,r9
 imul rdx,40
 mov rax,[r8+rdx+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 xor ecx,ecx
.named_find_module:
 cmp ecx,NEBOC_MODULE_MAX_UNITS
 jae .named_next
 mov rdx,rcx
 shl rdx,7
 cmp rax,[r13+rdx+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET]
 jne .named_find_next
 sub rsp,40
 mov [rsp],r8
 mov [rsp+8],r9
 mov [rsp+16],r10
 mov [rsp+24],rax
 mov [rsp+32],r11
 mov rdi,r12
 mov rsi,rcx
 mov rdx,r11
 call neboc_module_resolve_export
 test eax,eax
 jnz .named_no_export
 cmp qword [rdx+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PUBLIC
 jne .named_no_export
 mov edx,1
 jmp .named_export_result
.named_no_export:
 xor edx,edx
.named_export_result:
 mov r8,[rsp]
 mov r9,[rsp+8]
 mov r10,[rsp+16]
 mov rax,[rsp+24]
 mov r11,[rsp+32]
 add rsp,40
 test edx,edx
 jz .named_next
 test r10,r10
 jnz .ambiguous
 mov r10,rax
 jmp .named_next
.named_find_next:
 inc ecx
 jmp .named_find_module
.named_next:
 inc r9
 jmp .named_entry
.named_done:
 test r10,r10
 jz .bad
 mov rax,r10
 clc
 ret
.ambiguous:
 mov qword [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_AMBIGUOUS_SYMBOL
.bad:
 stc
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
