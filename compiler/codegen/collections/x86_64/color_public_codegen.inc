; Nominal Color and role-tagged ConsoleOption use the existing Color owner.
extern nebo_color_hex_literal
section .text
fcg_color_public_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov qword [rsp+48],0
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .ordinary_call
 CP_MATCH cp_Color,5,.constructor
.ordinary_call:
 mov rax,r13
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+32],rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+40],rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .method
 ; A lexical binding owns its name before a builtin namespace does.
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 call fcg_find_prior_binding
 test rax,rax
 jnz .method
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel cp_Color]
 mov ecx,5
 call fcg_token_matches_literal
 test eax,eax
 jnz .Color
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel cp_Console]
 mov ecx,7
 call fcg_token_matches_literal
 test eax,eax
 jnz .Console
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel cp_Position]
 mov ecx,8
 call fcg_token_matches_literal
 test eax,eax
 jz .method
 CP_MATCH cp_color_at,2,.position
 jmp .no
.constructor:
 mov qword [rsp+48],1
 mov rax,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+40],rax
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 je .rgb
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],4
 je .rgba
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 je .hex
 jmp .bad
.method:
 mov rdi,rbx
 mov rsi,[rsp+32]
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,FCG_TYPE_COLOR_RESULT
 je .result_method
 cmp rax,FCG_TYPE_COLOR
 jne .no
 CP_MATCH cp_color_red,3,.red
 CP_MATCH cp_color_green,5,.green
 CP_MATCH cp_color_blue,4,.blue
 CP_MATCH cp_color_alpha,5,.alpha
 CP_MATCH cp_color_withAlpha,9,.withAlpha
 CP_MATCH cp_color_isOpaque,8,.isOpaque
 CP_MATCH cp_color_equals,6,.equals
 CP_MATCH cp_color_toHex,5,.toHex
 CP_MATCH cp_color_toHexWithAlpha,14,.toHexWithAlpha
 CP_MATCH cp_color_hash,4,.hash
 jmp .bad
.result_method:
 CP_MATCH cp_color_isOk,4,.isOk
 CP_MATCH cp_color_isErr,5,.isErr
 CP_MATCH cp_color_expect,6,.expect
 CP_MATCH cp_color_unwrapOr,8,.unwrapOr
 jmp .bad
.Color:
 CP_MATCH cp_color_rgb,3,.rgb
 CP_MATCH cp_color_rgba,4,.rgba
 CP_MATCH cp_color_hex,3,.hex
 CP_MATCH cp_color_parseHex,8,.parseHex
 jmp .bad
.Console:
 CP_MATCH cp_color_fg,2,.fg
 CP_MATCH cp_color_bg,2,.bg
 jmp .no
.rgb:
 mov qword [rsp],20
 mov qword [rsp+8],3
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],FCG_TYPE_COLOR
 jmp .arguments
.rgba:
 mov qword [rsp],21
 mov qword [rsp+8],4
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],FCG_TYPE_COLOR
 jmp .arguments
.red:
 mov qword [rsp],22
 mov qword [rsp+8],0
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .arguments
.green:
 mov qword [rsp],23
 mov qword [rsp+8],0
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .arguments
.blue:
 mov qword [rsp],24
 mov qword [rsp+8],0
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .arguments
.alpha:
 mov qword [rsp],25
 mov qword [rsp+8],0
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .arguments
.withAlpha:
 mov qword [rsp],26
 mov qword [rsp+8],1
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],FCG_TYPE_COLOR
 jmp .arguments
.isOpaque:
 mov qword [rsp],27
 mov qword [rsp+8],0
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .arguments
.equals:
 mov qword [rsp],28
 mov qword [rsp+8],1
 mov qword [rsp+16],FCG_TYPE_COLOR
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .arguments
.fg:
 mov qword [rsp],30
 mov qword [rsp+8],1
 mov qword [rsp+16],FCG_TYPE_COLOR
 mov qword [rsp+24],FCG_TYPE_CONSOLE_OPTION
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],4
 jne .arguments
 mov qword [rsp],32
 mov qword [rsp+8],3
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 jmp .arguments
.bg:
 mov qword [rsp],31
 mov qword [rsp+8],1
 mov qword [rsp+16],FCG_TYPE_COLOR
 mov qword [rsp+24],FCG_TYPE_CONSOLE_OPTION
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],4
 jne .arguments
 mov qword [rsp],33
 mov qword [rsp+8],3
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 jmp .arguments
 .position:
 mov qword [rsp],40
 mov qword [rsp+8],2
 mov qword [rsp+16],NEBOC_TYPE_ID_INT
 mov qword [rsp+24],FCG_TYPE_POSITION
 jmp .arguments
.hex:
 mov qword [rsp],41
 mov qword [rsp+8],1
 mov qword [rsp+16],NEBOC_TYPE_ID_TEXT
 mov qword [rsp+24],FCG_TYPE_COLOR
 jmp .arguments
.parseHex:
 mov qword [rsp],42
 mov qword [rsp+8],1
 mov qword [rsp+16],NEBOC_TYPE_ID_TEXT
 mov qword [rsp+24],FCG_TYPE_COLOR_RESULT
 jmp .arguments
.toHex:
 mov qword [rsp],43
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],NEBOC_TYPE_ID_TEXT
 jmp .arguments
.toHexWithAlpha:
 mov qword [rsp],44
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],NEBOC_TYPE_ID_TEXT
 jmp .arguments
.hash:
 mov qword [rsp],45
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .arguments
.isOk:
 mov qword [rsp],46
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .arguments
.isErr:
 mov qword [rsp],47
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .arguments
.expect:
 mov qword [rsp],48
 mov qword [rsp+8],1
 mov qword [rsp+16],NEBOC_TYPE_ID_TEXT
 mov qword [rsp+24],FCG_TYPE_COLOR
 jmp .arguments
.unwrapOr:
 mov qword [rsp],49
 mov qword [rsp+8],1
 mov qword [rsp+16],FCG_TYPE_COLOR
 mov qword [rsp+24],FCG_TYPE_COLOR
 jmp .arguments
.arguments:
 mov rax,[rsp+8]
 inc rax
 sub rax,[rsp+48]
 cmp [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 jne .bad
 mov r14,[rsp+40]
 xor r15d,r15d
.loop:
 cmp r15,[rsp+8]
 jae .yes
 test r14,r14
 jz .bad
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+16]
 jne .bad
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov rdx,[rsp]
 cmp rdx,20
 je .channel_literal
 cmp rdx,21
 je .channel_literal
 cmp rdx,26
 je .channel_literal
 cmp rdx,32
 je .channel_literal
 cmp rdx,33
 jne .next_argument
.channel_literal:
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .channel_unary
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],255
 ja .bad
 jmp .next_argument
.channel_unary:
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 jne .next_argument
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .next_argument
 mov [rsp+56],rax
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .restore_unary
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 jne .bad
.restore_unary:
 mov rax,[rsp+56]
.next_argument:
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .loop
.yes:
 cmp qword [rsp],41
 jne .typed
 ; Color.hex and its Text sugar require an actual compile-time literal.
 mov rdi,rbx
 mov rsi,[rsp+40]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 jne .bad
 mov rdi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov esi,edi
 shr rdi,32
 mov rax,rdi
 add rax,rsi
 jc .bad
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET]
 ja .bad
 add rdi,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET]
 lea rdx,[rsp+56]
 call nebo_color_hex_literal
 test eax,eax
 jnz .bad
.typed:
 mov rax,[rsp]
 mov rcx,[rsp+24]
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

fcg_color_public_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_color_public_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 CP_APPEND cp_color_extern
 CP_APPEND ftm_frame_head
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov esi,112
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND ftm_frame_tail
 xor r15d,r15d
 ; Constructor sugar has no namespace child; reserve slot zero and evaluate
 ; all real source arguments once into the same native factory ABI.
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .ordinary_operands
 inc r15
 jmp .operand
.ordinary_operands:
 cmp qword [rsp],22
 jb .skip_namespace
 cmp qword [rsp],30
 jb .operand
 cmp qword [rsp],43
 jae .operand
.skip_namespace:
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
.operand:
 test r14,r14
 jz .invoke
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 CP_APPEND cp_color_save
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r15
 shl rsi,3
 cmp r15,3
 jb .slot
 add rsi,8
.slot:
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 CP_APPEND cp_color_save_tail
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .operand
.invoke:
 CP_APPEND cp_op
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 cmp qword [rsp],40
 je .position_result
 cmp qword [rsp],42
 jb .scalar_result
 cmp qword [rsp],44
 jbe .position_result
.scalar_result:
 CP_APPEND cp_color_call
 jmp .done
.position_result:
 CP_APPEND cp_position_call
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .rodata
cp_Color: db 'Color'
cp_Console: db 'Console'
cp_color_rgb: db 'rgb'
cp_color_rgba: db 'rgba'
cp_color_red: db 'red'
cp_color_green: db 'green'
cp_color_blue: db 'blue'
cp_color_alpha: db 'alpha'
cp_color_withAlpha: db 'withAlpha'
cp_color_isOpaque: db 'isOpaque'
cp_color_equals: db 'equals'
cp_color_fg: db 'fg'
cp_color_bg: db 'bg'
cp_color_extern: db '%ifndef NEBO_COLOR_PUBLIC_DECLARED',10,'%define NEBO_COLOR_PUBLIC_DECLARED 1',10,'extern nebo_runtime_color_public_call',10,'%endif',10
cp_color_extern_len equ $-cp_color_extern
cp_color_save: db '    mov [r12+'
cp_color_save_len equ $-cp_color_save
cp_color_save_tail: db '], rax',10
cp_color_save_tail_len equ $-cp_color_save_tail
cp_color_call: db 10,'    mov rsi, r12',10,'    call nebo_runtime_color_public_call',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10,'    add rsp, 112',10
cp_color_call_len equ $-cp_color_call

cp_Position: db 'Position'
cp_color_at: db 'at'
cp_position_call: db 10,'    mov rsi, r12',10,'    call nebo_runtime_color_public_call',10,'    mov rsp, r12',10,'    mov r12, [r12+24]',10
cp_position_call_len equ $-cp_position_call

cp_color_hex: db 'hex'

cp_color_parseHex: db 'parseHex'

cp_color_toHex: db 'toHex'

cp_color_toHexWithAlpha: db 'toHexWithAlpha'

cp_color_hash: db 'hash'

cp_color_isOk: db 'isOk'

cp_color_isErr: db 'isErr'

cp_color_expect: db 'expect'

cp_color_unwrapOr: db 'unwrapOr'
