; G151 deterministic import namespace binding and resolution.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"

section .text

; Legacy table surface: resolve_alias(pairs[alias,module], count, alias,
; out_module). Identical duplicate bindings converge; incompatible duplicates
; are rejected instead of depending on insertion order.
NEBOC_ABI_FUNCTION neboc_import_resolve_alias
 test rdi,rdi
 jz .arg
 test r8,r8
 jz .arg
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_IMPORT_MAX_ITEMS
 ja .limit
 xor ecx,ecx
 xor r9d,r9d
.loop:
 cmp rcx,rsi
 jae .publish
 mov rax,rcx
 shl rax,4
 cmp rdx,[rdi+rax]
 jne .next
 mov r10,[rdi+rax+8]
 test r10,r10
 jz .source
 test r9,r9
 jz .remember
 cmp r9,r10
 jne .source
 jmp .next
.remember:
 mov r9,r10
.next:
 inc rcx
 jmp .loop
.publish:
 test r9,r9
 jz .source
 mov [r8],r9
 xor eax,eax
 ret
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; ImportAlias.bind(ast, entry_index, alias_hash, module_hash) -> status.
; This is a proof/checking API: the parser remains the unique publisher.
NEBOC_ABI_FUNCTION neboc_import_alias_bind
 test rdi,rdi
 jz .arg
 test rdi,NEBOC_IMPORT_AST_ALIGNMENT-1
 jnz .arg
 cmp rsi,[rdi+NEBOC_IMPORT_AST_COUNT_OFFSET]
 jae .source
 test rdx,rdx
 jz .source
 test rcx,rcx
 jz .source
 imul rsi,40
 cmp rdx,[rdi+rsi+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 jne .source
 cmp rcx,[rdi+rsi+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 jne .source
 xor eax,eax
 ret
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE

; ImportResolver.resolve(ast, namespace_hash, out_module_hash) -> status.
NEBOC_ABI_FUNCTION neboc_import_resolve
 test rdi,rdi
 jz .arg
 test rdx,rdx
 jz .arg
 test rsi,rsi
 jz .source
 mov rax,[rdi+NEBOC_IMPORT_AST_FORM_OFFSET]
 cmp rax,NEBOC_IMPORT_FORM_NAMED_CAPSULE
 jne .aliases
 cmp rsi,[rdi+NEBOC_IMPORT_AST_CAPSULE_HASH_OFFSET]
 jne .source
 ; A named capsule with one entry resolves without export context. For two
 ; entries the semantic owner must use explain/exports to disambiguate.
 cmp qword [rdi+NEBOC_IMPORT_AST_COUNT_OFFSET],1
 jne .ambiguous
 mov rax,[rdi+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 jmp .publish
.aliases:
 cmp rsi,[rdi+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 je .first
 cmp qword [rdi+NEBOC_IMPORT_AST_COUNT_OFFSET],2
 jb .source
 cmp rsi,[rdi+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET]
 jne .source
 mov rax,[rdi+NEBOC_IMPORT_AST_TARGET1_HASH_OFFSET]
 jmp .publish
.first:
 mov rax,[rdi+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
.publish:
 test rax,rax
 jz .source
 mov [rdx],rax
 xor eax,eax
 ret
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.ambiguous:
 mov eax,NEBOC_IMPORT_DIAG_AMBIGUOUS_SYMBOL
 ret
.source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE

; imports.detectCollisions(ast, out_diagnostic) -> status. The output is zero
; for a clean AST and a stable G151 diagnostic for a rejected relation.
NEBOC_ABI_FUNCTION neboc_import_detect_collisions
 test rdi,rdi
 jz .arg
 test rsi,rsi
 jz .arg
 mov qword [rsi],0
 mov rax,[rdi+NEBOC_IMPORT_AST_COUNT_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_IMPORT_MAX_ITEMS
 ja .limit
 cmp rax,1
 je .capsule
 mov rax,[rdi+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 cmp rax,[rdi+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET]
 je .alias
 mov rax,[rdi+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 cmp rax,[rdi+NEBOC_IMPORT_AST_TARGET1_HASH_OFFSET]
 je .alias
.capsule:
 mov rax,[rdi+NEBOC_IMPORT_AST_FORM_OFFSET]
 cmp rax,NEBOC_IMPORT_FORM_NAMED_CAPSULE
 jne .ok
 mov rax,[rdi+NEBOC_IMPORT_AST_CAPSULE_HASH_OFFSET]
 test rax,rax
 jz .capsule_bad
 cmp rax,[rdi+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 je .capsule_bad
 cmp qword [rdi+NEBOC_IMPORT_AST_COUNT_OFFSET],2
 jb .ok
 cmp rax,[rdi+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET]
 je .capsule_bad
.ok:
 xor eax,eax
 ret
.alias:
 mov qword [rsi],NEBOC_IMPORT_DIAG_ALIAS_COLLISION
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.capsule_bad:
 mov qword [rsi],NEBOC_IMPORT_DIAG_CAPSULE_COLLISION
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; imports.importedModules(ast, out_hashes, capacity, out_count) -> status.
NEBOC_ABI_FUNCTION neboc_import_modules
 test rdi,rdi
 jz .arg
 test rsi,rsi
 jz .arg
 test rcx,rcx
 jz .arg
 mov rax,[rdi+NEBOC_IMPORT_AST_COUNT_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_IMPORT_MAX_ITEMS
 ja .source
 cmp rdx,rax
 jb .limit
 mov r8,[rdi+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 mov [rsi],r8
 cmp rax,2
 jb .count
 mov r8,[rdi+NEBOC_IMPORT_AST_TARGET1_HASH_OFFSET]
 mov [rsi+8],r8
.count:
 mov [rcx],rax
 xor eax,eax
 ret
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; imports.explain(ast, namespace_hash, symbol_hash, out[form,target,symbol,trace])
; -> status. For a multi-entry named capsule, export-aware resolution is
; deliberately required and this bounded API reports ambiguity.
NEBOC_ABI_FUNCTION neboc_import_explain
 test r8,r8
 jz .arg
 push rbx
 push r12
 push r13
 sub rsp,16
 mov rbx,r8
 mov r12,rdi
 mov r13,rdx
 mov rdx,rsp
 call neboc_import_resolve
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_IMPORT_AST_FORM_OFFSET]
 mov [rbx],rax
 mov rax,[rsp]
 mov [rbx+8],rax
 mov [rbx+16],r13
 mov rax,[r12+NEBOC_IMPORT_AST_TRACE_HASH_OFFSET]
 mov [rbx+24],rax
 xor eax,eax
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret
.arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
