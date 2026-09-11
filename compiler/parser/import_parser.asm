; G151/G152 canonical imports. Selective imports and explicit reexports extend
; the same pointerless ImportAstNode used by simple imports and capsules.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"

section .rodata
imp_kw_import: db 'import '
imp_kw_import_len equ $-imp_kw_import
imp_kw_export: db 'export '
imp_kw_export_len equ $-imp_kw_export

section .text

; ImportDecl.parse(bytes, length, out_ast) -> status
; Parses exactly one declaration (plus trailing trivia). The AST contains no
; source pointers and is published only after the whole declaration succeeds.
NEBOC_ABI_FUNCTION neboc_import_decl_parse
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 test rdx,NEBOC_IMPORT_AST_ALIGNMENT-1
 jnz .argument
 test rsi,rsi
 jz .source_before_output
 cmp rsi,NEBOC_IMPORT_MAX_BYTES
 ja .limit_before_output
 mov rax,rdi
 add rax,rsi
 jc .argument
 mov rcx,rdx
 add rcx,NEBOC_IMPORT_AST_SIZE
 jc .argument
 cmp rdx,rax
 jae .ranges_ok
 cmp rcx,rdi
 ja .argument
.ranges_ok:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rdi
 mov r14,rax
 mov r15,rdx
 call imp_clear_ast

 ; Closed grammar: wildcards, `::` and dynamic imports are rejected before any
 ; structural field is published. Selective syntax is parsed below.
 mov r8,r12
.preflight:
 cmp r8,r14
 jae .parse
 cmp byte [r8],'*'
 je .wildcard
 cmp byte [r8],':'
 jne .preflight_next
 lea rax,[r8+1]
 cmp rax,r14
 jae .preflight_next
 cmp byte [r8+1],':'
 je .reserved
.preflight_next:
 inc r8
 jmp .preflight

.parse:
 call imp_skip_trivia
 lea rsi,[rel imp_kw_export]
 mov ecx,imp_kw_export_len
 call imp_match
 jc .match_import
 or qword [r15+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_EXPORT
.match_import:
 lea rsi,[rel imp_kw_import]
 mov ecx,imp_kw_import_len
 call imp_match
 jc .syntax
 xor ebx,ebx
 cmp r13,r14
 jae .syntax
 cmp byte [r13],'"'
 je .simple
 cmp byte [r13],'d'
 je .dynamic
 cmp byte [r13],'{'
 jne .syntax
 test qword [r15+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_EXPORT
 jnz .reexport_requires_selective

 ; Capsule: import { import "path".alias; [import ...;] }.name;
 inc r13
 call imp_skip_trivia
.capsule_entry:
 cmp ebx,NEBOC_IMPORT_MAX_ITEMS
 jae .capacity
 lea rsi,[rel imp_kw_import]
 mov ecx,imp_kw_import_len
 call imp_match
 jc .selective
 call imp_parse_entry
 jc .syntax
 cmp r13,r14
 jae .syntax
 cmp byte [r13],';'
 jne .syntax
 inc r13
 inc rbx
 call imp_skip_trivia
 cmp r13,r14
 jae .syntax
 cmp byte [r13],'}'
 je .capsule_close
 jmp .capsule_entry
.capsule_close:
 test ebx,ebx
 jz .syntax
 inc r13
 mov [r15+NEBOC_IMPORT_AST_COUNT_OFFSET],rbx
 cmp r13,r14
 jae .syntax
 cmp byte [r13],'.'
 jne .anonymous
 inc r13
 mov r10,r13
 call imp_identity
 jc .syntax
 cmp rax,[r15+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 je .capsule_collision
 cmp qword [r15+NEBOC_IMPORT_AST_COUNT_OFFSET],2
 jb .capsule_name_ready
 cmp rax,[r15+NEBOC_IMPORT_AST_ALIAS1_HASH_OFFSET]
 je .capsule_collision
.capsule_name_ready:
 mov [r15+NEBOC_IMPORT_AST_CAPSULE_HASH_OFFSET],rax
 mov r11,r13
 sub r10,r12
 sub r11,r12
 sub r11,r10
 shl r11,32
 or r10,r11
 mov [r15+NEBOC_IMPORT_AST_CAPSULE_SPAN_OFFSET],r10
 mov qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_NAMED_CAPSULE
 jmp .capsule_terminator
.anonymous:
 mov qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_ANONYMOUS_CAPSULE
.capsule_terminator:
 cmp r13,r14
 jae .syntax
 cmp byte [r13],';'
 jne .syntax
 inc r13
 jmp .finish

.simple:
 call imp_parse_entry
 jc .syntax
 mov qword [r15+NEBOC_IMPORT_AST_COUNT_OFFSET],1
 cmp qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 je .simple_form_ready
 mov qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SIMPLE
.simple_form_ready:
 test qword [r15+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_EXPORT
 jz .simple_terminator
 cmp qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .reexport_requires_selective
.simple_terminator:
 cmp r13,r14
 jae .syntax
 cmp byte [r13],';'
 jne .syntax
 inc r13

.finish:
 call imp_skip_trivia
 cmp r13,r14
 jne .syntax
 mov rax,r13
 sub rax,r12
 mov [r15+NEBOC_IMPORT_AST_CONSUMED_OFFSET],rax
 mov rdx,rax
 shl rdx,32
 mov [r15+NEBOC_IMPORT_AST_DECL_SPAN_OFFSET],rdx
 or qword [r15+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_COMPILE_TIME|NEBOC_IMPORT_FLAG_CANONICAL
 call imp_trace_hash
 mov [r15+NEBOC_IMPORT_AST_TRACE_HASH_OFFSET],rax
 test qword [r15+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_EXPORT
 jz .finish_ok
 mov [r15+NEBOC_IMPORT_AST_API_HASH_OFFSET],rax
.finish_ok:
 xor eax,eax
 jmp .done

.wildcard:
 mov r13,r8
 mov eax,NEBOC_IMPORT_DIAG_WILDCARD
 jmp .source
.reserved:
 mov r13,r8
 mov eax,NEBOC_IMPORT_DIAG_RESERVED_QUALIFIER
 jmp .source
.dynamic:
 mov eax,NEBOC_IMPORT_DIAG_DYNAMIC_IMPORT
 jmp .source
.selective:
 mov eax,NEBOC_IMPORT_DIAG_SELECTIVE_DEFERRED
 jmp .source
.reexport_requires_selective:
 mov eax,NEBOC_IMPORT_DIAG_REEXPORT_REQUIRES_SELECTIVE
 jmp .source
.capsule_collision:
 mov eax,NEBOC_IMPORT_DIAG_CAPSULE_COLLISION
 jmp .source
.capacity:
 mov eax,NEBOC_IMPORT_DIAG_CAPACITY
 jmp .source_limit
.syntax:
 cmp qword [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],0
 jne .source_existing
 mov eax,NEBOC_IMPORT_DIAG_SYNTAX
 jmp .source
.source_existing:
 mov rax,[r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET]
.source:
 push rax
 call imp_clear_ast
 pop rax
 mov [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],rax
 mov rdx,r13
 sub rdx,r12
 cmp r13,r14
 jae .source_span_ready
 mov rcx,1
 shl rcx,32
 or rdx,rcx
.source_span_ready:
 mov [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_SPAN_OFFSET],rdx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.source_limit:
 push rax
 call imp_clear_ast
 pop rax
 mov [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],rax
 mov rdx,r13
 sub rdx,r12
 cmp r13,r14
 jae .source_limit_span_ready
 mov rcx,1
 shl rcx,32
 or rdx,rcx
.source_limit_span_ready:
 mov [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_SPAN_OFFSET],rdx
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 cld
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.source_before_output:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit_before_output:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; Compatibility surface: parse_import(bytes, len, out_form) -> status.
; It delegates to the canonical AST parser instead of reclassifying bytes.
NEBOC_ABI_FUNCTION neboc_import_parse
 test rdx,rdx
 jz .compat_arg
 push rbx
 mov rbx,rdx
 sub rsp,NEBOC_IMPORT_AST_SIZE+8
 mov rdx,rsp
 call neboc_import_decl_parse
 test eax,eax
 jnz .compat_done
 mov edx,[rsp+NEBOC_IMPORT_AST_FORM_OFFSET]
 mov [rbx],edx
.compat_done:
 add rsp,NEBOC_IMPORT_AST_SIZE+8
 pop rbx
 ret
.compat_arg:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Parse one canonical quoted target and mandatory alias into AST entry RBX.
; R13 advances; carry reports syntax/collision.
imp_parse_entry:
 cmp r13,r14
 jae .bad
 cmp byte [r13],'"'
 jne .bad
 mov rbp,rbx
 imul rbp,40
 add rbp,NEBOC_IMPORT_AST_PATH0_HASH_OFFSET
 inc r13
 mov r10,r13                    ; path start pointer
 mov r8,14695981039346656037    ; full path hash
 mov r9,14695981039346656037    ; current/final segment hash
 xor r11d,r11d                  ; segment byte count
 mov ecx,1                      ; segment count
.path_loop:
 cmp r13,r14
 jae .bad
 movzx edx,byte [r13]
 cmp dl,'"'
 je .path_done
 cmp dl,'.'
 je .dot
 test r11,r11
 jnz .path_tail
 cmp dl,'a'
 jb .bad
 cmp dl,'z'
 ja .bad
 jmp .path_take
.path_tail:
 cmp dl,'a'
 jb .path_digit
 cmp dl,'z'
 jbe .path_take
.path_digit:
 cmp dl,'0'
 jb .path_under
 cmp dl,'9'
 jbe .path_take
.path_under:
 cmp dl,'_'
 jne .bad
.path_take:
 cmp r11,NEBOC_IMPORT_MAX_IDENTIFIER_BYTES
 jae .bad
 xor r8,rdx
 mov rax,1099511628211
 imul r8,rax
 xor r9,rdx
 imul r9,rax
 inc r11
 inc r13
 jmp .path_loop
.dot:
 test r11,r11
 jz .bad
 cmp ecx,NEBOC_IMPORT_MAX_PATH_SEGMENTS
 jae .bad
 xor r8,rdx
 mov rax,1099511628211
 imul r8,rax
 mov r9,14695981039346656037
 xor r11d,r11d
 inc ecx
 inc r13
 jmp .path_loop
.path_done:
 test r11,r11
 jz .bad
 mov [r15+rbp],r8
 mov [r15+rbp+8],r9
 mov rax,r13
 sub rax,r10
 mov r11,rax
 mov rax,r10
 sub rax,r12
 shl r11,32
 or rax,r11
 mov [r15+rbp+24],rax
 inc r13
 call imp_skip_trivia
 cmp r13,r14
 jae .alias_required
 cmp byte [r13],'{'
 jne .expect_alias
 test rbx,rbx
 jnz .bad
 call imp_parse_selective_list
 jc .bad
.expect_alias:
 call imp_skip_trivia
 cmp r13,r14
 jae .alias_required
 cmp byte [r13],'.'
 jne .alias_required
 inc r13
 mov r10,r13
 call imp_identity
 jc .alias_required
 mov [r15+rbp+16],rax
 mov r11,r13
 sub r11,r10
 mov rdx,r10
 sub rdx,r12
 shl r11,32
 or rdx,r11
 mov [r15+rbp+32],rdx
 test rbx,rbx
 jz .ok
 cmp rax,[r15+NEBOC_IMPORT_AST_ALIAS0_HASH_OFFSET]
 je .alias_collision
 cmp qword [r15+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET],r9
 je .alias_collision
.ok:
 clc
 ret
.alias_required:
 mov qword [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_ALIAS_REQUIRED
 stc
 ret
.alias_collision:
 mov qword [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_ALIAS_COLLISION
.bad:
 stc
 ret

; Parse `{ Name; Other; }` into the G152 extension of ImportAstNode. Names
; retain byte-exact SymbolId hashes and spans; namespace kinds are resolved
; later against interface records, never inferred from spelling.
imp_parse_selective_list:
 push rbx
 push rbp
 cmp byte [r13],'{'
 jne .syntax
 inc r13
 xor ebx,ebx
.item:
 call imp_skip_trivia
 cmp r13,r14
 jae .syntax
 cmp byte [r13],'}'
 je .close
 cmp ebx,8
 jae .capacity
 mov r10,r13
 call imp_binding_identity
 jc .syntax
 xor ebp,ebp
.duplicate:
 cmp rbp,rbx
 jae .store
 cmp rax,[r15+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+rbp*8]
 je .duplicate_error
 inc rbp
 jmp .duplicate
.store:
 mov [r15+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+rbx*8],rax
 mov r11,r13
 sub r11,r10
 mov rdx,r10
 sub rdx,r12
 shl r11,32
 or rdx,r11
 mov [r15+NEBOC_IMPORT_AST_SELECTIVE_SPANS_OFFSET+rbx*8],rdx
 inc rbx
 call imp_skip_trivia
 cmp r13,r14
 jae .syntax
 cmp byte [r13],';'
 jne .syntax
 inc r13
 jmp .item
.close:
 test rbx,rbx
 jz .syntax
 inc r13
 mov [r15+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET],rbx
 mov qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 clc
 jmp .done
.duplicate_error:
 mov qword [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_SELECTIVE_DUPLICATE
 stc
 jmp .done
.capacity:
 mov qword [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_SELECTIVE_CAPACITY
 stc
 jmp .done
.syntax:
 mov qword [r15+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET],NEBOC_IMPORT_DIAG_SELECTIVE_SYNTAX
 stc
.done:
 pop rbp
 pop rbx
 ret

; Canonical lowercase identity. Returns FNV-1a in RAX.
imp_identity:
 cmp r13,r14
 jae .bad
 movzx edx,byte [r13]
 cmp dl,'a'
 jb .bad
 cmp dl,'z'
 ja .bad
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ecx,ecx
.loop:
 cmp r13,r14
 jae .done
 movzx edx,byte [r13]
 cmp dl,'a'
 jb .digit
 cmp dl,'z'
 jbe .take
.digit:
 cmp dl,'0'
 jb .under
 cmp dl,'9'
 jbe .take
.under:
 cmp dl,'_'
 jne .done
.take:
 cmp ecx,NEBOC_IMPORT_MAX_IDENTIFIER_BYTES
 jae .bad
 xor rax,rdx
 imul rax,r8
 inc r13
 inc ecx
 jmp .loop
.done:
 test ecx,ecx
 jz .bad
 clc
 ret
.bad:
 stc
 ret

; Public binding identity: [A-Za-z][A-Za-z0-9_]{0,31}.
imp_binding_identity:
 cmp r13,r14
 jae .bad
 movzx edx,byte [r13]
 cmp dl,'A'
 jb .bad
 cmp dl,'Z'
 jbe .first_ok
 cmp dl,'a'
 jb .bad
 cmp dl,'z'
 ja .bad
.first_ok:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ecx,ecx
.loop:
 cmp r13,r14
 jae .done
 movzx edx,byte [r13]
 cmp dl,'A'
 jb .digit
 cmp dl,'Z'
 jbe .take
 cmp dl,'a'
 jb .digit
 cmp dl,'z'
 jbe .take
.digit:
 cmp dl,'0'
 jb .under
 cmp dl,'9'
 jbe .take
.under:
 cmp dl,'_'
 jne .done
.take:
 cmp ecx,NEBOC_IMPORT_MAX_IDENTIFIER_BYTES
 jae .bad
 xor rax,rdx
 imul rax,r8
 inc r13
 inc ecx
 jmp .loop
.done:
 test ecx,ecx
 jz .bad
 clc
 ret
.bad:
 stc
 ret

; Match exact bytes at R13 without consuming on failure.
imp_match:
 mov rdx,r14
 sub rdx,r13
 cmp rdx,rcx
 jb .bad
 xor edx,edx
.loop:
 cmp rdx,rcx
 jae .ok
 mov al,[r13+rdx]
 cmp al,[rsi+rdx]
 jne .bad
 inc rdx
 jmp .loop
.ok:
 add r13,rcx
 clc
 ret
.bad:
 stc
 ret

; Whitespace and canonical line/nested-block comments are trivia at boundaries.
imp_skip_trivia:
.again:
 cmp r13,r14
 jae .done
 mov al,[r13]
 cmp al,' '
 je .one
 cmp al,9
 je .one
 cmp al,10
 je .one
 cmp al,13
 je .one
 cmp al,'/'
 jne .done
 lea rax,[r13+1]
 cmp rax,r14
 jae .done
 cmp byte [r13+1],'/'
 je .line_open
 cmp byte [r13+1],'*'
 je .block_open
 jmp .done
.line_open:
 add r13,2
.comment:
 cmp r13,r14
 jae .done
 cmp byte [r13],10
 je .again
 inc r13
 jmp .comment
.block_open:
 mov edx,1
 add r13,2
.block_loop:
 cmp r13,r14
 jae .done
 lea rax,[r13+1]
 cmp rax,r14
 jae .done
 cmp byte [r13],'/'
 jne .block_close
 cmp byte [r13+1],'*'
 jne .block_next
 inc edx
 cmp edx,64
 ja .done
 add r13,2
 jmp .block_loop
.block_close:
 cmp byte [r13],'*'
 jne .block_next
 cmp byte [r13+1],'/'
 jne .block_next
 add r13,2
 dec edx
 jnz .block_loop
 jmp .again
.block_next:
 inc r13
 jmp .block_loop
.one:
 inc r13
 jmp .again
.done:
 ret

imp_clear_ast:
 mov rdi,r15
 mov ecx,NEBOC_IMPORT_AST_QWORDS
 xor eax,eax
 rep stosq
 ret

; Stable trace digest over semantic fields only; source trivia and addresses do
; not participate, so argv/source-buffer permutations cannot perturb it.
imp_trace_hash:
 mov rax,14695981039346656037
 mov rdx,1099511628211
 ; Preserve G151's published trace exactly: it covered qwords 0..16 and
 ; deliberately mixed the still-zero trace slot as its final field.
 mov r8d,17
 cmp qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .limit_ready
 mov r8d,NEBOC_IMPORT_AST_QWORDS
.limit_ready:
 xor ecx,ecx
.loop:
 cmp ecx,r8d
 jae .done
 cmp ecx,1
 je .next                       ; consumed bytes are syntactic, not semantic
 cmp ecx,6
 je .next                       ; spans are source presentation
 cmp ecx,7
 je .next
 cmp ecx,11
 je .next
 cmp ecx,12
 je .next
 cmp ecx,14
 je .next
 cmp ecx,16
 jne .diagnostic_slots
 cmp qword [r15+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 je .next                       ; selective trace digest is being computed
 jmp .hash                      ; G151 compatibility mixes the zero slot
.diagnostic_slots:
 cmp ecx,17
 je .next                       ; diagnostic state is non-semantic
 cmp ecx,18
 je .next
 cmp ecx,28
 jb .hash
 cmp ecx,35
 jbe .next                      ; selective source spans
 cmp ecx,37
 je .next                       ; derived public API digest
 cmp ecx,38
 je .next                       ; declaration source span
.hash:
 xor rax,[r15+rcx*8]
 imul rax,rdx
.next:
 inc ecx
 jmp .loop
.done:
 test rax,rax
 jnz .ret
 mov eax,1
.ret:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
