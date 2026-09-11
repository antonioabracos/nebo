; G010 source-to-effect probe over the real bounded data runtime owners.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"

extern neboc_schema_init
extern neboc_schema_field
extern neboc_schema_index_of
extern neboc_row_from
extern neboc_row_get
extern neboc_row_project
extern neboc_row_to_tuple
extern neboc_column_from
extern neboc_column_get
extern neboc_column_cast
extern neboc_column_sum_i64
extern neboc_column_min_i64
extern neboc_column_max_i64
extern neboc_colecoes_primitivas_column_count_missing
extern neboc_table_from_columns
extern neboc_table_row_count
extern neboc_table_column_count
extern neboc_table_select
extern neboc_table_filter_eq_i64
extern neboc_table_sort_by_i64
extern neboc_table_group_by_i64
extern neboc_table_join_i64
extern neboc_column_is_missing
extern neboc_column_fill_missing
extern neboc_column_drop_missing
extern neboc_column_coalesce
extern neboc_table_validate
extern neboc_table_invalid_rows
extern neboc_dataset_from_tables
extern neboc_dataset_schema
extern neboc_dataset_partition_count
extern neboc_dataset_repartition
extern neboc_dataset_scan
extern neboc_dataset_collect_refs
extern neboc_dataset_cache
extern neboc_event_value
extern neboc_flow_init
extern neboc_flow_value
extern neboc_stream_from
extern neboc_stream_map
extern neboc_stream_filter
extern neboc_stream_batch
extern neboc_stream_window
extern neboc_stream_sink

%define P_SCHEMA 0
%define P_NAMES 64
%define P_DTYPES 128
%define P_DEFAULTS 192
%define P_VALUES_A 256
%define P_VALUES_B 512
%define P_VALUES_C 768
%define P_COL_A 1024
%define P_COL_B 1088
%define P_COL_C 1152
%define P_ROW 1216
%define P_TABLE_A 1280
%define P_TABLE_B 1360
%define P_DATASET 1440
%define P_EVENTS 1536
%define P_FLOW 1664
%define P_STREAM 1728
%define P_OUT_VALUES 1808
%define P_OUT_VALUES_2 2064
%define P_POINTERS 2320
%define P_INDICES 2384
%define P_COUNTS 2640
%define P_JOIN_LEFT 2704
%define P_JOIN_RIGHT 2960
%define P_SELECT_WORK 3216
%define P_SELECT_NAMES 3264
%define P_SELECT_DTYPES 3328
%define P_SELECT_DEFAULTS 3392
%define P_SELECT_COLUMNS 3456
%define P_SELECT_SCHEMA 3520
%define P_SELECT_TABLE 3584
%define P_JOIN_WORK 3664
%define P_OUT_A 3712
%define P_OUT_B 3720
%define P_OUT_C 3728
%define P_OUT_D 3736
%define P_OUT_E 3744
%define P_CONTEXT 3760

section .text

g10_schema_one:
 mov qword [rsp+P_NAMES+8],0xA101
 mov qword [rsp+P_DTYPES+8],NEBO_DTYPE_I64
 mov qword [rsp+P_DEFAULTS+8],0
 lea rdi,[rsp+P_SCHEMA+8]
 lea rsi,[rsp+P_NAMES+8]
 lea rdx,[rsp+P_DTYPES+8]
 xor ecx,ecx
 lea r8,[rsp+P_DEFAULTS+8]
 mov r9d,1
 jmp neboc_schema_init

g10_column_a_three:
 mov eax,r13d
 mov [rsp+P_VALUES_A+8],rax
 inc rax
 mov [rsp+P_VALUES_A+16],rax
 inc rax
 mov [rsp+P_VALUES_A+24],rax
 lea rdi,[rsp+P_COL_A+8]
 lea rsi,[rsp+P_VALUES_A+8]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 jmp neboc_column_from

g10_table_a_one_column:
 lea rax,[rsp+P_COL_A+8]
 mov [rsp+P_SELECT_COLUMNS+8],rax
 lea rdi,[rsp+P_TABLE_A+8]
 lea rsi,[rsp+P_SCHEMA+8]
 lea rdx,[rsp+P_SELECT_COLUMNS+8]
 mov ecx,1
 mov r8d,3
 jmp neboc_table_from_columns

; map(value, context, out*) adds a source-independent configured delta.
g10_map_add:
 test rdx,rdx
 jz .map_bad
 test rsi,rsi
 jz .map_bad
 add rdi,[rsi]
 mov [rdx],rdi
 xor eax,eax
 ret
.map_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

g10_filter_all:
 test rdx,rdx
 jz .filter_bad
 mov qword [rdx],1
 xor eax,eax
 ret
.filter_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

g10_sink_sum:
 test rsi,rsi
 jz .sink_bad
 add [rsi],rdi
 jo .sink_limit
 xor eax,eax
 ret
.sink_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.sink_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

global nebo_g010_source_probe
nebo_g010_source_probe:
 push rbx
 push r12
 push r13
 push r14
 mov r12d,edi
 mov r13d,esi
 sub rsp,8200
 cmp r12d,1
 je .row_schema
 cmp r12d,2
 je .column
 cmp r12d,3
 je .table
 cmp r12d,4
 je .missing
 cmp r12d,5
 je .dataset
 cmp r12d,6
 je .stream
 jmp .failure

.row_schema:
 mov qword [rsp+P_NAMES],0xA101
 mov qword [rsp+P_NAMES+8],0xB202
 mov qword [rsp+P_DTYPES],NEBO_DTYPE_I64
 mov qword [rsp+P_DTYPES+8],NEBO_DTYPE_U64
 mov qword [rsp+P_DEFAULTS],0
 mov qword [rsp+P_DEFAULTS+8],0
 lea rdi,[rsp+P_SCHEMA]
 lea rsi,[rsp+P_NAMES]
 lea rdx,[rsp+P_DTYPES]
 mov ecx,2
 lea r8,[rsp+P_DEFAULTS]
 mov r9d,2
 call neboc_schema_init
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_SCHEMA]
 mov esi,0xB202
 lea rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_OUT_B]
 call neboc_schema_field
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],NEBO_DTYPE_U64
 jne .failure
 cmp qword [rsp+P_OUT_B],1
 jne .failure
 lea rdi,[rsp+P_SCHEMA]
 mov esi,0xA101
 lea rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_OUT_B]
 call neboc_schema_index_of
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],0
 jne .failure
 cmp qword [rsp+P_OUT_B],1
 jne .failure
 mov eax,r13d
 mov [rsp+P_VALUES_A],rax
 inc rax
 mov [rsp+P_VALUES_A+8],rax
 lea rdi,[rsp+P_ROW]
 lea rsi,[rsp+P_SCHEMA]
 lea rdx,[rsp+P_VALUES_A]
 mov ecx,2
 lea r8,[rsp+P_VALUES_B]
 lea r9,[rsp+P_OUT_C]
 call neboc_row_from
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_C],2
 jne .failure
 lea rdi,[rsp+P_ROW]
 mov esi,0xA101
 lea rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_OUT_B]
 call neboc_row_get
 test eax,eax
 jnz .failure
 mov eax,r13d
 cmp [rsp+P_OUT_A],rax
 jne .failure
 cmp qword [rsp+P_OUT_B],1
 jne .failure
 mov qword [rsp+P_INDICES],1
 mov qword [rsp+P_INDICES+8],0
 lea rdi,[rsp+P_ROW]
 lea rsi,[rsp+P_INDICES]
 mov edx,2
 lea rcx,[rsp+P_OUT_VALUES]
 lea r8,[rsp+P_OUT_D]
 call neboc_row_project
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_D],1
 jne .failure
 mov eax,r13d
 cmp [rsp+P_OUT_VALUES+8],rax
 jne .failure
 lea rdi,[rsp+P_ROW]
 lea rsi,[rsp+P_OUT_VALUES_2]
 mov edx,8
 lea rcx,[rsp+P_OUT_E]
 lea r8,[rsp+P_OUT_D]
 call neboc_row_to_tuple
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_E],2
 jne .failure
 cmp qword [rsp+P_OUT_D],2
 jne .failure
 mov eax,r13d
 cmp [rsp+P_OUT_VALUES_2],rax
 jne .failure
 jmp .success

.column:
 mov eax,r13d
 mov [rsp+P_VALUES_A],rax
 inc rax
 mov [rsp+P_VALUES_A+8],rax
 inc rax
 mov [rsp+P_VALUES_A+16],rax
 inc rax
 mov [rsp+P_VALUES_A+24],rax
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_VALUES_A]
 mov edx,4
 mov ecx,4
 mov r8d,NEBO_DTYPE_I64
 mov r9d,4
 call neboc_column_from
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_COL_A]
 xor esi,esi
 lea rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_OUT_B]
 call neboc_column_get
 test eax,eax
 jnz .failure
 mov eax,r13d
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_OUT_A]
 call neboc_column_sum_i64
 test eax,eax
 jnz .failure
 mov eax,r13d
 imul rax,3
 add rax,4
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_OUT_A]
 lea rdx,[rsp+P_OUT_B]
 call neboc_column_min_i64
 test eax,eax
 jnz .failure
 mov eax,r13d
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_OUT_A]
 lea rdx,[rsp+P_OUT_B]
 call neboc_column_max_i64
 test eax,eax
 jnz .failure
 mov eax,r13d
 add rax,3
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_OUT_A]
 call neboc_colecoes_primitivas_column_count_missing
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],1
 jne .failure
 lea rdi,[rsp+P_COL_A]
 mov esi,NEBO_DTYPE_U64
 lea rdx,[rsp+P_COL_B]
 lea rcx,[rsp+P_VALUES_B]
 mov r8d,4
 call neboc_column_cast
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_COL_B+NEBO_COLUMN_DTYPE],NEBO_DTYPE_U64
 jne .failure
 cmp qword [rsp+P_COL_B+NEBO_COLUMN_MISSING_BITMAP],4
 jne .failure
 jmp .success

.table:
 call g10_schema_one
 test eax,eax
 jnz .failure
 mov qword [rsp+P_VALUES_A],3
 mov qword [rsp+P_VALUES_A+8],1
 mov qword [rsp+P_VALUES_A+16],2
 mov qword [rsp+P_VALUES_A+24],2
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_VALUES_A]
 mov edx,4
 mov ecx,4
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_from
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_COL_A]
 mov [rsp+P_POINTERS],rax
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_SCHEMA]
 lea rdx,[rsp+P_POINTERS]
 mov ecx,1
 mov r8d,4
 call neboc_table_from_columns
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_OUT_A]
 call neboc_table_row_count
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],4
 jne .failure
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_OUT_A]
 call neboc_table_column_count
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],1
 jne .failure
 mov qword [rsp+P_INDICES],0
 lea rax,[rsp+P_SELECT_NAMES]
 mov [rsp+P_SELECT_WORK+NEBO_TABLE_SELECT_NAMES],rax
 lea rax,[rsp+P_SELECT_DTYPES]
 mov [rsp+P_SELECT_WORK+NEBO_TABLE_SELECT_DTYPES],rax
 lea rax,[rsp+P_SELECT_DEFAULTS]
 mov [rsp+P_SELECT_WORK+NEBO_TABLE_SELECT_DEFAULTS],rax
 lea rax,[rsp+P_SELECT_COLUMNS]
 mov [rsp+P_SELECT_WORK+NEBO_TABLE_SELECT_COLUMNS],rax
 lea rax,[rsp+P_SELECT_SCHEMA]
 mov [rsp+P_SELECT_WORK+NEBO_TABLE_SELECT_SCHEMA],rax
 lea rax,[rsp+P_SELECT_TABLE]
 mov [rsp+P_SELECT_WORK+NEBO_TABLE_SELECT_TABLE],rax
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_INDICES]
 mov edx,1
 lea rcx,[rsp+P_SELECT_WORK]
 call neboc_table_select
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TABLE_A]
 xor esi,esi
 mov edx,2
 lea rcx,[rsp+P_INDICES]
 mov r8d,32
 lea r9,[rsp+P_OUT_A]
 call neboc_table_filter_eq_i64
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],2
 jne .failure
 lea rdi,[rsp+P_TABLE_A]
 xor esi,esi
 lea rdx,[rsp+P_INDICES]
 mov ecx,32
 lea r8,[rsp+P_OUT_A]
 call neboc_table_sort_by_i64
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_INDICES],1
 jne .failure
 cmp qword [rsp+P_INDICES+24],0
 jne .failure
 lea rdi,[rsp+P_TABLE_A]
 xor esi,esi
 lea rdx,[rsp+P_OUT_VALUES]
 lea rcx,[rsp+P_COUNTS]
 mov r8d,32
 lea r9,[rsp+P_OUT_A]
 call neboc_table_group_by_i64
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],3
 jne .failure
 cmp qword [rsp+P_COUNTS+16],2
 jne .failure
 ; A distinct right table proves left-join unmatched-row publication.
 mov qword [rsp+P_VALUES_B],1
 mov qword [rsp+P_VALUES_B+8],2
 mov qword [rsp+P_VALUES_B+16],4
 mov qword [rsp+P_VALUES_B+24],4
 lea rdi,[rsp+P_COL_B]
 lea rsi,[rsp+P_VALUES_B]
 mov edx,4
 mov ecx,4
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_from
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_COL_B]
 mov [rsp+P_POINTERS+8],rax
 lea rdi,[rsp+P_TABLE_B]
 lea rsi,[rsp+P_SCHEMA]
 lea rdx,[rsp+P_POINTERS+8]
 mov ecx,1
 mov r8d,4
 call neboc_table_from_columns
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_JOIN_LEFT]
 mov [rsp+P_JOIN_WORK+NEBO_TABLE_JOIN_LEFT_ROWS],rax
 lea rax,[rsp+P_JOIN_RIGHT]
 mov [rsp+P_JOIN_WORK+NEBO_TABLE_JOIN_RIGHT_ROWS],rax
 mov qword [rsp+P_JOIN_WORK+NEBO_TABLE_JOIN_CAPACITY],32
 lea rax,[rsp+P_OUT_A]
 mov [rsp+P_JOIN_WORK+NEBO_TABLE_JOIN_LENGTH],rax
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_TABLE_B]
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBO_DATA_JOIN_LEFT
 lea r9,[rsp+P_JOIN_WORK]
 call neboc_table_join_i64
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],4
 jne .failure
 cmp qword [rsp+P_JOIN_LEFT],0
 jne .failure
 cmp qword [rsp+P_JOIN_RIGHT],-1
 jne .failure
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_TABLE_A]
 xor edx,edx
 xor ecx,ecx
 mov r8d,NEBO_DATA_JOIN_INNER
 lea r9,[rsp+P_JOIN_WORK]
 call neboc_table_join_i64
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],6
 jne .failure
 jmp .success

.missing:
 call g10_schema_one
 test eax,eax
 jnz .failure
 mov eax,r13d
 mov [rsp+P_VALUES_A],rax
 inc rax
 mov [rsp+P_VALUES_A+8],rax
 inc rax
 mov [rsp+P_VALUES_A+16],rax
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_VALUES_A]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 mov r9d,2
 call neboc_column_from
 test eax,eax
 jnz .failure
 mov eax,r13d
 add rax,10
 mov [rsp+P_VALUES_B],rax
 inc rax
 mov [rsp+P_VALUES_B+8],rax
 inc rax
 mov [rsp+P_VALUES_B+16],rax
 lea rdi,[rsp+P_COL_B]
 lea rsi,[rsp+P_VALUES_B]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_from
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_COL_A]
 mov [rsp+P_POINTERS],rax
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_SCHEMA]
 lea rdx,[rsp+P_POINTERS]
 mov ecx,1
 mov r8d,3
 call neboc_table_from_columns
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_COL_A]
 mov esi,1
 lea rdx,[rsp+P_OUT_A]
 call neboc_column_is_missing
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],1
 jne .failure
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_COL_C]
 lea rdx,[rsp+P_VALUES_C]
 mov ecx,3
 call neboc_column_drop_missing
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_COL_C+NEBO_COLUMN_LENGTH],2
 jne .failure
 lea rdi,[rsp+P_COL_A]
 lea rsi,[rsp+P_COL_B]
 lea rdx,[rsp+P_OUT_VALUES]
 lea rcx,[rsp+P_OUT_A]
 call neboc_column_coalesce
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],0
 jne .failure
 mov eax,r13d
 add rax,11
 cmp [rsp+P_OUT_VALUES+8],rax
 jne .failure
 lea rdi,[rsp+P_TABLE_A]
 call neboc_table_validate
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_OUT_A]
 call neboc_table_invalid_rows
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],2
 jne .failure
 lea rdi,[rsp+P_COL_A]
 mov esi,r13d
 inc rsi
 lea rdx,[rsp+P_OUT_B]
 call neboc_column_fill_missing
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_B],1
 jne .failure
 lea rdi,[rsp+P_TABLE_A]
 lea rsi,[rsp+P_OUT_A]
 call neboc_table_invalid_rows
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],0
 jne .failure
 jmp .success

.dataset:
 call g10_schema_one
 test eax,eax
 jnz .failure
 call g10_column_a_three
 test eax,eax
 jnz .failure
 call g10_table_a_one_column
 test eax,eax
 jnz .failure
 mov eax,r13d
 add rax,10
 mov [rsp+P_VALUES_B],rax
 inc rax
 mov [rsp+P_VALUES_B+8],rax
 inc rax
 mov [rsp+P_VALUES_B+16],rax
 lea rdi,[rsp+P_COL_B]
 lea rsi,[rsp+P_VALUES_B]
 mov edx,3
 mov ecx,3
 mov r8d,NEBO_DTYPE_I64
 xor r9d,r9d
 call neboc_column_from
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_COL_B]
 mov [rsp+P_SELECT_COLUMNS+8],rax
 lea rdi,[rsp+P_TABLE_B]
 lea rsi,[rsp+P_SCHEMA]
 lea rdx,[rsp+P_SELECT_COLUMNS+8]
 mov ecx,1
 mov r8d,3
 call neboc_table_from_columns
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_TABLE_A]
 mov [rsp+P_POINTERS],rax
 lea rax,[rsp+P_TABLE_B]
 mov [rsp+P_POINTERS+8],rax
 lea rdi,[rsp+P_DATASET]
 lea rsi,[rsp+P_SCHEMA]
 lea rdx,[rsp+P_POINTERS]
 mov ecx,2
 mov r8d,6
 mov r9d,48
 call neboc_dataset_from_tables
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DATASET]
 lea rsi,[rsp+P_OUT_A]
 call neboc_dataset_schema
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_SCHEMA]
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_DATASET]
 lea rsi,[rsp+P_OUT_A]
 call neboc_dataset_partition_count
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],2
 jne .failure
 lea rdi,[rsp+P_DATASET]
 lea rsi,[rsp+P_OUT_VALUES]
 mov edx,8
 lea rcx,[rsp+P_OUT_A]
 call neboc_dataset_scan
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_TABLE_A]
 cmp [rsp+P_OUT_VALUES],rax
 jne .failure
 lea rdi,[rsp+P_DATASET]
 lea rsi,[rsp+P_INDICES]
 lea rdx,[rsp+P_COUNTS]
 mov ecx,256
 lea r8,[rsp+P_OUT_B]
 call neboc_dataset_collect_refs
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_B],6
 jne .failure
 lea rdi,[rsp+P_DATASET]
 mov esi,1
 call neboc_dataset_repartition
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DATASET]
 lea rsi,[rsp+P_OUT_VALUES]
 mov edx,8
 lea rcx,[rsp+P_OUT_A]
 call neboc_dataset_scan
 test eax,eax
 jnz .failure
 lea rax,[rsp+P_TABLE_B]
 cmp [rsp+P_OUT_VALUES],rax
 jne .failure
 lea rdi,[rsp+P_DATASET]
 mov esi,1
 call neboc_dataset_cache
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_DATASET+NEBO_DATASET_FLAGS],1
 jne .failure
 jmp .success

.stream:
 mov eax,r13d
 mov [rsp+P_EVENTS+nebo_data_contract_EVENT_VALUE],rax
 mov qword [rsp+P_EVENTS+NEBO_EVENT_SEQUENCE],0
 inc rax
 mov [rsp+P_EVENTS+nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],rax
 mov qword [rsp+P_EVENTS+nebo_data_contract_EVENT_SIZE+NEBO_EVENT_SEQUENCE],5
 inc rax
 mov [rsp+P_EVENTS+2*nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],rax
 mov qword [rsp+P_EVENTS+2*nebo_data_contract_EVENT_SIZE+NEBO_EVENT_SEQUENCE],10
 lea rdi,[rsp+P_EVENTS]
 lea rsi,[rsp+P_OUT_A]
 call neboc_event_value
 test eax,eax
 jnz .failure
 mov eax,r13d
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_FLOW]
 lea rsi,[rsp+P_EVENTS]
 mov edx,3
 call neboc_flow_init
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_FLOW]
 lea rsi,[rsp+P_OUT_A]
 call neboc_flow_value
 test eax,eax
 jnz .failure
 mov eax,r13d
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_STREAM]
 lea rsi,[rsp+P_EVENTS]
 mov edx,3
 mov ecx,3
 call neboc_stream_from
 test eax,eax
 jnz .failure
 mov qword [rsp+P_CONTEXT],1
 lea rdi,[rsp+P_STREAM]
 lea rsi,[rel g10_map_add]
 lea rdx,[rsp+P_CONTEXT]
 call neboc_stream_map
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_STREAM]
 lea rsi,[rel g10_filter_all]
 lea rdx,[rsp+P_CONTEXT]
 call neboc_stream_filter
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_STREAM]
 mov esi,2
 lea rdx,[rsp+P_OUT_A]
 call neboc_stream_batch
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],2
 jne .failure
 lea rdi,[rsp+P_STREAM]
 mov esi,6
 lea rdx,[rsp+P_OUT_A]
 call neboc_stream_window
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],2
 jne .failure
 mov qword [rsp+P_OUT_B],0
 lea rdi,[rsp+P_STREAM]
 lea rsi,[rel g10_sink_sum]
 lea rdx,[rsp+P_OUT_B]
 lea rcx,[rsp+P_OUT_C]
 call neboc_stream_sink
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_C],3
 jne .failure
 mov eax,r13d
 imul rax,3
 add rax,6
 cmp [rsp+P_OUT_B],rax
 jne .failure
 jmp .success

.success:
 mov eax,r13d
 jmp .done
.failure:
 mov eax,111
.done:
 add rsp,8200
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
