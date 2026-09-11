; Generic bounded Slash DSL parser and renderer. Dispatch is determined only
; by source bytes and a typed target, never by fixture names or source paths.
bits 64
default rel
%define NEBO_SLASH_DSL_IMPLEMENTATION 1
%include "runtime/textual/slash_dsl.inc"

SLASH_FLAG_CONTENT equ 1
SLASH_FLAG_ARGUMENT equ 2
SLASH_REGISTRY_ENTRY_SIZE equ 24

section .rodata
%macro SLASH_NAME 4
slash_name_%1: db %2
slash_name_%1_len equ $-slash_name_%1
%endmacro
SLASH_NAME br,'br',1,0
SLASH_NAME line,'line',2,0
SLASH_NAME hr,'hr',3,0
SLASH_NAME outdent,'outdent',4,0
SLASH_NAME space,'space',5,0
SLASH_NAME page,'page',6,0
SLASH_NAME title,'title',7,SLASH_FLAG_CONTENT
SLASH_NAME subtitle,'subtitle',8,SLASH_FLAG_CONTENT
SLASH_NAME section,'section',9,SLASH_FLAG_CONTENT
SLASH_NAME subsection,'subsection',10,SLASH_FLAG_CONTENT
SLASH_NAME p,'p',11,SLASH_FLAG_CONTENT
SLASH_NAME quote,'quote',12,SLASH_FLAG_CONTENT
SLASH_NAME indent,'indent',13,SLASH_FLAG_CONTENT
SLASH_NAME ok,'ok',14,SLASH_FLAG_CONTENT
SLASH_NAME success,'success',15,SLASH_FLAG_CONTENT
SLASH_NAME warn,'warn',16,SLASH_FLAG_CONTENT
SLASH_NAME error,'error',17,SLASH_FLAG_CONTENT
SLASH_NAME fail,'fail',18,SLASH_FLAG_CONTENT
SLASH_NAME info,'info',19,SLASH_FLAG_CONTENT
SLASH_NAME debug,'debug',20,SLASH_FLAG_CONTENT
SLASH_NAME trace,'trace',21,SLASH_FLAG_CONTENT
SLASH_NAME todo,'todo',22,SLASH_FLAG_CONTENT
SLASH_NAME blocked,'blocked',23,SLASH_FLAG_CONTENT
SLASH_NAME green,'green',24,SLASH_FLAG_CONTENT
SLASH_NAME yellow,'yellow',25,SLASH_FLAG_CONTENT
SLASH_NAME red,'red',26,SLASH_FLAG_CONTENT
SLASH_NAME bold,'bold',27,SLASH_FLAG_CONTENT
SLASH_NAME italic,'italic',28,SLASH_FLAG_CONTENT
SLASH_NAME underline,'underline',29,SLASH_FLAG_CONTENT
SLASH_NAME dim,'dim',30,SLASH_FLAG_CONTENT
SLASH_NAME blink,'blink',31,SLASH_FLAG_CONTENT
SLASH_NAME code,'code',32,SLASH_FLAG_CONTENT
SLASH_NAME kbd,'kbd',33,SLASH_FLAG_CONTENT
SLASH_NAME mark,'mark',34,SLASH_FLAG_CONTENT
SLASH_NAME muted,'muted',35,SLASH_FLAG_CONTENT
SLASH_NAME strong,'strong',36,SLASH_FLAG_CONTENT
SLASH_NAME em,'em',37,SLASH_FLAG_CONTENT
SLASH_NAME blue,'blue',38,SLASH_FLAG_CONTENT
SLASH_NAME cyan,'cyan',39,SLASH_FLAG_CONTENT
SLASH_NAME magenta,'magenta',40,SLASH_FLAG_CONTENT
SLASH_NAME gray,'gray',41,SLASH_FLAG_CONTENT
SLASH_NAME color,'color',42,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_NAME bg,'bg',43,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_NAME list,'list',44,SLASH_FLAG_CONTENT
SLASH_NAME ol,'ol',45,SLASH_FLAG_CONTENT
SLASH_NAME ul,'ul',46,SLASH_FLAG_CONTENT
SLASH_NAME item,'item',47,SLASH_FLAG_CONTENT
SLASH_NAME check,'check',48,SLASH_FLAG_CONTENT
SLASH_NAME cross,'cross',49,SLASH_FLAG_CONTENT
SLASH_NAME task,'task',50,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_NAME table,'table',51,SLASH_FLAG_CONTENT
SLASH_NAME thead,'thead',52,SLASH_FLAG_CONTENT
SLASH_NAME row,'row',53,SLASH_FLAG_CONTENT
SLASH_NAME cell,'cell',54,SLASH_FLAG_CONTENT
SLASH_NAME col,'col',55,SLASH_FLAG_CONTENT
SLASH_NAME align,'align',56,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_NAME tree,'tree',57,SLASH_FLAG_CONTENT
SLASH_NAME node,'node',58,SLASH_FLAG_CONTENT
SLASH_NAME leaf,'leaf',59,SLASH_FLAG_CONTENT
SLASH_NAME branch,'branch',60,SLASH_FLAG_CONTENT
SLASH_NAME json,'json',61,SLASH_FLAG_CONTENT
SLASH_NAME yaml,'yaml',62,SLASH_FLAG_CONTENT
SLASH_NAME map,'map',63,SLASH_FLAG_CONTENT
SLASH_NAME object,'object',64,SLASH_FLAG_CONTENT
%undef SLASH_NAME

%macro SLASH_ROW 3
 dq slash_name_%1
 dd slash_name_%1_len,%3,%2,0
%endmacro
slash_registry:
SLASH_ROW br,1,0
SLASH_ROW line,2,0
SLASH_ROW hr,3,0
SLASH_ROW outdent,4,0
SLASH_ROW space,5,0
SLASH_ROW page,6,0
SLASH_ROW title,7,SLASH_FLAG_CONTENT
SLASH_ROW subtitle,8,SLASH_FLAG_CONTENT
SLASH_ROW section,9,SLASH_FLAG_CONTENT
SLASH_ROW subsection,10,SLASH_FLAG_CONTENT
SLASH_ROW p,11,SLASH_FLAG_CONTENT
SLASH_ROW quote,12,SLASH_FLAG_CONTENT
SLASH_ROW indent,13,SLASH_FLAG_CONTENT
SLASH_ROW ok,14,SLASH_FLAG_CONTENT
SLASH_ROW success,15,SLASH_FLAG_CONTENT
SLASH_ROW warn,16,SLASH_FLAG_CONTENT
SLASH_ROW error,17,SLASH_FLAG_CONTENT
SLASH_ROW fail,18,SLASH_FLAG_CONTENT
SLASH_ROW info,19,SLASH_FLAG_CONTENT
SLASH_ROW debug,20,SLASH_FLAG_CONTENT
SLASH_ROW trace,21,SLASH_FLAG_CONTENT
SLASH_ROW todo,22,SLASH_FLAG_CONTENT
SLASH_ROW blocked,23,SLASH_FLAG_CONTENT
SLASH_ROW green,24,SLASH_FLAG_CONTENT
SLASH_ROW yellow,25,SLASH_FLAG_CONTENT
SLASH_ROW red,26,SLASH_FLAG_CONTENT
SLASH_ROW bold,27,SLASH_FLAG_CONTENT
SLASH_ROW italic,28,SLASH_FLAG_CONTENT
SLASH_ROW underline,29,SLASH_FLAG_CONTENT
SLASH_ROW dim,30,SLASH_FLAG_CONTENT
SLASH_ROW blink,31,SLASH_FLAG_CONTENT
SLASH_ROW code,32,SLASH_FLAG_CONTENT
SLASH_ROW kbd,33,SLASH_FLAG_CONTENT
SLASH_ROW mark,34,SLASH_FLAG_CONTENT
SLASH_ROW muted,35,SLASH_FLAG_CONTENT
SLASH_ROW strong,36,SLASH_FLAG_CONTENT
SLASH_ROW em,37,SLASH_FLAG_CONTENT
SLASH_ROW blue,38,SLASH_FLAG_CONTENT
SLASH_ROW cyan,39,SLASH_FLAG_CONTENT
SLASH_ROW magenta,40,SLASH_FLAG_CONTENT
SLASH_ROW gray,41,SLASH_FLAG_CONTENT
SLASH_ROW color,42,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_ROW bg,43,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_ROW list,44,SLASH_FLAG_CONTENT
SLASH_ROW ol,45,SLASH_FLAG_CONTENT
SLASH_ROW ul,46,SLASH_FLAG_CONTENT
SLASH_ROW item,47,SLASH_FLAG_CONTENT
SLASH_ROW check,48,SLASH_FLAG_CONTENT
SLASH_ROW cross,49,SLASH_FLAG_CONTENT
SLASH_ROW task,50,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_ROW table,51,SLASH_FLAG_CONTENT
SLASH_ROW thead,52,SLASH_FLAG_CONTENT
SLASH_ROW row,53,SLASH_FLAG_CONTENT
SLASH_ROW cell,54,SLASH_FLAG_CONTENT
SLASH_ROW col,55,SLASH_FLAG_CONTENT
SLASH_ROW align,56,SLASH_FLAG_CONTENT|SLASH_FLAG_ARGUMENT
SLASH_ROW tree,57,SLASH_FLAG_CONTENT
SLASH_ROW node,58,SLASH_FLAG_CONTENT
SLASH_ROW leaf,59,SLASH_FLAG_CONTENT
SLASH_ROW branch,60,SLASH_FLAG_CONTENT
SLASH_ROW json,61,SLASH_FLAG_CONTENT
SLASH_ROW yaml,62,SLASH_FLAG_CONTENT
SLASH_ROW map,63,SLASH_FLAG_CONTENT
SLASH_ROW object,64,SLASH_FLAG_CONTENT
%undef SLASH_ROW
slash_registry_count equ 64

slash_arg_done: db 'done'
slash_arg_done_len equ $-slash_arg_done
slash_arg_open: db 'open'
slash_arg_open_len equ $-slash_arg_open
slash_arg_left: db 'left'
slash_arg_left_len equ $-slash_arg_left
slash_html_open: db '<span data-slash="'
slash_html_open_len equ $-slash_html_open
slash_html_mid: db '">'
slash_html_mid_len equ $-slash_html_mid
slash_html_arg_mid: db '" data-slash-arg="'
slash_html_arg_mid_len equ $-slash_html_arg_mid
slash_html_close: db '</span>'
slash_html_close_len equ $-slash_html_close
slash_html_doc_open: db '<div class="slash">'
slash_html_doc_open_len equ $-slash_html_doc_open
slash_html_doc_close: db '</div>'
slash_html_doc_close_len equ $-slash_html_doc_close
slash_ansi_reset: db 27,'[0m'
slash_ansi_reset_len equ $-slash_ansi_reset
slash_ansi_open: db 27,'[1m'
slash_ansi_open_len equ $-slash_ansi_open
slash_ansi_italic: db 27,'[3m'
slash_ansi_italic_len equ $-slash_ansi_italic
slash_ansi_underline: db 27,'[4m'
slash_ansi_underline_len equ $-slash_ansi_underline
slash_ansi_dim: db 27,'[2m'
slash_ansi_dim_len equ $-slash_ansi_dim
slash_ansi_blink: db 27,'[5m'
slash_ansi_blink_len equ $-slash_ansi_blink
slash_ansi_reverse: db 27,'[7m'
slash_ansi_reverse_len equ $-slash_ansi_reverse
slash_ansi_blue: db 27,'[34m'
slash_ansi_blue_len equ $-slash_ansi_blue
slash_ansi_cyan: db 27,'[36m'
slash_ansi_cyan_len equ $-slash_ansi_cyan
slash_ansi_magenta: db 27,'[35m'
slash_ansi_magenta_len equ $-slash_ansi_magenta
slash_ansi_gray: db 27,'[90m'
slash_ansi_gray_len equ $-slash_ansi_gray
slash_ansi_bg_blue: db 27,'[44m'
slash_ansi_bg_blue_len equ $-slash_ansi_bg_blue
slash_hr: db '---',10
slash_hr_len equ $-slash_hr
slash_label_open: db '['
slash_label_close: db '] '

section .text
global neboc_slash_parse
global neboc_slash_validate
global neboc_slash_render
global neboc_slash_render_plain
global neboc_slash_render_ansi
global neboc_slash_render_markdown
global neboc_slash_render_html
global neboc_slash_render_console

; RDI name, RSI length -> EAX id (0 unknown), EDX flags.
slash_lookup:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 lea rbx,[rel slash_registry]
 mov ecx,slash_registry_count
.row:
 cmp r13d,[rbx+8]
 jne .next
 mov rdi,r12
 mov rsi,[rbx]
 mov r8,r13
.compare:
 test r8,r8
 jz .found
 mov al,[rdi]
 cmp al,[rsi]
 jne .next
 inc rdi
 inc rsi
 dec r8
 jmp .compare
.found:
 mov edx,[rbx+12]
 mov eax,[rbx+16]
 jmp .done
.next:
 add rbx,SLASH_REGISTRY_ENTRY_SIZE
 dec ecx
 jnz .row
 xor eax,eax
 xor edx,edx
.done:
 pop r13
 pop r12
 pop rbx
 ret

; RDI argument, RSI length, EDX directive id -> EAX boolean.
slash_argument_valid:
 cmp edx,50
 je .task
 cmp edx,56
 je .align
 ; color/bg names are bounded ASCII identifiers.
 test rsi,rsi
 jz .no
 cmp rsi,SLASH_MAX_ARGUMENT
 ja .no
 xor ecx,ecx
.ident:
 mov al,[rdi+rcx]
 cmp al,'A'
 jb .lower
 cmp al,'Z'
 jbe .ident_next
.lower:
 cmp al,'a'
 jb .digit
 cmp al,'z'
 jbe .ident_next
.digit:
 cmp al,'0'
 jb .dash
 cmp al,'9'
 jbe .ident_next
.dash:
 cmp al,'-'
 jne .no
.ident_next:
 inc rcx
 cmp rcx,rsi
 jb .ident
 mov eax,1
 ret
.task:
 lea r8,[rel slash_arg_done]
 mov r9d,slash_arg_done_len
 call .equals
 test eax,eax
 jnz .yes
 lea r8,[rel slash_arg_open]
 mov r9d,slash_arg_open_len
 jmp .equals
.align:
 lea r8,[rel slash_arg_left]
 mov r9d,slash_arg_left_len
.equals:
 cmp rsi,r9
 jne .no
 xor ecx,ecx
.eq_loop:
 cmp rcx,rsi
 je .yes
 mov al,[rdi+rcx]
 cmp al,[r8+rcx]
 jne .no
 inc rcx
 jmp .eq_loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; RDI source, RSI bytes, RDX SlashParse*, RCX SlashError* -> EAX status.
neboc_slash_parse:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r15,rdx
 mov [rbp-48],rcx
 mov qword [rbp-56],0       ; max depth
 mov qword [rbp-64],0       ; tokens
 mov qword [rbp-72],0       ; directives
 mov qword [rbp-80],0       ; escapes
 mov qword [rbp-88],0       ; first id
 mov dword [rbp-104],0      ; content token observed
 test r15,r15
 jz .invalid
 mov qword [r15+SLASH_PARSE_TOKENS],0
 mov qword [r15+SLASH_PARSE_DIRECTIVES],0
 mov qword [r15+SLASH_PARSE_MAX_DEPTH],0
 mov qword [r15+SLASH_PARSE_ESCAPES],0
 mov qword [r15+SLASH_PARSE_FIRST_ID],0
 mov rax,[rbp-48]
 test rax,rax
 jz .input
 mov qword [rax+SLASH_ERROR_CODE],0
 mov qword [rax+SLASH_ERROR_START],0
 mov qword [rax+SLASH_ERROR_END],0
.input:
 test r13,r13
 jz .syntax
 test r12,r12
 jz .invalid
 cmp r13,SLASH_MAX_INPUT
 ja .limit
 xor ebx,ebx
 xor r14d,r14d
.scan:
 cmp rbx,r13
 jae .finish
 mov al,[r12+rbx]
 cmp al,'/'
 je .slash
 cmp al,'}'
 je .close
 cmp al,'{'
 je .syntax
 cmp dword [rbp-104],0
 jne .content_byte
 mov dword [rbp-104],1
 inc qword [rbp-64]
 cmp qword [rbp-64],SLASH_MAX_TOKENS
 ja .limit
.content_byte:
 inc rbx
 jmp .scan
.slash:
 lea rax,[rbx+1]
 cmp rax,r13
 jae .syntax
 cmp byte [r12+rbx+1],'/'
 jne .directive
 add rbx,2
 inc qword [rbp-80]
 inc qword [rbp-64]
 cmp qword [rbp-64],SLASH_MAX_TOKENS
 ja .limit
 jmp .scan
.directive:
 lea r10,[rbx+1]
 mov r11,r10
.name:
 cmp r11,r13
 jae .name_done
 mov al,[r12+r11]
 cmp al,'A'
 jb .name_lower
 cmp al,'Z'
 jbe .name_next
.name_lower:
 cmp al,'a'
 jb .name_done
 cmp al,'z'
 ja .name_done
.name_next:
 inc r11
 jmp .name
.name_done:
 cmp r11,r10
 je .syntax
 lea rdi,[r12+r10]
 mov rsi,r11
 sub rsi,r10
 call slash_lookup
 test eax,eax
 jz .unknown
 mov [rbp-96],eax
 mov [rbp-100],edx
 inc qword [rbp-72]
 inc qword [rbp-64]
 cmp qword [rbp-64],SLASH_MAX_TOKENS
 ja .limit
 cmp qword [rbp-88],0
 jne .argument
 mov [rbp-88],rax
.argument:
 mov rbx,r11
 test edx,SLASH_FLAG_ARGUMENT
 jz .no_argument
 cmp rbx,r13
 jae .syntax
 cmp byte [r12+rbx],'('
 jne .syntax
 lea r10,[rbx+1]
 mov r11,r10
.arg_scan:
 cmp r11,r13
 jae .syntax
 cmp byte [r12+r11],')'
 je .arg_done
 inc r11
 mov rax,r11
 sub rax,r10
 cmp rax,SLASH_MAX_ARGUMENT
 ja .limit
 jmp .arg_scan
.arg_done:
 lea rdi,[r12+r10]
 mov rsi,r11
 sub rsi,r10
 mov edx,[rbp-96]
 call slash_argument_valid
 test eax,eax
 jz .syntax
 lea rbx,[r11+1]
 jmp .content
.no_argument:
 cmp rbx,r13
 jae .content
 cmp byte [r12+rbx],'('
 je .syntax
.content:
 mov edx,[rbp-100]
 test edx,SLASH_FLAG_CONTENT
 jz .without_content
 cmp rbx,r13
 jae .syntax
 cmp byte [r12+rbx],'{'
 jne .syntax
 inc r14
 cmp r14,SLASH_MAX_DEPTH
 ja .limit
 cmp r14,[rbp-56]
 jbe .content_ok
 mov [rbp-56],r14
.content_ok:
 inc rbx
 jmp .scan
.without_content:
 cmp rbx,r13
 jae .scan
 cmp byte [r12+rbx],'{'
 je .syntax
 jmp .scan
.close:
 test r14,r14
 jz .syntax
 dec r14
 inc rbx
 jmp .scan
.finish:
 test r14,r14
 jnz .syntax
 mov rax,[rbp-64]
 mov [r15+SLASH_PARSE_TOKENS],rax
 mov rax,[rbp-72]
 mov [r15+SLASH_PARSE_DIRECTIVES],rax
 mov rax,[rbp-56]
 mov [r15+SLASH_PARSE_MAX_DEPTH],rax
 mov rax,[rbp-80]
 mov [r15+SLASH_PARSE_ESCAPES],rax
 mov rax,[rbp-88]
 mov [r15+SLASH_PARSE_FIRST_ID],rax
 xor eax,eax
 jmp .done
.invalid:
 mov eax,SLASH_E_INVALID
 jmp .error
.limit:
 mov eax,SLASH_E_LIMIT
 jmp .error
.syntax:
 mov eax,SLASH_E_SYNTAX
 jmp .error
.unknown:
 mov eax,SLASH_E_UNKNOWN
.error:
 mov rcx,[rbp-48]
 test rcx,rcx
 jz .done
 mov [rcx+SLASH_ERROR_CODE],rax
 mov [rcx+SLASH_ERROR_START],rbx
 lea rdx,[rbx+1]
 cmp rdx,r13
 cmova rdx,r13
 mov [rcx+SLASH_ERROR_END],rdx
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 leave
 ret

neboc_slash_validate:
 push rbp
 mov rbp,rsp
 sub rsp,SLASH_PARSE_SIZE+8
 lea rdx,[rsp]
 xor ecx,ecx
 call neboc_slash_parse
 leave
 ret

; Internal renderer pass. R9D=0 measure, 1 write. Input is prevalidated.
; Returns byte count. The stack holds a 16-entry directive nesting stack.
slash_render_pass:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,240
 mov r12,rdi
 mov r13,rsi
 mov [rbp-48],rcx            ; output
 mov [rbp-56],r8             ; capacity
 mov [rbp-64],r9             ; write flag
 mov [rbp-72],rdx            ; target
 mov qword [rbp-80],0        ; nesting stack depth
 xor ebx,ebx
 xor r14d,r14d
 cmp edx,SLASH_TARGET_ANSI
 jne .prefix_html
 lea rdi,[rel slash_ansi_reset]
 mov esi,slash_ansi_reset_len
 call .emit_seq
 jmp .scan
.prefix_html:
 cmp edx,SLASH_TARGET_HTML
 jne .scan
 lea rdi,[rel slash_html_doc_open]
 mov esi,slash_html_doc_open_len
 call .emit_seq
.scan:
 cmp rbx,r13
 jae .suffix
 mov al,[r12+rbx]
 cmp al,'/'
 je .slash
 cmp al,'}'
 je .close
 cmp al,'{'
 je .skip
 cmp qword [rbp-72],SLASH_TARGET_HTML
 jne .ordinary
 cmp al,'&'
 je .amp
 cmp al,'<'
 je .lt
 cmp al,'>'
 je .gt
.ordinary:
 mov dil,al
 call .emit_byte
.skip:
 inc rbx
 jmp .scan
.amp:
 lea rdi,[rel .amp_text]
 mov esi,5
 call .emit_seq
 inc rbx
 jmp .scan
.lt:
 lea rdi,[rel .lt_text]
 mov esi,4
 call .emit_seq
 inc rbx
 jmp .scan
.gt:
 lea rdi,[rel .gt_text]
 mov esi,4
 call .emit_seq
 inc rbx
 jmp .scan
.slash:
 cmp byte [r12+rbx+1],'/'
 jne .directive
 mov edi,'/'
 call .emit_byte
 add rbx,2
 jmp .scan
.directive:
 lea r10,[rbx+1]
 mov r11,r10
.name:
 cmp r11,r13
 jae .name_done
 mov al,[r12+r11]
 cmp al,'A'
 jb .name_lower
 cmp al,'Z'
 jbe .name_next
.name_lower:
 cmp al,'a'
 jb .name_done
 cmp al,'z'
 ja .name_done
.name_next:
 inc r11
 jmp .name
.name_done:
 lea rdi,[r12+r10]
 mov rsi,r11
 sub rsi,r10
 mov [rbp-88],rdi
 mov [rbp-96],rsi
 call slash_lookup
 mov [rbp-104],rax
 mov [rbp-112],rdx
 mov qword [rbp-248],0       ; argument pointer
 mov qword [rbp-256],0       ; argument bytes
 mov rbx,r11
 test edx,SLASH_FLAG_ARGUMENT
 jz .open
 inc rbx
 lea rax,[r12+rbx]
 mov [rbp-248],rax
.arg_skip:
 cmp byte [r12+rbx],')'
 je .arg_end
 inc rbx
 jmp .arg_skip
.arg_end:
 lea rax,[r12+rbx]
 sub rax,[rbp-248]
 mov [rbp-256],rax
 inc rbx
.open:
 mov eax,[rbp-104]
 mov edx,[rbp-112]
 test edx,SLASH_FLAG_CONTENT
 jz .control
 mov rcx,[rbp-80]
 mov r9,rcx
 shl r9,3
 lea r8,[rbp-120]
 sub r8,r9
 mov [r8],rax
 inc rcx
 mov [rbp-80],rcx
 mov rcx,[rbp-72]
 cmp ecx,SLASH_TARGET_HTML
 je .span_open
 cmp ecx,SLASH_TARGET_MARKDOWN
 je .span_open
 cmp ecx,SLASH_TARGET_ANSI
 je .ansi_open
 jmp .semantic_label
.semantic_label:
 mov eax,[rbp-104]
 cmp eax,14
 jb .plain_list
 cmp eax,26
 jbe .label
.plain_list:
 cmp eax,47
 jb .open_done
 cmp eax,50
 jbe .label
 jmp .open_done
.label:
 lea rdi,[rel slash_label_open]
 mov esi,1
 call .emit_seq
 mov rdi,[rbp-88]
 mov rsi,[rbp-96]
 call .emit_seq
 mov eax,[rbp-104]
 cmp eax,50
 jne .label_close
 mov edi,'('
 call .emit_byte
 mov rdi,[rbp-248]
 mov rsi,[rbp-256]
 call .emit_seq
 mov edi,')'
 call .emit_byte
.label_close:
 lea rdi,[rel slash_label_close]
 mov esi,2
 call .emit_seq
 jmp .open_done
.ansi_open:
 mov eax,[rbp-104]
 cmp eax,14
 jb .ansi_style
 cmp eax,26
 jbe .ansi_bold
.ansi_style:
 cmp eax,27
 je .ansi_bold
 cmp eax,28
 je .ansi_italic_emit
 cmp eax,29
 je .ansi_underline_emit
 cmp eax,30
 je .ansi_dim_emit
 cmp eax,31
 je .ansi_blink_emit
 cmp eax,32
 je .ansi_reverse_emit
 cmp eax,33
 je .ansi_reverse_emit
 cmp eax,34
 je .ansi_reverse_emit
 cmp eax,35
 je .ansi_dim_emit
 cmp eax,36
 je .ansi_bold
 cmp eax,37
 je .ansi_italic_emit
 cmp eax,38
 je .ansi_blue_emit
 cmp eax,39
 je .ansi_cyan_emit
 cmp eax,40
 je .ansi_magenta_emit
 cmp eax,41
 je .ansi_gray_emit
 cmp eax,42
 je .ansi_cyan_emit
 cmp eax,43
 je .ansi_bg_blue_emit
 jmp .semantic_label
.ansi_bold:
 lea rdi,[rel slash_ansi_open]
 mov esi,slash_ansi_open_len
 jmp .ansi_emit
.ansi_italic_emit:
 lea rdi,[rel slash_ansi_italic]
 mov esi,slash_ansi_italic_len
 jmp .ansi_emit
.ansi_underline_emit:
 lea rdi,[rel slash_ansi_underline]
 mov esi,slash_ansi_underline_len
 jmp .ansi_emit
.ansi_dim_emit:
 lea rdi,[rel slash_ansi_dim]
 mov esi,slash_ansi_dim_len
 jmp .ansi_emit
.ansi_blink_emit:
 lea rdi,[rel slash_ansi_blink]
 mov esi,slash_ansi_blink_len
 jmp .ansi_emit
.ansi_reverse_emit:
 lea rdi,[rel slash_ansi_reverse]
 mov esi,slash_ansi_reverse_len
 jmp .ansi_emit
.ansi_blue_emit:
 lea rdi,[rel slash_ansi_blue]
 mov esi,slash_ansi_blue_len
 jmp .ansi_emit
.ansi_cyan_emit:
 lea rdi,[rel slash_ansi_cyan]
 mov esi,slash_ansi_cyan_len
 jmp .ansi_emit
.ansi_magenta_emit:
 lea rdi,[rel slash_ansi_magenta]
 mov esi,slash_ansi_magenta_len
 jmp .ansi_emit
.ansi_gray_emit:
 lea rdi,[rel slash_ansi_gray]
 mov esi,slash_ansi_gray_len
 jmp .ansi_emit
.ansi_bg_blue_emit:
 lea rdi,[rel slash_ansi_bg_blue]
 mov esi,slash_ansi_bg_blue_len
.ansi_emit:
 call .emit_seq
 jmp .semantic_label
.span_open:
 lea rdi,[rel slash_html_open]
 mov esi,slash_html_open_len
 call .emit_seq
 mov rdi,[rbp-88]
 mov rsi,[rbp-96]
 call .emit_seq
 cmp qword [rbp-248],0
 je .span_finish
 lea rdi,[rel slash_html_arg_mid]
 mov esi,slash_html_arg_mid_len
 call .emit_seq
 mov rdi,[rbp-248]
 mov rsi,[rbp-256]
 call .emit_seq
.span_finish:
 lea rdi,[rel slash_html_mid]
 mov esi,slash_html_mid_len
 call .emit_seq
 jmp .semantic_label
.open_done:
 inc rbx                       ; consume opening brace
 jmp .scan
.control:
 cmp eax,1
 je .newline
 cmp eax,2
 je .newline
 cmp eax,3
 je .horizontal
 cmp eax,5
 je .space
 cmp eax,6
 je .page
 jmp .scan
.newline:
 mov edi,10
 call .emit_byte
 jmp .scan
.horizontal:
 lea rdi,[rel slash_hr]
 mov esi,slash_hr_len
 call .emit_seq
 jmp .scan
.space:
 mov edi,' '
 call .emit_byte
 jmp .scan
.page:
 mov edi,12
 call .emit_byte
 jmp .scan
.close:
 mov rcx,[rbp-80]
 dec rcx
 mov [rbp-80],rcx
 mov r9,rcx
 shl r9,3
 lea r8,[rbp-120]
 sub r8,r9
 mov eax,[r8]
 mov edx,[rbp-72]
 cmp edx,SLASH_TARGET_HTML
 je .span_close
 cmp edx,SLASH_TARGET_MARKDOWN
 je .span_close
 cmp edx,SLASH_TARGET_ANSI
 jne .close_done
 cmp eax,14
 jb .ansi_close_style
 cmp eax,43
 jbe .ansi_close
.ansi_close_style:
 cmp eax,27
 jb .close_done
 cmp eax,43
 ja .close_done
.ansi_close:
 lea rdi,[rel slash_ansi_reset]
 mov esi,slash_ansi_reset_len
 call .emit_seq
 jmp .close_done
.span_close:
 lea rdi,[rel slash_html_close]
 mov esi,slash_html_close_len
 call .emit_seq
.close_done:
 inc rbx
 jmp .scan
.suffix:
 cmp qword [rbp-72],SLASH_TARGET_ANSI
 jne .suffix_html
 lea rdi,[rel slash_ansi_reset]
 mov esi,slash_ansi_reset_len
 call .emit_seq
 jmp .pass_done
.suffix_html:
 cmp qword [rbp-72],SLASH_TARGET_HTML
 jne .pass_done
 lea rdi,[rel slash_html_doc_close]
 mov esi,slash_html_doc_close_len
 call .emit_seq
.pass_done:
 mov rax,r14
 add rsp,240
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 leave
 ret

.emit_byte:
 cmp qword [rbp-64],0
 je .byte_count
 mov rax,[rbp-48]
 mov [rax+r14],dil
.byte_count:
 inc r14
 ret
.emit_seq:
 test rsi,rsi
 jz .seq_done
 cmp qword [rbp-64],0
 je .seq_count
 mov rax,[rbp-48]
 lea rax,[rax+r14]
 xor ecx,ecx
.seq_copy:
 mov dl,[rdi+rcx]
 mov [rax+rcx],dl
 inc rcx
 cmp rcx,rsi
 jb .seq_copy
.seq_count:
 add r14,rsi
.seq_done:
 ret
section .rodata
.amp_text: db '&amp;'
.lt_text: db '&lt;'
.gt_text: db '&gt;'
section .text

; RDI source, RSI bytes, EDX target, RCX output, R8 capacity.
; RAX committed bytes or negative typed error. No byte is written on failure.
neboc_slash_render:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,SLASH_PARSE_SIZE+SLASH_ERROR_SIZE+16
 mov r12,rdi
 mov r13,rsi
 mov r14d,edx
 mov r15,rcx
 mov rbx,r8
 cmp r14d,SLASH_TARGET_PLAIN
 jb .target
 cmp r14d,SLASH_TARGET_CONSOLE
 ja .target
 lea rdx,[rsp]
 lea rcx,[rsp+SLASH_PARSE_SIZE]
 call neboc_slash_parse
 test eax,eax
 jnz .negative
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call slash_render_pass
 cmp rax,rbx
 ja .capacity
 test rax,rax
 jz .write
 test r15,r15
 jz .invalid
.write:
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 mov rcx,r15
 mov r8,rbx
 mov r9d,1
 call slash_render_pass
 jmp .done
.negative:
 neg eax
 cdqe
 jmp .done
.target:
 mov rax,-SLASH_E_TARGET
 jmp .done
.capacity:
 mov rax,-SLASH_E_CAPACITY
 jmp .done
.invalid:
 mov rax,-SLASH_E_INVALID
.done:
 add rsp,SLASH_PARSE_SIZE+SLASH_ERROR_SIZE+16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 leave
 ret

neboc_slash_render_plain:
 mov r8,rcx
 mov rcx,rdx
 mov edx,SLASH_TARGET_PLAIN
 jmp neboc_slash_render
neboc_slash_render_ansi:
 mov r8,rcx
 mov rcx,rdx
 mov edx,SLASH_TARGET_ANSI
 jmp neboc_slash_render
neboc_slash_render_markdown:
 mov r8,rcx
 mov rcx,rdx
 mov edx,SLASH_TARGET_MARKDOWN
 jmp neboc_slash_render
neboc_slash_render_html:
 mov r8,rcx
 mov rcx,rdx
 mov edx,SLASH_TARGET_HTML
 jmp neboc_slash_render
neboc_slash_render_console:
 mov r8,rcx
 mov rcx,rdx
 mov edx,SLASH_TARGET_CONSOLE
 jmp neboc_slash_render

section .note.GNU-stack noalloc noexec nowrite progbits
