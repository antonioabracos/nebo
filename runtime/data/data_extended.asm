; G010 current-contract bounded data owners missing from the historical core.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"

extern neboc_schema_validate
extern neboc_schema_validate_missing_rules
extern neboc_row_apply_defaults
extern neboc_column_init
extern neboc_column_validate
extern neboc_table_init
extern neboc_table_validate
extern neboc_table_inner_join_i64
extern neboc_dataset_init
extern neboc_dataset_validate
extern neboc_stream_init
extern neboc_stream_configure
extern neboc_stream_consume

section .text

; schema_index_of(schema*, name_hash, out_index*, out_found*)
NEBOC_ABI_FUNCTION neboc_schema_index_of
 test rdx,rdx
 jz .sio_bad
 test rcx,rcx
 jz .sio_bad
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],0
 mov qword [r15],0
 call neboc_schema_validate
 test eax,eax
 jnz .sio_done
 mov rdx,[r12+NEBO_SCHEMA_NAMES]
 xor ecx,ecx
.sio_loop:
 cmp rcx,[r12+NEBO_SCHEMA_FIELD_COUNT]
 jae .sio_ok
 cmp [rdx+rcx*8],r13
 je .sio_found
 inc rcx
 jmp .sio_loop
.sio_found:
 mov [r14],rcx
 mov qword [r15],1
.sio_ok:
 xor eax,eax
.sio_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sio_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; schema_field(schema*, name_hash, out_dtype*, out_nullable*)
NEBOC_ABI_FUNCTION neboc_schema_field
 test rdx,rdx
 jz .sf_bad
 test rcx,rcx
 jz .sf_bad
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],0
 mov qword [r15],0
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 lea rcx,[rsp+8]
 call neboc_schema_index_of
 test eax,eax
 jnz .sf_done
 cmp qword [rsp+8],1
 jne .sf_source
 mov rcx,[rsp]
 mov rax,[r12+NEBO_SCHEMA_DTYPES]
 mov rax,[rax+rcx*8]
 mov [r14],rax
 bt qword [r12+NEBO_SCHEMA_NULLABLE],rcx
 jnc .sf_ok
 mov qword [r15],1
.sf_ok:
 xor eax,eax
 jmp .sf_done
.sf_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.sf_done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sf_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; row_from(row*, schema*, values*, missing_bitmap, owned_values*, out_missing*)
NEBOC_ABI_FUNCTION neboc_row_from
 test rdi,rdi
 jz .rf_bad
 test rsi,rsi
 jz .rf_bad
 test rdx,rdx
 jz .rf_bad
 test r8,r8
 jz .rf_bad
 test r9,r9
 jz .rf_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov rbx,r9
 mov qword [rbx],0
 mov rdi,r13
 call neboc_schema_validate_missing_rules
 test eax,eax
 jnz .rf_done
 mov rdi,r13
 mov rsi,r14
 mov rdx,r15
 mov rcx,rbp
 mov r8,rbx
 call neboc_row_apply_defaults
 test eax,eax
 jnz .rf_done
 mov rdi,r12
 mov ecx,NEBO_ROW_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_ROW_SCHEMA],r13
 mov [r12+NEBO_ROW_VALUES],rbp
 mov rax,[rbx]
 mov [r12+NEBO_ROW_MISSING_BITMAP],rax
 mov rax,[r13+NEBO_SCHEMA_FIELD_COUNT]
 mov [r12+NEBO_ROW_FIELD_COUNT],rax
 mov qword [r12+NEBO_ROW_GENERATION],1
 xor eax,eax
.rf_done:
 add rsp,8
 pop rbx
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.rf_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; row_get(row*, name_hash, out_value*, out_present*)
NEBOC_ABI_FUNCTION neboc_row_get
 test rdx,rdx
 jz .rg_bad
 test rcx,rcx
 jz .rg_bad
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],0
 mov qword [r15],0
 test r12,r12
 jz .rg_bad_saved
 mov rdi,[r12+NEBO_ROW_SCHEMA]
 mov rsi,r13
 lea rdx,[rsp]
 lea rcx,[rsp+8]
 call neboc_schema_index_of
 test eax,eax
 jnz .rg_done
 cmp qword [rsp+8],1
 jne .rg_source
 mov rcx,[rsp]
 cmp rcx,[r12+NEBO_ROW_FIELD_COUNT]
 jae .rg_source
 bt qword [r12+NEBO_ROW_MISSING_BITMAP],rcx
 jc .rg_ok
 mov rax,[r12+NEBO_ROW_VALUES]
 mov rax,[rax+rcx*8]
 mov [r14],rax
 mov qword [r15],1
.rg_ok:
 xor eax,eax
 jmp .rg_done
.rg_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .rg_done
.rg_bad_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.rg_done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.rg_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; row_project(row*, indices*, count, out_values*, out_missing*)
NEBOC_ABI_FUNCTION neboc_row_project
 test rdi,rdi
 jz .rp_bad
 test rsi,rsi
 jz .rp_bad
 test rcx,rcx
 jz .rp_bad
 test r8,r8
 jz .rp_bad
 test rdx,rdx
 jz .rp_limit
 cmp rdx,NEBO_DATA_MAX_FIELDS
 ja .rp_limit
 mov qword [r8],0
 xor r9d,r9d
 xor r10d,r10d
.rp_check:
 cmp r9,rdx
 jae .rp_copy
 mov rax,[rsi+r9*8]
 cmp rax,[rdi+NEBO_ROW_FIELD_COUNT]
 jae .rp_limit
 xor r11d,r11d
.rp_dup:
 cmp r11,r9
 jae .rp_next
 cmp rax,[rsi+r11*8]
 je .rp_bad
 inc r11
 jmp .rp_dup
.rp_next:
 inc r9
 jmp .rp_check
.rp_copy:
 xor r9d,r9d
.rp_loop:
 cmp r9,rdx
 jae .rp_ok
 mov rax,[rsi+r9*8]
 bt qword [rdi+NEBO_ROW_MISSING_BITMAP],rax
 jnc .rp_value
 bts r10,r9
 xor eax,eax
 jmp .rp_store
.rp_value:
 mov r11,[rdi+NEBO_ROW_VALUES]
 mov rax,[r11+rax*8]
.rp_store:
 mov [rcx+r9*8],rax
 inc r9
 jmp .rp_loop
.rp_ok:
 mov [r8],r10
 xor eax,eax
 ret
.rp_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.rp_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; row_to_tuple(row*, out_values*, capacity, out_count*, out_missing*)
NEBOC_ABI_FUNCTION neboc_row_to_tuple
 test rdi,rdi
 jz .rtt_bad
 test rsi,rsi
 jz .rtt_bad
 test rcx,rcx
 jz .rtt_bad
 test r8,r8
 jz .rtt_bad
 mov qword [rcx],0
 mov qword [r8],0
 mov rax,[rdi+NEBO_ROW_FIELD_COUNT]
 cmp rax,rdx
 ja .rtt_limit
 cmp rax,NEBO_DATA_MAX_FIELDS
 ja .rtt_source
 xor r9d,r9d
.rtt_loop:
 cmp r9,rax
 jae .rtt_ok
 mov r10,[rdi+NEBO_ROW_VALUES]
 mov r10,[r10+r9*8]
 mov [rsi+r9*8],r10
 inc r9
 jmp .rtt_loop
.rtt_ok:
 mov [rcx],rax
 mov r10,[rdi+NEBO_ROW_MISSING_BITMAP]
 mov [r8],r10
 xor eax,eax
 ret
.rtt_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.rtt_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.rtt_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; Public constructor aliases preserve the established bounded descriptors.
NEBOC_ABI_FUNCTION neboc_column_from
 jmp neboc_column_init

; column_cast(src*, dtype, dst*, out_values*, capacity)
NEBOC_ABI_FUNCTION neboc_column_cast
 test rdx,rdx
 jz .ccast_bad
 test rcx,rcx
 jz .ccast_bad
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
 call neboc_column_validate
 test eax,eax
 jnz .ccast_done
 cmp r13,NEBO_DTYPE_I64
 jb .ccast_bad_saved
 cmp r13,NEBO_DTYPE_FLOAT64
 ja .ccast_bad_saved
 mov rax,[r12+NEBO_COLUMN_LENGTH]
 cmp rax,rbp
 ja .ccast_limit
 ; Current checked numeric conversion supports identity and I64/U64.
 mov rdx,[r12+NEBO_COLUMN_DTYPE]
 cmp rdx,r13
 je .ccast_copy
 cmp rdx,NEBO_DTYPE_I64
 jne .ccast_u64
 cmp r13,NEBO_DTYPE_U64
 jne .ccast_source
 xor ecx,ecx
.ccast_i64_check:
 cmp rcx,rax
 jae .ccast_copy
 bt qword [r12+NEBO_COLUMN_MISSING_BITMAP],rcx
 jc .ccast_i64_next
 mov rdx,[r12+NEBO_COLUMN_VALUES]
 cmp qword [rdx+rcx*8],0
 jl .ccast_limit
.ccast_i64_next:
 inc rcx
 jmp .ccast_i64_check
.ccast_u64:
 cmp rdx,NEBO_DTYPE_U64
 jne .ccast_source
 cmp r13,NEBO_DTYPE_I64
 jne .ccast_source
 xor ecx,ecx
.ccast_u64_check:
 cmp rcx,rax
 jae .ccast_copy
 bt qword [r12+NEBO_COLUMN_MISSING_BITMAP],rcx
 jc .ccast_u64_next
 mov rdx,[r12+NEBO_COLUMN_VALUES]
 cmp qword [rdx+rcx*8],0
 jl .ccast_limit
.ccast_u64_next:
 inc rcx
 jmp .ccast_u64_check
.ccast_copy:
 xor ecx,ecx
.ccast_loop:
 cmp rcx,rax
 jae .ccast_init
 mov rdx,[r12+NEBO_COLUMN_VALUES]
 mov rdx,[rdx+rcx*8]
 mov [r15+rcx*8],rdx
 inc rcx
 jmp .ccast_loop
.ccast_init:
 mov rdi,r14
 mov rsi,r15
 mov rdx,rax
 mov rcx,rbp
 mov r8,r13
 mov r9,[r12+NEBO_COLUMN_MISSING_BITMAP]
 call neboc_column_init
 jmp .ccast_done
.ccast_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .ccast_done
.ccast_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .ccast_done
.ccast_bad_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.ccast_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.ccast_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; column_drop_missing(src*, dst*, out_values*, capacity)
NEBOC_ABI_FUNCTION neboc_column_drop_missing
 test rsi,rsi
 jz .cdm_bad
 test rdx,rdx
 jz .cdm_bad
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_column_validate
 test eax,eax
 jnz .cdm_done
 xor r8d,r8d
 xor r9d,r9d
.cdm_count:
 cmp r8,[r12+NEBO_COLUMN_LENGTH]
 jae .cdm_capacity
 bt qword [r12+NEBO_COLUMN_MISSING_BITMAP],r8
 jc .cdm_count_next
 inc r9
.cdm_count_next:
 inc r8
 jmp .cdm_count
.cdm_capacity:
 cmp r9,r15
 ja .cdm_limit
 xor r8d,r8d
 xor r10d,r10d
.cdm_copy:
 cmp r8,[r12+NEBO_COLUMN_LENGTH]
 jae .cdm_init
 bt qword [r12+NEBO_COLUMN_MISSING_BITMAP],r8
 jc .cdm_next
 mov rax,[r12+NEBO_COLUMN_VALUES]
 mov rax,[rax+r8*8]
 mov [r14+r10*8],rax
 inc r10
.cdm_next:
 inc r8
 jmp .cdm_copy
.cdm_init:
 mov rdi,r13
 mov rsi,r14
 mov rdx,r9
 mov rcx,r15
 mov r8,[r12+NEBO_COLUMN_DTYPE]
 xor r9d,r9d
 call neboc_column_init
 jmp .cdm_done
.cdm_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.cdm_done:
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.cdm_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_table_from_columns
 jmp neboc_table_init

NEBOC_ABI_FUNCTION neboc_table_row_count
 test rsi,rsi
 jz .trc_bad
 test rdi,rdi
 jz .trc_bad
 mov qword [rsi],0
 mov rax,[rdi+NEBO_TABLE_ROW_COUNT]
 cmp rax,NEBO_DATA_MAX_ROWS
 ja .trc_source
 mov [rsi],rax
 xor eax,eax
 ret
.trc_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.trc_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_table_column_count
 test rsi,rsi
 jz .tcc_bad
 test rdi,rdi
 jz .tcc_bad
 mov qword [rsi],0
 mov rax,[rdi+NEBO_TABLE_COLUMN_COUNT]
 test rax,rax
 jz .tcc_source
 cmp rax,NEBO_DATA_MAX_FIELDS
 ja .tcc_source
 mov [rsi],rax
 xor eax,eax
 ret
.tcc_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.tcc_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stable sortBy one I64 key, missing values last; returns row indices.
; table_sort_by_i64(table*, column, out_rows*, capacity, out_length*)
NEBOC_ABI_FUNCTION neboc_table_sort_by_i64
 test rdx,rdx
 jz .tsb_bad
 test r8,r8
 jz .tsb_bad
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
 call neboc_table_validate
 test eax,eax
 jnz .tsb_done
 cmp r13,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .tsb_limit
 mov rax,[r12+NEBO_TABLE_ROW_COUNT]
 cmp rax,r15
 ja .tsb_limit
 mov rdx,[r12+NEBO_TABLE_COLUMNS]
 mov rdx,[rdx+r13*8]
 cmp qword [rdx+NEBO_COLUMN_DTYPE],NEBO_DTYPE_I64
 jne .tsb_source
 xor ecx,ecx
.tsb_seed:
 cmp rcx,rax
 jae .tsb_sort
 mov [r14+rcx*8],rcx
 inc rcx
 jmp .tsb_seed
.tsb_sort:
 mov r8,1
.tsb_outer:
 cmp r8,rax
 jae .tsb_ok
 mov r9,[r14+r8*8]
 mov r10,r8
.tsb_inner:
 test r10,r10
 jz .tsb_place
 mov r11,[r14+r10*8-8]
 bt qword [rdx+NEBO_COLUMN_MISSING_BITMAP],r11
 jc .tsb_previous_missing
 bt qword [rdx+NEBO_COLUMN_MISSING_BITMAP],r9
 jc .tsb_place
 mov rcx,[rdx+NEBO_COLUMN_VALUES]
 mov rsi,[rcx+r11*8]
 cmp rsi,[rcx+r9*8]
 jle .tsb_place
 jmp .tsb_shift
.tsb_previous_missing:
 ; Both keys missing compare equal. Preserve their original row order;
 ; shift a missing predecessor only for a present current key.
 bt qword [rdx+NEBO_COLUMN_MISSING_BITMAP],r9
 jc .tsb_place
.tsb_shift:
 mov [r14+r10*8],r11
 dec r10
 jmp .tsb_inner
.tsb_place:
 mov [r14+r10*8],r9
 inc r8
 jmp .tsb_outer
.tsb_ok:
 mov [rbp],rax
 xor eax,eax
 jmp .tsb_done
.tsb_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .tsb_done
.tsb_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.tsb_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.tsb_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; table_join_i64(left*, right*, left_col, right_col, kind, join_work*)
NEBOC_ABI_FUNCTION neboc_table_join_i64
 cmp r8,NEBO_DATA_JOIN_INNER
 je .tjk_inner
 cmp r8,NEBO_DATA_JOIN_LEFT
 jne .tjk_bad
 test r9,r9
 jz .tjk_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 push rbx
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r9
 mov rdi,r12
 call neboc_table_validate
 test eax,eax
 jnz .tjk_done
 mov rdi,r13
 call neboc_table_validate
 test eax,eax
 jnz .tjk_done
 cmp r14,[r12+NEBO_TABLE_COLUMN_COUNT]
 jae .tjk_limit
 cmp r15,[r13+NEBO_TABLE_COLUMN_COUNT]
 jae .tjk_limit
 mov rax,[rbp+NEBO_TABLE_JOIN_LENGTH]
 test rax,rax
 jz .tjk_bad_saved
 mov qword [rax],0
 mov r10,[r12+NEBO_TABLE_COLUMNS]
 mov r10,[r10+r14*8]
 mov r11,[r13+NEBO_TABLE_COLUMNS]
 mov r11,[r11+r15*8]
 xor ecx,ecx
 xor ebx,ebx
.tjk_left:
 cmp rcx,[r12+NEBO_TABLE_ROW_COUNT]
 jae .tjk_ok
 xor edx,edx
 xor r8d,r8d
.tjk_right:
 cmp rdx,[r13+NEBO_TABLE_ROW_COUNT]
 jae .tjk_unmatched
 bt qword [r10+NEBO_COLUMN_MISSING_BITMAP],rcx
 jc .tjk_right_next
 bt qword [r11+NEBO_COLUMN_MISSING_BITMAP],rdx
 jc .tjk_right_next
 mov rax,[r10+NEBO_COLUMN_VALUES]
 mov rsi,[r11+NEBO_COLUMN_VALUES]
 mov rax,[rax+rcx*8]
 cmp rax,[rsi+rdx*8]
 jne .tjk_right_next
 cmp rbx,[rbp+NEBO_TABLE_JOIN_CAPACITY]
 jae .tjk_limit
 mov rax,[rbp+NEBO_TABLE_JOIN_LEFT_ROWS]
 mov [rax+rbx*8],rcx
 mov rax,[rbp+NEBO_TABLE_JOIN_RIGHT_ROWS]
 mov [rax+rbx*8],rdx
 inc rbx
 mov r8d,1
.tjk_right_next:
 inc rdx
 jmp .tjk_right
.tjk_unmatched:
 test r8,r8
 jnz .tjk_next_left
 cmp rbx,[rbp+NEBO_TABLE_JOIN_CAPACITY]
 jae .tjk_limit
 mov rax,[rbp+NEBO_TABLE_JOIN_LEFT_ROWS]
 mov [rax+rbx*8],rcx
 mov rax,[rbp+NEBO_TABLE_JOIN_RIGHT_ROWS]
 mov qword [rax+rbx*8],-1
 inc rbx
.tjk_next_left:
 inc rcx
 jmp .tjk_left
.tjk_ok:
 mov rax,[rbp+NEBO_TABLE_JOIN_LENGTH]
 mov [rax],rbx
 xor eax,eax
 jmp .tjk_done
.tjk_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .tjk_done
.tjk_bad_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.tjk_done:
 add rsp,8
 pop rbx
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.tjk_inner:
 mov r8,r9
 jmp neboc_table_inner_join_i64
.tjk_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_dataset_from_tables
 jmp neboc_dataset_init

NEBOC_ABI_FUNCTION neboc_dataset_schema
 test rsi,rsi
 jz .dsc_bad
 test rdi,rdi
 jz .dsc_bad
 mov qword [rsi],0
 mov rax,[rdi+NEBO_DATASET_SCHEMA]
 test rax,rax
 jz .dsc_source
 mov [rsi],rax
 xor eax,eax
 ret
.dsc_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.dsc_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_dataset_partition_count
 test rsi,rsi
 jz .dpc_bad
 test rdi,rdi
 jz .dpc_bad
 mov qword [rsi],0
 mov rax,[rdi+NEBO_DATASET_PARTITIONS]
 test rax,rax
 jz .dpc_source
 cmp rax,NEBO_DATA_MAX_PARTITIONS
 ja .dpc_source
 mov [rsi],rax
 xor eax,eax
 ret
.dpc_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.dpc_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; strategy 1 reverses bounded partition order deterministically.
NEBOC_ABI_FUNCTION neboc_dataset_repartition
 cmp rsi,1
 jne .dr_bad
 push r12
 push r13
 mov r12,rdi
 call neboc_dataset_validate
 test eax,eax
 jnz .dr_done
 cmp qword [r12+NEBO_DATASET_FLAGS],0
 jne .dr_source
 mov rax,[r12+NEBO_DATASET_TABLES]
 xor ecx,ecx
 mov rdx,[r12+NEBO_DATASET_PARTITIONS]
 dec rdx
.dr_loop:
 cmp rcx,rdx
 jae .dr_commit
 mov r8,[rax+rcx*8]
 mov r9,[rax+rdx*8]
 mov [rax+rcx*8],r9
 mov [rax+rdx*8],r8
 inc rcx
 dec rdx
 jmp .dr_loop
.dr_commit:
 inc qword [r12+NEBO_DATASET_GENERATION]
 xor eax,eax
 jmp .dr_done
.dr_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.dr_done:
 pop r13
 pop r12
 ret
.dr_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; dataset_scan copies a finite lazy partition plan without materializing rows.
; dataset_scan(ds*, out_table_ptrs*, capacity, out_length*)
NEBOC_ABI_FUNCTION neboc_dataset_scan
 test rsi,rsi
 jz .dscan_bad
 test rcx,rcx
 jz .dscan_bad
 mov qword [rcx],0
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_dataset_validate
 test eax,eax
 jnz .dscan_done
 mov rax,[r12+NEBO_DATASET_PARTITIONS]
 cmp rax,r14
 ja .dscan_limit
 xor ecx,ecx
 mov rdx,[r12+NEBO_DATASET_TABLES]
.dscan_loop:
 cmp rcx,rax
 jae .dscan_ok
 mov r8,[rdx+rcx*8]
 mov [r13+rcx*8],r8
 inc rcx
 jmp .dscan_loop
.dscan_ok:
 mov [r15],rax
 xor eax,eax
 jmp .dscan_done
.dscan_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.dscan_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.dscan_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; cache policy 0 disables, 1 enables a bounded local descriptor cache.
NEBOC_ABI_FUNCTION neboc_dataset_cache
 cmp rsi,1
 ja .dc_bad
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 call neboc_dataset_validate
 test eax,eax
 jnz .dc_done
 mov [r12+NEBO_DATASET_FLAGS],r13
 inc qword [r12+NEBO_DATASET_GENERATION]
 xor eax,eax
.dc_done:
 add rsp,8
 pop r13
 pop r12
 ret
.dc_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_event_value
 test rdi,rdi
 jz .ev_bad
 test rsi,rsi
 jz .ev_bad
 mov rax,[rdi+nebo_data_contract_EVENT_VALUE]
 mov [rsi],rax
 xor eax,eax
 ret
.ev_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; flow_value observes the first event without consuming the flow.
NEBOC_ABI_FUNCTION neboc_flow_value
 test rdi,rdi
 jz .fv_bad
 test rsi,rsi
 jz .fv_bad
 mov qword [rsi],0
 mov rax,[rdi+NEBO_FLOW_SOURCE]
 test rax,rax
 jz .fv_source
 cmp qword [rdi+NEBO_FLOW_LENGTH],0
 je .fv_source
 mov rax,[rax+nebo_data_contract_EVENT_VALUE]
 mov [rsi],rax
 xor eax,eax
 ret
.fv_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.fv_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_stream_from
 jmp neboc_stream_init

NEBOC_ABI_FUNCTION neboc_stream_map_filter
 jmp neboc_stream_configure

; Individual lazy configuration owners preserve the other callback.
; stream_map(stream*, map_cb, context*)
NEBOC_ABI_FUNCTION neboc_stream_map
 test rdi,rdi
 jz .smap_bad
 test rsi,rsi
 jz .smap_bad
 cmp qword [rdi+NEBO_STREAM_INDEX],0
 jne .smap_source
 mov [rdi+NEBO_STREAM_MAP_CALLBACK],rsi
 mov [rdi+NEBO_STREAM_CONTEXT],rdx
 inc qword [rdi+NEBO_STREAM_GENERATION]
 xor eax,eax
 ret
.smap_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.smap_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stream_filter(stream*, filter_cb, context*)
NEBOC_ABI_FUNCTION neboc_stream_filter
 test rdi,rdi
 jz .sfilter_bad
 test rsi,rsi
 jz .sfilter_bad
 cmp qword [rdi+NEBO_STREAM_INDEX],0
 jne .sfilter_source
 mov [rdi+NEBO_STREAM_FILTER_CALLBACK],rsi
 mov [rdi+NEBO_STREAM_CONTEXT],rdx
 inc qword [rdi+NEBO_STREAM_GENERATION]
 xor eax,eax
 ret
.sfilter_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.sfilter_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stream_batch(stream*, size, out_batch_count*)
NEBOC_ABI_FUNCTION neboc_stream_batch
 test rdx,rdx
 jz .sb_bad
 push r12
 mov r12,rdx
 mov qword [r12],0
 test rdi,rdi
 jz .sb_bad_saved
 test rsi,rsi
 jz .sb_limit
 cmp rsi,NEBO_DATA_MAX_EVENTS
 ja .sb_limit
 cmp qword [rdi+NEBO_STREAM_INDEX],0
 jne .sb_source
 mov rax,[rdi+NEBO_STREAM_LENGTH]
 xor edx,edx
 div rsi
 test rdx,rdx
 jz .sb_store
 inc rax
.sb_store:
 mov [r12],rax
 mov rcx,rsi
 shl rcx,8
 or [rdi+nebo_data_contract_STREAM_FLAGS],rcx
 inc qword [rdi+NEBO_STREAM_GENERATION]
 xor eax,eax
 jmp .sb_done
.sb_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .sb_done
.sb_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .sb_done
.sb_bad_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.sb_done:
 pop r12
 ret
.sb_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stream_window(stream*, duration, out_window_count*) groups sequence buckets.
NEBOC_ABI_FUNCTION neboc_stream_window
 test rdx,rdx
 jz .sw_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 test r12,r12
 jz .sw_bad_saved
 test r13,r13
 jz .sw_limit
 cmp qword [r12+NEBO_STREAM_INDEX],0
 jne .sw_source
 mov rax,[r12+NEBO_STREAM_LENGTH]
 test rax,rax
 jz .sw_ok
 mov rdx,[r12+NEBO_STREAM_SOURCE]
 test rdx,rdx
 jz .sw_source
 xor ecx,ecx
 xor r8d,r8d
 mov r9,-1
.sw_loop:
 cmp rcx,rax
 jae .sw_store
 mov r10,rcx
 imul r10,nebo_data_contract_EVENT_SIZE
 mov r10,[rdx+r10+NEBO_EVENT_SEQUENCE]
 mov rax,r10
 xor edx,edx
 div r13
 cmp rax,r9
 je .sw_next
 mov r9,rax
 inc r8
.sw_next:
 inc rcx
 mov rax,[r12+NEBO_STREAM_LENGTH]
 mov rdx,[r12+NEBO_STREAM_SOURCE]
 jmp .sw_loop
.sw_store:
 mov [r14],r8
.sw_ok:
 inc qword [r12+NEBO_STREAM_GENERATION]
 xor eax,eax
 jmp .sw_done
.sw_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .sw_done
.sw_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .sw_done
.sw_bad_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.sw_done:
 pop r14
 pop r13
 pop r12
 ret
.sw_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_stream_sink
 jmp neboc_stream_consume

section .note.GNU-stack noalloc noexec nowrite progbits
