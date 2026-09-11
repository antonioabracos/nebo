; Checked nominal Color values reuse the canonical immutable RGBA8 kernels.
extern nebo_color_rgb_lowering
extern nebo_color_rgba_lowering
extern nebo_color_red
extern nebo_color_green
extern nebo_color_blue
extern nebo_color_alpha
extern nebo_color_with_alpha
extern nebo_color_is_opaque
extern nebo_color_equal
extern nebo_color_hex_literal
extern nebo_color_parse_hex
extern nebo_color_hash
extern nebo_color_to_hex
extern nebo_color_to_hex_with_alpha
extern nebo_geometry_position
extern neboc_color_option_typecheck
extern nebo_color_option_materialize
%include "compiler/semantic/color.inc"
section .text
global nebo_runtime_color_public_call
nebo_runtime_color_public_call:
 push rbx
 push r12
 sub rsp,72
 mov r12,rdi
 mov rbx,rsi
 cmp edi,40
 je .position
 cmp edi,41
 je .hex
 cmp edi,42
 je .parse_hex
 cmp edi,43
 je .to_hex
 cmp edi,44
 je .to_hex
 cmp edi,45
 je .hash
 cmp edi,46
 jae .result
 cmp edi,20
 je .rgb
 cmp edi,21
 je .rgba
 cmp edi,30
 jae .role
 mov edi,[rbx]
 cmp r12,22
 je .red
 cmp r12,23
 je .green
 cmp r12,24
 je .blue
 cmp r12,25
 je .alpha
 cmp r12,26
 je .with_alpha
 cmp r12,27
 je .opaque
 cmp r12,28
 je .equal
 jmp runtime_public_console_failed
.hex:
 mov rax,[rbx+8]
 mov rdi,[rax]
 mov rsi,[rax+8]
 mov rdx,rsp
 call nebo_color_hex_literal
 jmp .status
.parse_hex:
 mov rax,[rbx+8]
 mov rdi,[rax]
 mov rsi,[rax+8]
 lea rdx,[rbx+48]
 call nebo_color_parse_hex
 test eax,eax
 jnz runtime_public_console_failed
 lea rax,[rbx+48]
 jmp .done
.to_hex:
 mov edi,[rbx]
 lea rsi,[rbx+80]
 mov edx,16
 cmp r12,44
 je .to_alpha
 call nebo_color_to_hex
 jmp .serialized
.to_alpha:
 call nebo_color_to_hex_with_alpha
.serialized:
 test eax,eax
 jnz runtime_public_console_failed
 lea rax,[rbx+80]
 mov [rbx+48],rax
 mov [rbx+56],rdx
 mov dword [rbx+64],5
 mov word [rbx+68],1
 mov word [rbx+70],0
 mov qword [rbx+72],0
 lea rax,[rbx+48]
 jmp .done
.hash:
 mov edi,[rbx]
 call nebo_color_hash
 jmp .done
.result:
 mov rdx,[rbx]
 test rdx,rdx
 jz runtime_public_console_failed
 mov rax,[rdx+8]
 cmp rax,1
 ja runtime_public_console_failed
 cmp r12,46
 je .done
 cmp r12,47
 je .is_err
 cmp r12,48
 je .expect
 cmp r12,49
 jne runtime_public_console_failed
 test eax,eax
 jnz .unwrap
 mov rax,[rbx+8]
 jmp .done
.expect:
 test eax,eax
 jz runtime_public_console_failed
.unwrap:
 mov eax,[rdx]
 jmp .done
.is_err:
 xor eax,1
 jmp .done
.position:
 mov rax,[rbx+8]
 mov [rsp],rax
 mov rax,[rbx+16]
 mov [rsp+8],rax
 mov qword [rsp+16],0
 mov rdi,rsp
 lea rsi,[rbx+48]
 call nebo_geometry_position
 test eax,eax
 jnz runtime_public_console_failed
 lea rax,[rbx+48]
 jmp .done
.rgb:
 mov rdi,[rbx+8]
 mov rsi,[rbx+16]
 mov rdx,[rbx+32]
 mov rcx,rsp
 call nebo_color_rgb_lowering
 jmp .status
.rgba:
 mov rdi,[rbx+8]
 mov rsi,[rbx+16]
 mov rdx,[rbx+32]
 mov rcx,[rbx+40]
 mov r8,rsp
 call nebo_color_rgba_lowering
 jmp .status
.red:
 call nebo_color_red
 jmp .done
.green:
 call nebo_color_green
 jmp .done
.blue:
 call nebo_color_blue
 jmp .done
.alpha:
 call nebo_color_alpha
 jmp .done
.with_alpha:
 mov rsi,[rbx+8]
 mov rdx,rsp
 call nebo_color_with_alpha
 jmp .status
.opaque:
 call nebo_color_is_opaque
 jmp .done
.equal:
 mov esi,[rbx+8]
 call nebo_color_equal
 jmp .done
.role:
 cmp r12,33
 ja runtime_public_console_failed
 cmp r12,32
 jae .role_rgb
 mov eax,[rbx+8]
 jmp .role_pack
.role_rgb:
 mov rdi,[rbx+8]
 mov rsi,[rbx+16]
 mov rdx,[rbx+32]
 mov rcx,rsp
 call nebo_color_rgb_lowering
 test eax,eax
 jnz runtime_public_console_failed
 mov eax,[rsp]
.role_pack:
 ; A role is typed metadata, not an implicit color-to-Int conversion.
 and r12d,1
 inc r12
 mov rdi,r12
 mov esi,NEBOC_COLOR_TYPE_ID
 mov edx,eax
 mov rcx,rsp
 call neboc_color_option_typecheck
 test eax,eax
 jnz runtime_public_console_failed
 mov rdi,rsp
 lea rsi,[rsp+32]
 call nebo_color_option_materialize
 test eax,eax
 jnz runtime_public_console_failed
 mov rax,[rsp+40]
 mov r12,[rsp+32]
 shl r12,32
 or rax,r12
 jmp .done
.status:
 test eax,eax
 jnz runtime_public_console_failed
 mov eax,[rsp]
.done:
 add rsp,72
 pop r12
 pop rbx
 ret

; caller frame*, packed typed role. Reject duplicate roles before publication.
global nebo_runtime_console_option_accumulate
nebo_runtime_console_option_accumulate:
 mov rax,rsi
 shr rax,32
 cmp eax,1
 je .fg
 cmp eax,2
 jne runtime_public_console_failed
 test qword [rdi+32],2
 jnz runtime_public_console_failed
 mov [rdi+16],rsi
 or qword [rdi+32],2
 ret
.fg:
 test qword [rdi+32],1
 jnz runtime_public_console_failed
 mov [rdi+8],rsi
 or qword [rdi+32],1
 ret

global nebo_runtime_console_position_accumulate
nebo_runtime_console_position_accumulate:
 cmp qword [rsi+24],1
 jne runtime_public_console_failed
 test qword [rdi+32],4
 jnz runtime_public_console_failed
 mov rax,[rsi]
 cmp rax,255
 ja runtime_public_console_failed
 mov rdx,[rsi+8]
 cmp rdx,127
 ja runtime_public_console_failed
 mov [rdi+40],rax
 mov [rdi+48],rdx
 or qword [rdi+32],4
 ret

global nebo_runtime_console_options_prepare
nebo_runtime_console_options_prepare:
 push rbx
 mov rbx,rdi
 mov rax,[rbx+32]
 mov [rel runtime_public_pending_mask],rax
 test rax,rax
 jz .done
 mov rax,[rbx+8]
 mov [rel runtime_public_pending_fg],rax
 mov rax,[rbx+16]
 mov [rel runtime_public_pending_bg],rax
 mov rax,[rbx+40]
 mov [rel runtime_public_pending_x],rax
 mov rax,[rbx+48]
 mov [rel runtime_public_pending_y],rax
 call nebo_runtime_contract_1
 mov rsi,rax
 call runtime_public_console_retained
 mov rax,[rax+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
 mov [rel runtime_public_pending_start],rax
.done:
 pop rbx
 ret

; Committed retained nodes receive the source's explicit color roles. The
; per-node record is associated with NodeId, not textual content or a fixture.
runtime_public_console_commit_colors:
 push rbx
 mov rbx,[rel runtime_public_pending_mask]
 test rbx,rbx
 jz .done
 mov qword [rel runtime_public_pending_mask],0
 mov rsi,[rel nebo_runtime_last_console_handle]
 call runtime_public_console_retained
 mov rcx,[rel runtime_public_pending_start]
 mov rdx,[rax+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET]
 lea r8,[rel runtime_public_node_colors]
.node:
 cmp rcx,rdx
 jae .done
 cmp rcx,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
 jae runtime_public_console_failed
 mov r9,rcx
 shl r9,4
 test rbx,1
 jz .bg
 mov rax,[rel runtime_public_pending_fg]
 mov [r8+r9],rax
.bg:
 test rbx,2
 jz .next
 mov rax,[rel runtime_public_pending_bg]
 mov [r8+r9+8],rax
.next:
 test rbx,4
 jz .next_node
 lea r8,[rel runtime_public_node_positions]
 imul r9,rcx,24
 mov rax,[rel runtime_public_pending_x]
 mov [r8+r9],rax
 mov rax,[rel runtime_public_pending_y]
 mov [r8+r9+8],rax
 mov qword [r8+r9+16],1
 lea r8,[rel runtime_public_node_colors]
.next_node:
 inc rcx
 jmp .node
.done:
 pop rbx
 ret
section .bss align=16
runtime_public_pending_mask: resq 1
runtime_public_pending_fg: resq 1
runtime_public_pending_bg: resq 1
runtime_public_pending_start: resq 1
runtime_public_node_colors: resb NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*16

runtime_public_pending_x: resq 1
runtime_public_pending_y: resq 1
runtime_public_node_positions: resb NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*24

; Prepare native presentation from the same typed role and Position owners
; used by the software RenderTree. No source bytes or fixture identity enter.
section .bss align=16
runtime_public_live_colors: resb NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*16
section .text
runtime_public_live_presentation:
 push rbx
 push r12
 push r13
 mov rsi,[rel nebo_runtime_last_console_handle]
 call runtime_public_console_retained
 mov r12,rax
 xor ebx,ebx
.convert:
 cmp rbx,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY*2
 jae .ready
 lea r13,[rel runtime_public_node_colors]
 mov rdi,[r13+rbx*8]
 test rdi,rdi
 jz .color_ready
 mov r13,rdi
 shr r13,32
 call nebo_console_color_bgra
 shl r13,32
 or rax,r13
 mov rdi,rax
.color_ready:
 lea r13,[rel runtime_public_live_colors]
 mov [r13+rbx*8],rdi
 inc rbx
 jmp .convert
.ready:
 mov rdi,r12
 lea rsi,[rel runtime_public_live_colors]
 lea rdx,[rel runtime_public_node_positions]
 mov ecx,NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
 call nebo_runtime_live_set_presentation
 pop r13
 pop r12
 pop rbx
 ret
