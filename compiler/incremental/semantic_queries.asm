; SEMANTIC-QUERIES-F04 bounded deterministic semantic query database.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/incremental/semantic_queries.inc"

section .text

; Internal: rdi=db, rsi=key. Returns entry pointer or zero.
query_find:
 xor ecx,ecx
 mov r8,[rdi+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
.loop:
 cmp rcx,r8
 jae .missing
 mov rax,rcx
 shl rax,6
 add rax,rdi
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 cmp [rax+NEBOC_QUERY_ENTRY_KEY_OFFSET],rsi
 je .done
 inc rcx
 jmp .loop
.missing:
 xor eax,eax
.done:
 ret

NEBOC_ABI_FUNCTION neboc_query_database_new
 ; rdi=db, rsi=revision, rdx=query limit, rcx=edge limit.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_QUERY_MAX_ENTRIES
 ja .limit
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBOC_QUERY_MAX_EDGES
 ja .limit
 mov r8,rdi
 mov r9,rsi
 mov r10,rdx
 mov r11,rcx
 xor eax,eax
 mov ecx,NEBOC_QUERY_DB_SIZE/8
 rep stosq
 mov [r8+NEBOC_QUERY_DB_REVISION_OFFSET],r9
 mov [r8+NEBOC_QUERY_DB_LIMIT_ENTRIES_OFFSET],r10
 mov [r8+NEBOC_QUERY_DB_LIMIT_EDGES_OFFSET],r11
 mov qword [r8+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_query_db_execute
 ; rdi=db, rsi=canonical key, rdx=bounded provider descriptor.
 test rdi,rdi
 jz .invalid_before_save
 test rsi,rsi
 jz .invalid_before_save
 test rdx,rdx
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp qword [rbx+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[r13+NEBOC_QUERY_PROVIDER_REVISION_OFFSET]
 cmp rax,[rbx+NEBOC_QUERY_DB_REVISION_OFFSET]
 jne .stale
 test qword [r13+NEBOC_QUERY_PROVIDER_CLASS_OFFSET],-1
 jz .invalid
 mov rdi,rbx
 mov rsi,r12
 call query_find
 test rax,rax
 jz .new_entry
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_EXECUTING
 je .cycle
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 jne .recompute
 mov rcx,[rax+NEBOC_QUERY_ENTRY_INPUT_DIGEST_OFFSET]
 cmp rcx,[r13+NEBOC_QUERY_PROVIDER_INPUT_DIGEST_OFFSET]
 jne .recompute
 mov rcx,[rax+NEBOC_QUERY_ENTRY_CLASS_OFFSET]
 cmp rcx,[r13+NEBOC_QUERY_PROVIDER_CLASS_OFFSET]
 jne .recompute
 mov rcx,[rax+NEBOC_QUERY_ENTRY_REVISION_OFFSET]
 cmp rcx,[rbx+NEBOC_QUERY_DB_REVISION_OFFSET]
 jne .stale
 inc qword [rbx+NEBOC_QUERY_DB_HITS_OFFSET]
 inc qword [rax+NEBOC_QUERY_ENTRY_HITS_OFFSET]
 xor eax,eax
 jmp .done
.new_entry:
 mov rcx,[rbx+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 cmp rcx,[rbx+NEBOC_QUERY_DB_LIMIT_ENTRIES_OFFSET]
 jae .limit
 mov rax,rcx
 shl rax,6
 add rax,rbx
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 inc qword [rbx+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 inc qword [rbx+NEBOC_QUERY_DB_MISSES_OFFSET]
 jmp .publish
.recompute:
 inc qword [rax+NEBOC_QUERY_ENTRY_RECOMPUTES_OFFSET]
.publish:
 inc qword [rbx+NEBOC_QUERY_DB_RECOMPUTES_OFFSET]
 mov qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_EXECUTING
 mov [rax+NEBOC_QUERY_ENTRY_KEY_OFFSET],r12
 mov rcx,[r13+NEBOC_QUERY_PROVIDER_INPUT_DIGEST_OFFSET]
 mov [rax+NEBOC_QUERY_ENTRY_INPUT_DIGEST_OFFSET],rcx
 mov rcx,[r13+NEBOC_QUERY_PROVIDER_RESULT_DIGEST_OFFSET]
 mov [rax+NEBOC_QUERY_ENTRY_RESULT_DIGEST_OFFSET],rcx
 mov rcx,[rbx+NEBOC_QUERY_DB_REVISION_OFFSET]
 mov [rax+NEBOC_QUERY_ENTRY_REVISION_OFFSET],rcx
 mov rcx,[r13+NEBOC_QUERY_PROVIDER_CLASS_OFFSET]
 mov [rax+NEBOC_QUERY_ENTRY_CLASS_OFFSET],rcx
 mov qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 xor eax,eax
 jmp .done
.cycle:
 inc qword [rbx+NEBOC_QUERY_DB_CYCLES_OFFSET]
 mov [rbx+NEBOC_QUERY_DB_CYCLE_KEY_OFFSET],r12
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
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

NEBOC_ABI_FUNCTION neboc_query_db_record_dependency
 ; rdi=db, rsi=parent, rdx=child. Parent depends on child.
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
 push r15
 sub rsp,NEBOC_QUERY_MAX_ENTRIES*8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp qword [rbx+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,r12
 call query_find
 test rax,rax
 jz .invalid
 mov rdi,rbx
 mov rsi,r13
 call query_find
 test rax,rax
 jz .invalid
 xor ecx,ecx
.duplicate_loop:
 cmp rcx,[rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 jae .capacity
 mov rax,rcx
 shl rax,4
 add rax,rbx
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 cmp [rax+NEBOC_QUERY_EDGE_PARENT_OFFSET],r12
 jne .duplicate_next
 cmp [rax+NEBOC_QUERY_EDGE_CHILD_OFFSET],r13
 je .success
.duplicate_next:
 inc rcx
 jmp .duplicate_loop
.capacity:
 mov rax,[rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 cmp rax,[rbx+NEBOC_QUERY_DB_LIMIT_EDGES_OFFSET]
 jae .limit
 mov [rsp],r13
 mov r14d,1
 xor r15d,r15d
.bfs:
 cmp r15,r14
 jae .add_edge
 mov rdx,[rsp+r15*8]
 cmp rdx,r12
 je .cycle
 xor ecx,ecx
.edge_scan:
 cmp rcx,[rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 jae .bfs_next
 mov rax,rcx
 shl rax,4
 add rax,rbx
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 cmp [rax+NEBOC_QUERY_EDGE_PARENT_OFFSET],rdx
 jne .edge_next
 mov r9,[rax+NEBOC_QUERY_EDGE_CHILD_OFFSET]
 xor r10d,r10d
.visited:
 cmp r10,r14
 jae .enqueue
 cmp [rsp+r10*8],r9
 je .edge_next
 inc r10
 jmp .visited
.enqueue:
 cmp r14,NEBOC_QUERY_MAX_ENTRIES
 jae .limit
 mov [rsp+r14*8],r9
 inc r14
.edge_next:
 inc rcx
 jmp .edge_scan
.bfs_next:
 inc r15
 jmp .bfs
.add_edge:
 mov rax,[rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 mov rcx,rax
 shl rax,4
 add rax,rbx
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 mov [rax+NEBOC_QUERY_EDGE_PARENT_OFFSET],r12
 mov [rax+NEBOC_QUERY_EDGE_CHILD_OFFSET],r13
 inc rcx
 mov [rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET],rcx
.success:
 xor eax,eax
 jmp .done
.cycle:
 inc qword [rbx+NEBOC_QUERY_DB_CYCLES_OFFSET]
 mov [rbx+NEBOC_QUERY_DB_CYCLE_KEY_OFFSET],r12
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,NEBOC_QUERY_MAX_ENTRIES*8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_query_db_invalidate
 ; rdi=db, rsi=input key, rdx=strictly newer revision.
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
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp qword [rbx+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 cmp r13,[rbx+NEBOC_QUERY_DB_REVISION_OFFSET]
 jbe .stale
 xor ecx,ecx
.executing_scan:
 cmp rcx,[rbx+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 jae .find_input
 mov rax,rcx
 shl rax,6
 add rax,rbx
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_EXECUTING
 je .stale
 inc rcx
 jmp .executing_scan
.find_input:
 mov rdi,rbx
 mov rsi,r12
 call query_find
 test rax,rax
 jz .invalid
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_INVALID
 je .propagate
 mov qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_INVALID
 inc qword [rbx+NEBOC_QUERY_DB_INVALIDATIONS_OFFSET]
.propagate:
 mov r15d,1
.closure:
 test r15,r15
 jz .advance_revision
 xor r15d,r15d
 xor r14d,r14d
.closure_edge:
 cmp r14,[rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 jae .closure
 mov rax,r14
 shl rax,4
 add rax,rbx
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 mov rcx,[rax+NEBOC_QUERY_EDGE_PARENT_OFFSET]
 mov [rsp],rcx
 mov rcx,[rax+NEBOC_QUERY_EDGE_CHILD_OFFSET]
 mov [rsp+8],rcx
 mov rdi,rbx
 mov rsi,[rsp+8]
 call query_find
 test rax,rax
 jz .closure_next
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_INVALID
 jne .closure_next
 mov rdi,rbx
 mov rsi,[rsp]
 call query_find
 test rax,rax
 jz .closure_next
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 jne .closure_next
 mov qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_INVALID
 inc qword [rbx+NEBOC_QUERY_DB_INVALIDATIONS_OFFSET]
 mov r15d,1
.closure_next:
 inc r14
 jmp .closure_edge
.advance_revision:
 mov [rbx+NEBOC_QUERY_DB_REVISION_OFFSET],r13
 xor ecx,ecx
.revision_loop:
 cmp rcx,[rbx+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 jae .success
 mov rax,rcx
 shl rax,6
 add rax,rbx
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 jne .revision_next
 mov [rax+NEBOC_QUERY_ENTRY_REVISION_OFFSET],r13
.revision_next:
 inc rcx
 jmp .revision_loop
.success:
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
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

NEBOC_ABI_FUNCTION neboc_query_db_cycle_report
 ; rdi=db, rsi=key (zero means latest), rdx=report.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_QUERY_DB_CYCLE_KEY_OFFSET]
 test rsi,rsi
 jz .key_ok
 cmp rsi,rax
 jne .not_detected
.key_ok:
 mov [rdx+NEBOC_QUERY_CYCLE_KEY_OFFSET],rax
 mov rcx,[rdi+NEBOC_QUERY_DB_CYCLES_OFFSET]
 mov [rdx+NEBOC_QUERY_CYCLE_COUNT_OFFSET],rcx
 xor r8d,r8d
 test rcx,rcx
 setnz r8b
 mov [rdx+NEBOC_QUERY_CYCLE_DETECTED_OFFSET],r8
 xor eax,eax
 ret
.not_detected:
 mov [rdx+NEBOC_QUERY_CYCLE_KEY_OFFSET],rsi
 mov rcx,[rdi+NEBOC_QUERY_DB_CYCLES_OFFSET]
 mov [rdx+NEBOC_QUERY_CYCLE_COUNT_OFFSET],rcx
 mov qword [rdx+NEBOC_QUERY_CYCLE_DETECTED_OFFSET],0
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_query_db_result_digest
 ; rdi=db, rsi=key, rdx=caller-owned digest output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 push rdx
 call query_find
 pop rdx
 test rax,rax
 jz .invalid
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 jne .stale
 mov rcx,[rax+NEBOC_QUERY_ENTRY_REVISION_OFFSET]
 cmp rcx,[rdi+NEBOC_QUERY_DB_REVISION_OFFSET]
 jne .stale
 mov rcx,[rax+NEBOC_QUERY_ENTRY_RESULT_DIGEST_OFFSET]
 mov [rdx],rcx
 xor eax,eax
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_query_db_reuse_report
 ; rdi=db, rsi=report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_QUERY_DB_HITS_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_HITS_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_MISSES_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_MISSES_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_RECOMPUTES_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_RECOMPUTES_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_INVALIDATIONS_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_INVALIDATIONS_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_CYCLES_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_CYCLES_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_ENTRIES_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_EDGES_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_REVISION_OFFSET]
 mov [rsi+NEBOC_QUERY_REPORT_REVISION_OFFSET],rax
 xor r8d,r8d
 xor r9d,r9d
 xor ecx,ecx
.hot_loop:
 cmp rcx,[rdi+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 jae .hot_done
 mov rax,rcx
 shl rax,6
 add rax,rdi
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 mov r10,[rax+NEBOC_QUERY_ENTRY_HITS_OFFSET]
 cmp r10,r9
 ja .hot_take
 jne .hot_next
 test r10,r10
 jz .hot_next
 mov r11,[rax+NEBOC_QUERY_ENTRY_KEY_OFFSET]
 cmp r11,r8
 jae .hot_next
.hot_take:
 mov r9,r10
 mov r8,[rax+NEBOC_QUERY_ENTRY_KEY_OFFSET]
.hot_next:
 inc rcx
 jmp .hot_loop
.hot_done:
 mov [rsi+NEBOC_QUERY_REPORT_HOT_KEY_OFFSET],r8
 mov [rsi+NEBOC_QUERY_REPORT_HOT_HITS_OFFSET],r9
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_query_db_verify_against_cold
 ; rdi=db, rsi=keys, rdx=cold digests, rcx=count, r8=report.
 test rdi,rdi
 jz .invalid_before_save
 test r8,r8
 jz .invalid_before_save
 cmp rcx,NEBOC_QUERY_MAX_ENTRIES
 ja .limit_before_save
 test rcx,rcx
 jz .pointers_ok
 test rsi,rsi
 jz .invalid_before_save
 test rdx,rdx
 jz .invalid_before_save
.pointers_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp qword [rbx+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 mov [r15+NEBOC_QUERY_VERIFY_CHECKED_OFFSET],r14
 mov qword [r15+NEBOC_QUERY_VERIFY_MISMATCHES_OFFSET],0
 mov qword [r15+NEBOC_QUERY_VERIFY_FIRST_KEY_OFFSET],0
 xor r10d,r10d
.loop:
 cmp r10,r14
 jae .success
 mov rsi,[r12+r10*8]
 mov rdi,rbx
 call query_find
 test rax,rax
 jz .mismatch
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 jne .mismatch
 mov rcx,[rax+NEBOC_QUERY_ENTRY_REVISION_OFFSET]
 cmp rcx,[rbx+NEBOC_QUERY_DB_REVISION_OFFSET]
 jne .mismatch
 mov rcx,[rax+NEBOC_QUERY_ENTRY_RESULT_DIGEST_OFFSET]
 cmp rcx,[r13+r10*8]
 je .next
.mismatch:
 cmp qword [r15+NEBOC_QUERY_VERIFY_MISMATCHES_OFFSET],0
 jne .count_mismatch
 mov rcx,[r12+r10*8]
 mov [r15+NEBOC_QUERY_VERIFY_FIRST_KEY_OFFSET],rcx
.count_mismatch:
 inc qword [r15+NEBOC_QUERY_VERIFY_MISMATCHES_OFFSET]
.next:
 inc r10
 jmp .loop
.success:
 xor eax,eax
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
.limit_before_save:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_query_db_prune
 ; rdi=db, rsi=minimum retained revision, rdx=report.
 test rdi,rdi
 jz .invalid_before_save
 test rdx,rdx
 jz .invalid_before_save
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov [rsp],rsi
 mov [rsp+8],rdx
 cmp qword [rbx+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 cmp rsi,[rbx+NEBOC_QUERY_DB_REVISION_OFFSET]
 ja .invalid
 mov r15,[rbx+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 xor r12d,r12d
 xor r13d,r13d
.entry_loop:
 cmp r12,r15
 jae .entries_done
 mov rax,r12
 shl rax,6
 add rax,rbx
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 jne .entry_next
 mov rcx,[rax+NEBOC_QUERY_ENTRY_REVISION_OFFSET]
 cmp rcx,[rsp]
 jb .entry_next
 cmp r12,r13
 je .kept
 mov rsi,rax
 mov rdi,r13
 shl rdi,6
 add rdi,rbx
 add rdi,NEBOC_QUERY_DB_ENTRIES_OFFSET
 mov ecx,NEBOC_QUERY_ENTRY_SIZE/8
 rep movsq
.kept:
 inc r13
.entry_next:
 inc r12
 jmp .entry_loop
.entries_done:
 mov [rsp+16],r15
 mov [rbx+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET],r13
 mov r14,r13
.zero_entries:
 cmp r14,r15
 jae .edge_prepare
 mov rdi,r14
 shl rdi,6
 add rdi,rbx
 add rdi,NEBOC_QUERY_DB_ENTRIES_OFFSET
 xor eax,eax
 mov ecx,NEBOC_QUERY_ENTRY_SIZE/8
 rep stosq
 inc r14
 jmp .zero_entries
.edge_prepare:
 mov r15,[rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 xor r12d,r12d
 xor r13d,r13d
.edge_loop:
 cmp r12,r15
 jae .edges_done
 mov rax,r12
 shl rax,4
 add rax,rbx
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 mov rcx,[rax+NEBOC_QUERY_EDGE_PARENT_OFFSET]
 mov [rsp+24],rcx
 mov rcx,[rax+NEBOC_QUERY_EDGE_CHILD_OFFSET]
 mov [rsp+32],rcx
 mov rdi,rbx
 mov rsi,[rsp+24]
 call query_find
 test rax,rax
 jz .edge_next
 mov rdi,rbx
 mov rsi,[rsp+32]
 call query_find
 test rax,rax
 jz .edge_next
 cmp r12,r13
 je .edge_kept
 mov rax,r13
 shl rax,4
 add rax,rbx
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 mov rcx,[rsp+24]
 mov [rax+NEBOC_QUERY_EDGE_PARENT_OFFSET],rcx
 mov rcx,[rsp+32]
 mov [rax+NEBOC_QUERY_EDGE_CHILD_OFFSET],rcx
.edge_kept:
 inc r13
.edge_next:
 inc r12
 jmp .edge_loop
.edges_done:
 mov [rbx+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET],r13
 mov r14,r13
.zero_edges:
 cmp r14,r15
 jae .report
 mov rax,r14
 shl rax,4
 add rax,rbx
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 mov qword [rax],0
 mov qword [rax+8],0
 inc r14
 jmp .zero_edges
.report:
 mov rdx,[rsp+8]
 mov rax,[rbx+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 mov [rdx+NEBOC_QUERY_PRUNE_RETAINED_OFFSET],rax
 mov rcx,[rsp]
 mov [rdx+NEBOC_QUERY_PRUNE_REVISION_OFFSET],rcx
 mov rcx,[rsp+16]
 sub rcx,rax
 mov [rdx+NEBOC_QUERY_PRUNE_REMOVED_OFFSET],rcx
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_semantic_snapshot_freeze
 ; rdi=db, rsi=caller-owned snapshot. Refuses mixed/invalid revisions.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_QUERY_DB_ACTIVE_OFFSET],1
 jne .invalid
 xor ecx,ecx
.validate:
 cmp rcx,[rdi+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 jae .digest
 mov rax,rcx
 shl rax,6
 add rax,rdi
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 cmp qword [rax+NEBOC_QUERY_ENTRY_STATE_OFFSET],NEBOC_QUERY_STATE_VALID
 jne .stale
 mov rdx,[rax+NEBOC_QUERY_ENTRY_REVISION_OFFSET]
 cmp rdx,[rdi+NEBOC_QUERY_DB_REVISION_OFFSET]
 jne .stale
 inc rcx
 jmp .validate
.digest:
 mov r8,0xcbf29ce484222325
 xor ecx,ecx
.entry_digest:
 cmp rcx,[rdi+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 jae .edge_digest_prepare
 mov rax,rcx
 shl rax,6
 add rax,rdi
 add rax,NEBOC_QUERY_DB_ENTRIES_OFFSET
 mov rdx,[rax+NEBOC_QUERY_ENTRY_KEY_OFFSET]
 xor rdx,[rax+NEBOC_QUERY_ENTRY_INPUT_DIGEST_OFFSET]
 rol rdx,13
 xor rdx,[rax+NEBOC_QUERY_ENTRY_RESULT_DIGEST_OFFSET]
 rol rdx,17
 xor rdx,[rax+NEBOC_QUERY_ENTRY_CLASS_OFFSET]
 rol rdx,11
 add r8,rdx
 inc rcx
 jmp .entry_digest
.edge_digest_prepare:
 xor ecx,ecx
.edge_digest:
 cmp rcx,[rdi+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 jae .publish
 mov rax,rcx
 shl rax,4
 add rax,rdi
 add rax,NEBOC_QUERY_DB_EDGES_OFFSET
 mov rdx,[rax+NEBOC_QUERY_EDGE_PARENT_OFFSET]
 rol rdx,7
 xor rdx,[rax+NEBOC_QUERY_EDGE_CHILD_OFFSET]
 rol rdx,19
 add r8,rdx
 inc rcx
 jmp .edge_digest
.publish:
 mov rax,[rdi+NEBOC_QUERY_DB_REVISION_OFFSET]
 xor r8,rax
 mov rax,[rdi+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 rol rax,23
 xor r8,rax
 mov rax,[rdi+NEBOC_QUERY_DB_REVISION_OFFSET]
 mov [rsi+NEBOC_SEMANTIC_SNAPSHOT_REVISION_OFFSET],rax
 mov rax,[rdi+NEBOC_QUERY_DB_ENTRY_COUNT_OFFSET]
 mov [rsi+NEBOC_SEMANTIC_SNAPSHOT_QUERY_COUNT_OFFSET],rax
 mov [rsi+NEBOC_SEMANTIC_SNAPSHOT_DIGEST_OFFSET],r8
 mov rax,[rdi+NEBOC_QUERY_DB_EDGE_COUNT_OFFSET]
 mov [rsi+NEBOC_SEMANTIC_SNAPSHOT_EDGE_COUNT_OFFSET],rax
 mov qword [rsi+NEBOC_SEMANTIC_SNAPSHOT_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_query_report
 ; Bounded report backend only; project traversal remains outside this ABI.
 jmp neboc_query_db_reuse_report
