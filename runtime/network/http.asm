bits 64
default rel
%define NEBO_HTTP_IMPLEMENTATION 1
%include "runtime/network/http.inc"

section .rodata
get_prefix db 'GET '
get_prefix_len equ $-get_prefix
version_host db ' HTTP/1.1',13,10,'Host: '
version_host_len equ $-version_host
suffix db 13,10,'Connection: close',13,10,'Content-Length: 0',13,10,13,10
suffix_len equ $-suffix
content_name db 'Content-Length: '
content_name_len equ $-content_name
chunked_name db 'Transfer-Encoding: chunked'
chunked_name_len equ $-chunked_name
section .text
global nebo_http_encode_get
global nebo_http_parse_response
global nebo_http_decode_chunked

; rdi=out,rsi=cap,rdx=path,rcx=path len,r8=host,r9=host len. eax=status,rdx=len.
nebo_http_encode_get:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r14,rdx
 mov r15,rcx
 test rbx,rbx
 jz .encode_invalid
 test rdx,rdx
 jz .encode_invalid
 test r8,r8
 jz .encode_invalid
 test rcx,rcx
 jz .encode_invalid
 cmp byte [rdx],'/'
 jne .encode_invalid
 cmp rcx,1024
 ja .encode_limit
 cmp r9,253
 ja .encode_limit
 mov rax,get_prefix_len+version_host_len+suffix_len
 add rax,rcx
 add rax,r9
 cmp rax,r12
 ja .encode_limit
 mov r13,rax
 mov rdi,rbx
 lea rsi,[get_prefix]
 mov ecx,get_prefix_len
 rep movsb
 mov rsi,r14
 mov rcx,r15
 rep movsb
 lea rsi,[version_host]
 mov ecx,version_host_len
 rep movsb
 mov rsi,r8
 mov rcx,r9
 rep movsb
 lea rsi,[suffix]
 mov ecx,suffix_len
 rep movsb
 mov rdx,r13
 xor eax,eax
 jmp .encode_return
.encode_invalid: mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .encode_return
.encode_limit: mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
.encode_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=Response out,rsi=mutable response bytes,rdx=len,rcx=max body,r8=max headers.
nebo_http_parse_response:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 test rbx,rbx
 jz .parse_invalid
 test r12,r12
 jz .parse_invalid
 cmp r13,19
 jb .parse_invalid
 cmp dword [r12],'HTTP'
 jne .parse_invalid
 cmp dword [r12+4],0x312e312f
 jne .parse_invalid
 cmp byte [r12+8],' '
 jne .parse_invalid
 movzx eax,byte [r12+9]
 sub eax,'0'
 cmp eax,9
 ja .parse_invalid
 imul eax,eax,100
 movzx ecx,byte [r12+10]
 sub ecx,'0'
 cmp ecx,9
 ja .parse_invalid
 imul ecx,ecx,10
 add eax,ecx
 movzx ecx,byte [r12+11]
 sub ecx,'0'
 cmp ecx,9
 ja .parse_invalid
 add eax,ecx
 mov [rbx+NEBO_HTTP_RESPONSE_STATUS],rax
 mov qword [rbx+NEBO_HTTP_RESPONSE_FLAGS],0
 xor r9d,r9d
 xor r10d,r10d
 mov r11,12
.find_headers_end:
 lea rax,[r11+3]
 cmp rax,r13
 jae .parse_invalid
 cmp dword [r12+r11],0x0a0d0a0d
 je .headers_end
 cmp byte [r12+r11],10
 jne .find_next
 cmp r11,0
 je .parse_invalid
 cmp byte [r12+r11-1],13
 jne .parse_invalid
 inc r10
 cmp r10,r15
 ja .parse_limit
.find_next:
 inc r11
 jmp .find_headers_end
.headers_end:
 add r11,4
 mov rax,r13
 sub rax,r11
 cmp rax,r14
 ja .parse_limit
 ; Strictly locate either Content-Length or Transfer-Encoding in bounded headers.
 mov rdi,r12
 mov rsi,r11
 lea rdx,[content_name]
 mov ecx,content_name_len
 call http_find
 test rax,rax
 jz .check_chunked
 mov r9,rax
 add r9,content_name_len
 xor eax,eax
.length_loop:
 lea rdx,[r12+r11]
 cmp r9,rdx
 jae .parse_invalid
 movzx ecx,byte [r9]
 cmp cl,13
 je .length_done
 sub ecx,'0'
 cmp ecx,9
 ja .parse_invalid
 imul rax,rax,10
 add rax,rcx
 cmp rax,r14
 ja .parse_limit
 inc r9
 jmp .length_loop
.length_done:
 mov rcx,r13
 sub rcx,r11
 cmp rax,rcx
 jne .parse_invalid
 lea rcx,[r12+r11]
 mov [rbx+NEBO_HTTP_RESPONSE_BODY],rcx
 mov [rbx+NEBO_HTTP_RESPONSE_BODY_LENGTH],rax
 mov qword [rbx+NEBO_HTTP_RESPONSE_FLAGS],NEBO_HTTP_FLAG_CONTENT_LENGTH
 xor eax,eax
 jmp .parse_return
.check_chunked:
 mov rdi,r12
 mov rsi,r11
 lea rdx,[chunked_name]
 mov ecx,chunked_name_len
 call http_find
 test rax,rax
 jz .parse_invalid
 lea rdi,[r12+r11]
 mov rsi,r13
 sub rsi,r11
 mov rdx,rbx
 mov rcx,r14
 call nebo_http_decode_chunked
 test eax,eax
 jnz .parse_return
 mov qword [rbx+NEBO_HTTP_RESPONSE_FLAGS],NEBO_HTTP_FLAG_CHUNKED
 jmp .parse_return
.parse_invalid: mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .parse_return
.parse_limit: mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.parse_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=chunk bytes,rsi=len,rdx=Response out,rcx=max body. Decodes in-place.
nebo_http_decode_chunked:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rdx
 mov r14,rsi
 mov r15,rcx
 xor r8d,r8d
 xor r9d,r9d
.chunk_size:
 cmp r8,r14
 jae .chunk_invalid
 xor eax,eax
.hex_loop:
 cmp r8,r14
 jae .chunk_invalid
 movzx edx,byte [rbx+r8]
 cmp dl,13
 je .hex_done
 shl rax,4
 cmp dl,'0'
 jb .chunk_invalid
 cmp dl,'9'
 jbe .hex_digit
 or dl,32
 cmp dl,'a'
 jb .chunk_invalid
 cmp dl,'f'
 ja .chunk_invalid
 sub edx,'a'-10
 jmp .hex_add
.hex_digit: sub edx,'0'
.hex_add: add rax,rdx
 cmp rax,r15
 ja .chunk_limit
 inc r8
 jmp .hex_loop
.hex_done:
 inc r8
 cmp r8,r14
 jae .chunk_invalid
 cmp byte [rbx+r8],10
 jne .chunk_invalid
 inc r8
 test rax,rax
 jz .chunk_finish
 mov r10,r9
 add r10,rax
 cmp r10,r15
 ja .chunk_limit
 mov r13,rax
 lea rsi,[rbx+r8]
 lea rdi,[rbx+r9]
 mov rcx,rax
 rep movsb
 add r8,r13
 add r9,r13
 cmp byte [rbx+r8],13
 jne .chunk_invalid
 cmp byte [rbx+r8+1],10
 jne .chunk_invalid
 add r8,2
 jmp .chunk_size
.chunk_finish:
 lea rax,[rbx]
 mov [r12+NEBO_HTTP_RESPONSE_BODY],rax
 mov [r12+NEBO_HTTP_RESPONSE_BODY_LENGTH],r9
 xor eax,eax
 jmp .chunk_return
.chunk_invalid: mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .chunk_return
.chunk_limit: mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.chunk_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=haystack,rsi=len,rdx=needle,rcx=needle len. rax=address or zero.
http_find:
 xor r8d,r8d
.find_outer:
 mov rax,r8
 add rax,rcx
 cmp rax,rsi
 ja .find_none
 xor r9d,r9d
.find_inner:
 cmp r9,rcx
 jae .find_yes
 mov al,[rdi+r8]
 cmp al,[rdx+r9]
 jne .find_next_outer
 inc r8
 inc r9
 jmp .find_inner
.find_next_outer:
 sub r8,r9
 inc r8
 jmp .find_outer
.find_yes:
 sub r8,rcx
 lea rax,[rdi+r8]
 ret
.find_none:
 xor eax,eax
 ret
