; G104 target-neutral window backend, event-loop and renderer lifecycle.
; Callback ABI (System V AMD64):
;   open(ctx, user_data) -> 0 on success
;   close(ctx, user_data) -> 0 on success
;   present(ctx, user_data, frame_id, digest) -> 0 on success
;   run_once(ctx, user_data, event, processed_out) -> 0 on success
; All public mutations are validated before publication.  Adapter failures do
; not publish a successful frame/event transition.
bits 64
default rel
%define NEBO_G104_LIVE_CONSOLE_IMPLEMENTATION 1
%include "runtime/console/live_console.inc"

global nebo_visual_console_registry_init
global nebo_visual_console_registry_register
global nebo_visual_console_registry_hash
global nebo_visual_console_renderer_key
global nebo_visual_console_is_available
global nebo_visual_console_open_default
global nebo_visual_console_begin_frame
global nebo_visual_console_end_frame
global nebo_visual_console_run_once
global nebo_visual_console_should_close
global nebo_visual_console_close
global nebo_visual_console_evidence
global nebo_visual_console_shape_text

section .text

; RDI=destination, RSI=qword count.
g104_zero_qwords:
 xor eax,eax
 mov rcx,rsi
 cld
 rep stosq
 ret

; RDI=registry. Return entry pointer or zero for ESI=backend, EDX=renderer,
; ECX=target. Target-specific entries win over target-neutral entries.
g104_lookup:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13d,esi
 mov r14d,edx
 xor ebx,ebx
 test r12,r12
 jz .none
 cmp qword [r12+NEBO_G104_REGISTRY_FLAGS_OFFSET],NEBO_G104_REGISTRY_FLAG_READY
 jne .none
 mov r10,[r12+NEBO_G104_REGISTRY_ENTRIES_PTR_OFFSET]
 test r10,r10
 jz .none
 mov r11,[r12+NEBO_G104_REGISTRY_COUNT_OFFSET]
 xor r9d,r9d
.loop:
 cmp r9,r11
 jae .finish
 imul rax,r9,NEBO_G104_ENTRY_SIZE
 add rax,r10
 test qword [rax+NEBO_G104_ENTRY_FLAGS_OFFSET],NEBO_G104_ENTRY_FLAG_ENABLED
 jz .next
 cmp dword [rax+NEBO_G104_ENTRY_BACKEND_OFFSET],r13d
 jne .next
 cmp dword [rax+NEBO_G104_ENTRY_RENDERER_OFFSET],r14d
 jne .next
 cmp dword [rax+NEBO_G104_ENTRY_TARGET_OFFSET],ecx
 je .exact
 cmp dword [rax+NEBO_G104_ENTRY_TARGET_OFFSET],NEBO_G104_TARGET_ANY
 jne .next
 test rbx,rbx
 cmovz rbx,rax
.next:
 inc r9
 jmp .loop
.exact:
 mov rbx,rax
 jmp .finish
.finish:
 mov rax,rbx
 jmp .done
.none:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Deterministic FNV-1a over public descriptor identity, excluding addresses.
; RDI=registry -> RAX=hash, zero on invalid registry.
nebo_visual_console_registry_hash:
 push rbx
 push r12
 push r13
 test rdi,rdi
 jz .bad
 cmp qword [rdi+NEBO_G104_REGISTRY_FLAGS_OFFSET],NEBO_G104_REGISTRY_FLAG_READY
 jne .bad
 mov r12,[rdi+NEBO_G104_REGISTRY_ENTRIES_PTR_OFFSET]
 mov r13,[rdi+NEBO_G104_REGISTRY_COUNT_OFFSET]
 test r12,r12
 jz .bad
 mov rax,0xcbf29ce484222325
 mov r8,0x100000001b3
 xor ebx,ebx
.entry:
 cmp rbx,r13
 jae .done
 imul rcx,rbx,NEBO_G104_ENTRY_SIZE
 add rcx,r12
 xor edx,edx
.field:
 cmp edx,4
 jae .wide
 mov r9d,[rcx+rdx*4]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .field
.wide:
 mov r9,[rcx+NEBO_G104_ENTRY_CAPABILITIES_OFFSET]
 xor rax,r9
 imul rax,r8
 mov r9,[rcx+NEBO_G104_ENTRY_FLAGS_OFFSET]
 xor rax,r9
 imul rax,r8
.next:
 inc rbx
 jmp .entry
.bad:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; RDI=registry, RSI=caller-owned entries, RDX=capacity.
nebo_visual_console_registry_init:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 cmp r13,NEBO_G104_REGISTRY_BUILTIN_COUNT
 jb .limit
 cmp r13,NEBO_G104_REGISTRY_MAX_ENTRIES
 ja .limit

 mov rdi,rbx
 mov esi,NEBO_G104_REGISTRY_QWORDS
 call g104_zero_qwords
 mov rdi,r12
 mov esi,NEBO_G104_ENTRY_QWORDS*NEBO_G104_REGISTRY_BUILTIN_COUNT
 call g104_zero_qwords
 mov [rbx+NEBO_G104_REGISTRY_ENTRIES_PTR_OFFSET],r12
 mov [rbx+NEBO_G104_REGISTRY_CAPACITY_OFFSET],r13
 mov qword [rbx+NEBO_G104_REGISTRY_COUNT_OFFSET],NEBO_G104_REGISTRY_BUILTIN_COUNT
 mov qword [rbx+NEBO_G104_REGISTRY_GENERATION_OFFSET],1
 mov qword [rbx+NEBO_G104_REGISTRY_FLAGS_OFFSET],NEBO_G104_REGISTRY_FLAG_READY

 ; Built-ins are deterministic software paths and make no hardware claim.
 mov dword [r12+NEBO_G104_ENTRY_BACKEND_OFFSET],NEBO_G104_BACKEND_PLAIN
 mov dword [r12+NEBO_G104_ENTRY_RENDERER_OFFSET],NEBO_G104_RENDERER_SOFTWARE
 mov dword [r12+NEBO_G104_ENTRY_TARGET_OFFSET],NEBO_G104_TARGET_ANY
 mov dword [r12+NEBO_G104_ENTRY_MATURITY_OFFSET],NEBO_G104_MATURITY_HEADLESS_RENDERER_GREEN
 mov qword [r12+NEBO_G104_ENTRY_CAPABILITIES_OFFSET],NEBO_G104_CAP_ALL
 mov qword [r12+NEBO_G104_ENTRY_FLAGS_OFFSET],NEBO_G104_ENTRY_FLAG_ENABLED|NEBO_G104_ENTRY_FLAG_BUILTIN
 lea rax,[r12+NEBO_G104_ENTRY_SIZE]
 mov dword [rax+NEBO_G104_ENTRY_BACKEND_OFFSET],NEBO_G104_BACKEND_HEADLESS
 mov dword [rax+NEBO_G104_ENTRY_RENDERER_OFFSET],NEBO_G104_RENDERER_SOFTWARE
 mov dword [rax+NEBO_G104_ENTRY_TARGET_OFFSET],NEBO_G104_TARGET_ANY
 mov dword [rax+NEBO_G104_ENTRY_MATURITY_OFFSET],NEBO_G104_MATURITY_HEADLESS_RENDERER_GREEN
 mov qword [rax+NEBO_G104_ENTRY_CAPABILITIES_OFFSET],NEBO_G104_CAP_ALL
 mov qword [rax+NEBO_G104_ENTRY_FLAGS_OFFSET],NEBO_G104_ENTRY_FLAG_ENABLED|NEBO_G104_ENTRY_FLAG_BUILTIN
 add rax,NEBO_G104_ENTRY_SIZE
 mov dword [rax+NEBO_G104_ENTRY_BACKEND_OFFSET],NEBO_G104_BACKEND_ANSI
 mov dword [rax+NEBO_G104_ENTRY_RENDERER_OFFSET],NEBO_G104_RENDERER_SOFTWARE
 mov dword [rax+NEBO_G104_ENTRY_TARGET_OFFSET],NEBO_G104_TARGET_ANY
 mov dword [rax+NEBO_G104_ENTRY_MATURITY_OFFSET],NEBO_G104_MATURITY_HEADLESS_RENDERER_GREEN
 mov qword [rax+NEBO_G104_ENTRY_CAPABILITIES_OFFSET],NEBO_G104_CAP_ALL
 mov qword [rax+NEBO_G104_ENTRY_FLAGS_OFFSET],NEBO_G104_ENTRY_FLAG_ENABLED|NEBO_G104_ENTRY_FLAG_BUILTIN
 mov rdi,rbx
 call nebo_visual_console_registry_hash
 mov [rbx+NEBO_G104_REGISTRY_STATE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.limit:
 mov eax,-NEBO_G104_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; RDI=registry, RSI=descriptor. The descriptor is copied on success.
nebo_visual_console_registry_register:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 cmp qword [rbx+NEBO_G104_REGISTRY_FLAGS_OFFSET],NEBO_G104_REGISTRY_FLAG_READY
 jne .invalid
 mov eax,[r12+NEBO_G104_ENTRY_BACKEND_OFFSET]
 cmp eax,NEBO_G104_BACKEND_PLAIN
 jb .invalid
 cmp eax,NEBO_G104_BACKEND_MAX
 ja .invalid
 mov r13d,eax
 mov eax,[r12+NEBO_G104_ENTRY_RENDERER_OFFSET]
 cmp eax,NEBO_G104_RENDERER_SOFTWARE
 jb .invalid
 cmp eax,NEBO_G104_RENDERER_MAX
 ja .invalid
 mov r14d,eax
 mov eax,[r12+NEBO_G104_ENTRY_TARGET_OFFSET]
 cmp eax,NEBO_G104_TARGET_MAX
 ja .invalid
 mov r15d,eax
 mov eax,[r12+NEBO_G104_ENTRY_MATURITY_OFFSET]
 cmp eax,NEBO_G104_MATURITY_CONTRACT_GREEN
 jb .invalid
 cmp eax,NEBO_G104_MATURITY_LIVE_WINDOW_HARDWARE_GREEN
 ja .invalid
 mov rax,[r12+NEBO_G104_ENTRY_CAPABILITIES_OFFSET]
 test rax,rax
 jz .invalid
 mov rdx,rax
 and rdx,~NEBO_G104_CAP_ALL
 jnz .invalid
 mov rax,[r12+NEBO_G104_ENTRY_FLAGS_OFFSET]
 test rax,NEBO_G104_ENTRY_FLAG_ENABLED
 jz .invalid
 mov rdx,rax
 and rdx,~NEBO_G104_ENTRY_KNOWN_FLAGS
 jnz .invalid
 cmp dword [r12+NEBO_G104_ENTRY_MATURITY_OFFSET],NEBO_G104_MATURITY_LIVE_WINDOW_HARDWARE_GREEN
 jne .capacity
 test rax,NEBO_G104_ENTRY_FLAG_LIVE
 jz .invalid
 cmp qword [r12+NEBO_G104_ENTRY_OPEN_FN_OFFSET],0
 je .invalid
 cmp qword [r12+NEBO_G104_ENTRY_CLOSE_FN_OFFSET],0
 je .invalid
 test qword [r12+NEBO_G104_ENTRY_CAPABILITIES_OFFSET],NEBO_G104_CAP_FRAME
 jz .live_events
 cmp qword [r12+NEBO_G104_ENTRY_PRESENT_FN_OFFSET],0
 je .invalid
.live_events:
 test qword [r12+NEBO_G104_ENTRY_CAPABILITIES_OFFSET],NEBO_G104_CAP_EVENTS
 jz .capacity
 cmp qword [r12+NEBO_G104_ENTRY_RUN_ONCE_FN_OFFSET],0
 je .invalid
.capacity:
 mov rax,[rbx+NEBO_G104_REGISTRY_COUNT_OFFSET]
 cmp rax,[rbx+NEBO_G104_REGISTRY_CAPACITY_OFFSET]
 jae .limit
 mov rdi,rbx
 mov esi,r13d
 mov edx,r14d
 mov ecx,r15d
 call g104_lookup
 test rax,rax
 jnz .duplicate
 mov rdx,[rbx+NEBO_G104_REGISTRY_COUNT_OFFSET]
 imul rdx,rdx,NEBO_G104_ENTRY_SIZE
 add rdx,[rbx+NEBO_G104_REGISTRY_ENTRIES_PTR_OFFSET]
 mov rdi,rdx
 mov rsi,r12
 mov ecx,NEBO_G104_ENTRY_QWORDS
 cld
 rep movsq
 inc qword [rbx+NEBO_G104_REGISTRY_COUNT_OFFSET]
 inc qword [rbx+NEBO_G104_REGISTRY_GENERATION_OFFSET]
 mov rdi,rbx
 call nebo_visual_console_registry_hash
 mov [rbx+NEBO_G104_REGISTRY_STATE_HASH_OFFSET],rax
 mov qword [rbx+NEBO_G104_REGISTRY_LAST_STATUS_OFFSET],NEBO_G104_STATUS_OK
 xor eax,eax
 jmp .done
.duplicate:
 mov eax,-NEBO_G104_STATUS_DUPLICATE
 jmp .status
.limit:
 mov eax,-NEBO_G104_STATUS_LIMIT_EXCEEDED
 jmp .status
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
.status:
 test rbx,rbx
 jz .done
 movsxd rdx,eax
 neg rdx
 mov [rbx+NEBO_G104_REGISTRY_LAST_STATUS_OFFSET],rdx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=UTF-8 bytes, RSI=length, RDX=renderer out.
nebo_visual_console_renderer_key:
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,8
 je .software
 cmp rsi,6
 je .opengl
 cmp rsi,4
 je .bgfx
 jmp .unsupported
.software:
 cmp dword [rdi],0x74666f73       ; soft
 jne .unsupported
 cmp dword [rdi+4],0x65726177     ; ware
 jne .unsupported
 mov dword [rdx],NEBO_G104_RENDERER_SOFTWARE
 xor eax,eax
 ret
.opengl:
 cmp dword [rdi],0x6e65706f       ; open
 jne .unsupported
 cmp word [rdi+4],0x6c67          ; gl
 jne .unsupported
 mov dword [rdx],NEBO_G104_RENDERER_OPENGL
 xor eax,eax
 ret
.bgfx:
 cmp dword [rdi],0x78666762       ; bgfx
 jne .unsupported
 mov dword [rdx],NEBO_G104_RENDERER_BGFX
 xor eax,eax
 ret
.unsupported:
 mov eax,-NEBO_G104_STATUS_UNSUPPORTED
 ret
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 ret

; RDI=registry, ESI=backend, EDX=renderer, ECX=target -> 0/1 or negative.
nebo_visual_console_is_available:
 cmp esi,NEBO_G104_BACKEND_PLAIN
 jb .invalid
 cmp esi,NEBO_G104_BACKEND_MAX
 ja .invalid
 cmp edx,NEBO_G104_RENDERER_SOFTWARE
 jb .invalid
 cmp edx,NEBO_G104_RENDERER_MAX
 ja .invalid
 cmp ecx,NEBO_G104_TARGET_MAX
 ja .invalid
 call g104_lookup
 test rax,rax
 setnz al
 movzx eax,al
 ret
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 ret

; RDI=context, RSI=registry, RDX=request.
nebo_visual_console_open_default:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 mov eax,[r13+NEBO_G104_REQUEST_BACKEND_OFFSET]
 test eax,eax
 jnz .backend
 mov eax,NEBO_G104_BACKEND_HEADLESS
.backend:
 cmp eax,NEBO_G104_BACKEND_PLAIN
 jb .invalid
 cmp eax,NEBO_G104_BACKEND_MAX
 ja .invalid
 mov r14d,eax
 mov eax,[r13+NEBO_G104_REQUEST_RENDERER_OFFSET]
 test eax,eax
 jnz .renderer
 mov eax,NEBO_G104_RENDERER_SOFTWARE
.renderer:
 cmp eax,NEBO_G104_RENDERER_SOFTWARE
 jb .invalid
 cmp eax,NEBO_G104_RENDERER_MAX
 ja .invalid
 mov r15d,eax
 mov ecx,[r13+NEBO_G104_REQUEST_TARGET_OFFSET]
 test ecx,ecx
 jnz .target
 mov ecx,NEBO_G104_TARGET_LINUX_X86_64
.target:
 cmp ecx,NEBO_G104_TARGET_MAX
 ja .invalid
 mov [rsp],rcx
 cmp dword [r13+NEBO_G104_REQUEST_RESERVED_OFFSET],0
 jne .invalid
 mov rax,[r13+NEBO_G104_REQUEST_WIDTH_OFFSET]
 cmp rax,NEBO_G104_MIN_WIDTH
 jb .invalid
 cmp rax,NEBO_G104_MAX_WIDTH
 ja .limit
 mov rax,[r13+NEBO_G104_REQUEST_HEIGHT_OFFSET]
 cmp rax,NEBO_G104_MIN_HEIGHT
 jb .invalid
 cmp rax,NEBO_G104_MAX_HEIGHT
 ja .limit
 mov rax,[r13+NEBO_G104_REQUEST_EVENT_CAPACITY_OFFSET]
 cmp rax,NEBO_G104_MIN_EVENTS
 jb .invalid
 cmp rax,NEBO_G104_MAX_EVENTS
 ja .limit
 mov rax,[r13+NEBO_G104_REQUEST_REQUIRED_CAPABILITIES_OFFSET]
 mov rdx,rax
 and rdx,~NEBO_G104_CAP_ALL
 jnz .invalid
 mov rax,[r13+NEBO_G104_REQUEST_FLAGS_OFFSET]
 mov rdx,rax
 and rdx,~NEBO_G104_REQUEST_REQUIRED_FLAGS
 jnz .invalid
 and eax,NEBO_G104_REQUEST_REQUIRED_FLAGS
 cmp eax,NEBO_G104_REQUEST_REQUIRED_FLAGS
 jne .invalid
 mov rdi,r12
 mov esi,r14d
 mov edx,r15d
 mov ecx,[rsp]
 call g104_lookup
 test rax,rax
 jz .unavailable
 mov [rsp+8],rax
 mov rdx,[r13+NEBO_G104_REQUEST_REQUIRED_CAPABILITIES_OFFSET]
 mov rcx,[rax+NEBO_G104_ENTRY_CAPABILITIES_OFFSET]
 and rcx,rdx
 cmp rcx,rdx
 jne .unsupported

 mov rdi,rbx
 mov esi,NEBO_G104_CONTEXT_QWORDS
 call g104_zero_qwords
 mov rax,NEBO_G104_CONTEXT_MAGIC
 mov [rbx+NEBO_G104_CONTEXT_MAGIC_OFFSET],rax
 mov [rbx+NEBO_G104_CONTEXT_REGISTRY_PTR_OFFSET],r12
 mov rax,[rsp+8]
 mov [rbx+NEBO_G104_CONTEXT_ENTRY_PTR_OFFSET],rax
 mov [rbx+NEBO_G104_CONTEXT_BACKEND_OFFSET],r14d
 mov [rbx+NEBO_G104_CONTEXT_RENDERER_OFFSET],r15d
 mov eax,[rsp]
 mov [rbx+NEBO_G104_CONTEXT_TARGET_OFFSET],eax
 mov dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_OPEN
 mov rax,[r13+NEBO_G104_REQUEST_WIDTH_OFFSET]
 mov [rbx+NEBO_G104_CONTEXT_WIDTH_OFFSET],rax
 mov rax,[r13+NEBO_G104_REQUEST_HEIGHT_OFFSET]
 mov [rbx+NEBO_G104_CONTEXT_HEIGHT_OFFSET],rax
 mov rax,[r13+NEBO_G104_REQUEST_FLAGS_OFFSET]
 mov [rbx+NEBO_G104_CONTEXT_FLAGS_OFFSET],rax
 mov rax,[r13+NEBO_G104_REQUEST_EVENT_CAPACITY_OFFSET]
 mov [rbx+NEBO_G104_CONTEXT_EVENT_CAPACITY_OFFSET],rax
 mov rax,[rsp+8]
 mov rcx,[rax+NEBO_G104_ENTRY_USER_DATA_OFFSET]
 mov [rbx+NEBO_G104_CONTEXT_CALLBACK_DATA_OFFSET],rcx
 mov rax,[rax+NEBO_G104_ENTRY_OPEN_FN_OFFSET]
 test rax,rax
 jz .ok
 mov rdi,rbx
 mov rsi,[rbx+NEBO_G104_CONTEXT_CALLBACK_DATA_OFFSET]
 call rax
 test eax,eax
 jnz .adapter_open
.ok:
 xor eax,eax
 jmp .done
.adapter_open:
 ; A failed host open may already own a partial native resource. Invoke its
 ; paired close callback before making the failed context unobservable.
 mov rax,[rsp+8]
 mov rax,[rax+NEBO_G104_ENTRY_CLOSE_FN_OFFSET]
 test rax,rax
 jz .zero_failed_open
 mov rdi,rbx
 mov rsi,[rbx+NEBO_G104_CONTEXT_CALLBACK_DATA_OFFSET]
 call rax
.zero_failed_open:
 mov rdi,rbx
 mov esi,NEBO_G104_CONTEXT_QWORDS
 call g104_zero_qwords
 mov eax,-NEBO_G104_STATUS_ADAPTER_FAILURE
 jmp .done
.unsupported:
 mov eax,-NEBO_G104_STATUS_UNSUPPORTED
 jmp .done
.unavailable:
 mov eax,-NEBO_G104_STATUS_BACKEND_UNAVAILABLE
 jmp .done
.limit:
 mov eax,-NEBO_G104_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=context, RSI=frame-id out.
nebo_visual_console_begin_frame:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,NEBO_G104_CONTEXT_MAGIC
 cmp [rdi+NEBO_G104_CONTEXT_MAGIC_OFFSET],rax
 jne .invalid
 cmp dword [rdi+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_OPEN
 jne .state
 mov rax,[rdi+NEBO_G104_CONTEXT_FRAME_ID_OFFSET]
 inc rax
 jz .limit
 mov [rdi+NEBO_G104_CONTEXT_FRAME_ID_OFFSET],rax
 mov dword [rdi+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_FRAME
 mov [rsi],rax
 xor eax,eax
 ret
.limit: mov eax,-NEBO_G104_STATUS_LIMIT_EXCEEDED
 ret
.state: mov eax,-NEBO_G104_STATUS_BAD_STATE
 ret
.invalid: mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 ret

; RDI=context, RSI=frame id, RDX=render digest.
nebo_visual_console_end_frame:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 mov rax,NEBO_G104_CONTEXT_MAGIC
 cmp [rbx+NEBO_G104_CONTEXT_MAGIC_OFFSET],rax
 jne .invalid
 cmp dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_FRAME
 jne .state
 cmp [rbx+NEBO_G104_CONTEXT_FRAME_ID_OFFSET],r12
 jne .mismatch
 mov r14,[rbx+NEBO_G104_CONTEXT_ENTRY_PTR_OFFSET]
 test r14,r14
 jz .invalid
 mov rax,[r14+NEBO_G104_ENTRY_PRESENT_FN_OFFSET]
 test rax,rax
 jz .publish
 mov rdi,rbx
 mov rsi,[rbx+NEBO_G104_CONTEXT_CALLBACK_DATA_OFFSET]
 mov rdx,r12
 mov rcx,r13
 call rax
 test eax,eax
 jnz .adapter
.publish:
 mov [rbx+NEBO_G104_CONTEXT_LAST_DIGEST_OFFSET],r13
 inc qword [rbx+NEBO_G104_CONTEXT_PRESENT_COUNT_OFFSET]
 mov dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_OPEN
 xor eax,eax
 jmp .done
.adapter: mov eax,-NEBO_G104_STATUS_ADAPTER_FAILURE
 jmp .done
.mismatch: mov eax,-NEBO_G104_STATUS_FRAME_MISMATCH
 jmp .done
.state: mov eax,-NEBO_G104_STATUS_BAD_STATE
 jmp .done
.invalid: mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=context, RSI=event, RDX=processed out.
nebo_visual_console_run_once:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 mov rax,NEBO_G104_CONTEXT_MAGIC
 cmp [rbx+NEBO_G104_CONTEXT_MAGIC_OFFSET],rax
 jne .invalid
 cmp dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_OPEN
 jne .state
 mov eax,[r12+NEBO_G104_EVENT_KIND_OFFSET]
 cmp eax,NEBO_G104_EVENT_MAX
 ja .invalid
 cmp dword [r12+NEBO_G104_EVENT_FLAGS_OFFSET],0
 jne .invalid
 mov rax,[rbx+NEBO_G104_CONTEXT_EVENT_COUNT_OFFSET]
 cmp rax,[rbx+NEBO_G104_CONTEXT_EVENT_CAPACITY_OFFSET]
 jae .event_limit
 mov r14,[rbx+NEBO_G104_CONTEXT_ENTRY_PTR_OFFSET]
 mov rax,[r14+NEBO_G104_ENTRY_RUN_ONCE_FN_OFFSET]
 test rax,rax
 jz .builtin
 sub rsp,16
 mov qword [rsp],0
 mov rdi,rbx
 mov rsi,[rbx+NEBO_G104_CONTEXT_CALLBACK_DATA_OFFSET]
 mov rdx,r12
 lea rcx,[rsp]
 call rax
 test eax,eax
 jnz .adapter_pop
 mov rax,[rsp]
 cmp rax,1
 ja .invalid_pop
 add rsp,16
 test rax,rax
 jz .not_processed
 inc qword [rbx+NEBO_G104_CONTEXT_EVENT_COUNT_OFFSET]
 mov [r13],rax
 xor eax,eax
 jmp .done
.adapter_pop:
 add rsp,16
 mov eax,-NEBO_G104_STATUS_ADAPTER_FAILURE
 jmp .done
.invalid_pop:
 add rsp,16
 jmp .invalid
.builtin:
 mov eax,[r12+NEBO_G104_EVENT_KIND_OFFSET]
 test eax,eax
 jz .not_processed
 cmp eax,NEBO_G104_EVENT_RESIZED
 jne .commit_kind
 mov rax,[r12+NEBO_G104_EVENT_PAYLOAD0_OFFSET]
 cmp rax,NEBO_G104_MIN_WIDTH
 jb .invalid
 cmp rax,NEBO_G104_MAX_WIDTH
 ja .limit
 mov rcx,[r12+NEBO_G104_EVENT_PAYLOAD1_OFFSET]
 cmp rcx,NEBO_G104_MIN_HEIGHT
 jb .invalid
 cmp rcx,NEBO_G104_MAX_HEIGHT
 ja .limit
 mov [rbx+NEBO_G104_CONTEXT_WIDTH_OFFSET],rax
 mov [rbx+NEBO_G104_CONTEXT_HEIGHT_OFFSET],rcx
.commit_kind:
 cmp eax,NEBO_G104_EVENT_CLOSE_REQUESTED
 jne .failure
 mov qword [rbx+NEBO_G104_CONTEXT_SHOULD_CLOSE_OFFSET],1
.failure:
 cmp eax,NEBO_G104_EVENT_BACKEND_FAILURE
 jne .processed
 mov qword [rbx+NEBO_G104_CONTEXT_SHOULD_CLOSE_OFFSET],1
 mov dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_FAILED
 inc qword [rbx+NEBO_G104_CONTEXT_EVENT_COUNT_OFFSET]
 mov qword [r13],1
 mov eax,-NEBO_G104_STATUS_ADAPTER_FAILURE
 jmp .done
.processed:
 inc qword [rbx+NEBO_G104_CONTEXT_EVENT_COUNT_OFFSET]
 mov qword [r13],1
 xor eax,eax
 jmp .done
.not_processed:
 mov qword [r13],0
 xor eax,eax
 jmp .done
.event_limit: mov eax,-NEBO_G104_STATUS_EVENT_LIMIT
 jmp .done
.limit: mov eax,-NEBO_G104_STATUS_LIMIT_EXCEEDED
 jmp .done
.state: mov eax,-NEBO_G104_STATUS_BAD_STATE
 jmp .done
.invalid: mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=context, RSI=boolean out.
nebo_visual_console_should_close:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,NEBO_G104_CONTEXT_MAGIC
 cmp [rdi+NEBO_G104_CONTEXT_MAGIC_OFFSET],rax
 jne .invalid
 mov rax,[rdi+NEBO_G104_CONTEXT_SHOULD_CLOSE_OFFSET]
 mov [rsi],rax
 xor eax,eax
 ret
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 ret

; RDI=context. Close is idempotent; an active frame must be ended first.
nebo_visual_console_close:
 push rbx
 sub rsp,16
 mov rbx,rdi
 test rbx,rbx
 jz .invalid
 mov rax,NEBO_G104_CONTEXT_MAGIC
 cmp [rbx+NEBO_G104_CONTEXT_MAGIC_OFFSET],rax
 jne .invalid
 cmp dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_CLOSED
 je .ok
 cmp dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_FRAME
 je .state
 cmp qword [rbx+NEBO_G104_CONTEXT_CLEANUP_COUNT_OFFSET],0
 jne .state
 mov rax,[rbx+NEBO_G104_CONTEXT_ENTRY_PTR_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[rax+NEBO_G104_ENTRY_CLOSE_FN_OFFSET]
 test rax,rax
 jz .publish
 mov rdi,rbx
 mov rsi,[rbx+NEBO_G104_CONTEXT_CALLBACK_DATA_OFFSET]
 call rax
 test eax,eax
 jnz .adapter
.publish:
 inc qword [rbx+NEBO_G104_CONTEXT_CLEANUP_COUNT_OFFSET]
 mov qword [rbx+NEBO_G104_CONTEXT_SHOULD_CLOSE_OFFSET],1
 mov dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_CLOSED
.ok:
 xor eax,eax
 jmp .done
.adapter:
 inc qword [rbx+NEBO_G104_CONTEXT_CLEANUP_COUNT_OFFSET]
 mov qword [rbx+NEBO_G104_CONTEXT_SHOULD_CLOSE_OFFSET],1
 mov dword [rbx+NEBO_G104_CONTEXT_STATE_OFFSET],NEBO_G104_STATE_FAILED
 mov eax,-NEBO_G104_STATUS_ADAPTER_FAILURE
 jmp .done
.state: mov eax,-NEBO_G104_STATUS_BAD_STATE
 jmp .done
.invalid: mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop rbx
 ret

; RDI=context, RSI=evidence out.
nebo_visual_console_evidence:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,NEBO_G104_CONTEXT_MAGIC
 cmp [rdi+NEBO_G104_CONTEXT_MAGIC_OFFSET],rax
 jne .invalid
 mov r8,[rdi+NEBO_G104_CONTEXT_ENTRY_PTR_OFFSET]
 test r8,r8
 jz .invalid
 mov r9,[rdi+NEBO_G104_CONTEXT_REGISTRY_PTR_OFFSET]
 test r9,r9
 jz .invalid
 mov eax,[rdi+NEBO_G104_CONTEXT_BACKEND_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_BACKEND_OFFSET],eax
 mov eax,[rdi+NEBO_G104_CONTEXT_RENDERER_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_RENDERER_OFFSET],eax
 mov eax,[rdi+NEBO_G104_CONTEXT_TARGET_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_TARGET_OFFSET],eax
 mov eax,[r8+NEBO_G104_ENTRY_MATURITY_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_MATURITY_OFFSET],eax
 mov rax,[rdi+NEBO_G104_CONTEXT_FLAGS_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_FLAGS_OFFSET],rax
 mov rax,[rdi+NEBO_G104_CONTEXT_FRAME_ID_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_FRAME_ID_OFFSET],rax
 mov rax,[rdi+NEBO_G104_CONTEXT_PRESENT_COUNT_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_PRESENT_COUNT_OFFSET],rax
 mov rax,[rdi+NEBO_G104_CONTEXT_EVENT_COUNT_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_EVENT_COUNT_OFFSET],rax
 mov rax,[rdi+NEBO_G104_CONTEXT_CLEANUP_COUNT_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_CLEANUP_COUNT_OFFSET],rax
 mov rax,[rdi+NEBO_G104_CONTEXT_LAST_DIGEST_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_LAST_DIGEST_OFFSET],rax
 mov rax,[r9+NEBO_G104_REGISTRY_STATE_HASH_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_REGISTRY_HASH_OFFSET],rax
 mov eax,[rdi+NEBO_G104_CONTEXT_STATE_OFFSET]
 mov [rsi+NEBO_G104_EVIDENCE_STATE_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 ret

; RDI=Unicode scalar array (u32), RSI=count, RDX=glyph array, RCX=capacity.
; Returns glyph count or a negative status. Validation precedes all writes.
nebo_visual_console_shape_text:
 push rbx
 push r12
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rsi,1
 jb .invalid
 cmp rsi,NEBO_G104_MAX_CODEPOINTS
 ja .limit
 cmp rcx,rsi
 jb .limit
 xor eax,eax
.validate:
 cmp rax,rsi
 jae .write
 mov ebx,[rdi+rax*4]
 cmp ebx,0x10ffff
 ja .invalid
 cmp ebx,0xd800
 jb .next_scalar
 cmp ebx,0xdfff
 jbe .invalid
.next_scalar:
 inc rax
 jmp .validate
.write:
 xor eax,eax
.glyph:
 cmp rax,rsi
 jae .success
 imul r12,rax,NEBO_G104_GLYPH_SIZE
 mov ebx,[rdi+rax*4]
 mov [rdx+r12+NEBO_G104_GLYPH_ID_OFFSET],rbx
 mov qword [rdx+r12+NEBO_G104_GLYPH_ADVANCE_OFFSET],NEBO_G104_GLYPH_ADVANCE_MONO
 mov [rdx+r12+NEBO_G104_GLYPH_CLUSTER_OFFSET],rax
 inc rax
 jmp .glyph
.success:
 jmp .done
.limit: mov eax,-NEBO_G104_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid: mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret
