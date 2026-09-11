; Typed foreground/background roles feed the existing RenderTree and software
; draw owners. Records are indexed by document node slot, never source text.
bits 64
default rel
%include "runtime/console/document/console_document.inc"
%include "runtime/console/render/render_tree.inc"
extern nebo_console_render_tree_validate
extern nebo_console_render_tree_state_hash
extern nebo_console_document_validate
global nebo_console_output_apply_typed_colors
section .text

; Logical unpremultiplied RGBA8 -> packed premultiplied BGRA8, rounded nearest.
; The software target stores alpha; it does not claim a compositing backend.
global nebo_console_color_bgra
nebo_console_color_bgra:
typed_color_bgra:
 mov r10d,edi
 movzx r11d,dil
 mov eax,edi
 shr eax,8
 and eax,255
 imul eax,r11d
 add eax,127
 xor edx,edx
 mov ecx,255
 div ecx
 mov r8d,eax
 mov eax,r10d
 shr eax,16
 and eax,255
 imul eax,r11d
 add eax,127
 xor edx,edx
 div ecx
 shl eax,8
 or r8d,eax
 mov eax,r10d
 shr eax,24
 imul eax,r11d
 add eax,127
 xor edx,edx
 div ecx
 shl eax,16
 or eax,r8d
 shl r11d,24
 or eax,r11d
 ret

; tree, document, packed role pairs*, capacity -> checked status.
nebo_console_output_apply_typed_colors:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 call nebo_console_render_tree_validate
 test eax,eax
 jnz .done
 mov rdi,r13
 call nebo_console_document_validate
 test eax,eax
 jnz .done
 cmp r15,[r13+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
 jb .invalid
 xor ebx,ebx
.preflight:
 cmp rbx,[r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
 jae .ready
 mov rax,rbx
 imul rax,NEBO_RENDER_NODE_SIZE
 add rax,[r12+NEBO_RENDER_TREE_NODES_PTR_OFFSET]
 mov rdx,[rax+NEBO_RENDER_NODE_DOCUMENT_NODE_ID_OFFSET]
 test rdx,rdx
 jz .invalid
 cmp rdx,[r13+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
 ja .invalid
 dec rdx
 shl rdx,4
 mov rax,[r14+rdx]
 test rax,rax
 jz .check_bg
 shr rax,32
 cmp eax,1
 jne .invalid
.check_bg:
 mov rax,[r14+rdx+8]
 test rax,rax
 jz .next_check
 shr rax,32
 cmp eax,2
 jne .invalid
.next_check:
 inc rbx
 jmp .preflight
.ready:
 xor ebx,ebx
.node:
 cmp rbx,[r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
 jae .hash
 mov rax,rbx
 imul rax,NEBO_RENDER_NODE_SIZE
 add rax,[r12+NEBO_RENDER_TREE_NODES_PTR_OFFSET]
 mov [rsp],rax
 mov rdx,[rax+NEBO_RENDER_NODE_DOCUMENT_NODE_ID_OFFSET]
 dec rdx
 shl rdx,4
 add rdx,r14
 mov [rsp+8],rdx
 mov rdi,[rdx]
 test rdi,rdi
 jz .bg
 call typed_color_bgra
 mov rdx,[rsp]
 mov [rdx+NEBO_RENDER_NODE_FOREGROUND_OFFSET],rax
.bg:
 mov rdx,[rsp+8]
 mov rdi,[rdx+8]
 test rdi,rdi
 jz .next
 call typed_color_bgra
 mov rdx,[rsp]
 mov [rdx+NEBO_RENDER_NODE_BACKGROUND_OFFSET],rax
 or dword [rdx+NEBO_RENDER_NODE_FLAGS_OFFSET],NEBO_RENDER_NODE_FLAG_EXPLICIT_BACKGROUND
.next:
 inc rbx
 jmp .node
.hash:
 mov rdi,r12
 lea rsi,[r12+NEBO_RENDER_TREE_STATE_HASH_OFFSET]
 call nebo_console_render_tree_state_hash
 jmp .done
.invalid:
 mov eax,NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
