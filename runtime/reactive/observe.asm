; MEDIA-IMAGEM-AUDIO-E-VIDEO-F06 bounded causal tracing, graph reports and local snapshot checks.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/reactive/observe.inc"
section .text
NEBOC_ABI_FUNCTION nebo_trace_init
 test rdi,rdi
 jz .invalid_init
 mov qword [rdi+NEBO_TRACE_ENTRIES],0
 mov qword [rdi+NEBO_TRACE_CAPACITY],0
 mov qword [rdi+NEBO_TRACE_COUNT],0
 mov qword [rdi+NEBO_TRACE_HEAD],0
 mov qword [rdi+NEBO_TRACE_DROPPED],0
 test rsi,rsi
 jz .invalid_init
 test rdx,rdx
 jz .invalid_init
 cmp rdx,NEBO_TRACE_MAX_EVENTS
 ja .limit_init
 mov [rdi+NEBO_TRACE_ENTRIES],rsi
 mov [rdi+NEBO_TRACE_CAPACITY],rdx
 xor eax,eax
 ret
.invalid_init: mov eax,NEBO_OBSERVE_STATUS_INVALID
 ret
.limit_init: mov eax,NEBO_OBSERVE_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_trace_append
 test rdi,rdi
 jz .invalid_append
 test rsi,rsi
 jz .invalid_append
 mov rcx,[rdi+NEBO_TRACE_COUNT]
 mov r8,[rdi+NEBO_TRACE_HEAD]
 cmp rcx,[rdi+NEBO_TRACE_CAPACITY]
 jb .space
 inc r8
 xor edx,edx
 mov rax,r8
 div qword [rdi+NEBO_TRACE_CAPACITY]
 mov r8,rdx
 mov [rdi+NEBO_TRACE_HEAD],r8
 dec rcx
 inc qword [rdi+NEBO_TRACE_DROPPED]
.space:
 mov rax,r8
 add rax,rcx
 xor edx,edx
 div qword [rdi+NEBO_TRACE_CAPACITY]
 mov r9,rdx
 imul r9,NEBO_TRACE_ENTRY_SIZE
 mov r10,[rdi+NEBO_TRACE_ENTRIES]
 mov rax,[rsi]
 mov [r10+r9],rax
 mov rax,[rsi+8]
 mov [r10+r9+8],rax
 mov rax,[rsi+16]
 mov [r10+r9+16],rax
 mov rax,[rsi+24]
 mov [r10+r9+24],rax
 mov rax,[rsi+32]
 mov [r10+r9+32],rax
 inc rcx
 mov [rdi+NEBO_TRACE_COUNT],rcx
 xor eax,eax
 ret
.invalid_append: mov eax,NEBO_OBSERVE_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_reactive_graph_report
 ; adjacency[64], node count, output
 test rdx,rdx
 jz .invalid_report
 mov qword [rdx],0
 mov qword [rdx+8],0
 mov qword [rdx+16],0
 test rdi,rdi
 jz .invalid_report
 test rsi,rsi
 jz .invalid_report
 cmp rsi,64
 ja .limit_report
 xor eax,eax
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
.report_loop:
 cmp rax,rsi
 jae .report_done
 mov r10,[rdi+rax*8]
 popcnt r10,r10
 add rcx,r10
 cmp r10,r8
 jbe .report_next
 mov r8,r10
 mov r9,rax
.report_next: inc rax
 jmp .report_loop
.report_done:
 mov [rdx+NEBO_GRAPH_REPORT_EDGES],rcx
 mov [rdx+NEBO_GRAPH_REPORT_MAX_FANOUT],r8
 mov [rdx+NEBO_GRAPH_REPORT_HOTSPOT],r9
 xor eax,eax
 ret
.invalid_report: mov eax,NEBO_OBSERVE_STATUS_INVALID
 ret
.limit_report: mov eax,NEBO_OBSERVE_STATUS_LIMIT
 ret

NEBOC_ABI_FUNCTION nebo_snapshot_validate
 ; snapshot, expected schema, minimum version
 test rdi,rdi
 jz .invalid_snapshot
 cmp qword [rdi+NEBO_SNAPSHOT_CAPABILITY],NEBO_SNAPSHOT_CAP_LOCAL
 jne .capability_snapshot
 cmp [rdi+NEBO_SNAPSHOT_SCHEMA],rsi
 jne .schema_snapshot
 cmp [rdi+NEBO_SNAPSHOT_VERSION],rdx
 jb .schema_snapshot
 cmp qword [rdi+NEBO_SNAPSHOT_VALUE_HASH],0
 je .invalid_snapshot
 cmp qword [rdi+NEBO_SNAPSHOT_KEY_HASH],0
 je .invalid_snapshot
 xor eax,eax
 ret
.invalid_snapshot: mov eax,NEBO_OBSERVE_STATUS_INVALID
 ret
.schema_snapshot: mov eax,NEBO_OBSERVE_STATUS_SCHEMA
 ret
.capability_snapshot: mov eax,NEBO_OBSERVE_STATUS_CAPABILITY
 ret

NEBOC_ABI_FUNCTION nebo_reactive_await_stable
 ; pending work count: observation only, never busy waits
 test rdi,rdi
 jnz .pending
 xor eax,eax
 ret
.pending: mov eax,NEBO_OBSERVE_STATUS_PENDING
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
