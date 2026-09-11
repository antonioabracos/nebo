; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F05 canonical bounded parser for three static source units.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/module_parser.inc"
%include "compiler/parser/doc.inc"
%include "compiler/interface/interface_v1.inc"

extern neboc_import_decl_parse
extern neboc_doc_parse
extern neboc_interface_module_decode

section .rodata
mod_kw_module: db 'module '
mod_kw_module_len equ $-mod_kw_module
mod_kw_import: db ' import '
mod_kw_import_len equ $-mod_kw_import
mod_kw_import_modern: db 'import '
mod_kw_import_modern_len equ $-mod_kw_import_modern
mod_kw_export_import_modern: db 'export import '
mod_kw_export_import_modern_len equ $-mod_kw_export_import_modern
mod_kw_export: db ' export '
mod_kw_export_len equ $-mod_kw_export
mod_kw_export_modern: db 'export '
mod_kw_export_modern_len equ $-mod_kw_export_modern
mod_kw_public: db 'public '
mod_kw_public_len equ $-mod_kw_public
mod_kw_private: db 'private '
mod_kw_private_len equ $-mod_kw_private
mod_kw_internal: db 'internal '
mod_kw_internal_len equ $-mod_kw_internal
mod_kw_assign: db ' = '
mod_kw_assign_len equ $-mod_kw_assign
mod_kw_start: db ' start '
mod_kw_start_len equ $-mod_kw_start
mod_kw_start_modern: db 'start '
mod_kw_start_modern_len equ $-mod_kw_start_modern
mod_kw_plus: db ' + '
mod_kw_plus_len equ $-mod_kw_plus

section .text

; parse(request*) -> status.  The request owns three source pointer/length
; pairs and a caller-owned three-record table.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_seguranca_numerica_conversoes_e_overflow_module_parse
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
 mov r12,rdi
 mov qword [r12+NEBOC_MODULE_FOUND_OFFSET],1
 mov qword [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_MODULE_DIAGNOSTIC_UNIT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_UNIT_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_ROOT_INDEX_OFFSET],-1
 mov qword [r12+NEBOC_MODULE_RESULT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_GRAPH_HASH_OFFSET],0
 mov qword [r12+NEBOC_MODULE_SEMANTIC_HASH_OFFSET],0
 mov qword [r12+NEBOC_MODULE_EDGE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_PUBLIC_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_PRIVATE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_START_REF_COUNT_OFFSET],0
 mov qword [r12+NEBOC_MODULE_FLAGS_OFFSET],0
 mov rax,[r12+NEBOC_MODULE_RECORDS_OFFSET]
 test rax,rax
 jz .transport
 test rax,NEBOC_MODULE_ALIGNMENT-1
 jnz .transport
 cmp qword [r12+NEBOC_MODULE_CAPACITY_OFFSET],NEBOC_MODULE_MAX_UNITS
 jb .capacity
 mov rdi,rax
 mov ecx,(NEBOC_MODULE_MAX_UNITS*NEBOC_MODULE_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 mov rax,[r12+NEBOC_MODULE_IMPORT_ASTS_OFFSET]
 test rax,rax
 jz .metadata_ready
 test rax,NEBOC_IMPORT_AST_ALIGNMENT-1
 jnz .transport
 cmp qword [r12+NEBOC_MODULE_IMPORT_AST_CAPACITY_OFFSET],NEBOC_MODULE_MAX_UNITS
 jb .capacity
 mov rdi,rax
 mov ecx,(NEBOC_MODULE_MAX_UNITS*NEBOC_IMPORT_AST_SIZE)/8
 xor eax,eax
 rep stosq
.metadata_ready:
 xor ebx,ebx
.unit_loop:
 cmp ebx,NEBOC_MODULE_MAX_UNITS
 jae .parsed
 mov rdx,rbx
 shl rdx,4
 mov r15,[r12+rdx+NEBOC_MODULE_SOURCE0_OFFSET]
 mov rax,[r12+rdx+NEBOC_MODULE_LENGTH0_OFFSET]
 test r15,r15
 jz .capacity
 test rax,rax
 jz .capacity
 cmp rax,NEBOC_MODULE_MAX_SOURCE_BYTES
 ja .capacity
 mov r13,r15
 mov r14,r15
 add r14,rax
 jc .transport
 mov rbp,[r12+NEBOC_MODULE_RECORDS_OFFSET]
 mov rdx,rbx
 shl rdx,7
 add rbp,rdx

 ; Auxiliary interfaces enter the same parsed-record/semantic/lowering path.
 ; Magic selects the transport format; no fixture name or source hash routes.
 cmp rax,8
 jb .source_unit
 mov rdx,NEBOC_NI_MAGIC
 cmp [r15],rdx
 jne .source_unit
 mov rdi,r15
 mov rsi,rax
 mov rdx,rbp
 call neboc_interface_module_decode
 test eax,eax
 jnz .interface_bad
 jmp .unit_done
.interface_bad:
 mov [r12+NEBOC_MODULE_DIAGNOSTIC_UNIT_OFFSET],rbx
 mov [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],rdx
 jmp .done
.source_unit:
 ; Authenticate the exact source bytes independently of argv ordering.
 mov rsi,r15
 mov rcx,rax
 call mod_hash_bytes
 mov [rbp+NEBOC_MODULE_RECORD_SOURCE_HASH_OFFSET],rax

 ; Documentation-grade module fixtures may carry ordinary line comments.
 ; Trivia never changes the exact bounded grammar between material tokens.
 call mod_skip_trivia
 call mod_skip_semantic_doc
 jc .doc_syntax

 lea rsi,[rel mod_kw_module]
 mov ecx,mod_kw_module_len
 call mod_match
 jc .syntax
 mov r10,r13
 sub r10,r15
 call mod_identity
 jc .syntax
 mov [rbp+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET],rax
 mov r11,r13
 sub r11,r15
 sub r11,r10
 shl r11,32
 or r10,r11
 mov [rbp+NEBOC_MODULE_RECORD_NAME_SPAN_OFFSET],r10

 ; G151 source uses declaration terminators. The established compact G003
 ; grammar remains accepted for every earlier group and existing SDK caller.
 cmp r13,r14
 jae .syntax
 cmp byte [r13],';'
 jne .imports
 cmp qword [r12+NEBOC_MODULE_IMPORT_ASTS_OFFSET],0
 je .transport
 inc r13
 or qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_MODERN_IMPORTS
 call mod_skip_trivia
 jmp .modern_import

.imports:
 lea rsi,[rel mod_kw_import]
 mov ecx,mod_kw_import_len
 call mod_match
 jc .export
 mov rdx,[rbp+NEBOC_MODULE_RECORD_IMPORT_COUNT_OFFSET]
 cmp rdx,NEBOC_MODULE_MAX_IMPORTS
 jae .capacity
 call mod_identity
 jc .syntax
 mov rcx,[rbp+NEBOC_MODULE_RECORD_IMPORT_COUNT_OFFSET]
 mov [rbp+rcx*8+NEBOC_MODULE_RECORD_IMPORT0_HASH_OFFSET],rax
 inc qword [rbp+NEBOC_MODULE_RECORD_IMPORT_COUNT_OFFSET]
 jmp .imports

.modern_import:
 mov r9,r13
 lea rsi,[rel mod_kw_import_modern]
 mov ecx,mod_kw_import_modern_len
 call mod_match
 jnc .modern_import_found
 mov r13,r9
 lea rsi,[rel mod_kw_export_import_modern]
 mov ecx,mod_kw_export_import_modern_len
 call mod_match
 jc .export
 or qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_REEXPORT
.modern_import_found:
 mov r13,r9
 mov r10,r13
 xor r11d,r11d                ; brace depth
 xor r8d,r8d                  ; inside quoted path
.modern_scan:
 cmp r10,r14
 jae .syntax
 mov al,[r10]
 cmp al,'"'
 jne .modern_not_quote
 xor r8d,1
 inc r10
 jmp .modern_scan
.modern_not_quote:
 test r8d,r8d
 jnz .modern_next
 cmp al,'{'
 jne .modern_close
 inc r11
 jmp .modern_next
.modern_close:
 cmp al,'}'
 jne .modern_semicolon
 test r11,r11
 jz .syntax
 dec r11
 jmp .modern_next
.modern_semicolon:
 cmp al,';'
 jne .modern_next
 test r11,r11
 jnz .modern_next
 inc r10
 mov rsi,r10
 sub rsi,r13
 mov rdx,rbx
 imul rdx,NEBOC_IMPORT_AST_SIZE
 add rdx,[r12+NEBOC_MODULE_IMPORT_ASTS_OFFSET]
 mov rdi,r13
 call neboc_import_decl_parse
 test eax,eax
 jnz .import_failed
 mov rdx,rbx
 imul rdx,NEBOC_IMPORT_AST_SIZE
 add rdx,[r12+NEBOC_MODULE_IMPORT_ASTS_OFFSET]
 mov rax,r13
 sub rax,r15
 add [rdx+NEBOC_IMPORT_AST_PATH0_SPAN_OFFSET],eax
 add [rdx+NEBOC_IMPORT_AST_ALIAS0_SPAN_OFFSET],eax
 cmp qword [rdx+NEBOC_IMPORT_AST_COUNT_OFFSET],2
 jb .modern_spans_capsule
 add [rdx+NEBOC_IMPORT_AST_PATH1_SPAN_OFFSET],eax
 add [rdx+NEBOC_IMPORT_AST_ALIAS1_SPAN_OFFSET],eax
.modern_spans_capsule:
 cmp qword [rdx+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_NAMED_CAPSULE
 jne .modern_spans_selective
 add [rdx+NEBOC_IMPORT_AST_CAPSULE_SPAN_OFFSET],eax
.modern_spans_selective:
 cmp qword [rdx+NEBOC_IMPORT_AST_FORM_OFFSET],NEBOC_IMPORT_FORM_SELECTIVE
 jne .modern_spans_done
 xor ecx,ecx
.modern_selective_span:
 cmp rcx,[rdx+NEBOC_IMPORT_AST_SELECTIVE_COUNT_OFFSET]
 jae .modern_spans_done
 add [rdx+NEBOC_IMPORT_AST_SELECTIVE_SPANS_OFFSET+rcx*8],eax
 inc rcx
 jmp .modern_selective_span
.modern_spans_done:
 add r13,[rdx+NEBOC_IMPORT_AST_CONSUMED_OFFSET]
 mov rcx,[rdx+NEBOC_IMPORT_AST_COUNT_OFFSET]
 mov [rbp+NEBOC_MODULE_RECORD_IMPORT_COUNT_OFFSET],rcx
 mov rax,[rdx+NEBOC_IMPORT_AST_TARGET0_HASH_OFFSET]
 mov [rbp+NEBOC_MODULE_RECORD_IMPORT0_HASH_OFFSET],rax
 test qword [rdx+NEBOC_IMPORT_AST_FLAGS_OFFSET],NEBOC_IMPORT_FLAG_EXPORT
 jz .modern_import_not_exported
 or qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_REEXPORT
.modern_import_not_exported:
 cmp rcx,2
 jb .modern_import_done
 mov rax,[rdx+NEBOC_IMPORT_AST_TARGET1_HASH_OFFSET]
 mov [rbp+NEBOC_MODULE_RECORD_IMPORT1_HASH_OFFSET],rax
.modern_import_done:
 call mod_skip_trivia
 jmp .export
.modern_next:
 inc r10
 jmp .modern_scan

.export:
 test qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_MODERN_IMPORTS
 jz .export_legacy
 lea rsi,[rel mod_kw_export_modern]
 mov ecx,mod_kw_export_modern_len
 jmp .export_match
.export_legacy:
 lea rsi,[rel mod_kw_export]
 mov ecx,mod_kw_export_len
.export_match:
 call mod_match
 jc .start
 test qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_EXPORT
 jnz .syntax
 lea rsi,[rel mod_kw_public]
 mov ecx,mod_kw_public_len
 call mod_match
 jnc .public
 lea rsi,[rel mod_kw_private]
 mov ecx,mod_kw_private_len
 call mod_match
 jnc .private
 lea rsi,[rel mod_kw_internal]
 mov ecx,mod_kw_internal_len
 call mod_match
 jc .syntax
 mov qword [rbp+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_INTERNAL
 jmp .export_name
.private:
 mov qword [rbp+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PRIVATE
 jmp .export_name
.public:
 mov qword [rbp+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PUBLIC
.export_name:
 ; Exported value names share the language binding grammar.  Module/package
 ; identities remain lowercase, while value identity may be camelCase,
 ; PascalCase, or ALL_CAPS (G085 ConstBinding).
 call mod_binding_identity
 jc .syntax
 mov [rbp+NEBOC_MODULE_RECORD_EXPORT_HASH_OFFSET],rax
 lea rsi,[rel mod_kw_assign]
 mov ecx,mod_kw_assign_len
 call mod_match
 jc .syntax
 call mod_uint8
 jc .syntax
 mov [rbp+NEBOC_MODULE_RECORD_EXPORT_VALUE_OFFSET],rax
 or qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_EXPORT

.start:
 test qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_MODERN_IMPORTS
 jz .start_legacy
 lea rsi,[rel mod_kw_start_modern]
 mov ecx,mod_kw_start_modern_len
 jmp .start_match
.start_legacy:
 lea rsi,[rel mod_kw_start]
 mov ecx,mod_kw_start_len
.start_match:
 call mod_match
 jc .terminator
 test qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_START
 jnz .syntax
 call mod_reference
 jc .syntax
 mov [rbp+NEBOC_MODULE_RECORD_START0_MODULE_OFFSET],rax
 mov [rbp+NEBOC_MODULE_RECORD_START0_SYMBOL_OFFSET],rdx
 mov qword [rbp+NEBOC_MODULE_RECORD_START_COUNT_OFFSET],1
 lea rsi,[rel mod_kw_plus]
 mov ecx,mod_kw_plus_len
 call mod_match
 jc .start_done
 call mod_reference
 jc .syntax
 mov [rbp+NEBOC_MODULE_RECORD_START1_MODULE_OFFSET],rax
 mov [rbp+NEBOC_MODULE_RECORD_START1_SYMBOL_OFFSET],rdx
 mov qword [rbp+NEBOC_MODULE_RECORD_START_COUNT_OFFSET],2
.start_done:
 or qword [rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET],NEBOC_MODULE_RECORD_START

.terminator:
 mov rax,[rbp+NEBOC_MODULE_RECORD_FLAGS_OFFSET]
 test rax,NEBOC_MODULE_RECORD_EXPORT|NEBOC_MODULE_RECORD_START|NEBOC_MODULE_RECORD_REEXPORT
 jz .syntax
 cmp r13,r14
 jb .terminator_present
 test rax,NEBOC_MODULE_RECORD_REEXPORT
 jnz .unit_done
 jmp .syntax
.terminator_present:
 cmp byte [r13],';'
 jne .syntax
 inc r13
 call mod_skip_trivia
 cmp r13,r14
 jne .syntax
.unit_done:
 inc rbx
 jmp .unit_loop

.parsed:
 mov qword [r12+NEBOC_MODULE_UNIT_COUNT_OFFSET],NEBOC_MODULE_MAX_UNITS
 mov qword [r12+NEBOC_MODULE_FLAGS_OFFSET],NEBOC_MODULE_FLAG_PARSED
 xor eax,eax
 jmp .done
.syntax:
 mov qword [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_SYNTAX
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.doc_syntax:
 mov eax,16615500
 add rax,rdx
 mov [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.import_failed:
 mov rdx,rbx
 imul rdx,NEBOC_IMPORT_AST_SIZE
 add rdx,[r12+NEBOC_MODULE_IMPORT_ASTS_OFFSET]
 mov rax,r13
 sub rax,r15
 add [rdx+NEBOC_IMPORT_AST_DIAGNOSTIC_SPAN_OFFSET],eax
 mov rax,[rdx+NEBOC_IMPORT_AST_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .import_diag_ready
 mov eax,NEBOC_IMPORT_DIAG_SYNTAX
.import_diag_ready:
 mov [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.capacity:
 mov qword [r12+NEBOC_MODULE_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_CAPACITY
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.transport:
 mov qword [r12+NEBOC_MODULE_FOUND_OFFSET],0
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
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

; Consume ASCII whitespace plus canonical line/nested-block trivia.
; R13 is the current byte and R14 is the exclusive end.
mod_skip_trivia:
.again:
 cmp r13,r14
 jae .done
 mov al,[r13]
 cmp al,' '
 je .space
 cmp al,9
 je .space
 cmp al,10
 je .space
 cmp al,13
 je .space
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
.space:
 inc r13
 jmp .again
.done:
 ret

; Match exact bytes at r13 without consuming on failure.
%undef call
; Consume one semantic doc block through the canonical G155 parser and leave
; R13 at the attached module declaration. Ordinary sources take no call.
mod_skip_semantic_doc:
 cmp r13,r14
 jae .none
 mov rax,r14
 sub rax,r13
 cmp rax,3
 jb .none
 cmp byte [r13],'d'
 jne .none
 cmp byte [r13+1],'o'
 jne .none
 cmp byte [r13+2],'c'
 jne .none
 sub rsp,584
 mov rdi,r13
 mov rsi,r14
 sub rsi,r13
 lea rdx,[rsp]
 call neboc_doc_parse
 test eax,eax
 jnz .failed
 mov rax,[rsp+NEBOC_DOC_CONSUMED_OFFSET]
 add rsp,584
 add r13,rax
 clc
 ret
.failed:
 add rsp,584
 stc
 ret
.none:
 clc
 ret

mod_match:
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

; Canonical identifier: [a-z][a-z0-9_]{0,31}; returns FNV-1a in RAX.
mod_identity:
 cmp r13,r14
 jae .bad
 movzx edx,byte [r13]
 cmp dl,'a'
 jb .bad
 cmp dl,'z'
 ja .bad
 mov rax,14695981039346656037
 mov r9,1099511628211
 xor r8d,r8d
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
 jb .underscore
 cmp dl,'9'
 jbe .take
.underscore:
 cmp dl,'_'
 jne .done
.take:
 cmp r8d,NEBOC_MODULE_MAX_IDENTIFIER_BYTES
 jae .bad
 xor rax,rdx
 imul rax,r9
 inc r13
 inc r8d
 jmp .loop
.done:
 test r8d,r8d
 jz .bad
 clc
 ret
.bad:
 stc
 ret

; Binding identity: [A-Za-z][A-Za-z0-9_]{0,31}.  The byte-exact FNV hash is
; intentionally the same algorithm as module identities and references.
mod_binding_identity:
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
 mov r9,1099511628211
 xor r8d,r8d
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
 jb .underscore
 cmp dl,'9'
 jbe .take
.underscore:
 cmp dl,'_'
 jne .done
.take:
 cmp r8d,NEBOC_MODULE_MAX_IDENTIFIER_BYTES
 jae .bad
 xor rax,rdx
 imul rax,r9
 inc r13
 inc r8d
 jmp .loop
.done:
 test r8d,r8d
 jz .bad
 clc
 ret
.bad:
 stc
 ret

; Decimal 0..255 with canonical no-leading-zero spelling.
mod_uint8:
 cmp r13,r14
 jae .bad
 movzx edx,byte [r13]
 cmp dl,'0'
 jb .bad
 cmp dl,'9'
 ja .bad
 xor eax,eax
 xor r8d,r8d
.loop:
 cmp r13,r14
 jae .done
 movzx edx,byte [r13]
 cmp dl,'0'
 jb .done
 cmp dl,'9'
 ja .done
 cmp r8d,0
 jne .accumulate
 cmp dl,'0'
 jne .accumulate
 inc r13
 inc r8d
 cmp r13,r14
 jae .done
 movzx edx,byte [r13]
 cmp dl,'0'
 jb .done
 cmp dl,'9'
 jbe .bad
 jmp .done
.accumulate:
 imul rax,rax,10
 sub edx,'0'
 add rax,rdx
 cmp rax,255
 ja .bad
 inc r13
 inc r8d
 jmp .loop
.done:
 test r8d,r8d
 jz .bad
 clc
 ret
.bad:
 stc
 ret

; Qualified reference; returns module hash in RAX and symbol hash in RDX.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
mod_reference:
 call mod_identity
 jc .bad
 mov r10,rax
 cmp r13,r14
 jae .bad
 cmp byte [r13],'.'
 jne .bad
 inc r13
 call mod_binding_identity
 jc .bad
 mov rdx,rax
 mov rax,r10
 clc
 ret
.bad:
 stc
 ret

%undef call
mod_hash_bytes:
 mov rax,14695981039346656037
 mov r9,1099511628211
 xor r8d,r8d
.loop:
 cmp r8,rcx
 jae .done
 movzx edx,byte [rsi+r8]
 xor rax,rdx
 imul rax,r9
 inc r8
 jmp .loop
.done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
