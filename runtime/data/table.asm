; COLECOES-PRIMITIVAS-F03 bounded typed Table and relational index operations.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_column_validate
extern neboc_column_get
section .text

; schema_init(schema*, names*, dtypes*, nullable_bitmap, defaults*, count)
NEBOC_ABI_FUNCTION neboc_schema_init
 push rbx
 mov rbx,rcx
 test rdi,rdi
 jz .si_bad
 test rdi,7
 jnz .si_bad
 test rsi,rsi
 jz .si_bad
 test rdx,rdx
 jz .si_bad
 test r9,r9
 jz .si_limit
 cmp r9,NEBO_DATA_MAX_FIELDS
 ja .si_limit
 mov r10,rcx
 mov rcx,r9
 mov rax,r10
 shr rax,cl
 test rax,rax
 jnz .si_bad
 xor r10d,r10d
.si_outer:
 cmp r10,r9
 jae .si_commit
 cmp qword [rsi+r10*8],0
 je .si_bad
 mov rax,[rdx+r10*8]
 cmp rax,NEBO_DTYPE_I64
 jb .si_bad
 cmp rax,NEBO_DTYPE_FLOAT64
 ja .si_bad
 xor r11d,r11d
.si_inner:
 cmp r11,r10
 jae .si_next
 mov rax,[rsi+r10*8]
 cmp rax,[rsi+r11*8]
 je .si_bad
 inc r11
 jmp .si_inner
.si_next:
 inc r10
 jmp .si_outer
.si_commit:
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rbx
 mov rcx,NEBO_SCHEMA_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_SCHEMA_NAMES],r13
 mov [r12+NEBO_SCHEMA_DTYPES],r14
 mov [r12+NEBO_SCHEMA_NULLABLE],r15
 mov [r12+NEBO_SCHEMA_DEFAULTS],r8
 mov [r12+NEBO_SCHEMA_FIELD_COUNT],r9
 mov qword [r12+NEBO_SCHEMA_GENERATION],1
 xor eax,eax
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.si_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 pop rbx
 ret
.si_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_schema_validate
 test rdi,rdi
 jz .sv_bad
 mov r9,[rdi+NEBO_SCHEMA_FIELD_COUNT]
 test r9,r9
 jz .sv_source
 cmp r9,NEBO_DATA_MAX_FIELDS
 ja .sv_source
 mov rsi,[rdi+NEBO_SCHEMA_NAMES]
 mov rdx,[rdi+NEBO_SCHEMA_DTYPES]
 test rsi,rsi
 jz .sv_source
 test rdx,rdx
 jz .sv_source
 mov rcx,r9
 mov rax,[rdi+NEBO_SCHEMA_NULLABLE]
 shr rax,cl
 test rax,rax
 jnz .sv_source
 xor r10d,r10d
.sv_outer:
 cmp r10,r9
 jae .sv_ok
 cmp qword [rsi+r10*8],0
 je .sv_source
 mov rax,[rdx+r10*8]
 cmp rax,NEBO_DTYPE_I64
 jb .sv_source
 cmp rax,NEBO_DTYPE_FLOAT64
 ja .sv_source
 xor r11d,r11d
.sv_inner:
 cmp r11,r10
 jae .sv_next
 mov rax,[rsi+r10*8]
 cmp rax,[rsi+r11*8]
 je .sv_source
 inc r11
 jmp .sv_inner
.sv_next: inc r10
 jmp .sv_outer
.sv_ok: xor eax,eax
 ret
.sv_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.sv_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; table_init(table*, schema*, column_ptrs*, count, row_capacity)
NEBOC_ABI_FUNCTION neboc_table_init
 test rdi,rdi
 jz .ti_bad
 test rdi,7
 jnz .ti_bad
 test rsi,rsi
 jz .ti_bad
 test rdx,rdx
 jz .ti_bad
 test rcx,rcx
 jz .ti_limit
 cmp rcx,NEBO_DATA_MAX_FIELDS
 ja .ti_limit
 test r8,r8
 jz .ti_limit
 cmp r8,NEBO_DATA_MAX_ROWS
 ja .ti_limit
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
 mov rdi,r13
 call neboc_schema_validate
 test eax,eax
 jnz .ti_done
 cmp [r13+NEBO_SCHEMA_FIELD_COUNT],r15
 jne .ti_source
 xor r10d,r10d
 xor r11d,r11d
.ti_loop:
 cmp r10,r15
 jae .ti_commit
 mov rdi,[r14+r10*8]
 test rdi,rdi
 jz .ti_source
 push r10
 push r11
 call neboc_column_validate
 pop r11
 pop r10
 test eax,eax
 jnz .ti_source
 mov rax,[r14+r10*8]
 mov rcx,[rax+NEBO_COLUMN_DTYPE]
 mov rdx,[r13+NEBO_SCHEMA_DTYPES]
 cmp rcx,[rdx+r10*8]
 jne .ti_source
 mov rcx,[rax+NEBO_COLUMN_LENGTH]
 test r10,r10
 jz .ti_first
 cmp rcx,r11
 jne .ti_source
 jmp .ti_next
.ti_first: mov r11,rcx
.ti_next:
 inc r10
 jmp .ti_loop
.ti_commit:
 cmp r11,rbp
 ja .ti_limit_saved
 mov rdi,r12
 mov ecx,NEBO_TABLE_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_TABLE_SCHEMA],r13
 mov [r12+NEBO_TABLE_COLUMNS],r14
 mov [r12+NEBO_TABLE_COLUMN_COUNT],r15
 mov [r12+NEBO_TABLE_ROW_COUNT],r11
 mov qword [r12+NEBO_TABLE_GENERATION],1
 mov [r12+NEBO_TABLE_ROW_CAPACITY],rbp
 xor eax,eax
 jmp .ti_done
.ti_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .ti_done
.ti_limit_saved: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.ti_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.ti_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.ti_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_table_validate
 test rdi,rdi
 jz .tv_bad
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,[r12+NEBO_TABLE_SCHEMA]
 mov r14,[r12+NEBO_TABLE_COLUMNS]
 mov r15,[r12+NEBO_TABLE_COLUMN_COUNT]
 test r13,r13
 jz .tv_source
 test r14,r14
 jz .tv_source
 test r15,r15
 jz .tv_source
 cmp r15,NEBO_DATA_MAX_FIELDS
 ja .tv_source
 cmp qword [r12+NEBO_TABLE_ROW_CAPACITY],NEBO_DATA_MAX_ROWS
 ja .tv_source
 mov rdi,r13
 call neboc_schema_validate
 test eax,eax
 jnz .tv_source
 cmp [r13+NEBO_SCHEMA_FIELD_COUNT],r15
 jne .tv_source
 xor r10d,r10d
.tv_loop:
 cmp r10,r15
 jae .tv_ok
 mov rdi,[r14+r10*8]
 push r10
 call neboc_column_validate
 pop r10
 test eax,eax
 jnz .tv_source
 mov rax,[r14+r10*8]
 mov rcx,[rax+NEBO_COLUMN_LENGTH]
 cmp rcx,[r12+NEBO_TABLE_ROW_COUNT]
 jne .tv_source
 mov rdx,[r13+NEBO_SCHEMA_DTYPES]
 mov rcx,[rax+NEBO_COLUMN_DTYPE]
 cmp rcx,[rdx+r10*8]
 jne .tv_source
 inc r10
 jmp .tv_loop
.tv_ok: xor eax,eax
 jmp .tv_done
.tv_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.tv_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.tv_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; table_get(table*, row, column, out_value*, present*)
NEBOC_ABI_FUNCTION neboc_table_get
 test rcx,rcx
 jz .tg_bad
 test r8,r8
 jz .tg_bad
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
 mov qword [r15],0
 mov qword [rbp],0
 call neboc_table_validate
 test eax,eax
 jnz .tg_done
 cmp r13,[r12+NEBO_TABLE_ROW_COUNT]
 jae .tg_limit
 cmp r14,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .tg_limit
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov rdi,[rax+r14*8]
 mov rsi,r13
 mov rdx,r15
 mov rcx,rbp
 call neboc_column_get
 jmp .tg_done
.tg_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.tg_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.tg_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; table_select(src*, indices*, count, select_work*)
NEBOC_ABI_FUNCTION neboc_table_select
 test rsi,rsi
 jz .ts_bad
 test rcx,rcx
 jz .ts_bad
 test rdx,rdx
 jz .ts_limit
 cmp rdx,NEBO_DATA_MAX_FIELDS
 ja .ts_limit
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_table_validate
 test eax,eax
 jnz .ts_done
 mov rax,[r15+NEBO_TABLE_SELECT_NAMES]
 test rax,rax
 jz .ts_bad_saved
 mov rax,[r15+NEBO_TABLE_SELECT_DTYPES]
 test rax,rax
 jz .ts_bad_saved
 mov rax,[r15+NEBO_TABLE_SELECT_DEFAULTS]
 test rax,rax
 jz .ts_bad_saved
 mov rax,[r15+NEBO_TABLE_SELECT_COLUMNS]
 test rax,rax
 jz .ts_bad_saved
 mov rax,[r15+NEBO_TABLE_SELECT_SCHEMA]
 test rax,rax
 jz .ts_bad_saved
 mov rax,[r15+NEBO_TABLE_SELECT_TABLE]
 test rax,rax
 jz .ts_bad_saved
 xor r10d,r10d
.ts_check:
 cmp r10,r14
 jae .ts_write
 mov rax,[r13+r10*8]
 cmp rax,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .ts_limit_saved
 xor r11d,r11d
.ts_dup:
 cmp r11,r10
 jae .ts_next
 cmp rax,[r13+r11*8]
 je .ts_bad_saved
 inc r11
 jmp .ts_dup
.ts_next: inc r10
 jmp .ts_check
.ts_write:
 mov rbp,[r12+NEBO_TABLE_SCHEMA]
 xor r10d,r10d
 xor r9d,r9d
 xor r8d,r8d
.ts_copy:
 cmp r10,r14
 jae .ts_schema
 mov rax,[r13+r10*8]
 mov rcx,[rbp+NEBO_SCHEMA_NAMES]
 mov rdx,[rcx+rax*8]
 mov rcx,[r15+NEBO_TABLE_SELECT_NAMES]
 mov [rcx+r10*8],rdx
 mov rcx,[rbp+NEBO_SCHEMA_DTYPES]
 mov rdx,[rcx+rax*8]
 mov rcx,[r15+NEBO_TABLE_SELECT_DTYPES]
 mov [rcx+r10*8],rdx
 mov rcx,[rbp+NEBO_SCHEMA_DEFAULTS]
 xor edx,edx
 test rcx,rcx
 jz .ts_default
 mov rdx,[rcx+rax*8]
.ts_default:
 mov rcx,[r15+NEBO_TABLE_SELECT_DEFAULTS]
 mov [rcx+r10*8],rdx
 bt qword [rbp+NEBO_SCHEMA_NULLABLE],rax
 jnc .ts_no_nullable
 bts r8,r10
.ts_no_nullable:
 bt qword [rbp+NEBO_SCHEMA_DEFAULT_BITMAP],rax
 jnc .ts_no_default
 bts r9,r10
.ts_no_default:
 mov rcx,[r12+NEBO_TABLE_COLUMNS]
 mov rdx,[rcx+rax*8]
 mov rcx,[r15+NEBO_TABLE_SELECT_COLUMNS]
 mov [rcx+r10*8],rdx
 inc r10
 jmp .ts_copy
.ts_schema:
 mov rdi,[r15+NEBO_TABLE_SELECT_SCHEMA]
 mov rcx,NEBO_SCHEMA_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,[r15+NEBO_TABLE_SELECT_SCHEMA]
 mov rax,[r15+NEBO_TABLE_SELECT_NAMES]
 mov [rdi+NEBO_SCHEMA_NAMES],rax
 mov rax,[r15+NEBO_TABLE_SELECT_DTYPES]
 mov [rdi+NEBO_SCHEMA_DTYPES],rax
 mov [rdi+NEBO_SCHEMA_NULLABLE],r8
 mov rax,[r15+NEBO_TABLE_SELECT_DEFAULTS]
 mov [rdi+NEBO_SCHEMA_DEFAULTS],rax
 mov [rdi+NEBO_SCHEMA_DEFAULT_BITMAP],r9
 mov [rdi+NEBO_SCHEMA_FIELD_COUNT],r14
 mov qword [rdi+NEBO_SCHEMA_GENERATION],1
 mov rdi,[r15+NEBO_TABLE_SELECT_TABLE]
 mov rcx,NEBO_TABLE_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,[r15+NEBO_TABLE_SELECT_TABLE]
 mov rax,[r15+NEBO_TABLE_SELECT_SCHEMA]
 mov [rdi+NEBO_TABLE_SCHEMA],rax
 mov rax,[r15+NEBO_TABLE_SELECT_COLUMNS]
 mov [rdi+NEBO_TABLE_COLUMNS],rax
 mov [rdi+NEBO_TABLE_COLUMN_COUNT],r14
 mov rax,[r12+NEBO_TABLE_ROW_COUNT]
 mov [rdi+NEBO_TABLE_ROW_COUNT],rax
 mov qword [rdi+NEBO_TABLE_GENERATION],1
 mov rax,[r12+NEBO_TABLE_ROW_CAPACITY]
 mov [rdi+NEBO_TABLE_ROW_CAPACITY],rax
 xor eax,eax
 jmp .ts_done
.ts_bad_saved: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .ts_done
.ts_limit_saved: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.ts_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.ts_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.ts_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; filter_eq_i64(table*, column, key, out_rows*, capacity, out_length*)
NEBOC_ABI_FUNCTION neboc_table_filter_eq_i64
 test rcx,rcx
 jz .tf_bad
 test r9,r9
 jz .tf_bad
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
 mov qword [r9],0
 push r9
 call neboc_table_validate
 pop r9
 test eax,eax
 jnz .tf_done
 cmp r13,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .tf_limit
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov rax,[rax+r13*8]
 cmp qword [rax+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .tf_source
 xor r10d,r10d
 xor r11d,r11d
 mov rcx,[rax+NEBO_COLUMN_VALUES]
 mov rdx,[rax+NEBO_COLUMN_MISSING_BITMAP]
.tf_count:
 cmp r10,[r12+NEBO_TABLE_ROW_COUNT]
 jae .tf_capacity
 bt rdx,r10
 jc .tf_count_next
 cmp [rcx+r10*8],r14
 jne .tf_count_next
 inc r11
.tf_count_next: inc r10
 jmp .tf_count
.tf_capacity:
 cmp r11,rbp
 ja .tf_limit
 xor r10d,r10d
 xor r13d,r13d
.tf_write:
 cmp r10,[r12+NEBO_TABLE_ROW_COUNT]
 jae .tf_ok
 bt rdx,r10
 jc .tf_write_next
 cmp [rcx+r10*8],r14
 jne .tf_write_next
 mov [r15+r13*8],r10
 inc r13
.tf_write_next: inc r10
 jmp .tf_write
.tf_ok: mov [r9],r13
 xor eax,eax
 jmp .tf_done
.tf_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .tf_done
.tf_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.tf_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.tf_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; group_by_i64(table*, column, out_keys*, out_counts*, capacity, out_length*)
NEBOC_ABI_FUNCTION neboc_table_group_by_i64
 test rdx,rdx
 jz .gb_bad
 test rcx,rcx
 jz .gb_bad
 test r9,r9
 jz .gb_bad
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
 mov qword [r9],0
 push r9
 call neboc_table_validate
 pop r9
 test eax,eax
 jnz .gb_done
 cmp r13,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .gb_limit
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov rax,[rax+r13*8]
 cmp qword [rax+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .gb_source
 mov rdx,[rax+NEBO_COLUMN_VALUES]
 mov rcx,[rax+NEBO_COLUMN_MISSING_BITMAP]
 xor r10d,r10d
 xor r11d,r11d
.gb_pre_row:
 cmp r10,[r12+NEBO_TABLE_ROW_COUNT]
 jae .gb_capacity
 bt rcx,r10
 jc .gb_pre_next
 xor r13d,r13d
.gb_pre_prior:
 cmp r13,r10
 jae .gb_pre_unique
 bt rcx,r13
 jc .gb_pre_prior_next
 mov rax,[rdx+r13*8]
 cmp rax,[rdx+r10*8]
 je .gb_pre_next
.gb_pre_prior_next: inc r13
 jmp .gb_pre_prior
.gb_pre_unique: inc r11
.gb_pre_next: inc r10
 jmp .gb_pre_row
.gb_capacity:
 cmp r11,rbp
 ja .gb_limit
 xor r10d,r10d
 xor r11d,r11d
.gb_row:
 cmp r10,[r12+NEBO_TABLE_ROW_COUNT]
 jae .gb_ok
 bt rcx,r10
 jc .gb_next
 xor r13d,r13d
.gb_prior:
 cmp r13,r10
 jae .gb_unique
 bt rcx,r13
 jc .gb_prior_next
 mov rax,[rdx+r13*8]
 cmp rax,[rdx+r10*8]
 je .gb_next
.gb_prior_next: inc r13
 jmp .gb_prior
.gb_unique:
 mov rax,[rdx+r10*8]
 mov [r14+r11*8],rax
 xor r13d,r13d
 xor edi,edi
.gb_count:
 cmp r13,[r12+NEBO_TABLE_ROW_COUNT]
 jae .gb_store_count
 bt rcx,r13
 jc .gb_count_next
 cmp rax,[rdx+r13*8]
 jne .gb_count_next
 inc rdi
.gb_count_next: inc r13
 jmp .gb_count
.gb_store_count:
 mov [r15+r11*8],rdi
 inc r11
.gb_next: inc r10
 jmp .gb_row
.gb_ok: mov [r9],r11
 xor eax,eax
 jmp .gb_done
.gb_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .gb_done
.gb_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.gb_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.gb_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; inner_join_i64(left*, right*, left_column, right_column, join_work*)
NEBOC_ABI_FUNCTION neboc_table_inner_join_i64
 test r8,r8
 jz .tj_bad
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
 mov rax,[rbp+NEBO_TABLE_JOIN_LENGTH]
 test rax,rax
 jz .tj_bad_saved
 mov qword [rax],0
 mov rax,[rbp+NEBO_TABLE_JOIN_LEFT_ROWS]
 test rax,rax
 jz .tj_bad_saved
 mov rax,[rbp+NEBO_TABLE_JOIN_RIGHT_ROWS]
 test rax,rax
 jz .tj_bad_saved
 mov rdi,r12
 call neboc_table_validate
 test eax,eax
 jnz .tj_done
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .tj_done
 cmp r14,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .tj_limit
 cmp r15,[r13+NEBO_TABLE_COLUMN_COUNT]
 jae .tj_limit
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov r10,[rax+r14*8]
 mov rax,[r13+NEBO_TABLE_COLUMNS]
 mov r11,[rax+r15*8]
 cmp qword [r10+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .tj_source
 cmp qword [r11+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .tj_source
 xor ecx,ecx
 xor edx,edx
.tj_pre_left:
 cmp rcx,[r12+NEBO_TABLE_ROW_COUNT]
 jae .tj_capacity
 bt qword [r10+NEBO_COLUMN_MISSING_BITMAP],rcx
 jc .tj_pre_left_next
 xor eax,eax
.tj_pre_right:
 cmp rax,[r13+NEBO_TABLE_ROW_COUNT]
 jae .tj_pre_left_next
 bt qword [r11+NEBO_COLUMN_MISSING_BITMAP],rax
 jc .tj_pre_right_next
 mov rsi,[r10+NEBO_COLUMN_VALUES]
 mov rdi,[r11+NEBO_COLUMN_VALUES]
 mov rsi,[rsi+rcx*8]
 cmp rsi,[rdi+rax*8]
 jne .tj_pre_right_next
 inc rdx
 cmp rdx,NEBO_DATA_MAX_JOIN_ROWS
 ja .tj_limit
.tj_pre_right_next: inc rax
 jmp .tj_pre_right
.tj_pre_left_next: inc rcx
 jmp .tj_pre_left
.tj_capacity:
 cmp rdx,[rbp+NEBO_TABLE_JOIN_CAPACITY]
 ja .tj_limit
 xor ecx,ecx
 xor edx,edx
.tj_left:
 cmp rcx,[r12+NEBO_TABLE_ROW_COUNT]
 jae .tj_ok
 bt qword [r10+NEBO_COLUMN_MISSING_BITMAP],rcx
 jc .tj_left_next
 xor eax,eax
.tj_right:
 cmp rax,[r13+NEBO_TABLE_ROW_COUNT]
 jae .tj_left_next
 bt qword [r11+NEBO_COLUMN_MISSING_BITMAP],rax
 jc .tj_right_next
 mov rsi,[r10+NEBO_COLUMN_VALUES]
 mov rdi,[r11+NEBO_COLUMN_VALUES]
 mov rsi,[rsi+rcx*8]
 cmp rsi,[rdi+rax*8]
 jne .tj_right_next
 mov rdi,[rbp+NEBO_TABLE_JOIN_LEFT_ROWS]
 mov [rdi+rdx*8],rcx
 mov rdi,[rbp+NEBO_TABLE_JOIN_RIGHT_ROWS]
 mov [rdi+rdx*8],rax
 inc rdx
.tj_right_next: inc rax
 jmp .tj_right
.tj_left_next: inc rcx
 jmp .tj_left
.tj_ok:
 mov rax,[rbp+NEBO_TABLE_JOIN_LENGTH]
 mov [rax],rdx
 xor eax,eax
 jmp .tj_done
.tj_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .tj_done
.tj_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .tj_done
.tj_bad_saved: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.tj_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.tj_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
