; Nebo Assembly — MF024 deterministic effect classification
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/semantic/effect/effect_classifier.inc"

section .text
NEBOC_ABI_FUNCTION neboc_effect_classify
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_EFFECT_REQUEST_INPUTS_OFFSET]
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBOC_EFFECT_REQUEST_INPUT_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_EFFECT_REQUEST_OUTPUT_CAPACITY_OFFSET]
 ja .limit
 cmp qword [r12+NEBOC_EFFECT_REQUEST_OUTPUTS_OFFSET],0
 je .invalid
 mov qword [r12+NEBOC_EFFECT_REQUEST_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_EFFECT_REQUEST_ERROR_INDEX_OFFSET],0
 mov qword [r12+NEBOC_EFFECT_REQUEST_HASH_OFFSET],0
 xor r14d,r14d
.loop:
 cmp r14,[r12+NEBOC_EFFECT_REQUEST_INPUT_COUNT_OFFSET]
 jae .finish
 mov rax,r14
 imul rax,NEBOC_EFFECT_INPUT_SIZE
 add rax,r13
 mov rbx,rax
 mov r15,[rbx+NEBOC_EFFECT_INPUT_DIRECT_OFFSET]
 cmp r15,NEBOC_EFFECT_ID_PURE
 jb .invalid
 cmp r15,NEBOC_EFFECT_ID_COUNT
 ja .invalid
 mov rax,[rbx+NEBOC_EFFECT_INPUT_CALLEE_OFFSET_OFFSET]
 mov rdx,[rbx+NEBOC_EFFECT_INPUT_CALLEE_COUNT_OFFSET]
 mov rcx,rax
 add rcx,rdx
 jc .limit
 cmp rcx,[r12+NEBOC_EFFECT_REQUEST_CALLEE_EFFECT_COUNT_OFFSET]
 ja .limit
 xor ecx,ecx
.callee_loop:
 cmp rcx,rdx
 jae .callee_done
 mov r8,[r12+NEBOC_EFFECT_REQUEST_CALLEE_EFFECTS_OFFSET]
 mov r9,[r8+rax*8]
 cmp r9,NEBOC_EFFECT_ID_PURE
 je .callee_next
 cmp r9,NEBOC_EFFECT_ID_CONSOLE
 je .join_console
 cmp r9,NEBOC_EFFECT_ID_SCAN
 je .join_scan
 cmp r9,NEBOC_EFFECT_ID_CONSOLE_SCAN
 je .join_both
 jmp .invalid
.join_console:
 cmp r15,NEBOC_EFFECT_ID_SCAN
 je .set_both
 cmp r15,NEBOC_EFFECT_ID_CONSOLE_SCAN
 je .callee_next
 mov r15,NEBOC_EFFECT_ID_CONSOLE
 jmp .callee_next
.join_scan:
 cmp r15,NEBOC_EFFECT_ID_CONSOLE
 je .set_both
 cmp r15,NEBOC_EFFECT_ID_CONSOLE_SCAN
 je .callee_next
 mov r15,NEBOC_EFFECT_ID_SCAN
 jmp .callee_next
.join_both:
.set_both:
 mov r15,NEBOC_EFFECT_ID_CONSOLE_SCAN
.callee_next:
 inc rax
 inc rcx
 jmp .callee_loop
.callee_done:
 mov rcx,[rbx+NEBOC_EFFECT_INPUT_FLAGS_OFFSET]
 test rcx,NEBOC_EFFECT_FUNCTION_FLAG_THREAD_CAPABLE
 jz .store
 cmp r15,NEBOC_EFFECT_ID_PURE
 je .thread_error
.store:
 mov rax,[r12+NEBOC_EFFECT_REQUEST_OUTPUTS_OFFSET]
 mov [rax+r14*8],r15
 inc r14
 jmp .loop
.thread_error:
 mov qword [r12+NEBOC_EFFECT_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_EFFECT_THREAD_CAPABILITY
 mov [r12+NEBOC_EFFECT_REQUEST_ERROR_INDEX_OFFSET],r14
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.finish:
 mov eax,NEBOC_EFFECT_HASH_FNV1A32_OFFSET_BASIS
 xor r14d,r14d
.hash_loop:
 cmp r14,[r12+NEBOC_EFFECT_REQUEST_INPUT_COUNT_OFFSET]
 jae .hash_done
 mov rdx,[r12+NEBOC_EFFECT_REQUEST_OUTPUTS_OFFSET]
 xor eax,[rdx+r14*8]
 imul eax,eax,NEBOC_EFFECT_HASH_FNV1A32_PRIME
 inc r14
 jmp .hash_loop
.hash_done:
 mov [r12+NEBOC_EFFECT_REQUEST_HASH_OFFSET],rax
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
 cld
 ret
