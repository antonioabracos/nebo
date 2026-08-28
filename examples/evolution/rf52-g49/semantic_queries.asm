bits 64
default rel
%include "compiler/incremental/semantic_queries.inc"
global _start
extern neboc_query_database_new,neboc_query_db_execute
extern neboc_semantic_snapshot_freeze,neboc_host_process_exit

section .data
provider: dq 0x1234,0x5678,1,1

section .bss align=16
db: resb NEBOC_QUERY_DB_SIZE
snapshot: resb NEBOC_SEMANTIC_SNAPSHOT_SIZE

section .text
_start:
 sub rsp,8
 lea rdi,[rel db]
 mov esi,1
 mov edx,8
 mov ecx,16
 call neboc_query_database_new
 test eax,eax
 jne .done
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel provider]
 call neboc_query_db_execute
 test eax,eax
 jne .done
 lea rdi,[rel db]
 lea rsi,[rel snapshot]
 call neboc_semantic_snapshot_freeze
.done:
 mov edi,eax
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
