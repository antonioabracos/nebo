; COMPILER-METRICS-F01 deterministic, bounded compiler metrics and profile backend.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/metrics/compiler_metrics.inc"

section .text
metrics_validate:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_ACTIVE_OFFSET],1
 jne .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_CORRECTNESS_OFFSET],NEBOC_METRICS_CORRECTNESS_PASS
 jne .source
 mov rax,[rdi+NEBOC_METRICS_CTX_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_METRICS_CTX_CAPACITY_OFFSET]
 ja .invalid
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

metrics_reserve:
 ; rdi=context. Return rax=event or zero when disabled; edx=status.
 call metrics_validate
 test eax,eax
 jnz .error
 cmp qword [rdi+NEBOC_METRICS_CTX_ENABLED_OFFSET],0
 je .disabled
 mov rcx,[rdi+NEBOC_METRICS_CTX_COUNT_OFFSET]
 cmp rcx,[rdi+NEBOC_METRICS_CTX_CAPACITY_OFFSET]
 jae .limit
 imul rax,rcx,NEBOC_METRICS_EVENT_SIZE
 add rax,[rdi+NEBOC_METRICS_CTX_EVENTS_OFFSET]
 push rdi
 mov rdi,rax
 push rcx
 mov ecx,NEBOC_METRICS_EVENT_SIZE/8
 xor edx,edx
.zero:
 mov [rdi],rdx
 add rdi,8
 loop .zero
 pop rcx
 pop rdi
 mov [rax+NEBOC_METRICS_EVENT_SEQUENCE_OFFSET],rcx
 inc qword [rdi+NEBOC_METRICS_CTX_COUNT_OFFSET]
 xor edx,edx
 ret
.disabled:
 xor eax,eax
 xor edx,edx
 ret
.limit:
 inc qword [rdi+NEBOC_METRICS_CTX_DROPPED_OFFSET]
 xor eax,eax
 mov edx,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.error:
 mov edx,eax
 xor eax,eax
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_new
 ; rdi=prepopulated context, rsi=event storage, rdx=event capacity.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_METRICS_MAX_EVENTS
 ja .limit
 cmp qword [rdi+NEBOC_METRICS_CTX_REVISION_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_HARDWARE_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_TOOLCHAIN_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_HOST_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_TARGET_OFFSET],0
 je .invalid
 mov rax,[rdi+NEBOC_METRICS_CTX_MODE_OFFSET]
 cmp rax,NEBOC_METRICS_MODE_COLD
 jb .invalid
 cmp rax,NEBOC_METRICS_MODE_INCREMENTAL
 ja .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_ENABLED_OFFSET],1
 ja .invalid
 cmp qword [rdi+NEBOC_METRICS_CTX_CORRECTNESS_OFFSET],NEBOC_METRICS_CORRECTNESS_PASS
 jne .source
 mov [rdi+NEBOC_METRICS_CTX_EVENTS_OFFSET],rsi
 mov [rdi+NEBOC_METRICS_CTX_CAPACITY_OFFSET],rdx
 mov qword [rdi+NEBOC_METRICS_CTX_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_METRICS_CTX_DROPPED_OFFSET],0
 mov qword [rdi+NEBOC_METRICS_CTX_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_phase_timer
 ; rdi=context, rsi=stable phase id, rdx=unit id, rcx=wall, r8=cpu.
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
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
 call metrics_reserve
 test edx,edx
 jnz .status
 test rax,rax
 jz .ok
 mov qword [rax+NEBOC_METRICS_EVENT_KIND_OFFSET],NEBOC_METRICS_EVENT_PHASE
 mov [rax+NEBOC_METRICS_EVENT_NAME_OFFSET],r12
 mov [rax+NEBOC_METRICS_EVENT_UNIT_OFFSET],r13
 mov [rax+NEBOC_METRICS_EVENT_VALUE0_OFFSET],r14
 mov [rax+NEBOC_METRICS_EVENT_VALUE1_OFFSET],r15
.ok:
 xor eax,eax
 jmp .done
.status:
 mov eax,edx
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_counter
 ; rdi=context, rsi=stable counter id, rdx=value.
 test rsi,rsi
 jz .invalid
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call metrics_reserve
 test edx,edx
 jnz .status
 test rax,rax
 jz .ok
 mov qword [rax+NEBOC_METRICS_EVENT_KIND_OFFSET],NEBOC_METRICS_EVENT_COUNTER
 mov [rax+NEBOC_METRICS_EVENT_NAME_OFFSET],r12
 mov [rax+NEBOC_METRICS_EVENT_VALUE0_OFFSET],r13
.ok:
 xor eax,eax
 jmp .done
.status:
 mov eax,edx
.done:
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_memory_snapshot
 ; rdi=context, rsi=label, rdx=arena, rcx=heap, r8=rss, r9=virtual.
 test rsi,rsi
 jz .invalid
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
 call metrics_reserve
 test edx,edx
 jnz .status
 test rax,rax
 jz .ok
 mov qword [rax+NEBOC_METRICS_EVENT_KIND_OFFSET],NEBOC_METRICS_EVENT_MEMORY
 mov [rax+NEBOC_METRICS_EVENT_NAME_OFFSET],r12
 mov [rax+NEBOC_METRICS_EVENT_VALUE0_OFFSET],r13
 mov [rax+NEBOC_METRICS_EVENT_VALUE1_OFFSET],r14
 mov [rax+NEBOC_METRICS_EVENT_VALUE2_OFFSET],r15
 mov rdx,[rsp]
 mov [rax+NEBOC_METRICS_EVENT_VALUE3_OFFSET],rdx
 mov edx,NEBOC_METRICS_AVAILABLE_ARENA | NEBOC_METRICS_AVAILABLE_HEAP
 test r15,r15
 jz .no_rss
 or edx,NEBOC_METRICS_AVAILABLE_RSS
.no_rss:
 cmp qword [rsp],0
 je .availability
 or edx,NEBOC_METRICS_AVAILABLE_VIRTUAL
.availability:
 mov [rax+NEBOC_METRICS_EVENT_AVAILABLE_OFFSET],rdx
.ok:
 xor eax,eax
 jmp .done
.status:
 mov eax,edx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_io_snapshot
 ; rdi=context, rsi=label, rdx=bytes read, rcx=bytes written,
 ; r8=files read, r9=files written.
 test rsi,rsi
 jz .invalid
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
 call metrics_reserve
 test edx,edx
 jnz .status
 test rax,rax
 jz .ok
 mov qword [rax+NEBOC_METRICS_EVENT_KIND_OFFSET],NEBOC_METRICS_EVENT_IO
 mov [rax+NEBOC_METRICS_EVENT_NAME_OFFSET],r12
 mov [rax+NEBOC_METRICS_EVENT_VALUE0_OFFSET],r13
 mov [rax+NEBOC_METRICS_EVENT_VALUE1_OFFSET],r14
 mov [rax+NEBOC_METRICS_EVENT_VALUE2_OFFSET],r15
 mov rdx,[rsp]
 mov [rax+NEBOC_METRICS_EVENT_VALUE3_OFFSET],rdx
.ok:
 xor eax,eax
 jmp .done
.status:
 mov eax,edx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_cache_event
 ; rdi=context, rsi=kind, rdx=stable key class.
 cmp rsi,NEBOC_METRICS_CACHE_HIT
 jb .invalid
 cmp rsi,NEBOC_METRICS_CACHE_BYPASS
 ja .invalid
 test rdx,rdx
 jz .invalid
 push r12
 push r13
 mov r12,rsi
 mov r13,rdx
 call metrics_reserve
 test edx,edx
 jnz .status
 test rax,rax
 jz .ok
 mov qword [rax+NEBOC_METRICS_EVENT_KIND_OFFSET],NEBOC_METRICS_EVENT_CACHE
 mov [rax+NEBOC_METRICS_EVENT_NAME_OFFSET],r12
 mov [rax+NEBOC_METRICS_EVENT_UNIT_OFFSET],r13
.ok:
 xor eax,eax
 jmp .done
.status:
 mov eax,edx
.done:
 pop r13
 pop r12
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_trace_event
 ; rdi=context, rsi=category id, rdx=qword fields, rcx=field count.
 test rsi,rsi
 jz .invalid
 cmp rcx,NEBOC_METRICS_MAX_TRACE_FIELDS
 ja .limit
 test rcx,rcx
 jz .fields_ok
 test rdx,rdx
 jz .invalid
.fields_ok:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 call metrics_reserve
 test edx,edx
 jnz .status
 test rax,rax
 jz .ok
 mov qword [rax+NEBOC_METRICS_EVENT_KIND_OFFSET],NEBOC_METRICS_EVENT_TRACE
 mov [rax+NEBOC_METRICS_EVENT_NAME_OFFSET],r12
 mov [rax+NEBOC_METRICS_EVENT_FIELD_COUNT_OFFSET],r14
 test r14,r14
 jz .ok
 mov rdx,[r13]
 mov [rax+NEBOC_METRICS_EVENT_VALUE0_OFFSET],rdx
 cmp r14,1
 je .ok
 mov rdx,[r13+8]
 mov [rax+NEBOC_METRICS_EVENT_VALUE1_OFFSET],rdx
 cmp r14,2
 je .ok
 mov rdx,[r13+16]
 mov [rax+NEBOC_METRICS_EVENT_VALUE2_OFFSET],rdx
 cmp r14,3
 je .ok
 mov rdx,[r13+24]
 mov [rax+NEBOC_METRICS_EVENT_VALUE3_OFFSET],rdx
.ok:
 xor eax,eax
 jmp .done
.status:
 mov eax,edx
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_summary
 ; rdi=context, rsi=summary.
 test rsi,rsi
 jz .invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 call metrics_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov ecx,NEBOC_METRICS_SUMMARY_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[rbx+NEBOC_METRICS_CTX_COUNT_OFFSET]
 mov [r12+NEBOC_METRICS_SUMMARY_EVENT_COUNT_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_DROPPED_OFFSET]
 mov [r12+NEBOC_METRICS_SUMMARY_DROPPED_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_OVERHEAD_WALL_OFFSET]
 mov [r12+NEBOC_METRICS_SUMMARY_OVERHEAD_WALL_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_OVERHEAD_CPU_OFFSET]
 mov [r12+NEBOC_METRICS_SUMMARY_OVERHEAD_CPU_OFFSET],rax
 mov r13,[rbx+NEBOC_METRICS_CTX_EVENTS_OFFSET]
 mov r14,[rbx+NEBOC_METRICS_CTX_COUNT_OFFSET]
 xor r15d,r15d
.loop:
 cmp r15,r14
 jae .success
 mov rax,[r13+NEBOC_METRICS_EVENT_KIND_OFFSET]
 cmp rax,NEBOC_METRICS_EVENT_PHASE
 je .phase
 cmp rax,NEBOC_METRICS_EVENT_COUNTER
 je .counter
 cmp rax,NEBOC_METRICS_EVENT_MEMORY
 je .memory
 cmp rax,NEBOC_METRICS_EVENT_IO
 je .io
 cmp rax,NEBOC_METRICS_EVENT_CACHE
 je .cache
 cmp rax,NEBOC_METRICS_EVENT_TRACE
 je .trace
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.phase:
 mov rax,[r13+NEBOC_METRICS_EVENT_VALUE0_OFFSET]
 add [r12+NEBOC_METRICS_SUMMARY_WALL_OFFSET],rax
 mov rdx,[r13+NEBOC_METRICS_EVENT_VALUE1_OFFSET]
 add [r12+NEBOC_METRICS_SUMMARY_CPU_OFFSET],rdx
 cmp rax,[r12+NEBOC_METRICS_SUMMARY_CRITICAL_WALL_OFFSET]
 jbe .next
 mov [r12+NEBOC_METRICS_SUMMARY_CRITICAL_WALL_OFFSET],rax
 mov rax,[r13+NEBOC_METRICS_EVENT_NAME_OFFSET]
 mov [r12+NEBOC_METRICS_SUMMARY_CRITICAL_PHASE_OFFSET],rax
 mov rax,[r13+NEBOC_METRICS_EVENT_UNIT_OFFSET]
 mov [r12+NEBOC_METRICS_SUMMARY_CRITICAL_UNIT_OFFSET],rax
 jmp .next
.counter:
 mov rax,[r13+NEBOC_METRICS_EVENT_VALUE0_OFFSET]
 add [r12+NEBOC_METRICS_SUMMARY_COUNTER_TOTAL_OFFSET],rax
 jmp .next
.memory:
 mov rax,[r13+NEBOC_METRICS_EVENT_VALUE1_OFFSET]
 cmp rax,[r12+NEBOC_METRICS_SUMMARY_PEAK_HEAP_OFFSET]
 jbe .rss
 mov [r12+NEBOC_METRICS_SUMMARY_PEAK_HEAP_OFFSET],rax
.rss:
 test qword [r13+NEBOC_METRICS_EVENT_AVAILABLE_OFFSET],NEBOC_METRICS_AVAILABLE_RSS
 jz .next
 mov rax,[r13+NEBOC_METRICS_EVENT_VALUE2_OFFSET]
 cmp rax,[r12+NEBOC_METRICS_SUMMARY_PEAK_RSS_OFFSET]
 jbe .next
 mov [r12+NEBOC_METRICS_SUMMARY_PEAK_RSS_OFFSET],rax
 jmp .next
.io:
 mov rax,[r13+NEBOC_METRICS_EVENT_VALUE0_OFFSET]
 add [r12+NEBOC_METRICS_SUMMARY_IO_READ_OFFSET],rax
 mov rax,[r13+NEBOC_METRICS_EVENT_VALUE1_OFFSET]
 add [r12+NEBOC_METRICS_SUMMARY_IO_WRITE_OFFSET],rax
 jmp .next
.cache:
 cmp qword [r13+NEBOC_METRICS_EVENT_NAME_OFFSET],NEBOC_METRICS_CACHE_HIT
 jne .cache_other
 inc qword [r12+NEBOC_METRICS_SUMMARY_CACHE_HITS_OFFSET]
 jmp .next
.cache_other:
 inc qword [r12+NEBOC_METRICS_SUMMARY_CACHE_OTHER_OFFSET]
 jmp .next
.trace:
 inc qword [r12+NEBOC_METRICS_SUMMARY_TRACE_COUNT_OFFSET]
.next:
 add r13,NEBOC_METRICS_EVENT_SIZE
 inc r15
 jmp .loop
.success:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_metrics_export
 ; rdi=context, rsi=caller-owned output, rdx=capacity, rcx=format.
 test rsi,rsi
 jz .invalid
 cmp rcx,NEBOC_METRICS_FORMAT_JSON
 je .format_ok
 cmp rcx,NEBOC_METRICS_FORMAT_TRACE
 jne .invalid
.format_ok:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 call metrics_validate
 test eax,eax
 jnz .done
 mov rax,[rbx+NEBOC_METRICS_CTX_COUNT_OFFSET]
 imul rax,NEBOC_METRICS_EVENT_SIZE
 add rax,NEBOC_METRICS_EXPORT_HEADER_SIZE
 cmp rax,r13
 ja .limit
 mov r15,rax
 mov rdi,r12
 mov ecx,NEBOC_METRICS_EXPORT_HEADER_SIZE/8
 xor eax,eax
 rep stosq
 mov qword [r12+NEBOC_METRICS_EXPORT_MAGIC_OFFSET],NEBOC_METRICS_EXPORT_MAGIC
 mov qword [r12+NEBOC_METRICS_EXPORT_VERSION_OFFSET],NEBOC_METRICS_SCHEMA_VERSION
 mov [r12+NEBOC_METRICS_EXPORT_FORMAT_OFFSET],r14
 mov rax,[rbx+NEBOC_METRICS_CTX_REVISION_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_REVISION_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_HARDWARE_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_HARDWARE_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_TOOLCHAIN_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_TOOLCHAIN_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_HOST_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_HOST_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_TARGET_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_TARGET_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_MODE_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_MODE_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_CORRECTNESS_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_CORRECTNESS_OFFSET],rax
 mov rax,[rbx+NEBOC_METRICS_CTX_COUNT_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_EVENT_COUNT_OFFSET],rax
 mov qword [r12+NEBOC_METRICS_EXPORT_EVENT_SIZE_OFFSET],NEBOC_METRICS_EVENT_SIZE
 mov rax,[rbx+NEBOC_METRICS_CTX_ENABLED_OFFSET]
 mov [r12+NEBOC_METRICS_EXPORT_ENABLED_OFFSET],rax
 lea rdi,[r12+NEBOC_METRICS_EXPORT_HEADER_SIZE]
 mov rsi,[rbx+NEBOC_METRICS_CTX_EVENTS_OFFSET]
 mov rcx,[rbx+NEBOC_METRICS_CTX_COUNT_OFFSET]
 imul rcx,NEBOC_METRICS_EVENT_SIZE/8
 rep movsq
 mov rax,r15
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

align 16
neboc_compiler_metrics_report:
 cld
 ; rdi=profile artifact, rsi=size, rdx=summary; never compiles.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_METRICS_EXPORT_HEADER_SIZE
 jb .invalid_source
 cmp qword [rdi+NEBOC_METRICS_EXPORT_MAGIC_OFFSET],NEBOC_METRICS_EXPORT_MAGIC
 jne .invalid_source
 cmp qword [rdi+NEBOC_METRICS_EXPORT_VERSION_OFFSET],NEBOC_METRICS_SCHEMA_VERSION
 jne .invalid_source
 cmp qword [rdi+NEBOC_METRICS_EXPORT_EVENT_SIZE_OFFSET],NEBOC_METRICS_EVENT_SIZE
 jne .invalid_source
 cmp qword [rdi+NEBOC_METRICS_EXPORT_CORRECTNESS_OFFSET],NEBOC_METRICS_CORRECTNESS_PASS
 jne .invalid_source
 mov rax,[rdi+NEBOC_METRICS_EXPORT_FORMAT_OFFSET]
 cmp rax,NEBOC_METRICS_FORMAT_JSON
 je .format_ok
 cmp rax,NEBOC_METRICS_FORMAT_TRACE
 jne .invalid_source
.format_ok:
 mov rax,[rdi+NEBOC_METRICS_EXPORT_EVENT_COUNT_OFFSET]
 cmp rax,NEBOC_METRICS_MAX_EVENTS
 ja .limit
 imul rax,NEBOC_METRICS_EVENT_SIZE
 add rax,NEBOC_METRICS_EXPORT_HEADER_SIZE
 cmp rax,rsi
 ja .invalid_source
 push rbp
 mov rbp,rsp
 sub rsp,128
 mov r8,rdi
 mov r9,rdx
 mov rdi,rsp
 mov ecx,NEBOC_METRICS_CTX_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r8+NEBOC_METRICS_EXPORT_REVISION_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_REVISION_OFFSET],rax
 mov rax,[r8+NEBOC_METRICS_EXPORT_HARDWARE_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_HARDWARE_OFFSET],rax
 mov rax,[r8+NEBOC_METRICS_EXPORT_TOOLCHAIN_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_TOOLCHAIN_OFFSET],rax
 mov rax,[r8+NEBOC_METRICS_EXPORT_HOST_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_HOST_OFFSET],rax
 mov rax,[r8+NEBOC_METRICS_EXPORT_TARGET_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_TARGET_OFFSET],rax
 mov rax,[r8+NEBOC_METRICS_EXPORT_MODE_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_MODE_OFFSET],rax
 mov rax,[r8+NEBOC_METRICS_EXPORT_ENABLED_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_ENABLED_OFFSET],rax
 mov qword [rsp+NEBOC_METRICS_CTX_CORRECTNESS_OFFSET],NEBOC_METRICS_CORRECTNESS_PASS
 lea rax,[r8+NEBOC_METRICS_EXPORT_HEADER_SIZE]
 mov [rsp+NEBOC_METRICS_CTX_EVENTS_OFFSET],rax
 mov rax,[r8+NEBOC_METRICS_EXPORT_EVENT_COUNT_OFFSET]
 mov [rsp+NEBOC_METRICS_CTX_CAPACITY_OFFSET],rax
 mov [rsp+NEBOC_METRICS_CTX_COUNT_OFFSET],rax
 mov qword [rsp+NEBOC_METRICS_CTX_ACTIVE_OFFSET],1
 mov rdi,rsp
 mov rsi,r9
 call neboc_compiler_metrics_summary
 mov rsp,rbp
 pop rbp
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_timings
 jmp neboc_compiler_metrics_summary

NEBOC_ABI_FUNCTION neboc_cli_compiler_profile
 jmp neboc_compiler_metrics_export

NEBOC_ABI_FUNCTION neboc_cli_compiler_report
 jmp neboc_compiler_metrics_report

section .note.GNU-stack noalloc noexec nowrite progbits
