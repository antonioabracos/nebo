; Nebo practical live Console visual frontend — bounded software rasterizer.
; ConsoleDocument remains the semantic owner. This module renders a clipped
; viewport using only the runtime-owned custom chrome and dependency-free font.
bits 64
default rel

%include "runtime/console/live/live_console.inc"
%include "runtime/console/live/live_typography.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/input/editing/text_editor.inc"

extern nebo_console_document_copy_plain_text
extern nebo_console_chrome_render
extern nebo_software_surface_fill_rect

global nebo_runtime_live_set_presentation
global nebo_runtime_live_visual_render

section .rodata align=8
; Rows 0..6, low five bits left-to-right.
glyph_upper:
 db 14,17,17,31,17,17,17, 30,17,17,30,17,17,30
 db 14,17,16,16,16,17,14, 30,17,17,17,17,17,30
 db 31,16,16,30,16,16,31, 31,16,16,30,16,16,16
 db 14,17,16,23,17,17,15, 17,17,17,31,17,17,17
 db 14,4,4,4,4,4,14, 7,2,2,2,2,18,12
 db 17,18,20,24,20,18,17, 16,16,16,16,16,16,31
 db 17,27,21,21,17,17,17, 17,25,21,19,17,17,17
 db 14,17,17,17,17,17,14, 30,17,17,30,16,16,16
 db 14,17,17,17,21,18,13, 30,17,17,30,20,18,17
 db 15,16,16,14,1,1,30, 31,4,4,4,4,4,4
 db 17,17,17,17,17,17,14, 17,17,17,17,17,10,4
 db 17,17,17,21,21,21,10, 17,17,10,4,10,17,17
 db 17,17,10,4,4,4,4, 31,1,2,4,8,16,31

glyph_lower:
 db 0,0,14,1,15,17,15, 16,16,30,17,17,17,30
 db 0,0,14,16,16,17,14, 1,1,15,17,17,17,15
 db 0,0,14,17,31,16,14, 6,9,8,28,8,8,8
 db 0,15,17,17,15,1,14, 16,16,30,17,17,17,17
 db 4,0,12,4,4,4,14, 2,0,6,2,2,18,12
 db 16,16,18,20,24,20,18, 12,4,4,4,4,4,14
 db 0,0,26,21,21,21,21, 0,0,30,17,17,17,17
 db 0,0,14,17,17,17,14, 0,0,30,17,30,16,16
 db 0,0,15,17,15,1,1, 0,0,22,25,16,16,16
 db 0,0,15,16,14,1,30, 8,8,28,8,8,9,6
 db 0,0,17,17,17,19,13, 0,0,17,17,17,10,4
 db 0,0,17,17,21,21,10, 0,0,17,10,4,10,17
 db 0,0,17,17,15,1,14, 0,0,31,2,4,8,31

glyph_digits:
 db 14,17,19,21,25,17,14, 4,12,4,4,4,4,14
 db 14,17,1,2,4,8,31, 30,1,1,14,1,1,30
 db 2,6,10,18,31,2,2, 31,16,16,30,1,1,30
 db 14,16,16,30,17,17,14, 31,1,2,4,8,8,8
 db 14,17,17,14,17,17,14, 14,17,17,15,1,1,14

punctuation_question: db 14,17,1,2,4,0,4
punctuation_left_paren: db 2,4,8,8,8,4,2
punctuation_right_paren: db 8,4,2,2,2,4,8
punctuation_left_bracket: db 14,8,8,8,8,8,14
punctuation_right_bracket: db 14,2,2,2,2,2,14
punctuation_left_brace: db 3,4,4,24,4,4,3
punctuation_right_brace: db 24,4,4,3,4,4,24
punctuation_comma: db 0,0,0,0,0,4,8
punctuation_semicolon: db 0,4,0,0,0,4,8
punctuation_plus: db 0,4,4,31,4,4,0
punctuation_star: db 0,21,14,31,14,21,0
punctuation_slash: db 1,1,2,4,8,16,16
punctuation_exclamation: db 4,4,4,4,4,0,4
punctuation_dot: db 0,0,0,0,0,0,4
punctuation_colon: db 0,4,0,0,4,0,0
punctuation_dash: db 0,0,0,14,0,0,0
punctuation_underscore: db 0,0,0,0,0,0,31
punctuation_equals: db 0,31,0,31,0,0,0

%if NEBO_LIVE_CONTENT_SMOOTHING_MODE = NEBO_LIVE_SMOOTHING_STROKE_ATLAS
%include "runtime/console/live/live_glyph_smooth_atlas.inc"
%elif NEBO_LIVE_CONTENT_SMOOTHING_MODE = NEBO_LIVE_SMOOTHING_CRISP_ATLAS
%include "runtime/console/live/live_glyph_crisp_atlas.inc"
%elif NEBO_LIVE_CONTENT_SMOOTHING_MODE = NEBO_LIVE_SMOOTHING_PROFESSIONAL_ATLAS
%include "runtime/console/live/nebo_console_mono_atlas.inc"
%endif

section .bss align=64
visual_plain_text: resb NEBO_LIVE_PLAIN_TEXT_BYTES
visual_plain_length: resq 1
visual_pixels_ptr: resq 1
visual_width: resq 1
visual_height: resq 1
visual_stride: resq 1
visual_cursor_x: resq 1
visual_cursor_y: resq 1
visual_line_start_x: resq 1
visual_max_x: resq 1
visual_max_y: resq 1
visual_glyph_color: resd 1
visual_background_color: resq 1
visual_surface_ptr: resq 1
visual_single_line: resd 1
visual_frame_generation: resq 1
visual_presentation_document: resq 1
visual_presentation_colors: resq 1
visual_presentation_positions: resq 1
visual_presentation_capacity: resq 1

section .text
; Bind only the authenticated current document to caller-owned presentation.
nebo_runtime_live_set_presentation:
 mov [rel visual_presentation_document],rdi
 mov [rel visual_presentation_colors],rsi
 mov [rel visual_presentation_positions],rdx
 mov [rel visual_presentation_capacity],rcx
 ret
; render(document*, optional TextEditRecord*, surface*, pixels*, capacity,
;        const LiveConfig*) -> zero on success.
nebo_runtime_live_visual_render:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov [rel visual_surface_ptr],rdx
 mov qword [rel visual_background_color],0
 mov r15,rcx
 mov [rsp],r8
 mov [rsp+8],r9
 test r12,r12
 jz .bad
 test r14,r14
 jz .bad
 test r15,r15
 jz .bad
 test r9,r9
 jz .bad
 mov rbx,[r9+NEBO_LIVE_CONFIG_WIDTH_OFFSET]
 mov r10,[r9+NEBO_LIVE_CONFIG_HEIGHT_OFFSET]
 cmp rbx,NEBO_CHROME_MIN_WINDOW_WIDTH_PX
 jb .bad
 cmp r10,NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
 jb .bad
 cmp rbx,NEBO_SURFACE_MAX_AXIS_PIXELS
 ja .bad
 cmp r10,NEBO_SURFACE_MAX_AXIS_PIXELS
 ja .bad
 mov rax,rbx
 shl rax,2
 jc .bad
 mov [rel visual_stride],rax
 mul r10
 test rdx,rdx
 jnz .bad
 cmp rax,NEBO_SURFACE_MAX_BYTES
 ja .bad
 cmp [rsp],rax
 jb .bad
 mov [rsp+16],rax
 mov rax,[rel visual_frame_generation]
 inc rax
 jz .bad
 mov [rel visual_frame_generation],rax
 mov [rsp+24],rax
 mov [rel visual_pixels_ptr],r15
 mov [rel visual_width],rbx
 mov [rel visual_height],r10

 mov rdi,r14
 xor eax,eax
 mov ecx,NEBO_SOFTWARE_SURFACE_QWORDS
 cld
 rep stosq
 mov [r14+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET],r15
 mov rax,[rsp+16]
 mov [r14+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET],rax
 mov [r14+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET],rbx
 mov [r14+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET],r10
 mov rax,[rel visual_stride]
 mov [r14+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET],rax
 mov qword [r14+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET],NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
 mov rax,[rsp+24]
 mov [r14+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET],rax
 mov qword [r14+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET],NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS

 mov rdi,r15
 mov eax,NEBO_LIVE_CONTENT_BACKGROUND_COLOR
 mov rcx,[rsp+16]
 shr rcx,2
 cld
 rep stosd

 mov rdi,r14
 mov rsi,rbx
 mov rdx,r10
 mov r9,[rsp+8]
 mov rcx,[r9+NEBO_LIVE_CONFIG_WINDOW_FLAGS_OFFSET]
 call nebo_console_chrome_render
 test eax,eax
 jnz .bad

 mov r9,[rsp+8]
 mov qword [rel visual_cursor_x],NEBO_CHROME_TITLE_LEFT_PADDING_PX
 mov qword [rel visual_line_start_x],NEBO_CHROME_TITLE_LEFT_PADDING_PX
 mov qword [rel visual_cursor_y],NEBO_LIVE_TITLE_TOP_PX
 mov rax,rbx
 sub rax,NEBO_CHROME_CONTROLS_WIDTH_PX+NEBO_CHROME_ICON_RIGHT_GAP_PX
 cmp qword [r9+NEBO_LIVE_CONFIG_ICON_WIDTH_OFFSET],0
 je .title_limit_ready
 sub rax,[r9+NEBO_LIVE_CONFIG_ICON_WIDTH_OFFSET]
 sub rax,NEBO_CHROME_ICON_RIGHT_GAP_PX
.title_limit_ready:
 mov [rel visual_max_x],rax
 mov qword [rel visual_max_y],NEBO_CHROME_HEIGHT_PX-1
 mov dword [rel visual_glyph_color],0xfff2f6fc
 mov dword [rel visual_single_line],1
 mov rdi,[r9+NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET]
 mov rsi,[r9+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET]
 call visual_draw_title_bytes

 mov rdi,[rsp+8]
 call visual_draw_icon
 test eax,eax
 jnz .bad

 lea rdi,[rel visual_plain_length]
 mov qword [rdi],0
 mov rdi,r12
 lea rsi,[rel visual_plain_text]
 mov edx,NEBO_LIVE_PLAIN_TEXT_BYTES
 lea rcx,[rel visual_plain_length]
 call nebo_console_document_copy_plain_text
 test eax,eax
 jnz .bad
 mov qword [rel visual_cursor_x],NEBO_LIVE_CONTENT_LEFT_PADDING_PX
 mov qword [rel visual_line_start_x],NEBO_LIVE_CONTENT_LEFT_PADDING_PX
 mov qword [rel visual_cursor_y],NEBO_CHROME_HEIGHT_PX+NEBO_LIVE_CONTENT_TOP_PADDING_PX
 mov rax,[rel visual_width]
 sub rax,NEBO_LIVE_CONTENT_LEFT_PADDING_PX+NEBO_CHROME_BORDER_PX
 mov [rel visual_max_x],rax
 mov rax,[rel visual_height]
 sub rax,NEBO_CHROME_BORDER_PX
 mov [rel visual_max_y],rax
 mov dword [rel visual_glyph_color],0xffdce7f5
 mov dword [rel visual_single_line],0
 cmp r12,[rel visual_presentation_document]
 jne .plain_content
 mov rdi,r12
 call visual_draw_document_nodes
 jmp .content_ready
.plain_content:
 lea rdi,[rel visual_plain_text]
 mov rsi,[rel visual_plain_length]
 call visual_draw_content_bytes
.content_ready:

 test r13,r13
 jz .ok
 mov rsi,[r13+NEBO_TEXT_EDIT_LENGTH_OFFSET]
 test rsi,rsi
 jz .caret
 mov rdi,[r13+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
 test rdi,rdi
 jz .bad
 call visual_draw_content_bytes
.caret:
 call visual_draw_caret
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBO_LIVE_STATUS_RENDER
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
visual_newline: db 10
section .text
visual_draw_document_nodes:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov rax,[r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
 mov rbx,[rax+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET]
.node:
 test rbx,rbx
 jz .done
 mov rax,rbx
 dec rax
 imul r13,rax,NEBO_CONSOLE_NODE_HEADER_SIZE
 add r13,[r12+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
 mov dword [rel visual_glyph_color],0xffdce7f5
 mov qword [rel visual_background_color],0
 cmp rax,[rel visual_presentation_capacity]
 jae .payload
 mov rdx,rax
 shl rdx,4
 add rdx,[rel visual_presentation_colors]
 mov rcx,[rdx+8]
 mov [rel visual_background_color],rcx
 mov rcx,[rdx]
 test rcx,rcx
 jz .position
 mov [rel visual_glyph_color],ecx
.position:
 imul rax,24
 add rax,[rel visual_presentation_positions]
 cmp qword [rax+16],0
 je .payload
 mov rdx,[rax]
 mov [rel visual_cursor_x],rdx
 mov [rel visual_line_start_x],rdx
 mov rdx,[rax+8]
 add rdx,NEBO_CHROME_HEIGHT_PX
 mov [rel visual_cursor_y],rdx
.payload:
 cmp dword [r13+NEBO_CONSOLE_NODE_KIND_OFFSET],NEBO_CONSOLE_NODE_KIND_LINE_BREAK
 je .newline
 mov rdi,[r12+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
 add rdi,[r13+NEBO_CONSOLE_NODE_PAYLOAD_OFFSET_OFFSET]
 mov rsi,[r13+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET]
 jmp .draw
.newline:
 lea rdi,[rel visual_newline]
 mov esi,1
.draw:
 call visual_draw_content_bytes
 mov rbx,[r13+NEBO_CONSOLE_NODE_NEXT_SIBLING_ID_OFFSET]
 jmp .node
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; LiveConfig* -> zero or render error. The icon is owned BGRA8 premultiplied.
visual_draw_icon:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,[r12+NEBO_LIVE_CONFIG_ICON_WIDTH_OFFSET]
 mov r14,[r12+NEBO_LIVE_CONFIG_ICON_HEIGHT_OFFSET]
 test r13,r13
 jz .icon_ok
 test r14,r14
 jz .icon_bad
 cmp r13,NEBO_LIVE_ICON_MAX_WIDTH
 ja .icon_bad
 cmp r14,NEBO_LIVE_ICON_MAX_HEIGHT
 ja .icon_bad
 mov r15,[r12+NEBO_LIVE_CONFIG_ICON_PTR_OFFSET]
 test r15,r15
 jz .icon_bad
 mov rbx,[r12+NEBO_LIVE_CONFIG_ICON_STRIDE_OFFSET]
 mov rax,r13
 shl rax,2
 cmp rbx,rax
 jb .icon_bad
 mov r10,[rel visual_width]
 sub r10,NEBO_CHROME_CONTROLS_WIDTH_PX+NEBO_CHROME_ICON_RIGHT_GAP_PX
 sub r10,r13
 mov r11,NEBO_CHROME_HEIGHT_PX
 sub r11,r14
 shr r11,1
 xor r9d,r9d
.icon_row:
 cmp r9,r14
 jae .icon_ok
 mov rax,r9
 imul rax,rbx
 lea rsi,[r15+rax]
 mov rax,r11
 add rax,r9
 imul rax,[rel visual_stride]
 lea rdi,[rax+r10*4]
 add rdi,[rel visual_pixels_ptr]
 mov rcx,r13
 cld
 rep movsd
 inc r9
 jmp .icon_row
.icon_ok:
 xor eax,eax
 jmp .icon_done
.icon_bad:
 mov eax,NEBO_LIVE_STATUS_RENDER
.icon_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=bytes, RSI=length. Non-ASCII bytes use a bounded '?' fallback.
visual_draw_title_bytes:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .bytes_done
 xor ebx,ebx
.bytes_loop:
 cmp rbx,r13
 jae .bytes_done
 movzx edi,byte [r12+rbx]
 inc rbx
 cmp dil,10
 je .bytes_newline
 cmp dil,13
 je .bytes_loop
 cmp dil,9
 jne .bytes_room
 add qword [rel visual_cursor_x],NEBO_LIVE_TITLE_CELL_WIDTH_PX*4
 jmp .bytes_check_wrap
.bytes_room:
 mov rax,[rel visual_cursor_x]
 add rax,NEBO_LIVE_TITLE_CELL_WIDTH_PX
 cmp rax,[rel visual_max_x]
 ja .bytes_wrap
 mov rsi,[rel visual_cursor_x]
 mov rdx,[rel visual_cursor_y]
 call visual_draw_title_glyph
 add qword [rel visual_cursor_x],NEBO_LIVE_TITLE_CELL_WIDTH_PX
.bytes_check_wrap:
 mov rax,[rel visual_cursor_x]
 add rax,NEBO_LIVE_TITLE_CELL_WIDTH_PX
 cmp rax,[rel visual_max_x]
 jbe .bytes_loop
.bytes_wrap:
 cmp dword [rel visual_single_line],0
 jne .bytes_done
.bytes_newline:
 mov rax,[rel visual_line_start_x]
 mov [rel visual_cursor_x],rax
 add qword [rel visual_cursor_y],NEBO_LIVE_TITLE_LINE_HEIGHT_PX
 mov rax,[rel visual_cursor_y]
 add rax,NEBO_LIVE_TITLE_CELL_HEIGHT_PX
 cmp rax,[rel visual_max_y]
 jbe .bytes_loop
.bytes_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; EDI=ASCII byte, RSI=x, RDX=y.
visual_draw_title_glyph:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12d,edi
 mov r13,rsi
 mov r14,rdx
 cmp r12b,' '
 je .glyph_done
%if NEBO_LIVE_TITLE_MODE = NEBO_LIVE_TITLE_MODE_PROFESSIONAL
 cmp r12d,32
 jb .title_atlas_fallback
 cmp r12d,126
 jbe .title_atlas_index
.title_atlas_fallback:
 mov eax,NEBO_CONSOLE_TITLE_ATLAS_FALLBACK_INDEX
 jmp .title_atlas_offset
.title_atlas_index:
 mov eax,r12d
 sub eax,32
.title_atlas_offset:
 imul eax,NEBO_CONSOLE_TITLE_ATLAS_WIDTH*NEBO_CONSOLE_TITLE_ATLAS_HEIGHT
 lea r15,[rel nebo_console_title_atlas]
 add r15,rax
 xor ebx,ebx
.title_atlas_row:
 cmp ebx,NEBO_CONSOLE_TITLE_ATLAS_HEIGHT
 jae .glyph_done
 mov qword [rsp],0
.title_atlas_col:
 cmp qword [rsp],NEBO_CONSOLE_TITLE_ATLAS_WIDTH
 jae .title_atlas_next_row
 mov rax,rbx
 imul rax,NEBO_CONSOLE_TITLE_ATLAS_WIDTH
 add rax,[rsp]
 movzx edx,byte [r15+rax]
 test edx,edx
 jz .title_atlas_next_col
 mov rdi,r13
 add rdi,[rsp]
 mov rsi,r14
 add rsi,rbx
 call visual_plot_alpha8
.title_atlas_next_col:
 inc qword [rsp]
 jmp .title_atlas_col
.title_atlas_next_row:
 inc ebx
 jmp .title_atlas_row
%else
 cmp r12b,'A'
 jb .glyph_lower_test
 cmp r12b,'Z'
 ja .glyph_lower_test
 movzx eax,r12b
 sub eax,'A'
 lea r15,[rel glyph_upper]
 jmp .glyph_table
.glyph_lower_test:
 cmp r12b,'a'
 jb .glyph_digit_test
 cmp r12b,'z'
 ja .glyph_digit_test
 movzx eax,r12b
 sub eax,'a'
 lea r15,[rel glyph_lower]
 jmp .glyph_table
.glyph_digit_test:
 cmp r12b,'0'
 jb .glyph_punctuation
 cmp r12b,'9'
 ja .glyph_punctuation
 movzx eax,r12b
 sub eax,'0'
 lea r15,[rel glyph_digits]
.glyph_table:
 imul eax,7
 add r15,rax
 xor ebx,ebx
.glyph_row:
 cmp ebx,7
 jae .glyph_done
 movzx eax,byte [r15+rbx]
 mov [rsp],rax
 xor ecx,ecx
.glyph_col:
 cmp ecx,5
 jae .glyph_next_row
 mov eax,16
 shr eax,cl
 test [rsp],rax
 jz .glyph_next_col
 mov rdi,r13
 lea rdi,[rdi+rcx*2]
 mov rsi,r14
 lea rsi,[rsi+rbx*2]
 call visual_plot_2x2
.glyph_next_col:
 inc ecx
 jmp .glyph_col
.glyph_next_row:
 inc ebx
 jmp .glyph_row
.glyph_punctuation:
 mov edi,r12d
 call visual_punctuation_ptr
 mov r15,rax
 xor ebx,ebx
 jmp .glyph_row
%endif
.glyph_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; EDI=ASCII byte -> seven-row glyph pointer.
visual_punctuation_ptr:
 lea rax,[rel punctuation_question]
 cmp dil,'?'
 je .punct_done
 cmp dil,'.'
 jne .punct_comma
 lea rax,[rel punctuation_dot]
 ret
.punct_comma:
 cmp dil,','
 jne .punct_colon
 lea rax,[rel punctuation_comma]
 ret
.punct_colon:
 cmp dil,':'
 jne .punct_semicolon
 lea rax,[rel punctuation_colon]
 ret
.punct_semicolon:
 cmp dil,';'
 jne .punct_plus
 lea rax,[rel punctuation_semicolon]
 ret
.punct_plus:
 cmp dil,'+'
 jne .punct_dash
 lea rax,[rel punctuation_plus]
 ret
.punct_dash:
 cmp dil,'-'
 jne .punct_star
 lea rax,[rel punctuation_dash]
 ret
.punct_star:
 cmp dil,'*'
 jne .punct_slash
 lea rax,[rel punctuation_star]
 ret
.punct_slash:
 cmp dil,'/'
 jne .punct_bang
 lea rax,[rel punctuation_slash]
 ret
.punct_bang:
 cmp dil,'!'
 jne .punct_equals
 lea rax,[rel punctuation_exclamation]
 ret
.punct_equals:
 cmp dil,'='
 jne .punct_underscore
 lea rax,[rel punctuation_equals]
 ret
.punct_underscore:
 cmp dil,'_'
 jne .punct_left_paren
 lea rax,[rel punctuation_underscore]
 ret
.punct_left_paren:
 cmp dil,'('
 jne .punct_right_paren
 lea rax,[rel punctuation_left_paren]
 ret
.punct_right_paren:
 cmp dil,')'
 jne .punct_left_bracket
 lea rax,[rel punctuation_right_paren]
 ret
.punct_left_bracket:
 cmp dil,'['
 jne .punct_right_bracket
 lea rax,[rel punctuation_left_bracket]
 ret
.punct_right_bracket:
 cmp dil,']'
 jne .punct_left_brace
 lea rax,[rel punctuation_right_bracket]
 ret
.punct_left_brace:
 cmp dil,'{'
 jne .punct_right_brace
 lea rax,[rel punctuation_left_brace]
 ret
.punct_right_brace:
 cmp dil,'}'
 jne .punct_done
 lea rax,[rel punctuation_right_brace]
.punct_done:
 ret

; RDI=UTF-8 bytes, RSI=length, RDX=byte offset.
; Returns EAX=decoded scalar (or U+FFFD for an invalid byte) and ECX=bytes
; consumed. Bounds and scalar validity are checked before every multibyte load.
visual_decode_utf8_codepoint:
 mov eax,0xfffd
 mov ecx,1
 cmp rdx,rsi
 jae .utf8_done
 mov r8,rsi
 sub r8,rdx
 movzx r9d,byte [rdi+rdx]
 cmp r9d,0x80
 jb .utf8_ascii
 cmp r9d,0xc2
 jb .utf8_invalid
 cmp r9d,0xdf
 jbe .utf8_two
 cmp r9d,0xef
 jbe .utf8_three
 cmp r9d,0xf4
 jbe .utf8_four
 jmp .utf8_invalid
.utf8_ascii:
 mov eax,r9d
 ret
.utf8_two:
 cmp r8,2
 jb .utf8_invalid
 movzx r10d,byte [rdi+rdx+1]
 mov r11d,r10d
 and r11d,0xc0
 cmp r11d,0x80
 jne .utf8_invalid
 and r9d,0x1f
 shl r9d,6
 and r10d,0x3f
 or r9d,r10d
 mov eax,r9d
 mov ecx,2
 ret
.utf8_three:
 cmp r8,3
 jb .utf8_invalid
 movzx r10d,byte [rdi+rdx+1]
 movzx r11d,byte [rdi+rdx+2]
 mov ecx,r10d
 and ecx,0xc0
 cmp ecx,0x80
 jne .utf8_invalid
 mov ecx,r11d
 and ecx,0xc0
 cmp ecx,0x80
 jne .utf8_invalid
 cmp r9d,0xe0
 jne .utf8_three_not_e0
 cmp r10d,0xa0
 jb .utf8_invalid
.utf8_three_not_e0:
 cmp r9d,0xed
 jne .utf8_three_decode
 cmp r10d,0x9f
 ja .utf8_invalid
.utf8_three_decode:
 and r9d,0x0f
 shl r9d,12
 and r10d,0x3f
 shl r10d,6
 or r9d,r10d
 and r11d,0x3f
 or r9d,r11d
 mov eax,r9d
 mov ecx,3
 ret
.utf8_four:
 cmp r8,4
 jb .utf8_invalid
 movzx r10d,byte [rdi+rdx+1]
 movzx r11d,byte [rdi+rdx+2]
 movzx edx,byte [rdi+rdx+3]
 mov ecx,r10d
 and ecx,0xc0
 cmp ecx,0x80
 jne .utf8_invalid
 mov ecx,r11d
 and ecx,0xc0
 cmp ecx,0x80
 jne .utf8_invalid
 mov ecx,edx
 and ecx,0xc0
 cmp ecx,0x80
 jne .utf8_invalid
 cmp r9d,0xf0
 jne .utf8_four_not_f0
 cmp r10d,0x90
 jb .utf8_invalid
.utf8_four_not_f0:
 cmp r9d,0xf4
 jne .utf8_four_decode
 cmp r10d,0x8f
 ja .utf8_invalid
.utf8_four_decode:
 and r9d,0x07
 shl r9d,18
 and r10d,0x3f
 shl r10d,12
 or r9d,r10d
 and r11d,0x3f
 shl r11d,6
 or r9d,r11d
 and edx,0x3f
 or r9d,edx
 mov eax,r9d
 mov ecx,4
 ret
.utf8_invalid:
 mov eax,0xfffd
 mov ecx,1
.utf8_done:
 ret

; RDI=UTF-8 bytes, RSI=length. Content uses its own fixed-width metrics while
; title geometry remains on the retained 12x14 opaque path above. Every valid
; scalar reaches glyph selection exactly once, independent of its byte length.
visual_draw_content_bytes:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .content_bytes_done
 xor ebx,ebx
.content_bytes_loop:
 cmp rbx,r13
 jae .content_bytes_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call visual_decode_utf8_codepoint
 add rbx,rcx
 mov edi,eax
 cmp edi,10
 je .content_bytes_newline
 cmp edi,13
 je .content_bytes_loop
 cmp edi,9
 jne .content_bytes_room
 add qword [rel visual_cursor_x],NEBO_LIVE_CONTENT_CELL_WIDTH_PX*4
 jmp .content_bytes_check_wrap
.content_bytes_room:
 mov rax,[rel visual_cursor_x]
 add rax,NEBO_LIVE_CONTENT_CELL_WIDTH_PX
 cmp rax,[rel visual_max_x]
 ja .content_bytes_wrap
 cmp qword [rel visual_background_color],0
 je .content_no_background
 mov [rsp],rdi
 mov rdi,[rel visual_surface_ptr]
 mov rsi,[rel visual_cursor_x]
 mov rdx,[rel visual_cursor_y]
 mov ecx,NEBO_LIVE_CONTENT_CELL_WIDTH_PX
 mov r8d,NEBO_LIVE_CONTENT_CELL_HEIGHT_PX
 mov r9d,[rel visual_background_color]
 call nebo_software_surface_fill_rect
 mov rdi,[rsp]
.content_no_background:
 mov rsi,[rel visual_cursor_x]
 mov rdx,[rel visual_cursor_y]
 call visual_draw_content_glyph
 add qword [rel visual_cursor_x],NEBO_LIVE_CONTENT_CELL_WIDTH_PX
.content_bytes_check_wrap:
 mov rax,[rel visual_cursor_x]
 add rax,NEBO_LIVE_CONTENT_CELL_WIDTH_PX
 cmp rax,[rel visual_max_x]
 jbe .content_bytes_loop
.content_bytes_wrap:
 cmp dword [rel visual_single_line],0
 jne .content_bytes_done
.content_bytes_newline:
 mov rax,[rel visual_line_start_x]
 mov [rel visual_cursor_x],rax
 add qword [rel visual_cursor_y],NEBO_LIVE_CONTENT_LINE_HEIGHT_PX
 mov rax,[rel visual_cursor_y]
 add rax,NEBO_LIVE_CONTENT_CELL_HEIGHT_PX
 cmp rax,[rel visual_max_y]
 jbe .content_bytes_loop
.content_bytes_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; EDI=Unicode codepoint, RSI=cell x, RDX=cell y. Candidate A uses bounded 2x2 area
; samples of the legacy source. Candidate B uses the generated higher-resolution
; 8-bit versioned atlas. No path needs a runtime font engine.
visual_draw_content_glyph:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12d,edi
 mov r13,rsi
 mov r14,rdx
 cmp r12d,' '
 je .content_glyph_done
%if NEBO_LIVE_CONTENT_USES_ALPHA8_ATLAS
%if NEBO_LIVE_CONTENT_SMOOTHING_MODE = NEBO_LIVE_SMOOTHING_PROFESSIONAL_ATLAS
 cmp r12d,32
 jb .content_glyph_atlas_fallback
 cmp r12d,126
 jbe .content_glyph_atlas_ascii_index
 cmp r12d,0x00a0
 jb .content_glyph_atlas_extra
 cmp r12d,0x00ff
 jbe .content_glyph_atlas_latin1_index
.content_glyph_atlas_extra:
 cmp r12d,0x20ac
 je .content_glyph_atlas_euro_index
.content_glyph_atlas_fallback:
 mov eax,NEBO_CONSOLE_MONO_ATLAS_REPLACEMENT_INDEX
 jmp .content_glyph_atlas_offset
.content_glyph_atlas_ascii_index:
 mov eax,r12d
 sub eax,32
 jmp .content_glyph_atlas_offset
.content_glyph_atlas_latin1_index:
 mov eax,r12d
 sub eax,0x00a0
 add eax,0x7f-0x20
 jmp .content_glyph_atlas_offset
.content_glyph_atlas_euro_index:
 mov eax,NEBO_CONSOLE_MONO_ATLAS_COUNT-2
 .content_glyph_atlas_offset:
 imul eax,NEBO_LIVE_ACTIVE_ATLAS_WIDTH*NEBO_LIVE_ACTIVE_ATLAS_HEIGHT
 lea r15,[rel nebo_console_mono_atlas]
%else
 cmp r12d,32
 jb .content_glyph_atlas_fallback
 cmp r12d,126
 jbe .content_glyph_atlas_index
.content_glyph_atlas_fallback:
 mov r12d,'?'
.content_glyph_atlas_index:
 mov eax,r12d
 sub eax,32
 imul eax,NEBO_LIVE_ACTIVE_ATLAS_WIDTH*NEBO_LIVE_ACTIVE_ATLAS_HEIGHT
%if NEBO_LIVE_CONTENT_SMOOTHING_MODE = NEBO_LIVE_SMOOTHING_STROKE_ATLAS
 lea r15,[rel live_glyph_smooth_atlas]
%else
 lea r15,[rel live_glyph_crisp_atlas]
%endif
%endif
 add r15,rax
 xor ebx,ebx
.content_glyph_atlas_row:
 cmp ebx,NEBO_LIVE_ACTIVE_ATLAS_HEIGHT
 jae .content_glyph_done
 mov qword [rsp],0
.content_glyph_atlas_col:
 cmp qword [rsp],NEBO_LIVE_ACTIVE_ATLAS_WIDTH
 jae .content_glyph_atlas_next_row
 mov rax,rbx
 imul rax,NEBO_LIVE_ACTIVE_ATLAS_WIDTH
 add rax,[rsp]
 movzx edx,byte [r15+rax]
 test edx,edx
 jz .content_glyph_atlas_next_col
 mov rdi,r13
 add rdi,NEBO_LIVE_CONTENT_GLYPH_X_OFFSET_PX
 add rdi,[rsp]
 mov rsi,r14
 add rsi,NEBO_LIVE_CONTENT_GLYPH_Y_OFFSET_PX
 add rsi,rbx
 call visual_plot_alpha8
.content_glyph_atlas_next_col:
 inc qword [rsp]
 jmp .content_glyph_atlas_col
.content_glyph_atlas_next_row:
 inc ebx
 jmp .content_glyph_atlas_row
%else
 cmp r12b,'A'
 jb .content_glyph_lower_test
 cmp r12b,'Z'
 ja .content_glyph_lower_test
 movzx eax,r12b
 sub eax,'A'
 lea r15,[rel glyph_upper]
 jmp .content_glyph_table
.content_glyph_lower_test:
 cmp r12b,'a'
 jb .content_glyph_digit_test
 cmp r12b,'z'
 ja .content_glyph_digit_test
 movzx eax,r12b
 sub eax,'a'
 lea r15,[rel glyph_lower]
 jmp .content_glyph_table
.content_glyph_digit_test:
 cmp r12b,'0'
 jb .content_glyph_punctuation
 cmp r12b,'9'
 ja .content_glyph_punctuation
 movzx eax,r12b
 sub eax,'0'
 lea r15,[rel glyph_digits]
.content_glyph_table:
 imul eax,NEBO_LIVE_GLYPH_SOURCE_HEIGHT
 add r15,rax
 jmp .content_glyph_ready
.content_glyph_punctuation:
 mov edi,r12d
 call visual_punctuation_ptr
 mov r15,rax
.content_glyph_ready:
%if NEBO_LIVE_CONTENT_SMOOTHING_MODE = NEBO_LIVE_SMOOTHING_OPAQUE_2X
 mov edi,r12d
 mov rsi,r13
 mov rdx,r14
 call visual_draw_title_glyph
 jmp .content_glyph_done
%else
 xor ebx,ebx
.content_glyph_row:
 cmp ebx,NEBO_LIVE_CONTENT_GLYPH_HEIGHT_PX
 jae .content_glyph_done
 mov rax,rbx
 shl rax,2
 inc rax
 imul rax,NEBO_LIVE_GLYPH_SOURCE_HEIGHT
 xor edx,edx
 mov ecx,NEBO_LIVE_CONTENT_GLYPH_HEIGHT_PX*4
 div rcx
 mov [rsp+8],rax
 mov rax,rbx
 shl rax,2
 add rax,3
 imul rax,NEBO_LIVE_GLYPH_SOURCE_HEIGHT
 xor edx,edx
 mov ecx,NEBO_LIVE_CONTENT_GLYPH_HEIGHT_PX*4
 div rcx
 mov [rsp+16],rax
 mov qword [rsp],0
.content_glyph_col:
 cmp qword [rsp],NEBO_LIVE_CONTENT_GLYPH_WIDTH_PX
 jae .content_glyph_next_row
 mov rax,[rsp]
 shl rax,2
 inc rax
 imul rax,NEBO_LIVE_GLYPH_SOURCE_WIDTH
 xor edx,edx
 mov ecx,NEBO_LIVE_CONTENT_GLYPH_WIDTH_PX*4
 div rcx
 mov [rsp+24],rax
 mov rax,[rsp]
 shl rax,2
 add rax,3
 imul rax,NEBO_LIVE_GLYPH_SOURCE_WIDTH
 xor edx,edx
 mov ecx,NEBO_LIVE_CONTENT_GLYPH_WIDTH_PX*4
 div rcx
 mov [rsp+32],rax

 mov rdi,r15
 mov rsi,[rsp+24]
 mov rdx,[rsp+8]
 call visual_sample_source_bit
 mov [rsp+40],rax
 mov rdi,r15
 mov rsi,[rsp+32]
 mov rdx,[rsp+8]
 call visual_sample_source_bit
 add [rsp+40],rax
 mov rdi,r15
 mov rsi,[rsp+24]
 mov rdx,[rsp+16]
 call visual_sample_source_bit
 add [rsp+40],rax
 mov rdi,r15
 mov rsi,[rsp+32]
 mov rdx,[rsp+16]
 call visual_sample_source_bit
 add [rsp+40],rax
 cmp qword [rsp+40],0
 je .content_glyph_next_col
 mov rdi,r13
 add rdi,NEBO_LIVE_CONTENT_GLYPH_X_OFFSET_PX
 add rdi,[rsp]
 mov rsi,r14
 add rsi,NEBO_LIVE_CONTENT_GLYPH_Y_OFFSET_PX
 add rsi,rbx
 mov rdx,[rsp+40]
 call visual_plot_coverage
.content_glyph_next_col:
 inc qword [rsp]
 jmp .content_glyph_col
.content_glyph_next_row:
 inc rbx
 jmp .content_glyph_row
%endif
%endif
.content_glyph_done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=seven-row glyph, RSI=source x [0,4], RDX=source y [0,6].
visual_sample_source_bit:
 movzx eax,byte [rdi+rdx]
 mov ecx,esi
 mov r8d,16
 shr r8d,cl
 test eax,r8d
 setnz al
 movzx eax,al
 ret

; RDI=x, RSI=y, RDX=coverage quarters [1,4]. Blend opaque foreground over the
; already-cleared current frame; output alpha remains opaque.
visual_plot_coverage:
 test rdx,rdx
 jz .coverage_done
 cmp rdx,4
 ja .coverage_done
 cmp rdi,[rel visual_width]
 jae .coverage_done
 cmp rsi,[rel visual_height]
 jae .coverage_done
 imul rsi,[rel visual_stride]
 lea r9,[rsi+rdi*4]
 add r9,[rel visual_pixels_ptr]
 mov r8d,[rel visual_glyph_color]
 cmp edx,4
 je .coverage_solid
 mov r10d,edx
 mov edx,4
 sub edx,r10d
 mov r11d,[r9]

 movzx eax,r11b
 imul eax,edx
 movzx ecx,r8b
 imul ecx,r10d
 add eax,ecx
 add eax,2
 shr eax,2
 mov edi,eax

 mov eax,r11d
 shr eax,8
 and eax,255
 imul eax,edx
 mov ecx,r8d
 shr ecx,8
 and ecx,255
 imul ecx,r10d
 add eax,ecx
 add eax,2
 shr eax,2
 shl eax,8
 or edi,eax

 mov eax,r11d
 shr eax,16
 and eax,255
 imul eax,edx
 mov ecx,r8d
 shr ecx,16
 and ecx,255
 imul ecx,r10d
 add eax,ecx
 add eax,2
 shr eax,2
 shl eax,16
 or edi,eax
 or edi,0xff000000
 mov [r9],edi
 ret
.coverage_solid:
 mov [r9],r8d
.coverage_done:
 ret

; RDI=x, RSI=y, RDX=coverage [1,255]. Candidate B's precomputed grayscale
; atlas is blended over the already-cleared opaque current frame.
visual_plot_alpha8:
 test edx,edx
 jz .alpha8_done
 cmp edx,255
 ja .alpha8_done
 cmp rdi,[rel visual_width]
 jae .alpha8_done
 cmp rsi,[rel visual_height]
 jae .alpha8_done
 imul rsi,[rel visual_stride]
 lea r9,[rsi+rdi*4]
 add r9,[rel visual_pixels_ptr]
 mov r8d,[rel visual_glyph_color]
 cmp edx,255
 je .alpha8_solid
 mov r10d,edx
 mov edi,255
 sub edi,r10d
 mov r11d,[r9]

 movzx eax,r11b
 imul eax,edi
 movzx ecx,r8b
 imul ecx,r10d
 add eax,ecx
 add eax,127
 xor edx,edx
 mov ecx,255
 div ecx
 mov esi,eax

 mov eax,r11d
 shr eax,8
 and eax,255
 imul eax,edi
 mov ecx,r8d
 shr ecx,8
 and ecx,255
 imul ecx,r10d
 add eax,ecx
 add eax,127
 xor edx,edx
 mov ecx,255
 div ecx
 shl eax,8
 or esi,eax

 mov eax,r11d
 shr eax,16
 and eax,255
 imul eax,edi
 mov ecx,r8d
 shr ecx,16
 and ecx,255
 imul ecx,r10d
 add eax,ecx
 add eax,127
 xor edx,edx
 mov ecx,255
 div ecx
 shl eax,16
 or esi,eax
 or esi,0xff000000
 mov [r9],esi
 ret
.alpha8_solid:
 mov [r9],r8d
.alpha8_done:
 ret

; RDI=x, RSI=y. Every write is clipped independently of caller wrapping.
visual_plot_2x2:
 mov rax,rdi
 inc rax
 cmp rax,[rel visual_width]
 jae .plot_done
 mov rax,rsi
 inc rax
 cmp rax,[rel visual_height]
 jae .plot_done
 imul rsi,[rel visual_stride]
 lea rax,[rsi+rdi*4]
 add rax,[rel visual_pixels_ptr]
 mov edx,[rel visual_glyph_color]
 mov [rax],edx
 mov [rax+4],edx
 add rax,[rel visual_stride]
 mov [rax],edx
 mov [rax+4],edx
.plot_done:
 ret

visual_draw_caret:
 mov rdi,[rel visual_cursor_x]
 mov rsi,[rel visual_cursor_y]
 add rsi,NEBO_LIVE_CONTENT_GLYPH_Y_OFFSET_PX
 mov rax,rdi
 add rax,NEBO_LIVE_CONTENT_CARET_WIDTH_PX
 cmp rax,[rel visual_width]
 ja .caret_done
 mov rax,rsi
 add rax,NEBO_LIVE_CONTENT_GLYPH_HEIGHT_PX
 cmp rax,[rel visual_height]
 ja .caret_done
 imul rsi,[rel visual_stride]
 lea rax,[rsi+rdi*4]
 add rax,[rel visual_pixels_ptr]
 mov ecx,NEBO_LIVE_CONTENT_GLYPH_HEIGHT_PX
.caret_loop:
 mov rdx,rax
 mov r8d,NEBO_LIVE_CONTENT_CARET_WIDTH_PX
.caret_row:
 mov dword [rdx],0xff78a9ff
 add rdx,4
 dec r8d
 jnz .caret_row
 add rax,[rel visual_stride]
 dec ecx
 jnz .caret_loop
.caret_done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
