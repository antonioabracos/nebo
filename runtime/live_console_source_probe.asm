; G104 source-to-effect bridge. Every accepted source program traverses the
; public registry, renderer selection, window lifecycle, frame, event, text
; shaping and evidence surfaces without ambient display state or fixture paths.
bits 64
default rel
%define NEBO_G104_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/live_console_source_probe.inc"
%include "runtime/console/live_console.inc"

global nebo_g104_source_probe
global nebo_g104_observation_probe
global nebo_g104_counter_probe
global nebo_g104_negative_probe

section .rodata
g104_renderer_software: db 'software'

section .data
g104_codepoints: dd 0x41,0x03bb,0x1f642

section .bss align=16
g104_registry: resb NEBO_G104_REGISTRY_SIZE
g104_entries: resb NEBO_G104_ENTRY_SIZE*NEBO_G104_REGISTRY_MAX_ENTRIES
g104_request: resb NEBO_G104_REQUEST_SIZE
g104_context: resb NEBO_G104_CONTEXT_SIZE
g104_event: resb NEBO_G104_EVENT_SIZE
g104_evidence: resb NEBO_G104_EVIDENCE_SIZE
g104_glyphs: resb NEBO_G104_GLYPH_SIZE*3
g104_renderer_value: resd 1
g104_frame_id: resq 1
g104_processed: resq 1
g104_close_value: resq 1

section .text
; EDI=mode, ESI=seed. Return seed after a complete observable lifecycle.
nebo_g104_source_probe:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12d,edi
 mov r13d,esi
 cmp r12d,1
 jb .invalid
 cmp r12d,10
 ja .invalid
 cmp r13d,1401
 jb .invalid
 cmp r13d,9999
 ja .invalid

 lea rdi,[rel g104_registry]
 lea rsi,[rel g104_entries]
 mov edx,NEBO_G104_REGISTRY_MAX_ENTRIES
 call nebo_visual_console_registry_init
 test eax,eax
 jnz .effect
 cmp qword [rel g104_registry+NEBO_G104_REGISTRY_COUNT_OFFSET],NEBO_G104_REGISTRY_BUILTIN_COUNT
 jne .effect

 lea rdi,[rel g104_renderer_software]
 mov esi,8
 lea rdx,[rel g104_renderer_value]
 call nebo_visual_console_renderer_key
 test eax,eax
 jnz .effect
 cmp dword [rel g104_renderer_value],NEBO_G104_RENDERER_SOFTWARE
 jne .effect
 lea rdi,[rel g104_registry]
 mov esi,NEBO_G104_BACKEND_HEADLESS
 mov edx,NEBO_G104_RENDERER_SOFTWARE
 mov ecx,NEBO_G104_TARGET_LINUX_X86_64
 call nebo_visual_console_is_available
 cmp eax,1
 jne .effect
 lea rdi,[rel g104_registry]
 mov esi,NEBO_G104_BACKEND_X11
 mov edx,NEBO_G104_RENDERER_OPENGL
 mov ecx,NEBO_G104_TARGET_LINUX_X86_64
 call nebo_visual_console_is_available
 test eax,eax
 jnz .effect

 ; Request schema owns renderer: as a typed enum, not a fixture string.
 lea rdi,[rel g104_request]
 xor eax,eax
 mov ecx,NEBO_G104_REQUEST_QWORDS
 cld
 rep stosq
 mov dword [rel g104_request+NEBO_G104_REQUEST_BACKEND_OFFSET],NEBO_G104_BACKEND_HEADLESS
 mov dword [rel g104_request+NEBO_G104_REQUEST_RENDERER_OFFSET],NEBO_G104_RENDERER_SOFTWARE
 mov dword [rel g104_request+NEBO_G104_REQUEST_TARGET_OFFSET],NEBO_G104_TARGET_LINUX_X86_64
 mov eax,r12d
 add eax,319
 mov [rel g104_request+NEBO_G104_REQUEST_WIDTH_OFFSET],rax
 mov eax,r12d
 add eax,199
 mov [rel g104_request+NEBO_G104_REQUEST_HEIGHT_OFFSET],rax
 mov qword [rel g104_request+NEBO_G104_REQUEST_EVENT_CAPACITY_OFFSET],8
 mov qword [rel g104_request+NEBO_G104_REQUEST_REQUIRED_CAPABILITIES_OFFSET],NEBO_G104_CAP_ALL
 mov qword [rel g104_request+NEBO_G104_REQUEST_FLAGS_OFFSET],NEBO_G104_REQUEST_REQUIRED_FLAGS
 lea rdi,[rel g104_context]
 lea rsi,[rel g104_registry]
 lea rdx,[rel g104_request]
 call nebo_visual_console_open_default
 test eax,eax
 jnz .effect

 lea rdi,[rel g104_context]
 lea rsi,[rel g104_frame_id]
 call nebo_visual_console_begin_frame
 test eax,eax
 jnz .effect
 mov rax,[rel g104_frame_id]
 cmp rax,1
 jne .effect
 mov rdx,r13
 shl rdx,8
 or rdx,r12
 lea rdi,[rel g104_context]
 mov rsi,rax
 call nebo_visual_console_end_frame
 test eax,eax
 jnz .effect

 ; Resize and redraw are independent events; close is requested at the end.
 lea rdi,[rel g104_event]
 xor eax,eax
 mov ecx,NEBO_G104_EVENT_QWORDS
 cld
 rep stosq
 mov dword [rel g104_event+NEBO_G104_EVENT_KIND_OFFSET],NEBO_G104_EVENT_RESIZED
 mov eax,r12d
 add eax,639
 mov [rel g104_event+NEBO_G104_EVENT_PAYLOAD0_OFFSET],rax
 mov eax,r12d
 add eax,479
 mov [rel g104_event+NEBO_G104_EVENT_PAYLOAD1_OFFSET],rax
 mov [rel g104_event+NEBO_G104_EVENT_SEQUENCE_OFFSET],r12
 lea rdi,[rel g104_context]
 lea rsi,[rel g104_event]
 lea rdx,[rel g104_processed]
 call nebo_visual_console_run_once
 test eax,eax
 jnz .effect
 cmp qword [rel g104_processed],1
 jne .effect
 mov dword [rel g104_event+NEBO_G104_EVENT_KIND_OFFSET],NEBO_G104_EVENT_REDRAW_REQUESTED
 inc qword [rel g104_event+NEBO_G104_EVENT_SEQUENCE_OFFSET]
 lea rdi,[rel g104_context]
 lea rsi,[rel g104_event]
 lea rdx,[rel g104_processed]
 call nebo_visual_console_run_once
 test eax,eax
 jnz .effect
 mov dword [rel g104_event+NEBO_G104_EVENT_KIND_OFFSET],NEBO_G104_EVENT_CLOSE_REQUESTED
 inc qword [rel g104_event+NEBO_G104_EVENT_SEQUENCE_OFFSET]
 lea rdi,[rel g104_context]
 lea rsi,[rel g104_event]
 lea rdx,[rel g104_processed]
 call nebo_visual_console_run_once
 test eax,eax
 jnz .effect
 lea rdi,[rel g104_context]
 lea rsi,[rel g104_close_value]
 call nebo_visual_console_should_close
 test eax,eax
 jnz .effect
 cmp qword [rel g104_close_value],1
 jne .effect

 lea rdi,[rel g104_codepoints]
 mov esi,3
 lea rdx,[rel g104_glyphs]
 mov ecx,3
 call nebo_visual_console_shape_text
 cmp eax,3
 jne .effect
 cmp qword [rel g104_glyphs+NEBO_G104_GLYPH_ADVANCE_OFFSET],NEBO_G104_GLYPH_ADVANCE_MONO
 jne .effect

 lea rdi,[rel g104_context]
 call nebo_visual_console_close
 test eax,eax
 jnz .effect
 ; Idempotence proves exactly-once cleanup rather than a second side effect.
 lea rdi,[rel g104_context]
 call nebo_visual_console_close
 test eax,eax
 jnz .effect
 lea rdi,[rel g104_context]
 lea rsi,[rel g104_evidence]
 call nebo_visual_console_evidence
 test eax,eax
 jnz .effect
 cmp dword [rel g104_evidence+NEBO_G104_EVIDENCE_MATURITY_OFFSET],NEBO_G104_MATURITY_HEADLESS_RENDERER_GREEN
 jne .effect
 cmp qword [rel g104_evidence+NEBO_G104_EVIDENCE_PRESENT_COUNT_OFFSET],1
 jne .effect
 cmp qword [rel g104_evidence+NEBO_G104_EVIDENCE_EVENT_COUNT_OFFSET],3
 jne .effect
 cmp qword [rel g104_evidence+NEBO_G104_EVIDENCE_CLEANUP_COUNT_OFFSET],1
 jne .effect
 cmp dword [rel g104_evidence+NEBO_G104_EVIDENCE_STATE_OFFSET],NEBO_G104_STATE_CLOSED
 jne .effect
 mov eax,r13d
 jmp .done
.invalid:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 jmp .done
.effect:
 mov eax,-NEBO_G104_STATUS_BAD_STATE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=mode, RSI=seed -> independently observable frame digest.
nebo_g104_observation_probe:
 push rbx
 mov ebx,esi
 call nebo_g104_source_probe
 cmp eax,ebx
 jne .failed
 mov rax,[rel g104_evidence+NEBO_G104_EVIDENCE_LAST_DIGEST_OFFSET]
 pop rbx
 ret
.failed:
 cdqe
 pop rbx
 ret

; RDI=mode, RSI=seed, RDX=selector.
nebo_g104_counter_probe:
 push rbx
 push r12
 sub rsp,8
 mov ebx,esi
 mov r12,rdx
 call nebo_g104_source_probe
 cmp eax,ebx
 jne .done
 cmp r12,1
 je .registry_count
 cmp r12,2
 je .maturity
 cmp r12,3
 je .presents
 cmp r12,4
 je .events
 cmp r12,5
 je .cleanups
 cmp r12,6
 je .digest
 cmp r12,7
 je .hash
 cmp r12,8
 je .should_close
 cmp r12,9
 je .width
 cmp r12,10
 je .advance
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 jmp .done
.registry_count: mov rax,[rel g104_registry+NEBO_G104_REGISTRY_COUNT_OFFSET]
 jmp .done
.maturity: mov eax,[rel g104_evidence+NEBO_G104_EVIDENCE_MATURITY_OFFSET]
 jmp .done
.presents: mov rax,[rel g104_evidence+NEBO_G104_EVIDENCE_PRESENT_COUNT_OFFSET]
 jmp .done
.events: mov rax,[rel g104_evidence+NEBO_G104_EVIDENCE_EVENT_COUNT_OFFSET]
 jmp .done
.cleanups: mov rax,[rel g104_evidence+NEBO_G104_EVIDENCE_CLEANUP_COUNT_OFFSET]
 jmp .done
.digest: mov rax,[rel g104_evidence+NEBO_G104_EVIDENCE_LAST_DIGEST_OFFSET]
 jmp .done
.hash: mov rax,[rel g104_evidence+NEBO_G104_EVIDENCE_REGISTRY_HASH_OFFSET]
 jmp .done
.should_close: mov rax,[rel g104_close_value]
 jmp .done
.width: mov rax,[rel g104_context+NEBO_G104_CONTEXT_WIDTH_OFFSET]
 jmp .done
.advance: mov rax,[rel g104_glyphs+NEBO_G104_GLYPH_ADVANCE_OFFSET]
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; EDI=case. Return zero only when the requested negative/atomicity behavior is
; observed. These probes operate on the state left by a fresh valid lifecycle.
nebo_g104_negative_probe:
 push rbx
 push r12
 sub rsp,8
 mov ebx,edi
 mov edi,10
 mov esi,1410
 call nebo_g104_source_probe
 cmp eax,1410
 jne .failed
 cmp ebx,1
 je .renderer
 cmp ebx,2
 je .unavailable
 cmp ebx,3
 je .shape
 cmp ebx,4
 je .closed_frame
 jmp .invalid_case
.renderer:
 mov dword [rel g104_renderer_value],0x55555555
 lea rdi,[rel g104_renderer_software]
 mov esi,7
 lea rdx,[rel g104_renderer_value]
 call nebo_visual_console_renderer_key
 cmp eax,-NEBO_G104_STATUS_UNSUPPORTED
 jne .failed
 cmp dword [rel g104_renderer_value],0x55555555
 jne .failed
 jmp .ok
.unavailable:
 lea rdi,[rel g104_registry]
 mov esi,NEBO_G104_BACKEND_WAYLAND
 mov edx,NEBO_G104_RENDERER_BGFX
 mov ecx,NEBO_G104_TARGET_LINUX_X86_64
 call nebo_visual_console_is_available
 test eax,eax
 jne .failed
 jmp .ok
.shape:
 mov dword [rel g104_codepoints],0xd800
 mov rax,0x5555555555555555
 mov [rel g104_glyphs],rax
 lea rdi,[rel g104_codepoints]
 mov esi,3
 lea rdx,[rel g104_glyphs]
 mov ecx,3
 call nebo_visual_console_shape_text
 mov dword [rel g104_codepoints],0x41
 cmp eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 jne .failed
 mov rax,0x5555555555555555
 cmp [rel g104_glyphs],rax
 jne .failed
 jmp .ok
.closed_frame:
 mov rax,0x5555555555555555
 mov [rel g104_frame_id],rax
 lea rdi,[rel g104_context]
 lea rsi,[rel g104_frame_id]
 call nebo_visual_console_begin_frame
 cmp eax,-NEBO_G104_STATUS_BAD_STATE
 jne .failed
 mov rax,0x5555555555555555
 cmp [rel g104_frame_id],rax
 jne .failed
.ok:
 xor eax,eax
 jmp .done
.invalid_case:
 mov eax,-NEBO_G104_STATUS_INVALID_ARGUMENT
 jmp .done
.failed:
 mov eax,-NEBO_G104_STATUS_BAD_STATE
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
