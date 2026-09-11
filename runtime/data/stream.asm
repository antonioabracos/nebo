; COLECOES-PRIMITIVAS-F06 finite bounded Event, Flow and lazy Stream core.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
section .text

; flow_init(flow*, event_array*, length)
NEBOC_ABI_FUNCTION neboc_flow_init
 test rdi,rdi
 jz .fi_bad
 test rdi,7
 jnz .fi_bad
 test rsi,rsi
 jz .fi_bad
 cmp rdx,NEBO_DATA_MAX_EVENTS
 ja .fi_limit
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov ecx,NEBO_FLOW_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_FLOW_SOURCE],r13
 mov [r12+NEBO_FLOW_LENGTH],r14
 mov qword [r12+NEBO_FLOW_GENERATION],1
 mov qword [r12+NEBO_FLOW_FLAGS],NEBO_DATA_STREAM_FINITE
 xor eax,eax
 pop r14
 pop r13
 pop r12
 ret
.fi_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.fi_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; flow_next(flow*, out_event*, out_has*)
NEBOC_ABI_FUNCTION neboc_flow_next
 test rdi,rdi
 jz .fn_bad
 test rsi,rsi
 jz .fn_bad
 test rdx,rdx
 jz .fn_bad
 mov qword [rdx],0
 mov qword [rsi+nebo_data_contract_EVENT_VALUE],0
 mov qword [rsi+NEBO_EVENT_SEQUENCE],0
 mov qword [rsi+NEBO_EVENT_FLAGS],0
 mov rax,[rdi+NEBO_FLOW_SOURCE]
 test rax,rax
 jz .fn_source
 mov rcx,[rdi+NEBO_FLOW_LENGTH]
 cmp rcx,NEBO_DATA_MAX_EVENTS
 ja .fn_source
 mov r8,[rdi+NEBO_FLOW_INDEX]
 cmp r8,rcx
 ja .fn_source
 je .fn_complete
 imul r9,r8,nebo_data_contract_EVENT_SIZE
 mov r10,[rax+r9+nebo_data_contract_EVENT_VALUE]
 mov [rsi+nebo_data_contract_EVENT_VALUE],r10
 mov r10,[rax+r9+NEBO_EVENT_SEQUENCE]
 mov [rsi+NEBO_EVENT_SEQUENCE],r10
 mov r10,[rax+r9+NEBO_EVENT_FLAGS]
 mov [rsi+NEBO_EVENT_FLAGS],r10
 inc r8
 mov [rdi+NEBO_FLOW_INDEX],r8
 mov qword [rdx],1
 cmp r8,rcx
 jne .fn_ok
 or qword [rdi+NEBO_FLOW_FLAGS],NEBO_DATA_STREAM_COMPLETE
.fn_ok: xor eax,eax
 ret
.fn_complete:
 or qword [rdi+NEBO_FLOW_FLAGS],NEBO_DATA_STREAM_COMPLETE
 xor eax,eax
 ret
.fn_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.fn_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stream_init(stream*, event_array*, length, capacity)
NEBOC_ABI_FUNCTION neboc_stream_init
 test rdi,rdi
 jz .sti_bad
 test rdi,7
 jnz .sti_bad
 test rsi,rsi
 jz .sti_bad
 cmp rdx,NEBO_DATA_MAX_EVENTS
 ja .sti_limit
 test rcx,rcx
 jz .sti_limit
 cmp rcx,NEBO_DATA_MAX_EVENTS
 ja .sti_limit
 cmp rdx,rcx
 ja .sti_limit
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov ecx,nebo_data_contract_STREAM_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_STREAM_SOURCE],r13
 mov [r12+NEBO_STREAM_LENGTH],r14
 mov [r12+nebo_data_contract_STREAM_CAPACITY],r15
 mov qword [r12+NEBO_STREAM_GENERATION],1
 mov qword [r12+nebo_data_contract_STREAM_FLAGS],NEBO_DATA_STREAM_FINITE
 xor eax,eax
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sti_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.sti_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stream_configure(stream*, map_cb?, filter_cb?, context*)
; map(value, context, out_value*) -> status
; filter(value, context, out_bool*) -> status
NEBOC_ABI_FUNCTION neboc_stream_configure
 test rdi,rdi
 jz .sc_bad
 mov rax,[rdi+NEBO_STREAM_SOURCE]
 test rax,rax
 jz .sc_source
 cmp qword [rdi+NEBO_STREAM_INDEX],0
 jne .sc_source
 mov [rdi+NEBO_STREAM_MAP_CALLBACK],rsi
 mov [rdi+NEBO_STREAM_FILTER_CALLBACK],rdx
 mov [rdi+NEBO_STREAM_CONTEXT],rcx
 inc qword [rdi+NEBO_STREAM_GENERATION]
 xor eax,eax
 ret
.sc_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.sc_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stream_next(stream*, out_event*, out_has*)
NEBOC_ABI_FUNCTION neboc_stream_next
 test rdi,rdi
 jz .sn_bad
 test rsi,rsi
 jz .sn_bad
 test rdx,rdx
 jz .sn_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 push rbx
 sub rsp,24 ; keep SysV call alignment across source callback bridges
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 mov qword [r13+nebo_data_contract_EVENT_VALUE],0
 mov qword [r13+NEBO_EVENT_SEQUENCE],0
 mov qword [r13+NEBO_EVENT_FLAGS],0
 mov rax,[r12+NEBO_STREAM_SOURCE]
 test rax,rax
 jz .sn_source
 mov r15,[r12+NEBO_STREAM_LENGTH]
 cmp r15,[r12+nebo_data_contract_STREAM_CAPACITY]
 ja .sn_source
 cmp r15,NEBO_DATA_MAX_EVENTS
 ja .sn_source
.sn_loop:
 mov rbp,[r12+NEBO_STREAM_INDEX]
 cmp rbp,r15
 ja .sn_source
 je .sn_complete
 mov rax,rbp
 imul rax,nebo_data_contract_EVENT_SIZE
 mov rcx,[r12+NEBO_STREAM_SOURCE]
 mov rbx,[rcx+rax+nebo_data_contract_EVENT_VALUE]
 mov qword [rsp],1
 mov rax,[r12+NEBO_STREAM_FILTER_CALLBACK]
 test rax,rax
 jz .sn_map
 mov rdi,rbx
 mov rsi,[r12+NEBO_STREAM_CONTEXT]
 lea rdx,[rsp]
 call rax
 test eax,eax
 jnz .sn_done
 cmp qword [rsp],0
 jne .sn_map
 inc rbp
 mov [r12+NEBO_STREAM_INDEX],rbp
 jmp .sn_loop
.sn_map:
 mov [rsp+8],rbx
 mov rax,[r12+NEBO_STREAM_MAP_CALLBACK]
 test rax,rax
 jz .sn_emit
 mov rdi,rbx
 mov rsi,[r12+NEBO_STREAM_CONTEXT]
 lea rdx,[rsp+8]
 call rax
 test eax,eax
 jnz .sn_done
.sn_emit:
 mov rax,[rsp+8]
 mov [r13+nebo_data_contract_EVENT_VALUE],rax
 mov rax,rbp
 imul rax,nebo_data_contract_EVENT_SIZE
 mov rcx,[r12+NEBO_STREAM_SOURCE]
 mov rdx,[rcx+rax+NEBO_EVENT_SEQUENCE]
 mov [r13+NEBO_EVENT_SEQUENCE],rdx
 mov rdx,[rcx+rax+NEBO_EVENT_FLAGS]
 mov [r13+NEBO_EVENT_FLAGS],rdx
 inc rbp
 mov [r12+NEBO_STREAM_INDEX],rbp
 mov qword [r14],1
 cmp rbp,r15
 jne .sn_ok
 or qword [r12+nebo_data_contract_STREAM_FLAGS],NEBO_DATA_STREAM_COMPLETE
.sn_ok: xor eax,eax
 jmp .sn_done
.sn_complete:
 or qword [r12+nebo_data_contract_STREAM_FLAGS],NEBO_DATA_STREAM_COMPLETE
 xor eax,eax
 jmp .sn_done
.sn_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
.sn_done:
 add rsp,24
 pop rbx
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sn_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stream_consume(stream*, consumer_cb, context*, out_count*)
; consumer(value, context) -> status
NEBOC_ABI_FUNCTION neboc_stream_consume
 test rsi,rsi
 jz .sco_bad
 test rcx,rcx
 jz .sco_bad
 push r12
 push r13
 push r14
 push r15
 sub rsp,40 ; native next and consumer calls require aligned RSP
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r15],0
.sco_loop:
 mov rdi,r12
 lea rsi,[rsp]
 lea rdx,[rsp+24]
 call neboc_stream_next
 test eax,eax
 jnz .sco_done
 cmp qword [rsp+24],0
 je .sco_ok
 mov rdi,[rsp+nebo_data_contract_EVENT_VALUE]
 mov rsi,r14
 call r13
 test eax,eax
 jnz .sco_done
 inc qword [r15]
 jmp .sco_loop
.sco_ok: xor eax,eax
.sco_done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sco_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
