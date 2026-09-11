; Typed JSON values own canonical UTF-8 bytes. The existing strict parser
; validates depth, entries, numeric domains, key order and trailing data.
bits 64
default rel
%include "runtime/core/runtime_core.inc"
%include "compiler/semantic/data/data_contract.inc"
extern nebo_json_canonical_copy
extern nebo_csv_parse_i64
extern nebo_csv_write_i64
extern nebo_runtime_filesystem_public
extern neboc_schema_validate
extern neboc_column_init
extern neboc_table_validate
extern nebo_tabular_call
extern nebo_tabular_schema_copy
extern nebo_runtime_trap_arithmetic_domain
global nebo_codec_public
section .text
; op, receiver, argument, argument2, caller storage (16320 bytes).
nebo_codec_public:
 cmp edi,110
 jae codec_csv
 push rbx
 push r12
 push r13
 mov r12,r8
 cmp edi,100
 je .parse
 cmp edi,101
 jne .trap
 cmp rdx,1
 jne .trap
 mov rbx,rsi
 jmp .copy
.parse:
 mov rbx,rdx
.copy:
 mov rdi,[rbx]
 mov rsi,[rbx+8]
 cmp rsi,4096
 ja .trap
 lea rdx,[r12+32]
 mov ecx,4096
 mov r8d,64
 mov r9d,1024
 call nebo_json_canonical_copy
 test eax,eax
 jnz .trap
 lea rax,[r12+32]
 mov [r12],rax
 mov [r12+8],rdx
 mov qword [r12+16],0
 mov word [r12+20],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 mov qword [r12+24],0
 mov rax,r12
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 jmp nebo_runtime_trap_arithmetic_domain

; Csv options in this public profile are an explicit ordered Int Schema.
; UTF-8, comma delimiters, RFC double quotes, nullable empty cells, LF output,
; 8 columns/32 rows/4096 bytes and atomic replacement are fixed policies.
; Every native parser/formatter validates before publishing a value or file.
codec_csv:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov ebx,edi
 mov r12,r8
 mov r13,rdx
 mov r14,rcx
 mov r15,rcx
 cmp ebx,110
 je .schema
 cmp ebx,111
 jne .trap
 mov r15,r9
.schema:
 mov rdi,r15
 call neboc_schema_validate
 test eax,eax
 jnz .trap
 xor ecx,ecx
.types:
 cmp rcx,[r15+NEBO_SCHEMA_FIELD_COUNT]
 jae .dispatch
 mov rax,[r15+NEBO_SCHEMA_DTYPES]
 cmp qword [rax+rcx*8],NEBO_DTYPE_I64
 jne .trap
 inc rcx
 jmp .types
.dispatch:
 cmp ebx,111
 je .write
 ; Reuse the current-directory File capability and exact native cleanup.
 mov [r12+8192],r13
 mov qword [r12+8200],1
 mov qword [r12+8208],4096
 mov edi,10
 lea rsi,[r12+8192]
 call nebo_runtime_filesystem_public
 mov rdi,[rax]
 mov rsi,[rax+8]
 lea rdx,[r12+5504]
 lea rcx,[r12+7552]
 mov r8d,256
 mov r9,[r15+NEBO_SCHEMA_FIELD_COUNT]
 shl r9,32
 or r9,32
 call nebo_csv_parse_i64
 test eax,eax
 jnz .trap
 mov [rsp],rdx
 mov edi,450
 mov r8,r12
 call nebo_tabular_call
 xor ebx,ebx
.column:
 cmp rbx,[r15+NEBO_SCHEMA_FIELD_COUNT]
 jae .finish
 mov r9,[r12+7552+rbx*8]
 test r9,r9
 jz .column_init
 bt qword [r15+NEBO_SCHEMA_NULLABLE],rbx
 jnc .trap
.column_init:
 lea rdi,[r12+5120]
 mov rax,rbx
 shl rax,8
 lea rsi,[r12+rax+5504]
 mov rdx,[rsp]
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 call neboc_column_init
 test eax,eax
 jnz .trap
 mov edi,451
 mov rsi,r12
 mov rax,rbx
 shl rax,5
 lea rdx,[r15+rax+256]
 lea rcx,[r12+5120]
 xor r8d,r8d
 call nebo_tabular_call
 inc rbx
 jmp .column
.finish:
 lea rdi,[r12+256]
 mov rsi,r15
 call nebo_tabular_schema_copy
 test eax,eax
 jnz .trap
 mov edi,452
 mov rsi,r12
 xor r8d,r8d
 call nebo_tabular_call
 jmp .done
.write:
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .trap
 mov rax,[r13+NEBO_TABLE_COLUMN_COUNT]
 cmp rax,[r15+NEBO_SCHEMA_FIELD_COUNT]
 jne .trap
 xor ebx,ebx
.gather:
 cmp rbx,[r15+NEBO_SCHEMA_FIELD_COUNT]
 jae .format
 ; Schema names are compared by bytes, not by hashes alone.
 mov rax,rbx
 shl rax,5
 mov rdx,[r13+NEBO_TABLE_SCHEMA]
 lea rdx,[rdx+rax+256]
 lea rax,[r15+rax+256]
 mov rcx,[rax+8]
 cmp rcx,[rdx+8]
 jne .trap
 mov rsi,[rax]
 mov rdi,[rdx]
 repe cmpsb
 jne .trap
 mov rax,[r13+NEBO_TABLE_COLUMNS]
 mov rdx,[rax+rbx*8]
 cmp qword [rdx+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .trap
 mov rax,[rdx+NEBO_COLUMN_MISSING_BITMAP]
 mov [r12+7552+rbx*8],rax
 test rax,rax
 jz .gather_cells
 bt qword [r15+NEBO_SCHEMA_NULLABLE],rbx
 jnc .trap
.gather_cells:
 mov rax,rbx
 shl rax,8
 lea rdi,[r12+rax+5504]
 mov rsi,[rdx+NEBO_COLUMN_VALUES]
 mov rcx,[rdx+NEBO_COLUMN_LENGTH]
 rep movsq
 inc rbx
 jmp .gather
.format:
 lea rdi,[r12+5504]
 lea rsi,[r12+7552]
 mov rdx,[r13+NEBO_TABLE_ROW_COUNT]
 mov rcx,[r13+NEBO_TABLE_COLUMN_COUNT]
 lea r8,[r12+32]
 mov r9d,4096
 call nebo_csv_write_i64
 test eax,eax
 jnz .trap
 lea rax,[r12+32]
 mov [r12],rax
 mov [r12+8],rdx
 mov qword [r12+16],0
 mov word [r12+20],NEBO_RUNTIME_TEXT_ENCODING_UTF8
 mov qword [r12+24],0
 mov [r12+8192],r14
 mov [r12+8200],r12
 mov qword [r12+8208],1
 mov qword [r12+8224],2
 mov edi,11
 lea rsi,[r12+8192]
 call nebo_runtime_filesystem_public
 mov rax,[r13+NEBO_TABLE_ROW_COUNT]
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 jmp nebo_runtime_trap_arithmetic_domain
section .note.GNU-stack noalloc noexec nowrite progbits
