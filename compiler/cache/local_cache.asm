; LOCAL-CACHE-F05 bounded caller-owned local content-addressed cache.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/cache/local_cache.inc"

%define FNV64_OFFSET 0xcbf29ce484222325
%define FNV64_PRIME 0x100000001b3

section .text

; Internal: rdi=canonical key. Returns digest in rax.
cache_key_digest:
 mov rax,FNV64_OFFSET
 mov r8,FNV64_PRIME
 mov ecx,1
.loop:
 cmp ecx,9
 jae .done
 mov rdx,[rdi+rcx*8]
 xor rax,rdx
 imul rax,r8
 inc ecx
 jmp .loop
.done:
 test rax,rax
 jnz .ret
 mov eax,1
.ret:
 ret

; Internal: rdi=bytes, rsi=length. Returns digest in rax.
cache_payload_digest:
 mov rax,FNV64_OFFSET
 mov r8,FNV64_PRIME
 xor ecx,ecx
.loop:
 cmp rcx,rsi
 jae .done
 movzx edx,byte [rdi+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .loop
.done:
 ret

; Internal: rdi=cache, rsi=key. Returns full-component match or zero.
cache_find:
 mov r8,[rdi+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 mov r9,[rdi+NEBOC_CACHE_CTX_COUNT_OFFSET]
 xor ecx,ecx
.entry_loop:
 cmp rcx,r9
 jae .missing
 mov rax,rcx
 shl rax,7
 add rax,r8
 cmp qword [rax+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],1
 jne .next
 xor r10d,r10d
.field_loop:
 cmp r10d,9
 jae .found
 mov r11,[rsi+r10*8]
 cmp [rax+r10*8],r11
 jne .next
 inc r10
 jmp .field_loop
.next:
 inc rcx
 jmp .entry_loop
.found:
 ret
.missing:
 xor eax,eax
 ret

; Internal: compact active entries. rdi=cache; returns removed count/bytes rax/rdx.
cache_compact:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 xor r13d,r13d
 xor r14d,r14d
 xor r15d,r15d
 mov qword [rsp],0
 mov qword [rsp+8],0
.scan:
 cmp r13,r12
 jae .scanned
 mov rax,r13
 shl rax,7
 add rax,[rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 cmp qword [rax+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],1
 jne .removed
 mov rcx,[rax+NEBOC_CACHE_ENTRY_LENGTH_OFFSET]
 add [rsp+8],rcx
 cmp r13,r14
 je .kept
 mov rsi,rax
 mov rdi,r14
 shl rdi,7
 add rdi,[rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 mov ecx,NEBOC_CACHE_ENTRY_SIZE/8
 rep movsq
.kept:
 inc r14
 jmp .next
.removed:
 inc r15
 mov rcx,[rax+NEBOC_CACHE_ENTRY_LENGTH_OFFSET]
 add [rsp],rcx
.next:
 inc r13
 jmp .scan
.scanned:
 mov [rbx+NEBOC_CACHE_CTX_COUNT_OFFSET],r14
 mov rax,[rsp+8]
 mov [rbx+NEBOC_CACHE_CTX_USED_BYTES_OFFSET],rax
 mov r13,r14
.zero_tail:
 cmp r13,r12
 jae .done
 mov rdi,r13
 shl rdi,7
 add rdi,[rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 xor eax,eax
 mov ecx,NEBOC_CACHE_ENTRY_SIZE/8
 rep stosq
 inc r13
 jmp .zero_tail
.done:
 mov rax,r15
 mov rdx,[rsp]
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_compiler_cache_open
 ; rdi=cache, rsi=config descriptor. Storage remains caller-owned.
 test rdi,rdi
 jz .invalid_before_save
 test rsi,rsi
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 cmp qword [r12+NEBOC_CACHE_CONFIG_PATH_DIGEST_OFFSET],0
 je .invalid
 mov rax,[r12+NEBOC_CACHE_CONFIG_POLICY_OFFSET]
 cmp rax,NEBOC_CACHE_MODE_READ_WRITE
 ja .invalid
 cmp qword [r12+NEBOC_CACHE_CONFIG_CAPABILITY_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_CACHE_CONFIG_ENTRIES_OFFSET],0
 je .invalid
 mov r13,[r12+NEBOC_CACHE_CONFIG_CAPACITY_OFFSET]
 test r13,r13
 jz .invalid
 cmp r13,NEBOC_CACHE_MAX_ENTRIES
 ja .limit
 mov r14,[r12+NEBOC_CACHE_CONFIG_MAX_BYTES_OFFSET]
 test r14,r14
 jz .invalid
 cmp r14,NEBOC_CACHE_MAX_BYTES
 ja .limit
 cmp qword [r12+NEBOC_CACHE_CONFIG_SCHEMA_OFFSET],NEBOC_CACHE_SCHEMA_VERSION
 jne .invalid
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_CACHE_CTX_SIZE/8
 rep stosq
 mov r15,[r12+NEBOC_CACHE_CONFIG_ENTRIES_OFFSET]
 mov rdi,r15
 xor eax,eax
 mov rcx,r13
 shl rcx,4
 rep stosq
 mov [rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET],r15
 mov [rbx+NEBOC_CACHE_CTX_CAPACITY_OFFSET],r13
 mov [rbx+NEBOC_CACHE_CTX_MAX_BYTES_OFFSET],r14
 mov rax,[r12+NEBOC_CACHE_CONFIG_PATH_DIGEST_OFFSET]
 mov [rbx+NEBOC_CACHE_CTX_PATH_DIGEST_OFFSET],rax
 mov rax,[r12+NEBOC_CACHE_CONFIG_POLICY_OFFSET]
 mov [rbx+NEBOC_CACHE_CTX_POLICY_OFFSET],rax
 mov rax,[r12+NEBOC_CACHE_CONFIG_CAPABILITY_OFFSET]
 mov [rbx+NEBOC_CACHE_CTX_CAPABILITY_OFFSET],rax
 mov rax,[r12+NEBOC_CACHE_CONFIG_SCHEMA_OFFSET]
 mov [rbx+NEBOC_CACHE_CTX_SCHEMA_OFFSET],rax
 mov qword [rbx+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cache_key_new
 ; rdi=key output, rsi=ordered component digest descriptor.
 test rdi,rdi
 jz .invalid_before_save
 test rsi,rsi
 jz .invalid_before_save
 cmp qword [rsi+NEBOC_CACHE_KEY_INPUT_NAMESPACE_OFFSET],0
 je .invalid_before_save
 cmp qword [rsi+NEBOC_CACHE_KEY_INPUT_SOURCE_OFFSET],0
 je .invalid_before_save
 cmp qword [rsi+NEBOC_CACHE_KEY_INPUT_OPTIONS_OFFSET],0
 je .invalid_before_save
 cmp qword [rsi+NEBOC_CACHE_KEY_INPUT_TARGET_OFFSET],0
 je .invalid_before_save
 cmp qword [rsi+NEBOC_CACHE_KEY_INPUT_ABI_OFFSET],0
 je .invalid_before_save
 cmp qword [rsi+NEBOC_CACHE_KEY_INPUT_COMPILER_OFFSET],0
 je .invalid_before_save
 cmp qword [rsi+NEBOC_CACHE_KEY_INPUT_SCHEMA_OFFSET],NEBOC_CACHE_SCHEMA_VERSION
 jne .invalid_before_save
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 lea rdi,[rbx+8]
 mov rsi,r12
 mov ecx,NEBOC_CACHE_KEY_INPUT_SIZE/8
 rep movsq
 mov rdi,rbx
 call cache_key_digest
 mov [rbx+NEBOC_CACHE_KEY_DIGEST_OFFSET],rax
 xor eax,eax
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cache_store
 ; rdi=cache, rsi=key, rdx=payload, rcx=length, r8=digest, r9=metadata.
 test rdi,rdi
 jz .invalid_before_save
 test rsi,rsi
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 cmp qword [rbx+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rbx+NEBOC_CACHE_CTX_POLICY_OFFSET],NEBOC_CACHE_MODE_READ_WRITE
 jne .invalid
 cmp r14,NEBOC_CACHE_MAX_ARTIFACT_BYTES
 ja .limit
 cmp r14,[rbx+NEBOC_CACHE_CTX_MAX_BYTES_OFFSET]
 ja .limit
 test r14,r14
 jz .payload_ok
 test r13,r13
 jz .invalid
.payload_ok:
 mov rdi,r12
 call cache_key_digest
 cmp rax,[r12+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 jne .invalid
 mov rax,[r12+NEBOC_CACHE_KEY_SCHEMA_OFFSET]
 cmp rax,[rbx+NEBOC_CACHE_CTX_SCHEMA_OFFSET]
 jne .invalid
 mov rdi,r13
 mov rsi,r14
 call cache_payload_digest
 cmp rax,r15
 jne .corrupt_input
 mov rdi,rbx
 mov rsi,r12
 call cache_find
 mov [rsp+8],rax
 test rax,rax
 jnz .space
 mov rcx,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 cmp rcx,[rbx+NEBOC_CACHE_CTX_CAPACITY_OFFSET]
 jae .limit
.space:
 mov rcx,[rbx+NEBOC_CACHE_CTX_USED_BYTES_OFFSET]
 mov rax,[rsp+8]
 test rax,rax
 jz .add_length
 sub rcx,[rax+NEBOC_CACHE_ENTRY_LENGTH_OFFSET]
.add_length:
 add rcx,r14
 jc .limit
 cmp rcx,[rbx+NEBOC_CACHE_CTX_MAX_BYTES_OFFSET]
 ja .limit
 mov [rbx+NEBOC_CACHE_CTX_USED_BYTES_OFFSET],rcx
 mov rdi,[rsp+8]
 test rdi,rdi
 jnz .publish
 mov rax,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 mov rdi,rax
 shl rdi,7
 add rdi,[rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 inc rax
 mov [rbx+NEBOC_CACHE_CTX_COUNT_OFFSET],rax
.publish:
 mov rsi,r12
 mov ecx,NEBOC_CACHE_KEY_SIZE/8
 rep movsq
 mov [rdi+NEBOC_CACHE_ENTRY_PAYLOAD_OFFSET-NEBOC_CACHE_KEY_SIZE],r13
 mov [rdi+NEBOC_CACHE_ENTRY_LENGTH_OFFSET-NEBOC_CACHE_KEY_SIZE],r14
 mov [rdi+NEBOC_CACHE_ENTRY_PAYLOAD_DIGEST_OFFSET-NEBOC_CACHE_KEY_SIZE],r15
 mov rax,[rsp]
 mov [rdi+NEBOC_CACHE_ENTRY_METADATA_DIGEST_OFFSET-NEBOC_CACHE_KEY_SIZE],rax
 mov rax,[rbx+NEBOC_CACHE_CTX_SCHEMA_OFFSET]
 mov [rdi+NEBOC_CACHE_ENTRY_ARTIFACT_SCHEMA_OFFSET-NEBOC_CACHE_KEY_SIZE],rax
 inc qword [rbx+NEBOC_CACHE_CTX_SEQUENCE_OFFSET]
 mov rax,[rbx+NEBOC_CACHE_CTX_SEQUENCE_OFFSET]
 mov [rdi+NEBOC_CACHE_ENTRY_SEQUENCE_OFFSET-NEBOC_CACHE_KEY_SIZE],rax
 mov qword [rdi+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET-NEBOC_CACHE_KEY_SIZE],1
 inc qword [rbx+NEBOC_CACHE_CTX_STORES_OFFSET]
 xor eax,eax
 jmp .done
.corrupt_input:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cache_lookup
 ; rdi=cache, rsi=key, rdx=result. Invalid artifacts are never exposed.
 test rdi,rdi
 jz .invalid_before_save
 test rsi,rsi
 jz .invalid_before_save
 test rdx,rdx
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp qword [rbx+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .invalid
 mov rdi,r12
 call cache_key_digest
 cmp rax,[r12+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 jne .invalid
 cmp qword [rbx+NEBOC_CACHE_CTX_POLICY_OFFSET],NEBOC_CACHE_MODE_OFF
 je .off
 mov rdi,rbx
 mov rsi,r12
 call cache_find
 test rax,rax
 jz .miss
 mov r14,rax
 mov rcx,[r14+NEBOC_CACHE_ENTRY_ARTIFACT_SCHEMA_OFFSET]
 cmp rcx,[rbx+NEBOC_CACHE_CTX_SCHEMA_OFFSET]
 jne .stale
 mov rdi,[r14+NEBOC_CACHE_ENTRY_PAYLOAD_OFFSET]
 mov rsi,[r14+NEBOC_CACHE_ENTRY_LENGTH_OFFSET]
 call cache_payload_digest
 cmp rax,[r14+NEBOC_CACHE_ENTRY_PAYLOAD_DIGEST_OFFSET]
 jne .corrupt
 inc qword [rbx+NEBOC_CACHE_CTX_HITS_OFFSET]
 mov eax,NEBOC_CACHE_LOOKUP_HIT
 jmp .publish_hit
.stale:
 inc qword [rbx+NEBOC_CACHE_CTX_STALE_OFFSET]
 inc qword [rbx+NEBOC_CACHE_CTX_MISSES_OFFSET]
 mov eax,NEBOC_CACHE_LOOKUP_STALE
 jmp .publish_invalid
.corrupt:
 inc qword [rbx+NEBOC_CACHE_CTX_CORRUPT_OFFSET]
 inc qword [rbx+NEBOC_CACHE_CTX_MISSES_OFFSET]
 mov eax,NEBOC_CACHE_LOOKUP_CORRUPT
 jmp .publish_invalid
.miss:
 inc qword [rbx+NEBOC_CACHE_CTX_MISSES_OFFSET]
 mov eax,NEBOC_CACHE_LOOKUP_MISS
 xor r14d,r14d
 jmp .publish_invalid
.off:
 mov eax,NEBOC_CACHE_LOOKUP_OFF
 xor r14d,r14d
.publish_invalid:
 mov [r13+NEBOC_CACHE_RESULT_KIND_OFFSET],rax
 mov qword [r13+NEBOC_CACHE_RESULT_PAYLOAD_OFFSET],0
 mov qword [r13+NEBOC_CACHE_RESULT_LENGTH_OFFSET],0
 mov qword [r13+NEBOC_CACHE_RESULT_METADATA_OFFSET],0
 mov rcx,[r12+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 mov [r13+NEBOC_CACHE_RESULT_KEY_DIGEST_OFFSET],rcx
 xor ecx,ecx
 test r14,r14
 jz .sequence_done
 mov rcx,[r14+NEBOC_CACHE_ENTRY_SEQUENCE_OFFSET]
.sequence_done:
 mov [r13+NEBOC_CACHE_RESULT_SEQUENCE_OFFSET],rcx
 xor eax,eax
 jmp .done
.publish_hit:
 mov [r13+NEBOC_CACHE_RESULT_KIND_OFFSET],rax
 mov rcx,[r14+NEBOC_CACHE_ENTRY_PAYLOAD_OFFSET]
 mov [r13+NEBOC_CACHE_RESULT_PAYLOAD_OFFSET],rcx
 mov rcx,[r14+NEBOC_CACHE_ENTRY_LENGTH_OFFSET]
 mov [r13+NEBOC_CACHE_RESULT_LENGTH_OFFSET],rcx
 mov rcx,[r14+NEBOC_CACHE_ENTRY_METADATA_DIGEST_OFFSET]
 mov [r13+NEBOC_CACHE_RESULT_METADATA_OFFSET],rcx
 mov rcx,[r12+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 mov [r13+NEBOC_CACHE_RESULT_KEY_DIGEST_OFFSET],rcx
 mov rcx,[r14+NEBOC_CACHE_ENTRY_SEQUENCE_OFFSET]
 mov [r13+NEBOC_CACHE_RESULT_SEQUENCE_OFFSET],rcx
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cache_verify
 jmp neboc_cache_lookup

NEBOC_ABI_FUNCTION neboc_cache_invalidate
 ; rdi=cache, rsi=namespace (zero means all), rdx=report.
 test rdi,rdi
 jz .invalid_before_save
 test rdx,rdx
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp qword [rbx+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .invalid
 xor ecx,ecx
.mark:
 cmp rcx,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 jae .compact
 mov rax,rcx
 shl rax,7
 add rax,[rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 test r12,r12
 jz .remove
 cmp [rax+NEBOC_CACHE_KEY_NAMESPACE_OFFSET],r12
 jne .next
.remove:
 mov qword [rax+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],0
.next:
 inc rcx
 jmp .mark
.compact:
 mov rdi,rbx
 call cache_compact
 add [rbx+NEBOC_CACHE_CTX_INVALIDATIONS_OFFSET],rax
 mov [r13+NEBOC_CACHE_MUTATION_REMOVED_OFFSET],rax
 mov [r13+NEBOC_CACHE_MUTATION_BYTES_OFFSET],rdx
 mov rcx,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 mov [r13+NEBOC_CACHE_MUTATION_REMAINING_OFFSET],rcx
 mov rcx,[rbx+NEBOC_CACHE_CTX_USED_BYTES_OFFSET]
 mov [r13+NEBOC_CACHE_MUTATION_REMAINING_BYTES_OFFSET],rcx
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cache_prune
 ; rdi=cache, rsi=max bytes, rdx=max items, rcx=min sequence, r8=report.
 test rdi,rdi
 jz .invalid_before_save
 test r8,r8
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov qword [rsp],0
 mov qword [rsp+8],0
 cmp qword [rbx+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .invalid
 cmp r12,[rbx+NEBOC_CACHE_CTX_MAX_BYTES_OFFSET]
 ja .invalid
 cmp r13,[rbx+NEBOC_CACHE_CTX_CAPACITY_OFFSET]
 ja .invalid
 test r14,r14
 jz .compact_age
 xor ecx,ecx
.age_mark:
 cmp rcx,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 jae .compact_age
 mov rax,rcx
 shl rax,7
 add rax,[rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 cmp [rax+NEBOC_CACHE_ENTRY_SEQUENCE_OFFSET],r14
 jae .age_next
 mov qword [rax+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],0
.age_next:
 inc rcx
 jmp .age_mark
.compact_age:
 mov rdi,rbx
 call cache_compact
 add [rsp],rax
 add [rsp+8],rdx
.budget_loop:
 mov rax,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 cmp rax,r13
 ja .evict_first
 mov rax,[rbx+NEBOC_CACHE_CTX_USED_BYTES_OFFSET]
 cmp rax,r12
 jbe .report
.evict_first:
 cmp qword [rbx+NEBOC_CACHE_CTX_COUNT_OFFSET],0
 je .report
 mov rax,[rbx+NEBOC_CACHE_CTX_ENTRIES_OFFSET]
 mov qword [rax+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],0
 mov rdi,rbx
 call cache_compact
 add [rsp],rax
 add [rsp+8],rdx
 jmp .budget_loop
.report:
 mov rax,[rsp]
 add [rbx+NEBOC_CACHE_CTX_EVICTIONS_OFFSET],rax
 mov [r15+NEBOC_CACHE_MUTATION_REMOVED_OFFSET],rax
 mov rax,[rsp+8]
 mov [r15+NEBOC_CACHE_MUTATION_BYTES_OFFSET],rax
 mov rax,[rbx+NEBOC_CACHE_CTX_COUNT_OFFSET]
 mov [r15+NEBOC_CACHE_MUTATION_REMAINING_OFFSET],rax
 mov rax,[rbx+NEBOC_CACHE_CTX_USED_BYTES_OFFSET]
 mov [r15+NEBOC_CACHE_MUTATION_REMAINING_BYTES_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cache_stats
 ; rdi=cache, rsi=stats.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_CACHE_CTX_HITS_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_HITS_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_MISSES_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_MISSES_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_COUNT_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_ENTRIES_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_USED_BYTES_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_BYTES_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_CORRUPT_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_CORRUPTIONS_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_STALE_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_STALE_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_EVICTIONS_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_EVICTIONS_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_INVALIDATIONS_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_INVALIDATIONS_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_STORES_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_STORES_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_POLICY_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_POLICY_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_CAPACITY_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_CAPACITY_OFFSET],rax
 mov rax,[rdi+NEBOC_CACHE_CTX_MAX_BYTES_OFFSET]
 mov [rsi+NEBOC_CACHE_STATS_MAX_BYTES_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cache_explain
 ; rdi=cache, rsi=key, rdx=explanation.
 test rdi,rdi
 jz .invalid_before_save
 test rsi,rsi
 jz .invalid_before_save
 test rdx,rdx
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp qword [rbx+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .invalid
 mov rdi,r12
 call cache_key_digest
 cmp rax,[r12+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 jne .invalid
 cmp qword [rbx+NEBOC_CACHE_CTX_POLICY_OFFSET],NEBOC_CACHE_MODE_OFF
 je .reason_off
 mov rdi,rbx
 mov rsi,r12
 call cache_find
 test rax,rax
 jz .reason_miss
 mov r14,rax
 mov rcx,[r14+NEBOC_CACHE_ENTRY_ARTIFACT_SCHEMA_OFFSET]
 cmp rcx,[rbx+NEBOC_CACHE_CTX_SCHEMA_OFFSET]
 jne .reason_stale
 mov rdi,[r14+NEBOC_CACHE_ENTRY_PAYLOAD_OFFSET]
 mov rsi,[r14+NEBOC_CACHE_ENTRY_LENGTH_OFFSET]
 call cache_payload_digest
 cmp rax,[r14+NEBOC_CACHE_ENTRY_PAYLOAD_DIGEST_OFFSET]
 jne .reason_corrupt
 mov eax,NEBOC_CACHE_LOOKUP_HIT
 jmp .publish
.reason_off:
 mov eax,NEBOC_CACHE_LOOKUP_OFF
 jmp .publish
.reason_miss:
 mov eax,NEBOC_CACHE_LOOKUP_MISS
 jmp .publish
.reason_stale:
 mov eax,NEBOC_CACHE_LOOKUP_STALE
 jmp .publish
.reason_corrupt:
 mov eax,NEBOC_CACHE_LOOKUP_CORRUPT
.publish:
 mov [r13+NEBOC_CACHE_EXPLAIN_REASON_OFFSET],rax
 mov rcx,[r12+NEBOC_CACHE_KEY_DIGEST_OFFSET]
 mov [r13+NEBOC_CACHE_EXPLAIN_DIGEST_OFFSET],rcx
 mov ecx,1
.copy:
 cmp ecx,8
 jae .success
 mov rax,[r12+rcx*8]
 mov [r13+8+rcx*8],rax
 inc ecx
 jmp .copy
.success:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_cache_admin
 ; rdi=cache, rsi=operation, rdx=argument, r8=output.
 cmp rsi,NEBOC_CACHE_ADMIN_STATS
 je .stats
 cmp rsi,NEBOC_CACHE_ADMIN_VERIFY
 je .verify
 cmp rsi,NEBOC_CACHE_ADMIN_PRUNE
 je .prune
 cmp rsi,NEBOC_CACHE_ADMIN_CLEAR
 je .clear
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.stats:
 mov rsi,r8
 jmp neboc_cache_stats
.verify:
 mov rsi,rdx
 mov rdx,r8
 jmp neboc_cache_verify
.prune:
 test rdx,rdx
 jz .invalid
 mov rax,[rdx+NEBOC_CACHE_PRUNE_REQUEST_MIN_SEQUENCE_OFFSET]
 mov rcx,rax
 mov rsi,[rdx+NEBOC_CACHE_PRUNE_REQUEST_MAX_BYTES_OFFSET]
 mov rdx,[rdx+NEBOC_CACHE_PRUNE_REQUEST_MAX_ITEMS_OFFSET]
 jmp neboc_cache_prune
.clear:
 xor esi,esi
 mov rdx,r8
 jmp neboc_cache_invalidate
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_build_cache_mode
 ; rdi=cache, rsi=off/read/read-write.
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_CACHE_CTX_ACTIVE_OFFSET],1
 jne .invalid
 cmp rsi,NEBOC_CACHE_MODE_READ_WRITE
 ja .invalid
 mov [rdi+NEBOC_CACHE_CTX_POLICY_OFFSET],rsi
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_cache_explain
 jmp neboc_cache_explain
