; G152 selective import resolution over distinct symbol namespaces.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/import_parser.inc"
%include "compiler/parser/selective_import_parser.inc"

section .text

; SelectiveImport.resolve(ast, symbol_hash, namespace_kind,
;                         interface_records, record_count, out_result)
; The requested namespace is explicit, so an equal spelling in another
; namespace can never satisfy or make this lookup ambiguous.
NEBOC_ABI_FUNCTION neboc_selective_resolve
 test rdi,rdi
 jz .argument
 test rcx,rcx
 jz .argument
 test r9,r9
 jz .argument
 test rdi,7
 jnz .argument
 test rcx,7
 jnz .argument
 test r9,7
 jnz .argument
 mov r10,rdi
 mov rdi,r9
 mov r11,rcx
 mov ecx,NEBOC_SELECTIVE_RESULT_QWORDS
 xor eax,eax
 rep stosq
 mov rdi,r10
 mov rcx,r11
 cmp qword [rdi+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .source
 test qword [rdi+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_CANONICAL
 jz .source
 test rsi,rsi
 jz .source
 cmp rdx,NEBOC_NAMESPACE_TYPE
 jb .source
 cmp rdx,NEBOC_NAMESPACE_MODULE
 ja .source
 test r8,r8
 jz .source
 cmp r8,NEBOC_SELECTIVE_MAX
 ja .limit
 mov rax,[rdi+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_SELECTIVE_MAX
 ja .source
 xor r10d,r10d
.selected:
 cmp r10,rax
 jae .missing
 cmp rsi,[rdi+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+r10*8]
 je .scan_records
 inc r10
 jmp .selected
.scan_records:
 xor r10d,r10d
 xor eax,eax                         ; match count
 xor r11d,r11d                       ; matching record pointer
.record:
 cmp r10,r8
 jae .resolved
 mov rdi,r10
 shl rdi,6
 add rdi,rcx
 cmp rsi,[rdi+NEBOC_SELECTIVE_SYMBOL_HASH_OFFSET]
 jne .next
 cmp rdx,[rdi+NEBOC_SELECTIVE_SYMBOL_KIND_OFFSET]
 jne .next
 cmp qword [rdi+NEBOC_SELECTIVE_SYMBOL_VISIBILITY_OFFSET],NEBOC_VIS_PRIVATE
 je .next
 inc rax
 mov r11,rdi
.next:
 inc r10
 jmp .record
.resolved:
 test rax,rax
 jz .missing
 cmp rax,1
 jne .ambiguous
 mov [r9+NEBOC_SELECTIVE_RESULT_MATCHES_OFFSET],rax
 mov rax,[r11+NEBOC_SELECTIVE_SYMBOL_HASH_OFFSET]
 mov [r9+NEBOC_SELECTIVE_RESULT_SYMBOL_OFFSET],rax
 mov rax,[r11+NEBOC_SELECTIVE_SYMBOL_KIND_OFFSET]
 mov [r9+NEBOC_SELECTIVE_RESULT_KIND_OFFSET],rax
 mov rax,[r11+NEBOC_SELECTIVE_SYMBOL_MODULE_OFFSET]
 mov [r9+NEBOC_SELECTIVE_RESULT_MODULE_OFFSET],rax
 mov rax,[r11+NEBOC_SELECTIVE_SYMBOL_VALUE_OFFSET]
 mov [r9+NEBOC_SELECTIVE_RESULT_VALUE_OFFSET],rax
 mov rax,[r11+NEBOC_SELECTIVE_SYMBOL_ID_OFFSET]
 mov [r9+NEBOC_SELECTIVE_RESULT_ID_OFFSET],rax
 xor eax,eax
 ret
.ambiguous:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.missing:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; imports.unused(ast, used_symbol_hashes, used_count, out_unused_count)
NEBOC_ABI_FUNCTION neboc_imports_unused
 test rdi,rdi
 jz .argument
 test rcx,rcx
 jz .argument
 mov qword [rcx],0
 cmp qword [rdi+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .source
 cmp rdx,NEBOC_SELECTIVE_MAX
 ja .limit
 test rdx,rdx
 jz .all_unused
 test rsi,rsi
 jz .argument
 xor r8d,r8d
 xor r9d,r9d
.unused_item:
 cmp r8,[rdi+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET]
 jae .unused_done
 mov r10,[rdi+NEBOC_IMPORT_AST_SELECTIVE_HASHES_OFFSET+r8*8]
 xor r11d,r11d
.used_scan:
 cmp r11,rdx
 jae .unused
 cmp r10,[rsi+r11*8]
 je .unused_next
 inc r11
 jmp .used_scan
.unused:
 inc r9
.unused_next:
 inc r8
 jmp .unused_item
.unused_done:
 mov [rcx],r9
 xor eax,eax
 ret
.all_unused:
 mov rax,[rdi+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET]
 mov [rcx],rax
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; imports.ambiguous(records, count, out_pair_count). Equal spellings in
; different namespaces are deliberately not ambiguous.
NEBOC_ABI_FUNCTION neboc_imports_ambiguous
 test rdi,rdi
 jz .argument
 test rdx,rdx
 jz .argument
 mov qword [rdx],0
 test rsi,rsi
 jz .source
 cmp rsi,NEBOC_SELECTIVE_MAX
 ja .limit
 xor ecx,ecx
 xor r8d,r8d
.outer:
 cmp rcx,rsi
 jae .done
 lea r9,[rcx+1]
 mov r10,rcx
 shl r10,6
.inner:
 cmp r9,rsi
 jae .next_outer
 mov r11,r9
 shl r11,6
 mov rax,[rdi+r10+NEBOC_SELECTIVE_SYMBOL_HASH_OFFSET]
 cmp rax,[rdi+r11+NEBOC_SELECTIVE_SYMBOL_HASH_OFFSET]
 jne .next_inner
 mov rax,[rdi+r10+NEBOC_SELECTIVE_SYMBOL_KIND_OFFSET]
 cmp rax,[rdi+r11+NEBOC_SELECTIVE_SYMBOL_KIND_OFFSET]
 jne .next_inner
 inc r8
.next_inner:
 inc r9
 jmp .inner
.next_outer:
 inc rcx
 jmp .outer
.done:
 mov [rdx],r8
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
