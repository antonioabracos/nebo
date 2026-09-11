; Source-owned bounded schemas use the canonical ordered native schema owner.
; Names retain their UTF-8 bytes in caller storage, so hash lookup is followed
; by exact name equality and cannot manufacture a field on a hash collision.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/data/data_contract.inc"
%define PUBLIC_SCHEMA_HASHES 64
%define PUBLIC_SCHEMA_DTYPES 128
%define PUBLIC_SCHEMA_DEFAULTS 192
%define PUBLIC_SCHEMA_TEXTS 256
%define PUBLIC_SCHEMA_BYTES 512
%define PUBLIC_SCHEMA_NAME_LIMIT 128
%define PUBLIC_TABLE_SCHEMA 256
%define PUBLIC_TABLE_COLUMNS 128
%define PUBLIC_TABLE_STORAGE 2304
%define PUBLIC_TABLE_COLUMN_BYTES 320
%define PUBLIC_DATASET_SCHEMA 256
%define PUBLIC_DATASET_TABLES 128
%define PUBLIC_DATASET_STORAGE 2304
%define PUBLIC_TABLE_BYTES 5120
%define PUBLIC_ROWS_SCHEMA 64
%define PUBLIC_ROWS_STORAGE 2112
extern neboc_schema_init
extern neboc_schema_validate
extern neboc_schema_index_of
extern neboc_schema_field
extern neboc_row_from
extern neboc_row_get
extern neboc_row_project
extern neboc_row_to_tuple
extern neboc_column_init
extern neboc_column_validate
extern neboc_column_get
extern neboc_table_from_columns
extern neboc_table_validate
extern neboc_table_row_count
extern neboc_table_column_count
extern neboc_table_sort_by_i64
extern neboc_table_select
extern neboc_table_group_by_i64
extern neboc_table_join_i64
extern neboc_table_invalid_rows
extern neboc_dataset_from_tables
extern neboc_dataset_validate
extern neboc_dataset_schema
extern neboc_dataset_partition_count
extern neboc_dataset_scan
extern neboc_dataset_collect_refs
extern neboc_dataset_cache
extern neboc_hasher_init
extern neboc_hasher_write_bytes
extern neboc_hasher_finish
extern nebo_runtime_trap
section .text
; Native single-key join materialization. Inputs: dst, left, right, key Text,
; native kind (1 inner, 2 left). The shared key is emitted once; other names
; must be distinct. Output order is left row, then matching right row order.
tabular_table_join:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,656
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov [rsp+552],rcx
 mov [rsp+560],r8
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .done
 mov rdi,r14
 call neboc_table_validate
 test eax,eax
 jnz .done
 mov edi,402
 mov rsi,[r13+NEBO_TABLE_SCHEMA]
 mov rdx,[rsp+552]
 xor ecx,ecx
 lea r8,[rsp+624]
 call nebo_tabular_call
 cmp qword [rsp+624],1
 jne .invalid
 mov rax,[rsp+632]
 mov [rsp+568],rax
 mov edi,402
 mov rsi,[r14+NEBO_TABLE_SCHEMA]
 mov rdx,[rsp+552]
 xor ecx,ecx
 lea r8,[rsp+624]
 call nebo_tabular_call
 cmp qword [rsp+624],1
 jne .invalid
 mov rax,[rsp+632]
 mov [rsp+576],rax
 lea rax,[rsp]
 mov [rsp+512+NEBO_TABLE_JOIN_LEFT_ROWS],rax
 lea rax,[rsp+256]
 mov [rsp+512+NEBO_TABLE_JOIN_RIGHT_ROWS],rax
 mov qword [rsp+512+NEBO_TABLE_JOIN_CAPACITY],32
 lea rax,[rsp+544]
 mov [rsp+512+NEBO_TABLE_JOIN_LENGTH],rax
 mov rdi,r13
 mov rsi,r14
 mov rdx,[rsp+568]
 mov rcx,[rsp+576]
 mov r8,[rsp+560]
 lea r9,[rsp+512]
 call neboc_table_join_i64
 test eax,eax
 jnz .done
 lea rdi,[r12+PUBLIC_TABLE_SCHEMA]
 mov rsi,[r13+NEBO_TABLE_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .done
 xor r15d,r15d
.schema:
 cmp r15,[r14+NEBO_TABLE_COLUMN_COUNT]
 jae .columns_begin
 cmp r15,[rsp+576]
 je .schema_next
 mov rdx,[r14+NEBO_TABLE_SCHEMA]
 mov rax,r15
 shl rax,5
 lea rdx,[rdx+rax+PUBLIC_SCHEMA_TEXTS]
 mov edi,401
 lea rsi,[r12+PUBLIC_TABLE_SCHEMA]
 mov ecx,1
 xor r8d,r8d
 call nebo_tabular_call
.schema_next:
 inc r15
 jmp .schema
.columns_begin:
 xor r15d,r15d
.column:
 cmp r15,[r12+PUBLIC_TABLE_SCHEMA+NEBO_SCHEMA_FIELD_COUNT]
 jae .table
 mov rax,r15
 mov rdx,r13
 lea rcx,[rsp]
 cmp rax,[r13+NEBO_TABLE_COLUMN_COUNT]
 jb .source_column
 sub rax,[r13+NEBO_TABLE_COLUMN_COUNT]
 cmp rax,[rsp+576]
 jb .right_column
 inc rax
.right_column:
 mov rdx,r14
 lea rcx,[rsp+256]
.source_column:
 mov [rsp+608],rcx
 mov rdx,[rdx+NEBO_TABLE_COLUMNS]
 mov rax,[rdx+rax*8]
 cmp qword [rax+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .invalid
 mov [rsp+592],rax
 mov rax,r15
 imul rax,PUBLIC_TABLE_COLUMN_BYTES
 lea rax,[r12+rax+PUBLIC_TABLE_STORAGE]
 mov [rsp+600],rax
 mov qword [rsp+640],0
 xor ebx,ebx
.cell:
 cmp rbx,[rsp+544]
 jae .column_init
 mov rax,[rsp+608]
 mov rsi,[rax+rbx*8]
 cmp rsi,-1
 je .missing
 mov rdi,[rsp+592]
 lea rdx,[rsp+624]
 lea rcx,[rsp+632]
 call neboc_column_get
 test eax,eax
 jnz .done
 cmp qword [rsp+632],0
 je .missing
 mov rax,[rsp+624]
 jmp .store
.missing:
 bts qword [rsp+640],rbx
 xor eax,eax
.store:
 mov rdx,[rsp+600]
 mov [rdx+64+rbx*8],rax
 inc rbx
 jmp .cell
.column_init:
 mov rdi,[rsp+600]
 lea rsi,[rdi+64]
 mov rdx,[rsp+544]
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 mov r9,[rsp+640]
 call neboc_column_init
 test eax,eax
 jnz .done
 mov rax,[rsp+600]
 mov [r12+PUBLIC_TABLE_COLUMNS+r15*8],rax
 inc r15
 jmp .column
.table:
 mov rdi,r12
 lea rsi,[r12+PUBLIC_TABLE_SCHEMA]
 lea rdx,[r12+PUBLIC_TABLE_COLUMNS]
 mov rcx,r15
 mov r8d,32
 call neboc_table_from_columns
 jmp .done
.invalid:
 mov eax,1
.done:
 add rsp,656
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Materialized groups retain first-seen key order and source row order. The
; canonical native Int grouping policy excludes missing keys. Every yielded
; table owns all original columns and can be independently aggregated/filtered.
; dst groups*, source Table*, key Text*; maximum 32 groups, each <=32 rows.
tabular_table_groups:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,832
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r12],0
 mov qword [r12+8],0
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .done
 mov edi,402
 mov rsi,[r13+NEBO_TABLE_SCHEMA]
 mov rdx,r14
 xor ecx,ecx
 lea r8,[rsp+768]
 call nebo_tabular_call
 cmp qword [rsp+768],1
 jne .invalid
 mov r14,[rsp+776]
 mov rdi,r13
 mov rsi,r14
 mov rdx,rsp
 lea rcx,[rsp+256]
 mov r8d,32
 lea r9,[rsp+784]
 call neboc_table_group_by_i64
 test eax,eax
 jnz .done
 xor ebx,ebx
.group:
 cmp rbx,[rsp+784]
 jae .finish
 mov qword [rsp+792],0
 xor r15d,r15d
.row:
 cmp r15,[r13+NEBO_TABLE_ROW_COUNT]
 jae .gather
 mov rax,[r13+NEBO_TABLE_COLUMNS]
 mov rdi,[rax+r14*8]
 mov rsi,r15
 lea rdx,[rsp+800]
 lea rcx,[rsp+808]
 call neboc_column_get
 test eax,eax
 jnz .done
 cmp qword [rsp+808],0
 je .next
 mov rax,[rsp+800]
 cmp rax,[rsp+rbx*8]
 jne .next
 mov rax,[rsp+792]
 mov [rsp+512+rax*8],r15
 inc qword [rsp+792]
.next:
 inc r15
 jmp .row
.gather:
 mov rcx,[rsp+792]
 cmp rcx,[rsp+256+rbx*8]
 jne .invalid
 mov rax,rbx
 imul rax,PUBLIC_TABLE_BYTES
 lea rdi,[r12+rax+320]
 mov [rsp+816],rdi
 mov rsi,r13
 lea rdx,[rsp+512]
 call neboc_table_gather_i64
 test eax,eax
 jnz .done
 mov rax,[rsp+816]
 mov [r12+32+rbx*8],rax
 inc rbx
 jmp .group
.finish:
 mov [r12],rbx
 xor eax,eax
 jmp .done
.invalid:
 mov eax,1
.done:
 add rsp,832
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Bounded by-size repartitioning of actual native rows into independent tables.
; dst Dataset*, source Dataset*, maximum rows per output partition (1..32).
; This materializes through the canonical collect owner; it does not reuse the
; older internal strategy-1 partition reversal as a public by-size operation.
NEBOC_ABI_FUNCTION neboc_dataset_repartition_rows_i64
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,34944
 mov r12,rdi
 mov r13,rsi
 mov [rsp+34880],rdx
 cmp rdx,1
 jb .invalid
 cmp rdx,32
 ja .invalid
 mov rdi,r13
 call neboc_dataset_validate
 test eax,eax
 jnz .done
 cmp qword [r13+NEBO_DATASET_FLAGS],0
 jne .invalid
 mov rax,[r13+NEBO_DATASET_ROWS]
 add rax,[rsp+34880]
 dec rax
 xor edx,edx
 div qword [rsp+34880]
 test rax,rax
 jnz .partition_count
 inc rax
.partition_count:
 cmp rax,8
 ja .invalid
 mov [rsp+34888],rax
 mov rdi,rsp
 mov rsi,r13
 call tabular_dataset_collect
 test eax,eax
 jnz .done
 lea rdi,[r12+PUBLIC_DATASET_SCHEMA]
 lea rsi,[rsp+PUBLIC_ROWS_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .done
 mov qword [rsp+34896],0
.partition:
 mov rax,[rsp+34896]
 cmp rax,[rsp+34888]
 jae .dataset
 imul rax,[rsp+34880]
 mov [rsp+34904],rax
 mov rcx,[rsp]
 sub rcx,rax
 cmp rcx,[rsp+34880]
 jbe .rows_ready
 mov rcx,[rsp+34880]
.rows_ready:
 mov [rsp+34912],rcx
 mov r14,[rsp+34896]
 imul r14,PUBLIC_TABLE_BYTES
 lea r14,[r12+r14+PUBLIC_DATASET_STORAGE]
 lea rdi,[r14+PUBLIC_TABLE_SCHEMA]
 lea rsi,[r12+PUBLIC_DATASET_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .done
 xor r15d,r15d
.column:
 cmp r15,[r12+PUBLIC_DATASET_SCHEMA+NEBO_SCHEMA_FIELD_COUNT]
 jae .table
 mov rax,r15
 imul rax,PUBLIC_TABLE_COLUMN_BYTES
 lea rax,[r14+rax+PUBLIC_TABLE_STORAGE]
 mov [rsp+34920],rax
 xor ebx,ebx
 xor r13d,r13d
.cell:
 cmp rbx,[rsp+34912]
 jae .column_init
 mov rax,[rsp+34904]
 add rax,rbx
 shl rax,7
 lea rax,[rsp+rax+PUBLIC_ROWS_STORAGE]
 mov rcx,[rax+64+r15*8]
 mov rdx,[rsp+34920]
 mov [rdx+64+rbx*8],rcx
 bt qword [rax+NEBO_ROW_MISSING_BITMAP],r15
 jnc .present
 bts r13,rbx
.present:
 inc rbx
 jmp .cell
.column_init:
 mov rdi,[rsp+34920]
 lea rsi,[rdi+64]
 mov rdx,[rsp+34912]
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 mov r9,r13
 call neboc_column_init
 test eax,eax
 jnz .done
 mov rax,[rsp+34920]
 mov [r14+PUBLIC_TABLE_COLUMNS+r15*8],rax
 inc r15
 jmp .column
.table:
 mov rdi,r14
 lea rsi,[r12+PUBLIC_DATASET_SCHEMA]
 lea rdx,[r14+PUBLIC_TABLE_COLUMNS]
 mov rcx,r15
 mov r8d,32
 call neboc_table_from_columns
 test eax,eax
 jnz .done
 mov rax,[rsp+34896]
 mov [r12+PUBLIC_DATASET_TABLES+rax*8],r14
 inc qword [rsp+34896]
 jmp .partition
.dataset:
 mov rdi,r12
 lea rsi,[r12+PUBLIC_DATASET_SCHEMA]
 lea rdx,[r12+PUBLIC_DATASET_TABLES]
 mov rcx,[rsp+34888]
 mov r8d,256
 mov r9d,16384
 call neboc_dataset_from_tables
 jmp .done
.invalid:
 mov eax,1
.done:
 add rsp,34944
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Copy an authenticated native Row into an independent public Row value.
; Both ordinary Rows and compact collected rows carry the same native layout.
tabular_row_copy:
 push r12
 push r13
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 lea rdi,[r12+128]
 mov rsi,[r13+NEBO_ROW_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[r12+128]
 mov rdx,[r13+NEBO_ROW_VALUES]
 mov rcx,[r13+NEBO_ROW_MISSING_BITMAP]
 lea r8,[r12+64]
 mov r9,rsp
 call neboc_row_from
.done:
 add rsp,24
 pop r13
 pop r12
 ret

; Materialize the native finite partition/row reference plan into owned rows.
; The compact cells share one immutable owned schema; no Dataset pointers escape.
; Caller storage: count, cursor, 2048-byte schema, 256 native Row/cell records.
tabular_dataset_collect:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,6416
 mov r12,rdi
 mov r13,rsi
 mov qword [r12],0
 mov qword [r12+8],0
 mov rdi,r13
 mov rsi,rsp
 lea rdx,[rsp+2048]
 mov ecx,256
 lea r8,[rsp+6400]
 call neboc_dataset_collect_refs
 test eax,eax
 jnz .done
 lea rdi,[r12+PUBLIC_ROWS_SCHEMA]
 mov rsi,[r13+NEBO_DATASET_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .done
 xor ebx,ebx
.row:
 cmp rbx,[rsp+6400]
 jae .finish
 mov rax,[rsp+rbx*8]
 mov rsi,[r13+NEBO_DATASET_TABLES]
 mov rsi,[rsi+rax*8]
 mov rdx,[rsp+2048+rbx*8]
 lea rdi,[rsp+4096]
 call tabular_row_from_table
 test eax,eax
 jnz .done
 mov r14,rbx
 shl r14,7
 lea r14,[r12+r14+PUBLIC_ROWS_STORAGE]
 mov rdi,r14
 lea rsi,[r12+PUBLIC_ROWS_SCHEMA]
 lea rdx,[rsp+4096+64]
 mov rcx,[rsp+4096+NEBO_ROW_MISSING_BITMAP]
 lea r8,[r14+64]
 lea r9,[rsp+6408]
 call neboc_row_from
 test eax,eax
 jnz .done
 inc rbx
 jmp .row
.finish:
 mov [r12],rbx
 xor eax,eax
.done:
 add rsp,6416
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Independent table copy is the identity row gather, preserving schema,
; values, row order and missing state through the same canonical owner.
tabular_table_copy:
 push r12
 push r13
 sub rsp,264
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .done
 xor ecx,ecx
.index:
 cmp rcx,[r13+NEBO_TABLE_ROW_COUNT]
 jae .gather
 mov [rsp+rcx*8],rcx
 inc rcx
 jmp .index
.gather:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rsp
 call neboc_table_gather_i64
.done:
 add rsp,264
 pop r13
 pop r12
 ret

; Equality of actual ordered public schema metadata, not descriptor addresses.
; The native Dataset owner can then share one authenticated immutable schema.
tabular_schema_equal:
 xor edx,edx
 jmp tabular_schema_compare
; Constraints may strengthen nullability without changing field identity/type.
tabular_schema_fields_equal:
 mov edx,1
tabular_schema_compare:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov [rsp],rdx
 mov r12,rdi
 mov r13,rsi
 call neboc_schema_validate
 test eax,eax
 jnz .no
 mov rdi,r13
 call neboc_schema_validate
 test eax,eax
 jnz .no
 mov rax,[r12+NEBO_SCHEMA_FIELD_COUNT]
 cmp rax,[r13+NEBO_SCHEMA_FIELD_COUNT]
 jne .no
 cmp qword [rsp],0
 jne .fields
 mov rax,[r12+NEBO_SCHEMA_NULLABLE]
 cmp rax,[r13+NEBO_SCHEMA_NULLABLE]
 jne .no
 mov rax,[r12+NEBO_SCHEMA_DEFAULT_BITMAP]
 cmp rax,[r13+NEBO_SCHEMA_DEFAULT_BITMAP]
 jne .no
.fields:
 xor ebx,ebx
.field:
 cmp rbx,[r12+NEBO_SCHEMA_FIELD_COUNT]
 jae .yes
 mov rax,[r12+NEBO_SCHEMA_DTYPES]
 mov rdx,[r13+NEBO_SCHEMA_DTYPES]
 mov rax,[rax+rbx*8]
 cmp rax,[rdx+rbx*8]
 jne .no
 mov rax,rbx
 shl rax,5
 mov rcx,[r12+rax+PUBLIC_SCHEMA_TEXTS+8]
 cmp rcx,[r13+rax+PUBLIC_SCHEMA_TEXTS+8]
 jne .no
 mov rdi,[r12+rax+PUBLIC_SCHEMA_TEXTS]
 mov rsi,[r13+rax+PUBLIC_SCHEMA_TEXTS]
 repe cmpsb
 jne .no
 inc rbx
 jmp .field
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; Replace a native projection's borrowed column pointers by independent
; descriptors/cells, retaining exactly the columns selected by its owner.
tabular_own_columns:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 xor ebx,ebx
.column:
 cmp rbx,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .validate
 mov rax,[r12+NEBO_TABLE_COLUMNS]
 mov r13,[rax+rbx*8]
 mov rdi,r13
 call neboc_column_validate
 test eax,eax
 jnz .done
 cmp qword [r13+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .invalid
 mov rax,rbx
 imul rax,PUBLIC_TABLE_COLUMN_BYTES
 lea r14,[r12+rax+PUBLIC_TABLE_STORAGE]
 lea rdi,[r14+64]
 mov rsi,[r13+NEBO_COLUMN_VALUES]
 mov rcx,[r13+NEBO_COLUMN_LENGTH]
 rep movsq
 mov rdi,r14
 lea rsi,[r14+64]
 mov rdx,[r13+NEBO_COLUMN_LENGTH]
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 mov r9,[r13+NEBO_COLUMN_MISSING_BITMAP]
 call neboc_column_init
 test eax,eax
 jnz .done
 mov [r12+PUBLIC_TABLE_COLUMNS+rbx*8],r14
 inc rbx
 jmp .column
.validate:
 lea rax,[r12+PUBLIC_TABLE_COLUMNS]
 mov [r12+NEBO_TABLE_COLUMNS],rax
 mov rdi,r12
 call neboc_table_validate
 jmp .done
.invalid:
 mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Materialize one row through native Column/Row owners. The public Row callback
; receives its actual values, missing bitmap and independent schema snapshot.
tabular_row_from_table:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .done
 cmp r14,[r13+NEBO_TABLE_ROW_COUNT]
 jae .invalid
 lea rdi,[r12+128]
 mov rsi,[r13+NEBO_TABLE_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .done
 xor ebx,ebx
 xor r15d,r15d
.cell:
 cmp r15,[r13+NEBO_TABLE_COLUMN_COUNT]
 jae .row
 mov rax,[r13+NEBO_TABLE_COLUMNS]
 mov rdi,[rax+r15*8]
 cmp qword [rdi+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .invalid
 mov rsi,r14
 lea rdx,[r12+64+r15*8]
 mov rcx,rsp
 call neboc_column_get
 test eax,eax
 jnz .done
 cmp qword [rsp],0
 jne .present
 bts rbx,r15
.present:
 inc r15
 jmp .cell
.row:
 mov rdi,r12
 lea rsi,[r12+128]
 lea rdx,[r12+64]
 mov rcx,rbx
 lea r8,[r12+64]
 mov r9,rsp
 call neboc_row_from
 jmp .done
.invalid:
 mov eax,1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Canonical bounded gather for native Int tables: dst, src, row indices, count.
; Actual Column getters supply each cell and missing bit; table/schema owners
; authenticate the resulting independent storage. Filter and ordering share it.
NEBOC_ABI_FUNCTION neboc_table_gather_i64
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov [rsp],rdx
 mov [rsp+8],rcx
 cmp rcx,32
 ja .invalid
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .done
 xor ecx,ecx
.validate_indices:
 cmp rcx,[rsp+8]
 jae .schema
 mov rdx,[rsp]
 mov rax,[rdx+rcx*8]
 cmp rax,[r13+NEBO_TABLE_ROW_COUNT]
 jae .invalid
 inc rcx
 jmp .validate_indices
.schema:
 lea rdi,[r12+PUBLIC_TABLE_SCHEMA]
 mov rsi,[r13+NEBO_TABLE_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .done
 xor r14d,r14d
.column:
 cmp r14,[r13+NEBO_TABLE_COLUMN_COUNT]
 jae .table
 mov rax,[r13+NEBO_TABLE_COLUMNS]
 mov rax,[rax+r14*8]
 cmp qword [rax+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .invalid
 mov rax,r14
 imul rax,PUBLIC_TABLE_COLUMN_BYTES
 lea rax,[r12+rax+PUBLIC_TABLE_STORAGE]
 mov [rsp+16],rax
 mov [r12+PUBLIC_TABLE_COLUMNS+r14*8],rax
 xor ebx,ebx
 xor r15d,r15d
.cell:
 cmp r15,[rsp+8]
 jae .column_init
 mov rax,[r13+NEBO_TABLE_COLUMNS]
 mov rdi,[rax+r14*8]
 mov rax,[rsp]
 mov rsi,[rax+r15*8]
 mov rax,[rsp+16]
 lea rdx,[rax+64+r15*8]
 lea rcx,[rsp+24]
 call neboc_column_get
 test eax,eax
 jnz .done
 cmp qword [rsp+24],0
 jne .present
 bts rbx,r15
.present:
 inc r15
 jmp .cell
.column_init:
 mov rdi,[rsp+16]
 lea rsi,[rdi+64]
 mov rdx,[rsp+8]
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 mov r9,rbx
 call neboc_column_init
 test eax,eax
 jnz .done
 inc r14
 jmp .column
.table:
 mov rdi,r12
 lea rsi,[r12+PUBLIC_TABLE_SCHEMA]
 lea rdx,[r12+PUBLIC_TABLE_COLUMNS]
 mov rcx,[rsi+NEBO_SCHEMA_FIELD_COUNT]
 mov r8d,32
 call neboc_table_from_columns
 jmp .done
.invalid:
 mov eax,1
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Clone a source-owned schema, repairing every internal pointer. Rows retain
; schema and name snapshots independently of future constructor evaluations.
global nebo_tabular_schema_copy
nebo_tabular_schema_copy:
tabular_schema_copy:
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,r13
 call neboc_schema_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 mov ecx,256
 rep movsq
 lea rax,[r12+PUBLIC_SCHEMA_HASHES]
 mov [r12+NEBO_SCHEMA_NAMES],rax
 lea rax,[r12+PUBLIC_SCHEMA_DTYPES]
 mov [r12+NEBO_SCHEMA_DTYPES],rax
 lea rax,[r12+PUBLIC_SCHEMA_DEFAULTS]
 mov [r12+NEBO_SCHEMA_DEFAULTS],rax
 xor ecx,ecx
.name:
 cmp rcx,[r12+NEBO_SCHEMA_FIELD_COUNT]
 jae .ok
 mov rax,rcx
 shl rax,7
 lea rax,[r12+rax+PUBLIC_SCHEMA_BYTES]
 mov rdx,rcx
 shl rdx,5
 mov [r12+rdx+PUBLIC_SCHEMA_TEXTS],rax
 inc rcx
 jmp .name
.ok:
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop r12
 ret

; Text descriptor* -> native deterministic hash. The same native Hasher is
; used for construction and lookup. No compiler or fixture name is consulted.
tabular_name_hash:
 push r12
 sub rsp,48
 mov r12,rdi
 test r12,r12
 jz .trap
 cmp qword [r12+8],1
 jb .trap
 cmp qword [r12+8],PUBLIC_SCHEMA_NAME_LIMIT
 ja .trap
 test qword [r12],-1
 jz .trap
 mov rdi,rsp
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 call neboc_hasher_init
 test eax,eax
 jnz .trap
 mov rdi,rsp
 mov rsi,[r12]
 mov rdx,[r12+8]
 call neboc_hasher_write_bytes
 test eax,eax
 jnz .trap
 mov rdi,rsp
 call neboc_hasher_finish
 test rax,rax
 jz .trap
 add rsp,48
 pop r12
 ret
.trap:
 mov edi,49
 call nebo_runtime_trap
 ud2

NEBOC_ABI_FUNCTION nebo_tabular_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov [rsp+24],r9
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,400
 je .schema_new
 cmp ebx,401
 je .schema_append
 cmp ebx,402
 je .schema_lookup
 cmp ebx,403
 je .schema_lookup
 cmp ebx,410
 je .field_name
 cmp ebx,411
 je .field_dtype
 cmp ebx,412
 je .field_nullable
 cmp ebx,413
 je .field_length
 cmp ebx,420
 je .row_new
 cmp ebx,421
 je .row_append
 cmp ebx,422
 je .row_append_option
 cmp ebx,423
 je .row_finish
 cmp ebx,424
 je .row_get
 cmp ebx,425
 je .row_project_new
 cmp ebx,426
 je .row_project_append
 cmp ebx,427
 je .row_project_finish
 cmp ebx,428
 je .row_to_tuple
 cmp ebx,438
 je .row_tuple_length
 cmp ebx,450
 je .table_new
 cmp ebx,451
 je .table_append
 cmp ebx,452
 je .table_finish
 cmp ebx,453
 je .table_query
 cmp ebx,454
 je .table_query
 cmp ebx,455
 je .table_select_new
 cmp ebx,456
 je .table_filter
 cmp ebx,457
 je .table_sort
 cmp ebx,459
 je .table_select_append
 cmp ebx,460
 je .table_select_finish
 cmp ebx,500
 je .dataset_new
 cmp ebx,501
 je .dataset_append
 cmp ebx,502
 je .dataset_finish
 cmp ebx,503
 je .dataset_schema
 cmp ebx,504
 je .dataset_count
 cmp ebx,510
 je .dataset_scan
 cmp ebx,511
 je .dataset_scan_next
 cmp ebx,512
 je .table_option_some
 cmp ebx,513
 je .table_option_none
 cmp ebx,514
 je .table_option_expect
 cmp ebx,515
 je .dataset_scan_sink
 cmp ebx,520
 je .dataset_collect
 cmp ebx,521
 je .dataset_rows_length
 cmp ebx,522
 je .dataset_rows_at
 cmp ebx,523
 je .dataset_rows_next
 cmp ebx,524
 je .row_option_expect
 cmp ebx,535
 je .dataset_repartition
 cmp ebx,536
 je .dataset_cache
 cmp ebx,545
 je .table_groups
 cmp ebx,550
 je .table_join
 cmp ebx,560
 je .table_constraints
 cmp ebx,561
 je .table_invalid_rows
 cmp ebx,430
 jb .trap
 cmp ebx,437
 jbe .row_tuple_at
 jmp .trap
.schema_new:
 mov rdi,r15
 mov ecx,256
 xor eax,eax
 rep stosq
 jmp .result
.schema_append:
 cmp r14,1
 ja .trap
 cmp qword [r12+NEBO_SCHEMA_FIELD_COUNT],8
 jae .trap
 mov rdi,r13
 call tabular_name_hash
 mov rbx,[r12+NEBO_SCHEMA_FIELD_COUNT]
 mov [r12+PUBLIC_SCHEMA_HASHES+rbx*8],rax
 mov qword [r12+PUBLIC_SCHEMA_DTYPES+rbx*8],NEBO_DTYPE_I64
 mov rax,rbx
 shl rax,5
 mov rcx,rbx
 shl rcx,7
 lea rdi,[r12+rcx+PUBLIC_SCHEMA_BYTES]
 mov [r12+rax+PUBLIC_SCHEMA_TEXTS],rdi
 mov rcx,[r13+8]
 mov [r12+rax+PUBLIC_SCHEMA_TEXTS+8],rcx
 mov rdx,[r13+16]
 mov [r12+rax+PUBLIC_SCHEMA_TEXTS+16],rdx
 mov rsi,[r13]
 rep movsb
 mov rcx,[r12+NEBO_SCHEMA_NULLABLE]
 test r14,r14
 jz .schema_nullable_ready
 bts rcx,rbx
.schema_nullable_ready:
 mov rdi,r12
 lea rsi,[r12+PUBLIC_SCHEMA_HASHES]
 lea rdx,[r12+PUBLIC_SCHEMA_DTYPES]
 lea r8,[r12+PUBLIC_SCHEMA_DEFAULTS]
 lea r9,[rbx+1]
 call neboc_schema_init
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.schema_lookup:
 mov rdi,r13
 call tabular_name_hash
 mov [rsp+16],rax
 mov rdi,r12
 mov rsi,rax
 mov rdx,rsp
 lea rcx,[rsp+8]
 call neboc_schema_index_of
 test eax,eax
 jnz .trap
 cmp qword [rsp+8],1
 jne .lookup_ready
 mov rax,[rsp]
 shl rax,5
 mov rcx,[r12+rax+PUBLIC_SCHEMA_TEXTS+8]
 cmp rcx,[r13+8]
 jne .lookup_collision
 mov rdi,[r12+rax+PUBLIC_SCHEMA_TEXTS]
 mov rsi,[r13]
 repe cmpsb
 je .lookup_ready
.lookup_collision:
 mov qword [rsp+8],0
.lookup_ready:
 cmp ebx,403
 je .field_result
 mov rax,[rsp+8]
 mov [r15],rax
 mov rax,[rsp]
 mov [r15+8],rax
 jmp .result
.field_result:
 cmp qword [rsp+8],1
 jne .trap
 mov rax,[rsp]
 shl rax,5
 lea rax,[r12+rax+PUBLIC_SCHEMA_TEXTS]
 lea rdi,[r15+64]
 mov [r15+32],rdi
 mov rcx,[rax+8]
 mov [r15+40],rcx
 mov rdx,[rax+16]
 mov [r15+48],rdx
 mov rsi,[rax]
 rep movsb
 lea rax,[r15+32]
 mov [r15],rax
 mov rdi,r12
 mov rsi,[rsp+16]
 lea rdx,[r15+8]
 lea rcx,[r15+16]
 call neboc_schema_field
 test eax,eax
 jnz .trap
 jmp .result
.field_name:
 mov rax,[r12]
 jmp .done
.field_dtype:
 mov rax,[r12+8]
 jmp .done
.field_nullable:
 mov rax,[r12+16]
 jmp .done
.field_length:
 mov eax,3
 jmp .done
.row_new:
 mov rdi,r15
 mov ecx,16
 xor eax,eax
 rep stosq
 lea rdi,[r15+128]
 mov rsi,r13
 call tabular_schema_copy
 test eax,eax
 jnz .trap
 lea rax,[r15+128]
 mov [r15+NEBO_ROW_SCHEMA],rax
 jmp .result
.row_append_option:
 cmp qword [r13],1
 ja .trap
 cmp qword [r13],0
 jne .row_option_present
 mov rcx,[r12+48]
 cmp rcx,8
 jae .trap
 bts qword [r12+56],rcx
 xor r13d,r13d
 jmp .row_append
.row_option_present:
 mov r13,[r13+8]
.row_append:
 mov rcx,[r12+48]
 mov rax,[r12+NEBO_ROW_SCHEMA]
 cmp rcx,[rax+NEBO_SCHEMA_FIELD_COUNT]
 jae .trap
 mov [r12+64+rcx*8],r13
 inc qword [r12+48]
 mov rax,r12
 jmp .done
.row_finish:
 mov rsi,[r12+NEBO_ROW_SCHEMA]
 mov rax,[rsi+NEBO_SCHEMA_FIELD_COUNT]
 cmp rax,[r12+48]
 jne .trap
 mov rdi,r12
 lea rdx,[r12+64]
 mov rcx,[r12+56]
 lea r8,[r12+64]
 mov r9,rsp
 call neboc_row_from
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.row_get:
 mov edi,402
 mov rsi,[r12+NEBO_ROW_SCHEMA]
 mov rdx,r13
 xor ecx,ecx
 mov r8,rsp
 call nebo_tabular_call
 cmp qword [rsp],1
 jne .trap
 mov rdi,r13
 call tabular_name_hash
 mov rdi,r12
 mov rsi,rax
 lea rdx,[r15+8]
 mov rcx,r15
 call neboc_row_get
 test eax,eax
 jnz .trap
 jmp .result
.row_project_new:
 mov rdi,r15
 mov ecx,288
 xor eax,eax
 rep stosq
 mov [r15+56],r12
 lea rax,[r15+128]
 mov [r15+NEBO_ROW_SCHEMA],rax
 jmp .result
.row_project_append:
 cmp qword [r12+48],8
 jae .trap
 mov rax,[r12+56]
 mov edi,402
 mov rsi,[rax+NEBO_ROW_SCHEMA]
 mov rdx,r13
 xor ecx,ecx
 mov r8,rsp
 call nebo_tabular_call
 cmp qword [rsp],1
 jne .trap
 mov r14,[rsp+8]
 xor ecx,ecx
.project_duplicate:
 cmp rcx,[r12+48]
 jae .project_field
 cmp [r12+2176+rcx*8],r14
 je .trap
 inc rcx
 jmp .project_duplicate
.project_field:
 mov [r12+2176+rcx*8],r14
 mov rax,[r12+56]
 mov rax,[rax+NEBO_ROW_SCHEMA]
 xor ecx,ecx
 bt qword [rax+NEBO_SCHEMA_NULLABLE],r14
 setc cl
 mov edi,401
 lea rsi,[r12+128]
 mov rdx,r13
 xor r8d,r8d
 call nebo_tabular_call
 inc qword [r12+48]
 mov rax,r12
 jmp .done
.row_project_finish:
 mov rdi,[r12+56]
 lea rsi,[r12+2176]
 mov rdx,[r12+48]
 lea rcx,[r12+64]
 mov r8,rsp
 call neboc_row_project
 test eax,eax
 jnz .trap
 mov rdi,r12
 lea rsi,[r12+128]
 lea rdx,[r12+64]
 mov rcx,[rsp]
 lea r8,[r12+64]
 lea r9,[rsp+8]
 call neboc_row_from
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.row_to_tuple:
 mov rdi,r12
 lea rsi,[r15+32]
 mov edx,8
 mov rcx,r15
 lea r8,[r15+8]
 call neboc_row_to_tuple
 test eax,eax
 jnz .trap
 jmp .result
.row_tuple_length:
 mov rax,[r12]
 jmp .done
.row_tuple_at:
 sub ebx,430
 cmp rbx,[r12]
 jae .trap
 xor eax,eax
 bt qword [r12+8],rbx
 setnc al
 mov [r15],rax
 mov rax,[r12+32+rbx*8]
 mov [r15+8],rax
 jmp .result
.table_new:
 mov rdi,r15
 mov ecx,640
 xor eax,eax
 rep stosq
 jmp .result
.table_append:
 mov rbx,[r12+PUBLIC_TABLE_SCHEMA+NEBO_SCHEMA_FIELD_COUNT]
 cmp rbx,8
 jae .trap
 mov rdi,r14
 call neboc_column_validate
 test eax,eax
 jnz .trap
 cmp qword [r14+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .trap
 mov rax,rbx
 imul rax,PUBLIC_TABLE_COLUMN_BYTES
 lea rax,[r12+rax+PUBLIC_TABLE_STORAGE]
 mov [rsp+16],rax
 mov [r12+PUBLIC_TABLE_COLUMNS+rbx*8],rax
 lea rdi,[rax+64]
 mov rsi,[r14+NEBO_COLUMN_VALUES]
 mov rcx,[r14+NEBO_COLUMN_LENGTH]
 rep movsq
 mov rdi,[rsp+16]
 lea rsi,[rdi+64]
 mov rdx,[r14+NEBO_COLUMN_LENGTH]
 mov ecx,32
 mov r8d,NEBO_DTYPE_I64
 mov r9,[r14+NEBO_COLUMN_MISSING_BITMAP]
 call neboc_column_init
 test eax,eax
 jnz .trap
 mov edi,401
 lea rsi,[r12+PUBLIC_TABLE_SCHEMA]
 mov rdx,r13
 mov ecx,1 ; nullable Column<Int> retains its missing-capable public type
 xor r8d,r8d
 call nebo_tabular_call
 mov rax,r12
 jmp .done
.table_finish:
 mov rdi,r12
 lea rsi,[r12+PUBLIC_TABLE_SCHEMA]
 lea rdx,[r12+PUBLIC_TABLE_COLUMNS]
 mov rcx,[rsi+NEBO_SCHEMA_FIELD_COUNT]
 mov r8d,32
 call neboc_table_from_columns
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.table_query:
 mov rdi,r12
 call neboc_table_validate
 test eax,eax
 jnz .trap
 mov rdi,r12
 mov rsi,r15
 cmp ebx,453
 jne .table_column_query
 call neboc_table_row_count
 jmp .table_scalar
.table_column_query:
 call neboc_table_column_count
.table_scalar:
 test eax,eax
 jnz .trap
 mov rax,[r15]
 jmp .done
.table_filter:
 mov rdi,r12
 call neboc_table_validate
 test eax,eax
 jnz .trap
 sub rsp,2560 ; one owned Row plus at most 32 selected source indices
 xor ebx,ebx
 xor r14d,r14d
.table_filter_row:
 cmp rbx,[r12+NEBO_TABLE_ROW_COUNT]
 jae .table_filter_gather
 mov rdi,rsp
 mov rsi,r12
 mov rdx,rbx
 call tabular_row_from_table
 test eax,eax
 jnz .trap
 mov rdi,rsp
 call r13
 cmp rax,1
 ja .trap
 test rax,rax
 jz .table_filter_next
 mov [rsp+2304+r14*8],rbx
 inc r14
.table_filter_next:
 inc rbx
 jmp .table_filter_row
.table_filter_gather:
 mov rdi,r15
 mov rsi,r12
 lea rdx,[rsp+2304]
 mov rcx,r14
 call neboc_table_gather_i64
 test eax,eax
 jnz .trap
 add rsp,2560
 jmp .result
.table_sort:
 mov edi,402
 mov rsi,[r12+NEBO_TABLE_SCHEMA]
 mov rdx,r13
 xor ecx,ecx
 mov r8,rsp
 call nebo_tabular_call
 cmp qword [rsp],1
 jne .trap
 mov r14,[rsp+8]
 sub rsp,272
 mov rdi,r12
 mov rsi,r14
 mov rdx,rsp
 mov ecx,32
 lea r8,[rsp+256]
 call neboc_table_sort_by_i64
 test eax,eax
 jnz .trap
 mov rdi,r15
 mov rsi,r12
 mov rdx,rsp
 mov rcx,[rsp+256]
 call neboc_table_gather_i64
 test eax,eax
 jnz .trap
 add rsp,272
 jmp .result
.table_select_new:
 mov rdi,r15
 mov ecx,640
 xor eax,eax
 rep stosq
 mov [r15+80],r12
 jmp .result
.table_select_append:
 mov r14,[r12+PUBLIC_TABLE_SCHEMA+NEBO_SCHEMA_FIELD_COUNT]
 cmp r14,8
 jae .trap
 mov rax,[r12+80]
 mov edi,402
 mov rsi,[rax+NEBO_TABLE_SCHEMA]
 mov rdx,r13
 xor ecx,ecx
 mov r8,rsp
 call nebo_tabular_call
 cmp qword [rsp],1
 jne .trap
 mov rax,[rsp+8]
 mov [r12+4864+r14*8],rax
 mov rdx,[r12+80]
 mov rdx,[rdx+NEBO_TABLE_SCHEMA]
 xor ecx,ecx
 bt qword [rdx+NEBO_SCHEMA_NULLABLE],rax
 setc cl
 mov edi,401
 lea rsi,[r12+PUBLIC_TABLE_SCHEMA]
 mov rdx,r13
 xor r8d,r8d
 call nebo_tabular_call
 mov rax,r12
 jmp .done
.table_select_finish:
 lea r14,[r12+PUBLIC_TABLE_SCHEMA]
 lea rbx,[r12+4928]
 lea rax,[r14+PUBLIC_SCHEMA_HASHES]
 mov [rbx+NEBO_TABLE_SELECT_NAMES],rax
 lea rax,[r14+PUBLIC_SCHEMA_DTYPES]
 mov [rbx+NEBO_TABLE_SELECT_DTYPES],rax
 lea rax,[r14+PUBLIC_SCHEMA_DEFAULTS]
 mov [rbx+NEBO_TABLE_SELECT_DEFAULTS],rax
 lea rax,[r12+PUBLIC_TABLE_COLUMNS]
 mov [rbx+NEBO_TABLE_SELECT_COLUMNS],rax
 mov [rbx+NEBO_TABLE_SELECT_SCHEMA],r14
 mov [rbx+NEBO_TABLE_SELECT_TABLE],r12
 mov rdi,[r12+80]
 lea rsi,[r12+4864]
 mov rdx,[r14+NEBO_SCHEMA_FIELD_COUNT]
 mov rcx,rbx
 call neboc_table_select
 test eax,eax
 jnz .trap
 mov rdi,r12
 call tabular_own_columns
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.dataset_new:
 mov rdi,r15
 mov ecx,5440
 xor eax,eax
 rep stosq
 jmp .result
.dataset_append:
 cmp qword [r12+64],8
 jae .trap
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .trap
 cmp qword [r12+64],0
 jne .dataset_same_schema
 lea rdi,[r12+PUBLIC_DATASET_SCHEMA]
 mov rsi,[r13+NEBO_TABLE_SCHEMA]
 call tabular_schema_copy
 test eax,eax
 jnz .trap
 jmp .dataset_copy_table
.dataset_same_schema:
 lea rdi,[r12+PUBLIC_DATASET_SCHEMA]
 mov rsi,[r13+NEBO_TABLE_SCHEMA]
 call tabular_schema_equal
 test eax,eax
 jz .trap
.dataset_copy_table:
 mov rbx,[r12+64]
 mov rax,rbx
 imul rax,PUBLIC_TABLE_BYTES
 lea r14,[r12+rax+PUBLIC_DATASET_STORAGE]
 mov rdi,r14
 mov rsi,r13
 call tabular_table_copy
 test eax,eax
 jnz .trap
 lea rax,[r12+PUBLIC_DATASET_SCHEMA]
 mov [r14+NEBO_TABLE_SCHEMA],rax
 mov [r12+PUBLIC_DATASET_TABLES+rbx*8],r14
 inc qword [r12+64]
 mov rax,r12
 jmp .done
.dataset_finish:
 mov rdi,r12
 lea rsi,[r12+PUBLIC_DATASET_SCHEMA]
 lea rdx,[r12+PUBLIC_DATASET_TABLES]
 mov rcx,[r12+64]
 mov r8d,256
 mov r9d,16384
 call neboc_dataset_from_tables
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.dataset_schema:
 mov rdi,r12
 mov rsi,rsp
 call neboc_dataset_schema
 test eax,eax
 jnz .trap
 mov rdi,r15
 mov rsi,[rsp]
 call tabular_schema_copy
 test eax,eax
 jnz .trap
 jmp .result
.dataset_count:
 mov rdi,r12
 call neboc_dataset_validate
 test eax,eax
 jnz .trap
 mov rdi,r12
 mov rsi,r15
 call neboc_dataset_partition_count
 test eax,eax
 jnz .trap
 mov rax,[r15]
 jmp .done
.dataset_scan:
 mov qword [r15+8],0
 mov rdi,r12
 lea rsi,[r15+32]
 mov edx,8
 mov rcx,r15
 call neboc_dataset_scan
 test eax,eax
 jnz .trap
 jmp .result
.dataset_scan_next:
 mov qword [r15],0
 mov rbx,[r12+8]
 cmp rbx,[r12]
 jae .result
 lea rdi,[r15+16]
 mov rsi,[r12+32+rbx*8]
 call tabular_table_copy
 test eax,eax
 jnz .trap
 inc qword [r12+8]
 mov qword [r15],1
 jmp .result
.table_option_some:
 mov rax,[r12]
 jmp .done
.table_option_none:
 xor eax,eax
 cmp qword [r12],0
 sete al
 jmp .done
.table_option_expect:
 cmp qword [r12],1
 jne .trap
 mov rdi,r15
 lea rsi,[r12+16]
 call tabular_table_copy
 test eax,eax
 jnz .trap
 mov qword [r12],0
 jmp .result
.dataset_scan_sink:
 xor ebx,ebx
.dataset_sink_next:
 mov rax,[r12+8]
 cmp rax,[r12]
 jae .dataset_sink_done
 mov rdi,[r12+32+rax*8]
 call r13
 inc qword [r12+8]
 inc rbx
 jmp .dataset_sink_next
.dataset_sink_done:
 mov rax,rbx
 jmp .done
.dataset_collect:
 mov rdi,r15
 mov rsi,r12
 call tabular_dataset_collect
 test eax,eax
 jnz .trap
 jmp .result
.dataset_repartition:
 mov rdi,r15
 mov rsi,r12
 mov rdx,r13
 call neboc_dataset_repartition_rows_i64
 test eax,eax
 jnz .trap
 jmp .result
.dataset_cache:
 mov rdi,r12
 mov rsi,r13
 call neboc_dataset_cache
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.table_groups:
 mov rdi,r15
 mov rsi,r12
 mov rdx,r13
 call tabular_table_groups
 test eax,eax
 jnz .trap
 jmp .result
.table_join:
 mov rdi,r15
 mov rsi,r12
 mov rdx,r13
 mov rcx,r14
 mov r8,[rsp+24]
 call tabular_table_join
 test eax,eax
 jnz .trap
 jmp .result
.table_constraints:
 mov rdi,r12
 call neboc_table_validate
 test eax,eax
 jnz .trap
 mov rdi,[r12+NEBO_TABLE_SCHEMA]
 mov rsi,r13
 call tabular_schema_fields_equal
 test eax,eax
 jz .trap
 sub rsp,96
 mov rdi,rsp
 mov rsi,r12
 mov ecx,NEBO_TABLE_SIZE/8
 rep movsq
 mov [rsp+NEBO_TABLE_SCHEMA],r13
 mov rdi,rsp
 lea rsi,[rsp+80]
 call neboc_table_invalid_rows
 test eax,eax
 jnz .constraints_failed
 mov rax,[rsp+80]
 mov [r12+NEBO_TABLE_RESERVED],rax
 mov qword [r12+NEBO_TABLE_FLAGS],1
 test rax,rax
 setz al
 movzx eax,al
 add rsp,96
 jmp .done
.constraints_failed:
 add rsp,96
 jmp .trap
.table_invalid_rows:
 mov rdi,r12
 call neboc_table_validate
 test eax,eax
 jnz .trap
 sub rsp,272
 cmp qword [r12+NEBO_TABLE_FLAGS],1
 je .last_constraints
 mov rdi,r12
 lea rsi,[rsp+256]
 call neboc_table_invalid_rows
 test eax,eax
 jnz .invalid_rows_failed
 mov rax,[rsp+256]
 jmp .invalid_indices
.last_constraints:
 mov rax,[r12+NEBO_TABLE_RESERVED]
.invalid_indices:
 xor ecx,ecx
 xor edx,edx
.invalid_row:
 cmp rdx,[r12+NEBO_TABLE_ROW_COUNT]
 jae .invalid_gather
 bt rax,rdx
 jnc .invalid_next
 mov [rsp+rcx*8],rdx
 inc rcx
.invalid_next:
 inc rdx
 jmp .invalid_row
.invalid_gather:
 mov rdi,r15
 mov rsi,r12
 mov rdx,rsp
 call neboc_table_gather_i64
 test eax,eax
 jnz .invalid_rows_failed
 add rsp,272
 jmp .result
.invalid_rows_failed:
 add rsp,272
 jmp .trap
.dataset_rows_length:
 mov rax,[r12]
 jmp .done
.dataset_rows_at:
 cmp r13,[r12]
 jae .trap
 shl r13,7
 lea rsi,[r12+r13+PUBLIC_ROWS_STORAGE]
 mov rdi,r15
 call tabular_row_copy
 test eax,eax
 jnz .trap
 jmp .result
.dataset_rows_next:
 mov qword [r15],0
 mov rbx,[r12+8]
 cmp rbx,[r12]
 jae .result
 mov rax,rbx
 shl rax,7
 lea rsi,[r12+rax+PUBLIC_ROWS_STORAGE]
 lea rdi,[r15+16]
 call tabular_row_copy
 test eax,eax
 jnz .trap
 inc qword [r12+8]
 mov qword [r15],1
 jmp .result
.row_option_expect:
 cmp qword [r12],1
 jne .trap
 mov rdi,r15
 lea rsi,[r12+16]
 call tabular_row_copy
 test eax,eax
 jnz .trap
 mov qword [r12],0
 jmp .result
.result:
 mov rax,r15
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 mov edi,49
 call nebo_runtime_trap
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
