; Typed finite stream plans reuse the existing native Stream cursor, callback
; and sink owners. Ordered source map/filter stages are private caller storage,
; never global callbacks or an eager report computed during construction.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/data/data_contract.inc"
%include "compiler/semantic/collections/list_core.inc"
%define TSTREAM_CONTEXT 80
%define TSTREAM_STAGE_COUNT 80
%define TSTREAM_CACHED_VALUE 88
%define TSTREAM_STAGES 96
%define TSTREAM_EVENTS 384
%define TSTREAM_MAX_STAGES 16
%define TSTREAM_BATCH_SIZE 1920
%define TSTREAM_WINDOW_MODE 1928
extern neboc_stream_from
extern neboc_stream_map
extern neboc_stream_filter
extern neboc_stream_next
extern neboc_stream_sink
extern neboc_stream_batch
extern neboc_stream_window
extern neboc_flow_init
extern neboc_flow_value
extern neboc_event_value
extern neboc_list_validate
extern neboc_list_init
extern neboc_list_push
extern nebo_runtime_trap
section .text
; dst wrapper*, length. Event cells are already initialized in owned storage.
NEBOC_ABI_FUNCTION neboc_typed_stream_init
 push r12
 mov r12,rdi
 mov rdx,rsi
 lea rsi,[rdi+TSTREAM_EVENTS]
 mov ecx,64
 call neboc_stream_from
 test eax,eax
 jnz .done
 mov qword [r12+TSTREAM_STAGE_COUNT],0
 mov qword [r12+TSTREAM_CACHED_VALUE],0
 mov qword [r12+TSTREAM_BATCH_SIZE],0
 mov qword [r12+TSTREAM_WINDOW_MODE],0
.done:
 pop r12
 ret

; src wrapper*, kind (0 clone, 1 map, 2 filter), typed function*, dst wrapper*.
; Construction copies finite source data and the current cursor without invoking
; any transform. Only native next/sink executes these actual source functions.
NEBOC_ABI_FUNCTION neboc_typed_stream_stage_append
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 cmp r13,2
 ja .invalid
 test r13,r13
 jz .clone_capacity
 test r14,r14
 jz .invalid
 cmp qword [r12+TSTREAM_STAGE_COUNT],TSTREAM_MAX_STAGES
 jae .invalid
 jmp .capacity_ready
.clone_capacity:
 cmp qword [r12+TSTREAM_STAGE_COUNT],TSTREAM_MAX_STAGES
 ja .invalid
.capacity_ready:
 mov rbx,[r12+NEBO_STREAM_LENGTH]
 cmp rbx,64
 ja .invalid
 cmp [r12+NEBO_STREAM_INDEX],rbx
 ja .invalid
 lea rsi,[r12+TSTREAM_EVENTS]
 lea rdi,[r15+TSTREAM_EVENTS]
 lea rcx,[rbx+rbx*2]
 rep movsq
 mov rdi,r15
 mov rsi,rbx
 call neboc_typed_stream_init
 test eax,eax
 jnz .done
 mov rbx,[r12+TSTREAM_STAGE_COUNT]
 mov rcx,rbx
 shl rcx,1
 lea rsi,[r12+TSTREAM_STAGES]
 lea rdi,[r15+TSTREAM_STAGES]
 rep movsq
 test r13,r13
 jz .stages_ready
 mov [rdi],r13
 mov [rdi+8],r14
 inc rbx
.stages_ready:
 mov [r15+TSTREAM_STAGE_COUNT],rbx
 mov rdi,r15
 lea rsi,[rel typed_stream_cached_map]
 lea rdx,[r15+TSTREAM_CONTEXT]
 call neboc_stream_map
 test eax,eax
 jnz .done
 mov rdi,r15
 lea rsi,[rel typed_stream_ordered_filter]
 lea rdx,[r15+TSTREAM_CONTEXT]
 call neboc_stream_filter
 test eax,eax
 jnz .done
 ; Configure the freshly constructed owner before restoring the cloned
 ; cursor. The source stream is never reconfigured after consumption.
 mov rdx,[r12+NEBO_STREAM_INDEX]
 mov [r15+NEBO_STREAM_INDEX],rdx
 jmp .done
.invalid:
 mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Native filter ABI: value, context*, out_bool*. Apply the ordered typed stages
; once, stopping immediately on a false predicate. Native map then reads only
; the cached value, preserving the source order even for map().filter().
typed_stream_ordered_filter:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rsi
 mov r13,rdi
 mov r14,rdx
 xor ebx,ebx
 mov qword [r14],0
 cmp qword [r12],TSTREAM_MAX_STAGES
 ja .invalid
.stage:
 cmp rbx,[r12]
 jae .present
 mov r15,rbx
 shl r15,4
 lea r15,[r12+r15+16]
 mov rdi,r13
 call [r15+8]
 cmp qword [r15],1
 jne .predicate
 mov r13,rax
 jmp .next
.predicate:
 cmp rax,1
 ja .invalid
 test rax,rax
 jz .ok
.next:
 inc rbx
 jmp .stage
.present:
 mov [r12+8],r13
 mov qword [r14],1
.ok:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
typed_stream_cached_map:
 mov rax,[rsi+8]
 mov [rdx],rax
 xor eax,eax
 ret
; Source Void consumer has no returned status value. Its successful return
; maps to native OK; traps retain the source runtime trap behavior.
typed_stream_void_consumer:
 sub rsp,8
 call rsi
 xor eax,eax
 add rsp,8
 ret

NEBOC_ABI_FUNCTION nebo_stream_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,350
 je .array_new
 cmp ebx,351
 je .from_list
 cmp ebx,352
 je .event_new
 cmp ebx,353
 je .flow_new
 cmp ebx,354
 je .event_value
 cmp ebx,355
 je .flow_value
 cmp ebx,360
 je .map
 cmp ebx,361
 je .filter
 cmp ebx,362
 je .sink
 cmp ebx,363
 je .next
 cmp ebx,364
 je .batch
 cmp ebx,365
 je .batch_next
 cmp ebx,366
 je .batch_some
 cmp ebx,367
 je .batch_none
 cmp ebx,368
 je .batch_expect
 cmp ebx,369
 je .batch_sink
 cmp ebx,370
 je .window
 cmp ebx,380
 je .append
 jmp .trap
.array_new:
 mov rdi,r15
 xor esi,esi
 call neboc_typed_stream_init
 jmp .result_status
.from_list:
 mov rdi,r13
 call neboc_list_validate
 test eax,eax
 jnz .trap
 cmp qword [r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET],8
 jne .trap
 mov rdx,[r13+NEBOC_LIST_LENGTH_OFFSET]
 cmp rdx,64
 ja .trap
 mov rsi,[r13+NEBOC_LIST_DATA_OFFSET]
 xor ecx,ecx
.list_event:
 cmp rcx,rdx
 jae .list_done
 lea rax,[rcx+rcx*2]
 mov r8,[rsi+rcx*8]
 mov [r15+TSTREAM_EVENTS+rax*8],r8
 mov [r15+TSTREAM_EVENTS+rax*8+8],rcx
 mov qword [r15+TSTREAM_EVENTS+rax*8+16],0
 inc rcx
 jmp .list_event
.list_done:
 mov rdi,r15
 mov rsi,rdx
 call neboc_typed_stream_init
 jmp .result_status
.append:
 cmp qword [r12+TSTREAM_STAGE_COUNT],0
 jne .trap
 mov rsi,[r12+NEBO_STREAM_LENGTH]
 cmp rsi,64
 jae .trap
 lea rax,[rsi+rsi*2]
 mov [r12+TSTREAM_EVENTS+rax*8],r13
 mov [r12+TSTREAM_EVENTS+rax*8+8],rsi
 mov qword [r12+TSTREAM_EVENTS+rax*8+16],0
 inc rsi
 mov rdi,r12
 call neboc_typed_stream_init
 test eax,eax
 jnz .trap
 mov rax,r12
 jmp .done
.event_new:
 mov [r15+nebo_data_contract_EVENT_VALUE],r13
 mov qword [r15+NEBO_EVENT_SEQUENCE],0
 mov qword [r15+NEBO_EVENT_FLAGS],0
 jmp .result
.flow_new:
 mov [r15+64+nebo_data_contract_EVENT_VALUE],r13
 mov qword [r15+64+NEBO_EVENT_SEQUENCE],0
 mov qword [r15+64+NEBO_EVENT_FLAGS],0
 mov rdi,r15
 lea rsi,[r15+64]
 mov edx,1
 call neboc_flow_init
 jmp .result_status
.event_value:
 mov rdi,r12
 mov rsi,r15
 call neboc_event_value
 jmp .scalar_status
.flow_value:
 mov rdi,r12
 mov rsi,r15
 call neboc_flow_value
 jmp .scalar_status
.map:
 mov esi,1
 jmp .stage
.filter:
 mov esi,2
.stage:
 mov rdi,r12
 mov rdx,r13
 mov rcx,r15
 call neboc_typed_stream_stage_append
 jmp .result_status
.sink:
 mov rdi,r12
 lea rsi,[rel typed_stream_void_consumer]
 mov rdx,r13
 mov rcx,r15
 call neboc_stream_sink
 jmp .scalar_status
.next:
 mov rdi,r12
 mov rsi,rsp
 mov rdx,r15
 call neboc_stream_next
 test eax,eax
 jnz .trap
 mov rax,[rsp+nebo_data_contract_EVENT_VALUE]
 mov [r15+8],rax
 jmp .result
.window:
 test r13,r13
 jle .trap
.batch:
 ; Clone the finite cursor and ordered transformations, then authenticate
 ; the native batch policy without consuming any source element.
 mov rdi,r12
 xor esi,esi
 xor edx,edx
 mov rcx,r15
 call neboc_typed_stream_stage_append
 test eax,eax
 jnz .trap
 mov rax,[r15+NEBO_STREAM_INDEX]
 mov [rsp+24],rax
 mov qword [r15+NEBO_STREAM_INDEX],0
 mov rdi,r15
 mov rsi,r13
 mov rdx,rsp
 cmp ebx,370
 je .configure_window
 call neboc_stream_batch
 jmp .configured
.configure_window:
 call neboc_stream_window
 mov qword [r15+TSTREAM_WINDOW_MODE],1
.configured:
 test eax,eax
 jnz .trap
 mov rax,[rsp+24]
 mov [r15+NEBO_STREAM_INDEX],rax
 mov [r15+TSTREAM_BATCH_SIZE],r13
 jmp .result
.batch_next:
 cmp qword [r12+TSTREAM_BATCH_SIZE],1
 jb .trap
 cmp qword [r12+TSTREAM_WINDOW_MODE],1
 je .window_init
 cmp qword [r12+TSTREAM_BATCH_SIZE],64
 ja .trap
.window_init:
 mov qword [r15],0
 lea rdi,[r15+16]
 lea rsi,[r15+96]
 mov edx,64
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz .trap
 cmp qword [r12+TSTREAM_WINDOW_MODE],1
 je .window_bucket
.batch_element:
 mov rax,[r15+16+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r12+TSTREAM_BATCH_SIZE]
 jae .batch_ready
 mov rdi,r12
 mov rsi,rsp
 lea rdx,[rsp+24]
 call neboc_stream_next
 test eax,eax
 jnz .trap
 cmp qword [rsp+24],0
 je .batch_ready
 lea rdi,[r15+16]
 mov rsi,rsp
 call neboc_list_push
 test eax,eax
 jnz .trap
 jmp .batch_element
; Event.sequence is the canonical bounded stream timestamp. Restrict the
; native cursor to one bucket before invoking callbacks; no lookahead effect
; belonging to a later window may execute early. Empty filtered buckets vanish.
.window_bucket:
 mov rax,[r12+NEBO_STREAM_LENGTH]
 mov [rsp+32],rax
 mov rcx,[r12+NEBO_STREAM_INDEX]
 cmp rcx,rax
 jae .batch_ready
 lea rax,[rcx+rcx*2]
 mov rax,[r12+TSTREAM_EVENTS+rax*8+NEBO_EVENT_SEQUENCE]
 xor edx,edx
 div qword [r12+TSTREAM_BATCH_SIZE]
 mov [rsp+48],rax
.window_bound:
 inc rcx
 cmp rcx,[rsp+32]
 jae .window_bounded
 lea rax,[rcx+rcx*2]
 mov rax,[r12+TSTREAM_EVENTS+rax*8+NEBO_EVENT_SEQUENCE]
 xor edx,edx
 div qword [r12+TSTREAM_BATCH_SIZE]
 cmp rax,[rsp+48]
 je .window_bound
.window_bounded:
 mov [r12+NEBO_STREAM_LENGTH],rcx
.window_element:
 mov rdi,r12
 mov rsi,rsp
 lea rdx,[rsp+24]
 call neboc_stream_next
 test eax,eax
 jnz .trap
 cmp qword [rsp+24],0
 je .window_restore
 lea rdi,[r15+16]
 mov rsi,rsp
 call neboc_list_push
 test eax,eax
 jnz .trap
 jmp .window_element
.window_restore:
 mov rax,[rsp+32]
 mov [r12+NEBO_STREAM_LENGTH],rax
 cmp [r12+NEBO_STREAM_INDEX],rax
 jae .window_complete
 and qword [r12+nebo_data_contract_STREAM_FLAGS],~NEBO_DATA_STREAM_COMPLETE
.window_complete:
 cmp qword [r15+16+NEBOC_LIST_LENGTH_OFFSET],0
 je .window_bucket
 jmp .batch_ready
.batch_ready:
 cmp qword [r15+16+NEBOC_LIST_LENGTH_OFFSET],0
 setne al
 movzx eax,al
 mov [r15],rax
 jmp .result
.batch_sink:
 ; Each callback borrows one actual List batch. Storage is private to this
 ; invocation and can neither alias a retained batch nor escape as a scalar.
 sub rsp,704
 xor ebx,ebx
.batch_sink_next:
 mov edi,365
 mov rsi,r12
 xor edx,edx
 xor ecx,ecx
 mov r8,rsp
 call nebo_stream_call
 cmp qword [rsp],0
 je .batch_sink_done
 lea rdi,[rsp+16]
 call r13
 inc rbx
 jmp .batch_sink_next
.batch_sink_done:
 add rsp,704
 mov rax,rbx
 jmp .done
.batch_some:
 mov rax,[r12]
 jmp .done
.batch_none:
 xor eax,eax
 cmp qword [r12],0
 sete al
 jmp .done
.batch_expect:
 cmp qword [r12],1
 jne .trap
 ; Move the owned List payload to independent caller storage. A subsequent
 ; next at the same source call site cannot overwrite a retained batch.
 lea rdi,[r12+16]
 call neboc_list_validate
 test eax,eax
 jnz .trap
 mov rdi,r15
 lea rsi,[r15+80]
 mov edx,64
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz .trap
 mov rcx,[r12+16+NEBOC_LIST_LENGTH_OFFSET]
 mov [r15+NEBOC_LIST_LENGTH_OFFSET],rcx
 mov rsi,[r12+16+NEBOC_LIST_DATA_OFFSET]
 mov rdi,[r15+NEBOC_LIST_DATA_OFFSET]
 rep movsq
 mov qword [r12],0
 jmp .result
.result_status:
 test eax,eax
 jnz .trap
.result:
 mov rax,r15
 jmp .done
.scalar_status:
 test eax,eax
 jnz .trap
 mov rax,[r15]
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 mov edi,49
 call nebo_runtime_trap
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
