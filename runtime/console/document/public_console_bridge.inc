; Program Console lifecycle bridge. The retained document remains the output
; authority; the existing bounded linear owner supplies lifecycle semantics.
; No source, fixture name, expected text or expected status enters this ABI.
%include "runtime/console/document/linear_console_document.inc"
extern nebo_console_document_clear
section .bss align=16
runtime_public_console_handle: resq 1
runtime_public_console_document: resb NEBO_CONSOLE_SIZE
runtime_public_console_text: resb NEBO_CONSOLE_MAX_TEXT
runtime_public_console_title: resb NEBO_CONSOLE_MAX_TITLE
runtime_public_console_copy: resb NEBO_CONSOLE_MAX_TEXT
section .text

; Resolve through the native generational handle owner, never a pointer cast.
runtime_public_console_retained:
 sub rsp,24
 lea rdi,[rel nebo_runtime_console_context]
 lea rdx,[rsp]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz runtime_public_console_failed
 mov rax,[rsp]
 mov rax,[rax+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
 test rax,rax
 jz runtime_public_console_failed
 add rsp,24
 ret

; Reconcile a completed retained publication through the canonical linear
; append/clear owners. Preserve title, style, and the user's scroll position.
runtime_public_console_sync:
 push rbx
 push r12
 sub rsp,24
 mov rsi,[rel runtime_public_console_handle]
 test rsi,rsi
 jz .done
 call runtime_public_console_retained
 mov rdi,rax
 lea rsi,[rel runtime_public_console_copy]
 mov edx,NEBO_CONSOLE_MAX_TEXT
 lea rcx,[rsp]
 call nebo_console_document_copy_plain_text
 test eax,eax
 jnz runtime_public_console_failed
 mov r12,[rel runtime_public_console_document+NEBO_CONSOLE_SCROLL]
 lea rdi,[rel runtime_public_console_document]
 call nebo_console_clear
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_console_document]
 lea rsi,[rel runtime_public_console_copy]
 mov rdx,[rsp]
 call nebo_console_append
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_console_document]
 mov rsi,r12
 call nebo_console_scroll
 test eax,eax
 jnz runtime_public_console_failed
.done:
 add rsp,24
 pop r12
 pop rbx
 ret

; op, ConsoleHandle, scalar argument, caller-owned 32-byte result storage.
; size returns the canonical bounded owner's (UTF-8 byte length, line count)
; as a two-lane Int Vector; these are document metrics, not display pixels.
global nebo_runtime_console_public_call
nebo_runtime_console_public_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp+64],r8
 mov [rsp+72],r9
 call runtime_public_console_retained
 mov rbx,rax
 mov rax,[rel runtime_public_console_handle]
 test rax,rax
 jnz .active
 lea rdi,[rel runtime_public_console_document]
 lea rsi,[rel runtime_public_console_text]
 mov edx,NEBO_CONSOLE_MAX_TEXT
 lea rcx,[rel runtime_public_console_title]
 mov r8d,NEBO_CONSOLE_MAX_TITLE
 call nebo_console_init
 test eax,eax
 jnz runtime_public_console_failed
 mov [rel runtime_public_console_handle],r13
 call runtime_public_console_sync
.active:
 cmp [rel runtime_public_console_handle],r13
 jne runtime_public_console_failed
 lea rdi,[rel runtime_public_console_document]
 call nebo_console_size_query
 test eax,eax
 jnz runtime_public_console_failed
 cmp r12,9
 je .style
 cmp r12,10
 je .style
 cmp r12,19
 jb .plain
 cmp r12,21
 ja runtime_public_console_failed
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+32],0
 mov rdi,rsp
 mov rsi,[rsp+64]
 call nebo_runtime_console_option_accumulate
 mov rdi,rsp
 call nebo_runtime_console_options_prepare
 sub r12,16
.plain:
 lea rdi,[rel runtime_public_console_document]
 cmp r12,1
 je .title
 cmp r12,2
 je .clear
 cmp r12,3
 je .text
 cmp r12,4
 je .int
 cmp r12,5
 je .bool
 cmp r12,6
 je .scroll
 cmp r12,7
 je .size
 cmp r12,8
 je .close
 jmp runtime_public_console_failed
.style:
 mov rcx,[rsp+64]
 cmp r12,10
 jne .range_ready
 add rcx,1
 jo runtime_public_console_failed
.range_ready:
 cmp r14,rcx
 ja runtime_public_console_failed
 mov rax,[rbx+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
 dec rax
 cmp rcx,rax
 ja runtime_public_console_failed
 mov rax,[rsp+72]
 mov rdx,rax
 shr rdx,32
 cmp edx,1
 je .role_ready
 cmp edx,2
 jne runtime_public_console_failed
.role_ready:
 ; A single public range update is checked completely before role mutation.
 mov r8,[rbx+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
 cmp r8,-1
 je runtime_public_console_failed
 lea r9,[rel runtime_public_node_colors]
.style_node:
 cmp r14,rcx
 jae .style_commit
 lea r10,[r14+1]
 shl r10,4
 lea r10,[r9+r10]
 cmp edx,1
 je .style_fg
 mov [r10+8],rax
 jmp .style_next
.style_fg:
 mov [r10],rax
.style_next:
 inc r14
 jmp .style_node
.style_commit:
 inc r8
 mov [rbx+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET],r8
 mov [rbx+NEBO_CONSOLE_DOCUMENT_DIRTY_REVISION_OFFSET],r8
 mov rdi,rbx
 lea rsi,[rbx+NEBO_CONSOLE_DOCUMENT_STATE_HASH_OFFSET]
 call nebo_console_document_state_hash
 jmp .status
.title:
 mov rsi,[r14]
 mov rdx,[r14+8]
 call nebo_console_set_title
 jmp .status
.clear:
 ; The retained owner rejects a clear with outstanding input nodes. Its
 ; preflight runs before either representation changes.
 mov rdi,rbx
 call nebo_console_document_clear
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_node_colors]
 xor eax,eax
 mov ecx,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*2
 cld
 rep stosq
 lea rdi,[rel runtime_public_node_positions]
 mov ecx,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*3
 rep stosq
 lea rdi,[rel runtime_public_console_document]
 call nebo_console_clear
 jmp .status
.text:
 mov rdi,r14
 call nebo_runtime_console_publish_text
 jmp .ok
.int:
 mov rdi,r14
 call nebo_runtime_console_publish_int
 jmp .ok
.bool:
 mov rdi,r14
 call nebo_runtime_console_publish_bool
 jmp .ok
.scroll:
 mov rsi,0x7fffffffffffffff
 call nebo_console_scroll
 jmp .status
.size:
 call nebo_console_size_query
 test eax,eax
 jnz runtime_public_console_failed
 mov [r15],rdx
 mov [r15+8],rcx
 mov rax,r15
 jmp .done
.close:
 call nebo_console_close
.status:
 test eax,eax
 jnz runtime_public_console_failed
.ok:
 xor eax,eax
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
runtime_public_console_failed:
 mov edi,NEBO_RUNTIME_TRAP_CONSOLE_RUNTIME
 jmp nebo_runtime_trap
