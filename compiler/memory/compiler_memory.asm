; COMPILER-MEMORY-F02 bounded caller-owned arenas, interning and memory budgets.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/memory/compiler_memory.inc"

section .text
NEBOC_ABI_FUNCTION neboc_compiler_arena_new
 ; rdi=context, rsi=backing bytes, rdx=capacity, rcx=policy, r8=session id.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_MEMORY_MAX_ARENA_BYTES
 ja .limit
 cmp rcx,NEBOC_ARENA_POLICY_PHASE
 jb .invalid
 cmp rcx,NEBOC_ARENA_POLICY_SESSION
 ja .invalid
 test r8,r8
 jz .invalid
 mov rax,rsi
 add rax,rdx
 jc .invalid
 mov [rdi+neboc_compiler_memory_ARENA_BASE_OFFSET],rsi
 mov [rdi+neboc_compiler_memory_ARENA_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_ARENA_USED_OFFSET],0
 mov qword [rdi+neboc_compiler_memory_ARENA_HIGH_WATER_OFFSET],0
 mov qword [rdi+NEBOC_ARENA_ALLOCATIONS_OFFSET],0
 mov qword [rdi+neboc_compiler_memory_ARENA_GENERATION_OFFSET],1
 mov qword [rdi+NEBOC_ARENA_BORROW_COUNT_OFFSET],0
 mov [rdi+NEBOC_ARENA_POLICY_OFFSET],rcx
 mov [rdi+NEBOC_ARENA_SESSION_OFFSET],r8
 mov qword [rdi+NEBOC_COMPILER_MEMORY_ARENA_ACTIVE_OFFSET],1
 mov qword [rdi+NEBOC_ARENA_ALIGNMENT_WASTE_OFFSET],0
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_allocate
 ; rdi=context, rsi=layout {size,alignment}, rdx=pointer output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rdi+NEBOC_COMPILER_MEMORY_ARENA_ACTIVE_OFFSET],1
 jne .invalid
 mov r8,[rsi+neboc_compiler_memory_LAYOUT_SIZE_OFFSET]
 test r8,r8
 jz .invalid
 mov r9,[rsi+neboc_compiler_memory_LAYOUT_ALIGNMENT_OFFSET]
 test r9,r9
 jz .invalid
 cmp r9,NEBOC_MEMORY_MAX_ALIGNMENT
 ja .limit
 lea r10,[r9-1]
 test r9,r10
 jnz .invalid
 mov rax,[rdi+neboc_compiler_memory_ARENA_BASE_OFFSET]
 add rax,[rdi+NEBOC_ARENA_USED_OFFSET]
 jc .oom
 mov r11,rax
 add rax,r10
 jc .oom
 not r10
 and rax,r10
 mov r9,rax
 add rax,r8
 jc .oom
 mov r8,[rdi+neboc_compiler_memory_ARENA_BASE_OFFSET]
 mov r10,r8
 add r10,[rdi+neboc_compiler_memory_ARENA_CAPACITY_OFFSET]
 jc .invalid
 cmp rax,r10
 ja .oom
 sub rax,r8
 sub r9,r11
 mov r10,[rdi+NEBOC_ARENA_ALIGNMENT_WASTE_OFFSET]
 add r10,r9
 jc .oom
 mov r9,[rdi+neboc_compiler_memory_ARENA_BASE_OFFSET]
 add r9,rax
 sub r9,[rsi+neboc_compiler_memory_LAYOUT_SIZE_OFFSET]
 mov [rdx],r9
 mov [rdi+NEBOC_ARENA_USED_OFFSET],rax
 cmp rax,[rdi+neboc_compiler_memory_ARENA_HIGH_WATER_OFFSET]
 jbe .high_water_done
 mov [rdi+neboc_compiler_memory_ARENA_HIGH_WATER_OFFSET],rax
.high_water_done:
 inc qword [rdi+NEBOC_ARENA_ALLOCATIONS_OFFSET]
 mov [rdi+NEBOC_ARENA_ALIGNMENT_WASTE_OFFSET],r10
 xor eax,eax
 ret
.oom:
 mov eax,NEBOC_STATUS_OUT_OF_MEMORY
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_mark
 ; rdi=context, rsi=mark output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_COMPILER_MEMORY_ARENA_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_ARENA_USED_OFFSET]
 mov [rsi+NEBOC_ARENA_MARK_USED_OFFSET],rax
 mov rax,[rdi+neboc_compiler_memory_ARENA_GENERATION_OFFSET]
 mov [rsi+NEBOC_COMPILER_MEMORY_ARENA_MARK_GENERATION_OFFSET],rax
 mov rax,[rdi+NEBOC_ARENA_ALLOCATIONS_OFFSET]
 mov [rsi+NEBOC_ARENA_MARK_ALLOCATIONS_OFFSET],rax
 mov rax,[rdi+NEBOC_ARENA_ALIGNMENT_WASTE_OFFSET]
 mov [rsi+NEBOC_ARENA_MARK_WASTE_OFFSET],rax
 mov rax,[rdi+NEBOC_ARENA_SESSION_OFFSET]
 mov [rsi+NEBOC_ARENA_MARK_SESSION_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_reset
 ; rdi=context, rsi=previous mark. Reset is blocked while borrows are live.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_COMPILER_MEMORY_ARENA_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rdi+NEBOC_ARENA_BORROW_COUNT_OFFSET],0
 jne .invalid
 mov rax,[rsi+NEBOC_ARENA_MARK_SESSION_OFFSET]
 cmp rax,[rdi+NEBOC_ARENA_SESSION_OFFSET]
 jne .invalid
 mov rax,[rsi+NEBOC_COMPILER_MEMORY_ARENA_MARK_GENERATION_OFFSET]
 cmp rax,[rdi+neboc_compiler_memory_ARENA_GENERATION_OFFSET]
 jne .invalid
 mov rax,[rsi+NEBOC_ARENA_MARK_USED_OFFSET]
 cmp rax,[rdi+NEBOC_ARENA_USED_OFFSET]
 ja .invalid
 mov rdx,[rsi+NEBOC_ARENA_MARK_ALLOCATIONS_OFFSET]
 cmp rdx,[rdi+NEBOC_ARENA_ALLOCATIONS_OFFSET]
 ja .invalid
 mov rcx,[rsi+NEBOC_ARENA_MARK_WASTE_OFFSET]
 cmp rcx,[rdi+NEBOC_ARENA_ALIGNMENT_WASTE_OFFSET]
 ja .invalid
 cmp qword [rdi+neboc_compiler_memory_ARENA_GENERATION_OFFSET],-1
 je .limit
 mov [rdi+NEBOC_ARENA_USED_OFFSET],rax
 mov [rdi+NEBOC_ARENA_ALLOCATIONS_OFFSET],rdx
 mov [rdi+NEBOC_ARENA_ALIGNMENT_WASTE_OFFSET],rcx
 inc qword [rdi+neboc_compiler_memory_ARENA_GENERATION_OFFSET]
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_arena_stats
 ; rdi=context, rsi=statistics output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_COMPILER_MEMORY_ARENA_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_ARENA_USED_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_USED_OFFSET],rax
 mov rax,[rdi+neboc_compiler_memory_ARENA_CAPACITY_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_RESERVED_OFFSET],rax
 mov rax,[rdi+neboc_compiler_memory_ARENA_HIGH_WATER_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_HIGH_WATER_OFFSET],rax
 mov rax,[rdi+NEBOC_ARENA_ALIGNMENT_WASTE_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_FRAGMENTATION_OFFSET],rax
 mov rax,[rdi+NEBOC_ARENA_ALLOCATIONS_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_ALLOCATIONS_OFFSET],rax
 mov rax,[rdi+neboc_compiler_memory_ARENA_GENERATION_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_GENERATION_OFFSET],rax
 mov rax,[rdi+NEBOC_ARENA_BORROW_COUNT_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_BORROWS_OFFSET],rax
 mov rax,[rdi+NEBOC_ARENA_SESSION_OFFSET]
 mov [rsi+NEBOC_ARENA_STATS_SESSION_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_intern_pool_new
 ; rdi=context, rsi=config with caller-owned entries and payload.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rsi+NEBOC_INTERN_CONFIG_ENTRIES_OFFSET]
 test rax,rax
 jz .invalid
 mov rdx,[rsi+NEBOC_INTERN_CONFIG_MAX_ENTRIES_OFFSET]
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_MEMORY_MAX_INTERN_ENTRIES
 ja .limit
 mov rcx,[rsi+NEBOC_INTERN_CONFIG_PAYLOAD_OFFSET]
 test rcx,rcx
 jz .invalid
 mov r8,[rsi+NEBOC_INTERN_CONFIG_MAX_BYTES_OFFSET]
 test r8,r8
 jz .invalid
 cmp r8,NEBOC_MEMORY_MAX_INTERN_BYTES
 ja .limit
 cmp qword [rsi+NEBOC_INTERN_CONFIG_KIND_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_INTERN_CONFIG_SESSION_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_INTERN_CONFIG_VERSION_OFFSET],0
 je .invalid
 mov r9,[rsi+NEBOC_INTERN_CONFIG_ID_WIDTH_OFFSET]
 cmp r9,NEBOC_ID_WIDTH_U8
 je .width8
 cmp r9,NEBOC_ID_WIDTH_U16
 je .width16
 cmp r9,NEBOC_ID_WIDTH_U32
 jne .invalid
 mov r10d,0xffffffff
 jmp .width_ready
.width16:
 mov r10d,0xffff
 jmp .width_ready
.width8:
 mov r10d,0xff
.width_ready:
 cmp rdx,r10
 ja .limit
 mov [rdi+NEBOC_INTERN_ENTRIES_OFFSET],rax
 mov [rdi+NEBOC_INTERN_MAX_ENTRIES_OFFSET],rdx
 mov qword [rdi+NEBOC_INTERN_COUNT_OFFSET],0
 mov [rdi+NEBOC_INTERN_PAYLOAD_OFFSET],rcx
 mov [rdi+NEBOC_INTERN_MAX_BYTES_OFFSET],r8
 mov qword [rdi+NEBOC_INTERN_USED_BYTES_OFFSET],0
 mov rax,[rsi+NEBOC_INTERN_CONFIG_KIND_OFFSET]
 mov [rdi+NEBOC_INTERN_KIND_OFFSET],rax
 mov rax,[rsi+NEBOC_INTERN_CONFIG_SESSION_OFFSET]
 mov [rdi+NEBOC_INTERN_SESSION_OFFSET],rax
 mov rax,[rsi+NEBOC_INTERN_CONFIG_VERSION_OFFSET]
 mov [rdi+NEBOC_INTERN_VERSION_OFFSET],rax
 mov [rdi+NEBOC_INTERN_ID_WIDTH_OFFSET],r9
 mov qword [rdi+NEBOC_INTERN_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_intern_pool_intern
 ; rdi=context, rsi=bytes, rdx=length, rcx=stable-id output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rdx,NEBOC_MEMORY_MAX_INTERN_ITEM_BYTES
 ja .limit
 cmp qword [rdi+NEBOC_INTERN_ACTIVE_OFFSET],1
 jne .invalid
 mov r8,rdi
 mov r9,rsi
 mov r10,rdx
 mov r11,rcx
 xor ecx,ecx
.search:
 cmp rcx,[r8+NEBOC_INTERN_COUNT_OFFSET]
 jae .insert
 imul rdi,rcx,NEBOC_INTERN_ENTRY_SIZE
 add rdi,[r8+NEBOC_INTERN_ENTRIES_OFFSET]
 cmp [rdi+NEBOC_INTERN_ENTRY_LENGTH_OFFSET],r10
 jne .next
 mov rsi,[r8+NEBOC_INTERN_PAYLOAD_OFFSET]
 add rsi,[rdi+NEBOC_INTERN_ENTRY_OFFSET_OFFSET]
 xor edx,edx
.compare:
 cmp rdx,r10
 jae .found
 mov al,[r9+rdx]
 cmp al,[rsi+rdx]
 jne .next
 inc rdx
 jmp .compare
.found:
 mov rax,[rdi+NEBOC_INTERN_ENTRY_ID_OFFSET]
 mov [r11],rax
 xor eax,eax
 ret
.next:
 inc rcx
 jmp .search
.insert:
 mov rax,[r8+NEBOC_INTERN_COUNT_OFFSET]
 cmp rax,[r8+NEBOC_INTERN_MAX_ENTRIES_OFFSET]
 jae .limit
 mov rdx,[r8+NEBOC_INTERN_USED_BYTES_OFFSET]
 mov rax,rdx
 add rax,r10
 jc .limit
 cmp rax,[r8+NEBOC_INTERN_MAX_BYTES_OFFSET]
 ja .limit
 mov rcx,[r8+NEBOC_INTERN_COUNT_OFFSET]
 inc rcx
 mov rsi,[r8+NEBOC_INTERN_ID_WIDTH_OFFSET]
 cmp rsi,NEBOC_ID_WIDTH_U8
 jne .not8
 cmp rcx,0xff
 ja .limit
 jmp .copy
.not8:
 cmp rsi,NEBOC_ID_WIDTH_U16
 jne .copy
 cmp rcx,0xffff
 ja .limit
.copy:
 mov rdi,[r8+NEBOC_INTERN_PAYLOAD_OFFSET]
 add rdi,rdx
 mov rsi,r9
 mov rcx,r10
 rep movsb
 mov rax,[r8+NEBOC_INTERN_COUNT_OFFSET]
 imul rdi,rax,NEBOC_INTERN_ENTRY_SIZE
 add rdi,[r8+NEBOC_INTERN_ENTRIES_OFFSET]
 mov [rdi+NEBOC_INTERN_ENTRY_OFFSET_OFFSET],rdx
 mov [rdi+NEBOC_INTERN_ENTRY_LENGTH_OFFSET],r10
 inc rax
 mov [rdi+NEBOC_INTERN_ENTRY_ID_OFFSET],rax
 add rdx,r10
 mov [r8+NEBOC_INTERN_USED_BYTES_OFFSET],rdx
 mov [r8+NEBOC_INTERN_COUNT_OFFSET],rax
 mov [r11],rax
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compact_id_table_new
 ; rdi=context, rsi=width bytes, rdx=session, rcx=table version.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rsi,NEBOC_ID_WIDTH_U8
 je .width8
 cmp rsi,NEBOC_ID_WIDTH_U16
 je .width16
 cmp rsi,NEBOC_ID_WIDTH_U32
 jne .invalid
 mov r8d,0xffffffff
 jmp .ready
.width16:
 mov r8d,0xffff
 jmp .ready
.width8:
 mov r8d,0xff
.ready:
 mov [rdi+NEBOC_COMPACT_ID_WIDTH_OFFSET],rsi
 mov [rdi+NEBOC_COMPACT_ID_MAX_OFFSET],r8
 mov qword [rdi+NEBOC_COMPACT_ID_NEXT_OFFSET],1
 mov [rdi+NEBOC_COMPACT_ID_SESSION_OFFSET],rdx
 mov [rdi+NEBOC_COMPACT_ID_VERSION_OFFSET],rcx
 mov qword [rdi+NEBOC_COMPACT_ID_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_memory_pressure_level
 ; rdi={used,budget,high,critical}, rsi=level output.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PRESSURE_BUDGET_OFFSET]
 test rax,rax
 jz .invalid
 mov rdx,[rdi+NEBOC_PRESSURE_HIGH_OFFSET]
 test rdx,rdx
 jz .invalid
 mov rcx,[rdi+NEBOC_PRESSURE_CRITICAL_OFFSET]
 cmp rdx,rcx
 ja .invalid
 cmp rcx,rax
 ja .invalid
 mov rax,[rdi+NEBOC_PRESSURE_USED_OFFSET]
 cmp rax,rcx
 jae .critical
 cmp rax,rdx
 jae .high
 mov qword [rsi],NEBOC_MEMORY_PRESSURE_NORMAL
 xor eax,eax
 ret
.high:
 mov qword [rsi],NEBOC_MEMORY_PRESSURE_HIGH
 xor eax,eax
 ret
.critical:
 mov qword [rsi],NEBOC_MEMORY_PRESSURE_CRITICAL
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_memory_evict_caches
 ; rdi=cache records, rsi=count, rdx=target bytes, rcx=report output.
 test rcx,rcx
 jz .invalid_before_save
 cmp rsi,NEBOC_MEMORY_MAX_CACHE_ENTRIES
 ja .limit_before_save
 test rsi,rsi
 jz .pointer_ok
 test rdi,rdi
 jz .invalid_before_save
.pointer_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 xor ecx,ecx
.validate:
 cmp rcx,r12
 jae .validated
 mov rax,rcx
 shl rax,5
 lea rdi,[rbx+rax]
 cmp qword [rdi+NEBOC_CACHE_ENTRY_ID_OFFSET],0
 je .invalid
 mov rax,[rdi+NEBOC_CACHE_ENTRY_BYTES_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_MEMORY_MAX_CACHE_ITEM_BYTES
 ja .limit
 mov rax,[rdi+NEBOC_CACHE_ENTRY_KIND_OFFSET]
 cmp rax,NEBOC_CACHE_RECOMPUTABLE
 je .kind_ok
 cmp rax,NEBOC_CACHE_SOURCE_OF_TRUTH
 jne .invalid
.kind_ok:
 cmp qword [rdi+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],1
 ja .invalid
 lea r8,[rcx+1]
.unique:
 cmp r8,r12
 jae .next_validate
 mov rax,r8
 shl rax,5
 lea r9,[rbx+rax]
 mov rax,[rdi+NEBOC_CACHE_ENTRY_ID_OFFSET]
 cmp rax,[r9+NEBOC_CACHE_ENTRY_ID_OFFSET]
 je .invalid
 inc r8
 jmp .unique
.next_validate:
 inc rcx
 jmp .validate
.validated:
 xor r15d,r15d
 xor r10d,r10d
.evict_again:
 cmp r15,r13
 jae .aggregate
 mov rdx,-1
 xor r11d,r11d
 xor ecx,ecx
.find:
 cmp rcx,r12
 jae .found_best
 mov rax,rcx
 shl rax,5
 lea rdi,[rbx+rax]
 cmp qword [rdi+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],NEBOC_CACHE_ACTIVE
 jne .find_next
 cmp qword [rdi+NEBOC_CACHE_ENTRY_KIND_OFFSET],NEBOC_CACHE_RECOMPUTABLE
 jne .find_next
 mov rax,[rdi+NEBOC_CACHE_ENTRY_ID_OFFSET]
 cmp rax,rdx
 jae .find_next
 mov rdx,rax
 mov r11,rdi
.find_next:
 inc rcx
 jmp .find
.found_best:
 test r11,r11
 jz .aggregate
 mov qword [r11+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],0
 add r15,[r11+NEBOC_CACHE_ENTRY_BYTES_OFFSET]
 inc r10
 jmp .evict_again
.aggregate:
 xor r8d,r8d
 xor r9d,r9d
 xor ecx,ecx
.aggregate_loop:
 cmp rcx,r12
 jae .write_report
 mov rax,rcx
 shl rax,5
 lea rdi,[rbx+rax]
 cmp qword [rdi+NEBOC_CACHE_ENTRY_ACTIVE_OFFSET],NEBOC_CACHE_ACTIVE
 jne .aggregate_next
 add r8,[rdi+NEBOC_CACHE_ENTRY_BYTES_OFFSET]
 inc r9
.aggregate_next:
 inc rcx
 jmp .aggregate_loop
.write_report:
 mov [r14+NEBOC_EVICT_FREED_BYTES_OFFSET],r15
 mov [r14+NEBOC_EVICT_ITEMS_OFFSET],r10
 mov [r14+NEBOC_EVICT_REMAINING_BYTES_OFFSET],r8
 mov [r14+NEBOC_EVICT_REMAINING_ITEMS_OFFSET],r9
 xor eax,eax
 cmp r15,r13
 setae al
 mov [r14+NEBOC_EVICT_TARGET_REACHED_OFFSET],rax
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
.limit_before_save:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_before_save:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_memory_leak_report
 ; rdi=array of arena pointers, rsi=count, rdx=report output.
 test rdx,rdx
 jz .invalid_before_save
 cmp rsi,NEBOC_MEMORY_MAX_ARENAS
 ja .limit_before_save
 test rsi,rsi
 jz .pointer_ok
 test rdi,rdi
 jz .invalid_before_save
.pointer_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 xor ecx,ecx
.validate:
 cmp rcx,r12
 jae .validated
 mov rdi,[rbx+rcx*8]
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_COMPILER_MEMORY_ARENA_ACTIVE_OFFSET],1
 jne .invalid
 lea r8,[rcx+1]
.unique:
 cmp r8,r12
 jae .next_validate
 cmp rdi,[rbx+r8*8]
 je .invalid
 inc r8
 jmp .unique
.next_validate:
 inc rcx
 jmp .validate
.validated:
 xor r14d,r14d
 xor r15d,r15d
 mov qword [rsp],0
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],0
 xor ecx,ecx
.aggregate:
 cmp rcx,r12
 jae .write_report
 mov rdi,[rbx+rcx*8]
 inc r14
 mov rax,[rdi+NEBOC_ARENA_USED_OFFSET]
 add [rsp],rax
 jc .limit
 mov rdx,[rdi+NEBOC_ARENA_BORROW_COUNT_OFFSET]
 add [rsp+8],rdx
 jc .limit
 or rax,rdx
 jz .not_leaked
 inc r15
.not_leaked:
 mov rax,[rdi+neboc_compiler_memory_ARENA_CAPACITY_OFFSET]
 add [rsp+16],rax
 jc .limit
 mov rax,[rdi+neboc_compiler_memory_ARENA_HIGH_WATER_OFFSET]
 add [rsp+24],rax
 jc .limit
 inc rcx
 jmp .aggregate
.write_report:
 mov [r13+NEBOC_LEAK_ACTIVE_ARENAS_OFFSET],r14
 mov [r13+NEBOC_LEAK_ARENAS_OFFSET],r15
 mov rax,[rsp]
 mov [r13+NEBOC_LEAK_LIVE_BYTES_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_LEAK_BORROWS_OFFSET],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_LEAK_RESERVED_BYTES_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_LEAK_HIGH_WATER_OFFSET],rax
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
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

NEBOC_ABI_FUNCTION neboc_cli_compiler_memory
 ; rdi=array of arena pointers, rsi=count, rdx=bounded local summary output.
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call neboc_memory_leak_report
 test eax,eax
 jnz .done
 mov rax,[r13+NEBOC_LEAK_RESERVED_BYTES_OFFSET]
 test rax,rax
 jz .normal
 mov rcx,rax
 imul rcx,95
 mov rdx,[r13+NEBOC_LEAK_LIVE_BYTES_OFFSET]
 imul rdx,100
 cmp rdx,rcx
 jae .critical
 mov rcx,rax
 imul rcx,80
 cmp rdx,rcx
 jae .high
.normal:
 mov qword [r13+NEBOC_MEMORY_SUMMARY_PRESSURE_OFFSET],NEBOC_MEMORY_PRESSURE_NORMAL
 jmp .availability
.high:
 mov qword [r13+NEBOC_MEMORY_SUMMARY_PRESSURE_OFFSET],NEBOC_MEMORY_PRESSURE_HIGH
 jmp .availability
.critical:
 mov qword [r13+NEBOC_MEMORY_SUMMARY_PRESSURE_OFFSET],NEBOC_MEMORY_PRESSURE_CRITICAL
.availability:
 mov qword [r13+NEBOC_MEMORY_SUMMARY_AVAILABLE_OFFSET],NEBOC_MEMORY_AVAILABLE_ARENAS
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
