; COLECOES-PRIMITIVAS-F04 explicit missing/default/error validation operations.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_schema_validate
extern neboc_table_validate
extern neboc_column_validate
section .text

NEBOC_ABI_FUNCTION neboc_schema_validate_missing_rules
 test rdi,rdi
 jz .svr_bad
 push r12
 mov r12,rdi
 call neboc_schema_validate
 test eax,eax
 jnz .svr_done
 mov rcx,[r12+NEBO_SCHEMA_FIELD_COUNT]
 mov rax,[r12+NEBO_SCHEMA_DEFAULT_BITMAP]
 mov rdx,rax
 shr rdx,cl
 test rdx,rdx
 jnz .svr_source
 test rax,rax
 jz .svr_ok
 cmp qword [r12+NEBO_SCHEMA_DEFAULTS],0
 je .svr_source
.svr_ok: xor eax,eax
 jmp .svr_done
.svr_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.svr_done: pop r12
 ret
.svr_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; apply_defaults(schema*, values*, missing_bitmap, out_values*, out_missing*)
NEBOC_ABI_FUNCTION neboc_row_apply_defaults
 test rsi,rsi
 jz .rad_bad
 test rcx,rcx
 jz .rad_bad
 test r8,r8
 jz .rad_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov qword [rbp],0
 call neboc_schema_validate_missing_rules
 test eax,eax
 jnz .rad_done
 mov rcx,[r12+NEBO_SCHEMA_FIELD_COUNT]
 mov rax,r14
 shr rax,cl
 test rax,rax
 jnz .rad_source
 xor r10d,r10d
.rad_pre:
 cmp r10,rcx
 jae .rad_write
 bt r14,r10
 jnc .rad_pre_next
 bt qword [r12+NEBO_SCHEMA_DEFAULT_BITMAP],r10
 jc .rad_pre_next
 bt qword [r12+NEBO_SCHEMA_NULLABLE],r10
 jnc .rad_source
.rad_pre_next: inc r10
 jmp .rad_pre
.rad_write:
 xor r10d,r10d
 xor r11d,r11d
.rad_loop:
 cmp r10,rcx
 jae .rad_ok
 mov rax,[r13+r10*8]
 bt r14,r10
 jnc .rad_store
 bt qword [r12+NEBO_SCHEMA_DEFAULT_BITMAP],r10
 jnc .rad_missing
 mov rdx,[r12+NEBO_SCHEMA_DEFAULTS]
 mov rax,[rdx+r10*8]
 jmp .rad_store
.rad_missing: bts r11,r10
.rad_store:
 mov [r15+r10*8],rax
 inc r10
 jmp .rad_loop
.rad_ok: mov [rbp],r11
 xor eax,eax
 jmp .rad_done
.rad_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.rad_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.rad_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; table_invalid_rows(table*, out_row_bitmap*)
NEBOC_ABI_FUNCTION neboc_table_invalid_rows
 test rsi,rsi
 jz .tir_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov qword [r13],0
 call neboc_table_validate
 test eax,eax
 jnz .tir_done
 mov r14,[r12+NEBO_TABLE_SCHEMA]
 mov rdi,r14
 call neboc_schema_validate_missing_rules
 test eax,eax
 jnz .tir_done
 xor r10d,r10d
 xor r11d,r11d
.tir_col:
 cmp r10,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .tir_ok
 bt qword [r14+NEBO_SCHEMA_NULLABLE],r10
 jc .tir_next
 bt qword [r14+NEBO_SCHEMA_DEFAULT_BITMAP],r10
 jc .tir_next
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov rax,[rax+r10*8]
 or r11,[rax+NEBO_COLUMN_MISSING_BITMAP]
.tir_next: inc r10
 jmp .tir_col
.tir_ok: mov [r13],r11
 xor eax,eax
.tir_done:
 pop r14
 pop r13
 pop r12
 ret
.tir_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; fill_missing(column*, value, out_filled*)
NEBOC_ABI_FUNCTION neboc_column_fill_missing
 test rdx,rdx
 jz .cfm_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_column_validate
 test eax,eax
 jnz .cfm_done
 cmp qword [r12+NEBO_COLUMN_BORROW],0
 jne .cfm_source
 mov rdx,[r12+NEBO_COLUMN_MISSING_BITMAP]
 xor r10d,r10d
 xor r11d,r11d
 mov rcx,[r12+NEBO_COLUMN_VALUES]
.cfm_loop:
 cmp r10,[r12+NEBO_COLUMN_LENGTH]
 jae .cfm_commit
 bt rdx,r10
 jnc .cfm_next
 mov [rcx+r10*8],r13
 inc r11
.cfm_next: inc r10
 jmp .cfm_loop
.cfm_commit:
 test r11,r11
 jz .cfm_ok
 mov qword [r12+NEBO_COLUMN_MISSING_BITMAP],0
 inc qword [r12+NEBO_COLUMN_GENERATION]
.cfm_ok: mov [r14],r11
 xor eax,eax
 jmp .cfm_done
.cfm_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.cfm_done:
 pop r14
 pop r13
 pop r12
 ret
.cfm_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; coalesce(left*, right*, out_values*, out_missing*)
NEBOC_ABI_FUNCTION neboc_column_coalesce
 test rdx,rdx
 jz .cc_bad
 test rcx,rcx
 jz .cc_bad
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r15],0
 call neboc_column_validate
 test eax,eax
 jnz .cc_done
 mov rdi,r13
 call neboc_column_validate
 test eax,eax
 jnz .cc_done
 mov rax,[r12+NEBO_COLUMN_LENGTH]
 cmp rax,[r13+NEBO_COLUMN_LENGTH]
 jne .cc_source
 mov rax,[r12+NEBO_COLUMN_DTYPE]
 cmp rax,[r13+NEBO_COLUMN_DTYPE]
 jne .cc_source
 xor r10d,r10d
 xor r11d,r11d
.cc_loop:
 cmp r10,[r12+NEBO_COLUMN_LENGTH]
 jae .cc_ok
 bt qword [r12+NEBO_COLUMN_MISSING_BITMAP],r10
 jc .cc_right
 mov rax,[r12+NEBO_COLUMN_VALUES]
 mov rax,[rax+r10*8]
 jmp .cc_store
.cc_right:
 bt qword [r13+NEBO_COLUMN_MISSING_BITMAP],r10
 jc .cc_missing
 mov rax,[r13+NEBO_COLUMN_VALUES]
 mov rax,[rax+r10*8]
 jmp .cc_store
.cc_missing:
 xor eax,eax
 bts r11,r10
.cc_store: mov [r14+r10*8],rax
 inc r10
 jmp .cc_loop
.cc_ok: mov [r15],r11
 xor eax,eax
 jmp .cc_done
.cc_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.cc_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.cc_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
