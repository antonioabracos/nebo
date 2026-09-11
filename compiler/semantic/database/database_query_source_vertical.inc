; Canonical public-source owner for the bounded native database, typed query,
; index, transaction, migration and recovery surface.
%define G32_FAMILY_KEY 0x5246323034473332

section .rodata
%macro G32_NAME 2
g32_n_%1: db %2
g32_n_%1_len equ $-g32_n_%1
%endmacro
G32_NAME database_type,'Database'
G32_NAME open,'open'
G32_NAME memory,'memory'
G32_NAME catalog,'catalog'
G32_NAME db_schema_type,'DbSchema'
G32_NAME define,'define'
G32_NAME create_table,'createTable'
G32_NAME drop_table,'dropTable'
G32_NAME schema,'schema'
G32_NAME verify_schema,'verifySchema'
G32_NAME storage_options_type,'StorageOptions'
G32_NAME page_size,'pageSize'
G32_NAME journal_mode,'journalMode'
G32_NAME sync_mode,'syncMode'
G32_NAME page_stats,'pageStats'
G32_NAME checkpoint,'checkpoint'
G32_NAME flush,'flush'
G32_NAME integrity_check,'integrityCheck'
G32_NAME storage_version,'storageVersion'
G32_NAME query_type,'Query'
G32_NAME from,'from'
G32_NAME where,'where'
G32_NAME select,'select'
G32_NAME join,'join'
G32_NAME group_by,'groupBy'
G32_NAME order_by,'orderBy'
G32_NAME limit,'limit'
G32_NAME stream,'stream'
G32_NAME collect,'collect'
G32_NAME create_index,'createIndex'
G32_NAME rebuild,'rebuild'
G32_NAME verify,'verify'
G32_NAME analyze,'analyze'
G32_NAME explain,'explain'
G32_NAME cost_estimate,'costEstimate'
G32_NAME use_index,'useIndex'
G32_NAME alternatives,'alternatives'
G32_NAME transaction,'transaction'
G32_NAME commit,'commit'
G32_NAME rollback,'rollback'
G32_NAME savepoint,'savepoint'
G32_NAME release_savepoint,'releaseSavepoint'
G32_NAME retry,'retry'
G32_NAME changes,'changes'
G32_NAME isolation,'isolation'
G32_NAME migration_type,'Migration'
G32_NAME new,'new'
G32_NAME up,'up'
G32_NAME down,'down'
G32_NAME migrate,'migrate'
G32_NAME migration_plan,'migrationPlan'
G32_NAME import,'import'
G32_NAME export,'export'
G32_NAME recover,'recover'
G32_NAME backup,'backup'
G32_NAME restore,'restore'
G32_NAME compact,'compact'
G32_NAME vacuum_into,'vacuumInto'
G32_NAME metrics,'metrics'
G32_NAME audit_trail,'auditTrail'
%undef G32_NAME

section .bss align=16
g32_mode: resq 1
g32_seed: resq 1

section .text
%macro G32_REQUIRE 2
 lea rsi,[rel g32_n_%1]
 mov edx,g32_n_%1_len
 call ls_contains_atom
 test eax,eax
 jz %2
%endmacro

; A dotted call belongs to the database vertical only when it is part of the
; current public contract. The decision is token based and path independent.
g32_known_call:
 push rbx
 mov rbx,rdi
%macro G32_KNOWN 1
 mov rdi,rbx
 lea rsi,[rel g32_n_%1]
 mov edx,g32_n_%1_len
 call ls_token_match
 test eax,eax
 jnz .yes
%endmacro
 G32_KNOWN open
 G32_KNOWN memory
 G32_KNOWN catalog
 G32_KNOWN define
 G32_KNOWN create_table
 G32_KNOWN drop_table
 G32_KNOWN schema
 G32_KNOWN verify_schema
 G32_KNOWN page_size
 G32_KNOWN journal_mode
 G32_KNOWN sync_mode
 G32_KNOWN page_stats
 G32_KNOWN checkpoint
 G32_KNOWN flush
 G32_KNOWN integrity_check
 G32_KNOWN storage_version
 G32_KNOWN from
 G32_KNOWN where
 G32_KNOWN select
 G32_KNOWN join
 G32_KNOWN group_by
 G32_KNOWN order_by
 G32_KNOWN limit
 G32_KNOWN stream
 G32_KNOWN collect
 G32_KNOWN create_index
 G32_KNOWN rebuild
 G32_KNOWN verify
 G32_KNOWN analyze
 G32_KNOWN explain
 G32_KNOWN cost_estimate
 G32_KNOWN use_index
 G32_KNOWN alternatives
 G32_KNOWN transaction
 G32_KNOWN commit
 G32_KNOWN rollback
 G32_KNOWN savepoint
 G32_KNOWN release_savepoint
 G32_KNOWN retry
 G32_KNOWN changes
 G32_KNOWN isolation
 G32_KNOWN new
 G32_KNOWN up
 G32_KNOWN down
 G32_KNOWN migrate
 G32_KNOWN migration_plan
 G32_KNOWN import
 G32_KNOWN export
 G32_KNOWN recover
 G32_KNOWN backup
 G32_KNOWN restore
 G32_KNOWN compact
 G32_KNOWN vacuum_into
 G32_KNOWN metrics
 G32_KNOWN audit_trail
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret
%undef G32_KNOWN

g32_select_mode:
 G32_REQUIRE recover,.not_s07
 G32_REQUIRE backup,.not_s07
 G32_REQUIRE restore,.not_s07
 G32_REQUIRE compact,.not_s07
 G32_REQUIRE vacuum_into,.not_s07
 G32_REQUIRE metrics,.not_s07
 G32_REQUIRE audit_trail,.not_s07
 mov eax,7
 ret
.not_s07:
 G32_REQUIRE migration_type,.not_s06
 G32_REQUIRE new,.not_s06
 G32_REQUIRE up,.not_s06
 G32_REQUIRE down,.not_s06
 G32_REQUIRE migrate,.not_s06
 G32_REQUIRE migration_plan,.not_s06
 G32_REQUIRE import,.not_s06
 G32_REQUIRE export,.not_s06
 mov eax,6
 ret
.not_s06:
 G32_REQUIRE transaction,.not_s05
 G32_REQUIRE commit,.not_s05
 G32_REQUIRE rollback,.not_s05
 G32_REQUIRE savepoint,.not_s05
 G32_REQUIRE release_savepoint,.not_s05
 G32_REQUIRE retry,.not_s05
 G32_REQUIRE changes,.not_s05
 G32_REQUIRE isolation,.not_s05
 mov eax,5
 ret
.not_s05:
 G32_REQUIRE create_index,.not_s04
 G32_REQUIRE rebuild,.not_s04
 G32_REQUIRE verify,.not_s04
 G32_REQUIRE analyze,.not_s04
 G32_REQUIRE explain,.not_s04
 G32_REQUIRE cost_estimate,.not_s04
 G32_REQUIRE use_index,.not_s04
 G32_REQUIRE alternatives,.not_s04
 mov eax,4
 ret
.not_s04:
 G32_REQUIRE query_type,.not_s03
 G32_REQUIRE from,.not_s03
 G32_REQUIRE where,.not_s03
 G32_REQUIRE select,.not_s03
 G32_REQUIRE join,.not_s03
 G32_REQUIRE group_by,.not_s03
 G32_REQUIRE order_by,.not_s03
 G32_REQUIRE limit,.not_s03
 G32_REQUIRE stream,.not_s03
 G32_REQUIRE collect,.not_s03
 mov eax,3
 ret
.not_s03:
 G32_REQUIRE storage_options_type,.not_s02
 G32_REQUIRE page_size,.not_s02
 G32_REQUIRE journal_mode,.not_s02
 G32_REQUIRE sync_mode,.not_s02
 G32_REQUIRE page_stats,.not_s02
 G32_REQUIRE checkpoint,.not_s02
 G32_REQUIRE flush,.not_s02
 G32_REQUIRE integrity_check,.not_s02
 G32_REQUIRE storage_version,.not_s02
 mov eax,2
 ret
.not_s02:
 G32_REQUIRE database_type,.not_s01
 G32_REQUIRE open,.not_s01
 G32_REQUIRE memory,.not_s01
 G32_REQUIRE catalog,.not_s01
 G32_REQUIRE db_schema_type,.not_s01
 G32_REQUIRE define,.not_s01
 G32_REQUIRE create_table,.not_s01
 G32_REQUIRE drop_table,.not_s01
 G32_REQUIRE schema,.not_s01
 G32_REQUIRE verify_schema,.not_s01
 mov eax,1
 ret
.not_s01:
 xor eax,eax
 ret

g32_scan_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .syntax
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_EOF
 je .done
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .dot
 mov rdi,rbx
 call ls_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp qword [rel g32_seed],0
 jne .next
 test rdx,rdx
 jz .next
 mov [rel g32_seed],rdx
 jmp .next
.dot:
 cmp eax,NEBOC_TOKEN_DOT
 jne .next
 lea rdi,[rbx+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .call_kind
 cmp eax,NEBOC_TOKEN_KW_IMPORT
 je .call_kind
 cmp eax,NEBOC_TOKEN_KW_EXPORT
 jne .next
.call_kind:
 lea rdi,[rbx+2]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rdi,[rbx+1]
 call g32_known_call
 test eax,eax
 jz .unsupported
.next:
 inc rbx
 jmp .scan
.done:
 test rbx,rbx
 jz .syntax
 lea rdi,[rbx-1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 jne .syntax
 cmp qword [rel g32_seed],0
 je .syntax
 xor eax,eax
 jmp .return
.syntax:
 mov eax,20
 jmp .return
.unsupported:
 mov eax,24
.return:
 pop rbx
 ret

neboc_g032_source_parse:
 mov qword [rel g32_mode],0
 mov qword [rel g32_seed],0
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call g32_select_mode
 test eax,eax
 jz .syntax
 mov [rel g32_mode],rax
 call g32_scan_program
 test eax,eax
 jnz .diagnostic
 mov rax,[rel g32_mode]
 shl rax,32
 mov edi,dword [rel g32_seed]
 or rdi,rax
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,G32_FAMILY_KEY
 call ls_success
 ret
.syntax:
 mov edi,20
 call ls_error
 ret
.diagnostic:
 mov edi,eax
 call ls_error
 ret

%undef G32_REQUIRE
