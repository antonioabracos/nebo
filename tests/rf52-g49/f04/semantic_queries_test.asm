bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/incremental/semantic_queries.inc"
global _start
extern neboc_query_database_new,neboc_query_db_execute
extern neboc_query_db_record_dependency,neboc_query_db_invalidate
extern neboc_query_db_cycle_report,neboc_query_db_result_digest
extern neboc_query_db_reuse_report,neboc_query_db_verify_against_cold
extern neboc_query_db_prune,neboc_semantic_snapshot_freeze
extern neboc_cli_query_report,neboc_host_process_exit

section .data
provider_a1: dq 0x101,0xa01,1,1
provider_a1_class4: dq 0x101,0xa01,4,1
provider_b1: dq 0x102,0xb01,2,1
provider_c1: dq 0x103,0xc01,3,1
provider_a2: dq 0x101,0xa01,1,2
provider_b2: dq 0x102,0xb01,2,2
provider_c2: dq 0x203,0xc02,3,2
provider_a3: dq 0x301,0xa03,1,3
provider_fill3: dq 0x777,0x888,4,3
keys: dq 1,2,3
cold: dq 0xa01,0xb01,0xc02

section .bss align=16
db: resb NEBOC_QUERY_DB_SIZE
db2: resb NEBOC_QUERY_DB_SIZE
snapshot1: resb NEBOC_SEMANTIC_SNAPSHOT_SIZE
snapshot2: resb NEBOC_SEMANTIC_SNAPSHOT_SIZE
snapshot_after: resb NEBOC_SEMANTIC_SNAPSHOT_SIZE
cycle_report: resb NEBOC_QUERY_CYCLE_REPORT_SIZE
reuse_report: resb NEBOC_QUERY_REPORT_SIZE
verify_report: resb NEBOC_QUERY_VERIFY_REPORT_SIZE
prune_report: resb NEBOC_QUERY_PRUNE_REPORT_SIZE
digest_out: resq 1

section .text
_start:
 sub rsp,8
 ; Constructor bounds fail before touching caller storage.
 xor edi,edi
 mov esi,1
 mov edx,8
 mov ecx,16
 call neboc_query_database_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail1
 mov qword [rel db],0x55
 lea rdi,[rel db]
 mov esi,1
 mov edx,NEBOC_QUERY_MAX_ENTRIES+1
 mov ecx,16
 call neboc_query_database_new
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail2
 cmp qword [rel db],0x55
 jne .fail3
 lea rdi,[rel db]
 mov esi,1
 mov edx,8
 mov ecx,16
 call neboc_query_database_new
 test eax,eax
 jne .fail4
 cmp qword [rel db+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .fail5

 ; Initial execution records misses/recomputes; exact reuse records hits.
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel provider_a1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail6
 cmp qword [rel db+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET],1
 jne .fail7
 cmp qword [rel db+NEBOC_QUERY_DB_MISSES_OFFSET],1
 jne .fail8
 cmp qword [rel db+NEBOC_QUERY_DB_RECOMPUTES_OFFSET],1
 jne .fail9
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel provider_a1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail10
 cmp qword [rel db+NEBOC_QUERY_DB_HITS_OFFSET],1
 jne .fail11
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel digest_out]
 call neboc_query_db_result_digest
 test eax,eax
 jne .fail12
 cmp qword [rel digest_out],0xa01
 jne .fail13
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel provider_a1_class4]
 call neboc_query_db_execute
 test eax,eax
 jne .fail75
 cmp qword [rel db+NEBOC_QUERY_DB_ENTRIES_OFFSET+NEBOC_QUERY_ENTRY_CLASS_OFFSET],4
 jne .fail76

 lea rdi,[rel db]
 mov esi,2
 lea rdx,[rel provider_b1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail14
 lea rdi,[rel db]
 mov esi,3
 lea rdx,[rel provider_c1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail15
 lea rdi,[rel db]
 mov esi,1
 mov edx,2
 call neboc_query_db_record_dependency
 test eax,eax
 jne .fail16
 lea rdi,[rel db]
 mov esi,2
 mov edx,3
 call neboc_query_db_record_dependency
 test eax,eax
 jne .fail17
 cmp qword [rel db+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET],2
 jne .fail18
 lea rdi,[rel db]
 mov esi,1
 mov edx,2
 call neboc_query_db_record_dependency
 test eax,eax
 jne .fail19
 cmp qword [rel db+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET],2
 jne .fail20

 ; A transitive cycle is rejected without publishing the edge.
 lea rdi,[rel db]
 mov esi,3
 mov edx,1
 call neboc_query_db_record_dependency
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail21
 cmp qword [rel db+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET],2
 jne .fail22
 lea rdi,[rel db]
 mov esi,3
 lea rdx,[rel cycle_report]
 call neboc_query_db_cycle_report
 test eax,eax
 jne .fail23
 cmp qword [rel cycle_report+NEBOC_QUERY_CYCLE_DETECTED_OFFSET],1
 jne .fail24
 cmp qword [rel cycle_report+NEBOC_QUERY_CYCLE_KEY_OFFSET],3
 jne .fail25

 ; A coherent revision freezes, independently of insertion and edge order.
 lea rdi,[rel db]
 lea rsi,[rel snapshot1]
 call neboc_semantic_snapshot_freeze
 test eax,eax
 jne .fail26
 cmp qword [rel snapshot1+NEBOC_SEMANTIC_SNAPSHOT_QUERY_COUNT_OFFSET],3
 jne .fail27
 lea rdi,[rel db2]
 mov esi,1
 mov edx,8
 mov ecx,16
 call neboc_query_database_new
 test eax,eax
 jne .fail28
 lea rdi,[rel db2]
 mov esi,3
 lea rdx,[rel provider_c1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail29
 lea rdi,[rel db2]
 mov esi,2
 lea rdx,[rel provider_b1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail30
 lea rdi,[rel db2]
 mov esi,1
 lea rdx,[rel provider_a1_class4]
 call neboc_query_db_execute
 test eax,eax
 jne .fail31
 lea rdi,[rel db2]
 mov esi,2
 mov edx,3
 call neboc_query_db_record_dependency
 test eax,eax
 jne .fail32
 lea rdi,[rel db2]
 mov esi,1
 mov edx,2
 call neboc_query_db_record_dependency
 test eax,eax
 jne .fail33
 lea rdi,[rel db2]
 lea rsi,[rel snapshot2]
 call neboc_semantic_snapshot_freeze
 test eax,eax
 jne .fail34
 mov rax,[rel snapshot1+NEBOC_SEMANTIC_SNAPSHOT_DIGEST_OFFSET]
 cmp rax,[rel snapshot2+NEBOC_SEMANTIC_SNAPSHOT_DIGEST_OFFSET]
 jne .fail35

 ; Invalidation reaches only the dependency closure and blocks mixed snapshots.
 lea rdi,[rel db]
 mov esi,3
 mov edx,2
 call neboc_query_db_invalidate
 test eax,eax
 jne .fail36
 cmp qword [rel db+NEBOC_QUERY_DB_REVISION_OFFSET],2
 jne .fail37
 cmp qword [rel db+NEBOC_QUERY_DB_INVALIDATIONS_OFFSET],3
 jne .fail38
 cmp qword [rel db+NEBOC_QUERY_DB_ENTRIES_OFFSET+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_INVALID
 jne .fail39
 mov qword [rel snapshot_after+NEBOC_SEMANTIC_SNAPSHOT_ACTIVE_OFFSET],0x66
 lea rdi,[rel db]
 lea rsi,[rel snapshot_after]
 call neboc_semantic_snapshot_freeze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail40
 cmp qword [rel snapshot_after+NEBOC_SEMANTIC_SNAPSHOT_ACTIVE_OFFSET],0x66
 jne .fail41
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel provider_a1]
 call neboc_query_db_execute
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail42
 cmp qword [rel db+NEBOC_QUERY_DB_ENTRIES_OFFSET+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_INVALID
 jne .fail43

 ; Recompute every invalid query in the new revision and compare with cold data.
 lea rdi,[rel db]
 mov esi,3
 lea rdx,[rel provider_c2]
 call neboc_query_db_execute
 test eax,eax
 jne .fail44
 lea rdi,[rel db]
 mov esi,2
 lea rdx,[rel provider_b2]
 call neboc_query_db_execute
 test eax,eax
 jne .fail45
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel provider_a2]
 call neboc_query_db_execute
 test eax,eax
 jne .fail46
 lea rdi,[rel db]
 lea rsi,[rel snapshot_after]
 call neboc_semantic_snapshot_freeze
 test eax,eax
 jne .fail47
 cmp qword [rel snapshot_after+NEBOC_SEMANTIC_SNAPSHOT_REVISION_OFFSET],2
 jne .fail48
 lea rdi,[rel db]
 lea rsi,[rel keys]
 lea rdx,[rel cold]
 mov ecx,3
 lea r8,[rel verify_report]
 call neboc_query_db_verify_against_cold
 test eax,eax
 jne .fail49
 cmp qword [rel verify_report+NEBOC_QUERY_VERIFY_MISMATCHES_OFFSET],0
 jne .fail50
 mov qword [rel cold+8],0xdead
 lea rdi,[rel db]
 lea rsi,[rel keys]
 lea rdx,[rel cold]
 mov ecx,3
 lea r8,[rel verify_report]
 call neboc_query_db_verify_against_cold
 test eax,eax
 jne .fail51
 cmp qword [rel verify_report+NEBOC_QUERY_VERIFY_MISMATCHES_OFFSET],1
 jne .fail52
 cmp qword [rel verify_report+NEBOC_QUERY_VERIFY_FIRST_KEY_OFFSET],2
 jne .fail53

 ; Unknown invalidation is atomic; pruning removes stale queries and dangling edges.
 lea rdi,[rel db]
 mov esi,99
 mov edx,3
 call neboc_query_db_invalidate
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail54
 cmp qword [rel db+NEBOC_QUERY_DB_REVISION_OFFSET],2
 jne .fail55
 lea rdi,[rel db]
 mov esi,3
 mov edx,3
 call neboc_query_db_invalidate
 test eax,eax
 jne .fail56
 lea rdi,[rel db]
 mov esi,1
 lea rdx,[rel provider_a3]
 call neboc_query_db_execute
 test eax,eax
 jne .fail57
 lea rdi,[rel db]
 mov esi,3
 lea rdx,[rel prune_report]
 call neboc_query_db_prune
 test eax,eax
 jne .fail58
 cmp qword [rel prune_report+NEBOC_QUERY_PRUNE_RETAINED_OFFSET],1
 jne .fail59
 cmp qword [rel prune_report+NEBOC_QUERY_PRUNE_REMOVED_OFFSET],2
 jne .fail60
 cmp qword [rel db+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET],0
 jne .fail61
 lea rdi,[rel db]
 lea rsi,[rel snapshot_after]
 call neboc_semantic_snapshot_freeze
 test eax,eax
 jne .fail62

 ; Bounded capacity and reports remain deterministic and caller-owned.
 mov r12d,4
.fill:
 cmp r12d,11
 jae .filled
 lea rdi,[rel db]
 mov rsi,r12
 lea rdx,[rel provider_fill3]
 call neboc_query_db_execute
 test eax,eax
 jne .fail63
 inc r12
 jmp .fill
.filled:
 cmp qword [rel db+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET],8
 jne .fail64
 lea rdi,[rel db]
 mov esi,11
 lea rdx,[rel provider_fill3]
 call neboc_query_db_execute
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail65
 lea rdi,[rel db]
 lea rsi,[rel reuse_report]
 call neboc_cli_query_report
 test eax,eax
 jne .fail66
 cmp qword [rel reuse_report+NEBOC_QUERY_REPORT_ENTRIES_OFFSET],8
 jne .fail67
 cmp qword [rel reuse_report+NEBOC_QUERY_REPORT_EDGES_OFFSET],0
 jne .fail68
 mov qword [rel verify_report],0x44
 lea rdi,[rel db]
 lea rsi,[rel keys]
 lea rdx,[rel cold]
 mov ecx,NEBOC_QUERY_MAX_ENTRIES+1
 lea r8,[rel verify_report]
 call neboc_query_db_verify_against_cold
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail69
 cmp qword [rel verify_report],0x44
 jne .fail70
 lea rdi,[rel db]
 mov esi,99
 lea rdx,[rel cycle_report]
 call neboc_query_db_cycle_report
 test eax,eax
 jne .fail71
 cmp qword [rel cycle_report+NEBOC_QUERY_CYCLE_DETECTED_OFFSET],0
 jne .fail72
 mov qword [rel digest_out],0x99
 lea rdi,[rel db]
 mov esi,99
 lea rdx,[rel digest_out]
 call neboc_query_db_result_digest
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail73
 cmp qword [rel digest_out],0x99
 jne .fail74

 ; Edge capacity is independently bounded and failure-atomic.
 lea rdi,[rel db2]
 mov esi,1
 mov edx,8
 mov ecx,1
 call neboc_query_database_new
 test eax,eax
 jne .fail77
 lea rdi,[rel db2]
 mov esi,1
 lea rdx,[rel provider_a1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail78
 lea rdi,[rel db2]
 mov esi,2
 lea rdx,[rel provider_b1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail79
 lea rdi,[rel db2]
 mov esi,3
 lea rdx,[rel provider_c1]
 call neboc_query_db_execute
 test eax,eax
 jne .fail80
 lea rdi,[rel db2]
 mov esi,1
 mov edx,2
 call neboc_query_db_record_dependency
 test eax,eax
 jne .fail81
 lea rdi,[rel db2]
 mov esi,2
 mov edx,3
 call neboc_query_db_record_dependency
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail82
 cmp qword [rel db2+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET],1
 jne .fail83

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 83
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
