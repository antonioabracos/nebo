; TEXT-CHAR-UNICODE-E-BYTES-PF005 TypeId 10/11 append contract
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
extern neboc_type_table_init
extern neboc_type_table_declare_builtins
extern neboc_type_table_declare_intrinsic_types
extern neboc_type_table_declare_foundation_float
extern neboc_type_table_declare_text_char_bytes
extern neboc_type_table_freeze
extern neboc_type_table_get
global _start
section .bss align=16
table: resb NEBOC_TYPE_TABLE_SIZE
entries: resb NEBOC_TYPE_V02_TEXTUAL_MAX_COUNT*NEBOC_TYPE_ENTRY_SIZE
outp: resq 1
section .text
_start:
 lea rdi,[rel table]
 lea rsi,[rel entries]
 mov edx,NEBOC_TYPE_V02_TEXTUAL_MAX_COUNT
 call neboc_type_table_init
 test eax,eax
 jnz .fail
 lea rdi,[rel table]
 call neboc_type_table_declare_builtins
 test eax,eax
 jnz .fail
 lea rdi,[rel table]
 call neboc_type_table_declare_intrinsic_types
 test eax,eax
 jnz .fail
 lea rdi,[rel table]
 call neboc_type_table_declare_foundation_float
 test eax,eax
 jnz .fail
 lea rdi,[rel table]
 call neboc_type_table_declare_text_char_bytes
 test eax,eax
 jnz .fail
 cmp qword [rel table+NEBOC_TYPE_TABLE_COUNT_OFFSET],11
 jne .fail
 lea rdi,[rel table]
 mov esi,NEBOC_TYPE_ID_CHAR
 lea rdx,[rel outp]
 call neboc_type_table_get
 test eax,eax
 jnz .fail
 mov rax,[rel outp]
 cmp qword [rax+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_CHAR
 jne .fail
 lea rdi,[rel table]
 mov esi,NEBOC_TYPE_ID_BYTES
 lea rdx,[rel outp]
 call neboc_type_table_get
 test eax,eax
 jnz .fail
 mov rax,[rel outp]
 cmp qword [rax+NEBOC_TYPE_ENTRY_KIND_OFFSET],NEBOC_TYPE_KIND_BYTES
 jne .fail
 lea rdi,[rel table]
 call neboc_type_table_freeze
 test eax,eax
 jnz .fail
 mov eax,60
 xor edi,edi
 syscall
.fail: mov eax,60
 mov edi,1
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
