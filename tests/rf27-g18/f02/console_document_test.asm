bits 64
default rel
%include "runtime/console/document/linear_console_document.inc"
section .data
hello db 'hello'
title db 'Nebo'
with_newline db 'a',10,'b'
newline db 10
expected_text db 'hello','a',10,'b',10
section .bss
doc resb NEBO_CONSOLE_SIZE
text resb 4096
title_store resb 256
section .text
global _start
_start:
 ; Invalid initialization must not mutate the caller descriptor.
 mov rbx,0x1122334455667788
 mov [doc+NEBO_CONSOLE_STATE],rbx
 lea rdi,[doc]
 lea rsi,[text]
 mov edx,NEBO_CONSOLE_MAX_TEXT+1
 lea rcx,[title_store]
 mov r8d,NEBO_CONSOLE_MAX_TITLE
 call nebo_console_init
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail1
 cmp [doc+NEBO_CONSOLE_STATE],rbx
 jne .fail2
 lea rdi,[doc]
 lea rsi,[text]
 mov edx,NEBO_CONSOLE_MAX_TEXT
 lea rcx,[title_store]
 mov r8d,NEBO_CONSOLE_MAX_TITLE+1
 call nebo_console_init
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail3
 cmp [doc+NEBO_CONSOLE_STATE],rbx
 jne .fail4

 ; Canonical bounded initialization.
 lea rdi,[doc]
 lea rsi,[text]
 mov edx,NEBO_CONSOLE_MAX_TEXT
 lea rcx,[title_store]
 mov r8d,NEBO_CONSOLE_MAX_TITLE
 call nebo_console_init
 test eax,eax
 jnz .fail5
 cmp qword [doc+NEBO_CONSOLE_STATE],NEBO_CONSOLE_STATE_OPEN
 jne .fail6
 cmp qword [doc+NEBO_CONSOLE_LINES],1
 jne .fail7
 cmp qword [doc+NEBO_CONSOLE_REVISION],1
 jne .fail8

 ; Title success and oversized-title failure atomicity.
 lea rdi,[doc]
 lea rsi,[title]
 mov edx,4
 call nebo_console_set_title
 test eax,eax
 jnz .fail9
 cmp dword [title_store],0x6f62654e
 jne .fail10
 cmp qword [doc+NEBO_CONSOLE_TITLE_LENGTH],4
 jne .fail11
 mov r12,[doc+NEBO_CONSOLE_REVISION]
 lea rdi,[doc]
 lea rsi,[title]
 mov edx,NEBO_CONSOLE_MAX_TITLE+1
 call nebo_console_set_title
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail12
 cmp qword [doc+NEBO_CONSOLE_TITLE_LENGTH],4
 jne .fail13
 cmp [doc+NEBO_CONSOLE_REVISION],r12
 jne .fail14
 cmp dword [title_store],0x6f62654e
 jne .fail15

 ; Style plus exact payload/newline composition.
 lea rdi,[doc]
 mov esi,7
 call nebo_console_set_style
 test eax,eax
 jnz .fail16
 lea rdi,[doc]
 lea rsi,[hello]
 mov edx,5
 call nebo_console_append
 test eax,eax
 jnz .fail17
 lea rdi,[doc]
 lea rsi,[with_newline]
 mov edx,3
 call nebo_console_append_line
 test eax,eax
 jnz .fail18
 lea rdi,[doc]
 call nebo_console_size_query
 test eax,eax
 jnz .fail19
 cmp rdx,9
 jne .fail20
 cmp rcx,3
 jne .fail21
 cmp r8,7
 jne .fail22
 test r9,r9
 jnz .fail23
 cld
 lea rsi,[text]
 lea rdi,[expected_text]
 mov ecx,9
 repe cmpsb
 jne .fail24

 ; Signed scroll saturation, including positive overflow at the upper bound.
 lea rdi,[doc]
 mov esi,99
 call nebo_console_scroll
 test eax,eax
 jnz .fail25
 cmp qword [doc+NEBO_CONSOLE_SCROLL],2
 jne .fail26
 lea rdi,[doc]
 mov rsi,0x7fffffffffffffff
 call nebo_console_scroll
 test eax,eax
 jnz .fail27
 cmp qword [doc+NEBO_CONSOLE_SCROLL],2
 jne .fail28
 lea rdi,[doc]
 mov rsi,-1
 call nebo_console_scroll
 test eax,eax
 jnz .fail29
 cmp qword [doc+NEBO_CONSOLE_SCROLL],1
 jne .fail30
 lea rdi,[doc]
 mov rsi,0x8000000000000000
 call nebo_console_scroll
 test eax,eax
 jnz .fail31
 cmp qword [doc+NEBO_CONSOLE_SCROLL],0
 jne .fail32

 ; Clear preserves title/style but resets text, lines and scroll.
 lea rdi,[doc]
 call nebo_console_clear
 test eax,eax
 jnz .fail33
 cmp qword [doc+NEBO_CONSOLE_LENGTH],0
 jne .fail34
 cmp qword [doc+NEBO_CONSOLE_LINES],1
 jne .fail35
 cmp qword [doc+NEBO_CONSOLE_SCROLL],0
 jne .fail36
 cmp qword [doc+NEBO_CONSOLE_STYLE],7
 jne .fail37

 ; Invalid style is failure-atomic.
 mov r12,[doc+NEBO_CONSOLE_REVISION]
 lea rdi,[doc]
 mov esi,16
 call nebo_console_set_style
 cmp eax,NEBO_CONSOLE_ERROR_STYLE
 jne .fail38
 cmp qword [doc+NEBO_CONSOLE_STYLE],7
 jne .fail39
 cmp [doc+NEBO_CONSOLE_REVISION],r12
 jne .fail40

 ; Checked capacity arithmetic: no length wrap and no partial newline commit.
 mov qword [doc+NEBO_CONSOLE_LENGTH],4095
 mov r12,[doc+NEBO_CONSOLE_REVISION]
 lea rdi,[doc]
 lea rsi,[hello]
 mov edx,1
 call nebo_console_append_line
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail41
 cmp qword [doc+NEBO_CONSOLE_LENGTH],4095
 jne .fail42
 cmp [doc+NEBO_CONSOLE_REVISION],r12
 jne .fail43
 mov qword [doc+NEBO_CONSOLE_LENGTH],0
 mov r12,[doc+NEBO_CONSOLE_REVISION]
 lea rdi,[doc]
 lea rsi,[hello]
 mov rdx,-1
 call nebo_console_append
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail44
 cmp qword [doc+NEBO_CONSOLE_LENGTH],0
 jne .fail45
 cmp [doc+NEBO_CONSOLE_REVISION],r12
 jne .fail46
 lea rdi,[doc]
 lea rsi,[hello]
 mov rdx,-1
 call nebo_console_append_line
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail47
 cmp qword [doc+NEBO_CONSOLE_LENGTH],0
 jne .fail48
 cmp [doc+NEBO_CONSOLE_REVISION],r12
 jne .fail49

 ; Line overflow is rejected before bytes are copied.
 mov qword [doc+NEBO_CONSOLE_LINES],NEBO_CONSOLE_MAX_LINES
 mov byte [text],0x5a
 mov r12,[doc+NEBO_CONSOLE_REVISION]
 lea rdi,[doc]
 lea rsi,[newline]
 mov edx,1
 call nebo_console_append
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail50
 cmp qword [doc+NEBO_CONSOLE_LINES],NEBO_CONSOLE_MAX_LINES
 jne .fail51
 cmp qword [doc+NEBO_CONSOLE_LENGTH],0
 jne .fail52
 cmp [doc+NEBO_CONSOLE_REVISION],r12
 jne .fail53
 cmp byte [text],0x5a
 jne .fail54
 mov qword [doc+NEBO_CONSOLE_LINES],1

 ; Empty append is a true no-op and permits a null byte pointer.
 mov r12,[doc+NEBO_CONSOLE_REVISION]
 lea rdi,[doc]
 xor esi,esi
 xor edx,edx
 call nebo_console_append
 test eax,eax
 jnz .fail55
 cmp [doc+NEBO_CONSOLE_REVISION],r12
 jne .fail56

 ; Corrupted caller descriptors are rejected without exposing stale outputs.
 mov qword [doc+NEBO_CONSOLE_LENGTH],NEBO_CONSOLE_MAX_TEXT+1
 lea rdi,[doc]
 mov rdx,-1
 mov rcx,-1
 mov r8,-1
 mov r9,-1
 call nebo_console_size_query
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail57
 mov rax,rdx
 or rax,rcx
 or rax,r8
 or rax,r9
 jnz .fail58
 mov qword [doc+NEBO_CONSOLE_LENGTH],0

 mov qword [doc+NEBO_CONSOLE_TITLE_LENGTH],NEBO_CONSOLE_MAX_TITLE+1
 lea rdi,[doc]
 call nebo_console_size_query
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail59
 mov qword [doc+NEBO_CONSOLE_TITLE_LENGTH],4

 mov qword [doc+NEBO_CONSOLE_STYLE],16
 lea rdi,[doc]
 call nebo_console_size_query
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail60
 mov qword [doc+NEBO_CONSOLE_STYLE],7

 mov qword [doc+NEBO_CONSOLE_SCROLL],1
 lea rdi,[doc]
 call nebo_console_size_query
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail61
 mov qword [doc+NEBO_CONSOLE_SCROLL],0

 mov qword [doc+NEBO_CONSOLE_LINES],0
 lea rdi,[doc]
 call nebo_console_size_query
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail62
 mov qword [doc+NEBO_CONSOLE_LINES],1

 mov r12,[doc+NEBO_CONSOLE_REVISION]
 mov qword [doc+NEBO_CONSOLE_REVISION],0
 lea rdi,[doc]
 call nebo_console_size_query
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail63
 mov [doc+NEBO_CONSOLE_REVISION],r12

 ; Revision exhaustion is bounded and leaves the open document unchanged.
 mov r12,[doc+NEBO_CONSOLE_REVISION]
 mov qword [doc+NEBO_CONSOLE_REVISION],-1
 lea rdi,[doc]
 call nebo_console_clear
 cmp eax,NEBO_LINEAR_CONSOLE_DOCUMENT_CONSOLE_ERROR_LIMIT
 jne .fail64
 cmp qword [doc+NEBO_CONSOLE_REVISION],-1
 jne .fail65
 cmp qword [doc+NEBO_CONSOLE_STATE],NEBO_CONSOLE_STATE_OPEN
 jne .fail66
 mov [doc+NEBO_CONSOLE_REVISION],r12

 ; Close is terminal and null queries return a stable argument error.
 lea rdi,[doc]
 call nebo_console_close
 test eax,eax
 jnz .fail67
 cmp qword [doc+NEBO_CONSOLE_STATE],NEBO_CONSOLE_STATE_CLOSED
 jne .fail68
 lea rdi,[doc]
 call nebo_console_close
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail69
 lea rdi,[doc]
 lea rsi,[hello]
 mov edx,5
 call nebo_console_append
 cmp eax,NEBO_CONSOLE_ERROR_STATE
 jne .fail70
 xor edi,edi
 mov rdx,-1
 mov rcx,-1
 mov r8,-1
 mov r9,-1
 call nebo_console_size_query
 cmp eax,NEBO_CONSOLE_ERROR_ARGUMENT
 jne .fail71
 mov rax,rdx
 or rax,rcx
 or rax,r8
 or rax,r9
 jnz .fail72

 xor edi,edi
 jmp .exit
%assign i 1
%rep 72
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
