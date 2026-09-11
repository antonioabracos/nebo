; Source-to-effect oracle for G067 target-independent style tokens.
bits 64
default rel
%define NEBO_G067_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/textual/render_nodes_source_probe.inc"
%include "runtime/textual/render_console.inc"

section .rodata
g67_bar: db '|'
g67_b: db 'B'
g67_i: db 'I'
g67_u: db 'U'
g67_d: db 'D'
g67_v: db 'V'
g67_k: db 'K'
g67_r: db 'R'
g67_g: db 'G'
g67_y: db 'Y'
g67_c: db 'C'
g67_m: db 'M'
g67_a: db 'A'
g67_n: db 'N'
g67_x: db 'X'
g67_q: db 'Q'
g67_z: db 'Z'
g67_s: db 'S'
g67_t: db 'T'
g67_same: db 'same'
g67_stable: db 'stable'
g67_ok: db '[ok]'
g67_success: db '[success]'
g67_warn: db '[warn]'
g67_warning: db '[warning]'
g67_error: db '[error]'
g67_fail: db '[fail]'
g67_info: db '[info]'
g67_debug: db '[debug]'
g67_trace: db '[trace]'
g67_blocked: db '[blocked]'
g67_todo: db '[todo]'
g67_done: db '[done]'
g67_skip: db '[skip]'
g67_pending: db '[pending]'
g67_critical: db '[critical]'
g67_neutral: db '[neutral]'

g67_plain_1: db 'B|I|U|D|V|K'
g67_plain_1_len equ $-g67_plain_1
g67_ansi_1:
 db 27,'[1mB',27,'[0m|',27,'[3mI',27,'[0m|',27,'[4mU',27,'[0m|'
 db 27,'[2mD',27,'[0m|',27,'[7mV',27,'[0m|',27,'[5mK',27,'[0m'
g67_ansi_1_len equ $-g67_ansi_1
g67_plain_2: db 'R|G|B|Y|C|M|A|N|X|Q|Z|S|T'
g67_plain_2_len equ $-g67_plain_2
g67_ansi_2:
 db 27,'[31mR',27,'[0m|',27,'[32mG',27,'[0m|',27,'[34mB',27,'[0m|'
 db 27,'[33mY',27,'[0m|',27,'[36mC',27,'[0m|',27,'[35mM',27,'[0m|'
 db 27,'[90mA',27,'[0m|',27,'[31mN',27,'[0m|'
 db 27,'[38;2;018;052;171mX',27,'[0m|',27,'[44mQ',27,'[0m|'
 db 27,'[0mZ',27,'[0m|',27,'[1mS',27,'[0m|',27,'[36mT',27,'[0m'
g67_ansi_2_len equ $-g67_ansi_2
g67_plain_3:
 db '[ok]|[success]|[warn]|[warning]|[error]|[fail]|[info]|[debug]|'
 db '[trace]|[blocked]|[todo]|[done]|[skip]|[pending]|[critical]|[neutral]'
g67_plain_3_len equ $-g67_plain_3
g67_plain_4: db 'same[info]'
g67_plain_4_len equ $-g67_plain_4
g67_ansi_4: db 27,'[1msame',27,'[0m[info]'
g67_ansi_4_len equ $-g67_ansi_4
g67_ansi_5: db 27,'[38;2;018;052;171mstable',27,'[0m'
g67_ansi_5_len equ $-g67_ansi_5

section .data align=16
%macro G67_STYLE 2
 dq RENDER_NODE_STYLE,RENDER_FLAG_FALLBACK,0,0,%1,%2
%endmacro
%macro G67_TEXT 2
 dq RENDER_NODE_TEXT,RENDER_FLAG_FALLBACK,%1,%2,0,0
%endmacro
%macro G67_SEMANTIC 2
 dq RENDER_NODE_SEMANTIC,RENDER_FLAG_FALLBACK,%1,%2,0,0
%endmacro
%macro G67_BAR 0
 dq RENDER_NODE_SEPARATOR,RENDER_FLAG_FALLBACK,g67_bar,1,0,0
%endmacro

g67_nodes_1:
 G67_STYLE RENDER_STYLE_BOLD,0
 G67_TEXT g67_b,1
 G67_STYLE RENDER_STYLE_RESET,0
 G67_BAR
 G67_STYLE RENDER_STYLE_ITALIC,0
 G67_TEXT g67_i,1
 G67_STYLE RENDER_STYLE_RESET,0
 G67_BAR
 G67_STYLE RENDER_STYLE_UNDERLINE,0
 G67_TEXT g67_u,1
 G67_STYLE RENDER_STYLE_RESET,0
 G67_BAR
 G67_STYLE RENDER_STYLE_DIM,0
 G67_TEXT g67_d,1
 G67_STYLE RENDER_STYLE_RESET,0
 G67_BAR
 G67_STYLE RENDER_STYLE_INVERSE,0
 G67_TEXT g67_v,1
 G67_STYLE RENDER_STYLE_RESET,0
 G67_BAR
 G67_STYLE RENDER_STYLE_BLINK,0
 G67_TEXT g67_k,1
 G67_STYLE RENDER_STYLE_RESET,0
g67_nodes_1_count equ ($-g67_nodes_1)/RENDER_NODE_SIZE

g67_nodes_2:
%macro G67_COLOR_ITEM 3
 G67_STYLE %1,%2
 G67_TEXT %3,1
 G67_STYLE RENDER_STYLE_RESET,0
%endmacro
 G67_COLOR_ITEM RENDER_STYLE_FG_RED,0,g67_r
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_GREEN,0,g67_g
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_BLUE,0,g67_b
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_YELLOW,0,g67_y
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_CYAN,0,g67_c
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_MAGENTA,0,g67_m
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_GRAY,0,g67_a
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_RED,0,g67_n
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_FG_RGB,0x1234ab,g67_x
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_BG_BLUE,0,g67_q
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_RESET,0,g67_z
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_GENERIC,0,g67_s
 G67_BAR
 G67_COLOR_ITEM RENDER_STYLE_THEME,0,g67_t
g67_nodes_2_count equ ($-g67_nodes_2)/RENDER_NODE_SIZE
%undef G67_COLOR_ITEM

g67_nodes_3:
 G67_SEMANTIC g67_ok,4
 G67_BAR
 G67_SEMANTIC g67_success,9
 G67_BAR
 G67_SEMANTIC g67_warn,6
 G67_BAR
 G67_SEMANTIC g67_warning,9
 G67_BAR
 G67_SEMANTIC g67_error,7
 G67_BAR
 G67_SEMANTIC g67_fail,6
 G67_BAR
 G67_SEMANTIC g67_info,6
 G67_BAR
 G67_SEMANTIC g67_debug,7
 G67_BAR
 G67_SEMANTIC g67_trace,7
 G67_BAR
 G67_SEMANTIC g67_blocked,9
 G67_BAR
 G67_SEMANTIC g67_todo,6
 G67_BAR
 G67_SEMANTIC g67_done,6
 G67_BAR
 G67_SEMANTIC g67_skip,6
 G67_BAR
 G67_SEMANTIC g67_pending,9
 G67_BAR
 G67_SEMANTIC g67_critical,10
 G67_BAR
 G67_SEMANTIC g67_neutral,9
g67_nodes_3_count equ ($-g67_nodes_3)/RENDER_NODE_SIZE

g67_nodes_4:
 G67_STYLE RENDER_STYLE_BOLD,0
 G67_TEXT g67_same,4
 G67_STYLE RENDER_STYLE_RESET,0
 G67_SEMANTIC g67_info,6
g67_nodes_4_count equ ($-g67_nodes_4)/RENDER_NODE_SIZE
g67_nodes_5:
 G67_STYLE RENDER_STYLE_FG_RGB,0x1234ab
 G67_TEXT g67_stable,6
 G67_STYLE RENDER_STYLE_RESET,0
g67_nodes_5_count equ ($-g67_nodes_5)/RENDER_NODE_SIZE
g67_bad_token:
 G67_STYLE 0,0
g67_bad_aux:
 G67_STYLE RENDER_STYLE_BOLD,1
g67_bad_rgb:
 G67_STYLE RENDER_STYLE_FG_RGB,0x1000000
%undef G67_STYLE
%undef G67_TEXT
%undef G67_SEMANTIC
%undef G67_BAR

section .bss align=16
g67_output_a: resb 1024
g67_output_b: resb 1024
g67_atomic: resb 1024

section .text
extern neboc_render_plan_validate
extern neboc_render_plan_measure
extern neboc_render_plan_write
extern neboc_render_feature_validate
global nebo_g067_source_probe
global nebo_g067_negative_probe

; RDI nodes, RSI count, EDX target, RCX expected, R8 expected length.
g67_run_plan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14d,edx
 mov r15,rcx
 mov rbx,r8
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 call neboc_render_plan_validate
 test eax,eax
 jnz .fail
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 call neboc_render_plan_measure
 cmp rax,rbx
 jne .fail
 lea rdi,[rel g67_output_a]
 mov ecx,1024
 mov al,0xa5
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g67_output_a]
 mov r8d,1024
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g67_output_a]
 mov rdi,r15
 mov rcx,rbx
 repe cmpsb
 jne .fail
 lea rdi,[rel g67_output_b]
 mov ecx,1024
 mov al,0x5a
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g67_output_b]
 mov r8d,1024
 call neboc_render_plan_write
 cmp rax,rbx
 jne .fail
 lea rsi,[rel g67_output_a]
 lea rdi,[rel g67_output_b]
 mov rcx,rbx
 repe cmpsb
 jne .fail
 test rbx,rbx
 jz .ok
 lea rdi,[rel g67_atomic]
 mov ecx,1024
 mov al,0xcc
 rep stosb
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 lea rcx,[rel g67_atomic]
 lea r8,[rbx-1]
 call neboc_render_plan_write
 cmp rax,-RENDER_E_CAPACITY
 jne .fail
 cmp byte [rel g67_atomic],0xcc
 jne .fail
.ok: xor eax,eax
 jmp .done
.fail: mov eax,1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%macro G67_RUN 5
 lea rdi,[rel %1]
 mov esi,%2
 mov edx,%3
 lea rcx,[rel %4]
 mov r8d,%5
 call g67_run_plan
 test eax,eax
 jnz .return
%endmacro

nebo_g067_source_probe:
 push rbx
 mov ebx,esi
 cmp edi,1
 je .m1
 cmp edi,2
 je .m2
 cmp edi,3
 je .m3
 cmp edi,4
 je .m4
 cmp edi,5
 je .m5
 mov eax,RENDER_E_UNAVAILABLE
 jmp .return
.m1:
 G67_RUN g67_nodes_1,g67_nodes_1_count,RENDER_TARGET_PLAIN,g67_plain_1,g67_plain_1_len
 G67_RUN g67_nodes_1,g67_nodes_1_count,RENDER_TARGET_ANSI,g67_ansi_1,g67_ansi_1_len
 jmp .success
.m2:
 G67_RUN g67_nodes_2,g67_nodes_2_count,RENDER_TARGET_PLAIN,g67_plain_2,g67_plain_2_len
 G67_RUN g67_nodes_2,g67_nodes_2_count,RENDER_TARGET_ANSI,g67_ansi_2,g67_ansi_2_len
 jmp .success
.m3:
 G67_RUN g67_nodes_3,g67_nodes_3_count,RENDER_TARGET_PLAIN,g67_plain_3,g67_plain_3_len
 G67_RUN g67_nodes_3,g67_nodes_3_count,RENDER_TARGET_HEADLESS,g67_plain_3,g67_plain_3_len
 jmp .success
.m4:
 G67_RUN g67_nodes_4,g67_nodes_4_count,RENDER_TARGET_PLAIN,g67_plain_4,g67_plain_4_len
 G67_RUN g67_nodes_4,g67_nodes_4_count,RENDER_TARGET_ANSI,g67_ansi_4,g67_ansi_4_len
 G67_RUN g67_nodes_4,g67_nodes_4_count,RENDER_TARGET_MARKDOWN,g67_plain_4,g67_plain_4_len
 G67_RUN g67_nodes_4,g67_nodes_4_count,RENDER_TARGET_HTML,g67_plain_4,g67_plain_4_len
 G67_RUN g67_nodes_4,g67_nodes_4_count,RENDER_TARGET_HEADLESS,g67_plain_4,g67_plain_4_len
 jmp .success
.m5:
 G67_RUN g67_nodes_5,g67_nodes_5_count,RENDER_TARGET_ANSI,g67_ansi_5,g67_ansi_5_len
.success: mov eax,ebx
.return: pop rbx
 ret
%undef G67_RUN

nebo_g067_negative_probe:
 cmp edi,1
 je .token
 cmp edi,2
 je .aux
 cmp edi,3
 je .rgb
 cmp edi,4
 je .feature
 mov eax,RENDER_E_UNAVAILABLE
 ret
.token: lea rdi,[rel g67_bad_token]
 jmp .validate
.aux: lea rdi,[rel g67_bad_aux]
 jmp .validate
.rgb: lea rdi,[rel g67_bad_rgb]
.validate:
 mov esi,1
 mov edx,RENDER_TARGET_ANSI
 call neboc_render_plan_validate
 ret
.feature:
 mov edi,6701
 xor esi,esi
 mov edx,8
 mov ecx,1
 mov r8d,RENDER_TARGET_ANSI
 jmp neboc_render_feature_validate
