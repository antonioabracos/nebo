; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F05 canonical bounded parser for three static source units.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/module_parser.inc"

section .rodata
mod_kw_module: db 'module '
mod_kw_module_len equ $-mod_kw_module
mod_kw_import: db ' import '
mod_kw_import_len equ $-mod_kw_import
mod_kw_export: db ' export '
mod_kw_export_len equ $-mod_kw_export
mod_kw_public: db 'public '
mod_kw_public_len equ $-mod_kw_public
mod_kw_private: db 'private '
mod_kw_private_len equ $-mod_kw_private
mod_kw_assign: db ' = '
mod_kw_assign_len equ $-mod_kw_assign
mod_kw_start: db ' start '
mod_kw_start_len equ $-mod_kw_start
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

 ; Authenticate the exact source bytes independently of argv ordering.
 mov rsi,r15
 mov rcx,rax
 call mod_hash_bytes
 mov [rbp+NEBOC_MODULE_RECORD_SOURCE_HASH_OFFSET],rax

 lea rsi,[rel mod_kw_module]
 mov ecx,mod_kw_module_len
 call mod_match
 jc .syntax
 call mod_identity
 jc .syntax
 mov [rbp+NEBOC_MODULE_RECORD_MODULE_HASH_OFFSET],rax

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

.export:
 lea rsi,[rel mod_kw_export]
 mov ecx,mod_kw_export_len
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
 jc .syntax
 mov qword [rbp+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PRIVATE
 jmp .export_name
.public:
 mov qword [rbp+NEBOC_MODULE_RECORD_VISIBILITY_OFFSET],NEBOC_MODULE_VISIBILITY_PUBLIC
.export_name:
 call mod_identity
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
 lea rsi,[rel mod_kw_start]
 mov ecx,mod_kw_start_len
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
 test rax,NEBOC_MODULE_RECORD_EXPORT|NEBOC_MODULE_RECORD_START
 jz .syntax
 cmp r13,r14
 jae .syntax
 cmp byte [r13],';'
 jne .syntax
 inc r13
 cmp r13,r14
 je .unit_done
 cmp byte [r13],10
 jne .syntax
 inc r13
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

; Match exact bytes at r13 without consuming on failure.
%undef call
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
 call mod_identity
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
