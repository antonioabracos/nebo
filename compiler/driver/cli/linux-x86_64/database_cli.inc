; Bounded offline database verification and migration planning for `neboc db`.
%ifndef NEBO_DATABASE_CLI_INC
%define NEBO_DATABASE_CLI_INC 1
%include "runtime/database/db_format.inc"
%include "runtime/database/db_page.inc"
extern nebo_db_header_validate
extern nebo_db_page_validate

section .rodata
db_verify_heading: db 'db-verify v1',10
db_verify_heading_len equ $-db_verify_heading
db_verify_format: db 'format=NEBODB01',10
db_verify_format_len equ $-db_verify_format
db_verify_storage_version: db 'storage-version=1',10
db_verify_storage_version_len equ $-db_verify_storage_version
db_verify_page_size: db 'page-size=4096',10
db_verify_page_size_len equ $-db_verify_page_size
db_verify_pages: db 'pages='
db_verify_pages_len equ $-db_verify_pages
db_verify_schema: db 'schema-version='
db_verify_schema_len equ $-db_verify_schema
db_verify_integrity: db 'integrity=ok',10
db_verify_integrity_len equ $-db_verify_integrity
db_verify_indexes: db 'indexes=none',10
db_verify_indexes_len equ $-db_verify_indexes
db_verify_scope: db 'scope=offline-local',10
db_verify_scope_len equ $-db_verify_scope
db_verify_error: db 'NEBO-DB-VERIFY-001: invalid, incompatible, truncated, or checksummed database header',10
db_verify_error_len equ $-db_verify_error

db_migrate_heading: db 'db-migrate v1',10
db_migrate_heading_len equ $-db_migrate_heading
db_migrate_mode: db 'mode=dry-run',10
db_migrate_mode_len equ $-db_migrate_mode
db_migrate_current: db 'current-version='
db_migrate_current_len equ $-db_migrate_current
db_migrate_target: db 'target-version=2',10
db_migrate_target_len equ $-db_migrate_target
db_migrate_steps: db 'steps='
db_migrate_steps_len equ $-db_migrate_steps
db_migrate_compatible: db 'compatible=yes',10
db_migrate_compatible_len equ $-db_migrate_compatible
db_migrate_backup: db 'backup-policy=required-on-apply',10
db_migrate_backup_len equ $-db_migrate_backup
db_migrate_mutation: db 'mutation=none',10
db_migrate_mutation_len equ $-db_migrate_mutation
db_migrate_error: db 'NEBO-DB-MIGRATE-001: no compatible bounded migration plan for database header',10
db_migrate_error_len equ $-db_migrate_error

section .text
cli_db_validate_header:
 push r12
 push r13
 cmp qword [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],NEBO_DB_HEADER_SIZE
 jb .invalid
 lea rdi,[rel cli_source]
 call nebo_db_header_validate
 test eax,eax
 jnz .invalid
 mov r12,[rel cli_source+NEBO_DB_HEADER_PAGE_COUNT]
 mov rax,r12
 shl rax,12
 add rax,NEBO_DB_HEADER_SIZE
 cmp [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],rax
 jne .invalid
 xor r13d,r13d
.pages:
 cmp r13,r12
 jae .valid
 mov rax,r13
 shl rax,12
 lea rdi,[rel cli_source+NEBO_DB_HEADER_SIZE]
 add rdi,rax
 call nebo_db_page_validate
 test eax,eax
 jnz .invalid
 inc r13
 jmp .pages
.valid:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,1
.done:
 pop r13
 pop r12
 ret

cli_db_verify:
 call cli_db_validate_header
 test eax,eax
 jnz .invalid
 lea rdi,[rel db_verify_heading]
 mov esi,db_verify_heading_len
 call cli_write_stdout
 lea rdi,[rel db_verify_format]
 mov esi,db_verify_format_len
 call cli_write_stdout
 lea rdi,[rel db_verify_storage_version]
 mov esi,db_verify_storage_version_len
 call cli_write_stdout
 lea rdi,[rel db_verify_page_size]
 mov esi,db_verify_page_size_len
 call cli_write_stdout
 lea rdi,[rel db_verify_pages]
 mov esi,db_verify_pages_len
 call cli_write_stdout
 mov rdi,[rel cli_source+NEBO_DB_HEADER_PAGE_COUNT]
 call reactive_report_write_u64
 lea rdi,[rel db_verify_schema]
 mov esi,db_verify_schema_len
 call cli_write_stdout
 mov rdi,[rel cli_source+NEBO_DB_HEADER_SCHEMA_VERSION]
 call reactive_report_write_u64
 lea rdi,[rel db_verify_integrity]
 mov esi,db_verify_integrity_len
 call cli_write_stdout
 lea rdi,[rel db_verify_indexes]
 mov esi,db_verify_indexes_len
 call cli_write_stdout
 lea rdi,[rel db_verify_scope]
 mov esi,db_verify_scope_len
 call cli_write_stdout
 xor eax,eax
 ret
.invalid:
 lea rdi,[rel db_verify_error]
 mov esi,db_verify_error_len
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 ret

cli_db_migrate:
 push r12
 push r13
 call cli_db_validate_header
 test eax,eax
 jnz .invalid
 mov r12,[rel cli_source+NEBO_DB_HEADER_SCHEMA_VERSION]
 test r12,r12
 jz .invalid
 cmp r12,2
 ja .invalid
 mov r13,1
 cmp r12,2
 jne .emit
 xor r13d,r13d
.emit:
 lea rdi,[rel db_migrate_heading]
 mov esi,db_migrate_heading_len
 call cli_write_stdout
 lea rdi,[rel db_migrate_mode]
 mov esi,db_migrate_mode_len
 call cli_write_stdout
 lea rdi,[rel db_migrate_current]
 mov esi,db_migrate_current_len
 call cli_write_stdout
 mov rdi,r12
 call reactive_report_write_u64
 lea rdi,[rel db_migrate_target]
 mov esi,db_migrate_target_len
 call cli_write_stdout
 lea rdi,[rel db_migrate_steps]
 mov esi,db_migrate_steps_len
 call cli_write_stdout
 mov rdi,r13
 call reactive_report_write_u64
 lea rdi,[rel db_migrate_compatible]
 mov esi,db_migrate_compatible_len
 call cli_write_stdout
 lea rdi,[rel db_migrate_backup]
 mov esi,db_migrate_backup_len
 call cli_write_stdout
 lea rdi,[rel db_migrate_mutation]
 mov esi,db_migrate_mutation_len
 call cli_write_stdout
 xor eax,eax
 jmp .done
.invalid:
 lea rdi,[rel db_migrate_error]
 mov esi,db_migrate_error_len
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
.done:
 pop r13
 pop r12
 ret

%endif
