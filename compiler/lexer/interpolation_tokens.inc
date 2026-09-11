%ifndef NEBOC_LEX_INTERPOLATION_TOKENS_INC
%define NEBOC_LEX_INTERPOLATION_TOKENS_INC 1
; Private lexical context: normal expression tokens still use lexer_scan.
; Each active interpolated quote retains its own chunk and brace state.
%define LEX_INTERP_DEPTH 240
%define LEX_INTERP_PENDING 248
%define LEX_INTERP_FRAMES 256
%define LEX_INTERP_FRAME_SIZE 48
%define LEX_INTERP_MAX_DEPTH 16
%define LEX_INTERP_STACK_SIZE 1024
%define LEX_INTERP_QUOTE 0
%define LEX_INTERP_SOURCE 8
%define LEX_INTERP_POOL 16
%define LEX_INTERP_BRACES 24
%define LEX_INTERP_STATE 32
%define LEX_INTERP_SEGMENTS 40
; State 1 awaits `${`, state 2 uses the ordinary lexer, state 3 scans Text.

%macro LEX_INTERP_TOP 1
 mov %1,[rsp+LEX_INTERP_DEPTH]
 dec %1
 imul %1,LEX_INTERP_FRAME_SIZE
 lea %1,[rsp+%1+LEX_INTERP_FRAMES]
%endmacro

%macro LEX_INTERPOLATION_BODY 0
.interpolation_begin:
 ; R15 points at an unescaped `${` inside the ordinary Text scanner.
 cmp qword [rsp+LEX_INTERP_DEPTH],0
 je .interpolation_push
 LEX_INTERP_TOP r8
 cmp qword [r8+LEX_INTERP_STATE],3
 je .interpolation_middle
.interpolation_push:
 cmp qword [rsp+LEX_INTERP_DEPTH],LEX_INTERP_MAX_DEPTH
 jae .limit
 inc qword [rsp+LEX_INTERP_DEPTH]
 LEX_INTERP_TOP r8
 mov rax,[rsp]
 mov [r8+LEX_INTERP_QUOTE],rax
 mov [r8+LEX_INTERP_SOURCE],rax
 mov rax,[rsp+16]
 mov [r8+LEX_INTERP_POOL],rax
 mov qword [r8+LEX_INTERP_SEGMENTS],0
 mov r10d,NEBOC_TOKEN_INTERPOLATION_HEAD
 jmp .interpolation_chunk
.interpolation_middle:
 mov r10d,NEBOC_TOKEN_INTERPOLATION_MIDDLE
.interpolation_chunk:
 mov rax,[r8+LEX_INTERP_POOL]
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 sub rcx,rax
 mov edx,0xffffffff
 cmp rax,rdx
 ja .limit
 cmp rcx,rdx
 ja .limit
 inc qword [r8+LEX_INTERP_SEGMENTS]
 test rcx,rcx
 jz .interpolation_chunk_counted
 inc qword [r8+LEX_INTERP_SEGMENTS]
.interpolation_chunk_counted:
 cmp qword [r8+LEX_INTERP_SEGMENTS],64
 ja .limit
 shl rax,32
 or rax,rcx
 mov [rsp+8],rax
 mov r11,[r8+LEX_INTERP_SOURCE]
 mov r9d,NEBOC_TOKEN_FLAG_TEXT_DECODED
 mov qword [r8+LEX_INTERP_STATE],1
 mov qword [rsp+LEX_INTERP_PENDING],1
 jmp .emit
.interpolation_open:
 mov qword [rsp+LEX_INTERP_PENDING],0
 LEX_INTERP_TOP r8
 mov qword [r8+LEX_INTERP_STATE],2
 mov qword [r8+LEX_INTERP_BRACES],1
 mov r11,r15
 add r15,2
 mov r10d,NEBOC_TOKEN_INTERPOLATION_OPEN
 xor r9d,r9d
 mov qword [rsp+8],0
 jmp .emit
.interpolation_resume_text:
 mov qword [rsp+LEX_INTERP_PENDING],0
 LEX_INTERP_TOP r8
 mov [r8+LEX_INTERP_SOURCE],r15
 mov rax,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [r8+LEX_INTERP_POOL],rax
 mov [rsp+16],rax
 mov rax,[r8+LEX_INTERP_QUOTE]
 mov [rsp],rax
 jmp .text_loop
.interpolation_tail:
 ; R15 points to the closing quote; the final segment includes that delimiter.
 LEX_INTERP_TOP r8
 mov rcx,r15
 sub rcx,[r8+LEX_INTERP_QUOTE]
 dec rcx
 cmp rcx,4096
 ja .limit
 mov rax,[r8+LEX_INTERP_POOL]
 mov rcx,[r12+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 sub rcx,rax
 test rcx,rcx
 jz .interpolation_tail_counted
 inc qword [r8+LEX_INTERP_SEGMENTS]
.interpolation_tail_counted:
 cmp qword [r8+LEX_INTERP_SEGMENTS],64
 ja .limit
 mov edx,0xffffffff
 cmp rax,rdx
 ja .limit
 cmp rcx,rdx
 ja .limit
 shl rax,32
 or rax,rcx
 mov [rsp+8],rax
 mov r11,[r8+LEX_INTERP_SOURCE]
 inc r15
 dec qword [rsp+LEX_INTERP_DEPTH]
 mov r10d,NEBOC_TOKEN_INTERPOLATION_TAIL
 mov r9d,NEBOC_TOKEN_FLAG_TEXT_DECODED
 jmp .emit
.interpolation_unterminated:
 LEX_INTERP_TOP r8
 mov r11,[r8+LEX_INTERP_QUOTE]
 mov qword [rsp+LEX_INTERP_DEPTH],0
 mov qword [rsp+LEX_INTERP_PENDING],0
 mov r10d,NEBOC_TOKEN_UNTERMINATED_TEXT
 mov r9d,NEBOC_TOKEN_FLAG_ERROR
 mov qword [rsp+8],NEBOC_LEX_DIAG_UNTERMINATED_TEXT
 inc qword [r12+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 jmp .emit
%endmacro
%endif
