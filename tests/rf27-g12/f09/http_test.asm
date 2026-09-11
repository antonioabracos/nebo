bits 64
default rel
%include "runtime/network/http.inc"
section .rodata
path db '/health'
host db '127.0.0.1:39030'
good_response db 'HTTP/1.1 200 OK',13,10,'Content-Length: 5',13,10,'Connection: close',13,10,13,10,'hello'
good_response_len equ $-good_response
bad_lf db 'HTTP/1.1 200 OK',10,'Content-Length: 1',13,10,13,10,'x'
bad_lf_len equ $-bad_lf
section .data
chunked_response db 'HTTP/1.1 201 OK',13,10,'Transfer-Encoding: chunked',13,10,13,10,'5',13,10,'hello',13,10,'0',13,10,13,10
chunked_response_len equ $-chunked_response
section .bss
request resb 256
response resb 32
section .text
global _start
_start:
 lea rdi,[request]
 mov esi,256
 lea rdx,[path]
 mov ecx,7
 lea r8,[host]
 mov r9d,15
 call nebo_http_encode_get
 test eax,eax
 jnz .fail1
 cmp dword [request],'GET '
 jne .fail2
 cmp byte [request+4],'/'
 jne .fail3
 cmp rdx,70
 jb .fail4
 lea rdi,[response]
 lea rsi,[good_response]
 mov edx,good_response_len
 mov ecx,16
 mov r8d,8
 call nebo_http_parse_response
 test eax,eax
 jnz .fail5
 cmp qword [response+NEBO_HTTP_RESPONSE_STATUS],200
 jne .fail6
 cmp qword [response+NEBO_HTTP_RESPONSE_BODY_LENGTH],5
 jne .fail7
 mov rax,[response+NEBO_HTTP_RESPONSE_BODY]
 cmp dword [rax],'hell'
 jne .fail8
 cmp qword [response+NEBO_HTTP_RESPONSE_FLAGS],NEBO_HTTP_FLAG_CONTENT_LENGTH
 jne .fail9
 lea rdi,[response]
 lea rsi,[chunked_response]
 mov edx,chunked_response_len
 mov ecx,16
 mov r8d,8
 call nebo_http_parse_response
 test eax,eax
 jnz .fail10
 cmp qword [response+NEBO_HTTP_RESPONSE_STATUS],201
 jne .fail11
 cmp qword [response+NEBO_HTTP_RESPONSE_BODY_LENGTH],5
 jne .fail12
 mov rax,[response+NEBO_HTTP_RESPONSE_BODY]
 cmp dword [rax],'hell'
 jne .fail13
 cmp qword [response+NEBO_HTTP_RESPONSE_FLAGS],NEBO_HTTP_FLAG_CHUNKED
 jne .fail14
 lea rdi,[response]
 lea rsi,[bad_lf]
 mov edx,bad_lf_len
 mov ecx,16
 mov r8d,8
 call nebo_http_parse_response
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail15
 lea rdi,[response]
 lea rsi,[good_response]
 mov edx,good_response_len
 mov ecx,4
 mov r8d,8
 call nebo_http_parse_response
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail16
 lea rdi,[request]
 mov esi,2
 lea rdx,[path]
 mov ecx,7
 lea r8,[host]
 mov r9d,15
 call nebo_http_encode_get
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail17
 xor edi,edi
 jmp .exit
%assign i 1
%rep 17
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
