; Optional observation of actual native document/lifecycle/software state.
; The observer consumes no expected value, source text or fixture identity.
%include "runtime/console/render/software_surface.inc"
extern nebo_console_output_apply_typed_colors
extern nebo_runtime_console_view_count
extern nebo_runtime_console_view_records
section .rodata
runtime_console_state_environment: db 'NEBO_CONSOLE_STATE_TRACE=1',0
runtime_console_state_environment_len equ $-runtime_console_state_environment
section .bss align=16
runtime_public_layout: resb NEBO_LAYOUT_TREE_SIZE
runtime_public_layout_boxes: resb 512*NEBO_LAYOUT_BOX_SIZE
runtime_public_render_tree: resb NEBO_RENDER_TREE_SIZE
runtime_public_render_nodes: resb 512*NEBO_RENDER_NODE_SIZE
runtime_public_draw_buffer: resb NEBO_DRAW_BUFFER_SIZE
runtime_public_draw_commands: resb 1024*NEBO_DRAW_COMMAND_SIZE
runtime_public_glyph_provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
runtime_public_surface: resb NEBO_SOFTWARE_SURFACE_SIZE
runtime_public_pixels: resb 256*128*4
runtime_public_console_state_header: resq 16
section .text
runtime_public_console_observe:
 push rbx
 push r12
 sub rsp,24
 lea rsi,[rel runtime_console_state_environment]
 mov edx,runtime_console_state_environment_len
 call nebo_runtime_trace_setting
 test eax,eax
 jz .done
 mov rsi,[rel nebo_runtime_last_console_handle]
 call runtime_public_console_retained
 mov rbx,rax
 lea rdi,[rel runtime_public_glyph_provider]
 call nebo_fake_glyph_provider_init
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_layout]
 lea rsi,[rel runtime_public_layout_boxes]
 mov edx,512
 mov ecx,256*NEBO_LAYOUT_ONE
 mov r8d,128*NEBO_LAYOUT_ONE
 lea r9,[rel runtime_public_glyph_provider]
 call nebo_console_layout_init
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_layout]
 mov rsi,rbx
 call nebo_console_layout_document
 test eax,eax
 jnz runtime_public_console_failed
 call runtime_public_console_apply_positions
 lea rdi,[rel runtime_public_render_tree]
 lea rsi,[rel runtime_public_render_nodes]
 mov edx,512
 call nebo_console_render_tree_init
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_render_tree]
 lea rsi,[rel runtime_public_layout]
 mov rdx,rbx
 call nebo_console_render_tree_build
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_render_tree]
 mov rsi,rbx
 lea rdx,[rel runtime_public_node_colors]
 mov ecx,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
 call nebo_console_output_apply_typed_colors
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_draw_buffer]
 lea rsi,[rel runtime_public_draw_commands]
 mov edx,1024
 mov rcx,rbx
 call nebo_draw_command_buffer_init
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_draw_buffer]
 lea rsi,[rel runtime_public_layout]
 lea rdx,[rel runtime_public_render_tree]
 call nebo_console_draw_commands_build
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_surface]
 lea rsi,[rel runtime_public_pixels]
 mov edx,256*128*4
 mov ecx,256
 mov r8d,128
 call nebo_software_surface_init
 test eax,eax
 jnz runtime_public_console_failed
 lea rdi,[rel runtime_public_surface]
 lea rsi,[rel runtime_public_draw_buffer]
 lea rdx,[rel runtime_public_glyph_provider]
 call nebo_software_surface_execute
 test eax,eax
 jnz runtime_public_console_failed
 ; Lifecycle fields are present only after a public lifecycle operation.
 ; Default publication alone does not opt into the smaller linear profile.
 lea r12,[rel runtime_public_console_state_header]
 mov rax,0x315453434f42454e
 mov [r12],rax
 mov rax,[rel runtime_public_console_document+NEBO_CONSOLE_STATE]
 mov [r12+8],rax
 mov rax,[rel runtime_public_console_document+NEBO_CONSOLE_LENGTH]
 mov [r12+16],rax
 mov rax,[rel runtime_public_console_document+NEBO_CONSOLE_LINES]
 mov [r12+24],rax
 mov rax,[rel runtime_public_console_document+NEBO_CONSOLE_STYLE]
 mov [r12+32],rax
 mov rax,[rel runtime_public_console_document+NEBO_CONSOLE_SCROLL]
 mov [r12+40],rax
 mov rax,[rel runtime_public_console_document+NEBO_CONSOLE_TITLE_LENGTH]
 mov [r12+48],rax
 mov rax,[rel runtime_public_layout+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
 mov [r12+56],rax
 mov rax,[rel runtime_public_render_tree+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
 mov [r12+64],rax
 mov rax,[rel runtime_public_draw_buffer+NEBO_DRAW_BUFFER_COUNT_OFFSET]
 mov [r12+72],rax
 mov rax,[rel runtime_public_surface+NEBO_SOFTWARE_SURFACE_STATE_HASH_OFFSET]
 mov [r12+80],rax
 mov qword [r12+88],256
 mov qword [r12+96],128
 mov rax,[rel runtime_public_surface+NEBO_SOFTWARE_SURFACE_EXECUTED_COMMANDS_OFFSET]
 mov [r12+104],rax
 mov rsi,r12
 mov edx,112
 call runtime_public_console_write
 lea rsi,[rel runtime_public_console_title]
 mov rdx,[r12+48]
 call runtime_public_console_write
 ; Successful structured publications expose canonical pointer-free shape
 ; records. No record is emitted for ordinary scalar Console programs.
 mov rax,[rel nebo_runtime_console_view_count]
 test rax,rax
 jz .done
 mov [r12+8],rax
 mov rax,0x315749564f42454e
 mov [r12],rax
 mov rsi,r12
 mov edx,16
 call runtime_public_console_write
 lea rsi,[rel nebo_runtime_console_view_records]
 mov rdx,[r12+8]
 shl rdx,5
 call runtime_public_console_write
.done:
 add rsp,24
 pop r12
 pop rbx
 ret
runtime_public_console_write:
 mov r8d,64
.write:
 test rdx,rdx
 jz .done
 dec r8
 jz runtime_public_console_failed
 mov eax,1
 mov edi,1
 syscall
 cmp rax,-4
 je .write
 test rax,rax
 jle runtime_public_console_failed
 add rsi,rax
 sub rdx,rax
 jmp .write
.done:
 ret

; Explicit Position.at uses logical software pixels, with x horizontal and y
; vertical. It translates this node's wrapped boxes as one owned layout unit;
; it does not move a different publication or invent a window position.
runtime_public_console_apply_positions:
 push rbx
 push r12
 push r13
 push r14
 push r15
 lea r12,[rel runtime_public_layout]
 mov rbx,[r12+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
 add rbx,2*NEBO_LAYOUT_BOX_SIZE
 mov r13d,2
 xor r14d,r14d
.box:
 cmp r13,[r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
 jae .done
 mov rax,[rbx+NEBO_LAYOUT_BOX_NODE_ID_OFFSET]
 test rax,rax
 jz runtime_public_console_failed
 dec rax
 cmp rax,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
 jae runtime_public_console_failed
 lea rdx,[rel runtime_public_node_positions]
 imul rcx,rax,24
 add rdx,rcx
 cmp qword [rdx+16],0
 je .next
 inc rax
 cmp rax,r14
 je .translate
 mov r14,rax
 mov r8,[rdx]
 shl r8,NEBO_LAYOUT_FRACTION_BITS
 sub r8,[rbx+NEBO_LAYOUT_BOX_X_OFFSET]
 mov r9,[rdx+8]
 shl r9,NEBO_LAYOUT_FRACTION_BITS
 sub r9,[rbx+NEBO_LAYOUT_BOX_Y_OFFSET]
.translate:
 add [rbx+NEBO_LAYOUT_BOX_X_OFFSET],r8
 add [rbx+NEBO_LAYOUT_BOX_Y_OFFSET],r9
 add [rbx+NEBO_LAYOUT_BOX_BASELINE_OFFSET],r9
.next:
 add rbx,NEBO_LAYOUT_BOX_SIZE
 inc r13
 jmp .box
.done:
 mov rdi,r12
 lea rsi,[r12+NEBO_LAYOUT_TREE_STATE_HASH_OFFSET]
 call nebo_console_layout_state_hash
 test eax,eax
 jnz runtime_public_console_failed
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
