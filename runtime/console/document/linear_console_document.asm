; CONTROLO-DE-FLUXO-ESTRUTURADO-F02 bounded canonical Console document profile.
bits 64
default rel
%define NEBO_CONSOLE_DOCUMENT_IMPLEMENTATION 1
%include "runtime/console/document/linear_console_document.inc"
section .text
global nebo_console_init
global nebo_console_set_title
global nebo_console_set_style
global nebo_console_append
global nebo_console_append_line
global nebo_console_clear
global nebo_console_scroll
global nebo_console_size_query
global nebo_console_close

; doc,text,capacity,title,title_capacity
; Initialization is failure-atomic: no descriptor field changes until all
; caller-owned storage bindings and bounded capacities have been accepted.
nebo_console_init:
 test rdi,rdi
 jz console_argument_error
 test rsi,rsi
 jz console_argument_error
 test rdx,rdx
 jz console_limit_error
 cmp rdx,NEBO_CONSOLE_MAX_TEXT
 ja console_limit_error
 test rcx,rcx
 jz console_argument_error
 test r8,r8
 jz console_limit_error
 cmp r8,NEBO_CONSOLE_MAX_TITLE
 ja console_limit_error
 mov qword [rdi+NEBO_CONSOLE_STATE],NEBO_CONSOLE_STATE_OPEN
 mov [rdi+NEBO_CONSOLE_TEXT],rsi
 mov [rdi+NEBO_CONSOLE_CAPACITY],rdx
 mov qword [rdi+NEBO_CONSOLE_LENGTH],0
 mov qword [rdi+NEBO_CONSOLE_LINES],1
 mov [rdi+NEBO_CONSOLE_TITLE],rcx
 mov [rdi+NEBO_CONSOLE_TITLE_CAPACITY],r8
 mov qword [rdi+NEBO_CONSOLE_TITLE_LENGTH],0
 mov qword [rdi+NEBO_CONSOLE_STYLE],0
 mov qword [rdi+NEBO_CONSOLE_SCROLL],0
 mov qword [rdi+NEBO_CONSOLE_REVISION],1
 xor eax,eax
 ret

; doc,title,length
nebo_console_set_title:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .ret
 sub rsp,8
 call console_require_mutation_room
 add rsp,8
 test eax,eax
 jnz .ret
 test rsi,rsi
 jz console_argument_error
 cmp rdx,[rdi+NEBO_CONSOLE_TITLE_CAPACITY]
 ja console_limit_error
 mov rcx,[rdi+NEBO_CONSOLE_TITLE]
 xor r8d,r8d
.copy:
 cmp r8,rdx
 jae .done
 mov al,[rsi+r8]
 mov [rcx+r8],al
 inc r8
 jmp .copy
.done:
 mov [rdi+NEBO_CONSOLE_TITLE_LENGTH],rdx
 inc qword [rdi+NEBO_CONSOLE_REVISION]
 xor eax,eax
.ret:
 ret

; doc,style 0..15
nebo_console_set_style:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .ret
 sub rsp,8
 call console_require_mutation_room
 add rsp,8
 test eax,eax
 jnz .ret
 cmp rsi,15
 ja console_style_error
 mov [rdi+NEBO_CONSOLE_STYLE],rsi
 inc qword [rdi+NEBO_CONSOLE_REVISION]
 xor eax,eax
.ret:
 ret

; doc,bytes,length
nebo_console_append:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .ret
 test rdx,rdx
 jz .ok
 sub rsp,8
 call console_require_mutation_room
 add rsp,8
 test eax,eax
 jnz .ret
 test rsi,rsi
 jz console_argument_error
 mov r8,[rdi+NEBO_CONSOLE_LENGTH]
 mov r9,[rdi+NEBO_CONSOLE_CAPACITY]
 sub r9,r8
 cmp rdx,r9
 ja console_limit_error
 lea r9,[r8+rdx]
 mov r10,[rdi+NEBO_CONSOLE_LINES]
 xor ecx,ecx
.count:
 cmp rcx,rdx
 jae .counted
 cmp byte [rsi+rcx],10
 jne .next
 inc r10
 cmp r10,NEBO_CONSOLE_MAX_LINES
 ja console_limit_error
.next:
 inc rcx
 jmp .count
.counted:
 mov r11,[rdi+NEBO_CONSOLE_TEXT]
 xor ecx,ecx
.copy:
 cmp rcx,rdx
 jae .commit
 mov al,[rsi+rcx]
 mov [r11+r8],al
 inc r8
 inc rcx
 jmp .copy
.commit:
 mov [rdi+NEBO_CONSOLE_LENGTH],r9
 mov [rdi+NEBO_CONSOLE_LINES],r10
 inc qword [rdi+NEBO_CONSOLE_REVISION]
.ok:
 xor eax,eax
.ret:
 ret

; doc,bytes,length; newline is committed atomically with the payload.
nebo_console_append_line:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .ret
 sub rsp,8
 call console_require_mutation_room
 add rsp,8
 test eax,eax
 jnz .ret
 test rdx,rdx
 jz .preflight
 test rsi,rsi
 jz console_argument_error
.preflight:
 mov r8,[rdi+NEBO_CONSOLE_LENGTH]
 mov r9,[rdi+NEBO_CONSOLE_CAPACITY]
 sub r9,r8
 test r9,r9
 jz console_limit_error
 dec r9
 cmp rdx,r9
 ja console_limit_error
 lea r9,[r8+rdx+1]
 mov r10,[rdi+NEBO_CONSOLE_LINES]
 cmp r10,NEBO_CONSOLE_MAX_LINES
 jae console_limit_error
 inc r10
 xor ecx,ecx
.count:
 cmp rcx,rdx
 jae .counted
 cmp byte [rsi+rcx],10
 jne .next
 inc r10
 cmp r10,NEBO_CONSOLE_MAX_LINES
 ja console_limit_error
.next:
 inc rcx
 jmp .count
.counted:
 mov r11,[rdi+NEBO_CONSOLE_TEXT]
 xor ecx,ecx
.copy:
 cmp rcx,rdx
 jae .newline
 mov al,[rsi+rcx]
 mov [r11+r8],al
 inc r8
 inc rcx
 jmp .copy
.newline:
 mov byte [r11+r8],10
 mov [rdi+NEBO_CONSOLE_LENGTH],r9
 mov [rdi+NEBO_CONSOLE_LINES],r10
 inc qword [rdi+NEBO_CONSOLE_REVISION]
 xor eax,eax
.ret:
 ret

nebo_console_clear:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .ret
 sub rsp,8
 call console_require_mutation_room
 add rsp,8
 test eax,eax
 jnz .ret
 mov qword [rdi+NEBO_CONSOLE_LENGTH],0
 mov qword [rdi+NEBO_CONSOLE_LINES],1
 mov qword [rdi+NEBO_CONSOLE_SCROLL],0
 inc qword [rdi+NEBO_CONSOLE_REVISION]
 xor eax,eax
.ret:
 ret

; doc,signed delta, saturating 0..lines-1 without signed wraparound.
nebo_console_scroll:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .ret
 sub rsp,8
 call console_require_mutation_room
 add rsp,8
 test eax,eax
 jnz .ret
 mov rax,[rdi+NEBO_CONSOLE_SCROLL]
 mov rdx,[rdi+NEBO_CONSOLE_LINES]
 dec rdx
 test rsi,rsi
 js .negative
 mov rcx,rdx
 sub rcx,rax
 cmp rsi,rcx
 ja .to_max
 add rax,rsi
 jmp .commit
.to_max:
 mov rax,rdx
 jmp .commit
.negative:
 mov rcx,rax
 neg rcx
 cmp rsi,rcx
 jl .to_zero
 add rax,rsi
 jmp .commit
.to_zero:
 xor eax,eax
.commit:
 mov [rdi+NEBO_CONSOLE_SCROLL],rax
 inc qword [rdi+NEBO_CONSOLE_REVISION]
 xor eax,eax
.ret:
 ret

; doc -> length rdx, lines rcx, style r8, scroll r9
nebo_console_size_query:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .fail
 mov rdx,[rdi+NEBO_CONSOLE_LENGTH]
 mov rcx,[rdi+NEBO_CONSOLE_LINES]
 mov r8,[rdi+NEBO_CONSOLE_STYLE]
 mov r9,[rdi+NEBO_CONSOLE_SCROLL]
 xor eax,eax
 ret
.fail:
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 ret

nebo_console_close:
 sub rsp,8
 call console_require_open
 add rsp,8
 test eax,eax
 jnz .ret
 sub rsp,8
 call console_require_mutation_room
 add rsp,8
 test eax,eax
 jnz .ret
 mov qword [rdi+NEBO_CONSOLE_STATE],NEBO_CONSOLE_STATE_CLOSED
 inc qword [rdi+NEBO_CONSOLE_REVISION]
 xor eax,eax
.ret:
 ret

; Validate all descriptor invariants that are representable without probing
; caller memory.  This prevents corrupted lengths/counters from turning a
; bounded operation into pointer arithmetic outside the frozen profile.
console_require_open:
 test rdi,rdi
 jz console_argument_error
 cmp qword [rdi+NEBO_CONSOLE_STATE],NEBO_CONSOLE_STATE_OPEN
 jne console_state_error
 mov r10,[rdi+NEBO_CONSOLE_TEXT]
 test r10,r10
 jz console_state_error
 mov r10,[rdi+NEBO_CONSOLE_CAPACITY]
 test r10,r10
 jz console_state_error
 cmp r10,NEBO_CONSOLE_MAX_TEXT
 ja console_state_error
 mov r11,[rdi+NEBO_CONSOLE_LENGTH]
 cmp r11,r10
 ja console_state_error
 mov r10,[rdi+NEBO_CONSOLE_LINES]
 test r10,r10
 jz console_state_error
 cmp r10,NEBO_CONSOLE_MAX_LINES
 ja console_state_error
 mov r11,[rdi+NEBO_CONSOLE_TITLE]
 test r11,r11
 jz console_state_error
 mov r10,[rdi+NEBO_CONSOLE_TITLE_CAPACITY]
 test r10,r10
 jz console_state_error
 cmp r10,NEBO_CONSOLE_MAX_TITLE
 ja console_state_error
 mov r11,[rdi+NEBO_CONSOLE_TITLE_LENGTH]
 cmp r11,r10
 ja console_state_error
 cmp qword [rdi+NEBO_CONSOLE_STYLE],15
 ja console_state_error
 mov r11,[rdi+NEBO_CONSOLE_SCROLL]
 mov r10,[rdi+NEBO_CONSOLE_LINES]
 cmp r11,r10
 jae console_state_error
 cmp qword [rdi+NEBO_CONSOLE_REVISION],0
 je console_state_error
 xor eax,eax
 ret

console_require_mutation_room:
 cmp qword [rdi+NEBO_CONSOLE_REVISION],-1
 je console_limit_error
 xor eax,eax
 ret

console_argument_error:
 mov eax,NEBO_CONSOLE_ERROR_ARGUMENT
 ret
console_state_error:
 mov eax,NEBO_CONSOLE_ERROR_STATE
 ret
console_limit_error:
 mov eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 ret
console_style_error:
 mov eax,NEBO_CONSOLE_ERROR_STYLE
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
