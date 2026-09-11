; Source-to-effect adapter for the bounded public database surface. Each mode
; drives the reusable storage/query owner and validates independently
; observable state before returning the source seed.
bits 64
default rel
%include "runtime/database/db_format.inc"
%include "runtime/database/db_page.inc"
%include "runtime/query/query.inc"
%include "runtime/query/index.inc"
%include "runtime/database/db_tx.inc"
%include "runtime/database/db_migrate.inc"
%include "runtime/database/db_maintenance.inc"

extern nebo_db_header_init
extern nebo_db_header_validate
extern nebo_db_page_seal
extern nebo_db_page_validate
extern nebo_db_journal_prepare
extern nebo_db_journal_recover
extern nebo_query_plan_validate
extern nebo_query_filter_sum
extern nebo_index_lookup
extern nebo_planner_choose
extern nebo_db_tx_begin
extern nebo_db_tx_set
extern nebo_db_tx_savepoint
extern nebo_db_tx_rollback_savepoint
extern nebo_db_tx_commit
extern nebo_db_tx_abort
extern nebo_db_migrate_v1_v2
extern nebo_db_transfer_chunk
extern nebo_db_backup_copy
extern nebo_db_backup_verify
extern nebo_db_compact_nonzero

section .bss align=16
db_probe_header: resb NEBO_DB_HEADER_SIZE
db_probe_page: resb NEBO_DB_PAGE_SIZE
db_probe_journal: resb NEBO_DB_JOURNAL_SIZE
db_probe_recovered: resq 1
db_probe_values: resq 5
db_probe_count: resq 1
db_probe_sum: resq 1
db_probe_pairs: resq 8
db_probe_value: resq 1
db_probe_reason: resq 1
db_probe_current: resq 3
db_probe_shadow: resq 3
db_probe_save: resq 3
db_probe_tx: resb NEBO_DB_TX_SIZE
db_probe_old_schema: resq 3
db_probe_new_schema: resq 4
db_probe_transfer_source: resb 5
db_probe_transfer_dest: resb 3
db_probe_transfer_count: resq 1
db_probe_backup_source: resb 8
db_probe_backup_dest: resb 8
db_probe_backup_hash: resq 1
db_probe_sparse_rows: resq 6
db_probe_dense_rows: resq 3
db_probe_dense_count: resq 1

section .text
db_probe_schema:
 mov rax,r13
 and eax,15
 inc eax
 mov rdi,db_probe_header
 mov esi,eax
 mov rdx,r13
 mov rcx,0x3141592653589793
 xor rcx,r13
 call nebo_db_header_init
 test eax,eax
 jnz .bad
 mov rdi,db_probe_header
 call nebo_db_header_validate
 test eax,eax
 jnz .bad
 cmp [rel db_probe_header+NEBO_DB_HEADER_SCHEMA_VERSION],r13
 jne .bad
 cmp qword [rel db_probe_header+NEBO_DB_HEADER_PAGE_SIZE],NEBO_DB_PAGE_SIZE
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

db_probe_storage:
 mov byte [rel db_probe_page+NEBO_DB_PAGE_DATA],r13b
 mov rdi,db_probe_page
 lea rsi,[r13+1]
 call nebo_db_page_seal
 test eax,eax
 jnz .bad
 mov rdi,db_probe_page
 call nebo_db_page_validate
 test eax,eax
 jnz .bad
 mov rdi,db_probe_journal
 mov esi,3
 mov rdx,r13
 lea rcx,[r13+1]
 call nebo_db_journal_prepare
 test eax,eax
 jnz .bad
 mov qword [rel db_probe_recovered],0
 mov rdi,db_probe_journal
 mov rsi,-1
 mov rdx,db_probe_recovered
 call nebo_db_journal_recover
 cmp eax,NEBO_DB_PAGE_STATUS_RECOVERED
 jne .bad
 cmp [rel db_probe_recovered],r13
 jne .bad
 mov rdi,db_probe_journal
 mov esi,3
 mov rdx,r13
 lea rcx,[r13+1]
 call nebo_db_journal_prepare
 test eax,eax
 jnz .bad
 mov rdi,db_probe_journal
 lea rsi,[r13+1]
 mov rdx,db_probe_recovered
 call nebo_db_journal_recover
 test eax,eax
 jnz .bad
 lea rax,[r13+1]
 cmp [rel db_probe_recovered],rax
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

db_probe_query:
 lea rax,[r13-1]
 mov [rel db_probe_values],rax
 mov [rel db_probe_values+8],r13
 lea rax,[r13+2]
 mov [rel db_probe_values+16],rax
 mov qword [rel db_probe_values+24],3
 lea rax,[r13+5]
 mov [rel db_probe_values+32],rax
 mov edi,8
 mov esi,2
 mov edx,4
 mov ecx,3
 call nebo_query_plan_validate
 test eax,eax
 jnz .bad
 mov rdi,db_probe_values
 mov esi,5
 mov rdx,r13
 mov ecx,3
 mov r8,db_probe_count
 mov r9,db_probe_sum
 call nebo_query_filter_sum
 test eax,eax
 jnz .bad
 cmp qword [rel db_probe_count],3
 jne .bad
 mov rax,r13
 imul rax,3
 add rax,7
 cmp [rel db_probe_sum],rax
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

db_probe_index:
 mov qword [rel db_probe_pairs],1
 lea rax,[r13+1]
 mov [rel db_probe_pairs+8],rax
 mov qword [rel db_probe_pairs+16],3
 lea rax,[r13+3]
 mov [rel db_probe_pairs+24],rax
 mov qword [rel db_probe_pairs+32],7
 lea rax,[r13+7]
 mov [rel db_probe_pairs+40],rax
 mov qword [rel db_probe_pairs+48],9
 lea rax,[r13+9]
 mov [rel db_probe_pairs+56],rax
 mov rdi,db_probe_pairs
 mov esi,4
 mov edx,7
 mov rcx,db_probe_value
 call nebo_index_lookup
 test eax,eax
 jnz .bad
 lea rax,[r13+7]
 cmp [rel db_probe_value],rax
 jne .bad
 mov edi,100
 mov esi,1
 mov edx,1
 mov rcx,db_probe_reason
 call nebo_planner_choose
 cmp eax,NEBO_PLAN_INDEX
 jne .bad
 cmp qword [rel db_probe_reason],NEBO_PLAN_REASON_EQUALITY_INDEX
 jne .bad
 mov edi,4
 mov esi,1
 mov edx,1
 mov rcx,db_probe_reason
 call nebo_planner_choose
 cmp eax,NEBO_PLAN_SCAN
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

db_probe_transaction:
 mov [rel db_probe_current],r13
 lea rax,[r13+1]
 mov [rel db_probe_current+8],rax
 lea rax,[r13+2]
 mov [rel db_probe_current+16],rax
 mov rdi,db_probe_tx
 mov rsi,db_probe_current
 mov rdx,db_probe_shadow
 mov rcx,db_probe_save
 mov r8d,3
 call nebo_db_tx_begin
 test eax,eax
 jnz .bad
 mov rdi,db_probe_tx
 mov esi,1
 lea rdx,[r13+9]
 call nebo_db_tx_set
 test eax,eax
 jnz .bad
 mov rdi,db_probe_tx
 call nebo_db_tx_savepoint
 test eax,eax
 jnz .bad
 mov rdi,db_probe_tx
 mov esi,2
 lea rdx,[r13+15]
 call nebo_db_tx_set
 test eax,eax
 jnz .bad
 mov rdi,db_probe_tx
 call nebo_db_tx_rollback_savepoint
 test eax,eax
 jnz .bad
 mov rdi,db_probe_tx
 call nebo_db_tx_commit
 test eax,eax
 jnz .bad
 lea rax,[r13+9]
 cmp [rel db_probe_current+8],rax
 jne .bad
 lea rax,[r13+2]
 cmp [rel db_probe_current+16],rax
 jne .bad
 mov rdi,db_probe_tx
 mov rsi,db_probe_current
 mov rdx,db_probe_shadow
 mov rcx,db_probe_save
 mov r8d,3
 call nebo_db_tx_begin
 test eax,eax
 jnz .bad
 mov rdi,db_probe_tx
 xor esi,esi
 lea rdx,[r13+20]
 call nebo_db_tx_set
 test eax,eax
 jnz .bad
 mov rdi,db_probe_tx
 call nebo_db_tx_abort
 test eax,eax
 jnz .bad
 cmp [rel db_probe_current],r13
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

db_probe_migration:
 mov [rel db_probe_old_schema],r13
 lea rax,[r13+1]
 mov [rel db_probe_old_schema+8],rax
 lea rax,[r13+2]
 mov [rel db_probe_old_schema+16],rax
 mov rdi,db_probe_old_schema
 mov rsi,db_probe_new_schema
 mov edx,3
 mov ecx,4
 lea r8,[r13+9]
 call nebo_db_migrate_v1_v2
 cmp rax,4
 jne .bad
 lea rax,[r13+9]
 cmp [rel db_probe_new_schema+24],rax
 jne .bad
 mov byte [rel db_probe_transfer_source],1
 mov [rel db_probe_transfer_source+1],r13b
 mov byte [rel db_probe_transfer_source+2],3
 mov byte [rel db_probe_transfer_source+3],4
 mov byte [rel db_probe_transfer_source+4],5
 mov rdi,db_probe_transfer_source
 mov rsi,db_probe_transfer_dest
 mov edx,1
 mov ecx,5
 mov r8d,3
 mov r9,db_probe_transfer_count
 call nebo_db_transfer_chunk
 test eax,eax
 jnz .bad
 cmp qword [rel db_probe_transfer_count],3
 jne .bad
 cmp [rel db_probe_transfer_dest],r13b
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

db_probe_maintenance:
 mov [rel db_probe_backup_source],r13b
 mov byte [rel db_probe_backup_source+1],2
 mov byte [rel db_probe_backup_source+2],3
 mov byte [rel db_probe_backup_source+3],4
 mov byte [rel db_probe_backup_source+4],5
 mov byte [rel db_probe_backup_source+5],6
 mov byte [rel db_probe_backup_source+6],7
 mov byte [rel db_probe_backup_source+7],8
 mov rdi,db_probe_backup_source
 mov rsi,db_probe_backup_dest
 mov edx,8
 mov rcx,db_probe_backup_hash
 call nebo_db_backup_copy
 test eax,eax
 jnz .bad
 cmp qword [rel db_probe_backup_hash],0
 je .bad
 mov rdi,db_probe_backup_source
 mov rsi,db_probe_backup_dest
 mov edx,8
 call nebo_db_backup_verify
 test eax,eax
 jnz .bad
 xor byte [rel db_probe_backup_dest+3],1
 mov rdi,db_probe_backup_source
 mov rsi,db_probe_backup_dest
 mov edx,8
 call nebo_db_backup_verify
 cmp eax,NEBO_DB_MAINT_MISMATCH
 jne .bad
 mov rdi,db_probe_backup_source
 mov rsi,db_probe_backup_dest
 mov edx,8
 mov rcx,db_probe_backup_hash
 call nebo_db_backup_copy
 test eax,eax
 jnz .bad
 mov qword [rel db_probe_sparse_rows],0
 mov [rel db_probe_sparse_rows+8],r13
 mov qword [rel db_probe_sparse_rows+16],0
 lea rax,[r13+1]
 mov [rel db_probe_sparse_rows+24],rax
 lea rax,[r13+2]
 mov [rel db_probe_sparse_rows+32],rax
 mov qword [rel db_probe_sparse_rows+40],0
 mov rdi,db_probe_sparse_rows
 mov esi,6
 mov rdx,db_probe_dense_rows
 mov ecx,3
 mov r8,db_probe_dense_count
 call nebo_db_compact_nonzero
 test eax,eax
 jnz .bad
 cmp qword [rel db_probe_dense_count],3
 jne .bad
 lea rax,[r13+2]
 cmp [rel db_probe_dense_rows+16],rax
 jne .bad
 xor eax,eax
 ret
.bad: mov eax,1
 ret

global nebo_database_source_probe
nebo_database_source_probe:
 push rbp
 mov rbp,rsp
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 cmp r12d,1
 je .s01
 cmp r12d,2
 je .s02
 cmp r12d,3
 je .s03
 cmp r12d,4
 je .s04
 cmp r12d,5
 je .s05
 cmp r12d,6
 je .s06
 cmp r12d,7
 je .s07
 jmp .failed
.s01: call db_probe_schema
 jmp .check
.s02: call db_probe_storage
 jmp .check
.s03: call db_probe_query
 jmp .check
.s04: call db_probe_index
 jmp .check
.s05: call db_probe_transaction
 jmp .check
.s06: call db_probe_migration
 jmp .check
.s07: call db_probe_maintenance
.check:
 test eax,eax
 jnz .failed
 mov eax,r13d
 jmp .done
.failed:
 mov eax,112
.done:
 pop r13
 pop r12
 leave
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
