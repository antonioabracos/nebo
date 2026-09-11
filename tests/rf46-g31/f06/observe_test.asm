bits 64
default rel
%include "runtime/reactive/observe.inc"
extern nebo_trace_init,nebo_trace_append,nebo_reactive_graph_report,nebo_snapshot_validate,nebo_reactive_await_stable
section .data
entry dq 1,2,3,4,5
edges dq 6,8,8,0
snapshot dq 99,3,123,456,NEBO_SNAPSHOT_CAP_LOCAL
section .bss
trace resb nebo_observe_TRACE_SIZE
events resb NEBO_TRACE_ENTRY_SIZE*2
report resb NEBO_OBSERVE_GRAPH_REPORT_SIZE
section .text
global _start
_start:
 lea rdi,[trace]
 lea rsi,[events]
 mov edx,2
 call nebo_trace_init
 test eax,eax
 jnz fail
 lea rdi,[trace]
 lea rsi,[entry]
 call nebo_trace_append
 call nebo_trace_append
 call nebo_trace_append
 cmp qword [trace+NEBO_TRACE_COUNT],2
 jne fail
 cmp qword [trace+NEBO_TRACE_DROPPED],1
 jne fail
 lea rdi,[edges]
 mov esi,4
 lea rdx,[report]
 call nebo_reactive_graph_report
 test eax,eax
 jnz fail
 cmp qword [report],4
 jne fail
 cmp qword [report+8],2
 jne fail
 lea rdi,[snapshot]
 mov esi,99
 mov edx,2
 call nebo_snapshot_validate
 test eax,eax
 jnz fail
 xor edi,edi
 call nebo_reactive_await_stable
 test eax,eax
 jnz fail
 mov edi,1
 call nebo_reactive_await_stable
 cmp eax,NEBO_OBSERVE_STATUS_PENDING
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
