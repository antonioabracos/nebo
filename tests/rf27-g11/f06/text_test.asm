bits 64
default rel

%include "compiler/semantic/system/filesystem_contract.inc"
%include "runtime/filesystem/text.inc"
extern nebo_file_capability_init
extern nebo_file_open
extern nebo_file_close

%define SYS_OPENAT 257
%define SYS_CLOSE 3
%define AT_FDCWD -100
%define O_DIRECTORY 0x10000
%define O_CLOEXEC 0x80000

section .rodata
text_path db 'text.txt',0
atomic_path db 'atomic.txt',0
payload db 'alpha',13,10,'beta',10
atom db 'atom'
bang db '!'
invalid db 0xc0,0x80

section .bss
capability resb NEBO_FILE_CAPABILITY_SIZE
file resb NEBO_FILE_SIZE
buffer resb 64
line_buffer resb 32
ranges resq 8

section .text
global _start
_start:
 cmp qword [rsp],2
 jne .fail1
 mov rsi,[rsp+16]
 mov eax,SYS_OPENAT
 mov rdi,AT_FDCWD
 mov edx,O_DIRECTORY | O_CLOEXEC
 xor r10d,r10d
 syscall
 test rax,rax
 js .fail2
 mov r15,rax
 lea rdi,[capability]
 mov rsi,r15
 mov edx,31
 mov ecx,NEBO_FILE_CAP_ALL
 mov r8d,4
 mov r9d,65536
 call nebo_file_capability_init
 test eax,eax
 jnz .fail3
 lea rdi,[capability]
 lea rsi,[text_path]
 mov edx,8
 lea rcx,[payload]
 mov r8d,12
 mov r9d,NEBO_TEXT_WRITE_TRUNCATE
 call nebo_file_write_text
 test eax,eax
 jnz .fail4
 cmp edx,12
 jne .fail5
 lea rdi,[capability]
 lea rsi,[text_path]
 mov edx,8
 lea rcx,[buffer]
 mov r8d,32
 call nebo_file_read_text
 test eax,eax
 jnz .fail6
 cmp edx,12
 jne .fail7
 cmp dword [buffer],0x68706c61
 jne .fail8
 lea rdi,[invalid]
 mov esi,2
 call nebo_utf8_validate
 cmp eax,NEBO_FILE_ERROR_INVALID_ENCODING
 jne .fail9
 lea rdi,[buffer]
 mov esi,12
 lea rdx,[ranges]
 mov ecx,4
 call nebo_text_lines
 test eax,eax
 jnz .fail10
 cmp edx,3
 jne .fail11
 cmp qword [ranges],0
 jne .fail12
 cmp qword [ranges+8],5
 jne .fail13
 cmp qword [ranges+16],7
 jne .fail14
 cmp qword [ranges+24],4
 jne .fail15
 cmp qword [ranges+32],12
 jne .fail16
 cmp qword [ranges+40],0
 jne .fail17
 lea rdi,[capability]
 lea rsi,[text_path]
 mov edx,8
 lea rcx,[buffer]
 mov r8d,5
 call nebo_file_read_bytes
 cmp eax,NEBO_FILE_ERROR_LIMIT_EXCEEDED
 jne .fail18
 lea rdi,[file]
 lea rsi,[capability]
 lea rdx,[text_path]
 mov ecx,8
 xor r8d,r8d
 xor r9d,r9d
 call nebo_file_open
 test eax,eax
 jnz .fail19
 lea rdi,[file]
 lea rsi,[line_buffer]
 mov edx,16
 call nebo_file_read_line
 test eax,eax
 jnz .fail20
 cmp ecx,1
 jne .fail21
 cmp edx,5
 jne .fail22
 lea rdi,[file]
 lea rsi,[line_buffer]
 mov edx,16
 call nebo_file_read_line
 test eax,eax
 jnz .fail23
 cmp ecx,1
 jne .fail24
 cmp edx,4
 jne .fail25
 lea rdi,[file]
 lea rsi,[line_buffer]
 mov edx,16
 call nebo_file_read_line
 test eax,eax
 jnz .fail26
 test ecx,ecx
 jnz .fail27
 lea rdi,[file]
 call nebo_file_close
 test eax,eax
 jnz .fail28
 lea rdi,[capability]
 lea rsi,[atomic_path]
 mov edx,10
 lea rcx,[atom]
 mov r8d,4
 mov r9d,NEBO_TEXT_WRITE_ATOMIC
 call nebo_file_write_bytes
 test eax,eax
 jnz .fail29
 cmp edx,4
 jne .fail30
 lea rdi,[capability]
 lea rsi,[atomic_path]
 mov edx,10
 lea rcx,[bang]
 mov r8d,1
 mov r9d,NEBO_TEXT_WRITE_APPEND
 call nebo_file_write_bytes
 test eax,eax
 jnz .fail31
 lea rdi,[capability]
 lea rsi,[atomic_path]
 mov edx,10
 lea rcx,[buffer]
 mov r8d,16
 call nebo_file_read_bytes
 test eax,eax
 jnz .fail32
 cmp edx,5
 jne .fail33
 cmp dword [buffer],0x6d6f7461
 jne .fail34
 cmp byte [buffer+4],'!'
 jne .fail35
 mov eax,SYS_CLOSE
 mov rdi,r15
 syscall
 xor edi,edi
 jmp .exit
.fail1: mov edi,1
 jmp .exit
.fail2: mov edi,2
 jmp .exit
.fail3: mov edi,3
 jmp .exit
.fail4: mov edi,4
 jmp .exit
.fail5: mov edi,5
 jmp .exit
.fail6: mov edi,6
 jmp .exit
.fail7: mov edi,7
 jmp .exit
.fail8: mov edi,8
 jmp .exit
.fail9: mov edi,9
 jmp .exit
.fail10: mov edi,10
 jmp .exit
.fail11: mov edi,11
 jmp .exit
.fail12: mov edi,12
 jmp .exit
.fail13: mov edi,13
 jmp .exit
.fail14: mov edi,14
 jmp .exit
.fail15: mov edi,15
 jmp .exit
.fail16: mov edi,16
 jmp .exit
.fail17: mov edi,17
 jmp .exit
.fail18: mov edi,18
 jmp .exit
.fail19: mov edi,19
 jmp .exit
.fail20: mov edi,20
 jmp .exit
.fail21: mov edi,21
 jmp .exit
.fail22: mov edi,22
 jmp .exit
.fail23: mov edi,23
 jmp .exit
.fail24: mov edi,24
 jmp .exit
.fail25: mov edi,25
 jmp .exit
.fail26: mov edi,26
 jmp .exit
.fail27: mov edi,27
 jmp .exit
.fail28: mov edi,28
 jmp .exit
.fail29: mov edi,29
 jmp .exit
.fail30: mov edi,30
 jmp .exit
.fail31: mov edi,31
 jmp .exit
.fail32: mov edi,32
 jmp .exit
.fail33: mov edi,33
 jmp .exit
.fail34: mov edi,34
 jmp .exit
.fail35: mov edi,35
.exit:
 mov eax,60
 syscall
