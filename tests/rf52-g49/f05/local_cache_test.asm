bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/cache/local_cache.inc"
global _start
extern neboc_compiler_cache_open,neboc_cache_key_new
extern neboc_cache_lookup,neboc_cache_store,neboc_cache_verify
extern neboc_cache_invalidate,neboc_cache_prune,neboc_cache_stats
extern neboc_cache_explain,neboc_cli_cache_admin
extern neboc_cli_build_cache_mode,neboc_cli_cache_explain
extern neboc_host_process_exit

section .data
key_input1: dq 1,0x11,0x21,0x31,0x41,0x51,0,NEBOC_CACHE_SCHEMA_VERSION
key_input2: dq 2,0x12,0x22,0x32,0x42,0x52,0x62,NEBOC_CACHE_SCHEMA_VERSION
key_input3: dq 1,0x13,0x23,0x33,0x43,0x53,0x63,NEBOC_CACHE_SCHEMA_VERSION
key_input4: dq 4,0x14,0x24,0x34,0x44,0x54,0x64,NEBOC_CACHE_SCHEMA_VERSION
payload1: db "artifact-one"
payload2: db "artifact-two"
payload3: db "artifact-three"

section .bss align=16
cache: resb NEBOC_CACHE_CTX_SIZE
entries: resb NEBOC_CACHE_ENTRY_SIZE*8
config: resb NEBOC_CACHE_CONFIG_SIZE
key1: resb NEBOC_CACHE_KEY_SIZE
key2: resb NEBOC_CACHE_KEY_SIZE
key3: resb NEBOC_CACHE_KEY_SIZE
key4: resb NEBOC_CACHE_KEY_SIZE
invalid_input: resb NEBOC_CACHE_KEY_INPUT_SIZE
result: resb NEBOC_CACHE_RESULT_SIZE
stats: resb NEBOC_CACHE_STATS_SIZE
explain: resb NEBOC_CACHE_EXPLAIN_SIZE
mutation: resb NEBOC_CACHE_MUTATION_REPORT_SIZE
prune_request: resb NEBOC_CACHE_PRUNE_REQUEST_SIZE

section .text
configure:
 ; rdi=config, rsi=entry storage, rdx=capacity, rcx=max bytes, r8=policy.
 mov qword [rdi+NEBOC_CACHE_CONFIG_PATH_DIGEST_OFFSET],0xcace
 mov [rdi+NEBOC_CACHE_CONFIG_POLICY_OFFSET],r8
 mov qword [rdi+NEBOC_CACHE_CONFIG_CAPABILITY_OFFSET],0xca01
 mov [rdi+NEBOC_CACHE_CONFIG_ENTRIES_OFFSET],rsi
 mov [rdi+NEBOC_CACHE_CONFIG_CAPACITY_OFFSET],rdx
 mov [rdi+NEBOC_CACHE_CONFIG_MAX_BYTES_OFFSET],rcx
 mov qword [rdi+NEBOC_CACHE_CONFIG_SCHEMA_OFFSET],NEBOC_CACHE_SCHEMA_VERSION
 ret

_start:
 sub rsp,8
 ; Open preflights config and storage bounds before mutation.
 lea rdi,[rel config]
 lea rsi,[rel entries]
 mov edx,NEBOC_CACHE_MAX_ENTRIES+1
 mov ecx,64
 mov r8d,NEBOC_CACHE_MODE_READ_WRITE
 call configure
 mov qword [rel cache],0x55
 lea rdi,[rel cache]
 lea rsi,[rel config]
 call neboc_compiler_cache_open
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail1
 cmp qword [rel cache],0x55
 jne .fail2
 lea rdi,[rel config]
 lea rsi,[rel entries]
 mov edx,8
 mov ecx,64
 mov r8d,NEBOC_CACHE_MODE_READ_WRITE
 call configure
 lea rdi,[rel cache]
 lea rsi,[rel config]
 call neboc_compiler_cache_open
 test eax,eax
 jne .fail3
 cmp qword [rel cache+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .fail4

 ; Every required key component is validated and copied canonically.
 lea rsi,[rel key_input1]
 lea rdi,[rel invalid_input]
 mov ecx,NEBOC_CACHE_KEY_INPUT_SIZE/8
 rep movsq
 mov qword [rel invalid_input+NEBOC_CACHE_KEY_INPUT_OPTIONS_OFFSET],0
 mov qword [rel key1],0x66
 lea rdi,[rel key1]
 lea rsi,[rel invalid_input]
 call neboc_cache_key_new
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail5
 cmp qword [rel key1],0x66
 jne .fail6
 lea rdi,[rel key1]
 lea rsi,[rel key_input1]
 call neboc_cache_key_new
 test eax,eax
 jne .fail7
 lea rdi,[rel key2]
 lea rsi,[rel key_input2]
 call neboc_cache_key_new
 test eax,eax
 jne .fail8
 lea rdi,[rel key3]
 lea rsi,[rel key_input3]
 call neboc_cache_key_new
 test eax,eax
 jne .fail9
 lea rdi,[rel key4]
 lea rsi,[rel key_input4]
 call neboc_cache_key_new
 test eax,eax
 jne .fail10
 mov rax,[rel key1+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 cmp rax,[rel key2+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 je .fail11

 ; Failed digest verification publishes no entry.
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel payload1]
 mov ecx,12
 mov r8,0x111
 mov r9,0xa1
 call neboc_cache_store
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail12
 cmp qword [rel cache+NEBOC_CACHE_CTX_COUNT_OFFSET],0
 jne .fail13
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel payload1]
 mov ecx,12
 mov r8,0xe0e63357c77f7932
 mov r9,0xa1
 call neboc_cache_store
 test eax,eax
 jne .fail14
 cmp qword [rel cache+NEBOC_CACHE_CTX_COUNT_OFFSET],1
 jne .fail15
 cmp qword [rel cache+NEBOC_CACHE_CTX_USED_BYTES_OFFSET],12
 jne .fail16

 ; Hit and verify expose only a validated artifact.
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel result]
 call neboc_cache_lookup
 test eax,eax
 jne .fail17
 cmp qword [rel result+NEBOC_CACHE_RESULT_KIND_OFFSET],NEBOC_CACHE_LOOKUP_HIT
 jne .fail18
 cmp qword [rel result+NEBOC_CACHE_RESULT_LENGTH_OFFSET],12
 jne .fail19
 cmp qword [rel result+NEBOC_CACHE_RESULT_METADATA_OFFSET],0xa1
 jne .fail20
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel result]
 call neboc_cache_verify
 test eax,eax
 jne .fail21
 cmp qword [rel result+NEBOC_CACHE_RESULT_KIND_OFFSET],NEBOC_CACHE_LOOKUP_HIT
 jne .fail22

 ; Caller mutation is detected as corruption and payload is withheld.
 mov byte [rel payload1],0x58
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel result]
 call neboc_cache_lookup
 test eax,eax
 jne .fail23
 cmp qword [rel result+NEBOC_CACHE_RESULT_KIND_OFFSET],NEBOC_CACHE_LOOKUP_CORRUPT
 jne .fail24
 cmp qword [rel result+NEBOC_CACHE_RESULT_PAYLOAD_OFFSET],0
 jne .fail25
 mov byte [rel payload1],0x61
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel result]
 call neboc_cache_lookup
 test eax,eax
 jne .fail26
 cmp qword [rel result+NEBOC_CACHE_RESULT_KIND_OFFSET],NEBOC_CACHE_LOOKUP_HIT
 jne .fail27

 ; Schema mismatch is stale and is likewise never exposed.
 mov qword [rel entries+NEBOC_CACHE_ENTRY_ARTIFACT_SCHEMA_OFFSET],2
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel result]
 call neboc_cache_lookup
 test eax,eax
 jne .fail28
 cmp qword [rel result+NEBOC_CACHE_RESULT_KIND_OFFSET],NEBOC_CACHE_LOOKUP_STALE
 jne .fail29
 cmp qword [rel result+NEBOC_CACHE_RESULT_PAYLOAD_OFFSET],0
 jne .fail30
 mov qword [rel entries+NEBOC_CACHE_ENTRY_ARTIFACT_SCHEMA_OFFSET],NEBOC_CACHE_SCHEMA_VERSION

 ; Store distinct namespaces, collect factual stats, and explain keys.
 lea rdi,[rel cache]
 lea rsi,[rel key2]
 lea rdx,[rel payload2]
 mov ecx,12
 mov r8,0xb9775a58422b7de8
 mov r9,0xa2
 call neboc_cache_store
 test eax,eax
 jne .fail31
 lea rdi,[rel cache]
 lea rsi,[rel key3]
 lea rdx,[rel payload3]
 mov ecx,14
 mov r8,0x85cd5b4f7622a02a
 mov r9,0xa3
 call neboc_cache_store
 test eax,eax
 jne .fail32
 lea rdi,[rel cache]
 lea rsi,[rel stats]
 call neboc_cache_stats
 test eax,eax
 jne .fail33
 cmp qword [rel stats+NEBOC_CACHE_STATS_ENTRIES_OFFSET],3
 jne .fail34
 cmp qword [rel stats+NEBOC_CACHE_STATS_BYTES_OFFSET],38
 jne .fail35
 cmp qword [rel stats+NEBOC_CACHE_STATS_CORRUPTIONS_OFFSET],1
 jne .fail36
 cmp qword [rel stats+NEBOC_CACHE_STATS_STALE_OFFSET],1
 jne .fail37
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel explain]
 call neboc_cache_explain
 test eax,eax
 jne .fail38
 cmp qword [rel explain+NEBOC_CACHE_EXPLAIN_REASON_OFFSET],NEBOC_CACHE_LOOKUP_HIT
 jne .fail39
 cmp qword [rel explain+NEBOC_CACHE_EXPLAIN_NAMESPACE_OFFSET],1
 jne .fail40
 lea rdi,[rel cache]
 lea rsi,[rel key4]
 lea rdx,[rel explain]
 call neboc_cli_cache_explain
 test eax,eax
 jne .fail41
 cmp qword [rel explain+NEBOC_CACHE_EXPLAIN_REASON_OFFSET],NEBOC_CACHE_LOOKUP_MISS
 jne .fail42

 ; Explicit cache modes preserve one-shot behavior and reject writes in read mode.
 lea rdi,[rel cache]
 mov esi,NEBOC_CACHE_MODE_OFF
 call neboc_cli_build_cache_mode
 test eax,eax
 jne .fail43
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel result]
 call neboc_cache_lookup
 test eax,eax
 jne .fail44
 cmp qword [rel result+NEBOC_CACHE_RESULT_KIND_OFFSET],NEBOC_CACHE_LOOKUP_OFF
 jne .fail45
 lea rdi,[rel cache]
 mov esi,NEBOC_CACHE_MODE_READ
 call neboc_cli_build_cache_mode
 test eax,eax
 jne .fail46
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel payload1]
 mov ecx,12
 mov r8,0xe0e63357c77f7932
 mov r9,0xa1
 call neboc_cache_store
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail47
 lea rdi,[rel cache]
 mov esi,NEBOC_CACHE_MODE_READ_WRITE
 call neboc_cli_build_cache_mode
 test eax,eax
 jne .fail48

 ; Namespace invalidation compacts only selected local entries.
 lea rdi,[rel cache]
 mov esi,1
 lea rdx,[rel mutation]
 call neboc_cache_invalidate
 test eax,eax
 jne .fail49
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMOVED_OFFSET],2
 jne .fail50
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_BYTES_OFFSET],26
 jne .fail51
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMAINING_OFFSET],1
 jne .fail52
 cmp qword [rel entries+NEBOC_CACHE_KEY_NAMESPACE_OFFSET],2
 jne .fail53

 ; Reinsert and deterministically prune the lowest stable slot.
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel payload1]
 mov ecx,12
 mov r8,0xe0e63357c77f7932
 mov r9,0xa1
 call neboc_cache_store
 test eax,eax
 jne .fail54
 lea rdi,[rel cache]
 mov esi,12
 mov edx,1
 xor ecx,ecx
 lea r8,[rel mutation]
 call neboc_cache_prune
 test eax,eax
 jne .fail55
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMOVED_OFFSET],1
 jne .fail56
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMAINING_OFFSET],1
 jne .fail57
 cmp qword [rel entries+NEBOC_CACHE_KEY_DIGEST_OFFSET],0
 je .fail58
 mov rax,[rel entries+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 cmp rax,[rel key1+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 jne .fail59
 lea rdi,[rel cache]
 xor esi,esi
 xor edx,edx
 mov ecx,5
 lea r8,[rel mutation]
 call neboc_cache_prune
 test eax,eax
 jne .fail60
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMOVED_OFFSET],1
 jne .fail61
 cmp qword [rel cache+NEBOC_CACHE_CTX_COUNT_OFFSET],0
 jne .fail62

 ; CLI administration dispatches stats/verify/prune/clear over the same backend.
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel payload1]
 mov ecx,12
 mov r8,0xe0e63357c77f7932
 mov r9,0xa1
 call neboc_cache_store
 test eax,eax
 jne .fail63
 lea rdi,[rel cache]
 mov esi,NEBOC_CACHE_ADMIN_STATS
 xor edx,edx
 lea r8,[rel stats]
 call neboc_cli_cache_admin
 test eax,eax
 jne .fail64
 cmp qword [rel stats+NEBOC_CACHE_STATS_ENTRIES_OFFSET],1
 jne .fail65
 lea rdi,[rel cache]
 mov esi,NEBOC_CACHE_ADMIN_VERIFY
 lea rdx,[rel key1]
 lea r8,[rel result]
 call neboc_cli_cache_admin
 test eax,eax
 jne .fail66
 cmp qword [rel result+NEBOC_CACHE_RESULT_KIND_OFFSET],NEBOC_CACHE_LOOKUP_HIT
 jne .fail67
 lea rdi,[rel cache]
 lea rsi,[rel key2]
 lea rdx,[rel payload2]
 mov ecx,12
 mov r8,0xb9775a58422b7de8
 xor r9d,r9d
 call neboc_cache_store
 test eax,eax
 jne .fail77
 mov qword [rel prune_request+NEBOC_CACHE_PRUNE_REQUEST_MAX_BYTES_OFFSET],64
 mov qword [rel prune_request+NEBOC_CACHE_PRUNE_REQUEST_MAX_ITEMS_OFFSET],1
 mov qword [rel prune_request+NEBOC_CACHE_PRUNE_REQUEST_MIN_SEQUENCE_OFFSET],0
 lea rdi,[rel cache]
 mov esi,NEBOC_CACHE_ADMIN_PRUNE
 lea rdx,[rel prune_request]
 lea r8,[rel mutation]
 call neboc_cli_cache_admin
 test eax,eax
 jne .fail78
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMOVED_OFFSET],1
 jne .fail79
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMAINING_OFFSET],1
 jne .fail80
 lea rdi,[rel cache]
 mov esi,NEBOC_CACHE_ADMIN_CLEAR
 xor edx,edx
 lea r8,[rel mutation]
 call neboc_cli_cache_admin
 test eax,eax
 jne .fail68
 cmp qword [rel mutation+NEBOC_CACHE_MUTATION_REMOVED_OFFSET],1
 jne .fail69

 ; Independent item and byte bounds are failure-atomic.
 lea rdi,[rel config]
 lea rsi,[rel entries]
 mov edx,2
 mov ecx,64
 mov r8d,NEBOC_CACHE_MODE_READ_WRITE
 call configure
 lea rdi,[rel cache]
 lea rsi,[rel config]
 call neboc_compiler_cache_open
 test eax,eax
 jne .fail70
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel payload1]
 mov ecx,12
 mov r8,0xe0e63357c77f7932
 xor r9d,r9d
 call neboc_cache_store
 test eax,eax
 jne .fail71
 lea rdi,[rel cache]
 lea rsi,[rel key2]
 lea rdx,[rel payload2]
 mov ecx,12
 mov r8,0xb9775a58422b7de8
 xor r9d,r9d
 call neboc_cache_store
 test eax,eax
 jne .fail72
 lea rdi,[rel cache]
 lea rsi,[rel key3]
 lea rdx,[rel payload3]
 mov ecx,14
 mov r8,0x85cd5b4f7622a02a
 xor r9d,r9d
 call neboc_cache_store
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail73
 cmp qword [rel cache+NEBOC_CACHE_CTX_COUNT_OFFSET],2
 jne .fail74
 lea rdi,[rel cache]
 lea rsi,[rel key1]
 lea rdx,[rel payload1]
 mov ecx,65
 xor r8d,r8d
 xor r9d,r9d
 call neboc_cache_store
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail75
 cmp qword [rel cache+NEBOC_CACHE_CTX_USED_BYTES_OFFSET],24
 jne .fail76

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 80
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
